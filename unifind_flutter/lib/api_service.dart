import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

// api_service.dart
// Handles all HTTP calls to the UniFind PHP API
// On web: use relative URL (same origin) to avoid CORS/mixed-content issues
// On mobile: use full URL

const String _baseUrl = 'http://cyan.csam.montclair.edu/~ivanovs1/UniFind_API';

class ApiException implements Exception {
  final String message;
  final String? code;

  const ApiException(this.message, {this.code});

  @override
  String toString() => message;
}


// LOGIN
// Sends email and password to login.php
// Returns a Map with user info on success, or throws an error on failure

Future<Map<String, dynamic>> loginUser(String email, String password) async {
  final url = Uri.parse('$_baseUrl/auth/login/login.php');

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
  String? firstName,
}) async {
  final body = <String, dynamic>{
    'email': email,
  };
  if (password != null && password.isNotEmpty) {
    body['password'] = password;
  }
  if (firstName != null && firstName.isNotEmpty) {
    body['first_name'] = firstName; 
  }

  final response = await http.post(
    Uri.parse('$_baseUrl/auth/register/send_verification_code.php'),
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
  int? graduationYear,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/auth/register/verify_code_register.php'),
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
      if (graduationYear != null) 'graduation_year': graduationYear,
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

Future<bool> checkUsernameAvailable(String username) async {
  final response = await http.get(
    Uri.parse('$_baseUrl/auth/account/check_username.php?username=${Uri.encodeComponent(username)}'),
  );
  final data = jsonDecode(response.body);
  return data['available'] == true;
}

// CHANGE USERNAME
Future<void> changeUsername(String newUsername, String email) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/auth/account/change_username.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': newUsername, 'email': email}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) return;
  throw ApiException(
    data['error']?.toString() ?? 'Failed to change username.',
    code: data['error_code']?.toString(),
  );
}

// PASSWORD RESET STEP 1: REQUEST RESET CODE
Future<Map<String, dynamic>> requestPasswordReset(String email) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/auth/password/request_password_reset.php'),
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
    Uri.parse('$_baseUrl/auth/password/reset_password.php'),
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
  String endpoint = '$_baseUrl/listings/marketplace/get_listings_rated.php';

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
  String endpoint = '$_baseUrl/listings/lostfound/get_lostfound.php';

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
    Uri.parse('$_baseUrl/listings/marketplace/post_listing.php'),
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
    Uri.parse('$_baseUrl/listings/marketplace/update_listing.php'),
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
    Uri.parse('$_baseUrl/listings/lostfound/post_lostfound.php'),
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
    Uri.parse('$_baseUrl/listings/lostfound/update_lostfound.php'),
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
    Uri.parse('$_baseUrl/listings/lostfound/post_lostfound_match.php'),
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
          Uri.parse('$_baseUrl/listings/lostfound/claim_lostfound.php'),
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
// Sends an image file to the cPanel server at uploads/upload_image.php
// Returns the public URL of the uploaded image

Future<String> uploadImage(String filePath, Uint8List fileBytes) async {
  if (fileBytes.isEmpty) {
    throw Exception('Image data is empty. Please select a valid image file.');
  }

  const int maxBytes = 5 * 1024 * 1024; // 5 MB
  if (fileBytes.length > maxBytes) {
    final sizeMb = (fileBytes.length / 1048576).toStringAsFixed(1);
    throw Exception(
      'Image is too large ($sizeMb MB). Please use an image under 5 MB.',
    );
  }

  final uri = Uri.parse('$_baseUrl/../uploads/upload_image.php');
  final request = http.MultipartRequest('POST', uri);

  // Derive a safe filename from the path, fallback to upload.jpg
  final name = filePath.isNotEmpty
      ? filePath.split('/').last.split('\\').last
      : 'upload.jpg';

  request.files.add(
    http.MultipartFile.fromBytes('file', fileBytes, filename: name),
  );

  http.StreamedResponse streamedResponse;
  try {
    streamedResponse = await request.send().timeout(const Duration(seconds: 30));
  } on TimeoutException {
    throw Exception('Image upload timed out. Please check your connection and try again.');
  } catch (e) {
    throw Exception('Failed to connect to server for image upload. Please try again.');
  }

  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['success'] == true && data['url'] != null) {
      return data['url'] as String;
    }
    final serverMsg = data['error']?.toString() ?? 'Upload failed.';
    throw Exception(serverMsg);
  }

  // Parse server error body for a user-friendly message
  try {
    final data = jsonDecode(response.body);
    final serverMsg = data['error']?.toString();
    if (serverMsg != null && serverMsg.isNotEmpty) {
      throw Exception(serverMsg);
    }
  } catch (_) {}

  if (response.statusCode == 413) {
    throw Exception('Image is too large for the server. Please use an image under 5 MB.');
  }
  throw Exception('Image upload failed (HTTP ${response.statusCode}). Please try again.');
}


