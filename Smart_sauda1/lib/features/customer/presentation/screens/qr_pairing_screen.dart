import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sauda1/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_sauda1/features/customer/presentation/providers/checkout_provider.dart';

class QRPairingScreen extends StatelessWidget {
  const QRPairingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: const [
            Text(
              "Pair Smart Cart",
              style: TextStyle(
                color: Color(0xFF0D1B2A),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Scan QR code on cart",
              style: TextStyle(
                color: Color(0xFF6C757D),
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Scanner Placeholder
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF263238), // Dark color like in image
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Corner Markers
                    Positioned(
                      top: 40,
                      left: 40,
                      child: _CornerMarker(rotation: 0),
                    ),
                    Positioned(
                      top: 40,
                      right: 40,
                      child: _CornerMarker(rotation: 90),
                    ),
                    Positioned(
                      bottom: 40,
                      left: 40,
                      child: _CornerMarker(rotation: 270),
                    ),
                    Positioned(
                      bottom: 40,
                      right: 40,
                      child: _CornerMarker(rotation: 180),
                    ),
                    
                    // Center Icon
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.qr_code_2, color: Colors.white30, size: 80),
                        Icon(Icons.qr_code_scanner, color: Colors.white10, size: 40),
                      ],
                    ),

                    // Top Right Camera Icon
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Icon(Icons.camera_alt_outlined, color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Text
            const Text(
              "Position QR Code in Frame",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Look for the QR code sticker on your smart\ncart handle",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6C757D),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                   final auth = context.read<AuthProvider>();
                   final checkout = context.read<CheckoutProvider>();
                   
                   if (auth.user != null) {
                     // scannerId links this cart to the physical NFC scanner
                     await checkout.startNewCartSession(
                       auth.user!.id,
                       scannerId: 'SCANNER_01',
                     );
                     if (context.mounted) {
                       Navigator.pop(context);
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(content: Text("Cart Paired: ${checkout.activeCartId}")),
                       );
                     }
                   }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Simulate QR Scan",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CornerMarker extends StatelessWidget {
  final double rotation;

  const _CornerMarker({required this.rotation});

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: AlwaysStoppedAnimation(rotation / 360),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF00C853), width: 4), // Green
            left: BorderSide(color: Color(0xFF00C853), width: 4),
          ),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
        ),
      ),
    );
  }
}
