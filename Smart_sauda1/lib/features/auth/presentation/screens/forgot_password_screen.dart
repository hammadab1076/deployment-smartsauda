import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? role;
  const ForgotPasswordScreen({super.key, this.role});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _success = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch ((widget.role ?? 'customer').toLowerCase()) {
      case 'admin':   return const Color(0xFF2962FF);
      case 'auditor': return const Color(0xFFAA00FF);
      default:        return const Color(0xFF00C853);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final ok = await auth.resetPassword(
      _emailCtrl.text.trim(),
      _newPassCtrl.text.trim(),
    );
    if (!mounted) return;
    if (ok) setState(() => _success = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: _success ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 60.h),
        Container(
          width: 100.w,
          height: 100.w,
          decoration: BoxDecoration(
            color: _accentColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle_outline, color: _accentColor, size: 56.sp),
        ),
        SizedBox(height: 32.h),
        Text(
          "Password Reset!",
          style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0D1B2A)),
        ),
        SizedBox(height: 12.h),
        Text(
          "Your password has been updated successfully.\nYou can now log in with your new password.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6C757D), height: 1.5),
        ),
        SizedBox(height: 48.h),
        SizedBox(
          width: double.infinity,
          height: 56.h,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              elevation: 0,
            ),
            child: Text("Back to Login", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),
              // Icon + Title
              Row(
                children: [
                  Container(
                    width: 64.w,
                    height: 64.w,
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(Icons.lock_reset_outlined, color: _accentColor, size: 32.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Forgot Password",
                          style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0D1B2A)),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "Enter your email and new password",
                          style: TextStyle(fontSize: 13.sp, color: const Color(0xFF6C757D)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40.h),

              // Email
              _label("Registered Email"),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
                decoration: _inputDeco(hint: "Enter your registered email", icon: Icons.mail_outline_rounded),
              ),
              SizedBox(height: 24.h),

              // New Password
              _label("New Password"),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _newPassCtrl,
                obscureText: _obscureNew,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
                decoration: _inputDeco(
                  hint: "Enter new password",
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey, size: 20.sp),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // Confirm Password
              _label("Confirm New Password"),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _confirmPassCtrl,
                obscureText: _obscureConfirm,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm your password';
                  if (v != _newPassCtrl.text) return 'Passwords do not match';
                  return null;
                },
                decoration: _inputDeco(
                  hint: "Re-enter new password",
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey, size: 20.sp),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              SizedBox(height: 32.h),

              // Error
              if (auth.errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(auth.errorMessage!, style: TextStyle(color: Colors.red.shade700, fontSize: 13.sp)),
                  ),
                ),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: auth.loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    elevation: 0,
                  ),
                  child: auth.loading
                      ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("Reset Password", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(fontSize: 16.sp, color: const Color(0xFF424242), fontWeight: FontWeight.w500),
      );

  InputDecoration _inputDeco({required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: const Color(0xFF9E9E9E), fontSize: 14.sp),
      prefixIcon: Icon(icon, color: const Color(0xFF9E9E9E), size: 20.sp),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide(color: _accentColor, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: const BorderSide(color: Colors.red)),
    );
  }
}
