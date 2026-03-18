library unifind_app;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'api_service.dart';
part 'src/landing_page.dart';
part 'src/auth_screens.dart';
part 'src/marketplace_screen.dart';
part 'src/lost_found_screen.dart';
part 'src/post_listing_screen.dart';
part 'src/my_listings_screen.dart';
part 'src/documentation_screen.dart';
part 'src/item_detail_screen.dart';
part 'src/ui_controls.dart';
part 'src/ui_feedback.dart';
part 'src/data.dart';

// ─── THEME ───────────────────────────────────────────────────────────────────
const Color cRed = Color(0xFFA12727);
const Color cRedDark = Color(0xFF7A1A1A);
const Color cRedLight = Color(0xFFFFEEEE);
const Color cRedGlow = Color(0x22A12727);
const Color cSurface = Color(0xFFFFFFFF);
const Color cBg = Color(0xFFFCF8F8);
const Color cMuted = Color(0xFF9C7070);
const Color cBorder = Color(0xFFEDD8D8);
const Color cText = Color(0xFF1A1010);
const Color cPlaceholder = Color(0xFFEBD1D1);
const Color cNavBg = Color(0xFF8B1A1A);
const Color cNavBgDark = Color(0xFF6B1010);
const Duration kFast = Duration(milliseconds: 180);
const Duration kMid = Duration(milliseconds: 320);
const Duration kSlow = Duration(milliseconds: 520);
const Duration kPage = Duration(milliseconds: 420);

void main() => runApp(const UniFindApp());

// ─── ROOT ────────────────────────────────────────────────────────────────────
class UniFindApp extends StatefulWidget {
  const UniFindApp({super.key});
  @override
  State<UniFindApp> createState() => _UniFindAppState();
}

class _UniFindAppState extends State<UniFindApp> {
  int _tab = 0;
  bool _loggedIn = false;
  String _email = '';

  final List<MarketplaceItem> _market = [];
  final List<LostFoundItem> _lostFound = [];

  String get _owner => _email.isEmpty ? 'You' : _email;

  Future<void> _loadListings() async {
    try {
      final apiItems = await getListings();
      if (apiItems.isNotEmpty) {
        setState(() {
          _market
            ..clear()
            ..addAll(
              apiItems.map(
                (item) => MarketplaceItem(
                  id: item['id'].toString(),
                  title: item['title'],
                  price: (item['price'] as num).toDouble(),
                  description: item['description'],
                  category: item['category'],
                  condition: item['condition'],
                  image: item['image'] ?? '',
                  seller: item['seller'] ?? '',
                  createdAt:
                      DateTime.tryParse(item['createdAt'] ?? '') ??
                      DateTime.now(),
                  location: item['location'] ?? '',
                ),
              ),
            );
        });
      }
    } catch (_) {}
  }

  Future<void> _loadLostFound() async {
    try {
      final apiItems = await getLostFoundItems();
      if (apiItems.isNotEmpty) {
        setState(() {
          _lostFound
            ..clear()
            ..addAll(
              apiItems.map(
                (item) => LostFoundItem(
                  id: item['id'].toString(),
                  title: item['title'],
                  description: item['description'],
                  category: item['category'],
                  type: item['type'] == 'lost'
                      ? LostFoundType.lost
                      : LostFoundType.found,
                  image: item['image'] ?? '',
                  poster: item['poster'] ?? '',
                  createdAt:
                      DateTime.tryParse(item['createdAt'] ?? '') ??
                      DateTime.now(),
                  location: item['location'] ?? '',
                  status: item['status'] ?? 'active',
                ),
              ),
            );
        });
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _loadListings();
    _loadLostFound();
  }

  void _goToPostTab() => setState(() => _tab = 2);

  Future<void> _addListing(NewListingInput in_) async {
    try {
      if (in_.type == ListingType.marketplace) {
        await createListing(
          title: in_.title,
          description: in_.description,
          price: in_.price,
          category: in_.category,
          condition: in_.condition,
          location: in_.location,
          email: _email,
          image: in_.imageUrl,
        );
      } else {
        await createLostFoundItem(
          title: in_.title,
          description: in_.description,
          category: in_.category,
          type: in_.type == ListingType.lost ? 'lost' : 'found',
          location: in_.location,
          email: _email,
          image: in_.imageUrl,
        );
      }
      await _loadListings();
      await _loadLostFound();
    } catch (_) {
      setState(() {
        if (in_.type == ListingType.marketplace) {
          _market.insert(
            0,
            MarketplaceItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: in_.title,
              price: in_.price,
              description: in_.description,
              category: in_.category,
              condition: in_.condition,
              image: in_.imageUrl,
              seller: _owner,
              createdAt: DateTime.now(),
              location: in_.location,
            ),
          );
        } else {
          _lostFound.insert(
            0,
            LostFoundItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: in_.title,
              description: in_.description,
              category: in_.category,
              type: in_.type == ListingType.lost
                  ? LostFoundType.lost
                  : LostFoundType.found,
              image: in_.imageUrl,
              poster: _owner,
              createdAt: DateTime.now(),
              location: in_.location,
              status: 'active',
            ),
          );
        }
      });
    }

    setState(() {
      _tab = in_.type == ListingType.marketplace ? 0 : 1;
    });
  }

  void _login(String email) => setState(() {
        _loggedIn = true;
        _email = email;
        _tab = 0;
      });

  void _logout() => setState(() {
        _loggedIn = false;
        _email = '';
        _tab = 0;
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniFind',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: !_loggedIn
          ? LandingPage(onLogin: _login)
          : Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: Column(
                  mainAxisSize: MainAxisSize.min, // keeps it centered vertically
                  children: [
                    Image.asset(
                      'assets/images/whitelogo.png',
                      height: 32,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 2), // small spacing
                    Text(
                      _email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white, // 👈 pure white
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: 'Log out',
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
              body: IndexedStack(
                index: _tab,
                children: [
                  MarketplaceScreen(items: _market, onListItem: _goToPostTab),
                  LostFoundScreen(items: _lostFound),
                  PostListingScreen(onPost: _addListing),
                  MyListingsScreen(
                    marketplaceItems: _market
                        .where((item) => item.seller == _owner)
                        .toList(),
                    lostFoundItems: _lostFound
                        .where((item) => item.poster == _owner)
                        .toList(),
                    onListItem: _goToPostTab,
                  ),
                  const DocumentationScreen(),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (index) =>
                    setState(() => _tab = index),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.storefront_outlined),
                    label: 'Shop',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.search),
                    label: 'Lost/Found',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.add_circle_outline),
                    label: 'Post',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    label: 'My Listings',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    label: 'Docs',
                  ),
                ],
              ),
            ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: cRed).copyWith(
        primary: cRed,
        secondary: cRed,
        surface: cSurface,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: cBg,
      fontFamily: 'Georgia',
      appBarTheme: const AppBarTheme(
        backgroundColor: cNavBg,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
