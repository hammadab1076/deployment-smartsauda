-- ============================================================
-- Smart Sauda — Fix carts.status column size
-- Run in MySQL Workbench on the smart_sauda database
-- ============================================================

USE smart_sauda;

-- Expand status column to hold all new status values:
-- 'active', 'checkout_requested'(18), 'bill_generated'(14), 'paid', 'completed', 'abandoned'
ALTER TABLE carts MODIFY COLUMN status VARCHAR(50) NOT NULL DEFAULT 'active';

SELECT 'Column fix applied.' AS result;
