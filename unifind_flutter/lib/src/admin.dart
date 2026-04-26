part of '../main.dart';

// ─── ADMIN DATA MODELS ────────────────────────────────────────────────────────

enum AdminTab { dashboard, listings, lostFound, meetups, users, reports, profile }

enum UserRole { student, fac, admin, unknown }

extension UserRoleExt on UserRole {
  String get label {
    switch (this) {
      case UserRole.student: return 'Student';
      case UserRole.fac:     return 'Faculty';
      case UserRole.admin:   return 'Admin';
      case UserRole.unknown: return 'Unknown';
    }
  }

  static UserRole fromString(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'admin':   return UserRole.admin;
      case 'fac':
      case 'faculty': return UserRole.fac;
      case 'student': return UserRole.student;
      default:        return UserRole.unknown;
    }
  }
}

enum DenialReason {
  na,
  inappropriateContent,
  prohibitedItem,
  insufficientDescription,
  incompleteListing,
  personalInfoInListing,
  unreasonablePricing,
}

extension DenialReasonLabel on DenialReason {
  String get label {
    switch (this) {
      case DenialReason.na:                      return 'N/A';
      case DenialReason.inappropriateContent:    return 'Inappropriate Content';
      case DenialReason.prohibitedItem:          return 'Prohibited Item';
      case DenialReason.insufficientDescription: return 'Insufficient Description';
      case DenialReason.incompleteListing:       return 'Incomplete Listing';
      case DenialReason.personalInfoInListing:   return 'Personal Info in Listing';
      case DenialReason.unreasonablePricing:     return 'Unreasonable Pricing';
    }
  }
}

enum ReportReason { inappropriate, scamming, spam, harassment, fakeItem, other }

extension ReportReasonLabel on ReportReason {
  String get label {
    switch (this) {
      case ReportReason.inappropriate: return 'Inappropriate Content';
      case ReportReason.scamming:      return 'Scamming / Fraud';
      case ReportReason.spam:          return 'Spam / Duplicate';
      case ReportReason.harassment:    return 'Harassment';
      case ReportReason.fakeItem:      return 'Fake / Misleading Item';
      case ReportReason.other:         return 'Other';
    }
  }
}

// ─── DATA CLASSES ─────────────────────────────────────────────────────────────

class PendingListing {
  final String id, title, description, category, condition, location, image;
  final String sellerEmail, sellerUsername;
  final double price;
  final DateTime submittedAt;
  final bool isLostFound;
  final String type;

  const PendingListing({
    required this.id, required this.title, required this.description,
    required this.category, required this.condition, required this.location,
    required this.price, required this.image,
    required this.sellerEmail, required this.sellerUsername,
    required this.submittedAt, required this.isLostFound, required this.type,
  });
}

class AdminUser {
  final int id;
  final String email, username, displayName;
  final UserRole role;
  final bool isBanned, isVerified, hasWarning;
  final DateTime registeredAt;
  final DateTime? lastActive, warnedAt;
  final int listingCount;

  const AdminUser({
    required this.id, required this.email, required this.username,
    required this.displayName, required this.role,
    required this.isBanned, required this.isVerified,
    required this.hasWarning,
    required this.registeredAt, this.lastActive, this.warnedAt,
    required this.listingCount,
  });
}

class AdminReport {
  final String id, reporterEmail, targetId, targetType, targetTitle, notes;
  final ReportReason reason;
  final DateTime reportedAt;
  final bool isResolved;

  const AdminReport({
    required this.id, required this.reporterEmail, required this.targetId,
    required this.targetType, required this.targetTitle, required this.reason,
    required this.notes, required this.reportedAt, required this.isResolved,
  });
}

class AdminStats {
  final int totalActiveListings, pendingApprovals, newUsersThisWeek, openReports;
  final List<ActivityEntry> recentActivity;

  const AdminStats({
    required this.totalActiveListings, required this.pendingApprovals,
    required this.newUsersThisWeek, required this.openReports,
    required this.recentActivity,
  });
}

class ActivityEntry {
  final String description, type;
  final DateTime timestamp;
  const ActivityEntry({required this.description, required this.timestamp, required this.type});
}

class AdminLostFoundItem {
  final String id, title, description, category, type, status, image;
  final String posterEmail, posterUsername, location;
  final DateTime createdAt;
  final List<ClaimSummary> claims;
  final List<MatchSummary> matches;

  const AdminLostFoundItem({
    required this.id, required this.title, required this.description,
    required this.category, required this.type, required this.status,
    required this.image, required this.posterEmail, required this.posterUsername,
    required this.createdAt, required this.location,
    required this.claims, required this.matches,
  });
}

class ClaimSummary {
  final String id, claimantEmail, proofDetails, status;
  final DateTime submittedAt;
  const ClaimSummary({required this.id, required this.claimantEmail, required this.proofDetails, required this.status, required this.submittedAt});
}

class MatchSummary {
  final String id, submitterEmail, matchDetails, foundLocation, status;
  final DateTime submittedAt;
  const MatchSummary({required this.id, required this.submitterEmail, required this.matchDetails, required this.foundLocation, required this.status, required this.submittedAt});
}

class MatchedPair {
  final String matchId, status;
  final DateTime createdAt;
  final AdminLostFoundItem lostItem;
  final AdminLostFoundItem foundItem;
  const MatchedPair({
    required this.matchId, required this.status, required this.createdAt,
    required this.lostItem, required this.foundItem,
  });
}

class BugReport {
  final int id, userId;
  final String email, category, description, steps;
  final DateTime createdAt;

  const BugReport({
    required this.id, required this.userId,
    required this.email, required this.category,
    required this.description, required this.steps,
    required this.createdAt,
  });
}

class AdminMeetup {
  final int meetupId, buyerId, sellerId;
  final String buyerUsername, buyerEmail, sellerUsername, sellerEmail;
  final String location, status, itemTitle, meetupTime;
  final DateTime meetupDate, createdAt;
  final String? buyerPhotoUrl, sellerPhotoUrl;
  final String? itemImage, itemCategory;
  final double? itemPrice;
  final bool isMarketplace;

