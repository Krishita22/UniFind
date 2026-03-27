part of '../main.dart';

class LoginScreen extends StatefulWidget {
  final AuthSuccessCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  bool _loading = false;
  String? _errorMessage;
  late AnimationController _c;
  late Animation<double> _fade, _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _slide = Tween(begin: 24.0, end: 0.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  String _loginErrorMessage(ApiException e) {
    switch (e.code) {
      case 'INVALID_CREDENTIALS':
        return 'Invalid username or password.';
      case 'USER_NOT_FOUND':
        return 'No account found for this username. Please sign up first.';
      case 'EMAIL_NOT_FOUND':
        return 'No account found for this username. Please sign up first.';
      case 'ACCOUNT_UNVERIFIED':
        return 'Your account is not verified yet. Please complete verification.';
      case 'ACCOUNT_BANNED':
        return 'Your account has been permanently banned from UniFind.';
      default:
        return e.message;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final data = await loginUser(_username.trim(), _password);
      final user = data['user'] as Map<String, dynamic>?;

      print('DEBUG full response: $data');
      print('DEBUG user map: $user');
      print('DEBUG role value: ${user?['role']}');

      final loggedInEmail = (user?['email'] as String?) ?? _username.trim();
      final loggedInUserId = int.tryParse(
        (user?['id'] ??
                user?['user_id'] ??
                data['user_id'] ??
                data['id'] ??
                data['data']?['id'] ??
                '')
            .toString(),
      );
      final loggedInUsername = ((user?['username'] ??
                  user?['user_name'] ??
                  data['username'] ??
                  data['user_name'] ??
                  _username)
              as Object?)
          ?.toString()
          .trim();
      final loggedInRole = (user?['role'] ?? data['role'] ?? '').toString().trim();
      if (!mounted) return;
      widget.onLogin(
        loggedInEmail,
        loggedInUserId,
        (loggedInUsername == null || loggedInUsername.isEmpty)
            ? _username.trim()
            : loggedInUsername,
        loggedInRole,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _loginErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: Stack(
        children: [
          Positioned(right: -80, top: -80, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [cRed.withValues(alpha: 0.08), Colors.transparent])))),
          Positioned(left: -60, bottom: -60, child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [cRed.withValues(alpha: 0.05), Colors.transparent])))),
          Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, child) => Opacity(
                opacity: _fade.value,
                child: Transform.translate(offset: Offset(0, _slide.value), child: child),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      Image.asset('assets/images/logo.jpg', height: 90, fit: BoxFit.contain),
                      const SizedBox(height: 24),
                      const Text('Welcome back!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      const Text('Sign in to your UniFind account', style: TextStyle(fontSize: 14, color: cMuted)),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: cSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: cBorder),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 6))],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _StyledField(
                                label: 'Username',
                                hint: 'janedoe123',
                                icon: Icons.alternate_email_rounded,
                                onChanged: (v) => _username = v,
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Username is required';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _StyledField(
                                label: 'Password',
                                hint: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                obscure: true,
                                onChanged: (v) => _password = v,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: cRedDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              _AuthButton(loading: _loading, onTap: _submit, label: 'Sign In'),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Forgot Password?'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('← Back to homepage', style: TextStyle(color: cMuted, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FORGOT PASSWORD SCREEN ─────────────────────────────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _code = '';
  String _newPassword = '';
  bool _loading = false;
  bool _codeSent = false;
  bool _emailNotFound = false;
  String? _errorMessage;
  late AnimationController _c;
  late Animation<double> _fade, _slide;

  @override
  void initState() {
    super.initState();
    _email = (widget.initialEmail ?? '').trim().toLowerCase();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOut),
    );
    _slide = Tween(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _forgotPasswordErrorMessage(ApiException e) {
    switch (e.code) {
      case 'EMAIL_NOT_FOUND':
        return 'No account found with this email. Please sign up first.';
      case 'INVALID_CODE':
        return 'That reset code is invalid. Please check and try again.';
      case 'CODE_EXPIRED':
        return 'Your reset code expired. Request a new code.';
      case 'WEAK_PASSWORD':
        return 'Use a stronger password (at least 6 characters).';
      case 'TOO_MANY_REQUESTS':
        return 'Too many attempts. Please wait a bit and try again.';
      default:
        return e.message;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
      _emailNotFound = false;
    });

    try {
      if (!_codeSent) {
        final response = await requestPasswordReset(_email.trim().toLowerCase());
        if (!mounted) return;
        setState(() => _codeSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message']?.toString() ?? 'Reset code sent to your email.',
            ),
          ),
        );
      } else {
        await resetPassword(
          email: _email.trim().toLowerCase(),
          code: _code.trim(),
          newPassword: _newPassword,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successful. Please log in.')),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _forgotPasswordErrorMessage(e);
        _emailNotFound = e.code == 'EMAIL_NOT_FOUND';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _emailNotFound = false;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: Stack(
        children: [
          Positioned(
            right: -80,
            top: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [cRed.withValues(alpha: 0.08), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            left: -60,
            bottom: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [cRed.withValues(alpha: 0.05), Colors.transparent],
                ),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, child) => Opacity(
                opacity: _fade.value,
                child: Transform.translate(offset: Offset(0, _slide.value), child: child),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      Image.asset('assets/images/logo.jpg', height: 90, fit: BoxFit.contain),
                      const SizedBox(height: 24),
                      const Text(
                        'Forgot Password',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: cText,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _codeSent
                            ? 'Enter the code sent to your email and set a new password'
                            : 'Enter your MSU email to receive a reset code',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: cMuted),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: cSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: cBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                                _StyledField(
                                  key: const ValueKey('forgot_email'),
                                  label: 'MSU Email Address',
                                  hint: 'you@montclair.edu',
                                  icon: Icons.mail_outline_rounded,
                                  initialValue: _email,
                                onChanged: (v) => _email = v,
                                textInputAction: _codeSent
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                onFieldSubmitted: (_) {
                                  if (!_codeSent) _submit();
                                },
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email is required';
                                  if (!v.toLowerCase().trim().endsWith('@montclair.edu')) {
                                    return 'Must use an @montclair.edu email';
                                  }
                                  return null;
                                },
                              ),
                              if (_codeSent) ...[
                                const SizedBox(height: 16),
                                _StyledField(
                                  key: const ValueKey('forgot_code'),
                                  label: 'Reset Code',
                                  hint: 'Enter code from your email',
                                  icon: Icons.verified_outlined,
                                  onChanged: (v) => _code = v,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    if (!_codeSent) return null;
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Reset code is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _StyledField(
                                  key: const ValueKey('forgot_new_password'),
                                  label: 'New Password',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: true,
                                  onChanged: (v) => _newPassword = v,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    if (!_codeSent) return null;
                                    if (v == null || v.isEmpty) return 'New password is required';
                                    if (v.length < 6) return 'Minimum 6 characters';
                                    if (v.length > 14) return 'Maximum 14 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _StyledField(
                                  key: const ValueKey('forgot_confirm_password'),
                                  label: 'Confirm New Password',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: true,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  validator: (v) {
                                    if (!_codeSent) return null;
                                    if (v == null || v.isEmpty) return 'Please confirm your password';
                                    if (v != _newPassword) return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                              ],
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: cRedDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              _AuthButton(
                                loading: _loading,
                                onTap: _submit,
                                label: _codeSent ? 'Reset Password' : 'Send Reset Code',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back, size: 14, color: cMuted),
                              SizedBox(width: 6),
                              Text('Back to login', style: TextStyle(color: cMuted, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── REGISTRATION SCREEN ─────────────────────────────────────────────────────
class RegistrationScreen extends StatefulWidget {
  final AuthSuccessCallback onRegister;
  const RegistrationScreen({super.key, required this.onRegister});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _firstName = '';
  String _lastName = '';
  String _username = '';
  String _password = '';
  String _age = '';
  String _role = 'student';
  String _code = '';
  bool _loading = false;
  bool _codeSent = false;
  bool _agreedToTerms = false;
  String? _errorMessage;
  late AnimationController _c;
  late Animation<double> _fade, _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _slide = Tween(begin: 24.0, end: 0.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  bool get _passwordStrong {
  return _password.length >= 6 &&
      _password.length <= 14 &&
      RegExp(r'[A-Z]').hasMatch(_password) &&
      RegExp(r'[0-9]').hasMatch(_password) &&
      RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(_password);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      if (!_codeSent) {
        await sendSignupVerificationCode(
          email: _email.trim().toLowerCase(),
          password: 'TempPass123!',
        );
        if (!mounted) return;
        setState(() => _codeSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent. Set your password and enter the code.'),
          ),
        );
      } else {
        await verifyCodeAndCreateAccount(
          email: _email.trim().toLowerCase(),
          password: _password,
          code: _code.trim(),
          firstName: _firstName.trim(),
          lastName: _lastName.trim(),
          username: _username.trim(),
          role: _role,
          age: int.tryParse(_age.trim()) ?? 0,
        );
        if (!mounted) return;
        widget.onRegister(
          _email.trim().toLowerCase(),
          null,
          _username.trim(),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;

      if (e.code == 'USER_EXISTS') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email already registered. Please log in.'),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LoginScreen(
              onLogin: (email, [userId, username, role]) =>
                widget.onRegister(email, userId, username, role),
            ),
          ),
        );
        return;
      }

      setState(() {
        if (!_codeSent && e.message.toLowerCase().contains('password')) {
          _errorMessage = 'Unable to start sign up. Please try again.';
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: Stack(
        children: [
          Positioned(right: -80, top: -80, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [cRed.withValues(alpha: 0.08), Colors.transparent])))),
          Positioned(left: -60, bottom: -60, child: Container(width: 220, height: 220, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [cRed.withValues(alpha: 0.05), Colors.transparent])))),
          Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, child) => Opacity(
                opacity: _fade.value,
                child: Transform.translate(offset: Offset(0, _slide.value), child: child),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      Image.asset('assets/images/logo.jpg', height: 90, fit: BoxFit.contain),
                      const SizedBox(height: 24),
                      const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: cText, letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Text(
                        _codeSent
                            ? 'Set your password and verify your email'
                            : 'Enter your details to get started',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: cMuted),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: cSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: cBorder),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 6))],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [

                              if (!_codeSent) ...[
                                // ── Step 1: profile info ──────────────────
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _StyledField(
                                        key: const ValueKey('signup_first_name'),
                                        label: 'First Name',
                                        hint: 'Jane',
                                        icon: Icons.person_outline_rounded,
                                        onChanged: (v) => _firstName = v,
                                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _StyledField(
                                        key: const ValueKey('signup_last_name'),
                                        label: 'Last Name',
                                        hint: 'Doe',
                                        icon: Icons.person_outline_rounded,
                                        onChanged: (v) => _lastName = v,
                                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _StyledField(
                                  key: const ValueKey('signup_email'),
                                  label: 'MSU Email Address',
                                  hint: 'you@montclair.edu',
                                  icon: Icons.mail_outline_rounded,
                                  onChanged: (v) => _email = v,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Email is required';
                                    if (!v.toLowerCase().trim().endsWith('@montclair.edu')) {
                                      return 'Must use an @montclair.edu email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _StyledField(
                                  key: const ValueKey('signup_username'),
                                  label: 'Username',
                                  hint: 'janedoe123',
                                  icon: Icons.alternate_email_rounded,
                                  onChanged: (v) => _username = v,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Username is required';
                                    if (v.trim().length < 3) return 'At least 3 characters';
                                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                                      return 'Letters, numbers, and underscores only';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Role picker
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'I am a...',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cText, letterSpacing: 0.3),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _RoleChip(
                                          label: 'Student',
                                          icon: Icons.school_outlined,
                                          selected: _role == 'student',
                                          onTap: () => setState(() => _role = 'student'),
                                        ),
                                        const SizedBox(width: 10),
                                        _RoleChip(
                                          label: 'Faculty',
                                          icon: Icons.work_outline_rounded,
                                          selected: _role == 'faculty',
                                          onTap: () => setState(() => _role = 'faculty'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _StyledField(
                                  key: const ValueKey('signup_age'),
                                  label: 'Age',
                                  hint: '20',
                                  icon: Icons.cake_outlined,
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => _age = v,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    if (!_codeSent) _submit();
                                  },
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Age is required';
                                    final parsed = int.tryParse(v.trim());
                                    if (parsed == null) return 'Enter a valid age';
                                    if (parsed < 16 || parsed > 120) return 'Enter a realistic age';
                                    return null;
                                  },
                                ),
                              ],

                              if (_codeSent) ...[
                                // ── Step 2: password + verification code ──
                                _PasswordField(
                                  key: const ValueKey('signup_password'),
                                  onChanged: (v) => setState(() => _password = v),
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) =>
                                      FocusScope.of(context).nextFocus(),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Password is required';
                                    if (v.length < 6) return 'Minimum 6 characters';
                                    if (v.length > 14) return 'Maximum 14 characters';
                                    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Add an uppercase letter';
                                    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Add a number';
                                    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(v)) return 'Add a special character';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _StyledField(
                                  key: const ValueKey('signup_confirm_password'),
                                  label: 'Confirm Password',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: true,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Please confirm your password';
                                    if (v != _password) return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _StyledField(
                                  key: const ValueKey('signup_verification_code'),
                                  label: 'Verification Code',
                                  hint: 'Enter code from your email',
                                  icon: Icons.verified_outlined,
                                  onChanged: (v) => _code = v,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Verification code is required';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                GestureDetector(
                                  onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: _agreedToTerms ? cRed : cBg,
                                          borderRadius: BorderRadius.circular(5),
                                          border: Border.all(
                                            color: _agreedToTerms ? cRed : cBorder,
                                            width: _agreedToTerms ? 0 : 1.5,
                                          ),
                                        ),
                                        child: _agreedToTerms
                                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: cMuted,
                                              height: 1.5,
                                              fontFamily: 'Georgia',
                                            ),
                                            children: [
                                              const TextSpan(text: 'I have read and agree to the  '),
                                              TextSpan(
                                                text: 'Terms & Conditions',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: cRed,
                                                  height: 1.5,
                                                  decorationColor: cRed,
                                                  decoration: TextDecoration.underline,
                                                  fontFamily: 'Georgia',
                                                ),
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () async {
                                                    final uri = Uri.parse(
                                                      'http://cyan.csam.montclair.edu/~ivanovs1/UniFind_Test_API/terms.html',
                                                    );
                                                    if (await canLaunchUrl(uri)) {
                                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                    }
                                                  },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (_errorMessage != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: cRedDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              _AuthButton(
                                loading: _loading,
                                onTap: (!_codeSent || (_passwordStrong && _agreedToTerms))
                                    ? _submit
                                    : () {},
                                label: _codeSent
                                    ? 'Verify & Create Account'
                                    : 'Send Verification Code',
                                disabled: _codeSent && (!_passwordStrong || !_agreedToTerms),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back, size: 14, color: cMuted),
                              SizedBox(width: 6),
                              Text('Back to login', style: TextStyle(color: cMuted, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PASSWORD FIELD WITH STRENGTH INDICATOR ───────────────────────────────────
class _PasswordField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;

  const _PasswordField({
    super.key,
    required this.onChanged,
    this.validator,
    this.onFieldSubmitted,
    this.textInputAction,
  });

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  String _value = '';
  bool _obscure = true;

  // ── Rule checkers ──────────────────────────────────────────────────────────
  bool get _hasMinLength   => _value.length >= 6;
  bool get _hasMaxLength   => _value.length <= 14;
  bool get _hasUppercase   => RegExp(r'[A-Z]').hasMatch(_value);
  bool get _hasNumber      => RegExp(r'[0-9]').hasMatch(_value);
  bool get _hasSpecial     => RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(_value);

  int get _score {
    int s = 0;
    if (_hasMinLength) s++;
    if (_hasMaxLength && _value.isNotEmpty) s++;
    if (_hasUppercase) s++;
    if (_hasNumber)    s++;
    if (_hasSpecial)   s++;
    return s;
  }

  Color get _barColor {
    if (_value.isEmpty) return cBorder;
    if (_score <= 2) return const Color(0xFFE53935); // red
    if (_score <= 3) return const Color(0xFFFB8C00); // orange
    if (_score == 4) return const Color(0xFFFDD835); // yellow
    return const Color(0xFF43A047);                  // green
  }

  String get _strengthLabel {
    if (_value.isEmpty) return '';
    if (_score <= 2) return 'Weak';
    if (_score <= 3) return 'Fair';
    if (_score == 4) return 'Good';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Field label ───────────────────────────────────────────────────
        const Text(
          'Password',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cText, letterSpacing: 0.3),
        ),
        const SizedBox(height: 6),

        // ── Text input ────────────────────────────────────────────────────
        TextFormField(
          obscureText: _obscure,
          onChanged: (v) {
            setState(() => _value = v);
            widget.onChanged(v);
          },
          onFieldSubmitted: widget.onFieldSubmitted,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: cMuted, fontSize: 14),
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: cMuted),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: cMuted,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cRed, width: 2)),
            filled: true,
            fillColor: cBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),

        // ── Strength bar for password ───────────────────────
        if (true) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _score / 5,
                    minHeight: 6,
                    backgroundColor: cBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _strengthLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _barColor,
                ),
              ),
            ],
          ),

          // ── Rules checklist ───────────────────────────────────────────
          const SizedBox(height: 10),
          _PasswordRule(met: _hasMinLength,  text: '6–14 characters'),
          _PasswordRule(met: _hasUppercase,  text: 'At least one uppercase letter'),
          _PasswordRule(met: _hasNumber,     text: 'At least one number'),
          _PasswordRule(met: _hasSpecial,    text: 'At least one special character (!@#\$%^&*...)'),
        ],
      ],
    );
  }
}

// ─── SINGLE RULE ROW ──────────────────────────────────────────────────────────
class _PasswordRule extends StatelessWidget {
  final bool met;
  final String text;

  const _PasswordRule({required this.met, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: met ? const Color(0xFF43A047) : cMuted,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: met ? const Color(0xFF43A047) : cMuted,
              fontWeight: met ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AUTH BUTTON ─────────────────────────────────────────────────────────────
class _AuthButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;
  final String label;
  final bool disabled;
  const _AuthButton({required this.loading, required this.onTap, required this.label, this.disabled = false});

  @override
  State<_AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<_AuthButton> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kFast);
    _scale = Tween(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Opacity(
          opacity: widget.disabled ? 0.4 : 1.0,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [cRed, cRedDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: cRed.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 5))],
            ),
          child: Center(
            child: widget.loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
          ),
        ),
      ),
      ),
    );
  }
}

// ─── STYLED FIELD ─────────────────────────────────────────────────────────────
class _StyledField extends StatelessWidget {
  final String label, hint;
  final IconData icon;
  final bool obscure;
  final String? initialValue;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;

  const _StyledField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.initialValue,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cText, letterSpacing: 0.3)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          textInputAction: textInputAction,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: cMuted, fontSize: 14),
            prefixIcon: Icon(icon, size: 18, color: cMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cRed, width: 2)),
            filled: true,
            fillColor: cBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ─── ROLE CHIP ────────────────────────────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? cRed.withValues(alpha: 0.08) : cBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? cRed : cBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? cRed : cMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? cRed : cMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
