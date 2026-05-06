const router = require('express').Router();
const db = require('../config/db');

// GET admin dashboard stats
router.get('/', async (req, res) => {
  try {
    const [[sales]]     = await db.query("SELECT COALESCE(SUM(total_amount),0) AS v FROM orders WHERE DATE(created_at)=CURDATE() AND status='completed'");
    const [[orders]]    = await db.query("SELECT COUNT(*) AS v FROM orders WHERE DATE(created_at)=CURDATE()");
    const [[revenue]]   = await db.query("SELECT COALESCE(SUM(total_amount),0) AS v FROM orders WHERE status='completed'");
    const [[allOrders]] = await db.query("SELECT COUNT(*) AS v FROM orders");
    const [[users]]     = await db.query("SELECT COUNT(*) AS v FROM users WHERE is_active=1");
    const [[invoices]]  = await db.query("SELECT COUNT(*) AS v FROM invoices");

    console.log(`[STATS] Dashboard — today sales: Rs.${sales.v} | orders today: ${orders.v} | total revenue: Rs.${revenue.v} | active users: ${users.v}`);

    res.json({
      todaysSales:   parseFloat(sales.v),
      todaysOrders:  orders.v,
      totalRevenue:  parseFloat(revenue.v),
      totalOrders:   allOrders.v,
      activeUsers:   users.v,
      totalInvoices: invoices.v,
    });
  } catch (e) {
    console.error(`[STATS] GET error: ${e.message}`);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
