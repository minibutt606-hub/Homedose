import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homedose/constants/app_colors.dart';
import 'package:homedose/screens/auth/login/login_screen.dart';
import 'package:homedose/controllers/auth_controller.dart';
import 'package:homedose/widgets/custom_text_field.dart';
import 'package:homedose/widgets/social_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthController _authController = Get.put(AuthController());
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isPasswordHintChecked = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
              const SizedBox(height: 30),
              // Logo
              Image.asset(
                'assets/images/logo.png',

                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'Sign Up',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create an account to continue',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 24),
              // Username
              CustomTextField(
                label: 'Username',
                hint: 'Enter your Username',
                controller: _usernameController,
                suffixIcon: const Icon(
                  Icons.person_outline,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 16),
              // Email
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
              const SizedBox(height: 16),
              // Password
              CustomTextField(
                label: 'Password',
                hint: 'Enter password',
                controller: _passwordController,
                obscureText: _obscurePassword,
                suffixIcon: GestureDetector(
                  onTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textGrey,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _isPasswordHintChecked,
                    onChanged: (val) =>
                        setState(() => _isPasswordHintChecked = val ?? false),
                    activeColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    side: const BorderSide(color: AppColors.textGrey),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Password must be at least 8 character, uppercase, lowercase, and unique code like #%!',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Sign Up Button
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _authController.isLoading.value
                        ? null
                        : () => _authController.register(
                            name: _usernameController.text.trim(),
                            email: _emailController.text.trim(),
                            password: _passwordController.text,
                          ),
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
                    child: _authController.isLoading.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Sign Up',
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
              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Or Sign Up with',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textBlack,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                ],
              ),
              const SizedBox(height: 14),
              // Google Button
              SocialButton(
                icon: Image.asset(
                  'assets/images/google_logo.png',
                  height: 24,
                  width: 24,
                  fit: BoxFit.contain,
                ),
                label: 'Continue with Google',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              // Apple Button
              SocialButton(
                icon: const Icon(Icons.apple, size: 24, color: Colors.black),
                label: 'Continue with Apple ID',
                onTap: () {},
              ),
              const SizedBox(height: 20),
              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textBlack,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.to(() => const LoginScreen()),
                    child: Text(
                      'Login',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.primaryTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
