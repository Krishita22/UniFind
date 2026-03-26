part of '../main.dart';

class LandingPage extends StatelessWidget {
  final AuthSuccessCallback onLogin;
  const LandingPage({super.key, required this.onLogin});

  static final _aboutKey = GlobalKey();
  static final _howKey = GlobalKey();
  static final _faqKey = GlobalKey();
  static final _contactKey = GlobalKey();

  void _scrollTo(GlobalKey k) {
    final ctx = k.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: kSlow, curve: Curves.easeInOutCubic);
  }

  void _openLogin(BuildContext ctx) {
    Navigator.of(ctx).push(PageRouteBuilder(
      transitionDuration: kPage,
      pageBuilder: (_, a, __) => FadeTransition(
        opacity: a,
        child: LoginScreen(
          onLogin: (email, [userId, username]) {
            onLogin(email, userId, username);
            Navigator.of(ctx).popUntil((r) => r.isFirst);
          },
        ),
      ),
    ));
  }

  void _openRegister(BuildContext ctx) {
    Navigator.of(ctx).push(PageRouteBuilder(
      transitionDuration: kPage,
      pageBuilder: (_, a, __) => FadeTransition(
        opacity: a,
        child: RegistrationScreen(
          onRegister: (email, [userId, username]) {
            onLogin(email, userId, username);
            Navigator.of(ctx).popUntil((r) => r.isFirst);
          },
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cSurface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LandingNav(
              onAbout: () => _scrollTo(_aboutKey),
              onHow: () => _scrollTo(_howKey),
              onFaq: () => _scrollTo(_faqKey),
              onContact: () => _scrollTo(_contactKey),
              onLogin: () => _openLogin(context),
              onRegister: () => _openRegister(context),
            ),
            _HeroSection(onLogin: () => _openLogin(context), onRegister: () => _openRegister(context)),
            KeyedSubtree(key: _howKey, child: const _HowItWorksSection()),
            const _FeaturesSection(),
            KeyedSubtree(key: _aboutKey, child: const _AboutSection()),
            KeyedSubtree(key: _faqKey, child: const _FaqSection()),
            KeyedSubtree(key: _contactKey, child: const _ContactSection()), // ← Contact after FAQ
            _ExclusiveBanner(onLogin: () => _openRegister(context)),         // ← Banner after Contact
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

// ─── LANDING NAV ─────────────────────────────────────────────────────────────
class _LandingNav extends StatelessWidget {
  final VoidCallback onAbout, onHow, onFaq, onContact, onLogin, onRegister;
  const _LandingNav({
    required this.onAbout,
    required this.onHow,
    required this.onFaq,
    required this.onContact,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = <MapEntry<String, VoidCallback>>[
      MapEntry('About', onAbout),
      MapEntry('How It Works', onHow),
      MapEntry('FAQ', onFaq),
      MapEntry('Contact', onContact),
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [cNavBg, cNavBgDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: Color(0x33A12727), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 920;

          if (isCompact) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnimatedLogo(),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...navItems.map((e) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: TextButton(
                                onPressed: e.value,
                                child: Text(
                                  e.key,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            )),
                        Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 8)),
                        TextButton(
                          onPressed: onLogin,
                          child: const Text('Log In', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        _PillButton(label: 'Sign Up', icon: Icons.person_add_rounded, onTap: onRegister),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Row(
              children: [
                _AnimatedLogo(),
                const Spacer(),
                ...navItems.map((e) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: TextButton(
                        onPressed: e.value,
                        child: Text(e.key, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    )),
                Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 8)),
                TextButton(
                  onPressed: onLogin,
                  child: const Text('Log In', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                _PillButton(label: 'Sign Up', icon: Icons.person_add_rounded, onTap: onRegister),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kFast);
    _scale = Tween(begin: 1.0, end: 0.94).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) { _c.reverse(); widget.onTap(); },
        onTapCancel: () => _c.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: kFast,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _hovered ? Colors.white.withValues(alpha: 0.30) : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: _hovered ? 0.6 : 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedLogo extends StatefulWidget {
  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          child: Image.asset('assets/images/whitelogo.png', height: 44, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

// ─── HERO SECTION ────────────────────────────────────────────────────────────
class _HeroSection extends StatefulWidget {
  final VoidCallback onLogin, onRegister;
  const _HeroSection({required this.onLogin, required this.onRegister});
  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _slide, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _slide = Tween(begin: 30.0, end: 0.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.easeOutCubic)));
    _scale = Tween(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.easeOutCubic)));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(offset: Offset(0, _slide.value), child: Transform.scale(scale: _scale.value, child: child)),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFF5F5), Color(0xFFFCECEC), Color(0xFFFFF8F8)], begin: Alignment.topLeft, end: Alignment.bottomRight)))),
          Positioned(right: -60, top: -40, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [cRed.withValues(alpha: 0.08), Colors.transparent])))),
          Positioned(left: -40, bottom: -20, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [cRed.withValues(alpha: 0.06), Colors.transparent])))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: cBorder)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.school_rounded, size: 14, color: cRed), SizedBox(width: 6), Text('MSU Campus Exclusive', style: TextStyle(color: cRed, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3))]),
                ),
                const SizedBox(height: 28),
                const Text('Your Campus.\nYour Marketplace.', textAlign: TextAlign.center, style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: cText, height: 1.15, letterSpacing: -1.5)),
                const SizedBox(height: 20),
                const Text('Buy, sell, and reunite with lost items within the\nMontclair State University community.', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: cMuted, height: 1.7)),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _HeroButton(label: 'Get Started', primary: true, onTap: widget.onRegister),
                    const SizedBox(width: 14),
                    _HeroButton(label: 'Log In', primary: false, onTap: widget.onLogin),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatefulWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _HeroButton({required this.label, required this.primary, required this.onTap});

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kFast);
    _scale = Tween(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) { _c.reverse(); widget.onTap(); },
        onTapCancel: () => _c.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: kFast,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: widget.primary ? LinearGradient(colors: _hovered ? [cRedDark, Color(0xFF5A0A0A)] : [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
              color: widget.primary ? null : (_hovered ? cRedLight : cSurface),
              borderRadius: BorderRadius.circular(32),
              border: widget.primary ? null : Border.all(color: cRed, width: 2),
              boxShadow: widget.primary ? [BoxShadow(color: cRed.withValues(alpha: _hovered ? 0.55 : 0.35), blurRadius: _hovered ? 24 : 16, offset: const Offset(0, 6))] : null,
            ),
            child: Text(widget.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: widget.primary ? Colors.white : cRed, letterSpacing: 0.3)),
          ),
        ),
      ),
    );
  }
}

