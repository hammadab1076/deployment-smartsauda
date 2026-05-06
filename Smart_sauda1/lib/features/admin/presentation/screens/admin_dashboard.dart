import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_sauda1/core/app_router.dart';
import 'package:smart_sauda1/features/auth/presentation/providers/auth_provider.dart';
import '../providers/admin_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {

  @override
  void initState() {
    super.initState();
    // Fetch stats when dashboard initializes
    Future.microtask(() {
      if (mounted) {
        Provider.of<AdminProvider>(context, listen: false).loadAdminStats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Consumer<AuthProvider>(
                builder: (context, auth, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Admin Panel",
                          style: TextStyle(
                            fontSize: 24.sp, 
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B), // Dark Slate
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "Manage Smart Sauda",
                          style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRouter.adminProfile),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10.r,
                              offset: Offset(0, 4.h),
                            )
                          ],
                        ),
                        child: Icon(Icons.person_outline, color: const Color(0xFF1E293B), size: 24.sp),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Stats Grid (2x2)
              Consumer<AdminProvider>(
                builder: (context, admin, child) {
                  final stats = admin.adminStats;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.w,
                    mainAxisSpacing: 16.h,
                    childAspectRatio: 1.4,
                    children: [
                      _buildStatCard(
                        icon: Icons.attach_money,
                        color: Colors.green,
                        title: "Today's Sales",
                        value: "Rs. ${stats['todaysSales'] ?? 0}",
                      ),
                      _buildStatCard(
                        icon: Icons.shopping_cart_outlined,
                        color: Colors.blue,
                        title: "Orders",
                        value: "${stats['todaysOrders'] ?? 0}",
                      ),
                      _buildStatCard(
                        icon: Icons.people_outline,
                        color: Colors.purple,
                        title: "Active Users",
                        value: "${stats['activeUsers'] ?? 0}",
                      ),
                      _buildStatCard(
                        icon: Icons.receipt_long_outlined,
                        color: Colors.orange,
                        title: "Invoices",
                        value: "${stats['totalInvoices'] ?? 0}",
                      ),
                    ],
                  );
                },
              ),
              
              SizedBox(height: 24.h),

              // Monthly Performance Card (Blue)
              Consumer<AdminProvider>(
                builder: (context, admin, child) {
                  final stats = admin.adminStats;
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8), // Bright Blue
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Performance Summary",
                          style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Total Revenue", style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
                                SizedBox(height: 4.h),
                                Text("Rs. ${stats['totalRevenue'] ?? 0}", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Avg. Order", style: TextStyle(color: Colors.white70, fontSize: 13.sp)),
                                SizedBox(height: 4.h),
                                Text("Rs. ${stats['averageOrder'] ?? 0}", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                        // Placeholder for Graph
                        SizedBox(height: 20.h),
                        Container(
                          height: 60.h,
                          decoration: BoxDecoration(
                             gradient: LinearGradient(
                               colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.3)],
                             ),
                             borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: (admin.salesChartData).map((val) => Container(
                              width: 30.w,
                              height: (val * 40).h + 5.h,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(4.r)),
                              ),
                            )).toList(),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),

              SizedBox(height: 24.h),
              Text("Quick Actions", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 16.h),

              // Quick Actions List
              _buildActionItem(
                context,
                icon: Icons.group_outlined,
                iconBg: Colors.purple.shade50,
                iconColor: Colors.purple,
                title: "User Management",
                subtitle: "Manage customers & auditors",
                route: AppRouter.userManagement,
              ),
              const SizedBox(height: 12),
              _buildActionItem(
                context,
                icon: Icons.description_outlined,
                iconBg: Colors.orange.shade50,
                iconColor: Colors.orange,
                title: "All Invoices",
                subtitle: "View & export invoices",
                route: AppRouter.invoices,
              ),
              const SizedBox(height: 12),
              _buildActionItem(
                context,
                icon: Icons.trending_up,
                iconBg: Colors.blue.shade50,
                iconColor: Colors.blue,
                title: "Sales Analytics",
                subtitle: "View detailed reports",
                route: AppRouter.salesAnalytics,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required Color color, required String title, required String value}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22.sp),
          SizedBox(height: 12.h),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13.sp)),
          SizedBox(height: 4.h),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, {
    required IconData icon, 
    required Color iconBg, 
    required Color iconColor, 
    required String title, 
    required String subtitle,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC), // Very light grey blue
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(icon, color: iconColor, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp)),
                  SizedBox(height: 2.h),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12.sp)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
