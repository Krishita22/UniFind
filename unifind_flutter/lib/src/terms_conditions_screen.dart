part of '../main.dart';

// ─── TERMS & CONDITIONS + PRIVACY POLICY SCREEN ──────────────────────────────
class TermsAndConditionsScreen extends StatefulWidget {
  final int initialTab;
  const TermsAndConditionsScreen({super.key, this.initialTab = 0});

  @override
  State<TermsAndConditionsScreen> createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        title: const Text('Legal', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Terms & Conditions'),
            Tab(text: 'Privacy Policy'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _TermsTab(),
          _PrivacyTab(),
        ],
      ),
    );
  }
}

// ─── TERMS TAB ────────────────────────────────────────────────────────────────
class _TermsTab extends StatelessWidget {
  const _TermsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: const [
        _LegalHeader(
          icon: Icons.gavel_rounded,
          title: 'Terms & Conditions',
          subtitle: 'Last updated: January 2026',
        ),
        SizedBox(height: 20),
        _LegalSection(
          number: '1',
          title: 'Acceptance of Terms',
          body:
              'By accessing or using UniFind, you agree to be bound by these Terms and Conditions. '
              'UniFind is a campus marketplace and lost-and-found platform exclusively for '
              'Montclair State University (MSU) students, faculty, and staff. '
              'If you do not agree to these terms, please do not use the platform.',
        ),
        _LegalSection(
          number: '2',
          title: 'Eligibility',
          body:
              'UniFind is available exclusively to members of the Montclair State University community. '
              'You must register with a valid MSU email address. You are responsible for maintaining '
              'the confidentiality of your account credentials and for all activity that occurs under your account.',
        ),
        _LegalSection(
          number: '3',
          title: 'Marketplace Listings',
          body:
              'Users may post items for sale through the Marketplace feature. By posting a listing you confirm that:\n\n'
              '• You own the item or have the right to sell it.\n'
              '• The item is accurately described, including condition and price.\n'
              '• The item does not violate any applicable laws or MSU policies.\n'
              '• You will not list prohibited items such as weapons, controlled substances, alcohol, '
              'counterfeit goods, or any items banned by MSU.\n\n'
              'UniFind is not responsible for the quality, safety, legality, or delivery of listed items. '
              'All transactions are between buyers and sellers — UniFind is not a party to any sale.',
        ),
        _LegalSection(
          number: '4',
          title: 'Lost & Found',
          body:
              'The Lost & Found feature is provided to help the MSU community reunite people with their belongings. '
              'Users must provide truthful and accurate information when posting a lost or found item. '
              'Fraudulent claims — including claiming ownership of items you do not own — may result in '
              'permanent account suspension and referral to MSU Student Affairs.',
        ),
        _LegalSection(
          number: '5',
          title: 'Prohibited Conduct',
          body:
              'You agree not to:\n\n'
              '• Post false, misleading, or fraudulent listings.\n'
              '• Harass, threaten, or harm other users.\n'
              '• Use UniFind for any commercial purpose unrelated to personal campus transactions.\n'
              '• Attempt to access, tamper with, or disrupt UniFind\'s servers or systems.\n'
              '• Collect or harvest other users\' personal information without consent.\n'
              '• Impersonate any person or entity.',
        ),
        _LegalSection(
          number: '6',
          title: 'Content Responsibility',
          body:
              'You are solely responsible for all content you post on UniFind, including listings, '
              'descriptions, images, and messages. UniFind reserves the right to remove any content '
              'that violates these terms or is otherwise deemed inappropriate, without notice.',
        ),
        _LegalSection(
          number: '7',
          title: 'Disclaimer of Warranties',
          body:
              'UniFind is provided "as is" without warranties of any kind. We do not guarantee that '
              'the platform will be uninterrupted, error-free, or secure. Use of UniFind is at your own risk.',
        ),
        _LegalSection(
          number: '8',
          title: 'Limitation of Liability',
          body:
              'UniFind and its developers shall not be liable for any indirect, incidental, or consequential '
              'damages arising from your use of the platform, including loss of property, disputes between '
              'users, or failed transactions.',
        ),
        _LegalSection(
          number: '9',
          title: 'Termination',
          body:
              'We reserve the right to suspend or terminate your account at any time, with or without notice, '
              'for violation of these Terms or for any other reason at our discretion.',
        ),
        _LegalSection(
          number: '10',
          title: 'Changes to Terms',
          body:
              'UniFind may update these Terms at any time. Continued use of the platform after changes '
              'are posted constitutes your acceptance of the revised Terms.',
        ),
        _LegalSection(
          number: '11',
          title: 'Contact',
          body:
              'If you have questions about these Terms, please contact the UniFind team through the '
              'Montclair State University student portal or reach out via your MSU email.',
        ),
        SizedBox(height: 8),
        _LegalFootnote(text: '© 2026 UniFind · Montclair State University'),
      ],
    );
  }
}