// ─── HOW IT WORKS ────────────────────────────────────────────────────────────
class _HowItWorksSection extends StatefulWidget {
  const _HowItWorksSection();
  @override
  State<_HowItWorksSection> createState() => _HowItWorksSectionState();
}

class _StepData {
  final IconData icon;
  final String title, desc;
  const _StepData({required this.icon, required this.title, required this.desc});
}

class _HowItWorksSectionState extends State<_HowItWorksSection> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward(); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const List<_StepData> steps = [
      _StepData(icon: Icons.person_add_rounded, title: 'Sign Up', desc: 'Create an account using your Montclair State University email to join the community.'),
      _StepData(icon: Icons.add_circle_rounded, title: 'Browse or Post', desc: 'Find items for sale, report lost belongings, or create your own listings.'),
      _StepData(icon: Icons.handshake_rounded, title: 'Connect', desc: 'Message students, arrange pickups, and complete exchanges safely on campus.'),
    ];
    return Container(
      color: cSurface,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 72),
      child: Column(
        children: [
          _SectionLabel(label: 'HOW IT WORKS'),
          const SizedBox(height: 12),
          const Text('Three simple steps', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.8)),
          const SizedBox(height: 8),
          const Text('to get started on UniFind.', style: TextStyle(fontSize: 16, color: cMuted)),
          const SizedBox(height: 52),
          Wrap(
            spacing: 20, runSpacing: 20, alignment: WrapAlignment.center,
            children: List.generate(steps.length, (i) {
              final s = steps[i];
              return ConstrainedBox(constraints: const BoxConstraints(minHeight: 200), child: _StepCard(icon: s.icon, title: s.title, desc: s.desc, delay: Duration(milliseconds: 120 * i)));
            }),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: cRed, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
    );
  }
}

