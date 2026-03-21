part of '../main.dart';

class ProfileScreen extends StatelessWidget {
  final String email;
  final String username;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.email,
    required this.username,
    required this.onLogout,
  });

  String get _initials {
    if (username.isNotEmpty) return username[0].toUpperCase();
    if (email.isNotEmpty) return email[0].toUpperCase();
    return 'U';
  }

  String get _displayHandle {
    if (username.isNotEmpty) return username;
    if (email.contains('@')) return email.split('@').first;
    return email;
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
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
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
                    Text(email, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
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
        const SizedBox(height: 20),

        // ── Account section ─────────────────────────────────────────────
        _ProfileSectionHeader(label: 'Account'),
        const SizedBox(height: 8),
        _ProfileInfoTile(icon: Icons.person_outline_rounded, label: 'Username', value: _displayHandle),
        _ProfileInfoTile(icon: Icons.mail_outline_rounded, label: 'Email', value: email),
        _ProfileInfoTile(icon: Icons.school_outlined, label: 'Institution', value: 'Montclair State University'),
        const SizedBox(height: 20),

        // ── Security section ────────────────────────────────────────────
        _ProfileSectionHeader(label: 'Security'),
        const SizedBox(height: 8),
        _ProfileActionTile(
          icon: Icons.lock_reset_rounded,
          label: 'Change Password',
          subtitle: 'Update your account password',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ForgotPasswordScreen(initialEmail: email)),
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
            if (confirm == true) onLogout();
          },
        ),
        const SizedBox(height: 32),
        const Center(
          child: Text('© 2026 UniFind · Montclair State University', style: TextStyle(fontSize: 11, color: cMuted)),
        ),
        const SizedBox(height: 16),
      ],
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