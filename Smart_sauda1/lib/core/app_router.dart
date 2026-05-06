// dart
import 'package:flutter/material.dart';
import 'package:smart_sauda1/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:smart_sauda1/features/auditor/presentation/screens/auditor_dashboard.dart';
import 'package:smart_sauda1/features/auditor/presentation/screens/auditor_profile_screen.dart';
import 'package:smart_sauda1/features/auditor/presentation/screens/auditor_qr_pairing_screen.dart';
import 'package:smart_sauda1/features/auditor/presentation/screens/audit_cart_screen.dart';
import 'package:smart_sauda1/features/auditor/presentation/screens/audit_history_screen.dart';
import 'package:smart_sauda1/features/customer/presentation/screens/customer_dashboard.dart';
import 'package:smart_sauda1/features/auth/presentation/screens/login_screen.dart';
import 'package:smart_sauda1/features/auth/presentation/screens/signup_screen.dart';
import 'package:smart_sauda1/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:smart_sauda1/features/customer/presentation/screens/customer_profile_screen.dart';
import 'package:smart_sauda1/features/customer/presentation/screens/cart_screen.dart';
import 'package:smart_sauda1/features/customer/presentation/screens/qr_pairing_screen.dart';
import 'package:smart_sauda1/features/customer/presentation/screens/nfc_scan_screen.dart';
import 'package:smart_sauda1/features/customer/presentation/screens/barcode_scan_screen.dart';
import 'package:smart_sauda1/features/customer/presentation/screens/checkout_screen.dart';
import 'package:smart_sauda1/features/customer/presentation/screens/payment_success_screen.dart';
import 'package:smart_sauda1/features/customer/presentation/screens/purchase_history_screen.dart';
import 'package:smart_sauda1/features/customer/presentation/screens/invoice_screen.dart';

class AppRouter {
  static const String roleSelection = '/roleSelection';
  static const String adminDashboard = '/adminDashboard';
  static const String auditorDashboard = '/auditorDashboard';
  static const String customerDashboard = '/customerDashboard';
  static const String customerProfile = '/customerProfile';
  static const String qrPairing = '/qrPairing';
  static const String nfcScan = '/nfcScan';
  static const String barcodeScan = '/barcodeScan';
  static const String cart = '/cart';
  static const String purchaseHistory = '/purchaseHistory';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgotPassword';
  static const String checkout = '/checkout';
  static const String paymentSuccess = '/paymentSuccess';
  static const String invoice = '/invoice';
  
  // Admin Routes
  static const String adminProfile = '/adminProfile';
  static const String userManagement = '/userManagement';
  static const String invoices = '/invoices';
  static const String salesAnalytics = '/salesAnalytics';
  
  // Auditor Routes
  static const String auditorProfile = '/auditorProfile';
  static const String auditorQrPair = '/auditorQrPair';
  static const String auditCart = '/auditCart';
  static const String auditHistory = '/auditHistory';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (ctx) => const _AdminWebOnlyScreen());
      case auditorDashboard:
        return MaterialPageRoute(builder: (_) => const AuditorDashboard());
      case customerDashboard:
        return MaterialPageRoute(builder: (_) => const CustomerDashboard());
      case login:
        final args = settings.arguments;
        String? role;
        if (args is Map) {
          role = args['role'] as String?;
        } else if (args is String) {
          role = args;
        }
        return MaterialPageRoute(builder: (_) => LoginScreen(role: role));
      case signup:
        final args = settings.arguments;
        String? role;
        if (args is Map) {
          role = args['role'] as String?;
        } else if (args is String) {
          role = args;
        }
        return MaterialPageRoute(builder: (_) => SignupScreen(role: role));
      case forgotPassword:
        final fpArgs = settings.arguments;
        String? fpRole;
        if (fpArgs is Map) {
          fpRole = fpArgs['role'] as String?;
        } else if (fpArgs is String) {
          fpRole = fpArgs;
        }
        return MaterialPageRoute(builder: (_) => ForgotPasswordScreen(role: fpRole));
      case customerProfile:
        return MaterialPageRoute(builder: (_) => const CustomerProfileScreen());
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case qrPairing:
        return MaterialPageRoute(builder: (_) => const QRPairingScreen());
      case nfcScan:
        return MaterialPageRoute(builder: (_) => const NFCScanScreen());
      case barcodeScan:
        return MaterialPageRoute(builder: (_) => const BarcodeScanScreen());
      case purchaseHistory:
        return MaterialPageRoute(builder: (_) => const PurchaseHistoryScreen());
      case checkout:
        final args = settings.arguments as Map<String, dynamic>;
        final dynamicRawItems = args['items'] as List;
        final items = dynamicRawItems.map((e) => Map<String, dynamic>.from(e)).toList();
        
        return MaterialPageRoute(
          builder: (_) => CheckoutScreen(
            items: items,
            totalAmount: (args['totalAmount'] as num).toDouble(),
          ),
        );
      case paymentSuccess:
        return MaterialPageRoute(builder: (_) => const PaymentSuccessScreen());
      case invoice:
        final invArgs = settings.arguments as Map<String, dynamic>;
        final rawInvItems = invArgs['items'] as List;
        return MaterialPageRoute(
          builder: (_) => InvoiceScreen(
            items: rawInvItems.map((e) => Map<String, dynamic>.from(e)).toList(),
            totalAmount: (invArgs['totalAmount'] as num).toDouble(),
            paymentMethod: invArgs['paymentMethod'] as String,
            timestamp: invArgs['timestamp'] as String,
          ),
        );
      
      // Auditor Routes
      case auditorProfile:
        return MaterialPageRoute(builder: (_) => const AuditorProfileScreen());
      case auditorQrPair:
        return MaterialPageRoute(builder: (_) => const AuditorQRPairingScreen());
      case auditCart:
        return MaterialPageRoute(builder: (_) => const AuditCartScreen());
      case auditHistory:
        return MaterialPageRoute(builder: (_) => const AuditHistoryScreen());
      
      // Default
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}

class _AdminWebOnlyScreen extends StatelessWidget {
  const _AdminWebOnlyScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88, height: 88,
                  decoration: const BoxDecoration(color: Color(0xFFE3F2FD), shape: BoxShape.circle),
                  child: const Icon(Icons.computer_rounded, size: 44, color: Color(0xFF2962FF)),
                ),
                const SizedBox(height: 28),
                const Text(
                  "Admin Panel — Web Only",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A)),
                ),
                const SizedBox(height: 12),
                const Text(
                  "The Admin Panel has moved to the Smart Sauda POS web portal. Please use a browser to access it.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xFF6C757D), height: 1.5),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, AppRouter.roleSelection, (r) => false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2962FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text("Back to Role Selection",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
