import 'package:flutter/material.dart';

void main() {
  runApp(const UniFindApp());
}

class UniFindApp extends StatefulWidget {
  const UniFindApp({super.key});

  @override
  State<UniFindApp> createState() => _UniFindAppState();
}

class _UniFindAppState extends State<UniFindApp> {
  int _selectedIndex = 0;

  final List<MarketplaceItem> _marketplaceItems =
      List<MarketplaceItem>.from(seedMarketplaceItems);
  final List<LostFoundItem> _lostFoundItems =
      List<LostFoundItem>.from(seedLostFoundItems);

  void _addListing(NewListingInput input) {
    setState(() {
      if (input.type == ListingType.marketplace) {
        _marketplaceItems.insert(
          0,
          MarketplaceItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: input.title,
            price: input.price,
            description: input.description,
            category: input.category,
            condition: input.condition,
            image: input.imageUrl,
            seller: 'You',
            createdAt: DateTime.now(),
            location: input.location,
          ),
        );
      } else {
        _lostFoundItems.insert(
          0,
          LostFoundItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: input.title,
            description: input.description,
            category: input.category,
            type: input.type == ListingType.lost
                ? LostFoundType.lost
                : LostFoundType.found,
            image: input.imageUrl,
            poster: 'You',
            createdAt: DateTime.now(),
            location: input.location,
            status: 'active',
          ),
        );
      }
      _selectedIndex = input.type == ListingType.marketplace ? 0 : 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniFind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB91C1C)),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFB91C1C),
          foregroundColor: Colors.white,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('UniFind', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Montclair State', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            MarketplaceScreen(items: _marketplaceItems),
            LostFoundScreen(items: _lostFoundItems),
            PostListingScreen(onPost: _addListing),
            MyListingsScreen(
              marketplaceItems: _marketplaceItems
                  .where((item) => item.seller == 'You')
                  .toList(),
              lostFoundItems: _lostFoundItems
                  .where((item) => item.poster == 'You')
                  .toList(),
            ),
            const DocumentationScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.storefront_outlined), label: 'Shop'),
            NavigationDestination(
                icon: Icon(Icons.search), label: 'Lost/Found'),
            NavigationDestination(
                icon: Icon(Icons.add_circle_outline), label: 'Post'),
            NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined), label: 'My'),
            NavigationDestination(
                icon: Icon(Icons.menu_book_outlined), label: 'Docs'),
          ],
        ),
      ),
    );
  }
}

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key, required this.items});

  final List<MarketplaceItem> items;

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String selectedCategory = 'All';
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items.where((item) {
      final categoryMatch =
          selectedCategory == 'All' || item.category == selectedCategory;
      final query = searchQuery.toLowerCase();
      final searchMatch = item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
      return categoryMatch && searchMatch;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search marketplace...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => searchQuery = value),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: categories
                .map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => selectedCategory = category),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filteredItems.isEmpty
              ? const Center(
                  child: Text('No items found matching your criteria'))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ItemDetailScreen(item: item),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Image.network(
                                item.image,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const ColoredBox(
                                  color: Color(0xFFE5E7EB),
                                  child: Center(
                                      child: Icon(Icons.image_not_supported)),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '\$${item.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Color(0xFFB91C1C),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(item.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.location,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    item.condition,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key, required this.items});

  final List<LostFoundItem> items;

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  String selectedCategory = 'All';
  LostFilter selectedType = LostFilter.all;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items.where((item) {
      final categoryMatch =
          selectedCategory == 'All' || item.category == selectedCategory;
      final typeMatch =
          selectedType == LostFilter.all || item.type.name == selectedType.name;
      final query = searchQuery.toLowerCase();
      final searchMatch = item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
      return categoryMatch && typeMatch && searchMatch;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Lost & Found',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Help fellow students reunite with their belongings'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () =>
                      setState(() => selectedType = LostFilter.all),
                  style: FilledButton.styleFrom(
                    backgroundColor: selectedType == LostFilter.all
                        ? const Color(0xFFB91C1C)
                        : null,
                    foregroundColor:
                        selectedType == LostFilter.all ? Colors.white : null,
                  ),
                  child: const Text('All'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () =>
                      setState(() => selectedType = LostFilter.lost),
                  style: FilledButton.styleFrom(
                    backgroundColor: selectedType == LostFilter.lost
                        ? const Color(0xFFEA580C)
                        : null,
                    foregroundColor:
                        selectedType == LostFilter.lost ? Colors.white : null,
                  ),
                  child: const Text('Lost'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () =>
                      setState(() => selectedType = LostFilter.found),
                  style: FilledButton.styleFrom(
                    backgroundColor: selectedType == LostFilter.found
                        ? const Color(0xFF16A34A)
                        : null,
                    foregroundColor:
                        selectedType == LostFilter.found ? Colors.white : null,
                  ),
                  child: const Text('Found'),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search lost & found items...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => searchQuery = value),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: lostFoundCategories
                .map(
                  (category) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => selectedCategory = category),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filteredItems.isEmpty
              ? const Center(
                  child: Text('No items found matching your criteria'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.image,
                                width: 82,
                                height: 82,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  width: 82,
                                  height: 82,
                                  child: ColoredBox(
                                    color: Color(0xFFE5E7EB),
                                    child: Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: item.type == LostFoundType.lost
                                              ? const Color(0xFFFED7AA)
                                              : const Color(0xFFDCFCE7),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          item.type == LostFoundType.lost
                                              ? 'Lost'
                                              : 'Found',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                item.type == LostFoundType.lost
                                                    ? const Color(0xFF9A3412)
                                                    : const Color(0xFF166534),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        const TextStyle(color: Colors.black54),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.location} • ${item.poster} • ${formatDate(item.createdAt)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black45),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class PostListingScreen extends StatefulWidget {
  const PostListingScreen({super.key, required this.onPost});

  final void Function(NewListingInput input) onPost;

  @override
  State<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends State<PostListingScreen> {
  final _formKey = GlobalKey<FormState>();

  ListingType listingType = ListingType.marketplace;
  String title = '';
  String description = '';
  String category = '';
  String condition = 'Good';
  String location = '';
  double price = 0;

  List<String> get _availableCategories =>
      listingType == ListingType.marketplace
          ? categories.where((item) => item != 'All').toList()
          : lostFoundCategories.where((item) => item != 'All').toList();

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
              const Text('Post an Item',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              const Text('Listing Type',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _typeButton(
                        label: 'For Sale', type: ListingType.marketplace),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _typeButton(label: 'Lost', type: ListingType.lost),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _typeButton(label: 'Found', type: ListingType.found),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                    labelText: 'Title *', border: OutlineInputBorder()),
                onChanged: (value) => title = value,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                ),
                minLines: 3,
                maxLines: 5,
                onChanged: (value) => description = value,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              if (listingType == ListingType.marketplace) ...[
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Price *',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => price = double.tryParse(value) ?? 0,
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: condition,
                  decoration: const InputDecoration(
                    labelText: 'Condition *',
                    border: OutlineInputBorder(),
                  ),
                  items: const ['New', 'Like New', 'Good', 'Fair']
                      .map((item) =>
                          DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => condition = value ?? 'Good'),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category.isEmpty ? null : category,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: _availableCategories
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) => setState(() => category = value ?? ''),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Category is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => location = value,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Location is required'
                    : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Post Item'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeButton({required String label, required ListingType type}) {
    final selected = listingType == type;
    Color? background;
    if (selected && type == ListingType.marketplace) {
      background = const Color(0xFFB91C1C);
    }
    if (selected && type == ListingType.lost) {
      background = const Color(0xFFEA580C);
    }
    if (selected && type == ListingType.found) {
      background = const Color(0xFF16A34A);
    }

    return FilledButton.tonal(
      onPressed: () => setState(() {
        listingType = type;
        category = '';
      }),
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: selected ? Colors.white : null,
      ),
      child: Text(label),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    widget.onPost(
      NewListingInput(
        type: listingType,
        title: title.trim(),
        description: description.trim(),
        category: category,
        condition: condition,
        location: location.trim(),
        price: price,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item posted successfully.')),
    );

    setState(() {
      title = '';
      description = '';
      category = '';
      condition = 'Good';
      location = '';
      price = 0;
      _formKey.currentState?.reset();
    });
  }
}

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({
    super.key,
    required this.marketplaceItems,
    required this.lostFoundItems,
  });

  final List<MarketplaceItem> marketplaceItems;
  final List<LostFoundItem> lostFoundItems;

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  bool showMarketplace = true;

  @override
  Widget build(BuildContext context) {
    final isEmpty = showMarketplace
        ? widget.marketplaceItems.isEmpty
        : widget.lostFoundItems.isEmpty;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Listings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Marketplace Items'),
                selected: showMarketplace,
                onSelected: (_) => setState(() => showMarketplace = true),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Lost & Found'),
                selected: !showMarketplace,
                onSelected: (_) => setState(() => showMarketplace = false),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: isEmpty
                ? Center(
                    child: Text(
                      showMarketplace
                          ? 'You have not posted any marketplace items yet.'
                          : 'You have not posted any lost/found items yet.',
                    ),
                  )
                : ListView(
                    children: showMarketplace
                        ? widget.marketplaceItems
                            .map(
                              (item) => Card(
                                child: ListTile(
                                  leading: const Icon(Icons.storefront),
                                  title: Text(item.title),
                                  subtitle: Text(
                                      '${item.category} • ${item.location}'),
                                  trailing: Text(
                                      '\$${item.price.toStringAsFixed(0)}'),
                                ),
                              ),
                            )
                            .toList()
                        : widget.lostFoundItems
                            .map(
                              (item) => Card(
                                child: ListTile(
                                  leading: Icon(item.type == LostFoundType.lost
                                      ? Icons.report_problem_outlined
                                      : Icons.check_circle_outline),
                                  title: Text(item.title),
                                  subtitle: Text(
                                      '${item.category} • ${item.location}'),
                                  trailing: Text(item.type == LostFoundType.lost
                                      ? 'Lost'
                                      : 'Found'),
                                ),
                              ),
                            )
                            .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class DocumentationScreen extends StatelessWidget {
  const DocumentationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('UniFind Documentation',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        Text(
          'UniFind is a campus marketplace and lost-and-found app for Montclair State University. '
          'This Flutter version mirrors the React flows: browse, filter, post, and track your listings.',
        ),
        SizedBox(height: 12),
        Text('Core Features', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 6),
        Text('• Marketplace browsing with category and search filters'),
        Text('• Lost & Found feed with Lost/Found filtering'),
        Text('• Listing creation form for all listing types'),
        Text('• Item detail view and personal listing history'),
      ],
    );
  }
}

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.item});

  final MarketplaceItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFFE5E7EB),
                  child: Center(child: Icon(Icons.image_not_supported)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '\$${item.price.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Color(0xFFB91C1C),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(item.title,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Condition: ${item.condition}'),
                  Text('Location: ${item.location}'),
                  Text('Posted: ${formatDate(item.createdAt)}'),
                  Text('Category: ${item.category}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Description',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(item.description),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Seller'),
              subtitle: Text(item.seller),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Contact flow can be connected to chat/API next.')),
              );
            },
            icon: const Icon(Icons.message_outlined),
            label: const Text('Contact Seller'),
          ),
        ],
      ),
    );
  }
}

