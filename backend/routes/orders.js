const router = require('express').Router();
const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');

// GET all orders (admin) — includes customer name and items
router.get('/', async (req, res) => {
  try {
    const [orders] = await db.query(
      `SELECT o.*, u.name AS customer_name, u.email AS customer_email
       FROM orders o
       LEFT JOIN users u ON o.user_id = u.id
       ORDER BY o.created_at DESC`
    );
    for (const order of orders) {
      const [items] = await db.query(
        'SELECT * FROM order_items WHERE order_id = ?',
        [order.id]
      );
      order.items = items;
    }
    console.log(`[ORDERS] GET all — ${orders.length} orders`);
    res.json(orders);
  } catch (e) {
    console.error(`[ORDERS] GET all error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// GET orders for a specific user
router.get('/user/:userId', async (req, res) => {
  try {
    const [orders] = await db.query(
      'SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC',
      [req.params.userId]
    );
    for (const order of orders) {
      const [items] = await db.query(
        'SELECT * FROM order_items WHERE order_id = ?',
        [order.id]
      );
      order.items = items;
    }
    console.log(`[ORDERS] GET user ${req.params.userId} — ${orders.length} order(s)`);
    res.json(orders);
  } catch (e) {
    console.error(`[ORDERS] GET /user error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// POST create order (called at checkout)
router.post('/', async (req, res) => {
  const { id, userId, cartId, totalAmount, items } = req.body;
  const orderId = id || uuidv4();
  try {
    await db.query(
      'INSERT INTO orders (id, user_id, cart_id, total_amount, status) VALUES (?, ?, ?, ?, ?)',
      [orderId, userId, cartId || null, totalAmount, 'completed']
    );

    for (const item of (items || [])) {
      await db.query(
        'INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price) VALUES (?, ?, ?, ?, ?)',
        [orderId, item.productId, item.productName, item.quantity || 1, item.price]
      );
    }

    if (cartId) {
      await db.query(
        "UPDATE carts SET status = 'completed', completed_at = NOW() WHERE id = ?",
        [cartId]
      );
      console.log(`[ORDERS] Cart ${cartId} marked completed`);
    }

    console.log(`[ORDERS] Created: ${orderId} | user: ${userId} | total: Rs.${totalAmount} | items: ${(items || []).length}`);
    res.json({ orderId });
  } catch (e) {
    console.error(`[ORDERS] POST create error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
