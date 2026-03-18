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
