part of '../main.dart';

class LostFoundScreen extends StatefulWidget {
  final List<LostFoundItem> items;
  final VoidCallback onCreateLost;
  final VoidCallback onCreateFound;
  final Future<void> Function(LostFoundItem item, ClaimEvidence evidence) onClaimLost;
  final Future<void> Function(LostFoundItem item, FoundMatchInput input) onPostFoundMatch;
  final Set<String> submittedClaimItemIds;
  final Set<String> submittedMatchItemIds;
  final String currentUserEmail;
  const LostFoundScreen({
    super.key,
    required this.items,
    required this.onCreateLost,
    required this.onCreateFound,
    required this.onClaimLost,
    required this.onPostFoundMatch,
    required this.submittedClaimItemIds,
    required this.submittedMatchItemIds,
    required this.currentUserEmail,
  });

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  String _cat = 'All';
  LostFilter _filter = LostFilter.all;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((i) {
      final cm = _cat == 'All' || i.category == _cat;
      final fm = _filter == LostFilter.all || i.type.name == _filter.name;
      final sm = i.title.toLowerCase().contains(_q.toLowerCase()) || i.description.toLowerCase().contains(_q.toLowerCase());
      return cm && fm && sm;
    }).toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lost & Found', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.5)),
              const SizedBox(height: 2),
              const Text('Help reunite students with their belongings!', style: TextStyle(fontSize: 12, color: cMuted)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _RedButton(
                      label: 'Report Lost',
                      icon: Icons.report_problem_outlined,
                      onTap: widget.onCreateLost,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RedButton(
                      label: 'Post Found',
                      icon: Icons.check_circle_outline_rounded,
                      onTap: widget.onCreateFound,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _FilterChip(label: 'All', selected: _filter == LostFilter.all, onTap: () => setState(() => _filter = LostFilter.all)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Lost', selected: _filter == LostFilter.lost, onTap: () => setState(() => _filter = LostFilter.lost), color: const Color(0xFFE74C3C)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Found', selected: _filter == LostFilter.found, onTap: () => setState(() => _filter = LostFilter.found), color: const Color(0xFF27AE60)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: _SearchField(hint: 'Search lost & found...', onChanged: (v) => setState(() => _q = v)),
        ),
        SizedBox(
          height: 28,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Chip(
                  label: 'All',
                  selected: _cat == 'All',
                  onTap: () => setState(() => _cat = 'All'),
                ),
              ),
              ...categories.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _Chip(label: c, selected: _cat == c, onTap: () => setState(() => _cat = c)),
              )),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: filtered.isEmpty
              ? const _EmptyState(message: 'No items found')
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _LostFoundCard(
                    item: filtered[i],
                    onClaim: (evidence) => widget.onClaimLost(filtered[i], evidence),
                    onPostFoundMatch: (input) => widget.onPostFoundMatch(filtered[i], input),
                    claimSubmittedByMe: widget.submittedClaimItemIds.contains(filtered[i].id),
                    matchSubmittedByMe: widget.submittedMatchItemIds.contains(filtered[i].id),
                    currentUserEmail: widget.currentUserEmail,
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Lost & Found item popup ────────────────────────────────────────────────────
void _showLostFoundPopup(
  BuildContext context,
  LostFoundItem item, {
  required Future<void> Function(ClaimEvidence) onClaim,
  required Future<void> Function(FoundMatchInput) onPostFoundMatch,
  required bool claimSubmittedByMe,
  required bool matchSubmittedByMe,
}) {
  final isLost = item.type == LostFoundType.lost;
  final typeColor = isLost ? const Color(0xFFE74C3C) : const Color(0xFF27AE60);
  final typeBg   = isLost ? const Color(0xFFFDECEC) : const Color(0xFFECF9F0);

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'LF Item',
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
              constraints: const BoxConstraints(maxWidth: 460, maxHeight: 580),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image header
                      Stack(
                        children: [
                          Image.network(
                            item.image,
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 160,
                              color: cPlaceholder,
                              child: const Center(child: Icon(Icons.image_not_supported, color: cMuted, size: 36)),
                            ),
                          ),
                          Positioned(
                            top: 10, left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: typeColor.withValues(alpha: 0.4))),
                              child: Text(isLost ? 'Lost' : 'Found',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: typeColor)),
                            ),
                          ),
                          Positioned(
                            top: 8, right: 8,
                            child: GestureDetector(
                              onTap: () => Navigator.of(ctx).pop(),
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.3)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _LFPopupChip(icon: Icons.category_outlined, label: item.category),
                                  _LFPopupChip(icon: Icons.location_on_outlined, label: item.location),
                                  _LFPopupChip(icon: Icons.person_outline_rounded, label: item.poster),
                                  _LFPopupChip(icon: Icons.access_time_rounded, label: formatDate(item.createdAt)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(item.description, style: const TextStyle(fontSize: 13, color: cMuted, height: 1.55)),
                              const SizedBox(height: 16),
                              // Action button inside popup
                              if (!isLost)
                                _LFActionButton(
                                  label: item.status.toLowerCase() == 'claimed'
                                      ? 'Already Claimed'
                                      : claimSubmittedByMe
                                          ? 'Claim Submitted'
                                          : 'Claim This Item',
                                  icon: item.status.toLowerCase() == 'claimed'
                                      ? Icons.check_circle_outline_rounded
                                      : claimSubmittedByMe
                                          ? Icons.mark_email_read_outlined
                                          : Icons.volunteer_activism_outlined,
                                  color: const Color(0xFFE74C3C),
                                  disabled: item.status.toLowerCase() == 'claimed' || claimSubmittedByMe,
                                  onTap: () async {
                                    Navigator.of(ctx).pop();
                                  },
                                ),
                              if (isLost)
                                _LFActionButton(
                                  label: matchSubmittedByMe ? 'Match Submitted' : 'I Found This Item',
                                  icon: matchSubmittedByMe ? Icons.check_circle_outline_rounded : Icons.add_circle_outline_rounded,
                                  color: const Color(0xFF27AE60),
                                  disabled: matchSubmittedByMe,
                                  onTap: () async {
                                    Navigator.of(ctx).pop();
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _LFPopupChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _LFPopupChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(7), border: Border.all(color: cBorder)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: cMuted),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted)),
        ],
      ),
    );
  }
}

