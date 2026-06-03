const router = require('express').Router();
const db     = require('../config/db');

// GET /api/notifications
// Returns real-time events from the database as notification objects.
router.get('/', async (req, res) => {
  try {
    const notifications = [];

    // ── New orders in last 24 hours ───────────────────────────────────────────
    const [newOrders] = await db.query(
      `SELECT o.id, u.name AS customer, o.total_amount, o.created_at
       FROM orders o
       LEFT JOIN users u ON o.user_id = u.id
       WHERE o.created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
       ORDER BY o.created_at DESC
       LIMIT 10`
    );
    newOrders.forEach(o => {
      notifications.push({
        id:      `order-${o.id}`,
        type:    'order',
        title:   'New Order Placed',
        message: `${o.customer || 'A customer'} placed an order for Rs. ${parseFloat(o.total_amount).toLocaleString()}`,
        time:    o.created_at,
      });
    });

    // ── Low stock products (stock 1–19) ───────────────────────────────────────
    const [lowStock] = await db.query(
      `SELECT id, name, stock FROM products WHERE stock > 0 AND stock < 20 ORDER BY stock ASC LIMIT 10`
    );
    lowStock.forEach(p => {
      notifications.push({
        id:      `low-${p.id}`,
        type:    'low_stock',
        title:   'Low Stock Alert',
        message: `${p.name} has only ${p.stock} unit${p.stock === 1 ? '' : 's'} remaining`,
        time:    null,
      });
    });

    // ── Out-of-stock products ─────────────────────────────────────────────────
    const [outOfStock] = await db.query(
      `SELECT id, name FROM products WHERE stock = 0 ORDER BY name ASC LIMIT 5`
    );
    outOfStock.forEach(p => {
      notifications.push({
        id:      `oos-${p.id}`,
        type:    'out_of_stock',
        title:   'Out of Stock',
        message: `${p.name} is out of stock`,
        time:    null,
      });
    });

    // ── Flagged audits (discrepancies found) ──────────────────────────────────
    const [flagged] = await db.query(
      `SELECT a.id, a.cart_id, a.discrepancies_count, a.created_at, u.name AS auditor
       FROM audits a
       LEFT JOIN users u ON a.auditor_id = u.id
       WHERE a.status = 'flagged' AND a.created_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
       ORDER BY a.created_at DESC
       LIMIT 5`
    );
    flagged.forEach(a => {
      notifications.push({
        id:      `audit-${a.id}`,
        type:    'flagged_audit',
        title:   'Audit Discrepancy',
        message: `${a.discrepancies_count} discrepanc${a.discrepancies_count === 1 ? 'y' : 'ies'} found in cart ${a.cart_id.slice(-6)} by ${a.auditor || 'auditor'}`,
        time:    a.created_at,
      });
    });

    // ── New user registrations today ──────────────────────────────────────────
    const [newUsers] = await db.query(
      `SELECT id, name, role, created_at FROM users
       WHERE DATE(created_at) = CURDATE()
       ORDER BY created_at DESC
       LIMIT 5`
    );
    newUsers.forEach(u => {
      notifications.push({
        id:      `user-${u.id}`,
        type:    'new_user',
        title:   'New User Registered',
        message: `${u.name} joined as ${u.role}`,
        time:    u.created_at,
      });
    });

    // Sort: timestamped events first (newest), then static alerts
    notifications.sort((a, b) => {
      if (a.time && b.time) return new Date(b.time) - new Date(a.time);
      if (a.time && !b.time) return -1;
      if (!a.time && b.time) return 1;
      return 0;
    });

    console.log(`[NOTIFICATIONS] Returning ${notifications.length} notifications`);
    res.json(notifications);
  } catch (e) {
    console.error(`[NOTIFICATIONS] GET error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
