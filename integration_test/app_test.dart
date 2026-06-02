import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:free_vpns/providers/vpn_provider.dart';
import 'package:free_vpns/screens/splash_screen.dart';
import 'package:free_vpns/screens/home_screen.dart';
import 'package:free_vpns/screens/server_list_screen.dart';
import 'package:free_vpns/screens/settings_screen.dart';
import 'package:free_vpns/screens/data_usage_screen.dart';
import 'package:free_vpns/theme/app_theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget createApp({Widget? home}) {
    return ChangeNotifierProvider(
      create: (_) => VpnProvider(),
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: home ?? const HomeScreen(),
      ),
    );
  }

  group('App Launch', () {
    testWidgets('splash screen shows app name and creator', (tester) async {
      await tester.pumpWidget(createApp(home: const SplashScreen()));
      await tester.pump();

      expect(find.text('FreeVPN'), findsOneWidget);
      expect(find.text('Prasad Rawas'), findsOneWidget);
    });

    testWidgets('home screen renders all core elements', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      expect(find.text('FreeVPN'), findsOneWidget);
      expect(find.text('CONNECT'), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
      expect(find.text('Created by Prasad Rawas'), findsOneWidget);
    });
  });

  group('Navigation', () {
    testWidgets('settings icon opens settings screen', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Data Usage'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('VPN Disclaimer'), findsOneWidget);
    });

    testWidgets('settings > About shows app info', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      expect(find.text('FreeVPN'), findsOneWidget);
      expect(find.text('Prasad Rawas'), findsOneWidget);
      expect(find.text('VPN Gate (vpngate.net)'), findsOneWidget);
      expect(find.text('OpenVPN'), findsOneWidget);
    });

    testWidgets('settings > Data Usage shows summary cards', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Data Usage'));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);
      expect(find.text('DAILY BREAKDOWN'), findsOneWidget);
    });

    testWidgets('server selector opens server list', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      final selector = find.textContaining(RegExp('Select a server|Loading servers'));
      if (selector.evaluate().isNotEmpty) {
        await tester.tap(selector);
        await tester.pumpAndSettle();

        expect(find.text('Select Server'), findsOneWidget);
      }
    });
  });

  group('Server List Screen', () {
    testWidgets('shows search bar and back button', (tester) async {
      await tester.pumpWidget(createApp(home: const ServerListScreen()));
      await tester.pump();

      expect(find.text('Select Server'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });

    testWidgets('search bar accepts input and shows clear button', (tester) async {
      await tester.pumpWidget(createApp(home: const ServerListScreen()));
      await tester.pump();

      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField, 'Japan');
        await tester.pump();

        expect(find.byIcon(Icons.clear_rounded), findsOneWidget);
      }
    });

    testWidgets('clear button resets search', (tester) async {
      await tester.pumpWidget(createApp(home: const ServerListScreen()));
      await tester.pump();

      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField, 'Japan');
        await tester.pump();

        await tester.tap(find.byIcon(Icons.clear_rounded));
        await tester.pump();

        expect(find.byIcon(Icons.clear_rounded), findsNothing);
      }
    });
  });

  group('Connect Button Interactions', () {
    testWidgets('shows CONNECT when disconnected', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      expect(find.text('CONNECT'), findsOneWidget);
    });

    testWidgets('tapping connect does not crash with no service', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      await tester.tap(find.text('CONNECT'));
      await tester.pump();

      // Should not crash — service null guard handles this
    });

    testWidgets('power icon visible when disconnected', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      expect(find.byIcon(Icons.power_settings_new_rounded), findsOneWidget);
    });
  });

  group('Settings Screen', () {
    testWidgets('all tiles present with correct icons', (tester) async {
      await tester.pumpWidget(createApp(home: const SettingsScreen()));
      await tester.pump();

      expect(find.byIcon(Icons.data_usage_rounded), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('each tile has chevron icon', (tester) async {
      await tester.pumpWidget(createApp(home: const SettingsScreen()));
      await tester.pump();

      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(5));
    });
  });

  group('Data Usage Screen', () {
    testWidgets('shows empty state when no data', (tester) async {
      await tester.pumpWidget(createApp(home: const DataUsageScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('No usage data yet'), findsOneWidget);
    });

    testWidgets('shows all three summary cards', (tester) async {
      await tester.pumpWidget(createApp(home: const DataUsageScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);
    });
  });

  group('End-to-End Flow', () {
    testWidgets('home > settings > about > back > back', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      // Home
      expect(find.text('CONNECT'), findsOneWidget);

      // Open settings
      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      // Open about
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      expect(find.text('Prasad Rawas'), findsOneWidget);

      // Back to settings
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      // Back to home
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('CONNECT'), findsOneWidget);
    });

    testWidgets('home > settings > data usage > back > back', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Data Usage'));
      await tester.pumpAndSettle();
      expect(find.text('DAILY BREAKDOWN'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('CONNECT'), findsOneWidget);
    });
  });
}
