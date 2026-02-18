import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../theme/app_theme.dart';
import '../constants/grounding_texts.dart';
import '../constants/audio_assets.dart';
import '../widgets/breath_circle.dart';
import 'home_screen.dart';

enum _PanicPhase { breathing, groundingText, cameraGrounding }

class PanicModeScreen extends StatefulWidget {
  const PanicModeScreen({super.key});

  @override
  State<PanicModeScreen> createState() => _PanicModeScreenState();
}

class _PanicModeScreenState extends State<PanicModeScreen>
    with TickerProviderStateMixin {
  _PanicPhase _phase = _PanicPhase.breathing;

  // ── Phase 1: 호흡 ──────────────────────────────
  late AnimationController _breathController;
  late Animation<double> _breathScale;
  String _breathPhase = '코로 들이마세요';
  bool _canAdvance = false; // 22초 후 활성화
  Timer? _advanceTimer;

  // ── 오디오 ─────────────────────────────────────
  late AudioPlayer _audioPlayer;
  int _soundIndex = 0;

  // ── Phase 2: 그라운딩 텍스트 ───────────────────
  int _groundingIndex = 0;

  // ── Phase 3: 카메라 그라운딩 ───────────────────
  static const _missions = [
    '빨간색(또는 파란색) 물건을\n하나 찾아서 바라보세요',
    '지금 눈앞에서\n가장 큰 물건은 무엇인가요?',
    '창문이나 문이 보이나요?\n그쪽으로 시선을 옮겨보세요',
  ];

  CameraController? _cameraController;
  bool _cameraInitialized = false;
  bool _hasCameraPermission = false;
  int _missionIndex = 0;
  bool _missionComplete = false;
  Timer? _cameraTimer; // 3분 후 Phase 2 복귀

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _initAudio();
    _initBreathing();
    HapticFeedback.mediumImpact();

    // 최소 2사이클(22초) 후 "다음" 버튼 활성화
    _advanceTimer = Timer(const Duration(seconds: 22), () {
      if (mounted) setState(() => _canAdvance = true);
    });
  }

  // ── 오디오 ──────────────────────────────────────

  Future<void> _initAudio() async {
    _audioPlayer = AudioPlayer();
    await _audioPlayer.setAsset(AudioAssets.options[_soundIndex].path);
    await _audioPlayer.setLoopMode(LoopMode.one);
    await _audioPlayer.setVolume(0.6);
    await _audioPlayer.play();
  }

  Future<void> _switchSound(int index) async {
    if (index == _soundIndex) return;
    setState(() => _soundIndex = index);
    await _audioPlayer.setAsset(AudioAssets.options[index].path);
    await _audioPlayer.play();
  }

  // ── Phase 1: 호흡 ───────────────────────────────

  void _initBreathing() {
    // 생리적 한숨: 들이마시기(4s) → 짧은 추가 흡기(1.5s) → 내쉬기(6s) = 11s 1사이클
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    );

    _breathScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.5)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 55,
      ),
    ]).animate(_breathController);

    _breathController.repeat();
    _breathController.addListener(_onBreathTick);
  }

  void _onBreathTick() {
    final t = _breathController.value;
    String phase;
    if (t < 0.36) {
      phase = '코로 들이마세요';
    } else if (t < 0.50) {
      phase = '한 번 더 흡입';
    } else {
      phase = '천천히 내쉬어요';
    }
    if (phase != _breathPhase) {
      setState(() => _breathPhase = phase);
      _hapticForPhase(phase);
    }
  }

  void _hapticForPhase(String phase) {
    if (phase == '한 번 더 흡입') {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _goToGrounding() {
    _advanceTimer?.cancel();
    _breathController.removeListener(_onBreathTick);
    setState(() {
      _phase = _PanicPhase.groundingText;
    });
  }

  // ── Phase 2: 그라운딩 텍스트 ────────────────────

  void _nextGrounding() {
    setState(() {
      _groundingIndex = (_groundingIndex + 1) % groundingTexts.length;
    });
  }

  // ── Phase 3: 카메라 ─────────────────────────────

  Future<void> _goToCamera() async {
    // 웹은 색상 스캔 모드
    if (kIsWeb) {
      setState(() {
        _phase = _PanicPhase.cameraGrounding;
        _hasCameraPermission = false;
      });
      _startCameraTimer();
      return;
    }

    final status = await Permission.camera.status;
    if (status.isGranted) {
      await _initCamera();
    } else {
      // 권한 없음 → 색상 스캔 모드 (Panic Mode 중 권한 팝업 금지)
      setState(() {
        _phase = _PanicPhase.cameraGrounding;
        _hasCameraPermission = false;
      });
      _startCameraTimer();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _fallbackToColorScan();
        return;
      }
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _phase = _PanicPhase.cameraGrounding;
        _hasCameraPermission = true;
        _cameraInitialized = true;
      });
      _startCameraTimer();
    } catch (_) {
      _fallbackToColorScan();
    }
  }

  void _fallbackToColorScan() {
    if (!mounted) return;
    setState(() {
      _phase = _PanicPhase.cameraGrounding;
      _hasCameraPermission = false;
    });
    _startCameraTimer();
  }

  void _startCameraTimer() {
    // 3분 경과 → 카메라 자동 종료 → Phase 2로 복귀
    _cameraTimer = Timer(const Duration(minutes: 3), () {
      if (!mounted) return;
      _disposeCamera();
      setState(() {
        _phase = _PanicPhase.groundingText;
        _missionIndex = 0;
        _missionComplete = false;
      });
    });
  }

  void _disposeCamera() {
    _cameraTimer?.cancel();
    _cameraController?.dispose();
    _cameraController = null;
    _cameraInitialized = false;
  }

  void _nextMission() {
    if (_missionIndex < _missions.length - 1) {
      setState(() => _missionIndex++);
    } else {
      setState(() => _missionComplete = true);
    }
  }

  // ── 종료 ────────────────────────────────────────

  void _exitPanicMode() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '괜찮아졌나요?',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: const Text(
          '조금 더 있고 싶으면 아래 버튼을 눌러요.',
          style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '더 있을게요',
              style: TextStyle(color: Color(0xB3FFFFFF)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _disposeCamera();
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const HomeScreen(),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                  transitionDuration: AppDurations.screenTransition,
                ),
              );
            },
            child: const Text(
              '나갈게요',
              style: TextStyle(color: AppColors.sos),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _breathController.removeListener(_onBreathTick);
    _breathController.dispose();
    _audioPlayer.dispose();
    _disposeCamera();
    WakelockPlus.disable();
    super.dispose();
  }

  // ── 빌드 ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _exitPanicMode(),
      child: Scaffold(
        backgroundColor: AppColors.panicBg,
        body: SafeArea(
          child: switch (_phase) {
            _PanicPhase.breathing => _buildBreathingPhase(),
            _PanicPhase.groundingText => _buildGroundingPhase(),
            _PanicPhase.cameraGrounding => _buildCameraPhase(),
          },
        ),
      ),
    );
  }

  // ── Phase 1 UI ──────────────────────────────────

  Widget _buildBreathingPhase() {
    return Stack(
      children: [
        // 호흡 원
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BreathCircle(animation: _breathScale),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: AppDurations.groundingFade,
                child: Text(
                  _breathPhase,
                  key: ValueKey(_breathPhase),
                  style: AppTextStyles.breathInstruction,
                ),
              ),
            ],
          ),
        ),

        // 소리 선택 (좌상단)
        Positioned(
          top: 12,
          left: 16,
          child: _buildSoundSelector(),
        ),

        // 안정됐어요 (우상단)
        Positioned(
          top: 12,
          right: 16,
          child: TextButton(
            onPressed: _exitPanicMode,
            child: const Text(
              '안정됐어요',
              style: TextStyle(color: Color(0x66FFFFFF), fontSize: 14),
            ),
          ),
        ),

        // 다음 버튼 — 22초 후 페이드 인
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedOpacity(
              opacity: _canAdvance ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: GestureDetector(
                onTap: _canAdvance ? _goToGrounding : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    '다음  →',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Phase 2 UI ──────────────────────────────────

  Widget _buildGroundingPhase() {
    return Stack(
      children: [
        // 그라운딩 텍스트 (중앙)
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: GestureDetector(
              onTap: _nextGrounding,
              child: AnimatedSwitcher(
                duration: AppDurations.groundingFade,
                child: Column(
                  key: ValueKey(_groundingIndex),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      groundingTexts[_groundingIndex],
                      textAlign: TextAlign.center,
                      style: AppTextStyles.groundingText,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '탭해서 다음',
                      style: AppTextStyles.groundingHint,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 소리 선택 (좌상단)
        Positioned(
          top: 12,
          left: 16,
          child: _buildSoundSelector(),
        ),

        // 안정됐어요 (우상단)
        Positioned(
          top: 12,
          right: 16,
          child: TextButton(
            onPressed: _exitPanicMode,
            child: const Text(
              '안정됐어요',
              style: TextStyle(color: Color(0x66FFFFFF), fontSize: 14),
            ),
          ),
        ),

        // 카메라로 주변 보기 (하단)
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: OutlinedButton.icon(
              onPressed: _goToCamera,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text(
                '카메라로 주변 보기',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Phase 3 UI ──────────────────────────────────

  Widget _buildCameraPhase() {
    return Stack(
      children: [
        // 배경: 카메라 프리뷰 또는 단색(색상 스캔 모드)
        if (_hasCameraPermission && _cameraInitialized && _cameraController != null)
          Positioned.fill(
            child: CameraPreview(_cameraController!),
          )
        else
          Positioned.fill(
            child: Container(color: AppColors.panicBg),
          ),

        // 미션 오버레이
        if (!_missionComplete)
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Column(
                  key: ValueKey(_missionIndex),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 색상 스캔 모드 안내 (카메라 없을 때)
                    if (!_hasCameraPermission) ...[
                      const Text(
                        '지금 방 안에서\n파란색 물건을 3개 찾아보세요',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => setState(() => _missionComplete = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white38),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '찾았어요  →',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ),
                    ] else ...[
                      // 카메라 미션
                      Text(
                        '미션 ${_missionIndex + 1} / ${_missions.length}',
                        style: TextStyle(
                          color: AppColors.sos.withOpacity(0.8),
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _missions[_missionIndex],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _nextMission,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white38),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '찾았어요  →',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
        else
          // 미션 완료 → 안정됐어요 버튼
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '잘 하셨어요',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _exitPanicMode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sos,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '안정됐어요',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 뒤로 버튼 (좌상단)
        Positioned(
          top: 12,
          left: 8,
          child: TextButton.icon(
            onPressed: () {
              _disposeCamera();
              setState(() {
                _phase = _PanicPhase.groundingText;
                _missionIndex = 0;
                _missionComplete = false;
              });
            },
            icon: const Icon(Icons.arrow_back_ios,
                color: Colors.white54, size: 15),
            label: const Text(
              '뒤로',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ── 공통 위젯 ────────────────────────────────────

  Widget _buildSoundSelector() {
    return Row(
      children: List.generate(AudioAssets.options.length, (i) {
        final selected = i == _soundIndex;
        return GestureDetector(
          onTap: () => _switchSound(i),
          child: AnimatedContainer(
            duration: AppDurations.tapResponse,
            margin: const EdgeInsets.only(right: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: selected
                  ? Colors.white.withOpacity(0.15)
                  : Colors.transparent,
              border: Border.all(
                color: Colors.white.withOpacity(selected ? 0.4 : 0.15),
                width: 1,
              ),
            ),
            child: Text(
              AudioAssets.options[i].label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(selected ? 1.0 : 0.4),
              ),
            ),
          ),
        );
      }),
    );
  }
}
