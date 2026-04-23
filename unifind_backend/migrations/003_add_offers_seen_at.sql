-- Migration 003: add seen_at column to offers for notification tracking.
--
-- Run once on existing deployments:
--   mysql -u <user> -p <database> < migrations/003_add_offers_seen_at.sql
--
-- Safe to re-run: the ADD COLUMN is wrapped so it no-ops when the column
-- already exists.
--
-- `seen_at` drives the "you have N new offer events" badge on the Offers tab.
-- An offer "event" is anything the user should be told about:
--   - a pending offer you received           (you are recipient, status=pending)
--   - a response to an offer you sent        (you are sender, status is terminal
--     or countered, and responded_at > seen_at)
-- Whenever the user opens the Offers tab (or resolves an offer via
-- accept/reject/counter/withdraw) the app calls mark_offers_seen.php which
-- sets seen_at = NOW() on every row that matches the above predicates for
-- that user, clearing the badge.

SET @col_exists := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME   = 'offers'
    AND COLUMN_NAME  = 'seen_at'
);

SET @ddl := IF(
  @col_exists = 0,
  'ALTER TABLE offers ADD COLUMN seen_at DATETIME NULL AFTER responded_at',
  'SELECT 1'
);

PREPARE stmt FROM @ddl;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
