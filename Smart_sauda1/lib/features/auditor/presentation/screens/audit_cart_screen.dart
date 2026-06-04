import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sauda1/core/app_router.dart';
import 'package:smart_sauda1/features/auth/presentation/providers/auth_provider.dart';
import '../providers/auditor_provider.dart';

class AuditCartScreen extends StatefulWidget {
  const AuditCartScreen({super.key});

  @override
  State<AuditCartScreen> createState() => _AuditCartScreenState();
}

class _AuditCartScreenState extends State<AuditCartScreen> {
  bool _isNfcScan = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuditorProvider>(
      builder: (context, auditor, child) {
        final cartId     = auditor.activeCartData['id'] as String? ?? 'Not Linked';
        final items      = auditor.cartItems;
        final status     = auditor.cartStatus;
        final verified   = items.where((i) => i['isVerified'] == true).length;
        final total      = items.length;
        final issues     = total - verified;

        // ── Auto-pop once customer has paid ──────────────────────────────────
        if (status == 'completed') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            auditor.stopListening();
            Navigator.pushNamedAndRemoveUntil(
                context, AppRouter.auditorDashboard, (r) => false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Customer has paid — cart session closed."),
                backgroundColor: Color(0xFF00C853),
                duration: Duration(seconds: 3),
              ),
            );
          });
        }

        // Generate bill enabled only after customer pressed checkout (awaiting_audit)
        // and all items are verified and bill not yet sent
        final canGenerate = total > 0 &&
            issues == 0 &&
            !auditor.billGenerated &&
            status == 'awaiting_audit';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Audit Cart",
                    style: TextStyle(
                        color: Color(0xFF0D1B2A),
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
                Text("ID: $cartId",
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.normal)),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              // ── Status banners ─────────────────────────────────────────────
              if (status == 'awaiting_audit')
                _StatusBanner(
                  color: const Color(0xFF1565C0),
                  bg:    const Color(0xFFE3F2FD),
                  icon:  Icons.shopping_cart_checkout,
                  text:  "Customer is ready to pay — verify all items, then generate the bill.",
                ),
              if (status == 'auditing' || auditor.billGenerated)
                _StatusBanner(
                  color: const Color(0xFF00796B),
                  bg:    const Color(0xFFE0F2F1),
                  icon:  Icons.hourglass_top_rounded,
                  text:  "Bill sent to customer — waiting for payment...",
                ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    // ── NFC / Barcode toggle ───────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _ScanToggleTab(
                            label: "NFC Scan",
                            icon: Icons.nfc,
                            active: _isNfcScan,
                            onTap: () => setState(() => _isNfcScan = true),
                          ),
                          _ScanToggleTab(
                            label: "Barcode",
                            icon: Icons.qr_code_scanner,
                            active: !_isNfcScan,
                            onTap: () => setState(() => _isNfcScan = false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Stats row ──────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryBox(
                            icon: Icons.check_circle_outline,
                            label: "Verified",
                            value: "$verified",
                            color: const Color(0xFFE8F5E9),
                            textColor: const Color(0xFF00C853),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryBox(
                            icon: Icons.warning_amber_rounded,
                            label: "Pending",
                            value: "$issues",
                            color: const Color(0xFFFFF3E0),
                            textColor: const Color(0xFFFF6D00),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryBox(
                            icon: Icons.list_alt,
                            label: "Total",
                            value: "$total",
                            color: const Color(0xFFE3F2FD),
                            textColor: const Color(0xFF2962FF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Items list ─────────────────────────────────────────────────
              Expanded(
                child: Container(
                  color: const Color(0xFFFAFAFA),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Text("Items to Verify",
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6A6A8B))),
                      ),
                      Expanded(
                        child: total == 0
                            ? const Center(child: Text("No items in cart"))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20),
                                itemCount: total,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  final isVerified =
                                      item['isVerified'] == true;
                                  return _ItemCard(
                                    name: item['name'] ?? 'Unknown',
                                    price: "Rs. ${item['price'] ?? 0}",
                                    qty: ((item['quantity'] ?? 1) as num).toInt(),
                                    isVerified: isVerified,
                                    onTap: (auditor.billGenerated ||
                                            status == 'auditing' ||
                                            status == 'completed')
                                        ? null // lock after bill generated
                                        : () {
                                            if (cartId != 'Not Linked') {
                                              auditor.verifyItem(
                                                  cartId, item['id']);
                                            }
                                          },
                                  );
                                },
                              ),
                      ),

                      // ── Bottom buttons ───────────────────────────────────
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Hint text below the button
                            if (!canGenerate && !auditor.billGenerated &&
                                status != 'auditing' &&
                                status != 'completed')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  issues > 0
                                      ? "Verify all $issues remaining item(s) to enable bill generation."
                                      : status != 'awaiting_audit'
                                          ? "Waiting for customer to press 'Proceed to Checkout'."
                                          : "",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Color(0xFF6C757D),
                                      fontSize: 13),
                                ),
                              ),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                icon: Icon(
                                  auditor.billGenerated ||
                                          status == 'auditing'
                                      ? Icons.hourglass_top_rounded
                                      : Icons.receipt_long,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  auditor.billGenerated ||
                                          status == 'auditing'
                                      ? "Waiting for Customer Payment..."
                                      : "Generate Bill & Send to Customer",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: canGenerate
                                    ? () async {
                                        final auditorId = context
                                                .read<AuthProvider>()
                                                .user
                                                ?.id ??
                                            '';
                                        await auditor.generateBill(
                                            cartId, auditorId, issues);
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                "Bill generated — customer can now pay."),
                                            backgroundColor:
                                                Color(0xFF00796B),
                                          ),
                                        );
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canGenerate
                                      ? const Color(0xFFAA00FF)
                                      : Colors.grey.shade300,
                                  disabledBackgroundColor:
                                      Colors.grey.shade300,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Reusable sub-widgets ─────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final Color color, bg;
  final IconData icon;
  final String text;
  const _StatusBanner(
      {required this.color,
      required this.bg,
      required this.icon,
      required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ScanToggleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ScanToggleTab(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFAA00FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: active ? Colors.white : Colors.grey),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: active ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color, textColor;
  const _SummaryBox(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(color: textColor, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final String name, price;
  final int qty;
  final bool isVerified;
  final VoidCallback? onTap;
  const _ItemCard(
      {required this.name,
      required this.price,
      required this.qty,
      required this.isVerified,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isVerified
                  ? const Color(0xFFC8E6C9)
                  : Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isVerified
                            ? const Color(0xFF00C853)
                            : Colors.grey,
                        width: 2),
                  ),
                  child: Icon(Icons.check,
                      size: 16,
                      color: isVerified
                          ? const Color(0xFF00C853)
                          : Colors.transparent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D1B2A))),
                      const SizedBox(height: 3),
                      Text("$price  ×  $qty",
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
                if (!isVerified && onTap != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFAA00FF)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("Tap to Verify",
                        style: TextStyle(
                            color: Color(0xFFAA00FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            if (isVerified) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check, size: 13, color: Color(0xFF00C853)),
                    SizedBox(width: 4),
                    Text("Verified",
                        style: TextStyle(
                            color: Color(0xFF00C853),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
