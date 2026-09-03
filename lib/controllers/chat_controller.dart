import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get_storage/get_storage.dart';
import 'package:homedose/constants/app_colors.dart';
import 'package:homedose/models/chat_message.dart';
import 'package:homedose/models/chat_session.dart';
import 'package:homedose/models/chat_model.dart';
import 'package:homedose/models/family_member.dart';
import 'package:homedose/controllers/home_controller.dart';
import 'package:homedose/services/list_chats_service.dart';
import 'package:homedose/services/get_chat_service.dart';
import 'package:homedose/services/delete_chat_service.dart';
import 'package:homedose/services/send_message_service.dart';
import 'package:homedose/services/get_chat_messages_service.dart';
import 'package:homedose/services/clear_chat_messages_service.dart';
import 'package:homedose/controllers/subscription_controller.dart';
import 'package:homedose/screens/account/premium_screen.dart';

class ChatController extends GetxController {
  var chatSessions = <ChatSession>[].obs;
  var currentSession = Rxn<ChatSession>(); // For family members
  var aiSession = Rxn<ChatSession>();      // Dedicated AI session
  var isLoading = false.obs;

  // Personal chats from backend
  var personalChats = <ChatModel>[].obs;
  var isChatsLoading = false.obs;
  var isDeletingChat = false.obs;

  // Message states for currently active chat
  var activeMessages = <ChatMessage>[].obs;
  var isMessagesLoading = false.obs;
  var activeChatId = RxnInt();

  // Speech to Text states
  final SpeechToText _speechToText = SpeechToText();
  var isListening = false.obs;
  var recognizedText = "".obs;

