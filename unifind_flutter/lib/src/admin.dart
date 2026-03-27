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

  String _emailToHandle(String input) {
    final n = input.trim().toLowerCase();
    if (n.isEmpty) return '';
    return n.contains('@') ? n.split('@').first : n;
  }

  bool _isMyMarketplaceItem(MarketplaceItem item) {
    if (userId != null && item.sellerId != null) return item.sellerId == userId;
    return item.sellerEmail == email.trim().toLowerCase();
  }

  bool _isMyLostFoundItem(LostFoundItem item) {
    if (userId != null && item.posterId != null) return item.posterId == userId;
    return item.posterEmail == email.trim().toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/whitelogo.png', height: 32, fit: BoxFit.contain),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  username.isNotEmpty ? username : _emailToHandle(email),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                if (role == UserRole.fac) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                    child: const Text('FACULTY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.8)),
                  ),
                ],
              ],
            ),
          ],
        ),
        actions: [IconButton(tooltip: 'Log out', onPressed: onLogout, icon: const Icon(Icons.logout))],
      ),
      body: Column(
        children: [
          _BreadcrumbBar(
            tab: tab,
            onHome: () => onTabChanged(0),
          ),
          Expanded(
            child: IndexedStack(
              index: tab,
              children: [
                MarketplaceScreen(items: market, onListItem: () => goToPostTab(), currentUserEmail: email),
                LostFoundScreen(
                  items: lostFound,
                  onCreateLost: () => goToPostTab(ListingType.lost),
                  onCreateFound: () => goToPostTab(ListingType.found),
                  onClaimLost: claimLostItem,
                  onPostFoundMatch: postFoundMatch,
                  submittedClaimItemIds: submittedClaimItemIds,
                  submittedMatchItemIds: submittedMatchItemIds,
                  currentUserEmail: email,
                ),
                PostListingScreen(key: ValueKey(postFormNonce), onPost: addListing, initialType: postDefaultType),
                MyListingsScreen(
                  marketplaceItems: market.where(_isMyMarketplaceItem).toList(),
                  lostFoundItems: lostFound.where(_isMyLostFoundItem).toList(),
                  onListItem: () => goToPostTab(),
                  onEditMarketplace: editMarketplace,
                  onEditLostFound: editLostFound,
                ),
                const DocumentationScreen(),
                ProfileScreen(
                  email: email,
                  username: username,
                  onLogout: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: onTabChanged,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Shop'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Lost/Found'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Post'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'My Listings'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Docs'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
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

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  String _s(dynamic v) => v?.toString() ?? '';
  DateTime _d(dynamic v) => DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final r = await Future.wait([
        getAdminStats(), getAdminPendingListings(), getAdminActiveListings(),
        getAdminUsers(), getAdminReports(), getAdminLostFoundItems()
      ]);
      final rawStats   = r[0] as Map<String, dynamic>;
      final rawPending = r[1] as List<Map<String, dynamic>>;
      final rawActive  = r[2] as List<Map<String, dynamic>>;
      final rawUsers   = r[3] as List<Map<String, dynamic>>;
      final rawReports = r[4] as List<Map<String, dynamic>>;
      final rawLF      = r[5] as List<Map<String, dynamic>>;

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
          id: _s(p['id']),
          title: _s(p['title']),
          description: _s(p['description']),
          category: _s(p['category']),
          condition: _s(p['condition']).isEmpty || _s(p['condition']) == 'N/A'
              ? 'Good'
              : _s(p['condition']),
          location: _s(p['location']),
          price: double.tryParse(_s(p['price'])) ?? 0,
          image: _s(p['image']).isEmpty ? _s(p['image_url']) : _s(p['image']),
          sellerEmail: _s(p['seller_email']),
          sellerUsername:
         _s(p['seller_username']).isEmpty ? 'Student' : _s(p['seller_username']),
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
        submittedAt: _d(p['created_at']),
        isLostFound: false,
        type: 'marketplace',
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
        _pending ..clear() ..addAll(pending);
        _active  ..clear() ..addAll(active);
        _users   ..clear() ..addAll(users);
        _reports ..clear() ..addAll(reports);
        _lf      ..clear() ..addAll(lfItems);
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
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.admin_panel_settings_rounded, size: 14, color: Colors.white),
              SizedBox(width: 6),
              Text('ADMIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white)),
            ]),
          ),
          const SizedBox(width: 10),
          Text(widget.adminUsername, style: const TextStyle(fontSize: 14, color: Colors.white70)),
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
                  setState(() {
                    _listingInitialShowActive = showActive;
                    _tab = t;
                  });
                },
              ),
              _AdminListingsPanel(
                key: ValueKey('listings_$_listingInitialShowActive'),
                pendingListings: _pending,
                activeListings: _active,
                onRefresh: _loadAll,
                initialShowActive: _listingInitialShowActive,
              ),
              _AdminLostFoundPanel(items: _lf, onRefresh: _loadAll),
              _AdminUsersPanel(users: _users, onRefresh: _loadAll),
              _AdminReportsPanel(reports: _reports, users: _users, onRefresh: _loadAll),
            ]),
      bottomNavigationBar: NavigationBar(
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [cNavBg, cNavBgDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Admin Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('UniFind · ${_todayLabel()}', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75))),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cText, letterSpacing: 0.2)),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, childAspectRatio: 1.6, crossAxisSpacing: 10, mainAxisSpacing: 10,
          children: [
            _StatCard(label: 'Active Listings',   value: '${stats.totalActiveListings}', icon: Icons.storefront_rounded,       color: cRed,                       onTap: () => onNavigate(AdminTab.listings, showActive: true)),
            _StatCard(label: 'Pending Approvals', value: '${stats.pendingApprovals}',    icon: Icons.pending_actions_rounded,   color: const Color(0xFFE67E22),    onTap: () => onNavigate(AdminTab.listings, showActive: false)),
            _StatCard(label: 'New Users (7d)',    value: '${stats.newUsersThisWeek}',    icon: Icons.person_add_rounded,        color: const Color(0xFF2980B9),    onTap: () => onNavigate(AdminTab.users, showActive: false)),
            _StatCard(label: 'Open Reports',      value: '${stats.openReports}',         icon: Icons.flag_rounded,              color: const Color(0xFF8E44AD),    onTap: () => onNavigate(AdminTab.reports, showActive: false)),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Recent Activity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cText, letterSpacing: 0.2)),
        const SizedBox(height: 10),
        stats.recentActivity.isEmpty
            ? _AdminEmptyState(message: 'No recent activity', icon: Icons.history_rounded)
            : Column(children: stats.recentActivity.take(12).map((a) => _ActivityTile(entry: a)).toList()),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: cBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
            Text(label, style: const TextStyle(fontSize: 11, color: cMuted, fontWeight: FontWeight.w600)),
          ]),
        ]),
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
  const _AdminListingsPanel({
    super.key,
    required this.pendingListings,
    required this.activeListings,
    required this.onRefresh,
    this.initialShowActive = false,
  });

  @override
  State<_AdminListingsPanel> createState() => _AdminListingsPanelState();
}

