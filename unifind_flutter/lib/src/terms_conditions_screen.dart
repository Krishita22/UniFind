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
      backgroundColor: const Color(0xFFFCF8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B1A1A),
        foregroundColor: Colors.white,
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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
      children: const [
        _IntroCard(
          text:
              'Welcome to UniFind, the student marketplace and lost & found platform for Montclair State University. '
              'By creating an account and using UniFind, you agree to the following terms. Please read them carefully. '
              'If you do not agree, you may not use the platform.',
          lastUpdated: 'March 2026',
        ),
        SizedBox(height: 20),
        _LegalSection(
          number: '1',
          title: 'Eligibility',
          body:
              'UniFind is exclusively available to current Montclair State University students and faculty. '
              'You must be at least 18 years of age and register with a valid @montclair.edu email address. '
              'By registering, you confirm that all information you provide is accurate and up to date.',
        ),
        _LegalSection(
          number: '2',
          title: 'Account Responsibility',
          body:
              'You are solely responsible for all activity that occurs under your account. You must keep your '
              'login credentials confidential and must not share your account with anyone else. UniFind is not '
              'liable for any loss or damage resulting from unauthorized access to your account.\n\n'
              'If you believe your account has been compromised, please contact us immediately.',
        ),
        _LegalSection(
          number: '3',
          title: 'Acceptable Use',
          body:
              'UniFind is a community platform built on mutual respect. All users are expected to behave '
              'professionally and courteously at all times. The following are strictly prohibited:\n\n'
              '• Posting content that is racist, sexist, homophobic, transphobic, or otherwise discriminatory\n'
              '• Harassment, threats, or intimidation of any other user\n'
              '• Impersonating another person or entity\n'
              '• Using the platform for any illegal activity\n'
              '• Attempting to manipulate, spam, or defraud other users\n'
              '• Posting false, misleading, or deliberately inaccurate information\n\n'
              'Violations of these rules may result in immediate and permanent suspension from the platform.',
        ),
        _LegalSection(
          number: '4',
          title: 'Prohibited Items',
          body:
              'UniFind is intended for the exchange of everyday goods within the MSU community. '
              'The following items are strictly prohibited:\n\n'
              '• Weapons, firearms, or ammunition of any kind\n'
              '• Illegal drugs, controlled substances, or drug paraphernalia\n'
              '• Alcohol or tobacco products\n'
              '• Counterfeit, stolen, or fraudulently obtained goods\n'
              '• Prescription medications\n'
              '• Explicit, adult, or sexually suggestive content\n'
              '• Live animals\n'
              '• Any item whose sale is prohibited by local, state, or federal law\n\n'
              'UniFind reserves the right to determine, at its sole discretion, whether a listing violates this policy.',
        ),
        _LegalSection(
          number: '5',
          title: 'Listing Standards',
          body:
              'All marketplace listings must meet the following standards to remain active:\n\n'
              '• Insufficient description — listings must clearly describe the item\n'
              '• Unreasonable pricing — no exploitative or misleading prices\n'
              '• Personal information — no phone numbers, addresses, or sensitive data\n'
              '• Duplicate listings — the same item may not be listed multiple times\n'
              '• Prohibited content — any listing that violates Section 4\n'
              '• Misleading imagery — images must accurately represent the item\n\n'
              'Users whose listings are repeatedly removed may have their accounts suspended or permanently banned.',
        ),
        _LegalSection(
          number: '6',
          title: 'Lost & Found',
          body:
              'The Lost & Found feature is provided as a community service. UniFind does not guarantee '
              'the recovery of any lost item and is not responsible for any transactions or interactions '
              'that arise from a Lost & Found post. Users are encouraged to exercise caution and use '
              'good judgment when arranging item returns.',
        ),
        _LegalSection(
          number: '7',
          title: 'Account Suspension & Banning',
          body:
              'UniFind administrators reserve the right to suspend or permanently ban any user account at '
              'any time, with or without prior notice, for any violation of these Terms & Conditions.\n\n'
              '• Posting prohibited items or content\n'
              '• Engaging in discriminatory, hateful, or harassing behavior\n'
              '• Repeated listing violations\n'
              '• Any conduct deemed harmful to the UniFind community\n\n'
              'Banned users may not create new accounts to circumvent a suspension.',
        ),
        _LegalSection(
          number: '8',
          title: 'Privacy',
          body:
              'UniFind collects only the information necessary to operate the platform, including your name, '
              'MSU email address, username, age, and role. We do not sell your personal information to third '
              'parties. Your data is stored securely and used solely for the purpose of providing the UniFind service.',
        ),
        _LegalSection(
          number: '9',
          title: 'Disclaimer of Warranties',
          body:
              'UniFind is provided "as is" without warranties of any kind. We do not guarantee that the '
              'platform will be uninterrupted, error-free, or free of harmful components. UniFind is not '
              'responsible for any damages arising from your use of the platform.',
        ),
        _LegalSection(
          number: '10',
          title: 'Changes to These Terms',
          body:
              'UniFind reserves the right to update these Terms & Conditions at any time. Continued use '
              'of the platform after changes are posted constitutes your acceptance of the revised terms.',
        ),
        _LegalSection(
          number: '11',
          title: 'Contact',
          body:
              'If you have any questions about these Terms & Conditions or wish to report a violation, '
              'please reach out to the UniFind team through your MSU email.',
        ),
        SizedBox(height: 16),
        _LegalFootnote(text: '© 2026 UniFind · Montclair State University · All rights reserved.'),
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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
      children: const [
        _IntroCard(
          text:
              'UniFind is committed to protecting your privacy. This policy explains what information '
              'we collect, how we use it, and how we keep it safe.',
          lastUpdated: 'March 2026',
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
              'Your email address is used internally and is not publicly displayed — only your username '
              'is visible on listings. We may share information if required by law or MSU policy.',
        ),
        _LegalSection(
          number: '4',
          title: 'Profile Pictures',
          body:
              'Profile pictures you upload are stored locally on your device and are not uploaded '
              'to UniFind servers in the current version. Future versions may offer cloud-based '
              'profile images, covered by an updated privacy policy.',
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
              'transmission over the internet is 100% secure. Please use a strong, unique password.',
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
              'We may update this Privacy Policy from time to time. Continued use of UniFind after '
              'changes are posted constitutes acceptance of the revised policy.',
        ),
        SizedBox(height: 16),
        _LegalFootnote(text: '© 2026 UniFind · Montclair State University · All rights reserved.'),
      ],
    );
  }
}