// ══════════════════════════════════════════════════════════════════════════════
// ADMIN API CALLS
// ══════════════════════════════════════════════════════════════════════════════

// ─── ADMIN: GET STATS ────────────────────────────────────────────────────────
Future<Map<String, dynamic>> getAdminStats() async {
  final response = await http.get(
    Uri.parse('$_baseUrl/admin/stats/get_admin_stats.php'),
    headers: {'Content-Type': 'application/json'},
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data['data'] ?? data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to load admin stats.');
}

// ─── ADMIN: GET PENDING LISTINGS ─────────────────────────────────────────────
Future<List<Map<String, dynamic>>> getAdminPendingListings() async {
  final response = await http.get(Uri.parse('$_baseUrl/admin/listings/get_pending_listings.php'));
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to load pending listings.');
}

// ─── ADMIN: GET ACTIVE LISTINGS ──────────────────────────────────────────────
Future<List<Map<String, dynamic>>> getAdminActiveListings() async {
  final response = await http.get(Uri.parse('$_baseUrl/admin/listings/get_active_listings.php'));
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to load active listings.');
}

// ─── ADMIN: APPROVE LISTING ───────────────────────────────────────────────────
Future<Map<String, dynamic>> adminApproveListing({
  required String listingId,
  required bool isLostFound,
  required String title,
  required String description,
  required String category,
  required String condition,
  required String location,
  required double price,
  required bool notifyUser,
  required String userEmail,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/admin/listings/approve_listing.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'listing_id': listingId,
      'is_lost_found': isLostFound,
      'title': title,
      'description': description,
      'category': category,
      'condition': condition,
      'location': location,
      'price': price,
      'notify_user': notifyUser,
      'user_email': userEmail,
    }),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to approve listing.');
}

// ─── ADMIN: DENY LISTING ─────────────────────────────────────────────────────
Future<Map<String, dynamic>> adminDenyListing({
  required String listingId,
  required bool isLostFound,
  required String reason,
  required String explanation,
  required bool notifyUser,
  required String userEmail,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/admin/listings/deny_listing.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'listing_id': listingId,
      'is_lost_found': isLostFound,
      'reason': reason,
      'explanation': explanation,
      'notify_user': notifyUser,
      'user_email': userEmail,
    }),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to deny listing.');
}

// ─── ADMIN: GET USERS ────────────────────────────────────────────────────────
Future<List<Map<String, dynamic>>> getAdminUsers() async {
  final response = await http.get(Uri.parse('$_baseUrl/admin/users/get_users.php'));
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to load users.');
}

// ─── ADMIN: ISSUE ONE-TIME WARNING ───────────────────────────────────────────
// Sends a warning email to the user and marks has_warning = 1 in the DB.
// A user must be warned once before they can be permanently banned.
Future<Map<String, dynamic>> adminIssueWarning({
  required int userId,
  required String email,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/admin/users/issue_warning.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'user_id': userId, 'email': email}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to issue warning.');
}