  const AdminMeetup({
    required this.meetupId, required this.buyerId, required this.sellerId,
    required this.buyerUsername, required this.buyerEmail,
    required this.sellerUsername, required this.sellerEmail,
    required this.location, required this.status, required this.itemTitle,
    required this.meetupTime, required this.meetupDate, required this.createdAt,
    this.buyerPhotoUrl, this.sellerPhotoUrl,
    this.itemImage, this.itemCategory, this.itemPrice,
    this.isMarketplace = false,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// AUTH WRAPPER
// ═════════════════════════════════════════════════════════════════════════════

class RoleAuthWrapper extends StatelessWidget {
  final UserRole role;
  final String email, username;
  final int? userId;
  final int unreadCount;
  final int unseenOfferCount;
  final VoidCallback onLogout;
  final List<MarketplaceItem> market;
  final List<LostFoundItem> lostFound;
  final int tab, postFormNonce;
  final int offersNonce;
  final ListingType postDefaultType;
  final Set<String> submittedClaimItemIds, submittedMatchItemIds;
  final void Function([ListingType]) goToPostTab;
  final Future<void> Function(NewListingInput) addListing;
  final Future<void> Function(LostFoundItem, ClaimEvidence) claimLostItem;
  final Future<void> Function(LostFoundItem, FoundMatchInput) postFoundMatch;
  final Future<void> Function(MarketplaceItem, MarketplaceUpdateInput) editMarketplace;
  final Future<void> Function(LostFoundItem, LostFoundUpdateInput) editLostFound;
  final Future<void> Function(MarketplaceItem) deleteMarketplace;
  final Future<void> Function(LostFoundItem) deleteLostFound;
  final void Function(int) onTabChanged;

  const RoleAuthWrapper({
    super.key,
    required this.role, required this.email, required this.username,
    required this.userId, this.unreadCount = 0, this.unseenOfferCount = 0,
    required this.onLogout,
    required this.market, required this.lostFound,
    required this.tab, required this.postFormNonce,
    this.offersNonce = 0,
    required this.postDefaultType,
    required this.submittedClaimItemIds, required this.submittedMatchItemIds,
    required this.goToPostTab, required this.addListing,
    required this.claimLostItem, required this.postFoundMatch,
    required this.editMarketplace, required this.editLostFound,
    required this.deleteMarketplace, required this.deleteLostFound,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (role == UserRole.admin) {
      return AdminApp(adminEmail: email, adminUsername: username, onLogout: onLogout);
    }
    return _StandardUserShell(
      email: email, username: username, userId: userId, role: role,
      unreadCount: unreadCount,
      unseenOfferCount: unseenOfferCount,
      onLogout: onLogout, market: market, lostFound: lostFound,
      tab: tab, postFormNonce: postFormNonce, postDefaultType: postDefaultType,
      offersNonce: offersNonce,
      submittedClaimItemIds: submittedClaimItemIds, submittedMatchItemIds: submittedMatchItemIds,
      goToPostTab: goToPostTab, addListing: addListing,
      claimLostItem: claimLostItem, postFoundMatch: postFoundMatch,
      editMarketplace: editMarketplace, editLostFound: editLostFound,
      deleteMarketplace: deleteMarketplace, deleteLostFound: deleteLostFound,
      onTabChanged: onTabChanged,
    );
  }
}

class _StandardUserShell extends StatelessWidget {
  final String email, username;
  final int? userId;
  final UserRole role;
  final int unreadCount;
  final int unseenOfferCount;
  final VoidCallback onLogout;
  final List<MarketplaceItem> market;
  final List<LostFoundItem> lostFound;
  final int tab, postFormNonce;
  final int offersNonce;
  final ListingType postDefaultType;
  final Set<String> submittedClaimItemIds, submittedMatchItemIds;
  final void Function([ListingType]) goToPostTab;
  final Future<void> Function(NewListingInput) addListing;
  final Future<void> Function(LostFoundItem, ClaimEvidence) claimLostItem;
  final Future<void> Function(LostFoundItem, FoundMatchInput) postFoundMatch;
  final Future<void> Function(MarketplaceItem, MarketplaceUpdateInput) editMarketplace;
  final Future<void> Function(LostFoundItem, LostFoundUpdateInput) editLostFound;
  final Future<void> Function(MarketplaceItem) deleteMarketplace;
  final Future<void> Function(LostFoundItem) deleteLostFound;
  final void Function(int) onTabChanged;

  const _StandardUserShell({
    required this.email, required this.username, required this.userId,
    required this.role, this.unreadCount = 0, this.unseenOfferCount = 0,
    required this.onLogout,
    required this.market, required this.lostFound,
    required this.tab, required this.postFormNonce,
    this.offersNonce = 0,
    required this.postDefaultType,
    required this.submittedClaimItemIds, required this.submittedMatchItemIds,
    required this.goToPostTab, required this.addListing,
    required this.claimLostItem, required this.postFoundMatch,
    required this.editMarketplace, required this.editLostFound,
    required this.deleteMarketplace, required this.deleteLostFound,
    required this.onTabChanged,
  });

  bool _isMyMarketplaceItem(MarketplaceItem item) {
    if (userId != null && item.sellerId != null) return item.sellerId == userId;
    return item.sellerEmail == email.trim().toLowerCase();
  }

  bool _isMyLostFoundItem(LostFoundItem item) {
    if (userId != null && item.posterId != null) return item.posterId == userId;
    return item.posterEmail == email.trim().toLowerCase();
  }

  static const List<_TopNavItem> _studentNavItems = [
    _TopNavItem(icon: Icons.storefront_outlined,    activeIcon: Icons.storefront_rounded,      label: 'Market',      tabIndex: 0),
    _TopNavItem(icon: Icons.search_outlined,         activeIcon: Icons.search_rounded,          label: 'Lost & Found',tabIndex: 1),
    _TopNavItem(icon: Icons.list_alt_outlined,       activeIcon: Icons.list_alt_rounded,        label: 'My Listings', tabIndex: 3),
    _TopNavItem(icon: Icons.chat_bubble_outline,     activeIcon: Icons.chat_bubble_rounded,     label: 'Messages',    tabIndex: 4),
    _TopNavItem(icon: Icons.local_offer_outlined,    activeIcon: Icons.local_offer_rounded,     label: 'Offers',      tabIndex: 6),
    _TopNavItem(icon: Icons.person_outline_rounded,  activeIcon: Icons.person_rounded,          label: 'Profile',     tabIndex: 5),
  ];

  static const List<_TopNavItem> _facultyNavItems = [
    _TopNavItem(icon: Icons.search_outlined,         activeIcon: Icons.search_rounded,          label: 'Lost & Found',tabIndex: 1),
    _TopNavItem(icon: Icons.list_alt_outlined,       activeIcon: Icons.list_alt_rounded,        label: 'My Listings', tabIndex: 3),
    _TopNavItem(icon: Icons.add_circle_outline,     activeIcon: Icons.add_circle_rounded,     label: 'Post',         tabIndex: 2),
    _TopNavItem(icon: Icons.chat_bubble_outline,     activeIcon: Icons.chat_bubble_rounded,     label: 'Messages',    tabIndex: 4),
    _TopNavItem(icon: Icons.person_outline_rounded,  activeIcon: Icons.person_rounded,          label: 'Profile',     tabIndex: 5),
  ];

  List<_TopNavItem> get _navItems => role == UserRole.fac ? _facultyNavItems : _studentNavItems;

  int _navIndexForTab(int tabIndex) {
    final items = _navItems;
    for (int i = 0; i < items.length; i++) {
      if (items[i].tabIndex == tabIndex) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final activeNavIndex = _navIndexForTab(tab);

    final screens = [
      MarketplaceScreen(items: market, onListItem: () => goToPostTab(), currentUserEmail: email, currentUserId: userId),
      LostFoundScreen(
        items: lostFound,
        onCreateLost: () => goToPostTab(ListingType.lost),
        onCreateFound: () => goToPostTab(ListingType.found),
        onClaimLost: claimLostItem,
        onPostFoundMatch: postFoundMatch,
        submittedClaimItemIds: submittedClaimItemIds,
        submittedMatchItemIds: submittedMatchItemIds,
        currentUserEmail: email,
        currentUserId: userId,
      ),
      PostListingScreen(key: ValueKey(postFormNonce), onPost: addListing, initialType: postDefaultType, hideSale: role == UserRole.fac),
        MyListingsScreen(
          marketplaceItems: market.where(_isMyMarketplaceItem).toList(),
          lostFoundItems: lostFound.where(_isMyLostFoundItem).toList(),
          onListItem: () => goToPostTab(ListingType.lost),
          onEditMarketplace: editMarketplace,
          onEditLostFound: editLostFound,
          onDeleteMarketplace: deleteMarketplace,
          onDeleteLostFound: deleteLostFound,
          lostFoundOnly: role == UserRole.fac,
        ),
      MessagingScreen(userId: userId ?? 0, userEmail: email),
      ProfileScreen(email: email, username: username, onLogout: onLogout, userId: userId, role: role),
      userId != null
          ? OffersScreen(key: ValueKey('offers-$offersNonce'), userId: userId!)
          : const Center(child: Text('Sign in to view offers.')),
    ];

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: cBg,
      appBar: isMobile
          ? AppBar(
              backgroundColor: cNavBg, foregroundColor: Colors.white, elevation: 0, centerTitle: true,
              title: Column(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('assets/images/whitelogo.png', height: 36, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text('UniFind', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white))),
                if (role == UserRole.fac) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(5)),
                    child: Text(
                      role == UserRole.fac ? 'FACULTY' : 'STUDENT',
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8),
                    ),
                  ),
                ],
              ]),
              actions: [IconButton(tooltip: 'Log out', icon: const Icon(Icons.logout_rounded, size: 18), onPressed: onLogout)],
            )
          : PreferredSize(
              preferredSize: const Size.fromHeight(90),
              child: Container(
                color: cNavBg,
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: 90,
                    child:Stack(children: [
                    // Logo pinned to the left
                   Positioned(left: 12, top: 0, bottom: 0, child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Image.asset('assets/images/whitelogo.png', height: 42, fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Text('UniFind',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white))),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(5)),
                          child: Text(
                            role == UserRole.fac ? 'FACULTY' : 'STUDENT',
                            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8),
                          ),
                        ),
                      ]),
                    )),
                    // Nav tabs stay centered
                    Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(height: 4),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        for (int i = 0; i < _navItems.length; i++) ...[
                          _TopNavTab(
                            item: _navItems[i],
                            isActive: activeNavIndex == i,
                            onTap: () => onTabChanged(_navItems[i].tabIndex),
                            badgeCount: _navItems[i].tabIndex == 4
                                ? unreadCount
                                : _navItems[i].tabIndex == 6
                                    ? unseenOfferCount
                                    : 0,
                          ),
                          if (role != UserRole.fac && i == 2) ...[const SizedBox(width: 6), _NavPostButton(onTap: () => goToPostTab()), const SizedBox(width: 6)],
                        ],
                      ]),
                    ])),
                    // Logout stays on the right
                    Positioned(top: 0, right: 8, bottom: 0, child: Center(
                      child: IconButton(tooltip: 'Log out', icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white), onPressed: onLogout),
                    )),
                  ]),
                  ),
                ),
              ),
            ),
     body: IndexedStack(index: tab, children: screens),
      bottomNavigationBar: isMobile
          ? Theme(
              data: Theme.of(context).copyWith(
                navigationBarTheme: NavigationBarThemeData(
                  labelTextStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              child: role == UserRole.fac
                ? NavigationBar(
                  selectedIndex: tab == 1 ? 0 : tab == 2 ? 1 : tab == 3 ? 2 : tab == 4 ? 3 : 4,
                  backgroundColor: cNavBg,
                  indicatorColor: Colors.white.withValues(alpha: 0.2),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: (i) {
                    if (i == 1) { goToPostTab(ListingType.lost); return; }
                    onTabChanged(i == 0 ? 1 : i == 2 ? 3 : i == 3 ? 4 : 5);
                  },
                  destinations: [
                    const NavigationDestination(icon: Icon(Icons.search_outlined, color: Colors.white70), selectedIcon: Icon(Icons.search_rounded, color: Colors.white), label: 'Lost/Found'),
                    const NavigationDestination(icon: Icon(Icons.add_circle_outline, color: Colors.white70), selectedIcon: Icon(Icons.add_circle_rounded, color: Colors.white), label: 'Post'),
                    const NavigationDestination(icon: Icon(Icons.list_alt_outlined, color: Colors.white70), selectedIcon: Icon(Icons.list_alt_rounded, color: Colors.white), label: 'Listings'),
                    NavigationDestination(icon: Badge(isLabelVisible: unreadCount > 0, label: Text('$unreadCount', style: const TextStyle(fontSize: 9)), child: const Icon(Icons.chat_bubble_outline, color: Colors.white70)), selectedIcon: Badge(isLabelVisible: unreadCount > 0, label: Text('$unreadCount', style: const TextStyle(fontSize: 9)), child: const Icon(Icons.chat_bubble_rounded, color: Colors.white)), label: 'Messages'),
                    const NavigationDestination(icon: Icon(Icons.person_outline_rounded, color: Colors.white70), selectedIcon: Icon(Icons.person_rounded, color: Colors.white), label: 'Profile'),
                  ],
                )
              : NavigationBar(
                  selectedIndex: tab == 6 ? 5 : tab == 5 ? 6 : tab,
                  backgroundColor: cNavBg,
                  indicatorColor: Colors.white.withValues(alpha: 0.2),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: (i) {
                    if (i == 2) { goToPostTab(); return; }
                    onTabChanged(i == 5 ? 6 : i == 6 ? 5 : i);
                  },                  destinations: [
                    const NavigationDestination(icon: Icon(Icons.storefront_outlined, color: Colors.white70), selectedIcon: Icon(Icons.storefront_rounded, color: Colors.white), label: 'Market'),
                    const NavigationDestination(icon: Icon(Icons.search_outlined, color: Colors.white70), selectedIcon: Icon(Icons.search_rounded, color: Colors.white), label: 'Lost/Found'),
                    const NavigationDestination(icon: Icon(Icons.add_circle_outline, color: Colors.white70), selectedIcon: Icon(Icons.add_circle_rounded, color: Colors.white), label: 'Post'),
                    const NavigationDestination(icon: Icon(Icons.inventory_2_outlined, color: Colors.white70), selectedIcon: Icon(Icons.inventory_2_rounded, color: Colors.white), label: 'Listings'),
                    NavigationDestination(icon: Badge(isLabelVisible: unreadCount > 0, label: Text('$unreadCount', style: const TextStyle(fontSize: 9)), child: const Icon(Icons.chat_bubble_outline, color: Colors.white70)), selectedIcon: Badge(isLabelVisible: unreadCount > 0, label: Text('$unreadCount', style: const TextStyle(fontSize: 9)), child: const Icon(Icons.chat_bubble_rounded, color: Colors.white)), label: 'Messages'),
                    NavigationDestination(icon: Badge(isLabelVisible: unseenOfferCount > 0, label: Text('$unseenOfferCount', style: const TextStyle(fontSize: 9)), child: const Icon(Icons.local_offer_outlined, color: Colors.white70)), selectedIcon: Badge(isLabelVisible: unseenOfferCount > 0, label: Text('$unseenOfferCount', style: const TextStyle(fontSize: 9)), child: const Icon(Icons.local_offer_rounded, color: Colors.white)), label: 'Offers'),
                    const NavigationDestination(icon: Icon(Icons.person_outline_rounded, color: Colors.white70), selectedIcon: Icon(Icons.person_rounded, color: Colors.white), label: 'Profile'),
                  ],
                ))
          : null,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ADMIN APP ROOT
// ═════════════════════════════════════════════════════════════════════════════

class AdminApp extends StatefulWidget {
  final String adminEmail, adminUsername;
  final VoidCallback onLogout;
  const AdminApp({super.key, required this.adminEmail, required this.adminUsername, required this.onLogout});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  AdminTab _tab = AdminTab.dashboard;
  bool _loading = true;
  bool _listingInitialShowActive = false;

  AdminStats _stats = const AdminStats(totalActiveListings: 0, pendingApprovals: 0, newUsersThisWeek: 0, openReports: 0, recentActivity: []);
  final List<PendingListing>     _pending  = [];
  final List<PendingListing>     _active   = [];
  final List<AdminUser>          _users    = [];
  final List<AdminReport>        _reports  = [];
  final List<AdminLostFoundItem> _lf       = [];
  final List<MatchedPair>        _matches  = [];
  final List<AdminMeetup>         _meetups  = [];
  final List<BugReport>           _bugReports = [];

  @override
  void initState() { super.initState(); _loadAll(); }

  String _s(dynamic v) => v?.toString() ?? '';
  DateTime _d(dynamic v) => DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();

  AdminLostFoundItem _parseLFSide(Map<String, dynamic> s) => AdminLostFoundItem(
    id: _s(s['id']), title: _s(s['title']), description: _s(s['description']),
    category: _s(s['category']), type: _s(s['type']),
    status: _s(s['status']).isEmpty ? 'matched' : _s(s['status']),
    image: _s(s['image']).isEmpty ? _s(s['image_url']) : _s(s['image']),
    posterEmail: _s(s['poster_email']), posterUsername: _s(s['poster_username']).isEmpty ? 'Student' : _s(s['poster_username']),
    createdAt: _d(s['created_at']), location: _s(s['location']),
    claims: const [], matches: const [],
  );

  List<MatchedPair> _parseMatches(List<Map<String, dynamic>> raw) => raw.map((m) {
    final l = (m['lost_item'] is Map) ? Map<String, dynamic>.from(m['lost_item'] as Map) : <String, dynamic>{};
    final f = (m['found_item'] is Map) ? Map<String, dynamic>.from(m['found_item'] as Map) : <String, dynamic>{};
    return MatchedPair(
      matchId: _s(m['match_id'] ?? m['id']),
      status: _s(m['status']),
      createdAt: _d(m['created_at']),
      lostItem: _parseLFSide(l),
      foundItem: _parseLFSide(f),
    );
  }).toList();

  Future<List<BugReport>> _fetchBugReports() async {
    final res = await http.get(Uri.parse('http://cyan.csam.montclair.edu/~ivanovs1/UniFind_API/admin/reports/get_bug_reports.php'));
    final data = jsonDecode(res.body);
    if (data['success'] != true) return [];
    return (data['data'] as List).map((b) => BugReport(
      id:          int.tryParse(b['id']?.toString() ?? '') ?? 0,
      userId:      int.tryParse(b['user_id']?.toString() ?? '') ?? 0,
      email:       b['email']?.toString() ?? '',
      category:    b['category']?.toString() ?? '',
      description: b['description']?.toString() ?? '',
      steps:       b['steps']?.toString() ?? '',
      createdAt:   DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.now(),
    )).toList();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final r = await Future.wait([
        getAdminStats(), getAdminPendingListings(), getAdminActiveListings(),
        getAdminUsers(), getAdminReports(),
        getAdminLostFoundItems().catchError((_) => <Map<String, dynamic>>[]),
        adminGetMatches().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      final rawStats   = r[0] as Map<String, dynamic>;
      final rawPending = r[1] as List<Map<String, dynamic>>;
      final rawActive  = r[2] as List<Map<String, dynamic>>;
      final rawUsers   = r[3] as List<Map<String, dynamic>>;
      final rawReports = r[4] as List<Map<String, dynamic>>;
      final rawLF      = r[5] as List<Map<String, dynamic>>;
      final rawMatches = r[6] as List<Map<String, dynamic>>;

      final activity = (rawStats['recent_activity'] as List? ?? [])
          .map((a) => ActivityEntry(
            description: _s(a['description']),
            timestamp: _d(a['timestamp']),
            type: _s(a['type']).isEmpty ? 'listing' : _s(a['type']),
          )).toList();

      final pending = rawPending.map((p) {
        final rawType = _s(p['type']);
        final isLF = p['is_lost_found'] == true || p['is_lost_found'] == 1 ||
            rawType == 'lost' || rawType == 'found';
        return PendingListing(
          id: _s(p['id']), title: _s(p['title']), description: _s(p['description']),
          category: _s(p['category']),
          condition: _s(p['condition']).isEmpty || _s(p['condition']) == 'N/A' ? 'Good' : _s(p['condition']),
          location: _s(p['location']),
          price: double.tryParse(_s(p['price'])) ?? 0,
          image: _s(p['image']).isEmpty ? _s(p['image_url']) : _s(p['image']),
          sellerEmail: _s(p['seller_email']),
          sellerUsername: _s(p['seller_username']).isEmpty ? 'Student' : _s(p['seller_username']),
          submittedAt: _d(p['created_at']),
          isLostFound: isLF,
          type: rawType.isEmpty ? 'marketplace' : rawType,
        );
      }).toList();

      final active = rawActive.map((p) => PendingListing(
        id: _s(p['id']), title: _s(p['title']), description: _s(p['description']),
        category: _s(p['category']), condition: _s(p['condition']).isEmpty ? 'Good' : _s(p['condition']),
        location: _s(p['location']), price: double.tryParse(_s(p['price'])) ?? 0,
        image: _s(p['image']).isEmpty ? _s(p['image_url']) : _s(p['image']),
        sellerEmail: _s(p['seller_email']),
        sellerUsername: _s(p['seller_username']).isEmpty ? 'Student' : _s(p['seller_username']),
        submittedAt: _d(p['created_at']), isLostFound: false, type: 'marketplace',
      )).toList();

      final users = rawUsers.map((u) => AdminUser(
        id: int.tryParse(_s(u['id'])) ?? 0, email: _s(u['email']),
        username: _s(u['username']),
        displayName: _s(u['display_name']).isEmpty ? _s(u['username']) : _s(u['display_name']),
        role: UserRoleExt.fromString(_s(u['role'])),
        isBanned: u['is_banned'] == true || u['is_banned'] == 1,
        isVerified: u['is_verified'] == true || u['is_verified'] == 1,
        hasWarning: u['has_warning'] == true || u['has_warning'] == 1,
        registeredAt: _d(u['created_at']),
        lastActive: DateTime.tryParse(_s(u['last_active'])),
        warnedAt: DateTime.tryParse(_s(u['warned_at'])),
        listingCount: int.tryParse(_s(u['listing_count'])) ?? 0,
      )).toList();

      final rMap = {
        'inappropriate': ReportReason.inappropriate, 'scamming': ReportReason.scamming,
        'spam': ReportReason.spam, 'harassment': ReportReason.harassment,
        'fake_item': ReportReason.fakeItem, 'other': ReportReason.other,
      };
      final reports = rawReports.map((r) => AdminReport(
        id: _s(r['id']), reporterEmail: _s(r['reporter_email']), targetId: _s(r['target_id']),
        targetType: _s(r['target_type']).isEmpty ? 'listing' : _s(r['target_type']),
        targetTitle: _s(r['target_title']),
        reason: rMap[_s(r['reason'])] ?? ReportReason.other,
        notes: _s(r['notes']), reportedAt: _d(r['created_at']),
        isResolved: r['is_resolved'] == true || r['is_resolved'] == 1,
      )).toList();

      final lfItems = rawLF.map((l) {
        final claims = (l['claims'] as List? ?? []).map((c) => ClaimSummary(
          id: _s(c['id']), claimantEmail: _s(c['claimant_email']),
          proofDetails: _s(c['proof_details']), status: _s(c['status']),
          submittedAt: _d(c['created_at']),
        )).toList();
        final matches = (l['matches'] as List? ?? []).map((m) => MatchSummary(
          id: _s(m['id']), submitterEmail: _s(m['submitter_email']),
          matchDetails: _s(m['match_details']), foundLocation: _s(m['found_location']),
          status: _s(m['status']), submittedAt: _d(m['created_at']),
        )).toList();
        return AdminLostFoundItem(
          id: _s(l['id']), title: _s(l['title']), description: _s(l['description']),
          category: _s(l['category']), type: _s(l['type']),
          status: _s(l['status']).isEmpty ? 'active' : _s(l['status']),
          image: _s(l['image']).isEmpty ? _s(l['image_url']) : _s(l['image']),
          posterEmail: _s(l['poster_email']),
          posterUsername: _s(l['poster_username']).isEmpty ? 'Student' : _s(l['poster_username']),
          createdAt: _d(l['created_at']), location: _s(l['location']),
          claims: claims, matches: matches,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _stats = AdminStats(
          totalActiveListings: int.tryParse(_s(rawStats['total_active_listings'])) ?? 0,
          pendingApprovals: pending.length,
          newUsersThisWeek: int.tryParse(_s(rawStats['new_users_this_week'])) ?? 0,
          openReports: reports.where((r) => !r.isResolved).length,
          recentActivity: activity,
        );
        _pending..clear()..addAll(pending);
        _active..clear()..addAll(active);
        _users..clear()..addAll(users);
        _reports..clear()..addAll(reports);
        _lf..clear()..addAll(lfItems);
        try {
          _matches..clear()..addAll(_parseMatches(rawMatches));
        } catch (e) {
          debugPrint('_parseMatches error: $e');
          _matches.clear();
        }
        _loading = false;
      });
      // Load bug reports
      try {
        final rawBugs = await _fetchBugReports();
        if (mounted) setState(() => _bugReports..clear()..addAll(rawBugs));
      } catch (_) {}

      // Load meetups (admin_pending + completion_pending)
      try {
        final pending    = await getAdminMeetups(status: 'admin_pending');
        final completing = await getAdminMeetups(status: 'completion_pending');
        print('Raw pending meetups: $pending');
        print('Raw completing meetups: $completing');
        final rawMeetups = [...pending, ...completing];
        if (!mounted) return;
        final meetups = rawMeetups.map((m) => AdminMeetup(
          meetupId:       int.tryParse(_s(m['meetup_id'])) ?? 0,
          buyerId:        int.tryParse(_s(m['buyer_id'])) ?? 0,
          sellerId:       int.tryParse(_s(m['seller_id'])) ?? 0,
          buyerUsername:  _s(m['buyer_username']).isEmpty ? 'Unknown' : _s(m['buyer_username']),
          buyerEmail:     _s(m['buyer_email']),
          sellerUsername: _s(m['seller_username']).isEmpty ? 'Unknown' : _s(m['seller_username']),
          sellerEmail:    _s(m['seller_email']),
          location:       _s(m['location']),
          status:         _s(m['status']),
          itemTitle:      _s(m['item_title']).isEmpty ? 'Meetup' : _s(m['item_title']),
          meetupTime:     _s(m['meetup_time']),
          meetupDate:     _d(m['meetup_date']),
          createdAt:      _d(m['created_at']),
          buyerPhotoUrl:  m['buyer_photo_url']?.toString(),
          sellerPhotoUrl: m['seller_photo_url']?.toString(),
          itemImage:      m['item_image']?.toString(),
          itemCategory:   m['item_category']?.toString(),
          itemPrice:      m['item_price'] != null ? double.tryParse(m['item_price'].toString()) : null,
          isMarketplace:  m['is_marketplace']?.toString() == '1',
        )).toList();
        if (mounted) setState(() => _meetups..clear()..addAll(meetups));
      } catch (e, stack) { 
        debugPrint('Meetups error: $e\n$stack'); 
      }
    } catch (e, stack) { 
      debugPrint('_loadAll outer error: $e\n$stack');
      if (mounted) setState(() => _loading = false); 
    }
  }

  int get _openReports => _reports.where((r) => !r.isResolved).length;

  NavigationDestination _dest(IconData icon, String label, {String? badge}) {
    Widget w = Icon(icon, color: Colors.white70);
    Widget s = Icon(icon, color: Colors.white);
    if (badge != null) {
      w = Badge(label: Text(badge, style: const TextStyle(fontSize: 10)), child: w);
      s = Badge(label: Text(badge, style: const TextStyle(fontSize: 10)), child: s);
    }
    return NavigationDestination(icon: w, selectedIcon: s, label: label);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0F0),
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: cNavBgDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 6),
          Image.asset(
            'assets/images/whitelogo.png',
            height: 36,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Text(
              'UniFind',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          const SizedBox (height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8),
            ),
          ),
          const SizedBox(height: 6),
        ]),
        actions: [
          IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh_rounded), onPressed: _loadAll),
          IconButton(tooltip: 'Log out', icon: const Icon(Icons.logout_rounded), onPressed: widget.onLogout),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: cRed))
          : IndexedStack(index: _tab.index, children: [
              _AdminDashboard(
                stats: _stats,
                onNavigate: (t, {bool showActive = false}) {
                  setState(() { _listingInitialShowActive = showActive; _tab = t; });
                },
              ),
              _AdminListingsPanel(
                key: ValueKey('listings_$_listingInitialShowActive'),
                pendingListings: _pending, activeListings: _active,
                onRefresh: _loadAll, initialShowActive: _listingInitialShowActive,
              ),
              _AdminLostFoundPanel(
                items: _lf,
                lostItems: _lf.where((i) => i.type == 'lost' && i.status == 'active').toList(),
                foundItems: _lf.where((i) => i.type == 'found' && i.status == 'active').toList(),
                matchedPairs: _matches,
                onRefresh: _loadAll,
              ),
              _AdminMeetupsPanel(meetups: _meetups, onRefresh: _loadAll),
              _AdminUsersPanel(users: _users, onRefresh: _loadAll),
              _AdminReportsPanel(reports: _reports, bugReports: _bugReports, users: _users, allListings: [..._pending, ..._active], allLFItems: _lf, onRefresh: _loadAll),
              _AdminProfileTab(
                adminEmail: widget.adminEmail,
                adminUsername: widget.adminUsername,
                onLogout: widget.onLogout,
              ),
            ]),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _tab.index,
          backgroundColor: cNavBgDark,
          indicatorColor: Colors.white.withValues(alpha: 0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) => setState(() => _tab = AdminTab.values[i]),
          destinations: [
            _dest(Icons.dashboard_rounded, 'Dashboard'),
            _dest(Icons.storefront_outlined, 'Listings', badge: _stats.pendingApprovals > 0 ? '${_stats.pendingApprovals}' : null),
            _dest(Icons.search_rounded, 'Lost/Found'),
            _dest(Icons.handshake_outlined, 'Meetups', badge: _meetups.isNotEmpty ? '${_meetups.length}' : null),
            _dest(Icons.people_outline_rounded, 'Users'),
            _dest(Icons.flag_outlined, 'Reports', badge: _openReports > 0 ? '$_openReports' : null),
            _dest(Icons.person_outline_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DASHBOARD
// ═════════════════════════════════════════════════════════════════════════════

class _AdminDashboard extends StatelessWidget {
  final AdminStats stats;
  final void Function(AdminTab, {bool showActive}) onNavigate;
  const _AdminDashboard({required this.stats, required this.onNavigate});

  String _todayLabel() {
    final n = DateTime.now();
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[n.month - 1]} ${n.day}, ${n.year}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity, padding: EdgeInsets.fromLTRB(16, 14, isMobile ? 16 : 24, 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [cNavBg, cNavBgDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Admin Dashboard', style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('UniFind · ${_todayLabel()}', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.65))),
              ])),
              if (!isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(color: const Color(0xFF4ADE80), shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFF4ADE80).withValues(alpha: 0.4), blurRadius: 6)])),
                    const SizedBox(width: 7),
                    const Text('System Online', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          const Text('   OVERVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: cMuted, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          if (isMobile) ...[
            Row(children: [
              Expanded(child: _StatCard(label: 'Active', value: '${stats.totalActiveListings}', icon: Icons.storefront_rounded, color: cRed, onTap: () => onNavigate(AdminTab.listings, showActive: true))),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: 'Pending', value: '${stats.pendingApprovals}', icon: Icons.pending_actions_rounded, color: const Color(0xFFD97706), onTap: () => onNavigate(AdminTab.listings, showActive: false))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _StatCard(label: 'New Users', value: '${stats.newUsersThisWeek}', icon: Icons.person_add_rounded, color: const Color(0xFF1D4ED8), onTap: () => onNavigate(AdminTab.users, showActive: false))),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: 'Reports', value: '${stats.openReports}', icon: Icons.flag_rounded, color: const Color(0xFF7C3AED), onTap: () => onNavigate(AdminTab.reports, showActive: false))),
            ]),
          ] else
            Row(children: [
              Expanded(child: _StatCard(label: 'Active Listings', value: '${stats.totalActiveListings}', icon: Icons.storefront_rounded, color: cRed, onTap: () => onNavigate(AdminTab.listings, showActive: true))),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'Pending Approvals', value: '${stats.pendingApprovals}', icon: Icons.pending_actions_rounded, color: const Color(0xFFD97706), onTap: () => onNavigate(AdminTab.listings, showActive: false))),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'New Users (7d)', value: '${stats.newUsersThisWeek}', icon: Icons.person_add_rounded, color: const Color(0xFF1D4ED8), onTap: () => onNavigate(AdminTab.users, showActive: false))),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'Open Reports', value: '${stats.openReports}', icon: Icons.flag_rounded, color: const Color(0xFF7C3AED), onTap: () => onNavigate(AdminTab.reports, showActive: false))),
            ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: cBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Quick Actions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cText)),
              const SizedBox(height: 12),
              _QuickAction(icon: Icons.pending_actions_rounded, iconBg: const Color.fromARGB(255, 254, 199, 199), iconColor: cRed, label: 'Pending Listings', sub: '${stats.pendingApprovals} submissions awaiting', onTap: () => onNavigate(AdminTab.listings, showActive: false)),
              _QuickAction(icon: Icons.storefront_rounded, iconBg: const Color.fromARGB(255, 254, 236, 226), iconColor: const Color(0xFFD97706), label: 'Active Listings', sub: '${stats.totalActiveListings} live posts', onTap: () => onNavigate(AdminTab.listings, showActive: true)),
              _QuickAction(icon: Icons.flag_rounded, iconBg: const Color.fromARGB(255, 254, 247, 226), iconColor: const Color.fromARGB(255, 161, 122, 39), label: 'Reports', sub: '${stats.openReports} reports need action', onTap: () => onNavigate(AdminTab.reports, showActive: false)),
              _QuickAction(icon: Icons.people_outline_rounded, iconBg: const Color.fromARGB(255, 219, 254, 221), iconColor: const Color(0xFF16A34A), label: 'Users', sub: 'View, warn, or ban accounts', onTap: () => onNavigate(AdminTab.users, showActive: false)),
              _QuickAction(icon: Icons.search_rounded, iconBg: const Color.fromARGB(255, 209, 227, 250), iconColor: const Color.fromARGB(255, 22, 83, 163), label: 'Lost & Found', sub: 'Review claims and matches', onTap: () => onNavigate(AdminTab.lostFound, showActive: false)),
              _QuickAction(icon: Icons.handshake_outlined, iconBg: const Color.fromARGB(255, 254, 243, 199), iconColor: const Color(0xFF7B5800), label: 'Meetups', sub: 'Approve or deny meetup proposals', onTap: () => onNavigate(AdminTab.meetups, showActive: false)),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: cBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Recent Activity', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cText)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: cBorder)),
                  child: Text('${stats.recentActivity.length} events', style: const TextStyle(fontSize: 11, color: cMuted, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 12),
              if (stats.recentActivity.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: _AdminEmptyState(message: 'No recent activity', icon: Icons.history_rounded))
              else
                ...stats.recentActivity.map((e) => _ActivityTile(entry: e)),
            ]),
          ),
        ]),
      );
    });
  }
}

