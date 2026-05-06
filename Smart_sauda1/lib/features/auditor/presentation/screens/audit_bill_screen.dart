import 'package:flutter/material.dart';
import 'package:smart_sauda1/core/widgets/card_container.dart';
import 'package:smart_sauda1/core/styles.dart';
import 'package:smart_sauda1/core/widgets/app_button.dart';

class AuditBillScreen extends StatelessWidget {
  const AuditBillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const total = 480;

    return Scaffold(
      appBar: AppBar(title: const Text("Audit Bill Summary")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CardContainer(
              child: Column(
                children: [
                  Text("Total Items: 3", style: AppTextStyles.subHeading),
                  const SizedBox(height: 6),
                  Text("Total Price: Rs $total", style: AppTextStyles.heading),
                ],
              ),
            ),
            const Spacer(),
            AppButton(
              text: "Submit Audit",
              onTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}
