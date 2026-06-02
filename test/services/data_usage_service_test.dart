import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:free_vpns/services/data_usage_service.dart';

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('DailyUsage', () {
    test('totalBytes returns sum of download and upload', () {
      final usage = DailyUsage(date: '2026-06-01', downloadBytes: 100, uploadBytes: 50);
      expect(usage.totalBytes, 150);
    });

    test('toJson produces correct map', () {
      final usage = DailyUsage(date: '2026-06-01', downloadBytes: 1024, uploadBytes: 512);
      final json = usage.toJson();
      expect(json['date'], '2026-06-01');
      expect(json['download'], 1024);
      expect(json['upload'], 512);
    });

    test('fromJson restores correctly', () {
      final json = {'date': '2026-06-01', 'download': 2048, 'upload': 1024};
      final usage = DailyUsage.fromJson(json);
      expect(usage.date, '2026-06-01');
      expect(usage.downloadBytes, 2048);
      expect(usage.uploadBytes, 1024);
    });

    test('fromJson handles missing fields', () {
      final usage = DailyUsage.fromJson({});
      expect(usage.date, '');
      expect(usage.downloadBytes, 0);
      expect(usage.uploadBytes, 0);
    });

    test('roundtrip toJson/fromJson preserves data', () {
      final original = DailyUsage(date: '2026-06-01', downloadBytes: 999, uploadBytes: 111);
      final restored = DailyUsage.fromJson(original.toJson());
      expect(restored.date, original.date);
      expect(restored.downloadBytes, original.downloadBytes);
      expect(restored.uploadBytes, original.uploadBytes);
    });
  });

  group('DataUsageService', () {
    test('getUsage returns empty list initially', () async {
      final usage = await DataUsageService.getUsage();
      expect(usage, isEmpty);
    });

    test('getTodayUsage returns zero initially', () async {
      final usage = await DataUsageService.getTodayUsage();
      expect(usage.downloadBytes, 0);
      expect(usage.uploadBytes, 0);
    });

    test('addUsage stores data', () async {
      await DataUsageService.addUsage(1000, 500);
      final today = await DataUsageService.getTodayUsage();
      expect(today.downloadBytes, 1000);
      expect(today.uploadBytes, 500);
    });

    test('addUsage accumulates within same day', () async {
      await DataUsageService.addUsage(1000, 500);
      await DataUsageService.addUsage(2000, 1000);
      final today = await DataUsageService.getTodayUsage();
      expect(today.downloadBytes, 3000);
      expect(today.uploadBytes, 1500);
    });

    test('addUsage ignores zero bytes', () async {
      await DataUsageService.addUsage(0, 0);
      final usage = await DataUsageService.getUsage();
      expect(usage, isEmpty);
    });

    test('addUsage ignores negative bytes', () async {
      await DataUsageService.addUsage(-100, -50);
      final usage = await DataUsageService.getUsage();
      expect(usage, isEmpty);
    });

    test('getWeekUsage sums last 7 days', () async {
      await DataUsageService.addUsage(5000, 2000);
      final week = await DataUsageService.getWeekUsage();
      expect(week.downloadBytes, 5000);
      expect(week.uploadBytes, 2000);
    });

    test('getMonthUsage sums all data', () async {
      await DataUsageService.addUsage(10000, 5000);
      final month = await DataUsageService.getMonthUsage();
      expect(month.downloadBytes, 10000);
      expect(month.uploadBytes, 5000);
    });

    test('getUsage returns sorted by date descending', () async {
      await DataUsageService.addUsage(1000, 500);
      final usage = await DataUsageService.getUsage();
      expect(usage.length, 1);
      expect(usage.first.downloadBytes, 1000);
    });
  });
}
