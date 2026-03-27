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
                        crossAxisCount: 2, childAspectRatio: 1.0,
                        crossAxisSpacing: 8, mainAxisSpacing: 8,
                      ),
                      itemBuilder: (ctx, i) => _MarketCard(
                        item: filtered[i],
                        compact: false,
                        onTap: () => _showItemPopup(ctx, filtered[i], widget.currentUserEmail),
                        currentUserEmail: widget.currentUserEmail,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
// -- Full-screen image viewer --
class _FullScreenImagePage extends StatelessWidget {
  final String imageUrl;
  const _FullScreenImagePage({required this.imageUrl});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.image_not_supported, color: Colors.white30, size: 48),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Item popup -- full detail content --
void _showItemPopup(BuildContext context, MarketplaceItem item, String currentUserEmail) {
  // Helper to clean up seller display name (mirrors ItemDetailScreen logic)
  String asSellerUsername() {
    final raw = item.seller.trim();
    if (raw.isEmpty || raw.contains('@') || raw.contains(' ')) return 'Student';
    return raw;
  }
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Item',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: kMid,
    pageBuilder: (ctx, _, __) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, __, ___) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return Opacity(
        opacity: curved.value,
        child: Transform.scale(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved).value,
          child: Center(
            child: ConstrainedBox(
              // Taller max height to fit all the detail content
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                decoration: BoxDecoration(
                  color: cSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 40, offset: const Offset(0, 12))],
                ),
                clipBehavior: Clip.antiAlias,
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -- Tappable image header --
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              PageRouteBuilder(
                                opaque: false,
                                barrierColor: Colors.black,
                                pageBuilder: (_, __, ___) => _FullScreenImagePage(imageUrl: item.image),
                                transitionsBuilder: (_, anim, __, child) =>
                                    FadeTransition(opacity: anim, child: child),
                                transitionDuration: kMid,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Image.network(
                                  item.image,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 200,
                                    color: cPlaceholder,
                                    child: const Center(child: Icon(Icons.image_not_supported, color: cMuted, size: 36)),
                                  ),
                                ),
                                // Expand affordance badge
                                Positioned(
                                  bottom: 8, right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.open_in_full_rounded, size: 11, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text('Tap to expand', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Category badge
                          Positioned(
                            top: 10, left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: cRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.category.toUpperCase(),
                                style: const TextStyle(color: cRed, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                              ),
                            ),
                          ),
                          // Report + close buttons row
                          Positioned(
                            top: 8, right: 8,
                            child: Row(
                              children: [
                                // Report menu
                                PopupMenuButton<String>(
                                  icon: Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.more_vert, color: Colors.white, size: 16),
                                  ),
                                  tooltip: 'Options',
                                  onSelected: (value) {
                                    Navigator.of(ctx).pop();
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
                                        targetTitle: '@${asSellerUsername()}',
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
                                        Text('Report Listing', style: TextStyle(fontSize: 13)),
                                      ]),
                                    ),
                                    const PopupMenuItem(
                                      value: 'report_user',
                                      child: Row(children: [
                                        Icon(Icons.person_off_outlined, size: 15, color: cRed),
                                        SizedBox(width: 10),
                                        Text('Report Seller', style: TextStyle(fontSize: 13)),
                                      ]),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                                // Close button
                                GestureDetector(
                                  onTap: () => Navigator.of(ctx).pop(),
                                  child: Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.45),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // -- Scrollable content (mirrors ItemDetailScreen) --
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Price + category badge row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '\$${item.price.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: cRed, letterSpacing: -1),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: cRed.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.category.toUpperCase(),
                                      style: const TextStyle(color: cRed, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Title
                              Text(
                                item.title,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cText, letterSpacing: -0.3, height: 1.25),
                              ),
                              const SizedBox(height: 6),
                              // Seller + date row
                              Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded, size: 13, color: cMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    asSellerUsername(),
                                    style: const TextStyle(fontSize: 12, color: cMuted, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.circle, size: 3, color: cMuted),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.calendar_today_outlined, size: 12, color: cMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    formatDate(item.createdAt),
                                    style: const TextStyle(fontSize: 12, color: cMuted, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),


                              // Condition + location chips
                              Row(
                                children: [
                                  _InfoChip(icon: Icons.stars_rounded, label: item.condition),
                                  const SizedBox(width: 8),
                                  _InfoChip(icon: Icons.location_on_outlined, label: item.location),
                                ],
                              ),
                              const SizedBox(height: 18),


                              Divider(height: 1, color: cBorder),
                              const SizedBox(height: 18),


                              // Description
                              const Text(
                                'Description',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cText, letterSpacing: 0.1),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.description,
                                style: const TextStyle(fontSize: 13, color: cMuted, height: 1.75),
                              ),
                              const SizedBox(height: 24),


                              // Contact Seller button (same behaviour as detail screen)
                              GestureDetector(
                                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(children: [
                                      Icon(Icons.message_rounded, color: Colors.white, size: 17),
                                      SizedBox(width: 10),
                                      Text('Contact flow coming soon!'),
                                    ]),
                                    backgroundColor: cRed,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                                      Icon(Icons.message_rounded, color: Colors.white, size: 17),
                                      SizedBox(width: 8),
                                      Text(
                                        'Contact Seller',
                                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.2),
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
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _PopupChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PopupChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: cRed),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cRed)),
        ],
      ),
    );
  }
}

