-- Smart Sauda — Add total_amount to audits table
USE smart_sauda;
ALTER TABLE audits ADD COLUMN IF NOT EXISTS total_amount DECIMAL(10,2) NULL;
SELECT 'Audit total_amount column added.' AS result;
