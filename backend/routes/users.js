const router = require('express').Router();
const db = require('../config/db');

// GET all users (admin)
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM users ORDER BY created_at DESC');
    console.log(`[USERS] GET all — ${rows.length} users`);
    res.json(rows);
  } catch (e) {
    console.error(`[USERS] GET all error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// GET user by id
router.get('/:uid', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM users WHERE id = ?', [req.params.uid]);
    if (rows.length === 0) {
      console.log(`[USERS] GET — not found: ${req.params.uid}`);
      return res.status(404).json({ error: 'User not found' });
    }
    console.log(`[USERS] GET — ${rows[0].email} (${rows[0].role})`);
    res.json(rows[0]);
  } catch (e) {
    console.error(`[USERS] GET /:uid error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// POST create or update user profile
router.post('/', async (req, res) => {
  const { id, name, email, role, phone } = req.body;
  if (!id || !email) return res.status(400).json({ error: 'id and email are required' });
  try {
    await db.query(
      `INSERT INTO users (id, name, email, role, phone)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE name = VALUES(name), email = VALUES(email)`,
      [id, name || email.split('@')[0], email, role || 'customer', phone || null]
    );
    const [rows] = await db.query('SELECT * FROM users WHERE id = ?', [id]);
    console.log(`[USERS] Upsert — ${email} (${role || 'customer'})`);
    res.json(rows[0]);
  } catch (e) {
    console.error(`[USERS] POST upsert error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// PUT update name/phone
router.put('/:uid', async (req, res) => {
  const { name, phone } = req.body;
  try {
    await db.query(
      'UPDATE users SET name = ?, phone = ? WHERE id = ?',
      [name, phone || null, req.params.uid]
    );
    console.log(`[USERS] Profile updated — uid: ${req.params.uid} | name: ${name}`);
    res.json({ success: true });
  } catch (e) {
    console.error(`[USERS] PUT update error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// PUT toggle active status (admin)
router.put('/:uid/status', async (req, res) => {
  const { isActive } = req.body;
  try {
    await db.query('UPDATE users SET is_active = ? WHERE id = ?', [isActive ? 1 : 0, req.params.uid]);
    console.log(`[USERS] Status updated — uid: ${req.params.uid} | active: ${isActive}`);
    res.json({ success: true });
  } catch (e) {
    console.error(`[USERS] PUT status error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// DELETE user (POS admin)
router.delete('/:uid', async (req, res) => {
  try {
    await db.query('DELETE FROM users WHERE id = ?', [req.params.uid]);
    console.log(`[USERS] Deleted — uid: ${req.params.uid}`);
    res.json({ success: true });
  } catch (e) {
    console.error(`[USERS] DELETE error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
