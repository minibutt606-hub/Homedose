import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homedose/constants/app_colors.dart';
import 'package:homedose/controllers/profile_controller.dart';
import 'package:homedose/widgets/custom_text_field.dart';
import 'package:homedose/widgets/premium_snackbar.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _profileController = Get.find<ProfileController>();
  
  late final TextEditingController _idController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final user = _profileController.user;
    _idController = TextEditingController(text: user['id']?.toString() ?? '');
    _usernameController = TextEditingController(text: user['name'] ?? '');
    _emailController = TextEditingController(text: user['email'] ?? '');
    _profileController.pickedImagePath.value = '';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60, // Compress to ~60% quality
      maxWidth: 800, // Resize large images
    );
    if (pickedFile != null) {
      _profileController.pickedImagePath.value = pickedFile.path;
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
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
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                    Obx(() {
                      final pickedPath = _profileController.pickedImagePath.value;
                      final baseNetworkUrl = _profileController.user['profile_image_url'] ??
                          _profileController.user['profile_image'] ?? '';
                      final userId = _profileController.user['id']?.toString();
                      final customUrl = userId != null ? GetStorage().read('custom_avatar_user_$userId') : null;
                      final networkUrl = customUrl ?? baseNetworkUrl;

                      ImageProvider? imageProvider;
                      if (pickedPath.isNotEmpty) {
                        imageProvider = FileImage(File(pickedPath));
                      } else if (networkUrl.isNotEmpty) {
                        imageProvider = NetworkImage(networkUrl.startsWith('http')
                            ? networkUrl
                            : 'https://homedose.tecclubb.com/$networkUrl');
                      }

                    return CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(Icons.person, size: 40, color: Colors.grey)
                          : null,
                    );
                  }),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Change Profile Picture',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            CustomTextField(
              label: 'User ID',
              hint: 'Enter User ID',
              controller: _idController,
              suffixIcon: const Icon(Icons.person, color: AppColors.textGrey),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Username',
              hint: 'Enter Username',
              controller: _usernameController,
              suffixIcon: const Icon(Icons.account_circle_outlined, color: AppColors.textGrey),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Email',
              hint: 'Enter Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              suffixIcon: const Icon(Icons.mail_outline, color: AppColors.textGrey),
            ),
            const SizedBox(height: 40),
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _profileController.isUpdating.value
                      ? null
                      : () async {
                          final oldName = _profileController.user['name'] ?? '';
                          final oldEmail = _profileController.user['email'] ?? '';
                          final newName = _usernameController.text.trim();
                          final newEmail = _emailController.text.trim();
                          final hasNewImage = _profileController.pickedImagePath.value.isNotEmpty;

                          final success = await _profileController.updateProfile(
                            name: newName,
                            email: newEmail,
                          );
                          if (success) {
                            Get.back(); // return to AccountScreen first
                            
                            // Determine which fields were updated
                            final List<String> changes = [];
                            if (newName != oldName) changes.add('Username');
                            if (newEmail != oldEmail) changes.add('Email');
                            if (hasNewImage) changes.add('Profile Picture');

                            String msg;
                            if (changes.isEmpty) {
                              msg = 'Profile updated successfully!';
                            } else if (changes.length == 1) {
                              msg = 'Successfully updated ${changes.first}!';
                            } else {
                              final last = changes.removeLast();
                              msg = 'Successfully updated ${changes.join(', ')} & $last!';
                            }

                            PremiumSnackbar.showSuccess(
                              title: 'Profile Updated',
                              message: msg,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    disabledBackgroundColor: AppColors.primaryTeal.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: _profileController.isUpdating.value
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
