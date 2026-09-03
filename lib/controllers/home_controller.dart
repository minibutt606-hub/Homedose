import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:homedose/constants/app_colors.dart';
import 'package:homedose/models/family_member.dart';
import 'package:homedose/services/list_family_members_service.dart';
import 'package:homedose/services/create_family_member_service.dart';
import 'package:homedose/services/update_family_member_service.dart';
import 'package:homedose/services/delete_family_member_service.dart';

class HomeController extends GetxController {
  var members = <FamilyMember>[].obs;
  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var selectedImagePath = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchFamilyMembers();
  }

  Future<void> fetchFamilyMembers() async {
    isLoading.value = true;
    final result = await ListFamilyMembersService.listFamilyMembers();
    isLoading.value = false;

    if (result['success'] == true && result['members'] != null) {
      members.assignAll(result['members'] as List<FamilyMember>);
    }
  }

  Future<bool> addFamilyMember({
    required String name,
    required String gender,
    required String relationship,
    String? threads,
    String? imagePath,
  }) async {
    isSubmitting.value = true;
    final result = await CreateFamilyMemberService.createFamilyMember(
      name: name,
      gender: gender,
      relationship: relationship,
      threads: threads,
      imagePath: imagePath,
    );
    isSubmitting.value = false;

    if (result['success'] == true && result['member'] != null) {
      members.insert(0, result['member'] as FamilyMember);
      Get.snackbar(
        'Success',
        'Family member added successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryTeal,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return true;
    } else {
      Get.snackbar(
        'Error',
        result['message'] ?? 'Failed to add family member',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return false;
    }
  }

  Future<bool> updateFamilyMember({
    required String id,
    String? name,
    String? gender,
    String? relationship,
    String? threads,
    String? imagePath,
  }) async {
    isSubmitting.value = true;
    final result = await UpdateFamilyMemberService.updateFamilyMember(
      id: id,
      name: name,
      gender: gender,
      relationship: relationship,
      threads: threads,
      imagePath: imagePath,
    );
    isSubmitting.value = false;

    if (result['success'] == true && result['member'] != null) {
      final updated = result['member'] as FamilyMember;
      final index = members.indexWhere((m) => m.id == id);
      if (index != -1) {
        members[index] = updated;
      }
      Get.snackbar(
        'Success',
        'Family member updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryTeal,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return true;
    } else {
      Get.snackbar(
        'Error',
        result['message'] ?? 'Failed to update family member',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return false;
    }
  }

  Future<bool> deleteFamilyMember(String id) async {
    isLoading.value = true;
    final result = await DeleteFamilyMemberService.deleteFamilyMember(id);
    isLoading.value = false;

    if (result['success'] == true) {
      members.removeWhere((m) => m.id == id);
      Get.snackbar(
        'Deleted',
        'Family member deleted successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryTeal,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return true;
    } else {
      Get.snackbar(
        'Error',
        result['message'] ?? 'Failed to delete family member',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return false;
    }
  }
}