// ─── ADMIN: BAN USER ─────────────────────────────────────────────────────────
Future<Map<String, dynamic>> adminBanUser({
  required int userId,
  required String email,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/admin/users/ban_user.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'user_id': userId, 'email': email}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to ban user.');
}

// ─── ADMIN: UNBAN USER ───────────────────────────────────────────────────────
Future<Map<String, dynamic>> adminUnbanUser({
  required int userId,
  required String email,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/admin/users/unban_user.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'user_id': userId, 'email': email}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to unban user.');
}

// ─── ADMIN: DELETE USER ──────────────────────────────────────────────────────
Future<Map<String, dynamic>> adminDeleteUser({
  required int userId,
  required String email,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/admin/users/delete_user.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'user_id': userId, 'email': email}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to delete user.');
}

// ─── ADMIN: TOGGLE EMAIL VERIFICATION ────────────────────────────────────────
Future<Map<String, dynamic>> adminToggleVerification({
  required int userId,
  required bool verify,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/admin/users/toggle_verification.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'user_id': userId, 'verify': verify}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to toggle verification.');
}

// ─── ADMIN: GET LOST & FOUND ITEMS ───────────────────────────────────────────
Future<List<Map<String, dynamic>>> getAdminLostFoundItems() async {
  final response = await http.get(Uri.parse('$_baseUrl/admin/lostfound/get_lostfound_admin.php'));
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to load lost & found items.');
}

// ─── ADMIN: MARK LOST/FOUND AS RESOLVED ──────────────────────────────────────
Future<Map<String, dynamic>> adminMarkLostFoundResolved({
  required String itemId,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/admin/lostfound/resolve_lostfound.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'item_id': itemId}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to resolve item.');
}

// ─── ADMIN: GET REPORTS ──────────────────────────────────────────────────────
Future<List<Map<String, dynamic>>> getAdminReports() async {
  final response = await http.get(Uri.parse('$_baseUrl/admin/reports/get_reports.php'));
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to load reports.');
}

// ─── ADMIN: RESOLVE REPORT ───────────────────────────────────────────────────
Future<Map<String, dynamic>> adminResolveReport({
  required String reportId,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/admin/reports/resolve_report.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'report_id': reportId}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to resolve report.');
}

// ─── USER: SUBMIT REPORT ─────────────────────────────────────────────────────
Future<Map<String, dynamic>> submitReport({
  required String targetId,
  required String targetType,
  required String targetTitle,
  required String reporterEmail,
  required String reason,
  required String notes,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/reports/submit_report.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'target_id': targetId,
      'target_type': targetType,
      'target_title': targetTitle,
      'reporter_email': reporterEmail,
      'reason': reason,
      'notes': notes,
    }),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to submit report.');
}

