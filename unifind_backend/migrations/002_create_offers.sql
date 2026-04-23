-- Migration 002: create the `offers` table for counter-offer negotiations.
--
-- Run once on existing deployments:
--   mysql -u <user> -p <database> < migrations/002_create_offers.sql
--
-- Safe to re-run: CREATE TABLE IF NOT EXISTS is a no-op when the table exists.
-- The offers schema also lives in schema.sql so fresh installs get it via the
-- normal bootstrap path; this file is just for upgrading existing DBs.

CREATE TABLE IF NOT EXISTS offers (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    listing_id INT UNSIGNED NOT NULL,
    sender_id INT UNSIGNED NOT NULL,
    recipient_id INT UNSIGNED NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status ENUM('pending','accepted','rejected','countered','withdrawn','superseded')
        NOT NULL DEFAULT 'pending',
    parent_offer_id INT UNSIGNED NULL,
    note TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    responded_at DATETIME NULL,
    CONSTRAINT fk_offers_parent FOREIGN KEY (parent_offer_id)
        REFERENCES offers(id)
        ON DELETE SET NULL,
    KEY idx_offers_listing_status (listing_id, status),
    KEY idx_offers_sender_status (sender_id, status),
    KEY idx_offers_recipient_status (recipient_id, status),
    KEY idx_offers_parent (parent_offer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
