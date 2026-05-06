const router = require('express').Router();
const db = require('../config/db');

// GET /api/dashboard — comprehensive POS analytics
router.get('/', async (req, res) => {
  try {
    // ── Today's stats ─────────────────────────────────────────────────────────
    const [[todayRev]]    = await db.query(
      "SELECT COALESCE(SUM(total_amount),0) AS v FROM orders WHERE DATE(created_at)=CURDATE() AND status='completed'"
    );
    const [[todayOrders]] = await db.query(
      "SELECT COUNT(*) AS v FROM orders WHERE DATE(created_at)=CURDATE()"
    );
    const [[activeUsers]] = await db.query(
      "SELECT COUNT(*) AS v FROM users WHERE is_active=1 AND role='customer'"
    );
    const [[totalProds]]  = await db.query("SELECT COUNT(*) AS v FROM products");
    const [[lowStock]]    = await db.query(
      "SELECT COUNT(*) AS v FROM products WHERE stock > 0 AND stock < 20"
    );
    const [[outOfStock]]  = await db.query(
      "SELECT COUNT(*) AS v FROM products WHERE stock = 0"
    );

    // ── Weekly revenue (last 7 days, fill missing days with 0) ───────────────
    const [weekRows] = await db.query(
      `SELECT DATE(created_at) AS day, COALESCE(SUM(total_amount),0) AS revenue
       FROM orders
       WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY) AND status='completed'
       GROUP BY DATE(created_at)
       ORDER BY day ASC`
    );
    const weekMap = {};
    weekRows.forEach(r => {
      weekMap[r.day.toISOString().slice(0,10)] = parseFloat(r.revenue);
    });
    const weeklyRevenue = [];
    const days = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const key = d.toISOString().slice(0,10);
      weeklyRevenue.push({ day: days[d.getDay()], date: key, revenue: weekMap[key] || 0 });
    }

    // ── Top 5 products by units sold ─────────────────────────────────────────
    const [topProds] = await db.query(
      `SELECT product_name AS name, COALESCE(SUM(quantity),0) AS sales
       FROM order_items
       GROUP BY product_name
       ORDER BY sales DESC
       LIMIT 5`
    );

    // ── Sales by category ────────────────────────────────────────────────────
    const [catRows] = await db.query(
      `SELECT p.category AS name, COUNT(oi.id) AS value
       FROM order_items oi
       JOIN products p ON oi.product_id = p.id
       GROUP BY p.category
       ORDER BY value DESC`
    );

    // ── Recent 5 orders ───────────────────────────────────────────────────────
    const [recentOrders] = await db.query(
      `SELECT o.id, u.name AS customer, DATE(o.created_at) AS date,
              o.total_amount AS total, o.status,
              COUNT(oi.id) AS items
       FROM orders o
       LEFT JOIN users u ON o.user_id = u.id
       LEFT JOIN order_items oi ON o.id = oi.order_id
       GROUP BY o.id, u.name, o.created_at, o.total_amount, o.status
       ORDER BY o.created_at DESC
       LIMIT 5`
    );

    // ── Scanner status (graceful — table may not exist until migration runs) ──────
    let scanner = null;
    try {
      const [scanners] = await db.query('SELECT * FROM scanners LIMIT 1');
      if (scanners.length > 0) {
        const s = scanners[0];
        const [activeCarts] = await db.query(
          `SELECT c.id AS cartId, u.name AS userName
           FROM carts c LEFT JOIN users u ON c.user_id = u.id
           WHERE c.scanner_id = ? AND c.status = 'active'
           ORDER BY c.created_at DESC LIMIT 1`,
          [s.id]
        );
        const lastSeen   = s.last_seen ? new Date(s.last_seen) : null;
        const minutesAgo = lastSeen ? (Date.now() - lastSeen.getTime()) / 60000 : Infinity;
        const isOnline   = activeCarts.length > 0 || minutesAgo < 10;
        scanner = {
          id:         s.id,
          port:       s.port,
          status:     isOnline ? 'online' : 'offline',
          lastSeen:   s.last_seen,
          pairedCart: activeCarts[0]?.cartId  || null,
          pairedUser: activeCarts[0]?.userName || null,
        };
      }
    } catch {
      // scanners table not yet created — migration pending
    }

    console.log(`[DASHBOARD] Stats — today: Rs.${todayRev.v} | orders: ${todayOrders.v} | users: ${activeUsers.v}`);

    res.json({
      todayRevenue:   parseFloat(todayRev.v),
      todayOrders:    todayOrders.v,
      activeUsers:    activeUsers.v,
      totalProducts:  totalProds.v,
      lowStock:       lowStock.v,
      outOfStock:     outOfStock.v,
      weeklyRevenue,
      topProducts:    topProds.map(p => ({ name: p.name, sales: Number(p.sales) })),
      salesByCategory: catRows.map(c => ({ name: c.name, value: Number(c.value) })),
      recentOrders:   recentOrders.map(o => ({
        id:       o.id,
        customer: o.customer || 'Unknown',
        date:     o.date,
        items:    Number(o.items),
        total:    parseFloat(o.total),
        status:   o.status,
      })),
      scanner,
    });
  } catch (e) {
    console.error(`[DASHBOARD] GET error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
