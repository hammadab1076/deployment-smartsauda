import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sauda1/core/app_router.dart';
import 'package:smart_sauda1/features/auth/presentation/providers/auth_provider.dart';
import '../providers/checkout_provider.dart';
import 'package:smart_sauda1/domain/entities/order_entity.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.items,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedPayment = 'Cash';

  static const _paymentMethods = [
    {'id': 'Cash',    'label': 'Cash',           'icon': Icons.money},
    {'id': 'Card',    'label': 'Debit / Credit',  'icon': Icons.credit_card},
    {'id': 'Digital', 'label': 'Digital Wallet',  'icon': Icons.phone_android},
  ];

  // ── Build variations based on cart status ──────────────────────────────────

  Widget _buildWaiting() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  size: 48, color: Color(0xFFAA00FF)),
            ),
            const SizedBox(height: 28),
            const Text(
              "Waiting for Auditor",
              style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold,
                color: Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "The auditor is verifying your cart items.\nPlease wait at the counter.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Color(0xFF6C757D), height: 1.5),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Color(0xFFAA00FF)),
            const SizedBox(height: 16),
            Text(
              "Items: ${widget.items.length}   ·   Total: Rs. ${widget.totalAmount.toStringAsFixed(0)}",
              style: const TextStyle(color: Color(0xFF6C757D), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptions(CheckoutProvider checkout) {
    final user = context.read<AuthProvider>().user;

    return Column(
      children: [
        // ── Bill Summary ─────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FFF4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: Color(0xFF00C853), size: 20),
                  const SizedBox(width: 8),
                  const Text("Bill Generated",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF00C853))),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("Auditor Approved",
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              // Items list
              ...widget.items.map((item) {
                final qty = ((item['quantity'] ?? 1) as num).toInt();
                final price = ((item['price'] ?? 0) as num).toDouble();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Color(0xFF6C757D)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(item['name'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF0D1B2A))),
                      ),
                      Text("x$qty",
                          style: const TextStyle(color: Color(0xFF6C757D), fontSize: 13)),
                      const SizedBox(width: 16),
                      Text("Rs. ${(price * qty).toStringAsFixed(0)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                );
              }),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Amount",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Color(0xFF0D1B2A))),
                  Text("Rs. ${widget.totalAmount.toStringAsFixed(0)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Color(0xFF00C853))),
                ],
              ),
            ],
          ),
        ),

        // ── Payment Method ───────────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text("Select Payment Method",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0D1B2A))),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: _paymentMethods.map((method) {
              final isSelected = _selectedPayment == method['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedPayment = method['id'] as String),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00C853)
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00C853).withOpacity(0.15)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(method['icon'] as IconData,
                            color: isSelected
                                ? const Color(0xFF00C853)
                                : const Color(0xFF6C757D)),
                      ),
                      const SizedBox(width: 14),
                      Text(method['label'] as String,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: isSelected
                                  ? const Color(0xFF00C853)
                                  : const Color(0xFF0D1B2A))),
                      const Spacer(),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            color: Color(0xFF00C853), size: 22),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const Spacer(),

        // ── Confirm Payment Button ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Consumer<CheckoutProvider>(
            builder: (context, provider, _) {
              return SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("User not logged in")),
                            );
                            return;
                          }

                          // Capture before async gap to avoid BuildContext warnings
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          final orderItems = widget.items.map((item) {
                            return OrderItemEntity(
                              productId:   item['id'] ?? 'unknown',
                              productName: item['name'] ?? 'Unknown',
                              quantity:
                                  ((item['quantity'] ?? 1) as num).toInt(),
                              price: ((item['price'] ?? 0) as num).toDouble(),
                            );
                          }).toList();

                          final success = await provider.processPayment(
                            userId: user.id,
                            totalAmount: widget.totalAmount,
                            items: orderItems,
                            paymentMethod: _selectedPayment,
                          );

                          if (!mounted) return;

                          if (success) {
                            navigator.pushReplacementNamed(
                              AppRouter.invoice,
                              arguments: {
                                'items': widget.items,
                                'totalAmount': widget.totalAmount,
                                'paymentMethod': _selectedPayment,
                                'timestamp': DateTime.now().toIso8601String(),
                              },
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                    "Payment Failed: ${provider.error ?? 'Unknown error'}"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          "Pay Rs. ${widget.totalAmount.toStringAsFixed(0)} · $_selectedPayment",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Color(0xFF0D1B2A))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text("Back to Home"),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final checkout = context.watch<CheckoutProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Checkout",
          style: TextStyle(
              color: Color(0xFF0D1B2A),
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: checkout.cartStream,
        builder: (context, snapshot) {
          // While we have no data yet, show waiting
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildWaiting();
          }

          final status = snapshot.data!['status'] as String? ?? '';

          switch (status) {
            case 'checkout_requested':
              return _buildWaiting();

            case 'bill_generated':
              return _buildPaymentOptions(checkout);

            case 'paid':
            case 'completed':
              // Rare: user somehow still on this screen after paying
              return _buildError("This order has already been processed.");

            case 'abandoned':
              return _buildError(
                  "Cart session was reset.\nPlease start a new cart.");

            default:
              return _buildWaiting();
          }
        },
      ),
    );
  }
}
