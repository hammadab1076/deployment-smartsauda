const { SerialPort }    = require('serialport');
const { ReadlineParser } = require('@serialport/parser-readline');
const http              = require('http');

// ── Config ────────────────────────────────────────────────────────────────────
const COM_PORT    = 'COM7';        // Arduino UNO on COM7
const BAUD_RATE   = 115200;
const SCANNER_ID  = 'SCANNER_01';
const BACKEND_HOST = 'localhost';
const BACKEND_PORT = 3000;
// ─────────────────────────────────────────────────────────────────────────────

const port = new SerialPort({ path: COM_PORT, baudRate: BAUD_RATE });
const parser = port.pipe(new ReadlineParser({ delimiter: '\n' }));

port.on('open', () => {
  console.log(`[BRIDGE] ✅ Listening on ${COM_PORT} at ${BAUD_RATE} baud`);
  console.log(`[BRIDGE]    Forwarding scans → http://${BACKEND_HOST}:${BACKEND_PORT}/api/scan\n`);
});

port.on('error', (e) => {
  console.error(`[BRIDGE] ❌ Serial port error: ${e.message}`);
  console.error(`[BRIDGE]    Is the correct COM port set? Check Arduino IDE → Tools → Port`);
});

parser.on('data', (raw) => {
  const line = raw.trim();
  if (line) console.log(`[SERIAL] ${line}`);

  // Match "Card scanned: 437702f8"
  const match = line.match(/^Card scanned:\s*([0-9a-fA-F]+)$/i);
  if (match) {
    const uid = match[1].toLowerCase();
    console.log(`[BRIDGE] → Forwarding uid: ${uid} to backend...`);
    postScan(uid);
  }
});

function postScan(uid) {
  const body = JSON.stringify({ uid, scannerId: SCANNER_ID });
  const req = http.request(
    {
      hostname: BACKEND_HOST,
      port:     BACKEND_PORT,
      path:     '/api/scan',
      method:   'POST',
      headers:  { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
    },
    (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        const parsed = JSON.parse(data);
        if (parsed.success) {
          console.log(`[BRIDGE] ✅ "${parsed.product}" added to cart ${parsed.cartId}`);
        } else {
          console.log(`[BRIDGE] ⚠️  Backend: ${data}`);
        }
      });
    }
  );
  req.on('error', (e) => console.error(`[BRIDGE] ❌ HTTP error: ${e.message}`));
  req.write(body);
  req.end();
}
