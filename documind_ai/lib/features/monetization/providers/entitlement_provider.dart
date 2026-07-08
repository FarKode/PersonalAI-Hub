import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart'; // import sharedPreferencesProvider

final entitlementProvider = NotifierProvider<EntitlementNotifier, bool>(() {
  return EntitlementNotifier();
});

class EntitlementNotifier extends Notifier<bool> {
  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool('isPro') ?? false;
  }

  Future<void> unlockPro() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('isPro', true);
    state = true;
  }
}
