part of '../main.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onContinue;
  final String? username;
  const WelcomeScreen({super.key, required this.onContinue, this.username});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {

  late AnimationController _bgController;
  late AnimationController _screenFadeController;
  late AnimationController _contentController;
  late AnimationController _exitController;
  late AnimationController _pulseController;

  late Animation<double> _bgScale;
  late Animation<double> _screenFade;

  late Animation<double> _logoFade;
  late Animation<double> _logoSlide;
  late Animation<double> _dividerScale;
  late Animation<double> _welcomeFade;
  late Animation<double> _welcomeSlide;
  late Animation<double> _subFade;
  late Animation<double> _subSlide;

  late Animation<double> _logoPulse;
  late Animation<double> _exitFade;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _bgScale = Tween(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );

    // Screen fades in from black over 600ms before content animates
    _screenFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _screenFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _screenFadeController, curve: Curves.easeIn),
    );
    _screenFadeController.forward();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    Animation<double> curved(double start, double end) =>
        CurvedAnimation(
          parent: _contentController,
          curve: Interval(start, end, curve: Curves.easeOut),
        );

    // 0.0 → 0.25 is intentionally empty — acts as a delay while the background fades in.
    // All content animates simultaneously after that pause.
    _logoFade     = Tween(begin: 0.0, end: 1.0).animate(curved(0.25, 0.85));
    _logoSlide    = Tween(begin: -20.0, end: 0.0).animate(curved(0.25, 0.85));
    _dividerScale = Tween(begin: 0.0, end: 1.0).animate(curved(0.25, 0.85));
    _welcomeFade  = Tween(begin: 0.0, end: 1.0).animate(curved(0.25, 0.85));
    _welcomeSlide = Tween(begin: 20.0, end: 0.0).animate(curved(0.25, 0.85));
    _subFade      = Tween(begin: 0.0, end: 1.0).animate(curved(0.25, 0.85));
    _subSlide     = Tween(begin: 20.0, end: 0.0).animate(curved(0.25, 0.85));

    // Logo pulse fires last, after content has settled
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoPulse = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _exitFade = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    // Chime fires exactly when the animations kick in (after the 0.25 interval delay)
    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      _audioPlayer.play(AssetSource('sounds/chime.wav'));
    });

    _contentController.forward().then((_) async {
      // Pulse fires after all content has appeared
      _pulseController.forward();
      await Future.delayed(const Duration(milliseconds: 4200));
      if (!mounted) return;
      await _exitController.forward();
      if (!mounted) return;
      widget.onContinue();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _screenFadeController.dispose();
    _contentController.dispose();
    _exitController.dispose();
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String get _firstName {
    final name = widget.username ?? '';
    if (name.isEmpty) return 'there';
    return name[0].toUpperCase() + name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final double dividerWidth = MediaQuery.of(context).size.width / 5;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _bgController,
          _screenFadeController,
          _contentController,
          _exitController,
          _pulseController,
        ]),
        builder: (context, _) {
          return Opacity(
            opacity: _exitFade.value,
            child: Opacity(
              opacity: _screenFade.value,
              child: Stack(
              fit: StackFit.expand,
              children: [

                // Animated background
                Transform.scale(
                  scale: _bgScale.value,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1a0000),
                          Color(0xFF8B0000),
                          Color(0xFFB71C1C),
                          Color(0xFF6D0000),
                          Color(0xFF0D0D0D),
                        ],
                        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),

                // Content
                SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        // Logo — fades down simultaneously with divider + sub text
                        Opacity(
                          opacity: _logoFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _logoSlide.value),
                            child: Transform.scale(
                              scale: _logoPulse.value,
                              child: Image.asset(
                                'assets/images/whitelogo.png',
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Divider — expands center-out simultaneously with logo + sub text
                        SizedBox(
                          width: dividerWidth,
                          child: Transform.scale(
                            scaleX: _dividerScale.value,
                            alignment: Alignment.center,
                            child: Container(
                              height: 2,
                              color: Colors.white.withOpacity(0.35),
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Welcome text — fades in with the group
                        Opacity(
                          opacity: _welcomeFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _welcomeSlide.value),
                            child: Text(
                              'Welcome, $_firstName!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // "You're all set" — fades up simultaneously with logo + divider
                        Opacity(
                          opacity: _subFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _subSlide.value),
                            child: Text(
                              'You\'re all set.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.6),
                                fontWeight: FontWeight.w300,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }
}