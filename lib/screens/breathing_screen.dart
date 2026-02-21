import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../constants/audio_assets.dart';
import '../widgets/fluid_breath_shape.dart';
import 'home_screen.dart';

enum _AppPhase { intro, simpleBreath, grounding, mainBreath }

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  // ── Breathing ──────────────────────────────────
  late AnimationController _breathController;
  late Animation<double> _breathScale;

  static const _inhale = 'Breathe in for 4s';
  static const _topUp = 'Top-up for 2s';
  static const _exhale = 'Breathe out for 6s';
  static const _idle = 'Breathe right now.';

  String _displayText = _idle;
  int _countdownSeconds = 0;

  // ── Onboarding phase (Bypassed for Seamless Launch) ─
  _AppPhase _appPhase = _AppPhase.mainBreath; // CHANGED: Start directly in main breath
  int _introStep = 0; // 0=message, 1/2/3=count
  Timer? _introTimer;
  late AnimationController _simpleController;
  late Animation<double> _simpleScale;
  int _simpleCycles = 0;
  static const int _totalSimpleCycles = 4;

  // ── Controls ───────────────────────────────────
  bool _breathingOn = true;
  bool _audioOn = true;

  // ── Dynamic Color & Haptics ────────────────────
  late AnimationController _colorController;
  late Animation<Color?> _bgColor;
  late Animation<Color?> _fluidColor;
  Timer? _hapticTimer;

  // ── Reality Grounding ──────────────────────────
  bool _groundingActive = false;
  int _groundingTurn = 0;

  static const _groundingCopy = [
    '1. Visual Anchor\nLook around. Name 5 things you can see.',
    '2. Physical Anchor\nTouch 4 things and notice their texture.',
    '3. Auditory Anchor\nListen closely. Name 3 sounds you hear.',
    '4. Olfactory Anchor\nBreathe in. Name 2 things you can smell.',
    '5. Gustatory Anchor\nFocus on your mouth. 1 thing you can taste.',
    "The storm is passing.\nYou are safe here.",
  ];

  // ── Audio ──────────────────────────────────────
  late AudioPlayer _audioPlayer;
  bool _audioReady = false;
  bool _firstInteractionDone = false;

  // ── Session log ────────────────────────────────
  DateTime? _sessionStart;

  // ── Trust card ────────────────────────────────
  bool _showTrustCard = false;
  Timer? _trustCardTimer;

  static const _trustQuotes = [
    ('Breath is the fastest way to tell your\nnervous system: you are safe, right now.', 'trauma therapy principle'),
    ('As long as you\'re breathing,\nmore things are right than wrong.', 'mindfulness-based therapy'),
    ('Breathing is the fastest tool\nto change the brain\'s level of alertness.', 'neuroscience research'),
  ];
  int _trustQuoteIndex = 0;

  // ── 개선 1: Web start overlay (Disabled for immediate action)
  bool _showStartOverlay = false;

  // ── Haptic feedback hint ─────────────────────
  bool _showHapticHint = false;

  // ── 개선 2: 2초 호흡 레이블 지연 ───────────────
  Timer? _breathStartTimer;

  // ── 개선 3: 아이콘 라벨 힌트 ──────────────────
  bool _showIconHints = false;
  Timer? _iconHintTimer;

  // ── Lifecycle ──────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _sessionStart = DateTime.now();
    _initAudio();
    _initBreathing();
    _initSimpleBreath();
    
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 90),
    );
    _bgColor = ColorTween(
      begin: AppColors.backgroundAnxious,
      end: AppColors.backgroundCalm,
    ).animate(_colorController)..addListener(() => setState(() {}));
    _fluidColor = ColorTween(
      begin: AppColors.fluidAnxious,
      end: AppColors.fluidCalm,
    ).animate(_colorController);

    // Start with Intro Onboarding instead of Main Breath
    _startIntro();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _breathController.stop();
        if (_audioReady) _audioPlayer.pause();
        WakelockPlus.disable();
        break;
      case AppLifecycleState.resumed:
        WakelockPlus.enable();
        if (_breathingOn) _breathController.repeat();
        if (_audioOn && _audioReady) _audioPlayer.play();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breathController.removeListener(_onBreathTick);
    _breathController.dispose();
    _simpleController.dispose();
    _colorController.dispose();
    _audioPlayer.dispose();
    _trustCardTimer?.cancel();
    _breathStartTimer?.cancel();
    _iconHintTimer?.cancel();
    _introTimer?.cancel();
    _hapticTimer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  // ── Audio ──────────────────────────────────────

  Future<void> _initAudio() async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer.setAsset(AudioAssets.options[0].path);
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.setVolume(0.45);
      if (mounted) {
        setState(() => _audioReady = true);
        if (!kIsWeb) {
          _audioPlayer.play();
        }
      }
    } catch (_) {}
  }

  void _toggleAudio() {
    setState(() => _audioOn = !_audioOn);
    if (_audioOn) {
      _audioPlayer.play();
    } else {
      _audioPlayer.pause();
    }
  }

  // ── Breathing ─────────────────────────────────

  void _initBreathing() {
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11), // 4s + 1.5s + 6s = physiological sigh
    );

    _breathScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40, // inhale 4s
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15, // top-up 1.5s
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.5)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 55, // exhale 6s
      ),
    ]).animate(_breathController);

    // repeat() is called in _startMainBreath()
  }

  void _onBreathTick() {
    if (_groundingActive || !_breathingOn) return;
    final t = _breathController.value;
    // Phase boundaries derived from TweenSequence weights (40/110, 55/110)
    const inhaleBound = 4.0 / 11.0;   // ≈ 0.3636
    const topupBound  = 5.5 / 11.0;   // = 0.5000

    String newText;
    int newCountdown;

    if (t < inhaleBound) {
      newText = _inhale;
      newCountdown = ((inhaleBound - t) * 11).ceil().clamp(1, 4);
    } else if (t < topupBound) {
      newText = _topUp;
      newCountdown = ((topupBound - t) * 11).ceil().clamp(1, 2);
    } else {
      newText = _exhale;
      newCountdown = ((1.0 - t) * 11).ceil().clamp(1, 6);
    }

    final phaseChanged    = newText != _displayText;
    final countdownChanged = newCountdown != _countdownSeconds;

    if (phaseChanged || countdownChanged) {
      setState(() {
        _displayText = newText;
        _countdownSeconds = newCountdown;
      });
      if (phaseChanged) _hapticForPhase(newText);
    }
  }

  void _hapticForPhase(String phase) {
    _hapticTimer?.cancel();
    if (phase.contains('Breathe in')) {
      // Accelerating rumble
      int count = 0;
      _hapticTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
        count++;
        if (count > 10) timer.cancel();
        HapticFeedback.lightImpact();
      });
      HapticFeedback.mediumImpact(); 
    } else if (phase.contains('Top')) {
      HapticFeedback.selectionClick();
    } else if (phase.contains('Breathe out')) {
      // Fading soft tap
      int count = 0;
      _hapticTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
         count++;
         if (count > 8) timer.cancel();
         HapticFeedback.lightImpact();
      });
      HapticFeedback.lightImpact();
    }
  }

  // ── Onboarding ────────────────────────────────

  void _initSimpleBreath() {
    _simpleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // 4s inhale + 4s exhale
    );
    _simpleScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.5)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_simpleController);

    _simpleController.addListener(_onSimpleTick);
    _simpleController.addStatusListener(_onSimpleStatus);
  }

  void _onSimpleTick() {
    if (_appPhase != _AppPhase.simpleBreath) return;
    final t = _simpleController.value;
    final newText = t < 0.5 ? 'Breathe in for 4s' : 'Breathe out for 4s';
    final newCd = t < 0.5
        ? ((0.5 - t) * 8).ceil().clamp(1, 4)
        : ((1.0 - t) * 8).ceil().clamp(1, 4);
    final textChanged = newText != _displayText;
    final cdChanged = newCd != _countdownSeconds;
    if (textChanged || cdChanged) {
      setState(() {
        _displayText = newText;
        _countdownSeconds = newCd;
      });
      if (textChanged) _hapticForPhase(newText);
    }
  }

  void _onSimpleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_appPhase != _AppPhase.simpleBreath) return;
    _simpleCycles++;
    if (_simpleCycles >= _totalSimpleCycles) {
      // 4 cycles simple -> move to main breath
      _startMainBreath();
    } else {
      setState(() {});
      _simpleController.forward(from: 0.0);
    }
  }

  void _startIntro() {
    // Bypassed 5-second intro to provide immediate relief
    _startSimpleBreath();
  }

  void _advanceIntro() {
    // Deprecated
  }

  void _startSimpleBreath() {
    setState(() {
      _appPhase = _AppPhase.simpleBreath;
      _simpleCycles = 0;
      _displayText = _inhale;
      _countdownSeconds = 4;
      _showHapticHint = true;
    });
    Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showHapticHint = false);
    });
    _simpleController.forward();
  }

  void _startGroundingPhase() {
    setState(() {
      _appPhase = _AppPhase.grounding;
      _groundingTurn = 0;
      _countdownSeconds = 0;
    });
    _simpleController.repeat(); // circle keeps breathing during grounding
  }

  void _advanceOnboardingGrounding() {
    if (!mounted) return;
    final next = _groundingTurn + 1;
    if (next >= _groundingCopy.length) {
      _goHome();
    } else {
      setState(() => _groundingTurn = next);
    }
  }

  int _mainCycles = 0;
  static const int _totalMainCycles = 4;

  void _startMainBreath() {
    setState(() {
      _appPhase = _AppPhase.mainBreath;
      _displayText = _idle;
      _countdownSeconds = 0;
      _mainCycles = 0;
    });
    
    // Listen for cycle completion
    _breathController.addStatusListener(_onMainStatus);
    
    _breathController.forward(from: 0.0);
    _colorController.forward(); // Start dynamic color shift
    _initTrustCard();
    _initIconHints();
    _breathController.addListener(_onBreathTick);
  }
  
  void _onMainStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_appPhase != _AppPhase.mainBreath) return;
    _mainCycles++;
    if (_mainCycles >= _totalMainCycles) {
      _breathController.removeStatusListener(_onMainStatus);
      _startGroundingPhase();
    } else {
      _breathController.forward(from: 0.0);
    }
  }

  // ── Controls ──────────────────────────────────

  void _toggleBreathing() {
    setState(() => _breathingOn = !_breathingOn);
    if (_breathingOn) {
      if (_appPhase == _AppPhase.mainBreath) {
        _breathController.forward(from: _breathController.value == 1.0 ? 0.0 : _breathController.value);
      } else if (_appPhase == _AppPhase.simpleBreath) {
        _simpleController.forward(from: _simpleController.value == 1.0 ? 0.0 : _simpleController.value);
      }
    } else {
      _breathController.stop();
      _simpleController.stop();
      setState(() {
        _countdownSeconds = 0;
        if (!_groundingActive) _displayText = 'Rest here.';
      });
    }
  }

  // ── Reality Grounding ─────────────────────────

