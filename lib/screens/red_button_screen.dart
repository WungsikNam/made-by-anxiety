import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'panic_mode_screen.dart';

class RedButtonScreen extends StatefulWidget {
  const RedButtonScreen({super.key});

  @override
  State<RedButtonScreen> createState() => _RedButtonScreenState();
}

class _RedButtonScreenState extends State<RedButtonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    // 버튼 살아있음을 느끼게 하는 미세한 pulse 애니메이션
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onButtonTap() async {
    setState(() => _isPressed = true);
    await Future.delayed(AppDurations.tapResponse);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PanicModeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: AppDurations.screenTransition,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    // 모바일: 너비 72%, 태블릿/웹 세로: 최대 360px, 가로: 높이 기준 60%
    final buttonSize = isLandscape
        ? (size.height * 0.60).clamp(200.0, 340.0)
        : (size.width * 0.72).clamp(200.0, 360.0);

    return Scaffold(
      backgroundColor: AppColors.mainBg,
      body: SafeArea(
        child: Center(
          child: GestureDetector(
            onTap: _onButtonTap,
            child: AnimatedScale(
              scale: _isPressed ? 0.94 : 1.0,
              duration: AppDurations.tapResponse,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, __) => Transform.scale(
                  scale: _isPressed ? 1.0 : _pulseAnimation.value,
                  child: Container(
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.sos,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sos.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '도와줘',
                          style: AppTextStyles.sosLabel,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'SOS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textSecondary,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
