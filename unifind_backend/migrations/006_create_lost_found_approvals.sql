-- Lost & Found Item Approvals table
CREATE TABLE IF NOT EXISTS lost_found_item_approvals (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    item_id INT UNSIGNED NOT NULL,
    admin_id INT UNSIGNED,
    status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    rejection_reason TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME,
    CONSTRAINT fk_item_approval_item FOREIGN KEY (item_id)
        REFERENCES lost_found_items(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_item_approval_admin FOREIGN KEY (admin_id)
        REFERENCES users(id)
        ON DELETE SET NULL,
    KEY idx_item_approval_status (status),
    KEY idx_item_approval_item (item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Lost & Found Claims Approvals table
CREATE TABLE IF NOT EXISTS claim_approvals (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    claim_id INT UNSIGNED NOT NULL,
    admin_id INT UNSIGNED,
    status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    rejection_reason TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME,
    CONSTRAINT fk_claim_approval_claim FOREIGN KEY (claim_id)
        REFERENCES lost_found_claims(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_claim_approval_admin FOREIGN KEY (admin_id)
        REFERENCES users(id)
        ON DELETE SET NULL,
    KEY idx_claim_approval_status (status),
    KEY idx_claim_approval_claim (claim_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Meetup Approvals table
CREATE TABLE IF NOT EXISTS meetup_approvals (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    meetup_id INT UNSIGNED NOT NULL,
    admin_id INT UNSIGNED,
    status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    rejection_reason TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME,
    CONSTRAINT fk_meetup_approval_meetup FOREIGN KEY (meetup_id)
        REFERENCES lost_found_meetups(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_meetup_approval_admin FOREIGN KEY (admin_id)
        REFERENCES users(id)
        ON DELETE SET NULL,
    KEY idx_meetup_approval_status (status),
    KEY idx_meetup_approval_meetup (meetup_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Resolutions table (both users must confirm)
CREATE TABLE IF NOT EXISTS lost_found_resolutions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    meetup_id INT UNSIGNED NOT NULL,
    user1_id INT UNSIGNED NOT NULL,
    user2_id INT UNSIGNED NOT NULL,
    user1_confirmed_at DATETIME,
    user2_confirmed_at DATETIME,
    status ENUM('pending', 'partial', 'completed') NOT NULL DEFAULT 'pending',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    CONSTRAINT fk_resolution_meetup FOREIGN KEY (meetup_id)
        REFERENCES lost_found_meetups(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_resolution_user1 FOREIGN KEY (user1_id)
        REFERENCES users(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_resolution_user2 FOREIGN KEY (user2_id)
        REFERENCES users(id)
        ON DELETE CASCADE,
    KEY idx_resolution_meetup (meetup_id),
    KEY idx_resolution_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
