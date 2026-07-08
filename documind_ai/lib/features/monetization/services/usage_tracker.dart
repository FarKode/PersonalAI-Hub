import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/entitlement_provider.dart';

final usageTrackerProvider = Provider((ref) {
  final isPro = ref.watch(entitlementProvider);
  return UsageTracker(isPro);
});

class UsageTracker {
  final bool isPro;
  
  static const String _lastDateKey = 'tracker_last_date';
  
  static const String _quickChatKey = 'count_quick_chat';
  static const String _docDocsKey = 'count_doc_docs';
  static const String _docMsgKey = 'count_doc_msg';
  static const String _emailKey = 'count_email';
  static const String _tutorKey = 'count_tutor';
  static const String _voiceKey = 'count_voice';

  UsageTracker(this.isPro);

  Future<void> _checkAndResetDaily() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastDate = prefs.getString(_lastDateKey) ?? '';

    if (lastDate != today) {
      await prefs.setInt(_quickChatKey, 0);
      await prefs.setInt(_docDocsKey, 0);
      await prefs.setInt(_docMsgKey, 0);
      await prefs.setInt(_emailKey, 0);
      await prefs.setInt(_tutorKey, 0);
      await prefs.setInt(_voiceKey, 0);
      await prefs.setString(_lastDateKey, today);
    }
  }

  // --- Check Methods ---

  Future<bool> canUseQuickChat() async {
    if (isPro) return true;
    await _checkAndResetDaily();
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_quickChatKey) ?? 0) < 5;
  }

  Future<bool> canProcessDocument() async {
    if (isPro) return true;
    await _checkAndResetDaily();
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_docDocsKey) ?? 0) < 1;
  }

  Future<bool> canSendDocumentMessage() async {
    if (isPro) return true;
    await _checkAndResetDaily();
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_docMsgKey) ?? 0) < 3;
  }

  Future<bool> canUseEmailCrafter() async {
    if (isPro) return true;
    await _checkAndResetDaily();
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_emailKey) ?? 0) < 1;
  }

  Future<bool> canUseLanguageTutor() async {
    if (isPro) return true;
    await _checkAndResetDaily();
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_tutorKey) ?? 0) < 1;
  }

  Future<bool> canUseVoice() async {
    if (isPro) return true;
    await _checkAndResetDaily();
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_voiceKey) ?? 0) < 1;
  }

  bool canUseCustomPersona() {
    return isPro; // Blocked entirely for free users
  }

  // --- Increment Methods ---

  Future<void> _increment(String key) async {
    if (isPro) return;
    await _checkAndResetDaily();
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  Future<void> incrementQuickChat() => _increment(_quickChatKey);
  Future<void> incrementDocumentCount() => _increment(_docDocsKey);
  Future<void> incrementDocumentMessage() => _increment(_docMsgKey);
  Future<void> incrementEmailCrafter() => _increment(_emailKey);
  Future<void> incrementLanguageTutor() => _increment(_tutorKey);
  Future<void> incrementVoiceUsage() => _increment(_voiceKey);
}
