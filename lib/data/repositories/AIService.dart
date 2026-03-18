import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pulse_exchange/data/models/ChatMessage.dart';

class AIService extends ChangeNotifier {
  final List<ChatMessage> _chatHistory = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isApiKeyAvailable = false;

  // Store conversation history for ChatGPT context
  final List<Map<String, String>> _conversationHistory = [];

  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isApiKeyAvailable => _isApiKeyAvailable;

  // ChatGPT API Constants
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  late final String _apiKey; // Store API key from .env

  AIService() {
    try {
      _apiKey = dotenv.env['AI_API_KEY'] ?? '';
      _isApiKeyAvailable = _apiKey.isNotEmpty;

      if (!_isApiKeyAvailable) {
        debugPrint('Warning: AI_API_KEY is not set in .env - AI features will use fallback responses');
      } else {
        debugPrint('AI_API_KEY loaded successfully');
      }
    } catch (e) {
      debugPrint('Error accessing environment variables: $e');
      _apiKey = '';
      _isApiKeyAvailable = false;
    }

    // Initialize conversation with system message
    _conversationHistory.add({
      'role': 'system',
      'content':
      'You are Pulse Exchange AI, a helpful health assistant that specializes in fitness, health monitoring, and overall wellness. Provide accurate, concise information and personalized recommendations based on the user\'s health data when available.'
    });
  }

  // Initialize service (required for main.dart compatibility)
  Future<void> init() async {
    // No async operations needed currently, but included for consistency
    debugPrint('AIService initialized');
  }

  // Send message to ChatGPT API or use fallback
  Future<ChatMessage?> sendMessage(
      String message, {
        required BuildContext context,
        Map<String, dynamic>? messageContext,
      }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'user',
        senderName: 'You',
        receiverId: 'ai_chatbot',
        content: message,
        timestamp: DateTime.now(),
        isRead: true,
        messageType: 'text',
        isAI: false,
      );

      _chatHistory.add(userMessage);
      _conversationHistory.add({
        'role': 'user',
        'content': _buildFullPrompt(message, messageContext),
      });
      notifyListeners();

      // Check if API key is available, otherwise use fallback responses
      if (!_isApiKeyAvailable) {
        return _useFallbackResponse(message, messageContext);
      }

      // Make API request to ChatGPT
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': _conversationHistory,
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final aiResponse = responseData['choices'][0]['message']['content'];

        // Add AI response to conversation history
        _conversationHistory.add({
          'role': 'assistant',
          'content': aiResponse,
        });

