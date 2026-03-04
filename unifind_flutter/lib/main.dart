import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'api_service.dart';

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

  final List<MarketplaceItem> _market = List.from(seedMarketplace);
  final List<LostFoundItem> _lostFound = List.from(seedLostFound);

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

// ─── MAIN SHELL ──────────────────────────────────────────────────────────────
class _MainShell extends StatelessWidget {
  final int tab;
  final String email;
  final String owner;
  final List<MarketplaceItem> market;
  final List<LostFoundItem> lostFound;
  final ValueChanged<int> onTabChange;
  final void Function(NewListingInput) onPost;
  final VoidCallback onLogout;

  const _MainShell({
    required this.tab,
    required this.email,
    required this.owner,
    required this.market,
    required this.lostFound,
    required this.onTabChange,
    required this.onPost,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final screens = [
      MarketplaceScreen(items: market, onListItem: () => onTabChange(2)),
      LostFoundScreen(items: lostFound),
      PostListingScreen(onPost: onPost),
      MyListingsScreen(
        marketplaceItems: market.where((i) => i.seller == owner).toList(),
        lostFoundItems: lostFound.where((i) => i.poster == owner).toList(),
        onListItem: () => onTabChange(2),
      ),
      const DocumentationScreen(),
    ];

    return Scaffold(
      appBar: _GlassAppBar(email: email, onLogout: onLogout),
      body: AnimatedSwitcher(
        duration: kPage,
        transitionBuilder: (child, anim) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: KeyedSubtree(key: ValueKey(tab), child: screens[tab]),
      ),
      bottomNavigationBar: _AnimatedNavBar(current: tab, onTap: onTabChange),
    );
  }
}

// ─── GLASS APP BAR ───────────────────────────────────────────────────────────
class _GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String email;
  final VoidCallback onLogout;
  const _GlassAppBar({required this.email, required this.onLogout});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [cNavBg, cNavBgDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Color(0x44A12727), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              // Logo
              Image.asset(
                'assets/images/whitelogo.png',
                height: 34,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('UniFind', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.3)),
                  Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                ],
              ),
              const Spacer(),
              _PillButton(
                label: 'Log out',
                icon: Icons.logout_rounded,
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kFast);
    _scale = Tween(begin: 1.0, end: 0.94).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
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
            duration: kFast,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.30)
                  : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: _hovered ? 0.6 : 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── ANIMATED NAV BAR ────────────────────────────────────────────────────────
class _NavItemData {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  const _NavItemData(this.activeIcon, this.inactiveIcon, this.label);
}

