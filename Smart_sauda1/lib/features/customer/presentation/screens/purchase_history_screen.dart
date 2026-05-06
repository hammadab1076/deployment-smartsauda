import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_sauda1/domain/repositories/order_repository.dart';
import 'package:smart_sauda1/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_sauda1/domain/entities/order_entity.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  List<OrderEntity> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      setState(() { _isLoading = false; _error = "User not logged in"; });
      return;
    }
    try {
      final orders = await context.read<OrderRepository>().getOrders(user.id);
      setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _showReceipt(OrderEntity order) {
    final dateStr = DateFormat('MMM d, yyyy  h:mm a').format(order.timestamp);
    final invoiceNo = 'INV-${DateFormat('yyyyMMdd').format(order.timestamp)}-${order.timestamp.millisecondsSinceEpoch % 100000}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    // ── Store header ──────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C853), Color(0xFF00897B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 30),
                          ),
                          const SizedBox(height: 10),
                          const Text("Smart Sauda",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text("Smart Shopping Experience",
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                          const SizedBox(height: 16),
                          Text(
                            "Rs. ${order.totalAmount.toStringAsFixed(0)}",
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text("Payment Successful",
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Receipt details card ──────────────────────────────────
                    _ReceiptCard(
                      child: Column(
                        children: [
                          _receiptRow("Invoice No.", invoiceNo, bold: true),
                          _dashedDivider(),
                          _receiptRow("Date", dateStr),
                          _dashedDivider(),
                          _receiptRow("Order ID",
                              "...${order.id.substring(order.id.length > 8 ? order.id.length - 8 : 0)}"),
                          _dashedDivider(),
                          _receiptRow("Status", "COMPLETED",
                              valueColor: const Color(0xFF00C853)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Items card ────────────────────────────────────────────
                    _ReceiptCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Items Purchased",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D1B2A))),
                          const SizedBox(height: 14),
                          ...order.items.map((item) {
                            final lineTotal = item.price * item.quantity;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.shopping_basket_outlined,
                                        color: Color(0xFF00C853), size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.productName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0D1B2A))),
                                        Text("Rs. ${item.price.toStringAsFixed(0)} × ${item.quantity}",
                                            style: const TextStyle(color: Color(0xFF6C757D), fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  Text("Rs. ${lineTotal.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0D1B2A))),
                                ],
                              ),
                            );
                          }),
                          _dashedDivider(),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total",
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D1B2A))),
                              Text("Rs. ${order.totalAmount.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF00C853))),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Footer ────────────────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(20, (_) =>
                                Container(width: 4, height: 1.5, margin: const EdgeInsets.symmetric(horizontal: 2),
                                    color: Colors.grey[300])),
                          ),
                          const SizedBox(height: 12),
                          Text("Thank you for shopping at Smart Sauda!",
                              style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 4),
                          Text(invoiceNo,
                              style: TextStyle(color: Colors.grey[400], fontSize: 11, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value, {Color? valueColor, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6C757D), fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
                color: valueColor ?? const Color(0xFF0D1B2A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashedDivider() {
    return Row(
      children: List.generate(
        40,
        (_) => Expanded(child: Container(
          height: 1, margin: const EdgeInsets.symmetric(horizontal: 2),
          color: Colors.grey[200],
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      appBar: AppBar(
        title: Text("Purchase History",
            style: TextStyle(color: const Color(0xFF0D1B2A), fontWeight: FontWeight.bold, fontSize: 18.sp)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text("Error: $_error"))
              : _orders.isEmpty
                  ? Center(child: Text("No orders found", style: TextStyle(color: Colors.grey, fontSize: 14.sp)))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final totalSpent = _orders.fold(0.0, (s, o) => s + o.totalAmount);

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _HistoryStatCard(label: "Total Orders", value: "${_orders.length}", textColor: const Color(0xFF0D1B2A))),
              SizedBox(width: 16.w),
              Expanded(child: _HistoryStatCard(label: "Total Spent", value: "Rs. ${totalSpent.toStringAsFixed(0)}", textColor: const Color(0xFF00C853))),
            ],
          ),
          SizedBox(height: 24.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _orders.length,
            separatorBuilder: (_, __) => SizedBox(height: 16.h),
            itemBuilder: (_, i) {
              final order = _orders[i];
              return _OrderCard(
                date: DateFormat('MMM d, yyyy  h:mm a').format(order.timestamp),
                id: order.id,
                itemsCount: order.items.length,
                amount: order.totalAmount.toInt(),
                onViewReceipt: () => _showReceipt(order),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryStatCard extends StatelessWidget {
  final String label, value;
  final Color textColor;
  const _HistoryStatCard({required this.label, required this.value, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 2, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: const Color(0xFF6C757D), fontSize: 14.sp)),
          SizedBox(height: 8.h),
          Text(value, style: TextStyle(color: textColor, fontSize: 18.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String date, id;
  final int itemsCount, amount;
  final VoidCallback onViewReceipt;

  const _OrderCard({
    required this.date,
    required this.id,
    required this.itemsCount,
    required this.amount,
    required this.onViewReceipt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 2, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48.w, height: 48.w,
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12.r)),
                child: Icon(Icons.shopping_bag_outlined, color: const Color(0xFF00C853), size: 24.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date, style: TextStyle(fontWeight: FontWeight.w600, color: const Color(0xFF0D1B2A), fontSize: 14.sp)),
                    SizedBox(height: 4.h),
                    Text("Order #...${id.substring(id.length > 5 ? id.length - 5 : 0)}",
                        style: TextStyle(color: const Color(0xFF6C757D), fontSize: 13.sp)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Items", style: TextStyle(color: const Color(0xFF6C757D), fontSize: 13.sp)),
                  SizedBox(height: 4.h),
                  Text("$itemsCount", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Amount", style: TextStyle(color: const Color(0xFF6C757D), fontSize: 13.sp)),
                  SizedBox(height: 4.h),
                  Text("Rs. $amount",
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp, color: const Color(0xFF00C853))),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: OutlinedButton.icon(
              onPressed: onViewReceipt,
              icon: Icon(Icons.receipt_long_rounded, size: 18.sp),
              label: Text("View Receipt", style: TextStyle(fontSize: 14.sp)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00C853),
                side: const BorderSide(color: Color(0xFF00C853)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final Widget child;
  const _ReceiptCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}
