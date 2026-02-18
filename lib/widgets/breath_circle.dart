import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BreathCircle extends StatelessWidget {
  final Animation<double> animation;
  final int countdown;

  const BreathCircle({
    super.key,
    required this.animation,
    this.countdown = 0,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    // 가로 모드: 높이 기준, 세로 모드: 너비 기준. 최대 280px
    final maxSize = isLandscape
        ? (screenSize.height * 0.50).clamp(160.0, 280.0)
        : (screenSize.width * 0.60).clamp(160.0, 280.0);

    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final size = maxSize * animation.value;
        return SizedBox(
          width: maxSize + 40,
          height: maxSize + 40,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 외부 글로우
                Container(
                  width: size + 24,
                  height: size + 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.breathCircleGlow,
                  ),
                ),
                // 메인 원
                Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.breathCircle,
                  ),
                ),
                // 원 안 카운트다운
                if (countdown > 0)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Text(
                      '$countdown',
                      key: ValueKey(countdown),
                      style: const TextStyle(
                        color: Color(0x55FFFFFF),
                        fontSize: 36,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
