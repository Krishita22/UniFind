<?php
/**
 * Schedule: Run daily at 3:00 AM
 * Cron expression: 0 3 * * *
 *
 * Setup on cPanel:
 *   
 * 
 * Command: /usr/local/bin/php /home/ivanovs1/public_html/UniFind_API/cleanup_cron.php >> /home/ivanovs1/logs/cleanup.log 2>&1
 *   
 * Schedule: 0 3 * * *
 *   
 */

// ─────────────────────────────────────────────
// BOOTSTRAP — reuse existing DB connection
// ─────────────────────────────────────────────
require_once __DIR__ . '/config.php';
// $conn is now available (mysqli)

// ─────────────────────────────────────────────
// EMAIL CONFIG
// ─────────────────────────────────────────────
$mail_from   = 'unifind@ivanovs1.nodomain';
$app_name    = 'UniFind';
$support_url = 'http://cyan.csam.montclair.edu/~ivanovs1/Unifind/';

// ─────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────
function log_cleanup(string $label, int $rows): void {
    $ts = date('Y-m-d H:i:s');
    echo "[$ts] Deleted $rows row(s) from $label\n";
}

function log_info(string $msg): void {
    $ts = date('Y-m-d H:i:s');
    echo "[$ts] $msg\n";
}

function db_delete(mysqli $conn, string $sql): int {
    $result = $conn->query($sql);
    if ($result === false) {
        $ts = date('Y-m-d H:i:s');
        echo "[$ts] SQL ERROR: " . $conn->error . " | Query: $sql\n";
        return 0;
    }
    return $conn->affected_rows;
}

function send_email(string $to, string $subject, string $body, string $from): void {
    $headers  = "From: $from\r\n";
    $headers .= "Content-Type: text/plain; charset=UTF-8\r\n";
    $headers .= "MIME-Version: 1.0\r\n";
    if (!mail($to, $subject, $body, $headers)) {
        $ts = date('Y-m-d H:i:s');
        echo "[$ts] WARNING: Failed to send email to $to\n";
    }
}

$total_deleted = 0;
$current_year  = (int) date('Y');
$today_date    = date('Y-m-d');
$month_day     = date('m-d');

// ─────────────────────────────────────────────
// 1. admin_activity_log — remove after 7 days
// ─────────────────────────────────────────────
$rows = db_delete($conn, "DELETE FROM admin_activity_log WHERE created_at < NOW() - INTERVAL 7 DAY");
log_cleanup('admin_activity_log', $rows);
$total_deleted += $rows;

// ─────────────────────────────────────────────
// 2. bug_reports — DO NOT REMOVE
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// 3. claim_approvals — remove after 60 days
// ─────────────────────────────────────────────
$rows = db_delete($conn, "DELETE FROM claim_approvals WHERE created_at < NOW() - INTERVAL 60 DAY");
log_cleanup('claim_approvals', $rows);
$total_deleted += $rows;

