import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homedose/constants/app_colors.dart';
import 'package:homedose/controllers/subscription_controller.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final SubscriptionController subCtrl = Get.find<SubscriptionController>();
  int? _selectedPlanId;
  double _selectedPlanPrice = 0.0;

  @override
  void initState() {
    super.initState();
    // Fetch plans on screen open to ensure fresh data
    subCtrl.fetchPlans();
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
          'Premium',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (subCtrl.isPlansLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryTeal),
          );
        }

        if (subCtrl.plans.isEmpty) {
          return RefreshIndicator(
            onRefresh: subCtrl.fetchPlans,
            color: AppColors.primaryTeal,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              children: [
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.workspace_premium_outlined, size: 60, color: AppColors.textGrey),
                      const SizedBox(height: 16),
                      Text(
                        'No Active Subscription Plans',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please try again later or refresh.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Auto-select first plan when plans list loads
        if (_selectedPlanId == null && subCtrl.plans.isNotEmpty) {
          _selectedPlanId = subCtrl.plans.first['id'];
          _selectedPlanPrice = double.tryParse(subCtrl.plans.first['price']?.toString() ?? '0.0') ?? 0.0;
        }

        return RefreshIndicator(
          onRefresh: subCtrl.fetchPlans,
          color: AppColors.primaryTeal,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white24,
                        ),
                        child: const Icon(Icons.person_pin, color: Colors.white, size: 50),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Get Pro Access',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Unlock your AI Chatbot & get all premium features!',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Title
                Row(
                  children: [
                    const Text('👑', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text(
                      'Get Pro Access',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Features List
                _buildFeatureRow('Unlimited chat access'),
                _buildFeatureRow('Unlimited Family members'),
                _buildFeatureRow('Upload image to get response'),
                _buildFeatureRow('Upload & Ask By Voice'),

                const SizedBox(height: 30),

                // Plan Options
                ...subCtrl.plans.map((plan) {
                  return _buildPlanOption(plan);
                }),

                const SizedBox(height: 24),
                Text(
                  'Subscription auto-renews according to billing intervals unless canceled.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 24),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: subCtrl.isSubscribing.value
                        ? null
                        : () {
                            if (_selectedPlanId != null) {
                              subCtrl.upgradeSubscription(
                                planId: _selectedPlanId!,
                                price: _selectedPlanPrice,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      disabledBackgroundColor: AppColors.primaryTeal.withValues(alpha: 0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    child: subCtrl.isSubscribing.value
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue Payment',
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_circle_right_rounded, color: Colors.white),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.primaryTeal, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption(dynamic plan) {
    final int planId = plan['id'] as int;
    final bool isSelected = _selectedPlanId == planId;

    String? badge;
    if (plan['is_best_deal'] == true) {
      badge = 'Best Value';
    } else if (plan['trial_period'] != null && (plan['trial_period'] as int) > 0) {
      badge = '${plan['trial_period']}-${plan['trial_interval']} Free Trial';
    }

    final double priceVal = double.tryParse(plan['price']?.toString() ?? '0.0') ?? 0.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanId = planId;
          _selectedPlanPrice = priceVal;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    plan['name'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primaryTeal : AppColors.textBlack,
                    ),
                  ),
                  if (plan['description'] != null && plan['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      plan['description'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (plan['has_discount'] == true && plan['original_price'] != null) ...[
                      Text(
                        '${plan['currency_symbol'] ?? '\$'}${plan['original_price']}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.redAccent,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      '${plan['currency_symbol'] ?? '\$'}${plan['price']}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.primaryTeal : AppColors.textBlack,
                      ),
                    ),
                  ],
                ),
                Text(
                  'per ${plan['invoice_interval'] ?? 'month'}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: isSelected ? AppColors.primaryTeal : AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