class _QuickAction extends StatefulWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String label, sub;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.iconBg, required this.iconColor, required this.label, required this.sub, required this.onTap});

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hovered ? cBg : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _hovered ? cBorder.withValues(alpha: 0.6) : cBorder),
            boxShadow: _hovered ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3))] : [],
          ),
          child: Row(children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: widget.iconBg, borderRadius: BorderRadius.circular(8)), child: Icon(widget.icon, color: widget.iconColor, size: 16)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cText)),
              Text(widget.sub, style: const TextStyle(fontSize: 11, color: cMuted)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: cMuted, size: 18),
          ]),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor, borderColor, iconColor, textColor;
  final bool loading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon, required this.label,
    required this.bgColor, required this.borderColor, required this.iconColor,
    required this.textColor, required this.loading, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(children: [
          loading
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: iconColor))
              : Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor))),
          Icon(Icons.chevron_right_rounded, color: textColor.withValues(alpha: 0.4), size: 16),
        ]),
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.onTap});

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hovered ? cBg : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cBorder),
            boxShadow: [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Icon(widget.icon, color: widget.color, size: 18)),
              const SizedBox(height: 6),
              Text(widget.value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: widget.color, letterSpacing: -0.5)),
              Text(widget.label, style: const TextStyle(fontSize: 11, color: cMuted, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityEntry entry;
  const _ActivityTile({required this.entry});

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24)   return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final icons  = {'listing': Icons.storefront_rounded, 'user': Icons.person_rounded, 'report': Icons.flag_rounded, 'lostfound': Icons.search_rounded};
    final colors = {'listing': cRed, 'user': const Color(0xFF2980B9), 'report': const Color(0xFF8E44AD), 'lostfound': const Color(0xFF27AE60)};
    final icon  = icons[entry.type]  ?? Icons.circle;
    final color = colors[entry.type] ?? cMuted;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
      child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16)),
        const SizedBox(width: 12),
        Expanded(child: Text(entry.description, style: const TextStyle(fontSize: 13, color: cText))),
        Text(_timeAgo(entry.timestamp), style: const TextStyle(fontSize: 11, color: cMuted)),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LISTINGS PANEL
// ═════════════════════════════════════════════════════════════════════════════

class _AdminListingsPanel extends StatefulWidget {
  final List<PendingListing> pendingListings;
  final List<PendingListing> activeListings;
  final VoidCallback onRefresh;
  final bool initialShowActive;
  const _AdminListingsPanel({super.key, required this.pendingListings, required this.activeListings, required this.onRefresh, this.initialShowActive = false});

  @override
  State<_AdminListingsPanel> createState() => _AdminListingsPanelState();
}

class _AdminListingsPanelState extends State<_AdminListingsPanel> {
  String _filter = 'All';
  late bool _showActive;

  @override
  void initState() { super.initState(); _showActive = widget.initialShowActive; }