// ─────────────────────────────────────────────
// 4. conversations — remove after 7 days of being completed
// ─────────────────────────────────────────────
$rows = db_delete($conn, "
    DELETE FROM conversations
    WHERE is_complete = 1
      AND completed_at IS NOT NULL
      AND completed_at < NOW() - INTERVAL 7 DAY
");
log_cleanup('conversations', $rows);
$total_deleted += $rows;

// ─────────────────────────────────────────────
// 5. email_blacklist — DO NOT REMOVE
// ─────────────────────────────────────────────

// ─────────────────────────────────────────────
// 6. email_verification_codes — remove 1 hour after expiration
// ─────────────────────────────────────────────
$rows = db_delete($conn, "DELETE FROM email_verification_codes WHERE expires_at < NOW() - INTERVAL 1 HOUR");
log_cleanup('email_verification_codes', $rows);
$total_deleted += $rows;

// ─────────────────────────────────────────────
// 7. lost_found_claims — remove after 60 days if approved or rejected
// ─────────────────────────────────────────────
$rows = db_delete($conn, "
    DELETE FROM lost_found_claims
    WHERE status IN ('approved', 'rejected')
      AND created_at < NOW() - INTERVAL 60 DAY
");
log_cleanup('lost_found_claims', $rows);
$total_deleted += $rows;

// ─────────────────────────────────────────────
// 8. lost_found_items
//    active → 14 days  |  resolved/denied → 7 days
// ─────────────────────────────────────────────
$rows = db_delete($conn, "
    DELETE FROM lost_found_items
    WHERE status = 'active'
      AND created_at < NOW() - INTERVAL 14 DAY
");
log_cleanup('lost_found_items (active)', $rows);
$total_deleted += $rows;

$rows = db_delete($conn, "
    DELETE FROM lost_found_items
    WHERE status IN ('resolved', 'denied')
      AND created_at < NOW() - INTERVAL 7 DAY
");
log_cleanup('lost_found_items (resolved/denied)', $rows);
$total_deleted += $rows;

// 9.  lost_found_item_approvals   — NOT IN USE
// 10. lost_found_mismatch_reports — NOT IN USE
// 11. lost_found_resolutions      — NOT IN USE

// ─────────────────────────────────────────────
// 12. lost_found_matches — remove after 60 days
// ─────────────────────────────────────────────
$rows = db_delete($conn, "DELETE FROM lost_found_matches WHERE created_at < NOW() - INTERVAL 60 DAY");
log_cleanup('lost_found_matches', $rows);
$total_deleted += $rows;

// ─────────────────────────────────────────────
// 13. lost_found_meetups — remove after 7 days if completed
// ─────────────────────────────────────────────
$rows = db_delete($conn, "
    DELETE FROM lost_found_meetups
    WHERE status = 'completed'
      AND created_at < NOW() - INTERVAL 7 DAY
");
log_cleanup('lost_found_meetups', $rows);
$total_deleted += $rows;

// ─────────────────────────────────────────────
// 14. marketplace_items
//    active → 14 days  |  sold/denied → 7 days
// ─────────────────────────────────────────────
$rows = db_delete($conn, "
    DELETE FROM marketplace_items
    WHERE status = 'active'
      AND created_at < NOW() - INTERVAL 14 DAY
");
log_cleanup('marketplace_items (active)', $rows);
$total_deleted += $rows;

$rows = db_delete($conn, "
    DELETE FROM marketplace_items
    WHERE status IN ('sold', 'denied')
      AND created_at < NOW() - INTERVAL 7 DAY
");
log_cleanup('marketplace_items (sold/denied)', $rows);
$total_deleted += $rows;

// ─────────────────────────────────────────────
// 15. matches — remove after 60 days if resolved
// ─────────────────────────────────────────────
$rows = db_delete($conn, "DELETE FROM matches WHERE status = 'resolved' AND created_at < NOW() - INTERVAL 60 DAY");
log_cleanup('matches', $rows);
$total_deleted += $rows;

// ─────────────────────────────────────────────
// 16. meetups — remove after 7 days if completed
// ─────────────────────────────────────────────
$rows = db_delete($conn, "DELETE FROM meetups WHERE status = 'completed' AND created_at < NOW() - INTERVAL 7 DAY");
log_cleanup('meetups', $rows);
$total_deleted += $rows;

// 17. meetup_approvals — NOT IN USE

// ─────────────────────────────────────────────
// 18. messages — remove after 60 days
// ─────────────────────────────────────────────
$rows = db_delete($conn, "DELETE FROM messages WHERE sent_at < NOW() - INTERVAL 60 DAY");
log_cleanup('messages', $rows);
$total_deleted += $rows;

// ─────────────────────────────────────────────
// 19. offers — remove after 60 days
// ─────────────────────────────────────────────
$rows = db_delete($conn, "DELETE FROM offers WHERE created_at < NOW() - INTERVAL 60 DAY");
log_cleanup('offers', $rows);
$total_deleted += $rows;

// ─────────────────────────────────────────────
// 20. password_reset_codes — remove 1 hour after expiration
// ─────────────────────────────────────────────
$rows = db_delete($conn, "DELETE FROM password_reset_codes WHERE expires_at < NOW() - INTERVAL 1 HOUR");
log_cleanup('password_reset_codes', $rows);
$total_deleted += $rows;

// ─────────────────────────────────────────────
// 21. payment_offers — remove after 7 days if completed/refunded/cancelled
// ─────────────────────────────────────────────
$rows = db_delete($conn, "
    DELETE FROM payment_offers
    WHERE status IN ('completed', 'refunded', 'cancelled')
      AND updated_at < NOW() - INTERVAL 7 DAY
");
log_cleanup('payment_offers', $rows);
$total_deleted += $rows;

// 22. ratings — DO NOT REMOVE

// ─────────────────────────────────────────────
// 23. reports — remove 7 days after resolved_at
// ─────────────────────────────────────────────
$rows = db_delete($conn, "
    DELETE FROM reports
    WHERE is_resolved = 1
      AND resolved_at IS NOT NULL
      AND resolved_at < NOW() - INTERVAL 7 DAY
");
log_cleanup('reports', $rows);
$total_deleted += $rows;

// ─────────────────────────────────────────────
// 24. users — STUDENTS ONLY
//
// Email timeline per student:
//   Dec 1–31 of graduation year → warning: "account deletes Dec 31, YYYY"
//   Jan 1–30 of next year       → final notice: "account deletes Jan 30, YYYY"
//   After Jan 30                → account deleted from DB
//
// Faculty cleanup is deferred to a later phase.
// ─────────────────────────────────────────────
$grace_end_date = "{$current_year}-01-30";

// 24a. Warning email — students graduating THIS year (runs Dec 1–31)
if ($month_day >= '12-01' && $month_day <= '12-31') {
    $result = $conn->query("
        SELECT id, email, first_name, last_name, graduation_year
        FROM users
        WHERE role = 'student'
          AND graduation_year = {$current_year}
          AND email IS NOT NULL
    ");
    if ($result) {
        while ($s = $result->fetch_assoc()) {
            $delete_date = "December 31, {$current_year}";
            $name        = trim($s['first_name'] . ' ' . $s['last_name']);
            $subject     = "[$app_name] Your account will be deleted on $delete_date";
            $body =
                "Hi $name,\n\n"
                . "This is an automated notice from $app_name at Montclair State University.\n\n"
                . "Our records show that you are graduating in {$s['graduation_year']}. As part of our student "
                . "account policy, your $app_name account — including your listings, messages, and profile — "
                . "will be permanently deleted on $delete_date.\n\n"
                . "If you believe this is a mistake or have any questions, please visit:\n$support_url\n\n"
                . "Thank you for being part of $app_name, and congratulations on your upcoming graduation!\n\n"
                . "— The $app_name Team";

            send_email($s['email'], $subject, $body, $mail_from);
            log_info("Sent Dec warning to {$s['email']} (class of {$s['graduation_year']})");
        }
        $result->free();
    }
}

// 24b. Final notice — already-graduated students still in grace period (Jan 1–30)
if ($today_date >= "{$current_year}-01-01" && $today_date <= $grace_end_date) {
    $result = $conn->query("
        SELECT id, email, first_name, last_name, graduation_year
        FROM users
        WHERE role = 'student'
          AND graduation_year IS NOT NULL
          AND graduation_year < {$current_year}
          AND email IS NOT NULL
    ");
    if ($result) {
        while ($s = $result->fetch_assoc()) {
            $delete_date = "January 30, {$current_year}";
            $name        = trim($s['first_name'] . ' ' . $s['last_name']);
            $subject     = "[$app_name] Final notice — your account will be deleted on $delete_date";
            $body =
                "Hi $name,\n\n"
                . "This is a final notice from $app_name at Montclair State University.\n\n"
                . "Your graduation year was {$s['graduation_year']}. Your $app_name account is scheduled to be "
                . "permanently deleted on $delete_date as part of our student account policy.\n\n"
                . "After this date, your account, listings, messages, and profile will no longer be recoverable.\n\n"
                . "If you believe this is a mistake or have any questions, please visit:\n$support_url\n\n"
                . "— The $app_name Team";

            send_email($s['email'], $subject, $body, $mail_from);
            log_info("Sent final notice to {$s['email']} (class of {$s['graduation_year']})");
        }
        $result->free();
    }
}

// 24c. Delete graduated students after Jan 30 grace period
if ($today_date > $grace_end_date) {
    $rows = db_delete($conn, "
        DELETE FROM users
        WHERE role = 'student'
          AND graduation_year IS NOT NULL
          AND graduation_year < {$current_year}
    ");
    log_cleanup('users (graduated students)', $rows);
    $total_deleted += $rows;
} else {
    log_info("Skipping student deletion — grace period active until $grace_end_date");
}

// 25. user_warnings — DO NOT REMOVE

// ─────────────────────────────────────────────
// CLOSE CONNECTION & SUMMARY
// ─────────────────────────────────────────────
$conn->close();

log_info("Cleanup complete. Total rows deleted: $total_deleted");
echo str_repeat('-', 60) . "\n";