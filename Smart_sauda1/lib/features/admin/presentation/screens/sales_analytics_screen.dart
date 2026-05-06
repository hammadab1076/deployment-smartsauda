import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/admin_provider.dart';

class SalesAnalyticsScreen extends StatefulWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> {
  // Interaction State
  int? _touchedIndex;
  Offset? _touchedPosition;

  @override
  void initState() {
    super.initState();
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Sales Analytics",
          style: TextStyle(
            color: const Color(0xFF0D1B2A),
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: false,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          final stats = admin.adminStats;
          final barData = admin.salesChartData;
          final xLabels = admin.salesChartLabels;
          final List<String> yLabels = ["0", "25%", "50%", "75%", "100%"]; 

          return SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                // Stats Grid (2x2)
                 GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.w,
                    mainAxisSpacing: 16.h,
                    childAspectRatio: 1.3,
                    children: [
                      _buildColorStatCard(
                        icon: Icons.attach_money,
                        title: "Today's Sales",
                        value: "Rs. ${stats['todaysSales'] ?? 0}",
                        color: const Color(0xFF1A73E8), // Blue
                      ),
                      _buildColorStatCard(
                        icon: Icons.shopping_cart_outlined,
                        title: "Orders",
                        value: "${stats['todaysOrders'] ?? 0}",
                        color: const Color(0xFF00C853), // Green
                      ),
                       _buildColorStatCard(
                        icon: Icons.group_outlined,
                        title: "Customers",
                        value: "${stats['activeUsers'] ?? 0}",
                        color: const Color(0xFF9C27B0), // Purple
                      ),
                       _buildColorStatCard(
                        icon: Icons.trending_up,
                        title: "Growth",
                        value: "+24.5%",
                        color: const Color(0xFFFF6D00), // Orange
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),

                  // Daily Sales Chart (Interactive)
                  _buildChartContainer(
                    title: "Last 7 Days (Normalized)",
                    child: SizedBox(
                       height: 200.h,
                       child: LayoutBuilder(
                         builder: (context, constraints) {
                           return GestureDetector(
                             onPanUpdate: (details) => _handleTouch(details.localPosition, constraints.maxWidth, barData.length),
                             onPanDown: (details) => _handleTouch(details.localPosition, constraints.maxWidth, barData.length),
                             onTapUp: (_) => setState(() => _touchedIndex = null),
                             child: Stack(
                               children: [
                                 CustomPaint(
                                   painter: _BarChartPainter(
                                     barData: barData,
                                     xLabels: xLabels,
                                     yLabels: yLabels,
                                     touchedIndex: _touchedIndex,
                                   ),
                                   size: Size(constraints.maxWidth, 200.h),
                                 ),
                                 if (_touchedIndex != null && _touchedPosition != null)
                                   Positioned(
                                     left: _clampTooltipX(_touchedPosition!.dx, constraints.maxWidth),
                                     top: 200.h - (barData[_touchedIndex!] * 200.h) - 40.h,
                                     child: _buildTooltip(barData[_touchedIndex!]),
                                   ),
                               ],
                             ),
                           );
                         }
                       ),
                    ),
                  ),

              SizedBox(height: 24.h),
              
              // Monthly Trend (Line Chart)
               _buildChartContainer(
                title: "Monthly Trend",
                child: SizedBox(
                   height: 200.h,
                   child: CustomPaint(
                     painter: _LineChartPainter(),
                     size: Size(double.infinity, 200.h),
                   ),
                ),
               ),

               SizedBox(height: 24.h),

               // Year Summary Card
               Container(
                 width: double.infinity,
                 padding: EdgeInsets.all(24.w),
                 decoration: BoxDecoration(
                   color: const Color(0xFFEFF6FF), 
                   borderRadius: BorderRadius.circular(20.r),
                   border: Border.all(color: const Color(0xFFDBEAFE)),
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       "Year Summary",
                       style: TextStyle(
                         fontSize: 18.sp,
                         fontWeight: FontWeight.bold,
                         color: const Color(0xFF0F172A),
                       ),
                     ),
                     SizedBox(height: 24.h),
                     _buildSummaryRow("Total Revenue", "Rs. ${stats['totalRevenue'] ?? '0'}", isBlue: true),
                     SizedBox(height: 16.h),
                     _buildSummaryRow("Total Orders", "${stats['totalOrders'] ?? '0'}", isBlue: false),
                     SizedBox(height: 16.h),
                     _buildSummaryRow("Average Order", "Rs. ${stats['averageOrder'] ?? '0'}", isBlue: false),
                   ],
                 ),
               ),
               SizedBox(height: 20.h),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleTouch(Offset localPosition, double width, int dataLength) {
    if (dataLength == 0) return;
    final double leftPadding = 40.0.w;
    final double chartWidth = width - leftPadding;
    final double spacing = chartWidth / dataLength;
    
    if (localPosition.dx < leftPadding || localPosition.dx > width) {
      if (_touchedIndex != null) setState(() => _touchedIndex = null);
      return;
    }

    int index = ((localPosition.dx - leftPadding) / spacing).floor();
    if (index >= 0 && index < dataLength) {
      if (_touchedIndex != index) {
        setState(() {
          _touchedIndex = index;
          double barCenterX = leftPadding + (index * spacing) + (spacing / 2);
           _touchedPosition = Offset(barCenterX, 0); 
        });
      }
    } else {
      if (_touchedIndex != null) setState(() => _touchedIndex = null);
    }
  }

  double _clampTooltipX(double x, double maxWidth) {
    if (x < 60.w) return 0;
    if (x > maxWidth - 60.w) return maxWidth - 120.w;
    return x - 60.w; 
  }

  Widget _buildTooltip(double normalizedValue) {
    final percent = (normalizedValue * 100).toInt();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        "Vol: $percent%", 
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp),
      ),
    );
  }

  Widget _buildChartContainer({required String title, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: 24.h),
          child,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {required bool isBlue}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15.sp,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isBlue ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildColorStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white, size: 28.sp),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> barData;
  final List<String> xLabels;
  final List<String> yLabels;
  final int? touchedIndex;

  _BarChartPainter({
    required this.barData,
    required this.xLabels,
    required this.yLabels,
    this.touchedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF4285F4);
    final touchedPaint = Paint()..color = const Color(0xFF1976D2); 
    final axisPaint = Paint()..color = Colors.grey.withValues(alpha: 0.5)..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final double yStep = size.height / (yLabels.length - 1);
    
    for (int i = 0; i < yLabels.length; i++) {
       final y = size.height - (i * yStep);
       canvas.drawLine(Offset(40, y), Offset(size.width, y), Paint()..color = Colors.grey.withValues(alpha: 0.2)..strokeWidth = 1..style = PaintingStyle.stroke);
       
       textPainter.text = TextSpan(text: yLabels[i], style: const TextStyle(color: Colors.grey, fontSize: 10));
       textPainter.layout();
       textPainter.paint(canvas, Offset(0, y - 6));
    }

    canvas.drawLine(const Offset(40, 0), Offset(40, size.height), axisPaint);

    final double barWidth = 20;
    final double spacing = (size.width - 40) / (barData.isEmpty ? 1 : barData.length);

    for (int i = 0; i < barData.length; i++) {
       final x = 40 + (i * spacing) + (spacing - barWidth) / 2;
       final barHeight = size.height * barData[i];
       final rect = Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight);
       
       canvas.drawRRect(
         RRect.fromRectAndCorners(rect, topLeft: const Radius.circular(4), topRight: const Radius.circular(4)), 
         (i == touchedIndex) ? touchedPaint : paint
       );
       
       textPainter.text = TextSpan(text: xLabels[i], style: const TextStyle(color: Colors.grey, fontSize: 10));
       textPainter.layout();
       textPainter.paint(canvas, Offset(x + (barWidth - textPainter.width)/2, size.height + 5));
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.touchedIndex != touchedIndex || oldDelegate.barData != barData;
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF00C853)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
      
    final dotPaint = Paint()
      ..color = const Color(0xFF00C853)
      ..style = PaintingStyle.fill;
    
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final yLabels = ["0", "200k", "400k", "600k", "800k"];
    final double yStep = size.height / (yLabels.length - 1);
    
    for (int i = 0; i < yLabels.length; i++) {
       final y = size.height - (i * yStep);
       canvas.drawLine(Offset(50, y), Offset(size.width, y), Paint()..color = Colors.grey.withValues(alpha: 0.2)..strokeWidth = 1);
       
       textPainter.text = TextSpan(text: yLabels[i], style: const TextStyle(color: Colors.grey, fontSize: 10));
       textPainter.layout();
       textPainter.paint(canvas, Offset(0, y - 6));
    }
    
     canvas.drawLine(const Offset(50, 0), Offset(50, size.height), Paint()..color = Colors.grey.withValues(alpha: 0.5));

    final dataPoints = [0.45, 0.52, 0.48, 0.6, 0.63, 0.75]; 
    final xLabels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"];
    final double spacing = (size.width - 50) / (dataPoints.length - 1); 

    final path = Path();
    final List<Offset> points = [];

    for (int i = 0; i < dataPoints.length; i++) {
      final x = 50 + (i * spacing);
      final y = size.height - (dataPoints[i] * size.height);
      points.add(Offset(x, y));
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      
      textPainter.text = TextSpan(text: xLabels[i], style: const TextStyle(color: Colors.grey, fontSize: 10));
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width/2, size.height + 5));
    }
    
    canvas.drawPath(path, linePaint);
    
    for (var point in points) {
      canvas.drawCircle(point, 6, Paint()..color = Colors.white); 
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(point, 4, dotBorderPaint); 
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