class _AnimatedNavBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _AnimatedNavBar({required this.current, required this.onTap});

  static const List<_NavItemData> _items = [
    _NavItemData(Icons.storefront_rounded, Icons.storefront_outlined, 'Shop'),
    _NavItemData(Icons.search_rounded, Icons.search_outlined, 'Lost & Found'),
    _NavItemData(Icons.add_circle_rounded, Icons.add_circle_outline_rounded, 'Post'),
    // FIX 5: Changed label from 'My' to 'My List' so it's readable and not cut off
    _NavItemData(Icons.inventory_2_rounded, Icons.inventory_2_outlined, 'My List'),
    _NavItemData(Icons.menu_book_rounded, Icons.menu_book_outlined, 'Docs'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: cSurface,
        boxShadow: [BoxShadow(color: Color(0x15000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final selected = i == current;
              final item = _items[i];
              return _NavItem(
                icon: selected ? item.activeIcon : item.inactiveIcon,
                label: item.label,
                selected: selected,
                isPost: i == 2,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isPost;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.isPost, required this.onTap});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale, _bounce;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kMid);
    _scale = Tween(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _c, curve: Curves.elasticOut));
    _bounce = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_NavItem old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) {
      _c.forward(from: 0);
    } else if (!widget.selected && old.selected) {
      _c.reverse();
    }
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.isPost) {
      return GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: kMid,
          curve: Curves.easeOutCubic,
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: widget.selected
                ? const LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : LinearGradient(colors: [cRed.withValues(alpha: 0.85), cRedDark.withValues(alpha: 0.85)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: cRed.withValues(alpha: widget.selected ? 0.5 : 0.3), blurRadius: widget.selected ? 16 : 8, offset: const Offset(0, 4))],
          ),
          child: ScaleTransition(
            scale: _scale,
            child: Icon(widget.icon, color: Colors.white, size: widget.selected ? 26 : 24),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      // FIX 5: Widened from 64 to 72 to prevent label text from being cut off
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: kMid,
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: widget.selected ? cRedLight : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ScaleTransition(
                scale: _scale,
                child: Icon(widget.icon, color: widget.selected ? cRed : cMuted, size: 22),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: kFast,
              style: TextStyle(
                fontSize: 10,
                color: widget.selected ? cRed : cMuted,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.normal,
              ),
              child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── LANDING PAGE ────────────────────────────────────────────────────────────
class LandingPage extends StatelessWidget {
  final void Function(String) onLogin;
  const LandingPage({super.key, required this.onLogin});

  static final _aboutKey = GlobalKey();
  static final _howKey = GlobalKey();
  static final _faqKey = GlobalKey();

  void _scrollTo(GlobalKey k) {
    final ctx = k.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: kSlow, curve: Curves.easeInOutCubic);
  }

  void _openLogin(BuildContext ctx) {
    Navigator.of(ctx).push(PageRouteBuilder(
      transitionDuration: kPage,
      pageBuilder: (_, a, __) => FadeTransition(
        opacity: a,
        child: LoginScreen(
          onLogin: (email) {
            onLogin(email);
            Navigator.of(ctx).popUntil((r) => r.isFirst);
          },
        ),
      ),
    ));
  }
void _openRegister(BuildContext ctx) {
  Navigator.of(ctx).push(PageRouteBuilder(
    transitionDuration: kPage,
    pageBuilder: (_, a, __) => FadeTransition(
      opacity: a,
      child: RegistrationScreen(
        onRegister: (email) {
          onLogin(email);
          Navigator.of(ctx).popUntil((r) => r.isFirst);
        },
      ),
    ),
  ));
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cSurface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LandingNav(
              onAbout: () => _scrollTo(_aboutKey),
              onHow: () => _scrollTo(_howKey),
              onFaq: () => _scrollTo(_faqKey),
              onLogin: () => _openLogin(context),
              onRegister: () => _openRegister(context),
            ),
            _HeroSection(onLogin: () => _openLogin(context), onRegister: () => _openRegister(context)),
            KeyedSubtree(key: _howKey, child: const _HowItWorksSection()),
            const _FeaturesSection(),
            KeyedSubtree(key: _aboutKey, child: const _AboutSection()),
            KeyedSubtree(key: _faqKey, child: const _FaqSection()),
            _ExclusiveBanner(onLogin: () => _openRegister(context)),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

// ─── LANDING NAV ─────────────────────────────────────────────────────────────
class _LandingNav extends StatelessWidget {
  final VoidCallback onAbout, onHow, onFaq, onLogin, onRegister;
  const _LandingNav({required this.onAbout, required this.onHow, required this.onFaq, required this.onLogin, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    final navItems = <MapEntry<String, VoidCallback>>[
      MapEntry('About', onAbout),
      MapEntry('How It Works', onHow),
      MapEntry('FAQ', onFaq),
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [cNavBg, cNavBgDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: Color(0x33A12727), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 920;

          if (isCompact) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnimatedLogo(),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...navItems.map((e) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: TextButton(
                                onPressed: e.value,
                                child: Text(
                                  e.key,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            )),
                        Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 8)),
                        TextButton(
                          onPressed: onLogin,
                          child: const Text('Log In', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        _PillButton(label: 'Sign Up', icon: Icons.person_add_rounded, onTap: onRegister),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Row(
              children: [
                _AnimatedLogo(),
                const Spacer(),
                ...navItems.map((e) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: TextButton(
                        onPressed: e.value,
                        child: Text(e.key, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    )),
                Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 8)),
                TextButton(
                  onPressed: onLogin,
                  child: const Text('Log In', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                _PillButton(label: 'Sign Up', icon: Icons.person_add_rounded, onTap: onRegister),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedLogo extends StatefulWidget {
  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          child: Image.asset(
            'assets/images/whitelogo.png',
            height: 44,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// ─── HERO SECTION ────────────────────────────────────────────────────────────
class _HeroSection extends StatefulWidget {
  final VoidCallback onLogin, onRegister;
  const _HeroSection({required this.onLogin, required this.onRegister});
  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _slide, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _slide = Tween(begin: 30.0, end: 0.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.easeOutCubic)));
    _scale = Tween(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.easeOutCubic)));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(
          offset: Offset(0, _slide.value),
          child: Transform.scale(scale: _scale.value, child: child),
        ),
      ),
      child: Stack(
        children: [
          // Background decoration
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFF5F5), Color(0xFFFCECEC), Color(0xFFFFF8F8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Decorative circle
          Positioned(
            right: -60,
            top: -40,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [cRed.withValues(alpha: 0.08), Colors.transparent]),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -20,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [cRed.withValues(alpha: 0.06), Colors.transparent]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
            child: Column(
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: cRedLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school_rounded, size: 14, color: cRed),
                      SizedBox(width: 6),
                      Text('MSU Campus Exclusive', style: TextStyle(color: cRed, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Your Campus.\nYour Marketplace.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: cText,
                    height: 1.15,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Buy, sell, and reunite with lost items within the\nMontclair State University community.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, color: cMuted, height: 1.7),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _HeroButton(label: 'Get Started', primary: true, onTap: widget.onRegister),
                    const SizedBox(width: 14),
                    _HeroButton(label: 'Log In', primary: false, onTap: widget.onLogin),
                  ],
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatefulWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _HeroButton({required this.label, required this.primary, required this.onTap});

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kFast);
    _scale = Tween(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
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
            duration: kFast,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: widget.primary
                  ? LinearGradient(
                      colors: _hovered ? [cRedDark, Color(0xFF5A0A0A)] : [cRed, cRedDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: widget.primary ? null : (_hovered ? cRedLight : cSurface),
              borderRadius: BorderRadius.circular(32),
              border: widget.primary ? null : Border.all(color: cRed, width: 2),
              boxShadow: widget.primary
                  ? [BoxShadow(color: cRed.withValues(alpha: _hovered ? 0.55 : 0.35), blurRadius: _hovered ? 24 : 16, offset: const Offset(0, 6))]
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: widget.primary ? Colors.white : cRed,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── HOW IT WORKS ────────────────────────────────────────────────────────────
class _HowItWorksSection extends StatefulWidget {
  const _HowItWorksSection();
  @override
  State<_HowItWorksSection> createState() => _HowItWorksSectionState();
}

class _StepData {
  final IconData icon;
  final String title, desc;
  const _StepData({required this.icon, required this.title, required this.desc});
}

class _HowItWorksSectionState extends State<_HowItWorksSection> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward(); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const List<_StepData> steps = [
      _StepData(icon: Icons.person_add_rounded, title: 'Sign Up', desc: 'Create an account using your Montclair State University email to join the community.'),
      _StepData(icon: Icons.add_circle_rounded, title: 'Browse or Post', desc: 'Find items for sale, report lost belongings, or create your own listings.'),
      _StepData(icon: Icons.handshake_rounded, title: 'Connect', desc: 'Message students, arrange pickups, and complete exchanges safely on campus.'),
    ];
    return Container(
      color: cSurface,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 72),
      child: Column(
        children: [
          _SectionLabel(label: 'HOW IT WORKS'),
          const SizedBox(height: 12),
          const Text('Three simple steps', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.8)),
          const SizedBox(height: 8),
          const Text('to get started on UniFind.', style: TextStyle(fontSize: 16, color: cMuted)),
          const SizedBox(height: 52),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: List.generate(steps.length, (i) {
              final s = steps[i];
              final delay = Duration(milliseconds: 120 * i);
              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 200),
                child: _StepCard(icon: s.icon, title: s.title, desc: s.desc, delay: delay),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: cRed, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
    );
  }
}

class _StepCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  final Duration delay;
  const _StepCard({required this.icon, required this.title, required this.desc, required this.delay});

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kMid);
    _scale = Tween(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) { setState(() => _hovered = true); _c.forward(); },
      onExit: (_) { setState(() => _hovered = false); _c.reverse(); },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: kMid,
          width: 270,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _hovered ? cRedLight : cSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _hovered ? cRed.withValues(alpha: 0.4) : cBorder, width: 1.5),
            boxShadow: [BoxShadow(color: _hovered ? cRed.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06), blurRadius: _hovered ? 20 : 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 16),
              Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cText)),
              const SizedBox(height: 8),
              Text(widget.desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: cMuted, height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── FEATURES ────────────────────────────────────────────────────────────────
class _FeatureData {
  final IconData icon;
  final String title, desc;
  const _FeatureData(this.icon, this.title, this.desc);
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    const List<_FeatureData> features = [
      _FeatureData(Icons.storefront_rounded, 'Campus Marketplace', 'Buy and sell textbooks, electronics, furniture, clothing, and more with other MSU students.'),
      _FeatureData(Icons.search_rounded, 'Lost & Found', 'Report lost items or post things you\'ve found to help reunite students with their belongings.'),
      _FeatureData(Icons.bolt_rounded, 'Post in Seconds', 'Create a listing with a title, photo, price, and category in just a few clicks.'),
      _FeatureData(Icons.verified_user_rounded, 'MSU Community Only', 'Exclusively for Montclair State University members — a trusted, verified space you can rely on.'),
    ];

    return Container(
      color: const Color(0xFFF8F2F2),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 72),
      child: Column(
        children: [
          _SectionLabel(label: 'FEATURES'),
          const SizedBox(height: 12),
          const Text('Everything you need', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.8)),
          const SizedBox(height: 8),
          const Text('for campus life, simplified.', style: TextStyle(fontSize: 16, color: cMuted)),
          const SizedBox(height: 52),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: features.map((f) => _FeatureCard(icon: f.icon, title: f.title, desc: f.desc)).toList(),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  const _FeatureCard({required this.icon, required this.title, required this.desc});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _lift;
  bool _hov = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kMid);
    _lift = Tween(begin: 0.0, end: -6.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) { setState(() => _hov = true); _c.forward(); },
      onExit: (_) { setState(() => _hov = false); _c.reverse(); },
      child: AnimatedBuilder(
        animation: _lift,
        builder: (_, child) => Transform.translate(offset: Offset(0, _lift.value), child: child),
        child: AnimatedContainer(
          duration: kMid,
          width: 270,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: cSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _hov ? cRed.withValues(alpha: 0.3) : cBorder),
            boxShadow: [BoxShadow(color: _hov ? cRed.withValues(alpha: 0.14) : Colors.black.withValues(alpha: 0.07), blurRadius: _hov ? 24 : 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: kMid,
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: _hov
                      ? const LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight)
                      : const LinearGradient(colors: [cRedLight, cRedLight]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: _hov ? Colors.white : cRed, size: 24),
              ),
              const SizedBox(height: 16),
              Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cText)),
              const SizedBox(height: 8),
              Text(widget.desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: cMuted, height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ABOUT ───────────────────────────────────────────────────────────────────
class _AboutData {
  final IconData icon;
  final String title, desc;
  final bool shaded;
  const _AboutData(this.icon, this.title, this.desc, this.shaded);
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    const List<_AboutData> items = [
      _AboutData(Icons.school_rounded, 'Our Mission', 'UniFind was created to make campus life easier at MSU. We believe everyone deserves a safe, trusted platform to buy, sell, and recover lost belongings within their own community.', false),
      _AboutData(Icons.groups_rounded, 'Who We Are', 'We are MSU students who saw a need for a dedicated campus marketplace. UniFind is built with the MSU community in mind — every feature is designed around how students actually live on campus.', true),
      _AboutData(Icons.favorite_rounded, 'Why UniFind', 'Unlike other marketplaces, UniFind is exclusively for MSU community members. That means safer transactions, familiar faces, and a community you can trust. No strangers, just fellow Red Hawks.', false),
    ];
    return Container(
      color: cSurface,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 72),
      child: Column(
        children: [
          _SectionLabel(label: 'ABOUT'),
          const SizedBox(height: 12),
          const Text('About UniFind', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.8)),
          const SizedBox(height: 8),
          const Text('Built for the Red Hawk community.', style: TextStyle(fontSize: 16, color: cMuted)),
          const SizedBox(height: 52),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: items.map((i) => _AboutRow(icon: i.icon, title: i.title, desc: i.desc, shaded: i.shaded)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatefulWidget {
  final IconData icon;
  final String title, desc;
  final bool shaded;
  const _AboutRow({required this.icon, required this.title, required this.desc, required this.shaded});

  @override
  State<_AboutRow> createState() => _AboutRowState();
}

class _AboutRowState extends State<_AboutRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: _hovered
            ? Matrix4.translationValues(0, -8, 0)
            : Matrix4.identity(),
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: widget.shaded ? cRedLight : cSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? cRed.withValues(alpha: 0.4) : cBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? cRed.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: _hovered ? 24 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [cRed, cRedDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: cRed.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(widget.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: cRed,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.desc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: cMuted,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FAQ ─────────────────────────────────────────────────────────────────────
class _FaqData {
  final String question, answer;
  const _FaqData(this.question, this.answer);
}

class _FaqSection extends StatelessWidget {
  const _FaqSection();

  @override
  Widget build(BuildContext context) {
    const List<_FaqData> faqs = [
      _FaqData('Who can use UniFind?', 'UniFind is exclusively for Montclair State University students, faculty, and staff. You must sign up with a valid MSU email address to access the platform.'),
      _FaqData('Is UniFind safe?', 'Yes! UniFind will have administrators monitoring listings and users to ensure listings are legitimate and all users are verified MSU students and faculty.'),
      _FaqData('How do I post an item for sale?', 'After signing in, tap the "Post" tab at the bottom of the app. Fill in the title, description, price, category, and location. It takes less than a minute!'),
      _FaqData('What categories are available?', 'You can list items under Textbooks, Electronics, Furniture, Clothing, and Other. The Lost & Found board supports Electronics, Bags, Keys, ID/Cards, Clothing, and Other.'),
      _FaqData('How does Lost & Found work?', 'Students can post items they\'ve lost or found on campus. Browse the feed, filter by category, and reach out to reunite items with their owners.'),
      _FaqData('How do I contact a seller?', 'Once signed in and viewing a listing, you can message the seller directly through the app to arrange a meetup or ask questions.'),
    ];
    return Container(
      color: const Color(0xFFF8F2F2),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 72),
      child: Column(
        children: [
          _SectionLabel(label: 'FAQ'),
          const SizedBox(height: 12),
          const Text('Frequently asked questions', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.8)),
          const SizedBox(height: 8),
          const Text('Everything you need to know before getting started', style: TextStyle(fontSize: 16, color: cMuted)),
          const SizedBox(height: 52),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(children: faqs.map((f) => _FaqTile(question: f.question, answer: f.answer)).toList()),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question, answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _expand, _rotate;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kMid);
    _expand = CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic);
    _rotate = Tween(begin: 0.0, end: 0.5).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) _c.forward(); else _c.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _open ? cRed.withValues(alpha: 0.4) : cBorder, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: _open ? 0.08 : 0.04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _open ? cRed : cRedLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: RotationTransition(
                      turns: _rotate,
                      child: Icon(Icons.keyboard_arrow_down_rounded, color: _open ? Colors.white : cRed, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(widget.question, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _open ? cRed : cText)),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expand,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(64, 0, 18, 18),
              child: Text(widget.answer, style: const TextStyle(fontSize: 13, color: cMuted, height: 1.7)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── EXCLUSIVE BANNER ────────────────────────────────────────────────────────
class _ExclusiveBanner extends StatelessWidget {
  final VoidCallback onLogin;
  const _ExclusiveBanner({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [cNavBg, cNavBgDark, Color(0xFF4A0A0A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 20),
          const Text('Made for the Red Hawk Community', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 14),
          Text('UniFind is designed solely for MSU — a safe, verified space to sell and connect.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 15, height: 1.6)),
          const SizedBox(height: 32),
          _HeroButton(label: 'Join UniFind Today', primary: false, onTap: onLogin),
        ],
      ),
    );
  }
}

// ─── FOOTER ──────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: const Center(
        child: Text('© 2026 UniFind · Montclair State University', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
      ),
    );
  }
}

// ─── LOGIN SCREEN ────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  final void Function(String) onLogin;
  const LoginScreen({super.key, required this.onLogin});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _loading = false;
  String? _errorMessage;
  late AnimationController _c;
  late Animation<double> _fade, _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _slide = Tween(begin: 24.0, end: 0.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  String _loginErrorMessage(ApiException e) {
    switch (e.code) {
      case 'INVALID_CREDENTIALS':
        return 'Invalid email or password.';
      case 'EMAIL_NOT_FOUND':
        return 'No account found for this email. Please sign up first.';
      case 'ACCOUNT_UNVERIFIED':
        return 'Your account is not verified yet. Please complete verification.';
      default:
        return e.message;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final data = await loginUser(_email.trim(), _password);
      final user = data['user'] as Map<String, dynamic>?;
      final loggedInEmail = (user?['email'] as String?) ?? _email.trim();
      if (!mounted) return;
      widget.onLogin(loggedInEmail);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _loginErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: Stack(
        children: [
          // Background decoration
          Positioned(right: -80, top: -80, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [cRed.withValues(alpha: 0.08), Colors.transparent])))),
          Positioned(left: -60, bottom: -60, child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [cRed.withValues(alpha: 0.05), Colors.transparent])))),
          Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, child) => Opacity(
                opacity: _fade.value,
                child: Transform.translate(offset: Offset(0, _slide.value), child: child),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/logo.jpg',
                        height: 90,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      const Text('Welcome back!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      const Text('Sign in to your UniFind account', style: TextStyle(fontSize: 14, color: cMuted)),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: cSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: cBorder),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 6))],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _StyledField(
                                label: 'Email Address',
                                hint: 'you@montclair.edu',
                                icon: Icons.mail_outline_rounded,
                                onChanged: (v) => _email = v,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email is required';
                                  if (!v.contains('@')) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _StyledField(
                                label: 'Password',
                                hint: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                obscure: true,
                                onChanged: (v) => _password = v,
                                validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: cRedDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              _AuthButton(loading: _loading, onTap: _submit, label: 'Sign In'),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Forgot Password?'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('← Back to homepage', style: TextStyle(color: cMuted, fontSize: 13)),
                      ),
                    ],
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

// ─── FORGOT PASSWORD SCREEN ─────────────────────────────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _code = '';
  String _newPassword = '';
  bool _loading = false;
  bool _codeSent = false;
  bool _emailNotFound = false;
  String? _errorMessage;
  late AnimationController _c;
  late Animation<double> _fade, _slide;

  @override
  void initState() {
    super.initState();
    _email = (widget.initialEmail ?? '').trim().toLowerCase();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOut),
    );
    _slide = Tween(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _forgotPasswordErrorMessage(ApiException e) {
    switch (e.code) {
      case 'EMAIL_NOT_FOUND':
        return 'No account found with this email. Please sign up first.';
      case 'INVALID_CODE':
        return 'That reset code is invalid. Please check and try again.';
      case 'CODE_EXPIRED':
        return 'Your reset code expired. Request a new code.';
      case 'WEAK_PASSWORD':
        return 'Use a stronger password (at least 8 characters).';
      case 'TOO_MANY_REQUESTS':
        return 'Too many attempts. Please wait a bit and try again.';
      default:
        return e.message;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
      _emailNotFound = false;
    });

    try {
      if (!_codeSent) {
        final response = await requestPasswordReset(_email.trim().toLowerCase());
        if (!mounted) return;
        setState(() => _codeSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message']?.toString() ?? 'Reset code sent to your email.',
            ),
          ),
        );
      } else {
        await resetPassword(
          email: _email.trim().toLowerCase(),
          code: _code.trim(),
          newPassword: _newPassword,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successful. Please log in.')),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _forgotPasswordErrorMessage(e);
        _emailNotFound = e.code == 'EMAIL_NOT_FOUND';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _emailNotFound = false;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: Stack(
        children: [
          Positioned(
            right: -80,
            top: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [cRed.withValues(alpha: 0.08), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            left: -60,
            bottom: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [cRed.withValues(alpha: 0.05), Colors.transparent],
                ),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, child) => Opacity(
                opacity: _fade.value,
                child: Transform.translate(offset: Offset(0, _slide.value), child: child),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      Image.asset('assets/images/logo.jpg', height: 90, fit: BoxFit.contain),
                      const SizedBox(height: 24),
                      const Text(
                        'Forgot Password',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: cText,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _codeSent
                            ? 'Enter the code sent to your email and set a new password'
                            : 'Enter your MSU email to receive a reset code',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: cMuted),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: cSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: cBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _StyledField(
                                label: 'MSU Email Address',
                                hint: 'you@montclair.edu',
                                icon: Icons.mail_outline_rounded,
                                initialValue: _email,
                                onChanged: (v) => _email = v,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email is required';
                                  if (!v.toLowerCase().trim().endsWith('@montclair.edu')) {
                                    return 'Must use an @montclair.edu email';
                                  }
                                  return null;
                                },
                              ),
                              if (_codeSent) ...[
                                const SizedBox(height: 16),
                                _StyledField(
                                  label: 'Reset Code',
                                  hint: 'Enter code from your email',
                                  icon: Icons.verified_outlined,
                                  onChanged: (v) => _code = v,
                                  validator: (v) {
                                    if (!_codeSent) return null;
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Reset code is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _StyledField(
                                  label: 'New Password',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: true,
                                  onChanged: (v) => _newPassword = v,
                                  validator: (v) {
                                    if (!_codeSent) return null;
                                    if (v == null || v.isEmpty) return 'New password is required';
                                    if (v.length < 8) return 'Minimum 8 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _StyledField(
                                  label: 'Confirm New Password',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: true,
                                  validator: (v) {
                                    if (!_codeSent) return null;
                                    if (v == null || v.isEmpty) return 'Please confirm your password';
                                    if (v != _newPassword) return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                              ],
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: cRedDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              _AuthButton(
                                loading: _loading,
                                onTap: _submit,
                                label: _codeSent ? 'Reset Password' : 'Send Reset Code',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back, size: 14, color: cMuted),
                              SizedBox(width: 6),
                              Text('Back to login', style: TextStyle(color: cMuted, fontSize: 13)),
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
        ],
      ),
    );
  }
}

// ─── REGISTRATION SCREEN ─────────────────────────────────────────────────────
class RegistrationScreen extends StatefulWidget {
  final void Function(String email) onRegister;
  const RegistrationScreen({super.key, required this.onRegister});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _code = '';
  bool _loading = false;
  bool _codeSent = false;
  String? _errorMessage;
  late AnimationController _c;
  late Animation<double> _fade, _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _slide = Tween(begin: 24.0, end: 0.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      if (!_codeSent) {
        await sendSignupVerificationCode(
          email: _email.trim().toLowerCase(),
          password: _password.isEmpty ? 'TempPass123!' : _password,
        );
        if (!mounted) return;
        setState(() => _codeSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent. Now set your password and enter the code.'),
          ),
        );
      } else {
        await verifyCodeAndCreateAccount(
          email: _email.trim().toLowerCase(),
          password: _password,
          code: _code.trim(),
        );
        if (!mounted) return;
        widget.onRegister(_email.trim().toLowerCase());
      }
    } on ApiException catch (e) {
      if (!mounted) return;

      if (e.code == 'USER_EXISTS') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email already registered. Please log in.'),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LoginScreen(
              onLogin: widget.onRegister,
            ),
          ),
        );
        return;
      }

      setState(() {
        if (!_codeSent && e.message.toLowerCase().contains('password')) {
          _errorMessage = 'Unable to start sign up. Please try again.';
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: Stack(
        children: [
          Positioned(right: -80, top: -80, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [cRed.withValues(alpha: 0.08), Colors.transparent])))),
          Positioned(left: -60, bottom: -60, child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [cRed.withValues(alpha: 0.05), Colors.transparent])))),
          Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, child) => Opacity(
                opacity: _fade.value,
                child: Transform.translate(offset: Offset(0, _slide.value), child: child),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      Image.asset('assets/images/logo.jpg', height: 90, fit: BoxFit.contain),
                      const SizedBox(height: 24),
                      const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Text(
                        _codeSent
                            ? 'Set your password and verify your email'
                            : 'Enter your MSU email to begin sign up',
                        style: const TextStyle(fontSize: 14, color: cMuted),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: cSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: cBorder),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 6))],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _StyledField(
                                label: 'MSU Email Address',
                                hint: 'you@montclair.edu',
                                icon: Icons.mail_outline_rounded,
                                onChanged: (v) => _email = v,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email is required';
                                  if (!v.toLowerCase().trim().endsWith('@montclair.edu')) {
                                    return 'Must use an @montclair.edu email';
                                  }
                                  return null;
                                },
                              ),
                              if (_codeSent) ...[
                                const SizedBox(height: 16),
                                _StyledField(
                                  label: 'Password',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: true,
                                  onChanged: (v) => _password = v,
                                  validator: (v) {
                                    if (!_codeSent) return null;
                                    if (v == null || v.isEmpty) return 'Password is required';
                                    if (v.length < 8) return 'Minimum 8 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _StyledField(
                                  label: 'Confirm Password',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: true,
                                  validator: (v) {
                                    if (!_codeSent) return null;
                                    if (v == null || v.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    if (v != _password) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _StyledField(
                                  label: 'Verification Code',
                                  hint: 'Enter code from your email',
                                  icon: Icons.verified_outlined,
                                  onChanged: (v) => _code = v,
                                  validator: (v) {
                                    if (!_codeSent) return null;
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Verification code is required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: cRedDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              _AuthButton(
                                loading: _loading,
                                onTap: _submit,
                                label: _codeSent
                                    ? 'Verify & Create Account'
                                    : 'Send Verification Code',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back, size: 14, color: cMuted),
                              SizedBox(width: 6),
                              Text('Back to login', style: TextStyle(color: cMuted, fontSize: 13)),
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
        ],
      ),
    );
  }
}

// ─── AUTH BUTTON ─────────────────────────────────────────────────────────────
class _AuthButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;
  final String label;
  const _AuthButton({required this.loading, required this.onTap, required this.label});

  @override
  State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

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
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
          ),
        ),
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  final String label, hint;
  final IconData icon;
  final bool obscure;
  final String? initialValue;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const _StyledField({
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.initialValue,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cText, letterSpacing: 0.3)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          obscureText: obscure,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: cMuted, fontSize: 14),
            prefixIcon: Icon(icon, size: 18, color: cMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cRed, width: 2)),
            filled: true,
            fillColor: cBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ─── MARKETPLACE SCREEN ──────────────────────────────────────────────────────
class MarketplaceScreen extends StatefulWidget {
  final List<MarketplaceItem> items;
  final VoidCallback onListItem;
  const MarketplaceScreen({super.key, required this.items, required this.onListItem});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _cat = 'All';
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((i) {
      final cm = _cat == 'All' || i.category == _cat;
      final sm = i.title.toLowerCase().contains(_q.toLowerCase()) || i.description.toLowerCase().contains(_q.toLowerCase());
      return cm && sm;
    }).toList();

    return Column(
      children: [
        // Header
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
              _HoverButton(
                child: _RedButton(
                  label: 'List Item',
                  icon: Icons.add_rounded,
                  onTap: widget.onListItem,
                ),
              ),
            ],
          ),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.all(12),
          child: _SearchField(hint: 'Search marketplace...', onChanged: (v) => setState(() => _q = v)),
        ),
        // FIX 2 & 3: Category chips with fixed gap and hover animation
        SizedBox(
          height: 28,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: categories.map((c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(label: c, selected: _cat == c, onTap: () => setState(() => _cat = c)),
            )).toList(),
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
                    crossAxisCount: 3,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (ctx, i) => _MarketCard(
                    item: filtered[i],
                    onTap: () => Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => ItemDetailScreen(item: filtered[i]))),
                  ),
                ),
        ),
      ],
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
      child: AnimatedScale(
        scale: _hovering ? 1.08 : 1.0, // 👈 zoom effect
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ─── MARKET CARD — FIX 4: Added hover animation ───────────────────────────
class _MarketCard extends StatefulWidget {
  final MarketplaceItem item;
  final VoidCallback onTap;
  const _MarketCard({required this.item, required this.onTap});

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
                blurRadius: _hovered ? 18 : 10,
                offset: const Offset(0, 3),
              )],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Image.network(
                        widget.item.image,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(color: cPlaceholder, child: Center(child: Icon(Icons.image_not_supported, color: cMuted))),
                      ),
                      // Category badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cRed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(widget.item.category, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('\$${widget.item.price.toStringAsFixed(0)}', style: const TextStyle(color: cRed, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
                      const SizedBox(height: 3),
                      Text(widget.item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cText)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 11, color: cMuted),
                          const SizedBox(width: 3),
                          Expanded(child: Text(widget.item.location, style: const TextStyle(fontSize: 11, color: cMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(widget.item.condition, style: const TextStyle(fontSize: 11, color: cMuted)),
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

// ─── LOST & FOUND SCREEN ─────────────────────────────────────────────────────
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

// ─── POST LISTING SCREEN ─────────────────────────────────────────────────────
class PostListingScreen extends StatefulWidget {
  final void Function(NewListingInput) onPost;
  const PostListingScreen({super.key, required this.onPost});

  @override
  State<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends State<PostListingScreen> {
  final _formKey = GlobalKey<FormState>();
  ListingType _type = ListingType.marketplace;
  String _title = '', _desc = '', _cat = '', _cond = 'Good', _loc = '';
  double _price = 0;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  List<String> get _cats => _type == ListingType.marketplace
      ? categories.where((c) => c != 'All').toList()
      : lostFoundCategories.where((c) => c != 'All').toList();

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
                      Text('Create a new listing', style: TextStyle(fontSize: 12, color: cMuted)),
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
                  Expanded(child: _TypeBtn(label: 'For Sale', type: ListingType.marketplace, selected: _type == ListingType.marketplace, onTap: () => setState(() { _type = ListingType.marketplace; _cat = ''; }))),
                  const SizedBox(width: 8),
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
              _StyledField(
                label: 'Location *',
                hint: 'e.g. Blanton Hall',
                icon: Icons.location_on_outlined,
                onChanged: (v) => _loc = v,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Location is required' : null,
              ),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'Item posted successfully!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: cRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ),
      );

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
        height: 44,
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

// ─── MY LISTINGS ─────────────────────────────────────────────────────────────
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

// ─── DOCS SCREEN ─────────────────────────────────────────────────────────────
class DocumentationScreen extends StatelessWidget {
  const DocumentationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('UniFind Docs', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              SizedBox(height: 4),
              Text('Everything you need to know', style: TextStyle(color: Color(0xFFFFCCCC), fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DocSection(title: 'Overview', content: 'UniFind is a campus marketplace and lost-and-found app for Montclair State University. Browse listings, filter by category, post items, and track your own listings.'),
        _DocSection(title: 'Marketplace', content: 'Browse items for sale from other MSU students. Filter by category (Textbooks, Electronics, Furniture, Clothing, Other) and search by keyword. Tap any item to see full details and contact the seller.'),
        _DocSection(title: 'Lost & Found', content: 'View lost and found reports from the community. Filter between "Lost" and "Found" items, and browse by category to find matches.'),
        _DocSection(title: 'Posting a Listing', content: 'Tap the Post tab to create a listing. Choose the type (For Sale, Lost, Found), fill in the required fields, and hit Post Item. Your listing appears immediately.'),
        _DocSection(title: 'My Listings', content: 'View all your posted marketplace items and lost/found reports in one place. Switch between tabs to manage each type.'),
      ],
    );
  }
}

class _DocSection extends StatelessWidget {
  final String title, content;
  const _DocSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cRed)),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 13, color: cMuted, height: 1.6)),
        ],
      ),
    );
  }
}

