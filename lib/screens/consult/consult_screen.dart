import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homedose/constants/app_colors.dart';
import 'package:homedose/controllers/chat_controller.dart';
import 'package:homedose/controllers/home_controller.dart';
import 'package:homedose/models/chat_message.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:homedose/screens/consult/case_history_screen.dart';

class ConsultScreen extends StatefulWidget {
  const ConsultScreen({super.key});

  @override
  State<ConsultScreen> createState() => _ConsultScreenState();
}

class _ConsultScreenState extends State<ConsultScreen> {
  final ChatController chatCtrl = Get.find<ChatController>();
  final HomeController homeCtrl = Get.find<HomeController>();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initPersonalChat();
  }

  Future<void> _initPersonalChat() async {
    chatCtrl.activeMessages.clear();
    chatCtrl.isMessagesLoading.value = true;
    await chatCtrl.fetchPersonalChats();
    if (chatCtrl.personalChats.isNotEmpty) {
      final latestChat = chatCtrl.personalChats.first;
      chatCtrl.loadChatMessages(latestChat.chatId);
    } else {
      chatCtrl.activeChatId.value = null;
      chatCtrl.isMessagesLoading.value = false;
    }
  }

  void _confirmClearChat() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Clear Chat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textBlack),
        ),
        content: Text(
          'Are you sure you want to clear this chat screen? Your past conversation history will remain saved in Case History.',
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
          TextButton(
            onPressed: () {
              Get.back();
              // Clear locally only and reset activeChatId to start a new chat session on next message
              chatCtrl.activeMessages.clear();
              chatCtrl.activeChatId.value = null;
              Get.snackbar(
                'Success',
                'Chat cleared locally! A new session has been started.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.primaryTeal,
                colorText: Colors.white,
                margin: const EdgeInsets.all(15),
              );
            },
            child: Text(
              'Clear',
              style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Chat',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.more_vert, color: AppColors.textBlack),
          onPressed: () => Get.to(() => const CaseHistoryScreen()),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 1.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.edit_square,
                color: Colors.black,
                size: 20,
              ),
            ),
            onPressed: () {
              chatCtrl.clearChat();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (chatCtrl.isMessagesLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            );
          }

          final hasMessages = chatCtrl.activeMessages.isNotEmpty;

          return Column(
            children: [
              Expanded(
                child: !hasMessages ? _buildEmptyState() : _buildChatContent(),
              ),
              _buildInputArea(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.medication_liquid_rounded, size: 60, color: AppColors.primaryTeal),
          const SizedBox(height: 20),
          Text(
            'Home Dose',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hi, I\'m HomeDose! Powered by Ai Chatbot. I am best suited for tasks that mix visuals, text, and code.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textGrey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('Marketing', '🎯'),
              _buildSuggestionChip('Digital Marketing', '💼'),
              _buildSuggestionChip('UI/UX', '📱'),
              _buildSuggestionChip('Social Media', '🚀'),
              _buildSuggestionChip('Design', '✏️'),
              _buildSuggestionChip('Branding', '♦️'),
              _buildSuggestionChip('Educations', '📚'),
              _buildSuggestionChip('Health', '🩺'),
              _buildSuggestionChip('Finance', '💰'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label, String emoji) {
    return GestureDetector(
      onTap: () {
        chatCtrl.sendPersonalMessage(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textBlack,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatContent() {
    // Auto scroll when messages change
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Obx(() {
      final messagesLength = chatCtrl.activeMessages.length;
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: messagesLength + (chatCtrl.isLoading.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messagesLength) {
            // Typing indicator
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundImage: AssetImage('assets/images/ai_logo.png'), 
                    backgroundColor: Colors.transparent,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEBEBEB),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryTeal),
                        ),
                        SizedBox(width: 8),
                        Text("Writing...", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return _buildChatBubble(chatCtrl.activeMessages[index]);
        },
      );
    });
  }

  Widget _buildChatBubble(ChatMessage msg) {
    bool isUser = msg.isUser;
    
    final storage = GetStorage();
    final user = storage.read('user');
    final userId = user?['id']?.toString();
    String? userProfilePic;
    if (userId != null) {
      userProfilePic = storage.read('custom_avatar_user_$userId');
    }
    userProfilePic ??= user != null ? (user['profile_image_url'] ?? user['profile_image'] ?? user['profilePicture'])?.toString() : null;
    
    if (userProfilePic != null && userProfilePic.isNotEmpty && !userProfilePic.startsWith('http')) {
      userProfilePic = 'https://homedose.tecclubb.com/$userProfilePic';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/images/ai_logo.png'),
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primaryTeal : const Color(0xFFEBEBEB),
                borderRadius: BorderRadius.only(
                  topLeft: isUser ? const Radius.circular(20) : const Radius.circular(0),
                  topRight: const Radius.circular(20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAttachment(msg, isUser),
                  if (msg.text.isNotEmpty && msg.text != 'Sent an attachment')
                    MarkdownBody(
                      data: msg.text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isUser ? Colors.white : AppColors.textBlack,
                        ),
                        code: GoogleFonts.firaCode(
                          fontSize: 12,
                          backgroundColor: Colors.transparent,
                          color: isUser ? Colors.white70 : Colors.blueGrey.shade800,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: isUser ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: userProfilePic != null && userProfilePic.isNotEmpty
                  ? NetworkImage(userProfilePic)
                  : null,
              backgroundColor: Colors.grey.shade200,
              child: (userProfilePic == null || userProfilePic.isEmpty)
                  ? const Icon(Icons.person, size: 16, color: Colors.grey)
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachment(ChatMessage msg, bool isUser) {
    if (msg.localAttachmentPath == null && (msg.attachmentUrl == null || msg.attachmentUrl!.isEmpty)) {
      return const SizedBox.shrink();
    }
    
    final pathOrUrl = msg.localAttachmentPath ?? msg.attachmentUrl!;
    final isImage = pathOrUrl.toLowerCase().endsWith('.png') || 
                    pathOrUrl.toLowerCase().endsWith('.jpg') || 
                    pathOrUrl.toLowerCase().endsWith('.jpeg') || 
                    pathOrUrl.toLowerCase().endsWith('.webp') || 
                    pathOrUrl.toLowerCase().endsWith('.gif');
                    
    if (isImage) {
      return Container(
        margin: EdgeInsets.only(bottom: msg.text.isNotEmpty && msg.text != 'Sent an attachment' ? 8 : 0),
        constraints: const BoxConstraints(maxHeight: 200, maxWidth: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: msg.localAttachmentPath != null
            ? Image.file(File(msg.localAttachmentPath!), fit: BoxFit.cover)
            : Image.network(msg.attachmentUrl!, fit: BoxFit.cover),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: EdgeInsets.only(bottom: msg.text.isNotEmpty && msg.text != 'Sent an attachment' ? 8 : 0),
        decoration: BoxDecoration(
          color: isUser ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: isUser ? Colors.white : AppColors.primaryTeal, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                pathOrUrl.split('/').last,
                style: GoogleFonts.poppins(color: isUser ? Colors.white : AppColors.textBlack, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _showAttachmentMenu,
            child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.add, color: AppColors.textGrey, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() {
                    if (chatCtrl.selectedAttachmentPath.value.isNotEmpty) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file, color: AppColors.primaryTeal, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                chatCtrl.selectedAttachmentName.value,
                                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textBlack),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => chatCtrl.clearAttachment(),
                              child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(() {
                          if (chatCtrl.recognizedText.value.isNotEmpty) {
                            _msgController.text = chatCtrl.recognizedText.value;
                            // Set cursor to end
                            _msgController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _msgController.text.length),
                            );
                          }
                          return TextField(
                            controller: _msgController,
                            style: GoogleFonts.poppins(fontSize: 14),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              hintText: chatCtrl.isListening.value ? 'Listening...' : 'Ask a questions...',
                              hintStyle: GoogleFonts.poppins(
                                  color: chatCtrl.isListening.value ? AppColors.primaryTeal : Colors.grey, 
                                  fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          );
                        }),
                      ),
                      GestureDetector(
                        onTap: () async {
                          bool started = await chatCtrl.toggleListening();
                          if (started) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Listening...', style: GoogleFonts.poppins()),
                                backgroundColor: AppColors.primaryTeal,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Obx(() => Icon(
                          chatCtrl.isListening.value ? Icons.mic : Icons.mic_none,
                          color: chatCtrl.isListening.value ? AppColors.primaryTeal : AppColors.textGrey,
                          size: 24,
                        )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: const Icon(Icons.send, color: AppColors.primaryTeal, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentMenu() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 20,
          children: [
            _buildAttachmentOption(
              icon: Icons.insert_drive_file,
              color: Colors.indigo,
              label: 'Document',
              onTap: () {
                Get.back();
                chatCtrl.pickDocument();
              },
            ),
            _buildAttachmentOption(
              icon: Icons.camera_alt,
              color: Colors.pink,
              label: 'Camera',
              onTap: () {
                Get.back();
                chatCtrl.pickImage(ImageSource.camera);
              },
            ),
            _buildAttachmentOption(
              icon: Icons.image,
              color: Colors.purple,
              label: 'Gallery',
              onTap: () {
                Get.back();
                chatCtrl.pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textBlack),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isNotEmpty || chatCtrl.selectedAttachmentPath.value.isNotEmpty) {
      chatCtrl.sendPersonalMessage(text);
      _msgController.clear();
      chatCtrl.recognizedText.value = '';
    }
  }
}
