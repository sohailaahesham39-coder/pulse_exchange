import 'package:flutter/cupertino.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderImage;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String messageType; // "text", "image", "medication_request"
  final Map<String, dynamic>? metadata;
  final bool isAI;
  final List<String> reactions; // e.g., ['thumbs_up', 'thumbs_down']
  final bool isPinned;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderImage,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.isRead,
    required this.messageType,
    this.metadata,
    required this.isAI,
    this.reactions = const [], // Default to empty list
    this.isPinned = false, // Default to not pinned
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    try {
      return ChatMessage(
        id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: json['senderId']?.toString() ?? 'unknown',
        senderName: json['senderName']?.toString() ?? 'Unknown',
        senderImage: json['senderImage']?.toString(),
        receiverId: json['receiverId']?.toString() ?? 'unknown',
        content: json['content']?.toString() ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now()
            : DateTime.now(),
        isRead: json['isRead'] as bool? ?? false,
        messageType: json['messageType']?.toString() ?? 'text',
        metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata'] as Map) : null,
        isAI: json['isAI'] as bool? ?? (json['senderId']?.toString() == 'ai_chatbot'),
        reactions: (json['reactions'] as List<dynamic>?)?.cast<String>() ?? [],
        isPinned: json['isPinned'] as bool? ?? false,
      );
    } catch (e) {
      // Handle parsing errors gracefully
      debugPrint('Error parsing ChatMessage from JSON: $e');
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'unknown',
        senderName: 'Unknown',
        receiverId: 'unknown',
        content: 'Error loading message',
        timestamp: DateTime.now(),
        isRead: false,
        messageType: 'text',
        isAI: false,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderImage': senderImage,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'messageType': messageType,
      'metadata': metadata,
      'isAI': isAI,
      'reactions': reactions,
      'isPinned': isPinned,
    };
  }

  String get formattedTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');

    if (messageDate == today) {
      return '$hour:$minute';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday $hour:$minute';
    } else {
      final day = timestamp.day.toString().padLeft(2, '0');
      final month = timestamp.month.toString().padLeft(2, '0');
      final year = timestamp.year.toString();
      return '$day/$month/$year $hour:$minute';
    }
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderImage,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    String? messageType,
    Map<String, dynamic>? metadata,
    bool? isAI,
    List<String>? reactions,
    bool? isPinned,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderImage: senderImage ?? this.senderImage,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      messageType: messageType ?? this.messageType,
      metadata: metadata ?? this.metadata,
      isAI: isAI ?? this.isAI,
      reactions: reactions ?? this.reactions,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}