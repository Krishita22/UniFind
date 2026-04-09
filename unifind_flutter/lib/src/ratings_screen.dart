part of '../main.dart';

// ── STAR DISPLAY ──────────────────────────────────────────────────────────────

class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int count;
  final double size;
  final bool showCount;
  const StarRatingDisplay({
    super.key,
    required this.rating,
    required this.count,
    this.size = 13,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final full  = rating.floor();
    final half  = (rating - full) >= 0.5;
    final empty = 5 - full - (half ? 1 : 0);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      ...List.generate(full,  (_) => Icon(Icons.star_rounded,         size: size, color: const Color(0xFFF59E0B))),
      if (half)                    Icon(Icons.star_half_rounded,       size: size, color: const Color(0xFFF59E0B)),
      ...List.generate(empty, (_) => Icon(Icons.star_outline_rounded,  size: size, color: const Color(0xFFF59E0B))),
      if (showCount) ...[
        const SizedBox(width: 4),
        Text('${rating.toStringAsFixed(1)} ($count)',
            style: TextStyle(fontSize: size - 1, color: cMuted, fontWeight: FontWeight.w600)),
      ],
    ]);
  }
}

// ── INTERACTIVE STAR PICKER ───────────────────────────────────────────────────

class _StarPicker extends StatefulWidget {
  final int initial;
  final ValueChanged<int> onChanged;
  const _StarPicker({required this.initial, required this.onChanged});
  @override
  State<_StarPicker> createState() => _StarPickerState();
}

class _StarPickerState extends State<_StarPicker> {
  late int _value;
  @override
  void initState() { super.initState(); _value = widget.initial; }
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () { setState(() => _value = i + 1); widget.onChanged(i + 1); },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              i < _value ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 36,
              color: i < _value ? const Color(0xFFF59E0B) : cBorder,
            ),
          ),
        );
      }),
    );
  }
}

// ── RATING SUBMIT DIALOG ──────────────────────────────────────────────────────

class RatingDialog extends StatefulWidget {
  final String targetName;
  final int targetUserId;
  final int conversationId;
  final int raterUserId;
  const RatingDialog({
    super.key,
    required this.targetName,
    required this.targetUserId,
    required this.conversationId,
    required this.raterUserId,
  });

  static Future<bool> show(BuildContext context, {
    required String targetName,
    required int targetUserId,
    required int conversationId,
    required int raterUserId,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(
        targetName:     targetName,
        targetUserId:   targetUserId,
        conversationId: conversationId,
        raterUserId:    raterUserId,
      ),
    );
    return result ?? false;
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int    _stars   = 0;
  String _comment = '';
  bool   _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_stars == 0) { setState(() => _error = 'Please select a star rating.'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await submitRating(
        conversationId: widget.conversationId,
        raterUserId:    widget.raterUserId,
        targetUserId:   widget.targetUserId,
        stars:          _stars,
        comment:        _comment.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: cSurface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 28),
          ),
          const SizedBox(height: 14),
          const Text('Rate your experience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cText)),
          const SizedBox(height: 6),
          Text('How was your interaction with ${widget.targetName}?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: cMuted, height: 1.4)),
          const SizedBox(height: 22),
          _StarPicker(initial: _stars, onChanged: (v) => setState(() { _stars = v; _error = null; })),
          const SizedBox(height: 6),
          Text(
            _stars == 0 ? 'Tap to rate'
                : _stars == 1 ? 'Poor' : _stars == 2 ? 'Fair'
                : _stars == 3 ? 'Good' : _stars == 4 ? 'Great' : 'Excellent!',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: _stars == 0 ? cMuted : const Color(0xFFF59E0B)),
          ),
          const SizedBox(height: 18),
          TextField(
            maxLines: 3, maxLength: 200,
            onChanged: (v) => setState(() => _comment = v),
            decoration: InputDecoration(
              hintText: 'Optional: describe your experience…',
              hintStyle: const TextStyle(color: cMuted, fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cRed, width: 2)),
              filled: true, fillColor: cBg,
              contentPadding: const EdgeInsets.all(12),
              counterStyle: const TextStyle(color: cMuted, fontSize: 11),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: cRedDark, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _loading ? null : () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: cBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Skip', style: TextStyle(color: cMuted, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cRed, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── REVIEWS BOTTOM SHEET ──────────────────────────────────────────────────────
// Shows full review list for a user — used from Profile and listing detail.

class ReviewsSheet extends StatefulWidget {
  final int userId;
  final String userName;
  const ReviewsSheet({super.key, required this.userId, required this.userName});

  static Future<void> show(BuildContext context, {required int userId, required String userName}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Reviews',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: kMid,
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return Opacity(
          opacity: curved.value,
          child: Transform.scale(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved).value,
            child: Center(child: ReviewsSheet(userId: userId, userName: userName)),
          ),
        );
      },
    );
  }

  @override
  State<ReviewsSheet> createState() => _ReviewsSheetState();
}

class _ReviewsSheetState extends State<ReviewsSheet> {
  List<Map<String, dynamic>> _reviews = [];
  double _avg = 0;
  int _count  = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final reviewData  = await getUserReviews(userId: widget.userId);
      final ratingData  = await getUserRating(userId: widget.userId);
      if (!mounted) return;
      setState(() {
        _reviews  = reviewData;
        _avg      = (ratingData['avg'] as num?)?.toDouble() ?? 0.0;
        _count    = (ratingData['count'] as num?)?.toInt() ?? 0;
        _loading  = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460, maxHeight: 520),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cBorder),
        ),
        child: Material(color: Colors.transparent, child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${widget.userName}\'s Reviews',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cText)),
                if (_count > 0) ...[
                  const SizedBox(height: 4),
                  StarRatingDisplay(rating: _avg, count: _count, size: 14),
                ],
              ])),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: cMuted)),
            ]),
          ),
          const Divider(height: 20),
          // Reviews list
          Flexible(
            child: _loading
                ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: cRed)))
                : _reviews.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.star_outline_rounded, color: cMuted, size: 40),
                          const SizedBox(height: 12),
                          Text('No reviews yet for ${widget.userName}',
                              style: const TextStyle(color: cMuted, fontSize: 14)),
                        ]),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: _reviews.length,
                        separatorBuilder: (_, __) => const Divider(height: 24),
                        itemBuilder: (_, i) => _ReviewTile(review: _reviews[i]),
                      ),
          ),
        ])),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final stars   = (review['stars'] as num?)?.toInt() ?? 0;
    final comment = review['comment']?.toString() ?? '';
    final rater   = review['rater_username']?.toString() ?? review['rater_name']?.toString() ?? 'Anonymous';
    final dateStr = review['created_at']?.toString() ?? '';
    DateTime? date = DateTime.tryParse(dateStr);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        // Stars
        Row(children: List.generate(5, (i) => Icon(
          i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16,
          color: const Color(0xFFF59E0B),
        ))),
        const Spacer(),
        if (date != null)
          Text(
            '${date.month}/${date.day}/${date.year}',
            style: const TextStyle(fontSize: 11, color: cMuted),
          ),
      ]),
      const SizedBox(height: 6),
      if (comment.isNotEmpty) ...[
        Text('"$comment"',
            style: const TextStyle(fontSize: 13, color: cText, height: 1.5)),
        const SizedBox(height: 4),
      ],
      Text('— $rater',
          style: const TextStyle(fontSize: 12, color: cMuted, fontStyle: FontStyle.italic)),
    ]);
  }
}