// ─── ADMIN: BAN USER BY EMAIL (used when user ID is not resolved) ─────────────
Future<Map<String, dynamic>> adminBanUserByEmail({
  required String email,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/admin/users/ban_user.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to ban user by email.');
}

// ─── ADMIN: REMOVE LISTING (from reports panel) ───────────────────────────────
Future<Map<String, dynamic>> adminRemoveListing({
  required String listingId,
  required bool isLostFound,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/admin/listings/remove_listing.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'listing_id': listingId, 'is_lost_found': isLostFound}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to remove listing.');
}



Future<List<Map<String, dynamic>>> getUserMarketListings(int userId) async {
  final response = await http.get(Uri.parse('$_baseUrl/admin/users/get_user_listings.php?user_id=$userId'));
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to load listings.');
}

Future<List<Map<String, dynamic>>> getUserLostFoundListings(int userId) async {
  final response = await http.get(Uri.parse('$_baseUrl/admin/users/get_user_lostfound.php?user_id=$userId'));
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to load lost & found.');
}

// Revoke User warning
Future<void> adminRevokeWarning({required int userId}) async {
  final resp = await http.post(
    Uri.parse('$_baseUrl/admin/users/revoke_warning.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'user_id': userId}),
  );
  final data = jsonDecode(resp.body);
  if (data['success'] != true) throw Exception(data['error'] ?? 'Failed to revoke warning');
}

// ─── ADMIN: CREATE MATCH ────────────────────────────────────────────────────
Future<Map<String, dynamic>> adminCreateMatch({
  required String lostItemId,
  required String foundItemId,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/admin/matches/create_match.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'lost_item_id': lostItemId, 'found_item_id': foundItemId}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to create match.');
}

// ─── ADMIN: GET MATCHES ─────────────────────────────────────────────────────
Future<List<Map<String, dynamic>>> adminGetMatches() async {
  final response = await http.get(Uri.parse('$_baseUrl/admin/matches/get_matches.php'));
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to load matches.');
}

// ─── ADMIN: RESOLVE MATCH ───────────────────────────────────────────────────
Future<Map<String, dynamic>> adminResolveMatch({
  required String matchId,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/admin/matches/resolve_match.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'match_id': matchId}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to resolve match.');
}

Future<Map<String, dynamic>> adminUnmatch({
  required String matchId,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/admin/matches/unmatch.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'match_id': matchId}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to unmatch items.');
}

Future<Map<String, dynamic>> adminAcceptClaim({
  required String claimId,
  required String itemId,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/admin/claims/accept_claim.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'claim_id': claimId, 'item_id': itemId}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to accept claim.');
}

// ── MESSAGING ─────────────────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> getInbox({required int userId}) async {
  final response = await http.get(Uri.parse('$_baseUrl/messaging/inbox/get_inbox.php?user_id=$userId'));
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to load inbox.');
}

Future<List<Map<String, dynamic>>> getMessages({
  required int conversationId,
  required int userId,
}) async {
  final response = await http.get(
    Uri.parse('$_baseUrl/messaging/conversation/get_messages.php?conversation_id=$conversationId&user_id=$userId'),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return List<Map<String, dynamic>>.from(data['data'] ?? []);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to load messages.');
}

Future<void> sendMessage({
  required int conversationId,
  required int senderId,
  required String body,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/messaging/conversation/send_message.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'conversation_id': conversationId, 'sender_id': senderId, 'body': body}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) return;
  throw ApiException(data['error']?.toString() ?? 'Failed to send message.');
}

Future<Map<String, dynamic>> startConversation({
  required int listingId,
  required int user1Id,
  required int user2Id,
  required String subject,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/messaging/conversation/start_conversation.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'listing_id': listingId,
      'user1_id':   user1Id,
      'user2_id':   user2Id,
      'subject':    subject,
    }),
  );
  final json = jsonDecode(response.body);
  if (response.statusCode == 200 && json['success'] == true) {
    final data = json['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return Map<String, dynamic>.from(json);
  }
  throw ApiException(json['error']?.toString() ?? 'Failed to start conversation.');
}

Future<int> getUnreadCount({required int userId}) async {
  try {
    final response = await http.get(Uri.parse('$_baseUrl/messaging/inbox/get_unread_count.php?user_id=$userId'));
    final json = jsonDecode(response.body);
    if (response.statusCode == 200 && json['success'] == true) {
      final data = json['data'] as Map<String, dynamic>?;
      return (data?['count'] as num?)?.toInt() ?? 0;
    }
  } catch (_) {}
  return 0;
}

// ── RATINGS ───────────────────────────────────────────────────────────────────

Future<Map<String, dynamic>> getUserRating({required int userId}) async {
  try {
    final response = await http.get(Uri.parse('$_baseUrl/ratings/user/get_user_rating.php?user_id=$userId'));
    final json = jsonDecode(response.body);
    if (response.statusCode == 200 && json['success'] == true) {
      return Map<String, dynamic>.from(json['data'] as Map);
    }
  } catch (_) {}
  return {'avg': 0.0, 'count': 0};
}

