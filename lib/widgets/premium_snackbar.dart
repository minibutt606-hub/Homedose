import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homedose/constants/app_colors.dart';

class PremiumSnackbar {
  static void showSuccess({
    required String title,
    required String message,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      backgroundGradient: LinearGradient(
        colors: [
          const Color(0xFF1E293B).withValues(alpha: 0.95), // Deep Slate-800
          const Color(0xFF0F172A).withValues(alpha: 0.95), // Deep Slate-900
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      titleText: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      messageText: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
      icon: Container(
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle_outline_rounded,
          color: AppColors.primaryTeal,
          size: 24,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderRadius: 16,
      borderColor: AppColors.primaryTeal.withValues(alpha: 0.3),
      borderWidth: 1.5,
      boxShadows: [
        BoxShadow(
          color: AppColors.primaryTeal.withValues(alpha: 0.15),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
      duration: const Duration(seconds: 4),
      barBlur: 10.0,
    );
  }

  static void showError({
    required String title,
    required String message,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      backgroundGradient: LinearGradient(
        colors: [
          const Color(0xFF2C1C1C).withValues(alpha: 0.95), // Dark Red/Slate
          const Color(0xFF1F1111).withValues(alpha: 0.95), // Darker Red/Slate
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      titleText: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      messageText: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
      icon: Container(
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.error_outline_rounded,
          color: Colors.redAccent,
          size: 24,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderRadius: 16,
      borderColor: Colors.redAccent.withValues(alpha: 0.3),
      borderWidth: 1.5,
      boxShadows: [
        BoxShadow(
          color: Colors.redAccent.withValues(alpha: 0.15),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
      duration: const Duration(seconds: 4),
      barBlur: 10.0,
    );
  }
}
