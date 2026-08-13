import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'onboarding_screen.dart';
import '../navigation/main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(
      const Duration(seconds: 3),
    );

    if (!mounted) return;

    final settingsBox = Hive.box('settings_box');

    final bool hasSeenOnboarding =
        settingsBox.get(
          'hasSeenOnboarding',
          defaultValue: false,
        );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) {
          if (hasSeenOnboarding) {
            return const MainNavigation();
          }

          return const OnboardingScreen();
        },
        transitionDuration: const Duration(
          milliseconds: 400,
        ),
        transitionsBuilder: (
          _,
          animation,
          __,
          child,
        ) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: SizedBox.expand(
        child: Image(
          image: AssetImage(
            'assets/images/lg_splash_screen.png',
          ),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}