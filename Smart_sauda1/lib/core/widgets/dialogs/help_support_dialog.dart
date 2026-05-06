import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app_colors.dart';

class HelpSupportDialog extends StatelessWidget {
  const HelpSupportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: const Text("Help & Support", style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSupportItem(Icons.chat_bubble_outline, "Live Chat", "Talk to our support team"),
          SizedBox(height: 12.h),
          _buildSupportItem(Icons.email_outlined, "Email Support", "support@smartsauda.com"),
          SizedBox(height: 12.h),
          _buildSupportItem(Icons.phone_outlined, "Phone", "+92 300 1234567"),
          SizedBox(height: 12.h),
          _buildSupportItem(Icons.help_outline, "FAQs", "Read frequently asked questions"),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSupportItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp)),
              Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
            ],
          ),
        ),
      ],
    );
  }
}
