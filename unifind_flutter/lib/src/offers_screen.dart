part of '../main.dart';

// ─── OFFERS SCREEN ───────────────────────────────────────────────────────────
//
// Negotiation center. Two tabs:
//   - "Received"  : offers where the user is the recipient. Pending rows get
//                   Accept / Reject / Counter actions. Non-pending rows are
//                   shown as historical cards with their terminal status.
//   - "Sent"      : offers the user created. Pending rows get a Withdraw
//                   action; everything else is historical.
//
// The screen pulls both lists in parallel via api_service.getOffers() and
// re-fetches on pull-to-refresh or after any action completes, so the UI
// stays consistent with server state rather than trying to locally mutate.
//
// Tapping a row from either tab opens OfferThreadScreen, which shows the full
// counter-chain (opener + all counters) in chronological order.

class OffersScreen extends StatefulWidget {
  final int userId;
  const OffersScreen({super.key, required this.userId});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Offer> _received = const [];
  List<Offer> _sent     = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    markOffersSeen(userId: widget.userId);
    try {
      final results = await Future.wait([
        getOffers(userId: widget.userId, filter: 'received'),
        getOffers(userId: widget.userId, filter: 'sent'),
      ]);
      if (!mounted) return;
      setState(() {
        _received = results[0];
        _sent     = results[1];
        _loading  = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  int _pendingCount(List<Offer> rows) =>
      rows.where((o) => o.isPending).length;

  @override
  Widget build(BuildContext context) {
    final pendingReceived = _pendingCount(_received);
    final pendingSent     = _pendingCount(_sent);

    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Offers',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: cText,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Your negotiation center',
                          style: TextStyle(fontSize: 15, color: cMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: cText),
                    onPressed: _load,
                  ),
                ],
              ),
            ),
            // ── Tab buttons ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _OfferTabBtn(
                      label: 'Received',
                      badge: pendingReceived,
                      selected: _tabs.index == 0,
                      onTap: () => _tabs.animateTo(0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OfferTabBtn(
                      label: 'Sent',
                      badge: pendingSent,
                      selected: _tabs.index == 1,
                      onTap: () => _tabs.animateTo(1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // ── Body ──────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: cRed))
                  : _error != null
                      ? _ErrorState(message: _error!, onRetry: _load)
                      : TabBarView(
                          controller: _tabs,
                          children: [
                            _OfferList(
                              offers:    _received,
                              userId:    widget.userId,
                              emptyMsg:  'No offers received yet.',
                              onChanged: _load,
                            ),
                            _OfferList(
                              offers:    _sent,
                              userId:    widget.userId,
                              emptyMsg:  'You haven\'t made any offers yet.',
                              onChanged: _load,
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TAB TOGGLE BUTTON ───────────────────────────────────────────────────────

class _OfferTabBtn extends StatelessWidget {
  final String label;
  final int badge;
  final bool selected;
  final VoidCallback onTap;

  const _OfferTabBtn({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cRed : cSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? cRed : cBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : cText,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : cRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    color: selected ? cRed : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── ERROR STATE ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: cMuted, size: 32),
          const SizedBox(height: 8),
          const Text('Could not load offers',
              style: TextStyle(fontWeight: FontWeight.w700, color: cText)),
          const SizedBox(height: 4),
          Text(message,
              style: const TextStyle(color: cMuted, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: cRed, foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ]),
      ),
    );
  }
}

// ─── OFFER LIST ──────────────────────────────────────────────────────────────

class _OfferList extends StatelessWidget {
  final List<Offer> offers;
  final int userId;
  final String emptyMsg;
  final VoidCallback onChanged;

  const _OfferList({
    required this.offers,
    required this.userId,
    required this.emptyMsg,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return RefreshIndicator(
        color: cRed,
        onRefresh: () async => onChanged(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            Center(child: Text(emptyMsg,
                style: const TextStyle(color: cMuted, fontSize: 13))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: cRed,
      onRefresh: () async => onChanged(),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: offers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => OfferCard(
          offer:     offers[i],
          userId:    userId,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── OFFER CARD ──────────────────────────────────────────────────────────────
class OfferCard extends StatelessWidget {
  final Offer offer;
  final int userId;
  final VoidCallback onChanged;
  final bool readOnly;

  const OfferCard({
    super.key,
    required this.offer,
    required this.userId,
    required this.onChanged,
    this.readOnly = false,
  });

  String _counterparty() {
      if (offer.role == 'recipient') {
      return offer.senderName?.trim().isNotEmpty == true
          ? offer.senderName!
          : 'User #${offer.senderId}';
    }
    return offer.recipientName?.trim().isNotEmpty == true
        ? offer.recipientName!
        : 'User #${offer.recipientId}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: readOnly ? null : () async { 
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => OfferThreadScreen(
            rootOffer: offer,
            userId:    userId,
          ),
        ));
        onChanged();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: offer.isPending ? cRedLight.withValues(alpha: 0.35) : cSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: offer.isPending ? cRed.withValues(alpha: 0.3) : cBorder,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _StatusPill(status: offer.status),
            const SizedBox(width: 8),
            Text('\$${offer.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: cRed, fontSize: 18, fontWeight: FontWeight.w900)),
            const Spacer(),
            Text(_shortDate(offer.createdAt),
                style: const TextStyle(color: cMuted, fontSize: 11)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Icon(offer.role == 'recipient' ? Icons.call_received : Icons.call_made,
                size: 13, color: cMuted),
            const SizedBox(width: 5),
            Expanded(child: Text(
              offer.role == 'recipient' ? 'From ${_counterparty()}' : 'To ${_counterparty()}',
              style: const TextStyle(fontSize: 12, color: cText, fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
            const SizedBox(width: 8),
            Text(
              'Listing: ${offer.listingTitle ?? '#${offer.listingId}'}',
              style: const TextStyle(fontSize: 11, color: cMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ]),
          if (offer.note != null && offer.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cBorder),
              ),
              child: Text(offer.note!,
                  style: const TextStyle(fontSize: 12, color: cText, height: 1.4),
                  maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
          ],
          if (offer.canRespond) ...[
            const SizedBox(height: 10),
            _ResponseActions(offer: offer, userId: userId, onChanged: onChanged),
          ] else if (offer.isPending && offer.role == 'sender') ...[
            const SizedBox(height: 10),
            _WithdrawAction(offer: offer, userId: userId, onChanged: onChanged),
          ],
        ]),
      ),
    );
  }
}

String _shortDate(DateTime dt) {
  final now  = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1)   return 'just now';
  if (diff.inMinutes < 60)  return '${diff.inMinutes}m';
  if (diff.inHours   < 24)  return '${diff.inHours}h';
  if (diff.inDays    < 7)   return '${diff.inDays}d';
  return '${dt.month}/${dt.day}';
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  _PillStyle _style() {
    switch (status) {
      case 'pending':    return const _PillStyle(Color(0xFFFEF3C7), Color(0xFF92400E), 'PENDING');
      case 'accepted':   return const _PillStyle(Color(0xFFD1FAE5), Color(0xFF065F46), 'ACCEPTED');
      case 'rejected':   return const _PillStyle(Color(0xFFFEE2E2), Color(0xFF991B1B), 'REJECTED');
      case 'countered':  return const _PillStyle(Color(0xFFDBEAFE), Color(0xFF1E3A8A), 'COUNTERED');
      case 'withdrawn':  return const _PillStyle(Color(0xFFE5E7EB), Color(0xFF374151), 'WITHDRAWN');
      case 'superseded': return const _PillStyle(Color(0xFFE5E7EB), Color(0xFF374151), 'SUPERSEDED');
      default:           return _PillStyle(cBorder, cMuted, status.toUpperCase());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(6)),
      child: Text(s.label,
          style: TextStyle(color: s.fg, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }
}

class _PillStyle {
  final Color bg;
  final Color fg;
  final String label;
  const _PillStyle(this.bg, this.fg, this.label);
}

// ─── ACTION BUTTONS ──────────────────────────────────────────────────────────

class _ResponseActions extends StatefulWidget {
  final Offer offer;
  final int userId;
  final VoidCallback onChanged;

  const _ResponseActions({
    required this.offer,
    required this.userId,
    required this.onChanged,
  });

  @override
  State<_ResponseActions> createState() => _ResponseActionsState();
}

class _ResponseActionsState extends State<_ResponseActions> {
  bool _busy = false;

  Future<void> _respond(String action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await respondOffer(
        offerId: widget.offer.id,
        userId:  widget.userId,
        action:  action,
      );
      markOffersSeen(userId: widget.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Offer ${action == 'accept' ? 'accepted' : 'rejected'}.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cRed));
      widget.onChanged();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Action failed: $e'),
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _counter() async {
    if (_busy) return;
    final result = await showDialog<_OfferFormResult>(
      context: context,
      builder: (_) => MakeOfferSheet(
        listingTitle:     'Listing #${widget.offer.listingId}',
        listingPrice:     widget.offer.amount,
        counteringAmount: widget.offer.amount,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await makeOffer(
        listingId:     widget.offer.listingId,
        senderId:      widget.userId,
        amount:        result.amount,
        note:          result.note,
        parentOfferId: widget.offer.id,
      );
      markOffersSeen(userId: widget.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Counter of \$${result.amount.toStringAsFixed(2)} sent.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cRed));
      widget.onChanged();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Counter failed: $e'),
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(color: cRed, strokeWidth: 2)),
        ),
      );
    }
    return Row(children: [
      Expanded(child: _ActionBtn(
        label: 'Accept', filled: true,
        onTap: () => _respond('accept'),
      )),
      const SizedBox(width: 8),
      Expanded(child: _ActionBtn(
        label: 'Counter',
        onTap: _counter,
      )),
      const SizedBox(width: 8),
      Expanded(child: _ActionBtn(
        label: 'Reject', danger: true,
        onTap: () => _respond('reject'),
      )),
    ]);
  }
}

class _WithdrawAction extends StatefulWidget {
  final Offer offer;
  final int userId;
  final VoidCallback onChanged;
  const _WithdrawAction({required this.offer, required this.userId, required this.onChanged});

  @override
  State<_WithdrawAction> createState() => _WithdrawActionState();
}

class _WithdrawActionState extends State<_WithdrawAction> {
  bool _busy = false;

  Future<void> _withdraw() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Withdraw offer?'),
        content: Text(
          'This will retract your \$${widget.offer.amount.toStringAsFixed(2)} offer. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: cRed),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await respondOffer(
        offerId: widget.offer.id,
        userId:  widget.userId,
        action:  'withdraw',
      );
      markOffersSeen(userId: widget.userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Offer withdrawn.'),
          behavior: SnackBarBehavior.floating));
      widget.onChanged();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Withdraw failed: $e'),
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(color: cRed, strokeWidth: 2)),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerRight,
      child: _ActionBtn(label: 'Withdraw', danger: true, onTap: _withdraw),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final bool danger;
  const _ActionBtn({
    required this.label,
    required this.onTap,
    this.filled = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg     = filled ? cRed : cSurface;
    final fg     = filled ? Colors.white : (danger ? cRed : cText);
    final border = filled ? cRed : (danger ? cRed : cBorder);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Text(label,
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
      ),
    );
  }
}

// ─── OFFER THREAD SCREEN ─────────────────────────────────────────────────────
class OfferThreadScreen extends StatefulWidget {
  final Offer rootOffer;
  final int userId;

  const OfferThreadScreen({
    super.key,
    required this.rootOffer,
    required this.userId,
  });

  @override
  State<OfferThreadScreen> createState() => _OfferThreadScreenState();
}

class _OfferThreadScreenState extends State<OfferThreadScreen> {
  List<Offer> _thread = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final all = await getListingOffers(
        listingId: widget.rootOffer.listingId,
        userId:    widget.userId,
      );
      final parties = {widget.rootOffer.senderId, widget.rootOffer.recipientId};
      final thread = all.where((o) =>
          parties.contains(o.senderId) && parties.contains(o.recipientId)).toList();
      if (!mounted) return;
      setState(() { _thread = thread; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     backgroundColor: cBg,
      appBar: AppBar(
        title: Text(
          '${widget.rootOffer.listingTitle ?? 'Listing #${widget.rootOffer.listingId}'} · Offer Thread',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        backgroundColor: cNavBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: cRed))
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  color: cRed,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _thread.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => OfferCard(
                      offer:     _thread[i],
                      userId:    widget.userId,
                      onChanged: _load,
                      readOnly: true,
                    ),
                  ),
                ),
    );
  }
}