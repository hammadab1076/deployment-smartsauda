import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sauda1/core/app_router.dart';
import '../providers/checkout_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final checkout = context.watch<CheckoutProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Cart",
          style: TextStyle(
            color: Color(0xFF0D1B2A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          if (checkout.activeCartId != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  "ID: ...${checkout.activeCartId!.substring(checkout.activeCartId!.length - 5)}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Error banner
          if (checkout.error != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      checkout.error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder<Map<String, dynamic>>(
              stream: checkout.cartStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final cartData = snapshot.data ?? {};
                final List<dynamic> items = cartData['items'] ?? [];

                if (items.isEmpty) {
                  return _buildEmptyState();
                }

                // Verification stats
                final int verifiedCount =
                    items.where((i) => i['isVerified'] == true).length;
                final int total = items.length;
                final bool allVerified = verifiedCount == total;

                final double totalAmount =
                    items.fold<double>(0.0, (sum, item) {
                  final qty = ((item['quantity'] ?? 1) as num).toDouble();
                  return sum + ((item['price'] ?? 0) as num).toDouble() * qty;
                });

                return Column(
                  children: [
                    // ── Verification progress banner ───────────────────────
                    _VerificationBanner(
                      verifiedCount: verifiedCount,
                      total: total,
                      allVerified: allVerified,
                    ),

                    // ── Items list ─────────────────────────────────────────
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final int qty =
                              ((item['quantity'] ?? 1) as num).toInt();
                          final double unitPrice =
                              ((item['price'] ?? 0) as num).toDouble();
                          final double lineTotal = unitPrice * qty;
                          final bool isVerified = item['isVerified'] == true;

                          return _ItemCard(
                            name: item['name'] ?? 'Unknown Item',
                            unitPrice: unitPrice,
                            qty: qty,
                            lineTotal: lineTotal,
                            isVerified: isVerified,
                          );
                        },
                      ),
                    ),

                    // ── Bottom section ─────────────────────────────────────
                    _BottomBar(
                      totalAmount: totalAmount,
                      allVerified: allVerified,
                      verifiedCount: verifiedCount,
                      total: total,
                      isLoading: checkout.isLoading,
                      items: items,
                      onCheckout: () async {
                        final ok = await checkout.requestCheckout();
                        if (!context.mounted) return;
                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(checkout.error ??
                                  'Could not reach server. Check your connection.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        Navigator.pushNamed(
                          context,
                          AppRouter.checkout,
                          arguments: {
                            'items': items,
                            'totalAmount': totalAmount,
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F6F8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined,
                size: 48, color: Color(0xFF78909C)),
          ),
          const SizedBox(height: 24),
          const Text(
            "Your cart is empty",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D1B2A)),
          ),
          const SizedBox(height: 8),
          const Text(
            "Start scanning products to add them",
            style: TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
          ),
        ],
      ),
    );
  }
}

// ── Verification progress banner ─────────────────────────────────────────────

class _VerificationBanner extends StatelessWidget {
  final int verifiedCount, total;
  final bool allVerified;

  const _VerificationBanner({
    required this.verifiedCount,
    required this.total,
    required this.allVerified,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg       = allVerified ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1);
    final Color accent   = allVerified ? const Color(0xFF00C853) : const Color(0xFFFFA000);
    final IconData icon  = allVerified ? Icons.verified_user_rounded : Icons.shield_outlined;
    final String heading = allVerified
        ? "All items verified by auditor"
        : "Auditor verification in progress";
    final String sub = allVerified
        ? "You can now proceed to checkout."
        : "$verifiedCount of $total item(s) verified — please wait.";

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  heading,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                "$verifiedCount/$total",
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : verifiedCount / total,
              backgroundColor: accent.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sub,
            style: TextStyle(color: accent.withOpacity(0.85), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Item card ────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final String name;
  final double unitPrice, lineTotal;
  final int qty;
  final bool isVerified;

  const _ItemCard({
    required this.name,
    required this.unitPrice,
    required this.qty,
    required this.lineTotal,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified
              ? const Color(0xFFC8E6C9)
              : const Color(0xFFE2E8F0),
          width: isVerified ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isVerified
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.shopping_basket_outlined,
              color: isVerified
                  ? const Color(0xFF00C853)
                  : const Color(0xFF90A4AE),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Name & price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF0D1B2A)),
                ),
                const SizedBox(height: 4),
                Text(
                  "Rs. ${unitPrice.toStringAsFixed(0)} × $qty",
                  style: const TextStyle(
                      color: Color(0xFF90A4AE), fontSize: 13),
                ),
              ],
            ),
          ),

          // Right side: price + verification badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Rs. ${lineTotal.toStringAsFixed(0)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF0D1B2A)),
              ),
              const SizedBox(height: 6),
              // Verification badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isVerified
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVerified
                          ? Icons.check_circle
                          : Icons.access_time_rounded,
                      size: 12,
                      color: isVerified
                          ? const Color(0xFF00C853)
                          : const Color(0xFFFFA000),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVerified ? "Verified" : "Pending",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isVerified
                            ? const Color(0xFF00C853)
                            : const Color(0xFFFFA000),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final double totalAmount;
  final bool allVerified, isLoading;
  final int verifiedCount, total;
  final List<dynamic> items;
  final Future<void> Function() onCheckout;

  const _BottomBar({
    required this.totalAmount,
    required this.allVerified,
    required this.isLoading,
    required this.verifiedCount,
    required this.total,
    required this.items,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total",
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              Text(
                "Rs. ${totalAmount.toStringAsFixed(0)}",
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A)),
              ),
            ],
          ),

          // Hint when not all verified
          if (!allVerified) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFFFE082), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFFFFA000)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Waiting for auditor to verify ${total - verifiedCount} more item(s).",
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFF57F17),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (allVerified && !isLoading) ? onCheckout : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                disabledBackgroundColor: const Color(0xFFB0BEC5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          allVerified
                              ? Icons.shopping_cart_checkout
                              : Icons.lock_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          allVerified
                              ? "Proceed to Checkout"
                              : "Waiting for Verification ($verifiedCount/$total)",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
