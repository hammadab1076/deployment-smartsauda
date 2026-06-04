import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:smart_sauda1/core/app_router.dart';
import '../providers/auditor_provider.dart';

class AuditorQRPairingScreen extends StatefulWidget {
  const AuditorQRPairingScreen({super.key});

  @override
  State<AuditorQRPairingScreen> createState() => _AuditorQRPairingScreenState();
}

class _AuditorQRPairingScreenState extends State<AuditorQRPairingScreen> {
  MobileScannerController? _controller;
  bool _scanned = false;

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

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _scanned = true);
    _controller?.stop();

    context.read<AuditorProvider>().listenToCart(raw);
    Navigator.pushReplacementNamed(context, AppRouter.auditCart);
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
              "Audit Cart Pairing",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 2),
            Text(
              "Scan cart QR code to begin audit",
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Live camera
          MobileScanner(
            controller: _controller!,
            onDetect: _onDetect,
          ),

          // Corner frame overlay (purple theme for auditor)
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
                  // Scan line
                  Positioned(
                    top: 0, bottom: 0, left: 20, right: 20,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(height: 2, color: const Color(0xFFAA00FF).withOpacity(0.7)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom info
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner, color: Color(0xFFAA00FF), size: 32),
                  SizedBox(height: 12),
                  Text(
                    "Point camera at the QR code sticker on the smart cart",
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
            top:    isTop    ? const BorderSide(color: Color(0xFFAA00FF), width: 4) : BorderSide.none,
            bottom: !isTop   ? const BorderSide(color: Color(0xFFAA00FF), width: 4) : BorderSide.none,
            left:   isLeft   ? const BorderSide(color: Color(0xFFAA00FF), width: 4) : BorderSide.none,
            right:  !isLeft  ? const BorderSide(color: Color(0xFFAA00FF), width: 4) : BorderSide.none,
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
