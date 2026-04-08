part of '../main.dart';

// ─── DATA MODELS ─────────────────────────────────────────────────────────────

class Conversation {
  final String id;
  final String otherUserEmail;
  final String otherUsername;
  final String listingTitle;
  final String listingType; // 'marketplace' | 'lostfound'
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  const Conversation({
    required this.id,
    required this.otherUserEmail,
    required this.otherUsername,
    required this.listingTitle,
    required this.listingType,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });
}

class ChatMessage {
  final String id;
  final String senderEmail;
  final String content;
  final DateTime sentAt;
  const ChatMessage({
    required this.id,
    required this.senderEmail,
    required this.content,
    required this.sentAt,
  });
}

// ─── MESSAGES SCREEN (conversation list) ─────────────────────────────────────

class MessagesScreen extends StatefulWidget {
  final String currentUserEmail;
  final String currentUsername;
  const MessagesScreen({
    super.key,
    required this.currentUserEmail,
    required this.currentUsername,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Conversation> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await getConversations(widget.currentUserEmail);
      final parsed = raw.map((c) {
        final other = (c['other_user_email'] ?? c['otherUserEmail'] ?? '').toString();
        final otherName = (c['other_username'] ?? c['otherUsername'] ?? other.split('@').first).toString();
        return Conversation(
          id: (c['id'] ?? c['conversation_id'] ?? '').toString(),
          otherUserEmail: other,
          otherUsername: otherName.isEmpty ? other.split('@').first : otherName,
          listingTitle: (c['listing_title'] ?? c['listingTitle'] ?? 'Listing').toString(),
          listingType: (c['listing_type'] ?? c['listingType'] ?? 'marketplace').toString(),
          lastMessage: (c['last_message'] ?? c['lastMessage'] ?? '').toString(),
          lastMessageAt: DateTime.tryParse((c['last_message_at'] ?? c['lastMessageAt'] ?? '').toString()) ?? DateTime.now(),
          unreadCount: int.tryParse((c['unread_count'] ?? c['unreadCount'] ?? '0').toString()) ?? 0,
        );
      }).toList();
      parsed.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      if (mounted) setState(() { _conversations = parsed; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Messages', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.5)),
                    Text('Your conversations with other students', style: TextStyle(fontSize: 13, color: cMuted)),
                  ],
                ),
              ),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, color: cMuted, size: 20),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: cBorder),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: cRed, strokeWidth: 2))
              : _error != null
                  ? _ConvErrorState(onRetry: _load)
                  : _conversations.isEmpty
                      ? const _EmptyConversationsState()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: cRed,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _conversations.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, indent: 70, endIndent: 16, color: cBorder),
                            itemBuilder: (_, i) => _ConversationTile(
                              conversation: _conversations[i],
                              currentUserEmail: widget.currentUserEmail,
                              currentUsername: widget.currentUsername,
                              onRead: _load,
                            ),
                          ),
                        ),
        ),
      ],
    );
  }
}

class _EmptyConversationsState extends StatelessWidget {
  const _EmptyConversationsState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(color: cRedLight, shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline_rounded, color: cRed, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('No conversations yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cText)),
          const SizedBox(height: 6),
          const Text('Browse listings and tap "Chat with Seller"\nto start a conversation.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: cMuted, height: 1.6)),
        ],
      ),
    );
  }
}

