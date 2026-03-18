import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulse_exchange/data/repositories/AuthService.dart';
import 'package:pulse_exchange/data/repositories/BPService.dart';
import 'package:pulse_exchange/data/repositories/chat_service.dart';
import 'package:pulse_exchange/data/repositories/AIService.dart';
import 'package:pulse_exchange/widgets/chat/ChatInput.dart';
import 'package:pulse_exchange/widgets/chat/MessageBubble.dart';
import 'package:pulse_exchange/data/models/ChatMessage.dart';
import 'package:pulse_exchange/data/models/BPReadingModel.dart';
import 'package:pulse_exchange/core/theme/AppConstants.dart';

class CombinedChatScreen extends StatefulWidget {
  final String? userId;
  final String? userName;
  final String? threadId;
  final int initialTabIndex;

  const CombinedChatScreen({
    Key? key,
    this.userId,
    this.userName,
    this.threadId,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  State<CombinedChatScreen> createState() => _CombinedChatScreenState();
}

class _CombinedChatScreenState extends State<CombinedChatScreen> with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  bool _isLoading = false;
  Timer? _pollingTimer;
  late TabController _tabController;
  late AuthService _authService;
  late AIService _aiService;
  late BPService _bpService;
  late ChatService _chatService;
  bool _isUserMessagesLoaded = false;
  bool _isVisible = true;

  bool get _isAITab => _tabController.index == 0;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _aiService = Provider.of<AIService>(context, listen: false);
    _bpService = Provider.of<BPService>(context, listen: false);
    _chatService = Provider.of<ChatService>(context, listen: false);

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    if (widget.userId != null && widget.threadId != null && widget.initialTabIndex == 1) {
      _tabController.animateTo(1);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChatbot();
    });

    if (!_isAITab) {
      _loadUserMessagesAndThreads();
    }

    _startPolling();
    _tabController.addListener(() {
      if (!_isAITab && !_isUserMessagesLoaded) {
        _loadUserMessagesAndThreads();
      }
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isVisible = ModalRoute.of(context)?.isCurrent ?? true;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      Duration(seconds: AppConstants.defaultPollingInterval),
          (_) {
        if (mounted && _isVisible && !_isLoading && !_aiService.isLoading) {
          if (_isAITab) {
            _refreshAIMessages();
          } else if (widget.threadId != null) {
            _refreshUserMessages();
          }
        }
      },
    );
  }

