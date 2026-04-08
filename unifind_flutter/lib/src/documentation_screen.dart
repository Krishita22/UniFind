part of '../main.dart';

class DocumentationScreen extends StatelessWidget {
  const DocumentationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea (
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
          children: [
            // ── Logo banner ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF8B1A1A),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 12),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset('assets/images/whitelogo.png', height: 80, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Documentation',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2),
                    ),
                  ),
                  const SizedBox(height: 3),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Intro card ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEDD8D8)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 14, color: Color(0xFF9C7070), fontFamily: 'Georgia', height: 1.75),
                  children: [
                    TextSpan(
                      text: 'UniFind is a campus marketplace and lost-and-found app exclusively for Montclair State University. '
                          'Use this guide to learn how to get the most out of the platform.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _DocSection(
              icon: Icons.grid_view_rounded,
              title: 'Overview',
              content: 'UniFind is a campus marketplace and lost-and-found app for Montclair State University. Browse listings, filter by category, post items, and track your own listings — all in one place.',
            ),
            _DocSection(
              icon: Icons.storefront_outlined,
              title: 'Marketplace',
              content: 'Browse items for sale from other MSU students. Filter by category (Textbooks, Electronics, Furniture, Clothing, Other) and search by keyword. Tap any item to see full details and contact the seller.',
            ),
            _DocSection(
              icon: Icons.search_rounded,
              title: 'Lost & Found',
              content: 'View lost and found reports from the community. Filter between "Lost" and "Found" items, and browse by category to help find matches.',
            ),
            _DocSection(
              icon: Icons.add_circle_outline_rounded,
              title: 'Posting a Listing',
              content: 'Tap the Post tab to create a listing. Choose the type (For Sale, Lost, Found), fill in the required fields, and hit Post Item. Your listing will be reviewed and appear shortly.',
            ),
            _DocSection(
              icon: Icons.list_alt_rounded,
              title: 'My Listings',
              content: 'View all your posted marketplace items and lost/found reports in one place. Switch between tabs to manage each type.',
            ),
            _DocSection(
              icon: Icons.person_outline_rounded,
              title: 'Your Profile',
              content: 'Access your profile to update your username, change your password, or set a profile picture. You can also review our Terms & Conditions and Privacy Policy here.',
            ),
            _DocSection(
              icon: Icons.shield_outlined,
              title: 'Community Rules',
              content: 'UniFind is for MSU students and faculty only. All listings must be appropriate and campus-related. Misuse of the platform may result in a warning or permanent ban.',
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                '© 2026 UniFind · Montclair State University · All rights reserved.',
                style: TextStyle(fontSize: 12, color: Color(0xFF9C7070), fontFamily: 'Georgia'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocSection extends StatelessWidget {
  final IconData icon;
  final String title, content;
  const _DocSection({required this.icon, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: cRed),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cText)),
                const SizedBox(height: 5),
                Text(content, style: const TextStyle(fontSize: 13, color: cMuted, height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}