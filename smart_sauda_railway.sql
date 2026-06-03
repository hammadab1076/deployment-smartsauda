-- Smart Sauda - Railway MySQL Schema (no stored procedures)
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS users (
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

CREATE TABLE IF NOT EXISTS products (
    id              VARCHAR(36)   NOT NULL,
    name            VARCHAR(255)  NOT NULL,
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
    CONSTRAINT uq_products_barcode UNIQUE (barcode),
    CONSTRAINT uq_products_nfc_tag UNIQUE (nfc_tag_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS scanners (
    id        VARCHAR(50) NOT NULL,
    port      VARCHAR(50) NULL,
    last_seen TIMESTAMP   NULL,
    CONSTRAINT pk_scanners PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS carts (
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

CREATE TABLE IF NOT EXISTS cart_items (
    id           INT           NOT NULL AUTO_INCREMENT,
    cart_id      VARCHAR(100)  NOT NULL,
    product_id   VARCHAR(36)   NOT NULL,
    product_name VARCHAR(255)  NOT NULL,
    price        DECIMAL(10,2) NOT NULL,
    category     VARCHAR(100)  NOT NULL,
    is_verified  BOOLEAN       NOT NULL DEFAULT FALSE,
    added_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    verified_at  TIMESTAMP     NULL,
    verified_by  VARCHAR(36)   NULL,
    CONSTRAINT pk_cart_items PRIMARY KEY (id),
    CONSTRAINT fk_cart_items_cart    FOREIGN KEY (cart_id)    REFERENCES carts    (id) ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_cart_items_product FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_cart_items_auditor FOREIGN KEY (verified_by) REFERENCES users   (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS orders (
    id           VARCHAR(36)   NOT NULL,
    user_id      VARCHAR(36)   NOT NULL,
    cart_id      VARCHAR(100)  NULL,
    total_amount DECIMAL(12,2) NOT NULL,
    status       ENUM('pending','completed','cancelled') NOT NULL DEFAULT 'completed',
    created_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_orders PRIMARY KEY (id),
    CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_orders_cart FOREIGN KEY (cart_id) REFERENCES carts (id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS order_items (
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

CREATE TABLE IF NOT EXISTS audits (
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
    CONSTRAINT fk_audits_cart    FOREIGN KEY (cart_id)    REFERENCES carts (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_audits_auditor FOREIGN KEY (auditor_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_items (
    id                  INT           NOT NULL AUTO_INCREMENT,
    audit_id            VARCHAR(36)   NOT NULL,
    cart_item_id        INT           NOT NULL,
    product_id          VARCHAR(36)   NOT NULL,
    product_name        VARCHAR(255)  NOT NULL,
    price               DECIMAL(10,2) NOT NULL,
    verification_method ENUM('nfc','barcode','manual') NOT NULL DEFAULT 'manual',
    is_verified         BOOLEAN       NOT NULL DEFAULT FALSE,
    verified_at         TIMESTAMP     NULL,
    CONSTRAINT pk_audit_items PRIMARY KEY (id),
    CONSTRAINT fk_audit_items_audit     FOREIGN KEY (audit_id)     REFERENCES audits     (id) ON DELETE CASCADE  ON UPDATE CASCADE,
    CONSTRAINT fk_audit_items_cart_item FOREIGN KEY (cart_item_id) REFERENCES cart_items (id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_audit_items_product   FOREIGN KEY (product_id)   REFERENCES products   (id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS invoices (
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

CREATE TABLE IF NOT EXISTS daily_stats (
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

-- Views
CREATE OR REPLACE VIEW v_order_summary AS
SELECT
    o.id                           AS order_id,
    CONCAT('INV-', LEFT(o.id, 8)) AS invoice_id,
    u.name                         AS customer_name,
    u.email                        AS customer_email,
    u.role                         AS customer_role,
    o.total_amount,
    o.status                       AS order_status,
    o.created_at                   AS order_date,
    COUNT(oi.id)                   AS item_count,
    SUM(oi.subtotal)               AS calculated_total,
    i.status                       AS invoice_status,
    i.downloaded_at
FROM orders o
JOIN users       u  ON o.user_id   = u.id
JOIN order_items oi ON oi.order_id = o.id
LEFT JOIN invoices i ON i.order_id = o.id
GROUP BY o.id, invoice_id, u.name, u.email, u.role,
         o.total_amount, o.status, o.created_at, i.status, i.downloaded_at;

CREATE OR REPLACE VIEW v_audit_summary AS
SELECT
    a.id                                                          AS audit_id,
    CONCAT('AUD-', LEFT(a.id, 8))                                AS audit_ref,
    a.cart_id,
    c.user_id                                                     AS customer_id,
    cu.name                                                       AS customer_name,
    au.name                                                       AS auditor_name,
    au.id                                                         AS auditor_id,
    a.total_items,
    a.verified_items,
    a.discrepancies_count,
    ROUND((a.verified_items / NULLIF(a.total_items,0)) * 100, 1) AS verification_pct,
    a.status                                                      AS audit_status,
    a.notes,
    a.created_at                                                  AS audit_date,
    a.completed_at
FROM audits a
JOIN carts c  ON a.cart_id    = c.id
JOIN users cu ON c.user_id    = cu.id
JOIN users au ON a.auditor_id = au.id;

CREATE OR REPLACE VIEW v_admin_dashboard_stats AS
SELECT
    CURDATE()                                                                           AS today,
    COALESCE(SUM(CASE WHEN DATE(o.created_at) = CURDATE() THEN o.total_amount END), 0) AS todays_sales,
    COALESCE(COUNT(CASE WHEN DATE(o.created_at) = CURDATE() THEN 1 END), 0)            AS todays_orders,
    COALESCE(SUM(o.total_amount), 0)                                                    AS total_revenue,
    COALESCE(AVG(o.total_amount), 0)                                                    AS average_order,
    (SELECT COUNT(*) FROM users    WHERE is_active = TRUE)                              AS active_users,
    (SELECT COUNT(*) FROM invoices)                                                     AS total_invoices,
    (SELECT COUNT(*) FROM orders)                                                       AS total_orders
FROM orders o
WHERE o.status = 'completed';

-- Seed: products
INSERT IGNORE INTO products (id, name, price, image_url, barcode, nfc_tag_id, description, category, collection_src) VALUES
('prod-a-000', 'Coke 1.5 Liter',      150.00, NULL, '6001000000010', '437702f8', 'Coca-Cola 1.5 litre bottle',         'Beverages', 'productA'),
('prod-a-001', 'Nestle Milk 1L',       180.00, NULL, 'BAR-A-001',     '04a1b2c3', 'Full cream milk, 1 litre pack',      'Dairy',     'productA'),
('prod-a-002', 'Olpers Milk 250ml',     60.00, NULL, 'BAR-A-002',     '04d4e5f6', 'Olpers full cream milk 250ml',       'Dairy',     'productA'),
('prod-a-003', 'Pepsi 1.5L',           120.00, NULL, 'BAR-A-003',     '04789abc', 'Pepsi carbonated drink 1.5 litre',   'Beverages', 'productA'),
('prod-a-004', 'Mineral Water 500ml',   30.00, NULL, 'BAR-A-004',     '04def012', 'Pure mineral water 500ml',           'Beverages', 'productA'),
('prod-a-005', 'Desi Ghee 1kg',        950.00, NULL, 'BAR-A-005',     '04345678', 'Pure desi ghee 1 kilogram tin',      'Dairy',     'productA'),
('prod-b-001', 'Lays Classic 50g',      60.00, NULL, 'BAR-B-001',     '04abcdef', 'Classic salted chips 50g',           'Snacks',    'productB'),
('prod-b-002', 'Sooper Biscuit 126g',   50.00, NULL, 'BAR-B-002',     NULL,       'LU Sooper cream biscuit 126g',       'Snacks',    'productB'),
('prod-b-003', 'Surf Excel 500g',      280.00, NULL, 'BAR-B-003',     NULL,       'Surf Excel washing powder 500g',     'Household', 'productB'),
('prod-b-004', 'Dettol Soap 115g',      90.00, NULL, 'BAR-B-004',     NULL,       'Dettol antibacterial soap 115g',     'Household', 'productB'),
('prod-b-005', 'Brooke Bond Tea 190g', 260.00, NULL, 'BAR-B-005',     NULL,       'Brooke Bond Supreme tea 190g pouch', 'Beverages', 'productB');

-- Seed: Arduino scanner
INSERT IGNORE INTO scanners (id, port) VALUES ('SCANNER_01', NULL);

SET FOREIGN_KEY_CHECKS = 1;
