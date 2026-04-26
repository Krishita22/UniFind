# UniFind Lost & Found System - Current State Analysis

## CURRENT SYSTEM STATE

### Database Tables (Exist)
- `lost_found_items` - Lost/found item listings
- `lost_found_matches` - Manual matches by admin
- `lost_found_meetups` - Meetup proposals (EMPTY - no creation endpoint)
- `lost_found_claims` - User claims on found items
- `users` - User accounts

### Database Tables (Missing per Spec)
- `lost_found_item_approvals` - Track approval status and history
- `claim_approvals` - Track claim approval status
- `meetup_approvals` - Track meetup approval status
- `resolutions` - Track resolution confirmations (both users must confirm)

### API Endpoints (Exist)
- POST `/listings/lostfound/post_lostfound.php` - Submit item
- POST `/listings/lostfound/claim_lostfound.php` - Claim found item
- GET `/listings/lostfound/get_lostfound.php` - Get items
- POST `/admin/meetup/approve_meetup.php` - Approve meetup (BROKEN - assumes meetup exists)
- POST `/admin/meetup/deny_meetup.php` - Deny meetup
- GET `/admin/meetup/get_admin_meetups.php` - Get pending meetups

### API Endpoints (Missing per Spec)
- POST `/admin/lostfound/approve_item.php` - Approve lost/found item
- POST `/admin/lostfound/reject_item.php` - Reject lost/found item
- POST `/admin/claims/approve_claim.php` - Approve user claim
- POST `/admin/claims/reject_claim.php` - Reject user claim
- POST `/lostfound/create_meetup.php` - User proposes meetup (DIFFERENT from admin matching)
- POST `/lostfound/resolve_item.php` - Mark item as resolved (both users)
- POST `/lostfound/report_mismatch.php` - Report incorrect match
- POST `/admin/lostfound/unmatch.php` - Admin unmatch items

### State Management Issues
- No tracking of item approval status (items appear to auto-approve or skip approval)
- No tracking of claim approval status
- Meetup creation is missing - no endpoint for users to propose dates after claim approved
- No resolution confirmation tracking (both users required)
- Messaging/chat system referenced but implementation unclear

### Workflow Gaps vs Specification

#### LOST ITEM SUBMISSION
✗ No approval workflow - items go directly to public?
✗ No rejection notification
✗ No edit/resubmit capability

#### FOUND ITEM SUBMISSION
✗ No approval workflow
✗ No rejection notification
✗ No edit/resubmit capability

#### CLAIM FLOW
✗ Claim approval missing
✗ Chat opening after claim approval missing
✗ User-initiated meetup creation missing
✓ Meetup approval exists but broken
✗ Both-users-must-resolve missing

#### ADMIN MATCHING
✓ Manual matching exists
✗ Email notifications to both users missing
✗ Automatic chat opening missing

#### RESOLUTION
✗ Resolution confirmation system missing
✗ Both-users-must-confirm missing

### Current Issue (Immediate Fix)
**Meetup exists in UI but not in database** because:
1. `get_admin_meetups.php` queries both `meetups` (marketplace) and `lost_found_meetups` (lost & found)
2. `lost_found_meetups` table is EMPTY
3. There's no endpoint for users to CREATE a meetup after claim approval
4. Meetups can only come from:
   - Admin manual match (should create meetup automatically)
   - User proposal after claim approved (MISSING)

## IMMEDIATE FIX STRATEGY

1. Create the missing `POST /lostfound/create_meetup.php` endpoint
2. Ensure meetup is created through proper workflow:
   - User claims found item → Claim must be approved by admin → User can then propose meetup
3. Test the complete chain:
   - Claim exists and approved
   - User proposes meetup with date/time
   - Admin approves meetup
   - Users can then approve/deny

## BUILD PLAN (Per Specification)

### Phase 1: Database Schema
- [ ] Add `lost_found_item_approvals` table
- [ ] Add `claim_approvals` table
- [ ] Add `meetup_approvals` table
- [ ] Add `resolutions` table
- [ ] Update `lost_found_items` state enum

### Phase 2: Item Approval Workflow
- [ ] POST `/admin/lostfound/approve_item.php`
- [ ] POST `/admin/lostfound/reject_item.php`
- [ ] Email notifications on approval/rejection

### Phase 3: Claim Approval Workflow
- [ ] Update POST `/listings/lostfound/claim_lostfound.php` to create claim in pending state
- [ ] POST `/admin/claims/approve_claim.php` - Opens chat, notifies user
- [ ] POST `/admin/claims/reject_claim.php` - Email notification

### Phase 4: User-Initiated Meetup Creation
- [ ] POST `/lostfound/create_meetup.php` - User proposes meetup (requires approved claim)
- [ ] Fix POST `/admin/meetup/approve_meetup.php`
- [ ] Fix POST `/admin/meetup/deny_meetup.php`

### Phase 5: Admin Matching Workflow
- [ ] Ensure admin matching creates meetup automatically
- [ ] Send email notifications to both users
- [ ] Open chat automatically

### Phase 6: Resolution System
- [ ] POST `/lostfound/confirm_resolution.php` - Mark as resolved (user)
- [ ] GET `/lostfound/resolution_status.php` - Check both-user confirmation
- [ ] Email notification when resolved

### Phase 7: Mismatch Handling
- [ ] POST `/lostfound/report_mismatch.php` - User reports wrong match
- [ ] POST `/admin/lostfound/unmatch.php` - Admin unmatch

---

## CURRENT BLOCKER

The immediate issue is that meetups are being loaded from `get_admin_meetups.php` but the `lost_found_meetups` table is empty because:
- There's no user-initiated meetup creation endpoint
- The only way to create meetups should be:
  1. After user claim is approved → user proposes meetup
  2. Admin manual match → system creates meetup automatically

Once we add the `POST /lostfound/create_meetup.php` endpoint and trace through a complete workflow, the approve/deny endpoints will work properly.
