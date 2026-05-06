import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_sauda1/core/app_router.dart';
import '../providers/auth_provider.dart';
import 'package:smart_sauda1/core/utils/validators.dart';

class SignupScreen extends StatefulWidget {
  final String? role;
  const SignupScreen({super.key, this.role});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  // --- Helpers for Role-Specific Styles ---

  Color _getIconBgColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFE3F2FD);
      case 'auditor':
        return const Color(0xFFF3E5F5);
      case 'customer':
      default:
        return const Color(0xFFE8F5E9);
    }
  }

  Color _getIconColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFF2962FF);
      case 'auditor':
        return const Color(0xFFAA00FF);
      case 'customer':
      default:
        return const Color(0xFF00C853);
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.shield_outlined;
      case 'auditor':
        return Icons.assignment_outlined;
      case 'customer':
      default:
        return Icons.person_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role ?? 'customer';
    final primaryActionColor = const Color(0xFF00C853);

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
          child: Consumer<AuthProvider>(
            builder: (context, auth, child) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.h),
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 64.w,
                          height: 64.w,
                          decoration: BoxDecoration(
                            color: _getIconBgColor(role),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Icon(
                            _getRoleIcon(role),
                            color: _getIconColor(role),
                            size: 32.sp,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${role[0].toUpperCase()}${role.substring(1)} Sign Up',
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0D1B2A),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Create your new account',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: const Color(0xFF6C757D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 40.h),

                    // Name Field
                    _buildInputLabel("Full Name"),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: nameCtrl,
                      validator: Validators.validateName,
                      decoration: _inputDecoration(
                        hint: "Enter your full name",
                        icon: Icons.person_outline,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Email Field
                    _buildInputLabel("Email Address"),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: emailCtrl,
                      validator: Validators.validateEmail,
                      decoration: _inputDecoration(
                        hint: "Enter your email address",
                        icon: Icons.mail_outline_rounded,
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Password Field
                    _buildInputLabel("Password"),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: passCtrl,
                      obscureText: _obscurePassword,
                      validator: Validators.validatePassword,
                      decoration: _inputDecoration(
                        hint: "Create a password",
                        icon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey,
                            size: 20.sp,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // Loading / Button
                    if (auth.loading)
                      const Center(child: CircularProgressIndicator())
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 56.h,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                                await auth.signup(
                                nameCtrl.text.trim(),
                                emailCtrl.text.trim(),
                                passCtrl.text.trim(),
                                role,
                              ).then((_) {
                                if (!context.mounted) return;
                                if (auth.user != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Account created successfully!')),
                                  );

                                  // Navigate
                                  final r = auth.user?.role ?? 'customer';
                                  String route = AppRouter.customerDashboard;
                                  if (r == 'admin') route = AppRouter.adminDashboard;
                                  if (r == 'auditor') route = AppRouter.auditorDashboard;
                                  
                                  Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
                                }
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryActionColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Create Account",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    SizedBox(height: 24.h),
                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(color: const Color(0xFF6C757D), fontSize: 14.sp),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // Go back to Login
                          },
                          child: Text(
                            "Login",
                            style: TextStyle(
                              color: primaryActionColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16.sp,
        color: const Color(0xFF424242), // Dark grey
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: const Color(0xFF9E9E9E), fontSize: 14.sp),
      prefixIcon: Icon(icon, color: const Color(0xFF9E9E9E), size: 20.sp),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      contentPadding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: Color(0xFF00C853), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
