library unifind_app;

import 'package:flutter/gestures.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:io';
import 'api_service.dart';
import 'package:url_launcher/url_launcher.dart';
part 'src/landing_page.dart';
part 'src/auth_screens.dart';
part 'src/marketplace_screen.dart';
part 'src/lost_found_screen.dart';
part 'src/post_listing_screen.dart';
part 'src/profile_screen.dart';
part 'src/my_listings_screen.dart';
part 'src/documentation_screen.dart';
part 'src/item_detail_screen.dart';
part 'src/ui_controls.dart';
part 'src/ui_feedback.dart';
part 'src/data.dart';
part 'src/admin.dart';

typedef AuthSuccessCallback = void Function(
  String email, [
  int? userId,
  String? username,
  String? role,
]);

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

// ─── BREADCRUMB LABELS ───────────────────────────────────────────────────────
const List<List<String>> _tabBreadcrumbs = [
  ['Home', 'Marketplace'],
  ['Home', 'Lost & Found'],
  ['Home', 'Post Item'],
  ['Home', 'My Listings'],
  ['Home', 'Docs'],
  ['Home', 'Profile'],
];

// ─── BREADCRUMB BAR ──────────────────────────────────────────────────────────
class _BreadcrumbBar extends StatelessWidget {
  final int tab;
  final VoidCallback? onHome;
  const _BreadcrumbBar({required this.tab, this.onHome});

