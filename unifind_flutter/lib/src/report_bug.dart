part of '../main.dart';

// ─── BUG CATEGORIES ───────────────────────────────────────────────────────────

enum BugCategory {
  ui,
  crash,
  wrongInfo,
  performance,
  other,
}

extension BugCategoryLabel on BugCategory {
  String get label {
    switch (this) {
      case BugCategory.ui:          return 'UI / Visual Issue';
      case BugCategory.crash:       return 'App Crash / Freeze';
      case BugCategory.wrongInfo:   return 'Wrong Information';
      case BugCategory.performance: return 'Slow / Performance';
      case BugCategory.other:       return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case BugCategory.ui:          return Icons.broken_image_outlined;
      case BugCategory.crash:       return Icons.error_outline_rounded;
      case BugCategory.wrongInfo:   return Icons.info_outline_rounded;
      case BugCategory.performance: return Icons.speed_outlined;
      case BugCategory.other:       return Icons.help_outline_rounded;
    }
  }
}

// ─── REPORT BUG SCREEN ────────────────────────────────────────────────────────

class ReportBugScreen extends StatefulWidget {
  final String userEmail;
  const ReportBugScreen({super.key, required this.userEmail});

  @override
  State<ReportBugScreen> createState() => _ReportBugScreenState();
}

class _ReportBugScreenState extends State<ReportBugScreen>
    with TickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _descCtrl     = TextEditingController();
  final _stepsCtrl    = TextEditingController();

  BugCategory? _category;
  bool _loading  = false;
  bool _success  = false;
  String? _error;

  late AnimationController _c;
  late Animation<double> _fade, _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade  = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _slide = Tween(begin: 24.0, end: 0.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    _descCtrl.dispose();
    _stepsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      setState(() => _error = 'Please select a bug category.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    // ← TEMPORARY: simulate a short delay then show success
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() { _loading = false; _success = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: Stack(
        children: [
          // ── Background decoration ──────────────────────────────────────
          Positioned(right: -80, top: -80, child: Container(width: 300, height: 300,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [cRed.withValues(alpha: 0.08), Colors.transparent])))),
          Positioned(left: -60, bottom: -60, child: Container(width: 220, height: 220,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [cRed.withValues(alpha: 0.05), Colors.transparent])))),

          Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, child) => Opacity(
                opacity: _fade.value,
                child: Transform.translate(offset: Offset(0, _slide.value), child: child),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      // ── Logo ──────────────────────────────────────────
                      Image.asset('assets/images/logo.jpg', height: 90, fit: BoxFit.contain),
                      const SizedBox(height: 24),

                      // ── Title ─────────────────────────────────────────
                      const Text(
                        'Report a Bug',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Found something broken? Let us know and we\'ll fix it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: cMuted),
                      ),
                      const SizedBox(height: 32),

                      // ── Card ──────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: cSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: cBorder),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 6))],
                        ),
                        child: _success ? _buildSuccess() : _buildForm(),
                      ),

                      const SizedBox(height: 20),

                      // ── Back button ───────────────────────────────────
                      if (!_success)
                        TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back, size: 14, color: cMuted),
                              SizedBox(width: 6),
                              Text('Back to profile', style: TextStyle(color: cMuted, fontSize: 13)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Success state ──────────────────────────────────────────────────────────
  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [cNavBg, cNavBgDark]),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 20),
        const Text(
          'Bug Reported!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cText),
        ),
        const SizedBox(height: 8),
        const Text(
          'Thanks for helping us improve UniFind. We\'ll look into this as soon as possible.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: cMuted, height: 1.5),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: cRed, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Form state ─────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Category ────────────────────────────────────────────────
          const Text('Bug Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cText, letterSpacing: 0.3)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BugCategory.values.map((cat) {
              final selected = _category == cat;
              return GestureDetector(
                onTap: () => setState(() { _category = cat; _error = null; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? cRed.withValues(alpha: 0.08) : cBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? cRed : cBorder, width: selected ? 2 : 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon, size: 14, color: selected ? cRed : cMuted),
                      const SizedBox(width: 6),
                      Text(cat.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? cRed : cMuted)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // ── Description ──────────────────────────────────────────────
          const Text('What happened?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cText, letterSpacing: 0.3)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descCtrl,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please describe the bug';
              if (v.trim().length < 10) return 'Please provide a bit more detail';
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Describe the bug you found...',
              hintStyle: const TextStyle(color: cMuted, fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cRed, width: 2)),
              filled: true,
              fillColor: cBg,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 16),

          // ── Steps to reproduce ───────────────────────────────────────
          const Text('Steps to reproduce (optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cText, letterSpacing: 0.3)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _stepsCtrl,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: 'e.g. 1. Tap on a listing  2. Press back  3. App freezes',
              hintStyle: const TextStyle(color: cMuted, fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cRed, width: 2)),
              filled: true,
              fillColor: cBg,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 16),

          // ── Info note ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFD0FF).withValues(alpha: 0.6)),
            ),
            child: Row(children: [
              const Icon(Icons.mail_outline_rounded, size: 14, color: Color(0xFF3B5BDB)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Report will be sent from ${widget.userEmail}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF3B5BDB), height: 1.4),
              )),
            ]),
          ),

          // ── Error ────────────────────────────────────────────────────
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: cRedDark, fontSize: 12, fontWeight: FontWeight.w600)),
          ],

          const SizedBox(height: 24),

          // ── Submit button ────────────────────────────────────────────
          _AuthButton(
            loading: _loading,
            onTap: _submit,
            label: 'Submit Bug Report',
          ),
        ],
      ),
    );
  }
}