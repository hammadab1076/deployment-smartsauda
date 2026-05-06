import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sauda1/core/app_router.dart';
import 'package:smart_sauda1/core/app_colors.dart';
import 'package:smart_sauda1/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_sauda1/core/widgets/dialogs/help_support_dialog.dart';
import 'package:smart_sauda1/core/widgets/dialogs/preferences_dialog.dart';

class AuditorProfileScreen extends StatelessWidget {
  const AuditorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final user = auth.user;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                   // Custom AppBar / Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       GestureDetector(
                         onTap: () => Navigator.pop(context),
                         child: const Icon(Icons.arrow_back_ios, size: 20),
                       ),
                       const Text("Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(width: 20), // Balance
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Profile Header (Avatar + Name)
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFFAA00FF), // Purple for Auditor
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.assignment_ind_outlined, color: Colors.white, size: 40),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Auditor User',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Auditor',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                      )
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Contact Info Cards
                  _buildInfoCard(Icons.email_outlined, "Email", user?.email ?? "auditor@smartsauda.com"),
                  const SizedBox(height: 16),
                  _buildInfoCard(Icons.phone_outlined, "Phone", "+92 312 3456789"),

                  const SizedBox(height: 30),
                  const Align(alignment: Alignment.centerLeft, child: Text("Settings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                  const SizedBox(height: 16),

                  // Settings List
                  _buildSettingTile(
                    icon: Icons.history, 
                    color: Colors.blue, 
                    title: "Audit History", 
                    subtitle: "View past audits",
                    onTap: () => Navigator.pushNamed(context, AppRouter.auditHistory),
                  ),
                  const SizedBox(height: 12),
                   _buildSettingTile(
                    icon: Icons.settings_outlined, 
                    color: Colors.orange, 
                    title: "Preferences", 
                    subtitle: "App settings",
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const PreferencesDialog(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingTile(
                    icon: Icons.help_outline, 
                    color: Colors.purple, 
                    title: "Help & Support", 
                    subtitle: "Get assistance",
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const HelpSupportDialog(),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                         auth.logout();
                         Navigator.pushNamedAndRemoveUntil(context, AppRouter.roleSelection, (_) => false);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFFEF2F2), // Light Red Bg
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.logout, color: AppColors.danger),
                      label: const Text("Logout", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
           Icon(icon, color: Colors.grey[500], size: 22),
           const SizedBox(width: 16),
           Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
               const SizedBox(height: 2),
               Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
             ],
           )
        ],
      ),
    );
  }

  Widget _buildSettingTile({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
