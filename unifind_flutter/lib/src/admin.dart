part of '../main.dart';

// ─── ADMIN DATA MODELS ────────────────────────────────────────────────────────

enum AdminTab { dashboard, listings, lostFound, users, reports }

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

// ═════════════════════════════════════════════════════════════════════════════
// AUTH WRAPPER
// ═════════════════════════════════════════════════════════════════════════════

class RoleAuthWrapper extends StatelessWidget {
  final UserRole role;
  final String email, username;
  final int? userId;
  final VoidCallback onLogout;
  final List<MarketplaceItem> market;
  final List<LostFoundItem> lostFound;
  final int tab, postFormNonce;
  final ListingType postDefaultType;
  final Set<String> submittedClaimItemIds, submittedMatchItemIds;
  final void Function([ListingType]) goToPostTab;
  final Future<void> Function(NewListingInput) addListing;
  final Future<void> Function(LostFoundItem, ClaimEvidence) claimLostItem;
  final Future<void> Function(LostFoundItem, FoundMatchInput) postFoundMatch;
  final Future<void> Function(MarketplaceItem, MarketplaceUpdateInput) editMarketplace;
  final Future<void> Function(LostFoundItem, LostFoundUpdateInput) editLostFound;
  final void Function(int) onTabChanged;

  const RoleAuthWrapper({
    super.key,
    required this.role, required this.email, required this.username,
    required this.userId, required this.onLogout,
    required this.market, required this.lostFound,
    required this.tab, required this.postFormNonce, required this.postDefaultType,
    required this.submittedClaimItemIds, required this.submittedMatchItemIds,
    required this.goToPostTab, required this.addListing,
    required this.claimLostItem, required this.postFoundMatch,
    required this.editMarketplace, required this.editLostFound,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (role == UserRole.admin) {
      return AdminApp(adminEmail: email, adminUsername: username, onLogout: onLogout);
    }
    return _StandardUserShell(
      email: email, username: username, userId: userId, role: role,
      onLogout: onLogout, market: market, lostFound: lostFound,
      tab: tab, postFormNonce: postFormNonce, postDefaultType: postDefaultType,
      submittedClaimItemIds: submittedClaimItemIds, submittedMatchItemIds: submittedMatchItemIds,
      goToPostTab: goToPostTab, addListing: addListing,
      claimLostItem: claimLostItem, postFoundMatch: postFoundMatch,
      editMarketplace: editMarketplace, editLostFound: editLostFound,
      onTabChanged: onTabChanged,
    );
  }
}

class _StandardUserShell extends StatelessWidget {
  final String email, username;
  final int? userId;
  final UserRole role;
  final VoidCallback onLogout;
  final List<MarketplaceItem> market;
  final List<LostFoundItem> lostFound;
  final int tab, postFormNonce;
  final ListingType postDefaultType;
  final Set<String> submittedClaimItemIds, submittedMatchItemIds;
  final void Function([ListingType]) goToPostTab;
  final Future<void> Function(NewListingInput) addListing;
  final Future<void> Function(LostFoundItem, ClaimEvidence) claimLostItem;
  final Future<void> Function(LostFoundItem, FoundMatchInput) postFoundMatch;
  final Future<void> Function(MarketplaceItem, MarketplaceUpdateInput) editMarketplace;
  final Future<void> Function(LostFoundItem, LostFoundUpdateInput) editLostFound;
  final void Function(int) onTabChanged;

