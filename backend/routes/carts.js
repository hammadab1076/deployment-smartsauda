const router = require('express').Router();
const db = require('../config/db');

// POST create / reclaim cart session
// Supports static cart IDs (QR code on physical cart).
// Rules:
//   1. Cart active + same user      → already yours, return success
//   2. Cart active + different user → 409 Cart is in use
//   3. Cart exists but not active   → reset it (clear items, new session)
//   4. Cart doesn't exist           → INSERT new
router.post('/', async (req, res) => {
  const { cartId, userId, scannerId } = req.body;
  if (!cartId || !userId) return res.status(400).json({ error: 'cartId and userId are required' });
  try {
    const [existing] = await db.query('SELECT * FROM carts WHERE id = ?', [cartId]);

    if (existing.length > 0) {
      const cart = existing[0];

      // Rule 1: already the same user's active cart
      if (cart.status === 'active' && cart.user_id === userId) {
        return res.json({ cartId, scannerId: cart.scanner_id });
      }
      // Rule 2: active but belongs to someone else
      if (cart.status === 'active' && cart.user_id !== userId) {
        console.log(`[CART] BUSY: ${cartId} in use by another customer`);
        return res.status(409).json({ error: 'Cart is currently in use by another customer. Please wait until it is free.' });
      }
      // Rule 3: finished session — reset for new customer
      await db.query('DELETE FROM cart_items WHERE cart_id = ?', [cartId]);
      await db.query(
        "UPDATE carts SET user_id=?, scanner_id=?, status='active', last_updated=NOW(), completed_at=NULL WHERE id=?",
        [userId, scannerId || null, cartId]
      );
      console.log(`[CART] Reset: ${cartId} → new session for user: ${userId}`);
      return res.json({ cartId, scannerId: scannerId || null });
    }

    // Rule 4: brand new cart
    await db.query(
      'INSERT INTO carts (id, user_id, scanner_id, status) VALUES (?, ?, ?, ?)',
      [cartId, userId, scannerId || null, 'active']
    );
    console.log(`[CART] Created: ${cartId} | user: ${userId} | scanner: ${scannerId || 'none'}`);
    res.json({ cartId, scannerId: scannerId || null });
  } catch (e) {
    console.error(`[CART] POST create error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// GET cart with all items (polled by Flutter every 2s)
router.get('/:cartId', async (req, res) => {
  try {
    const [carts] = await db.query('SELECT * FROM carts WHERE id = ?', [req.params.cartId]);
    if (carts.length === 0) return res.status(404).json({ error: 'Cart not found' });

    const [rows] = await db.query(
      'SELECT * FROM cart_items WHERE cart_id = ? ORDER BY added_at',
      [req.params.cartId]
    );

    // Group rows by product_id so repeated scans show as quantity > 1
    const grouped = {};
    for (const r of rows) {
      const key = r.product_id;
      if (!grouped[key]) {
        grouped[key] = {
          id:         r.product_id,
          name:       r.product_name,
          price:      parseFloat(r.price),
          category:   r.category,
          isVerified: r.is_verified === 1,
          addedAt:    r.added_at,
          quantity:   1,
        };
      } else {
        grouped[key].quantity += 1;
        // Item is only fully verified if every individual scan row is verified
        if (r.is_verified !== 1) grouped[key].isVerified = false;
      }
    }

    const cart = { ...carts[0] };
    cart.items = Object.values(grouped);

    console.log(`[CART] GET ${req.params.cartId} — ${cart.items.length} item(s) | status: ${cart.status}`);
    res.json(cart);
  } catch (e) {
    console.error(`[CART] GET /:cartId error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// POST add a scanned item to cart
router.post('/:cartId/items', async (req, res) => {
  const { productId, productName, price, category } = req.body;
  if (!productId) return res.status(400).json({ error: 'productId is required' });
  try {
    await db.query(
      'INSERT INTO cart_items (cart_id, product_id, product_name, price, category) VALUES (?, ?, ?, ?, ?)',
      [req.params.cartId, productId, productName, price, category]
    );
    await db.query('UPDATE carts SET last_updated = NOW() WHERE id = ?', [req.params.cartId]);
    console.log(`[CART] Item added to ${req.params.cartId}: ${productName} @ Rs.${price}`);
    res.json({ success: true });
  } catch (e) {
    console.error(`[CART] POST item error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// PUT update cart status
router.put('/:cartId/status', async (req, res) => {
  const { status } = req.body;
  try {
    await db.query(
      'UPDATE carts SET status = ?, last_updated = NOW() WHERE id = ?',
      [status, req.params.cartId]
    );
    console.log(`[CART] Status: ${req.params.cartId} → ${status}`);
    res.json({ success: true });
  } catch (e) {
    console.error(`[CART] PUT status error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// PUT auditor verifies a specific item
router.put('/:cartId/items/:productId/verify', async (req, res) => {
  try {
    await db.query(
      'UPDATE cart_items SET is_verified = TRUE, verified_at = NOW() WHERE cart_id = ? AND product_id = ?',
      [req.params.cartId, req.params.productId]
    );
    console.log(`[CART] Item verified: product ${req.params.productId} in cart ${req.params.cartId}`);
    res.json({ success: true });
  } catch (e) {
    console.error(`[CART] PUT verify error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