  Future<void> _openReview(PendingListing listing) async {
    final titleCtrl   = TextEditingController(text: listing.title);
    final descCtrl    = TextEditingController(text: listing.description);
    final priceCtrl   = TextEditingController(text: listing.price > 0 ? listing.price.toStringAsFixed(2) : '');
    final locCtrl     = TextEditingController(text: listing.location);
    final explainCtrl = TextEditingController();
    String category   = listing.category;
    String condition  = listing.condition;
    DenialReason selectedReason = DenialReason.na;
    bool notifyUser   = true;
    bool loading      = false;
    String? error;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true, barrierLabel: 'Review',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: kMid,
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) => Opacity(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut).value,
        child: StatefulBuilder(
          builder: (ctx, setS) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                          child: const Text('PENDING REVIEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFE67E22), letterSpacing: 1)),
                        ),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      ]),
                      const SizedBox(height: 10),
                      const Text('Review Listing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cText)),
                      Text('By ${listing.sellerUsername} · ${listing.sellerEmail}', style: const TextStyle(fontSize: 12, color: cMuted)),
                      const SizedBox(height: 14),
                      if (listing.image.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(listing.image, height: 150, width: double.infinity, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                        ),
                      const SizedBox(height: 14),
                      const _AdminLabel('Edit Before Approving'),
                      const SizedBox(height: 8),
                      TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                      const SizedBox(height: 8),
                      TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
                      const SizedBox(height: 8),
                      if (!listing.isLostFound) ...[
                        TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price')),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: condition, decoration: const InputDecoration(labelText: 'Condition'),
                          items: const ['New','Like New','Good','Fair'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setS(() => condition = v ?? condition),
                        ),
                        const SizedBox(height: 8),
                      ],
                      DropdownButtonFormField<String>(
                        value: category.isEmpty ? null : category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: (listing.isLostFound ? lostFoundCategories : categories).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setS(() => category = v ?? category),
                      ),
                      const SizedBox(height: 8),
                      TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Location')),
                      const SizedBox(height: 16),
                      Row(children: [
                        const _AdminLabel('Denial Reason'),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(6)),
                          child: const Text('Required to deny', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: cRed)),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<DenialReason>(
                        value: selectedReason,
                        decoration: const InputDecoration(labelText: 'Denial Reason'),
                        items: DenialReason.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label))).toList(),
                        onChanged: (v) => setS(() => selectedReason = v ?? DenialReason.na),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: explainCtrl, maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Explanation to user (optional)', hintText: 'Describe why this was denied or what was changed...'),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Checkbox(value: notifyUser, onChanged: (v) => setS(() => notifyUser = v ?? true), activeColor: cRed),
                        const Text('Notify user via email', style: TextStyle(fontSize: 13)),
                      ]),
                      if (error != null) ...[const SizedBox(height: 6), Text(error!, style: const TextStyle(color: cRedDark, fontSize: 12))],
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: loading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Deny'),
                            style: OutlinedButton.styleFrom(foregroundColor: cRedDark, side: const BorderSide(color: cRedDark), padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: loading ? null : () async {
                              setS(() { loading = true; error = null; });
                              try {
                                await adminDenyListing(listingId: listing.id, isLostFound: listing.isLostFound, reason: selectedReason.name, explanation: explainCtrl.text.trim(), notifyUser: notifyUser, userEmail: listing.sellerEmail);
                                if (ctx.mounted) Navigator.pop(ctx);
                                widget.onRefresh();
                              } catch (e) { setS(() { loading = false; error = e.toString(); }); }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: loading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: loading ? null : () async {
                              setS(() { loading = true; error = null; });
                              try {
                                await adminApproveListing(listingId: listing.id, isLostFound: listing.isLostFound, title: titleCtrl.text.trim(), description: descCtrl.text.trim(), category: category, condition: condition, location: locCtrl.text.trim(), price: double.tryParse(priceCtrl.text.trim()) ?? listing.price, notifyUser: notifyUser, userEmail: listing.sellerEmail);
                                if (ctx.mounted) Navigator.pop(ctx);
                                widget.onRefresh();
                              } catch (e) { setS(() { loading = false; error = e.toString(); }); }
                            },
                          ),
                        ),
                      ]),
                    ]),
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
    final items = _showActive
        ? widget.activeListings
        : (_filter == 'All' ? widget.pendingListings : widget.pendingListings.where((p) => p.type == _filter.toLowerCase()).toList());

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [cRed, cRedDark]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Icon(
                  _showActive ? Icons.storefront_rounded : Icons.pending_actions_rounded,
                  color: Colors.white, size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_showActive ? 'Active Listings' : 'Pending Listings', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.4)),
                  Text(_showActive ? 'All live marketplace listings' : 'Review, edit, approve or deny submissions', style: const TextStyle(fontSize: 12, color: cMuted)),
                ],
              ),
            ],
          ),
    const SizedBox(height: 10),
    Row(children: [
      _Chip(label: 'Pending', selected: !_showActive, onTap: () => setState(() => _showActive = false)),
      const SizedBox(width: 8),
      _Chip(label: 'Active', selected: _showActive, onTap: () => setState(() => _showActive = true)),
    ]),
  ]),
),
      if (!_showActive)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final f in ['All', 'Marketplace', 'Lost', 'Found'])
                Padding(padding: const EdgeInsets.only(right: 8), child: _Chip(label: f, selected: _filter == f, onTap: () => setState(() => _filter = f))),
            ]),
          ),
        ),
      Expanded(
        child: items.isEmpty
            ? _AdminEmptyState(message: _showActive ? 'No active listings' : 'No pending listings', icon: _showActive ? Icons.storefront_outlined : Icons.check_circle_outline_rounded)
            : ListView.builder(
                primary: false,
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (_, i) => _PendingListingTile(listing: items[i], onTap: () => _openReview(items[i])),
              ),
      ),
    ]);
  }
}

class _PendingListingTile extends StatelessWidget {
  final PendingListing listing;
  final VoidCallback onTap;
  const _PendingListingTile({required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final typeColor = listing.type == 'marketplace' ? cRed : listing.type == 'lost' ? const Color(0xFFE74C3C) : const Color(0xFF27AE60);
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: cBorder),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(listing.image, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: cPlaceholder, child: const Icon(Icons.image_not_supported, color: cMuted)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(listing.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cText), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7)), child: Text(listing.type.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: typeColor, letterSpacing: 0.5))),
            ]),
            const SizedBox(height: 3),
            Text(listing.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: cMuted)),
            const SizedBox(height: 5),
            Row(children: [
              const Icon(Icons.person_outline, size: 11, color: cMuted), const SizedBox(width: 3),
              Text(listing.sellerUsername, style: const TextStyle(fontSize: 11, color: cMuted)),
              if (listing.price > 0) ...[const SizedBox(width: 8), Text('\$${listing.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cRed))],
              const SizedBox(width: 8), Text(formatDate(listing.submittedAt), style: const TextStyle(fontSize: 11, color: cMuted)),
            ]),
          ])),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: cMuted),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LOST & FOUND PANEL
// ═════════════════════════════════════════════════════════════════════════════

class _AdminLostFoundPanel extends StatefulWidget {
  final List<AdminLostFoundItem> items;
  final List<AdminLostFoundItem> lostItems;
  final List<AdminLostFoundItem> foundItems;
  final List<MatchedPair> matchedPairs;
  final VoidCallback onRefresh;
  const _AdminLostFoundPanel({required this.items, required this.lostItems, required this.foundItems, required this.matchedPairs, required this.onRefresh});

  @override
  State<_AdminLostFoundPanel> createState() => _AdminLostFoundPanelState();
}

const _cLost = Color(0xFFE74C3C);
const _cFound = Color(0xFF2980B9);
const _cGreen = Color(0xFF27AE60);
const _cOrange = Color(0xFFE67E22);

class _AdminLostFoundPanelState extends State<_AdminLostFoundPanel> {
  bool _showMatched = false;
  String? _selectedLostId;
  String? _selectedFoundId;
  bool _creating = false;

  void _showItemDetail(AdminLostFoundItem item) {
    final isLost = item.type == 'lost';
    final typeColor = isLost ? _cLost : _cFound;
    showGeneralDialog(
      context: context, barrierDismissible: true, barrierLabel: 'Detail',
      barrierColor: Colors.black.withValues(alpha: 0.45), transitionDuration: kMid,
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return Opacity(
          opacity: curved.value,
          child: Transform.scale(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved).value,
            child: Center(
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: cBorder)),
                  child: Material(color: Colors.transparent, child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Stack(children: [
                      Image.network(item.image, width: double.infinity, height: 150, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(height: 150, color: cPlaceholder, child: const Center(child: Icon(Icons.image_not_supported, color: cMuted, size: 36)))),
                      Positioned(top: 10, left: 10, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(7)),
                        child: Text(item.type.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                      )),
                      Positioned(top: 8, right: 8, child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(width: 30, height: 30, decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 16)),
                      )),
                    ]),
                    Flexible(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.3)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        _DetailChip(Icons.category_outlined, item.category),
                        _DetailChip(Icons.location_on_outlined, item.location),
                        _DetailChip(Icons.access_time_rounded, formatDate(item.createdAt)),
                      ]),
                      const SizedBox(height: 12),
                      Text(item.description, style: const TextStyle(fontSize: 13, color: cMuted, height: 1.55)),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity, padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: cBorder)),
                        child: Row(children: [
                          const Icon(Icons.person_outline_rounded, size: 16, color: cMuted),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.posterUsername, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cText)),
                            Text(item.posterEmail, style: const TextStyle(fontSize: 11, color: cMuted)),
                          ])),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      if (!isLost) ...[
                        Row(children: [
                          Icon(Icons.volunteer_activism_outlined, size: 16, color: item.claims.isNotEmpty ? _cOrange : cMuted),
                          const SizedBox(width: 6),
                          Text('Claims (${item.claims.length})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cText)),
                        ]),
                        const SizedBox(height: 8),
                        if (item.claims.isEmpty)
                          const Text('No claims submitted.', style: TextStyle(fontSize: 12, color: cMuted))
                        else
                          ...item.claims.map((c) {
                          final cColor = c.status == 'pending' ? _cOrange : c.status == 'approved' ? _cGreen : _cLost;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: cColor.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: cColor.withValues(alpha: 0.2))),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                const Icon(Icons.person_outline_rounded, size: 13, color: cMuted),
                                const SizedBox(width: 4),
                                Expanded(child: Text(c.claimantEmail, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cText))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(color: cColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                  child: Text(c.status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: cColor)),
                                ),
                              ]),
                              const SizedBox(height: 6),
                              const Text('Proof:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cMuted)),
                              const SizedBox(height: 2),
                              Text(c.proofDetails, style: const TextStyle(fontSize: 12, color: cText, height: 1.5)),
                              const SizedBox(height: 4),
                              Text(formatDate(c.submittedAt), style: const TextStyle(fontSize: 10, color: cMuted)),
                              if (c.status == 'pending') ...[
                                const SizedBox(height: 8),
                                SizedBox(width: double.infinity, child: ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await adminAcceptClaim(claimId: c.id, itemId: item.id);
                                      if (ctx.mounted) {
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                          content: Row(children: const [
                                            Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
                                            SizedBox(width: 8),
                                            Expanded(child: Text('Claim approved! Chat opened.')),
                                          ]),
                                          backgroundColor: _cGreen,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          margin: const EdgeInsets.all(12),
                                        ));
                                      }
                                      widget.onRefresh();
                                    } catch (e) {
                                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
                                    }
                                  },
                                  icon: const Icon(Icons.check_circle_rounded, size: 14),
                                  label: const Text('Accept Claim'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _cGreen, foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                )),
                              ],
                            ]),
                          );
                        }),
                      ],
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              if (isLost) {
                                _selectedLostId = _selectedLostId == item.id ? null : item.id;
                              } else {
                                _selectedFoundId = _selectedFoundId == item.id ? null : item.id;
                              }
                            });
                            Navigator.pop(ctx);
                          },
                          icon: Icon(
                            (isLost ? _selectedLostId == item.id : _selectedFoundId == item.id) ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                            size: 16,
                          ),
                          label: Text(
                            (isLost ? _selectedLostId == item.id : _selectedFoundId == item.id) ? 'Deselect' : 'Select to Match',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: typeColor, side: BorderSide(color: typeColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        )),
                      ]),
                    ]))),
                  ])),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _createMatch() async {
    if (_selectedLostId == null || _selectedFoundId == null) return;
    setState(() => _creating = true);
    try {
      await adminCreateMatch(lostItemId: _selectedLostId!, foundItemId: _selectedFoundId!);
      setState(() { _selectedLostId = null; _selectedFoundId = null; _showMatched = true; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text('Items matched! A chat has been created between both posters.')),
        ]),
        backgroundColor: _cGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
      widget.onRefresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _unmatch(String matchId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Unmatch Items?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Both items go back to active and can be matched again.', style: TextStyle(color: cMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Unmatch', style: TextStyle(color: cRedDark, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await adminUnmatch(matchId: matchId);
      widget.onRefresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    }
  }

  Widget _buildItemList({required List<AdminLostFoundItem> items, required bool isLost, required EdgeInsets padding}) {
    final accent = isLost ? _cLost : _cFound;
    final emptyMsg = isLost ? 'No approved\nlost items' : 'No approved\nfound items';
    final isMobile = MediaQuery.of(context).size.width < 600;
    final imgSize = isMobile ? 48.0 : 60.0;
    if (items.isEmpty) return Center(child: Text(emptyMsg, textAlign: TextAlign.center, style: const TextStyle(color: cMuted, fontSize: 11)));
    return ListView.builder(
      primary: false,
      padding: padding,
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final sel = isLost ? _selectedLostId == item.id : _selectedFoundId == item.id;
        final hasClaims = item.claims.isNotEmpty;
        return GestureDetector(
          onTap: () => _showItemDetail(item),
          onLongPress: () => setState(() {
            if (isLost) { _selectedLostId = sel ? null : item.id; }
            else { _selectedFoundId = sel ? null : item.id; }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: sel ? accent.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
              border: Border.all(color: sel ? accent : cBorder, width: sel ? 2 : 1),
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.horizontal(left: Radius.circular(isMobile ? 9 : 11)),
                child: Image.network(item.image, width: imgSize, height: imgSize, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: imgSize, height: imgSize, color: cPlaceholder, child: Icon(Icons.image, color: cMuted, size: isMobile ? 16 : 20))),
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Expanded(child: Padding(
                padding: EdgeInsets.symmetric(vertical: isMobile ? 6 : 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.title, style: TextStyle(fontSize: isMobile ? 11 : 12, fontWeight: FontWeight.w700, color: cText), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(item.category, style: TextStyle(fontSize: isMobile ? 9 : 10, color: cMuted), overflow: TextOverflow.ellipsis),
                  if (hasClaims)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: _cOrange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                        child: Text('${item.claims.length} claim${item.claims.length > 1 ? 's' : ''}', style: TextStyle(fontSize: isMobile ? 8 : 9, fontWeight: FontWeight.w800, color: _cOrange)),
                      ),
                    ),
                ]),
              )),
              if (sel) Padding(padding: EdgeInsets.only(right: isMobile ? 4 : 8), child: Icon(Icons.check_circle_rounded, color: accent, size: isMobile ? 16 : 20)),
            ]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [cRed, cRedDark]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Icon(
                _showMatched ? Icons.link_rounded : Icons.compare_arrows_rounded,
                color: Colors.white, size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lost & Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.4)),
                Text(
                  _showMatched ? 'Tap to view, long-press to select' : 'Select one from each side, then match',
                  style: const TextStyle(fontSize: 12, color: cMuted),
                ),
              ],
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showMatched = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: !_showMatched ? cRed : cSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: !_showMatched ? cRed : cBorder),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.compare_arrows_rounded, size: 16, color: !_showMatched ? Colors.white : cMuted),
                    const SizedBox(width: 6),
                    Text('Match Items', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: !_showMatched ? Colors.white : cMuted)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showMatched = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _showMatched ? cRed : cSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _showMatched ? cRed : cBorder),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.link_rounded, size: 16, color: _showMatched ? Colors.white : cMuted),
                    const SizedBox(width: 6),
                    Text('Matched (${widget.matchedPairs.length})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _showMatched ? Colors.white : cMuted)),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
      if (!_showMatched) ...[
        if (_selectedLostId != null || _selectedFoundId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: _cGreen.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: _cGreen.withValues(alpha: 0.3))),
              child: Row(children: [
                Icon(_selectedLostId != null ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 14, color: _selectedLostId != null ? _cLost : cMuted),
                const SizedBox(width: 3),
                Text('Lost', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _selectedLostId != null ? _cLost : cMuted)),
                const SizedBox(width: 10),
                Icon(_selectedFoundId != null ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 14, color: _selectedFoundId != null ? _cFound : cMuted),
                const SizedBox(width: 3),
                Text('Found', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _selectedFoundId != null ? _cFound : cMuted)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() { _selectedLostId = null; _selectedFoundId = null; }),
                  child: const Text('Clear', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cRedDark)),
                ),
              ]),
            ),
          ),
        const SizedBox(height: 4),
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(children: [
              Container(
                width: double.infinity, margin: const EdgeInsets.fromLTRB(12, 0, 4, 6),
                padding: EdgeInsets.symmetric(vertical: isMobile ? 5 : 6),
                decoration: BoxDecoration(color: _cLost.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.search_off_rounded, size: isMobile ? 12 : 14, color: _cLost),
                  const SizedBox(width: 4),
                  Text('LOST (${widget.lostItems.length})', style: TextStyle(fontSize: isMobile ? 10 : 11, fontWeight: FontWeight.w900, color: _cLost, letterSpacing: 0.5)),
                ]),
              ),
              Expanded(child: _buildItemList(items: widget.lostItems, isLost: true, padding: const EdgeInsets.fromLTRB(12, 0, 4, 12))),
            ])),
            Expanded(child: Column(children: [
              Container(
                width: double.infinity, margin: const EdgeInsets.fromLTRB(4, 0, 12, 6),
                padding: EdgeInsets.symmetric(vertical: isMobile ? 5 : 6),
                decoration: BoxDecoration(color: _cFound.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.inventory_2_outlined, size: isMobile ? 12 : 14, color: _cFound),
                  const SizedBox(width: 4),
                  Text('FOUND (${widget.foundItems.length})', style: TextStyle(fontSize: isMobile ? 10 : 11, fontWeight: FontWeight.w900, color: _cFound, letterSpacing: 0.5)),
                ]),
              ),
              Expanded(child: _buildItemList(items: widget.foundItems, isLost: false, padding: const EdgeInsets.fromLTRB(4, 0, 12, 12))),
            ])),
          ]),
        ),
        if (_selectedLostId != null && _selectedFoundId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _creating ? null : _createMatch,
                icon: _creating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.compare_arrows_rounded, size: 18),
                label: Text(_creating ? 'Matching...' : 'Match These Items'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cGreen, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
      ],
      if (_showMatched)
        Expanded(
          child: widget.matchedPairs.isEmpty
              ? const _AdminEmptyState(message: 'No matched pairs yet', icon: Icons.link_off_rounded)
              : ListView.builder(
                  primary: false,
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.matchedPairs.length,
                  itemBuilder: (_, i) {
                    final pair = widget.matchedPairs[i];
                    final isResolved = pair.status.toLowerCase() == 'resolved';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isResolved ? _cGreen.withValues(alpha: 0.3) : _cOrange.withValues(alpha: 0.3)),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                          child: Row(children: [
                            Expanded(child: Column(children: [
                              ClipRRect(borderRadius: BorderRadius.circular(12),
                                child: Image.network(pair.lostItem.image, width: 80, height: 80, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: cPlaceholder, child: const Icon(Icons.image, color: cMuted)))),
                              const SizedBox(height: 6),
                              Text(pair.lostItem.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cText), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: _cLost.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                                child: Text('LOST · ${pair.lostItem.category}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _cLost)),
                              ),
                            ])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Column(children: [
                                Icon(Icons.compare_arrows_rounded, color: isResolved ? _cGreen : _cOrange, size: 28),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isResolved ? _cGreen : _cOrange).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(isResolved ? 'RESOLVED' : 'MATCHED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isResolved ? _cGreen : _cOrange, letterSpacing: 0.5)),
                                ),
                              ]),
                            ),
                            Expanded(child: Column(children: [
                              ClipRRect(borderRadius: BorderRadius.circular(12),
                                child: Image.network(pair.foundItem.image, width: 80, height: 80, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(width: 80, height: 80, color: cPlaceholder, child: const Icon(Icons.image, color: cMuted)))),
                              const SizedBox(height: 6),
                              Text(pair.foundItem.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cText), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: _cFound.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                                child: Text('FOUND · ${pair.foundItem.category}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _cFound)),
                              ),
                            ])),
                          ]),
                        ),
                        if (!isResolved)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _unmatch(pair.matchId),
                                icon: const Icon(Icons.link_off_rounded, size: 14),
                                label: const Text('Unmatch'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: cRedDark, side: const BorderSide(color: cRedDark),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 14),
                      ]),
                    );
                  },
                ),
        ),
    ]);
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailChip(this.icon, this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(7), border: Border.all(color: cBorder)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: cMuted),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted)),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MEETUPS PANEL
// ═════════════════════════════════════════════════════════════════════════════

