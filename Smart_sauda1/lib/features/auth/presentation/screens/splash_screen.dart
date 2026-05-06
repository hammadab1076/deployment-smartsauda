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
      backgroundColor: const Color(0xFF00C853), // Professional vibrant green background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart,
              size: 110, // Increased size
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              "Smart Sauda",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Smart Shopping Cart System",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
