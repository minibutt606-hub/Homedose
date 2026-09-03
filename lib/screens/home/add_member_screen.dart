import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:homedose/constants/app_colors.dart';
import 'package:homedose/controllers/home_controller.dart';
import 'package:homedose/models/family_member.dart';
import 'package:homedose/widgets/custom_text_field.dart';
import 'package:homedose/controllers/nav_controller.dart';
class AddMemberScreen extends StatefulWidget {
  final FamilyMember? member;
  const AddMemberScreen({super.key, this.member});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final HomeController homeCtrl = Get.find<HomeController>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _threadsController = TextEditingController();
  String _selectedGender = 'Male';
  String _selectedRelationship = 'Brother';

  @override
  void initState() {
    super.initState();
    homeCtrl.selectedImagePath.value = '';
    if (widget.member != null) {
      _nameController.text = widget.member!.name;
      _threadsController.text = widget.member!.threadsDetail ?? '';
      
      final String gender = widget.member!.gender.toLowerCase();
      if (gender == 'male') {
        _selectedGender = 'Male';
      } else if (gender == 'female') {
        _selectedGender = 'Female';
      } else {
        _selectedGender = 'Other';
      }

      final String rel = widget.member!.relationship;
      if (rel.isNotEmpty) {
        final String capitalized = rel[0].toUpperCase() + rel.substring(1).toLowerCase();
        if (['Brother', 'Sister', 'Father', 'Mother', 'Friend', 'Other'].contains(capitalized)) {
          _selectedRelationship = capitalized;
        } else {
          _selectedRelationship = 'Other';
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _threadsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Error', 'Please enter a name');
      return;
    }
    
    final String gender = _selectedGender;
    final String relationship = _selectedRelationship;
    final String threads = _threadsController.text.trim();

    bool success = false;
    final imagePath = homeCtrl.selectedImagePath.value.isNotEmpty ? homeCtrl.selectedImagePath.value : null;

    if (widget.member != null) {
      success = await homeCtrl.updateFamilyMember(
        id: widget.member!.id,
        name: name,
        gender: gender,
        relationship: relationship,
        threads: threads,
        imagePath: imagePath,
      );
    } else {
      success = await homeCtrl.addFamilyMember(
        name: name,
        gender: gender,
        relationship: relationship,
        threads: threads,
        imagePath: imagePath,
      );
    }

    if (success) {
      Get.until((route) => route.isFirst);
      if (Get.isRegistered<NavController>()) {
        Get.find<NavController>().changePage(0);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60, // Compress to ~60% quality
      maxWidth: 800, // Resize large images
    );
    if (pickedFile != null) {
      homeCtrl.selectedImagePath.value = pickedFile.path;
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
          widget.member != null ? 'Edit Member' : 'Add a Member',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Column(
                  children: [
                    Obx(() {
                      final selectedPath = homeCtrl.selectedImagePath.value;
                      ImageProvider? bgImage;
                      if (selectedPath.isNotEmpty) {
                        bgImage = FileImage(File(selectedPath));
                      } else if (widget.member?.profilePicture != null && widget.member!.profilePicture!.isNotEmpty) {
                        bgImage = NetworkImage(widget.member!.profilePicture!);
                      }

                      return CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: bgImage,
                        child: bgImage == null
                            ? const Icon(Icons.person, size: 40, color: Colors.grey)
                            : null,
                      );
                    }),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Upload to Picture',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            
            // Name
            CustomTextField(
              label: 'Name',
              hint: 'Enter Name',
              controller: _nameController,
              suffixIcon: const Icon(Icons.person_outline, color: AppColors.textGrey),
            ),
            const SizedBox(height: 20),

            // Gender
            Text('Gender', style: _labelStyle()),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedGender,
              items: ['Male', 'Female', 'Other'],
              onChanged: (val) => setState(() => _selectedGender = val!),
            ),
            const SizedBox(height: 20),

            // Relationship
            Text('Relationship', style: _labelStyle()),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedRelationship,
              items: ['Brother', 'Sister', 'Father', 'Mother', 'Friend', 'Other'],
              onChanged: (val) => setState(() => _selectedRelationship = val!),
            ),
            const SizedBox(height: 20),

            // Threads
            Text('Threads', style: _labelStyle()),
            const SizedBox(height: 8),
            TextField(
              controller: _threadsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter Your Detail',
                hintStyle: GoogleFonts.poppins(color: AppColors.textGrey, fontSize: 13),
                filled: true,
                fillColor: AppColors.fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Buttons
            Obx(() {
              final isSubmitting = homeCtrl.isSubmitting.value;
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.member != null ? 'Save Changes' : 'Submit',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Obx(() {
              final isSubmitting = homeCtrl.isSubmitting.value;
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  TextStyle _labelStyle() {
    return GoogleFonts.poppins(
      fontSize: 12,
      color: AppColors.textGrey,
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.fillColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.chevron_right, color: AppColors.textGrey),
          style: GoogleFonts.poppins(color: AppColors.textBlack, fontSize: 14),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ),
    );
  }
}