// ─── SHARED LEGAL WIDGETS ─────────────────────────────────────────────────────

class _IntroCard extends StatelessWidget {
  final String text;
  final String lastUpdated;
  const _IntroCard({required this.text, required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDD8D8)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Color(0xFF9C7070), fontFamily: 'Georgia', height: 1.75),
          children: [
            TextSpan(
              text: 'Last updated: $lastUpdated\n\n',
              style: const TextStyle(color: Color(0xFF1A1010), fontWeight: FontWeight.w700),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  final String? warningText;
  const _LegalSection({
    required this.number,
    required this.title,
    required this.body,
    this.warningText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section heading matching HTML h2 ──────────────────────────
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEDD8D8), width: 2)),
            ),
            child: Text(
              '$number. $title',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFFA12727),
                fontFamily: 'Georgia',
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // ── Body text ─────────────────────────────────────────────────
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2A1A1A),
              fontFamily: 'Georgia',
              height: 1.75,
            ),
          ),
          // ── Warning box ───────────────────────────────────────────────
          if (warningText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: const BorderSide(color: Color(0xFFA12727), width: 4),
                  top: BorderSide(color: const Color(0xFFF5C0C0), width: 1),
                  right: BorderSide(color: const Color(0xFFF5C0C0), width: 1),
                  bottom: BorderSide(color: const Color(0xFFF5C0C0), width: 1),
                ),
              ),
              child: Text(
                warningText!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7A1A1A),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Georgia',
                ),
              ),
            ),
          ],
        ],
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
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF9C7070), fontFamily: 'Georgia'),
        ),
      ),
    );
  }
}