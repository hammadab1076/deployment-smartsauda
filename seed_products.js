/**
 * Firestore Seed Script — Smart Sauda
 *
 * Populates productA and productB collections with sample products.
 * Each product includes an `nfcTagId` that must match the UID printed
 * by your physical NFC sticker (lowercase hex, no separators).
 *
 * SETUP (run once):
 *   1. npm install firebase-admin
 *   2. Go to Firebase Console → Project Settings → Service Accounts
 *      → Generate new private key  → save as serviceAccountKey.json
 *      in the same folder as this file.
 *   3. node seed_products.js
 *
 * HOW TO FIND YOUR NFC TAG UIDs:
 *   Open Arduino Serial Monitor after flashing sketch_esp01.ino.
 *   Tap each physical NFC sticker to the reader.
 *   The UID is printed as e.g. "New NFC tag: 04a1b2c3"
 *   Copy that value into the nfcTagId field below.
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ---------------------------------------------------------------------------
// Products for collection "productA"
// ---------------------------------------------------------------------------
const productsA = [
  {
    name: 'Coke 1.5 Liter',
    price: 150.0,
    barcode: '6001000000010',
    nfcTagId: '043772f8',   // Physical NFC card UID (verified on hardware)
    imageUrl: '',
    description: 'Coca-Cola 1.5 litre bottle',
    category: 'Beverages',
  },
  {
    name: 'Milk (1 L)',
    price: 120.0,
    barcode: '6001000000001',
    nfcTagId: '04a1b2c3',
    imageUrl: '',
    description: 'Full cream milk 1 litre',
    category: 'Dairy',
  },
  {
    name: 'White Bread',
    price: 80.0,
    barcode: '6001000000002',
    nfcTagId: '04d4e5f6',
    imageUrl: '',
    description: 'Sliced white bread loaf',
    category: 'Bakery',
  },
  {
    name: 'Eggs (12-pack)',
    price: 250.0,
    barcode: '6001000000003',
    nfcTagId: '04789abc',
    imageUrl: '',
    description: 'Farm-fresh eggs, pack of 12',
    category: 'Dairy',
  },
];

// ---------------------------------------------------------------------------
// Products for collection "productB"
// ---------------------------------------------------------------------------
const productsB = [
  {
    name: 'Basmati Rice (5 kg)',
    price: 800.0,
    barcode: '6001000000004',
    nfcTagId: '04def012',
    imageUrl: '',
    description: 'Premium basmati rice 5 kg bag',
    category: 'Grains',
  },
  {
    name: 'Sunflower Oil (1 L)',
    price: 350.0,
    barcode: '6001000000005',
    nfcTagId: '04345678',
    imageUrl: '',
    description: 'Refined sunflower cooking oil 1 litre',
    category: 'Cooking',
  },
  {
    name: 'Sugar (1 kg)',
    price: 150.0,
    barcode: '6001000000006',
    nfcTagId: '04abcdef',
    imageUrl: '',
    description: 'Refined white sugar 1 kg',
    category: 'Baking',
  },
];

// ---------------------------------------------------------------------------
// Seed helper
// ---------------------------------------------------------------------------
async function seedCollection(collectionName, products) {
  console.log(`\nSeeding "${collectionName}" (${products.length} products)…`);
  for (const p of products) {
    const ref = await db.collection(collectionName).add(p);
    console.log(`  ✓ ${p.name}  [nfcTagId: ${p.nfcTagId}]  → doc ${ref.id}`);
  }
}

async function main() {
  await seedCollection('productA', productsA);
  await seedCollection('productB', productsB);
  console.log('\nAll products seeded successfully.\n');
  process.exit(0);
}

main().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
