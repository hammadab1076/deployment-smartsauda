import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_sauda1/core/app_router.dart';
import 'package:smart_sauda1/features/auth/presentation/providers/auth_provider.dart';

import '../providers/checkout_provider.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      body: SafeArea(
        child: Consumer<CheckoutProvider>(
          builder: (context, checkout, _) {
            return StreamBuilder<Map<String, dynamic>>(
              stream: checkout.cartStream,
              builder: (context, snapshot) {
                final cartData = snapshot.data ?? {};
                final items = cartData['items'] as List<dynamic>? ?? [];
                final int totalQty = items.fold<int>(0, (sum, item) => sum + ((item['quantity'] ?? 1) as num).toInt());
                final double totalAmount = items.fold<double>(0.0, (sum, item) {
                  final qty = ((item['quantity'] ?? 1) as num).toDouble();
                  return sum + ((item['price'] ?? 0) as num).toDouble() * qty;
                });
                final bool isPaired = checkout.activeCartId != null;

                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Header with Profile
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _greeting(),
                                    style: TextStyle(
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0D1B2A),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text("👋", style: TextStyle(fontSize: 22.sp)),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Consumer<AuthProvider>(
                                builder: (context, auth, _) {
                                  return Text(
                                    auth.user?.name ?? "Hammad Ali",
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: const Color(0xFF6C757D),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
              color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10.r,
                                  spreadRadius: 2.r,
                                ),
                              ],
                            ),
                            padding: EdgeInsets.all(8.w),
                            child: IconButton(
                              icon: Icon(Icons.person_outline_rounded, color: const Color(0xFF424242), size: 24.sp),
                              onPressed: () => Navigator.pushNamed(context, AppRouter.customerProfile),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      // 2. Alert Banner (Conditional)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: isPaired ? const Color(0xFFE8F5E9) : const Color(0xFFFF6D00),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPaired ? Icons.check_circle_outline : Icons.error_outline_rounded,
                              color: isPaired ? const Color(0xFF00C853) : Colors.white,
                              size: 28.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPaired ? "Cart Paired Successfully" : "No Cart Paired",
                                    style: TextStyle(
                                      color: isPaired ? const Color(0xFF1B5E20) : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    isPaired 
                                      ? "ID: ...${checkout.activeCartId!.substring(checkout.activeCartId!.length - 5)}"
                                      : "Scan QR code to connect",
                                    style: TextStyle(
                                      color: isPaired ? const Color(0xFF2E7D32) : Colors.white,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // 3. Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _StatsCard(
                              label: "Items",
                              value: totalQty.toString(),
                              icon: Icons.inbox_outlined
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: _StatsCard(
                              label: "Total Bill", 
                              value: "Rs. ${totalAmount.toStringAsFixed(0)}", 
                              icon: Icons.attach_money
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      // 4. Large Pair Button (Only if not paired)
                      if (!isPaired)
                        SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, AppRouter.qrPairing),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C853),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              elevation: 0,
                            ),
                            icon: Icon(Icons.qr_code_scanner, color: Colors.white, size: 20.sp),
                            label: Text(
                              "Pair Cart with QR Code",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (isPaired) SizedBox(height: 8.h), // Spacing adjustment

                      // 5. Quick Actions Section
                      Text(
                        "Quick Actions",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF424242),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Action List
                      _QuickActionCard(
                        title: "View Cart",
                        subtitle: "$totalQty Items • Rs. ${totalAmount.toStringAsFixed(0)}",
                        icon: Icons.shopping_cart_outlined,
                        iconColor: const Color(0xFF00C853),
                        iconBg: const Color(0xFFE8F5E9),
                        onTap: () => Navigator.pushNamed(context, AppRouter.cart),
                      ),
                      SizedBox(height: 16.h),
                      _QuickActionCard(
                        title: "Purchase History",
                        subtitle: "View past orders",
                        icon: Icons.history_rounded,
                        iconColor: const Color(0xFF2962FF),
                        iconBg: const Color(0xFFE3F2FD),
                        onTap: () => Navigator.pushNamed(context, AppRouter.purchaseHistory),
                      ),
                      SizedBox(height: 16.h),
                      if (!isPaired)
                        _QuickActionCard(
                          title: "Pair Smart Cart",
                          subtitle: "Scan QR to connect",
                          icon: Icons.qr_code_scanner_rounded,
                          iconColor: const Color(0xFF00C853),
                          iconBg: const Color(0xFFE8F5E9),
                          onTap: () => Navigator.pushNamed(context, AppRouter.qrPairing),
                        ),
                    ],
                  ),
                );
              }
            );
          },
        ),
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning!";
    if (hour < 17) return "Good Afternoon!";
    return "Good Evening!";
  }
}

// Subcomponents

class _StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatsCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            spreadRadius: 2.r,
            blurRadius: 10.r,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20.sp, color: const Color(0xFF00C853)),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(color: const Color(0xFF6C757D), fontSize: 14.sp),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0D1B2A),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 2.r,
              blurRadius: 10.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: iconColor, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D1B2A),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF6C757D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