class _ConvErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ConvErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: cMuted),
          const SizedBox(height: 12),
          const Text('Could not load messages', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cText)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: cRed),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String currentUserEmail;
  final String currentUsername;
  final VoidCallback onRead;
  const _ConversationTile({
    required this.conversation,
    required this.currentUserEmail,
    required this.currentUsername,
    required this.onRead,
  });

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;
    final initials = conversation.otherUsername.isNotEmpty
        ? conversation.otherUsername[0].toUpperCase()
        : '?';
    final isMarket = conversation.listingType == 'marketplace';

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: kPage,
            pageBuilder: (_, a, __) => FadeTransition(
              opacity: a,
              child: _ChatScreen(
                conversationId: conversation.id,
                otherUserEmail: conversation.otherUserEmail,
                otherUsername: conversation.otherUsername,
                listingTitle: conversation.listingTitle,
                listingType: conversation.listingType,
                currentUserEmail: currentUserEmail,
                currentUsername: currentUsername,
              ),
            ),
          ),
        );
        onRead();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(initials, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
                if (hasUnread)
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: cRed, shape: BoxShape.circle,
                        border: Border.all(color: cSurface, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          conversation.unreadCount > 9 ? '9+' : '${conversation.unreadCount}',
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.otherUsername,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                            color: cText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _timeLabel(conversation.lastMessageAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: hasUnread ? cRed : cMuted,
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isMarket ? cRedLight : const Color(0xFFECF9F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isMarket ? 'Market' : 'L&F',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: isMarket ? cRed : const Color(0xFF27AE60),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          conversation.listingTitle,
                          style: const TextStyle(fontSize: 11, color: cMuted, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conversation.lastMessage.isEmpty ? 'Start the conversation...' : conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasUnread ? cText : cMuted,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CHAT SCREEN ─────────────────────────────────────────────────────────────

class _ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserEmail;
  final String otherUsername;
  final String listingTitle;
  final String listingType;
  final String currentUserEmail;
  final String currentUsername;

  const _ChatScreen({
    required this.conversationId,
    required this.otherUserEmail,
    required this.otherUsername,
    required this.listingTitle,
    required this.listingType,
    required this.currentUserEmail,
    required this.currentUsername,
  });

  @override
  State<_ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<_ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markRead();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final raw = await getMessages(widget.conversationId);
      final parsed = raw.map((m) => ChatMessage(
        id: (m['id'] ?? '').toString(),
        senderEmail: (m['sender_email'] ?? m['senderEmail'] ?? '').toString(),
        content: (m['content'] ?? m['message'] ?? '').toString(),
        sentAt: DateTime.tryParse((m['sent_at'] ?? m['sentAt'] ?? m['created_at'] ?? '').toString()) ?? DateTime.now(),
      )).toList();
      parsed.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      if (mounted) {
        setState(() { _messages = parsed; _loading = false; });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead() async {
    try {
      await markConversationRead(widget.conversationId, widget.currentUserEmail);
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: kMid,
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _msgCtrl.clear();
    setState(() => _sending = true);
    try {
      await sendChatMessage(
        conversationId: widget.conversationId,
        senderEmail: widget.currentUserEmail,
        content: text,
      );
      await _loadMessages();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    }
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  bool _isMine(ChatMessage msg) =>
      msg.senderEmail.trim().toLowerCase() == widget.currentUserEmail.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final isMarket = widget.listingType == 'marketplace';
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cNavBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUsername, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isMarket ? 'Market' : 'L&F',
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    widget.listingTitle,
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: cRed, strokeWidth: 2))
                : _messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: cMuted),
                            SizedBox(height: 10),
                            Text('No messages yet', style: TextStyle(fontSize: 14, color: cMuted)),
                            SizedBox(height: 4),
                            Text('Say hello to get started!', style: TextStyle(fontSize: 12, color: cMuted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          final mine = _isMine(msg);
                          final showDate = i == 0 ||
                              _messages[i].sentAt.day != _messages[i - 1].sentAt.day ||
                              _messages[i].sentAt.month != _messages[i - 1].sentAt.month;
                          return Column(
                            children: [
                              if (showDate)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(color: cBorder, borderRadius: BorderRadius.circular(20)),
                                      child: Text(
                                        _timeLabel(msg.sentAt),
                                        style: const TextStyle(fontSize: 11, color: cMuted, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ),
                              _MessageBubble(message: msg, isMine: mine),
                            ],
                          );
                        },
                      ),
          ),
          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 12),
            decoration: BoxDecoration(
              color: cSurface,
              border: Border(top: BorderSide(color: cBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: cMuted, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: cBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: cBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: cRed, width: 1.5),
                      ),
                      filled: true,
                      fillColor: cBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: AnimatedContainer(
                    duration: kFast,
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: _sending
                        ? const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  const _MessageBubble({required this.message, required this.isMine});

  String _timeStr(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMine
              ? const LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isMine ? null : cSurface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          border: isMine ? null : Border.all(color: cBorder),
          boxShadow: [
            BoxShadow(
              color: isMine ? cRed.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: isMine ? Colors.white : cText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _timeStr(message.sentAt),
              style: TextStyle(
                fontSize: 10,
                color: isMine ? Colors.white.withValues(alpha: 0.65) : cMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── OPEN CHAT HELPER (used from marketplace & lost&found) ───────────────────

Future<void> openOrStartChat({
  required BuildContext context,
  required String currentUserEmail,
  required String currentUsername,
  required String sellerEmail,
  required String sellerUsername,
  required String listingId,
  required String listingTitle,
  required String listingType, // 'marketplace' | 'lostfound'
}) async {
  // Don't open chat with yourself
  if (currentUserEmail.trim().toLowerCase() == sellerEmail.trim().toLowerCase()) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.info_outline_rounded, color: Colors.white, size: 17),
          SizedBox(width: 10),
          Text('You cannot chat with yourself'),
        ]),
        backgroundColor: cRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
    return;
  }

  String? convId;
  String? error;

  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator(color: cRed)),
  );

  try {
    final result = await startOrGetConversation(
      senderEmail: currentUserEmail,
      receiverEmail: sellerEmail,
      listingId: listingId,
      listingType: listingType,
      listingTitle: listingTitle,
    );
    convId = (result['conversation_id'] ?? result['id'] ?? '').toString();
  } catch (e) {
    error = e.toString();
  }

  if (!context.mounted) return;
  Navigator.of(context).pop(); // dismiss loading

  if (error != null || convId == null || convId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 17),
          const SizedBox(width: 10),
          Expanded(child: Text('Could not open chat: ${error ?? 'Unknown error'}')),
        ]),
        backgroundColor: cRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
    return;
  }

  await Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: kPage,
      pageBuilder: (_, a, __) => FadeTransition(
        opacity: a,
        child: _ChatScreen(
          conversationId: convId!,
          otherUserEmail: sellerEmail,
          otherUsername: sellerUsername,
          listingTitle: listingTitle,
          listingType: listingType,
          currentUserEmail: currentUserEmail,
          currentUsername: currentUsername,
        ),
      ),
    ),
  );
}

