import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'breathing_screen.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _bgController;
  late Animation<Color?> _topColorAnim;
  late Animation<Color?> _bottomColorAnim;

  late AnimationController _rippleController;
  late Animation<double> _rippleScale;
  late Animation<double> _rippleOpacity;

  @override
  void initState() {
    super.initState();
    
    // Background dynamic breathing gradient animation
    _bgController = AnimationController(
       vsync: this, 
       duration: const Duration(seconds: 6)
    )..repeat(reverse: true);

    _topColorAnim = ColorTween(
      begin: const Color(0xFF070B19), // Deep midnight black-blue
      end: const Color(0xFF162545),   // Soft navy
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOutSine));

    _bottomColorAnim = ColorTween(
      begin: const Color(0xFF8B4B38).withOpacity(0.8), // Muted dark orange
      end: const Color(0xFFD67754).withOpacity(0.9),   // Soft dawn orange
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOutSine));

    // Ripple wave animation on click
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _rippleScale = Tween<double>(begin: 1.0, end: 4.5).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOutCubic),
    );
    _rippleOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _onBreatheTapped() {
    HapticFeedback.mediumImpact();
    _rippleController.forward(from: 0.0);
    
    // Wait for ripple to expand and engulf the screen, then transition seamlessly
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const BreathingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch constraints check
    final isWatch = MediaQuery.of(context).size.height < 400 || MediaQuery.of(context).size.width < 300;
    final double buttonSize = isWatch ? 110 : 160;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _topColorAnim.value ?? Colors.black,
                  _bottomColorAnim.value ?? Colors.black,
                ],
              ),
            ),
            child: child,
          );
        },
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ripple Effect Layer
              AnimatedBuilder(
                animation: _rippleController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _rippleScale.value,
                    child: Opacity(
                      opacity: _rippleOpacity.value,
                      child: Container(
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFD67754).withOpacity(0.5), // Dawn orange glow wave
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Central 'Breathe' Tactical Button
              GestureDetector(
                onTap: _onBreatheTapped,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Glassmorphism effect mimicking a premium UI
                    color: Colors.white.withOpacity(0.04),
                    border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 25,
                        spreadRadius: 2,
                      )
                    ]
                  ),
                  child: Center(
                    child: Text(
                      'Breathe',
                      style: AppTextStyles.breathInstruction.copyWith(
                        fontSize: isWatch ? 18 : 24,
                        letterSpacing: 3.0,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
