import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/AuthService.dart';
import '../../services/chat_service.dart';
import '../../widget/chat/ChatInput.dart';
import '../../widget/chat/MessageBubble.dart';

class UserChatScreen extends StatefulWidget {
  final String threadId;
  final String userId;
  final String userName;

  const UserChatScreen({
    Key? key,
    required this.threadId,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  bool _isLoading = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markThreadAsRead();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final chatService = context.read<ChatService>();
      final userId = authService.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await chatService.fetchMessages(widget.threadId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _markThreadAsRead() async {
    try {
      final authService = context.read<AuthService>();
      final chatService = context.read<ChatService>();
      final userId = authService.currentUser?.id;

      if (userId == null) {
        return; // Silently skip if not authenticated
      }

      await chatService.markThreadAsRead(widget.threadId);
    } catch (e) {
      debugPrint('Error marking thread as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    _textController.clear();

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final chatService = context.read<ChatService>();
      final userId = authService.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await chatService.sendMessage(
        widget.threadId,
        message,
        context: context,
      );
      await _loadMessages();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatService = context.watch<ChatService>();
    final messages = chatService.getMessagesForThread(widget.threadId);
    final currentUser = context.watch<AuthService>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'Refresh Messages',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No messages yet',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start a conversation by sending a message',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message.senderId == currentUser?.id;
                return MessageBubble(
                  message: message,
                  isUser: isUser,
                );
              },
            ),
          ),
          if (_isLoading && messages.isNotEmpty) const LinearProgressIndicator(),
          ChatInput(
            controller: _textController,
            onSend: _sendMessage,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}