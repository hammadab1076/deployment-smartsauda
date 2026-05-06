// ─── Products (matches actual DB) ────────────────────────────────────────────
export const products = [
  { id:'prod-a-000', name:'Coke 1.5 Liter',       price:150, category:'Beverages', nfc:'437702f8',     barcode:'6001000000010', stock:42, type:'single',    status:'active' },
  { id:'prod-a-001', name:'Nestle Milk 1L',        price:180, category:'Dairy',     nfc:'43631c25',     barcode:'BAR-A-001',     stock:28, type:'single',    status:'active' },
  { id:'prod-a-002', name:'Olpers Milk 250ml',     price:60,  category:'Dairy',     nfc:'04d4e5f6',     barcode:'BAR-A-002',     stock:65, type:'variation', status:'active' },
  { id:'prod-a-003', name:'Pepsi 1.5L',            price:120, category:'Beverages', nfc:'04789abc',     barcode:'BAR-A-003',     stock:38, type:'variation', status:'active' },
  { id:'prod-a-004', name:'Mineral Water 500ml',   price:30,  category:'Beverages', nfc:'04def012',     barcode:'BAR-A-004',     stock:90, type:'variation', status:'active' },
  { id:'prod-a-005', name:'Desi Ghee 1kg',         price:950, category:'Dairy',     nfc:'047cfa66ce2a81',barcode:'BAR-A-005',   stock:12, type:'single',    status:'active' },
  { id:'prod-b-001', name:'Lays Classic 50g',      price:60,  category:'Snacks',    nfc:'04abcdef',     barcode:'BAR-B-001',     stock:55, type:'single',    status:'active' },
  { id:'prod-b-002', name:'Sooper Biscuit 126g',   price:50,  category:'Snacks',    nfc:null,           barcode:'BAR-B-002',     stock:40, type:'single',    status:'active' },
  { id:'prod-b-003', name:'Surf Excel 500g',       price:280, category:'Household', nfc:null,           barcode:'BAR-B-003',     stock:20, type:'single',    status:'active' },
  { id:'prod-b-004', name:'Dettol Soap 115g',      price:90,  category:'Household', nfc:null,           barcode:'BAR-B-004',     stock:33, type:'single',    status:'active' },
  { id:'prod-b-005', name:'Brooke Bond Tea 100g',  price:260, category:'Beverages', nfc:null,           barcode:'BAR-B-005',     stock:18, type:'single',    status:'active' },
]

export const categories = ['Beverages', 'Dairy', 'Snacks', 'Household', 'Bakery', 'Frozen']

// ─── Users ────────────────────────────────────────────────────────────────────
export const users = [
  { id:'uid-001', name:'Admin User',   email:'admin@smartsauda.com',     role:'admin',    isActive:true,  joined:'2026-01-10', orders:0  },
  { id:'uid-002', name:'admin5',       email:'admin5@smartsaude.com',    role:'admin',    isActive:true,  joined:'2026-01-15', orders:0  },
  { id:'uid-003', name:'auditor5',     email:'auditor5@smartsaude.com',  role:'auditor',  isActive:true,  joined:'2026-02-01', orders:0  },
  { id:'uid-004', name:'customer4',    email:'c4@smartsauda.com',        role:'customer', isActive:true,  joined:'2026-02-10', orders:7  },
  { id:'uid-005', name:'customer5',    email:'c5@smartsauda.com',        role:'customer', isActive:true,  joined:'2026-03-01', orders:4  },
  { id:'uid-006', name:'Hammad Ali',   email:'hammad@smartsauda.com',    role:'customer', isActive:true,  joined:'2026-03-15', orders:12 },
  { id:'uid-007', name:'Sara Khan',    email:'sara@smartsauda.com',      role:'customer', isActive:false, joined:'2026-04-01', orders:2  },
  { id:'uid-008', name:'Ali Raza',     email:'ali@smartsauda.com',       role:'auditor',  isActive:true,  joined:'2026-04-05', orders:0  },
]

// ─── Sales / Orders ───────────────────────────────────────────────────────────
export const orders = [
  { id:'ORD-1001', customer:'Hammad Ali',  date:'2026-04-27', items:4, total:660,  status:'completed', products:['Coke 1.5 Liter×2','Nestle Milk 1L×2'] },
  { id:'ORD-1002', customer:'customer4',   date:'2026-04-27', items:3, total:530,  status:'completed', products:['Lays Classic 50g×2','Desi Ghee 1kg×1'] },
  { id:'ORD-1003', customer:'customer5',   date:'2026-04-26', items:5, total:1240, status:'completed', products:['Pepsi 1.5L×2','Surf Excel 500g×1','Dettol Soap 115g×2'] },
  { id:'ORD-1004', customer:'Sara Khan',   date:'2026-04-26', items:2, total:360,  status:'completed', products:['Nestle Milk 1L×2'] },
  { id:'ORD-1005', customer:'Hammad Ali',  date:'2026-04-25', items:6, total:2080, status:'completed', products:['Desi Ghee 1kg×2','Olpers Milk 250ml×2','Brooke Bond Tea 100g×1'] },
  { id:'ORD-1006', customer:'Ali Raza',    date:'2026-04-25', items:3, total:390,  status:'refunded',  products:['Mineral Water 500ml×3','Sooper Biscuit 126g×3'] },
  { id:'ORD-1007', customer:'customer4',   date:'2026-04-24', items:7, total:1730, status:'completed', products:['Coke 1.5 Liter×4','Lays Classic 50g×3'] },
  { id:'ORD-1008', customer:'customer5',   date:'2026-04-24', items:2, total:330,  status:'completed', products:['Coke 1.5 Liter×1','Nestle Milk 1L×1'] },
]