// ─── ITEM DETAIL SCREEN ──────────────────────────────────────────────────────
class ItemDetailScreen extends StatelessWidget {
  final MarketplaceItem item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: cNavBg,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                item.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(color: cPlaceholder, child: Center(child: Icon(Icons.image_not_supported, size: 48, color: cMuted))),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('\$${item.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: cRed, letterSpacing: -1)),
                            const SizedBox(height: 4),
                            Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cText, letterSpacing: -0.3)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: cRed, borderRadius: BorderRadius.circular(10)),
                        child: Text(item.category, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cSurface, borderRadius: BorderRadius.circular(14), border: Border.all(color: cBorder)),
                    child: Column(
                      children: [
                        _DetailRow(icon: Icons.stars_rounded, label: 'Condition', value: item.condition),
                        _DetailRow(icon: Icons.location_on_outlined, label: 'Location', value: item.location),
                        _DetailRow(icon: Icons.calendar_today_outlined, label: 'Posted', value: formatDate(item.createdAt)),
                        _DetailRow(icon: Icons.person_outline_rounded, label: 'Seller', value: item.seller, isLast: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cText)),
                  const SizedBox(height: 8),
                  Text(item.description, style: const TextStyle(fontSize: 13, color: cMuted, height: 1.7)),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(children: [Icon(Icons.message_rounded, color: Colors.white, size: 18), SizedBox(width: 10), Text('Contact flow coming soon!')]),
                        backgroundColor: cRed,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.all(12),
                      ),
                    ),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5))],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.message_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Contact Seller', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isLast;
  const _DetailRow({required this.icon, required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: cRed),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 12, color: cMuted, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cText)),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: cBorder),
      ],
    );
  }
}

