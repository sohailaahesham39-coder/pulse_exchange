import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'package:pulse_exchange/data/models/ChatMessage.dart';
import 'package:pulse_exchange/data/models/ChatThread.dart';
import 'AIService.dart'; // Ensure this import points to your AIService class

class ChatService extends ChangeNotifier {
  final List<ChatThread> _chatThreads = [];
  final Map<String, List<ChatMessage>> _chatMessages = {};
  bool _isLoading = false;
  String? _errorMessage;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  List<ChatThread> get chatThreads => List.unmodifiable(_chatThreads);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get messages for a specific chat thread
  List<ChatMessage> getMessagesForThread(String threadId) {
    return List.unmodifiable(_chatMessages[threadId] ?? []);
  }

  /// Initializes the service by loading stored threads and messages
  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load threads from secure storage
      final storedThreads = await _secureStorage.read(key: 'chat_threads');
      if (storedThreads != null) {
        final data = jsonDecode(storedThreads);
        if (data is List) {
          _chatThreads.clear();
          _chatThreads.addAll(data.map((item) => ChatThread.fromJson(item as Map<String, dynamic>)));
          debugPrint('ChatService: Loaded ${_chatThreads.length} threads from storage');
        } else {
          debugPrint('ChatService: Invalid thread data format');
        }
      }

