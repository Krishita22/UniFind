part of '../main.dart';

// ── DATA MODELS ───────────────────────────────────────────────────────────────

class Conversation {
  final int id;
  final String subject, otherName;
  final int otherId;
  final String? lastMessage;
  final DateTime? lastAt;
  final int unread;
  final int? listingId;
  const Conversation({
    required this.id, required this.subject,
    required this.otherName, required this.otherId,
    this.lastMessage, this.lastAt,
    required this.unread, this.listingId,
  });
  factory Conversation.fromMap(Map<String, dynamic> m, int myId) {
    final u1 = int.tryParse(m['user1_id'].toString()) ?? 0;
    final u2 = int.tryParse(m['user2_id'].toString()) ?? 0;
    final otherId   = u1 == myId ? u2 : u1;
    final otherName = u1 == myId
        ? (m['user2_name'] ?? m['user2_username'] ?? 'User').toString()
        : (m['user1_name'] ?? m['user1_username'] ?? 'User').toString();
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
  final int id, senderId;
  final String senderName, body;
  final DateTime sentAt;
  final bool isRead;
  const ChatMessage({
    required this.id, required this.senderId,
    required this.senderName, required this.body,
    required this.sentAt, required this.isRead,
  });
  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
    id:         int.tryParse(m['id'].toString()) ?? 0,
    senderId:   int.tryParse(m['sender_id'].toString()) ?? 0,
    senderName: m['sender_name']?.toString() ?? m['sender_username']?.toString() ?? 'User',
    body:       m['body']?.toString() ?? '',
    sentAt:     DateTime.tryParse(m['sent_at']?.toString() ?? '') ?? DateTime.now(),
    isRead:     m['is_read'] == 1 || m['is_read'] == true,
  );
}

