-- schema_django.sql
--
-- Run this in phpMyAdmin (or cPanel's MySQL section) to set up the database.
-- This is the same as the existing schema.sql PLUS one extra column:
-- `is_admin` on the users table, which our Django admin panel needs.
--
-- If you already ran schema.sql and the tables exist, just run the
-- ALTER TABLE statement at the bottom to add the is_admin column.
-- If you're starting fresh, run everything.
--
-- To run in phpMyAdmin:
--   1. Select your database in the left panel
--   2. Click the "SQL" tab at the top
--   3. Paste this entire file in and click "Go"

-- ============================================================
-- USERS TABLE
-- Stores all registered users. is_verified = 0 until they click
-- the email link. is_admin = 1 for admins who can see /admin/.
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name     VARCHAR(120)  NOT NULL,
    email         VARCHAR(190)  NOT NULL,
    password_hash VARCHAR(255)  NOT NULL,
    is_verified   TINYINT(1)    NOT NULL DEFAULT 0,
    is_admin      TINYINT(1)    NOT NULL DEFAULT 0,   -- Added for Django admin panel
    created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_users_email (email),
    KEY idx_users_verified (is_verified)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- EMAIL VERIFICATION TOKENS TABLE
-- Stores hashed verification tokens. Raw tokens only live in emails.
-- expires_at: 24 hours after creation
-- used_at:    NULL = not yet clicked; non-NULL = link already used
-- ============================================================

CREATE TABLE IF NOT EXISTS email_verification_tokens (
    id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id    INT UNSIGNED  NOT NULL,
    token_hash CHAR(64)      NOT NULL,   -- SHA-256 hex = 64 chars. Not a coincidence.
    expires_at DATETIME      NOT NULL,
    used_at    DATETIME      NULL,
    created_at DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_tokens_user FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,
    KEY idx_tokens_user_created (user_id, created_at),
    KEY idx_tokens_expires_used (expires_at, used_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- LISTINGS TABLE
-- Stores marketplace listings. is_approved = 1 by default.
-- Admins can set is_approved = 0 to hide a listing.
-- ============================================================

CREATE TABLE IF NOT EXISTS listings (
    id          INT UNSIGNED   AUTO_INCREMENT PRIMARY KEY,
    user_id     INT UNSIGNED   NOT NULL,
    name        VARCHAR(150)   NOT NULL,
    description TEXT           NOT NULL,
    price       DECIMAL(10,2)  NOT NULL,
    category    VARCHAR(80)    NOT NULL,
    image_path  VARCHAR(255)   NOT NULL,
    is_approved TINYINT(1)     NOT NULL DEFAULT 1,
    created_at  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_listings_user FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE,
    KEY idx_listings_approved_created (is_approved, created_at),
    KEY idx_listings_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- IF THE TABLES ALREADY EXIST from schema.sql, just run this:
-- (comment out the CREATE TABLE blocks above and just run this)
-- ============================================================

-- ALTER TABLE users ADD COLUMN is_admin TINYINT(1) NOT NULL DEFAULT 0;


-- ============================================================
-- DRF AUTH TOKEN TABLE
-- Django REST Framework stores auth tokens here.
-- Django creates this automatically via `python manage.py migrate`
-- but in case you need to create it manually:
-- ============================================================

CREATE TABLE IF NOT EXISTS authtoken_token (
    `key`       VARCHAR(40)  NOT NULL PRIMARY KEY,
    created     DATETIME(6)  NOT NULL,
    user_id     INT UNSIGNED NOT NULL UNIQUE,
    CONSTRAINT authtoken_token_user_id FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