      // Load messages for each thread
      for (final thread in _chatThreads) {
        final storedMessages = await _secureStorage.read(key: 'chat_messages_${thread.id}');
        if (storedMessages != null) {
          final data = jsonDecode(storedMessages);
          if (data is List) {
            _chatMessages[thread.id] = data.map((item) => ChatMessage.fromJson(item as Map<String, dynamic>)).toList();
            debugPrint('ChatService: Loaded ${_chatMessages[thread.id]!.length} messages for thread ${thread.id}');
          } else {
            debugPrint('ChatService: Invalid message data format for thread ${thread.id}');
            _chatMessages[thread.id] = [];
          }
        } else {
          _chatMessages[thread.id] = [];
        }
      }
    } catch (e) {
      _errorMessage = 'Error initializing chat: ${e.toString()}';
      debugPrint('ChatService: Error initializing: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all chat threads for the current user
  Future<void> fetchThreads() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate fetching threads (replace with actual API call if needed)
      await Future.delayed(const Duration(seconds: 1));
      debugPrint('ChatService: Fetched ${_chatThreads.length} chat threads');
    } catch (e) {
      _errorMessage = 'Error fetching threads: ${e.toString()}';
      debugPrint('ChatService: Error fetching chat threads: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch messages for a specific chat thread
  Future<void> fetchMessages(String threadId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate fetching messages (replace with actual API call if needed)
      await Future.delayed(const Duration(seconds: 1));
      _markThreadAsRead(threadId);
      debugPrint('ChatService: Fetched ${_chatMessages[threadId]?.length ?? 0} messages for thread $threadId');
    } catch (e) {
      _errorMessage = 'Error fetching messages: ${e.toString()}';
      debugPrint('ChatService: Error fetching messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send a message in a thread

  Future<bool> sendMessage(
      String threadId,
      String content, {
        String messageType = 'text',
        Map<String, dynamic>? metadata,
        required BuildContext context,
      }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Find the thread
      final thread = _chatThreads.firstWhere(
            (t) => t.id == threadId,
        orElse: () => throw Exception('Thread not found'),
      );

      // Create new user message
      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'mock_user',
        senderName: 'You',
        receiverId: thread.participantId,
        content: content,
        timestamp: DateTime.now(),
        isRead: false,
        messageType: messageType,
        metadata: metadata,
        isAI: false,
      );

      // Add message to local cache
      _chatMessages.putIfAbsent(threadId, () => []).add(message);

      // Save messages to secure storage
      await _secureStorage.write(
        key: 'chat_messages_$threadId',
        value: jsonEncode(_chatMessages[threadId]!.map((m) => m.toJson()).toList()),
      );

      // Update thread with latest message
      await _updateThreadWithLatestMessage(threadId, message);

      // Handle AI response if the thread is with ai_chatbot
      if (thread.isAI) {
        try {
          final aiService = Provider.of<AIService>(context, listen: false);

          // Call sendMessage without expecting a return value
          await aiService.sendMessage(
            content,
            context: context,
            messageContext: metadata,
          );

          // Retrieve the latest AI message from aiService.chatHistory
          ChatMessage? aiMessage;
          final chatHistory = aiService.chatHistory;
          if (chatHistory.isNotEmpty) {
            // Find the last message that is from AI
            aiMessage = chatHistory.lastWhere(
                  (msg) => msg.isAI,
              orElse: () => ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString() + '_ai_fallback',
                senderId: 'ai_chatbot',
                senderName: 'AI Assistant',
                receiverId: 'mock_user',
                content: 'I couldn’t generate a response at this time.',
                timestamp: DateTime.now().add(const Duration(seconds: 1)),
                isRead: true,
                messageType: 'text',
                isAI: true,
              ),
            );
          }

          // Process the AI message if we have one
          if (aiMessage != null) {
            // Add message to local cache
            _chatMessages[threadId]!.add(aiMessage);

            // Save messages to secure storage
            await _secureStorage.write(
              key: 'chat_messages_$threadId',
              value: jsonEncode(_chatMessages[threadId]!.map((m) => m.toJson()).toList()),
            );

            // Update thread with latest message
            await _updateThreadWithLatestMessage(threadId, aiMessage);
          } else {
            debugPrint('ChatService: No AI response found in chat history');
            // Add a fallback message
            final fallbackMessage = ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_fallback',
              senderId: 'ai_chatbot',
              senderName: 'AI Assistant',
              receiverId: 'mock_user',
              content: 'I apologize, but I couldn\'t generate a response at this time.',
              timestamp: DateTime.now().add(const Duration(seconds: 1)),
              isRead: true,
              messageType: 'text',
              isAI: true,
            );

            _chatMessages[threadId]!.add(fallbackMessage);
            await _secureStorage.write(
              key: 'chat_messages_$threadId',
              value: jsonEncode(_chatMessages[threadId]!.map((m) => m.toJson()).toList()),
            );
            await _updateThreadWithLatestMessage(threadId, fallbackMessage);
          }
        } catch (e) {
          debugPrint('ChatService: Error handling AI response: $e');
          _errorMessage = 'Error handling AI response: ${e.toString()}';
          // Add a fallback error message
          final errorMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString() + '_ai_error',
            senderId: 'ai_chatbot',
            senderName: 'AI Assistant',
            receiverId: 'mock_user',
            content: 'Sorry, I encountered an error processing your request.',
            timestamp: DateTime.now().add(const Duration(seconds: 1)),
            isRead: true,
            messageType: 'text',
            isAI: true,
          );

          _chatMessages[threadId]!.add(errorMessage);
          await _secureStorage.write(
            key: 'chat_messages_$threadId',
            value: jsonEncode(_chatMessages[threadId]!.map((m) => m.toJson()).toList()),
          );
          await _updateThreadWithLatestMessage(threadId, errorMessage);
        }
      } else {
        // Simulate non-AI recipient response
        final recipientMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_recipient',
          senderId: thread.participantId,
          senderName: thread.participantName,
          receiverId: 'mock_user',
          content: 'Thanks for your message! How can I assist with the medication exchange?',
          timestamp: DateTime.now().add(const Duration(seconds: 1)),
          isRead: false,
          messageType: 'text',
          isAI: false,
        );

        _chatMessages[threadId]!.add(recipientMessage);
        await _secureStorage.write(
          key: 'chat_messages_$threadId',
          value: jsonEncode(_chatMessages[threadId]!.map((m) => m.toJson()).toList()),
        );
        await _updateThreadWithLatestMessage(threadId, recipientMessage);
      }

      debugPrint('ChatService: Sent message to thread $threadId: $content');
      return true;
    } catch (e) {
      _errorMessage = 'Error sending message: ${e.toString()}';
      debugPrint('ChatService: Error sending message: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new chat thread for medication exchange
  Future<String?> createMedicationThread(
      String medicationId,
      String recipientId,
      String recipientName,
      ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate creating thread
      await Future.delayed(const Duration(seconds: 1));

      // Create new thread
      final thread = ChatThread(
        id: 'thread_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'mock_user',
        participantId: recipientId,
        participantName: recipientName,
        participantImage: null,
        lastMessageTime: DateTime.now(),
        lastMessageContent: 'Started medication exchange for ID: $medicationId',
        hasUnreadMessages: false,
        unreadCount: 0,
        type: 'medication',
      );

      _chatThreads.add(thread);

      // Save threads to secure storage
      await _secureStorage.write(
        key: 'chat_threads',
        value: jsonEncode(_chatThreads.map((t) => t.toJson()).toList()),
      );

      // Initialize empty message list for thread
      _chatMessages[thread.id] = [];

      // Add a system message about the medication
      final systemMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_system',
        senderId: 'system',
        senderName: 'System',
        receiverId: 'mock_user',
        content: 'Chat started regarding medication exchange. Please discuss pickup details and verification.',
        timestamp: DateTime.now(),
        isRead: true,

        isAI: false, messageType: '',
      );

      _chatMessages[thread.id]!.add(systemMessage);

      // Save messages to secure storage
      await _secureStorage.write(
        key: 'chat_messages_${thread.id}',
        value: jsonEncode(_chatMessages[thread.id]!.map((m) => m.toJson()).toList()),
      );

      debugPrint('ChatService: Created thread ${thread.id} for medication $medicationId with $recipientName');
      notifyListeners();
      return thread.id;
    } catch (e) {
      _errorMessage = 'Error creating thread: ${e.toString()}';
      debugPrint('ChatService: Error creating chat thread: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a chat thread
  Future<bool> deleteThread(String threadId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate deleting thread
      await Future.delayed(const Duration(seconds: 1));

      _chatThreads.removeWhere((thread) => thread.id == threadId);
      _chatMessages.remove(threadId);

      // Update secure storage
      await _secureStorage.write(
        key: 'chat_threads',
        value: jsonEncode(_chatThreads.map((t) => t.toJson()).toList()),
      );
      await _secureStorage.delete(key: 'chat_messages_$threadId');

      debugPrint('ChatService: Deleted thread $threadId');
      return true;
    } catch (e) {
      _errorMessage = 'Error deleting thread: ${e.toString()}';
      debugPrint('ChatService: Error deleting thread: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark thread as read
  Future<bool> markThreadAsRead(String threadId) async {
    try {
      // Simulate marking thread as read
      await Future.delayed(const Duration(milliseconds: 500));
      await _markThreadAsRead(threadId);
      debugPrint('ChatService: Marked thread $threadId as read');
      return true;
    } catch (e) {
      debugPrint('ChatService: Error marking thread as read: $e');
      return false;
    }
  }

  /// Update thread with latest message internally
  Future<void> _updateThreadWithLatestMessage(String threadId, ChatMessage message) async {
    final index = _chatThreads.indexWhere((thread) => thread.id == threadId);
    if (index != -1) {
      final isCurrentUser = message.senderId == 'mock_user';
      final updatedThread = _chatThreads[index].copyWith(
        lastMessageTime: message.timestamp,
        lastMessageContent: message.content,
        hasUnreadMessages: !isCurrentUser,
        unreadCount: isCurrentUser ? 0 : _chatThreads[index].unreadCount + 1,
      );

      _chatThreads[index] = updatedThread;

      // Save threads to secure storage
      await _secureStorage.write(
        key: 'chat_threads',
        value: jsonEncode(_chatThreads.map((t) => t.toJson()).toList()),
      );

      notifyListeners();
    }
  }

  /// Mark thread as read locally
  Future<void> _markThreadAsRead(String threadId) async {
    final index = _chatThreads.indexWhere((thread) => thread.id == threadId);
    if (index != -1) {
      final updatedThread = _chatThreads[index].copyWith(
        hasUnreadMessages: false,
        unreadCount: 0,
      );

      _chatThreads[index] = updatedThread;

      // Save threads to secure storage
      await _secureStorage.write(
        key: 'chat_threads',
        value: jsonEncode(_chatThreads.map((t) => t.toJson()).toList()),
      );

      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Create a thread object from chat message data
  ChatThread createThreadFromMessage(ChatMessage message, bool isCurrentUser) {
    final senderId = message.senderId;
    final senderName = message.senderName ?? 'Unknown';
    final participantId = isCurrentUser ? message.receiverId : senderId;
    final participantName = isCurrentUser ? message.receiverId : senderName;

    return ChatThread(
      id: 'thread_${DateTime.now().millisecondsSinceEpoch}',
      userId: isCurrentUser ? senderId : message.receiverId,
      participantId: participantId,
      participantName: participantName,
      participantImage: null,
      lastMessageTime: message.timestamp,
      lastMessageContent: message.content,
      hasUnreadMessages: !isCurrentUser,
      unreadCount: isCurrentUser ? 0 : 1,
      type: message.messageType == 'medication_request' ? 'medication' : 'user',
    );
  }

  /// Get chat contacts (list of users the current user has threads with)
  Future<List<Map<String, dynamic>>> getChatContacts() async {
    try {
      // Return a list of unique contacts based on threads
      final contacts = _chatThreads.map((thread) {
        return {
          'id': thread.participantId,
          'name': thread.participantName,
          'image': thread.participantImage,
        };
      }).toSet().toList();

      debugPrint('ChatService: Fetched ${contacts.length} chat contacts');
      return contacts;
    } catch (e) {
      _errorMessage = 'Error fetching contacts: ${e.toString()}';
      debugPrint('ChatService: Error fetching contacts: $e');
      return [];
    }
  }

  /// Mark messages as read in a thread
  Future<bool> markMessagesAsRead(String threadId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate marking messages as read
      await Future.delayed(const Duration(milliseconds: 500));

      // Update messages in the thread to mark them as read
      final messages = _chatMessages[threadId];
      if (messages != null) {
        final updatedMessages = messages.map((message) {
          if (!message.isRead && message.receiverId == 'mock_user') {
            return ChatMessage(
              id: message.id,
              senderId: message.senderId,
              senderName: message.senderName,
              receiverId: message.receiverId,
              content: message.content,
              timestamp: message.timestamp,
              isRead: true,
              messageType: message.messageType,
              metadata: message.metadata,
              isAI: message.isAI,
            );
          }
          return message;
        }).toList();

        _chatMessages[threadId] = updatedMessages;

        // Save updated messages to secure storage
        await _secureStorage.write(
          key: 'chat_messages_$threadId',
          value: jsonEncode(_chatMessages[threadId]!.map((m) => m.toJson()).toList()),
        );

        // Mark thread as read
        await _markThreadAsRead(threadId);
      }

      debugPrint('ChatService: Marked messages as read for thread $threadId');
      return true;
    } catch (e) {
      _errorMessage = 'Error marking messages as read: ${e.toString()}';
      debugPrint('ChatService: Error marking messages as read: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Stream messages for a specific thread
  Stream<List<ChatMessage>> streamMessages(String threadId) {
    try {
      // Create a stream that periodically checks for new messages
      return Stream.periodic(const Duration(seconds: 2), (_) {
        return getMessagesForThread(threadId);
      }).asyncMap((messages) async {
        // Fetch new messages from storage
        final storedMessages = await _secureStorage.read(key: 'chat_messages_$threadId');
        if (storedMessages != null) {
          final data = jsonDecode(storedMessages);
          if (data is List) {
            _chatMessages[threadId] = data.map((item) => ChatMessage.fromJson(item as Map<String, dynamic>)).toList();
          } else {
            debugPrint('ChatService: Invalid message data format in stream for thread $threadId');
            _chatMessages[threadId] = [];
          }
        }
        return getMessagesForThread(threadId);
      });
    } catch (e) {
      debugPrint('ChatService: Error streaming messages: $e');
      return Stream.value([]);
    }
  }
}