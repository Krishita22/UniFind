part of '../main.dart';

class ItemDetailScreen extends StatelessWidget {
  final MarketplaceItem item;
  final String currentUserEmail;
  const ItemDetailScreen({
    super.key,
    required this.item,
    required this.currentUserEmail,
  });

  String _asSellerUsername() {
    final raw = item.seller.trim();
    if (raw.isEmpty || raw.contains('@') || raw.contains(' ')) return 'Student';
    return raw;
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
                      targetId: item.id,
                      targetType: 'listing',
                      targetTitle: item.title,
                      reporterEmail: currentUserEmail,
                    );
                  } else if (value == 'report_user') {
                    showReportDialog(
                      context: context,
                      targetId: item.sellerEmail.isNotEmpty
                          ? item.sellerEmail
                          : item.id,
                      targetType: 'user',
                      targetTitle: '@${_asSellerUsername()}',
                      reporterEmail: currentUserEmail,
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
                item.image,
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
                        '\$${item.price.toStringAsFixed(0)}',
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
                          item.category.toUpperCase(),
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
                    item.title,
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
                        formatDate(item.createdAt),
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
                        label: item.condition,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.location_on_outlined,
                        label: item.location,
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
                    item.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: cMuted,
                      height: 1.75,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Contact button
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(children: [
                          Icon(Icons.message_rounded,
                              color: Colors.white, size: 17),
                          SizedBox(width: 10),
                          Text('Contact flow coming soon!'),
                        ]),
                        backgroundColor: cRed,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(12),
                      ),
                    ),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: cRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.message_rounded,
                              color: Colors.white, size: 17),
                          SizedBox(width: 8),
                          Text(
                            'Contact Seller',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
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
