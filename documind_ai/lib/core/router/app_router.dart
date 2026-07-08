import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dashboard/agents/document_mind_screen.dart';
import '../../features/dashboard/agents/email_crafter_screen.dart';
import '../../features/dashboard/agents/language_tutor_screen.dart';
import '../../features/dashboard/agents/quick_chat_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/api_guide_screen.dart';
import '../../features/history/history_screen.dart';
import '../../main.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  // Read SharedPreferences SYNCHRONOUSLY (it was pre-loaded in main() before runApp).
  // This is the KEY fix: initialLocation is resolved instantly with zero async delay.
  // No matter how many times the app warm-starts, GoRouter will NEVER show the splash
  // screen again to a returning user. It jumps straight to the correct screen.
  final prefs = ref.read(sharedPreferencesProvider);
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  // If user has completed onboarding → go straight to dashboard.
  // If first-ever cold start → show splash (which then goes to onboarding).
  final initialLocation = hasSeenOnboarding ? '/dashboard' : '/splash';

  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) {
          final filter = state.extra as String?;
          return HistoryScreen(initialFilter: filter);
        },
      ),
      GoRoute(
        path: '/document-mind',
        builder: (context, state) => const DocumentMindScreen(),
      ),
      GoRoute(
        path: '/email-crafter',
        builder: (context, state) => const EmailCrafterScreen(),
      ),
      GoRoute(
        path: '/language-tutor',
        builder: (context, state) => const LanguageTutorScreen(),
      ),
      GoRoute(
        path: '/quick-chat',
        builder: (context, state) => const QuickChatScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ChatScreen(
            docId: extra['docId'] as int,
            docName: extra['docName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/api-guide',
        builder: (context, state) => const ApiGuideScreen(),
      ),
    ],
  );
});
