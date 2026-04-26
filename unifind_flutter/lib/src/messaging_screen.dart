part of '../main.dart';

// ── DATA MODELS ───────────────────────────────────────────────────────────────
class Conversation {
  final int id;
  final String subject, otherName, otherEmail, otherFirstName;
  final int otherId;
  final String? lastMessage;
  final DateTime? lastAt;
  final int unread;
  final int? listingId;
  final bool isComplete;
  const Conversation({
    required this.id, required this.subject,
    required this.otherName, required this.otherEmail,
    required this.otherFirstName,
    required this.otherId,
    this.lastMessage, this.lastAt,
    required this.unread, this.listingId,
    this.isComplete = false,
  });
  factory Conversation.fromMap(Map<String, dynamic> m, int myId) {
    final u1 = int.tryParse(m['user1_id'].toString()) ?? 0;
    final u2 = int.tryParse(m['user2_id'].toString()) ?? 0;
    final otherId      = u1 == myId ? u2 : u1;
    final otherName    = u1 == myId
        ? (m['user2_name'] ?? m['user2_username'] ?? 'User').toString()
        : (m['user1_name'] ?? m['user1_username'] ?? 'User').toString();
    final otherEmail   = u1 == myId
        ? (m['user2_email'] ?? '').toString()
        : (m['user1_email'] ?? '').toString();
    final otherFirstName = u1 == myId
        ? (m['user2_first_name'] ?? '').toString()
        : (m['user1_first_name'] ?? '').toString();
    return Conversation(
      id:            int.tryParse(m['id'].toString()) ?? 0,
      subject:       m['subject']?.toString() ?? '',
      otherName:     otherName,
      otherEmail:    otherEmail,
      otherFirstName: otherFirstName,
      otherId:       otherId,
      lastMessage:   m['last_msg']?.toString(),
      lastAt:        m['last_at'] != null ? DateTime.tryParse(m['last_at'].toString()) : null,
      unread:        int.tryParse(m['unread']?.toString() ?? '0') ?? 0,
      listingId:     m['listing_id'] != null ? int.tryParse(m['listing_id'].toString()) : null,
      isComplete:    m['is_complete'] == 1 || m['is_complete'] == true || m['is_complete'] == '1',
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

  bool get isMeetupMessage => body.startsWith('__meetup__');

  Map<String, dynamic>? get meetupPayload {
    if (!isMeetupMessage) return null;
    try {
      return jsonDecode(body.substring('__meetup__'.length)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  MeetupProposal? toMeetupProposal({required int myId}) {
    final p = meetupPayload;
    if (p == null) return null;
    try {
      final timeParts = (p['time']?.toString() ?? '12:00:00').split(':');
      final proposerId = int.tryParse(p['proposer_id'].toString()) ?? senderId;
      final proposerName = proposerId == myId ? 'You' : senderName;
      return MeetupProposal(
        id:     p['meetup_id'] != null ? (p['meetup_id'] as num).toInt() : null,
        conversationId: 0,
        proposerId:     proposerId,
        proposerName:   proposerName,
        meetDate:       DateTime.tryParse(p['date']?.toString() ?? '') ?? DateTime.now(),
        meetTime: TimeOfDay(
          hour:   int.tryParse(timeParts[0]) ?? 12,
          minute: int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0,
        ),
        safeSpot: p['location']?.toString() ?? 'Student Center',
        note:     p['note']?.toString(),
        status:   MeetupStatus.userPending,
        claimId:  p['claim_id'] != null ? (p['claim_id'] as num).toInt() : null,
      );
    } catch (_) {
      return null;
    }
  }
}

// ── MEETUP MODELS ─────────────────────────────────────────────────────────────

// FIX 1: Added missing `completionPending` to enum
enum MeetupStatus {
  userPending,
  adminPending,
  confirmed,
  userDenied,
  adminDenied,
  userCancelled,
  completed,
  completionPending,
}

class MeetupProposal {
  final int? id;
  final int conversationId;
  final int proposerId;
  final String proposerName;
  final DateTime meetDate;
  final TimeOfDay meetTime;
  final String safeSpot;
  final String? note;
  final MeetupStatus status;
  final String? denialReason;
  final int? claimId;

  const MeetupProposal({
    this.id,
    required this.conversationId,
    required this.proposerId,
    required this.proposerName,
    required this.meetDate,
    required this.meetTime,
    required this.safeSpot,
    this.note,
    this.status = MeetupStatus.userPending,
    this.denialReason,
    this.claimId,
  });

  factory MeetupProposal.fromMap(Map<String, dynamic> m) {
    MeetupStatus parseStatus(String s) {
      switch (s.toLowerCase()) {
        case 'user_pending':        return MeetupStatus.userPending;
        case 'admin_pending':       return MeetupStatus.adminPending;
        case 'confirmed':           return MeetupStatus.confirmed;
        case 'user_denied':         return MeetupStatus.userDenied;
        case 'admin_denied':        return MeetupStatus.adminDenied;
        case 'user_cancelled':      return MeetupStatus.userCancelled;
        case 'completed':           return MeetupStatus.completed;
        case 'completion_pending':  return MeetupStatus.completionPending;
        default:                    return MeetupStatus.userPending;
      }
    }
    final timeParts = (m['meet_time']?.toString() ?? '12:00').split(':');
    return MeetupProposal(
      id:             int.tryParse(m['id'].toString()),
      conversationId: int.tryParse(m['conversation_id'].toString()) ?? 0,
      proposerId:     int.tryParse(m['proposer_id'].toString()) ?? 0,
      proposerName:   m['proposer_name']?.toString() ?? 'User',
      meetDate:       DateTime.tryParse(m['meet_date'].toString()) ?? DateTime.now(),
      meetTime:       TimeOfDay(
                        hour:   int.tryParse(timeParts[0]) ?? 12,
                        minute: int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0,
                      ),
      safeSpot:       m['safe_spot']?.toString() ?? 'Student Center',
      note:           m['note']?.toString(),
      status:         parseStatus(m['status']?.toString() ?? ''),
      denialReason:   m['denial_reason']?.toString(),
      claimId:        int.tryParse(m['claim_id']?.toString() ?? ''),
    );
  }

  MeetupProposal copyWith({MeetupStatus? status, String? denialReason}) => MeetupProposal(
    id:             id,
    conversationId: conversationId,
    proposerId:     proposerId,
    proposerName:   proposerName,
    meetDate:       meetDate,
    meetTime:       meetTime,
    safeSpot:       safeSpot,
    note:           note,
    status:         status ?? this.status,
    denialReason:   denialReason ?? this.denialReason,
    claimId:        claimId,
  );

  String get formattedDate {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final wd = days[(meetDate.weekday - 1) % 7];
    return '$wd, ${months[meetDate.month - 1]} ${meetDate.day}';
  }

  String get formattedTime {
    final h  = meetTime.hour % 12 == 0 ? 12 : meetTime.hour % 12;
    final m  = meetTime.minute.toString().padLeft(2, '0');
    final ap = meetTime.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }
}

// ── SAFE SPOTS ────────────────────────────────────────────────────────────────

class SafeSpotInfo {
  final String name;
  final String hours;
  final Map<int, DayHours> weeklyHours;
  const SafeSpotInfo({required this.name, required this.hours, required this.weeklyHours});
}

class DayHours {
  final int openHour;
  final int closeHour;
  const DayHours({required this.openHour, required this.closeHour});
}

const List<SafeSpotInfo> kSafeSpotInfos = [
  SafeSpotInfo(
    name: 'The Quad', hours: 'Open daily 7 AM–7 PM',
    weeklyHours: {
      1: DayHours(openHour: 7, closeHour: 19), 2: DayHours(openHour: 7, closeHour: 19),
      3: DayHours(openHour: 7, closeHour: 19), 4: DayHours(openHour: 7, closeHour: 19),
      5: DayHours(openHour: 7, closeHour: 19), 6: DayHours(openHour: 7, closeHour: 19),
      7: DayHours(openHour: 7, closeHour: 19),
    },
  ),
  SafeSpotInfo(
    name: 'Student Center', hours: 'Open daily 7 AM–10 PM',
    weeklyHours: {
      1: DayHours(openHour: 7, closeHour: 22), 2: DayHours(openHour: 7, closeHour: 22),
      3: DayHours(openHour: 7, closeHour: 22), 4: DayHours(openHour: 7, closeHour: 22),
      5: DayHours(openHour: 7, closeHour: 22), 6: DayHours(openHour: 7, closeHour: 22),
      7: DayHours(openHour: 7, closeHour: 22),
    },
  ),
  SafeSpotInfo(
    name: 'Susan A. Cole Hall', hours: 'Open daily 8 AM–8 PM',
    weeklyHours: {
      1: DayHours(openHour: 8, closeHour: 20), 2: DayHours(openHour: 8, closeHour: 20),
      3: DayHours(openHour: 8, closeHour: 20), 4: DayHours(openHour: 8, closeHour: 20),
      5: DayHours(openHour: 8, closeHour: 20), 6: DayHours(openHour: 8, closeHour: 20),
      7: DayHours(openHour: 8, closeHour: 20),
    },
  ),
  SafeSpotInfo(
    name: 'Feliciano School of Business', hours: 'Open daily 8 AM–8 PM',
    weeklyHours: {
      1: DayHours(openHour: 8, closeHour: 20), 2: DayHours(openHour: 8, closeHour: 20),
      3: DayHours(openHour: 8, closeHour: 20), 4: DayHours(openHour: 8, closeHour: 20),
      5: DayHours(openHour: 8, closeHour: 20), 6: DayHours(openHour: 8, closeHour: 20),
      7: DayHours(openHour: 8, closeHour: 20),
    },
  ),
  SafeSpotInfo(
    name: 'University Hall', hours: 'Open daily 8 AM–5 PM',
    weeklyHours: {
      1: DayHours(openHour: 8, closeHour: 17), 2: DayHours(openHour: 8, closeHour: 17),
      3: DayHours(openHour: 8, closeHour: 17), 4: DayHours(openHour: 8, closeHour: 17),
      5: DayHours(openHour: 8, closeHour: 17), 6: DayHours(openHour: 8, closeHour: 17),
      7: DayHours(openHour: 8, closeHour: 17),
    },
  ),
  SafeSpotInfo(
    name: 'Sprague Library',
    hours: 'Thu 8 AM–10 PM, Fri 8 AM–8 PM, Sat 9 AM–5 PM, Sun 12–9 PM, Mon–Wed 8 AM–12 AM',
    weeklyHours: {
      4: DayHours(openHour: 8, closeHour: 22),
      5: DayHours(openHour: 8, closeHour: 20),
      6: DayHours(openHour: 9, closeHour: 17),
      7: DayHours(openHour: 12, closeHour: 21),
      1: DayHours(openHour: 8, closeHour: 24),
      2: DayHours(openHour: 8, closeHour: 24),
      3: DayHours(openHour: 8, closeHour: 24),
    },
  ),
];

const List<Map<String, String>> kSafeSpots = [
  {'name': 'The Quad',                      'hours': 'Open daily during daylight hours'},
  {'name': 'Student Center',                'hours': 'Mon–Fri 7 AM–11 PM, Sat–Sun 9 AM–9 PM'},
  {'name': 'Susan A. Cole Hall',            'hours': 'Mon–Fri 8 AM–6 PM'},
  {'name': 'Feliciano School of Business',  'hours': 'Mon–Fri 8 AM–8 PM'},
  {'name': 'University Hall',               'hours': 'Mon–Fri 8 AM–5 PM'},
  {'name': 'Sprague Library',               'hours': 'Mon–Thu 8 AM–10 PM, Fri 8 AM–6 PM, Sat–Sun 10 AM–6 PM'},
];

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
      body: Column(
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
                      SizedBox(height: 2),
                      Text('Your conversations', style: TextStyle(fontSize: 15, color: cMuted)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.refresh, color: cMuted), onPressed: _load),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: cRed,
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: cRed))
                  : _error != null
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('Failed to load inbox', style: TextStyle(color: cMuted)),
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
                                              style: TextStyle(fontSize: 14,
                                                  fontWeight: c.unread > 0 ? FontWeight.w800 : FontWeight.w600,
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
                                          Text(
                                            c.lastMessage!.startsWith('__meetup__')
                                                ? '📍 Meetup proposed'
                                                : c.lastMessage!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: c.unread > 0 ? cText : cMuted,
                                              fontWeight: c.unread > 0 ? FontWeight.w600 : FontWeight.w400,
                                            ),
                                            maxLines: 1, overflow: TextOverflow.ellipsis,
                                          ),
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
          ),
        ],
      ),
    );
  }
}