class _StepCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  final Duration delay;
  const _StepCard({required this.icon, required this.title, required this.desc, required this.delay});

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kMid);
    _scale = Tween(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) { setState(() => _hovered = true); _c.forward(); },
      onExit: (_) { setState(() => _hovered = false); _c.reverse(); },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: kMid, width: 270, padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _hovered ? cRedLight : cSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _hovered ? cRed.withValues(alpha: 0.4) : cBorder, width: 1.5),
            boxShadow: [BoxShadow(color: _hovered ? cRed.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06), blurRadius: _hovered ? 20 : 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(gradient: const LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))]), child: Icon(widget.icon, color: Colors.white, size: 24)),
              const SizedBox(height: 16),
              Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cText)),
              const SizedBox(height: 8),
              Text(widget.desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: cMuted, height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── FEATURES ────────────────────────────────────────────────────────────────
class _FeatureData {
  final IconData icon;
  final String title, desc;
  const _FeatureData(this.icon, this.title, this.desc);
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    const List<_FeatureData> features = [
      _FeatureData(Icons.storefront_rounded, 'Campus Marketplace', 'Buy and sell textbooks, electronics, furniture, clothing, and more with other MSU students.'),
      _FeatureData(Icons.search_rounded, 'Lost & Found', 'Report lost items or post things you\'ve found to help reunite students with their belongings.'),
      _FeatureData(Icons.bolt_rounded, 'Post in Seconds', 'Create a listing with a title, photo, price, and category in just a few clicks.'),
      _FeatureData(Icons.verified_user_rounded, 'MSU Community Only', 'Exclusively for Montclair State University members — a trusted, verified space you can rely on.'),
    ];
    return Container(
      color: const Color(0xFFF8F2F2),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 72),
      child: Column(
        children: [
          _SectionLabel(label: 'FEATURES'),
          const SizedBox(height: 12),
          const Text('Everything you need', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.8)),
          const SizedBox(height: 8),
          const Text('for campus life, simplified.', style: TextStyle(fontSize: 16, color: cMuted)),
          const SizedBox(height: 52),
          Wrap(spacing: 20, runSpacing: 20, alignment: WrapAlignment.center, children: features.map((f) => _FeatureCard(icon: f.icon, title: f.title, desc: f.desc)).toList()),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  const _FeatureCard({required this.icon, required this.title, required this.desc});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _lift;
  bool _hov = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kMid);
    _lift = Tween(begin: 0.0, end: -6.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) { setState(() => _hov = true); _c.forward(); },
      onExit: (_) { setState(() => _hov = false); _c.reverse(); },
      child: AnimatedBuilder(
        animation: _lift,
        builder: (_, child) => Transform.translate(offset: Offset(0, _lift.value), child: child),
        child: AnimatedContainer(
          duration: kMid, width: 270, padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: cSurface, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _hov ? cRed.withValues(alpha: 0.3) : cBorder),
            boxShadow: [BoxShadow(color: _hov ? cRed.withValues(alpha: 0.14) : Colors.black.withValues(alpha: 0.07), blurRadius: _hov ? 24 : 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: kMid, width: 50, height: 50,
                decoration: BoxDecoration(gradient: _hov ? const LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight) : const LinearGradient(colors: [cRedLight, cRedLight]), borderRadius: BorderRadius.circular(14)),
                child: Icon(widget.icon, color: _hov ? Colors.white : cRed, size: 24),
              ),
              const SizedBox(height: 16),
              Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cText)),
              const SizedBox(height: 8),
              Text(widget.desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: cMuted, height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ABOUT ───────────────────────────────────────────────────────────────────
class _AboutData {
  final IconData icon;
  final String title, desc;
  final bool shaded;
  const _AboutData(this.icon, this.title, this.desc, this.shaded);
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    const List<_AboutData> items = [
      _AboutData(Icons.school_rounded, 'Our Mission', 'UniFind was created to make campus life easier at MSU. We believe everyone deserves a safe, trusted platform to buy, sell, and recover lost belongings within their own community.', false),
      _AboutData(Icons.groups_rounded, 'Who We Are', 'We are MSU students who saw a need for a dedicated campus marketplace. UniFind is built with the MSU community in mind — every feature is designed around how students actually live on campus.', true),
      _AboutData(Icons.favorite_rounded, 'Why UniFind', 'Unlike other marketplaces, UniFind is exclusively for MSU community members. That means safer transactions, familiar faces, and a community you can trust. No strangers, just fellow Red Hawks.', false),
    ];
    return Container(
      color: cSurface,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 72),
      child: Column(
        children: [
          _SectionLabel(label: 'ABOUT'),
          const SizedBox(height: 12),
          const Text('About UniFind', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.8)),
          const SizedBox(height: 8),
          const Text('Built for the Red Hawk community.', style: TextStyle(fontSize: 16, color: cMuted)),
          const SizedBox(height: 52),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(children: items.map((i) => _AboutRow(icon: i.icon, title: i.title, desc: i.desc, shaded: i.shaded)).toList()),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  final bool shaded;
  const _AboutRow({required this.icon, required this.title, required this.desc, required this.shaded});

  @override
  State<_AboutRow> createState() => _AboutRowState();
}

class _AboutRowState extends State<_AboutRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: _hovered ? Matrix4.translationValues(0, -8, 0) : Matrix4.identity(),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: widget.shaded ? cRedLight : cSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hovered ? cRed.withValues(alpha: 0.4) : cBorder),
          boxShadow: [BoxShadow(color: _hovered ? cRed.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.06), blurRadius: _hovered ? 24 : 10, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(width: 52, height: 52, decoration: BoxDecoration(gradient: const LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]), child: Icon(widget.icon, color: Colors.white, size: 22)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cRed)),
                  const SizedBox(height: 6),
                  Text(widget.desc, style: const TextStyle(fontSize: 13, color: cMuted, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FAQ ─────────────────────────────────────────────────────────────────────
class _FaqData {
  final String question, answer;
  const _FaqData(this.question, this.answer);
}

class _FaqSection extends StatelessWidget {
  const _FaqSection();

  @override
  Widget build(BuildContext context) {
    const List<_FaqData> faqs = [
      _FaqData('Who can use UniFind?', 'UniFind is exclusively for Montclair State University students, faculty, and staff. You must sign up with a valid MSU email address to access the platform.'),
      _FaqData('Is UniFind safe?', 'Yes! UniFind will have administrators monitoring listings and users to ensure listings are legitimate and all users are verified MSU students and faculty.'),
      _FaqData('How do I post an item for sale?', 'After signing in, tap the "Post" tab at the bottom of the app. Fill in the title, description, price, category, and location. It takes less than a minute!'),
      _FaqData('What categories are available?', 'Marketplace includes Beauty & Personal Care, Clothing, Dorm Essentials, Electronics, Instruments, Kitchen & Appliances, Lab Equipment, Other, School Supplies, Sports & Fitness, Textbooks, and Tickets. Lost & Found includes Electronics, Bags, Keys, ID/Cards, Wallets, Water Bottles, Clothing, Accessories, and Other.'),
      _FaqData('How does Lost & Found work?', 'Students can post items they\'ve lost or found on campus. Browse the feed, filter by category, and reach out to reunite items with their owners.'),
      _FaqData('How do I contact a seller?', 'Once signed in and viewing a listing, you can message the seller directly through the app to arrange a meetup or ask questions.'),
    ];
    return Container(
      color: const Color(0xFFF8F2F2),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 72),
      child: Column(
        children: [
          _SectionLabel(label: 'FAQ'),
          const SizedBox(height: 12),
          const Text('Frequently asked questions', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.8)),
          const SizedBox(height: 8),
          const Text('Everything you need to know before getting started', style: TextStyle(fontSize: 16, color: cMuted)),
          const SizedBox(height: 52),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(children: faqs.map((f) => _FaqTile(question: f.question, answer: f.answer)).toList()),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question, answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _expand, _rotate;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kMid);
    _expand = CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic);
    _rotate = Tween(begin: 0.0, end: 0.5).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) _c.forward(); else _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _open ? cRed.withValues(alpha: 0.4) : cBorder, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: _open ? 0.08 : 0.04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: _open ? cRed : cRedLight, borderRadius: BorderRadius.circular(8)),
                    child: RotationTransition(turns: _rotate, child: Icon(Icons.keyboard_arrow_down_rounded, color: _open ? Colors.white : cRed, size: 20)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(widget.question, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _open ? cRed : cText))),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expand,
            child: Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(64, 0, 18, 18), child: Text(widget.answer, style: const TextStyle(fontSize: 13, color: cMuted, height: 1.7))),
          ),
        ],
      ),
    );
  }
}

