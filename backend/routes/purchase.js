const router = require('express').Router();
const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');

// GET all purchase orders
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM purchase_orders ORDER BY created_at DESC');
    console.log(`[PURCHASE] GET all — ${rows.length} orders`);
    res.json(rows);
  } catch (e) {
    console.error(`[PURCHASE] GET all error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// GET single purchase order
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM purchase_orders WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ error: 'Purchase order not found' });
    res.json(rows[0]);
  } catch (e) {
    console.error(`[PURCHASE] GET /:id error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// POST create purchase order
router.post('/', async (req, res) => {
  const { supplier_id, supplier_name, date, items_count, total_cost, status, notes } = req.body;
  if (!supplier_name || !date) return res.status(400).json({ error: 'supplier_name and date are required' });
  const id = uuidv4();
  try {
    await db.query(
      `INSERT INTO purchase_orders (id, supplier_id, supplier_name, date, items_count, total_cost, status, notes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [id, supplier_id || null, supplier_name, date, Number(items_count || 1),
       Number(total_cost || 0), status || 'pending', notes || null]
    );
    const [rows] = await db.query('SELECT * FROM purchase_orders WHERE id = ?', [id]);
    console.log(`[PURCHASE] Created: ${id} | supplier: ${supplier_name} | cost: Rs.${total_cost}`);
    res.status(201).json(rows[0]);
  } catch (e) {
    console.error(`[PURCHASE] POST create error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// PUT update status (e.g. mark as received)
router.put('/:id', async (req, res) => {
  const { supplier_name, date, items_count, total_cost, status, notes } = req.body;
  try {
    await db.query(
      `UPDATE purchase_orders SET supplier_name=?, date=?, items_count=?, total_cost=?, status=?, notes=? WHERE id=?`,
      [supplier_name, date, Number(items_count || 1), Number(total_cost || 0),
       status || 'pending', notes || null, req.params.id]
    );
    const [rows] = await db.query('SELECT * FROM purchase_orders WHERE id = ?', [req.params.id]);
    console.log(`[PURCHASE] Updated: ${req.params.id} → status: ${status}`);
    res.json(rows[0]);
  } catch (e) {
    console.error(`[PURCHASE] PUT update error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// PATCH status only (quick mark received/cancelled)
router.patch('/:id/status', async (req, res) => {
  const { status } = req.body;
  if (!status) return res.status(400).json({ error: 'status is required' });
  try {
    await db.query('UPDATE purchase_orders SET status=? WHERE id=?', [status, req.params.id]);
    console.log(`[PURCHASE] Status update: ${req.params.id} → ${status}`);
    res.json({ success: true });
  } catch (e) {
    console.error(`[PURCHASE] PATCH status error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// DELETE purchase order
router.delete('/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM purchase_orders WHERE id = ?', [req.params.id]);
    console.log(`[PURCHASE] Deleted: ${req.params.id}`);
    res.json({ success: true });
  } catch (e) {
    console.error(`[PURCHASE] DELETE error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
