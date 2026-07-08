import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final apiUsageTrackerProvider = Provider((ref) => ApiUsageTracker());

class ApiUsageTracker {
  static const String _totalRequestsKey = 'api_total_requests';
  static const String _todayRequestsKey = 'api_today_requests';
  static const String _lastDateKey = 'api_last_date';

  Future<void> incrementUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastDate = prefs.getString(_lastDateKey) ?? '';

    int total = prefs.getInt(_totalRequestsKey) ?? 0;
    int todayCount = prefs.getInt(_todayRequestsKey) ?? 0;

    if (lastDate != today) {
      todayCount = 0;
      await prefs.setString(_lastDateKey, today);
    }

    await prefs.setInt(_totalRequestsKey, total + 1);
    await prefs.setInt(_todayRequestsKey, todayCount + 1);
  }

  Future<Map<String, int>> getUsageStats() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastDate = prefs.getString(_lastDateKey) ?? '';

    int total = prefs.getInt(_totalRequestsKey) ?? 0;
    int todayCount = prefs.getInt(_todayRequestsKey) ?? 0;

    if (lastDate != today) {
      todayCount = 0;
    }

    return {
      'total': total,
      'today': todayCount,
    };
  }
}
