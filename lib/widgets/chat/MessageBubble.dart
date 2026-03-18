import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import '../../model/ChatMessage.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isUser;
  final VoidCallback? onLongPress;
  final Function(String)? onSwipeReply;
  final Function(String, String)? onReact;
  final Function(String)? onPin;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isUser,
    this.onLongPress,
    this.onSwipeReply,
    this.onReact,
    this.onPin,
  }) : super(key: key);

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
    widget.onLongPress?.call();
  }

  bool _containsMarkdown(String content) {
    final markdownPatterns = [
      r'```[\s\S]*?```', // Code blocks
      r'#+ .+', // Headers
      r'\*[^\s].*?\*', // Bold/Italic
      r'\|.*?\|', // Tables
      r'- .+', // Unordered lists
      r'\d+\. .+', // Ordered lists
      r'\[.+?\]\(.+?\)', // Links
    ];
    return markdownPatterns.any((pattern) => RegExp(pattern).hasMatch(content));
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    if (now.difference(timestamp).inDays == 0) {
      return '$hour:$minute';
    }
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    return '$hour:$minute $day/$month';
  }

  Future<void> _launchUrl(BuildContext context, String? href) async {
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy'),
            onTap: () {
              Navigator.pop(context);
              _copyToClipboard(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.reply),
            title: const Text('Reply'),
            onTap: () {
              Navigator.pop(context);
              widget.onSwipeReply?.call(widget.message.content);
            },
          ),
          ListTile(
            leading: Icon(widget.message.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
            title: Text(widget.message.isPinned ? 'Unpin' : 'Pin'),
            onTap: () {
              Navigator.pop(context);
              widget.onPin?.call(widget.message.id);
            },
          ),
          if (widget.isUser) // Only allow delete for user messages
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                widget.onLongPress?.call();
              },
            ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              Navigator.pop(context);
              // Implement share functionality (e.g., using share_plus package)
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final colorScheme = Theme.of(context).colorScheme;
    final isAI = widget.message.isAI;
    final senderImage = widget.message.senderImage;

    return CircleAvatar(
      radius: 16,
      backgroundColor: isAI ? colorScheme.secondary : colorScheme.tertiary,
      child: senderImage != null
          ? ClipOval(
        child: senderImage.startsWith('http')
            ? Image.network(
          senderImage,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => isAI
              ? const Icon(Icons.health_and_safety, size: 20, color: Colors.white)
              : Text(
            widget.message.senderName.isNotEmpty
                ? widget.message.senderName[0].toUpperCase()
                : 'U',
            style: const TextStyle(color: Colors.white),
          ),
        )
            : Image.asset(
          senderImage,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => isAI
              ? const Icon(Icons.health_and_safety, size: 20, color: Colors.white)
              : Text(
            widget.message.senderName.isNotEmpty
                ? widget.message.senderName[0].toUpperCase()
                : 'U',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      )
          : isAI
          ? const Icon(Icons.health_and_safety, size: 20, color: Colors.white)
          : Text(
        widget.message.senderName.isNotEmpty
            ? widget.message.senderName[0].toUpperCase()
            : 'U',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final containsMarkdown = widget.message.isAI && _containsMarkdown(widget.message.content);

    final bubbleColor = widget.isUser
        ? colorScheme.primary
        : widget.message.isAI
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceVariant;

    final textColor = widget.isUser
        ? colorScheme.onPrimary
        : widget.message.isAI
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    final padding = EdgeInsets.only(
      left: widget.isUser ? screenWidth * 0.15 : 8,
      right: widget.isUser ? 8 : screenWidth * 0.15,
    );

    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Dismissible(
          key: Key(widget.message.id),
          background: Container(color: Colors.transparent),
          direction: DismissDirection.horizontal,
          onDismissed: (direction) {
            widget.onSwipeReply?.call(widget.message.content);
          },
          child: Row(
            mainAxisAlignment: widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar for AI messages
              if (!widget.isUser)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _buildAvatar(),
                ),

              // Message content
              Flexible(
                child: Padding(
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      // Sender name for AI messages
                      if (!widget.isUser && widget.message.isAI)
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
                          child: Text(
                            widget.message.senderName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),

                      // Message bubble
                      Semantics(
                        label: widget.isUser ? 'User message' : 'AI message',
                        child: MouseRegion(
                          onEnter: (_) => setState(() => _isHovered = true),
                          onExit: (_) => setState(() => _isHovered = false),
                          child: GestureDetector(
                            onLongPress: () => _showContextMenu(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: containsMarkdown
                                    ? MarkdownBody(
                                  data: widget.message.content,
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(color: textColor, fontSize: 16),
                                    h1: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
                                    h2: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                                    h3: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                    code: TextStyle(
                                      fontFamily: 'monospace',
                                      backgroundColor: Colors.black12,
                                      color: widget.isUser ? Colors.white : colorScheme.primary,
                                    ),
                                    codeblockDecoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    listBullet: TextStyle(color: colorScheme.secondary),
                                    a: TextStyle(color: colorScheme.primary, decoration: TextDecoration.underline),
                                  ),
                                  onTapLink: (text, href, title) => _launchUrl(context, href),
                                )
                                    : Text(
                                  widget.message.content,
                                  style: TextStyle(color: textColor, fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Timestamp and status
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTimestamp(widget.message.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (widget.isUser && widget.message.isRead) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.done_all,
                                size: 14,
                                color: Colors.blue,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Reactions for AI messages
                      if (_isHovered && widget.message.isAI)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.thumb_up_outlined,
                                  size: 16,
                                  color: widget.message.reactions.contains('thumbs_up')
                                      ? colorScheme.primary
                                      : Colors.grey,
                                ),
                                onPressed: () => widget.onReact?.call(widget.message.id, 'thumbs_up'),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.thumb_down_outlined,
                                  size: 16,
                                  color: widget.message.reactions.contains('thumbs_down')
                                      ? colorScheme.primary
                                      : Colors.grey,
                                ),
                                onPressed: () => widget.onReact?.call(widget.message.id, 'thumbs_down'),
                              ),
                            ],
                          ),
                        ),

                      // Pinned indicator
                      if (widget.message.isPinned)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Icon(
                            Icons.push_pin,
                            size: 16,
                            color: colorScheme.secondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // User avatar
              if (widget.isUser && widget.message.senderImage != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: _buildAvatar(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}