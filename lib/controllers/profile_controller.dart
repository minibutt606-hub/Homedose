import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:homedose/screens/get_started/get_started_screen.dart';
import 'package:homedose/services/get_user_service.dart';
import 'package:homedose/services/update_user_service.dart';
import 'package:homedose/services/delete_user_service.dart';
import 'package:homedose/services/login_service.dart';
import 'package:homedose/widgets/premium_snackbar.dart';

class ProfileController extends GetxController {
  final _storage = GetStorage();
  
  var user = <String, dynamic>{}.obs;
  var isLoading = false.obs;
  var isUpdating = false.obs;
  var isDeleting = false.obs;
  
  var pickedImagePath = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Load initially from storage
    final storedUser = _storage.read('user');
    if (storedUser != null && storedUser is Map) {
      user.value = Map<String, dynamic>.from(storedUser);
    }
    // Fetch fresh profile data
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    final result = await GetUserService.getUserProfile();
    isLoading.value = false;

    if (result['success'] == true && result['user'] != null) {
      user.value = Map<String, dynamic>.from(result['user']);
      await _storage.write('user', user);
    }
  }

  Future<bool> updateProfile({String? name, String? email}) async {
    isUpdating.value = true;
    
    final result = await UpdateUserService.updateProfile(
      name: name,
      email: email,
      profileImagePath: pickedImagePath.value.isNotEmpty ? pickedImagePath.value : null,
    );
    
    isUpdating.value = false;

    if (result['success'] == true) {
      if (result['user'] != null) {
        user.value = Map<String, dynamic>.from(result['user']);
        await _storage.write('user', user);
      }
      pickedImagePath.value = ''; // Reset path
      return true;
    } else {
      PremiumSnackbar.showError(
        title: 'Update Failed',
        message: result['message'] ?? 'Unable to update profile details',
      );
      return false;
    }
  }

  Future<void> deleteAccount(String password) async {
    isDeleting.value = true;
    final result = await DeleteUserService.deleteAccount(password: password);
    isDeleting.value = false;

    if (result['success'] == true) {
      Get.back(); // close confirm dialog
      PremiumSnackbar.showSuccess(
        title: 'Deleted',
        message: result['message'] ?? 'Account has been deleted.',
      );
      await LoginService.logout();
      Get.offAll(() => const GetStartedScreen());
    } else {
      PremiumSnackbar.showError(
        title: 'Error',
        message: result['message'] ?? 'Failed to delete account. Incorrect password.',
      );
    }
  }
}
