<?php

declare(strict_types=1);

/**
 * Message body encryption at rest.
 *
 * Scheme: AES-256-GCM, 12-byte random IV per message, 16-byte auth tag.
 *
 * On-disk format (stored in messages.body and offers.note as TEXT):
 *   "v1:" + base64( iv(12 bytes) || tag(16 bytes) || ciphertext )
 *
 * The "v1:" prefix lets us tell encrypted rows from legacy plaintext so the
 * migration is idempotent (already-encrypted rows are skipped) and reads
 * stay safe during/after migration: if any row slips through as plaintext,
 * decrypt_message_body() returns it unchanged rather than crashing.
 *
 * Key source: $config['security']['message_key'] — the shim in config.php
 * sets this from the MESSAGE_KEY constant. Must be 32 raw bytes or base64
 * of 32 bytes.
 */

if (!function_exists('message_encryption_key')) {
    /**
     * Resolve and cache the raw 32-byte AES-256 key from config.
     *
     * @throws RuntimeException if the key is missing or malformed.
     */
    function message_encryption_key(): string
    {
        static $cached = null;
        if ($cached !== null) {
            return $cached;
        }

        global $config;
        $raw = $config['security']['message_key'] ?? '';
        if (!is_string($raw) || $raw === '') {
            throw new RuntimeException(
                'security.message_key is not configured. Check config.php.'
            );
        }

        // Accept either raw 32 bytes or base64 of 32 bytes.
        if (strlen($raw) === 32) {
            return $cached = $raw;
        }
        $decoded = base64_decode($raw, true);
        if ($decoded === false || strlen($decoded) !== 32) {
            throw new RuntimeException(
                'security.message_key must be 32 raw bytes or base64 of 32 bytes.'
            );
        }
        return $cached = $decoded;
    }
}

if (!function_exists('encrypt_message_body')) {
    /**
     * Encrypt a message body for storage. Returns the "v1:..." string.
     */
    function encrypt_message_body(string $plaintext): string
    {
        $key = message_encryption_key();
        $iv  = random_bytes(12);
        $tag = '';
        $ciphertext = openssl_encrypt(
            $plaintext,
            'aes-256-gcm',
            $key,
            OPENSSL_RAW_DATA,
            $iv,
            $tag,
            '',
            16
        );
        if ($ciphertext === false) {
            throw new RuntimeException('Message encryption failed.');
        }
        return 'v1:' . base64_encode($iv . $tag . $ciphertext);
    }
}

if (!function_exists('decrypt_message_body')) {
    /**
     * Decrypt a stored body. Values without a recognized version prefix are
     * returned as-is so that reads stay safe if any legacy plaintext is ever
     * encountered (e.g. partially-migrated DB). NULLs pass through as NULL.
     */
    function decrypt_message_body(?string $stored): ?string
    {
        if ($stored === null) {
            return null;
        }
        if (strncmp($stored, 'v1:', 3) !== 0) {
            // Not encrypted (legacy plaintext or already-decoded): pass through.
            return $stored;
        }

        $blob = base64_decode(substr($stored, 3), true);
        // Must contain at least iv(12) + tag(16) = 28 bytes of header.
        if ($blob === false || strlen($blob) < 28) {
            return $stored;
        }

        $iv         = substr($blob, 0, 12);
        $tag        = substr($blob, 12, 16);
        $ciphertext = substr($blob, 28);

        try {
            $key = message_encryption_key();
        } catch (RuntimeException $e) {
            error_log('decrypt_message_body: ' . $e->getMessage());
            return $stored;
        }

        $plaintext = openssl_decrypt(
            $ciphertext,
            'aes-256-gcm',
            $key,
            OPENSSL_RAW_DATA,
            $iv,
            $tag
        );
        if ($plaintext === false) {
            error_log('decrypt_message_body: openssl_decrypt failed (auth or data error).');
            return $stored;
        }
        return $plaintext;
    }
}
