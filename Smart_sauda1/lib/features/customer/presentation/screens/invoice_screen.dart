import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:smart_sauda1/core/app_router.dart';
import '../providers/checkout_provider.dart';

class InvoiceScreen extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String paymentMethod;
  final String timestamp;

  const InvoiceScreen({
    super.key,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.timestamp,
  });

  static String _pad(int n) => n.toString().padLeft(2, '0');

  String get _invoiceNumber {
    final dt = DateTime.tryParse(timestamp) ?? DateTime.now();
    return 'INV-${dt.year}${_pad(dt.month)}${_pad(dt.day)}-${dt.millisecondsSinceEpoch % 100000}';
  }

  String get _formattedDate {
    final dt = DateTime.tryParse(timestamp) ?? DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  ${_pad(dt.hour)}:${_pad(dt.minute)}';
  }

  IconData get _paymentIcon {
    switch (paymentMethod) {
      case 'Card':    return Icons.credit_card;
      case 'Digital': return Icons.phone_android;
      default:        return Icons.money;
    }
  }

  Future<void> _downloadPdf(BuildContext context) async {
    final doc = pw.Document();
    final invoiceNo = _invoiceNumber;
    final dateStr = _formattedDate;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green700,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Smart Sauda',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Smart Shopping Experience',
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 12)),
                    pw.SizedBox(height: 12),
                    pw.Text('Rs. ${totalAmount.toStringAsFixed(0)}',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Payment Successful',
                        style: const pw.TextStyle(
                            color: PdfColors.white, fontSize: 12)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Invoice details
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _pdfRow('Invoice No.', invoiceNo),
                    _pdfDivider(),
                    _pdfRow('Date & Time', dateStr),
                    _pdfDivider(),
                    _pdfRow('Payment Method', paymentMethod),
                    _pdfDivider(),
                    _pdfRow('Status', 'COMPLETED'),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Items
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Items Purchased',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.SizedBox(height: 12),
                    ...items.map((item) {
                      final qty   = ((item['quantity'] ?? 1) as num).toInt();
                      final price = ((item['price'] ?? 0) as num).toDouble();
                      final line  = price * qty;
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                '${item['name'] ?? 'Unknown'} × $qty',
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            ),
                            pw.Text('Rs. ${line.toStringAsFixed(0)}',
                                style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      );
                    }),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 16)),
                        pw.Text('Rs. ${totalAmount.toStringAsFixed(0)}',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 16,
                                color: PdfColors.green700)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Footer
              pw.Center(
                child: pw.Text('Thank you for shopping at Smart Sauda!',
                    style: const pw.TextStyle(
                        color: PdfColors.grey600,
                        fontSize: 12,
                        fontStyle: pw.FontStyle.italic)),
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(invoiceNo,
                    style: const pw.TextStyle(
                        color: PdfColors.grey400, fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: '$invoiceNo.pdf',
    );
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 12)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _pdfDivider() => pw.Divider(color: PdfColors.grey200, height: 1);

  @override
  Widget build(BuildContext context) {
    final subtotal = totalAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Invoice",
          style: TextStyle(
              color: Color(0xFF0D1B2A),
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── Success header ─────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 44),
                        ),
                        const SizedBox(height: 14),
                        const Text("Payment Successful!",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20)),
                        const SizedBox(height: 6),
                        Text(
                          "Rs. ${subtotal.toStringAsFixed(0)}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Invoice details card ──────────────────────────────────
                  _Card(
                    child: Column(
                      children: [
                        _Row("Invoice No.", _invoiceNumber),
                        const Divider(height: 20),
                        _Row("Date & Time", _formattedDate),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Payment Method",
                                style: TextStyle(
                                    color: Color(0xFF6C757D), fontSize: 14)),
                            Row(
                              children: [
                                Icon(_paymentIcon,
                                    size: 16,
                                    color: const Color(0xFF0D1B2A)),
                                const SizedBox(width: 6),
                                Text(paymentMethod,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0xFF0D1B2A))),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Purchased items ───────────────────────────────────────
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Items Purchased",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF0D1B2A))),
                        const SizedBox(height: 16),
                        ...items.asMap().entries.map((entry) {
                          final item = entry.value;
                          final qty  = ((item['quantity'] ?? 1) as num).toInt();
                          final price= ((item['price'] ?? 0) as num).toDouble();
                          final line = price * qty;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F6F8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                      Icons.shopping_basket_outlined,
                                      color: Colors.grey, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item['name'] ?? 'Unknown',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Color(0xFF0D1B2A))),
                                      const SizedBox(height: 3),
                                      Text(
                                          "Rs. ${price.toStringAsFixed(0)} × $qty",
                                          style: const TextStyle(
                                              color: Color(0xFF6C757D),
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text("Rs. ${line.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0xFF0D1B2A))),
                              ],
                            ),
                          );
                        }),
                        const Divider(height: 8),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17)),
                            Text("Rs. ${subtotal.toStringAsFixed(0)}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Color(0xFF00C853))),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Thank you footer ──────────────────────────────────────
                  const Text("Thank you for shopping at Smart Sauda!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color(0xFF6C757D),
                          fontSize: 13,
                          fontStyle: FontStyle.italic)),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Action buttons ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              children: [
                // Download PDF button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.download_rounded,
                        color: Color(0xFF00C853)),
                    label: const Text("Download PDF",
                        style: TextStyle(
                            color: Color(0xFF00C853),
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    onPressed: () => _downloadPdf(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Color(0xFF00C853), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Back to Home button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.home_rounded, color: Colors.white),
                    label: const Text("Back to Home",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    onPressed: () {
                      context.read<CheckoutProvider>().reset();
                      Navigator.pushNamedAndRemoveUntil(
                          context, AppRouter.customerDashboard, (r) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D1B2A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF6C757D), fontSize: 14)),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF0D1B2A))),
        ),
      ],
    );
  }
}
