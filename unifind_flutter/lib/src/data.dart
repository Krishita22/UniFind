part of '../main.dart';

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
  final String id, title, description, category, condition, image, seller, sellerEmail, location;
  final int? sellerId;
  final double price;
  final DateTime createdAt;
  const MarketplaceItem({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.condition,
    required this.image,
    required this.seller,
    required this.sellerEmail,
    this.sellerId,
    required this.createdAt,
    required this.location,
  });
}

class LostFoundItem {
  final String id, title, description, category, image, poster, posterEmail, location, status;
  final int? posterId;
  final LostFoundType type;
  final DateTime createdAt;
  const LostFoundItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.image,
    required this.poster,
    required this.posterEmail,
    this.posterId,
    required this.createdAt,
    required this.location,
    required this.status,
  });
}

class ClaimEvidence {
  final String proofDetails;
  final String identifyingDetails;
  final String lastSeenContext;
  final String contactNote;
  const ClaimEvidence({
    required this.proofDetails,
    this.identifyingDetails = '',
    this.lastSeenContext = '',
    this.contactNote = '',
  });
}

class FoundMatchInput {
  final String foundLocation;
  final String foundWhen;
  final String matchDetails;
  final String contactNote;
  const FoundMatchInput({
    required this.foundLocation,
    required this.foundWhen,
    required this.matchDetails,
    this.contactNote = '',
  });
}

class MarketplaceUpdateInput {
  final String title;
  final String description;
  final String category;
  final String condition;
  final String location;
  final double price;
  final String? imageUrl;
  const MarketplaceUpdateInput({
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.location,
    required this.price,
    this.imageUrl,
  });
}

class LostFoundUpdateInput {
  final String title;
  final String description;
  final String category;
  final String location;
  final String? imageUrl;
  const LostFoundUpdateInput({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.imageUrl,
  });
}

String formatDate(DateTime d) => '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';

const List<String> categories = [
  'Beauty & Personal Care',
  'Clothing',
  'Dorm Essentials',
  'Electronics',
  'Instruments',
  'Kitchen & Appliances',
  'Lab Equipment',
  'School Supplies',
  'Sports & Fitness',
  'Textbooks',
  'Tickets',
  'Other',
];

const List<String> otherMarketplaceSubcategories = [
  'Bundles',
  'Collectibles',
  'Event Supplies',
  'Storage',
  'Misc',
];
const List<String> lostFoundCategories = [
  'Electronics',
  'Bags',
  'Keys',
  'ID/Cards',
  'Wallets',
  'Water Bottles',
  'Clothing',
  'Accessories',
  'Other',
];
