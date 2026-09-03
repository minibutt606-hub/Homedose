import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homedose/constants/app_colors.dart';
import 'package:homedose/controllers/auth_controller.dart';
import 'package:homedose/screens/auth/forgot_password/reset_password_screen.dart';
import 'package:homedose/widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submitForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      _authController.forgotPassword(email: email);
      return;
    }

    await _authController.forgotPassword(email: email);

    // Navigate to reset screen only if the API call succeeded
    if (!_authController.isForgotLoading.value) {
      Get.to(() => ResetPasswordScreen(email: email));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              Image.asset('assets/images/logo.png', height: 120),
              const SizedBox(height: 8),

              const SizedBox(height: 30),
              // Title
              Text(
                'Forgot Password',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                'Please enter your email. We will send you a link to reset your password. (Can we let the user know if their email exists in the database?)',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textGrey,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              // Email Field
              CustomTextField(
                label: 'Email',
                hint: 'Enter your email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                suffixIcon: const Icon(
                  Icons.mail_outline,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 28),
              // Submit Button
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _authController.isForgotLoading.value
                        ? null
                        : _submitForgotPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      disabledBackgroundColor: AppColors.primaryTeal.withValues(
                        alpha: 0.6,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _authController.isForgotLoading.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Submit',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Back to Login
              GestureDetector(
                onTap: () => Get.back(),
                child: Text(
                  'Back to Login',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
