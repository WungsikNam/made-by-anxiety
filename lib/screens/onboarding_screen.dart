import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 생리적 한숨 시연 애니메이션
  late AnimationController _breathController;
  late Animation<double> _breathAnim;
  String _breathPhase = '코로 들이마세요';

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat();

    _breathAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.3, end: 0.8)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.8, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.3)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 55,
      ),
    ]).animate(_breathController);

    _breathController.addListener(() {
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
      }
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _requestCameraAndFinish() async {
    if (!kIsWeb) {
      await Permission.camera.request();
    }
    await _finish();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: AppDurations.screenTransition,
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '개인정보처리방침',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: const SingleChildScrollView(
          child: Text(
            '• 카메라: 그라운딩 화면(뷰파인더) 표시 목적으로만 사용됩니다.\n\n'
            '• 사진 촬영 및 저장을 하지 않습니다.\n\n'
            '• 카메라 영상은 기기 외부로 전송되지 않습니다.\n\n'
            '• 서버 없이 기기에서만 동작하는 앱입니다.\n\n'
            '• 수집하는 개인정보가 없습니다.',
            style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 14, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: AppColors.sos)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0,
      onPopInvoked: (didPop) {
        if (!didPop && _currentPage > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.mainBg,
        body: SafeArea(
          child: Column(
            children: [
              // 페이지 인디케이터
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(2, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentPage == i
                            ? AppColors.sos
                            : Colors.white.withOpacity(0.25),
                      ),
                    );
                  }),
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _buildPage1(),
                    _buildPage2(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Panic Zero',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '공황이 오는 순간, 버튼 하나',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 48),

          // 생리적 한숨 시연 애니메이션
          AnimatedBuilder(
            animation: _breathAnim,
            builder: (_, __) {
              final size = _breathAnim.value * 160;
              return SizedBox(
                width: 200,
                height: 200,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: size + 20,
                        height: size + 20,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.breathCircleGlow,
                        ),
                      ),
                      Container(
                        width: size,
                        height: size,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.breathCircle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _breathPhase,
              key: ValueKey(_breathPhase),
              style: AppTextStyles.breathInstruction,
            ),
          ),

          const SizedBox(height: 32),
          Text(
            '생리적 한숨 — 코로 2번 들이쉬고\n천천히 길게 내쉬면 공황 증상이 빠르게 완화됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 13,
              height: 1.7,
            ),
          ),

          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sos,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                '다음',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            color: Colors.white54,
            size: 56,
          ),
          const SizedBox(height: 24),
          const Text(
            '주변을 보여주세요',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '공황 상태에서는 현실 세계에 집중하는 것이\n도움이 됩니다. 카메라 뷰파인더로\n주변을 바라보는 그라운딩 기능을 제공합니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 14,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, color: Colors.white38, size: 16),
                const SizedBox(width: 8),
                Text(
                  '사진 촬영 없음  ·  저장 없음  ·  전송 없음',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.38),
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showPrivacyPolicy,
            child: Text(
              '개인정보처리방침 보기',
              style: TextStyle(
                color: AppColors.sos.withOpacity(0.7),
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.sos.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _requestCameraAndFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sos,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                '시작하기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _finish,
            child: Text(
              '카메라 없이 시작',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
