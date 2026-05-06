import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_sauda1/core/app_router.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Set Status Bar Color to match the design (likely white or transparent)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: Colors.white, // Or very light grey equivalent to design
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60), // Top spacing
              // Header
              const Text(
                "Welcome to Smart Sauda",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A), // Dark Navy/Black text
                  fontFamily: 'Roboto', // Assuming default or specific font
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Select your role to continue",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6C757D), // Grey text
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 48), // Spacing before cards

              // Role Cards
              _RoleCard(
                title: "Customer",
                subtitle: "Shop with smart cart",
                icon: Icons.person_outline_rounded,
                mainColor: const Color(0xFF00C853), // Green
                bgColor: const Color(0xFFE8F5E9), // Light Green
                onTap: () {
                   Navigator.pushNamed(
                    context,
                    AppRouter.login,
                    arguments: {"role": "customer"},
                  );
                },
              ),
              const SizedBox(height: 16),
              _RoleCard(
                title: "Auditor",
                subtitle: "Verify cart contents",
                icon: Icons.assignment_outlined,
                mainColor: const Color(0xFFAA00FF), // Purple
                bgColor: const Color(0xFFF3E5F5), // Light Purple
                onTap: () {
                   Navigator.pushNamed(
                    context,
                    AppRouter.login,
                    arguments: {"role": "auditor"},
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color mainColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.mainColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4), // changes position of shadow
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: mainColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1B2A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6C757D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
