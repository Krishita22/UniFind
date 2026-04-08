part of '../main.dart';

class ProfileScreen extends StatefulWidget {
  final String email;
  final String username;
  final VoidCallback onLogout;
  final int? userId;

  const ProfileScreen({
    super.key,
    required this.email,
    required this.username,
    required this.onLogout,
    this.userId,
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
                      child: const Text('MSU Student', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
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
                      Text('View all', style: TextStyle(fontSize: 12, color: cRed, fontWeight: FontWeight.w700)),
                      Icon(Icons.chevron_right_rounded, color: cRed, size: 18),
                    ]),
                  ]),
          ),
        ),
        const SizedBox(height: 20),

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
            MaterialPageRoute(builder: (_) => const DocumentationScreen()),
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