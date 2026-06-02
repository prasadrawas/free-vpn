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

  Widget buildHomeScreen() {
    return ChangeNotifierProvider(
      create: (_) => VpnProvider(),
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }

  Future<void> disposeTree(WidgetTester tester) async {
    // Replace widget tree to dispose all controllers and cancel timers
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  testWidgets('Home screen renders with app name', (WidgetTester tester) async {
    await tester.pumpWidget(buildHomeScreen());
    await tester.pump();

    expect(find.text('FreeVPN'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('Home screen shows connect button', (WidgetTester tester) async {
    await tester.pumpWidget(buildHomeScreen());
    await tester.pump();

    expect(find.text('CONNECT'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('Home screen shows server selector', (WidgetTester tester) async {
    await tester.pumpWidget(buildHomeScreen());
    await tester.pump();

    // Should show loading or select server text
    expect(
      find.textContaining(RegExp('Loading servers|Select a server')),
      findsOneWidget,
    );

    await disposeTree(tester);
  });

  testWidgets('Home screen shows settings icon', (WidgetTester tester) async {
    await tester.pumpWidget(buildHomeScreen());
    await tester.pump();

    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('Home screen shows creator text', (WidgetTester tester) async {
    await tester.pumpWidget(buildHomeScreen());
    await tester.pump();

    expect(find.text('Created by Prasad Rawas'), findsOneWidget);

    await disposeTree(tester);
  });

  testWidgets('Home screen shows Change button on server selector',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildHomeScreen());
    await tester.pump();

    expect(find.text('Change'), findsOneWidget);

    await disposeTree(tester);
  });
}