// ── CONVERSATION SCREEN ───────────────────────────────────────────────────────

class ConversationScreen extends StatefulWidget {
  final Conversation conv;
  final int myId;
  final String myName;
  const ConversationScreen({super.key, required this.conv, required this.myId, this.myName = ''});
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

  final Map<int, MeetupStatus> _meetupStatusOverrides = {};
  final Map<int, String> _meetupDenialReasons = {};
  final Set<int> _myPhotoSubmitted = {};
  final Map<int, bool> _meetupPaymentStatus = {};

  @override
  void initState() {
    super.initState();
    _load();
    _checkOnlineStatus();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) => _silentRefresh());
    _statusTimer  = Timer.periodic(const Duration(seconds: 10), (_) => _checkOnlineStatus());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _statusTimer?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

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
      final msgs = raw.map(ChatMessage.fromMap).toList();
      await _syncMeetupStatuses(msgs);
      bool isComplete = widget.conv.isComplete;
      try {
        isComplete = await getConversationIsComplete(conversationId: widget.conv.id);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _msgs..clear()..addAll(msgs);
        _isComplete = isComplete;
        _loading = false;
      });
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
        await _syncMeetupStatuses(incoming);
        if (!mounted) return;
        setState(() { _msgs..clear()..addAll(incoming); });
        _scrollToBottom();
      }
      if (!_isComplete) {
        final nowComplete = await getConversationIsComplete(conversationId: widget.conv.id);
        if (nowComplete && mounted) {
          setState(() => _isComplete = true);
          await RatingDialog.show(context,
            targetName:     widget.conv.otherName,
            targetUserId:   widget.conv.otherId,
            conversationId: widget.conv.id,
            raterUserId:    widget.myId,
          );
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('This conversation has been marked as complete by the other party.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ));
        }
      }
    } catch (_) {}
  }

  Future<void> _syncMeetupStatuses(List<ChatMessage> msgs) async {
    final ids = msgs
        .where((m) => m.isMeetupMessage)
        .map((m) {
          final id = m.meetupPayload?['meetup_id'];
          if (id == null) return null;
          return (id as num).toInt();
        })
        .whereType<int>()
        .toList();
    if (ids.isEmpty) return;
    try {
      final resp = await http.get(Uri.parse(
        'https://cyan.csam.montclair.edu/~ivanovs1/UniFind_API/messaging/meetup/get_meetup_status.php?ids=${ids.join(',')}',
      ));
      if (resp.statusCode != 200) return;
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if (json['success'] != true) return;
      final data = json['data'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        data.forEach((key, value) {
          final id = int.tryParse(key);
          if (id == null) return;

          String statusStr;
          if (value is Map) {
            statusStr = value['status']?.toString() ?? '';
            final buyerId  = int.tryParse(value['buyer_id']?.toString() ?? '');
            final sellerId = int.tryParse(value['seller_id']?.toString() ?? '');
            final buyerPhoto  = value['buyer_photo_url']?.toString() ?? '';
            final sellerPhoto = value['seller_photo_url']?.toString() ?? '';
            final isBuyer  = buyerId  == widget.myId;
            final isSeller = sellerId == widget.myId;
            if ((isBuyer  && buyerPhoto.isNotEmpty) ||
                (isSeller && sellerPhoto.isNotEmpty)) {
              _myPhotoSubmitted.add(id);
            }
            final denialReason = value['denial_reason']?.toString() ?? '';
            if (denialReason.isNotEmpty) {
              _meetupDenialReasons[id] = denialReason;
            }
          } else {
            statusStr = value.toString();
          }
          _meetupStatusOverrides[id] = _parseStatus(statusStr);
        });
      });
    } catch (e) {
      debugPrint('_syncMeetupStatuses error: $e');
    }
  }

  MeetupStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'user_pending':        return MeetupStatus.userPending;
      case 'admin_pending':       return MeetupStatus.adminPending;
      case 'confirmed':           return MeetupStatus.confirmed;
      case 'user_denied':         return MeetupStatus.userDenied;
      case 'admin_denied':        return MeetupStatus.adminDenied;
      case 'user_cancelled':      return MeetupStatus.userCancelled;
      case 'completed':           return MeetupStatus.completed;
      case 'completion_pending':  return MeetupStatus.completionPending;
      default:                    return MeetupStatus.userPending;
    }
  }

  Future<void> _updateMeetupStatusInDb(int meetupId, String status) async {
    final resp = await http.post(
      Uri.parse('https://cyan.csam.montclair.edu/~ivanovs1/UniFind_API/messaging/meetup/update_meetup.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'meetup_id': meetupId, 'status': status}),
    );
    debugPrint('updateMeetup $meetupId -> $status : ${resp.statusCode} ${resp.body}');
    if (resp.statusCode != 200) throw Exception('Failed to update meetup status');
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    if (json['success'] != true) throw Exception(json['error']);
  }

  // ── Photo submission ──────────────────────────────────────────────────────

  Future<void> _submitCompletionPhoto(int meetupId) async {
    final hasPaid = await _checkMeetupPayment(meetupId);
    if (!hasPaid && mounted) {
      final listingId = widget.conv.listingId;
      if (listingId != null) {
        final items = await getListings();
        final rawItem = items.firstWhere(
          (i) => i['id']?.toString() == listingId.toString(),
          orElse: () => <String, dynamic>{},
        );
        if (!mounted) return;
        if (rawItem.isNotEmpty) {
          final item = MarketplaceItem(
            id: rawItem['id']?.toString() ?? '',
            title: rawItem['title']?.toString() ?? '',
            price: double.tryParse(rawItem['price']?.toString() ?? '0') ?? 0,
            description: rawItem['description']?.toString() ?? '',
            category: rawItem['category']?.toString() ?? '',
            condition: rawItem['condition']?.toString() ?? '',
            image: rawItem['image']?.toString().isNotEmpty == true
                ? rawItem['image'].toString()
                : rawItem['image_url']?.toString() ?? '',
            seller: rawItem['username']?.toString() ?? rawItem['seller_username']?.toString() ?? '',
            sellerEmail: rawItem['seller_email']?.toString() ?? '',
            location: rawItem['location']?.toString() ?? '',
            createdAt: DateTime.tryParse(rawItem['created_at']?.toString() ?? '') ?? DateTime.now(),
          );
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PaymentScreen(
              item: item,
              buyerId: widget.myId,
              sellerId: widget.conv.otherId,
              buyerEmail: widget.conv.otherEmail,
            ),
          ));
          if (mounted) {
            setState(() => _meetupPaymentStatus.remove(meetupId));
            await _checkMeetupPayment(meetupId);
          }
          return;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please complete payment before submitting a photo.'),
        backgroundColor: Color(0xFFD97706),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final picker = ImagePicker();
    XFile? picked;

    if (kIsWeb) {
      picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1000);
    } else {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        backgroundColor: cSurface,
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
                decoration: BoxDecoration(color: cBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Submit Completion Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cText)),
            const SizedBox(height: 4),
            const Text(
              'Take a photo at the meetup location to confirm the transaction.',
              style: TextStyle(fontSize: 12, color: cMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.camera_alt_outlined, color: cRed, size: 18)),
              title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.photo_library_outlined, color: cRed, size: 18)),
              title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ]),
        ),
      );
      if (source == null || !mounted) return;
      picked = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 1000);
    }

    if (picked == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Row(children: [
        SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        SizedBox(width: 12),
        Text('Uploading photo...'),
      ]),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 30),
    ));

    try {
      final bytes    = await picked.readAsBytes();
      final photoUrl = await uploadImage(picked.path, bytes, type: 'meetup');

      final result = await submitCompletionPhoto(
        meetupId: meetupId,
        userId:   widget.myId,
        photoUrl: photoUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final bothSubmitted = result['both_submitted'] == true;
      setState(() {
        _myPhotoSubmitted.add(meetupId);
        if (bothSubmitted) {
          _meetupStatusOverrides[meetupId] = MeetupStatus.completionPending;
        }
      });
      if (bothSubmitted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Both photos submitted! Waiting for admin to process.'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Photo submitted! Waiting for the other party to submit theirs.'),
          backgroundColor: Color(0xFF2980B9),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to submit photo: $e'),
        backgroundColor: cRedDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ));
    }
  }

  // ── Payment check ────────────────────────────────────────────────────────

  Future<bool> _checkMeetupPayment(int meetupId) async {
    if (_meetupPaymentStatus.containsKey(meetupId)) {
      return _meetupPaymentStatus[meetupId]!;
    }
    try {
      final resp = await http.get(Uri.parse(
        'https://cyan.csam.montclair.edu/~ivanovs1/UniFind_API/messaging/meetup/check_meetup_payment.php'
        '?meetup_id=$meetupId&user_id=${widget.myId}',
      ));
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if (json['success'] == true) {
        final hasPaid = json['data']['has_paid'] == true;
        if (mounted) setState(() => _meetupPaymentStatus[meetupId] = hasPaid);
        return hasPaid;
      }
    } catch (e) {
      debugPrint('checkMeetupPayment error: $e');
    }
    return true;
  }

  // ── Email helpers ─────────────────────────────────────────────────────────

  Future<void> _notifyProposalReceived(int meetupId, {
    required String date,
    required String time,
    required String location,
  }) async {
    try {
      await http.post(
        Uri.parse('https://cyan.csam.montclair.edu/~ivanovs1/UniFind_API/messaging/meetup/emails/notify_proposal_received.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'buyer_name':   widget.myName,
          'buyer_id':     widget.myId,
          'seller_email': widget.conv.otherEmail,
          'seller_name':  widget.conv.otherFirstName,
          'meetup_date':  date,
          'meetup_time':  time,
          'location':     location,
        }),
      );
    } catch (e) {
      debugPrint('notify_proposal_received error: $e');
    }
  }

  Future<void> _notifyProposalAccepted(int meetupId) async {
    try {
      await http.post(
        Uri.parse('https://cyan.csam.montclair.edu/~ivanovs1/UniFind_API/messaging/meetup/emails/notify_proposal_accepted.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'meetup_id': meetupId}),
      );
    } catch (e) {
      debugPrint('notify_proposal_accepted error: $e');
    }
  }

  Future<void> _notifyProposalDeclined(int meetupId) async {
    try {
      await http.post(
        Uri.parse('https://cyan.csam.montclair.edu/~ivanovs1/UniFind_API/messaging/meetup/emails/notify_proposal_declined.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'meetup_id': meetupId}),
      );
    } catch (e) {
      debugPrint('notify_proposal_declined error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

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
    if (body.isEmpty || _sending || _isComplete) return;
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

  void _openProposeMeetupSheet() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ProposeMeetupDialog(
        conv: widget.conv,
        myId: widget.myId,
        onProposed: (int meetupId, String date, String time, String location) async {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Meetup proposal sent!'),
            behavior: SnackBarBehavior.floating,
          ));
          await _notifyProposalReceived(meetupId, date: date, time: time, location: location);
        },
      ),
    );
  }

  // ── Meetup action handlers ────────────────────────────────────────────────

  Future<void> _withdrawMeetup(int meetupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Withdraw Proposal'),
        content: const Text('Are you sure you want to withdraw this meetup proposal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: cRed, foregroundColor: Colors.white),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _updateMeetupStatusInDb(meetupId, 'user_cancelled');
      if (!mounted) return;
      setState(() => _meetupStatusOverrides[meetupId] = MeetupStatus.userCancelled);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Meetup proposal withdrawn.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _confirmMeetup(int meetupId) async {
    try {
      await _updateMeetupStatusInDb(meetupId, 'admin_pending');
      if (!mounted) return;
      setState(() => _meetupStatusOverrides[meetupId] = MeetupStatus.adminPending);
      await _notifyProposalAccepted(meetupId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Meetup confirmed! Pending admin approval.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _declineOrCancelMeetup(int meetupId, bool isProposer, {bool isConfirmed = false}) async {
    final label = isProposer ? 'Cancel' : 'Decline';
    final content = isConfirmed
        ? 'Are you sure you want to cancel this confirmed meetup? If you have completed payment, it will be cancelled.'
        : 'Are you sure you want to ${label.toLowerCase()} this meetup?';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$label Meetup'),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: cRed, foregroundColor: Colors.white),
            child: Text(label),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _updateMeetupStatusInDb(meetupId, 'user_cancelled');
      if (!mounted) return;
      setState(() {
        _meetupStatusOverrides[meetupId] = MeetupStatus.userCancelled;
        _meetupPaymentStatus.remove(meetupId);
      });
      if (isConfirmed && widget.conv.listingId != null) {
        try {
          await http.post(
            Uri.parse('https://cyan.csam.montclair.edu/~ivanovs1/UniFind_API/payments/cancel_offer_by_listing.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'listing_id': widget.conv.listingId,
              'user_id': widget.myId,
            }),
          );
        } catch (_) {}
      }
      // FIX 3: Removed duplicate _notifyProposalDeclined call; only notify when non-proposer declines
      if (!isProposer) await _notifyProposalDeclined(meetupId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(label == 'Cancel' ? 'Meetup cancelled.' : 'Meetup declined.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────

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
                style: TextStyle(
                    fontSize: 10,
                    color: _otherOnline ? const Color(0xFF27AE60) : Colors.white38,
                    fontWeight: FontWeight.w600)),
          ]),
          Text(widget.conv.subject,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
        actions: [
          if (!_isComplete) ...[
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
          ],
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: cRed))
              : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Failed to load', style: TextStyle(color: cMuted)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ]))
                  : _msgs.isEmpty
                      ? const Center(
                          heightFactor: 6,
                          child: Text('No messages yet. Say hello!',
                              style: TextStyle(color: cMuted)))
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                          itemCount: _msgs.length,
                          itemBuilder: (_, i) {
                            final msg = _msgs[i];

                            if (msg.isMeetupMessage) {
                              final proposal = msg.toMeetupProposal(myId: widget.myId);
                              if (proposal == null) return const SizedBox.shrink();

                              final effectiveStatus = proposal.id != null
                                  ? (_meetupStatusOverrides[proposal.id!] ?? proposal.status)
                                  : proposal.status;
                              final effectiveDenialReason = proposal.id != null
                                  ? (_meetupDenialReasons[proposal.id!] ?? proposal.denialReason)
                                  : proposal.denialReason;
                              // FIX 4: Removed old partial _MeetupCard call; single correct call below
                              final effective = proposal.copyWith(
                                status: effectiveStatus,
                                denialReason: effectiveDenialReason,
                              );
                              final isProposer = effective.proposerId == widget.myId;
                              bool? buyerHasPaid;
                              if (effectiveStatus == MeetupStatus.confirmed && effective.id != null) {
                                buyerHasPaid = _meetupPaymentStatus[effective.id!];
                                if (buyerHasPaid == null) {
                                  _checkMeetupPayment(effective.id!);
                                }
                              }
                              return _MeetupCard(
                                proposal:          effective,
                                myId:              widget.myId,
                                myPhotoSubmitted:  effective.id != null && _myPhotoSubmitted.contains(effective.id),
                                buyerHasPaid:      buyerHasPaid,
                                onWithdraw:        () => _withdrawMeetup(effective.id ?? 0),
                                onConfirm:         () => _confirmMeetup(effective.id ?? 0),
                                onDeclineOrCancel: () => _declineOrCancelMeetup(
                                  effective.id ?? 0, isProposer,
                                  isConfirmed: effectiveStatus == MeetupStatus.confirmed,
                                ),
                                onProposeNew:      _openProposeMeetupSheet,
                                onSubmitPhoto:     () => _submitCompletionPhoto(effective.id ?? 0),
                              );
                            }

                            return _MsgBubble(msg: msg, isMine: msg.senderId == widget.myId);
                          },
                        ),
        ),
        if (_isComplete)
          Container(
            color: const Color(0xFF27AE60).withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(top: false, child: Row(children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF27AE60), size: 18),
              const SizedBox(width: 8),
              const Expanded(child: Text('This conversation has been marked as complete.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF27AE60), fontWeight: FontWeight.w600))),
              GestureDetector(
                onTap: () => RatingDialog.show(context,
                  targetName:     widget.conv.otherName,
                  targetUserId:   widget.conv.otherId,
                  conversationId: widget.conv.id,
                  raterUserId:    widget.myId,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFF27AE60), borderRadius: BorderRadius.circular(8)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.star_rounded, color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text('Rate', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ])),
          )
        else
          Container(
            color: cSurface,
            padding: EdgeInsets.fromLTRB(
                12, 10, 12, 10 + MediaQuery.of(context).viewInsets.bottom),
            child: SafeArea(
              top: false,
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                if (!_hasPendingMeetup) ...[
                  Tooltip(
                    message: 'Propose a Meetup',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: _openProposeMeetupSheet,
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cRedLight,
                          border: Border.all(color: cRed.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.location_on_outlined, color: cRed, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
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
              ]),
            ),
          ),
      ]),
    );
  }

  bool get _hasPendingMeetup {
    for (final msg in _msgs.reversed) {
      if (!msg.isMeetupMessage) continue;
      final proposal = msg.toMeetupProposal(myId: widget.myId);
      if (proposal == null) continue;
      final status = proposal.id != null
          ? (_meetupStatusOverrides[proposal.id!] ?? proposal.status)
          : proposal.status;
      if (status == MeetupStatus.userPending || status == MeetupStatus.adminPending) return true;
      break;
    }
    return false;
  }
}

