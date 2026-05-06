const router  = require('express').Router();
const db      = require('../config/db');
const bcrypt  = require('bcryptjs');
const jwt     = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

const SECRET = process.env.JWT_SECRET || 'smart_sauda_local_secret_2026';

// POST /api/auth/register
router.post('/register', async (req, res) => {
  const { name, email, password, role } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }
  try {
    const [existing] = await db.query('SELECT id FROM users WHERE email = ?', [email.toLowerCase()]);
    if (existing.length > 0) {
      console.log(`[AUTH] Register failed — email already exists: ${email}`);
      return res.status(409).json({ error: 'Email already registered' });
    }

    const hash = await bcrypt.hash(password, 10);
    const id   = uuidv4();

    await db.query(
      'INSERT INTO users (id, name, email, role, password_hash) VALUES (?, ?, ?, ?, ?)',
      [id, name || email.split('@')[0], email.toLowerCase(), role || 'customer', hash]
    );

    const [rows] = await db.query('SELECT * FROM users WHERE id = ?', [id]);
    const user   = rows[0];
    const token  = jwt.sign({ id: user.id, email: user.email, role: user.role }, SECRET, { expiresIn: '30d' });

    console.log(`[AUTH] Registered: ${user.email} | role: ${user.role} | id: ${user.id}`);
    res.status(201).json({ token, user });
  } catch (e) {
    console.error(`[AUTH] Register error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { email, password, role } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password are required' });
  }
  try {
    const [rows] = await db.query('SELECT * FROM users WHERE email = ?', [email.toLowerCase()]);
    if (rows.length === 0) {
      console.log(`[AUTH] Login failed — user not found: ${email}`);
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const user  = rows[0];
    const valid = await bcrypt.compare(password, user.password_hash || '');
    if (!valid) {
      console.log(`[AUTH] Login failed — wrong password: ${email}`);
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    if (role && user.role !== role) {
      console.log(`[AUTH] Login denied — role mismatch: ${email} is '${user.role}', tried '${role}'`);
      return res.status(403).json({ error: 'Access denied. Please use the correct login portal.' });
    }

    if (!user.is_active) {
      console.log(`[AUTH] Login denied — account inactive: ${email}`);
      return res.status(403).json({ error: 'Your account has been deactivated. Please contact admin.' });
    }

    const token = jwt.sign({ id: user.id, email: user.email, role: user.role }, SECRET, { expiresIn: '30d' });
    console.log(`[AUTH] Login OK: ${user.email} | role: ${user.role}`);
    res.json({ token, user });
  } catch (e) {
    console.error(`[AUTH] Login error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// POST /api/auth/reset-password  (forgot password — no current password needed)
router.post('/reset-password', async (req, res) => {
  const { email, newPassword } = req.body;
  if (!email || !newPassword) {
    return res.status(400).json({ error: 'Email and new password are required' });
  }
  if (newPassword.length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters' });
  }
  try {
    const [rows] = await db.query('SELECT id FROM users WHERE email = ?', [email.toLowerCase()]);
    if (rows.length === 0) {
      console.log(`[AUTH] Reset-password — email not found: ${email}`);
      return res.status(404).json({ error: 'No account found with this email' });
    }
    const newHash = await bcrypt.hash(newPassword, 10);
    await db.query('UPDATE users SET password_hash = ? WHERE email = ?', [newHash, email.toLowerCase()]);
    console.log(`[AUTH] Password reset: ${email}`);
    res.json({ success: true });
  } catch (e) {
    console.error(`[AUTH] Reset-password error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// POST /api/auth/change-password
router.post('/change-password', async (req, res) => {
  const { email, currentPassword, newPassword } = req.body;
  try {
    const [rows] = await db.query('SELECT * FROM users WHERE email = ?', [email.toLowerCase()]);
    if (rows.length === 0) {
      console.log(`[AUTH] Change-password failed — user not found: ${email}`);
      return res.status(404).json({ error: 'User not found' });
    }

    const user  = rows[0];
    const valid = await bcrypt.compare(currentPassword, user.password_hash || '');
    if (!valid) {
      console.log(`[AUTH] Change-password failed — wrong current password: ${email}`);
      return res.status(401).json({ error: 'Current password is incorrect' });
    }

    const newHash = await bcrypt.hash(newPassword, 10);
    await db.query('UPDATE users SET password_hash = ? WHERE id = ?', [newHash, user.id]);
    console.log(`[AUTH] Password changed: ${email}`);
    res.json({ success: true });
  } catch (e) {
    console.error(`[AUTH] Change-password error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