class _AdminMeetupsPanel extends StatefulWidget {
  final List<AdminMeetup> meetups;
  final VoidCallback onRefresh;
  const _AdminMeetupsPanel({required this.meetups, required this.onRefresh});

  @override
  State<_AdminMeetupsPanel> createState() => _AdminMeetupsPanelState();
}

class _AdminMeetupsPanelState extends State<_AdminMeetupsPanel> {
  bool _loading = false;
  String? _error;
  bool _showCompletion = false;
  final TextEditingController _reasonCtrl = TextEditingController();

  @override
  void dispose() { _reasonCtrl.dispose(); super.dispose(); }

  List<AdminMeetup> get _pendingList =>
      widget.meetups.where((m) => m.status == 'admin_pending').toList();
  List<AdminMeetup> get _completionList =>
      widget.meetups.where((m) => m.status == 'completion_pending').toList();

  String _fmtDate(DateTime d) {
    const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const dy = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${dy[(d.weekday-1)%7]}, ${mo[d.month-1]} ${d.day}, ${d.year}';
  }

  String _fmtTime(String t) {
    try {
      final p = t.split(':');
      int h = int.parse(p[0]);
      final m = p[1];
      final ap = h >= 12 ? 'PM' : 'AM';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      return '$h:$m $ap';
    } catch (_) { return t; }
  }

  Future<void> _approve(AdminMeetup m) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Approve Meetup?', style: TextStyle(fontWeight: FontWeight.w800)),
      content: Text('Both @${m.buyerUsername} and @${m.sellerUsername} will be notified.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Approve', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w700))),
      ],
    ));
    if (ok != true) return;
    setState(() { _loading = true; _error = null; });
    try { await adminApproveMeetup(meetupId: m.meetupId, meetupType: m.isMarketplace ? 'marketplace' : 'lost_found'); widget.onRefresh(); }
    catch (e) { setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _deny(AdminMeetup m) async {
    _reasonCtrl.clear();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Deny Meetup', style: TextStyle(fontWeight: FontWeight.w800)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Both @${m.buyerUsername} and @${m.sellerUsername} will be notified.', style: const TextStyle(color: cMuted, fontSize: 13)),
        const SizedBox(height: 12),
        const Text('Reason (required)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: _reasonCtrl, maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Explain why this meetup is being denied...',
            hintStyle: const TextStyle(color: cMuted, fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: cRed, width: 2)),
            filled: true, fillColor: cBg, contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () { if (_reasonCtrl.text.trim().isEmpty) return; Navigator.pop(ctx, true); },
          child: const Text('Deny', style: TextStyle(color: cRedDark, fontWeight: FontWeight.w700)),
        ),
      ],
    ));
    if (ok != true || _reasonCtrl.text.trim().isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try { await adminDenyMeetup(meetupId: m.meetupId, reason: _reasonCtrl.text.trim(), meetupType: m.isMarketplace ? 'marketplace' : 'lost_found'); widget.onRefresh(); }
    catch (e) { setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _completeMeetup(AdminMeetup m) async {
    final label = m.isMarketplace ? 'Complete & Process Payment' : 'Complete Meetup';
    final body  = m.isMarketplace
        ? 'Both photos have been verified. This will mark the meetup as completed, process the payment, and mark the listing as sold. Both users will be notified.'
        : 'Both photos have been verified. This will mark the meetup as completed. Both users will be notified.';
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(label, style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w700))),
      ],
    ));
    if (ok != true) return;
    setState(() { _loading = true; _error = null; });
    try { await adminCompleteMeetup(meetupId: m.meetupId); widget.onRefresh(); }
    catch (e) { setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Widget _card(AdminMeetup m, {required bool isCompletion}) {
    final accentColor = isCompletion ? const Color(0xFF16A34A) : const Color(0xFF7B5800);
    final accentBg    = isCompletion ? const Color(0xFFECFDF5) : const Color(0xFFFFF8EC);
    final badgeColor  = isCompletion ? const Color(0xFF16A34A).withValues(alpha: 0.12) : const Color(0xFFFFE082);
    final badgeText   = isCompletion ? 'VERIFY' : 'PENDING';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isCompletion ? const Color(0xFF16A34A).withValues(alpha: 0.3) : cBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(
            color: accentBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            border: Border(bottom: BorderSide(color: cBorder)),
          ),
          child: Row(children: [
            // Item image or icon
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: m.itemImage != null && m.itemImage!.isNotEmpty
                  ? Image.network(m.itemImage!, width: 44, height: 44, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 44, height: 44,
                          decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
                          child: Icon(isCompletion ? Icons.camera_alt_rounded : Icons.handshake_outlined, size: 20, color: accentColor)))
                  : Container(width: 44, height: 44,
                      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
                      child: Icon(isCompletion ? Icons.camera_alt_rounded : Icons.handshake_outlined, size: 20, color: accentColor)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.itemTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cText), maxLines: 1, overflow: TextOverflow.ellipsis),
              Row(children: [
                if (m.itemPrice != null) ...[
                  Text('\$${m.itemPrice!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cRed)),
                  const Text(' · ', style: TextStyle(fontSize: 11, color: cMuted)),
                ],
                if (m.itemCategory != null)
                  Text(m.itemCategory!, style: const TextStyle(fontSize: 11, color: cMuted)),
              ]),
              Text('Submitted ${formatDate(m.createdAt)}', style: const TextStyle(fontSize: 10, color: cMuted)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(6)),
              child: Text(badgeText, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: accentColor, letterSpacing: 0.5)),
            ),
          ]),
        ),
        // ── Body ──
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Users
            Row(children: [
              Expanded(child: _MeetupUserChip(
                label: m.isMarketplace ? 'Buyer' : 'Finder',
                username: m.buyerUsername,
                email: m.buyerEmail,
                color: const Color(0xFF2980B9),
              )),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.sync_alt_rounded, size: 16, color: cMuted)),
              Expanded(child: _MeetupUserChip(
                label: m.isMarketplace ? 'Seller' : 'Owner',
                username: m.sellerUsername,
                email: m.sellerEmail,
                color: const Color(0xFF16A34A),
              )),
            ]),
            const SizedBox(height: 12),
            // Location / Date / Time
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: cBorder)),
              child: Column(children: [
                _MeetupDetailRow(icon: Icons.location_on_outlined, label: m.location),
                const SizedBox(height: 6),
                _MeetupDetailRow(icon: Icons.calendar_today_outlined, label: _fmtDate(m.meetupDate)),
                const SizedBox(height: 6),
                _MeetupDetailRow(icon: Icons.access_time_rounded, label: _fmtTime(m.meetupTime)),
              ]),
            ),
            // Completion photos
            if (isCompletion) ...[
              const SizedBox(height: 12),
              const Text('Completion Photos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cText)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _PhotoPreview(label: m.isMarketplace ? 'Buyer Photo' : 'Lost Photo', url: m.buyerPhotoUrl)),
                const SizedBox(width: 8),
                Expanded(child: _PhotoPreview(label: m.isMarketplace ? 'Seller Photo' : 'Found Photo', url: m.sellerPhotoUrl)),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : () => _completeMeetup(m),
                  icon: _loading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded, size: 16),
                  label: Text(m.isMarketplace ? 'Complete & Process Payment' : 'Complete Meetup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () => _deny(m),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Deny'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cRedDark, side: const BorderSide(color: cRedDark),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : () => _approve(m),
                    icon: _loading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending    = _pendingList;
    final completing = _completionList;
    final shown      = _showCompletion ? completing : pending;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [cRed, cRedDark]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Icon(
                  _showCompletion ? Icons.camera_alt_rounded : Icons.handshake_outlined,
                  color: Colors.white, size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meetup Proposals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.4)),
                  Text('Review and approve or deny pending meetup proposals', style: TextStyle(fontSize: 12, color: cMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(children: [
            _Chip(label: 'Pending (${pending.length})', selected: !_showCompletion, onTap: () => setState(() => _showCompletion = false)),
            const SizedBox(width: 8),
            _Chip(label: 'Verify (${completing.length})', selected: _showCompletion, onTap: () => setState(() => _showCompletion = true)),
          ]),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: cRed.withValues(alpha: 0.3))),
              child: Row(children: [const Icon(Icons.error_outline_rounded, size: 14, color: cRed), const SizedBox(width: 8), Expanded(child: Text(_error!, style: const TextStyle(color: cRedDark, fontSize: 12)))]),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: shown.isEmpty
            ? _AdminEmptyState(
                message: _showCompletion ? 'No meetups awaiting verification' : 'No pending meetup proposals',
                icon: _showCompletion ? Icons.camera_alt_outlined : Icons.handshake_outlined,
              )
            : ListView.builder(
                primary: false,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: shown.length,
                itemBuilder: (_, i) => _card(shown[i], isCompletion: _showCompletion),
              ),
      ),
    ]);
  }
}

class _PhotoPreview extends StatelessWidget {
  final String label;
  final String? url;
  const _PhotoPreview({required this.label, this.url});

  void _showFullScreen(BuildContext context) {
    if (url == null || url!.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(url!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48))),
              ),
            ),
          ),
          Positioned(
            top: 0, right: 0,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
          Positioned(
            bottom: 8, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = url != null && url!.isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cMuted)),
      const SizedBox(height: 4),
      GestureDetector(
        onTap: hasPhoto ? () => _showFullScreen(context) : null,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: cBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: hasPhoto ? const Color(0xFF16A34A).withValues(alpha: 0.4) : cBorder),
          ),
          child: hasPhoto
              ? Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.network(url!, fit: BoxFit.cover, width: double.infinity, height: 110,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, color: cMuted))),
                  ),
                  Positioned(
                    bottom: 5, right: 5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                      child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ])
              : const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.camera_alt_outlined, color: cMuted, size: 20),
                  SizedBox(height: 4),
                  Text('Not submitted', style: TextStyle(fontSize: 10, color: cMuted)),
                ])),
        ),
      ),
    ]);
  }
}

class _MeetupUserChip extends StatelessWidget {
  final String label, username, email;
  final Color color;
  const _MeetupUserChip({required this.label, required this.username, required this.email, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
        const SizedBox(height: 3),
        Text('@$username', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cText), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(email, style: const TextStyle(fontSize: 10, color: cMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

class _MeetupDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MeetupDetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 14, color: cRed),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cText))),
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// USERS PANEL
// ═════════════════════════════════════════════════════════════════════════════

class _AdminUsersPanel extends StatefulWidget {
  final List<AdminUser> users;
  final VoidCallback onRefresh;
  const _AdminUsersPanel({required this.users, required this.onRefresh});

  @override
  State<_AdminUsersPanel> createState() => _AdminUsersPanelState();
}

class _AdminUsersPanelState extends State<_AdminUsersPanel> {
  String _q = '';
  String _roleFilter = 'All';

  List<AdminUser> get _filtered {
    final q = _q.toLowerCase();
    return widget.users.where((u) {
      final matchQ = q.isEmpty || u.email.contains(q) || u.username.toLowerCase().contains(q) || u.displayName.toLowerCase().contains(q);
      final matchR = _roleFilter == 'All'
          || (_roleFilter == 'Student' && u.role == UserRole.student)
          || (_roleFilter == 'Faculty' && u.role == UserRole.fac)
          || (_roleFilter == 'Warned'  && u.hasWarning && !u.isBanned)
          || (_roleFilter == 'Banned'  && u.isBanned);
      return matchQ && matchR;
    }).toList();
  }

