import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:homedose/screens/get_started/get_started_screen.dart';
import 'package:homedose/screens/main/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final storage = GetStorage();
      final bool isLoggedIn = storage.read('isLoggedIn') ?? false;
      if (isLoggedIn) {
        Get.offAll(() => const MainScreen());
      } else {
        Get.offAll(() => const GetStartedScreen());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 258,
          height: 306,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
