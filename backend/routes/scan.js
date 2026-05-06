const router = require('express').Router();
const db = require('../config/db');

// POST /api/scan
// Called directly by the Arduino/ESP-01 when an NFC tag is read.
// Body: { uid: "437702f8", scannerId: "SCANNER_01" }
router.post('/', async (req, res) => {
  const { uid, scannerId } = req.body;
  if (!uid || !scannerId) {
    return res.status(400).json({ error: 'uid and scannerId are required' });
  }

  console.log(`[SCAN] Received — uid: ${uid} | scanner: ${scannerId}`);

  try {
    // 1. Find the most recently paired active cart for this scanner
    const [carts] = await db.query(
      "SELECT * FROM carts WHERE scanner_id = ? AND status = 'active' ORDER BY created_at DESC LIMIT 1",
      [scannerId]
    );
    if (carts.length === 0) {
      console.log(`[SCAN] No active cart for scanner: ${scannerId}`);
      return res.status(404).json({ error: `No active cart paired to scanner: ${scannerId}` });
    }
    const cart = carts[0];
    console.log(`[SCAN] Active cart found: ${cart.id} (user: ${cart.user_id})`);

    // 2. Find the product by NFC tag UID
    const [products] = await db.query(
      'SELECT * FROM products WHERE nfc_tag_id = ? LIMIT 1',
      [uid]
    );
    if (products.length === 0) {
      console.log(`[SCAN] No product for NFC tag: ${uid}`);
      return res.status(404).json({ error: `No product found for NFC tag: ${uid}` });
    }
    const product = products[0];
    console.log(`[SCAN] Product found: ${product.name} @ Rs.${product.price}`);

    // 3. Add product to the cart (each scan = one row; GET groups by product_id into quantity)
    await db.query(
      'INSERT INTO cart_items (cart_id, product_id, product_name, price, category) VALUES (?, ?, ?, ?, ?)',
      [cart.id, product.id, product.name, product.price, product.category]
    );
    await db.query('UPDATE carts SET last_updated = NOW() WHERE id = ?', [cart.id]);
    // Update scanner last_seen so the POS dashboard can show real-time online status
    await db.query('UPDATE scanners SET last_seen = NOW() WHERE id = ?', [scannerId]);

    process.stdout.write('\x07'); // beep on successful scan
    console.log(`[SCAN] ✅ "${product.name}" added to cart ${cart.id}`);
    res.json({ success: true, product: product.name, cartId: cart.id });
  } catch (e) {
    console.error(`[SCAN] Error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