// ─── SHARED COMPONENTS ───────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: cMuted, fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded, color: cMuted, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cRed, width: 2)),
        filled: true,
        fillColor: cSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

// FIX 2 & 3: _Chip is now StatefulWidget with hover animation + fixed text gap
class _Chip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kFast);
    _scale = Tween(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) { setState(() => _hovered = true); _c.forward(); },
      onExit: (_) { setState(() => _hovered = false); _c.reverse(); },
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: kFast,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: widget.selected ? cRed : (_hovered ? cRedLight : cSurface),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.selected ? cRed : (_hovered ? cRed.withValues(alpha: 0.5) : cBorder)),
              boxShadow: widget.selected
                  ? [BoxShadow(color: cRed.withValues(alpha: 0.28), blurRadius: 8, offset: const Offset(0, 2))]
                  : (_hovered ? [BoxShadow(color: cRed.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2))] : null),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: widget.selected ? Colors.white : (_hovered ? cRed : cMuted),
                height: 1.0,  // Removes the extra font descender space gap
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? cRed;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: kFast,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c : cSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? c : cBorder, width: 1.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : cMuted)),
      ),
    );
  }
}

class _RedButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _RedButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_RedButton> createState() => _RedButtonState();
}

class _RedButtonState extends State<_RedButton> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kFast);
    _scale = Tween(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final String? cta;
  final VoidCallback? onCta;
  const _EmptyState({required this.message, this.cta, this.onCta});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: cRedLight, shape: BoxShape.circle),
            child: const Icon(Icons.inbox_rounded, color: cRed, size: 32),
          ),
          const SizedBox(height: 14),
          Text(message, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cText)),
          if (cta != null && onCta != null) ...[
            const SizedBox(height: 14),
            _RedButton(label: cta!, icon: Icons.add_rounded, onTap: onCta!),
          ],
        ],
      ),
    );
  }
}

