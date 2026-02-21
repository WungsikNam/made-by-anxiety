import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/fluid_breath_shape.dart';
import 'breathing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _idleController;
  late Animation<double> _idleScale;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _idleScale = Tween<double>(begin: 0.8, end: 0.9).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );
    
    _textOpacity = Tween<double>(begin: 0.15, end: 0.75).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  void _startSession() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const BreathingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundAnxious,
      body: GestureDetector(
        onTap: _startSession,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Background Fluid Effect
            Center(
               child: FluidBreathShape(
                  animation: _idleScale,
                  fluidColor: AppColors.fluidAnxious,
               ),
            ),
            
            // Centered Pulsing Text (Exactly in the middle of the ring)
            Center(
              child: AnimatedBuilder(
                animation: _textOpacity,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textOpacity.value,
                    child: child,
                  );
                },
                child: Text(
                  'tap anywhere to anchor',
                  style: AppTextStyles.breathInstruction.copyWith(
                    fontSize: 14,
                    color: AppColors.textPrimary.withOpacity(0.5),
                    letterSpacing: 3.0,
                  ),
                ),
              ),
            ),
            
            // Top Text Elements
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.08),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'MADE BY ANXIETY',
                        style: AppTextStyles.groundingHint.copyWith(
                          color: AppColors.textBrand,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 6.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Your Digital Anchor\nFor Panic & Overwhelm',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.breathInstruction.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.7),
                          fontSize: 16,
                          height: 1.6,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

