part of '../main.dart';

// ─── MODELS ──────────────────────────────────────────────────────────────────

class Conversation {
  final int id;
  final String subject;
  final String otherName;
  final int otherId;
  final String? lastMessage;
  final DateTime? lastAt;
  final int unread;
  final int? listingId;

  const Conversation({
    required this.id,
    required this.subject,
    required this.otherName,
    required this.otherId,
    this.lastMessage,
    this.lastAt,
    required this.unread,
    this.listingId,
  });

  factory Conversation.fromMap(Map<String, dynamic> m, int myId) {
    final u1 = int.tryParse(m['user1_id'].toString()) ?? 0;
    final u2 = int.tryParse(m['user2_id'].toString()) ?? 0;
    final otherId   = u1 == myId ? u2 : u1;
    final otherName = u1 == myId
        ? (m['user2_name'] ?? 'User').toString()
        : (m['user1_name'] ?? 'User').toString();
    return Conversation(
      id:          int.tryParse(m['id'].toString()) ?? 0,
      subject:     m['subject']?.toString() ?? '',
      otherName:   otherName,
      otherId:     otherId,
      lastMessage: m['last_msg']?.toString(),
      lastAt:      m['last_at'] != null ? DateTime.tryParse(m['last_at'].toString()) : null,
      unread:      int.tryParse(m['unread']?.toString() ?? '0') ?? 0,
      listingId:   m['listing_id'] != null ? int.tryParse(m['listing_id'].toString()) : null,
    );
  }
}

class ChatMessage {
  final int id;
  final int senderId;
  final String senderName;
  final String body;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.sentAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        id:         int.tryParse(m['id'].toString()) ?? 0,
        senderId:   int.tryParse(m['sender_id'].toString()) ?? 0,
        senderName: m['sender_name']?.toString() ?? 'User',
        body:       m['body']?.toString() ?? '',
        sentAt:     DateTime.tryParse(m['sent_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

// ─── INBOX SCREEN ─────────────────────────────────────────────────────────────

class MessagingScreen extends StatefulWidget {
  final int userId;
  final String userEmail;

  const MessagingScreen({super.key, required this.userId, required this.userEmail});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  List<Conversation> _convs = [];
  bool _loading = true;
  String? _error;
  Timer? _inboxTimer;

  @override
  void initState() {
    super.initState();
    _load();
    // Refresh inbox every 3 seconds so previews update when new messages arrive
    _inboxTimer = Timer.periodic(const Duration(seconds: 3), (_) => _silentInboxRefresh());
  }

  @override
  void dispose() {
    _inboxTimer?.cancel();
    super.dispose();
  }

  /// Refreshes inbox silently without showing the loading spinner.
  Future<void> _silentInboxRefresh() async {
    if (!mounted) return;
    try {
      final raw = await getInbox(userId: widget.userId);
      if (!mounted) return;
      setState(() {
        _convs = raw.map((m) => Conversation.fromMap(m, widget.userId)).toList();
      });
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await getInbox(userId: widget.userId);
      if (!mounted) return;
      setState(() {
        _convs = raw.map((m) => Conversation.fromMap(m, widget.userId)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _timeLabel(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours   < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays    < 1) return '${diff.inHours}h ago';
    if (diff.inDays    < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: RefreshIndicator(
        color: cRed,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: cRed))
            : _error != null
                ? ListView(children: [
                    const SizedBox(height: 80),
                    Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.wifi_off, size: 48, color: cMuted),
                      const SizedBox(height: 8),
                      const Text('Could not load messages', style: TextStyle(color: cMuted)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ])),
                  ])
                : _convs.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 80),
                        Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.chat_bubble_outline, size: 56, color: cMuted),
                          SizedBox(height: 12),
                          Text('No conversations yet',
                              style: TextStyle(color: cMuted, fontSize: 16, fontWeight: FontWeight.w600)),
                          SizedBox(height: 6),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Conversations start when you tap "Contact Seller" on a listing or "Claim Item" on a Lost & Found post.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: cMuted, fontSize: 13),
                            ),
                          ),
                        ])),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _convs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final c = _convs[i];
                          return _ConvTile(
                            conv: c,
                            timeLabel: _timeLabel(c.lastAt),
                            onTap: () async {
                              await Navigator.push(ctx, MaterialPageRoute(
                                builder: (_) => ConversationScreen(conv: c, myId: widget.userId),
                              ));
                              _load();
                            },
                          );
                        },
                      ),
      ),
    );
  }
}

// ─── INBOX TILE ───────────────────────────────────────────────────────────────

