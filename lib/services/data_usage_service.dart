import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DailyUsage {
  final String date;
  final int downloadBytes;
  final int uploadBytes;

  DailyUsage({
    required this.date,
    required this.downloadBytes,
    required this.uploadBytes,
  });

  int get totalBytes => downloadBytes + uploadBytes;

  Map<String, dynamic> toJson() => {
    'date': date,
    'download': downloadBytes,
    'upload': uploadBytes,
  };

  factory DailyUsage.fromJson(Map<String, dynamic> json) => DailyUsage(
    date: json['date'] ?? '',
    downloadBytes: json['download'] ?? 0,
    uploadBytes: json['upload'] ?? 0,
  );
}

class DataUsageService {
  static const _key = 'data_usage';

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static Future<Map<String, DailyUsage>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, DailyUsage.fromJson(v)));
  }

  static Future<void> _save(Map<String, DailyUsage> data) async {
    final prefs = await SharedPreferences.getInstance();
    final map = data.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_key, jsonEncode(map));
  }

  static Future<void> addUsage(int downloadBytes, int uploadBytes) async {
    if (downloadBytes <= 0 && uploadBytes <= 0) return;
    final data = await _load();
    final today = _today();
    final existing = data[today];
    data[today] = DailyUsage(
      date: today,
      downloadBytes: (existing?.downloadBytes ?? 0) + downloadBytes,
      uploadBytes: (existing?.uploadBytes ?? 0) + uploadBytes,
    );
    // Keep only last 30 days
    if (data.length > 30) {
      final keys = data.keys.toList()..sort();
      for (final key in keys.take(data.length - 30)) {
        data.remove(key);
      }
    }
    await _save(data);
  }

  static Future<List<DailyUsage>> getUsage() async {
    final data = await _load();
    final list = data.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static Future<DailyUsage> getTodayUsage() async {
    final data = await _load();
    return data[_today()] ?? DailyUsage(date: _today(), downloadBytes: 0, uploadBytes: 0);
  }

  static Future<DailyUsage> getWeekUsage() async {
    final data = await _load();
    final now = DateTime.now();
    int dl = 0, ul = 0;
    for (var i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final usage = data[key];
      if (usage != null) {
        dl += usage.downloadBytes;
        ul += usage.uploadBytes;
      }
    }
    return DailyUsage(date: 'week', downloadBytes: dl, uploadBytes: ul);
  }

  static Future<DailyUsage> getMonthUsage() async {
    final data = await _load();
    int dl = 0, ul = 0;
    for (final usage in data.values) {
      dl += usage.downloadBytes;
      ul += usage.uploadBytes;
    }
    return DailyUsage(date: 'month', downloadBytes: dl, uploadBytes: ul);
  }
}
