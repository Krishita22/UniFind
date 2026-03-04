
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

const Color appPrimaryColor = Color(0xFFA12727);
const Color appBackgroundColor = Color(0xFFFFFFFF);
const Color appMutedTextColor = Color(0xFF7A4A4A);
const Color appPlaceholderColor = Color(0xFFEBD1D1);

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
  bool _isLoggedIn = false;
  String _currentUserEmail = '';

  // Lists start with seed data as fallback,
  // then get replaced by API data once loaded
  List<MarketplaceItem> _marketplaceItems =
      List<MarketplaceItem>.from(seedMarketplaceItems);
  List<LostFoundItem> _lostFoundItems =
      List<LostFoundItem>.from(seedLostFoundItems);

  /// Uses the logged-in identity as listing owner so "My Listings" stays scoped
  /// to the active account instead of a hardcoded placeholder.
  String get _activeOwner =>
      _currentUserEmail.isEmpty ? 'You' : _currentUserEmail;

  /// Fetches marketplace listings from the API.
  /// Falls back to seed data if the API returns nothing or fails.
  Future<void> _loadListings() async {
    try {
      final apiItems = await getListings();
      if (apiItems.isNotEmpty) {
        setState(() {
          _marketplaceItems = apiItems.map((item) => MarketplaceItem(
            id:          item['id'].toString(),
            title:       item['title'],
            price:       (item['price'] as num).toDouble(),
            description: item['description'],
            category:    item['category'],
            condition:   item['condition'],
            image:       item['image'] ?? '',
            seller:      item['seller'] ?? '',
            createdAt:   DateTime.tryParse(item['createdAt'] ?? '') ?? DateTime.now(),
            location:    item['location'] ?? '',
          )).toList();
        });
      }
      // If API returns empty, seed data stays as fallback
    } catch (_) {
      // API failed — seed data stays as fallback
    }
  }

  /// Fetches lost & found items from the API.
  /// Falls back to seed data if the API returns nothing or fails.
  Future<void> _loadLostFound() async {
    try {
      final apiItems = await getLostFoundItems();
      if (apiItems.isNotEmpty) {
        setState(() {
          _lostFoundItems = apiItems.map((item) => LostFoundItem(
            id:          item['id'].toString(),
            title:       item['title'],
            description: item['description'],
            category:    item['category'],
            type:        item['type'] == 'lost' ? LostFoundType.lost : LostFoundType.found,
            image:       item['image'] ?? '',
            poster:      item['poster'] ?? '',
            createdAt:   DateTime.tryParse(item['createdAt'] ?? '') ?? DateTime.now(),
            location:    item['location'] ?? '',
            status:      item['status'] ?? 'active',
          )).toList();
        });
      }
      // If API returns empty, seed data stays as fallback
    } catch (_) {
      // API failed — seed data stays as fallback
    }
  }

  @override
  void initState() {
    super.initState();
    // Load data from API when the app starts
    _loadListings();
    _loadLostFound();
  }

  /// Adds a newly submitted listing into in-memory state.
  /// Keeping insertion at index 0 so the user immediately sees newly posted items.
  void _addListing(NewListingInput input) async {
  try {
    if (input.type == ListingType.marketplace) {
      await createListing(
        title:       input.title,
        description: input.description,
        price:       input.price,
        category:    input.category,
        condition:   input.condition,
        location:    input.location,
        email:       _currentUserEmail,
        image:       input.imageUrl,
      );
    } else {
      await createLostFoundItem(
        title:       input.title,
        description: input.description,
        category:    input.category,
        type:        input.type == ListingType.lost ? 'lost' : 'found',
        location:    input.location,
        email:       _currentUserEmail,
        image:       input.imageUrl,
      );
    }
    // Reload from database so new item appears immediately
    await _loadListings();
    await _loadLostFound();
  } catch (e) {
    // If API fails, insert locally as fallback
    setState(() {
      if (input.type == ListingType.marketplace) {
        _marketplaceItems.insert(0, MarketplaceItem(
          id:          DateTime.now().millisecondsSinceEpoch.toString(),
          title:       input.title,
          price:       input.price,
          description: input.description,
          category:    input.category,
          condition:   input.condition,
          image:       input.imageUrl,
          seller:      _activeOwner,
          createdAt:   DateTime.now(),
          location:    input.location,
        ));
      } else {
        _lostFoundItems.insert(0, LostFoundItem(
          id:          DateTime.now().millisecondsSinceEpoch.toString(),
          title:       input.title,
          description: input.description,
          category:    input.category,
          type:        input.type == ListingType.lost ? LostFoundType.lost : LostFoundType.found,
          image:       input.imageUrl,
          poster:      _activeOwner,
          createdAt:   DateTime.now(),
          location:    input.location,
          status:      'active',
        ));
      }
    });
  }

  setState(() {
    _selectedIndex = input.type == ListingType.marketplace ? 0 : 1;
  });
}

  void _goToPostTab() {
    setState(() {
      _selectedIndex = 2;
    });
  }

  void _handleLogin(String email) {
    setState(() {
      _isLoggedIn = true;
      _currentUserEmail = email;
      _selectedIndex = 0;
    });
  }

  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
      _currentUserEmail = '';
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniFind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: appPrimaryColor).copyWith(
          primary: appPrimaryColor,
          secondary: appPrimaryColor,
          surface: appBackgroundColor,
          onPrimary: appBackgroundColor,
        ),
        scaffoldBackgroundColor: appBackgroundColor,
        cardColor: appBackgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: appPrimaryColor,
          foregroundColor: appBackgroundColor,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: appPrimaryColor,
            foregroundColor: appBackgroundColor,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: appPrimaryColor,
            side: const BorderSide(color: appPrimaryColor),
          ),
        ),
      ),
      // Landing → Login → Main App
      // Replaced LoginScreen with LandingPage as the entry point when logged out
      home: !_isLoggedIn
          ? LandingPage(onLogin: _handleLogin)
          : Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('UniFind',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      _currentUserEmail,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Log out',
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
              body: IndexedStack(
                index: _selectedIndex,
                children: [
                  MarketplaceScreen(
                    items: _marketplaceItems,
                    onListItem: _goToPostTab,
                  ),
                  LostFoundScreen(items: _lostFoundItems),
                  PostListingScreen(onPost: _addListing),
                  MyListingsScreen(
                    marketplaceItems: _marketplaceItems
                        .where((item) => item.seller == _activeOwner)
                        .toList(),
                    lostFoundItems: _lostFoundItems
                        .where((item) => item.poster == _activeOwner)
                        .toList(),
                    onListItem: _goToPostTab,
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

// --------------------
// LANDING PAGE
// --------------------

class LandingPage extends StatelessWidget {
  const LandingPage({super.key, required this.onLogin});

  // Called when the user successfully logs in from the LoginScreen.
  final void Function(String email) onLogin;

  static final GlobalKey aboutKey = GlobalKey();
  static final GlobalKey howItWorksKey = GlobalKey();
  static final GlobalKey faqKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  // Opens the Login screen. Once the user logs in successfully,
  // the app marks them as logged in and returns them to the home screen.
  void _openLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          onLogin: (email) {
            onLogin(email); 
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }
  void _openRegister(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => RegistrationScreen(
        onRegister: (email) {
          onLogin(email);
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LandingNavbar(
                onAboutTap: () => _scrollTo(aboutKey),
                onHowItWorksTap: () => _scrollTo(howItWorksKey),
                onFaqTap: () => _scrollTo(faqKey),
                onLoginTap: () => _openLogin(context),
                onRegisterTap: () => _openRegister(context),
              ),
              _HeroSection(
                onLoginTap: () => _openLogin(context),
                onRegisterTap: () => _openRegister(context),
              ),
              _ExclusiveBanner(onLoginTap: () => _openRegister(context)),
          ],
        ),
      ),
    );
  }
}

// --------------------
// LANDING PAGE
// Navigation Bar
// --------------------

class _LandingNavbar extends StatelessWidget {
final VoidCallback onAboutTap;
final VoidCallback onHowItWorksTap;
final VoidCallback onFaqTap;
final VoidCallback onLoginTap;
final VoidCallback onRegisterTap;

const _LandingNavbar({
  required this.onAboutTap,
  required this.onHowItWorksTap,
  required this.onFaqTap,
  required this.onLoginTap,
  required this.onRegisterTap,
});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF8B1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85),
                    width: 2.5,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'MSU',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'UniFind',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          // Nav links + login and sign up buttons
          Row(
            children: [
              TextButton(
                onPressed: onAboutTap,
                child: const Text('About',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
              TextButton(
                onPressed: onHowItWorksTap,
                child: const Text('How It Works',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
              TextButton(
                onPressed: onFaqTap,
                child: const Text('FAQ',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
              Container(
                height: 20,
                width: 1,
                color: Colors.white38,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              TextButton(
                onPressed: onLoginTap,
                child: const Text('Log In',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: onRegisterTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF8B1A1A),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                child: const Text('Sign Up'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// --------------------
// LANDING PAGE
// Welcome Sign / Welcome Screen Section
// --------------------

class _HeroSection extends StatelessWidget {
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;
  const _HeroSection({required this.onLoginTap, required this.onRegisterTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF5F5),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      child: Column(
        children: [
          const Text(
            'Your Campus.\nYour Marketplace.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Buy, sell, and reunite with lost items within the \nMontclair State University community.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 18, color: Color(0xFF555555), height: 1.6),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                 onPressed: onLoginTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1A1A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 36, vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
               child: const Text('Log In'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                onPressed: onRegisterTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8B1A1A),
                  side: const BorderSide(color: Color(0xFF8B1A1A), width: 2),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 36, vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Sign Up'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// --------------------
// LANDING PAGE
// How It Works Section
// --------------------

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    const steps = [
      _Step(
          number: '1',
          title: 'Sign Up',
          description:
              'Create an account using your university email to join the MSU community.'),
      _Step(
          number: '2',
          title: 'Browse or Post',
          description:
              'Find items for sale, report lost belongings, or create your own listings in just a few seconds.'),
      _Step(
          number: '3',
          title: 'Connect',
          description:
              'Message fellow students, arrange pickups, and complete your exchange safely on campus.'),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
      child: Column(
        children: [
          const Text('How It Works',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          const Text('Get started in three simple steps',
              style: TextStyle(fontSize: 16, color: Color(0xFF777777))),
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: steps.map((s) => _StepCard(step: s)).toList(),
          ),
        ],
      ),
    );
  }
}

class _Step {
  final String number, title, description;
  const _Step(
      {required this.number, required this.title, required this.description});
}

class _StepCard extends StatelessWidget {
  final _Step step;
  const _StepCard({required this.step});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 230,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDD5D5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF8B1A1A),
              child: Text(step.number,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 14),
            Text(step.title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            Flexible(
              child: Text(step.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                      height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------
// LANDING PAGE
// Features Sections
// --------------------

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    const features = [
      _Feature(
          icon: Icons.storefront_rounded,
          title: 'Campus Marketplace',
          description:
              'Buy and sell textbooks, electronics, furniture, clothing, and more with other MSU students.'),
      _Feature(
          icon: Icons.search_rounded,
          title: 'Lost & Found',
          description:
              'Report lost items or post things you\'ve found to help reunite students with their belongings.'),
      _Feature(
          icon: Icons.add_circle_outline_rounded,
          title: 'Post in Seconds',
          description:
              'Create a listing with a title, photo, price, and category in just a few clicks.'),
      _Feature(
          icon: Icons.lock_outline_rounded,
          title: 'MSU Community Only',
          description:
              'Exclusively for Montclair State University students, faculty, and staff, providing a trusted and safe community you can rely on.'),
    ];

    return Container(
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
      child: Column(
        children: [
          const Text('Everything You Need',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          const Text('Your campus life was just made easier',
              style: TextStyle(fontSize: 16, color: Color(0xFF777777))),
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: features.map((f) => _FeatureCard(feature: f)).toList(),
          ),
        ],
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String title, description;
  const _Feature(
      {required this.icon, required this.title, required this.description});
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 230,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(feature.icon, color: const Color(0xFF8B1A1A), size: 28),
            ),
            const SizedBox(height: 14),
            Text(feature.title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            Flexible(
              child: Text(feature.description,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                      height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------
// LANDING PAGE
// About Section
// --------------------

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
      child: Column(
        children: [
          const Text('About UniFind',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          const Text('Built for every member of the Red Hawk community',
              style: TextStyle(fontSize: 16, color: Color(0xFF777777))),
          const SizedBox(height: 48),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: const Column(
                children: [
                  _AboutStrip(
                      icon: Icons.school_rounded,
                      title: 'Our Mission',
                      description:
                          'UniFind was created to make campus life easier at Montclair State University. We believe everyone deserves a safe, trusted platform to buy, sell, and recover lost belongings within their own community.',
                      shaded: false),
                  _AboutStrip(
                      icon: Icons.groups_rounded,
                      title: 'Who We Are',
                      description:
                          'We are MSU students who saw a need for a dedicated campus marketplace. UniFind is built with the MSU community in mind. Every feature is designed around how students actually live and interact on campus.',
                      shaded: true),
                  _AboutStrip(
                      icon: Icons.favorite_rounded,
                      title: 'Why UniFind',
                      description:
                          'Unlike other marketplaces, UniFind is exclusively for individuals who are a part of the MSU community. That means safer transactions, familiar faces, and a community you can trust. No strangers, just fellow Red Hawks.',
                      shaded: false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutStrip extends StatelessWidget {
  final IconData icon;
  final String title, description;
  final bool shaded;

  const _AboutStrip({
    required this.icon,
    required this.title,
    required this.description,
    required this.shaded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        color: shaded ? const Color(0xFFFFF8F8) : Colors.white,
        border: const Border(
            bottom: BorderSide(color: Color(0xFFF5E5E5), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EE),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEDD5D5), width: 2),
            ),
            child: Icon(icon, color: const Color(0xFF8B1A1A), size: 24),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B1A1A))),
                const SizedBox(height: 6),
                Text(description,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF555555),
                        height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------
// LANDING PAGE
// FAQ Section
// --------------------

class _FaqSection extends StatelessWidget {
  const _FaqSection();

  @override
  Widget build(BuildContext context) {
    const faqs = [
      _Faq(
          question: 'Who can use UniFind?',
          answer:
              'UniFind is exclusively for Montclair State University students, faculty, and staff. You must sign up with a valid MSU email address to access the platform.'),
      _Faq(
          question: 'Is UniFind safe?',
          answer:
              'Yes! UniFind will have administrators monitoring listings and users to ensure listings are legitimate and all users are verified MSU students and faculty'),
      _Faq(
          question: 'How do I post an item for sale?',
          answer:
              'After signing in, tap the "Post" tab at the bottom of the app. Fill in the title, description, price, category, and location. Afterwards, hit Post Item. It takes less than a minute!'),
      _Faq(
          question: 'What categories are available?',
          answer:
              'Right now, you can list items under Textbooks, Electronics, Furniture, Clothing, and Other. The Lost & Found board supports Electronics, Bags, Keys, ID/Cards, Clothing, and Other.'),
      _Faq(
          question: 'How does Lost & Found work?',
          answer:
              'Students can post items they\'ve lost or found on campus. Browse the Lost & Found feed, filter by category, and reach out to reunite items with their owners.'),
      _Faq(
          question: 'How do I contact a seller?',
          answer:
              'Once you\'re signed in and viewing a listing, you can message the seller directly through the app to arrange a meetup or ask questions.'),
    ];

    return Container(
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
      child: Column(
        children: [
          const Text('Frequently Asked Questions',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          const Text('Everything you need to know before getting started',
              style: TextStyle(fontSize: 16, color: Color(0xFF777777))),
          const SizedBox(height: 48),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: faqs.map((f) => _FaqTile(faq: f)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Faq {
  final String question, answer;
  const _Faq({required this.question, required this.answer});
}

class _FaqTile extends StatefulWidget {
  final _Faq faq;
  const _FaqTile({required this.faq});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDD5D5), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B1A1A).withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B1A1A), Color(0xFFB03030)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF8F8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                widget.faq.answer,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF555555),
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --------------------
// LANDING PAGE
// Bottome of the Page Banner
// --------------------

class _ExclusiveBanner extends StatelessWidget {
  final VoidCallback onLoginTap;
  const _ExclusiveBanner({required this.onLoginTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF8B1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
      child: Column(
        children: [
          const Text('Made for the Montclair State University Community',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
            'UniFind is designed solely for the Montclair State University community, offering a safe and verified space to sell and connect on campus.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFFFFCCCC), fontSize: 16, height: 1.6),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: onLoginTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF8B1A1A),
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              textStyle: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child: const Text('Join UniFind Today'),
          ),
        ],
      ),
    );
  }
}

// --------------------
// LANDING PAGE
// Footer
// --------------------

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: const Center(
        child: Text(
          '2026 UniFind · Montclair State University',
          style: TextStyle(color: Color(0xFF888888), fontSize: 13),
        ),
      ),
    );
  }
}

// END OF LANDING PAGE SECTIONS

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});

  final void Function(String email) onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, required this.onRegister});
  final void Function(String email) onRegister;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _confirm = '';
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Join the MSU community',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'MSU Email',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _email = value,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _password = value,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Password is required';
                          if (value.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _confirm = value,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please confirm your password';
                          if (value != _password) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : FilledButton(
                              onPressed: _submit,
                              child: const Text('Create Account'),
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
  }

  void _submit() {
  if (!_formKey.currentState!.validate()) return;
  widget.onRegister(_email.trim());
}
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniFind Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Sign in to browse listings',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _email = value,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _password = value,
                        validator: (value) =>
                            (value == null || value.isEmpty)
                                ? 'Password is required'
                                : null,
                      ),
                      // Show error message from API if login fails
                      if (_errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Show loading indicator while API call is in progress
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : FilledButton(
                              onPressed: _submit,
                              child: const Text('Log In'),
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
  }

  /// Calls the API to verify login credentials.
  /// Falls back to basic email validation if the API is unreachable.
  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await loginUser(_email.trim(), _password.trim());
      widget.onLogin(_email.trim());
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('connect') || errorMsg.contains('server')) {
        // Network error — fall back to basic email validation
        widget.onLogin(_email.trim());
      } else {
        setState(() {
          _errorMessage = 'Invalid email or password.';
          _isLoading = false;
        });
      }
    }
  }
}


class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({
    super.key,
    required this.items,
    required this.onListItem,
  });

  final List<MarketplaceItem> items;
  final VoidCallback onListItem;

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
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: widget.onListItem,
              icon: const Icon(Icons.add),
              label: const Text('List an Item'),
            ),
          ),
        ),
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
          child: widget.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No listings yet'),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: widget.onListItem,
                        icon: const Icon(Icons.add),
                        label: const Text('List an Item'),
                      ),
                    ],
                  ),
                )
              : filteredItems.isEmpty
                  ? const Center(
                      child:
                          Text('No items found matching your criteria'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredItems.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                                builder: (_) =>
                                    ItemDetailScreen(item: item),
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
                                    headers: const {'Access-Control-Allow-Origin': '*'},
                                    errorBuilder: (_, __, ___) =>
                                        const ColoredBox(
                                      color: appPlaceholderColor,
                                      child: Center(
                                          child: Icon(
                                              Icons.image_not_supported)),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '\$${item.price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: appPrimaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(item.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: appBackgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                              color: appPrimaryColor),
                                        ),
                                        child: Text(
                                          item.category,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: appPrimaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.location,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: appMutedTextColor),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        item.condition,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: appMutedTextColor),
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
      final typeMatch = selectedType == LostFilter.all ||
          item.type.name == selectedType.name;
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
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
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
                  child: _typeFilterButton(LostFilter.all, 'All')),
              const SizedBox(width: 8),
              Expanded(
                  child: _typeFilterButton(LostFilter.lost, 'Lost')),
              const SizedBox(width: 8),
              Expanded(
                  child: _typeFilterButton(LostFilter.found, 'Found')),
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
                                headers: const {'Access-Control-Allow-Origin': '*'},
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox(
                                  width: 82,
                                  height: 82,
                                  child: ColoredBox(
                                    color: appPlaceholderColor,
                                    child: Icon(
                                        Icons.image_not_supported),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                          color: appBackgroundColor,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          item.type == LostFoundType.lost
                                              ? 'Lost'
                                              : 'Found',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: appPrimaryColor,
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
                                    style: const TextStyle(
                                        color: appMutedTextColor),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.location} • ${item.poster} • ${formatDate(item.createdAt)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: appMutedTextColor),
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

  Widget _typeFilterButton(LostFilter value, String label) {
    final selected = selectedType == value;
    return FilledButton.tonal(
      onPressed: () => setState(() => selectedType = value),
      style: FilledButton.styleFrom(
        backgroundColor: selected ? appPrimaryColor : null,
        foregroundColor: selected ? appBackgroundColor : null,
      ),
      child: Text(label),
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
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();


  List<String> get _availableCategories =>
      listingType == ListingType.marketplace
          ? categories.where((item) => item != 'All').toList()
          : lostFoundCategories.where((item) => item != 'All').toList();

// Opens a bottom sheet so user can choose camera or gallery
Future<void> _pickImage() async {
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
              final picked = await _picker.pickImage(
                source: ImageSource.camera,
                imageQuality: 40,
                maxWidth: 800,
                maxHeight: 800,
              );
              if (picked != null) {
                final bytes = await picked.readAsBytes();
                setState(() {
                  _selectedImage = picked;
                  _selectedImageBytes = bytes;
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () async {
              Navigator.pop(context);
              final picked = await _picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 40,
                maxWidth: 800,
                maxHeight: 800,
              );
              if (picked != null) {
                final bytes = await picked.readAsBytes();
                setState(() {
                  _selectedImage = picked;
                  _selectedImageBytes = bytes;
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
                  Expanded(child: _typeButton(label: 'For Sale', type: ListingType.marketplace)),
                  const SizedBox(width: 8),
                  Expanded(child: _typeButton(label: 'Lost', type: ListingType.lost)),
                  const SizedBox(width: 8),
                  Expanded(child: _typeButton(label: 'Found', type: ListingType.found)),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                    labelText: 'Title *', border: OutlineInputBorder()),
                onChanged: (value) => title = value,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Title is required' : null,
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
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Description is required' : null,
              ),
              if (listingType == ListingType.marketplace) ...[
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Price *',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => price = double.tryParse(value) ?? 0,
                  validator: (value) {
                    final parsed = double.tryParse(value ?? '');
                    if (parsed == null || parsed <= 0) return 'Enter a valid price';
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
                      .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                      .toList(),
                  onChanged: (value) => setState(() => condition = value ?? 'Good'),
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
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) => setState(() => category = value ?? ''),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Category is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => location = value,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Location is required' : null,
              ),
              const SizedBox(height: 16),

              // Image picker section
              const Text('Item Image',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),

              // Show preview if image selected, otherwise show placeholder
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: appPlaceholderColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: appPrimaryColor, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _selectedImageBytes != null
                      ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                size: 40, color: appPrimaryColor),
                            SizedBox(height: 8),
                            Text('Tap to add a photo',
                                style: TextStyle(color: appPrimaryColor)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap the box to choose from gallery or take a photo',
                style: TextStyle(fontSize: 12, color: appMutedTextColor),
              ),
              const SizedBox(height: 20),

              // Show loading spinner while uploading, otherwise show Post button
              SizedBox(
                width: double.infinity,
                child: _isUploading
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
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
    return FilledButton.tonal(
      onPressed: () => setState(() {
        listingType = type;
        category = '';
      }),
      style: FilledButton.styleFrom(
        backgroundColor: selected ? appPrimaryColor : null,
        foregroundColor: selected ? appBackgroundColor : null,
      ),
      child: Text(label),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      // Upload image to server if one was selected
      // Otherwise fall back to default placeholder image
      String imageUrl = 'https://placehold.co/400x400?text=?';
      if (_selectedImage != null) {
        imageUrl = await uploadImage(_selectedImage!.path, _selectedImageBytes!);
        print('IMAGE URL: $imageUrl');
      }

      widget.onPost(
        NewListingInput(
          type:        listingType,
          title:       title.trim(),
          description: description.trim(),
          category:    category,
          condition:   condition,
          location:    location.trim(),
          price:       price,
          imageUrl:    imageUrl,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('URL: $imageUrl'),
          duration: const Duration(seconds: 10),
        ),
      );

      // Reset the form after successful post
      setState(() {
        title = '';
        description = '';
        category = '';
        condition = 'Good';
        location = '';
        price = 0;
        _selectedImage = null;
        _selectedImageBytes = null;
        _isUploading = false;
        _formKey.currentState?.reset();
      });

    } catch (e) {
      // Show error if upload or post failed
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post item: ${e.toString()}')),
      );
    }
  }
}

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({
    super.key,
    required this.marketplaceItems,
    required this.lostFoundItems,
    required this.onListItem,
  });

  final List<MarketplaceItem> marketplaceItems;
  final List<LostFoundItem> lostFoundItems;
  final VoidCallback onListItem;

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
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: widget.onListItem,
            icon: const Icon(Icons.add),
            label: const Text('List an Item'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Marketplace Items'),
                selected: showMarketplace,
                onSelected: (_) =>
                    setState(() => showMarketplace = true),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Lost & Found'),
                selected: !showMarketplace,
                onSelected: (_) =>
                    setState(() => showMarketplace = false),
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
                                  leading:
                                      const Icon(Icons.storefront),
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
                                  leading: Icon(
                                      item.type == LostFoundType.lost
                                          ? Icons.report_problem_outlined
                                          : Icons.check_circle_outline),
                                  title: Text(item.title),
                                  subtitle: Text(
                                      '${item.category} • ${item.location}'),
                                  trailing: Text(
                                      item.type == LostFoundType.lost
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
        Text('Core Features',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
                headers: const {'Access-Control-Allow-Origin': '*'},
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: appPlaceholderColor,
                  child: Center(child: Icon(Icons.image_not_supported)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '\$${item.price.toStringAsFixed(0)}',
            style: const TextStyle(
              color: appPrimaryColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(item.title,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
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
        'https://placehold.co/400x400?text=?',
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
    image:
        'https://images.unsplash.com/photo-1589998059171-988d887df646?w=400',
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
    image:
        'https://images.unsplash.com/photo-1571175443880-49e1d25b2bc5?w=400',
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
    image:
        'https://images.unsplash.com/photo-1611367840531-628f328d9a49?w=400',
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
    image:
        'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=400',
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
    image:
        'https://images.unsplash.com/photo-1591290619762-d06df1a8a8b0?w=400',
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
    image:
        'https://images.unsplash.com/photo-1576671081837-49000212a370?w=400',
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
    image:
        'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400',
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
    image:
        'https://images.unsplash.com/photo-1606841837239-c5a1a4a07af7?w=400',
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
    image:
        'https://images.unsplash.com/photo-1585155770958-eeb77df44de8?w=400',
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
    image:
        'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=400',
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
    image:
        'https://images.unsplash.com/photo-1582139329536-e7284fece509?w=400',
    poster: 'Ryan B.',
    createdAt: DateTime(2026, 2, 8),
    location: 'University Hall',
    status: 'active',
  ),
];
