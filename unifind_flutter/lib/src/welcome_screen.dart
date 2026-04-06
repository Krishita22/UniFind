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

    _logoFade     = Tween(begin: 0.0, end: 1.0).animate(curved(0.25, 0.85));
    _logoSlide    = Tween(begin: -20.0, end: 0.0).animate(curved(0.25, 0.85));
    _dividerScale = Tween(begin: 0.0, end: 1.0).animate(curved(0.25, 0.85));
    _welcomeFade  = Tween(begin: 0.0, end: 1.0).animate(curved(0.25, 0.85));
    _welcomeSlide = Tween(begin: 20.0, end: 0.0).animate(curved(0.25, 0.85));
    _subFade      = Tween(begin: 0.0, end: 1.0).animate(curved(0.25, 0.85));
    _subSlide     = Tween(begin: 20.0, end: 0.0).animate(curved(0.25, 0.85));

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

    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      _audioPlayer.play(AssetSource('sounds/chime.wav'));
    });

    _contentController.forward().then((_) async {
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
    final mq = MediaQuery.of(context);

    const baseWidth = 400.0;

    final isMobile = mq.size.width < 600;
    final scale = isMobile ? 1.0 : ((mq.size.width / baseWidth) * 1.5).clamp(1.0, 2.0);

    final double dividerWidth = (mq.size.width / 5) * scale;

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

                  // Background
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

                          Opacity(
                            opacity: _logoFade.value,
                            child: Transform.translate(
                              offset: Offset(0, _logoSlide.value * scale),
                              child: Transform.scale(
                                scale: _logoPulse.value,
                                child: Image.asset(
                                  'assets/images/whitelogo.png',
                                  height: 80 * scale,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 28 * scale),

                          SizedBox(
                            width: dividerWidth,
                            child: Transform.scale(
                              scaleX: _dividerScale.value,
                              child: Container(
                                height: 2 * scale,
                                color: Colors.white.withOpacity(0.35),
                              ),
                            ),
                          ),

                          SizedBox(height: 36 * scale),

                          Opacity(
                            opacity: _welcomeFade.value,
                            child: Transform.translate(
                              offset: Offset(0, _welcomeSlide.value * scale),
                              child: Text(
                                'Welcome, $_firstName!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 36 * scale,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 14 * scale),

                          Opacity(
                            opacity: _subFade.value,
                            child: Transform.translate(
                              offset: Offset(0, _subSlide.value * scale),
                              child: Text(
                                'You\'re all set.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16 * scale,
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