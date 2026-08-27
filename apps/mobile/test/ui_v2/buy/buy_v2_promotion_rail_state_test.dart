import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('promotion offsets remain isolated to their Buy destination', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(session: session),
      ),
    );
    await tester.pumpAndSettle();

    Finder promotionScrollable() => find
        .descendant(
          of: find.byKey(const ValueKey('buy-catalogue-promotions')),
          matching: find.byType(Scrollable),
        )
        .first;

    double offset() =>
        tester.state<ScrollableState>(promotionScrollable()).position.pixels;

    await tester.drag(promotionScrollable(), const Offset(-90, 0));
    await tester.pumpAndSettle();
    final shopOffset = offset();
    expect(shopOffset, greaterThan(40));

    session.openDestination(BuyV2Destination.wholesale);
    await tester.pumpAndSettle();
    expect(offset(), 0, reason: 'Wholesale must not inherit Shop offset');

    await tester.drag(promotionScrollable(), const Offset(-55, 0));
    await tester.pumpAndSettle();
    final wholesaleOffset = offset();
    expect(wholesaleOffset, greaterThan(20));

    session.openDestination(BuyV2Destination.shop);
    await tester.pumpAndSettle();
    expect(offset(), closeTo(shopOffset, 1));

    session.openDestination(BuyV2Destination.wholesale);
    await tester.pumpAndSettle();
    expect(offset(), closeTo(wholesaleOffset, 1));
    expect(tester.takeException(), isNull);
  });
}
