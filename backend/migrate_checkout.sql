-- ============================================================
-- Smart Sauda — Checkout Migration (MySQL 8.0 compatible)
-- Run ONCE in MySQL Workbench on the smart_sauda database
-- ============================================================

USE smart_sauda;

DROP PROCEDURE IF EXISTS _checkout_col;

DELIMITER $$
CREATE PROCEDURE _checkout_col(IN tbl VARCHAR(64), IN col VARCHAR(64), IN def TEXT)
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = tbl
      AND COLUMN_NAME  = col
  ) THEN
    SET @sql = CONCAT('ALTER TABLE `', tbl, '` ADD COLUMN `', col, '` ', def);
    PREPARE s FROM @sql;
    EXECUTE s;
    DEALLOCATE PREPARE s;
    SELECT CONCAT('Added: ', tbl, '.', col) AS info;
  ELSE
    SELECT CONCAT('Exists (skipped): ', tbl, '.', col) AS info;
  END IF;
END$$
DELIMITER ;

-- Add payment_method to carts so we can record how the customer paid
CALL _checkout_col('carts', 'payment_method', "VARCHAR(50) NULL");

DROP PROCEDURE IF EXISTS _checkout_col;

SELECT 'Checkout migration complete.' AS result;
