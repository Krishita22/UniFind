part of '../main.dart';

// ─── STAR DISPLAY WIDGET ──────────────────────────────────────────────────────
// Used anywhere a user's rating needs to be shown (marketplace cards,
// lost & found cards, item detail screen).

class StarRatingDisplay extends StatelessWidget {
  final double rating;    // 1.0 – 5.0
  final int count;        // number of ratings
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(full,  (_) => Icon(Icons.star_rounded,            size: size, color: const Color(0xFFF59E0B))),
        if (half)                     Icon(Icons.star_half_rounded,         size: size, color: const Color(0xFFF59E0B)),
        ...List.generate(empty, (_) => Icon(Icons.star_outline_rounded,    size: size, color: const Color(0xFFF59E0B))),
        if (showCount) ...[
          const SizedBox(width: 4),
          Text('${rating.toStringAsFixed(1)} ($count)',
              style: TextStyle(fontSize: size - 1, color: cMuted, fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }
}

// ─── INTERACTIVE STAR PICKER ──────────────────────────────────────────────────

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
        final filled = i < _value;
        return GestureDetector(
          onTap: () {
            setState(() => _value = i + 1);
            widget.onChanged(i + 1);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 36,
              color: filled ? const Color(0xFFF59E0B) : cBorder,
            ),
          ),
        );
      }),
    );
  }
}

// ─── RATING SUBMISSION DIALOG ─────────────────────────────────────────────────
// Shown after a conversation is marked complete. Both participants see it.

class RatingDialog extends StatefulWidget {
  /// The user being rated.
  final String targetName;
  final int targetUserId;

  /// The conversation this rating is tied to.
  final int conversationId;

  /// The user submitting the rating.
  final int raterUserId;

  const RatingDialog({
    super.key,
    required this.targetName,
    required this.targetUserId,
    required this.conversationId,
    required this.raterUserId,
  });

  /// Open the dialog and return true if a rating was submitted.
  static Future<bool> show(
    BuildContext context, {
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
    if (_stars == 0) {
      setState(() => _error = 'Please select a star rating.');
      return;
    }
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 28),
            ),
            const SizedBox(height: 14),
            const Text('Rate your experience',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cText)),
            const SizedBox(height: 6),
            Text('How was your interaction with ${widget.targetName}?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: cMuted, height: 1.4)),
            const SizedBox(height: 22),

            // Star picker
            _StarPicker(
              initial: _stars,
              onChanged: (v) => setState(() { _stars = v; _error = null; }),
            ),
            const SizedBox(height: 6),
            Text(
              _stars == 0 ? 'Tap to rate'
                  : _stars == 1 ? 'Poor'
                  : _stars == 2 ? 'Fair'
                  : _stars == 3 ? 'Good'
                  : _stars == 4 ? 'Great'
                  : 'Excellent!',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _stars == 0 ? cMuted : const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 18),

            // Optional comment
            TextField(
              maxLines: 3,
              maxLength: 200,
              onChanged: (v) => setState(() => _comment = v),
              decoration: InputDecoration(
                hintText: 'Optional: describe your experience…',
                hintStyle: const TextStyle(color: cMuted, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: cBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: cBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: cRed, width: 2),
                ),
                filled: true,
                fillColor: cBg,
                contentPadding: const EdgeInsets.all(12),
                counterStyle: const TextStyle(color: cMuted, fontSize: 11),
              ),
            ),

            // Error
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: cRedDark, fontSize: 12)),
            ],

            const SizedBox(height: 20),

            // Buttons
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
                    backgroundColor: cRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _loading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
