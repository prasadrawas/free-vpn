import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:free_vpns/providers/vpn_provider.dart';
import 'package:free_vpns/screens/home_screen.dart';
import 'package:free_vpns/theme/app_theme.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('Home screen renders with app name', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => VpnProvider(),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('FreeVPN'), findsOneWidget);
  });

  testWidgets('Home screen shows connect button', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => VpnProvider(),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('CONNECT'), findsOneWidget);
  });

  testWidgets('Home screen shows server selector', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => VpnProvider(),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    // Should show loading or select server text
    expect(
      find.textContaining(RegExp('Loading servers|Select a server')),
      findsOneWidget,
    );
  });

  testWidgets('Home screen shows settings icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => VpnProvider(),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
  });

  testWidgets('Home screen shows creator text', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => VpnProvider(),
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Created by Prasad Rawas'), findsOneWidget);
  });
}
