part of '../main.dart';

class MyListingsScreen extends StatefulWidget {
  final List<MarketplaceItem> marketplaceItems;
  final List<LostFoundItem> lostFoundItems;
  final VoidCallback onListItem;
  const MyListingsScreen({super.key, required this.marketplaceItems, required this.lostFoundItems, required this.onListItem});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  bool _showMarket = true;

  @override
  Widget build(BuildContext context) {
    final empty = _showMarket ? widget.marketplaceItems.isEmpty : widget.lostFoundItems.isEmpty;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('My Listings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.5)),
                    Text('Your active posts', style: TextStyle(fontSize: 12, color: cMuted)),
                  ],
                ),
              ),
              _RedButton(label: 'New Post', icon: Icons.add_rounded, onTap: widget.onListItem),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _TypeBtn(label: 'Marketplace', type: ListingType.marketplace, selected: _showMarket, onTap: () => setState(() => _showMarket = true))),
              const SizedBox(width: 10),
              Expanded(child: _TypeBtn(label: 'Lost & Found', type: ListingType.lost, selected: !_showMarket, onTap: () => setState(() => _showMarket = false))),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: empty
                ? _EmptyState(
                    message: _showMarket ? 'No marketplace listings yet' : 'No lost & found posts yet',
                    cta: 'Post Something',
                    onCta: widget.onListItem,
                  )
                : ListView(
                    children: _showMarket
                        ? widget.marketplaceItems.map((i) => _MyListingTile(
                              title: i.title,
                              subtitle: '${i.category} · ${i.location}',
                              trailing: '\$${i.price.toStringAsFixed(0)}',
                              icon: Icons.storefront_rounded,
                            )).toList()
                        : widget.lostFoundItems.map((i) => _MyListingTile(
                              title: i.title,
                              subtitle: '${i.category} · ${i.location}',
                              trailing: i.type == LostFoundType.lost ? 'Lost' : 'Found',
                              icon: i.type == LostFoundType.lost ? Icons.report_problem_outlined : Icons.check_circle_outline_rounded,
                            )).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MyListingTile extends StatelessWidget {
  final String title, subtitle, trailing;
  final IconData icon;
  const _MyListingTile({required this.title, required this.subtitle, required this.trailing, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: cRed, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cText)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: cMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(8)),
            child: Text(trailing, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cRed)),
          ),
        ],
      ),
    );
  }
}