enum ListingType { marketplace, lost, found }

enum LostFoundType { lost, found }

enum LostFilter { all, lost, found }

class NewListingInput {
  const NewListingInput({
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.location,
    required this.price,
    this.imageUrl =
        'https://images.unsplash.com/photo-1517466787929-bc90951d0974?w=400',
  });

  final ListingType type;
  final String title;
  final String description;
  final String category;
  final String condition;
  final String location;
  final double price;
  final String imageUrl;
}

class MarketplaceItem {
  const MarketplaceItem({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.condition,
    required this.image,
    required this.seller,
    required this.createdAt,
    required this.location,
  });

  final String id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String condition;
  final String image;
  final String seller;
  final DateTime createdAt;
  final String location;
}

class LostFoundItem {
  const LostFoundItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.image,
    required this.poster,
    required this.createdAt,
    required this.location,
    required this.status,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final LostFoundType type;
  final String image;
  final String poster;
  final DateTime createdAt;
  final String location;
  final String status;
}

String formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$month/$day/${date.year}';
}

const List<String> categories = [
  'All',
  'Textbooks',
  'Electronics',
  'Furniture',
  'Clothing',
  'Other',
];

const List<String> lostFoundCategories = [
  'All',
  'Electronics',
  'Bags',
  'Keys',
  'ID/Cards',
  'Clothing',
  'Other',
];

