import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sauda1/core/app_router.dart';
import '../providers/auditor_provider.dart';

class AuditorDashboard extends StatefulWidget {
  const AuditorDashboard({super.key});

  @override
  State<AuditorDashboard> createState() => _AuditorDashboardState();
}

class _AuditorDashboardState extends State<AuditorDashboard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        context.read<AuditorProvider>().loadAuditorStats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), 
      body: SafeArea(
        child: Consumer<AuditorProvider>(
          builder: (context, auditor, child) {
            final stats = auditor.auditorStats;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Auditor Panel",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D1B2A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Verify cart contents",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRouter.auditorProfile),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFAA00FF).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_outline, color: Color(0xFFAA00FF), size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.assignment_outlined,
                          label: "Today's\nAudits",
                          value: "${stats['todaysAudits'] ?? 0}",
                          iconColor: const Color(0xFF00C853),
                          iconBg: const Color(0xFFE8F5E9),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          icon: null, 
                          label: "Discrepancies",
                          value: "${stats['discrepancies'] ?? 0}",
                          iconColor: Colors.transparent, 
                          iconBg: Colors.transparent,
                          isSimple: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Pair Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRouter.auditorQrPair)
                          .then((_) { if (mounted) context.read<AuditorProvider>().loadAuditorStats(); }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAA00FF), 
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                      label: const Text(
                        "Pair Cart for Audit",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Quick Actions
                  const Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionCard(
                    icon: Icons.shopping_basket_outlined,
                    title: "Audit Cart",
                    subtitle: "Verify items in cart",
                    iconColor: const Color(0xFFAA00FF),
                    iconBg: const Color(0xFFF3E5F5),
                    onTap: () => Navigator.pushNamed(context, AppRouter.auditCart)
                        .then((_) { if (mounted) context.read<AuditorProvider>().loadAuditorStats(); }),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: Icons.history,
                    title: "Audit History",
                    subtitle: "View past audits",
                    iconColor: const Color(0xFF2962FF),
                    iconBg: const Color(0xFFE3F2FD),
                    onTap: () => Navigator.pushNamed(context, AppRouter.auditHistory), 
                  ),
                  const SizedBox(height: 32),

                  // Audit Process
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF), 
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF3E5F5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Audit Process",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1B2A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildProcessStep("1. Scan QR code on cart"),
                        const SizedBox(height: 8),
                        _buildProcessStep("2. Verify items using NFC/Barcode"),
                        const SizedBox(height: 8),
                        _buildProcessStep("3. Compare with customer's cart"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData? icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color iconBg,
    bool isSimple = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isSimple && icon != null) ...[
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.centerLeft,
               child: Icon(icon, color: iconColor, size: 24),
            ),
             const SizedBox(height: 12),
          ] else if (isSimple) ...[
             const SizedBox(height: 4), 
          ],

          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B2A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color iconBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessStep(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF6A6A8B), 
        height: 1.5,
      ),
    );
  }
}