  Future<void> _openListingHistory(BuildContext parentCtx, AdminUser user) async {
    List<Map<String, dynamic>> marketItems = [];
    List<Map<String, dynamic>> lfItems = [];
    bool loading = true;
    bool fetched = false;

    await showGeneralDialog(
      context: parentCtx, barrierDismissible: true, barrierLabel: 'History',
      barrierColor: Colors.black.withValues(alpha: 0.4), transitionDuration: kMid,
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) => Opacity(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut).value,
        child: StatefulBuilder(builder: (ctx, setS) {
          if (!fetched) {
            fetched = true;
            Future.microtask(() async {
              try {
                final market = await getUserMarketListings(user.id);
                final lf     = await getUserLostFoundListings(user.id);
                if (ctx.mounted) setS(() { marketItems = market; lfItems = lf; loading = false; });
              } catch (_) { if (ctx.mounted) setS(() => loading = false); }
            });
          }
          return Center(
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: cBorder)),
                child: Material(color: Colors.transparent, child: Padding(padding: const EdgeInsets.all(20),
                  child: loading
                      ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: cRed)))
                      : SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text('History — @${user.username}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: cText))),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                          ]),
                          const SizedBox(height: 4),
                          Text('Registered: ${formatDate(user.registeredAt)}', style: const TextStyle(fontSize: 12, color: cMuted)),
                          Text('Last Active: ${user.lastActive != null ? _lastActiveLabel(user.lastActive!) : 'Never'}', style: const TextStyle(fontSize: 12, color: cMuted)),
                          const SizedBox(height: 16),
                          const _AdminLabel('Marketplace Listings'),
                          const SizedBox(height: 8),
                          if (marketItems.isEmpty) const Text('No marketplace listings.', style: TextStyle(fontSize: 12, color: cMuted))
                          else ...marketItems.map((m) => _HistoryTile(title: m['title']?.toString() ?? '', subtitle: '${m['category']} · \$${m['price']} · ${m['status']}', date: m['created_at']?.toString() ?? '', icon: Icons.storefront_rounded)),
                          const SizedBox(height: 16),
                          const _AdminLabel('Lost & Found Posts'),
                          const SizedBox(height: 8),
                          if (lfItems.isEmpty) const Text('No lost & found posts.', style: TextStyle(fontSize: 12, color: cMuted))
                          else ...lfItems.map((l) => _HistoryTile(title: l['title']?.toString() ?? '', subtitle: '${l['category']} · ${l['type']} · ${l['status']}', date: l['created_at']?.toString() ?? '', icon: Icons.search_rounded)),
                        ])),
                )),
              ),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _openDetail(AdminUser user) async {
    bool loading = false; String? error;
    // Fetch online status before opening dialog
    bool? isOnline;
    try { isOnline = await getUserOnlineStatus(userId: user.id); } catch (_) { isOnline = false; }
    int marketCount = 0;
    int lfCount = 0;
    try {
      final market = await getUserMarketListings(user.id);
      final lf     = await getUserLostFoundListings(user.id);
      marketCount  = market.where((m) => m['status']?.toString() == 'active').length;
      lfCount      = lf.where((l) => l['status']?.toString() == 'active').length;
    } catch (_) {}
    await showGeneralDialog(
      context: context, barrierDismissible: true, barrierLabel: 'User',
      barrierColor: Colors.black.withValues(alpha: 0.4), transitionDuration: kMid,
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        return Opacity(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut).value,
          child: StatefulBuilder(builder: (ctx, setS) {
            return Center(
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: cBorder)),
                  child: Material(color: Colors.transparent, child: SingleChildScrollView(padding: const EdgeInsets.all(20),
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        CircleAvatar(backgroundColor: user.isBanned ? cRedDark : cRedLight, radius: 24, child: Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U', style: TextStyle(color: user.isBanned ? Colors.white : cRed, fontWeight: FontWeight.w900, fontSize: 20))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(user.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: cText)),
                          Text('@${user.username}', style: const TextStyle(fontSize: 12, color: cMuted)),
                          Text(user.email, style: const TextStyle(fontSize: 12, color: cMuted)),
                        ])),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      ]),
                      const SizedBox(height: 16),
                      _UserInfoRow(label: 'Role',           value: user.role.label),
                      _UserInfoRow(label: 'Registered',     value: formatDate(user.registeredAt)),
                      _UserInfoRow(label: 'Last Active',    value: user.lastActive != null ? _lastActiveLabel(user.lastActive!) : 'Never'),
                      _UserInfoRow(label: 'Active Marketplace', value: '$marketCount'),
                      _UserInfoRow(label: 'Active Lost & Found', value: '$lfCount'),
                      _UserInfoRow(label: 'Warning Issued', value: user.hasWarning ? (user.warnedAt != null ? 'Yes · ${formatDate(user.warnedAt!)}' : 'Yes') : 'No', highlight: user.hasWarning),
                      // ── Status row with online indicator ──
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          const Text('Status', style: TextStyle(fontSize: 12, color: cMuted, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          if (user.isBanned)
                            const Text('BANNED', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cRedDark))
                          else
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  color: isOnline == true ? const Color(0xFF4ADE80) : const Color(0xFF9CA3AF),
                                  shape: BoxShape.circle,
                                  boxShadow: isOnline == true ? [BoxShadow(color: const Color(0xFF4ADE80).withValues(alpha: 0.5), blurRadius: 4)] : [],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOnline == true ? 'Online' : 'Offline',
                                style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: isOnline == true ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
                                ),
                              ),

                            ]),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      if (!user.isBanned && !user.hasWarning)
                        Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFE082))),
                          child: const Row(children: [Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFFE67E22)), SizedBox(width: 8), Expanded(child: Text('A warning must be issued before a user can be permanently banned.', style: TextStyle(fontSize: 12, color: Color(0xFF7B5800), height: 1.4)))])),
                      if (!user.isBanned && user.hasWarning)
                        Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(10), border: Border.all(color: cRed.withValues(alpha: 0.4))),
                          child: const Row(children: [Icon(Icons.warning_amber_rounded, size: 15, color: cRedDark), SizedBox(width: 8), Expanded(child: Text('This user has already received their one-time warning. They can now be permanently banned if a further violation occurs.', style: TextStyle(fontSize: 12, color: cRedDark, height: 1.4)))])),
                      const SizedBox(height: 16),
                      if (error != null) ...[Text(error!, style: const TextStyle(color: cRedDark, fontSize: 12)), const SizedBox(height: 8)],
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        OutlinedButton.icon(icon: const Icon(Icons.history_rounded, size: 16), label: const Text('View Listing History'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2980B9), side: const BorderSide(color: Color(0xFF2980B9))), onPressed: () => _openListingHistory(ctx, user)),
                        if (!user.isBanned && !user.hasWarning)
                          OutlinedButton.icon(
                            icon: loading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.warning_amber_rounded, size: 16),
                            label: const Text('Issue Warning'),
                            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE67E22), side: const BorderSide(color: Color(0xFFE67E22))),
                            onPressed: loading ? null : () async {
                              final confirm = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(title: const Text('Issue a Warning?'), content: Text('This will send a one-time warning to @${user.username}.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Issue Warning', style: TextStyle(color: Color(0xFFE67E22))))]));
                              if (confirm != true) return;
                              setS(() { loading = true; error = null; });
                              try { await adminIssueWarning(userId: user.id, email: user.email); if (ctx.mounted) Navigator.pop(ctx); widget.onRefresh(); }
                              catch (e) { setS(() { loading = false; error = e.toString(); }); }
                            },
                          ),
                        if (!user.isBanned && user.hasWarning)
                          OutlinedButton.icon(
                            icon: loading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.undo_rounded, size: 16),
                            label: const Text('Revoke Warning'),
                            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE67E22), side: const BorderSide(color: Color(0xFFE67E22))),
                            onPressed: loading ? null : () async {
                              final confirm = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(title: const Text('Revoke Warning?'), content: Text('This will remove the warning from @' + user.username + "'s account."), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Revoke', style: TextStyle(color: Color(0xFFE67E22))))]));
                              if (confirm != true) return;
                              setS(() { loading = true; error = null; });
                              try { await adminRevokeWarning(userId: user.id); if (ctx.mounted) Navigator.pop(ctx); widget.onRefresh(); }
                              catch (e) { setS(() { loading = false; error = e.toString(); }); }
                            },
                          ),
                        if (!user.isBanned && user.hasWarning)
                          OutlinedButton.icon(
                            icon: loading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.block_rounded, size: 16),
                            label: const Text('Ban User'),
                            style: OutlinedButton.styleFrom(foregroundColor: cRedDark, side: const BorderSide(color: cRedDark)),
                            onPressed: loading ? null : () async {
                              final confirm = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(title: const Text('Permanently Ban This User?'), content: Text('@${user.username} has already been warned. This will permanently ban them and blacklist their email.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ban Permanently', style: TextStyle(color: cRedDark)))]));
                              if (confirm != true) return;
                              setS(() { loading = true; error = null; });
                              try { await adminBanUser(userId: user.id, email: user.email); if (ctx.mounted) Navigator.pop(ctx); widget.onRefresh(); }
                              catch (e) { setS(() { loading = false; error = e.toString(); }); }
                            },
                          ),
                        if (user.isBanned)
                          OutlinedButton.icon(
                            icon: loading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.lock_open_rounded, size: 16),
                            label: const Text('Unban User'),
                            style: OutlinedButton.styleFrom(foregroundColor: cRedDark, side: const BorderSide(color: cRedDark)),
                            onPressed: loading ? null : () async {
                              final confirm = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(title: const Text('Unban This User?'), content: Text('This will allow @${user.username} back onto UniFind.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Unban', style: TextStyle(color: cRedDark)))]));
                              if (confirm != true) return;
                              setS(() { loading = true; error = null; });
                              try { await adminUnbanUser(userId: user.id, email: user.email); if (ctx.mounted) Navigator.pop(ctx); widget.onRefresh(); }
                              catch (e) { setS(() { loading = false; error = e.toString(); }); }
                            },
                          ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.delete_forever_rounded, size: 16),
                          label: const Text('Delete Account'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade900, side: BorderSide(color: Colors.red.shade900)),
                          onPressed: loading ? null : () async {
                            final confirm = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(title: const Text('Delete Account?'), content: Text('Permanently deletes @${user.username} and all their data. Their email can be used to create a new account afterwards.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red)))]));
                            if (confirm != true) return;
                            setS(() { loading = true; error = null; });
                            try { await adminDeleteUser(userId: user.id, email: user.email); if (ctx.mounted) Navigator.pop(ctx); widget.onRefresh(); }
                            catch (e) { setS(() { loading = false; error = e.toString(); }); }
                          },
                        ),
                      ]),
                    ]),
                  )),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  // ── Create Admin Account dialog ─────────────────────────────────────────
  Future<void> _openCreateAdminDialog() async {
    final firstCtrl    = TextEditingController();
    final lastCtrl     = TextEditingController();
    final usernameCtrl = TextEditingController();
    final emailCtrl    = TextEditingController();
    bool loading = false;
    String? error;
    bool success = false;

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CreateAdmin',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: kMid,
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) => Opacity(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut).value,
        child: StatefulBuilder(
          builder: (ctx, setS) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: success
                        // ── Success state ──────────────────────────────────
                        ? Column(mainAxisSize: MainAxisSize.min, children: [
                            const SizedBox(height: 12),
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [cNavBg, cNavBgDark]),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
                            ),
                            const SizedBox(height: 20),
                            const Text('Admin Account Created!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cText)),
                            const SizedBox(height: 8),
                            Text(
                              'An email with login credentials has been sent to ${emailCtrl.text.trim()}.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13, color: cMuted, height: 1.5),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () { Navigator.pop(ctx); widget.onRefresh(); },
                                style: ElevatedButton.styleFrom(backgroundColor: cRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ])
                        // ── Form state ─────────────────────────────────────
                        : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                            // Header
                            Row(children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [cNavBg, cNavBgDark]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Create Admin Account', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: cText)),
                                Text('Credentials will be emailed to the new admin', style: TextStyle(fontSize: 11, color: cMuted)),
                              ])),
                              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                            ]),
                            const SizedBox(height: 20),

                            // Role badge (read-only)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cNavBgDark.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: cNavBgDark.withValues(alpha: 0.2)),
                              ),
                              child: const Row(children: [
                                Icon(Icons.admin_panel_settings_rounded, size: 16, color: cNavBgDark),
                                SizedBox(width: 10),
                                Text('Role: Administrator', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cNavBgDark)),
                                Spacer(),
                                Text('Auto-assigned', style: TextStyle(fontSize: 11, color: cMuted)),
                              ]),
                            ),
                            const SizedBox(height: 16),

                            // First + Last name row
                            Row(children: [
                              Expanded(child: _AdminFormField(controller: firstCtrl, label: 'First Name', hint: 'Jane', icon: Icons.person_outline_rounded)),
                              const SizedBox(width: 12),
                              Expanded(child: _AdminFormField(controller: lastCtrl, label: 'Last Name', hint: 'Doe', icon: Icons.person_outline_rounded)),
                            ]),
                            const SizedBox(height: 12),

                            // Username
                            _AdminFormField(controller: usernameCtrl, label: 'Username', hint: 'janedoe_admin', icon: Icons.alternate_email_rounded),
                            const SizedBox(height: 12),

                            // Email
                            _AdminFormField(controller: emailCtrl, label: 'Email Address', hint: 'jane@montclair.edu', icon: Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFFFFF8EC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFFE082))),
                              child: const Row(children: [
                                Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFFE67E22)),
                                SizedBox(width: 8),
                                Expanded(child: Text('A secure temporary password will be auto-generated and emailed to the new admin.', style: TextStyle(fontSize: 11, color: Color(0xFF7B5800), height: 1.4))),
                              ]),
                            ),

                            if (error != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(8), border: Border.all(color: cRed.withValues(alpha: 0.3))),
                                child: Row(children: [
                                  const Icon(Icons.error_outline_rounded, size: 14, color: cRed),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(error!, style: const TextStyle(color: cRedDark, fontSize: 12))),
                                ]),
                              ),
                            ],

                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: loading
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.admin_panel_settings_rounded, size: 17),
                                label: const Text('Create Admin Account', style: TextStyle(fontWeight: FontWeight.w800)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cNavBgDark, foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: loading ? null : () async {
                                  final first    = firstCtrl.text.trim();
                                  final last     = lastCtrl.text.trim();
                                  final uname    = usernameCtrl.text.trim();
                                  final mail     = emailCtrl.text.trim();

                                  if (first.isEmpty || last.isEmpty || uname.isEmpty || mail.isEmpty) {
                                    setS(() => error = 'All fields are required.');
                                    return;
                                  }
                                  if (!mail.contains('@')) {
                                    setS(() => error = 'Please enter a valid email address.');
                                    return;
                                  }

                                  setS(() { loading = true; error = null; });
                                  try {
                                    await createAdminUser(firstName: first, lastName: last, username: uname, email: mail);
                                    setS(() { loading = false; success = true; });
                                  } catch (e) {
                                    setS(() { loading = false; error = e.toString(); });
                                  }
                                },
                              ),
                            ),
                          ]),
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
    final users = _filtered;
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [cRed, cRedDark]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.people_outline_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('User Management', style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.4)),
            if (!isMobile) const Text('View, warn, ban, or delete users', style: TextStyle(fontSize: 12, color: cMuted)),
          ])),
          GestureDetector(
            onTap: _openCreateAdminDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [cNavBg, cNavBgDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 15),
                const SizedBox(width: 6),
                Text(isMobile ? 'New Admin' : 'Create Admin', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        _SearchField(hint: 'Search users...', onChanged: (v) => setState(() => _q = v)),
      ])),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            for (final f in ['All', 'Student', 'Faculty', 'Warned', 'Banned'])
              Padding(padding: const EdgeInsets.only(right: 6), child: _Chip(label: f, selected: _roleFilter == f, onTap: () => setState(() => _roleFilter = f))),
          ])),
        ),
      ),
      Expanded(
        child: users.isEmpty
            ? const _AdminEmptyState(message: 'No users found', icon: Icons.people_outline_rounded)
            : ListView.builder(primary: false, padding: const EdgeInsets.all(12), itemCount: users.length, itemBuilder: (_, i) {
                final u = users[i];
                return InkWell(
                  onTap: () => _openDetail(u), borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: u.isBanned ? const Color(0xFFFFF0F0) : u.hasWarning ? const Color(0xFFFFFBF0) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: u.isBanned ? cRedDark.withValues(alpha: 0.3) : u.hasWarning ? const Color(0xFFFFE082) : cBorder),
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        backgroundColor: u.isBanned ? cRedDark : u.hasWarning ? const Color(0xFFFFF3E0) : cRedLight, radius: 20,
                        child: Text(u.username.isNotEmpty ? u.username[0].toUpperCase() : 'U', style: TextStyle(color: u.isBanned ? Colors.white : u.hasWarning ? const Color(0xFFE67E22) : cRed, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('@${u.username}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cText)),
                        Text(u.email, style: const TextStyle(fontSize: 11, color: cMuted)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        _AdminBadge(label: u.isBanned ? 'BANNED' : u.role.label.toUpperCase(), color: u.isBanned ? cRedDark : u.role == UserRole.fac ? const Color(0xFF2980B9) : cMuted),
                        if (u.hasWarning && !u.isBanned) ...[const SizedBox(height: 4), const _AdminBadge(label: 'WARNED', color: Color(0xFFE67E22))],
                        const SizedBox(height: 4),
                        Text('${u.listingCount} listings', style: const TextStyle(fontSize: 11, color: cMuted)),
                      ]),
                    ]),
                  ),
                );
              }),
      ),
    ]);
  }
}