  const _StandardUserShell({
    required this.email, required this.username, required this.userId,
    required this.role, required this.onLogout,
    required this.market, required this.lostFound,
    required this.tab, required this.postFormNonce, required this.postDefaultType,
    required this.submittedClaimItemIds, required this.submittedMatchItemIds,
    required this.goToPostTab, required this.addListing,
    required this.claimLostItem, required this.postFoundMatch,
    required this.editMarketplace, required this.editLostFound,
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

// ═════════════════════════════════════════════════════════════════════════════
// Topnav items and helper functions
// ═════════════════════════════════════════════════════════════════════════════
  static const List<_TopNavItem> _userNavItems = [
    _TopNavItem(icon: Icons.storefront_outlined,    activeIcon: Icons.storefront_rounded,      label: 'Market',      tabIndex: 0),
    _TopNavItem(icon: Icons.search_outlined,         activeIcon: Icons.search_rounded,          label: 'Lost & Found',tabIndex: 1),
    _TopNavItem(icon: Icons.list_alt_outlined,       activeIcon: Icons.list_alt_rounded,        label: 'My Listings', tabIndex: 3),
    _TopNavItem(icon: Icons.chat_bubble_outline,     activeIcon: Icons.chat_bubble_rounded,     label: 'Messages',    tabIndex: 4),
    _TopNavItem(icon: Icons.person_outline_rounded,  activeIcon: Icons.person_rounded,          label: 'Profile',     tabIndex: 5),
  ];

  int _navIndexForTab(int tabIndex) {
    for (int i = 0; i < _userNavItems.length; i++) {
      if (_userNavItems[i].tabIndex == tabIndex) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final activeNavIndex = _navIndexForTab(tab);

    // Slots: 0=Market, 1=Lost&Found, 2=Post, 3=MyListings, 4=Messages, 5=Profile
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
      PostListingScreen(key: ValueKey(postFormNonce), onPost: addListing, initialType: postDefaultType),
      MyListingsScreen(
        marketplaceItems: market.where(_isMyMarketplaceItem).toList(),
        lostFoundItems: lostFound.where(_isMyLostFoundItem).toList(),
        onListItem: () => goToPostTab(),
        onEditMarketplace: editMarketplace,
        onEditLostFound: editLostFound,
      ),
      MessagingScreen(userId: userId ?? 0, userEmail: email),
      ProfileScreen(email: email, username: username, onLogout: onLogout, userId: userId),
    ];

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: cBg,
      appBar: isMobile
          // MOBILE: simple app bar with logo + logout
          ? AppBar(
              backgroundColor: cNavBg, foregroundColor: Colors.white, elevation: 0, centerTitle: true,
              title: Row(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('assets/images/whitelogo.png', height: 22, fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text('UniFind', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white))),
                if (role == UserRole.fac) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(5)),
                    child: const Text('FACULTY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8)),
                  ),
                ],
              ]),
              actions: [IconButton(tooltip: 'Log out', icon: const Icon(Icons.logout_rounded, size: 18), onPressed: onLogout)],
            )
          // DESKTOP: top nav bar with tabs
          : PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Container(
                color: cNavBg,
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: 80,
                    child: Stack(children: [
                      Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Image.asset('assets/images/whitelogo.png', height: 22, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Text('UniFind', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3))),
                          if (role == UserRole.fac) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(5)),
                              child: const Text('FACULTY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8)),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 4),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          for (int i = 0; i < _userNavItems.length; i++) ...[
                            _TopNavTab(item: _userNavItems[i], isActive: activeNavIndex == i, onTap: () => onTabChanged(_userNavItems[i].tabIndex)),
                            if (i == 1) ...[const SizedBox(width: 6), _NavPostButton(onTap: () => goToPostTab()), const SizedBox(width: 6)],
                          ],
                        ]),
                      ])),
                      Positioned(top: 0, right: 4, bottom: 0, child: Center(
                        child: IconButton(tooltip: 'Log out', icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white), onPressed: onLogout),
                      )),
                    ]),
                  ),
                ),
              ),
            ),
      body: IndexedStack(index: tab, children: screens),
      // MOBILE: bottom navigation bar
      bottomNavigationBar: isMobile
          ? Theme(
              data: Theme.of(context).copyWith(
                navigationBarTheme: NavigationBarThemeData(
                  labelTextStyle: WidgetStateProperty.all(
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              child: NavigationBar(
              selectedIndex: tab,
              backgroundColor: cNavBg,
              indicatorColor: Colors.white.withValues(alpha: 0.2),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: onTabChanged,
              destinations: [
                NavigationDestination(icon: const Icon(Icons.storefront_outlined, color: Colors.white70), selectedIcon: const Icon(Icons.storefront_rounded, color: Colors.white), label: 'Market'),
                NavigationDestination(icon: const Icon(Icons.search_outlined, color: Colors.white70), selectedIcon: const Icon(Icons.search_rounded, color: Colors.white), label: 'Lost/Found'),
                NavigationDestination(icon: const Icon(Icons.add_circle_outline, color: Colors.white70), selectedIcon: const Icon(Icons.add_circle_rounded, color: Colors.white), label: 'Post'),
                NavigationDestination(icon: const Icon(Icons.inventory_2_outlined, color: Colors.white70), selectedIcon: const Icon(Icons.inventory_2_rounded, color: Colors.white), label: 'Listings'),
                NavigationDestination(icon: const Icon(Icons.chat_bubble_outline, color: Colors.white70), selectedIcon: const Icon(Icons.chat_bubble_rounded, color: Colors.white), label: 'Messages'),
                NavigationDestination(icon: const Icon(Icons.person_outline_rounded, color: Colors.white70), selectedIcon: const Icon(Icons.person_rounded, color: Colors.white), label: 'Profile'),
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
    final l = m['lost_item'] as Map<String, dynamic>? ?? {};
    final f = m['found_item'] as Map<String, dynamic>? ?? {};
    return MatchedPair(
      matchId: _s(m['match_id'] ?? m['id']),
      status: _s(m['status']),
      createdAt: _d(m['created_at']),
      lostItem: _parseLFSide(l),
      foundItem: _parseLFSide(f),
    );
  }).toList();

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final r = await Future.wait([
        getAdminStats(), getAdminPendingListings(), getAdminActiveListings(),
        getAdminUsers(), getAdminReports(), getAdminLostFoundItems(),
        adminGetMatches(),
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
          pendingApprovals: int.tryParse(_s(rawStats['pending_approvals'])) ?? pending.length,
          newUsersThisWeek: int.tryParse(_s(rawStats['new_users_this_week'])) ?? 0,
          openReports: int.tryParse(_s(rawStats['open_reports'])) ?? reports.where((r) => !r.isResolved).length,
          recentActivity: activity,
        );
        _pending..clear()..addAll(pending);
        _active..clear()..addAll(active);
        _users..clear()..addAll(users);
        _reports..clear()..addAll(reports);
        _lf..clear()..addAll(lfItems);
        _matches..clear()..addAll(_parseMatches(rawMatches));
        _loading = false;
      });
    } catch (_) { if (mounted) setState(() => _loading = false); }
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
        backgroundColor: cNavBgDark, foregroundColor: Colors.white, elevation: 0, centerTitle: true,
        title: LayoutBuilder(builder: (ctx, c) {
          final compact = c.maxWidth < 280;
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.admin_panel_settings_rounded, size: 14, color: Colors.white),
                if (!compact) ...[
                  const SizedBox(width: 6),
                  const Text('ADMIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white)),
                ],
              ]),
            ),
            const SizedBox(width: 8),
            Flexible(child: Text(widget.adminUsername, style: const TextStyle(fontSize: 14, color: Colors.white70), overflow: TextOverflow.ellipsis)),
          ]);
        }),
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
              _AdminUsersPanel(users: _users, onRefresh: _loadAll),
              _AdminReportsPanel(reports: _reports, users: _users, allListings: [..._pending, ..._active], allLFItems: _lf, onRefresh: _loadAll),
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
            _dest(Icons.people_outline_rounded, 'Users'),
            _dest(Icons.flag_outlined, 'Reports', badge: _openReports > 0 ? '$_openReports' : null),
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

          // ── Hero Banner ──
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

          // ── Stat Cards ──
          const Text('   OVERVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: cMuted, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          // Mobile: 2x2 grid, Desktop: 4 in a row
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

          // ── Quick Actions (always shown) ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: cBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Quick Actions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cText)),
              const SizedBox(height: 12),
              _QuickAction(icon: Icons.pending_actions_rounded, iconBg: const Color.fromARGB(255, 254, 199, 199), iconColor: cRed, label: 'Pending Listings', sub: '${stats.pendingApprovals} submissions awaiting', onTap: () => onNavigate(AdminTab.listings, showActive: false)),
              _QuickAction(icon: Icons.storefront_rounded,      iconBg: const Color.fromARGB(255, 254, 236, 226), iconColor: const Color(0xFFD97706), label: 'Active Listings', sub: '${stats.totalActiveListings} live posts', onTap: () => onNavigate(AdminTab.listings, showActive: true)),
              _QuickAction(icon: Icons.flag_rounded,            iconBg: const Color.fromARGB(255, 254, 247, 226), iconColor: const Color.fromARGB(255, 161, 122, 39), label: 'Reports', sub: '${stats.openReports} reports need action', onTap: () => onNavigate(AdminTab.reports, showActive: false)),
              _QuickAction(icon: Icons.people_outline_rounded,  iconBg: const Color.fromARGB(255, 219, 254, 221), iconColor: const Color(0xFF16A34A), label: 'Users', sub: 'View, warn, or ban accounts', onTap: () => onNavigate(AdminTab.users, showActive: false)),
              _QuickAction(icon: Icons.search_rounded,          iconBg: const Color.fromARGB(255, 209, 227, 250), iconColor: const Color.fromARGB(255, 22, 83, 163), label: 'Lost & Found', sub: 'Review claims and matches', onTap: () => onNavigate(AdminTab.lostFound, showActive: false)),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Activity Feed ──
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
// end _AdminDashboard

class _QuickAction extends StatefulWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String label, sub;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.iconBg, required this.iconColor, required this.label, required this.sub, required this.onTap});

  @override
  State<_QuickAction> createState() => _QuickActionState();
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

