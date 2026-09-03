import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:homedose/constants/app_colors.dart';
import 'package:homedose/services/stripe_service.dart';
import 'package:homedose/services/subscription_service.dart';
import 'package:get_storage/get_storage.dart';

class SubscriptionController extends GetxController {
  final _storage = GetStorage();
  var plans = <dynamic>[].obs;
  var activeSubscription = Rxn<dynamic>();
  
  var isPlansLoading = false.obs;
  var isSubscriptionLoading = false.obs;
  var isSubscribing = false.obs;

  // Track daily sent messages limit (10 free messages/day)
  var dailySentCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    
    // Load subscription instantly from storage cache to avoid UI lag
    final storedSubscription = _storage.read('activeSubscription');
    if (storedSubscription != null) {
      activeSubscription.value = storedSubscription;
    }
    
    // Load message limit count
    _loadDailySentCount();
    
    fetchPlans();
    fetchActiveSubscription();
  }

  void _loadDailySentCount() {
    final today = DateTime.now().toString().substring(0, 10); // yyyy-MM-dd
    final storedDate = _storage.read('sent_date');
    if (storedDate != today) {
      _storage.write('sent_date', today);
      _storage.write('sent_count', 0);
      dailySentCount.value = 0;
    } else {
      dailySentCount.value = _storage.read('sent_count') ?? 0;
    }
  }

  Future<void> incrementSentCount() async {
    final today = DateTime.now().toString().substring(0, 10);
    final storedDate = _storage.read('sent_date');
    int count = 0;
    if (storedDate == today) {
      count = _storage.read('sent_count') ?? 0;
    } else {
      await _storage.write('sent_date', today);
    }
    count++;
    await _storage.write('sent_count', count);
    dailySentCount.value = count;
  }

  bool get canSendFreeMessage {
    if (hasActivePro) return true;
    return dailySentCount.value < 10;
  }

  Future<void> fetchPlans() async {
    isPlansLoading.value = true;
    final result = await SubscriptionService.getPlans();
    isPlansLoading.value = false;

    if (result['success'] == true) {
      plans.assignAll(result['plans'] as List<dynamic>);
    }
  }

  Future<void> fetchActiveSubscription() async {
    isSubscriptionLoading.value = true;
    final result = await SubscriptionService.getActiveSubscription();
    isSubscriptionLoading.value = false;

    if (result['success'] == true) {
      activeSubscription.value = result['subscription'];
      if (result['subscription'] != null) {
        await _storage.write('activeSubscription', result['subscription']);
      } else {
        await _storage.remove('activeSubscription');
      }
    }
  }

  // Returns true if user has active/trialing/grace status subscription
  bool get hasActivePro {
    if (activeSubscription.value == null) return false;
    final status = activeSubscription.value['status']?.toString().toLowerCase();
    return status == 'active' || status == 'trialing' || status == 'grace';
  }

  // Gets the name of the currently active plan
  String get activePlanName {
    if (activeSubscription.value == null) return 'Regular Plan';
    final plan = activeSubscription.value['plan'];
    if (plan != null && plan['name'] != null) {
      return plan['name'].toString();
    }
    return 'Pro Plan';
  }

  // Check if a plan is already active
  bool isPlanActive(int planId) {
    if (activeSubscription.value == null) return false;
    final plan = activeSubscription.value['plan'];
    if (plan != null && plan['id'] != null) {
      return plan['id'] == planId && hasActivePro;
    }
    return false;
  }

  Future<bool> upgradeSubscription({
    required int planId,
    required double price,
  }) async {
    // 1. Check if they already have an active subscription for this plan (or any plan)
    if (hasActivePro) {
      Get.snackbar(
        'Subscription Active',
        'You already have an active subscription! Please cancel your existing plan before changing subscriptions.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return false;
    }

    isSubscribing.value = true;

    try {
      // Get user email
      final storage = GetStorage();
      final user = storage.read('user');
      final String email = user != null ? (user['email'] ?? 'test@example.com') : 'test@example.com';

      // 2. Start Stripe Payment
      final int amountInCents = (price * 100).round();
      final bool paymentSuccess = await StripeService.startPayment(
        amountInCents: amountInCents,
        email: email,
      );

      if (!paymentSuccess) {
        isSubscribing.value = false;
        return false;
      }

      // 3. Post to backend to activate subscription
      final result = await SubscriptionService.createSubscription(planId);
      isSubscribing.value = false;

      if (result['success'] == true) {
        await fetchActiveSubscription(); // Reload status from server
        
        Get.dialog(
          AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Text('🎉', style: TextStyle(fontSize: 24)),
                SizedBox(width: 8),
                Text('Success', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'You are successful for subscription! Your Pro access is now active.',
              style: TextStyle(color: AppColors.textBlack),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Great!', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Failed to activate subscription on the server',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          margin: const EdgeInsets.all(15),
        );
        return false;
      }
    } catch (e) {
      isSubscribing.value = false;
      Get.snackbar(
        'Error',
        'Upgrade failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return false;
    }
  }
}
