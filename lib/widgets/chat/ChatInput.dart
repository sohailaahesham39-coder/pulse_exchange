import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:io';
import '../../config/AppConstants.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;
  final Function(bool)? onTyping;
  final bool isAIChat;
  final Function(String)? onAttachmentSelected;

  const ChatInput({
    Key? key,
    required this.controller,
    required this.onSend,
    this.isLoading = false,
    this.onTyping,
    this.isAIChat = false,
    this.onAttachmentSelected,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _showSendButton = false;
  bool _showVoiceButton = true;
  final FocusNode _focusNode = FocusNode();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isRecording = false;
  bool _speechInitialized = false;

  final List<String> _aiQuickResponses = [
    'How can I lower my blood pressure?',
    'What medications help with hypertension?',
    'Explain my latest readings',
    'What foods should I avoid?',
    'Recommend exercises for heart health',
  ];

  final List<String> _userQuickResponses = [
    'Hello, how are you?',
    'Thank you!',
    'Can you help me with something?',
    'I\'ll get back to you later',
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateSendButtonVisibility);
    _focusNode.addListener(_handleFocusChange);
    _initializeSpeech();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateSendButtonVisibility);
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    try {
      _speechInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          setState(() => _isRecording = false);
        },
      );
    } catch (e) {
      debugPrint('Speech initialization failed: $e');
    }
    setState(() {});
  }

  void _updateSendButtonVisibility() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    setState(() {
      _showSendButton = hasText;
      _showVoiceButton = !hasText;
    });
    widget.onTyping?.call(hasText);
  }

  void _handleFocusChange() {
    setState(() {}); // Rebuild to show/hide quick responses
  }

  void _handleSend() {
    if (!widget.isLoading && widget.controller.text.trim().isNotEmpty) {
      widget.onSend();
    }
  }

  void _insertQuickResponse(String response) {
    widget.controller.text = response;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.controller.text.length),
    );
    _focusNode.requestFocus();
    _updateSendButtonVisibility();
  }

  void _toggleVoiceRecording() async {
    if (!_speechInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      await _speech.listen(
        onResult: (result) {
          widget.controller.text = result.recognizedWords;
          _updateSendButtonVisibility();
          if (result.finalResult) {
            setState(() => _isRecording = false);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
      );
    } else {
      await _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final responses = widget.isAIChat ? _aiQuickResponses : _userQuickResponses;

    return Column(
      children: [
        // Quick responses carousel (shown when input is empty)
        if (widget.controller.text.isEmpty)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: responses.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ActionChip(
                  label: Text(responses[index], style: const TextStyle(fontSize: 12)),
                  onPressed: () => _insertQuickResponse(responses[index]),
                ),
              ),
            ),
          ),

        // Input area
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, -2),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.1),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Attachment button
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: widget.isLoading ? null : () => _showAttachmentOptions(context),
                ),

                // Text input field
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).inputDecorationTheme.fillColor ??
                          Theme.of(context).colorScheme.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      isCollapsed: true,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 5,
                    enabled: !widget.isLoading,
                    onSubmitted: (_) => _handleSend(),
                  ),
                ),

                // Send or voice button
                IconButton(
                  icon: widget.isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : _showSendButton
                      ? const Icon(Icons.send)
                      : Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: _isRecording ? Colors.red : null,
                  ),
                  onPressed: widget.isLoading
                      ? null
                      : _showSendButton
                      ? _handleSend
                      : _toggleVoiceRecording,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.photo, color: Colors.white),
            ),
            title: const Text('Photo'),
            onTap: () {
              Navigator.pop(context);
              widget.onAttachmentSelected?.call('photo');
            },
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.camera_alt, color: Colors.white),
            ),
            title: const Text('Camera'),
            onTap: () {
              Navigator.pop(context);
              widget.onAttachmentSelected?.call('camera');
            },
          ),
          if (widget.isAIChat)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.favorite, color: Colors.white),
              ),
              title: const Text('BP Reading'),
              onTap: () {
                Navigator.pop(context);
                widget.onAttachmentSelected?.call('bp_reading');
              },
            ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.insert_drive_file, color: Colors.white),
            ),
            title: const Text('Document'),
            onTap: () {
              Navigator.pop(context);
              widget.onAttachmentSelected?.call('document');
            },
          ),
        ],
      ),
    );
  }
}