// ─── RATING WIDGET (read-only stars) ─────────────────────────────────────────

class UserRatingBadge extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final bool compact;
  const UserRatingBadge({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (reviewCount == 0) {
      return Text(
        'No reviews yet',
        style: TextStyle(fontSize: compact ? 11 : 12, color: cMuted, fontStyle: FontStyle.italic),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final filled = i < rating.floor();
          final half = !filled && i < rating;
          return Icon(
            half ? Icons.star_half_rounded : filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: compact ? 12 : 15,
            color: const Color(0xFFF4B400),
          );
        }),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(fontSize: compact ? 11 : 13, fontWeight: FontWeight.w700, color: cText),
        ),
        const SizedBox(width: 3),
        Text(
          '($reviewCount)',
          style: TextStyle(fontSize: compact ? 10 : 11, color: cMuted),
        ),
      ],
    );
  }
}

// ─── REVIEWS DIALOG ──────────────────────────────────────────────────────────

Future<void> showUserReviewsDialog({
  required BuildContext context,
  required String userEmail,
  required String username,
}) async {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Reviews',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: kMid,
    pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, __, ___) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return Opacity(
        opacity: curved.value,
        child: Transform.scale(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved).value,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 620),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                decoration: BoxDecoration(
                  color: cSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 40, offset: const Offset(0, 12))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Material(
                  color: Colors.transparent,
                  child: _ReviewsDialogContent(userEmail: userEmail, username: username),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ReviewsDialogContent extends StatefulWidget {
  final String userEmail;
  final String username;
  const _ReviewsDialogContent({required this.userEmail, required this.username});

  @override
  State<_ReviewsDialogContent> createState() => _ReviewsDialogContentState();
}

class _ReviewsDialogContentState extends State<_ReviewsDialogContent> {
  bool _loading = true;
  double _avgRating = 0;
  int _reviewCount = 0;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await getUserReviews(widget.userEmail);
      if (!mounted) return;
      double sum = 0;
      for (final r in data) {
        sum += double.tryParse((r['stars'] ?? r['rating'] ?? '0').toString()) ?? 0;
      }
      setState(() {
        _reviews = data;
        _reviewCount = data.length;
        _avgRating = data.isEmpty ? 0 : sum / data.length;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [cNavBg, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    widget.username.isNotEmpty ? widget.username[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('@${widget.username}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                    if (!_loading && _reviewCount > 0)
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            final filled = i < _avgRating.floor();
                            final half = !filled && i < _avgRating;
                            return Icon(
                              half ? Icons.star_half_rounded : filled ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 14,
                              color: const Color(0xFFF4B400),
                            );
                          }),
                          const SizedBox(width: 5),
                          Text(
                            '${_avgRating.toStringAsFixed(1)} · $_reviewCount review${_reviewCount == 1 ? '' : 's'}',
                            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                          ),
                        ],
                      )
                    else if (!_loading)
                      Text('No reviews yet', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7), fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // Body
        Flexible(
          child: _loading
              ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: cRed, strokeWidth: 2)))
              : _reviews.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star_outline_rounded, size: 48, color: cMuted),
                          SizedBox(height: 12),
                          Text('No reviews yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cText)),
                          SizedBox(height: 6),
                          Text('This user hasn\'t received any reviews.', style: TextStyle(fontSize: 13, color: cMuted)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: _reviews.length,
                      separatorBuilder: (_, __) => const Divider(height: 20, color: cBorder),
                      itemBuilder: (_, i) {
                        final r = _reviews[i];
                        final stars = int.tryParse((r['stars'] ?? r['rating'] ?? '0').toString()) ?? 0;
                        final text = (r['review'] ?? r['comment'] ?? r['text'] ?? '').toString();
                        final rater = (r['rater_username'] ?? r['raterUsername'] ?? r['rater_email'] ?? 'Anonymous').toString();
                        final dateRaw = (r['created_at'] ?? r['createdAt'] ?? '').toString();
                        final date = DateTime.tryParse(dateRaw);
                        return _ReviewTile(stars: stars, text: text, rater: rater, date: date);
                      },
                    ),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final int stars;
  final String text;
  final String rater;
  final DateTime? date;
  const _ReviewTile({required this.stars, required this.text, required this.rater, this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Stars
            Row(
              children: List.generate(5, (i) => Icon(
                i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 16,
                color: const Color(0xFFF4B400),
              )),
            ),
            const Spacer(),
            if (date != null)
              Text(
                '${date!.month}/${date!.day}/${date!.year}',
                style: const TextStyle(fontSize: 11, color: cMuted),
              ),
          ],
        ),
        if (text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 13, color: cText, height: 1.55)),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.person_outline_rounded, size: 12, color: cMuted),
            const SizedBox(width: 4),
            Text(rater.contains('@') ? rater.split('@').first : rater,
                style: const TextStyle(fontSize: 11, color: cMuted, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

// ─── INLINE RATING SUMMARY (used inside item popups) ─────────────────────────

class _PosterRatingSection extends StatefulWidget {
  final String userEmail;
  final String username;
  const _PosterRatingSection({required this.userEmail, required this.username});

  @override
  State<_PosterRatingSection> createState() => _PosterRatingSectionState();
}

class _PosterRatingSectionState extends State<_PosterRatingSection> {
  bool _loading = true;
  double _avg = 0;
  int _count = 0;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await getUserReviews(widget.userEmail);
      if (!mounted) return;
      double sum = 0;
      for (final r in data) {
        sum += double.tryParse((r['stars'] ?? r['rating'] ?? '0').toString()) ?? 0;
      }
      setState(() {
        _reviews = data;
        _count = data.length;
        _avg = data.isEmpty ? 0 : sum / data.length;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: cRed)),
          SizedBox(width: 8),
          Text('Loading reviews...', style: TextStyle(fontSize: 12, color: cMuted)),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: cBorder),
        const SizedBox(height: 14),
        Row(
          children: [
            const Text('Seller Reviews', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cText)),
            const Spacer(),
            if (_count > 0)
              GestureDetector(
                onTap: () => showUserReviewsDialog(
                  context: context,
                  userEmail: widget.userEmail,
                  username: widget.username,
                ),
                child: const Row(
                  children: [
                    Text('View all', style: TextStyle(fontSize: 12, color: cRed, fontWeight: FontWeight.w700)),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded, size: 16, color: cRed),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_count == 0)
          const Text('No reviews yet for this user.', style: TextStyle(fontSize: 12, color: cMuted, fontStyle: FontStyle.italic))
        else ...[
          // Average stars row
          Row(
            children: [
              ...List.generate(5, (i) {
                final filled = i < _avg.floor();
                final half = !filled && i < _avg;
                return Icon(
                  half ? Icons.star_half_rounded : filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 18,
                  color: const Color(0xFFF4B400),
                );
              }),
              const SizedBox(width: 6),
              Text(_avg.toStringAsFixed(1), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cText)),
              const SizedBox(width: 4),
              Text('($_count review${_count == 1 ? '' : 's'})', style: const TextStyle(fontSize: 12, color: cMuted)),
            ],
          ),
          const SizedBox(height: 10),
          // Show up to 2 preview reviews
          ..._reviews.take(2).map((r) {
            final stars = int.tryParse((r['stars'] ?? r['rating'] ?? '0').toString()) ?? 0;
            final text = (r['review'] ?? r['comment'] ?? r['text'] ?? '').toString();
            final rater = (r['rater_username'] ?? r['raterUsername'] ?? r['rater_email'] ?? 'Anonymous').toString();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: cBorder)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Row(children: List.generate(5, (i) => Icon(
                        i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 13, color: const Color(0xFFF4B400),
                      ))),
                      const SizedBox(width: 6),
                      Text(rater.contains('@') ? rater.split('@').first : rater,
                          style: const TextStyle(fontSize: 11, color: cMuted, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(text, style: const TextStyle(fontSize: 12, color: cMuted, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            );
          }),
          if (_count > 2)
            GestureDetector(
              onTap: () => showUserReviewsDialog(
                context: context,
                userEmail: widget.userEmail,
                username: widget.username,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'View all $_count reviews →',
                  style: const TextStyle(fontSize: 12, color: cRed, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
