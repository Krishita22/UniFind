part of '../main.dart';

class ItemDetailScreen extends StatelessWidget {
  final MarketplaceItem item;
  final String currentUserEmail;
  const ItemDetailScreen({super.key, required this.item, required this.currentUserEmail});

  String _asSellerUsername() {
    final raw = item.seller.trim();
    if (raw.isEmpty) return 'Student';
    if (raw.contains('@')) return 'Student';
    if (raw.contains(' ')) return 'Student';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: cNavBg,
            actions: [
              // ── Report popup menu — report listing OR report seller ──
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
                      targetId: item.sellerEmail.isNotEmpty ? item.sellerEmail : item.id,
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
                      Icon(Icons.flag_outlined, size: 16, color: cRed),
                      SizedBox(width: 10),
                      Text('Report Listing', style: TextStyle(fontSize: 13)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'report_user',
                    child: Row(children: [
                      Icon(Icons.person_off_outlined, size: 16, color: cRed),
                      SizedBox(width: 10),
                      Text('Report Seller', style: TextStyle(fontSize: 13)),
                    ]),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                item.image,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const ColoredBox(color: cPlaceholder, child: Center(child: Icon(Icons.image_not_supported, size: 48, color: cMuted))),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('\$${item.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: cRed, letterSpacing: -1)),
                            const SizedBox(height: 4),
                            Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cText, letterSpacing: -0.3)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: cRed, borderRadius: BorderRadius.circular(10)),
                        child: Text(item.category, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: cBorder)),
                    child: Column(
                      children: [
                        _DetailRow(icon: Icons.stars_rounded, label: 'Condition', value: item.condition),
                        _DetailRow(icon: Icons.location_on_outlined, label: 'Location', value: item.location),
                        _DetailRow(icon: Icons.calendar_today_outlined, label: 'Posted', value: formatDate(item.createdAt)),
                        _DetailRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Seller',
                          value: _asSellerUsername(),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cText)),
                  const SizedBox(height: 8),
                  Text(item.description, style: const TextStyle(fontSize: 13, color: cMuted, height: 1.7)),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(children: [Icon(Icons.message_rounded, color: Colors.white, size: 18), SizedBox(width: 10), Text('Contact flow coming soon!')]),
                        backgroundColor: cRed,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(12),
                      ),
                    ),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5))],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.message_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Contact Seller', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isLast;
  const _DetailRow({required this.icon, required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: cRed),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 12, color: cMuted, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cText)),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: cBorder),
      ],
    );
  }
}
