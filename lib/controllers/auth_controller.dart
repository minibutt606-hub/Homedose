import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:homedose/constants/app_colors.dart';
import 'package:homedose/screens/auth/login/login_screen.dart';
import 'package:homedose/screens/main/main_screen.dart';
import 'package:homedose/services/login_service.dart';
import 'package:homedose/services/register_service.dart';
import 'package:homedose/services/forgot_password_service.dart';
import 'package:homedose/services/reset_password_service.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  var isForgotLoading = false.obs;
  var isResetLoading = false.obs;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (name.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter username',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return;
    }
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return;
    }
    if (password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return;
    }
    if (password.length < 8) {
      Get.snackbar(
        'Error',
        'Password must be at least 8 characters long',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return;
    }

    isLoading.value = true;

    final result = await RegisterService.register(
      name: name,
      email: email,
      password: password,
    );

    isLoading.value = false;

    if (result['success'] == true) {
      Get.snackbar(
        'Success',
        'Registration successful! Please login to continue.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryTeal,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      Get.offAll(() => LoginScreen(
        initialEmail: email,
        initialPassword: password,
      ));
    } else {
      Get.snackbar(
        'Registration Failed',
        result['message'] ?? 'Please check your information and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return;
    }
    if (password.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return;
    }

    isLoading.value = true;

    final result = await LoginService.login(
      email: email,
      password: password,
    );

    isLoading.value = false;

    if (result['success'] == true) {
      Get.snackbar(
        'Success',
        'Login successful!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryTeal,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      Get.offAll(() => const MainScreen());
    } else {
      Get.snackbar(
        'Login Failed',
        result['message'] ?? 'Please check your credentials and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  Future<void> forgotPassword({required String email}) async {
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return;
    }

    isForgotLoading.value = true;

    final result = await ForgotPasswordService.forgotPassword(email: email);

    isForgotLoading.value = false;

    if (result['success'] == true) {
      Get.snackbar(
        'Success',
        result['message'] ?? 'Password reset link sent successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryTeal,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 4),
      );
    } else {
      Get.snackbar(
        'Error',
        result['message'] ?? 'Unable to send reset link.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (token.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter the reset token',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return;
    }
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return;
    }
    if (password.isEmpty || password.length < 8) {
      Get.snackbar(
        'Error',
        'Password must be at least 8 characters long',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return;
    }
    if (password != passwordConfirmation) {
      Get.snackbar(
        'Error',
        'Passwords do not match',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return;
    }

    isResetLoading.value = true;

    final result = await ResetPasswordService.resetPassword(
      token: token,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );

    isResetLoading.value = false;

    if (result['success'] == true) {
      Get.snackbar(
        'Success',
        result['message'] ?? 'Password reset successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryTeal,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      Get.offAll(() => const LoginScreen());
    } else {
      Get.snackbar(
        'Error',
        result['message'] ?? 'Failed to reset password.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
    }
  }
}
