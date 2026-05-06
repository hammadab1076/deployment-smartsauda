import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_sauda1/core/app_colors.dart';
import 'package:smart_sauda1/core/styles.dart';
import '../providers/checkout_provider.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 120, color: AppColors.success),
            const SizedBox(height: 20),
            Text("Payment Successful!", style: AppTextStyles.heading),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                context.read<CheckoutProvider>().reset();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text("Back to Home"),
            ),
          ],
        ),
      ),
    );
  }
}
