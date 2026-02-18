import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../theme/app_theme.dart';
import '../constants/audio_assets.dart';
import '../widgets/breath_circle.dart';

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

  static const _inhale = 'Breathe in.';
  static const _topUp = 'And in.';
  static const _exhale = 'Out.';
  static const _idle = 'Breathe right now.';

  String _displayText = _idle;
  int _countdownSeconds = 0;

  // ── Onboarding phase ───────────────────────────
  _AppPhase _appPhase = _AppPhase.intro;
  int _introStep = 0; // 0=message, 1/2/3=count
  Timer? _introTimer;
  late AnimationController _simpleController;
  late Animation<double> _simpleScale;
  int _simpleCycles = 0;
  static const int _totalSimpleCycles = 5;

  // ── Controls ───────────────────────────────────
  bool _breathingOn = true;
  bool _audioOn = true;

  // ── Reality Grounding ──────────────────────────
  bool _groundingActive = false;
  int _groundingTurn = 0;

  static const _groundingCopy = [
    'Name one thing\nyou can see.',
    'One more thing\nyou can see.',
    "That's enough.\nStay here.",
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

  // ── 개선 1: Web start overlay ──────────────────
  bool _showStartOverlay = kIsWeb;

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
    // trust card / icon hints are started in _startMainBreath()

    // Web: intro starts after user tap. Native: start immediately.
    if (!kIsWeb) _startIntro();
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
    _audioPlayer.dispose();
    _trustCardTimer?.cancel();
    _breathStartTimer?.cancel();
    _iconHintTimer?.cancel();
    _introTimer?.cancel();
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
    if (phase == _topUp) {
      HapticFeedback.selectionClick();
    } else {
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
    final newText = t < 0.5 ? _inhale : 'Breathe out.';
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
      if (textChanged) HapticFeedback.lightImpact();
    }
  }

  void _onSimpleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_appPhase != _AppPhase.simpleBreath) return;
    _simpleCycles++;
    if (_simpleCycles >= _totalSimpleCycles) {
      _startGroundingPhase();
    } else {
      setState(() {});
      _simpleController.forward(from: 0.0);
    }
  }

  void _startIntro() {
    _introTimer = Timer(const Duration(seconds: 2), _advanceIntro);
  }

  void _advanceIntro() {
    if (!mounted) return;
    setState(() => _introStep++);
    if (_introStep < 4) {
      _introTimer = Timer(const Duration(seconds: 1), _advanceIntro);
    } else {
      _startSimpleBreath();
    }
  }

  void _startSimpleBreath() {
    setState(() {
      _appPhase = _AppPhase.simpleBreath;
      _simpleCycles = 0;
      _displayText = _inhale;
      _countdownSeconds = 4;
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
      _startMainBreath();
    } else {
      setState(() => _groundingTurn = next);
    }
  }

  void _startMainBreath() {
    setState(() {
      _appPhase = _AppPhase.mainBreath;
      _displayText = _idle;
      _countdownSeconds = 0;
    });
    _breathController.repeat();
    _initTrustCard();
    _initIconHints();
    _breathStartTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) _breathController.addListener(_onBreathTick);
    });
  }

  // ── Controls ──────────────────────────────────

  void _toggleBreathing() {
    setState(() => _breathingOn = !_breathingOn);
    if (_breathingOn) {
      _breathController.repeat();
    } else {
      _breathController.stop();
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

  // ── Exit ──────────────────────────────────────

  void _exit() {
    _writeSessionLog();
    if (!kIsWeb) {
      SystemNavigator.pop();
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
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 6),
            AnimatedOpacity(
              opacity: _showIconHints ? 0.35 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.5,
                ),
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
        backgroundColor: AppColors.background,
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
                const Positioned(
                  top: 20,
                  left: 20,
                  child: Text(
                    'Made by Anxiety',
                    style: TextStyle(
                      color: AppColors.textBrand,
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                // ② Center — phase-specific content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BreathCircle(
                        animation: (_appPhase == _AppPhase.simpleBreath ||
                                _appPhase == _AppPhase.grounding)
                            ? _simpleScale
                            : _breathScale,
                        countdown: _appPhase == _AppPhase.simpleBreath
                            ? _countdownSeconds
                            : 0,
                      ),
                      const SizedBox(height: 44),
                      ..._buildCenterContent(),
                    ],
                  ),
                ),

                // ③ Bottom controls — only in mainBreath
                if (_appPhase == _AppPhase.mainBreath)
                  Positioned(
                    bottom: 32,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildControl(
                          icon: _audioOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          active: _audioOn,
                          label: 'sound',
                          onTap: _toggleAudio,
                        ),
                        const SizedBox(width: 36),
                        _buildControl(
                          icon: _breathingOn ? Icons.air_rounded : Icons.pause_rounded,
                          active: _breathingOn,
                          label: 'breathing',
                          onTap: _toggleBreathing,
                        ),
                        const SizedBox(width: 36),
                        _buildControl(
                          icon: Icons.close_rounded,
                          active: false,
                          label: 'leave',
                          opacity: kIsWeb ? 0.1 : 0.28,
                          onTap: _exit,
                        ),
                      ],
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
                              const Text(
                                'Made by Anxiety',
                                style: TextStyle(
                                  color: Color(0x30FFFFFF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'Tap anywhere\nto begin.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.45),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w300,
                                  height: 1.9,
                                  letterSpacing: 0.3,
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
              ? const Text(
                  'Focus on\nyour breathing.',
                  key: ValueKey('msg'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    height: 1.6,
                    letterSpacing: 0.3,
                  ),
                )
              : Text(
                  '$_introStep',
                  key: ValueKey(_introStep),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
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
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Text(
            _groundingCopy[_groundingTurn],
            key: ValueKey(_groundingTurn),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w300,
              height: 1.6,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'tap anywhere',
          style: TextStyle(
            color: Color(0x33FFFFFF),
            fontSize: 11,
            fontWeight: FontWeight.w300,
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
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w300,
              height: 1.6,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${_simpleCycles + 1} of $_totalSimpleCycles',
          style: const TextStyle(
            color: Color(0x33FFFFFF),
            fontSize: 12,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
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
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w300,
            height: 1.6,
            letterSpacing: 0.3,
          ),
        ),
      ),
      if (_groundingActive) ...[
        const SizedBox(height: 16),
        Text(
          _groundingTurn < 2 ? 'tap anywhere' : 'tap to return',
          style: const TextStyle(
            color: Color(0x33FFFFFF),
            fontSize: 11,
            fontWeight: FontWeight.w300,
          ),
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
        color: const Color(0xFF1C1C1C),
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
                  style: const TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '— ${quote.$2}',
                  style: const TextStyle(
                    color: Color(0x66FFFFFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _closeTrustCard,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, color: Color(0x4DFFFFFF), size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