final List<MarketplaceItem> seedMarketplaceItems = [
  MarketplaceItem(
    id: '1',
    title: 'Chemistry Textbook - 11th Edition',
    price: 45,
    description:
        'Barely used chemistry textbook. Perfect condition with no highlighting or notes.',
    category: 'Textbooks',
    condition: 'Like New',
    image: 'https://images.unsplash.com/photo-1589998059171-988d887df646?w=400',
    seller: 'Sarah M.',
    createdAt: DateTime(2026, 2, 10),
    location: 'Blanton Hall',
  ),
  MarketplaceItem(
    id: '2',
    title: 'Mini Fridge - Perfect for Dorms',
    price: 80,
    description:
        'Compact mini fridge, great for dorm rooms. Works perfectly, very quiet.',
    category: 'Furniture',
    condition: 'Good',
    image: 'https://images.unsplash.com/photo-1571175443880-49e1d25b2bc5?w=400',
    seller: 'Mike T.',
    createdAt: DateTime(2026, 2, 9),
    location: 'Freeman Hall',
  ),
  MarketplaceItem(
    id: '3',
    title: 'Scientific Calculator TI-84',
    price: 60,
    description:
        'TI-84 Plus graphing calculator. Great for math and science courses.',
    category: 'Electronics',
    condition: 'Good',
    image: 'https://images.unsplash.com/photo-1611367840531-628f328d9a49?w=400',
    seller: 'Jessica L.',
    createdAt: DateTime(2026, 2, 8),
    location: 'Student Center',
  ),
  MarketplaceItem(
    id: '4',
    title: 'Desk Lamp with USB Port',
    price: 15,
    description:
        'LED desk lamp with adjustable brightness and USB charging port.',
    category: 'Furniture',
    condition: 'Like New',
    image: 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=400',
    seller: 'Alex K.',
    createdAt: DateTime(2026, 2, 7),
    location: 'Bohn Hall',
  ),
  MarketplaceItem(
    id: '5',
    title: 'MacBook Pro Charger',
    price: 30,
    description:
        'Original Apple 61W USB-C power adapter. Compatible with MacBook Pro.',
    category: 'Electronics',
    condition: 'Good',
    image: 'https://images.unsplash.com/photo-1591290619762-d06df1a8a8b0?w=400',
    seller: 'David R.',
    createdAt: DateTime(2026, 2, 6),
    location: 'Library',
  ),
  MarketplaceItem(
    id: '6',
    title: 'Biology Lab Coat',
    price: 12,
    description: 'White lab coat, size medium. Lightly used for one semester.',
    category: 'Other',
    condition: 'Good',
    image: 'https://images.unsplash.com/photo-1576671081837-49000212a370?w=400',
    seller: 'Emma W.',
    createdAt: DateTime(2026, 2, 5),
    location: 'Richardson Hall',
  ),
];

