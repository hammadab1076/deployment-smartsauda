import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_sauda1/domain/repositories/order_repository.dart';
import 'package:smart_sauda1/domain/entities/order_entity.dart';
import 'package:intl/intl.dart';


class AllInvoicesScreen extends StatefulWidget {
  const AllInvoicesScreen({super.key});

  @override
  State<AllInvoicesScreen> createState() => _AllInvoicesScreenState();
}

class _AllInvoicesScreenState extends State<AllInvoicesScreen> {
  List<OrderEntity> _allInvoices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    try {
      final repository = context.read<OrderRepository>();
      final orders = await repository.getAllOrders();
      setState(() {
        _allInvoices = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _selectedTimeFilter = "This Month"; // Default

  // Helper to get invoices based on filter
  List<OrderEntity> get _filteredInvoices {
    final now = DateTime.now();
    return _allInvoices.where((inv) {
      final date = inv.timestamp;
      if (_selectedTimeFilter == "Today") {
        return date.year == now.year && date.month == now.month && date.day == now.day;
      }
      if (_selectedTimeFilter == "This Month") {
        return date.year == now.year && date.month == now.month;
      }
      if (_selectedTimeFilter == "This Year") {
        return date.year == now.year;
      }
      return true;
    }).toList();
  }

  // Summary Calculations
  int get _totalInvoices => _filteredInvoices.length;
  double get _totalRevenue {
    double sum = 0;
    for (var inv in _filteredInvoices) {
      sum += inv.totalAmount;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "All Invoices",
          style: TextStyle(
            color: const Color(0xFF0D1B2A),
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.filter_list, color: Color(0xFF64748B), size: 20),
          ),
        ],
        centerTitle: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          children: [
            // Tabs
            Row(
              children: [
                _buildTab("Today"),
                SizedBox(width: 12.w),
                _buildTab("This Month"),
                SizedBox(width: 12.w),
                _buildTab("This Year"),
              ],
            ),
            SizedBox(height: 24.h),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: "Total Invoices",
                    value: "$_totalInvoices",
                    valueColor: const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildSummaryCard(
                    title: "Total Revenue",
                    value: "Rs. $_totalRevenue",
                    valueColor: const Color(0xFF1A73E8), // Blue
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Invoice List
            Expanded(
              child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text("Error: $_errorMessage"))
              : _filteredInvoices.isEmpty 
              ? Center(child: Text("No invoices found for $_selectedTimeFilter", style: const TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _filteredInvoices.length,
                  itemBuilder: (context, index) {
                     final inv = _filteredInvoices[index];
                     final dateStr = DateFormat('MMM d,\nyyyy').format(inv.timestamp);

                     return _buildInvoiceCard(
                      id: "INV-${inv.id.substring(inv.id.length > 8 ? inv.id.length - 8 : 0).toUpperCase()}",
                      name: "Customer ID: ${inv.userId.substring(0, 8)}", 
                      date: dateStr,
                      items: "${inv.items.length}", 
                      amount: "Rs. ${inv.totalAmount.toInt()}",
                     );
                  },
                ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildTab(String text) {
    final isActive = _selectedTimeFilter == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeFilter = text;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1A73E8) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required String value, required Color valueColor}) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: const Color(0xFF64748B), fontSize: 13.sp)),
          SizedBox(height: 8.h),
          Text(value, style: TextStyle(color: valueColor, fontSize: 18.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard({
    required String id,
    required String name,
    required String date,
    required String items,
    required String amount
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE), // Light Blue
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.description_outlined, color: const Color(0xFF1A73E8), size: 24.sp),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(id, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp, color: const Color(0xFF0F172A))),
                  SizedBox(height: 4.h),
                  Text(name, style: TextStyle(color: const Color(0xFF64748B), fontSize: 14.sp)),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInvoiceDetail("Date", date),
              _buildInvoiceDetail("Items", items),
              _buildInvoiceDetail("Amount", amount, isAmount: true),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.download_outlined, size: 18.sp),
              label: const Text("Download"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A73E8),
                side: const BorderSide(color: Color(0xFF1A73E8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetail(String label, String value, {bool isAmount = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: const Color(0xFF64748B), fontSize: 13.sp)),
        SizedBox(height: 4.h),
        Text(
          value, 
          style: TextStyle(
            color: isAmount ? const Color(0xFF1A73E8) : const Color(0xFF0F172A), 
            fontWeight: FontWeight.w600, 
            fontSize: 15.sp
          )
        ),
      ],
    );
  }
}