// ─── CONTACT SECTION ─────────────────────────────────────────────────────────
class _ContactSection extends StatefulWidget {
  const _ContactSection();

  @override
  State<_ContactSection> createState() => _ContactSectionState();
}

class _ContactSectionState extends State<_ContactSection> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _subject = '';
  String _message = '';
  bool _loading = false;
  bool _submitted = false;

  Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _loading = true);

  try {
    final response = await http.post(
    Uri.parse('https://cyan.csam.montclair.edu/~ivanovs1/UniFind_Test_API/contact.php'),
    headers: {
      'Content-Type': 'application/json', // This is required
    },
    body: jsonEncode({
      'name': _name,
      'email': _email,
      'subject': _subject,
      'message': _message,
    }),
  );

    final data = jsonDecode(response.body);

    if (mounted) {
      setState(() {
        _loading = false;
        _submitted = data['success'] == true;
      });
    }

    if (data['success'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['error'] ?? 'Something went wrong')),
      );
    }

  } catch (e) {
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cSurface,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 72),
      child: Column(
        children: [
          _SectionLabel(label: 'CONTACT'),
          const SizedBox(height: 12),
          const Text('Get in touch', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.8)),
          const SizedBox(height: 8),
          const Text('Have a question or feedback? We\'d love to hear from you.', style: TextStyle(fontSize: 16, color: cMuted), textAlign: TextAlign.center),
          const SizedBox(height: 52),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _submitted
                  ? _SuccessCard()
                  : _FormCard(
                      formKey: _formKey,
                      loading: _loading,
                      onNameChanged: (v) => _name = v,
                      onEmailChanged: (v) => _email = v,
                      onSubjectChanged: (v) => _subject = v,
                      onMessageChanged: (v) => _message = v,
                      onSubmit: _submit,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool loading;
  final ValueChanged<String> onNameChanged, onEmailChanged, onSubjectChanged, onMessageChanged;
  final VoidCallback onSubmit;

  const _FormCard({
    required this.formKey,
    required this.loading,
    required this.onNameChanged,
    required this.onEmailChanged,
    required this.onSubjectChanged,
    required this.onMessageChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('form'),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cSurface, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 480;
                final nameField = _ContactField(label: 'Your Name', hint: 'Jane Doe', icon: Icons.person_outline_rounded, onChanged: onNameChanged, textInputAction: TextInputAction.next, validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null);
                final emailField = _ContactField(label: 'Your Email', hint: 'you@example.com', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress, onChanged: onEmailChanged, textInputAction: TextInputAction.next, validator: (v) { if (v == null || v.trim().isEmpty) return 'Email is required'; if (!v.contains('@')) return 'Enter a valid email'; return null; });
                if (wide) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: nameField), const SizedBox(width: 14), Expanded(child: emailField)]);
                }
                return Column(children: [nameField, const SizedBox(height: 16), emailField]);
              },
            ),
            const SizedBox(height: 16),
            _ContactField(label: 'Subject', hint: 'What\'s this about?', icon: Icons.subject_rounded, onChanged: onSubjectChanged, textInputAction: TextInputAction.next, validator: (v) => (v == null || v.trim().isEmpty) ? 'Subject is required' : null),
            const SizedBox(height: 16),
            _ContactMessageField(onChanged: onMessageChanged, validator: (v) { if (v == null || v.trim().isEmpty) return 'Message is required'; if (v.trim().length < 10) return 'Please write a bit more'; return null; }),
            const SizedBox(height: 28),
            _ContactSubmitButton(loading: loading, onTap: onSubmit),
          ],
        ),
      ),
    );
  }
}

