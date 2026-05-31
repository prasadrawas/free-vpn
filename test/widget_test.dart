import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:free_vpns/main.dart';
import 'package:free_vpns/providers/vpn_provider.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => VpnProvider(),
        child: const FreeVpnApp(),
      ),
    );

    expect(find.text('FreeVPN'), findsOneWidget);
  });
}
