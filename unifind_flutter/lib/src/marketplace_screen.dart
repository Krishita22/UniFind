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

  // Price controllers for the side panel text fields
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  List<MarketplaceItem> get _filtered => widget.items.where((i) {
    final cm = _cat == 'All' || i.category == _cat;
    final cnd = _cond == 'All' || i.condition == _cond;
    final sm = i.title.toLowerCase().contains(_q.toLowerCase()) ||
        i.description.toLowerCase().contains(_q.toLowerCase());
    final minOk = _minPrice == null || i.price >= _minPrice!;
    final maxOk = _maxPrice == null || i.price <= _maxPrice!;
    return cm && cnd && sm && minOk && maxOk;
  }).toList();

  bool get _hasActiveFilters =>
      _cat != 'All' || _cond != 'All' || _minPrice != null || _maxPrice != null;

  void _clearFilters() {
    setState(() {
      _cat = 'All'; _cond = 'All'; _minPrice = null; _maxPrice = null;
    });
    _minCtrl.clear();
    _maxCtrl.clear();
  }

  // ── Mobile filter dialog (unchanged behavior on narrow screens) ───────────
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
      transitionBuilder: (ctx, anim, __, ___) => Opacity(
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
                  padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
                  decoration: BoxDecoration(
                    color: cSurface, borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cBorder),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cText)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: draftCategory,
                          decoration: const InputDecoration(labelText: 'Category'),
                          items: ['All', ...categories].map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setModalState(() => draftCategory = v ?? 'All'),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: draftCondition,
                          decoration: const InputDecoration(labelText: 'Condition'),
                          items: const ['All', 'New', 'Like New', 'Good', 'Fair']
                              .map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setModalState(() => draftCondition = v ?? 'All'),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: TextField(controller: minCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Min Price'))),
                            const SizedBox(width: 10),
                            Expanded(child: TextField(controller: maxCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Max Price'))),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () { _clearFilters(); Navigator.pop(ctx); },
                                child: const Text('Clear'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _RedButton(
                                label: 'Apply',
                                icon: Icons.check_rounded,
                                onTap: () {
                                  setState(() {
                                    _cat = draftCategory;
                                    _cond = draftCondition;
                                    _minPrice = double.tryParse(minCtrl.text.trim());
                                    _maxPrice = double.tryParse(maxCtrl.text.trim());
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isBrowser = constraints.maxWidth >= 720;

        if (isBrowser) {
          return _BrowserLayout(
            filtered: filtered,
            cat: _cat,
            cond: _cond,
            minPrice: _minPrice,
            maxPrice: _maxPrice,
            minCtrl: _minCtrl,
            maxCtrl: _maxCtrl,
            hasActiveFilters: _hasActiveFilters,
            onCatChanged: (v) => setState(() => _cat = v),
            onCondChanged: (v) => setState(() => _cond = v),
            onApplyPrice: (min, max) => setState(() { _minPrice = min; _maxPrice = max; }),
            onClearFilters: _clearFilters,
            onListItem: widget.onListItem,
            onSearch: (v) => setState(() => _q = v),
            q: _q,
            currentUserEmail: widget.currentUserEmail,
          );
        }

        // ── Mobile layout ─────────────────────────────────────────────────
        return Column(
          children: [
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
                  _HoverButton(child: _RedButton(label: 'List Item', icon: Icons.add_rounded, onTap: widget.onListItem)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: _SearchField(hint: 'Search marketplace...', onChanged: (v) => setState(() => _q = v))),
                  const SizedBox(width: 8),
                  _MarketFilterButton(onTap: _openFilters, hasActive: _hasActiveFilters),
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
                        crossAxisCount: 2, childAspectRatio: 0.85,
                        crossAxisSpacing: 10, mainAxisSpacing: 10,
                      ),
                      itemBuilder: (ctx, i) => _MarketCard(
                        item: filtered[i],
                        compact: false,
                        onTap: () => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => ItemDetailScreen(item: filtered[i], currentUserEmail: widget.currentUserEmail))),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─── BROWSER LAYOUT (side panel + grid) ──────────────────────────────────────
class _BrowserLayout extends StatelessWidget {
  final List<MarketplaceItem> filtered;
  final String cat;
  final String cond;
  final double? minPrice;
  final double? maxPrice;
  final TextEditingController minCtrl;
  final TextEditingController maxCtrl;
  final bool hasActiveFilters;
  final void Function(String) onCatChanged;
  final void Function(String) onCondChanged;
  final void Function(double?, double?) onApplyPrice;
  final VoidCallback onClearFilters;
  final VoidCallback onListItem;
  final void Function(String) onSearch;
  final String q;
  final String currentUserEmail;

  const _BrowserLayout({
    required this.filtered,
    required this.cat,
    required this.cond,
    required this.minPrice,
    required this.maxPrice,
    required this.minCtrl,
    required this.maxCtrl,
    required this.hasActiveFilters,
    required this.onCatChanged,
    required this.onCondChanged,
    required this.onApplyPrice,
    required this.onClearFilters,
    required this.onListItem,
    required this.onSearch,
    required this.q,
    required this.currentUserEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Side Panel ────────────────────────────────────────────────────
        Container(
          width: 240,
          decoration: BoxDecoration(
            color: cSurface,
            border: Border(right: BorderSide(color: cBorder)),
          ),
          child: _SidePanel(
            cat: cat,
            cond: cond,
            minCtrl: minCtrl,
            maxCtrl: maxCtrl,
            hasActiveFilters: hasActiveFilters,
            onCatChanged: onCatChanged,
            onCondChanged: onCondChanged,
            onApplyPrice: onApplyPrice,
            onClearFilters: onClearFilters,
          ),
        ),
        // ── Main Content ──────────────────────────────────────────────────
        Expanded(
          child: Column(
            children: [
              // Header bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cBorder))),
                child: Row(
                  children: [
                    Expanded(
                      child: _SearchField(hint: 'Search marketplace...', onChanged: onSearch),
                    ),
                    const SizedBox(width: 12),
                    _HoverButton(child: _RedButton(label: 'List Item', icon: Icons.add_rounded, onTap: onListItem)),
                  ],
                ),
              ),
              // Results header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} item${filtered.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cMuted),
                    ),
                    if (hasActiveFilters) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onClearFilters,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(8)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close_rounded, size: 12, color: cRed),
                              SizedBox(width: 3),
                              Text('Clear filters', style: TextStyle(fontSize: 11, color: cRed, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Grid
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(message: 'No items found', cta: 'List an Item', onCta: onListItem)
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: filtered.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (ctx, i) => _MarketCard(
                          item: filtered[i],
                          compact: true,
                          onTap: () => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => ItemDetailScreen(item: filtered[i], currentUserEmail: currentUserEmail))),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── SIDE PANEL ───────────────────────────────────────────────────────────────
class _SidePanel extends StatefulWidget {
  final String cat;
  final String cond;
  final TextEditingController minCtrl;
  final TextEditingController maxCtrl;
  final bool hasActiveFilters;
  final void Function(String) onCatChanged;
  final void Function(String) onCondChanged;
  final void Function(double?, double?) onApplyPrice;
  final VoidCallback onClearFilters;

  const _SidePanel({
    required this.cat,
    required this.cond,
    required this.minCtrl,
    required this.maxCtrl,
    required this.hasActiveFilters,
    required this.onCatChanged,
    required this.onCondChanged,
    required this.onApplyPrice,
    required this.onClearFilters,
  });

  @override
  State<_SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends State<_SidePanel> {
  static const _conditions = ['All', 'New', 'Like New', 'Good', 'Fair'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Panel header ─────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 16, color: cRed),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Filters', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: cText)),
              ),
              if (widget.hasActiveFilters)
                GestureDetector(
                  onTap: widget.onClearFilters,
                  child: const Text('Clear', style: TextStyle(fontSize: 11, color: cRed, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: cBorder),
          const SizedBox(height: 16),

          // ── Category ─────────────────────────────────────────────────
          const _PanelSectionLabel(label: 'CATEGORY'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['All', ...categories].map((c) {
              final selected = widget.cat == c;
              return GestureDetector(
                onTap: () => widget.onCatChanged(c),
                child: AnimatedContainer(
                  duration: kFast,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: selected ? cRed : cBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selected ? cRed : cBorder),
                  ),
                  child: Text(
                    c,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? Colors.white : cMuted),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: cBorder),
          const SizedBox(height: 16),

          // ── Condition ────────────────────────────────────────────────
          const _PanelSectionLabel(label: 'CONDITION'),
          const SizedBox(height: 8),
          Column(
            children: _conditions.map((c) {
              final selected = widget.cond == c;
              return GestureDetector(
                onTap: () => widget.onCondChanged(c),
                child: AnimatedContainer(
                  duration: kFast,
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? cRedLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? cRed.withValues(alpha: 0.4) : Colors.transparent),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: kFast,
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          color: selected ? cRed : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: selected ? cRed : cMuted, width: 1.5),
                        ),
                        child: selected ? const Icon(Icons.check_rounded, size: 10, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 10),
                      Text(c, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? cRed : cText)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: cBorder),
          const SizedBox(height: 16),

          // ── Price Range ───────────────────────────────────────────────
          const _PanelSectionLabel(label: 'PRICE RANGE'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.minCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Min',
                    hintStyle: const TextStyle(color: cMuted, fontSize: 12),
                    prefixText: '\$',
                    prefixStyle: const TextStyle(color: cMuted, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cRed, width: 1.5)),
                    filled: true, fillColor: cBg,
                  ),
                ),
              ),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text('–', style: TextStyle(color: cMuted, fontWeight: FontWeight.w700))),
              Expanded(
                child: TextField(
                  controller: widget.maxCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Max',
                    hintStyle: const TextStyle(color: cMuted, fontSize: 12),
                    prefixText: '\$',
                    prefixStyle: const TextStyle(color: cMuted, fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cRed, width: 1.5)),
                    filled: true, fillColor: cBg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final min = double.tryParse(widget.minCtrl.text.trim());
                final max = double.tryParse(widget.maxCtrl.text.trim());
                widget.onApplyPrice(min, max);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Apply', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelSectionLabel extends StatelessWidget {
  final String label;
  const _PanelSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: cMuted, letterSpacing: 1.2));
  }
}

// ─── FILTER BUTTON (mobile) ───────────────────────────────────────────────────
class _MarketFilterButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool hasActive;
  const _MarketFilterButton({required this.onTap, this.hasActive = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: hasActive ? cRedLight : cSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: hasActive ? cRed.withValues(alpha: 0.4) : cBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Icon(Icons.tune_rounded, color: hasActive ? cRed : cMuted),
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
      child: AnimatedScale(scale: _hovering ? 1.08 : 1.0, duration: const Duration(milliseconds: 150), curve: Curves.easeOut, child: widget.child),
    );
  }
}

// ─── MARKET CARD ─────────────────────────────────────────────────────────────
class _MarketCard extends StatefulWidget {
  final MarketplaceItem item;
  final VoidCallback onTap;
  // compact = true on browser (smaller image height)
  final bool compact;
  const _MarketCard({required this.item, required this.onTap, this.compact = false});
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
                blurRadius: _hovered ? 18 : 10, offset: const Offset(0, 3),
              )],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image — fixed height when compact, flexible otherwise
                SizedBox(
                  height: widget.compact ? 100 : 120,
                  child: Stack(
                    children: [
                      Image.network(
                        widget.item.image,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(color: cPlaceholder, child: Center(child: Icon(Icons.image_not_supported, color: cMuted))),
                      ),
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: cRed, borderRadius: BorderRadius.circular(8)),
                          child: Text(widget.item.category, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('\$${widget.item.price.toStringAsFixed(0)}', style: const TextStyle(color: cRed, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.5)),
                      const SizedBox(height: 2),
                      Text(widget.item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cText)),
                      const SizedBox(height: 2),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 10, color: cMuted),
                          const SizedBox(width: 3),
                          Expanded(child: Text(widget.item.location, style: const TextStyle(fontSize: 10, color: cMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(widget.item.condition, style: const TextStyle(fontSize: 10, color: cMuted)),
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