// ─── Revenue by day (last 7 days) ────────────────────────────────────────────
export const revenueWeekly = [
  { day:'Mon', revenue:2400 },
  { day:'Tue', revenue:1800 },
  { day:'Wed', revenue:3200 },
  { day:'Thu', revenue:2750 },
  { day:'Fri', revenue:4100 },
  { day:'Sat', revenue:5200 },
  { day:'Sun', revenue:3600 },
]

export const revenueMonthly = [
  { month:'Jan', revenue:42000 },
  { month:'Feb', revenue:58000 },
  { month:'Mar', revenue:71000 },
  { month:'Apr', revenue:65000 },
]

export const salesByCategory = [
  { name:'Beverages', value:38 },
  { name:'Dairy',     value:29 },
  { name:'Snacks',    value:16 },
  { name:'Household', value:12 },
  { name:'Other',     value:5  },
]

export const topProducts = [
  { name:'Desi Ghee 1kg',    sales:28 },
  { name:'Nestle Milk 1L',   sales:47 },
  { name:'Coke 1.5 Liter',   sales:62 },
  { name:'Pepsi 1.5L',       sales:38 },
  { name:'Lays Classic 50g', sales:55 },
]

// ─── Suppliers ────────────────────────────────────────────────────────────────
export const suppliers = [
  { id:'sup-001', name:'Nestle Pakistan Ltd',   contact:'Rizwan Ahmed',  phone:'021-3456789', email:'orders@nestle.pk',    products:['Nestle Milk 1L','Mineral Water 500ml'] },
  { id:'sup-002', name:'Coca-Cola Beverages Pk',contact:'Tariq Mehmood', phone:'021-7654321', email:'supply@cocacola.pk',  products:['Coke 1.5 Liter','Sprite 1.5L'] },
  { id:'sup-003', name:'Engro Foods',           contact:'Sana Malik',    phone:'042-1234567', email:'trade@engro.com',     products:['Olpers Milk 250ml','Desi Ghee 1kg'] },
  { id:'sup-004', name:'PepsiCo Pakistan',      contact:'Usman Ali',     phone:'051-9876543', email:'ops@pepsico.pk',      products:['Pepsi 1.5L','7UP 1.5L'] },
  { id:'sup-005', name:'Unilever Pakistan',     contact:'Aisha Noor',    phone:'021-5555555', email:'supply@unilever.pk', products:['Surf Excel 500g','Lux Soap'] },
]

// ─── Purchase Orders ──────────────────────────────────────────────────────────
export const purchaseOrders = [
  { id:'PO-2026-001', supplier:'Nestle Pakistan Ltd',    date:'2026-04-20', items:3, totalCost:18500, status:'received' },
  { id:'PO-2026-002', supplier:'Coca-Cola Beverages Pk', date:'2026-04-22', items:2, totalCost:9200,  status:'received' },
  { id:'PO-2026-003', supplier:'Engro Foods',            date:'2026-04-25', items:4, totalCost:32000, status:'pending'  },
  { id:'PO-2026-004', supplier:'PepsiCo Pakistan',       date:'2026-04-26', items:2, totalCost:8400,  status:'pending'  },
  { id:'PO-2026-005', supplier:'Unilever Pakistan',      date:'2026-04-27', items:5, totalCost:21000, status:'pending'  },
]

// ─── Audits ───────────────────────────────────────────────────────────────────
export const audits = [
  { id:'AUD-a1b2c3d4', cartId:'CART_177700001', auditor:'auditor5', date:'2026-04-27', items:4, discrepancies:0, status:'verified' },
  { id:'AUD-e5f6a7b8', cartId:'CART_177700002', auditor:'Ali Raza', date:'2026-04-26', items:6, discrepancies:2, status:'flagged'  },
  { id:'AUD-c9d0e1f2', cartId:'CART_177700003', auditor:'auditor5', date:'2026-04-25', items:3, discrepancies:0, status:'verified' },
  { id:'AUD-g3h4i5j6', cartId:'CART_177700004', auditor:'Ali Raza', date:'2026-04-24', items:5, discrepancies:1, status:'flagged'  },
]

// ─── Scanners ─────────────────────────────────────────────────────────────────
export const scanners = [
  { id:'SCANNER_01', port:'COM7', status:'online', lastSeen:'2026-04-27 18:42', pairedCart:'CART_177728316132', pairedUser:'Hammad Ali' },
]

export const CHART_COLORS = ['#1A73E8','#00C853','#FF6D00','#AA00FF','#D32F2F']
