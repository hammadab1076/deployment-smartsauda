import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_sauda1/core/app_router.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: ConstrainedBox(
              // mirrors max-w-sm (384 px) from the HTML
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  const Text(
                    "Welcome to Smart Sauda",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF191C1E),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Select your role to continue",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF5C5F62),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // ── Customer Card ────────────────────────────────────────
                  _RoleCard(
                    title: "Customer",
                    description: "Shop with smart cart technology",
                    actionText: "Enter Shopping Mode",
                    icon: Icons.person_rounded,
                    mainColor: const Color(0xFF00C853),
                    bgColor: const Color(0xFFE8F5E9),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.login,
                      arguments: {"role": "customer"},
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Auditor Card ─────────────────────────────────────────
                  _RoleCard(
                    title: "Auditor",
                    description: "Verify cart contents and checkout flows",
                    actionText: "Access Auditor Panel",
                    icon: Icons.verified_user_outlined,
                    mainColor: const Color(0xFFAA00FF),
                    bgColor: const Color(0xFFF3E5F5),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.login,
                      arguments: {"role": "auditor"},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final String actionText;
  final IconData icon;
  final Color mainColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.actionText,
    required this.icon,
    required this.mainColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1E3E4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          splashColor: mainColor.withOpacity(0.06),
          highlightColor: mainColor.withOpacity(0.03),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon bubble
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: mainColor, size: 30),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF191C1E),
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5C5F62),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),

                // Action link — mirrors the HTML anchor style
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      actionText.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: mainColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, color: mainColor, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
