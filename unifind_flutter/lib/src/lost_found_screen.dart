part of '../main.dart';

class LostFoundScreen extends StatefulWidget {
  final List<LostFoundItem> items;
  final VoidCallback onCreateLost;
  final VoidCallback onCreateFound;
  final Future<void> Function(LostFoundItem item, ClaimEvidence evidence) onClaimLost;
  final Future<void> Function(LostFoundItem item, FoundMatchInput input) onPostFoundMatch;
  final Set<String> submittedClaimItemIds;
  final Set<String> submittedMatchItemIds;
  const LostFoundScreen({
    super.key,
    required this.items,
    required this.onCreateLost,
    required this.onCreateFound,
    required this.onClaimLost,
    required this.onPostFoundMatch,
    required this.submittedClaimItemIds,
    required this.submittedMatchItemIds,
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
                  ),
                ),
        ),
      ],
    );
  }
}

class _LostFoundCard extends StatefulWidget {
  final LostFoundItem item;
  final Future<void> Function(ClaimEvidence evidence) onClaim;
  final Future<void> Function(FoundMatchInput input) onPostFoundMatch;
  final bool claimSubmittedByMe;
  final bool matchSubmittedByMe;
  const _LostFoundCard({
    required this.item,
    required this.onClaim,
    required this.onPostFoundMatch,
    required this.claimSubmittedByMe,
    required this.matchSubmittedByMe,
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
                      16,
                      16,
                      16,
                      MediaQuery.of(ctx).viewInsets.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: cSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
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
    _proofCtrl.clear();
    _identCtrl.clear();
    _lastSeenCtrl.clear();
    _contactCtrl.clear();

    String? error;
    return _openCenteredDialog<ClaimEvidence>((ctx, setModalState) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  const Text(
                    'Claim This Item',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Provide details to prove ownership. This will be sent for verification.',
                    style: TextStyle(fontSize: 12, color: cMuted),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _proofCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Proof details *',
                      hintText: 'Describe unique marks, contents, serial details...',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _identCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Identifying details',
                      hintText: 'Color, brand, stickers, initials, etc.',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _lastSeenCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Where/when you lost it',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _contactCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Preferred contact note',
                      hintText: 'Best time to reach you, alternate handle, etc.',
                    ),
                  ),
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
                        Navigator.of(ctx).pop(
                          ClaimEvidence(
                            proofDetails: proof,
                            identifyingDetails: _identCtrl.text.trim(),
                            lastSeenContext: _lastSeenCtrl.text.trim(),
                            contactNote: _contactCtrl.text.trim(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
    });
  }

  Future<FoundMatchInput?> _openFoundMatchSheet() async {
    _foundWhereCtrl.clear();
    _foundWhenCtrl.clear();
    _foundDetailsCtrl.clear();
    _foundContactCtrl.clear();
    String? error;

    return _openCenteredDialog<FoundMatchInput>((ctx, setModalState) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  const Text('Match', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    'Submit a match request for "${widget.item.title}".',
                    style: const TextStyle(fontSize: 12, color: cMuted),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _foundWhereCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Where did you find it? *',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _foundWhenCtrl,
                    decoration: const InputDecoration(
                      labelText: 'When did you find it? *',
                      hintText: 'e.g. Today 2PM',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _foundDetailsCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Matching details *',
                      hintText: 'Describe how this matches the lost item...',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _foundContactCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Contact note',
                    ),
                  ),
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
                        if (where.isEmpty) {
                          setModalState(() => error = 'Please enter where you found it.');
                          return;
                        }
                        if (when.isEmpty) {
                          setModalState(() => error = 'Please enter when you found it.');
                          return;
                        }
                        if (details.isEmpty) {
                          setModalState(() => error = 'Please enter matching details.');
                          return;
                        }
                        if (details.length < 8) {
                          setModalState(() => error = 'Matching details must be at least 8 characters.');
                          return;
                        }
                        Navigator.of(ctx).pop(
                          FoundMatchInput(
                            foundLocation: where,
                            foundWhen: when,
                            matchDetails: details,
                            contactNote: _foundContactCtrl.text.trim(),
                          ),
                        );
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
      onTapUp: (_) => _c.reverse(),
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
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 80, height: 80, child: ColoredBox(color: cPlaceholder, child: Center(child: Icon(Icons.image_not_supported, color: cMuted)))),
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
                    if (!isLost) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 30,
                        child: OutlinedButton.icon(
                          onPressed: isClaimed || _claiming
                              || isSubmitted
                              ? null
                              : () async {
                                  final evidence = await _openClaimSheet();
                                  if (evidence == null) return;
                                  setState(() => _claiming = true);
                                  try {
                                    await widget.onClaim(evidence);
                                  } finally {
                                    if (mounted) setState(() => _claiming = false);
                                  }
                                },
                          icon: _claiming
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  isClaimed
                                      ? Icons.check_circle_outline_rounded
                                      : isSubmitted
                                          ? Icons.mark_email_read_outlined
                                      : Icons.volunteer_activism_outlined,
                                  size: 14,
                                ),
                          label: Text(isClaimed ? 'Claimed' : isSubmitted ? 'Submitted' : 'Claim'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            side: BorderSide(
                              color: isClaimed
                                  ? cBorder
                                  : const Color(0xFFE74C3C).withValues(alpha: 0.35),
                            ),
                            foregroundColor: isClaimed
                                ? cMuted
                                : const Color(0xFFE74C3C),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (isLost) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 30,
                        child: OutlinedButton.icon(
                          onPressed: _postingMatch || isMatchSubmitted
                              ? null
                              : () async {
                                  final input = await _openFoundMatchSheet();
                                  if (input == null) return;
                                  setState(() => _postingMatch = true);
                                  try {
                                    await widget.onPostFoundMatch(input);
                                  } finally {
                                    if (mounted) setState(() => _postingMatch = false);
                                  }
                                },
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
                          label: Text(
                            isMatchSubmitted
                                ? 'Submitted'
                                : _postingMatch
                                    ? 'Posting...'
                                    : 'Match',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            side: BorderSide(
                              color: const Color(0xFF27AE60).withValues(alpha: 0.35),
                            ),
                            foregroundColor: const Color(0xFF27AE60),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
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
