part of '../main.dart';

class MarketplaceScreen extends StatefulWidget {
  final List<MarketplaceItem> items;
  final VoidCallback onListItem;
  final String currentUserEmail;
  const MarketplaceScreen({super.key, required this.items, required this.onListItem, required this.currentUserEmail});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _cat = 'All';
  String _cond = 'All';
  String _q = '';
  double? _minPrice;
  double? _maxPrice;

  Future<void> _openFilters() async {
    String draftCategory = _cat;
    String draftCondition = _cond;
    final minCtrl = TextEditingController(text: _minPrice?.toStringAsFixed(0) ?? '');
    final maxCtrl = TextEditingController(text: _maxPrice?.toStringAsFixed(0) ?? '');

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filters',
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
                  constraints: const BoxConstraints(maxWidth: 460),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filters',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cText),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: draftCategory,
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: ['All', ...categories]
                                .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) => setModalState(() => draftCategory = v ?? 'All'),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: draftCondition,
                            decoration: const InputDecoration(labelText: 'Condition'),
                            items: const ['All', 'New', 'Like New', 'Good', 'Fair']
                                .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) => setModalState(() => draftCondition = v ?? 'All'),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: minCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Min Price'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: maxCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Max Price'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _cat = 'All';
                                      _cond = 'All';
                                      _minPrice = null;
                                      _maxPrice = null;
                                    });
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Clear'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _RedButton(
                                  label: 'Apply',
                                  icon: Icons.check_rounded,
                                  onTap: () {
                                    final min = double.tryParse(minCtrl.text.trim());
                                    final max = double.tryParse(maxCtrl.text.trim());
                                    setState(() {
                                      _cat = draftCategory;
                                      _cond = draftCondition;
                                      _minPrice = min;
                                      _maxPrice = max;
                                    });
                                    Navigator.pop(ctx);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((i) {
      final cm = _cat == 'All' || i.category == _cat;
      final cnd = _cond == 'All' || i.condition == _cond;
      final sm = i.title.toLowerCase().contains(_q.toLowerCase()) || i.description.toLowerCase().contains(_q.toLowerCase());
      final minOk = _minPrice == null || i.price >= _minPrice!;
      final maxOk = _maxPrice == null || i.price <= _maxPrice!;
      return cm && cnd && sm && minOk && maxOk;
    }).toList();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Marketplace', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cText, letterSpacing: -0.5)),
                    Text('Find great deals on campus!', style: TextStyle(fontSize: 12, color: cMuted)),
                  ],
                ),
              ),
              _HoverButton(
                child: _RedButton(
                  label: 'List Item',
                  icon: Icons.add_rounded,
                  onTap: widget.onListItem,
                ),
              ),
            ],
          ),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: _SearchField(
                  hint: 'Search marketplace...',
                  onChanged: (v) => setState(() => _q = v),
                ),
              ),
              const SizedBox(width: 8),
              _MarketFilterButton(onTap: _openFilters),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: filtered.isEmpty
              ? _EmptyState(message: 'No items found', cta: 'List an Item', onCta: widget.onListItem)
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (ctx, i) => _MarketCard(
                    item: filtered[i],
                    onTap: () => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => ItemDetailScreen(item: filtered[i], currentUserEmail: widget.currentUserEmail))),
                  ),
                ),
        ),
      ],
    );
  }
}

class _MarketFilterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MarketFilterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: cSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.tune_rounded, color: cRed),
      ),
    );
  }
}

class _HoverButton extends StatefulWidget {
  final Widget child;

  const _HoverButton({required this.child});

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.08 : 1.0, // 👈 zoom effect
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ─── MARKET CARD — FIX 4: Added hover animation ───────────────────────────
class _MarketCard extends StatefulWidget {
  final MarketplaceItem item;
  final VoidCallback onTap;
  const _MarketCard({required this.item, required this.onTap});

  @override
  State<_MarketCard> createState() => _MarketCardState();
}

class _MarketCardState extends State<_MarketCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kFast);
    _scale = Tween(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _c.forward(),
        onTapUp: (_) { _c.reverse(); widget.onTap(); },
        onTapCancel: () => _c.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: kMid,
            decoration: BoxDecoration(
              color: cSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _hovered ? cRed.withValues(alpha: 0.35) : cBorder),
              boxShadow: [BoxShadow(
                color: _hovered ? cRed.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06),
                blurRadius: _hovered ? 18 : 10,
                offset: const Offset(0, 3),
              )],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Image.network(
                        widget.item.image,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(color: cPlaceholder, child: Center(child: Icon(Icons.image_not_supported, color: cMuted))),
                      ),
                      // Category badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cRed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(widget.item.category, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('\$${widget.item.price.toStringAsFixed(0)}', style: const TextStyle(color: cRed, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
                      const SizedBox(height: 3),
                      Text(widget.item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cText)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 11, color: cMuted),
                          const SizedBox(width: 3),
                          Expanded(child: Text(widget.item.location, style: const TextStyle(fontSize: 11, color: cMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(widget.item.condition, style: const TextStyle(fontSize: 11, color: cMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
