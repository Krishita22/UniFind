import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

// api_service.dart
// Handles all HTTP calls to the UniFind PHP API

const String _baseUrl = 'http://cyan.csam.montclair.edu/~ivanovs1/UniFind_Test_API';

class ApiException implements Exception {
  final String message;
  final String? code;

  const ApiException(this.message, {this.code});

  @override
  String toString() => message;
}


// LOGIN
// Sends login identifier and password to login.php.
// We send both `email` and `username` keys for backend compatibility.
// Returns a Map with user info on success, or throws an error on failure.

Future<Map<String, dynamic>> loginUser(String identifier, String password) async {
  final url = Uri.parse('$_baseUrl/login.php');

  print('DEBUG: Attempting login to $url');

  final normalized = identifier.trim();
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': normalized,
      'username': normalized,
      'password': password,
    }),
  );

  print('DEBUG: Status code = ${response.statusCode}');
  print('DEBUG: Response body = ${response.body}');

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['success'] == true) {
    return data;
  } else {
    throw ApiException(
      data['error']?.toString() ?? 'Login failed.',
      code: data['error_code']?.toString(),
    );
  }
}

// SIGNUP STEP 1: SEND VERIFICATION CODE
// Sends a verification code to the email. Backend should NOT create
// a permanent user record yet.
Future<Map<String, dynamic>> sendSignupVerificationCode({
  required String email,
  String? password,
}) async {
  final body = <String, dynamic>{
    'email': email,
  };
  if (password != null && password.isNotEmpty) {
    body['password'] = password;
  }

  final response = await http.post(
    Uri.parse('$_baseUrl/send_verification_code.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(
    data['error']?.toString() ?? 'Failed to send verification code.',
    code: data['error_code']?.toString(),
  );
}

// SIGNUP STEP 2: VERIFY CODE + CREATE ACCOUNT
// Verifies the code and then persists user credentials in DB.
Future<Map<String, dynamic>> verifyCodeAndCreateAccount({
  required String email,
  required String password,
  required String code,
  required String firstName,
  required String lastName,
  required String username,
  required String role,
  required int age,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/verify_code_register.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email':      email,
      'password':   password,
      'code':       code,
      'first_name': firstName,
      'last_name':  lastName,
      'username':   username,
      'role':       role,
      'age':        age,
    }),
  );

  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(
    data['error']?.toString() ?? 'Verification failed.',
    code: data['error_code']?.toString(),
  );
}

// PASSWORD RESET STEP 1: REQUEST RESET CODE
Future<Map<String, dynamic>> requestPasswordReset(String email) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/request_password_reset.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 &&
      data['success'] == true &&
      data['email_exists'] == false) {
    throw const ApiException(
      'This is not a verified UniFind email.',
      code: 'EMAIL_NOT_FOUND',
    );
  }
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(
    data['error']?.toString() ?? 'Failed to request password reset.',
    code: data['error_code']?.toString(),
  );
}

// PASSWORD RESET STEP 2: VERIFY CODE + UPDATE PASSWORD
Future<Map<String, dynamic>> resetPassword({
  required String email,
  required String code,
  required String newPassword,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/reset_password.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email':        email,
      'code':         code,
      'new_password': newPassword,
    }),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(
    data['error']?.toString() ?? 'Reset failed',
    code: data['error_code']?.toString(),
  );
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
    throw ApiException(
      data['error']?.toString() ?? 'Unable to load listings.',
      code: data['error_code']?.toString(),
    );
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
    throw ApiException(
      data['error']?.toString() ?? 'Unable to load lost & found items.',
      code: data['error_code']?.toString(),
    );
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
  String image = 'https://placehold.co/400x400?text=?',
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
    throw ApiException(
      data['error']?.toString() ?? 'Failed to post listing.',
      code: data['error_code']?.toString(),
    );
  }
}

Future<Map<String, dynamic>> updateListing({
  required String id,
  required String title,
  required String description,
  required double price,
  required String category,
  required String condition,
  required String location,
  required String email,
  String? imageUrl,
}) async {
  final payload = <String, dynamic>{
    'id': id,
    'title': title,
    'description': description,
    'price': price,
    'category': category,
    'condition': condition,
    'location': location,
    'email': email,
  };
  if (imageUrl != null && imageUrl.trim().isNotEmpty) {
    payload['image'] = imageUrl.trim();
    payload['image_url'] = imageUrl.trim();
  }

  final response = await http.post(
    Uri.parse('$_baseUrl/update_listing.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(payload),
  );

  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(
    data['error']?.toString() ?? 'Failed to update listing.',
    code: data['error_code']?.toString(),
  );
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
  String image = 'https://placehold.co/400x400?text=?',
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
    throw ApiException(
      data['error']?.toString() ?? 'Failed to post lost & found item.',
      code: data['error_code']?.toString(),
    );
  }
}

Future<Map<String, dynamic>> updateLostFoundItem({
  required String id,
  required String title,
  required String description,
  required String category,
  required String location,
  required String email,
  String? imageUrl,
}) async {
  final payload = <String, dynamic>{
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'location': location,
    'email': email,
  };
  if (imageUrl != null && imageUrl.trim().isNotEmpty) {
    payload['image'] = imageUrl.trim();
    payload['image_url'] = imageUrl.trim();
  }

  final response = await http.post(
    Uri.parse('$_baseUrl/update_lostfound.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(payload),
  );

  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(
    data['error']?.toString() ?? 'Failed to update lost/found item.',
    code: data['error_code']?.toString(),
  );
}

Future<Map<String, dynamic>> createLostFoundMatch({
  required String lostItemId,
  required String email,
  required String foundLocation,
  required String foundWhen,
  required String matchDetails,
  String contactNote = '',
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/post_lostfound_match.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'lost_item_id': lostItemId,
      'email': email,
      'found_location': foundLocation,
      'found_when': foundWhen,
      'match_details': matchDetails,
      'contact_note': contactNote,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  } else {
    throw ApiException(
      data['error']?.toString() ?? 'Failed to submit found match.',
      code: data['error_code']?.toString(),
    );
  }
}

Future<Map<String, dynamic>> claimLostFoundItem({
  required String itemId,
  required String email,
  required String proofDetails,
  String identifyingDetails = '',
  String lastSeenContext = '',
  String contactNote = '',
}) async {
  http.Response response;
  try {
    response = await http
        .post(
          Uri.parse('$_baseUrl/claim_lostfound.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'item_id': itemId,
            'email': email,
            'proof_details': proofDetails,
            'identifying_details': identifyingDetails,
            'last_seen_context': lastSeenContext,
            'contact_note': contactNote,
          }),
        )
        .timeout(const Duration(seconds: 12));
  } on TimeoutException {
    throw const ApiException('Claim request timed out.');
  }

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  } else {
    throw ApiException(
      data['error']?.toString() ?? 'Failed to claim item.',
      code: data['error_code']?.toString(),
    );
  }
}

// UPLOAD IMAGE
// Sends an image file from the device to upload_image.php
// Returns the public URL of the uploaded image on the server

Future<String> uploadImage(String filePath, Uint8List fileBytes) async {
  if (fileBytes.isEmpty) {
    throw Exception('Image data is empty.');
  }

  final uri = Uri.parse('https://api.cloudinary.com/v1_1/dj4lyjpnv/image/upload');
  final request = http.MultipartRequest('POST', uri);
  
  request.fields['upload_preset'] = 'Unifind';
  request.files.add(
    http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: 'upload.jpg',
    ),
  );

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);
  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data['secure_url'];
  } else {
    throw Exception(data['error']['message'] ?? 'Failed to upload image.');
  }
}
