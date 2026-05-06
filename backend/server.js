const express = require('express');
const cors    = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// ── Request logger ────────────────────────────────────────────────────────────
app.use((req, res, next) => {
  const ts = new Date().toISOString().replace('T', ' ').slice(0, 19);
  console.log(`[${ts}] ${req.method} ${req.originalUrl}`);
  next();
});

// Health check
app.get('/', (req, res) => {
  console.log('[SERVER] Health check ping');
  res.json({ status: 'Smart Sauda backend running' });
});

// Routes — Flutter app
app.use('/api/auth',            require('./routes/auth'));
app.use('/api/scan',            require('./routes/scan'));
app.use('/api/users',           require('./routes/users'));
app.use('/api/products',        require('./routes/products'));
app.use('/api/carts',           require('./routes/carts'));
app.use('/api/orders',          require('./routes/orders'));
app.use('/api/audits',          require('./routes/audits'));
app.use('/api/stats',           require('./routes/stats'));

// Routes — POS Terminal (additive, does not affect Flutter)
app.use('/api/dashboard',       require('./routes/dashboard'));
app.use('/api/suppliers',       require('./routes/suppliers'));
app.use('/api/purchase-orders', require('./routes/purchase'));
app.use('/api/scanners',        require('./routes/scanners'));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\n✅ Smart Sauda backend running at http://localhost:${PORT}`);
  console.log(`   Flutter (emulator) connects via: http://10.0.2.2:${PORT}/api\n`);
});
