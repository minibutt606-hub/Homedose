import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homedose/constants/app_colors.dart';
import 'package:homedose/services/submit_feedback_service.dart';
import 'package:homedose/widgets/premium_snackbar.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _msgController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate email if user is logged in
    final storage = GetStorage();
    final user = storage.read('user');
    if (user != null && user['email'] != null) {
      _emailController.text = user['email'].toString();
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _emailController.dispose();
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _submitSupportQuery() async {
    final String subject = _subjectController.text.trim();
    final String email = _emailController.text.trim();
    final String message = _msgController.text.trim();

    if (subject.isEmpty) {
      PremiumSnackbar.showError(title: 'Error', message: 'Please enter a subject');
      return;
    }
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      PremiumSnackbar.showError(title: 'Error', message: 'Please enter a valid email address');
      return;
    }
    if (message.isEmpty) {
      PremiumSnackbar.showError(title: 'Error', message: 'Please enter your message');
      return;
    }

    setState(() => _isLoading = true);

    final result = await SubmitFeedbackService.submitFeedback(
      subject: '[Support] $subject',
      email: email,
      message: message,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Get.back();
      PremiumSnackbar.showSuccess(
        title: 'Email Sent',
        message: 'Your message has been sent to admin@gmail.com and support team.',
      );
    } else {
      PremiumSnackbar.showError(
        title: 'Failed',
        message: result['message'] ?? 'Failed to send message. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Email Support',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send an Email to Support',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Have any questions or issues? Contact us at admin@gmail.com or send a message below and it will reach our admin panel immediately.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textGrey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),

              _buildLabel('Subject'),
              _buildTextField(hint: 'Enter subject of your query', controller: _subjectController),
              const SizedBox(height: 20),

              _buildLabel('Your Email'),
              _buildTextField(
                hint: 'Enter your email address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              _buildLabel('Message'),
              _buildTextField(
                hint: 'Describe your issue or query...',
                controller: _msgController,
                maxLines: 6,
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitSupportQuery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    disabledBackgroundColor: AppColors.primaryTeal.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Send Email',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: AppColors.textGrey,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textBlack),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: AppColors.textGrey, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