class _ConvTile extends StatelessWidget {
  final Conversation conv;
  final String timeLabel;
  final VoidCallback onTap;
  const _ConvTile({required this.conv, required this.timeLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUnread = conv.unread > 0;
    final initial   = conv.otherName.isNotEmpty ? conv.otherName[0].toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: cSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: hasUnread ? cRed : cBorder, width: hasUnread ? 1.8 : 1),
          boxShadow: [BoxShadow(color: cRed.withValues(alpha: hasUnread ? 0.07 : 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: hasUnread ? cRed : cPlaceholder,
            child: Text(initial, style: TextStyle(color: hasUnread ? Colors.white : cMuted, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(conv.otherName,
                style: TextStyle(fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600, fontSize: 15, color: cText),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (hasUnread)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: cRed, borderRadius: BorderRadius.circular(99)),
                  child: Text('${conv.unread}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(width: 6),
              Text(timeLabel, style: const TextStyle(color: cMuted, fontSize: 11)),
            ]),
            const SizedBox(height: 3),
            Text(conv.subject, style: const TextStyle(color: cMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (conv.lastMessage != null) ...[
              const SizedBox(height: 2),
              Text(conv.lastMessage!,
                style: TextStyle(color: hasUnread ? cText : cMuted, fontSize: 13, fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ])),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: cMuted, size: 20),
        ]),
      ),
    );
  }
}

// ─── CONVERSATION SCREEN ──────────────────────────────────────────────────────

class ConversationScreen extends StatefulWidget {
  final Conversation conv;
  final int myId;
  const ConversationScreen({super.key, required this.conv, required this.myId});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _ctrl   = TextEditingController();
  final ScrollController _scroll      = ScrollController();
  bool _loading     = true;
  bool _sending     = false;
  bool _completing  = false;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    // Poll for new messages every 4 seconds while the conversation is open
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) => _silentRefresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Silent refresh — polls for new messages without showing the loading spinner.
  /// Only scrolls to the bottom if new messages actually arrived.
  Future<void> _silentRefresh() async {
    if (!mounted || _sending) return;
    try {
      final raw = await getMessages(conversationId: widget.conv.id, userId: widget.myId);
      if (!mounted) return;
      final incoming = raw.map(ChatMessage.fromMap).toList();
      if (incoming.length != _messages.length) {
        setState(() {
          _messages..clear()..addAll(incoming);
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await getMessages(conversationId: widget.conv.id, userId: widget.myId);
      if (!mounted) return;
      setState(() {
        _messages..clear()..addAll(raw.map(ChatMessage.fromMap));
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final body = _ctrl.text.trim();
    if (body.isEmpty || _sending) return;
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      await sendMessage(conversationId: widget.conv.id, senderId: widget.myId, body: body);
      await _load();
    } catch (e) {
      if (!mounted) return;
      _ctrl.text = body;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Mark the interaction as complete, then prompt both users to rate each other.
  Future<void> _markComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as Complete'),
        content: Text(
          'Confirm that your interaction with ${widget.conv.otherName} is finished '
          '(item handed over / returned). Both of you will be prompted to rate each other.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: cRed, foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _completing = true);
    try {
      await markConversationComplete(
        conversationId: widget.conv.id,
        userId:         widget.myId,
      );
      if (!mounted) return;

      // Trigger rating dialog for this user
      await RatingDialog.show(
        context,
        targetName:     widget.conv.otherName,
        targetUserId:   widget.conv.otherId,
        conversationId: widget.conv.id,
        raterUserId:    widget.myId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Interaction marked complete. Thank you!'),
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.of(context).pop(); // return to inbox
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.conv.otherName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(widget.conv.subject, style: const TextStyle(fontSize: 11, color: Colors.white70),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
        actions: [
          if (_completing)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            )
          else
            TextButton.icon(
              onPressed: _markComplete,
              icon: const Icon(Icons.check_circle_outline, color: Colors.white70, size: 18),
              label: const Text('Complete', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(children: [
        // ── Thread ────────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: cRed))
              : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('Failed to load', style: const TextStyle(color: cMuted)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ]))
                  : _messages.isEmpty
                      ? const Center(child: Text('No messages yet. Say hello!', style: TextStyle(color: cMuted)))
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) => _MsgBubble(
                            msg: _messages[i],
                            isMine: _messages[i].senderId == widget.myId,
                          ),
                        ),
        ),
        // ── Compose ───────────────────────────────────────────────────────
        Container(
          color: cSurface,
          padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(top: false, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: cBorder),
                ),
                child: TextField(
                  controller: _ctrl,
                  maxLines: 5,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle: TextStyle(color: cMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
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
                  shape: BoxShape.circle,
                  color: _sending ? cMuted : cRed,
                ),
                child: _sending
                    ? const Padding(padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ])),
        ),
      ]),
    );
  }
}

// ─── MESSAGE BUBBLE ───────────────────────────────────────────────────────────

class _MsgBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMine;
  const _MsgBubble({required this.msg, required this.isMine});

  String _timeStr(DateTime dt) {
    final h    = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m    = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 3, left: 4, right: 4),
            child: Text(
              '${isMine ? 'You' : msg.senderName}  ·  ${_timeStr(msg.sentAt)}',
              style: const TextStyle(fontSize: 10, color: cMuted),
            ),
          ),
          Row(
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) ...[
                CircleAvatar(
                  radius: 14, backgroundColor: cPlaceholder,
                  child: Text(
                    msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
                    style: const TextStyle(color: cMuted, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine ? cRed : cSurface,
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(18),
                      topRight:    const Radius.circular(18),
                      bottomLeft:  Radius.circular(isMine ? 18 : 4),
                      bottomRight: Radius.circular(isMine ? 4  : 18),
                    ),
                    border: isMine ? null : Border.all(color: cBorder),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Text(msg.body,
                    style: TextStyle(color: isMine ? Colors.white : cText, fontSize: 14, height: 1.45)),
                ),
              ),
              if (isMine) const SizedBox(width: 6),
            ],
          ),
        ],
      ),
    );
  }
}