  @override
  Widget build(BuildContext context) {
    final crumbs = _tabBreadcrumbs[tab.clamp(0, _tabBreadcrumbs.length - 1)];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cRedLight,
        border: Border(bottom: BorderSide(color: cBorder, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.home_outlined, size: 12, color: cMuted),
          const SizedBox(width: 4),
          for (int i = 0; i < crumbs.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 13, color: cMuted),
              const SizedBox(width: 4),
            ],
            if (i == crumbs.length - 1)
              Text(
                crumbs[i],
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cRed,
                ),
              )
            else
              GestureDetector(
                onTap: i == 0 ? onHome : null,
                child: Text(
                  crumbs[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: cMuted,
                    decoration: i == 0 ? TextDecoration.underline : null,
                    decorationColor: cMuted,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

void main() {
  HttpOverrides.global = _AllowBadCertificates();
  runApp(const UniFindApp());
}

class _AllowBadCertificates extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

// ─── ROOT ────────────────────────────────────────────────────────────────────
class UniFindApp extends StatefulWidget {
  const UniFindApp({super.key});
  @override
  State<UniFindApp> createState() => _UniFindAppState();
}

class _UniFindAppState extends State<UniFindApp> {
  int _tab = 0;
  int _postFormNonce = 0;
  bool _loggedIn = false;
  bool _sessionLoaded = false;
  String _email = '';
  String _username = '';
  int? _userId;
  String _role = '';
  UserRole _userRole = UserRole.unknown;
  ListingType _postDefaultType = ListingType.marketplace;

  final List<MarketplaceItem> _market = [];
  final List<LostFoundItem> _lostFound = [];
  final Set<String> _myMarketIds = <String>{};
  final Set<String> _myLostFoundIds = <String>{};
  final Set<String> _myMarketFingerprints = <String>{};
  final Set<String> _myLostFoundFingerprints = <String>{};
  final Set<String> _submittedClaimItemIds = <String>{};
  final Set<String> _submittedMatchItemIds = <String>{};

  String _normalizeEmail(String input) => input.trim().toLowerCase();
  int? _toInt(dynamic value) => value == null ? null : int.tryParse(value.toString());
  String _asString(dynamic value) => value?.toString() ?? '';
  String _emailToHandle(String input) {
    final normalized = _normalizeEmail(input);
    if (normalized.isEmpty) return '';
    return normalized.contains('@') ? normalized.split('@').first : normalized;
  }
  String _preferredUserLabel(
    List<dynamic> rawCandidates, {
    String email = '',
  }) {
    for (final raw in rawCandidates) {
      final value = _asString(raw).trim();
      if (value.isEmpty) continue;
      final lowered = value.toLowerCase();
      if (lowered == 'msu student' ||
          lowered == 'student' ||
          lowered == 'anonymous') {
        continue;
      }
      if (value.contains('@')) continue;
      return value;
    }
    return 'Student';
  }
  String _claimsKeyForEmail(String email) =>
      'submitted_claim_ids_${_normalizeEmail(email)}';
  String _matchesKeyForEmail(String email) =>
      'submitted_match_ids_${_normalizeEmail(email)}';
  Future<void> _restoreSubmissionState(String email) async {
    if (email.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final claims = prefs.getStringList(_claimsKeyForEmail(email)) ?? const [];
    final matches = prefs.getStringList(_matchesKeyForEmail(email)) ?? const [];
    if (!mounted) return;
    setState(() {
      _submittedClaimItemIds
        ..clear()
        ..addAll(claims);
      _submittedMatchItemIds
        ..clear()
        ..addAll(matches);
    });
  }

  Future<void> _persistSubmissionState() async {
    if (_email.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _claimsKeyForEmail(_email),
      _submittedClaimItemIds.toList(),
    );
    await prefs.setStringList(
      _matchesKeyForEmail(_email),
      _submittedMatchItemIds.toList(),
    );
  }
  String _normalizeText(String input) =>
      input.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  String _short(String value, [int n = 50]) =>
      value.length <= n ? value : value.substring(0, n);
  String _extractIdFromResponse(Map<String, dynamic> response) {
    final dynamic rawId =
        response['id'] ??
        response['listingId'] ??
        response['listing_id'] ??
        response['itemId'] ??
        response['item_id'] ??
        response['data']?['id'];
    return rawId?.toString() ?? '';
  }

  bool _looksLikeCurrentUser(String value) {
    final normalizedValue = _normalizeEmail(value);
    final normalizedUser = _normalizeEmail(_email);
    if (normalizedValue.isEmpty || normalizedUser.isEmpty) return false;
    if (normalizedValue == normalizedUser) return true;
    final userLocal = normalizedUser.split('@').first;
    return normalizedValue.contains(userLocal);
  }

  bool _isMyMarketplaceItem(MarketplaceItem item) {
    if (_userId != null && item.sellerId != null) {
      return item.sellerId == _userId;
    }
    return item.sellerEmail == _normalizeEmail(_email) ||
        _looksLikeCurrentUser(item.seller) ||
        _myMarketIds.contains(item.id) ||
        _myMarketFingerprints.contains(_marketFingerprintFromItem(item));
  }

  bool _isMyLostFoundItem(LostFoundItem item) {
    if (_userId != null && item.posterId != null) {
      return item.posterId == _userId;
    }
    return item.posterEmail == _normalizeEmail(_email) ||
        _looksLikeCurrentUser(item.poster) ||
        _myLostFoundIds.contains(item.id) ||
        _myLostFoundFingerprints.contains(_lostFingerprintFromItem(item));
  }

  String _marketFingerprintFromInput(NewListingInput in_) {
    return [
      _normalizeText(in_.title),
      _normalizeText(_short(in_.description)),
      _normalizeText(in_.category),
      _normalizeText(in_.location),
      in_.price.toStringAsFixed(0),
    ].join('|');
  }

  String _lostFingerprintFromInput(NewListingInput in_) {
    return [
      _normalizeText(in_.title),
      _normalizeText(_short(in_.description)),
      _normalizeText(in_.category),
      _normalizeText(in_.location),
      in_.type.name,
    ].join('|');
  }

  String _marketFingerprintFromItem(MarketplaceItem item) {
    return [
      _normalizeText(item.title),
      _normalizeText(_short(item.description)),
      _normalizeText(item.category),
      _normalizeText(item.location),
      item.price.toStringAsFixed(0),
    ].join('|');
  }

  String _lostFingerprintFromItem(LostFoundItem item) {
    return [
      _normalizeText(item.title),
      _normalizeText(_short(item.description)),
      _normalizeText(item.category),
      _normalizeText(item.location),
      item.type.name,
    ].join('|');
  }

  Future<void> _loadListings() async {
    try {
      final apiItems = await getListings();
      final parsed = <MarketplaceItem>[];
      for (final item in apiItems) {
        try {
          parsed.add(
            MarketplaceItem(
              id: _asString(item['id']),
              title: _asString(item['title']),
              price: double.tryParse(_asString(item['price'])) ?? 0,
              description: _asString(item['description']),
              category: _asString(item['category']).isEmpty
                  ? 'Other'
                  : _asString(item['category']),
              condition: _asString(item['condition']).isEmpty
                  ? 'Good'
                  : _asString(item['condition']),
              image: _asString(item['image']).isEmpty
                  ? _asString(item['image_url'])
                  : _asString(item['image']),
              sellerEmail: _normalizeEmail(
                _asString(
                  item['sellerEmail'] ?? item['seller_email'] ?? item['email'],
                ),
              ),
              seller: _preferredUserLabel(
                [
                  item['username'],
                  item['seller_username'],
                  item['sellerName'],
                  item['seller_name'],
                  item['display_name'],
                  item['seller'],
                  item['email'],
                ],
                email: _asString(
                  item['sellerEmail'] ?? item['seller_email'] ?? item['email'],
                ),
              ),
              sellerId: _toInt(
                item['sellerId'] ??
                    item['seller_id'] ??
                    item['userId'] ??
                    item['user_id'] ??
                    item['owner_id'],
              ),
              createdAt:
                  DateTime.tryParse(
                    _asString(item['createdAt'] ?? item['created_at']),
                  ) ??
                  DateTime.now(),
              location: _asString(item['location']),
            ),
          );
        } catch (_) {
          continue;
        }
      }
      setState(() {
        _market
          ..clear()
          ..addAll(parsed);
        if (_userId == null) {
          for (final listing in _market) {
            if (listing.sellerId != null &&
                listing.sellerEmail == _normalizeEmail(_email)) {
              _userId = listing.sellerId;
              break;
            }
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _loadLostFound() async {
    try {
      final apiItems = await getLostFoundItems();
      final parsed = <LostFoundItem>[];
      for (final item in apiItems) {
        try {
          final rawType = _asString(item['type']).toLowerCase();
          parsed.add(
            LostFoundItem(
              id: _asString(item['id']),
              title: _asString(item['title']),
              description: _asString(item['description']),
              category: _asString(item['category']).isEmpty
                  ? 'Other'
                  : _asString(item['category']),
              type: rawType == 'found' ? LostFoundType.found : LostFoundType.lost,
              image: _asString(item['image']).isEmpty
                  ? _asString(item['image_url'])
                  : _asString(item['image']),
              posterEmail: _normalizeEmail(
                _asString(
                  item['posterEmail'] ?? item['poster_email'] ?? item['email'],
                ),
              ),
              poster: _preferredUserLabel(
                [
                  item['username'],
                  item['poster_username'],
                  item['posterName'],
                  item['poster_name'],
                  item['display_name'],
                  item['poster'],
                  item['email'],
                ],
                email: _asString(
                  item['posterEmail'] ?? item['poster_email'] ?? item['email'],
                ),
              ),
              posterId: _toInt(
                item['posterId'] ??
                    item['poster_id'] ??
                    item['userId'] ??
                    item['user_id'] ??
                    item['owner_id'],
              ),
              createdAt:
                  DateTime.tryParse(
                    _asString(item['createdAt'] ?? item['created_at']),
                  ) ??
                  DateTime.now(),
              location: _asString(item['location']),
              status: _asString(item['status']).isEmpty
                  ? 'active'
                  : _asString(item['status']),
            ),
          );
        } catch (_) {
          continue;
        }
      }
      setState(() {
        _lostFound
          ..clear()
          ..addAll(parsed);
        if (_userId == null) {
          for (final post in _lostFound) {
            if (post.posterId != null &&
                post.posterEmail == _normalizeEmail(_email)) {
              _userId = post.posterId;
              break;
            }
          }
        }
      });
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('logged_in') ?? false;
    final email = prefs.getString('logged_in_email') ?? '';
    final username = prefs.getString('logged_in_username') ?? '';
    final userId = prefs.getInt('logged_in_user_id');
    final role = prefs.getString('logged_in_role') ?? '';

    if (!mounted) return;
    setState(() {
      _loggedIn = loggedIn;
      _email = email;
      _username = username;
      _userId = userId;
      _role = role;
      _userRole = UserRoleExt.fromString(role);
      _sessionLoaded = true;
    });

    if (loggedIn && email.isNotEmpty) {
      await _restoreSubmissionState(email);
    }

    _loadListings();
    _loadLostFound();
  }

  void _goToPostTab([ListingType type = ListingType.marketplace]) {
    setState(() {
      _postDefaultType = type;
      _postFormNonce++;
      _tab = 2;
    });
  }

  Future<void> _addListing(NewListingInput in_) async {
  try {
    if (in_.type == ListingType.marketplace) {
      _myMarketFingerprints.add(_marketFingerprintFromInput(in_));
      print('DEBUG _addListing: email=$_email, title=${in_.title}');
      final res = await createListing(
        title: in_.title,
        description: in_.description,
        price: in_.price,
        category: in_.category,
        condition: in_.condition,
        location: in_.location,
        email: _email,
        image: in_.imageUrl,
      );
      print('DEBUG createListing response: $res');
        final id = _extractIdFromResponse(res);
        if (id.isNotEmpty) _myMarketIds.add(id);
      } else {
        _myLostFoundFingerprints.add(_lostFingerprintFromInput(in_));
        final res = await createLostFoundItem(
          title: in_.title,
          description: in_.description,
          category: in_.category,
          type: in_.type == ListingType.lost ? 'lost' : 'found',
          location: in_.location,
          email: _email,
          image: in_.imageUrl,
        );
        final id = _extractIdFromResponse(res);
        if (id.isNotEmpty) _myLostFoundIds.add(id);
      }
      await _loadListings();
      await _loadLostFound();
    } catch (e) {
      print('DEBUG addListing error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _tab = in_.type == ListingType.marketplace ? 0 : 1;
    });
  }

  Future<void> _claimLostItem(LostFoundItem item, ClaimEvidence evidence) async {
    try {
      await claimLostFoundItem(
        itemId: item.id,
        email: _email,
        proofDetails: evidence.proofDetails,
        identifyingDetails: evidence.identifyingDetails,
        lastSeenContext: evidence.lastSeenContext,
        contactNote: evidence.contactNote,
      );
      _submittedClaimItemIds.add(item.id);
      await _persistSubmissionState();
      await _loadLostFound();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Claim submitted for verification.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Claim failed to sync with database.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _postFoundMatch(LostFoundItem lostItem, FoundMatchInput input) async {
    try {
      await createLostFoundMatch(
        lostItemId: lostItem.id,
        email: _email,
        foundLocation: input.foundLocation,
        foundWhen: input.foundWhen,
        matchDetails: input.matchDetails,
        contactNote: input.contactNote,
      );
      _submittedMatchItemIds.add(lostItem.id);
      await _persistSubmissionState();
      await _loadLostFound();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match submitted for review.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to post found match right now.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _editMarketplaceItem(
    MarketplaceItem item,
    MarketplaceUpdateInput update,
  ) async {
    try {
      await updateListing(
        id: item.id,
        title: update.title,
        description: update.description,
        price: update.price,
        category: update.category,
        condition: update.condition,
        location: update.location,
        email: _email,
        imageUrl: update.imageUrl,
      );
      await _loadListings();
    } catch (_) {
      setState(() {
        final idx = _market.indexWhere((m) => m.id == item.id);
        if (idx == -1) return;
        final old = _market[idx];
        _market[idx] = MarketplaceItem(
          id: old.id,
          title: update.title,
          price: update.price,
          description: update.description,
          category: update.category,
          condition: update.condition,
          image: update.imageUrl ?? old.image,
          seller: old.seller,
          sellerEmail: old.sellerEmail,
          sellerId: old.sellerId,
          createdAt: old.createdAt,
          location: update.location,
        );
      });
    }
  }

  Future<void> _editLostFoundItem(
    LostFoundItem item,
    LostFoundUpdateInput update,
  ) async {
    try {
      await updateLostFoundItem(
        id: item.id,
        title: update.title,
        description: update.description,
        category: update.category,
        location: update.location,
        email: _email,
        imageUrl: update.imageUrl,
      );
      await _loadLostFound();
    } catch (_) {
      setState(() {
        final idx = _lostFound.indexWhere((m) => m.id == item.id);
        if (idx == -1) return;
        final old = _lostFound[idx];
        _lostFound[idx] = LostFoundItem(
          id: old.id,
          title: update.title,
          description: update.description,
          category: update.category,
          type: old.type,
          image: update.imageUrl ?? old.image,
          poster: old.poster,
          posterEmail: old.posterEmail,
          posterId: old.posterId,
          createdAt: old.createdAt,
          location: update.location,
          status: old.status,
        );
      });
    }
  }

  void _login(String email, [int? userId, String? username, String? role]) {
  print('DEBUG _login called: role=$role');
  print('DEBUG userRole will be: ${UserRoleExt.fromString(role ?? '')}');
  setState(() {
    _loggedIn = true;
    _email = email;
    _username = (username ?? '').trim();
    _userId = userId;
    _role = (role ?? '').trim();
    _userRole = UserRoleExt.fromString(_role);
    _tab = 0;
  });
  print('DEBUG _userRole after setState: $_userRole');
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('logged_in', true);
      prefs.setString('logged_in_email', email);
      prefs.setString('logged_in_username', (username ?? '').trim());
      if (userId != null) {
        prefs.setInt('logged_in_user_id', userId);
      } else {
        prefs.remove('logged_in_user_id');
      }
      prefs.setString('logged_in_role', (role ?? '').trim());
    });
    _restoreSubmissionState(email);
    _loadListings();
    _loadLostFound();
  }

  void _logout() => setState(() {
        _loggedIn = false;
        _email = '';
        _username = '';
        _userId = null;
        _role = '';
        _userRole = UserRole.unknown;
        _tab = 0;
        _submittedClaimItemIds.clear();
        _submittedMatchItemIds.clear();
      });
  
  void _clearSession() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('logged_in');
      prefs.remove('logged_in_email');
      prefs.remove('logged_in_username');
      prefs.remove('logged_in_user_id');
      prefs.remove('logged_in_role');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionLoaded) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: cBg,
          body: const Center(child: CircularProgressIndicator(color: cRed)),
        ),
      );
    }

    return MaterialApp(
      title: 'UniFind',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: !_loggedIn
          ? LandingPage(onLogin: _login)
          : RoleAuthWrapper(
              role: _userRole,
              email: _email,
              username: _username,
              userId: _userId,
              onLogout: () { _logout(); _clearSession(); },
              market: _market,
              lostFound: _lostFound,
              tab: _tab,
              postFormNonce: _postFormNonce,
              postDefaultType: _postDefaultType,
              submittedClaimItemIds: _submittedClaimItemIds,
              submittedMatchItemIds: _submittedMatchItemIds,
              goToPostTab: _goToPostTab,
              addListing: _addListing,
              claimLostItem: _claimLostItem,
              postFoundMatch: _postFoundMatch,
              editMarketplace: _editMarketplaceItem,
              editLostFound: _editLostFoundItem,
              onTabChanged: (index) {
                setState(() => _tab = index);
                if (index == 3 || index == 0 || index == 1) {
                  _loadListings();
                  _loadLostFound();
                }
              },
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
      // ─── ADDED: Navigation bar theme ───────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cSurface,
        indicatorColor: cRedLight,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cRed,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: cMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: cRed, size: 22);
          }
          return const IconThemeData(color: cMuted, size: 22);
        }),
      ),
    );
  }
}