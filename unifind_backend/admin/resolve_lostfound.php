<?php
declare(strict_types=1);
require_once __DIR__ . '/../api_helpers.php';
if ($_SERVER['REQUEST_METHOD'] !== 'POST') api_error('Method not allowed.', 405);

$body   = api_body();
$itemId = (int)($body['item_id'] ?? 0);
if ($itemId <= 0) api_error('item_id required.', 400);

// Verify item exists
$iStmt = $conn->prepare('SELECT id FROM lost_found_items WHERE id = ? LIMIT 1');
if (!$iStmt) api_error('Server error.', 500);
$iStmt->bind_param('i', $itemId);
$iStmt->execute();
$item = $iStmt->get_result()->fetch_assoc();
$iStmt->close();
if (!$item) api_error('Item not found.', 404);

// Mark as resolved
$upd = $conn->prepare('UPDATE lost_found_items SET status = "resolved" WHERE id = ?');
if (!$upd) api_error('Server error.', 500);
$upd->bind_param('i', $itemId);
if (!$upd->execute()) api_error('Failed to resolve item.', 500);
$upd->close();

api_success(['item_id' => $itemId, 'status' => 'resolved']);
