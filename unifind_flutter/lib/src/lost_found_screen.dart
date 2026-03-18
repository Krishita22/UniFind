part of '../main.dart';

class LostFoundScreen extends StatefulWidget {
  final List<LostFoundItem> items;
  const LostFoundScreen({super.key, required this.items});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  String _cat = 'All';
  LostFilter _filter = LostFilter.all;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((i) {
      final cm = _cat == 'All' || i.category == _cat;
      final fm = _filter == LostFilter.all || i.type.name == _filter.name;
      final sm = i.title.toLowerCase().contains(_q.toLowerCase()) || i.description.toLowerCase().contains(_q.toLowerCase());
      return cm && fm && sm;
    }).toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lost & Found', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.5)),
              SizedBox(height: 2),
              Text('Help reunite students with their belongings!', style: TextStyle(fontSize: 12, color: cMuted)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _FilterChip(label: 'All', selected: _filter == LostFilter.all, onTap: () => setState(() => _filter = LostFilter.all)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Lost', selected: _filter == LostFilter.lost, onTap: () => setState(() => _filter = LostFilter.lost), color: const Color(0xFFE74C3C)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Found', selected: _filter == LostFilter.found, onTap: () => setState(() => _filter = LostFilter.found), color: const Color(0xFF27AE60)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: _SearchField(hint: 'Search lost & found...', onChanged: (v) => setState(() => _q = v)),
        ),
        SizedBox(
          height: 28,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: lostFoundCategories.map((c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(label: c, selected: _cat == c, onTap: () => setState(() => _cat = c)),
            )).toList(),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: filtered.isEmpty
              ? const _EmptyState(message: 'No items found')
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _LostFoundCard(item: filtered[i]),
                ),
        ),
      ],
    );
  }
}

class _LostFoundCard extends StatefulWidget {
  final LostFoundItem item;
  const _LostFoundCard({required this.item});

  @override
  State<_LostFoundCard> createState() => _LostFoundCardState();
}

class _LostFoundCardState extends State<_LostFoundCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kFast);
    _scale = Tween(begin: 1.0, end: 0.98).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isLost = widget.item.type == LostFoundType.lost;
    final typeColor = isLost ? const Color(0xFFE74C3C) : const Color(0xFF27AE60);
    final typeBg = isLost ? const Color(0xFFFDECEC) : const Color(0xFFECF9F0);

    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) => _c.reverse(),
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cBorder),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.item.image,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 80, height: 80, child: ColoredBox(color: cPlaceholder, child: Center(child: Icon(Icons.image_not_supported, color: cMuted)))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(widget.item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cText), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(8)),
                          child: Text(isLost ? 'Lost' : 'Found', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: typeColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(widget.item.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: cMuted, height: 1.5)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 11, color: cMuted),
                        const SizedBox(width: 3),
                        Expanded(child: Text('${widget.item.location} · ${widget.item.poster} · ${formatDate(widget.item.createdAt)}', style: const TextStyle(fontSize: 11, color: cMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
