import 'package:flutter/material.dart';
import '../model/ChatMessage.dart';

class ChatThread {
  final String id;
  final String userId;
  final String participantId;
  final String participantName;
  final String? participantImage;
  final DateTime lastMessageTime;
  final String lastMessageContent;
  final bool hasUnreadMessages;
  final int unreadCount;
  final String type; // 'ai', 'medication', 'user', etc.

  ChatThread({
    required this.id,
    required this.userId,
    required this.participantId,
    required this.participantName,
    this.participantImage,
    required this.lastMessageTime,
    required this.lastMessageContent,
    required this.hasUnreadMessages,
    required this.unreadCount,
    this.type = 'user', // Default to user type
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    try {
      return ChatThread(
        id: json['id'] as String? ?? 'thread_${DateTime.now().millisecondsSinceEpoch}',
        userId: json['userId'] as String? ?? 'unknown',
        participantId: json['participantId'] as String? ?? 'unknown',
        participantName: json['participantName'] as String? ?? 'Unknown',
        participantImage: json['participantImage'] as String?,
        lastMessageTime: json['lastMessageTime'] != null
            ? DateTime.tryParse(json['lastMessageTime'] as String) ?? DateTime.now()
            : DateTime.now(),
        lastMessageContent: json['lastMessageContent'] as String? ?? '',
        hasUnreadMessages: json['hasUnreadMessages'] as bool? ?? false,
        unreadCount: json['unreadCount'] as int? ?? 0,
        type: json['type'] as String? ?? 'user',
      );
    } catch (e) {
      // Handle parsing errors gracefully
      debugPrint('Error parsing ChatThread from JSON: $e');
      return ChatThread(
        id: 'thread_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'unknown',
        participantId: 'unknown',
        participantName: 'Unknown',
        lastMessageTime: DateTime.now(),
        lastMessageContent: 'Error loading thread',
        hasUnreadMessages: false,
        unreadCount: 0,
        type: 'user',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'participantId': participantId,
      'participantName': participantName,
      'participantImage': participantImage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'lastMessageContent': lastMessageContent,
      'hasUnreadMessages': hasUnreadMessages,
      'unreadCount': unreadCount,
      'type': type,
    };
  }

  String get formattedLastMessageTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(lastMessageTime.year, lastMessageTime.month, lastMessageTime.day);

    if (messageDate == today) {
      return '${lastMessageTime.hour.toString().padLeft(2, '0')}:${lastMessageTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${lastMessageTime.day}/${lastMessageTime.month}/${lastMessageTime.year}';
    }
  }

  bool get isAI => participantId == 'ai_chatbot';

  // Getters for compatibility with CombinedChatScreen
  String get otherUserName => participantName;
  String get otherUserId => participantId;

  // For backward compatibility with code that might use lastMessage
  ChatMessage? get lastMessage => null;

  ChatThread copyWith({
    String? id,
    String? userId,
    String? participantId,
    String? participantName,
    String? participantImage,
    DateTime? lastMessageTime,
    String? lastMessageContent,
    bool? hasUnreadMessages,
    int? unreadCount,
    String? type,
  }) {
    return ChatThread(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantImage: participantImage ?? this.participantImage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
      unreadCount: unreadCount ?? this.unreadCount,
      type: type ?? this.type,
    );
  }
}