void _advanceGrounding() {
    if (!mounted) return;
    _groundingTurn++;
    if (_groundingTurn < _groundingCopy.length) {
      setState(() => _displayText = _groundingCopy[_groundingTurn]);
    } else {
      _endGrounding();
    }
  }

  void _endGrounding() {
    if (!mounted) return;
    setState(() {
      _groundingActive = false;
      _groundingTurn = 0;
      if (!_breathingOn) {
        // 개선 4: 호흡 Off 상태에서 그라운딩 종료 시 "Rest here."
        _displayText = 'Rest here.';
      } else {
        final t = _breathController.value;
        _displayText = t < 0.36 ? _inhale : t < 0.50 ? _topUp : _exhale;
      }
    });
  }

  // ── Trust Card ────────────────────────────────

  Future<void> _initTrustCard() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('trust_card_shown') ?? false;
    if (!shown) {
      _trustCardTimer = Timer(const Duration(seconds: 11), () {
        if (mounted) setState(() => _showTrustCard = true);
      });
      _trustQuoteIndex = DateTime.now().millisecondsSinceEpoch % 3;
    }
  }

  Future<void> _closeTrustCard() async {
    setState(() => _showTrustCard = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trust_card_shown', true);
  }

  // ── 개선 3: 아이콘 힌트 초기화 ────────────────

  Future<void> _initIconHints() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('icon_hints_shown') ?? false;
    if (!shown && mounted) {
      setState(() => _showIconHints = true);
      await prefs.setBool('icon_hints_shown', true);
      _iconHintTimer = Timer(const Duration(milliseconds: 3500), () {
        if (mounted) setState(() => _showIconHints = false);
      });
    }
  }

  // ── Session Log ───────────────────────────────

  Future<void> _writeSessionLog() async {
    final end = DateTime.now();
    final duration = end.difference(_sessionStart ?? end).inSeconds;
    try {
      final prefs = await SharedPreferences.getInstance();
      final newKey = 'session_${end.millisecondsSinceEpoch}';
      final keys = prefs.getStringList('session_keys') ?? [];
      await prefs.setString(
        newKey,
        '${end.toIso8601String()},$duration,$_audioOn,$_breathingOn',
      );
      keys.add(newKey);
      while (keys.length > 30) {
        final oldKey = keys.removeAt(0);
        await prefs.remove(oldKey);
      }
      await prefs.setStringList('session_keys', keys);
    } catch (_) {}
  }

  // ── Home Redirect ─────────────────────────────

  void _goHome() {
    _writeSessionLog();
    _breathController.stop();
    _simpleController.stop();
    HapticFeedback.lightImpact();
    WakelockPlus.disable();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  // ── 개선 3: _buildControl 메서드 ──────────────

  Widget _buildControl({
    required IconData icon,
    required bool active,
    required String label,
    required VoidCallback onTap,
    double? opacity,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              opacity: opacity ?? (active ? 0.85 : 0.28),
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, color: active ? AppColors.iconActive : AppColors.iconInactive, size: 22),
            ),
            const SizedBox(height: 6),
            AnimatedOpacity(
              opacity: _showIconHints ? 1.0 : 0.0, // Always show label if hints are active
              duration: AppDurations.controlTapAnimation, // Use new duration for smoother hint animation
              child: Text(
                label,
                style: AppTextStyles.controlLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (_) => _writeSessionLog(),
      child: Scaffold(
        backgroundColor: _bgColor.value ?? AppColors.backgroundAnxious,
        body: GestureDetector(
          onTap: () {
            if (kIsWeb && _audioReady && !_firstInteractionDone && _audioOn) {
              _audioPlayer.play();
              setState(() => _firstInteractionDone = true);
            }
          },
          child: SafeArea(
            child: Stack(
              children: [
                // ① "Made by Anxiety" — top left, very small
                Positioned(
                  top: 20,
                  left: 20,
                  child: Text(
                    'Made by Anxiety',
                    style: AppTextStyles.groundingHint.copyWith(color: AppColors.textBrand), // Use existing style, adjust color
                  ),
                ),

                // ② Center — phase-specific content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          FluidBreathShape(
                            animation: (_appPhase == _AppPhase.simpleBreath ||
                                    _appPhase == _AppPhase.grounding)
                                ? _simpleScale
                                : _breathScale,
                            fluidColor: _fluidColor.value ?? AppColors.fluidAnxious,
                          ),
                          if ((_appPhase == _AppPhase.simpleBreath || _appPhase == _AppPhase.mainBreath) && _countdownSeconds > 0)
                            Text(
                              '$_countdownSeconds',
                              style: AppTextStyles.breathInstruction.copyWith(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 44),
                      ..._buildCenterContent(),
                    ],
                  ),
                ),

                // ③ Bottom controls — available in both breathing phases
                if (_appPhase == _AppPhase.mainBreath || _appPhase == _AppPhase.simpleBreath)
                  Positioned(
                    bottom: 32,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControl(
                            icon: _audioOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            active: _audioOn,
                            label: 'sound',
                            onTap: _toggleAudio,
                          ),
                          _buildControl(
                            icon: _breathingOn ? Icons.air_rounded : Icons.pause_rounded,
                            active: _breathingOn,
                            label: 'breathing',
                            onTap: _toggleBreathing,
                          ),
                          _buildControl(
                            icon: Icons.anchor,
                            active: true,
                            label: 'anchor',
                            onTap: () {
                              _breathController.stop();
                              _simpleController.stop();
                              _startGroundingPhase();
                            },
                          ),
                          _buildControl(
                            icon: Icons.home_rounded,
                            active: true,
                            label: 'home',
                            onTap: _goHome,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Onboarding grounding tap detector
                if (_appPhase == _AppPhase.grounding)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _advanceOnboardingGrounding,
                    ),
                  ),

                // Grounding tap detector (Stack top layer)
                if (_appPhase == _AppPhase.mainBreath && _groundingActive)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (_groundingTurn >= _groundingCopy.length - 1) {
                          _endGrounding();
                        } else {
                          _advanceGrounding();
                        }
                      },
                    ),
                  ),

                // Trust card (bottom slide-in)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  bottom: _showTrustCard ? 0 : -200,
                  left: 0,
                  right: 0,
                  child: _showTrustCard
                      ? _buildTrustCard()
                      : const SizedBox.shrink(),
                ),

                // 개선 1: Web start overlay — Stack 최상단 (마지막 자식)
                if (_showStartOverlay)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _showStartOverlay = false;
                          _firstInteractionDone = true;
                        });
                        if (_audioReady && _audioOn) _audioPlayer.play();
                        _startIntro(); // Web: intro starts on first tap
                      },
                      child: Container(
                        color: AppColors.background,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Made by Anxiety',
                                style: AppTextStyles.groundingHint.copyWith(color: AppColors.textBrand), // Use existing style, adjust color
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'Tap anywhere\nto begin.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.breathInstruction.copyWith(color: AppColors.textHint), // Use existing style, adjust color
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Center content per phase ──────────────────

  List<Widget> _buildCenterContent() {
    if (_appPhase == _AppPhase.intro) {
      return [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: _introStep == 0
              ? Text(
                  'Get ready.',
                  key: const ValueKey('msg'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.breathInstruction,
                )
              : Text(
                  '${4 - _introStep}',
                  key: ValueKey(_introStep),
                  style: AppTextStyles.breathInstruction.copyWith(
                    fontSize: 56,
                    fontWeight: FontWeight.w100,
                    letterSpacing: 8,
                  ),
                ),
        ),
      ];
    }

    if (_appPhase == _AppPhase.grounding) {
      return [
        AnimatedSwitcher(
          duration: AppDurations.groundingFade,
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Text(
            _groundingCopy[_groundingTurn],
            key: ValueKey(_groundingTurn),
            textAlign: TextAlign.center,
            style: AppTextStyles.groundingText,
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Text(
            _groundingTurn >= _groundingCopy.length - 1
                ? 'tap to finish'
                : 'tap anywhere',
            key: ValueKey('hint_$_groundingTurn'),
            style: AppTextStyles.groundingHint,
          ),
        ),
      ];
    }

    if (_appPhase == _AppPhase.simpleBreath) {
      return [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Text(
            _displayText,
            key: ValueKey(_displayText),
            textAlign: TextAlign.center,
            style: AppTextStyles.breathInstruction,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${_simpleCycles + 1} / $_totalSimpleCycles',
          style: AppTextStyles.groundingHint.copyWith(letterSpacing: 2),
        ),
        AnimatedOpacity(
          opacity: _showHapticHint ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 800),
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              'Hold device for haptics',
              style: AppTextStyles.groundingHint.copyWith(
                color: AppColors.textBrand.withOpacity(0.8),
                letterSpacing: 2.0,
              ),
            ),
          ),
        ),
      ];
    }

    // mainBreath
    return [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: Text(
          _displayText,
          key: ValueKey(_displayText),
          textAlign: TextAlign.center,
          style: AppTextStyles.breathInstruction,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        '${_mainCycles + 1} / $_totalMainCycles',
        style: AppTextStyles.groundingHint.copyWith(letterSpacing: 2),
      ),
      if (_groundingActive) ...[
        const SizedBox(height: 16),
        Text(
          _groundingTurn < 2 ? 'tap anywhere' : 'tap to return',
          style: AppTextStyles.groundingHint,
        ),
      ],
    ];
  }

  // ── Trust Card Widget ──────────────────────────

  Widget _buildTrustCard() {
    final quote = _trustQuotes[_trustQuoteIndex];
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212), // Slightly lighter than background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote.$1,
                  style: AppTextStyles.trustCardQuote,
                ),
                const SizedBox(height: 8),
                Text(
                  '— ${quote.$2}',
                  style: AppTextStyles.trustCardSource,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _closeTrustCard,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, color: AppColors.iconInactive, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