// ── MESSAGE BUBBLE ────────────────────────────────────────────────────────────

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
                style: TextStyle(color: isMine ? Colors.white : cText, fontSize: 14, height: 1.4)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: Text(_timeStr(msg.sentAt), style: const TextStyle(fontSize: 10, color: cMuted)),
          ),
        ],
      ),
    );
  }
}

// ── MEETUP CARD ───────────────────────────────────────────────────────────────

class _MeetupCard extends StatelessWidget {
  final MeetupProposal proposal;
  final int myId;
  final VoidCallback onWithdraw;
  final VoidCallback onConfirm;
  final VoidCallback onDeclineOrCancel;
  final VoidCallback onProposeNew;
  final VoidCallback onSubmitPhoto;
  final bool myPhotoSubmitted;
  final bool? buyerHasPaid;

  const _MeetupCard({
    required this.proposal, required this.myId,
    required this.onWithdraw, required this.onConfirm,
    required this.onDeclineOrCancel, required this.onProposeNew,
    required this.onSubmitPhoto,
    this.myPhotoSubmitted = false,
    this.buyerHasPaid,
  });

  bool get _isProposer => proposal.proposerId == myId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: cSurface, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cBorder),
            ),
            child: Text(
              _isProposer ? 'You Proposed a Meetup' : '${proposal.proposerName} Proposed a Meetup',
              style: const TextStyle(fontSize: 11, color: cMuted),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          margin: EdgeInsets.only(left: _isProposer ? 40 : 0, right: _isProposer ? 0 : 40),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cSurface, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _statusBorderColor()),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _statusIconBg()),
                child: Icon(_statusIcon(), color: _statusIconColor(), size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Meetup Proposal',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cText)),
                Text(_statusSubtitle(), style: const TextStyle(fontSize: 11, color: cMuted)),
              ])),
              _StatusBadge(status: proposal.status),
            ]),
            const SizedBox(height: 12),
            const Divider(height: 1, color: cBorder),
            const SizedBox(height: 10),
            _InfoRow(icon: Icons.calendar_today_outlined, label: proposal.formattedDate),
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.access_time_outlined, label: proposal.formattedTime),
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.location_on_outlined, label: '${proposal.safeSpot}, MSU'),
            ..._hoursHint(),
            if (proposal.note != null && proposal.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cBg, borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cBorder),
                ),
                child: Text(proposal.note!,
                    style: const TextStyle(fontSize: 12, color: cMuted, height: 1.4)),
              ),
            ],
            if ((proposal.status == MeetupStatus.adminDenied ||
                 proposal.status == MeetupStatus.userDenied) &&
                proposal.denialReason != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cRedLight, borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cRed.withValues(alpha: 0.3)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.info_outline, color: cRed, size: 14),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Reason: ${proposal.denialReason}',
                      style: const TextStyle(fontSize: 12, color: cRed, height: 1.4))),
                ]),
              ),
            ],
            if (proposal.status == MeetupStatus.adminPending) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1FB), borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline, color: Color(0xFF185FA5), size: 13),
                  SizedBox(width: 6),
                  Expanded(child: Text('Waiting for admin approval.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF185FA5)))),
                ]),
              ),
            ],
            if (proposal.status == MeetupStatus.confirmed) ...[
              const SizedBox(height: 10),
              if (buyerHasPaid == false) ...[
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Icon(Icons.payment_rounded, size: 14, color: Color(0xFFD97706)),
                      SizedBox(width: 6),
                      Expanded(child: Text(
                        'Complete your payment before the meetup to confirm your order. Your payment is held securely until admin verifies the exchange.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.4),
                      )),
                    ]),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onSubmitPhoto,
                        icon: const Icon(Icons.lock_rounded, size: 16),
                        label: const Text('Complete Payment First'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ]),
                ),
              ] else ...[
                myPhotoSubmitted
                    ? Container(
                        width: double.infinity, padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                        ),
                        child: const Row(children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                          SizedBox(width: 6),
                          Expanded(child: Text(
                            'Your photo has been submitted. Waiting for the other party to submit theirs.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                          )),
                        ]),
                      )
                    : Container(
                        width: double.infinity, padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.35)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Row(children: [
                            Icon(Icons.camera_alt_rounded, size: 14, color: Color(0xFF16A34A)),
                            SizedBox(width: 6),
                            Expanded(child: Text(
                              'Both users must submit a photo at the meetup location to confirm the transaction.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.4),
                            )),
                          ]),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: onSubmitPhoto,
                              icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                              label: const Text('Submit Completion Photo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ]),
                      ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onDeclineOrCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Cancel Meetup'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cRed,
                    side: BorderSide(color: cRed.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
            if (proposal.status == MeetupStatus.completionPending) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity, padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.hourglass_top_rounded, color: Color(0xFF16A34A), size: 14),
                  SizedBox(width: 6),
                  Expanded(child: Text(
                    'Photos submitted! Waiting for admin to process the transaction.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                  )),
                ]),
              ),
            ],
            ..._buildActions(),
          ]),
        ),
      ]),
    );
  }

  List<Widget> _hoursHint() {
    final spot = kSafeSpots.firstWhere(
      (s) => s['name'] == proposal.safeSpot, orElse: () => {},
    );
    if (spot.isEmpty) return [];
    return [
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.only(left: 24),
        child: Text(spot['hours']!, style: const TextStyle(fontSize: 10, color: cMuted)),
      ),
    ];
  }

  List<Widget> _buildActions() {
    if (proposal.status == MeetupStatus.confirmed)         return [];
    if (proposal.status == MeetupStatus.completed)         return [];
    if (proposal.status == MeetupStatus.userCancelled)     return [];
    if (proposal.status == MeetupStatus.completionPending) return [];

    if (proposal.status == MeetupStatus.userDenied ||
        proposal.status == MeetupStatus.adminDenied) {
      return [
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onProposeNew,
            icon: const Icon(Icons.add_location_alt_outlined, size: 16),
            label: const Text('Propose new time'),
            style: ElevatedButton.styleFrom(
              backgroundColor: cRed, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
      ];
    }

    if (proposal.status == MeetupStatus.userPending) {
      // Lost & Found meetups are auto-submitted for admin approval, no user action needed
      if (proposal.claimId != null) {
        return [];
      }
      if (_isProposer) {
        return [
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onWithdraw,
              style: OutlinedButton.styleFrom(
                foregroundColor: cRed,
                side: BorderSide(color: cRed.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Withdraw', style: TextStyle(fontSize: 13)),
            ),
          ),
        ];
      } else {
        return [
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onDeclineOrCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cRed,
                  side: BorderSide(color: cRed.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Decline', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cRed, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Confirm', style: TextStyle(fontSize: 13)),
              ),
            ),
          ]),
        ];
      }
    }

    if (proposal.status == MeetupStatus.adminPending) {
      return [
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onDeclineOrCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: cRed,
              side: BorderSide(color: cRed.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel meetup', style: TextStyle(fontSize: 13)),
          ),
        ),
      ];
    }

    return [];
  }

  Color _statusBorderColor() {
    switch (proposal.status) {
      case MeetupStatus.confirmed:
      case MeetupStatus.completionPending: return const Color(0xFFC0DD97);
      case MeetupStatus.userDenied:
      case MeetupStatus.adminDenied:       return const Color(0xFFF09595);
      case MeetupStatus.adminPending:      return const Color(0xFFB5D4F4);
      default:                             return cBorder;
    }
  }

  Color _statusIconBg() {
    switch (proposal.status) {
      case MeetupStatus.confirmed:
      case MeetupStatus.completionPending: return const Color(0xFFEAF3DE);
      case MeetupStatus.userDenied:
      case MeetupStatus.adminDenied:       return const Color(0xFFFCEBEB);
      case MeetupStatus.adminPending:      return const Color(0xFFE6F1FB);
      default:                             return cRedLight;
    }
  }

  Color _statusIconColor() {
    switch (proposal.status) {
      case MeetupStatus.confirmed:
      case MeetupStatus.completionPending: return const Color(0xFF3B6D11);
      case MeetupStatus.userDenied:
      case MeetupStatus.adminDenied:       return cRed;
      case MeetupStatus.adminPending:      return const Color(0xFF185FA5);
      default:                             return cRed;
    }
  }

  IconData _statusIcon() {
    switch (proposal.status) {
      case MeetupStatus.confirmed:
      case MeetupStatus.completionPending: return Icons.check_circle_outline;
      case MeetupStatus.userDenied:
      case MeetupStatus.adminDenied:       return Icons.cancel_outlined;
      case MeetupStatus.adminPending:      return Icons.pending_outlined;
      default:                             return Icons.location_on_outlined;
    }
  }

  String _statusSubtitle() {
    switch (proposal.status) {
      case MeetupStatus.userPending:        return _isProposer ? 'Waiting for their confirmation' : 'Awaiting your response';
      case MeetupStatus.adminPending:       return 'Pending admin approval';
      case MeetupStatus.confirmed:          return 'Admin approved — meetup is on!';
      case MeetupStatus.userDenied:         return 'Proposal was declined';
      case MeetupStatus.adminDenied:        return 'Admin denied this proposal';
      case MeetupStatus.userCancelled:      return 'Meetup was cancelled';
      case MeetupStatus.completed:          return 'Meetup completed';
      case MeetupStatus.completionPending:  return 'Waiting for admin to process';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: cMuted),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontSize: 13, color: cText, fontWeight: FontWeight.w600)),
  ]);
}

