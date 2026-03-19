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

  Future<void> _editMarketplace(MarketplaceItem item) async {
    final titleCtrl = TextEditingController(text: item.title);
    final descCtrl = TextEditingController(text: item.description);
    final priceCtrl = TextEditingController(text: item.price.toStringAsFixed(0));
    final locCtrl = TextEditingController(text: item.location);
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
                          ? Image.memory(
                              selectedImageBytes!,
                              fit: BoxFit.cover,
                            )
                          : (item.image.trim().isNotEmpty
                                ? Image.network(
                                    item.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Text(
                                        'Current image unavailable',
                                        style: TextStyle(color: cMuted),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: Text(
                                      'Tap to add image',
                                      style: TextStyle(color: cMuted),
                                    ),
                                  )),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tap image to change',
                    style: TextStyle(fontSize: 11, color: cMuted),
                  ),
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
                final loc = locCtrl.text.trim();
                if (title.isEmpty || desc.isEmpty || loc.isEmpty || price <= 0) {
                  setDialogState(() => error = 'Please complete all fields with a valid price.');
                  return;
                }
                setDialogState(() {
                  saving = true;
                  error = null;
                });
                try {
                  String? imageUrl;
                  if (selectedImage != null && selectedImageBytes != null) {
                    imageUrl = await uploadImage(
                      selectedImage!.path,
                      selectedImageBytes!,
                    );
                  }

                  await widget.onEditMarketplace(
                    item,
                    MarketplaceUpdateInput(
                      title: title,
                      description: desc,
                      category: category,
                      condition: condition,
                      location: loc,
                      price: price,
                      imageUrl: imageUrl,
                    ),
                  );
                  if (mounted) Navigator.pop(ctx);
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
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: lostFoundCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
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
                          ? Image.memory(
                              selectedImageBytes!,
                              fit: BoxFit.cover,
                            )
                          : (item.image.trim().isNotEmpty
                                ? Image.network(
                                    item.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Text(
                                        'Current image unavailable',
                                        style: TextStyle(color: cMuted),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: Text(
                                      'Tap to add image',
                                      style: TextStyle(color: cMuted),
                                    ),
                                  )),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tap image to change',
                    style: TextStyle(fontSize: 11, color: cMuted),
                  ),
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
                setDialogState(() {
                  saving = true;
                  error = null;
                });
                try {
                  String? imageUrl;
                  if (selectedImage != null && selectedImageBytes != null) {
                    imageUrl = await uploadImage(
                      selectedImage!.path,
                      selectedImageBytes!,
                    );
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
                  if (mounted) Navigator.pop(ctx);
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
