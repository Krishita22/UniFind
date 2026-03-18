part of '../main.dart';

class LoginScreen extends StatefulWidget {
  final AuthSuccessCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
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
        return 'Invalid email or password.';
      case 'EMAIL_NOT_FOUND':
        return 'No account found for this email. Please sign up first.';
      case 'ACCOUNT_UNVERIFIED':
        return 'Your account is not verified yet. Please complete verification.';
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
      final data = await loginUser(_email.trim(), _password);
      final user = data['user'] as Map<String, dynamic>?;
      final loggedInEmail = (user?['email'] as String?) ?? _email.trim();
      final loggedInUserId = int.tryParse(
        (user?['id'] ??
                user?['user_id'] ??
                data['user_id'] ??
                data['id'] ??
                data['data']?['id'] ??
                '')
            .toString(),
      );
      if (!mounted) return;
      widget.onLogin(loggedInEmail, loggedInUserId);
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
                                label: 'Email Address',
                                hint: 'you@montclair.edu',
                                icon: Icons.mail_outline_rounded,
                                onChanged: (v) => _email = v,
                                textInputAction: TextInputAction.next,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email is required';
                                  if (!v.contains('@')) return 'Enter a valid email';
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
        return 'Use a stronger password (at least 8 characters).';
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
                                label: 'MSU Email Address',
                                hint: 'you@montclair.edu',
                                icon: Icons.mail_outline_rounded,
                                initialValue: _email,
                                onChanged: (v) => _email = v,
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
                                  label: 'Reset Code',
                                  hint: 'Enter code from your email',
                                  icon: Icons.verified_outlined,
                                  onChanged: (v) => _code = v,
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
                                  label: 'New Password',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: true,
                                  onChanged: (v) => _newPassword = v,
                                  validator: (v) {
                                    if (!_codeSent) return null;
                                    if (v == null || v.isEmpty) return 'New password is required';
                                    if (v.length < 8) return 'Minimum 8 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _StyledField(
                                  label: 'Confirm New Password',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: true,
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
        widget.onRegister(_email.trim().toLowerCase(), null);
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
              onLogin: (email, [userId]) => widget.onRegister(email, userId),
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
                                  label: 'Age',
                                  hint: '20',
                                  icon: Icons.cake_outlined,
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => _age = v,
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
                                _StyledField(
                                  label: 'Password',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: true,
                                  onChanged: (v) => _password = v,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Password is required';
                                    if (v.length < 8) return 'Minimum 8 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _StyledField(
                                  label: 'Confirm Password',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: true,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Please confirm your password';
                                    if (v != _password) return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _StyledField(
                                  label: 'Verification Code',
                                  hint: 'Enter code from your email',
                                  icon: Icons.verified_outlined,
                                  onChanged: (v) => _code = v,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Verification code is required';
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
                                label: _codeSent ? 'Verify & Create Account' : 'Send Verification Code',
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

// ─── AUTH BUTTON ─────────────────────────────────────────────────────────────
class _AuthButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;
  final String label;
  const _AuthButton({required this.loading, required this.onTap, required this.label});

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
