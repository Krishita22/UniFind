part of '../main.dart';

class PostListingScreen extends StatefulWidget {
  final void Function(NewListingInput) onPost;
  final ListingType initialType;
  final bool hideSale;
  const PostListingScreen({
    super.key,
    required this.onPost,
    this.initialType = ListingType.marketplace,
    this.hideSale = false,
  });

  @override
  State<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends State<PostListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late ListingType _type;
  String _title = '', _desc = '', _cat = '', _cond = 'Good', _loc = '';
  double _price = 0;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  List<String> get _cats {
    if (_type == ListingType.marketplace) {
      return categories.where((c) => c != 'All').toList();
    } else {
      return lostFoundCategories;
    }
  }

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  Future<void> _pickFromSource(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 40,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not pick image: ${e.toString().replaceFirst('Exception: ', '')}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: cRedDark,
      ));
    }
  }

  Future<void> _pickImage() async {
    // On web/desktop, camera is not supported — skip the sheet and go straight to gallery.
    if (kIsWeb) {
      await _pickFromSource(ImageSource.gallery);
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () async {
                Navigator.pop(context);
                await _pickFromSource(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _pickFromSource(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showSuccessCard() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: cSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 20),
                const Text('Listing Posted!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cText)),
                const SizedBox(height: 8),
                const Text('Your item has been submitted\nand is pending review.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: cMuted, height: 1.6)),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _title = '';
                        _desc = '';
                        _cat = '';
                        _cond = 'Good';
                        _loc = '';
                        _price = 0;
                        _selectedImage = null;
                        _selectedImageBytes = null;
                        _formKey.currentState?.reset();
                      });
                    },
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [cRed, cRedDark]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Post an Item', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.4)),
                      Text('Create a new listing', style: TextStyle(fontSize: 15, color: cMuted)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Type selector
              _FormLabel(label: 'Listing Type'),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (!widget.hideSale) ...[
                    Expanded(child: _TypeBtn(label: 'For Sale', type: ListingType.marketplace, selected: _type == ListingType.marketplace, onTap: () => setState(() { _type = ListingType.marketplace; _cat = ''; }))),
                    const SizedBox(width: 8),
                  ],
                  Expanded(child: _TypeBtn(label: 'Lost', type: ListingType.lost, selected: _type == ListingType.lost, onTap: () => setState(() { _type = ListingType.lost; _cat = ''; }))),
                  const SizedBox(width: 8),
                  Expanded(child: _TypeBtn(label: 'Found', type: ListingType.found, selected: _type == ListingType.found, onTap: () => setState(() { _type = ListingType.found; _cat = ''; }))),
                ],
              ),
              const SizedBox(height: 16),
              _StyledField(
                label: 'Title *',
                hint: 'What are you listing?',
                icon: Icons.title_rounded,
                onChanged: (v) => _title = v,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              _FormLabel(label: 'Description *'),
              const SizedBox(height: 6),
              TextFormField(
                maxLines: 4,
                onChanged: (v) => _desc = v,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                decoration: InputDecoration(
                  hintText: 'Describe your item...',
                  hintStyle: const TextStyle(color: cMuted, fontSize: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cRed, width: 2)),
                  filled: true,
                  fillColor: cBg,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              if (_type == ListingType.marketplace) ...[
                const SizedBox(height: 12),
                _StyledField(
                  label: 'Price *',
                  hint: '0.00',
                  icon: Icons.attach_money_rounded,
                  validator: (v) {
                    final p = double.tryParse(v ?? '');
                    return (p == null || p <= 0) ? 'Enter a valid price' : null;
                  },
                  onChanged: (v) => _price = double.tryParse(v) ?? 0,
                ),
                const SizedBox(height: 12),
                _FormLabel(label: 'Condition *'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _cond,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cRed, width: 2)),
                    filled: true,
                    fillColor: cBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  items: ['New', 'Like New', 'Good', 'Fair'].map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
                  onChanged: (v) => setState(() => _cond = v ?? 'Good'),
                ),
              ],
              const SizedBox(height: 12),
              _FormLabel(label: 'Category *'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _cat.isEmpty ? null : _cat,
                hint: const Text('Select a category', style: TextStyle(color: cMuted)),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cRed, width: 2)),
                  filled: true,
                  fillColor: cBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                items: _cats.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
                onChanged: (v) => setState(() => _cat = v ?? ''),
                validator: (v) => (v == null || v.isEmpty) ? 'Category is required' : null,
              ),
              const SizedBox(height: 12),
              if (_type != ListingType.marketplace) ...[
                const SizedBox(height: 12),
                _StyledField(
                  label: 'Location *',
                  hint: 'e.g. Blanton Hall',
                  icon: Icons.location_on_outlined,
                  onChanged: (v) => _loc = v,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Location is required' : null,
                ),
              ],
              const SizedBox(height: 12),
              _FormLabel(label: 'Image'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cBorder),
                  ),
                  child: _selectedImageBytes == null
                      ? const Row(
                          children: [
                            Icon(Icons.add_a_photo_outlined, color: cMuted),
                            SizedBox(width: 10),
                            Text('Tap to add image', style: TextStyle(color: cMuted)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _selectedImageBytes!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              _AuthButton(loading: _isUploading, onTap: _submit, label: 'Post Item'),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isUploading = true);
    try {
      String imageUrl = 'https://placehold.co/400x400?text=?';
      if (_selectedImage != null && _selectedImageBytes != null) {
        imageUrl = await uploadImage(
          _selectedImage!.path,
          _selectedImageBytes!,
          type: _type == ListingType.marketplace ? 'marketplace' : 'lostfound',
        );
      }

      widget.onPost(NewListingInput(
        type: _type,
        title: _title.trim(),
        description: _desc.trim(),
        category: _cat,
        condition: _cond,
        location: _loc.trim(),
        price: _price,
        imageUrl: imageUrl,
      ));

      _showSuccessCard();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload/post item: $e'),
          backgroundColor: cRedDark,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cText, letterSpacing: 0.3));
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final ListingType type;
  final bool selected;
  final VoidCallback onTap;
  const _TypeBtn({required this.label, required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: kMid,
        height: 40,
        decoration: BoxDecoration(
          gradient: selected ? const LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
          color: selected ? null : cSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.transparent : cBorder, width: 1.5),
          boxShadow: selected ? [BoxShadow(color: cRed.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : cMuted)),
        ),
      ),
    );
  }
}
