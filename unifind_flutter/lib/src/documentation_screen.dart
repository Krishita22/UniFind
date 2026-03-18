part of '../main.dart';

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
        _DocSection(title: 'Marketplace', content: 'Browse items for sale from other MSU students. Filter by categories like Beauty & Personal Care, Clothing, Dorm Essentials, Electronics, Instruments, Kitchen & Appliances, Lab Equipment, School Supplies, Sports & Fitness, Textbooks, Tickets, and Other. Tap any item to see full details and contact the seller.'),
        _DocSection(title: 'Lost & Found', content: 'View lost and found reports from the community. Filter between "Lost" and "Found" items, browse by category, and use the Claim button on lost posts when an item is yours.'),
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