  Future<void> _initChatbot() async {
    if (_aiService.chatHistory.isEmpty) {
      setState(() => _isLoading = true);

      try {
        final userId = _authService.currentUser?.id;
        if (userId == null) {
          throw Exception('User not authenticated');
        }

        _aiService.clearChat();
        await _aiService.sendMessage(
          'Hello',
          context: context,
          messageContext: {
            'type': 'welcome',
            'userName': _authService.currentUser?.name ?? 'User',
          },
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error initializing chatbot: $e'),
              action: SnackBarAction(label: 'Retry', onPressed: _initChatbot),
            ),
          );
        }
        debugPrint('Error initializing chatbot: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
          _scrollToBottom();
      }
    }
  }

  Future<void> _refreshAIMessages() async {
    if (_isLoading) return;

    try {
      if (!_aiService.isLoading) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing AI messages: $e')),
        );
      }
      debugPrint('Error refreshing AI messages: $e');
    }
  }

  Future<void> _sendMessageToAI() async {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    _textController.clear();
    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      Map<String, dynamic>? messageContext;
      if (_bpService.readings.isNotEmpty) {
        final latestReading = _bpService.readings.first;
        final bpStats = _bpService.getStatistics(period: 'month');
        messageContext = {
          'type': 'bp_context',
          'latest_reading': {
            'systolic': latestReading.systolic,
            'diastolic': latestReading.diastolic,
            'pulse': latestReading.pulse,
            'status': latestReading.status,
            'timestamp': latestReading.timestamp.toIso8601String(),
          },
          'stats': bpStats,
        };
      }

      await _aiService.sendMessage(
        message,
        context: context,
        messageContext: messageContext,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message to AI: $e'),
            action: SnackBarAction(label: 'Retry', onPressed: _sendMessageToAI),
          ),
        );
      }
      debugPrint('Error sending message to AI: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getHealthTips() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      String bpStatus = 'normal';
      if (_bpService.readings.isNotEmpty) {
        bpStatus = _bpService.readings.first.status;
      }

      await _aiService.sendMessage(
        'Can you give me some health tips for my blood pressure?',
        context: context,
        messageContext: {
          'type': 'health_tips_request',
          'bpStatus': bpStatus,
        },
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting health tips: $e'),
            action: SnackBarAction(label: 'Retry', onPressed: _getHealthTips),
          ),
        );
      }
      debugPrint('Error getting health tips: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _analyzeBPTrend() async {
    if (_bpService.readings.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No BP readings available to analyze')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final readings = _bpService.readings.take(30).map((BPReadingModel reading) {
        return {
          'systolic': reading.systolic,
          'diastolic': reading.diastolic,
          'pulse': reading.pulse,
          'timestamp': reading.timestamp.toIso8601String(),
        };
      }).toList();

      await _aiService.sendMessage(
        'Can you analyze my blood pressure trend?',
        context: context,
        messageContext: {
          'type': 'bp_trend_analysis',
          'readings': readings,
        },
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing BP trend: $e'),
            action: SnackBarAction(label: 'Retry', onPressed: _analyzeBPTrend),
          ),
        );
      }
      debugPrint('Error analyzing BP trend: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserMessagesAndThreads() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _chatService.fetchThreads();
      if (widget.threadId != null) {
        await _chatService.fetchMessages(widget.threadId!);
        await _markThreadAsRead();
      }
      _isUserMessagesLoaded = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user messages: $e'),
            action: SnackBarAction(label: 'Retry', onPressed: _loadUserMessagesAndThreads),
          ),
        );
      }
      debugPrint('Error loading user messages: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _refreshUserMessages() async {
    if (_isLoading || widget.threadId == null) return;

    try {
      if (!_chatService.isLoading) {
        await _chatService.fetchMessages(widget.threadId!);
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing user messages: $e')),
        );
      }
      debugPrint('Error refreshing user messages: Firefoxfox');
    }
  }

  Future<void> _markThreadAsRead() async {
    if (widget.threadId == null) return;

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        return;
      }

      await _chatService.markThreadAsRead(widget.threadId!);
    } catch (e) {
      debugPrint('Error marking thread as read: $e');
    }
  }

  Future<void> _sendMessageToUser() async {
    if (widget.threadId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No thread selected')),
        );
      }
      return;
    }

    final message = _textController.text.trim();
    if (message.isEmpty) return;

    _textController.clear();
    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _chatService.sendMessage(
        widget.threadId!,
        message,
        context: context,
      );
      await _chatService.fetchMessages(widget.threadId!);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message to user: $e'),
            action: SnackBarAction(label: 'Retry', onPressed: _sendMessageToUser),
          ),
        );
      }
      debugPrint('Error sending message to user: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAttachment(String type) async {
    try {
      if (_isAITab) {
        switch (type) {
          case 'bp_reading':
            if (_bpService.readings.isNotEmpty) {
              final latestReading = _bpService.readings.first;
              await _aiService.sendMessage(
                'Here is my latest BP reading: ${latestReading.systolic}/${latestReading.diastolic}, Pulse: ${latestReading.pulse}',
                context: context,
                messageContext: {'type': 'bp_reading'},
              );
              _scrollToBottom();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No BP readings available')),
              );
            }
            break;
          case 'photo':
          case 'camera':
          case 'document':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Attachment type not yet implemented for AI chat')),
            );
            break;
        }
      } else {
        switch (type) {
          case 'photo':
          case 'camera':
          case 'document':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Attachment type not yet implemented for user chat')),
            );
            break;
          case 'bp_reading':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('BP readings not supported in user chats')),
            );
            break;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error handling attachment: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_isAITab) {
      await _sendMessageToAI();
    } else {
      await _sendMessageToUser();
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
    final aiService = context.watch<AIService>();
    final chatService = context.watch<ChatService>();
    final authService = context.watch<AuthService>();

    List<ChatMessage> messages = [];
    if (_isAITab) {
      messages = aiService.chatHistory;
    } else if (widget.threadId != null) {
      messages = chatService.getMessagesForThread(widget.threadId!);
    }

    final screenTitle = _isAITab ? 'Health Assistant' : (widget.userName ?? 'Chats');

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.health_and_safety), text: 'Health Assistant'),
            Tab(icon: Icon(Icons.chat), text: 'User Chats'),
          ],
        ),
        actions: _isAITab
            ? [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  aiService.clearChat();
                  _initChatbot();
                  break;
                case 'tips':
                  _getHealthTips();
                  break;
                case 'analyze':
                  _analyzeBPTrend();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'tips', child: Text('Get Health Tips')),
              const PopupMenuItem(value: 'analyze', child: Text('Analyze BP Trend')),
              const PopupMenuItem(value: 'clear', child: Text('Clear Chat')),
            ],
          ),
        ]
            : [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUserMessages,
            tooltip: 'Refresh Messages',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isAITab && (messages.isEmpty || messages.length <= 2))
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.health_and_safety, size: 16),
                    label: const Text('Health Tips'),
                    onPressed: _getHealthTips,
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.trending_up, size: 16),
                    label: const Text('Analyze BP'),
                    onPressed: _analyzeBPTrend,
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.medication, size: 16),
                    label: const Text('Medication Info'),
                    onPressed: () {
                      _textController.text = 'Tell me about blood pressure medications';
                      _sendMessageToAI();
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMessageList(
                  messages: aiService.chatHistory,
                  loading: _isLoading && aiService.chatHistory.isEmpty,
                  emptyMessage: 'Start a conversation with the health assistant',
                  isAIChat: true,
                ),
                widget.threadId == null
                    ? _buildThreadsList(chatService)
                    : _buildMessageList(
                  messages: chatService.getMessagesForThread(widget.threadId!),
                  loading: _isLoading && chatService.getMessagesForThread(widget.threadId!).isEmpty,
                  emptyMessage: 'No messages yet. Start a conversation!',
                  isAIChat: false,
                ),
              ],
            ),
          ),
          if (_isLoading && messages.isNotEmpty && !_isAITab)
            LinearProgressIndicator(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          if (_isAITab || widget.threadId != null)
            ChatInput(
              controller: _textController,
              onSend: _sendMessage,
              isLoading: _isLoading,
              isAIChat: _isAITab,
              onAttachmentSelected: _handleAttachment,
            ),
        ],
      ),
    );
  }

  Widget _buildThreadsList(ChatService chatService) {
    final threads = chatService.chatThreads;
    final currentUser = context.watch<AuthService>().currentUser;

    if (_isLoading && threads.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (threads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No chat threads yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start by requesting a medication or messaging a donor',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: threads.length,
      itemBuilder: (context, index) {
        final thread = threads[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                thread.type == 'medication' ? Icons.medication : Icons.person,
                color: Colors.white,
              ),
            ),
            title: Text(thread.participantName ?? 'Unknown User'),
            subtitle: thread.lastMessageContent.isNotEmpty
                ? Text(
              thread.lastMessageContent,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
                : const Text('No messages yet'),
            trailing: thread.unreadCount > 0
                ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              child: Text(
                thread.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
                : Text(
              thread.lastMessageTime != null ? _formatTime(thread.lastMessageTime!) : '',
              style: TextStyle(color: Colors.grey[600]),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CombinedChatScreen(
                    threadId: thread.id,
                    userId: thread.participantId,
                    userName: thread.participantName,
                    initialTabIndex: 1,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (time.year == now.year) {
      return '${time.day}/${time.month}';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  Widget _buildMessageList({
    required List<ChatMessage> messages,
    required bool loading,
    required String emptyMessage,
    required bool isAIChat,
  }) {
    final currentUser = context.watch<AuthService>().currentUser;

    if (loading && messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAIChat ? Icons.health_and_safety_outlined : Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a conversation by sending a message',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUser = isAIChat ? !message.isAI : message.senderId == currentUser?.id;
        return MessageBubble(
          message: message,
          isUser: isUser,
        );
      },
    );
  }
}