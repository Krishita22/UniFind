<?php
// respond_offer.php — resolve a pending offer (accept / reject / withdraw).
//
// Rules:
//   accept   : caller must be the offer's recipient. On success, other pending
//              offers on the same listing are flipped to 'superseded'.
//   reject   : caller must be the offer's recipient.
//   withdraw : caller must be the offer's sender (retract your own offer).
//
// Request (JSON):
//   { "offer_id": int, "user_id": int,
//     "action": "accept"|"reject"|"withdraw" }

declare(strict_types=1);
require_once __DIR__ . '/../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

if (!function_exists('api_success')) {
    function api_success($data) { header('Content-Type: application/json'); echo json_encode(['success' => true, 'data' => $data]); exit; }
    function api_error(string $message, int $status = 400) { http_response_code($status); header('Content-Type: application/json'); echo json_encode(['success' => false, 'error' => $message]); exit; }
    function api_body(): array { $raw = file_get_contents('php://input'); if ($raw === false || $raw === '') return []; $decoded = json_decode($raw, true); return is_array($decoded) ? $decoded : []; }
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') api_error('Method not allowed.', 405);

$body    = api_body();
$offerId = (int)($body['offer_id'] ?? 0);
$userId  = (int)($body['user_id'] ?? 0);
$action  = strtolower(trim((string)($body['action'] ?? '')));

if ($offerId <= 0 || $userId <= 0) api_error('offer_id and user_id are required.', 400);
if (!in_array($action, ['accept', 'reject', 'withdraw'], true)) {
    api_error('action must be one of: accept, reject, withdraw.', 400);
}

$look = $conn->prepare(
    'SELECT id, listing_id, sender_id, recipient_id, status
     FROM offers WHERE id = ? LIMIT 1'
);
if (!$look) api_error('Server error.', 500);
$look->bind_param('i', $offerId);
$look->execute();
$offer = $look->get_result()->fetch_assoc();
$look->close();

if (!$offer) api_error('Offer not found.', 404);
if ($offer['status'] !== 'pending') {
    api_error('Offer is no longer pending (current status: ' . $offer['status'] . ').', 409);
}

if ($action === 'withdraw') {
    if ((int)$offer['sender_id'] !== $userId) {
        api_error('Only the sender of an offer can withdraw it.', 403);
    }
} else {
    if ((int)$offer['recipient_id'] !== $userId) {
        api_error('Only the recipient of an offer can ' . $action . ' it.', 403);
    }
}

$newStatus = [
    'accept'   => 'accepted',
    'reject'   => 'rejected',
    'withdraw' => 'withdrawn',
][$action];

$listingId  = (int)$offer['listing_id'];
$superseded = 0;

$conn->begin_transaction();
try {
    $upd = $conn->prepare(
        "UPDATE offers SET status = ?, responded_at = NOW()
         WHERE id = ? AND status = 'pending'"
    );
    if (!$upd) throw new RuntimeException('prepare(settle) failed: ' . $conn->error);
    $upd->bind_param('si', $newStatus, $offerId);
    if (!$upd->execute()) throw new RuntimeException('exec(settle) failed: ' . $upd->error);
    $affected = $upd->affected_rows;
    $upd->close();
    if ($affected !== 1) {
        $conn->rollback();
        api_error('Offer is no longer pending.', 409);
    }

    if ($action === 'accept') {
        // Other pending offers on this listing from unrelated threads are
        // now moot. Don't touch 'countered' rows or already-terminal rows.
        $sup = $conn->prepare(
            "UPDATE offers SET status = 'superseded', responded_at = NOW()
             WHERE listing_id = ? AND status = 'pending' AND id <> ?"
        );
        if (!$sup) throw new RuntimeException('prepare(supersede) failed: ' . $conn->error);
        $sup->bind_param('ii', $listingId, $offerId);
        if (!$sup->execute()) throw new RuntimeException('exec(supersede) failed: ' . $sup->error);
        $superseded = $sup->affected_rows;
        $sup->close();
    }

    $conn->commit();
} catch (Throwable $e) {
    $conn->rollback();
    error_log('respond_offer: ' . $e->getMessage());
    api_error('Failed to update offer.', 500);
}

api_success([
    'id'               => $offerId,
    'status'           => $newStatus,
    'superseded_count' => $superseded,
]);
