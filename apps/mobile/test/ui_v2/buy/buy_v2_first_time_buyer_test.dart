import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first-time buyer with no orders can open Shop tools safely', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final core = BuySession();
    final session = BuyV2Session(core: core, reviewDataEnabled: false);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.orders, isEmpty);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(session: session),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-catalogue-unavailable')),
      findsOneWidget,
    );
    final tools = find.byKey(const ValueKey('buy-filter-button'));
    expect(tools, findsOneWidget);
    await tester.tap(tools);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-active-orders-button')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