class _SuccessCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('success'),
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 32),
      decoration: BoxDecoration(
        color: cSurface, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight), shape: BoxShape.circle, boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))]),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 20),
          const Text('Message sent!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cText)),
          const SizedBox(height: 8),
          const Text('Thanks for reaching out.\nWe\'ll get back to you shortly.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: cMuted, height: 1.6)),
        ],
      ),
    );
  }
}

// ─── CONTACT FORM HELPERS ────────────────────────────────────────────────────

class _ContactField extends StatelessWidget {
  final String label, hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  const _ContactField({required this.label, required this.hint, required this.icon, this.keyboardType, this.onChanged, this.textInputAction, this.validator});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cText, letterSpacing: 0.3)),
        const SizedBox(height: 6),
        TextFormField(
          keyboardType: keyboardType, onChanged: onChanged, textInputAction: textInputAction, validator: validator,
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(color: cMuted, fontSize: 14),
            prefixIcon: Icon(icon, size: 18, color: cMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cRed, width: 2)),
            filled: true, fillColor: cBg, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _ContactMessageField extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const _ContactMessageField({this.onChanged, this.validator});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Message', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cText, letterSpacing: 0.3)),
        const SizedBox(height: 6),
        TextFormField(
          onChanged: onChanged, validator: validator, maxLines: 5, minLines: 4, textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'Write your message here...', hintStyle: const TextStyle(color: cMuted, fontSize: 14), alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cRed, width: 2)),
            filled: true, fillColor: cBg, contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}