final List<LostFoundItem> seedLostFoundItems = [
  LostFoundItem(
    id: 'lf1',
    title: 'Black Backpack with Laptop',
    description:
        'Lost black Jansport backpack containing a laptop and notebooks. Left in the library on the 3rd floor.',
    category: 'Bags',
    type: LostFoundType.lost,
    image: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400',
    poster: 'James P.',
    createdAt: DateTime(2026, 2, 11),
    location: 'Sprague Library - 3rd Floor',
    status: 'active',
  ),
  LostFoundItem(
    id: 'lf2',
    title: 'Found: AirPods in Case',
    description:
        'Found AirPods with charging case near the dining hall entrance.',
    category: 'Electronics',
    type: LostFoundType.found,
    image: 'https://images.unsplash.com/photo-1606841837239-c5a1a4a07af7?w=400',
    poster: 'Maria G.',
    createdAt: DateTime(2026, 2, 10),
    location: 'Student Center Dining Hall',
    status: 'active',
  ),
  LostFoundItem(
    id: 'lf3',
    title: 'Lost Student ID Card',
    description:
        'Lost my student ID card somewhere between Dickson Hall and the parking lot.',
    category: 'ID/Cards',
    type: LostFoundType.lost,
    image: 'https://images.unsplash.com/photo-1585155770958-eeb77df44de8?w=400',
    poster: 'Kevin S.',
    createdAt: DateTime(2026, 2, 9),
    location: 'Between Dickson Hall & Lot 60',
    status: 'active',
  ),
  LostFoundItem(
    id: 'lf4',
    title: 'Found: Red Water Bottle',
    description: 'Hydro Flask water bottle found in the gym locker room.',
    category: 'Other',
    type: LostFoundType.found,
    image: 'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=400',
    poster: 'Lisa M.',
    createdAt: DateTime(2026, 2, 9),
    location: 'Recreation Center',
    status: 'active',
  ),
  LostFoundItem(
    id: 'lf5',
    title: 'Lost Keys with Red Keychain',
    description:
        'Lost my keys with a distinctive red bottle opener keychain. Please contact if found!',
    category: 'Keys',
    type: LostFoundType.lost,
    image: 'https://images.unsplash.com/photo-1582139329536-e7284fece509?w=400',
    poster: 'Ryan B.',
    createdAt: DateTime(2026, 2, 8),
    location: 'University Hall',
    status: 'active',
  ),
];
