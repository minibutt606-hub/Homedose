import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homedose/constants/app_colors.dart';
import 'package:homedose/controllers/auth_controller.dart';
import 'package:homedose/controllers/profile_controller.dart';
import 'package:homedose/controllers/subscription_controller.dart';
import 'package:homedose/screens/account/feedback_screen.dart';
import 'package:homedose/screens/account/help_screen.dart';
import 'package:homedose/screens/account/premium_screen.dart';
import 'package:homedose/screens/account/privacy_policy_screen.dart';
import 'package:homedose/screens/account/profile_screen.dart';
import 'package:homedose/screens/account/security_screen.dart';
import 'package:homedose/screens/account/terms_screen.dart';
import 'package:homedose/screens/consult/case_history_screen.dart';
import 'package:homedose/screens/get_started/get_started_screen.dart';
import 'package:homedose/services/login_service.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController = Get.put(ProfileController());
    final SubscriptionController subCtrl = Get.put(SubscriptionController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Account',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Obx(() {
              final isPro = subCtrl.hasActivePro;
              return Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.flash_on,
                        color: AppColors.primaryTeal,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPro ? 'Unlimited' : '${10 - subCtrl.dailySentCount.value}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Profile Info + Subscription status
            Obx(() {
              final user = profileController.user;
              final name = user['name'] ?? 'Guest';
              final email = user['email'] ?? '';
              final isPro = subCtrl.hasActivePro;
              final planName = subCtrl.activePlanName;

              return Column(
                children: [
                  Obx(() {
                    final userObj = profileController.user;
                    final String profileImage = userObj['profile_image_url'] ?? userObj['profile_image'] ?? '';
                    final userId = userObj['id']?.toString();
                    final customUrl = userId != null ? GetStorage().read('custom_avatar_user_$userId') : null;
                    final String finalImage = customUrl ?? profileImage;

                    return CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: finalImage.isNotEmpty
                          ? NetworkImage(
                              finalImage.startsWith('http')
                                  ? finalImage
                                  : 'https://homedose.tecclubb.com/$finalImage',
                            )
                          : null,
                      child: finalImage.isEmpty
                          ? const Icon(Icons.person, size: 40, color: Colors.grey)
                          : null,
                    );
                  }),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBlack,
                    ),
                  ),
                  Text(
                    email,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          planName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.flash_on,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Get Pro Access Banner
                  if (!isPro) ...[
                    GestureDetector(
                      onTap: () => Get.to(() => const PremiumScreen()),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            // Placeholder for the man icon
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white24,
                              ),
                              child: const Icon(
                                Icons.person_pin,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Get Pro Access',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Unlock your AI Chatbot & get all premium features!',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Subscribe',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              );
            }),

            // Menu Items
            _buildMenuItem(
              Icons.person_outline,
              'My Profile',
              () => Get.to(() => const ProfileScreen()),
            ),
            _buildMenuItem(
              Icons.workspace_premium_outlined,
              'Premium',
              () => Get.to(() => const PremiumScreen()),
            ),
            _buildMenuItem(
              Icons.security,
              'Security',
              () => Get.to(() => const SecurityScreen()),
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              Icons.help_outline,
              'Help',
              () => Get.to(() => const HelpScreen()),
            ),

            _buildMenuItem(
              Icons.thumb_up_alt_outlined,
              'Feedback',
              () => Get.to(() => const FeedbackScreen()),
            ),
            _buildMenuItem(
              Icons.description_outlined,
              'Terms of Use',
              () => Get.to(() => const TermsScreen()),
            ),
            _buildMenuItem(
              Icons.privacy_tip_outlined,
              'Privacy Policy',
              () => Get.to(() => const PrivacyPolicyScreen()),
            ),
            _buildMenuItem(Icons.logout, 'Logout', () {
              Get.dialog(
                AlertDialog(
                  backgroundColor: Colors.white,
                  title: Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textBlack,
                    ),
                  ),
                  content: Text(
                    'Are you sure you want to logout?',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textBlack,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Get.back();
                        await LoginService.logout();
                        await Get.deleteAll(
                          force: true,
                        ); // Clear all controllers from memory
                        Get.offAll(() => const GetStartedScreen());
                      },
                      child: Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 30),
            Text(
              'App Version: 1.12.431.001',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(height: 100), // spacing for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.fillColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: AppColors.primaryBlue),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textBlack,
            ),
          ),
        ),
      ),
    );
  }
}
