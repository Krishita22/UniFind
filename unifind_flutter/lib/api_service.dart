
import 'dart:convert';
import 'package:http/http.dart' as http;

// api_service.dart
// Handles all HTTP calls to the UniFind PHP API

const String _baseUrl = 'http://cyan.csam.montclair.edu/~ivanovs1/UniFind_Test_API';

// LOGIN
// Sends email and password to login.php
// Returns a Map with user info on success, or throws an error on failure

Future<Map<String, dynamic>> loginUser(String email, String password) async {
  final url = Uri.parse('$_baseUrl/login.php');

  print('DEBUG: Attempting login to $url');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );

  print('DEBUG: Status code = ${response.statusCode}');
  print('DEBUG: Response body = ${response.body}');

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['success'] == true) {
    return data;
  } else {
    throw Exception(data['error'] ?? 'Login failed.');
  }
}

// GET MARKETPLACE LISTINGS
// Gets all active marketplace items from get_listings.php
// Returns a List of marketplace item maps

Future<List<Map<String, dynamic>>> getListings({String category = ''}) async {
  String endpoint = '$_baseUrl/get_listings.php';

  // Append category filter to URL if one was provided
  if (category.isNotEmpty && category != 'All') {
    endpoint += '?category=${Uri.encodeComponent(category)}';
  }

  final response = await http.get(Uri.parse(endpoint));
  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['success'] == true) {
    return List<Map<String, dynamic>>.from(data['data']);
  } else {
    throw Exception(data['error'] ?? 'Unable to load listings.');
  }
}

// GET LOST & FOUND ITEMS
// Gets all active lost & found posts from get_lostfound.php
// Returns a List of lost & found item maps

Future<List<Map<String, dynamic>>> getLostFoundItems({
  String type = '',
  String category = '',
}) async {
  String endpoint = '$_baseUrl/get_lostfound.php';

  // Build optional query parameters for type and category filters
  final List<String> params = [];

  if (type.isNotEmpty && type != 'all') {
    params.add('type=${Uri.encodeComponent(type)}');
  }

  if (category.isNotEmpty && category != 'All') {
    params.add('category=${Uri.encodeComponent(category)}');
  }

  if (params.isNotEmpty) {
    endpoint += '?${params.join('&')}';
  }

  final response = await http.get(Uri.parse(endpoint));
  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['success'] == true) {
    return List<Map<String, dynamic>>.from(data['data']);
  } else {
    throw Exception(data['error'] ?? 'Unable to load lost & found items.');
  }
}

// POST MARKETPLACE LISTING
// Sends a new marketplace listing to post_listing.php
// Returns a Map with success and the new item's ID

Future<Map<String, dynamic>> createListing({
  required String title,
  required String description,
  required double price,
  required String category,
  required String condition,
  required String location,
  required String email,
  String image = 'https://www.floraly.com.au/cdn/shop/articles/All_the_roses.jpg?v=1583911408',
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/post_listing.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'title':       title,
      'description': description,
      'price':       price,
      'category':    category,
      'condition':   condition,
      'location':    location,
      'email':       email,
      'image':       image,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['success'] == true) {
    return data;
  } else {
    throw Exception(data['error'] ?? 'Failed to post listing.');
  }
}

// POST LOST & FOUND ITEM
// Sends a new lost or found item to post_lostfound.php
// Returns a Map with success and the new item's ID

Future<Map<String, dynamic>> createLostFoundItem({
  required String title,
  required String description,
  required String category,
  required String type,
  required String location,
  required String email,
  String image = 'https://www.floraly.com.au/cdn/shop/articles/All_the_roses.jpg?v=1583911408',
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/post_lostfound.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'title':       title,
      'description': description,
      'category':    category,
      'type':        type,
      'location':    location,
      'email':       email,
      'image':       image,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['success'] == true) {
    return data;
  } else {
    throw Exception(data['error'] ?? 'Failed to post lost & found item.');
  }
}


