import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:free_vpns/providers/vpn_provider.dart';
import 'package:free_vpns/screens/home_screen.dart';
import 'package:free_vpns/screens/server_list_screen.dart';
import 'package:free_vpns/theme/app_theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late VpnProvider provider;

  Widget createApp({Widget? home}) {
    provider = VpnProvider()..initialize();
    return ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: home ?? const HomeScreen(),
      ),
    );
  }

  group('Server Fetching', () {
    testWidgets('fetches servers from VPN Gate API', (tester) async {
      await tester.pumpWidget(createApp());

      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (provider.servers.isNotEmpty) break;
      }

      expect(provider.servers, isNotEmpty);
      expect(provider.servers.first.hostName, isNotEmpty);
      expect(provider.servers.first.ip, isNotEmpty);
      expect(provider.servers.first.countryLong, isNotEmpty);
      expect(provider.servers.first.speed, greaterThan(0));
      expect(provider.servers.first.ping, greaterThan(0));

      provider.dispose();
    });

    testWidgets('servers are sorted by score', (tester) async {
      await tester.pumpWidget(createApp());

      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (provider.servers.isNotEmpty) break;
      }

      if (provider.servers.length >= 2) {
        expect(provider.servers.first.score,
            greaterThanOrEqualTo(provider.servers.last.score));
      }

      provider.dispose();
    });

    testWidgets('all servers have valid config', (tester) async {
      await tester.pumpWidget(createApp());

      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (provider.servers.isNotEmpty) break;
      }

      for (final server in provider.servers) {
        expect(server.openVpnConfigBase64, isNotEmpty);
        expect(server.numVpnSessions, greaterThan(0));
        expect(server.speed, greaterThanOrEqualTo(500000));
      }

      provider.dispose();
    });

    testWidgets('servers are filtered correctly', (tester) async {
      await tester.pumpWidget(createApp());

      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (provider.servers.isNotEmpty) break;
      }

      for (final server in provider.servers) {
        expect(server.ping, greaterThan(0));
        expect(server.score, greaterThan(0));
        expect(server.numVpnSessions, greaterThan(0));
        expect(server.speed, greaterThanOrEqualTo(500000));
      }

      provider.dispose();
    });
  });

  group('Country Filter', () {
    testWidgets('country chips appear after servers load', (tester) async {
      await tester.pumpWidget(createApp(home: const ServerListScreen()));

      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (provider.servers.isNotEmpty) break;
      }

      await tester.pump();

      expect(find.text('All'), findsOneWidget);

      provider.dispose();
    });

    testWidgets('tapping country chip filters servers', (tester) async {
      await tester.pumpWidget(createApp(home: const ServerListScreen()));

      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (provider.servers.isNotEmpty) break;
      }

      await tester.pump();

      // Find a country chip (not "All")
      final countries = provider.servers.map((s) => s.countryLong).toSet();
      if (countries.isNotEmpty) {
        final country = countries.first;
        final chip = find.text(country);
        if (chip.evaluate().isNotEmpty) {
          await tester.tap(chip.first);
          await tester.pump();
        }
      }

      provider.dispose();
    });
  });

  group('Provider State After Init', () {
    testWidgets('provider has correct initial state', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      expect(provider.connectionStatus, ConnectionStatus.disconnected);
      expect(provider.selectedServer, isNull);
      expect(provider.errorMessage, isNull);
      expect(provider.downloadSpeed, 0);
      expect(provider.uploadSpeed, 0);
      expect(provider.connectionQuality, ConnectionQuality.unknown);
      expect(provider.connectionDuration, Duration.zero);
      expect(provider.isAutoConnecting, false);
      expect(provider.serverWentOffline, false);

      provider.dispose();
    });

    testWidgets('online server IPs populated after fetch', (tester) async {
      await tester.pumpWidget(createApp());

      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (provider.servers.isNotEmpty) break;
      }

      // All fetched servers should be marked online
      for (final server in provider.servers) {
        expect(provider.isOnline(server), true);
      }

      provider.dispose();
    });
  });
}
