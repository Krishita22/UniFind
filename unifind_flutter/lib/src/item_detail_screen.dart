part of '../main.dart';

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

  Future<void> _contactSeller() async {
    final myId     = widget.currentUserId;
    final sellerId = widget.item.sellerId;
    if (myId == null || sellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not start conversation — user info unavailable.'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    if (myId == sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('This is your own listing.'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _startingChat = true);
    try {
      final result = await startConversation(
        listingId: int.tryParse(widget.item.id) ?? 0,
        user1Id:   myId,
        user2Id:   sellerId,
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
            otherId:   sellerId,
            unread:    0,
          ),
          myId: myId,
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

                  // Action buttons row
                  Row(
                    children: [
                      // Contact Seller
                      Expanded(
                        child: GestureDetector(
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
                      ),
                      // Only show Pay if this is not the user's own listing
                      if (widget.currentUserId != null &&
                          widget.item.sellerId != null &&
                          widget.currentUserId != widget.item.sellerId) ...[
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => PaymentScreen(
                              item:       widget.item,
                              buyerId:    widget.currentUserId!,
                              sellerId:   widget.item.sellerId!,
                              buyerEmail: widget.currentUserEmail,
                            ),
                          )),
                          child: AnimatedContainer(
                            duration: kFast,
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27AE60),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.payments_outlined, color: Colors.white, size: 17),
                                  SizedBox(width: 6),
                                  Text('Buy',
                                    style: TextStyle(color: Colors.white, fontSize: 14,
                                        fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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
