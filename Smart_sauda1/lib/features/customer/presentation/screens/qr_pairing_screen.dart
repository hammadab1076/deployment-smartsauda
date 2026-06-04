import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:smart_sauda1/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_sauda1/features/customer/presentation/providers/checkout_provider.dart';

class QRPairingScreen extends StatefulWidget {
  const QRPairingScreen({super.key});

  @override
  State<QRPairingScreen> createState() => _QRPairingScreenState();
}

class _QRPairingScreenState extends State<QRPairingScreen> {
  MobileScannerController? _controller;
  bool _scanned = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned || _loading) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() { _scanned = true; _loading = true; });
    await _controller?.stop();

    final auth     = context.read<AuthProvider>();
    final checkout = context.read<CheckoutProvider>();

    final error = await checkout.startNewCartSession(
      auth.user!.id,
      cartId:    raw,
      scannerId: 'SCANNER_01',
    );

    if (!mounted) return;

    if (error != null) {
      // Cart is busy or other error — show message and let user retry
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      setState(() { _scanned = false; _loading = false; });
      _controller?.start();
      return;
    }

    // Success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Cart paired: $raw"),
        backgroundColor: const Color(0xFF00C853),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          children: [
            Text(
              "Pair Smart Cart",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 2),
            Text(
              "Scan the QR code on your cart",
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller!,
            onDetect: _onDetect,
          ),

          // Corner frame overlay
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                children: [
                  _corner(top: 0, left: 0, isTop: true, isLeft: true),
                  _corner(top: 0, right: 0, isTop: true, isLeft: false),
                  _corner(bottom: 0, left: 0, isTop: false, isLeft: true),
                  _corner(bottom: 0, right: 0, isTop: false, isLeft: false),
                ],
              ),
            ),
          ),

          // Bottom label
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_loading)
                    const Column(
                      children: [
                        CircularProgressIndicator(color: Color(0xFF00C853)),
                        SizedBox(height: 12),
                        Text("Connecting to cart...",
                            style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    )
                  else
                    const Text(
                      "Position the QR code on the cart handle inside the frame",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner({double? top, double? bottom, double? left, double? right,
      required bool isTop, required bool isLeft}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          border: Border(
            top:    isTop    ? const BorderSide(color: Color(0xFF00C853), width: 4) : BorderSide.none,
            bottom: !isTop   ? const BorderSide(color: Color(0xFF00C853), width: 4) : BorderSide.none,
            left:   isLeft   ? const BorderSide(color: Color(0xFF00C853), width: 4) : BorderSide.none,
            right:  !isLeft  ? const BorderSide(color: Color(0xFF00C853), width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft:     (isTop && isLeft)   ? const Radius.circular(8) : Radius.zero,
            topRight:    (isTop && !isLeft)  ? const Radius.circular(8) : Radius.zero,
            bottomLeft:  (!isTop && isLeft)  ? const Radius.circular(8) : Radius.zero,
            bottomRight: (!isTop && !isLeft) ? const Radius.circular(8) : Radius.zero,
          ),
        ),
      ),
    );
  }
}
