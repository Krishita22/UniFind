CREATE TABLE IF NOT EXISTS users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(190) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_verified TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_users_email (email),
    KEY idx_users_verified (is_verified)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS email_verification_tokens (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    token_hash CHAR(64) NOT NULL,
    expires_at DATETIME NOT NULL,
    used_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tokens_user FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,
    KEY idx_tokens_user_created (user_id, created_at),
    KEY idx_tokens_expires_used (expires_at, used_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS listings (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(80) NOT NULL,
    image_path VARCHAR(255) NOT NULL,
    is_approved TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_listings_user FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,
    KEY idx_listings_approved_created (is_approved, created_at),
    KEY idx_listings_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS lost_found_claims (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    found_item_id INT UNSIGNED NOT NULL,
    claimant_id INT UNSIGNED NOT NULL,
    proof_details TEXT NOT NULL,
    identifying_details TEXT NULL,
    last_seen_context TEXT NULL,
    contact_note TEXT NULL,
    status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_claims_item (found_item_id),
    KEY idx_claims_claimant (claimant_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS lost_found_matches (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    lost_item_id INT UNSIGNED NOT NULL,
    found_item_id INT UNSIGNED NULL,
    submitter_id INT UNSIGNED NULL,
    found_location VARCHAR(255) NULL,
    found_when VARCHAR(255) NULL,
    match_details TEXT NULL,
    contact_note TEXT NULL,
    status ENUM('active','resolved','unmatched') NOT NULL DEFAULT 'active',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_matches_lost (lost_item_id),
    KEY idx_matches_found (found_item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
