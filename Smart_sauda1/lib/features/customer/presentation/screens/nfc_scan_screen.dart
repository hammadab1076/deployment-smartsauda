import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sauda1/core/app_colors.dart';
import '../providers/checkout_provider.dart';

class NFCScanScreen extends StatefulWidget {
  const NFCScanScreen({super.key});

  @override
  State<NFCScanScreen> createState() => _NFCScanScreenState();
}

class _NFCScanScreenState extends State<NFCScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.90, end: 1.10).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('NFC Scanner'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: Consumer<CheckoutProvider>(
        builder: (context, checkout, _) {
          final isPaired = checkout.activeCartId != null;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),

                  // Pulsing NFC icon
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, __) => Transform.scale(
                      scale: isPaired ? _pulseAnim.value : 1.0,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPaired
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : Colors.grey.shade100,
                        ),
                        child: Icon(
                          Icons.nfc_rounded,
                          size: 84,
                          color: isPaired
                              ? AppColors.primary
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    isPaired ? 'Scanner Active' : 'No Cart Paired',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isPaired ? AppColors.primary : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPaired
                        ? 'Hold any product near the NFC reader\non your cart to add it automatically'
                        : 'Please pair a cart first using the QR scanner',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),

                  if (isPaired) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'SCANNER_01  ·  Cart …${checkout.activeCartId!.substring(checkout.activeCartId!.length - 5)}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // Live cart stream — shows items as they are added
                  if (isPaired)
                    Expanded(
                      child: StreamBuilder<Map<String, dynamic>>(
                        stream: checkout.cartStream,
                        builder: (context, snapshot) {
                          final items = (snapshot.data?['items'] as List?) ?? [];
                          if (items.isEmpty) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined,
                                    size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                const Text(
                                  'No items yet — scan a product',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              ],
                            );
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${items.length} item${items.length == 1 ? '' : 's'} in cart',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (_, i) {
                                    final item = items[items.length - 1 - i]; // newest first
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle_rounded,
                                              color: AppColors.success, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              item['name'] ?? 'Unknown',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          Text(
                                            'Rs. ${item['price'] ?? 0}',
                                            style: const TextStyle(
                                                color: Colors.grey, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    )
                  else
                    const Spacer(),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text('Done Shopping',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
