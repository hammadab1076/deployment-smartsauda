-- ============================================================
-- Smart Sauda POS — Database Migration (MySQL 8.0 compatible)
-- Run this ONCE in MySQL Workbench on the smart_sauda database
-- ============================================================

USE smart_sauda;

-- ── Helper procedure to safely add a column if it doesn't exist ──────────────
DROP PROCEDURE IF EXISTS _add_col;

DELIMITER $$
CREATE PROCEDURE _add_col(
  IN tbl  VARCHAR(64),
  IN col  VARCHAR(64),
  IN def  TEXT
)
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
    SELECT CONCAT('Added column: ', tbl, '.', col) AS info;
  ELSE
    SELECT CONCAT('Column already exists (skipped): ', tbl, '.', col) AS info;
  END IF;
END$$
DELIMITER ;

-- ── 1. Add optional columns to products ──────────────────────────────────────
CALL _add_col('products', 'type',        "VARCHAR(20) NOT NULL DEFAULT 'single'");
CALL _add_col('products', 'description', 'TEXT');
CALL _add_col('products', 'stock',       'INT NOT NULL DEFAULT 0');
CALL _add_col('products', 'status',      "VARCHAR(20) NOT NULL DEFAULT 'active'");

-- Clean up helper
DROP PROCEDURE IF EXISTS _add_col;

-- ── 2. Suppliers ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS suppliers (
  id             VARCHAR(36)  PRIMARY KEY,
  name           VARCHAR(200) NOT NULL,
  contact_person VARCHAR(100),
  phone          VARCHAR(50),
  email          VARCHAR(100),
  notes          TEXT,
  created_at     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

-- ── 3. Purchase Orders ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS purchase_orders (
  id            VARCHAR(36)   PRIMARY KEY,
  supplier_id   VARCHAR(36),
  supplier_name VARCHAR(200)  NOT NULL,
  date          DATE          NOT NULL,
  items_count   INT           DEFAULT 1,
  total_cost    DECIMAL(10,2) DEFAULT 0,
  status        VARCHAR(20)   DEFAULT 'pending',
  notes         TEXT,
  created_at    TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
);

-- ── 4. Scanners ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS scanners (
  id         VARCHAR(50) PRIMARY KEY,
  port       VARCHAR(20),
  last_seen  TIMESTAMP   NULL,
  created_at TIMESTAMP   DEFAULT CURRENT_TIMESTAMP
);

-- Insert the default scanner (safe to re-run)
INSERT IGNORE INTO scanners (id, port) VALUES ('SCANNER_01', 'COM7');

SELECT 'Migration complete.' AS result;
-- ============================================================
