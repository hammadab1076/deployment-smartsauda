const router = require('express').Router();
const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');

// GET all suppliers
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM suppliers ORDER BY name');
    console.log(`[SUPPLIERS] GET all — ${rows.length} suppliers`);
    res.json(rows);
  } catch (e) {
    console.error(`[SUPPLIERS] GET all error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// GET single supplier
router.get('/:id', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM suppliers WHERE id = ?', [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ error: 'Supplier not found' });
    res.json(rows[0]);
  } catch (e) {
    console.error(`[SUPPLIERS] GET /:id error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// POST create supplier
router.post('/', async (req, res) => {
  const { name, contact_person, phone, email, notes } = req.body;
  if (!name) return res.status(400).json({ error: 'name is required' });
  const id = uuidv4();
  try {
    await db.query(
      'INSERT INTO suppliers (id, name, contact_person, phone, email, notes) VALUES (?, ?, ?, ?, ?, ?)',
      [id, name, contact_person || null, phone || null, email || null, notes || null]
    );
    const [rows] = await db.query('SELECT * FROM suppliers WHERE id = ?', [id]);
    console.log(`[SUPPLIERS] Created: ${name} (${id})`);
    res.status(201).json(rows[0]);
  } catch (e) {
    console.error(`[SUPPLIERS] POST create error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// PUT update supplier
router.put('/:id', async (req, res) => {
  const { name, contact_person, phone, email, notes } = req.body;
  try {
    await db.query(
      'UPDATE suppliers SET name=?, contact_person=?, phone=?, email=?, notes=? WHERE id=?',
      [name, contact_person || null, phone || null, email || null, notes || null, req.params.id]
    );
    const [rows] = await db.query('SELECT * FROM suppliers WHERE id = ?', [req.params.id]);
    console.log(`[SUPPLIERS] Updated: ${req.params.id}`);
    res.json(rows[0]);
  } catch (e) {
    console.error(`[SUPPLIERS] PUT update error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// DELETE supplier
router.delete('/:id', async (req, res) => {
  try {
    await db.query('DELETE FROM suppliers WHERE id = ?', [req.params.id]);
    console.log(`[SUPPLIERS] Deleted: ${req.params.id}`);
    res.json({ success: true });
  } catch (e) {
    console.error(`[SUPPLIERS] DELETE error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
