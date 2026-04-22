part of '../main.dart';

/// Tiny immutable pair used by `_ItemDetailScreenState._requireBuyerContext`
/// to hand back both IDs in one value. A plain class rather than a record so
/// the Dart SDK floor declared in pubspec.yaml (>=2.18) still compiles.
class _BuyerContext {
  final int myId;
  final int sellerId;
  const _BuyerContext({required this.myId, required this.sellerId});
}

class ItemDetailScreen extends StatefulWidget {
  final MarketplaceItem item;
  final String currentUserEmail;
  final int? currentUserId;
  const ItemDetailScreen({
    super.key,
    required this.item,
    required this.currentUserEmail,
    this.currentUserId,
  });
  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool _startingChat = false;
  bool _submittingOffer = false;
  double? _sellerRating;
  int _sellerRatingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSellerRating();
  }

  Future<void> _loadSellerRating() async {
    final sid = widget.item.sellerId;
    if (sid == null) return;
    try {
      final data = await getUserRating(userId: sid);
      if (!mounted) return;
      setState(() {
        _sellerRating      = (data['avg'] as num?)?.toDouble() ?? 0.0;
        _sellerRatingCount = (data['count'] as num?)?.toInt() ?? 0;
      });
    } catch (_) {}
  }

  String _asSellerUsername() {
    final raw = widget.item.seller.trim();
    if (raw.isEmpty || raw.contains('@') || raw.contains(' ')) return 'Student';
    return raw;
  }

  /// Validate preconditions for any buyer-initiated action (chat or offer).
  /// Returns a `_BuyerContext` if the user may proceed, otherwise shows a
  /// snackbar and returns null. A tiny private class (rather than a Dart 3
  /// record) keeps this compatible with the SDK floor in pubspec.yaml.
  _BuyerContext? _requireBuyerContext() {
    final myId     = widget.currentUserId;
    final sellerId = widget.item.sellerId;
    if (myId == null || sellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User info unavailable.'),
          behavior: SnackBarBehavior.floating));
      return null;
    }
    if (myId == sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('This is your own listing.'),
          behavior: SnackBarBehavior.floating));
      return null;
    }
    return _BuyerContext(myId: myId, sellerId: sellerId);
  }

  Future<void> _makeOfferFlow() async {
    final ctx = _requireBuyerContext();
    if (ctx == null) return;

    final listingId = int.tryParse(widget.item.id) ?? 0;
    if (listingId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not determine listing ID.'),
          behavior: SnackBarBehavior.floating));
      return;
    }

    final result = await showModalBottomSheet<_OfferFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MakeOfferSheet(
        listingTitle: widget.item.title,
        listingPrice: widget.item.price,
      ),
    );
    if (result == null || !mounted) return;

    setState(() => _submittingOffer = true);
    try {
      await makeOffer(
        listingId:   listingId,
        senderId:    ctx.myId,
        recipientId: ctx.sellerId,
        amount:      result.amount,
        note:        result.note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Offer of \$${result.amount.toStringAsFixed(2)} sent to ${_asSellerUsername()}.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cRed));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Offer failed: ${e.message}'),
          behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Offer failed: $e'),
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _submittingOffer = false);
    }
  }

  Future<void> _contactSeller() async {
    final ctx = _requireBuyerContext();
    if (ctx == null) return;
    setState(() => _startingChat = true);
    try {
      final result = await startConversation(
        listingId: int.tryParse(widget.item.id) ?? 0,
        user1Id:   ctx.myId,
        user2Id:   ctx.sellerId,
        subject:   'Interested in: ${widget.item.title}',
      );
      final convId = int.tryParse(result['id']?.toString() ?? '') ?? 0;
      if (convId <= 0) throw Exception('Invalid conversation ID.');
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ConversationScreen(
          conv: Conversation(
            id:        convId,
            subject:   'Interested in: ${widget.item.title}',
            otherName: _asSellerUsername(),
otherFirstName: '',
            otherEmail: '',
            otherId:   ctx.sellerId,
            unread:    0,
          ),
          myId: ctx.myId,
        ),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not open chat: $e'),
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _startingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: CustomScrollView(
        slivers: [
          // -- Hero image app bar --
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: cNavBg,
            elevation: 0,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                tooltip: 'Options',
                onSelected: (value) {
                  if (value == 'report_listing') {
                    showReportDialog(
                      context: context,
                      targetId: widget.item.id,
                      targetType: 'listing',
                      targetTitle: widget.item.title,
                      reporterEmail: widget.currentUserEmail,
                    );
                  } else if (value == 'report_user') {
                    showReportDialog(
                      context: context,
                      targetId: widget.item.sellerEmail.isNotEmpty
                          ? widget.item.sellerEmail
                          : widget.item.id,
                      targetType: 'user',
                      targetTitle: '@${_asSellerUsername()}',
                      reporterEmail: widget.currentUserEmail,
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'report_listing',
                    child: Row(children: [
                      Icon(Icons.flag_outlined, size: 15, color: cRed),
                      SizedBox(width: 10),
                      Text('Report Listing',
                          style: TextStyle(fontSize: 13)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'report_user',
                    child: Row(children: [
                      Icon(Icons.person_off_outlined, size: 15, color: cRed),
                      SizedBox(width: 10),
                      Text('Report Seller',
                          style: TextStyle(fontSize: 13)),
                    ]),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                widget.item.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: cPlaceholder,
                  child: Center(
                    child: Icon(Icons.image_not_supported,
                        size: 42, color: cMuted),
                  ),
                ),
              ),
            ),
          ),

          // -- Content --
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price + category badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '\$${widget.item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: cRed,
                          letterSpacing: -1,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: cRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.item.category.toUpperCase(),
                          style: const TextStyle(
                            color: cRed,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Title
                  Text(
                    widget.item.title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: cText,
                      letterSpacing: -0.3,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Seller + posted date inline
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 13, color: cMuted),
                      const SizedBox(width: 4),
                      Text(
                        _asSellerUsername(),
                        style: const TextStyle(
                            fontSize: 12,
                            color: cMuted,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.circle, size: 3, color: cMuted),
                      const SizedBox(width: 10),
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: cMuted),
                      const SizedBox(width: 4),
                      Text(
                        formatDate(widget.item.createdAt),
                        style: const TextStyle(
                            fontSize: 12,
                            color: cMuted,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Condition + location chips row
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.stars_rounded,
                        label: widget.item.condition,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.location_on_outlined,
                        label: widget.item.location,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Divider(height: 1, color: cBorder),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: cText,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: cMuted,
                      height: 1.75,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Seller rating display + view reviews link
                  if (_sellerRatingCount > 0) ...[
                    GestureDetector(
                      onTap: () => ReviewsSheet.show(
                        context,
                        userId:   widget.item.sellerId!,
                        userName: _asSellerUsername(),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                          const SizedBox(width: 8),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            StarRatingDisplay(
                              rating: _sellerRating!,
                              count:  _sellerRatingCount,
                              size:   13,
                            ),
                            const SizedBox(height: 2),
                            const Text('Tap to view all reviews',
                                style: TextStyle(fontSize: 11, color: cMuted)),
                          ]),
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded, color: cMuted, size: 18),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Contact Seller button
                  GestureDetector(
                    onTap: _startingChat ? null : _contactSeller,
                    child: AnimatedContainer(
                      duration: kFast,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _startingChat ? cMuted : cRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: _startingChat
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.message_rounded, color: Colors.white, size: 17),
                                  SizedBox(width: 8),
                                  Text('Contact Seller',
                                    style: TextStyle(color: Colors.white, fontSize: 14,
                                        fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Make Offer button — opens a bottom sheet for amount + note.
                  // Disabled if we're still submitting a previous offer, or if
                  // this is the user's own listing (handled inside the flow).
                  GestureDetector(
                    onTap: _submittingOffer ? null : _makeOfferFlow,
                    child: AnimatedContainer(
                      duration: kFast,
                      height: 48,
                      decoration: BoxDecoration(
                        color: cSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cRed, width: 1.5),
                      ),
                      child: Center(
                        child: _submittingOffer
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(color: cRed, strokeWidth: 2))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_offer_outlined, color: cRed, size: 17),
                                  SizedBox(width: 8),
                                  Text('Make an Offer',
                                    style: TextStyle(color: cRed, fontSize: 14,
                                        fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Small pill chip for condition / location --
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: cRed),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cText,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MAKE-OFFER BOTTOM SHEET ────────────────────────────────────────────────
//
// The sheet pops up when the buyer taps "Make an Offer" on an item detail
// page. It collects an amount and an optional note, runs client-side
// validation, and pops with an _OfferFormResult the caller can submit via
// makeOffer(). The sheet itself does NOT call the API — keeping network
// work in the parent keeps error handling in one place.

class _OfferFormResult {
  final double amount;
  final String? note;
  const _OfferFormResult({required this.amount, this.note});
}

class MakeOfferSheet extends StatefulWidget {
  final String listingTitle;
  final double listingPrice;

  /// If set, this sheet is being used to COUNTER an incoming offer rather
  /// than to make an opener. Changes labels and helper text accordingly.
  final double? counteringAmount;

  const MakeOfferSheet({
    super.key,
    required this.listingTitle,
    required this.listingPrice,
    this.counteringAmount,
  });

  @override
  State<MakeOfferSheet> createState() => _MakeOfferSheetState();
}

class _MakeOfferSheetState extends State<MakeOfferSheet> {
  final _amountCtl = TextEditingController();
  final _noteCtl   = TextEditingController();
  String? _error;

  bool get _isCounter => widget.counteringAmount != null;

  @override
  void dispose() {
    _amountCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _amountCtl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Enter an amount.');
      return;
    }
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      setState(() => _error = 'Amount must be a number.');
      return;
    }
    // Backend caps at 9,999,999.99; mirror that here to fail fast.
    if (parsed <= 0 || parsed > 9999999.99) {
      setState(() => _error = 'Amount must be greater than 0.');
      return;
    }
    Navigator.of(context).pop(_OfferFormResult(
      amount: double.parse(parsed.toStringAsFixed(2)),
      note:   _noteCtl.text.trim().isEmpty ? null : _noteCtl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Give the sheet enough room even when the keyboard is open.
    final insets = MediaQuery.of(context).viewInsets.bottom;
    final title  = _isCounter ? 'Counter Offer' : 'Make an Offer';
    final listed = widget.listingPrice.toStringAsFixed(2);

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: Container(
        decoration: const BoxDecoration(
          color: cSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: cBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cText)),
            const SizedBox(height: 4),
            Text(widget.listingTitle,
                style: const TextStyle(fontSize: 13, color: cMuted),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 14),
            // Context line: listed price; for counters, show the amount we're answering.
            Row(children: [
              const Icon(Icons.sell_outlined, size: 14, color: cMuted),
              const SizedBox(width: 6),
              Text('Listed at \$$listed',
                  style: const TextStyle(fontSize: 12, color: cMuted, fontWeight: FontWeight.w600)),
              if (_isCounter) ...[
                const SizedBox(width: 14),
                const Icon(Icons.swap_horiz_rounded, size: 14, color: cRed),
                const SizedBox(width: 4),
                Text('Their offer: \$${widget.counteringAmount!.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: cRed, fontWeight: FontWeight.w700)),
              ],
            ]),
            const SizedBox(height: 18),
            TextField(
              controller: _amountCtl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: _isCounter ? 'Your counter-offer (USD)' : 'Your offer (USD)',
                prefixText: '\$ ',
                prefixStyle: const TextStyle(fontSize: 16, color: cText, fontWeight: FontWeight.w700),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: cRed, width: 2),
                ),
              ),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtl,
              maxLines: 3,
              minLines: 2,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Mention condition questions, pickup details, etc.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: cRed, width: 2),
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(_error!, style: const TextStyle(color: cRed, fontSize: 12)),
            ],
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: cBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(color: cMuted, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_isCounter ? 'Send Counter' : 'Send Offer',
                      style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