// --- BROWSER LAYOUT ---
class _BrowserLayout extends StatefulWidget {
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
  State<_BrowserLayout> createState() => _BrowserLayoutState();
}

class _BrowserLayoutState extends State<_BrowserLayout> with SingleTickerProviderStateMixin {
  bool _panelOpen = true;
  late AnimationController _animCtrl;
  late Animation<double> _widthAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: kMid, value: 1.0);
    _widthAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _togglePanel() {
    setState(() => _panelOpen = !_panelOpen);
    if (_panelOpen) _animCtrl.forward();
    else _animCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: _widthAnim,
          builder: (context, child) => SizedBox(
            width: _widthAnim.value * 240,
            child: OverflowBox(maxWidth: 240, alignment: Alignment.topLeft, child: child),
          ),
          child: Container(
            width: 240,
            decoration: BoxDecoration(color: cSurface, border: Border(right: BorderSide(color: cBorder))),
            child: AnimatedOpacity(
              opacity: _panelOpen ? 1.0 : 0.0,
              duration: kFast,
              child: _SidePanel(
                cat: widget.cat,
                cond: widget.cond,
                minCtrl: widget.minCtrl,
                maxCtrl: widget.maxCtrl,
                hasActiveFilters: widget.hasActiveFilters,
                onCatChanged: widget.onCatChanged,
                onCondChanged: widget.onCondChanged,
                onApplyPrice: widget.onApplyPrice,
                onClearFilters: widget.onClearFilters,
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 10),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cBorder))),
                child: Row(
                  children: [
                    Tooltip(
                      message: _panelOpen ? 'Hide filters' : 'Show filters',
                      child: GestureDetector(
                        onTap: _togglePanel,
                        child: AnimatedContainer(
                          duration: kFast,
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: widget.hasActiveFilters ? cRedLight : cBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: widget.hasActiveFilters ? cRed.withValues(alpha: 0.4) : cBorder),
                          ),
                          child: Icon(
                            _panelOpen ? Icons.chevron_left_rounded : Icons.tune_rounded,
                            size: 18,
                            color: widget.hasActiveFilters ? cRed : cMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _SearchField(hint: 'Search marketplace...', onChanged: widget.onSearch)),
                    const SizedBox(width: 12),
                    _HoverButton(child: _RedButton(label: 'List Item', icon: Icons.add_rounded, onTap: widget.onListItem)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  children: [
                    Text(
                      '${widget.filtered.length} item${widget.filtered.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cMuted),
                    ),
                    if (widget.hasActiveFilters) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onClearFilters,
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
              Expanded(
                child: widget.filtered.isEmpty
                    ? _EmptyState(message: 'No items found', cta: 'List an Item', onCta: widget.onListItem)
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        itemCount: widget.filtered.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, childAspectRatio: 0.88,
                          crossAxisSpacing: 10, mainAxisSpacing: 10,
                        ),
                        itemBuilder: (ctx, i) => _MarketCard(
                          item: widget.filtered[i],
                          compact: true,
                          onTap: () => _showItemPopup(ctx, widget.filtered[i], widget.currentUserEmail),
                          currentUserEmail: widget.currentUserEmail,
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

// --- SIDE PANEL ---
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
  bool _categoryExpanded = true;
  bool _conditionExpanded = true;
  bool _priceExpanded = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 15, color: cRed),
              const SizedBox(width: 6),
              const Expanded(child: Text('Filters', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: cText))),
              if (widget.hasActiveFilters)
                GestureDetector(
                  onTap: widget.onClearFilters,
                  child: const Text('Clear all', style: TextStyle(fontSize: 11, color: cRed, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: cBorder),
          _CollapsibleSection(
            label: 'CATEGORY',
            expanded: _categoryExpanded,
            onToggle: () => setState(() => _categoryExpanded = !_categoryExpanded),
            child: Wrap(
              spacing: 5, runSpacing: 5,
              children: ['All', ...categories].map((c) {
                final selected = widget.cat == c;
                return GestureDetector(
                  onTap: () => widget.onCatChanged(c),
                  child: AnimatedContainer(
                    duration: kFast,
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected ? cRed : cBg,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: selected ? cRed : cBorder),
                    ),
                    child: Text(c, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: selected ? Colors.white : cMuted)),
                  ),
                );
              }).toList(),
            ),
          ),
          _CollapsibleSection(
            label: 'CONDITION',
            expanded: _conditionExpanded,
            onToggle: () => setState(() => _conditionExpanded = !_conditionExpanded),
            child: Column(
              children: _conditions.map((c) {
                final selected = widget.cond == c;
                return GestureDetector(
                  onTap: () => widget.onCondChanged(c),
                  child: AnimatedContainer(
                    duration: kFast,
                    margin: const EdgeInsets.only(bottom: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? cRedLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: selected ? cRed.withValues(alpha: 0.4) : Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: kFast,
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            color: selected ? cRed : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: selected ? cRed : cMuted, width: 1.5),
                          ),
                          child: selected ? const Icon(Icons.check_rounded, size: 9, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 8),
                        Text(c, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? cRed : cText)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          _CollapsibleSection(
            label: 'PRICE RANGE',
            expanded: _priceExpanded,
            onToggle: () => setState(() => _priceExpanded = !_priceExpanded),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.minCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Min', hintStyle: const TextStyle(color: cMuted, fontSize: 11),
                          prefixText: '\$', prefixStyle: const TextStyle(color: cMuted, fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: cBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: cBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: cRed, width: 1.5)),
                          filled: true, fillColor: cBg,
                        ),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 5), child: Text('--', style: TextStyle(color: cMuted, fontWeight: FontWeight.w700))),
                    Expanded(
                      child: TextField(
                        controller: widget.maxCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Max', hintStyle: const TextStyle(color: cMuted, fontSize: 11),
                          prefixText: '\$', prefixStyle: const TextStyle(color: cMuted, fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: cBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: cBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: cRed, width: 1.5)),
                          filled: true, fillColor: cBg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final min = double.tryParse(widget.minCtrl.text.trim());
                      final max = double.tryParse(widget.maxCtrl.text.trim());
                      widget.onApplyPrice(min, max);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cRed, foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    child: const Text('Apply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- COLLAPSIBLE SECTION ---
class _CollapsibleSection extends StatelessWidget {
  final String label;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _CollapsibleSection({
    required this.label,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: cMuted, letterSpacing: 1.2))),
                AnimatedRotation(
                  turns: expanded ? 0 : -0.25,
                  duration: kFast,
                  child: const Icon(Icons.expand_more_rounded, size: 16, color: cMuted),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Padding(padding: const EdgeInsets.only(bottom: 10), child: child),
          secondChild: const SizedBox.shrink(),
          crossFadeState: expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: kFast,
        ),
        Divider(height: 1, color: cBorder),
      ],
    );
  }
}

// --- FILTER BUTTON (mobile) ---
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

// --- MARKET CARD ---
class _MarketCard extends StatefulWidget {
  final MarketplaceItem item;
  final VoidCallback onTap;
  final bool compact;
  final String currentUserEmail;
  const _MarketCard({required this.item, required this.onTap, this.compact = false, this.currentUserEmail = ''});
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
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _hovered ? cRed.withValues(alpha: 0.35) : cBorder),
              boxShadow: [BoxShadow(
                color: _hovered ? cRed.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.05),
                blurRadius: _hovered ? 16 : 8, offset: const Offset(0, 2),
              )],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      Image.network(
                        widget.item.image,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(color: cPlaceholder, child: Center(child: Icon(Icons.image_not_supported, color: cMuted, size: 20))),
                      ),
                      Positioned(
                        top: 6, left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: cRed, borderRadius: BorderRadius.circular(6)),
                          child: Text(widget.item.category, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cText)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('\$${widget.item.price.toStringAsFixed(0)}',
                                style: const TextStyle(color: cRed, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: -0.3)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(5), border: Border.all(color: cBorder)),
                              child: Text(widget.item.condition, style: const TextStyle(fontSize: 8, color: cMuted, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 9, color: cMuted),
                            const SizedBox(width: 2),
                            Expanded(child: Text(widget.item.location, style: const TextStyle(fontSize: 9, color: cMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            GestureDetector(
                              onTap: () => showReportDialog(
                                context: context,
                                targetId: widget.item.id,
                                targetType: 'listing',
                                targetTitle: widget.item.title,
                                reporterEmail: widget.currentUserEmail,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flag_outlined, size: 10, color: cMuted),
                                  SizedBox(width: 2),
                                  Text('Report', style: TextStyle(fontSize: 8, color: cMuted, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