// ── _StatCard widget ──
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
            boxShadow: []
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cBorder),
      ),
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
    final priceCtrl   = TextEditingController(text: listing.price > 0 ? listing.price.toStringAsFixed(0) : '');
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
          Text(_showActive ? 'Active Listings' : 'Pending Listings', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.4)),
          Text(_showActive ? 'All live marketplace listings' : 'Review, edit, approve or deny submissions', style: const TextStyle(fontSize: 12, color: cMuted)),
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
              if (listing.price > 0) ...[const SizedBox(width: 8), Text('\$${listing.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cRed))],
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

// Colors
const _cLost = Color(0xFFE74C3C);
const _cFound = Color(0xFF2980B9);
const _cGreen = Color(0xFF27AE60);
const _cOrange = Color(0xFFE67E22);

class _AdminLostFoundPanelState extends State<_AdminLostFoundPanel> {
  bool _showMatched = false; // false = Items view, true = Matched view
  String? _selectedLostId;
  String? _selectedFoundId;
  bool _creating = false;

  // ── View claims on an item ──
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
                    // ── Image header ──
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
                    // ── Content ──
                    Flexible(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.3)),
                      const SizedBox(height: 8),
                      // Info chips
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        _DetailChip(Icons.category_outlined, item.category),
                        _DetailChip(Icons.location_on_outlined, item.location),
                        _DetailChip(Icons.access_time_rounded, formatDate(item.createdAt)),
                      ]),
                      const SizedBox(height: 12),
                      // Description
                      Text(item.description, style: const TextStyle(fontSize: 13, color: cMuted, height: 1.55)),
                      const SizedBox(height: 16),
                      // ── Posted by ──
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
                      // ── Claims section ──
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
                                      if (ctx.mounted) Navigator.pop(ctx);
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
                      // ── Select for matching button ──
                      const SizedBox(height: 16),
                      Row(children: [
                        // Select for matching
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
                        const SizedBox(width: 10),
                        // Resolve directly
                        Expanded(child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await adminMarkLostFoundResolved(itemId: item.id);
                              if (ctx.mounted) Navigator.pop(ctx);
                              widget.onRefresh();
                            } catch (e) {
                              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                          label: const Text('Resolve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _cGreen, foregroundColor: Colors.white,
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

  // ── Create match ──
  Future<void> _createMatch() async {
    if (_selectedLostId == null || _selectedFoundId == null) return;
    setState(() => _creating = true);
    try {
      await adminCreateMatch(lostItemId: _selectedLostId!, foundItemId: _selectedFoundId!);
      setState(() { _selectedLostId = null; _selectedFoundId = null; _showMatched = true; });
      widget.onRefresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  // ── Unmatch ──
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

  // ── Resolve ──
  Future<void> _resolve(String matchId) async {
    try {
      await adminResolveMatch(matchId: matchId);
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
      // ── Header ──
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Lost & Found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.4)),
            Text(isMobile ? 'Tap to view, long-press to select' : 'Select one from each side, then match', style: const TextStyle(fontSize: 12, color: cMuted)),
          ])),
        ]),
      ),

      // ── Two-tab toggle: Items | Matched ──
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
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
        ]),
      ),

      // ═══════════════════════════════════════════════════════════
      // ITEMS VIEW — side by side (Lost | Found)
      // Only admin-approved (active) items appear here
      // ═══════════════════════════════════════════════════════════
      if (!_showMatched) ...[
        // Selection indicator
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

        // ── Side by side: Lost | Found ──
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Lost column
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
            // Found column
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

        // Match button (shows when both selected)
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

      // ═══════════════════════════════════════════════════════════
      // MATCHED VIEW — matched pairs with resolve / unmatch
      // ═══════════════════════════════════════════════════════════
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
                        // Pair images row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                          child: Row(children: [
                            // Lost side
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
                            // Arrow
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
                            // Found side
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
                        // Action buttons
                        if (!isResolved)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                            child: Row(children: [
                              Expanded(
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
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _resolve(pair.matchId),
                                  icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                                  label: const Text('Resolve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _cGreen, foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ]),
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
                          Text('Last Active: ${user.lastActive != null ? formatDate(user.lastActive!) : 'Never'}', style: const TextStyle(fontSize: 12, color: cMuted)),
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
    await showGeneralDialog(
      context: context, barrierDismissible: true, barrierLabel: 'User',
      barrierColor: Colors.black.withValues(alpha: 0.4), transitionDuration: kMid,
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) => Opacity(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut).value,
        child: StatefulBuilder(builder: (ctx, setS) => Center(
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
                  _UserInfoRow(label: 'Last Active',    value: user.lastActive != null ? formatDate(user.lastActive!) : 'Never'),
                  _UserInfoRow(label: 'Total Listings', value: '${user.listingCount}'),
                  _UserInfoRow(label: 'Email Verified', value: user.isVerified ? 'Yes' : 'No'),
                  _UserInfoRow(label: 'Warning Issued', value: user.hasWarning ? (user.warnedAt != null ? 'Yes · ${formatDate(user.warnedAt!)}' : 'Yes') : 'No', highlight: user.hasWarning),
                  _UserInfoRow(label: 'Status',         value: user.isBanned ? 'BANNED' : 'Active', highlight: user.isBanned),
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
                          final confirm = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(title: const Text('Revoke Warning?'), content: Text('This will remove the warning from @${user.username}\'s account.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Revoke', style: TextStyle(color: Color(0xFFE67E22))))]));
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
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = _filtered;
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('User Management', style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.4)),
        if (!isMobile) const Text('View, warn, ban, or delete users', style: TextStyle(fontSize: 12, color: cMuted)),
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
            ? _AdminEmptyState(message: 'No users found', icon: Icons.people_outline_rounded)
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

// ═════════════════════════════════════════════════════════════════════════════
// REPORTS PANEL
// ═════════════════════════════════════════════════════════════════════════════

class _AdminReportsPanel extends StatefulWidget {
  final List<AdminReport> reports;
  final List<AdminUser> users;
  final List<PendingListing> allListings;
  final List<AdminLostFoundItem> allLFItems;
  final VoidCallback onRefresh;
  const _AdminReportsPanel({
    required this.reports,
    required this.users,
    required this.allListings,
    required this.allLFItems,
    required this.onRefresh,
  });

  @override
  State<_AdminReportsPanel> createState() => _AdminReportsPanelState();
}

class _AdminReportsPanelState extends State<_AdminReportsPanel> {
  bool _showResolved = false;
  AdminReport? _selected;
  bool _loading = false;
  String? _error;

  List<AdminReport> get _filtered =>
      widget.reports.where((r) => r.isResolved == _showResolved).toList();

  Map<String, dynamic>? _findListing(String listingId, bool isLostFound) {
    if (isLostFound) {
      for (final item in widget.allLFItems) {
        if (item.id == listingId) {
          return {
            'title': item.title, 'description': item.description,
            'category': item.category, 'location': item.location,
            'image': item.image, 'status': item.status,
            'seller_username': item.posterUsername, 'price': '',
          };
        }
      }
    } else {
      for (final item in widget.allListings) {
        if (item.id == listingId) {
          return {
            'title': item.title, 'description': item.description,
            'category': item.category, 'location': item.location,
            'image': item.image, 'status': item.type,
            'seller_username': item.sellerUsername,
            'price': item.price > 0 ? item.price.toStringAsFixed(0) : '',
          };
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
              (u) => u?.email.toLowerCase() == item.posterEmail.toLowerCase()
                  || u?.username.toLowerCase() == item.posterUsername.toLowerCase(),
              orElse: () => null,
            );
          }
        }
      } else {
        for (final item in widget.allListings) {
          if (item.id == report.targetId) {
            return widget.users.cast<AdminUser?>().firstWhere(
              (u) => u?.email.toLowerCase() == item.sellerEmail.toLowerCase()
                  || u?.username.toLowerCase() == item.sellerUsername.toLowerCase(),
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
    final typeColor = {
      'listing': cRed,
      'user': const Color(0xFF2980B9),
      'lostfound': const Color(0xFF27AE60),
    }[r.targetType] ?? cMuted;
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(r.targetType.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: typeColor, letterSpacing: 0.5)),
            ),
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
      // ── Header ──
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Reports & Flags', style: TextStyle(fontSize: isMobile ? 18 : 20, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.4)),
          if (!isMobile) const Text('User-submitted reports for review', style: TextStyle(fontSize: 12, color: cMuted)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(children: [
          _Chip(label: 'Open (${widget.reports.where((r) => !r.isResolved).length})', selected: !_showResolved, onTap: () => setState(() { _showResolved = false; _selected = null; })),
          const SizedBox(width: 8),
          _Chip(label: 'Resolved (${widget.reports.where((r) => r.isResolved).length})', selected: _showResolved, onTap: () => setState(() { _showResolved = true; _selected = null; })),
        ]),
      ),

      // ── Body ──
      Expanded(
        child: isMobile
            // MOBILE: full-width list, tap opens detail popup
            ? reports.isEmpty
                ? _AdminEmptyState(message: _showResolved ? 'No resolved reports' : 'No open reports', icon: Icons.flag_outlined)
                : ListView.builder(
                    primary: false,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: reports.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => _openDetailPopup(reports[i]),
                      child: _reportCard(reports[i]),
                    ),
                  )
            // DESKTOP: two-column layout
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

// ── Detail pane (right side) ──
class _ReportDetailPane extends StatelessWidget {
  final AdminReport report;
  final Map<String, dynamic>? listingDetails;
  final AdminUser? targetUser;
  final bool loading;
  final String? error;
  final Future<void> Function(Future<void> Function()) onAction;

  const _ReportDetailPane({
    super.key,
    required this.report,
    required this.listingDetails,
    required this.targetUser,
    required this.loading,
    required this.error,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isLostFound = report.targetType == 'lostfound';
    final typeColor = {
      'listing': cRed,
      'user': const Color(0xFF2980B9),
      'lostfound': const Color(0xFF27AE60),
    }[report.targetType] ?? cMuted;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Report summary card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cBorder),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 6, runSpacing: 4, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(report.targetType.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: typeColor)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFF8E44AD).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(report.reason.label,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF8E44AD))),
              ),
              if (report.isResolved)
                const _AdminBadge(label: 'RESOLVED', color: Color(0xFF27AE60)),
            ]),
            const SizedBox(height: 8),
            Text(report.targetTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: cText)),
            const SizedBox(height: 4),
            Text('Reported by: ${report.reporterEmail} · ${formatDate(report.reportedAt)}',
              style: const TextStyle(fontSize: 11, color: cMuted)),
            if (report.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(8)),
                child: Text(report.notes, style: const TextStyle(fontSize: 12, color: cText, height: 1.5)),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 12),

        // ── Listing preview ──
        if (report.targetType == 'listing' || report.targetType == 'lostfound') ...[
          const _AdminLabel('Reported Content'),
          const SizedBox(height: 8),
          if (listingDetails == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: cBorder)),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded, size: 14, color: cMuted),
                SizedBox(width: 8),
                Expanded(child: Text('Listing may have already been removed.', style: TextStyle(fontSize: 12, color: cMuted))),
              ]),
            )
          else
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
              clipBehavior: Clip.antiAlias,
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if ((listingDetails!['image']?.toString() ?? '').isNotEmpty)
                  Image.network(
                    listingDetails!['image'].toString(),
                    width: 90, height: 90, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 90, height: 90, color: cPlaceholder,
                      child: const Icon(Icons.image_not_supported, color: cMuted)),
                  ),
                Expanded(child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(listingDetails!['title']?.toString() ?? '',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cText)),
                    const SizedBox(height: 3),
                    Text(listingDetails!['description']?.toString() ?? '',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: cMuted, height: 1.4)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      if ((listingDetails!['price']?.toString() ?? '') != '' && listingDetails!['price'] != '0')
                        _AdminBadge(label: '\$${listingDetails!['price']}', color: cRed),
                      if ((listingDetails!['category']?.toString() ?? '').isNotEmpty)
                        _AdminBadge(label: listingDetails!['category'].toString(), color: cMuted),
                      _AdminBadge(label: (listingDetails!['status']?.toString() ?? '').toUpperCase(), color: typeColor),
                    ]),
                    const SizedBox(height: 4),
                    Text('By: ${listingDetails!['seller_username'] ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 10, color: cMuted)),
                  ]),
                )),
              ]),
            ),
          const SizedBox(height: 12),
        ],

        // ── Target user info ──
        if (targetUser != null) ...[
          const _AdminLabel('Reported User'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: cRedLight, radius: 18,
                child: Text(
                  targetUser!.username.isNotEmpty ? targetUser!.username[0].toUpperCase() : 'U',
                  style: const TextStyle(color: cRed, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('@${targetUser!.username}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cText)),
                Text(targetUser!.email, style: const TextStyle(fontSize: 11, color: cMuted)),
              ])),
              if (targetUser!.isBanned) const _AdminBadge(label: 'BANNED', color: cRed)
              else if (targetUser!.hasWarning) const _AdminBadge(label: 'WARNED', color: Color(0xFFE67E22))
              else _AdminBadge(label: targetUser!.role.label.toUpperCase(), color: cMuted),
            ]),
          ),
          const SizedBox(height: 12),
        ],

        // ── Actions ──
        if (!report.isResolved) ...[
          const _AdminLabel('Actions'),
          const SizedBox(height: 8),
          if (error != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: cRed.withValues(alpha: 0.3))),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, size: 14, color: cRed),
                const SizedBox(width: 8),
                Expanded(child: Text(error!, style: const TextStyle(color: cRedDark, fontSize: 12))),
              ]),
            ),
            const SizedBox(height: 8),
          ],

          if (report.targetType == 'listing' || report.targetType == 'lostfound') ...[
            _ActionButton(
              icon: Icons.remove_circle_outline_rounded,
              label: 'Remove Listing & Notify User',
              bgColor: const Color(0xFFFFF0F0),
              borderColor: cRed.withValues(alpha: 0.3),
              iconColor: cRed,
              textColor: cRedDark,
              loading: loading,
              onTap: () => onAction(() async {
                await adminRemoveListing(listingId: report.targetId, isLostFound: isLostFound);
                await adminResolveReport(reportId: report.id);
              }),
            ),
            const SizedBox(height: 6),
            if (targetUser != null && !targetUser!.hasWarning) ...[
              _ActionButton(
                icon: Icons.warning_amber_rounded,
                label: 'Remove Listing & Issue Warning',
                bgColor: const Color(0xFFFFF8EC),
                borderColor: const Color(0xFFE67E22).withValues(alpha: 0.35),
                iconColor: const Color(0xFFE67E22),
                textColor: const Color(0xFF92400E),
                loading: loading,
                onTap: () => onAction(() async {
                  await adminRemoveListing(listingId: report.targetId, isLostFound: isLostFound);
                  await adminIssueWarning(userId: targetUser!.id, email: targetUser!.email);
                  await adminResolveReport(reportId: report.id);
                }),
              ),
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
                onTap: () => onAction(() async {
                  await adminRemoveListing(listingId: report.targetId, isLostFound: isLostFound);
                  await adminBanUser(userId: targetUser!.id, email: targetUser!.email);
                  await adminResolveReport(reportId: report.id);
                }),
              ),
              const SizedBox(height: 6),
            ],
          ],

          if (report.targetType == 'user') ...[
            if (targetUser != null && !targetUser!.isBanned && !targetUser!.hasWarning) ...[
              _ActionButton(
                icon: Icons.warning_amber_rounded,
                label: 'Issue Warning',
                bgColor: const Color(0xFFFFF8EC),
                borderColor: const Color(0xFFE67E22).withValues(alpha: 0.35),
                iconColor: const Color(0xFFE67E22),
                textColor: const Color(0xFF92400E),
                loading: loading,
                onTap: () => onAction(() async {
                  await adminIssueWarning(userId: targetUser!.id, email: targetUser!.email);
                  await adminResolveReport(reportId: report.id);
                }),
              ),
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
                onTap: () => onAction(() async {
                  await adminBanUser(userId: targetUser!.id, email: targetUser!.email);
                  await adminResolveReport(reportId: report.id);
                }),
              ),
              const SizedBox(height: 6),
            ],
          ],

          _ActionButton(
            icon: Icons.check_circle_outline_rounded,
            label: 'Dismiss (No Action)',
            bgColor: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFF27AE60).withValues(alpha: 0.35),
            iconColor: const Color(0xFF27AE60),
            textColor: const Color(0xFF166534),
            loading: loading,
            onTap: () => onAction(() => adminResolveReport(reportId: report.id)),
          ),
        ],

        if (report.isResolved)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF27AE60).withValues(alpha: 0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF27AE60), size: 16),
              SizedBox(width: 8),
              Text('This report has been resolved.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF166534))),
            ]),
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