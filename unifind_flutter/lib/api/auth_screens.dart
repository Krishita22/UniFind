// ============================================================
// FLUTTER AUTH SCREENS — Updated to make real API calls
// FILE: unifind_flutter/lib/auth_screens.dart
//
// This file replaces the LoginScreen that was in main.dart.
// The old LoginScreen just faked the login with no API call.
// These screens actually talk to the Django backend.
//
// SETUP: Add the http package to pubspec.yaml:
//   dependencies:
//     http: ^1.2.0
// Then run: flutter pub get
//
// IMPORTANT: The BASE_URL below uses 10.0.2.2 which is what the
// Android emulator uses to reach your machine's localhost.
// If you're running on a PHYSICAL device, change it to your
// machine's local IP address (e.g. http://192.168.1.42:8000/api)
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ============================================================
// API CONFIGURATION
// Change BASE_URL here if needed. Don't change it in 10 places.
// ============================================================

// Android emulator → your machine's localhost
const String BASE_URL = 'http://10.0.2.2:8000/api';

// Physical device → uncomment this and put your machine's IP
// const String BASE_URL = 'http://192.168.1.42:8000/api';

// ============================================================
// AUTH SCREEN — the gate that guards the whole app
// Shows Login tab by default, with a Sign Up tab alongside it.
// ============================================================

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.onLogin});

  /// Called when login succeeds. Passes back the user's email
  /// so the main app can display it in the header.
  final void Function(String email) onLogin;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniFind'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Log In'),
            Tab(text: 'Sign Up'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          LoginTab(
            onLogin: widget.onLogin,
            onGoToSignUp: () => _tabController.animateTo(1),
          ),
          SignUpTab(
            onSignedUp: () => _tabController.animateTo(0),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LOGIN TAB
// ============================================================

class LoginTab extends StatefulWidget {
  const LoginTab({
    super.key,
    required this.onLogin,
    required this.onGoToSignUp,
  });

  final void Function(String email) onLogin;
  final VoidCallback onGoToSignUp;

  @override
  State<LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<LoginTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _showResend = false;  // Show "Resend Verification" button?

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showResend = false;
    });

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim().toLowerCase(),
          'password': _passwordController.text,
        }),
      ).timeout(const Duration(seconds: 15));
      // 15 second timeout. If Django hasn't responded by then, something is
      // very wrong. Either the server isn't running or the universe is broken.

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        // Login successful! We get back a token and user info.
        // In a real app you'd store the token in SharedPreferences.
        // For the demo, we just pass the email up to the app state.
        // TODO: store data['token'] in SharedPreferences for persistent login
        widget.onLogin(data['user']['email'] as String);
      } else {
        // Login failed. Show the error message from Django.
        setState(() {
          _errorMessage = data['error'] as String? ?? 'Login failed.';
          // If Django says the user isn't verified, offer a resend option
          _showResend = data['can_resend'] == true;
        });
      }
    } on Exception {
      setState(() {
        _errorMessage = 'Could not connect to server. '
            'Make sure the Django backend is running.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendVerification() async {
    // Hit the resend endpoint with the current email field value
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/resend-verify/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.statusCode == 200
                ? data['message'] as String? ?? 'Email sent!'
                : data['error'] as String? ?? 'Could not resend.',
          ),
        ),
      );
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to server.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Welcome back',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sign in with your Montclair State email',
                style: TextStyle(color: Color(0xFF7A4A4A)),
              ),
              const SizedBox(height: 24),

              // Error message (if any)
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Montclair Email',
                  hintText: 'yourname@montclair.edu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Password is required' : null,
              ),
              const SizedBox(height: 24),

              // Log In button
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Log In'),
              ),

              // Resend verification (shown only when Django says the account
              // exists but isn't verified yet)
              if (_showResend) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _resendVerification,
                  child: const Text('Resend Verification Email'),
                ),
              ],

              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onGoToSignUp,
                child: const Text("Don't have an account? Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SIGN UP TAB
// ============================================================

class SignUpTab extends StatefulWidget {
  const SignUpTab({super.key, required this.onSignedUp});

  /// Called after successful registration. We switch back to the login tab.
  final VoidCallback onSignedUp;

  @override
  State<SignUpTab> createState() => _SignUpTabState();
}

class _SignUpTabState extends State<SignUpTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim().toLowerCase(),
          'password': _passwordController.text,
          'full_name': _nameController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        // Registration successful. Tell the user to check their email,
        // then switch to the login tab.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] as String? ??
                'Account created! Check your email to verify.'),
            duration: const Duration(seconds: 6),
          ),
        );
        // Clear the form
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmController.clear();
        // Go back to login tab
        widget.onSignedUp();
      } else {
        setState(() {
          _errorMessage = data['error'] as String? ?? 'Registration failed.';
        });
      }
    } on Exception {
      setState(() {
        _errorMessage = 'Could not connect to server. '
            'Make sure the Django backend is running.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Create your account',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'MSU students and staff only — @montclair.edu required',
                style: TextStyle(color: Color(0xFF7A4A4A)),
              ),
              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Full Name
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outlined),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Full name is required'
                    : null,
              ),
              const SizedBox(height: 16),

              // Montclair Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Montclair Email',
                  hintText: 'yourname@montclair.edu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.toLowerCase().trim().endsWith('@montclair.edu')) {
                    return 'Must be a @montclair.edu address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  helperText: 'At least 8 characters, with letters and numbers',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Password is required';
                  if (value.length < 8) return 'Password must be at least 8 characters';
                  final hasLetter = value.contains(RegExp(r'[a-zA-Z]'));
                  final hasNumber = value.contains(RegExp(r'[0-9]'));
                  if (!hasLetter || !hasNumber) {
                    return 'Password needs at least one letter and one number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Sign Up button
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
