import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/breathing_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const MadeByAnxietyApp());
}

class MadeByAnxietyApp extends StatelessWidget {
  const MadeByAnxietyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Made by Anxiety',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const BreathingScreen(),
    );
  }
}