class _ContactSubmitButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;

  const _ContactSubmitButton({required this.loading, required this.onTap});

  @override
  State<_ContactSubmitButton> createState() => _ContactSubmitButtonState();
}

class _ContactSubmitButtonState extends State<_ContactSubmitButton> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kFast);
    _scale = Tween(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) { _c.reverse(); widget.onTap(); },
        onTapCancel: () => _c.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedScale(
            scale: _hovered ? 1.015 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5))],
              ),
              child: Center(
                child: widget.loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.send_rounded, color: Colors.white, size: 16), SizedBox(width: 8), Text('Send Message', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3))]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── EXCLUSIVE BANNER ────────────────────────────────────────────────────────
class _ExclusiveBanner extends StatelessWidget {
  final VoidCallback onLogin;
  const _ExclusiveBanner({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [cNavBg, cNavBgDark, Color(0xFF4A0A0A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2)),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 20),
          const Text('Made for the Red Hawk Community', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 14),
          Text('UniFind is designed solely for MSU — a safe, verified space to sell and connect.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 15, height: 1.6)),
          const SizedBox(height: 32),
          _HeroButton(label: 'Join UniFind Today', primary: false, onTap: onLogin),
        ],
      ),
    );
  }
}

// ─── FOOTER ──────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: const Center(
        child: Text('© 2026 UniFind · Montclair State University', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
      ),
    );
  }
}