String _lastActiveLabel(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  final dateStr = formatDate(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago · $dateStr';
  if (diff.inHours < 24)   return '${diff.inHours}h ago · $dateStr';
  if (diff.inDays == 1)    return 'Yesterday · $dateStr';
  if (diff.inDays < 30)    return '${diff.inDays} days ago · $dateStr';
  if (diff.inDays < 365)   return '${(diff.inDays / 30).floor()} months ago · $dateStr';
  return '${(diff.inDays / 365).floor()} year(s) ago · $dateStr';
}

class _UserInfoRow extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _UserInfoRow({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Text(label, style: const TextStyle(fontSize: 12, color: cMuted, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: highlight ? cRedDark : cText)),
      ]),
    );
  }
}

// ─── Admin form field helper ──────────────────────────────────────────────────
class _AdminFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final TextInputType? keyboardType;
  const _AdminFormField({required this.controller, required this.label, required this.hint, required this.icon, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cText, letterSpacing: 0.3)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
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
    ]);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// REPORTS PANEL
// ═════════════════════════════════════════════════════════════════════════════

class _AdminReportsPanel extends StatefulWidget {
  final List<AdminReport> reports;
  final List<BugReport> bugReports;
  final List<AdminUser> users;
  final List<PendingListing> allListings;
  final List<AdminLostFoundItem> allLFItems;
  final VoidCallback onRefresh;
  const _AdminReportsPanel({
    required this.reports, required this.bugReports, required this.users,
    required this.allListings, required this.allLFItems, required this.onRefresh,
  });

  @override
  State<_AdminReportsPanel> createState() => _AdminReportsPanelState();
}

class _AdminReportsPanelState extends State<_AdminReportsPanel> {
  bool _showResolved = false;
  bool _showBugs = false;
  AdminReport? _selected;
  bool _loading = false;
  String? _error;

  List<AdminReport> get _filtered =>
      widget.reports.where((r) => r.isResolved == _showResolved).toList();

  Map<String, dynamic>? _findListing(String listingId, bool isLostFound) {
    if (isLostFound) {
      for (final item in widget.allLFItems) {
        if (item.id == listingId) {
          return {'title': item.title, 'description': item.description, 'category': item.category, 'location': item.location, 'image': item.image, 'status': item.status, 'seller_username': item.posterUsername, 'price': ''};
        }
      }
    } else {
      for (final item in widget.allListings) {
        if (item.id == listingId) {
          return {'title': item.title, 'description': item.description, 'category': item.category, 'location': item.location, 'image': item.image, 'status': item.type, 'seller_username': item.sellerUsername, 'price': item.price > 0 ? item.price.toStringAsFixed(2) : ''};
        }
      }
    }
    return null;
  }

  AdminUser? _findUser(AdminReport report) {
    AdminUser? user = widget.users.cast<AdminUser?>().firstWhere(
      (u) => u?.email == report.targetId || u?.id.toString() == report.targetId,
      orElse: () => null,
    );
    if (user != null) return user;
    final isLostFound = report.targetType == 'lostfound';
    if (report.targetType == 'listing' || isLostFound) {
      if (isLostFound) {
        for (final item in widget.allLFItems) {
          if (item.id == report.targetId) {
            return widget.users.cast<AdminUser?>().firstWhere(
              (u) => u?.email.toLowerCase() == item.posterEmail.toLowerCase() || u?.username.toLowerCase() == item.posterUsername.toLowerCase(),
              orElse: () => null,
            );
          }
        }
      } else {
        for (final item in widget.allListings) {
          if (item.id == report.targetId) {
            return widget.users.cast<AdminUser?>().firstWhere(
              (u) => u?.email.toLowerCase() == item.sellerEmail.toLowerCase() || u?.username.toLowerCase() == item.sellerUsername.toLowerCase(),
              orElse: () => null,
            );
          }
        }
      }
    }
    return null;
  }

  Future<void> _doAction(Future<void> Function() action) async {
    setState(() { _loading = true; _error = null; });
    try {
      await action();
      setState(() { _selected = null; _loading = false; });
      widget.onRefresh();
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _openDetailPopup(AdminReport r) {
    setState(() { _selected = r; _error = null; });
    showGeneralDialog(
      context: context, barrierDismissible: true, barrierLabel: 'Report',
      barrierColor: Colors.black.withValues(alpha: 0.45), transitionDuration: kMid,
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) => Opacity(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut).value,
        child: Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
            child: Container(
              margin: const EdgeInsets.all(16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: cBorder)),
              child: Material(color: Colors.transparent, child: Column(mainAxisSize: MainAxisSize.min, children: [
                Align(alignment: Alignment.topRight, child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))),
                Expanded(child: _ReportDetailPane(
                  key: ValueKey(r.id),
                  report: r,
                  listingDetails: _findListing(r.targetId, r.targetType == 'lostfound'),
                  targetUser: _findUser(r),
                  loading: _loading,
                  error: _error,
                  onAction: (action) async {
                    await _doAction(action);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                )),
              ])),
            ),
          ),
        ),
      ),
    );
  }

  Widget _reportCard(AdminReport r, {bool isSelected = false}) {
    final typeColor = {'listing': cRed, 'user': const Color(0xFF2980B9), 'lostfound': const Color(0xFF27AE60)}[r.targetType] ?? cMuted;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? cRed.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? cRed.withValues(alpha: 0.4) : cBorder, width: isSelected ? 1.5 : 1),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(r.targetType.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: typeColor, letterSpacing: 0.5))),
            const SizedBox(width: 5),
            Expanded(child: Text(r.reason.label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: cMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 4),
          Text(r.targetTitle, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? cRed : cText), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(formatDate(r.reportedAt), style: const TextStyle(fontSize: 10, color: cMuted)),
        ])),
        if (!r.isResolved) Container(width: 6, height: 6, margin: const EdgeInsets.only(left: 8), decoration: const BoxDecoration(color: cRed, shape: BoxShape.circle)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = _filtered;
    final selected = _selected;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [cRed, cRedDark]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Icon(
                _showBugs ? Icons.bug_report_outlined : Icons.flag_rounded,
                color: Colors.white, size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Reports & Flags', style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.4)),
              if (!isMobile) const Text('User-submitted reports and bug reports', style: TextStyle(fontSize: 12, color: cMuted)),
            ]),
          ]),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(children: [
          _Chip(label: 'User Reports', selected: !_showBugs, onTap: () => setState(() { _showBugs = false; _selected = null; })),
          const SizedBox(width: 8),
          _Chip(label: 'Bug Reports (${widget.bugReports.length})', selected: _showBugs, onTap: () => setState(() { _showBugs = true; _selected = null; })),
        ]),
      ),
      if (!_showBugs) Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(children: [
          _Chip(label: 'Open (${widget.reports.where((r) => !r.isResolved).length})', selected: !_showResolved, onTap: () => setState(() { _showResolved = false; _selected = null; })),
          const SizedBox(width: 8),
          _Chip(label: 'Resolved (${widget.reports.where((r) => r.isResolved).length})', selected: _showResolved, onTap: () => setState(() { _showResolved = true; _selected = null; })),
        ]),
      ),
      Expanded(
        child: _showBugs
            ? _BugReportsView(bugReports: widget.bugReports)
            : isMobile
                ? reports.isEmpty
                    ? _AdminEmptyState(message: _showResolved ? 'No resolved reports' : 'No open reports', icon: Icons.flag_outlined)
                    : ListView.builder(
                        primary: false,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: reports.length,
                        itemBuilder: (_, i) => GestureDetector(onTap: () => _openDetailPopup(reports[i]), child: _reportCard(reports[i])),
                      )
                : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: 300,
                      child: reports.isEmpty
                          ? _AdminEmptyState(message: _showResolved ? 'No resolved reports' : 'No open reports', icon: Icons.flag_outlined)
                          : ListView.builder(
                              primary: false,
                              padding: const EdgeInsets.fromLTRB(12, 0, 6, 12),
                              itemCount: reports.length,
                              itemBuilder: (_, i) => GestureDetector(
                                onTap: () => setState(() { _selected = reports[i]; _error = null; }),
                                child: _reportCard(reports[i], isSelected: selected?.id == reports[i].id),
                              ),
                            ),
                    ),
                    Container(width: 1, color: cBorder),
                    Expanded(
                      child: selected == null
                          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Container(width: 56, height: 56, decoration: const BoxDecoration(color: cRedLight, shape: BoxShape.circle), child: const Icon(Icons.flag_outlined, color: cRed, size: 24)),
                              const SizedBox(height: 12),
                              const Text('Select a report', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cMuted)),
                              const SizedBox(height: 4),
                              const Text('Choose a report from the left to review it', style: TextStyle(fontSize: 12, color: cMuted)),
                            ]))
                          : _ReportDetailPane(
                              key: ValueKey(selected.id),
                              report: selected,
                              listingDetails: _findListing(selected.targetId, selected.targetType == 'lostfound'),
                              targetUser: _findUser(selected),
                              loading: _loading,
                              error: _error,
                              onAction: _doAction,
                            ),
                    ),
                  ]),
      ),
    ]);
  }
}

// ── Bug Reports View ─────────────────────────────────────────────────────────

class _BugReportsView extends StatelessWidget {
  final List<BugReport> bugReports;
  const _BugReportsView({required this.bugReports});

  static const _catColor = <String, Color>{
    'UI/UX':       Color(0xFF7C3AED),
    'Performance': Color(0xFFD97706),
    'Crash':       Color(0xFFDC2626),
    'Feature':     Color(0xFF2563EB),
    'Security':    Color(0xFF059669),
    'Other':       Color(0xFF6B7280),
  };

  static const _catBg = <String, Color>{
    'UI/UX':       Color(0xFFF5F3FF),
    'Performance': Color(0xFFFFFBEB),
    'Crash':       Color(0xFFFEF2F2),
    'Feature':     Color(0xFFEFF6FF),
    'Security':    Color(0xFFF0FDF4),
    'Other':       Color(0xFFF3F4F6),
  };

  @override
  Widget build(BuildContext context) {
    if (bugReports.isEmpty) {
      return const _AdminEmptyState(message: 'No bug reports submitted', icon: Icons.bug_report_outlined);
    }
    return ListView.builder(
      primary: false,
      padding: const EdgeInsets.all(12),
      itemCount: bugReports.length,
      itemBuilder: (_, i) {
        final bug     = bugReports[i];
        final color   = _catColor[bug.category] ?? const Color(0xFF6B7280);
        final bgColor = _catBg[bug.category]    ?? const Color(0xFFF3F4F6);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cBorder),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              leading: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.bug_report_outlined, size: 18, color: color),
              ),
              title: Text(bug.category, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
              subtitle: Text(bug.email, style: const TextStyle(fontSize: 11, color: cMuted)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(formatDate(bug.createdAt), style: const TextStyle(fontSize: 10, color: cMuted)),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more_rounded, color: cMuted, size: 18),
              ]),
              children: [
                const Divider(height: 1, color: cBorder),
                const SizedBox(height: 12),
                _BugField(label: 'Description', value: bug.description),
                if (bug.steps.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _BugField(label: 'Steps to Reproduce', value: bug.steps),
                ],
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.person_outline_rounded, size: 13, color: cMuted),
                  const SizedBox(width: 5),
                  Text('User ID: ${bug.userId}', style: const TextStyle(fontSize: 11, color: cMuted)),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time_rounded, size: 13, color: cMuted),
                  const SizedBox(width: 5),
                  Text(formatDate(bug.createdAt), style: const TextStyle(fontSize: 11, color: cMuted)),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BugField extends StatelessWidget {
  final String label, value;
  const _BugField({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: cMuted, letterSpacing: 0.3)),
      const SizedBox(height: 4),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: cBorder)),
        child: Text(value, style: const TextStyle(fontSize: 13, color: cText, height: 1.5)),
      ),
    ]);
  }
}

class _ReportDetailPane extends StatelessWidget {
  final AdminReport report;
  final Map<String, dynamic>? listingDetails;
  final AdminUser? targetUser;
  final bool loading;
  final String? error;
  final Future<void> Function(Future<void> Function()) onAction;

