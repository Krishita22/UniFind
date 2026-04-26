# Quick Start: Fix Approve/Deny in 3 Steps

## What's Wrong
You click Approve on a meetup, but it fails because the meetup isn't actually in the database yet.

## Why
The system displays meetups from `get_admin_meetups.php` but never creates them because the "create meetup" workflow is missing.

## The Fix

### Step 1: Create Database Tables (5 minutes)
Go to cPanel → phpMyAdmin → SQL tab and paste:
```sql
-- Copy the entire SQL from unifind_backend/migrations/006_create_lost_found_approvals.sql
```

### Step 2: Upload PHP Files (5 minutes)
Upload these files to cPanel `/public_html/UniFind_API/`:
1. `unifind_backend/admin/claims/approve_claim.php`
2. `unifind_backend/admin/claims/reject_claim.php`
3. `unifind_backend/lostfound/create_meetup.php`
4. `unifind_backend/admin/meetup/approve_meetup.php`

### Step 3: Test the Workflow (10 minutes)
Use Postman or curl to test in order:

**1. Get a claim ID** (check database)
```bash
SELECT id, claimant_id, found_item_id FROM lost_found_claims LIMIT 1;
# Note the claim_id
```

**2. Approve the claim:**
```bash
curl -X POST http://cyan.csam.montclair.edu/~ivanovs1/UniFind_API/admin/claims/approve_claim.php \
  -H "Content-Type: application/json" \
  -d '{"claim_id": 1}'
```

**3. Create the meetup:**
```bash
curl -X POST http://cyan.csam.montclair.edu/~ivanovs1/UniFind_API/lostfound/create_meetup.php \
  -H "Content-Type: application/json" \
  -d '{
    "claim_id": 1,
    "meetup_date": "2026-05-05",
    "meetup_time": "14:00:00",
    "meetup_location": "Sprague Library"
  }'
```
This returns `meetup_id` - note it.

**4. Refresh admin panel and click Approve:**
The meetup now exists, so Approve should work!

---

## That's It!

Once this works, you have:
- ✅ Claim approval workflow
- ✅ Meetup creation workflow  
- ✅ Meetup approval workflow

The next phases (item approval, resolution, admin matching) can be added separately.

---

## Files You Need

All locally in your project:

**New backend files:**
- `unifind_backend/admin/claims/approve_claim.php`
- `unifind_backend/admin/claims/reject_claim.php`
- `unifind_backend/lostfound/create_meetup.php`
- `unifind_backend/admin/meetup/approve_meetup.php`

**SQL migration:**
- `unifind_backend/migrations/006_create_lost_found_approvals.sql`

All have been created locally. Just need to upload to cPanel!
