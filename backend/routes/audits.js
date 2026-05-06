const router = require('express').Router();
const db = require('../config/db');
const { v4: uuidv4 } = require('uuid');

// GET all audits (admin)
router.get('/', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM audits ORDER BY created_at DESC');
    console.log(`[AUDITS] GET all — ${rows.length} audits`);
    res.json(rows);
  } catch (e) {
    console.error(`[AUDITS] GET all error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// GET audit stats (auditor dashboard)
router.get('/stats', async (req, res) => {
  try {
    const [[today]]   = await db.query("SELECT COUNT(*) AS c FROM audits WHERE DATE(created_at) = CURDATE()");
    const [[total]]   = await db.query("SELECT COUNT(*) AS c FROM audits");
    const [[flagged]] = await db.query("SELECT COUNT(*) AS c FROM audits WHERE status = 'flagged'");
    console.log(`[AUDITS] Stats — today: ${today.c} | total: ${total.c} | flagged: ${flagged.c}`);
    res.json({ todaysAudits: today.c, totalAudits: total.c, discrepancies: flagged.c });
  } catch (e) {
    console.error(`[AUDITS] GET stats error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// GET audits for specific auditor (joined with orders to get total_amount + order_id)
router.get('/auditor/:auditorId', async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT a.*,
              COALESCE(a.total_amount, o.total_amount) AS resolved_amount,
              o.id AS order_id
       FROM audits a
       LEFT JOIN orders o ON o.cart_id = a.cart_id
       WHERE a.auditor_id = ?
       ORDER BY a.created_at DESC`,
      [req.params.auditorId]
    );
    console.log(`[AUDITS] GET auditor ${req.params.auditorId} — ${rows.length} audit(s)`);
    res.json(rows);
  } catch (e) {
    console.error(`[AUDITS] GET /auditor error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

// POST create audit record
router.post('/', async (req, res) => {
  const { cartId, auditorId, discrepanciesCount, status, notes, totalAmount } = req.body;
  const auditId = uuidv4();
  try {
    await db.query(
      'INSERT INTO audits (id, cart_id, auditor_id, discrepancies_count, status, notes, total_amount, completed_at) VALUES (?, ?, ?, ?, ?, ?, ?, NOW())',
      [auditId, cartId, auditorId, discrepanciesCount || 0, status || 'verified', notes || null, totalAmount || null]
    );
    console.log(`[AUDITS] Created: ${auditId} | cart: ${cartId} | auditor: ${auditorId} | status: ${status || 'verified'} | discrepancies: ${discrepanciesCount || 0}`);
    res.json({ auditId });
  } catch (e) {
    console.error(`[AUDITS] POST create error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
