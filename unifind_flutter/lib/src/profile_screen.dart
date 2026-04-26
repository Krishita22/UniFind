part of '../main.dart';

class ProfileScreen extends StatefulWidget {
  final String email;
  final String username;
  final VoidCallback onLogout;
  final int? userId;
  final UserRole role;

  const ProfileScreen({
    super.key,
    required this.email,
    required this.username,
    required this.onLogout,
    this.userId,
    this.role = UserRole.student,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Uint8List? _avatarBytes;
  double? _ratingAvg;
  int _ratingCount = 0;
  Timer? _ratingTimer;
  late String _localUsername = '';

  @override
  void initState() {
    super.initState();
    _localUsername = widget.username;
    _loadRating();
    _ratingTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadRating());
  }

  @override
  void dispose() {
    _ratingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRating() async {
    if (widget.userId == null) return;
    try {
      final data = await getUserRating(userId: widget.userId!);
      if (!mounted) return;
      setState(() {
        _ratingAvg   = (data['avg'] as num?)?.toDouble() ?? 0.0;
        _ratingCount = (data['count'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {}
  }

  String get _initials {
  if (_localUsername.isNotEmpty) return _localUsername[0].toUpperCase();
  if (widget.email.isNotEmpty) return widget.email[0].toUpperCase();
  return 'U';
}

String get _displayHandle {
  if (_localUsername.isNotEmpty) return _localUsername;
  if (widget.email.contains('@')) return widget.email.split('@').first;
  return widget.email;
}

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 400);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _avatarBytes = bytes);
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: cSurface,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: cBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Profile Picture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cText)),
            const SizedBox(height: 4),
            const Text('Choose how to set your avatar', style: TextStyle(fontSize: 12, color: cMuted)),
            const SizedBox(height: 16),
            _BottomSheetOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: () { Navigator.pop(ctx); _pickAvatar(); },
            ),
            const SizedBox(height: 8),
            _BottomSheetOption(
              icon: Icons.camera_alt_outlined,
              label: 'Take a Photo',
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 400);
                if (picked == null) return;
                final bytes = await picked.readAsBytes();
                setState(() => _avatarBytes = bytes);
              },
            ),
            if (_avatarBytes != null) ...[
              const SizedBox(height: 8),
              _BottomSheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'Remove Photo',
                isDestructive: true,
                onTap: () { Navigator.pop(ctx); setState(() => _avatarBytes = null); },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Avatar + name card ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [cNavBg, cRedDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(
            children: [
              // ── Tappable avatar ─────────────────────────────────────
              GestureDetector(
                onTap: _showAvatarOptions,
                child: Stack(
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 2.5),
                      ),
                      child: ClipOval(
                        child: _avatarBytes != null
                            ? Image.memory(_avatarBytes!, fit: BoxFit.cover, width: 72, height: 72)
                            : Center(
                                child: Text(
                                  _initials,
                                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                              ),
                      ),
                    ),
                    // Camera badge
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: cRed,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 11, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayHandle,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.email, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Text(widget.role == UserRole.fac ? 'MSU Faculty' : 'MSU Student', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Edit avatar hint ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: GestureDetector(
            onTap: _showAvatarOptions,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit_outlined, size: 12, color: cMuted),
                const SizedBox(width: 4),
                Text(
                  _avatarBytes != null ? 'Change profile picture' : 'Add a profile picture',
                  style: const TextStyle(fontSize: 13, color: cMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Account section ─────────────────────────────────────────────
        _ProfileSectionHeader(label: 'Account'),
        const SizedBox(height: 8),
        _ProfileInfoTile(icon: Icons.person_outline_rounded, label: 'Username', value: _displayHandle),
        _ProfileInfoTile(icon: Icons.mail_outline_rounded, label: 'Email', value: widget.email),
        const SizedBox(height: 20),

        // ── Reputation section ──────────────────────────────────────────
        _ProfileSectionHeader(label: 'Reputation'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: widget.userId != null && _ratingCount > 0
              ? () => ReviewsSheet.show(context, userId: widget.userId!, userName: _displayHandle)
              : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cBorder),
            ),
            child: _ratingCount == 0
                ? Row(children: [
                    const Icon(Icons.star_outline_rounded, color: cMuted, size: 22),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('No ratings yet',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cText)),
                      const SizedBox(height: 2),
                      Text('Complete interactions to receive ratings',
                          style: const TextStyle(fontSize: 12, color: cMuted)),
                    ]),
                  ])
                : Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_ratingAvg!.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                              color: cText, letterSpacing: -1)),
                      StarRatingDisplay(rating: _ratingAvg!, count: _ratingCount, size: 13),
                    ])),
                    const Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.chevron_right_rounded, color: cRed, size: 18),
                    ]),
                  ]),
          ),
        ),
        const SizedBox(height: 20),

        // ── Past Purchases section ──────────────────────────────────────
        if (widget.userId != null && widget.role != UserRole.fac) ...[
          _ProfileSectionHeader(label: 'Past Purchases'),
          const SizedBox(height: 8),
          _PastPurchasesSection(userId: widget.userId!),
          const SizedBox(height: 20),
        ],

        // ── Security section ────────────────────────────────────────────
        _ProfileSectionHeader(label: 'Security'),
        const SizedBox(height: 8),
        _ProfileActionTile(
          icon: Icons.lock_reset_rounded,
          label: 'Change Password',
          subtitle: 'Update your account password',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ChangePasswordScreen()),
          ),
        ),
        _ProfileActionTile(
          icon: Icons.drive_file_rename_outline_rounded,
          label: 'Change Username',
          subtitle: 'Update your display name',
          onTap: () async {
            final newUsername = await Navigator.of(context).push<String>(
              MaterialPageRoute(builder: (_) => ChangeUsernameScreen(email: widget.email)),
            );
            if (newUsername != null) {
              setState(() => _localUsername = newUsername);
            }
          },
        ),
        const SizedBox(height: 20),

        // ── Help & Docs section ─────────────────────────────────────────
        _ProfileSectionHeader(label: 'Help & Docs'),
        const SizedBox(height: 8),
        _ProfileActionTile(
          icon: Icons.menu_book_outlined,
          label: 'Documentation',
          subtitle: 'How to use UniFind',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DocumentationScreen(facultyOnly: widget.role == UserRole.fac)),
          ),
        ),
        _ProfileActionTile(
          icon: Icons.gavel_rounded,
          label: 'Terms & Conditions',
          subtitle: 'Usage policy and community rules',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen()),
          ),
        ),
        _ProfileActionTile(
          icon: Icons.privacy_tip_outlined,
          label: 'Privacy Policy',
          subtitle: 'How we handle your data',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen(initialTab: 1)),
          ),
        ),
        _ProfileActionTile(
          icon: Icons.bug_report_outlined,
          label: 'Report a Bug',
          subtitle: 'Help us improve UniFind',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ReportBugScreen(
              userEmail: widget.email,
              userId: widget.userId ?? 0,
            )),
          ),
        ),
        const SizedBox(height: 20),

        // ── Session section ─────────────────────────────────────────────
        _ProfileSectionHeader(label: 'Session'),
        const SizedBox(height: 8),
        _ProfileActionTile(
          icon: Icons.logout_rounded,
          label: 'Log Out',
          subtitle: 'Sign out of your UniFind account',
          isDestructive: true,
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w800)),
                content: const Text('Are you sure you want to sign out?', style: TextStyle(color: cMuted)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Log Out', style: TextStyle(color: cRedDark, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
            if (confirm == true) widget.onLogout();
          },
        ),
        const SizedBox(height: 32),
        const Center(
          child: Text('\u00a9 2026 UniFind \u00b7 Montclair State University', style: TextStyle(fontSize: 11, color: cMuted)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── PAST PURCHASES SECTION ───────────────────────────────────────────────────

class _PastPurchasesSection extends StatefulWidget {
  final int userId;
  const _PastPurchasesSection({required this.userId});
  @override
  State<_PastPurchasesSection> createState() => _PastPurchasesSectionState();
}

class _PastPurchasesSectionState extends State<_PastPurchasesSection> {
  List<Map<String, dynamic>>? _offers;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final offers = await getUserOffers(userId: widget.userId);
      if (mounted) setState(() { _offers = offers; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _offers = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: cSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: cBorder)),
        child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cRed))),
      );
    }

    final offers = _offers ?? [];
    if (offers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: cSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: cBorder)),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.receipt_long_outlined, size: 18, color: cRed)),
          const SizedBox(width: 14),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('No purchases yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cText)),
            SizedBox(height: 2),
            Text('Items you buy will appear here', style: TextStyle(fontSize: 12, color: cMuted)),
          ]),
        ]),
      );
    }

    return Column(
      children: offers.map((o) => _PurchaseTile(offer: o, onRefresh: _load)).toList(),
    );
  }
}