// ─── DATA ────────────────────────────────────────────────────────────────────
enum ListingType { marketplace, lost, found }
enum LostFoundType { lost, found }
enum LostFilter { all, lost, found }

class NewListingInput {
  final ListingType type;
  final String title, description, category, condition, location;
  final double price;
  final String imageUrl;
  const NewListingInput({
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.location,
    required this.price,
    this.imageUrl = 'https://images.unsplash.com/photo-1517466787929-bc90951d0974?w=400',
  });
}

class MarketplaceItem {
  final String id, title, description, category, condition, image, seller, location;
  final double price;
  final DateTime createdAt;
  const MarketplaceItem({required this.id, required this.title, required this.price, required this.description, required this.category, required this.condition, required this.image, required this.seller, required this.createdAt, required this.location});
}

class LostFoundItem {
  final String id, title, description, category, image, poster, location, status;
  final LostFoundType type;
  final DateTime createdAt;
  const LostFoundItem({required this.id, required this.title, required this.description, required this.category, required this.type, required this.image, required this.poster, required this.createdAt, required this.location, required this.status});
}

String formatDate(DateTime d) => '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

const List<String> categories = ['All', 'Textbooks', 'Electronics', 'Furniture', 'Clothing', 'Other'];
const List<String> lostFoundCategories = ['All', 'Electronics', 'Bags', 'Keys', 'ID/Cards', 'Clothing', 'Other'];

