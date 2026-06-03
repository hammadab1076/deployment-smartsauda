const router = require('express').Router();
const db = require('../config/db');

// GET all scanner statuses
// Status is derived: online if last_seen within 60s, else offline
// Paired cart/user is read live from the carts table
router.get('/', async (req, res) => {
  try {
    const [scanners] = await db.query('SELECT * FROM scanners');

    const result = await Promise.all(scanners.map(async (s) => {
      // Check if scanner has an active cart right now
      const [activeCarts] = await db.query(
        `SELECT c.id AS cartId, u.name AS userName
         FROM carts c
         LEFT JOIN users u ON c.user_id = u.id
         WHERE c.scanner_id = ? AND c.status = 'active'
         ORDER BY c.created_at DESC LIMIT 1`,
        [s.id]
      );

      const paired = activeCarts.length > 0 ? activeCarts[0] : null;

      // Online only if hardware has sent a heartbeat in the last 10 minutes
      const lastSeen = s.last_seen ? new Date(s.last_seen) : null;
      const minutesAgo = lastSeen ? (Date.now() - lastSeen.getTime()) / 60000 : Infinity;
      const status = minutesAgo < 10 ? 'online' : 'offline';

      return {
        id:           s.id,
        port:         s.port,
        status,
        lastSeen:     s.last_seen,
        pairedCart:   paired ? paired.cartId   : null,
        pairedUser:   paired ? paired.userName  : null,
      };
    }));

    console.log(`[SCANNERS] GET — ${result.length} scanner(s)`);
    res.json(result);
  } catch (e) {
    // Return empty array if table doesn't exist yet (migration pending)
    console.warn(`[SCANNERS] GET — ${e.message}`);
    res.json([]);
  }
});

module.exports = router;