class _PurchaseTile extends StatefulWidget {
  final Map<String, dynamic> offer;
  final VoidCallback onRefresh;
  const _PurchaseTile({required this.offer, required this.onRefresh});
  @override
  State<_PurchaseTile> createState() => _PurchaseTileState();
}

class _PurchaseTileState extends State<_PurchaseTile> {
  static const _statusLabel = <String, String>{
    'pending':   'Active',
    'completed': 'Completed',
    'refunded':  'Refunded',
    'cancelled': 'Cancelled',
  };
  static const _statusFg = <String, Color>{
    'pending':   Color(0xFFD97706),
    'completed': Color(0xFF16A34A),
    'refunded':  Color(0xFF2563EB),
    'cancelled': Color(0xFF6B7280),
  };
  static const _statusBg = <String, Color>{
    'pending':   Color(0xFFFFFBEB),
    'completed': Color(0xFFF0FDF4),
    'refunded':  Color(0xFFEFF6FF),
    'cancelled': Color(0xFFF3F4F6),
  };

  String _formatDate(String raw) {
    // raw is 'YYYY-MM-DD HH:MM:SS'
    try {
      final dt = DateTime.parse(raw);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  void _openDetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OfferDetailSheet(
        offer: widget.offer,
        onProcessed: () {
          Navigator.pop(context);
          widget.onRefresh();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status     = (widget.offer['status'] as String?) ?? 'pending';
    final amount     = double.tryParse(widget.offer['amount']?.toString() ?? '0') ?? 0.0;
    final rawDate    = widget.offer['created_at'] as String? ?? '';
    final itemTitle  = (widget.offer['item_title'] as String?)?.isNotEmpty == true
        ? widget.offer['item_title'] as String
        : 'Marketplace Item';

    final label = _statusLabel[status] ?? status;
    final fg    = _statusFg[status]    ?? const Color(0xFF6B7280);
    final bg    = _statusBg[status]    ?? const Color(0xFFF3F4F6);

    return GestureDetector(
      onTap: _openDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.receipt_outlined, size: 18, color: cRed),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(itemTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cText)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text('\$${amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cRed)),
                    if (rawDate.isNotEmpty) ...[
                      const Text('  ·  ', style: TextStyle(fontSize: 11, color: cMuted)),
                      Text(_formatDate(rawDate), style: const TextStyle(fontSize: 11, color: cMuted)),
                    ],
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                  child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded, size: 16, color: cMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── OFFER DETAIL SHEET ───────────────────────────────────────────────────────

class _OfferDetailSheet extends StatefulWidget {
  final Map<String, dynamic> offer;
  final VoidCallback onProcessed;
  const _OfferDetailSheet({required this.offer, required this.onProcessed});
  @override
  State<_OfferDetailSheet> createState() => _OfferDetailSheetState();
}

class _OfferDetailSheetState extends State<_OfferDetailSheet> {
  bool _processing = false;
  String? _error;

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  Future<void> _confirmPayment(int userId) async {
    setState(() { _processing = true; _error = null; });
    try {
      await processPayment(
        offerId: widget.offer['offer_id']?.toString() ?? '',
        userId:  userId,
      );
      widget.onProcessed();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _processing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer      = widget.offer;
    final status     = (offer['status'] as String?) ?? 'pending';
    final amount     = double.tryParse(offer['amount']?.toString() ?? '0') ?? 0.0;
    final offerId    = offer['offer_id']?.toString()    ?? '';
    final itemTitle  = (offer['item_title'] as String?)?.isNotEmpty == true
        ? offer['item_title'] as String : 'Marketplace Item';
    final rawDate    = offer['created_at'] as String? ?? '';
    final address    = (offer['billing_address'] as String?)?.isNotEmpty == true
        ? offer['billing_address'] as String : 'Express checkout';
    final buyerEmail = offer['buyer_email'] as String? ?? '';
    final isPending  = status == 'pending';

    // get userId from context — find nearest ProfileScreen ancestor or pass down
    // For now we derive it from buyer_id stored in the offer
    final buyerId = int.tryParse(offer['buyer_id']?.toString() ?? '0') ?? 0;

    return Container(
      decoration: const BoxDecoration(
        color: cBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(width: 40, height: 4, decoration: BoxDecoration(color: cBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          // header
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.receipt_long_rounded, size: 22, color: cRed),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(itemTitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cText)),
              const SizedBox(height: 2),
              Text('\$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cRed)),
            ])),
          ]),
          const SizedBox(height: 20),

          // detail rows
          _DetailRow(label: 'Reference', value: offerId),
          _DetailRow(label: 'Date', value: rawDate.isNotEmpty ? _formatDate(rawDate) : '—'),
          _DetailRow(label: 'Amount', value: '\$${amount.toStringAsFixed(2)}'),
          _DetailRow(label: 'Status', value: isPending ? 'Active' : status[0].toUpperCase() + status.substring(1),
              valueColor: isPending ? const Color(0xFFD97706) : const Color(0xFF16A34A)),
          if (address != 'Express checkout') _DetailRow(label: 'Billing', value: address),
          if (buyerEmail.isNotEmpty) _DetailRow(label: 'Email', value: buyerEmail),
          const SizedBox(height: 8),

          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDF1B41).withValues(alpha: 0.3)),
              ),
              child: Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFDF1B41))),
            ),
            const SizedBox(height: 12),
          ],

          if (isPending) ...[
            // info banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A).withValues(alpha: 0.8)),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFFD97706)),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Only confirm once you have met the seller and received the item.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.4),
                )),
              ]),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _processing ? null : () => _confirmPayment(buyerId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cNavBg,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _processing
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.check_circle_outline_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Confirm Payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      ]),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cRed,
                  side: const BorderSide(color: cBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(children: [
        Text(label, style: const TextStyle(fontSize: 13, color: cMuted, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: valueColor ?? cText)),
      ]),
    );
  }
}

class _BottomSheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  const _BottomSheetOption({required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? cRedDark : cText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDestructive ? const Color(0xFFFFF0F0) : cBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDestructive ? cRed.withValues(alpha: 0.2) : cBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ProfileSectionHeader extends StatelessWidget {
  final String label;
  const _ProfileSectionHeader({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: cMuted, letterSpacing: 1.4)),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileInfoTile({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cSurface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: cRed),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: cMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  const _ProfileActionTile({required this.icon, required this.label, required this.subtitle, required this.onTap, this.isDestructive = false});
  @override
  State<_ProfileActionTile> createState() => _ProfileActionTileState();
}

class _ProfileActionTileState extends State<_ProfileActionTile> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive ? cRedDark : cRed;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: kFast,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _hovered ? (widget.isDestructive ? const Color(0xFFFFF0F0) : cRedLight) : cSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _hovered ? color.withValues(alpha: 0.3) : cBorder),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: widget.isDestructive ? const Color(0xFFFFEEEE) : cRedLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, size: 18, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                    const SizedBox(height: 2),
                    Text(widget.subtitle, style: const TextStyle(fontSize: 12, color: cMuted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20, color: _hovered ? color : cMuted),
            ],
          ),
        ),
      ),
    );
  }
}