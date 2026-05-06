import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sauda1/core/app_colors.dart';
import 'package:smart_sauda1/core/styles.dart';
import '../providers/checkout_provider.dart';

class BarcodeScanScreen extends StatelessWidget {
  const BarcodeScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final checkout = context.read<CheckoutProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Barcode Scanner")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Icon(Icons.document_scanner, size: 160, color: AppColors.primary),
            const SizedBox(height: 20),
            Text("Scan Product Barcode", style: AppTextStyles.heading),
            const SizedBox(height: 10),
            Text("Align barcode inside the frame to scan.", style: AppTextStyles.normal),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  // Simulate finding a product (e.g., Bread)
                  await checkout.scanAndAddProduct("123456");
                  
                  if (context.mounted) {
                    if (checkout.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(checkout.error!),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else {
                      final productName = checkout.scannedProductName ?? "Item";
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Added to cart: $productName"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Simulate Barcode Scan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }
}