  // Attachment state
  var selectedAttachmentPath = "".obs;
  var selectedAttachmentName = "".obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize AI session
    aiSession.value = ChatSession(memberId: 'ai_bot');
    fetchPersonalChats();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speechToText.initialize();
  }

  Future<bool> toggleListening() async {
    if (isListening.value) {
      await _speechToText.stop();
      isListening.value = false;
      return false;
    } else {
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        bool available = await _speechToText.initialize();
        if (available) {
          recognizedText.value = '';
          isListening.value = true;
          _speechToText.listen(
            onResult: (result) {
              recognizedText.value = result.recognizedWords;
              if (result.finalResult) {
                isListening.value = false;
              }
            },
            listenOptions: SpeechListenOptions(
              listenFor: const Duration(seconds: 60),
              pauseFor: const Duration(seconds: 15),
              cancelOnError: true,
              listenMode: ListenMode.dictation,
            ),
          );
          return true;
        }
      } else {
        Get.snackbar(
          'Permission Denied',
          'Please grant microphone permission to use voice typing.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    }
    return false;
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 60, // Compress to ~60% quality
      maxWidth: 800, // Resize large images
    );
    if (pickedFile != null) {
      selectedAttachmentPath.value = pickedFile.path;
      selectedAttachmentName.value = pickedFile.name;
    }
  }

  Future<void> pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );
    if (result != null && result.files.single.path != null) {
      selectedAttachmentPath.value = result.files.single.path!;
      selectedAttachmentName.value = result.files.single.name;
    }
  }

  void clearAttachment() {
    selectedAttachmentPath.value = '';
    selectedAttachmentName.value = '';
  }

  // Map to hold sessions by member ID for quick lookup
  List<ChatSession> getSessionsForMember(String memberId) {
    return chatSessions.where((s) => s.memberId == memberId).toList();
  }

  void startNewSession(String memberId) {
    final session = ChatSession(memberId: memberId);
    chatSessions.insert(0, session);
    currentSession.value = session;
  }

  void loadSession(String sessionId) {
    currentSession.value = chatSessions.firstWhereOrNull((s) => s.id == sessionId);
  }

  void clearAiSession() {
    aiSession.value = ChatSession(memberId: 'ai_bot');
  }

  Future<void> sendMessage(String text, {bool isAiChat = true}) async {
    if (!_checkAndShowLimit()) return;

    if (isAiChat && aiSession.value == null) {
      aiSession.value = ChatSession(memberId: 'ai_bot');
    }
    
    final sessionToUpdate = isAiChat ? aiSession : currentSession;
    if (sessionToUpdate.value == null || text.trim().isEmpty) return;

    // Add user message
    final userMsg = ChatMessage(text: text, isUser: true);
    sessionToUpdate.value!.messages.add(userMsg);
    sessionToUpdate.value!.updatedAt = DateTime.now();
    sessionToUpdate.refresh();
    
    final subscriptionController = Get.find<SubscriptionController>();
    if (!subscriptionController.hasActivePro) {
      await subscriptionController.incrementSentCount();
    }
    
    if (!isAiChat) {
      chatSessions.refresh();
      // Save a mock reply to backend so it persists
      Future.delayed(const Duration(seconds: 1), () async {
        final mockText = "Got it!";
        final tempMsg = ChatMessage(text: mockText, isUser: false);
        sessionToUpdate.value!.messages.add(tempMsg);
        sessionToUpdate.refresh();
        chatSessions.refresh();

        if (activeChatId.value != null) {
          final saveResult = await SendMessageService.sendMessage(
            content: mockText,
            chatId: activeChatId.value,
            role: 'assistant',
          );
          if (saveResult['success'] == true && saveResult['message'] != null) {
            final savedMsg = saveResult['message'] as ChatMessage;
            try {
              final storage = GetStorage();
              final List<dynamic> aiIds = storage.read('ai_message_ids') ?? [];
              if (!aiIds.contains(savedMsg.id)) {
                aiIds.add(savedMsg.id);
                storage.write('ai_message_ids', aiIds);
              }
            } catch (_) {}
            
            final index = sessionToUpdate.value!.messages.indexOf(tempMsg);
            if (index != -1) {
              sessionToUpdate.value!.messages[index] = ChatMessage(
                id: savedMsg.id,
                text: savedMsg.text,
                isUser: false,
                timestamp: savedMsg.timestamp,
              );
            }
          }
        }
      });
      return;
    }

    // AI Chat logic
    isLoading.value = true;

    try {
      // Create history array with strict language instructions
      final List<Map<String, String>> apiMessages = [
        {
          'role': 'system',
          'content': 'You are a helpful AI assistant. You MUST respond in the EXACT SAME language that the user uses. If the user writes in Roman Urdu/Hindi, respond ONLY in Roman Urdu/Hindi. If the user writes in pure English, respond in pure English. Match the tone and language strictly. CRITICAL: Do NOT use any asterisks (*) for formatting (no bold, no italics, no markdown lists with *). Provide plain, clean, and well-structured text with normal line breaks and numbering for lists. Be informative and clear like ChatGPT.'
        }
      ];

      for (var msg in sessionToUpdate.value!.messages) {
        apiMessages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.text,
        });
      }

      final response = await http.post(
        Uri.parse('https://api.mistral.ai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer sVrzNIoEyljWaPI3F4gPOcFffYO8K98G',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'mistral-large-latest',
          'messages': apiMessages
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['choices'][0]['message']['content'] ?? 'No response';
        
        final aiMsg = ChatMessage(text: aiText, isUser: false);
        sessionToUpdate.value!.messages.add(aiMsg);
      } else {
        // Handle error
        final errorMsg = ChatMessage(
          text: "Oops! Something went wrong while contacting the AI.",
          isUser: false,
        );
        sessionToUpdate.value!.messages.add(errorMsg);
      }
    } catch (e) {
      final errorMsg = ChatMessage(
        text: "Network error: Could not reach the AI.",
        isUser: false,
      );
      sessionToUpdate.value!.messages.add(errorMsg);
    } finally {
      isLoading.value = false;
      sessionToUpdate.value!.updatedAt = DateTime.now();
      sessionToUpdate.refresh();
    }
  }

  Future<void> fetchPersonalChats() async {
    isChatsLoading.value = true;
    final result = await ListChatsService.listChats();
    isChatsLoading.value = false;

    if (result['success'] == true && result['chats'] != null) {
      personalChats.assignAll(result['chats'] as List<ChatModel>);
    }
  }

  Future<ChatModel?> getChatDetails(int chatId) async {
    isChatsLoading.value = true;
    final result = await GetChatService.getChat(chatId);
    isChatsLoading.value = false;

    if (result['success'] == true && result['chat'] != null) {
      return result['chat'] as ChatModel;
    } else {
      Get.snackbar(
        'Error',
        result['message'] ?? 'Failed to load chat details',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return null;
    }
  }

  Future<bool> deletePersonalChat(int chatId) async {
    isDeletingChat.value = true;
    final result = await DeleteChatService.deleteChat(chatId);
    isDeletingChat.value = false;

    if (result['success'] == true) {
      personalChats.removeWhere((c) => c.chatId == chatId);
      Get.snackbar(
        'Deleted',
        'Chat deleted successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryTeal,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return true;
    } else {
      Get.snackbar(
        'Error',
        result['message'] ?? 'Failed to delete chat',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
      return false;
    }
  }

  Future<void> loadChatMessages(int chatId) async {
    activeMessages.clear();
    isMessagesLoading.value = true;
    activeChatId.value = chatId;
    final result = await GetChatMessagesService.getChatMessages(chatId);
    isMessagesLoading.value = false;

    if (result['success'] == true && result['messages'] != null) {
      activeMessages.assignAll(result['messages'] as List<ChatMessage>);
    } else {
      activeMessages.clear();
    }
  }

  Future<void> clearCurrentChatMessages() async {
    if (activeChatId.value == null) return;

    isLoading.value = true;
    final result = await ClearChatMessagesService.clearChatMessages(activeChatId.value!);
    isLoading.value = false;

    if (result['success'] == true) {
      activeMessages.clear();
      Get.snackbar(
        'Success',
        'Chat cleared successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryTeal,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
    } else {
      Get.snackbar(
        'Error',
        result['message'] ?? 'Failed to clear chat',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  Future<void> sendFamilyMemberMessage(String content, FamilyMember member) async {
    if (content.trim().isEmpty && selectedAttachmentPath.value.isEmpty) return;
    if (!_checkAndShowLimit()) return;

    final displayContent = content.trim().isEmpty ? "Sent an attachment" : content;
    final tempMsg = ChatMessage(text: displayContent, isUser: true, localAttachmentPath: selectedAttachmentPath.value.isNotEmpty ? selectedAttachmentPath.value : null);
    activeMessages.add(tempMsg);

    final String currentAttachmentPath = selectedAttachmentPath.value;
    // Clear attachment immediately so UI updates
    clearAttachment();

    final result = await SendMessageService.sendMessage(
      content: displayContent,
      familyMemberId: member.chatId == null ? int.tryParse(member.id) : null,
      chatId: member.chatId,
      attachmentPath: currentAttachmentPath,
    );

    if (result['success'] == true) {
      final subscriptionController = Get.find<SubscriptionController>();
      if (!subscriptionController.hasActivePro) {
        await subscriptionController.incrementSentCount();
      }
      if (result['message'] != null) {
        final index = activeMessages.indexOf(tempMsg);
        if (index != -1) {
          final savedMsg = result['message'] as ChatMessage;
          activeMessages[index] = ChatMessage(
            id: savedMsg.id,
            text: savedMsg.text,
            isUser: tempMsg.isUser,
            timestamp: savedMsg.timestamp,
            attachmentUrl: savedMsg.attachmentUrl,
            localAttachmentPath: tempMsg.localAttachmentPath,
          );
        }
      }

      // Update activeChatId if newly created or exists
      final activeId = member.chatId ?? result['chatId'] as int?;
      if (activeId != null) {
        activeChatId.value = activeId;
      }
      
      final homeCtrl = Get.find<HomeController>();
      final index = homeCtrl.members.indexWhere((m) => m.id == member.id);
      if (index != -1) {
        final updatedMember = FamilyMember(
          id: member.id,
          name: member.name,
          profilePicture: member.profilePicture,
          gender: member.gender,
          relationship: member.relationship,
          threadsDetail: member.threadsDetail,
          chatId: activeId,
          lastMessage: content,
          updatedAt: DateTime.now(),
        );
        homeCtrl.members[index] = updatedMember;
      }

      // Also update the chat model in personalChats list to show the new message and time instantly
      if (activeId != null) {
        final chatIndex = personalChats.indexWhere((c) => c.chatId == activeId);
        if (chatIndex != -1) {
          final oldChat = personalChats[chatIndex];
          final updatedChat = ChatModel(
            chatId: oldChat.chatId,
            title: oldChat.title,
            name: oldChat.name,
            avatar: oldChat.avatar,
            familyMemberId: oldChat.familyMemberId,
            lastMessage: content,
            updatedAt: DateTime.now(), // Local time which gets formatted as local
          );
          personalChats.removeAt(chatIndex);
          personalChats.insert(0, updatedChat);
        } else {
          final newChat = ChatModel(
            chatId: activeId,
            title: '',
            name: member.name,
            avatar: member.profilePicture,
            familyMemberId: int.tryParse(member.id),
            lastMessage: content,
            updatedAt: DateTime.now(),
          );
          personalChats.insert(0, newChat);
        }
      }

      // Trigger AI response for family member
      _triggerFamilyMemberAiResponse(content, member);
    } else {
      activeMessages.remove(tempMsg);
      Get.snackbar(
        'Error',
        result['message'] ?? 'Failed to send message',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  Future<void> sendPersonalMessage(String content) async {
    if (content.trim().isEmpty && selectedAttachmentPath.value.isEmpty) return;
    if (!_checkAndShowLimit()) return;

    final displayContent = content.trim().isEmpty ? "Sent an attachment" : content;
    final tempMsg = ChatMessage(text: displayContent, isUser: true, localAttachmentPath: selectedAttachmentPath.value.isNotEmpty ? selectedAttachmentPath.value : null);
    activeMessages.add(tempMsg);

    final result = await SendMessageService.sendMessage(
      content: displayContent,
      chatId: activeChatId.value,
      attachmentPath: selectedAttachmentPath.value,
    );
    
    // Clear attachment after sending
    clearAttachment();

    if (result['success'] == true) {
      final subscriptionController = Get.find<SubscriptionController>();
      if (!subscriptionController.hasActivePro) {
        await subscriptionController.incrementSentCount();
      }
      if (result['message'] != null) {
        final index = activeMessages.indexOf(tempMsg);
        if (index != -1) {
          final savedMsg = result['message'] as ChatMessage;
          activeMessages[index] = ChatMessage(
            id: savedMsg.id,
            text: savedMsg.text,
            isUser: tempMsg.isUser,
            timestamp: savedMsg.timestamp,
            attachmentUrl: savedMsg.attachmentUrl,
            localAttachmentPath: tempMsg.localAttachmentPath,
          );
        }
      }

      if (activeChatId.value == null && result['chatId'] != null) {
        activeChatId.value = result['chatId'] as int;
        fetchPersonalChats(); // refresh personal chats list
      }
      _triggerAiResponse(displayContent);
    } else {
      activeMessages.remove(tempMsg);
      Get.snackbar(
        'Error',
        result['message'] ?? 'Failed to send message',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
      );
    }
  }

  String _getMimeType(String path) {
    if (path.toLowerCase().endsWith('.png')) return 'image/png';
    if (path.toLowerCase().endsWith('.jpg') || path.toLowerCase().endsWith('.jpeg')) return 'image/jpeg';
    if (path.toLowerCase().endsWith('.gif')) return 'image/gif';
    if (path.toLowerCase().endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }

  Future<void> _triggerAiResponse(String userPrompt) async {
    final int? capturedChatId = activeChatId.value;
    isLoading.value = true;
    try {
      bool hasImage = false;
      final List<Map<String, dynamic>> apiMessages = [
        {
          'role': 'system',
          'content': 'You are a helpful AI assistant. You MUST respond in the EXACT SAME language that the user uses. If the user writes in Roman Urdu/Hindi, respond ONLY in Roman Urdu/Hindi. If the user writes in pure English, respond in pure English. Match the tone and language strictly. CRITICAL: Do NOT use any asterisks (*) for formatting (no bold, no italics, no markdown lists with *). Provide plain, clean, and well-structured text with normal line breaks and numbering for lists. Be informative and clear like ChatGPT.'
        }
      ];

      for (var msg in activeMessages) {
        if (msg.localAttachmentPath != null || msg.attachmentUrl != null) {
           final isLocal = msg.localAttachmentPath != null;
           final pathOrUrl = isLocal ? msg.localAttachmentPath! : msg.attachmentUrl!;
           final isImage = pathOrUrl.toLowerCase().endsWith('.png') || 
                           pathOrUrl.toLowerCase().endsWith('.jpg') || 
                           pathOrUrl.toLowerCase().endsWith('.jpeg') || 
                           pathOrUrl.toLowerCase().endsWith('.webp') || 
                           pathOrUrl.toLowerCase().endsWith('.gif');
           if (isImage) {
             hasImage = true;
             final List<Map<String, dynamic>> contentList = [];
             contentList.add({'type': 'text', 'text': msg.text});
             
             if (isLocal) {
               final file = File(pathOrUrl);
               if (file.existsSync()) {
                 final bytes = file.readAsBytesSync();
                 final base64String = base64Encode(bytes);
                 final mime = _getMimeType(pathOrUrl);
                 contentList.add({
                   'type': 'image_url',
                   'image_url': 'data:$mime;base64,$base64String',
                 });
               }
             } else {
               contentList.add({
                   'type': 'image_url',
                   'image_url': pathOrUrl,
               });
             }
             apiMessages.add({
                'role': msg.isUser ? 'user' : 'assistant',
                'content': contentList,
             });
           } else {
             apiMessages.add({
                'role': msg.isUser ? 'user' : 'assistant',
                'content': msg.text,
             });
           }
        } else {
          apiMessages.add({
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.text,
          });
        }
      }

      final response = await http.post(
        Uri.parse('https://api.mistral.ai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer sVrzNIoEyljWaPI3F4gPOcFffYO8K98G',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': hasImage ? 'pixtral-12b-2409' : 'mistral-large-latest',
          'messages': apiMessages
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['choices'][0]['message']['content'] ?? 'No response';
        final tempAiMsg = ChatMessage(text: aiText, isUser: false);
        
        // Only append to UI if we are still on the same chat!
        if (activeChatId.value == capturedChatId) {
          activeMessages.add(tempAiMsg);
        }

        // Save AI response to the database on the backend so it persists across screen navigations
        if (capturedChatId != null) {
          final saveResult = await SendMessageService.sendMessage(
            content: aiText,
            chatId: capturedChatId,
            role: 'assistant',
          );
          if (saveResult['success'] == true && saveResult['message'] != null) {
            if (activeChatId.value == capturedChatId) {
              final index = activeMessages.indexOf(tempAiMsg);
              if (index != -1) {
                final savedMsg = saveResult['message'] as ChatMessage;
                
                // Local fix: Remember this ID is an AI message
                try {
                  final storage = GetStorage();
                  final List<dynamic> aiIds = storage.read('ai_message_ids') ?? [];
                  if (!aiIds.contains(savedMsg.id)) {
                    aiIds.add(savedMsg.id);
                    storage.write('ai_message_ids', aiIds);
                  }
                } catch (_) {}

                activeMessages[index] = ChatMessage(
                  id: savedMsg.id,
                  text: savedMsg.text,
                  isUser: tempAiMsg.isUser,
                  timestamp: savedMsg.timestamp,
                );
              }
            }
          }
          // Refresh list to update Case History preview (this runs safely in background)
          fetchPersonalChats();
        }
      } else {
        if (activeChatId.value == capturedChatId) {
          activeMessages.add(ChatMessage(
            text: "Oops! Something went wrong while contacting the AI.",
            isUser: false,
          ));
        }
      }
    } catch (e) {
      if (activeChatId.value == capturedChatId) {
        activeMessages.add(ChatMessage(
          text: "Network error: Could not reach the AI.",
          isUser: false,
        ));
      }
    } finally {
      if (activeChatId.value == capturedChatId) {
        isLoading.value = false;
      }
    }
  }

  Future<void> _triggerFamilyMemberAiResponse(String userPrompt, FamilyMember member) async {
    final int? capturedChatId = activeChatId.value;
    isLoading.value = true;
    try {
      final String memberName = member.name;
      final String memberRelationship = member.relationship;
      final String memberGender = member.gender;
      final String details = member.threadsDetail ?? '';

      final List<Map<String, String>> apiMessages = [
        {
          'role': 'system',
          'content': 'You are a helpful AI assistant. You MUST respond in the EXACT SAME language that the user uses. If the user writes in Roman Urdu/Hindi, respond ONLY in Roman Urdu/Hindi. If the user writes in pure English, respond in pure English. Match the tone and language strictly. CRITICAL: Do NOT use any asterisks (*) for formatting (no bold, no italics, no markdown lists with *). Provide plain, clean, and well-structured text with normal line breaks and numbering for lists. \nContext about the family member you are helping with:\nName: $memberName\nRelationship: $memberRelationship\nGender: $memberGender\nMedical History / Details: $details'
        }
      ];

      for (var msg in activeMessages) {
        apiMessages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.text,
        });
      }

      final response = await http.post(
        Uri.parse('https://api.mistral.ai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer sVrzNIoEyljWaPI3F4gPOcFffYO8K98G',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'mistral-large-latest',
          'messages': apiMessages
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['choices'][0]['message']['content'] ?? 'No response';
        final tempAiMsg = ChatMessage(text: aiText, isUser: false);
        
        if (activeChatId.value == capturedChatId) {
          activeMessages.add(tempAiMsg);
        }

        // Save AI response to the database on the backend so it persists across screen navigations
        if (capturedChatId != null) {
          final saveResult = await SendMessageService.sendMessage(
            content: aiText,
            chatId: capturedChatId,
            role: 'assistant',
          );
          if (saveResult['success'] == true && saveResult['message'] != null) {
            if (activeChatId.value == capturedChatId) {
              final index = activeMessages.indexOf(tempAiMsg);
              if (index != -1) {
                final savedMsg = saveResult['message'] as ChatMessage;
                
                // Local fix: Remember this ID is an AI message
                try {
                  final storage = GetStorage();
                  final List<dynamic> aiIds = storage.read('ai_message_ids') ?? [];
                  if (!aiIds.contains(savedMsg.id)) {
                    aiIds.add(savedMsg.id);
                    storage.write('ai_message_ids', aiIds);
                  }
                } catch (_) {}

                activeMessages[index] = ChatMessage(
                  id: savedMsg.id,
                  text: savedMsg.text,
                  isUser: tempAiMsg.isUser,
                  timestamp: savedMsg.timestamp,
                );
              }
            }
          }
          
          // Also update the family member's last message on home controller so it shows up in home list/threads
          final homeCtrl = Get.find<HomeController>();
          final index = homeCtrl.members.indexWhere((m) => m.id == member.id);
          if (index != -1) {
            final updatedMember = FamilyMember(
              id: member.id,
              name: member.name,
              profilePicture: member.profilePicture,
              gender: member.gender,
              relationship: member.relationship,
              threadsDetail: member.threadsDetail,
              chatId: capturedChatId,
              lastMessage: aiText,
              updatedAt: DateTime.now(),
            );
            homeCtrl.members[index] = updatedMember;
          }

          // Update the chat model in personalChats list to show the AI response as the last message
          final chatIndex = personalChats.indexWhere((c) => c.chatId == capturedChatId);
          if (chatIndex != -1) {
            final oldChat = personalChats[chatIndex];
            final updatedChat = ChatModel(
              chatId: oldChat.chatId,
              title: oldChat.title,
              name: oldChat.name,
              avatar: oldChat.avatar,
              familyMemberId: oldChat.familyMemberId,
              lastMessage: aiText,
              updatedAt: DateTime.now(),
            );
            personalChats.removeAt(chatIndex);
            personalChats.insert(0, updatedChat);
          }
        }
      } else {
        if (activeChatId.value == capturedChatId) {
          activeMessages.add(ChatMessage(
            text: "Oops! Something went wrong while contacting the AI.",
            isUser: false,
          ));
        }
      }
    } catch (e) {
      if (activeChatId.value == capturedChatId) {
        activeMessages.add(ChatMessage(
          text: "Network error: Could not reach the AI.",
          isUser: false,
        ));
      }
    } finally {
      if (activeChatId.value == capturedChatId) {
        isLoading.value = false;
      }
    }
  }

  bool _checkAndShowLimit() {
    final subscriptionController = Get.find<SubscriptionController>();
    if (!subscriptionController.canSendFreeMessage) {
      Get.snackbar(
        'Limit Reached',
        'You have used your 10 free messages for today. Please upgrade to Pro for unlimited access!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 4),
        mainButton: TextButton(
          onPressed: () {
            if (Get.isSnackbarOpen) {
              Get.back();
            }
            Get.to(() => const PremiumScreen());
          },
          child: const Text(
            'Upgrade',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
      Get.to(() => const PremiumScreen());
      return false;
    }
    return true;
  }
  void clearChat() {
    activeChatId.value = null;
    activeMessages.clear();
    aiSession.value = null;
  }
}

