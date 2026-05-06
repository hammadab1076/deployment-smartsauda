const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host:     process.env.DB_HOST || 'localhost',
  user:     process.env.DB_USER || 'root',
  password: process.env.DB_PASS || '',
  database: process.env.DB_NAME || 'smart_sauda',
  waitForConnections: true,
  connectionLimit: 10,
  timezone: '+00:00',
});

module.exports = pool;
