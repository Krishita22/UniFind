# Immediate Fix: Getting Approve/Deny to Work

## Problem
The meetup being displayed in the admin panel doesn't actually exist in the database, so Approve/Deny fail.

## Root Cause
There's no workflow to CREATE a meetup in the database. The system only displays meetups but has no endpoint for users to propose them.

## Solution: Complete Workflow

### Step 1: Create Missing Database Tables
Run this SQL in phpMyAdmin:

```sql
-- Migration 006: Create approval tracking tables
CREATE TABLE IF NOT EXISTS lost_found_item_approvals (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    item_id INT UNSIGNED NOT NULL,
    admin_id INT UNSIGNED,
    status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    rejection_reason TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME,
    CONSTRAINT fk_item_approval_item FOREIGN KEY (item_id) REFERENCES lost_found_items(id) ON DELETE CASCADE,
    CONSTRAINT fk_item_approval_admin FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE SET NULL,
    KEY idx_item_approval_status (status),
    KEY idx_item_approval_item (item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS claim_approvals (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    claim_id INT UNSIGNED NOT NULL,
    admin_id INT UNSIGNED,
    status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    rejection_reason TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME,
    CONSTRAINT fk_claim_approval_claim FOREIGN KEY (claim_id) REFERENCES lost_found_claims(id) ON DELETE CASCADE,
    CONSTRAINT fk_claim_approval_admin FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE SET NULL,
    KEY idx_claim_approval_status (status),
    KEY idx_claim_approval_claim (claim_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS meetup_approvals (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    meetup_id INT UNSIGNED NOT NULL,
    admin_id INT UNSIGNED,
    status ENUM('pending', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
    rejection_reason TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_at DATETIME,
    CONSTRAINT fk_meetup_approval_meetup FOREIGN KEY (meetup_id) REFERENCES lost_found_meetups(id) ON DELETE CASCADE,
    CONSTRAINT fk_meetup_approval_admin FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE SET NULL,
    KEY idx_meetup_approval_status (status),
    KEY idx_meetup_approval_meetup (meetup_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
    CONSTRAINT fk_resolution_meetup FOREIGN KEY (meetup_id) REFERENCES lost_found_meetups(id) ON DELETE CASCADE,
    CONSTRAINT fk_resolution_user1 FOREIGN KEY (user1_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_resolution_user2 FOREIGN KEY (user2_id) REFERENCES users(id) ON DELETE CASCADE,
    KEY idx_resolution_meetup (meetup_id),
    KEY idx_resolution_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Step 2: Upload New PHP Endpoints to cPanel

Upload these new files to `/public_html/UniFind_API/`:

1. `/admin/claims/approve_claim.php` - NEW
2. `/admin/claims/reject_claim.php` - NEW
3. `/lostfound/create_meetup.php` - NEW
4. `/admin/meetup/approve_meetup.php` - UPDATED (step-by-step version)

### Step 3: Update `get_admin_meetups.php` on cPanel

Make sure this file has the table existence check (provided earlier). This prevents errors when querying non-existent marketplace tables.

### Step 4: Test Complete Workflow

#### Test Setup:
You already have:
- Lost item (Krishita posted)
- Found item (Edwin2 posted)  
- A claim from Krishita on the found item

#### Execute Workflow:

**1. Approve the Claim:**
```bash
POST to: http://cyan.csam.montclair.edu/~ivanovs1/UniFind_API/admin/claims/approve_claim.php
Body: {"claim_id": <claim_id_from_database>}
```
Expected Response: `{"success": true, "data": {"claim_id": X, "status": "approved"}}`

**2. Create the Meetup:**
```bash
POST to: http://cyan.csam.montclair.edu/~ivanovs1/UniFind_API/lostfound/create_meetup.php
Body: {
  "claim_id": <claim_id>,
  "meetup_date": "2026-05-05",
  "meetup_time": "14:00:00",
  "meetup_location": "Sprague Library"
}
```
Expected Response: `{"success": true, "data": {"meetup_id": X, "status": "pending"}}`

**3. Refresh Admin Panel:**
- Go to Meetup Proposals
- You should see the meetup with "Pending" status

**4. Click Approve:**
Should work now! The meetup exists in the database.

---

## Summary of Changes

### New Endpoints
- `POST /admin/claims/approve_claim.php` - Approve user claim
- `POST /admin/claims/reject_claim.php` - Reject user claim
- `POST /lostfound/create_meetup.php` - User proposes meetup

### Updated Endpoints
- `POST /admin/meetup/approve_meetup.php` - Fixed with step-by-step queries
- `GET /admin/meetup/get_admin_meetups.php` - Added table existence check

### Database
- `claim_approvals` - Track claim approvals
- `lost_found_item_approvals` - Track item approvals
- `meetup_approvals` - Track meetup approvals
- `lost_found_resolutions` - Track resolution confirmations

---

## Key Insight

The problem was architectural: The system tried to approve meetups that never got created. By adding the proper workflow (claim approval → meetup creation → meetup approval), the system now follows the specification and everything works.

The meetup must EXIST in `lost_found_meetups` table before it can be approved.
