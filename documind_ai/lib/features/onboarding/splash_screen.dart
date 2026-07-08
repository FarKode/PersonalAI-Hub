import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/ai_provider.dart';
import '../../main.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    // Only wait for the 2-second timer. Do NOT block on SecureStorage/API keys initialization
    // because Android KeyStore can deadlock/hang on warm starts, causing a permanent black screen.
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    // Read SharedPreferences synchronously from Riverpod since it was already loaded in main()
    final prefs = ref.read(sharedPreferencesProvider);
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    if (hasSeenOnboarding) {
      if (mounted) context.go('/dashboard');
    } else {
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // AMOLED Black
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for the App Logo
            Image.asset(
              'assets/images/app_logo.png',
              width: 120,
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.psychology,
                  size: 120,
                  color: AppTheme.electricBlue,
                );
              },
            ).animate().fade(duration: 800.ms).scale(curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            const Text(
              'PersonalAI Hub',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ).animate().fade(delay: 400.ms, duration: 800.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
}