class _LFActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool disabled;
  final VoidCallback onTap;

  const _LFActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: disabled ? null : onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: disabled ? cBorder : color.withValues(alpha: 0.6)),
          foregroundColor: disabled ? cMuted : color,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _LostFoundCard extends StatefulWidget {
  final LostFoundItem item;
  final Future<void> Function(ClaimEvidence evidence) onClaim;
  final Future<void> Function(FoundMatchInput input) onPostFoundMatch;
  final bool claimSubmittedByMe;
  final bool matchSubmittedByMe;
  final String currentUserEmail;
  const _LostFoundCard({
    required this.item,
    required this.onClaim,
    required this.onPostFoundMatch,
    required this.claimSubmittedByMe,
    required this.matchSubmittedByMe,
    required this.currentUserEmail,
  });

  @override
  State<_LostFoundCard> createState() => _LostFoundCardState();
}

class _LostFoundCardState extends State<_LostFoundCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  bool _claiming = false;
  bool _postingMatch = false;
  final _proofCtrl = TextEditingController();
  final _identCtrl = TextEditingController();
  final _lastSeenCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _foundWhereCtrl = TextEditingController();
  final _foundWhenCtrl = TextEditingController();
  final _foundDetailsCtrl = TextEditingController();
  final _foundContactCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kFast);
    _scale = Tween(begin: 1.0, end: 0.98).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    _proofCtrl.dispose();
    _identCtrl.dispose();
    _lastSeenCtrl.dispose();
    _contactCtrl.dispose();
    _foundWhereCtrl.dispose();
    _foundWhenCtrl.dispose();
    _foundDetailsCtrl.dispose();
    _foundContactCtrl.dispose();
    super.dispose();
  }

  Future<T?> _openCenteredDialog<T>(
    Widget Function(BuildContext ctx, StateSetter setModalState) childBuilder,
  ) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: kMid,
      pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        return Opacity(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut).value,
          child: Transform.scale(
            scale: Tween<double>(begin: 0.94, end: 1.0)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic))
                .value,
            child: StatefulBuilder(
              builder: (ctx, setModalState) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: EdgeInsets.fromLTRB(
                      16, 16, 16,
                      MediaQuery.of(ctx).viewInsets.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: cSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cBorder),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: childBuilder(ctx, setModalState),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<ClaimEvidence?> _openClaimSheet() async {
    _proofCtrl.clear(); _identCtrl.clear(); _lastSeenCtrl.clear(); _contactCtrl.clear();
    String? error;
    return _openCenteredDialog<ClaimEvidence>((ctx, setModalState) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Claim This Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Provide details to prove ownership. This will be sent for verification.', style: TextStyle(fontSize: 12, color: cMuted)),
            const SizedBox(height: 12),
            TextField(controller: _proofCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Proof details *', hintText: 'Describe unique marks, contents, serial details...')),
            const SizedBox(height: 10),
            TextField(controller: _identCtrl, decoration: const InputDecoration(labelText: 'Identifying details', hintText: 'Color, brand, stickers, initials, etc.')),
            const SizedBox(height: 10),
            TextField(controller: _lastSeenCtrl, decoration: const InputDecoration(labelText: 'Where/when you lost it')),
            const SizedBox(height: 10),
            TextField(controller: _contactCtrl, decoration: const InputDecoration(labelText: 'Preferred contact note', hintText: 'Best time to reach you, alternate handle, etc.')),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: cRedDark, fontSize: 12)),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _AuthButton(
                loading: false,
                label: 'Submit Claim',
                onTap: () {
                  final proof = _proofCtrl.text.trim();
                  if (proof.length < 12) {
                    setModalState(() => error = 'Please add more proof details (at least 12 characters).');
                    return;
                  }
                  Navigator.of(ctx).pop(ClaimEvidence(
                    proofDetails: proof,
                    identifyingDetails: _identCtrl.text.trim(),
                    lastSeenContext: _lastSeenCtrl.text.trim(),
                    contactNote: _contactCtrl.text.trim(),
                  ));
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<FoundMatchInput?> _openFoundMatchSheet() async {
    _foundWhereCtrl.clear(); _foundWhenCtrl.clear(); _foundDetailsCtrl.clear(); _foundContactCtrl.clear();
    String? error;
    return _openCenteredDialog<FoundMatchInput>((ctx, setModalState) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Match', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Submit a match request for "${widget.item.title}".', style: const TextStyle(fontSize: 12, color: cMuted)),
            const SizedBox(height: 12),
            TextField(controller: _foundWhereCtrl, decoration: const InputDecoration(labelText: 'Where did you find it? *')),
            const SizedBox(height: 10),
            TextField(controller: _foundWhenCtrl, decoration: const InputDecoration(labelText: 'When did you find it? *', hintText: 'e.g. Today 2PM')),
            const SizedBox(height: 10),
            TextField(controller: _foundDetailsCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Matching details *', hintText: 'Describe how this matches the lost item...')),
            const SizedBox(height: 10),
            TextField(controller: _foundContactCtrl, decoration: const InputDecoration(labelText: 'Contact note')),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: cRedDark, fontSize: 12)),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _AuthButton(
                loading: false,
                label: 'Submit Match',
                onTap: () {
                  final where = _foundWhereCtrl.text.trim();
                  final when = _foundWhenCtrl.text.trim();
                  final details = _foundDetailsCtrl.text.trim();
                  if (where.isEmpty) { setModalState(() => error = 'Please enter where you found it.'); return; }
                  if (when.isEmpty) { setModalState(() => error = 'Please enter when you found it.'); return; }
                  if (details.isEmpty) { setModalState(() => error = 'Please enter matching details.'); return; }
                  if (details.length < 8) { setModalState(() => error = 'Matching details must be at least 8 characters.'); return; }
                  Navigator.of(ctx).pop(FoundMatchInput(
                    foundLocation: where,
                    foundWhen: when,
                    matchDetails: details,
                    contactNote: _foundContactCtrl.text.trim(),
                  ));
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLost = widget.item.type == LostFoundType.lost;
    final isClaimed = widget.item.status.toLowerCase() == 'claimed';
    final isSubmitted = widget.claimSubmittedByMe;
    final isMatchSubmitted = widget.matchSubmittedByMe;
    final typeColor = isLost ? const Color(0xFFE74C3C) : const Color(0xFF27AE60);
    final typeBg = isLost ? const Color(0xFFFDECEC) : const Color(0xFFECF9F0);

    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        // Tap the card to open popup
        _showLostFoundPopup(
          context,
          widget.item,
          onClaim: widget.onClaim,
          onPostFoundMatch: widget.onPostFoundMatch,
          claimSubmittedByMe: isSubmitted,
          matchSubmittedByMe: isMatchSubmitted,
        );
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cBorder),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.item.image,
                  width: 72, height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 72, height: 72, child: ColoredBox(color: cPlaceholder, child: Center(child: Icon(Icons.image_not_supported, color: cMuted, size: 20)))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(widget.item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cText), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(8)),
                          child: Text(isLost ? 'Lost' : 'Found', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: typeColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(widget.item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: cMuted, height: 1.5)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 11, color: cMuted),
                        const SizedBox(width: 3),
                        Expanded(child: Text('${widget.item.location} · ${widget.item.poster} · ${formatDate(widget.item.createdAt)}', style: const TextStyle(fontSize: 11, color: cMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Action buttons inline (still available from card directly)
                    if (!isLost)
                      SizedBox(
                        height: 28,
                        child: OutlinedButton.icon(
                          onPressed: isClaimed || _claiming || isSubmitted
                              ? null
                              : () async {
                                  final evidence = await _openClaimSheet();
                                  if (evidence == null) return;
                                  setState(() => _claiming = true);
                                  try { await widget.onClaim(evidence); }
                                  finally { if (mounted) setState(() => _claiming = false); }
                                },
                          icon: _claiming
                              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(isClaimed ? Icons.check_circle_outline_rounded : isSubmitted ? Icons.mark_email_read_outlined : Icons.volunteer_activism_outlined, size: 13),
                          label: Text(isClaimed ? 'Claimed' : isSubmitted ? 'Submitted' : 'Claim', style: const TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            side: BorderSide(color: isClaimed ? cBorder : const Color(0xFFE74C3C).withValues(alpha: 0.35)),
                            foregroundColor: isClaimed ? cMuted : const Color(0xFFE74C3C),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    if (isLost)
                      SizedBox(
                        height: 28,
                        child: OutlinedButton.icon(
                          onPressed: _postingMatch || isMatchSubmitted
                              ? null
                              : () async {
                                  final input = await _openFoundMatchSheet();
                                  if (input == null) return;
                                  setState(() => _postingMatch = true);
                                  try { await widget.onPostFoundMatch(input); }
                                  finally { if (mounted) setState(() => _postingMatch = false); }
                                },
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 13),
                          label: Text(isMatchSubmitted ? 'Submitted' : _postingMatch ? 'Posting...' : 'Match', style: const TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            side: BorderSide(color: const Color(0xFF27AE60).withValues(alpha: 0.35)),
                            foregroundColor: const Color(0xFF27AE60),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                    // ── Report button ──
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.flag_outlined, size: 13),
                        label: const Text('Report'),
                        style: TextButton.styleFrom(
                          foregroundColor: cMuted,
                          textStyle: const TextStyle(fontSize: 11),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        ),
                        onPressed: () => showReportDialog(
                          context: context,
                          targetId: widget.item.id,
                          targetType: 'lostfound',
                          targetTitle: widget.item.title,
                          reporterEmail: widget.currentUserEmail,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}