  const _ReportDetailPane({super.key, required this.report, required this.listingDetails, required this.targetUser, required this.loading, required this.error, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final isLostFound = report.targetType == 'lostfound';
    final typeColor = {'listing': cRed, 'user': const Color(0xFF2980B9), 'lostfound': const Color(0xFF27AE60)}[report.targetType] ?? cMuted;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 6, runSpacing: 4, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(report.targetType.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: typeColor))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFF8E44AD).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(report.reason.label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF8E44AD)))),
              if (report.isResolved) const _AdminBadge(label: 'RESOLVED', color: Color(0xFF27AE60)),
            ]),
            const SizedBox(height: 8),
            Text(report.targetTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cText)),
            const SizedBox(height: 4),
            Text('Reported by: ${report.reporterEmail} · ${formatDate(report.reportedAt)}', style: const TextStyle(fontSize: 11, color: cMuted)),
            if (report.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(8)), child: Text(report.notes, style: const TextStyle(fontSize: 12, color: cText, height: 1.5))),
            ],
          ]),
        ),
        const SizedBox(height: 12),
        if (report.targetType == 'listing' || report.targetType == 'lostfound') ...[
          const _AdminLabel('Reported Content'),
          const SizedBox(height: 8),
          if (listingDetails == null)
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: cBorder)), child: const Row(children: [Icon(Icons.info_outline_rounded, size: 14, color: cMuted), SizedBox(width: 8), Expanded(child: Text('Listing may have already been removed.', style: TextStyle(fontSize: 12, color: cMuted)))]))
          else
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
              clipBehavior: Clip.antiAlias,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if ((listingDetails!['image']?.toString() ?? '').isNotEmpty)
                  Image.network(listingDetails!['image'].toString(), width: 90, height: 90, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 90, height: 90, color: cPlaceholder, child: const Icon(Icons.image_not_supported, color: cMuted))),
                Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(listingDetails!['title']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cText)),
                  const SizedBox(height: 3),
                  Text(listingDetails!['description']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: cMuted, height: 1.4)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    if ((listingDetails!['price']?.toString() ?? '') != '' && listingDetails!['price'] != '0') _AdminBadge(label: '\$${listingDetails!['price']}', color: cRed),
                    if ((listingDetails!['category']?.toString() ?? '').isNotEmpty) _AdminBadge(label: listingDetails!['category'].toString(), color: cMuted),
                    _AdminBadge(label: (listingDetails!['status']?.toString() ?? '').toUpperCase(), color: typeColor),
                  ]),
                  const SizedBox(height: 4),
                  Text('By: ${listingDetails!['seller_username'] ?? 'Unknown'}', style: const TextStyle(fontSize: 10, color: cMuted)),
                ]))),
              ]),
            ),
          const SizedBox(height: 12),
        ],
        if (targetUser != null) ...[
          const _AdminLabel('Reported User'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
            child: Row(children: [
              CircleAvatar(backgroundColor: cRedLight, radius: 18, child: Text(targetUser!.username.isNotEmpty ? targetUser!.username[0].toUpperCase() : 'U', style: const TextStyle(color: cRed, fontWeight: FontWeight.w900))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('@${targetUser!.username}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cText)),
                Text(targetUser!.email, style: const TextStyle(fontSize: 11, color: cMuted)),
              ])),
              if (targetUser!.isBanned) const _AdminBadge(label: 'BANNED', color: cRed)
              else if (targetUser!.hasWarning) const _AdminBadge(label: 'WARNED', color: Color(0xFFE67E22))
              else _AdminBadge(label: targetUser!.role.label.toUpperCase(), color: cMuted),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        if (!report.isResolved) ...[
          const _AdminLabel('Actions'),
          const SizedBox(height: 8),
          if (error != null) ...[
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: cRed.withValues(alpha: 0.3))), child: Row(children: [const Icon(Icons.error_outline_rounded, size: 14, color: cRed), const SizedBox(width: 8), Expanded(child: Text(error!, style: const TextStyle(color: cRedDark, fontSize: 12)))])),
            const SizedBox(height: 8),
          ],
          if (report.targetType == 'listing' || report.targetType == 'lostfound') ...[
            _ActionButton(icon: Icons.remove_circle_outline_rounded, label: 'Remove Listing & Notify User', bgColor: const Color(0xFFFFF0F0), borderColor: cRed.withValues(alpha: 0.3), iconColor: cRed, textColor: cRedDark, loading: loading, onTap: () => onAction(() async { await adminRemoveListing(listingId: report.targetId, isLostFound: isLostFound); await adminResolveReport(reportId: report.id); })),
            const SizedBox(height: 6),
            if (targetUser != null && !targetUser!.hasWarning) ...[
              _ActionButton(icon: Icons.warning_amber_rounded, label: 'Remove Listing & Issue Warning', bgColor: const Color(0xFFFFF8EC), borderColor: const Color(0xFFE67E22).withValues(alpha: 0.35), iconColor: const Color(0xFFE67E22), textColor: const Color(0xFF92400E), loading: loading, onTap: () => onAction(() async { await adminRemoveListing(listingId: report.targetId, isLostFound: isLostFound); await adminIssueWarning(userId: targetUser!.id, email: targetUser!.email); await adminResolveReport(reportId: report.id); })),
              const SizedBox(height: 6),
            ],
            if (targetUser != null) ...[
              _ActionButton(
                icon: Icons.gavel_rounded,
                label: 'Remove Listing & Ban User',
                bgColor: const Color(0xFFFEF2F2),
                borderColor: Colors.red.shade900.withValues(alpha: 0.3),
                iconColor: Colors.red.shade900,
                textColor: Colors.red.shade900,
                loading: loading,
                onTap: () {
                  if (!targetUser!.hasWarning) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Cannot Ban User', style: TextStyle(fontWeight: FontWeight.w800)),
                        content: const Text('A warning must be issued to this user before they can be permanently banned.', style: TextStyle(color: cMuted)),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: cRed, fontWeight: FontWeight.w700)))],
                      ),
                    );
                    return;
                  }
                  onAction(() async { await adminRemoveListing(listingId: report.targetId, isLostFound: isLostFound); await adminBanUser(userId: targetUser!.id, email: targetUser!.email); await adminResolveReport(reportId: report.id); });
                },
              ),
              const SizedBox(height: 6),
            ],
          ],
          if (report.targetType == 'user') ...[
            if (targetUser != null && !targetUser!.isBanned && !targetUser!.hasWarning) ...[
              _ActionButton(icon: Icons.warning_amber_rounded, label: 'Issue Warning', bgColor: const Color(0xFFFFF8EC), borderColor: const Color(0xFFE67E22).withValues(alpha: 0.35), iconColor: const Color(0xFFE67E22), textColor: const Color(0xFF92400E), loading: loading, onTap: () => onAction(() async { await adminIssueWarning(userId: targetUser!.id, email: targetUser!.email); await adminResolveReport(reportId: report.id); })),
              const SizedBox(height: 6),
            ],
            if (targetUser != null) ...[
              _ActionButton(
                icon: Icons.block_rounded,
                label: 'Ban User',
                bgColor: const Color(0xFFFEF2F2),
                borderColor: Colors.red.shade900.withValues(alpha: 0.3),
                iconColor: Colors.red.shade900,
                textColor: Colors.red.shade900,
                loading: loading,
                onTap: () {
                  if (!targetUser!.hasWarning) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Cannot Ban User', style: TextStyle(fontWeight: FontWeight.w800)),
                        content: const Text('A warning must be issued to this user before they can be permanently banned.', style: TextStyle(color: cMuted)),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: cRed, fontWeight: FontWeight.w700)))],
                      ),
                    );
                    return;
                  }
                  onAction(() async { await adminBanUser(userId: targetUser!.id, email: targetUser!.email); await adminResolveReport(reportId: report.id); });
                },
              ),
              const SizedBox(height: 6),
            ],
          ],
          _ActionButton(icon: Icons.check_circle_outline_rounded, label: 'Dismiss (No Action)', bgColor: const Color(0xFFF0FDF4), borderColor: const Color(0xFF27AE60).withValues(alpha: 0.35), iconColor: const Color(0xFF27AE60), textColor: const Color(0xFF166534), loading: loading, onTap: () => onAction(() => adminResolveReport(reportId: report.id))),
        ],
        if (report.isResolved)
          Container(
            width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF27AE60).withValues(alpha: 0.3))),
            child: const Row(children: [Icon(Icons.check_circle_rounded, color: Color(0xFF27AE60), size: 16), SizedBox(width: 8), Text('This report has been resolved.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF166534)))]),
          ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARED ADMIN WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _AdminEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  const _AdminEmptyState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 64, height: 64, decoration: BoxDecoration(color: cRedLight, shape: BoxShape.circle), child: Icon(icon, color: cRed, size: 28)),
      const SizedBox(height: 12),
      Text(message, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cMuted)),
    ]));
  }
}

class _AdminLabel extends StatelessWidget {
  final String label;
  const _AdminLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cText, letterSpacing: 0.3));
}

class _AdminBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _AdminBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String title, subtitle, date;
  final IconData icon;
  const _HistoryTile({required this.title, required this.subtitle, required this.date, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: cBorder)),
      child: Row(children: [
        Icon(icon, size: 16, color: cRed),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cText)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: cMuted)),
        ])),
        Text(date.length >= 10 ? date.substring(0, 10) : date, style: const TextStyle(fontSize: 11, color: cMuted)),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// REPORT DIALOG — user-facing
// ═════════════════════════════════════════════════════════════════════════════

Future<void> showReportDialog({
  required BuildContext context,
  required String targetId,
  required String targetType,
  required String targetTitle,
  required String reporterEmail,
}) async {
  ReportReason? selectedReason;
  final notesCtrl = TextEditingController();
  bool loading = false; String? error;

  await showGeneralDialog(
    context: context, barrierDismissible: true, barrierLabel: 'Report',
    barrierColor: Colors.black.withValues(alpha: 0.35), transitionDuration: kMid,
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, __, ___) => Opacity(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut).value,
      child: StatefulBuilder(builder: (ctx, setS) => Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: cBorder),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 8))]),
            child: Material(color: Colors.transparent, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.flag_rounded, color: cRed, size: 18)),
                const SizedBox(width: 12),
                const Text('Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cText)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ]),
              const SizedBox(height: 4),
              Text('Reporting: $targetTitle', style: const TextStyle(fontSize: 12, color: cMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              DropdownButtonFormField<ReportReason>(
                value: selectedReason, hint: const Text('Select a reason *'),
                decoration: InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cRed, width: 2)),
                  filled: true, fillColor: cBg,
                ),
                items: ReportReason.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label))).toList(),
                onChanged: (v) => setS(() => selectedReason = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesCtrl, maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Additional notes (optional)', hintText: 'Describe the issue...', hintStyle: const TextStyle(color: cMuted, fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cRed, width: 2)),
                  filled: true, fillColor: cBg,
                ),
              ),
              if (error != null) ...[const SizedBox(height: 8), Text(error!, style: const TextStyle(color: cRedDark, fontSize: 12))],
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                icon: loading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded, size: 16),
                label: const Text('Submit Report'),
                style: ElevatedButton.styleFrom(backgroundColor: cRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: loading ? null : () async {
                  if (selectedReason == null) { setS(() => error = 'Please select a reason.'); return; }
                  setS(() { loading = true; error = null; });
                  try {
                    await submitReport(targetId: targetId, targetType: targetType, targetTitle: targetTitle, reporterEmail: reporterEmail, reason: selectedReason!.name, notes: notesCtrl.text.trim());
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: const Row(children: [Icon(Icons.check_circle_rounded, color: Colors.white, size: 16), SizedBox(width: 8), Text('Report submitted. Thank you.')]),
                        backgroundColor: cRed, behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(12),
                      ));
                    }
                  } catch (e) { setS(() { loading = false; error = e.toString(); }); }
                },
              )),
            ])),
          ),
        ),
      )),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// ADMIN PROFILE TAB
// ═════════════════════════════════════════════════════════════════════════════

class _AdminProfileTab extends StatefulWidget {
  final String adminEmail, adminUsername;
  final VoidCallback onLogout;
  const _AdminProfileTab({required this.adminEmail, required this.adminUsername, required this.onLogout});

  @override
  State<_AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<_AdminProfileTab> {
  Uint8List? _avatarBytes;
  late String _localUsername;

  @override
  void initState() {
    super.initState();
    _localUsername = widget.adminUsername;
  }

  String get _initials {
    if (_localUsername.isNotEmpty) return _localUsername[0].toUpperCase();
    if (widget.adminEmail.isNotEmpty) return widget.adminEmail[0].toUpperCase();
    return 'A';
  }

  Future<void> _showAvatarOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: cSurface,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: cBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Profile Picture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cText)),
            const SizedBox(height: 4),
            const Text('Choose how to set your avatar', style: TextStyle(fontSize: 12, color: cMuted)),
            const SizedBox(height: 16),
            _BottomSheetOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 400);
                if (picked == null) return;
                final bytes = await picked.readAsBytes();
                if (mounted) setState(() => _avatarBytes = bytes);
              },
            ),
            const SizedBox(height: 8),
            _BottomSheetOption(
              icon: Icons.camera_alt_outlined,
              label: 'Take a Photo',
              onTap: () async {
                Navigator.pop(ctx);
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 400);
                if (picked == null) return;
                final bytes = await picked.readAsBytes();
                if (mounted) setState(() => _avatarBytes = bytes);
              },
            ),
            if (_avatarBytes != null) ...[
              const SizedBox(height: 8),
              _BottomSheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'Remove Photo',
                isDestructive: true,
                onTap: () { Navigator.pop(ctx); setState(() => _avatarBytes = null); },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Hero card ──
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [cNavBgDark, Color(0xFF3A0808)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Row(children: [
            GestureDetector(
              onTap: _showAvatarOptions,
              child: Stack(children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2.5)),
                  child: ClipOval(
                    child: _avatarBytes != null
                        ? Image.memory(_avatarBytes!, fit: BoxFit.cover, width: 72, height: 72)
                        : Center(child: Text(_initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white))),
                  ),
                ),
                Positioned(bottom: 0, right: 0, child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(color: cRed, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                  child: const Icon(Icons.camera_alt_rounded, size: 11, color: Colors.white),
                )),
              ]),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_localUsername, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3)),
              const SizedBox(height: 4),
              Text(widget.adminEmail, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.admin_panel_settings_rounded, size: 11, color: Colors.white),
                  SizedBox(width: 5),
                  Text('Administrator', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                ]),
              ),
            ])),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: GestureDetector(
            onTap: _showAvatarOptions,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.edit_outlined, size: 12, color: cMuted),
              const SizedBox(width: 4),
              Text(_avatarBytes != null ? 'Change profile picture' : 'Add a profile picture', style: const TextStyle(fontSize: 13, color: cMuted, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),

        const SizedBox(height: 20),

        // ── Account ──
        _ProfileSectionHeader(label: 'Account'),
        const SizedBox(height: 8),
        _ProfileInfoTile(icon: Icons.person_outline_rounded, label: 'Username', value: _localUsername),
        _ProfileInfoTile(icon: Icons.mail_outline_rounded, label: 'Email', value: widget.adminEmail),
        _ProfileInfoTile(icon: Icons.admin_panel_settings_rounded, label: 'Role', value: 'Administrator'),

        const SizedBox(height: 20),

        // ── Security ──
        _ProfileSectionHeader(label: 'Security'),
        const SizedBox(height: 8),
        _ProfileActionTile(
          icon: Icons.lock_reset_rounded,
          label: 'Change Password',
          subtitle: 'Update your admin account password',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChangePasswordScreen())),
        ),
        _ProfileActionTile(
          icon: Icons.drive_file_rename_outline_rounded,
          label: 'Change Username',
          subtitle: 'Update your display name',
          onTap: () async {
            final newUsername = await Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => ChangeUsernameScreen(email: widget.adminEmail)));
            if (newUsername != null) setState(() => _localUsername = newUsername);
          },
        ),

        const SizedBox(height: 20),

        // ── Help ──
        _ProfileSectionHeader(label: 'Help & Docs'),
        const SizedBox(height: 8),
        _ProfileActionTile(icon: Icons.menu_book_outlined, label: 'Documentation', subtitle: 'How to use UniFind', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DocumentationScreen()))),
        _ProfileActionTile(icon: Icons.gavel_rounded, label: 'Terms & Conditions', subtitle: 'Usage policy and community rules', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen()))),
        _ProfileActionTile(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', subtitle: 'How we handle your data', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen(initialTab: 1)))),

        const SizedBox(height: 20),

        // ── Session ──
        _ProfileSectionHeader(label: 'Session'),
        const SizedBox(height: 8),
        _ProfileActionTile(
          icon: Icons.logout_rounded,
          label: 'Log Out',
          subtitle: 'Sign out of your admin account',
          isDestructive: true,
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w800)),
                content: const Text('Are you sure you want to sign out of the admin panel?', style: TextStyle(color: cMuted)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log Out', style: TextStyle(color: cRedDark, fontWeight: FontWeight.w700))),
                ],
              ),
            );
            if (confirm == true) widget.onLogout();
          },
        ),

        const SizedBox(height: 32),
        const Center(child: Text('© 2026 UniFind · Montclair State University', style: TextStyle(fontSize: 11, color: cMuted))),
        const SizedBox(height: 16),
      ],
    );
  }
}

