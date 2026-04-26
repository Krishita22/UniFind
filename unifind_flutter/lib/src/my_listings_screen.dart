part of '../main.dart';

class MyListingsScreen extends StatefulWidget {
  final List<MarketplaceItem> marketplaceItems;
  final List<LostFoundItem> lostFoundItems;
  final VoidCallback onListItem;
  final Future<void> Function(MarketplaceItem item, MarketplaceUpdateInput update) onEditMarketplace;
  final Future<void> Function(LostFoundItem item, LostFoundUpdateInput update) onEditLostFound;
  final Future<void> Function(MarketplaceItem item) onDeleteMarketplace;
  final Future<void> Function(LostFoundItem item) onDeleteLostFound;
  final bool lostFoundOnly;
  const MyListingsScreen({
    super.key,
    required this.marketplaceItems,
    required this.lostFoundItems,
    required this.onListItem,
    required this.onEditMarketplace,
    required this.onEditLostFound,
    required this.onDeleteMarketplace,
    required this.onDeleteLostFound,
    this.lostFoundOnly = false,
  });

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  bool _showMarket = true;

  @override
  void initState() {
    super.initState();
    if (widget.lostFoundOnly) _showMarket = false;
  }

  Future<void> _deleteMarketplace(MarketplaceItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Listing'),
        content: Text('Are you sure you want to delete "${item.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: cRed, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.onDeleteMarketplace(item);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing deleted.'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e'), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 5)),
      );
    }
  }

  Future<void> _deleteLostFound(LostFoundItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Post'),
        content: Text('Are you sure you want to delete "${item.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: cRed, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.onDeleteLostFound(item);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted.'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e'), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 5)),
      );
    }
  }

  Future<void> _editMarketplace(MarketplaceItem item) async {
    final titleCtrl = TextEditingController(text: item.title);
    final descCtrl = TextEditingController(text: item.description);
    final priceCtrl = TextEditingController(text: item.price.toStringAsFixed(2));
    final picker = ImagePicker();
    String category = item.category;
    String condition = item.condition;
    XFile? selectedImage;
    Uint8List? selectedImageBytes;
    bool saving = false;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Marketplace Listing'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 8),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Price'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => category = v ?? category),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: condition,
                  decoration: const InputDecoration(labelText: 'Condition'),
                  items: const ['New', 'Like New', 'Good', 'Fair']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => condition = v ?? condition),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Image',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cText.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: saving
                      ? null
                      : () async {
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 55,
                            maxWidth: 1200,
                            maxHeight: 1200,
                          );
                          if (picked == null) return;
                          final bytes = await picked.readAsBytes();
                          setDialogState(() {
                            selectedImage = picked;
                            selectedImageBytes = bytes;
                          });
                        },
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: cBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cBorder),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: selectedImageBytes != null
                          ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                          : (item.image.trim().isNotEmpty
                                ? Image.network(
                                    item.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Text('Current image unavailable', style: TextStyle(color: cMuted)),
                                    ),
                                  )
                                : const Center(
                                    child: Text('Tap to add image', style: TextStyle(color: cMuted)),
                                  )),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Tap image to change', style: TextStyle(fontSize: 11, color: cMuted)),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: cRedDark, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            _RedButton(
              label: 'Save',
              icon: Icons.check_rounded,
              onTap: () async {
                if (saving) return;
                final title = titleCtrl.text.trim();
                final desc = descCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
                if (title.isEmpty || desc.isEmpty || price <= 0) {
                  setDialogState(() => error = 'Please complete all fields with a valid price.');
                  return;
                }
                setDialogState(() { saving = true; error = null; });
                try {
                  String? imageUrl;
                  if (selectedImage != null && selectedImageBytes != null) {
                    imageUrl = await uploadImage(selectedImage!.path, selectedImageBytes!, type: 'marketplace');
                  }
                  await widget.onEditMarketplace(
                    item,
                    MarketplaceUpdateInput(
                      title: title,
                      description: desc,
                      category: category,
                      condition: condition,
                      location: '',
                      price: price,
                      imageUrl: imageUrl,
                    ),
                  );
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  await showDialog<void>(
                    context: context,
                    builder: (ctx2) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      content: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.admin_panel_settings_rounded, color: cRed, size: 28),
                        ),
                        const SizedBox(height: 14),
                        const Text('Sent for Reapproval', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cText)),
                        const SizedBox(height: 8),
                        const Text(
                          'Your listing has been updated and sent to admin for reapproval. It will be visible again once approved.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: cMuted, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx2),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cRed, foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ]),
                    ),
                  );
                } catch (e) {
                  setDialogState(() {
                    error = 'Failed to save changes. ${e.toString().replaceFirst('Exception: ', '')}';
                    saving = false;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editLostFound(LostFoundItem item) async {
    final titleCtrl = TextEditingController(text: item.title);
    final descCtrl = TextEditingController(text: item.description);
    final locCtrl = TextEditingController(text: item.location);
    final picker = ImagePicker();
    String category = item.category;
    XFile? selectedImage;
    Uint8List? selectedImageBytes;
    bool saving = false;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Lost & Found Listing'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: category.isEmpty ? null : category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: {category, ...lostFoundCategories, ...categories}.where((c) => c.isNotEmpty).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => category = v ?? category),
                ),
                const SizedBox(height: 8),
                TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Location')),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Image',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cText.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: saving
                      ? null
                      : () async {
                          final picked = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 55,
                            maxWidth: 1200,
                            maxHeight: 1200,
                          );
                          if (picked == null) return;
                          final bytes = await picked.readAsBytes();
                          setDialogState(() {
                            selectedImage = picked;
                            selectedImageBytes = bytes;
                          });
                        },
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: cBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cBorder),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: selectedImageBytes != null
                          ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                          : (item.image.trim().isNotEmpty
                                ? Image.network(
                                    item.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Text('Current image unavailable', style: TextStyle(color: cMuted)),
                                    ),
                                  )
                                : const Center(
                                    child: Text('Tap to add image', style: TextStyle(color: cMuted)),
                                  )),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Tap image to change', style: TextStyle(fontSize: 11, color: cMuted)),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: cRedDark, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            _RedButton(
              label: 'Save',
              icon: Icons.check_rounded,
              onTap: () async {
                if (saving) return;
                final title = titleCtrl.text.trim();
                final desc = descCtrl.text.trim();
                final loc = locCtrl.text.trim();
                if (title.isEmpty || desc.isEmpty || loc.isEmpty) {
                  setDialogState(() => error = 'Please complete all required fields.');
                  return;
                }
                setDialogState(() { saving = true; error = null; });
                try {
                  String? imageUrl;
                  if (selectedImage != null && selectedImageBytes != null) {
                    imageUrl = await uploadImage(selectedImage!.path, selectedImageBytes!, type: 'lostfound');
                  }
                  await widget.onEditLostFound(
                    item,
                    LostFoundUpdateInput(
                      title: title,
                      description: desc,
                      category: category,
                      location: loc,
                      imageUrl: imageUrl,
                    ),
                  );
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  await showDialog<void>(
                    context: context,
                    builder: (ctx2) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      content: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.admin_panel_settings_rounded, color: cRed, size: 28),
                        ),
                        const SizedBox(height: 14),
                        const Text('Sent for Reapproval', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cText)),
                        const SizedBox(height: 8),
                        const Text(
                          'Your post has been updated and sent to admin for reapproval. It will be visible again once approved.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: cMuted, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx2),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cRed, foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ]),
                    ),
                  );
                } catch (e) {
                  setDialogState(() {
                    error = 'Failed to save changes. ${e.toString().replaceFirst('Exception: ', '')}';
                    saving = false;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

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
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [cRed, cRedDark]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Listings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.4)),
                    Text('Your active posts', style: TextStyle(fontSize: 15, color: cMuted)),
                  ],
                ),
              ),
              _RedButton(label: 'New Post', icon: Icons.add_rounded, onTap: widget.onListItem),
            ],
          ),
          const SizedBox(height: 16),
            if (!widget.lostFoundOnly)
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
                              subtitle: '${i.category} · ${i.condition}',
                              trailing: '\$${i.price.toStringAsFixed(2)}',
                              icon: Icons.storefront_rounded,
                              status: i.status,
                              imageUrl: i.image,
                              onTap: () => _editMarketplace(i),
                              onDelete: () => _deleteMarketplace(i),
                            )).toList()
                        : widget.lostFoundItems.map((i) => _MyListingTile(
                              title: i.title,
                              subtitle: '${i.category} · ${i.location}',
                              trailing: i.type == LostFoundType.lost ? 'Lost' : 'Found',
                              icon: i.type == LostFoundType.lost ? Icons.report_problem_outlined : Icons.check_circle_outline_rounded,
                              trailingColor: i.type == LostFoundType.lost ? const Color(0xFFE74C3C) : const Color(0xFF27AE60),
                              trailingBgColor: i.type == LostFoundType.lost ? const Color(0xFFFDECEC) : const Color(0xFFECF9F0),
                              status: i.status,
                              imageUrl: i.image,
                              onTap: () => _editLostFound(i),
                              onDelete: () => _deleteLostFound(i),
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
  final String imageUrl;
  final Color trailingColor;
  final Color trailingBgColor;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final String status;
  const _MyListingTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.icon,
    this.imageUrl = '',
    this.trailingColor = cRed,
    this.trailingBgColor = cRedLight,
    this.onTap,
    this.onDelete,
    this.status = 'active',
  });

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case 'pending': return const Color(0xFFE67E22);
      case 'active': case 'approved': return const Color(0xFF27AE60);
      case 'denied': case 'rejected': return const Color(0xFFE74C3C);
      case 'claimed': return const Color(0xFF2980B9);
      default: return cMuted;
    }
  }

  Color get _statusBg {
    switch (status.toLowerCase()) {
      case 'pending': return const Color(0xFFFEF3E2);
      case 'active': case 'approved': return const Color(0xFFECF9F0);
      case 'denied': case 'rejected': return const Color(0xFFFDECEC);
      case 'claimed': return const Color(0xFFEBF5FB);
      default: return cRedLight;
    }
  }

  String get _statusLabel {
    switch (status.toLowerCase()) {
      case 'active': return 'Approved';
      case 'pending': return 'Pending';
      case 'denied': return 'Denied';
      case 'claimed': return 'Claimed';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: hasImage
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: cRedLight,
                          child: Icon(icon, color: cRed, size: 20),
                        ),
                      )
                    : Container(
                        color: cRedLight,
                        child: Icon(icon, color: cRed, size: 20),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cText)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: cMuted)),
                  const SizedBox(height: 4),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(_statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit_outlined, size: 15, color: cMuted),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline_rounded, size: 15, color: cRed),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: trailingBgColor, borderRadius: BorderRadius.circular(8)),
              child: Text(
                trailing,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: trailingColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}