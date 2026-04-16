part of '../main.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PUBLIC ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────

class ProposeMeetupDialog extends StatelessWidget {
  final Conversation conv;
  final int myId;
  final void Function(MeetupProposal) onProposed;

  const ProposeMeetupDialog({
    super.key,
    required this.conv,
    required this.myId,
    required this.onProposed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: _ProposeMeetupWizard(
        conv: conv,
        myId: myId,
        onProposed: onProposed,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  WIZARD STATE
// ─────────────────────────────────────────────────────────────────────────────

class _ProposeMeetupWizard extends StatefulWidget {
  final Conversation conv;
  final int myId;
  final void Function(MeetupProposal) onProposed;

  const _ProposeMeetupWizard({
    required this.conv,
    required this.myId,
    required this.onProposed,
  });

  @override
  State<_ProposeMeetupWizard> createState() => _ProposeMeetupWizardState();
}

class _ProposeMeetupWizardState extends State<_ProposeMeetupWizard>
    with TickerProviderStateMixin {
  // ── wizard position ──────────────────────────────────────────────────────
  int _step = 0;
  bool _goingForward = true;
  static const int _totalSteps = 4;

  // ── user selections ──────────────────────────────────────────────────────
  String _selectedSpot = kSafeSpotInfos.first.name;
  DateTime? _date;
  String? _timeSlot;
  final TextEditingController _noteCtrl = TextEditingController();
  bool _submitting = false;

  // ── animation controllers ────────────────────────────────────────────────
  late final AnimationController _progressCtrl;
  late final AnimationController _slideCtrl;
  late Animation<double> _progressAnim;

  late Animation<Offset> _slideIn;
  late Animation<Offset> _slideOut;
  late Animation<double> _fadeIn;
  late Animation<double> _fadeOut;

  // We keep two "pages" for the cross-fade/slide: current and previous.
  int _visibleStep = 0;         // the step currently painted as "current"
  int _exitingStep = -1;        // the step animating out (-1 = none)

  @override
  void initState() {
    super.initState();

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _progressAnim = Tween<double>(begin: 0, end: 1 / _totalSteps)
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic));
    _progressCtrl.forward();

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      value: 1.0, // start fully visible so step 0 isn't faded out
    );
    _rebuildSlideAnimations();
  }

  void _rebuildSlideAnimations() {
    final fwd = _goingForward;
    _slideIn = Tween<Offset>(
      begin: Offset(fwd ? 0.18 : -0.18, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(fwd ? -0.18 : 0.18, 0),
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeInCubic));

    _fadeIn  = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: const Interval(0, 0.5, curve: Curves.easeOut)));
    _fadeOut = Tween<double>(begin: 1, end: 0)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: const Interval(0, 0.4, curve: Curves.easeIn)));
  }

  Future<void> _navigateTo(int target) async {
    if (target == _step) return;
    _goingForward = target > _step;
    _exitingStep  = _step;
    _step         = target;
    _rebuildSlideAnimations();

    // Animate progress bar
    final newFrac = (target + 1) / _totalSteps;
    _progressAnim = Tween<double>(
      begin: _progressAnim.value,
      end: newFrac,
    ).animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOutCubic));
    _progressCtrl
      ..reset()
      ..forward();

    // Animate slide
    _slideCtrl.reset();
    await _slideCtrl.forward();
    if (mounted) setState(() { _visibleStep = _step; _exitingStep = -1; });
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _slideCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  SafeSpotInfo get _spotInfo =>
      kSafeSpotInfos.firstWhere((s) => s.name == _selectedSpot);

  List<String> get _timeSlots {
    final info = _spotInfo;
    return [
      for (int h = info.openHour; h < info.closeHour; h++)
        '${h % 12 == 0 ? 12 : h % 12}:00 ${h >= 12 ? 'PM' : 'AM'}'
    ];
  }

  bool get _stepValid {
    switch (_step) {
      case 0: return _selectedSpot.isNotEmpty;
      case 1: return _date != null;
      case 2: return _timeSlot != null;
      case 3: return true;
      default: return false;
    }
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[(d.weekday - 1) % 7]}, ${months[d.month - 1]} ${d.day}';
  }

  TimeOfDay _parseSlot(String slot) {
    final parts = slot.split(':');
    int h = int.parse(parts[0]);
    final rest = parts[1].split(' ');
    final m = int.parse(rest[0]);
    final ampm = rest[1];
    if (ampm == 'PM' && h != 12) h += 12;
    if (ampm == 'AM' && h == 12) h = 0;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final proposal = MeetupProposal(
      conversationId: widget.conv.id,
      proposerId:     widget.myId,
      proposerName:   'You',
      meetDate:       _date!,
      meetTime:       _parseSlot(_timeSlot!),
      safeSpot:       _selectedSpot,
      note:           _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      status:         MeetupStatus.pending,
    );
    // TODO: await proposeMeetup(...)
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pop();
    widget.onProposed(proposal);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: cBg,
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressBar(),
              Expanded(child: _buildBody()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final titles = ['Safe Spot', 'Which day?', 'What time?', 'Any notes?'];
    final subtitles = [
      'Pick a safe campus location to meet ${widget.conv.otherName}',
      'Choose a date that works',
      'Select an available slot',
      'Optional extra details',
    ];
    return Container(
      color: cNavBg,
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              key: ValueKey(_step),
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titles[_step],
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitles[_step],
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: List.generate(_totalSteps, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.only(left: 5),
                    width: i == _step ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: i == _step
                          ? Colors.white
                          : i < _step
                              ? Colors.white54
                              : Colors.white24,
                    ),
                  );
                }),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white12,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Progress bar ──────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressAnim,
      builder: (_, __) => LinearProgressIndicator(
        value: _progressAnim.value,
        minHeight: 3,
        backgroundColor: cBorder,
        valueColor: const AlwaysStoppedAnimation<Color>(cRed),
      ),
    );
  }

  // ── Body (slide transition) ───────────────────────────────────────────────

  Widget _buildBody() {
    return AnimatedBuilder(
      animation: _slideCtrl,
      builder: (ctx, _) {
        return Stack(
          children: [
            // Exiting page
            if (_exitingStep >= 0)
              FractionalTranslation(
                translation: _slideOut.value,
                child: Opacity(
                  opacity: _fadeOut.value,
                  child: _stepContent(_exitingStep),
                ),
              ),
            // Entering page
            FractionalTranslation(
              translation: _slideIn.value,
              child: Opacity(
                opacity: _fadeIn.value,
                child: _stepContent(_step),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _stepContent(int step) {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: _buildStepContent(step),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    final isLast = _step == _totalSteps - 1;
    return Container(
      decoration: BoxDecoration(
        color: cSurface,
        border: Border(top: BorderSide(color: cBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(children: [
        // Back
        if (_step > 0)
          InkWell(
            onTap: () {
              setState(() => _visibleStep = _step);
              _navigateTo(_step - 1);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 44, width: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cBorder),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 18, color: cMuted),
            ),
          )
        else
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: cMuted,
              side: const BorderSide(color: cBorder),
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 13)),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLast
                ? ElevatedButton.icon(
                    key: const ValueKey('send'),
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Send proposal',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cRed,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: cMuted,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  )
                : ElevatedButton(
                    key: const ValueKey('next'),
                    onPressed: _stepValid
                        ? () {
                            setState(() => _visibleStep = _step);
                            _navigateTo(_step + 1);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cRed,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: cMuted,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                      Text('Continue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 15),
                    ]),
                  ),
          ),
        ),
      ]),
    );
  }

  Widget _buildStepContent(int step) {
    if (step == 0) {
      return _StepWhere(
        selectedSpot: _selectedSpot,
        onSelect: (spot) => setState(() => _selectedSpot = spot),
      );
    } else if (step == 1) {
      return _StepWhen(
        selectedDate: _date,
        onSelect: (d) => setState(() => _date = d),
      );
    } else if (step == 2) {
      return _StepTime(
        timeSlots: _timeSlots,
        selectedSlot: _timeSlot,
        spotHours: _spotInfo.hours,
        onSelect: (s) => setState(() => _timeSlot = s),
      );
    } else if (step == 3) {
      return _StepNotes(
        noteCtrl: _noteCtrl,
        summary: _StepSummary(
          spot:     _selectedSpot,
          date:     _date != null ? _formatDate(_date!) : '—',
          timeSlot: _timeSlot ?? '—',
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STEP 0 — WHERE
// ─────────────────────────────────────────────────────────────────────────────

const _kSpotAssets = [
  {'name': 'Feliciano School of Business', 'image': 'assets/images/sbus.jpg'},
  {'name': 'The Quad',                     'image': 'assets/images/quad.jpg'},
  {'name': 'Sprague Library',              'image': 'assets/images/sprague.jpg'},
  {'name': 'Student Center',               'image': 'assets/images/studentcenter.jpg'},
  {'name': 'Susan A. Cole Hall',           'image': 'assets/images/colehall.jpg'},
  {'name': 'University Hall',              'image': 'assets/images/unihall.jpg'},
];

class _StepWhere extends StatelessWidget {
  final String selectedSpot;
  final void Function(String) onSelect;
  const _StepWhere({required this.selectedSpot, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemCount: _kSpotAssets.length,
      itemBuilder: (_, i) {
        final spot = _kSpotAssets[i];
        final selected = spot['name'] == selectedSpot;
        return _AnimatedSpotCard(
          name: spot['name']!,
          image: spot['image']!,
          selected: selected,
          index: i,
          onTap: () => onSelect(spot['name']!),
        );
      },
    );
  }
}

class _AnimatedSpotCard extends StatefulWidget {
  final String name, image;
  final bool selected;
  final int index;
  final VoidCallback onTap;
  const _AnimatedSpotCard({
    required this.name, required this.image, required this.selected,
    required this.index, required this.onTap,
  });
  @override
  State<_AnimatedSpotCard> createState() => _AnimatedSpotCardState();
}

class _AnimatedSpotCardState extends State<_AnimatedSpotCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double>   _entryAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entryAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutBack);
    // Stagger by index
    Future.delayed(Duration(milliseconds: 50 + widget.index * 55), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() { _entryCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _entryAnim,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: kFast,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.selected ? cRed : cBorder,
              width: widget.selected ? 2.5 : 1,
            ),
            boxShadow: widget.selected
                ? [BoxShadow(color: cRed.withValues(alpha: 0.22), blurRadius: 8, spreadRadius: 1)]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(fit: StackFit.expand, children: [
              Image.asset(
                widget.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: cRedLight,
                  child: const Icon(Icons.location_on_outlined, color: cRed, size: 32),
                ),
              ),
              // Gradient overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
              // Name
              Positioned(
                left: 8, right: 8, bottom: 7,
                child: Text(
                  widget.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w800,
                    color: Colors.white, height: 1.25,
                  ),
                ),
              ),
              // Selection overlay
              AnimatedContainer(
                duration: kFast,
                decoration: BoxDecoration(
                  color: widget.selected ? cRed.withValues(alpha: 0.18) : Colors.transparent,
                ),
              ),
              // Checkmark
              if (widget.selected)
                Positioned(
                  top: 7, right: 7,
                  child: Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(color: cRed, shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STEP 1 — WHEN (date picker)
// ─────────────────────────────────────────────────────────────────────────────

class _StepWhen extends StatefulWidget {
  final DateTime? selectedDate;
  final void Function(DateTime) onSelect;
  const _StepWhen({required this.selectedDate, required this.onSelect});
  @override
  State<_StepWhen> createState() => _StepWhenState();
}

class _StepWhenState extends State<_StepWhen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _prevMonth() {
    final now = DateTime.now();
    final prev = DateTime(_month.year, _month.month - 1);
    if (!prev.isBefore(DateTime(now.year, now.month))) {
      setState(() => _month = prev);
    }
  }

  void _nextMonth() {
    setState(() => _month = DateTime(_month.year, _month.month + 1));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // weekday: Mon=1..Sun=7, we want Sun=0 offset
    int startOffset = firstDay.weekday % 7; // Sun=0,Mon=1,...Sat=6

    const monthNames = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    const dayLabels = ['Su','Mo','Tu','We','Th','Fr','Sa'];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Month nav
      Row(children: [
        IconButton(
          onPressed: _prevMonth,
          icon: const Icon(Icons.chevron_left, color: cMuted),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        Expanded(
          child: Text(
            '${monthNames[_month.month - 1]} ${_month.year}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cText),
          ),
        ),
        IconButton(
          onPressed: _nextMonth,
          icon: const Icon(Icons.chevron_right, color: cMuted),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ]),
      const SizedBox(height: 6),
      // Day-of-week headers
      Row(
        children: dayLabels.map((d) => Expanded(
          child: Center(
            child: Text(d,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cMuted)),
          ),
        )).toList(),
      ),
      const SizedBox(height: 6),
      // Calendar grid
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: startOffset + daysInMonth,
        itemBuilder: (_, i) {
          if (i < startOffset) return const SizedBox.shrink();
          final day = DateTime(_month.year, _month.month, i - startOffset + 1);
          final isPast = day.isBefore(today);
          final isSelected = widget.selectedDate != null &&
              day.year  == widget.selectedDate!.year &&
              day.month == widget.selectedDate!.month &&
              day.day   == widget.selectedDate!.day;
          final isToday = day == today;

          return GestureDetector(
            onTap: isPast ? null : () => widget.onSelect(day),
            child: AnimatedContainer(
              duration: kFast,
              decoration: BoxDecoration(
                color: isSelected ? cRed : isToday ? cRedLight : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSelected
                    ? Border.all(color: cRed, width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? Colors.white
                        : isPast
                            ? cMuted.withValues(alpha: 0.4)
                            : cText,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STEP 2 — TIME
// ─────────────────────────────────────────────────────────────────────────────

class _StepTime extends StatelessWidget {
  final List<String> timeSlots;
  final String? selectedSlot;
  final String spotHours;
  final void Function(String) onSelect;

  const _StepTime({
    required this.timeSlots,
    required this.selectedSlot,
    required this.spotHours,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Hours hint
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cRedLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cRed.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline, size: 13, color: cRed),
          const SizedBox(width: 8),
          Expanded(child: Text(spotHours,
              style: const TextStyle(fontSize: 11, color: cRed))),
        ]),
      ),
      const SizedBox(height: 12),
      // Time grid — 3 per row
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.5,
        ),
        itemCount: timeSlots.length,
        itemBuilder: (_, i) {
          final slot = timeSlots[i];
          final sel  = slot == selectedSlot;
          return _TimeSlotChip(
            label: slot,
            selected: sel,
            index: i,
            onTap: () => onSelect(slot),
          );
        },
      ),
    ]);
  }
}

class _TimeSlotChip extends StatefulWidget {
  final String label;
  final bool selected;
  final int index;
  final VoidCallback onTap;
  const _TimeSlotChip({
    required this.label, required this.selected,
    required this.index, required this.onTap,
  });
  @override
  State<_TimeSlotChip> createState() => _TimeSlotChipState();
}

class _TimeSlotChipState extends State<_TimeSlotChip> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    Future.delayed(Duration(milliseconds: 30 + widget.index * 28), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _anim,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: kFast,
          decoration: BoxDecoration(
            color: widget.selected ? cRed : cSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.selected ? cRed : cBorder,
              width: widget.selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(widget.label,
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: widget.selected ? Colors.white : cText,
                )),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  STEP 3 — NOTES + summary
// ─────────────────────────────────────────────────────────────────────────────

class _StepSummary {
  final String spot, date, timeSlot;
  const _StepSummary({required this.spot, required this.date, required this.timeSlot});
}

class _StepNotes extends StatefulWidget {
  final TextEditingController noteCtrl;
  final _StepSummary summary;
  const _StepNotes({required this.noteCtrl, required this.summary});
  @override
  State<_StepNotes> createState() => _StepNotesState();
}

class _StepNotesState extends State<_StepNotes> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cBorder),
          ),
          child: Column(children: [
            _SummaryRow(icon: Icons.location_on_outlined, label: widget.summary.spot),
            const SizedBox(height: 8),
            _SummaryRow(icon: Icons.calendar_today_outlined, label: widget.summary.date),
            const SizedBox(height: 8),
            _SummaryRow(icon: Icons.access_time_outlined, label: widget.summary.timeSlot),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('Note (optional)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cMuted)),
        const SizedBox(height: 4),
        const Text('Where exactly should they find you?',
            style: TextStyle(fontSize: 11, color: cMuted)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cBorder),
          ),
          child: TextField(
            controller: widget.noteCtrl,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'e.g. Meet by the main entrance…',
              hintStyle: TextStyle(color: cMuted, fontSize: 13),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SummaryRow({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: cRed),
    const SizedBox(width: 10),
    Expanded(child: Text(label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cText))),
  ]);
}