-- =============================================================
-- Smart Sauda - Complete MySQL Database Schema
-- App: Smart Sauda grocery shopping system (Flutter + Firebase)
-- Mirrors: users, products (A+B), carts, orders, audits, invoices
-- =============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- -------------------------------------------------------------
-- DATABASE
-- -------------------------------------------------------------
DROP DATABASE IF EXISTS smart_sauda;
CREATE DATABASE smart_sauda
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE smart_sauda;

-- =============================================================
-- TABLE 1: users
-- Mirrors: Firestore 'users' collection
-- Roles: customer | auditor | admin
-- =============================================================
CREATE TABLE users (
    id            VARCHAR(36)  NOT NULL,
    name          VARCHAR(255) NOT NULL,
    email         VARCHAR(255) NOT NULL,
    phone         VARCHAR(20)  NULL,
    password_hash VARCHAR(255) NOT NULL DEFAULT '',
    role          ENUM('customer','auditor','admin') NOT NULL,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_users PRIMARY KEY (id),
    CONSTRAINT uq_users_email UNIQUE (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_users_role     ON users (role);
CREATE INDEX idx_users_active   ON users (is_active);

-- =============================================================
-- TABLE 2: products
-- Mirrors: Firestore 'productA' + 'productB' collections
-- collection_src tracks which original Firestore collection
-- =============================================================
CREATE TABLE products (
    id              VARCHAR(36)  NOT NULL,
    name            VARCHAR(255) NOT NULL,
    price           DECIMAL(10,2) NOT NULL,
    image_url       VARCHAR(500)  NULL,
    barcode         VARCHAR(50)   NOT NULL,
    nfc_tag_id      VARCHAR(50)   NULL,
    description     TEXT          NULL,
    category        VARCHAR(100)  NOT NULL DEFAULT 'Miscellaneous',
    collection_src  ENUM('productA','productB') NOT NULL,
    created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_products PRIMARY KEY (id),
    CONSTRAINT uq_products_barcode   UNIQUE (barcode),
    CONSTRAINT uq_products_nfc_tag   UNIQUE (nfc_tag_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_products_category  ON products (category);
CREATE INDEX idx_products_barcode   ON products (barcode);
CREATE INDEX idx_products_nfc_tag   ON products (nfc_tag_id);

-- =============================================================
-- TABLE 3: carts
-- Mirrors: Firestore 'carts' collection
-- Real-time sync channel between Customer and Auditor apps
-- id format: CART_{millisecondsSinceEpoch}
-- =============================================================
CREATE TABLE carts (
    id           VARCHAR(100) NOT NULL,
    user_id      VARCHAR(36)  NOT NULL,
    status       ENUM('active','awaiting_audit','auditing','completed','abandoned') NOT NULL DEFAULT 'active',
    scanner_id   VARCHAR(50)  NULL,
    qr_code      VARCHAR(255) NULL,
    created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_updated TIMESTAMP    NULL,
    completed_at TIMESTAMP    NULL,
    CONSTRAINT pk_carts PRIMARY KEY (id),
    CONSTRAINT uq_carts_qr_code UNIQUE (qr_code),
    CONSTRAINT fk_carts_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_carts_user_id  ON carts (user_id);
CREATE INDEX idx_carts_status   ON carts (status);
CREATE INDEX idx_carts_scanner  ON carts (scanner_id);

-- =============================================================
-- TABLE 4: cart_items
-- Normalizes the embedded 'items' array from Firestore carts
-- is_verified: set TRUE by auditor during audit session
-- =============================================================
CREATE TABLE cart_items (
    id           INT          NOT NULL AUTO_INCREMENT,
    cart_id      VARCHAR(100) NOT NULL,
    product_id   VARCHAR(36)  NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    price        DECIMAL(10,2) NOT NULL,
    category     VARCHAR(100) NOT NULL,
    is_verified  BOOLEAN      NOT NULL DEFAULT FALSE,
    added_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    verified_at  TIMESTAMP    NULL,
    verified_by  VARCHAR(36)  NULL,
    CONSTRAINT pk_cart_items PRIMARY KEY (id),
    CONSTRAINT fk_cart_items_cart    FOREIGN KEY (cart_id)    REFERENCES carts    (id)  ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_cart_items_product FOREIGN KEY (product_id) REFERENCES products (id)  ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_cart_items_auditor FOREIGN KEY (verified_by) REFERENCES users   (id)  ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_cart_items_cart_id    ON cart_items (cart_id);
CREATE INDEX idx_cart_items_product_id ON cart_items (product_id);
CREATE INDEX idx_cart_items_verified   ON cart_items (is_verified);

-- =============================================================
-- TABLE 5: orders
-- Mirrors: Firestore 'orders' collection
-- Created by processPayment() after successful checkout
-- =============================================================
CREATE TABLE orders (
    id           VARCHAR(36)   NOT NULL,
    user_id      VARCHAR(36)   NOT NULL,
    cart_id      VARCHAR(100)  NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    status       ENUM('pending','completed','cancelled') NOT NULL DEFAULT 'completed',
    created_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_orders PRIMARY KEY (id),
    CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users  (id)   ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_orders_cart FOREIGN KEY (cart_id) REFERENCES carts  (id)   ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_orders_user_id    ON orders (user_id);
CREATE INDEX idx_orders_created_at ON orders (created_at);
CREATE INDEX idx_orders_status     ON orders (status);

-- =============================================================
-- TABLE 6: order_items
-- Normalizes the embedded 'items' array from Firestore orders
-- product_name + unit_price stored as historical snapshots
-- =============================================================
CREATE TABLE order_items (
    id           INT           NOT NULL AUTO_INCREMENT,
    order_id     VARCHAR(36)   NOT NULL,
    product_id   VARCHAR(36)   NOT NULL,
    product_name VARCHAR(255)  NOT NULL,
    quantity     INT           NOT NULL DEFAULT 1,
    unit_price   DECIMAL(10,2) NOT NULL,
    subtotal     DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    CONSTRAINT pk_order_items PRIMARY KEY (id),
    CONSTRAINT fk_order_items_order   FOREIGN KEY (order_id)   REFERENCES orders   (id) ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_order_items_order_id   ON order_items (order_id);
CREATE INDEX idx_order_items_product_id ON order_items (product_id);

-- =============================================================
-- TABLE 7: audits
-- Mirrors: Firestore 'audits' collection
-- One audit record per completed cart session
-- =============================================================
CREATE TABLE audits (
    id                  VARCHAR(36)  NOT NULL,
    cart_id             VARCHAR(100) NOT NULL,
    auditor_id          VARCHAR(36)  NOT NULL,
    total_items         INT          NOT NULL DEFAULT 0,
    verified_items      INT          NOT NULL DEFAULT 0,
    discrepancies_count INT          NOT NULL DEFAULT 0,
    status              ENUM('pending','verified','flagged') NOT NULL DEFAULT 'pending',
    notes               TEXT         NULL,
    created_at          TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at        TIMESTAMP    NULL,
    CONSTRAINT pk_audits PRIMARY KEY (id),
    CONSTRAINT fk_audits_cart    FOREIGN KEY (cart_id)    REFERENCES carts (id)  ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_audits_auditor FOREIGN KEY (auditor_id) REFERENCES users (id)  ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_audits_cart_id    ON audits (cart_id);
CREATE INDEX idx_audits_auditor_id ON audits (auditor_id);
CREATE INDEX idx_audits_status     ON audits (status);
CREATE INDEX idx_audits_created_at ON audits (created_at);

-- =============================================================
-- TABLE 8: audit_items
-- Tracks per-item verification outcome during each audit
-- verification_method: nfc | barcode | manual
-- =============================================================
CREATE TABLE audit_items (
    id                  INT          NOT NULL AUTO_INCREMENT,
    audit_id            VARCHAR(36)  NOT NULL,
    cart_item_id        INT          NOT NULL,
    product_id          VARCHAR(36)  NOT NULL,
    product_name        VARCHAR(255) NOT NULL,
    price               DECIMAL(10,2) NOT NULL,
    verification_method ENUM('nfc','barcode','manual') NOT NULL DEFAULT 'manual',
    is_verified         BOOLEAN      NOT NULL DEFAULT FALSE,
    verified_at         TIMESTAMP    NULL,
    CONSTRAINT pk_audit_items PRIMARY KEY (id),
    CONSTRAINT fk_audit_items_audit     FOREIGN KEY (audit_id)     REFERENCES audits     (id) ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_audit_items_cart_item FOREIGN KEY (cart_item_id) REFERENCES cart_items (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_audit_items_product   FOREIGN KEY (product_id)   REFERENCES products   (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_audit_items_audit_id ON audit_items (audit_id);

-- =============================================================
-- TABLE 9: invoices
-- One invoice per completed order
-- id format: INV-{first 8 chars of order_id}
-- =============================================================
CREATE TABLE invoices (
    id            VARCHAR(50)   NOT NULL,
    order_id      VARCHAR(36)   NOT NULL,
    user_id       VARCHAR(36)   NOT NULL,
    total_amount  DECIMAL(12,2) NOT NULL,
    item_count    INT           NOT NULL DEFAULT 0,
    status        ENUM('generated','sent','paid') NOT NULL DEFAULT 'generated',
    created_at    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    downloaded_at TIMESTAMP     NULL,
    CONSTRAINT pk_invoices PRIMARY KEY (id),
    CONSTRAINT uq_invoices_order UNIQUE (order_id),
    CONSTRAINT fk_invoices_order FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_invoices_user  FOREIGN KEY (user_id)  REFERENCES users  (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_invoices_user_id    ON invoices (user_id);
CREATE INDEX idx_invoices_created_at ON invoices (created_at);
CREATE INDEX idx_invoices_status     ON invoices (status);

-- =============================================================
-- TABLE 10: daily_stats
-- Pre-aggregated admin dashboard stats (one row per day)
-- Powers: AdminDashboard, SalesAnalyticsScreen, AllInvoicesScreen
-- =============================================================
CREATE TABLE daily_stats (
    id             INT           NOT NULL AUTO_INCREMENT,
    stat_date      DATE          NOT NULL,
    todays_sales   DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    todays_orders  INT           NOT NULL DEFAULT 0,
    total_revenue  DECIMAL(14,2) NOT NULL DEFAULT 0.00,
    average_order  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    active_users   INT           NOT NULL DEFAULT 0,
    total_invoices INT           NOT NULL DEFAULT 0,
    created_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_daily_stats PRIMARY KEY (id),
    CONSTRAINT uq_daily_stats_date UNIQUE (stat_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================
-- VIEWS
-- =============================================================

-- View 1: v_order_summary
-- Powers: AllInvoicesScreen — shows invoice list with customer info
CREATE OR REPLACE VIEW v_order_summary AS
SELECT
    o.id                                        AS order_id,
    CONCAT('INV-', LEFT(o.id, 8))              AS invoice_id,
    u.name                                      AS customer_name,
    u.email                                     AS customer_email,
    u.role                                      AS customer_role,
    o.total_amount,
    o.status                                    AS order_status,
    o.created_at                                AS order_date,
    COUNT(oi.id)                                AS item_count,
    SUM(oi.subtotal)                            AS calculated_total,
    i.status                                    AS invoice_status,
    i.downloaded_at
FROM orders o
JOIN users        u  ON o.user_id  = u.id
JOIN order_items  oi ON oi.order_id = o.id
LEFT JOIN invoices i ON i.order_id  = o.id
GROUP BY
    o.id, invoice_id, u.name, u.email, u.role,
    o.total_amount, o.status, o.created_at,
    i.status, i.downloaded_at;

-- View 2: v_audit_summary
-- Powers: AuditHistoryScreen — auditor sees their own audit records
CREATE OR REPLACE VIEW v_audit_summary AS
SELECT
    a.id                                                        AS audit_id,
    CONCAT('AUD-', LEFT(a.id, 8))                              AS audit_ref,
    a.cart_id,
    c.user_id                                                   AS customer_id,
    cu.name                                                     AS customer_name,
    au.name                                                     AS auditor_name,
    au.id                                                       AS auditor_id,
    a.total_items,
    a.verified_items,
    a.discrepancies_count,
    ROUND((a.verified_items / NULLIF(a.total_items,0)) * 100, 1) AS verification_pct,
    a.status                                                    AS audit_status,
    a.notes,
    a.created_at                                                AS audit_date,
    a.completed_at
FROM audits a
JOIN carts c  ON a.cart_id    = c.id
JOIN users cu ON c.user_id    = cu.id
JOIN users au ON a.auditor_id = au.id;

-- View 3: v_admin_dashboard_stats
-- Powers: AdminDashboard — live computed today/total stats
CREATE OR REPLACE VIEW v_admin_dashboard_stats AS
SELECT
    CURDATE()                                                           AS today,
    COALESCE(SUM(CASE WHEN DATE(o.created_at) = CURDATE() THEN o.total_amount END), 0) AS todays_sales,
    COALESCE(COUNT(CASE WHEN DATE(o.created_at) = CURDATE() THEN 1 END), 0)            AS todays_orders,
    COALESCE(SUM(o.total_amount), 0)                                    AS total_revenue,
    COALESCE(AVG(o.total_amount), 0)                                    AS average_order,
    (SELECT COUNT(*) FROM users WHERE is_active = TRUE)                 AS active_users,
    (SELECT COUNT(*) FROM invoices)                                     AS total_invoices,
    (SELECT COUNT(*) FROM orders)                                       AS total_orders
FROM orders o
WHERE o.status = 'completed';

-- =============================================================
-- STORED PROCEDURE 1: sp_complete_cart_audit
-- Called when auditor finishes verifying all items in a cart.
-- Atomically: updates cart status, creates audit record,
-- creates audit_items rows, and refreshes daily_stats.
-- =============================================================
DELIMITER $$

CREATE PROCEDURE sp_complete_cart_audit (
    IN  p_cart_id    VARCHAR(100),
    IN  p_auditor_id VARCHAR(36),
    IN  p_notes      TEXT,
    OUT p_audit_id   VARCHAR(36)
)
BEGIN
    DECLARE v_total_items     INT     DEFAULT 0;
    DECLARE v_verified_items  INT     DEFAULT 0;
    DECLARE v_discrepancies   INT     DEFAULT 0;
    DECLARE v_audit_status    ENUM('pending','verified','flagged') DEFAULT 'verified';
    DECLARE v_new_audit_id    VARCHAR(36);

    -- Count items
    SELECT COUNT(*),
           SUM(CASE WHEN is_verified = TRUE THEN 1 ELSE 0 END)
    INTO v_total_items, v_verified_items
    FROM cart_items
    WHERE cart_id = p_cart_id;

    SET v_discrepancies = v_total_items - v_verified_items;
    IF v_discrepancies > 0 THEN
        SET v_audit_status = 'flagged';
    END IF;

    -- Generate audit ID
    SET v_new_audit_id = UUID();
    SET p_audit_id = v_new_audit_id;

    -- Create audit record
    INSERT INTO audits (id, cart_id, auditor_id, total_items, verified_items, discrepancies_count, status, notes, completed_at)
    VALUES (v_new_audit_id, p_cart_id, p_auditor_id, v_total_items, v_verified_items, v_discrepancies, v_audit_status, p_notes, NOW());

    -- Populate audit_items from cart_items
    INSERT INTO audit_items (audit_id, cart_item_id, product_id, product_name, price, verification_method, is_verified, verified_at)
    SELECT v_new_audit_id, ci.id, ci.product_id, ci.product_name, ci.price,
           CASE WHEN ci.is_verified = TRUE THEN 'manual' ELSE 'manual' END,
           ci.is_verified,
           ci.verified_at
    FROM cart_items ci
    WHERE ci.cart_id = p_cart_id;

    -- Mark cart completed
    UPDATE carts
    SET status = 'completed', completed_at = NOW(), last_updated = NOW()
    WHERE id = p_cart_id;

    -- Upsert daily_stats
    INSERT INTO daily_stats (stat_date, todays_sales, todays_orders, total_revenue, average_order, active_users, total_invoices)
    SELECT CURDATE(), 0, 0,
           COALESCE((SELECT SUM(total_amount) FROM orders WHERE status='completed'), 0),
           COALESCE((SELECT AVG(total_amount) FROM orders WHERE status='completed'), 0),
           (SELECT COUNT(*) FROM users WHERE is_active=TRUE),
           (SELECT COUNT(*) FROM invoices)
    ON DUPLICATE KEY UPDATE
        total_revenue  = COALESCE((SELECT SUM(total_amount) FROM orders WHERE status='completed'), 0),
        average_order  = COALESCE((SELECT AVG(total_amount) FROM orders WHERE status='completed'), 0),
        active_users   = (SELECT COUNT(*) FROM users WHERE is_active=TRUE),
        total_invoices = (SELECT COUNT(*) FROM invoices),
        updated_at     = NOW();

END$$

-- =============================================================
-- STORED PROCEDURE 2: sp_process_payment
-- Called when customer checks out.
-- Atomically: creates order + order_items from cart_items,
-- creates invoice, updates daily_stats.
-- =============================================================
CREATE PROCEDURE sp_process_payment (
    IN  p_user_id      VARCHAR(36),
    IN  p_cart_id      VARCHAR(100),
    IN  p_total_amount DECIMAL(12,2),
    OUT p_order_id     VARCHAR(36),
    OUT p_invoice_id   VARCHAR(50)
)
BEGIN
    DECLARE v_order_id   VARCHAR(36);
    DECLARE v_invoice_id VARCHAR(50);
    DECLARE v_item_count INT DEFAULT 0;

    -- Generate order ID
    SET v_order_id = UUID();
    SET p_order_id = v_order_id;

    -- Create order
    INSERT INTO orders (id, user_id, cart_id, total_amount, status)
    VALUES (v_order_id, p_user_id, p_cart_id, p_total_amount, 'completed');

    -- Populate order_items from cart_items
    INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price)
    SELECT v_order_id, ci.product_id, ci.product_name, 1, ci.price
    FROM cart_items ci
    WHERE ci.cart_id = p_cart_id;

    -- Count items
    SELECT COUNT(*) INTO v_item_count FROM order_items WHERE order_id = v_order_id;

    -- Create invoice
    SET v_invoice_id = CONCAT('INV-', LEFT(v_order_id, 8));
    SET p_invoice_id = v_invoice_id;

    INSERT INTO invoices (id, order_id, user_id, total_amount, item_count, status)
    VALUES (v_invoice_id, v_order_id, p_user_id, p_total_amount, v_item_count, 'generated');

    -- Upsert daily_stats
    INSERT INTO daily_stats (stat_date, todays_sales, todays_orders, total_revenue, average_order, active_users, total_invoices)
    SELECT CURDATE(), p_total_amount, 1,
           COALESCE((SELECT SUM(total_amount) FROM orders WHERE status='completed'), 0),
           COALESCE((SELECT AVG(total_amount) FROM orders WHERE status='completed'), 0),
           (SELECT COUNT(*) FROM users WHERE is_active=TRUE),
           (SELECT COUNT(*) FROM invoices)
    ON DUPLICATE KEY UPDATE
        todays_sales   = todays_sales + p_total_amount,
        todays_orders  = todays_orders + 1,
        total_revenue  = COALESCE((SELECT SUM(total_amount) FROM orders WHERE status='completed'), 0),
        average_order  = COALESCE((SELECT AVG(total_amount) FROM orders WHERE status='completed'), 0),
        total_invoices = (SELECT COUNT(*) FROM invoices),
        updated_at     = NOW();

END$$

DELIMITER ;

-- =============================================================
-- SAMPLE DATA
-- =============================================================

-- =============================================================
-- LOGIN CREDENTIALS (register these in the app to use them)
-- Firebase Auth handles the password — register via the app's
-- Sign Up screen with the email + password shown below.
-- The MySQL row is auto-created on first login/signup.
-- =============================================================
-- Role     | Email                        | Password
-- ---------+------------------------------+-------------
-- admin    | admin@smartsauda.com         | Smart@1234
-- auditor  | auditor@smartsauda.com       | Smart@1234
-- customer | customer@smartsauda.com      | Smart@1234
-- customer | customer2@smartsauda.com     | Smart@1234
-- =============================================================

-- Placeholder rows — Firebase UIDs (28-char strings) will replace
-- these placeholder IDs after the user registers via the app.
-- These rows exist so foreign keys in sample carts/orders work.
INSERT INTO users (id, name, email, phone, role, is_active) VALUES
('admin-placeholder-001',    'Admin User',     'admin@smartsauda.com',      '0321-1234567', 'admin',    TRUE),
('auditor-placeholder-001',  'Auditor User',   'auditor@smartsauda.com',    '0333-2345678', 'auditor',  TRUE),
('customer-placeholder-001', 'Customer One',   'customer@smartsauda.com',   '0300-3456789', 'customer', TRUE),
('customer-placeholder-002', 'Customer Two',   'customer2@smartsauda.com',  '0311-4567890', 'customer', TRUE);

-- Products: 6 in productA (Dairy/Beverages incl. real NFC card), 5 in productB (Snacks/Household)
INSERT INTO products (id, name, price, image_url, barcode, nfc_tag_id, description, category, collection_src) VALUES
('prod-a-000', 'Coke 1.5 Liter',       150.00, NULL, '6001000000010', '437702f8', 'Coca-Cola 1.5 litre bottle',            'Beverages',  'productA'),
('prod-a-001', 'Nestle Milk 1L',        180.00, NULL, 'BAR-A-001',     '04a1b2c3', 'Full cream milk, 1 litre pack',         'Dairy',      'productA'),
('prod-a-002', 'Olpers Milk 250ml',      60.00, NULL, 'BAR-A-002',     '04d4e5f6', 'Olpers full cream milk 250ml',          'Dairy',      'productA'),
('prod-a-003', 'Pepsi 1.5L',            120.00, NULL, 'BAR-A-003',     '04789abc', 'Pepsi carbonated drink 1.5 litre',      'Beverages',  'productA'),
('prod-a-004', 'Mineral Water 500ml',    30.00, NULL, 'BAR-A-004',     '04def012', 'Pure mineral water 500ml',              'Beverages',  'productA'),
('prod-a-005', 'Desi Ghee 1kg',         950.00, NULL, 'BAR-A-005',     '04345678', 'Pure desi ghee 1 kilogram tin',         'Dairy',      'productA'),
('prod-b-001', 'Lays Classic 50g',       60.00, NULL, 'BAR-B-001',     '04abcdef', 'Classic salted chips 50g',              'Snacks',     'productB'),
('prod-b-002', 'Sooper Biscuit 126g',    50.00, NULL, 'BAR-B-002',     NULL,       'LU Sooper cream biscuit 126g',          'Snacks',     'productB'),
('prod-b-003', 'Surf Excel 500g',       280.00, NULL, 'BAR-B-003',     NULL,       'Surf Excel washing powder 500g',        'Household',  'productB'),
('prod-b-004', 'Dettol Soap 115g',       90.00, NULL, 'BAR-B-004',     NULL,       'Dettol antibacterial soap 115g',        'Household',  'productB'),
('prod-b-005', 'Brooke Bond Tea 190g',  260.00, NULL, 'BAR-B-005',     NULL,       'Brooke Bond Supreme tea 190g pouch',    'Beverages',  'productB');

-- Cart sessions
INSERT INTO carts (id, user_id, status, qr_code, created_at, last_updated, completed_at) VALUES
('CART_1700000001000', 'user-cust-001', 'completed', 'QR-CART-001', '2026-04-20 10:00:00', '2026-04-20 10:45:00', '2026-04-20 10:45:00'),
('CART_1700000002000', 'user-cust-002', 'completed', 'QR-CART-002', '2026-04-21 14:00:00', '2026-04-21 14:30:00', '2026-04-21 14:30:00'),
('CART_1700000003000', 'user-cust-001', 'active',    'QR-CART-003', '2026-04-22 09:00:00', '2026-04-22 09:15:00', NULL);

-- Cart items for cart 1
INSERT INTO cart_items (cart_id, product_id, product_name, price, category, is_verified, added_at, verified_at, verified_by) VALUES
('CART_1700000001000', 'prod-a-001', 'Nestle Milk 1L',    180.00, 'Dairy',     TRUE, '2026-04-20 10:05:00', '2026-04-20 10:40:00', 'user-audit-001'),
('CART_1700000001000', 'prod-a-003', 'Pepsi 1.5L',        120.00, 'Beverages', TRUE, '2026-04-20 10:08:00', '2026-04-20 10:41:00', 'user-audit-001'),
('CART_1700000001000', 'prod-b-001', 'Lays Classic 50g',   60.00, 'Snacks',    TRUE, '2026-04-20 10:10:00', '2026-04-20 10:42:00', 'user-audit-001');

-- Cart items for cart 2
INSERT INTO cart_items (cart_id, product_id, product_name, price, category, is_verified, added_at, verified_at, verified_by) VALUES
('CART_1700000002000', 'prod-b-003', 'Surf Excel 500g',   280.00, 'Household', TRUE,  '2026-04-21 14:05:00', '2026-04-21 14:25:00', 'user-audit-001'),
('CART_1700000002000', 'prod-b-004', 'Dettol Soap 115g',   90.00, 'Household', TRUE,  '2026-04-21 14:07:00', '2026-04-21 14:26:00', 'user-audit-001'),
('CART_1700000002000', 'prod-a-005', 'Desi Ghee 1kg',     950.00, 'Dairy',     FALSE, '2026-04-21 14:09:00', NULL,                  NULL);

-- Cart items for cart 3 (active, not yet audited)
INSERT INTO cart_items (cart_id, product_id, product_name, price, category, is_verified, added_at) VALUES
('CART_1700000003000', 'prod-b-002', 'Sooper Biscuit 126g', 50.00, 'Snacks',    FALSE, '2026-04-22 09:05:00'),
('CART_1700000003000', 'prod-b-005', 'Brooke Bond Tea 190g',260.00,'Beverages', FALSE, '2026-04-22 09:10:00');

-- Orders (for the 2 completed carts)
INSERT INTO orders (id, user_id, cart_id, total_amount, status, created_at) VALUES
('ord1a000-0000-0000-0000-000000000001', 'user-cust-001', 'CART_1700000001000', 360.00, 'completed', '2026-04-20 10:50:00'),
('ord2b000-0000-0000-0000-000000000002', 'user-cust-002', 'CART_1700000002000', 370.00, 'completed', '2026-04-21 14:35:00');

-- Order items
INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price) VALUES
('ord1a000-0000-0000-0000-000000000001', 'prod-a-001', 'Nestle Milk 1L',     1, 180.00),
('ord1a000-0000-0000-0000-000000000001', 'prod-a-003', 'Pepsi 1.5L',         1, 120.00),
('ord1a000-0000-0000-0000-000000000001', 'prod-b-001', 'Lays Classic 50g',   1,  60.00),
('ord2b000-0000-0000-0000-000000000002', 'prod-b-003', 'Surf Excel 500g',    1, 280.00),
('ord2b000-0000-0000-0000-000000000002', 'prod-b-004', 'Dettol Soap 115g',   1,  90.00),
('ord2b000-0000-0000-0000-000000000002', 'prod-a-005', 'Desi Ghee 1kg',      1, 950.00);

-- Audits (1 verified, 1 flagged due to discrepancy in cart 2)
INSERT INTO audits (id, cart_id, auditor_id, total_items, verified_items, discrepancies_count, status, notes, created_at, completed_at) VALUES
('aud1c000-0000-0000-0000-000000000001', 'CART_1700000001000', 'user-audit-001', 3, 3, 0, 'verified', 'All items verified successfully.',            '2026-04-20 10:35:00', '2026-04-20 10:45:00'),
('aud2d000-0000-0000-0000-000000000002', 'CART_1700000002000', 'user-audit-001', 3, 2, 1, 'flagged',  'Desi Ghee 1kg could not be verified by NFC.', '2026-04-21 14:20:00', '2026-04-21 14:30:00');

-- Audit items for audit 1 (all verified)
INSERT INTO audit_items (audit_id, cart_item_id, product_id, product_name, price, verification_method, is_verified, verified_at)
SELECT 'aud1c000-0000-0000-0000-000000000001', ci.id, ci.product_id, ci.product_name, ci.price, 'nfc', TRUE, ci.verified_at
FROM cart_items ci WHERE ci.cart_id = 'CART_1700000001000';

-- Audit items for audit 2 (one flagged)
INSERT INTO audit_items (audit_id, cart_item_id, product_id, product_name, price, verification_method, is_verified, verified_at)
SELECT 'aud2d000-0000-0000-0000-000000000002', ci.id, ci.product_id, ci.product_name, ci.price,
       CASE WHEN ci.is_verified THEN 'barcode' ELSE 'manual' END,
       ci.is_verified, ci.verified_at
FROM cart_items ci WHERE ci.cart_id = 'CART_1700000002000';

-- Invoices
INSERT INTO invoices (id, order_id, user_id, total_amount, item_count, status, created_at) VALUES
('INV-20260420-001', 'ord1a000-0000-0000-0000-000000000001', 'user-cust-001', 360.00, 3, 'paid',      '2026-04-20 10:51:00'),
('INV-20260421-001', 'ord2b000-0000-0000-0000-000000000002', 'user-cust-002', 370.00, 3, 'generated', '2026-04-21 14:36:00');

-- Daily stats for last 7 days
INSERT INTO daily_stats (stat_date, todays_sales, todays_orders, total_revenue, average_order, active_users, total_invoices) VALUES
('2026-04-16', 1200.00, 4, 1200.00, 300.00, 2, 4),
('2026-04-17', 850.00,  3,  850.00, 283.33, 3, 3),
('2026-04-18', 1500.00, 5, 1500.00, 300.00, 4, 5),
('2026-04-19', 620.00,  2,  620.00, 310.00, 2, 2),
('2026-04-20', 360.00,  1,  360.00, 360.00, 1, 1),
('2026-04-21', 370.00,  1,  370.00, 370.00, 1, 1),
('2026-04-22', 0.00,    0,    0.00,   0.00, 0, 0);

SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================
-- VERIFICATION QUERIES
-- =============================================================
SELECT 'users'       AS tbl, COUNT(*) AS row_count FROM users
UNION ALL SELECT 'products',    COUNT(*) FROM products
UNION ALL SELECT 'carts',       COUNT(*) FROM carts
UNION ALL SELECT 'cart_items',  COUNT(*) FROM cart_items
UNION ALL SELECT 'orders',      COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'audits',      COUNT(*) FROM audits
UNION ALL SELECT 'audit_items', COUNT(*) FROM audit_items
UNION ALL SELECT 'invoices',    COUNT(*) FROM invoices
UNION ALL SELECT 'daily_stats', COUNT(*) FROM daily_stats;