// FIX 5: Added missing `completionPending` case to _StatusBadge
class _StatusBadge extends StatelessWidget {
  final MeetupStatus status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    Color bg; Color fg; String label;
    switch (status) {
      case MeetupStatus.userPending:
        bg = const Color(0xFFFAEEDA); fg = const Color(0xFF854F0B); label = 'Pending'; break;
      case MeetupStatus.adminPending:
        bg = const Color(0xFFE6F1FB); fg = const Color(0xFF185FA5); label = 'Admin review'; break;
      case MeetupStatus.confirmed:
        bg = const Color(0xFFEAF3DE); fg = const Color(0xFF3B6D11); label = 'Confirmed'; break;
      case MeetupStatus.userDenied:
        bg = const Color(0xFFFCEBEB); fg = const Color(0xFFA32D2D); label = 'Declined'; break;
      case MeetupStatus.adminDenied:
        bg = const Color(0xFFFCEBEB); fg = const Color(0xFFA32D2D); label = 'Admin denied'; break;
      case MeetupStatus.userCancelled:
        bg = const Color(0xFFF1EFE8); fg = const Color(0xFF5F5E5A); label = 'Cancelled'; break;
      case MeetupStatus.completed:
        bg = const Color(0xFFEAF3DE); fg = const Color(0xFF3B6D11); label = 'Completed'; break;
      case MeetupStatus.completionPending:
        bg = const Color(0xFFE6F1FB); fg = const Color(0xFF185FA5); label = 'Processing'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

