import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sauda1/core/app_router.dart';
import '../providers/auditor_provider.dart';

class AuditorQRPairingScreen extends StatefulWidget {
  const AuditorQRPairingScreen({super.key});

  @override
  State<AuditorQRPairingScreen> createState() => _AuditorQRPairingScreenState();
}

class _AuditorQRPairingScreenState extends State<AuditorQRPairingScreen> {
  final TextEditingController _cartIdController = TextEditingController();

  @override
  void dispose() {
    _cartIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Audit Cart Pairing"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: const TextStyle(
          color: Color(0xFF0D1B2A),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
             const SizedBox(height: 10),
             const Text(
               "Scan cart QR code",
               style: TextStyle(
                 color: Color(0xFF6A6A8B),
                 fontSize: 14,
               ),
             ),
             const SizedBox(height: 30),

             // Scanner Area
             Container(
               margin: const EdgeInsets.symmetric(horizontal: 40),
               width: double.infinity,
               height: 320,
               decoration: BoxDecoration(
                 color: const Color(0xFF2D3344), // Dark scan background
                 borderRadius: BorderRadius.circular(30),
               ),
               child: Stack(
                 alignment: Alignment.center,
                 children: [
                   const Icon(Icons.qr_code_2, color: Colors.white24, size: 80),
                   const Positioned(
                     top: 20,
                     right: 20,
                     child: Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 24),
                   ),
                   // Corner Brackets
                   _buildCornerBracket(top: 40, left: 40, isTop: true, isLeft: true),
                   _buildCornerBracket(top: 40, right: 40, isTop: true, isLeft: false),
                   _buildCornerBracket(bottom: 40, left: 40, isTop: false, isLeft: true),
                   _buildCornerBracket(bottom: 40, right: 40, isTop: false, isLeft: false),
                   
                   // Horizontal Line
                   Positioned(
                     bottom: 80,
                     left: 60,
                     right: 60,
                     child: Container(
                       height: 2,
                       color: const Color(0xFFAA00FF), 
                     ),
                   )

                 ],
               ),
             ),
             const SizedBox(height: 30),
             
             const Text(
               "Scan Cart QR Code to Begin Audit",
               textAlign: TextAlign.center,
               style: TextStyle(
                 color: Color(0xFF0D1B2A),
                 fontWeight: FontWeight.w600,
                 fontSize: 16,
               ),
             ),
             const SizedBox(height: 8),
             const Text(
               "Position the QR code within the frame",
               textAlign: TextAlign.center,
               style: TextStyle(
                 color: Color(0xFF6A6A8B),
                 fontSize: 14,
               ),
             ),
             
             const SizedBox(height: 30),

             // Manual ID Input for Simulation
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 40),
               child: TextField(
                 controller: _cartIdController,
                 decoration: InputDecoration(
                   hintText: "Enter Cart ID (from Console or Shopping app)",
                   prefixIcon: const Icon(Icons.link, color: Color(0xFFAA00FF)),
                   focusedBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(16),
                     borderSide: const BorderSide(color: Color(0xFFAA00FF)),
                   ),
                   border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(16),
                   ),
                 ),
               ),
             ),
             const SizedBox(height: 16),

             // Simulate Button
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 40),
               child: SizedBox(
                 width: double.infinity,
                 height: 56,
                 child: ElevatedButton(
                   onPressed: () {
                     final cartId = _cartIdController.text.trim();
                     if (cartId.isNotEmpty) {
                       context.read<AuditorProvider>().listenToCart(cartId);
                       Navigator.pushReplacementNamed(context, AppRouter.auditCart);
                     } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text("Please enter a Cart ID to simulate")),
                       );
                     }
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFFAA00FF),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(16),
                     ),
                   ),
                   child: const Text(
                     "Link Cart & Start Audit",
                     style: TextStyle(
                       color: Colors.white, 
                       fontSize: 16, 
                       fontWeight: FontWeight.bold
                      ),
                   ),
                 ),
               ),
             ),

             const SizedBox(height: 40),

             // Instructions
             Container(
               margin: const EdgeInsets.symmetric(horizontal: 20),
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 color: const Color(0xFFFAFAFA),
                 borderRadius: BorderRadius.circular(20),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text(
                     "Audit Instructions",
                     style: TextStyle(
                       fontWeight: FontWeight.bold,
                       fontSize: 14,
                       color: Color(0xFF0D1B2A),
                     ),
                   ),
                   const SizedBox(height: 12),
                   _buildInstructionRow("1.", "Scan the cart QR code"),
                   const SizedBox(height: 8),
                   _buildInstructionRow("2.", "Verify each item in the cart"),
                 ],
               ),
             ),
             const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerBracket({double? top, double? bottom, double? left, double? right, required bool isTop, required bool isLeft}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? const BorderSide(color: Color(0xFFAA00FF), width: 3) : BorderSide.none,
            bottom: !isTop ? const BorderSide(color: Color(0xFFAA00FF), width: 3) : BorderSide.none,
            left: isLeft ? const BorderSide(color: Color(0xFFAA00FF), width: 3) : BorderSide.none,
            right: !isLeft ? const BorderSide(color: Color(0xFFAA00FF), width: 3) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
             topLeft: (isTop && isLeft) ? const Radius.circular(12) : Radius.zero,
             topRight: (isTop && !isLeft) ? const Radius.circular(12) : Radius.zero,
             bottomLeft: (!isTop && isLeft) ? const Radius.circular(12) : Radius.zero,
             bottomRight: (!isTop && !isLeft) ? const Radius.circular(12) : Radius.zero,
          )
        ),
      ),
    );
  }

  Widget _buildInstructionRow(String number, String text) {
    return Row(
      children: [
        Text(
          number,
          style: const TextStyle(
             color: Color(0xFFAA00FF),
             fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
             color: Color(0xFF6A6A8B),
             fontSize: 14,
          ),
        ),
      ],
    );
  }
}
