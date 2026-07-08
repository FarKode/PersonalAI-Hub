import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'objectbox.g.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

late Store obxStore;

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize ObjectBox DB
  final docsDir = await getApplicationDocumentsDirectory();
  obxStore = await openStore(directory: p.join(docsDir.path, "obx-documind"));

  // Load SharedPreferences synchronously for instant startup state

  // Load SharedPreferences synchronously for instant startup state
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const PersonalAIApp(),
    ),
  );
}

class PersonalAIApp extends ConsumerWidget {
  const PersonalAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'PersonalAI Hub',
      restorationScopeId: null, // Disable state restoration to prevent black screen on warm start
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
