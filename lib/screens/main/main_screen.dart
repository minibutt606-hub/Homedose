import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homedose/constants/app_colors.dart';
import 'package:homedose/controllers/nav_controller.dart';
import 'package:homedose/controllers/profile_controller.dart';
import 'package:homedose/controllers/subscription_controller.dart';
import 'package:homedose/screens/account/account_screen.dart';
import 'package:homedose/screens/consult/consult_screen.dart';
import 'package:homedose/screens/home/home_screen.dart';
import 'package:homedose/screens/onboarding/tips_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final NavController nav = Get.put(NavController());
  final ProfileController profile = Get.put(ProfileController());
  final SubscriptionController sub = Get.put(SubscriptionController());

  @override
  void initState() {
    super.initState();
    // Show tips dialog when first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TipsDialog.show();
    });
  }

  final List<Widget> _pages = [
    HomeScreen(),
    const ConsultScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (nav.currentIndex.value != 0) {
          nav.changePage(0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Obx(() => _pages[nav.currentIndex.value]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Container(
            height: 75,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(37.5),
            ),
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, 'Home'),
                  _buildNavItem(1, 'Consult'),
                  _buildNavItem(2, 'Account'),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildNavItem(int index, String label) {
    final isSelected = nav.currentIndex.value == index;
    
    IconData icon;
    switch (index) {
      case 0:
        icon = isSelected ? Icons.home : Icons.home_outlined;
        break;
      case 1:
        icon = isSelected ? Icons.chat_bubble : Icons.chat_bubble_outline;
        break;
      case 2:
      default:
        icon = isSelected ? Icons.person : Icons.person_outline;
        break;
    }

    return GestureDetector(
      onTap: () => nav.changePage(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryTeal : Colors.white,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isSelected ? AppColors.primaryTeal : Colors.white,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
