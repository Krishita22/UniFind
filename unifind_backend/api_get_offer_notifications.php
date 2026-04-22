<?php
// upload as: offers/get_offer_notifications.php
//
// Returns the count of unseen "offer events" for a given user. An event is
// anything the user should see a badge for:
//
//   1. PENDING RECEIVED  — an offer where the user is the recipient and
//                          status='pending' and seen_at IS NULL. Covers both
//                          fresh openers from buyers and counters sent by
//                          the other side (since a counter is itself a new
//                          pending offer with the counterparty flipped).
//
//   2. RESPONSE TO SENT  — an offer where the user is the sender, the status
//                          is terminal-or-countered (accepted/rejected/
//                          countered/withdrawn/superseded — i.e. not
//                          'pending'), AND the response landed after the
//                          user last marked the thread seen.
//
// Response (JSON):
//   { "success": true,
//     "data": {
//       "count":       int,     // total unseen events (badge value)
//       "pending_received": int,
//       "responses_to_sent": int
//     }
//   }
//
// Safe to call frequently — the app polls this every few seconds alongside
// the message unread-count check.

declare(strict_types=1);
require_once __DIR__ . '/../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
}

$userId = (int)($_GET['user_id'] ?? 0);
if ($userId <= 0) api_error('user_id required.', 400);

// Guard: if the seen_at column doesn't exist yet (migration 003 not applied),
// return zeros rather than 500. Keeps the app working during partial deploy.
$check = $conn->query(
    "SELECT COUNT(*) AS n FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE()
       AND TABLE_NAME   = 'offers'
       AND COLUMN_NAME  = 'seen_at'"
);
$hasSeen = $check && (int)($check->fetch_assoc()['n'] ?? 0) === 1;
if (!$hasSeen) {
    api_success(['count' => 0, 'pending_received' => 0, 'responses_to_sent' => 0]);
}

// 1. pending offers you received and haven't seen
$stmtA = $conn->prepare(
    "SELECT COUNT(*) AS n FROM offers
     WHERE recipient_id = ? AND status = 'pending' AND seen_at IS NULL"
);
if (!$stmtA) api_error('Server error.', 500);
$stmtA->bind_param('i', $userId);
$stmtA->execute();
$pendingReceived = (int)($stmtA->get_result()->fetch_assoc()['n'] ?? 0);
$stmtA->close();

// 2. responses to offers you sent, not yet seen. Unseen means seen_at IS NULL
//    or seen_at < responded_at (the latter covers the case where the user
//    saw the offer while it was pending, then the other side responded).
$stmtB = $conn->prepare(
    "SELECT COUNT(*) AS n FROM offers
     WHERE sender_id = ?
       AND status <> 'pending'
       AND responded_at IS NOT NULL
       AND (seen_at IS NULL OR seen_at < responded_at)"
);
if (!$stmtB) api_error('Server error.', 500);
$stmtB->bind_param('i', $userId);
$stmtB->execute();
$responsesToSent = (int)($stmtB->get_result()->fetch_assoc()['n'] ?? 0);
$stmtB->close();

api_success([
    'count'             => $pendingReceived + $responsesToSent,
    'pending_received'  => $pendingReceived,
    'responses_to_sent' => $responsesToSent,
]);