// ─── PRIVACY TAB ─────────────────────────────────────────────────────────────
class _PrivacyTab extends StatelessWidget {
  const _PrivacyTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: const [
        _LegalHeader(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          subtitle: 'Last updated: January 2026',
        ),
        SizedBox(height: 20),
        _LegalSection(
          number: '1',
          title: 'Information We Collect',
          body:
              'When you create an account, UniFind collects:\n\n'
              '• Your MSU email address\n'
              '• Your chosen display username\n'
              '• Listing content you post (titles, descriptions, images, prices, locations)\n'
              '• Lost & Found posts and any claim or match submissions\n\n'
              'We do not collect payment information. All transactions are handled directly between users.',
        ),
        _LegalSection(
          number: '2',
          title: 'How We Use Your Information',
          body:
              'Your information is used to:\n\n'
              '• Create and manage your UniFind account\n'
              '• Display your listings and profile to other MSU community members\n'
              '• Facilitate lost & found claim verification\n'
              '• Improve platform functionality and user experience\n'
              '• Send account-related communications if necessary',
        ),
        _LegalSection(
          number: '3',
          title: 'Information Sharing',
          body:
              'UniFind does not sell, rent, or trade your personal information to third parties. '
              'Your email address is used internally for account purposes and is not publicly '
              'displayed to other users — only your username is visible on listings. '
              'We may share information if required by law or MSU policy.',
        ),
        _LegalSection(
          number: '4',
          title: 'Profile Pictures',
          body:
              'Profile pictures you upload are stored locally on your device and are not uploaded '
              'to UniFind servers in the current version. Future versions may offer cloud-based '
              'profile images, which will be covered by an updated privacy policy.',
        ),
        _LegalSection(
          number: '5',
          title: 'Data Retention',
          body:
              'Your account data and listings are retained as long as your account is active. '
              'If your account is terminated, your listings may be removed. '
              'You may request deletion of your data by contacting the UniFind team.',
        ),
        _LegalSection(
          number: '6',
          title: 'Security',
          body:
              'We take reasonable measures to protect your information. However, no method of '
              'transmission over the internet or electronic storage is 100% secure. '
              'Please use a strong, unique password for your account.',
        ),
        _LegalSection(
          number: '7',
          title: 'Cookies & Local Storage',
          body:
              'UniFind uses local device storage (SharedPreferences) to maintain your login session '
              'across app restarts. No third-party tracking cookies or analytics tools are used.',
        ),
        _LegalSection(
          number: '8',
          title: 'Your Rights',
          body:
              'You have the right to:\n\n'
              '• Access the personal data we hold about you\n'
              '• Request correction of inaccurate data\n'
              '• Request deletion of your account and associated data\n\n'
              'To exercise any of these rights, contact the UniFind team via your MSU email.',
        ),
        _LegalSection(
          number: '9',
          title: 'Changes to This Policy',
          body:
              'We may update this Privacy Policy from time to time. We will notify users of '
              'significant changes through the app. Continued use of UniFind after changes '
              'are posted constitutes acceptance of the revised policy.',
        ),
        SizedBox(height: 8),
        _LegalFootnote(text: '© 2026 UniFind · Montclair State University'),
      ],
    );
  }
}

// ─── SHARED LEGAL WIDGETS ─────────────────────────────────────────────────────
class _LegalHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _LegalHeader({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [cNavBg, cRedDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.2)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.72))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  const _LegalSection({required this.number, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: cRedLight, borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Text(number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: cRed)),
            ),
          ),
          title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cText)),
          iconColor: cRed,
          collapsedIconColor: cMuted,
          children: [
            Text(body, style: const TextStyle(fontSize: 13, color: cMuted, height: 1.65)),
          ],
        ),
      ),
    );
  }
}

class _LegalFootnote extends StatelessWidget {
  final String text;
  const _LegalFootnote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: Text(text, style: const TextStyle(fontSize: 11, color: cMuted)),
      ),
    );
  }
}