Future<List<Map<String, dynamic>>> getUserReviews({required int userId}) async {
  try {
    final response = await http.get(Uri.parse('$_baseUrl/ratings/user/get_user_reviews.php?user_id=$userId'));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }
  } catch (_) {}
  return [];
}

Future<Map<String, dynamic>> submitRating({
  required int conversationId,
  required int raterUserId,
  required int targetUserId,
  required int stars,
  String comment = '',
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/ratings/user/submit_rating.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'conversation_id': conversationId,
      'rater_id':        raterUserId,
      'target_id':       targetUserId,
      'stars':           stars,
      'comment':         comment,
    }),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to submit rating.');
}

Future<Map<String, dynamic>> markConversationComplete({
  required int conversationId,
  required int userId,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/messaging/conversation/mark_complete.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'conversation_id': conversationId, 'user_id': userId}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to mark complete.');
}

// ── APPROVED CLAIMS ──────────────────────────────────────────────────────────

Future<List<Map<String, dynamic>>> getMyApprovedClaims({required int userId}) async {
  try {
    final response = await http.get(Uri.parse('$_baseUrl/users/claims/get_my_approved_claims.php?user_id=$userId'));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }
  } catch (_) {}
  return [];
}

// ── PAYMENTS (simulated — no real money, data not stored) ────────────────────

Future<Map<String, dynamic>> createOffer({
  required int listingId,
  required int buyerId,
  required int sellerId,
  required double amount,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/payments/create_offer.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'listing_id': listingId,
      'buyer_id':   buyerId,
      'seller_id':  sellerId,
      'amount':     amount,
    }),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data['data'] ?? data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to create offer.');
}

Future<Map<String, dynamic>> processPayment({
  required String offerId,
  required int userId,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/payments/process_payment.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'offer_id': offerId, 'user_id': userId}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data['data'] ?? data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to process payment.');
}

Future<Map<String, dynamic>> requestRefund({
  required String offerId,
  required int userId,
  required String reason,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/payments/request_refund.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'offer_id': offerId, 'user_id': userId, 'reason': reason}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) {
    return Map<String, dynamic>.from(data['data'] ?? data);
  }
  throw ApiException(data['error']?.toString() ?? 'Failed to request refund.');
}

Future<void> sendPaymentInvoice({
  required String offerId,
  required String buyerEmail,
  required String buyerName,
  required String itemTitle,
  required double itemPrice,
  required String itemCategory,
  required String itemCondition,
  required String itemImage,
  required String billingAddress,
}) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/payments/send_invoice.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'offer_id':        offerId,
      'buyer_email':     buyerEmail,
      'buyer_name':      buyerName,
      'item_title':      itemTitle,
      'item_price':      itemPrice,
      'item_category':   itemCategory,
      'item_condition':  itemCondition,
      'item_image':      itemImage,
      'billing_address': billingAddress,
    }),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode == 200 && data['success'] == true) return;
  throw ApiException(data['error']?.toString() ?? 'Failed to send invoice.');
}

Future<List<Map<String, dynamic>>> getUserOffers({required int userId}) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/payments/get_user_offers.php?user_id=$userId'),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }
  } catch (_) {}
  return [];
}

// ── HEARTBEAT & USER STATUS ──────────────────────────────────────────────────

Future<void> sendHeartbeat({required int userId}) async {
  try {
    await http.get(Uri.parse('$_baseUrl/users/status/heartbeat.php?user_id=$userId'));
  } catch (_) {}
}

Future<bool> getUserOnlineStatus({required int userId}) async {
  try {
    final response = await http.get(Uri.parse('$_baseUrl/users/status/get_user_status.php?user_id=$userId'));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data['data']['online'] == true;
    }
  } catch (_) {}
  return false;
}