class _AdminListingsPanelState extends State<_AdminListingsPanel> {
  String _filter = 'All';
  late bool _showActive;

  @override
  void initState() {
    super.initState();
    _showActive = widget.initialShowActive;
  }

  Future<void> _openReview(PendingListing listing) async {
    final titleCtrl   = TextEditingController(text: listing.title);
    final descCtrl    = TextEditingController(text: listing.description);
    final priceCtrl   = TextEditingController(text: listing.price > 0 ? listing.price.toStringAsFixed(0) : '');
    final locCtrl     = TextEditingController(text: listing.location);
    final explainCtrl = TextEditingController();
    String category   = listing.category;
    String condition  = listing.condition;
    // Default denial reason to na so it is always set
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
                      // ── Denial reason — mandatory, always shown ──
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
                        decoration: const InputDecoration(
                          labelText: 'Explanation to user (optional)',
                          hintText: 'Describe why this was denied or what was changed...',
                        ),
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
                            icon: loading
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Deny'),
                            style: OutlinedButton.styleFrom(foregroundColor: cRedDark, side: const BorderSide(color: cRedDark), padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: loading ? null : () async {
                              setS(() { loading = true; error = null; });
                              try {
                                await adminDenyListing(
                                  listingId: listing.id,
                                  isLostFound: listing.isLostFound,
                                  reason: selectedReason.name,
                                  explanation: explainCtrl.text.trim(),
                                  notifyUser: notifyUser,
                                  userEmail: listing.sellerEmail,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                widget.onRefresh();
                              } catch (e) { setS(() { loading = false; error = e.toString(); }); }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: loading
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: loading ? null : () async {
                              setS(() { loading = true; error = null; });
                              try {
                                await adminApproveListing(
                                  listingId: listing.id,
                                  isLostFound: listing.isLostFound,
                                  title: titleCtrl.text.trim(),
                                  description: descCtrl.text.trim(),
                                  category: category,
                                  condition: condition,
                                  location: locCtrl.text.trim(),
                                  price: double.tryParse(priceCtrl.text.trim()) ?? listing.price,
                                  notifyUser: notifyUser,
                                  userEmail: listing.sellerEmail,
                                );
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
        : (_filter == 'All'
            ? widget.pendingListings
            : widget.pendingListings.where((p) => p.type == _filter.toLowerCase()).toList());

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            _showActive ? 'Active Listings' : 'Pending Listings',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.4),
          ),
          Text(
            _showActive ? 'All live marketplace listings' : 'Review, edit, approve or deny submissions',
            style: const TextStyle(fontSize: 12, color: cMuted),
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
            ? _AdminEmptyState(
                message: _showActive ? 'No active listings' : 'No pending listings',
                icon: _showActive ? Icons.storefront_outlined : Icons.check_circle_outline_rounded,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (_, i) => _PendingListingTile(
                  listing: items[i],
                  onTap: () => _openReview(items[i]),
                ),
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
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: cBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(listing.image, width: 70, height: 70, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: cPlaceholder, child: const Icon(Icons.image_not_supported, color: cMuted))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(listing.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cText), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7)),
                child: Text(listing.type.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: typeColor, letterSpacing: 0.5)),
              ),
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
  final VoidCallback onRefresh;
  const _AdminLostFoundPanel({required this.items, required this.onRefresh});

  @override
  State<_AdminLostFoundPanel> createState() => _AdminLostFoundPanelState();
}

class _AdminLostFoundPanelState extends State<_AdminLostFoundPanel> {
  String _filter = 'All';

  List<AdminLostFoundItem> get _filtered {
    if (_filter == 'All')      return widget.items;
    if (_filter == 'Resolved') return widget.items.where((i) => i.status == 'resolved').toList();
    return widget.items.where((i) => i.type == _filter.toLowerCase() && i.status != 'resolved').toList();
  }

  Future<void> _openDetail(AdminLostFoundItem item) async {
    bool loading = false; String? error;
    await showGeneralDialog(
      context: context, barrierDismissible: true, barrierLabel: 'LF',
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
                    Expanded(child: Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cText))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  ]),
                  Text('${item.type.toUpperCase()} · ${item.category} · ${item.location}', style: const TextStyle(fontSize: 12, color: cMuted)),
                  Text('By ${item.posterUsername} (${item.posterEmail})', style: const TextStyle(fontSize: 12, color: cMuted)),
                  const SizedBox(height: 12),
                  Text(item.description, style: const TextStyle(fontSize: 13, color: cText, height: 1.6)),
                  const SizedBox(height: 16),
                  _AdminLabel('Claims (${item.claims.length})'),
                  const SizedBox(height: 8),
                  if (item.claims.isEmpty)
                    const Text('No claims.', style: TextStyle(fontSize: 12, color: cMuted))
                  else
                    ...item.claims.map((c) => _ClaimMatchTile(email: c.claimantEmail, details: c.proofDetails, status: c.status, date: c.submittedAt)),
                  const SizedBox(height: 12),
                  _AdminLabel('Matches (${item.matches.length})'),
                  const SizedBox(height: 8),
                  if (item.matches.isEmpty)
                    const Text('No matches.', style: TextStyle(fontSize: 12, color: cMuted))
                  else
                    ...item.matches.map((m) => _ClaimMatchTile(email: m.submitterEmail, details: '${m.matchDetails}\nFound at: ${m.foundLocation}', status: m.status, date: m.submittedAt)),
                  if (error != null) ...[const SizedBox(height: 8), Text(error!, style: const TextStyle(color: cRedDark, fontSize: 12))],
                  if (item.status != 'resolved') ...[
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: ElevatedButton.icon(
                      icon: loading
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: const Text('Mark as Resolved'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                      onPressed: loading ? null : () async {
                        setS(() { loading = true; error = null; });
                        try {
                          await adminMarkLostFoundResolved(itemId: item.id);
                          if (ctx.mounted) Navigator.pop(ctx);
                          widget.onRefresh();
                        } catch (e) { setS(() { loading = false; error = e.toString(); }); }
                      },
                    )),
                  ],
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
    final items = _filtered;
    return Column(children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Align(alignment: Alignment.centerLeft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Lost & Found Oversight', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.4)),
          Text('Review claims, matches, and resolve cases', style: TextStyle(fontSize: 12, color: cMuted)),
        ])),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          for (final f in ['All', 'Lost', 'Found', 'Resolved'])
            Padding(padding: const EdgeInsets.only(right: 8), child: _Chip(label: f, selected: _filter == f, onTap: () => setState(() => _filter = f))),
        ])),
      ),
      Expanded(
        child: items.isEmpty
            ? _AdminEmptyState(message: 'No items here', icon: Icons.search_off_rounded)
            : ListView.builder(padding: const EdgeInsets.all(12), itemCount: items.length, itemBuilder: (_, i) {
                final item = items[i];
                final isLost = item.type == 'lost';
                final typeColor = item.status == 'resolved' ? const Color(0xFF27AE60) : isLost ? const Color(0xFFE74C3C) : const Color(0xFF2980B9);
                return InkWell(
                  onTap: () => _openDetail(item), borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: cBorder)),
                    child: Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(item.image, width: 64, height: 64, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 64, height: 64, color: cPlaceholder, child: const Icon(Icons.image_not_supported, color: cMuted, size: 20))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cText), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7)),
                            child: Text(item.status == 'resolved' ? 'RESOLVED' : item.type.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: typeColor)),
                          ),
                        ]),
                        const SizedBox(height: 3),
                        Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: cMuted)),
                        const SizedBox(height: 4),
                        Text('${item.claims.length} claims · ${item.matches.length} matches · ${item.posterUsername}', style: const TextStyle(fontSize: 11, color: cMuted)),
                      ])),
                      const Icon(Icons.chevron_right_rounded, color: cMuted),
                    ]),
                  ),
                );
              }),
      ),
    ]);
  }
}

