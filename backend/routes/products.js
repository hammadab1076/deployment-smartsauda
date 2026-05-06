const router = require('express').Router();
const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');

// GET all products
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM products ORDER BY name');
    console.log(`[PRODUCTS] GET all — ${rows.length} products`);
    res.json(rows);
  } catch (e) {
    console.error(`[PRODUCTS] GET all error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// GET product by barcode
router.get('/barcode/:barcode', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM products WHERE barcode = ? LIMIT 1',
      [req.params.barcode]
    );
    if (rows.length === 0) {
      console.log(`[PRODUCTS] Barcode not found: ${req.params.barcode}`);
      return res.status(404).json({ error: 'Product not found' });
    }
    console.log(`[PRODUCTS] Barcode lookup: ${req.params.barcode} → ${rows[0].name}`);
    res.json(rows[0]);
  } catch (e) {
    console.error(`[PRODUCTS] GET /barcode error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// GET product by NFC tag ID
router.get('/nfc/:nfcTagId', async (req, res) => {
  try {
    const [rows] = await db.query(
      'SELECT * FROM products WHERE nfc_tag_id = ? LIMIT 1',
      [req.params.nfcTagId]
    );
    if (rows.length === 0) {
      console.log(`[PRODUCTS] NFC tag not found: ${req.params.nfcTagId}`);
      return res.status(404).json({ error: 'Product not found for NFC tag' });
    }
    console.log(`[PRODUCTS] NFC lookup: ${req.params.nfcTagId} → ${rows[0].name}`);
    res.json(rows[0]);
  } catch (e) {
    console.error(`[PRODUCTS] GET /nfc error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// POST create product (POS)
router.post('/', async (req, res) => {
  const { name, category, price, stock, barcode, nfc_tag_id, type, description, status } = req.body;
  if (!name || price === undefined) return res.status(400).json({ error: 'name and price are required' });
  const id = `prod-${uuidv4().slice(0, 8)}`;
  try {
    await db.query(
      `INSERT INTO products (id, name, category, price, stock, barcode, nfc_tag_id, type, description, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [id, name, category || 'Uncategorized', Number(price), Number(stock || 0),
       barcode || null, nfc_tag_id || null, type || 'single', description || null, status || 'active']
    );
    const [rows] = await db.query('SELECT * FROM products WHERE id = ?', [id]);
    console.log(`[PRODUCTS] Created: ${name} (${id})`);
    res.status(201).json(rows[0]);
  } catch (e) {
    console.error(`[PRODUCTS] POST create error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// PUT update product (POS)
router.put('/:id', async (req, res) => {
  const { name, category, price, stock, barcode, nfc_tag_id, type, description, status } = req.body;
  try {
    await db.query(
      `UPDATE products SET name=?, category=?, price=?, stock=?, barcode=?, nfc_tag_id=?,
       type=?, description=?, status=? WHERE id=?`,
      [name, category, Number(price), Number(stock || 0), barcode || null,
       nfc_tag_id || null, type || 'single', description || null, status || 'active', req.params.id]
    );
    const [rows] = await db.query('SELECT * FROM products WHERE id = ?', [req.params.id]);
    console.log(`[PRODUCTS] Updated: ${req.params.id}`);
    res.json(rows[0]);
  } catch (e) {
    console.error(`[PRODUCTS] PUT update error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// DELETE product (POS)
router.delete('/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM products WHERE id = ?', [req.params.id]);
    console.log(`[PRODUCTS] Deleted: ${req.params.id}`);
    res.json({ success: true });
  } catch (e) {
    console.error(`[PRODUCTS] DELETE error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
