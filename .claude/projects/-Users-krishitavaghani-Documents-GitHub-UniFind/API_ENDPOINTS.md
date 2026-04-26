# UniFind Lost & Found System - API Endpoints

## BASE URL
`http://cyan.csam.montclair.edu/~ivanovs1/UniFind_API`

---

## CLAIM WORKFLOW ENDPOINTS

### 1. Approve User Claim
**POST** `/admin/claims/approve_claim.php`

Approves a user's claim on a found item. Opens chat and notifies user.

**Request:**
```json
{
  "claim_id": 1
}
```

**Response (Success):**
```json
{
  "success": true,
  "data": {
    "claim_id": 1,
    "status": "approved"
  }
}
```

**Actions:**
- Updates `lost_found_claims` status to 'approved'
- Records approval in `claim_approvals` table
- Sends email notification to claimant
- Enables user to propose meetup

---

### 2. Reject User Claim
**POST** `/admin/claims/reject_claim.php`

Rejects a user's claim on a found item.

**Request:**
```json
{
  "claim_id": 1,
  "reason": "Insufficient proof of ownership"
}
```

**Response (Success):**
```json
{
  "success": true,
  "data": {
    "claim_id": 1,
    "status": "rejected"
  }
}
```

**Actions:**
- Updates `lost_found_claims` status to 'rejected'
- Records rejection in `claim_approvals` table with reason
- Sends email notification to claimant with rejection reason

---

## MEETUP CREATION ENDPOINTS

### 3. Create User-Proposed Meetup
**POST** `/lostfound/create_meetup.php`

User proposes a meetup AFTER their claim has been approved. Creates a meetup request pending admin approval.

**Request:**
```json
{
  "claim_id": 1,
  "meetup_date": "2026-05-05",
  "meetup_time": "14:00:00",
  "meetup_location": "Sprague Library"
}
```

**Response (Success):**
```json
{
  "success": true,
  "data": {
    "meetup_id": 1,
    "match_id": 1,
    "claim_id": 1,
    "status": "pending"
  }
}
```

**Requirements:**
- Claim must exist
- Claim must be approved (via `/admin/claims/approve_claim.php`)

**Actions:**
- Creates entry in `lost_found_matches` table
- Creates entry in `lost_found_meetups` table with status 'pending'
- Sends notification emails to both claimant and finder

---

## MEETUP APPROVAL ENDPOINTS

### 4. Approve Meetup Proposal
**POST** `/admin/meetup/approve_meetup.php`

Admin approves a meetup proposal. Users are notified and can proceed to meet.

**Request:**
```json
{
  "meetup_id": 1
}
```

**Response (Success):**
```json
{
  "success": true,
  "data": {
    "meetup_id": 1,
    "type": "lost_found",
    "status": "approved"
  }
}
```

**Actions:**
- Updates `lost_found_meetups` status to 'approved'
- Sends approval email to both users
- Enables resolution confirmation flow

---

### 5. Deny Meetup Proposal
**POST** `/admin/meetup/deny_meetup.php`

Admin denies a meetup proposal. Users must reschedule.

**Request:**
```json
{
  "meetup_id": 1,
  "reason": "Inconvenient location"
}
```

**Response (Success):**
```json
{
  "success": true,
  "data": {
    "meetup_id": 1,
    "type": "lost_found",
    "status": "denied"
  }
}
```

**Actions:**
- Updates `lost_found_meetups` status to 'denied'
- Records denial reason
- Sends denial email to both users
- Users can propose a new meetup

---

## COMPLETE WORKFLOW EXAMPLE

### Scenario: User Claims Found Item

**Step 1:** User claims found item
```bash
POST /listings/lostfound/claim_lostfound.php
{
  "found_item_id": 5,
  "proof_details": "I have the receipt"
}
# Response: claim_id = 1, status = "pending"
```

**Step 2:** Admin approves claim
```bash
POST /admin/claims/approve_claim.php
{
  "claim_id": 1
}
# Response: status = "approved"
# Email sent to claimant
```

**Step 3:** Claimant proposes meetup
```bash
POST /lostfound/create_meetup.php
{
  "claim_id": 1,
  "meetup_date": "2026-05-05",
  "meetup_time": "14:00:00",
  "meetup_location": "Sprague Library"
}
# Response: meetup_id = 1, status = "pending"
# Emails sent to both users
```

**Step 4:** Admin approves meetup
```bash
POST /admin/meetup/approve_meetup.php
{
  "meetup_id": 1
}
# Response: status = "approved"
# Emails sent to both users
```

**Step 5:** Users meet and both confirm resolution (future endpoint)
```bash
POST /lostfound/confirm_resolution.php
{
  "meetup_id": 1,
  "user_id": 4
}
# After both users confirm, item marked as resolved
```

---

## ADMIN MATCHING WORKFLOW

### Admin-Initiated Matching (Future Implementation)

**Step 1:** Admin matches lost item with found item
```bash
POST /admin/lostfound/match.php
{
  "lost_item_id": 3,
  "found_item_id": 5
}
# Creates match and auto-creates meetup request
# Opens chat between users
# Sends emails to both users
```

**Step 2:** Users negotiate meetup and confirm

---

## STATE TRANSITIONS

### Lost/Found Item States
- `pending_approval` → Admin must approve
- `approved` → Public visibility enabled
- `claimed` → User has claimed it (pending approval)
- `claim_approved` → Claim is approved, user can propose meetup
- `meetup_pending` → Meetup proposed, awaiting admin approval
- `meetup_approved` → Approved, users can meet
- `in_progress` → Meetup happening
- `resolved` → Both users confirmed resolution

### Claim States
- `pending` → Initial state
- `approved` → User can propose meetup
- `rejected` → User can retry

### Meetup States
- `pending` → Awaiting admin approval
- `approved` → Users can meet
- `denied` → Users must reschedule
- `completed` → Meeting happened, awaiting resolution

---

## EMAIL NOTIFICATIONS

Emails are sent at:
1. **Claim Approved** - To claimant
2. **Claim Rejected** - To claimant with reason
3. **Meetup Proposed** - To both claimant and finder
4. **Meetup Approved** - To both users with details
5. **Meetup Denied** - To both users with reason
6. **Item Resolved** - To both users confirming completion

---

## ERROR CODES

- `400` - Bad request (missing required fields)
- `404` - Resource not found (claim/meetup doesn't exist)
- `500` - Server error (database error)

---

## NEXT ENDPOINTS TO BUILD

1. **POST** `/admin/lostfound/approve_item.php` - Approve lost/found item submission
2. **POST** `/admin/lostfound/reject_item.php` - Reject item with reason
3. **POST** `/lostfound/confirm_resolution.php` - User marks as resolved
4. **GET** `/lostfound/resolution_status.php` - Check resolution confirmation status
5. **POST** `/lostfound/report_mismatch.php` - Report incorrect match
6. **POST** `/admin/lostfound/unmatch.php` - Admin unmatch items
