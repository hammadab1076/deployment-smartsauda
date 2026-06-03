// dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sauda1/core/app_router.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final authProvider = context.read<AuthProvider>();

    // Force sign out on app start so it always asks for role selection per user requirement
    await authProvider.logout();

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Always navigate to role selection
    Navigator.pushReplacementNamed(context, AppRouter.roleSelection);
  }

  void _navigateToRoleDashboard(String role) {
    final route = switch (role) {
      'admin' => AppRouter.adminDashboard,
      'auditor' => AppRouter.auditorDashboard,
      'customer' => AppRouter.customerDashboard,
      _ => AppRouter.roleSelection,
    };
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Icon at exact mathematical center — drawn with widgets, perfectly centred
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFF00C853),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shopping_cart_rounded,
                      color: Color(0xFF00C853),
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // App name below center
          const Align(
            alignment: Alignment(0, 0.72),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Smart Sauda",
                  style: TextStyle(
                    color: Color(0xFF0D1B2A),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Smart Shopping Cart System",
                  style: TextStyle(
                    color: Color(0xFF6C757D),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Spinner at the bottom
          const Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