class _ClaimMatchTile extends StatelessWidget {
  final String email, details, status;
  final DateTime date;
  const _ClaimMatchTile({required this.email, required this.details, required this.status, required this.date});

  @override
  Widget build(BuildContext context) {
    final statusColor = status == 'pending' ? const Color(0xFFE67E22) : status == 'approved' ? const Color(0xFF27AE60) : cRedDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: cBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(email, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cText)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(details, style: const TextStyle(fontSize: 12, color: cMuted, height: 1.5)),
        const SizedBox(height: 4),
        Text(formatDate(date), style: const TextStyle(fontSize: 11, color: cMuted)),
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

  // ── View full listing history for a user ──────────────────────────────────
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
              } catch (_) {
                if (ctx.mounted) setS(() => loading = false);
              }
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
                          if (marketItems.isEmpty)
                            const Text('No marketplace listings.', style: TextStyle(fontSize: 12, color: cMuted))
                          else
                            ...marketItems.map((m) => _HistoryTile(
                              title: m['title']?.toString() ?? '',
                              subtitle: '${m['category']} · \$${m['price']} · ${m['status']}',
                              date: m['created_at']?.toString() ?? '',
                              icon: Icons.storefront_rounded,
                            )),
                          const SizedBox(height: 16),
                          const _AdminLabel('Lost & Found Posts'),
                          const SizedBox(height: 8),
                          if (lfItems.isEmpty)
                            const Text('No lost & found posts.', style: TextStyle(fontSize: 12, color: cMuted))
                          else
                            ...lfItems.map((l) => _HistoryTile(
                              title: l['title']?.toString() ?? '',
                              subtitle: '${l['category']} · ${l['type']} · ${l['status']}',
                              date: l['created_at']?.toString() ?? '',
                              icon: Icons.search_rounded,
                            )),
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
                  // ── Header ──
                  Row(children: [
                    CircleAvatar(
                      backgroundColor: user.isBanned ? cRedDark : cRedLight, radius: 24,
                      child: Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                          style: TextStyle(color: user.isBanned ? Colors.white : cRed, fontWeight: FontWeight.w900, fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: cText)),
                      Text('@${user.username}', style: const TextStyle(fontSize: 12, color: cMuted)),
                      Text(user.email, style: const TextStyle(fontSize: 12, color: cMuted)),
                    ])),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  ]),
                  const SizedBox(height: 16),
                  // ── Info rows ──
                  _UserInfoRow(label: 'Role',           value: user.role.label),
                  _UserInfoRow(label: 'Registered',     value: formatDate(user.registeredAt)),
                  _UserInfoRow(label: 'Last Active',    value: user.lastActive != null ? formatDate(user.lastActive!) : 'Never'),
                  _UserInfoRow(label: 'Total Listings', value: '${user.listingCount}'),
                  _UserInfoRow(label: 'Email Verified', value: user.isVerified ? 'Yes' : 'No'),
                  _UserInfoRow(label: 'Warning Issued', value: user.hasWarning ? (user.warnedAt != null ? 'Yes · ${formatDate(user.warnedAt!)}' : 'Yes') : 'No', highlight: user.hasWarning),
                  _UserInfoRow(label: 'Status',         value: user.isBanned ? 'BANNED' : 'Active', highlight: user.isBanned),
                  const SizedBox(height: 12),
                  // ── Warning banners ──
                  if (!user.isBanned && !user.hasWarning)
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFFE082))),
                      child: const Row(children: [
                        Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFFE67E22)),
                        SizedBox(width: 8),
                        Expanded(child: Text('A warning must be issued before a user can be permanently banned.', style: TextStyle(fontSize: 12, color: Color(0xFF7B5800), height: 1.4))),
                      ]),
                    ),
                  if (!user.isBanned && user.hasWarning)
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(10), border: Border.all(color: cRed.withValues(alpha: 0.4))),
                      child: const Row(children: [
                        Icon(Icons.warning_amber_rounded, size: 15, color: cRedDark),
                        SizedBox(width: 8),
                        Expanded(child: Text('This user has already received their one-time warning. They can now be permanently banned if a further violation occurs.', style: TextStyle(fontSize: 12, color: cRedDark, height: 1.4))),
                      ]),
                    ),
                  const SizedBox(height: 16),
                  if (error != null) ...[Text(error!, style: const TextStyle(color: cRedDark, fontSize: 12)), const SizedBox(height: 8)],
                  // ── Action buttons ──
                  Wrap(spacing: 8, runSpacing: 8, children: [

                    // View listing history
                    OutlinedButton.icon(
                      icon: const Icon(Icons.history_rounded, size: 16),
                      label: const Text('View Listing History'),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF2980B9), side: const BorderSide(color: Color(0xFF2980B9))),
                      onPressed: () => _openListingHistory(ctx, user),
                    ),

                    // Issue warning
                    if (!user.isBanned && !user.hasWarning)
                      OutlinedButton.icon(
                        icon: loading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.warning_amber_rounded, size: 16),
                        label: const Text('Issue Warning'),
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE67E22), side: const BorderSide(color: Color(0xFFE67E22))),
                        onPressed: loading ? null : () async {
                          final confirm = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
                            title: const Text('Issue a Warning?'),
                            content: Text('This will send a one-time warning to @${user.username}.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Issue Warning', style: TextStyle(color: Color(0xFFE67E22)))),
                            ],
                          ));
                          if (confirm != true) return;
                          setS(() { loading = true; error = null; });
                          try {
                            await adminIssueWarning(userId: user.id, email: user.email);
                            if (ctx.mounted) Navigator.pop(ctx);
                            widget.onRefresh();
                          } catch (e) { setS(() { loading = false; error = e.toString(); }); }
                        },
                      ),

                    // Warning already issued — disabled
                    if (!user.isBanned && user.hasWarning)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Warning Issued'),
                        style: OutlinedButton.styleFrom(foregroundColor: cMuted, side: const BorderSide(color: cBorder)),
                        onPressed: null,
                      ),

                    // Ban — only after warning
                    if (!user.isBanned && user.hasWarning)
                      OutlinedButton.icon(
                        icon: loading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.block_rounded, size: 16),
                        label: const Text('Ban User'),
                        style: OutlinedButton.styleFrom(foregroundColor: cRedDark, side: const BorderSide(color: cRedDark)),
                        onPressed: loading ? null : () async {
                          final confirm = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
                            title: const Text('Permanently Ban This User?'),
                            content: Text('@${user.username} has already been warned. This will permanently ban them and blacklist their email.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ban Permanently', style: TextStyle(color: cRedDark))),
                            ],
                          ));
                          if (confirm != true) return;
                          setS(() { loading = true; error = null; });
                          try {
                            await adminBanUser(userId: user.id, email: user.email);
                            if (ctx.mounted) Navigator.pop(ctx);
                            widget.onRefresh();
                          } catch (e) { setS(() { loading = false; error = e.toString(); }); }
                        },
                      ),

                    // Unban
                    if (user.isBanned)
                      OutlinedButton.icon(
                        icon: loading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.lock_open_rounded, size: 16),
                        label: const Text('Unban User'),
                        style: OutlinedButton.styleFrom(foregroundColor: cRedDark, side: const BorderSide(color: cRedDark)),
                        onPressed: loading ? null : () async {
                          final confirm = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
                            title: const Text('Unban This User?'),
                            content: Text('This will allow @${user.username} back onto UniFind.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Unban', style: TextStyle(color: cRedDark))),
                            ],
                          ));
                          if (confirm != true) return;
                          setS(() { loading = true; error = null; });
                          try {
                            await adminUnbanUser(userId: user.id, email: user.email);
                            if (ctx.mounted) Navigator.pop(ctx);
                            widget.onRefresh();
                          } catch (e) { setS(() { loading = false; error = e.toString(); }); }
                        },
                      ),

                    // Delete account
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_forever_rounded, size: 16),
                      label: const Text('Delete Account'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade900, side: BorderSide(color: Colors.red.shade900)),
                      onPressed: loading ? null : () async {
                        final confirm = await showDialog<bool>(context: ctx, builder: (_) => AlertDialog(
                          title: const Text('Delete Account?'),
                          content: Text('Permanently deletes @${user.username} and all their data. Their email can be used to create a new account afterwards.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ));
                        if (confirm != true) return;
                        setS(() { loading = true; error = null; });
                        try {
                          await adminDeleteUser(userId: user.id, email: user.email);
                          if (ctx.mounted) Navigator.pop(ctx);
                          widget.onRefresh();
                        } catch (e) { setS(() { loading = false; error = e.toString(); }); }
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
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('User Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.4)),
        const Text('View, verify, ban, or delete users', style: TextStyle(fontSize: 12, color: cMuted)),
        const SizedBox(height: 10),
        _SearchField(hint: 'Search users...', onChanged: (v) => setState(() => _q = v)),
      ])),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          for (final f in ['All', 'Student', 'Faculty', 'Warned', 'Banned'])
            Padding(padding: const EdgeInsets.only(right: 8), child: _Chip(label: f, selected: _roleFilter == f, onTap: () => setState(() => _roleFilter = f))),
        ])),
      ),
      Expanded(
        child: users.isEmpty
            ? _AdminEmptyState(message: 'No users found', icon: Icons.people_outline_rounded)
            : ListView.builder(padding: const EdgeInsets.all(12), itemCount: users.length, itemBuilder: (_, i) {
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
                        backgroundColor: u.isBanned ? cRedDark : u.hasWarning ? const Color(0xFFFFF3E0) : cRedLight,
                        radius: 20,
                        child: Text(
                          u.username.isNotEmpty ? u.username[0].toUpperCase() : 'U',
                          style: TextStyle(color: u.isBanned ? Colors.white : u.hasWarning ? const Color(0xFFE67E22) : cRed, fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('@${u.username}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cText)),
                        Text(u.email, style: const TextStyle(fontSize: 11, color: cMuted)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        _AdminBadge(
                          label: u.isBanned ? 'BANNED' : u.role.label.toUpperCase(),
                          color: u.isBanned ? cRedDark : u.role == UserRole.fac ? const Color(0xFF2980B9) : cMuted,
                        ),
                        if (u.hasWarning && !u.isBanned) ...[
                          const SizedBox(height: 4),
                          const _AdminBadge(label: 'WARNED', color: Color(0xFFE67E22)),
                        ],
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
  final VoidCallback onRefresh;
  const _AdminReportsPanel({required this.reports, required this.users, required this.onRefresh});

  @override
  State<_AdminReportsPanel> createState() => _AdminReportsPanelState();
}

class _AdminReportsPanelState extends State<_AdminReportsPanel> {
  bool _showResolved = false;
  List<AdminReport> get _filtered => widget.reports.where((r) => r.isResolved == _showResolved).toList();

  Future<void> _openAction(AdminReport report) async {
    bool loading = false; String? error;
    final targetUser = widget.users.cast<AdminUser?>().firstWhere(
      (u) => u?.email == report.targetId || u?.id.toString() == report.targetId, orElse: () => null);

    await showGeneralDialog(
      context: context, barrierDismissible: true, barrierLabel: 'Action',
      barrierColor: Colors.black.withValues(alpha: 0.4), transitionDuration: kMid,
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) => Opacity(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut).value,
        child: StatefulBuilder(builder: (ctx, setS) => Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: cBorder),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: Material(color: Colors.transparent, child: Padding(padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.flag_rounded, color: cRed, size: 18)),
                    const SizedBox(width: 12),
                    const Text('Report Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: cText)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                  ]),
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        _AdminBadge(label: report.targetType.toUpperCase(), color: cRed),
                        const SizedBox(width: 8),
                        _AdminBadge(label: report.reason.label, color: const Color(0xFF8E44AD)),
                      ]),
                      const SizedBox(height: 8),
                      Text(report.targetTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cText)),
                      const SizedBox(height: 4),
                      Text('Reported by: ${report.reporterEmail}', style: const TextStyle(fontSize: 12, color: cMuted)),
                      if (report.notes.isNotEmpty) ...[const SizedBox(height: 6), Text(report.notes, style: const TextStyle(fontSize: 12, color: cText, height: 1.5))],
                    ]),
                  ),
                  const SizedBox(height: 16),
                  const _AdminLabel('Choose an Action'),
                  const SizedBox(height: 10),
                  if (error != null) ...[Text(error!, style: const TextStyle(color: cRedDark, fontSize: 12)), const SizedBox(height: 8)],
                  if (report.targetType == 'listing' || report.targetType == 'lostfound') ...[
                    SizedBox(width: double.infinity, child: OutlinedButton.icon(
                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 16),
                      label: const Text('Remove Listing Only'),
                      style: OutlinedButton.styleFrom(foregroundColor: cRedDark, side: const BorderSide(color: cRedDark), padding: const EdgeInsets.symmetric(vertical: 12), alignment: Alignment.centerLeft),
                      onPressed: loading ? null : () async {
                        setS(() { loading = true; error = null; });
                        try {
                          await adminRemoveListing(listingId: report.targetId, isLostFound: report.targetType == 'lostfound');
                          await adminResolveReport(reportId: report.id);
                          if (ctx.mounted) Navigator.pop(ctx); widget.onRefresh();
                        } catch (e) { setS(() { loading = false; error = e.toString(); }); }
                      },
                    )),
                    const SizedBox(height: 8),
                  ],
                  if (targetUser != null || report.targetType == 'user') ...[
                    SizedBox(width: double.infinity, child: OutlinedButton.icon(
                      icon: const Icon(Icons.block_rounded, size: 16),
                      label: const Text('Ban Reported User Only'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade900, side: BorderSide(color: Colors.red.shade900), padding: const EdgeInsets.symmetric(vertical: 12), alignment: Alignment.centerLeft),
                      onPressed: loading ? null : () async {
                        setS(() { loading = true; error = null; });
                        try {
                          if (targetUser != null) { await adminBanUser(userId: targetUser.id, email: targetUser.email); } else { await adminBanUserByEmail(email: report.targetId); }
                          await adminResolveReport(reportId: report.id);
                          if (ctx.mounted) Navigator.pop(ctx); widget.onRefresh();
                        } catch (e) { setS(() { loading = false; error = e.toString(); }); }
                      },
                    )),
                    const SizedBox(height: 8),
                  ],
                  if ((report.targetType == 'listing' || report.targetType == 'lostfound') && targetUser != null) ...[
                    SizedBox(width: double.infinity, child: OutlinedButton.icon(
                      icon: const Icon(Icons.gavel_rounded, size: 16),
                      label: const Text('Remove Listing & Ban User'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade900, side: BorderSide(color: Colors.red.shade900), padding: const EdgeInsets.symmetric(vertical: 12), alignment: Alignment.centerLeft),
                      onPressed: loading ? null : () async {
                        setS(() { loading = true; error = null; });
                        try {
                          await adminRemoveListing(listingId: report.targetId, isLostFound: report.targetType == 'lostfound');
                          await adminBanUser(userId: targetUser.id, email: targetUser.email);
                          await adminResolveReport(reportId: report.id);
                          if (ctx.mounted) Navigator.pop(ctx); widget.onRefresh();
                        } catch (e) { setS(() { loading = false; error = e.toString(); }); }
                      },
                    )),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Dismiss (No Action)'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: loading ? null : () async {
                      setS(() { loading = true; error = null; });
                      try {
                        await adminResolveReport(reportId: report.id);
                        if (ctx.mounted) Navigator.pop(ctx); widget.onRefresh();
                      } catch (e) { setS(() { loading = false; error = e.toString(); }); }
                    },
                  )),
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
    final reports = _filtered;
    return Column(children: [
      const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 0), child: Align(alignment: Alignment.centerLeft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Reports & Flags', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.4)),
        Text('User-submitted reports for review', style: TextStyle(fontSize: 12, color: cMuted)),
      ]))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Row(children: [
        _Chip(label: 'Open', selected: !_showResolved, onTap: () => setState(() => _showResolved = false)),
        const SizedBox(width: 8),
        _Chip(label: 'Resolved', selected: _showResolved, onTap: () => setState(() => _showResolved = true)),
      ])),
      Expanded(
        child: reports.isEmpty
            ? _AdminEmptyState(message: _showResolved ? 'No resolved reports' : 'No open reports', icon: Icons.flag_outlined)
            : ListView.builder(padding: const EdgeInsets.all(12), itemCount: reports.length, itemBuilder: (_, i) {
                final r = reports[i];
                final typeColor = {'listing': cRed, 'user': const Color(0xFF2980B9), 'lostfound': const Color(0xFF27AE60)}[r.targetType] ?? cMuted;
                return InkWell(
                  onTap: r.isResolved ? null : () => _openAction(r), borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: r.isResolved ? cBorder : cRed.withValues(alpha: 0.25))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(r.targetType.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: typeColor, letterSpacing: 0.5))),
                        const SizedBox(width: 6),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(8)),
                            child: Text(r.reason.label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: cRed))),
                        const Spacer(),
                        if (r.isResolved) const _AdminBadge(label: 'RESOLVED', color: Color(0xFF27AE60)),
                      ]),
                      const SizedBox(height: 8),
                      Text(r.targetTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cText)),
                      const SizedBox(height: 4),
                      Text('Reported by: ${r.reporterEmail} · ${formatDate(r.reportedAt)}', style: const TextStyle(fontSize: 11, color: cMuted)),
                      if (r.notes.isNotEmpty) ...[const SizedBox(height: 6), Text(r.notes, style: const TextStyle(fontSize: 12, color: cText, height: 1.5))],
                      if (!r.isResolved) ...[
                        const SizedBox(height: 10),
                        Align(alignment: Alignment.centerRight, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(8)),
                          child: const Text('Tap to take action →', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cRed)),
                        )),
                      ],
                    ]),
                  ),
                );
              }),
      ),
    ]);
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

// ── History tile used in listing history dialog ───────────────────────────────
class _HistoryTile extends StatelessWidget {
  final String title, subtitle, date;
  final IconData icon;
  const _HistoryTile({required this.title, required this.subtitle, required this.date, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
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
                    await submitReport(
                      targetId: targetId, targetType: targetType, targetTitle: targetTitle,
                      reporterEmail: reporterEmail, reason: selectedReason!.name, notes: notesCtrl.text.trim(),
                    );
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