// ── MESSAGING SCREEN (INBOX) ──────────────────────────────────────────────────

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
    _inboxTimer = Timer.periodic(const Duration(seconds: 3), (_) => _silentRefresh());
  }

  @override
  void dispose() { _inboxTimer?.cancel(); super.dispose(); }

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

  Future<void> _silentRefresh() async {
    if (!mounted) return;
    try {
      final raw = await getInbox(userId: widget.userId);
      if (!mounted) return;
      setState(() {
        _convs = raw.map((m) => Conversation.fromMap(m, widget.userId)).toList();
      });
    } catch (_) {}
  }

  String _timeStr(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours   < 24) return '${diff.inHours}h';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        backgroundColor: cNavBg,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: cRed,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: cRed))
            : _error != null
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Failed to load inbox', style: const TextStyle(color: cMuted)),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _load, child: const Text('Retry')),
                  ]))
                : _convs.isEmpty
                    ? const Center(child: Text('No conversations yet.', style: TextStyle(color: cMuted)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _convs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final c = _convs[i];
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              await Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => ConversationScreen(conv: c, myId: widget.userId),
                              ));
                              _silentRefresh();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: c.unread > 0 ? cRedLight : cSurface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: c.unread > 0 ? cRed.withValues(alpha: 0.3) : cBorder),
                              ),
                              child: Row(children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: cRedLight,
                                  child: Text(
                                    c.otherName.isNotEmpty ? c.otherName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: cRed, fontWeight: FontWeight.w800, fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(child: Text(c.otherName,
                                        style: TextStyle(
                                          fontSize: 14, fontWeight: c.unread > 0 ? FontWeight.w800 : FontWeight.w600,
                                          color: cText),
                                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    Text(_timeStr(c.lastAt),
                                        style: const TextStyle(fontSize: 11, color: cMuted)),
                                  ]),
                                  const SizedBox(height: 2),
                                  Text(c.subject,
                                      style: const TextStyle(fontSize: 11, color: cMuted),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  if (c.lastMessage != null) ...[
                                    const SizedBox(height: 2),
                                    Text(c.lastMessage!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: c.unread > 0 ? cText : cMuted,
                                          fontWeight: c.unread > 0 ? FontWeight.w600 : FontWeight.w400,
                                        ),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ])),
                                if (c.unread > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(color: cRed, borderRadius: BorderRadius.circular(10)),
                                    child: Text('${c.unread}',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ]),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

// ── CONVERSATION SCREEN ───────────────────────────────────────────────────────

class ConversationScreen extends StatefulWidget {
  final Conversation conv;
  final int myId;
  const ConversationScreen({super.key, required this.conv, required this.myId});
  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final List<ChatMessage> _msgs = [];
  final TextEditingController _ctrl   = TextEditingController();
  final ScrollController _scroll      = ScrollController();
  bool _loading    = true;
  bool _sending    = false;
  bool _completing = false;
  bool _isComplete = false;
  bool _otherOnline = false;
  String? _error;
  Timer? _refreshTimer;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _checkOnlineStatus();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) => _silentRefresh());
    _statusTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkOnlineStatus());
  }

  @override
  void dispose() { _refreshTimer?.cancel(); _statusTimer?.cancel(); _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  Future<void> _checkOnlineStatus() async {
    try {
      final online = await getUserOnlineStatus(userId: widget.conv.otherId);
      if (mounted && online != _otherOnline) setState(() => _otherOnline = online);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final raw = await getMessages(conversationId: widget.conv.id, userId: widget.myId);
      if (!mounted) return;
      setState(() { _msgs..clear()..addAll(raw.map(ChatMessage.fromMap)); _loading = false; });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _silentRefresh() async {
    if (!mounted || _sending) return;
    try {
      final raw = await getMessages(conversationId: widget.conv.id, userId: widget.myId);
      if (!mounted) return;
      final incoming = raw.map(ChatMessage.fromMap).toList();
      if (incoming.length != _msgs.length) {
        setState(() { _msgs..clear()..addAll(incoming); });
        _scrollToBottom();
      }
    } catch (_) {}
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
      await _silentRefresh();
    } catch (e) {
      if (!mounted) return;
      _ctrl.text = body;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _markComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as Complete'),
        content: Text('Confirm your interaction with ${widget.conv.otherName} is finished. Both of you can then rate each other.'),
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
      await markConversationComplete(conversationId: widget.conv.id, userId: widget.myId);
      if (!mounted) return;
      setState(() => _isComplete = true);
      await RatingDialog.show(context,
        targetName:     widget.conv.otherName,
        targetUserId:   widget.conv.otherId,
        conversationId: widget.conv.id,
        raterUserId:    widget.myId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Interaction marked complete. Thank you!'),
          behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cNavBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(widget.conv.otherName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _otherOnline ? const Color(0xFF27AE60) : Colors.white38,
              ),
            ),
            const SizedBox(width: 4),
            Text(_otherOnline ? 'Online' : 'Offline',
                style: TextStyle(fontSize: 10, color: _otherOnline ? const Color(0xFF27AE60) : Colors.white38, fontWeight: FontWeight.w600)),
          ]),
          Text(widget.conv.subject,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
        actions: [
          if (_completing)
            const Padding(padding: EdgeInsets.all(14),
                child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          else
            TextButton.icon(
              onPressed: _markComplete,
              icon: const Icon(Icons.check_circle_outline, color: Colors.white70, size: 18),
              label: const Text('Complete', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: cRed))
              : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('Failed to load', style: const TextStyle(color: cMuted)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ]))
                  : _msgs.isEmpty
                      ? const Center(child: Text('No messages yet. Say hello!',
                          style: TextStyle(color: cMuted)))
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                          itemCount: _msgs.length,
                          itemBuilder: (_, i) => _MsgBubble(
                              msg: _msgs[i], isMine: _msgs[i].senderId == widget.myId),
                        ),
        ),
        if (_isComplete)
          Container(
            color: const Color(0xFF27AE60).withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(top: false, child: Row(children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF27AE60), size: 18),
              const SizedBox(width: 8),
              const Expanded(child: Text('This conversation has been marked as complete.', style: TextStyle(fontSize: 12, color: Color(0xFF27AE60), fontWeight: FontWeight.w600))),
            ])),
          )
        else
        Container(
          color: cSurface,
          padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(top: false, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cBg, borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: cBorder),
                ),
                child: TextField(
                  controller: _ctrl,
                  maxLines: 5, minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
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

class _MsgBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMine;
  const _MsgBubble({required this.msg, required this.isMine});

  String _timeStr(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final a = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $a';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(msg.senderName,
                  style: const TextStyle(fontSize: 11, color: cMuted, fontWeight: FontWeight.w600)),
            ),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMine ? cRed : cSurface,
              borderRadius: BorderRadius.only(
                topLeft:     const Radius.circular(16),
                topRight:    const Radius.circular(16),
                bottomLeft:  Radius.circular(isMine ? 16 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 16),
              ),
              border: isMine ? null : Border.all(color: cBorder),
            ),
            child: Text(msg.body,
                style: TextStyle(
                  color: isMine ? Colors.white : cText,
                  fontSize: 14, height: 1.4,
                )),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: Text(_timeStr(msg.sentAt),
                style: const TextStyle(fontSize: 10, color: cMuted)),
          ),
        ],
      ),
    );
  }
}
