import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homedose/constants/app_colors.dart';
import 'package:homedose/controllers/chat_controller.dart';
import 'package:homedose/controllers/profile_controller.dart';
import 'package:homedose/controllers/auth_controller.dart';
import 'package:get_storage/get_storage.dart';
import 'package:homedose/models/chat_model.dart';
import 'package:intl/intl.dart';

class CaseHistoryScreen extends StatefulWidget {
  const CaseHistoryScreen({super.key});

  @override
  State<CaseHistoryScreen> createState() => _CaseHistoryScreenState();
}

class _CaseHistoryScreenState extends State<CaseHistoryScreen> {
  final ChatController chatCtrl = Get.find<ChatController>();

  String _getDisplayTitle(chat) {
    if (chat.title.isNotEmpty && chat.title.toLowerCase() != 'new chat') {
      return chat.title;
    }
    if (chat.lastMessage != null && chat.lastMessage!.isNotEmpty) {
      List<String> words = chat.lastMessage!.trim().split(RegExp(r'\s+'));
      if (words.length <= 5) return chat.lastMessage!;
      return '${words.take(5).join(' ')}...';
    }
    return chat.name.isNotEmpty ? chat.name : 'Chat';
  }

  @override
  void initState() {
    super.initState();
    // Refresh chats list on opening case history screen
    chatCtrl.fetchPersonalChats();
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
          'Case History',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (chatCtrl.isChatsLoading.value && chatCtrl.personalChats.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryTeal),
          );
        }

        if (chatCtrl.personalChats.isEmpty) {
          return RefreshIndicator(
            onRefresh: chatCtrl.fetchPersonalChats,
            color: AppColors.primaryTeal,
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, size: 48, color: AppColors.textGrey),
                      const SizedBox(height: 12),
                      Text(
                        'No history available.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Group chats by date (Today vs Older)
        final today = DateTime.now();
        final todayChats = chatCtrl.personalChats.where((c) {
          return c.updatedAt.year == today.year &&
                 c.updatedAt.month == today.month &&
                 c.updatedAt.day == today.day;
        }).toList();

        final olderChats = chatCtrl.personalChats.where((c) {
          return !(c.updatedAt.year == today.year &&
                   c.updatedAt.month == today.month &&
                   c.updatedAt.day == today.day);
        }).toList();

        return RefreshIndicator(
          onRefresh: chatCtrl.fetchPersonalChats,
          color: AppColors.primaryTeal,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (todayChats.isNotEmpty) ...[
                Text(
                  'Today',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 16),
                ...todayChats.map((c) => _buildHistoryItem(c)),
                const SizedBox(height: 24),
              ],
              if (olderChats.isNotEmpty) ...[
                Text(
                  'Last Week',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 16),
                ...olderChats.map((c) => _buildHistoryItem(c)),
              ]
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHistoryItem(ChatModel chat) {
    return GestureDetector(
      onTap: () {
        chatCtrl.activeChatId.value = chat.chatId;
        Get.back();
        chatCtrl.loadChatMessages(chat.chatId);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                final String baseNetworkUrl = chat.avatar ?? '';
                String? customUrl;
                if (chat.familyMemberId != null) {
                  customUrl = GetStorage().read('custom_avatar_member_${chat.familyMemberId}');
                } else {
                  try {
                    final profileController = Get.find<ProfileController>();
                    final userId = profileController.user['id']?.toString();
                    if (userId != null) {
                      customUrl = GetStorage().read('custom_avatar_user_$userId');
                    }
                  } catch (_) {}
                }
                final networkUrl = customUrl ?? baseNetworkUrl;

                return CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: networkUrl.isNotEmpty
                      ? NetworkImage(networkUrl.startsWith('http')
                          ? networkUrl
                          : 'https://homedose.tecclubb.com/$networkUrl')
                      : null,
                  child: networkUrl.isEmpty
                      ? const Icon(Icons.chat_bubble_outline, color: AppColors.primaryTeal, size: 20)
                      : null,
                );
              }
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDisplayTitle(chat),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBlack,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.lastMessage ?? 'No messages yet',
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.primaryTeal, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (val) {
                if (val == 'details') {
                  _showChatDetails(chat);
                } else if (val == 'delete') {
                  _confirmDeleteChat(chat);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'details',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.black54),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _showChatDetails(ChatModel chat) async {
    // Show a loading dialog first
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      ),
      barrierDismissible: false,
    );

    final details = await chatCtrl.getChatDetails(chat.chatId);
    Get.back(); // close the loading dialog

    if (details == null) return;

    // Show details sheet
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: details.avatar != null && details.avatar!.isNotEmpty
                    ? NetworkImage(details.avatar!.startsWith('http')
                        ? details.avatar!
                        : 'https://homedose.tecclubb.com/${details.avatar!}')
                    : null,
                child: (details.avatar == null || details.avatar!.isEmpty)
                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                details.name,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Chat ID', details.chatId.toString()),
            _buildDetailRow('Title', details.title.isNotEmpty ? details.title : 'N/A'),
            _buildDetailRow('Type', details.familyMemberId != null ? 'Family Chat' : 'Personal Chat'),
            _buildDetailRow('Last Updated', DateFormat('MMM d, yyyy • h:mm a').format(details.updatedAt.toLocal())),
            const SizedBox(height: 20),
            if (details.lastMessage != null && details.lastMessage!.isNotEmpty) ...[
              Text(
                'Last Message Preview',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.fillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  details.lastMessage!,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textBlack,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textGrey),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textBlack,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteChat(ChatModel chat) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Delete Chat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textBlack),
        ),
        content: Text(
          'Are you sure you want to permanently delete this chat history? This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textBlack),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textGrey, fontWeight: FontWeight.w500),
            ),
          ),
          Obx(() {
            final isDeleting = chatCtrl.isDeletingChat.value;
            return TextButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      final success = await chatCtrl.deletePersonalChat(chat.chatId);
                      if (success) {
                        Get.back(); // close confirm dialog
                      }
                    },
              child: isDeleting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
                      ),
                    )
                  : Text(
                      'Delete',
                      style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w600),
                    ),
            );
          }),
        ],
      ),
    );
  }
}