        final aiMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_ai',
          senderId: 'ai_chatbot',
          senderName: 'Pulse AI',
          receiverId: 'user',
          content: aiResponse,
          timestamp: DateTime.now(),
          isRead: true,
          messageType: 'text',
          isAI: true,
        );

        _chatHistory.add(aiMessage);
        debugPrint('AIService: Sent message to ChatGPT, received response');
        notifyListeners();
        return aiMessage;
      } else {
        throw Exception('Failed to connect to ChatGPT API: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      debugPrint('AIService: Error sending message: $e');

      // Use fallback if there's an API error
      return _useFallbackResponse(message, messageContext);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fallback response when API key is not available or API fails
  ChatMessage _useFallbackResponse(String message, Map<String, dynamic>? messageContext) {
    final String response = _generateFallbackResponse(message, messageContext);

    // Add fallback response to conversation history
    _conversationHistory.add({
      'role': 'assistant',
      'content': response,
    });

    final aiMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString() + '_ai_fallback',
      senderId: 'ai_chatbot',
      senderName: 'Pulse AI',
      receiverId: 'user',
      content: response,
      timestamp: DateTime.now(),
      isRead: true,
      messageType: 'text',
      isAI: true,
    );

    _chatHistory.add(aiMessage);
    debugPrint('AIService: Using fallback response');
    return aiMessage;
  }

  // Generate fallback responses based on message content
  String _generateFallbackResponse(String message, Map<String, dynamic>? messageContext) {
    final lowerMessage = message.toLowerCase();

    // Check for context type first if available
    if (messageContext != null && messageContext['type'] != null) {
      switch (messageContext['type']) {
        case 'welcome':
          return "Hello! I'm Pulse AI, your fitness and health companion. How can I help you today?";
        case 'health_tips_request':
          final bpStatus = messageContext['bpStatus'] as String? ?? 'normal';
          return _getHealthTipsByStatus(bpStatus);
        case 'bp_trend_analysis':
          return "Based on your recent health metrics, it's important to maintain consistent tracking. Pulse Exchange helps you visualize these trends for better health insights.";
        case 'bp_context':
          final reading = messageContext['latest_reading'];
          if (reading != null) {
            return _getBPFeedback(reading['systolic'], reading['diastolic']);
          }
      }
    }

    // General keyword-based responses
    if (lowerMessage.contains('hello') || lowerMessage.contains('hi')) {
      return 'Hello! How can I help you with your fitness and health today?';
    } else if (lowerMessage.contains('blood pressure') || lowerMessage.contains('bp')) {
      return 'Pulse Exchange makes tracking blood pressure easy. A normal reading is typically around 120/80 mmHg. Consistent monitoring helps you stay active and healthy.';
    } else if (lowerMessage.contains('medicine') || lowerMessage.contains('medication')) {
      return 'It\'s important to take your medications as prescribed. Pulse Exchange can help you track your health while managing your medications.';
    } else if (lowerMessage.contains('fitness') || lowerMessage.contains('workout')) {
      return 'Regular exercise is key to cardiovascular health. Pulse Exchange tracks your activity levels to help you reach your fitness goals.';
    } else if (lowerMessage.contains('diet') || lowerMessage.contains('food') || lowerMessage.contains('eat')) {
      return 'A balanced diet rich in whole foods supports your fitness journey. Focus on lean proteins, complex carbs, and plenty of vegetables.';
    } else {
      return 'Thank you for your message. I can provide general information about health metrics, fitness tracking, and wellness management. How else can I assist you?';
    }
  }

  // Fallback status-based health tips
  String _getHealthTipsByStatus(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return "Great job maintaining normal health levels! Here are some tips:\n\n"
            "1. Keep up the regular exercise, aiming for 150+ minutes weekly.\n"
            "2. Maintain a balanced diet rich in whole grains and lean protein.\n"
            "3. Stay hydrated, especially during workouts.\n"
            "4. Prioritize 7-9 hours of quality sleep.\n"
            "5. Continue tracking your progress in Pulse Exchange.";
      default:
        return "Here are some general wellness tips:\n\n"
            "1. Incorporate 30 minutes of activity daily.\n"
            "2. Reduce processed food and excess sodium.\n"
            "3. Use Pulse Exchange to monitor your metrics daily.\n"
            "4. Stay consistent with your fitness routine.\n"
            "5. Consult with a professional for personalized plans.";
    }
  }

  // Fallback health metric feedback
  String _getBPFeedback(dynamic systolic, dynamic diastolic) {
    int sys = systolic is int ? systolic : int.tryParse(systolic.toString()) ?? 120;
    int dia = diastolic is int ? diastolic : int.tryParse(diastolic.toString()) ?? 80;

    if (sys >= 140 || dia >= 90) {
      return "Your recent reading of $sys/$dia mmHg is higher than ideal. Consider tracking your activity and stress levels in Pulse Exchange, and consult a professional if this persists.";
    } else if (sys >= 120 && sys < 140) {
      return "Your reading of $sys/$dia mmHg is slightly elevated. Increasing your cardio activity and monitoring your sodium intake can help.";
    } else {
      return "Your reading of $sys/$dia mmHg is in a healthy range. Keep up the active lifestyle!";
    }
  }

  // Build a complete prompt with context
  String _buildFullPrompt(String message, Map<String, dynamic>? messageContext) {
    String fullPrompt = message;

    if (messageContext != null) {
      switch (messageContext['type']) {
        case 'welcome':
          fullPrompt = "The user ${messageContext['userName']} has just opened the chat. Greet them as Pulse AI and ask how you can help with their fitness goals today. Original message: $message";
          break;
        case 'health_ips_request':
          fullPrompt = "The user is asking for fitness and health tips. Their current health status is '${messageContext['bpStatus']}'. Provide specific, actionable advice. Original message: $message";
          break;
      }
    }

    return fullPrompt;
  }

  // Get health tips based on status
  Future<List<String>> getHealthTips({required String bpStatus}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (!_isApiKeyAvailable) {
        return _getHealthTipsByStatus(bpStatus).split('\n').where((s) => s.contains('.')).toList();
      }

      final prompt = "Provide 5 specific fitness and health tips for someone with $bpStatus health status. Format as a simple list.";
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [{'role': 'user', 'content': prompt}],
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'] as String;
        return text.split('\n').where((s) => s.trim().isNotEmpty).toList();
      }
      return [_getHealthTipsByStatus(bpStatus)];
    } catch (e) {
      return [_getHealthTipsByStatus(bpStatus)];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear chat history
  void clearChat() {
    _chatHistory.clear();
    _conversationHistory.clear();
    _conversationHistory.add({
      'role': 'system',
      'content': 'You are Pulse Exchange AI, a helpful health assistant.'
    });
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}