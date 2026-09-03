import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homedose/constants/app_colors.dart';
import 'package:homedose/controllers/chat_controller.dart';
import 'package:homedose/controllers/home_controller.dart';
import 'package:homedose/controllers/nav_controller.dart';
import 'package:homedose/models/family_member.dart';
import 'package:homedose/screens/chat/member_chat_screen.dart';
import 'package:homedose/screens/home/add_member_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeController homeCtrl = Get.put(HomeController());
  final ChatController chatCtrl = Get.put(ChatController());
  final NavController navCtrl = Get.find<NavController>();

  String _getLastMessageTime(FamilyMember member) {
    if (member.chatId != null) {
      final chat = chatCtrl.personalChats.firstWhereOrNull((c) => c.chatId == member.chatId);
      if (chat != null) {
        return DateFormat('h:mm a').format(chat.updatedAt.toLocal());
      }
    }
    if (member.updatedAt != null) {
      return DateFormat('h:mm a').format(member.updatedAt!.toLocal());
    }
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Home',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBlack,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => Get.to(() => const AddMemberScreen()),
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                label: Text(
                  'Add a Family Member',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'All Family Member',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (homeCtrl.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryTeal),
                  );
                }
                if (homeCtrl.members.isEmpty) {
                  return Center(
                    child: Text(
                      'No family members added yet.\nTap above to add one.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: homeCtrl.fetchFamilyMembers,
                  color: AppColors.primaryTeal,
                  child: ListView.builder(
                    itemCount: homeCtrl.members.length,
                    itemBuilder: (context, index) {
                      final member = homeCtrl.members[index];
                      return _buildMemberTile(member);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(FamilyMember member) {
    return GestureDetector(
      onTap: () {
        // Navigate to the direct member chat screen
        Get.to(() => MemberChatScreen(member: member));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Builder(
              builder: (context) {
                final String baseNetworkUrl = member.profilePicture ?? '';
                final customUrl = GetStorage().read('custom_avatar_member_${member.id}');
                final networkUrl = customUrl ?? baseNetworkUrl;

                return CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: networkUrl.isNotEmpty
                      ? NetworkImage(networkUrl.startsWith('http')
                          ? networkUrl
                          : 'https://homedose.tecclubb.com/$networkUrl')
                      : null,
                  child: networkUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                );
              }
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        member.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textBlack,
                        ),
                      ),
                      if (member.lastMessage != null && member.lastMessage!.isNotEmpty)
                        Obx(() => Text(
                              _getLastMessageTime(member),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppColors.textGrey,
                              ),
                            )),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.lastMessage ?? 'No messages yet',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