final List<MarketplaceItem> seedMarketplace = [
  MarketplaceItem(id: '1', title: 'Chemistry Textbook – 11th Edition', price: 45, description: 'Barely used chemistry textbook. Perfect condition with no highlighting or notes.', category: 'Textbooks', condition: 'Like New', image: 'https://images.unsplash.com/photo-1589998059171-988d887df646?w=400', seller: 'Sarah M.', createdAt: DateTime(2026, 2, 10), location: 'Blanton Hall'),
  MarketplaceItem(id: '2', title: 'Mini Fridge – Perfect for Dorms', price: 80, description: 'Compact mini fridge, great for dorm rooms. Works perfectly, very quiet.', category: 'Furniture', condition: 'Good', image: 'https://images.unsplash.com/photo-1571175443880-49e1d25b2bc5?w=400', seller: 'Mike T.', createdAt: DateTime(2026, 2, 9), location: 'Freeman Hall'),
  MarketplaceItem(id: '3', title: 'Scientific Calculator TI-84', price: 60, description: 'TI-84 Plus graphing calculator. Great for math and science courses.', category: 'Electronics', condition: 'Good', image: 'https://images.unsplash.com/photo-1611367840531-628f328d9a49?w=400', seller: 'Jessica L.', createdAt: DateTime(2026, 2, 8), location: 'Student Center'),
  MarketplaceItem(id: '4', title: 'Desk Lamp with USB Port', price: 15, description: 'LED desk lamp with adjustable brightness and USB charging port.', category: 'Furniture', condition: 'Like New', image: 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=400', seller: 'Alex K.', createdAt: DateTime(2026, 2, 7), location: 'Bohn Hall'),
  MarketplaceItem(id: '5', title: 'MacBook Pro Charger', price: 30, description: 'Original Apple 61W USB-C power adapter. Compatible with MacBook Pro.', category: 'Electronics', condition: 'Good', image: 'https://images.unsplash.com/photo-1591290619762-d06df1a8a8b0?w=400', seller: 'David R.', createdAt: DateTime(2026, 2, 6), location: 'Library'),
  MarketplaceItem(id: '6', title: 'Biology Lab Coat', price: 12, description: 'White lab coat, size medium. Lightly used for one semester.', category: 'Other', condition: 'Good', image: 'https://images.unsplash.com/photo-1576671081837-49000212a370?w=400', seller: 'Emma W.', createdAt: DateTime(2026, 2, 5), location: 'Richardson Hall'),
];

final List<LostFoundItem> seedLostFound = [
  LostFoundItem(id: 'lf1', title: 'Black Backpack with Laptop', description: 'Lost black Jansport backpack containing a laptop and notebooks. Left in the library on the 3rd floor.', category: 'Bags', type: LostFoundType.lost, image: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400', poster: 'James P.', createdAt: DateTime(2026, 2, 11), location: 'Sprague Library – 3rd Floor', status: 'active'),
  LostFoundItem(id: 'lf2', title: 'Found: AirPods in Case', description: 'Found AirPods with charging case near the dining hall entrance.', category: 'Electronics', type: LostFoundType.found, image: 'https://images.unsplash.com/photo-1606841837239-c5a1a4a07af7?w=400', poster: 'Maria G.', createdAt: DateTime(2026, 2, 10), location: 'Student Center Dining Hall', status: 'active'),
  LostFoundItem(id: 'lf3', title: 'Lost Student ID Card', description: 'Lost my student ID card somewhere between Dickson Hall and the parking lot.', category: 'ID/Cards', type: LostFoundType.lost, image: 'https://images.unsplash.com/photo-1585155770958-eeb77df44de8?w=400', poster: 'Kevin S.', createdAt: DateTime(2026, 2, 9), location: 'Between Dickson Hall & Lot 60', status: 'active'),
  LostFoundItem(id: 'lf4', title: 'Found: Red Water Bottle', description: 'Hydro Flask water bottle found in the gym locker room.', category: 'Other', type: LostFoundType.found, image: 'https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=400', poster: 'Lisa M.', createdAt: DateTime(2026, 2, 9), location: 'Recreation Center', status: 'active'),
  LostFoundItem(id: 'lf5', title: 'Lost Keys with Red Keychain', description: 'Lost my keys with a distinctive red bottle opener keychain. Please contact if found!', category: 'Keys', type: LostFoundType.lost, image: 'https://images.unsplash.com/photo-1582139329536-e7284fece509?w=400', poster: 'Ryan B.', createdAt: DateTime(2026, 2, 8), location: 'University Hall', status: 'active'),
];