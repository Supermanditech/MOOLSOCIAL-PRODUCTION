import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('both promotion intents fit without horizontal clipping', (
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

    void expectContained(List<ValueKey<String>> keys) {
      final owner = tester.getRect(
        find.byKey(const ValueKey('buy-catalogue-promotions')),
      );
      for (final key in keys) {
        final rect = tester.getRect(find.byKey(key));
        expect(owner.contains(rect.topLeft), isTrue);
        expect(owner.contains(rect.bottomRight), isTrue);
        expect(rect.width, greaterThanOrEqualTo(140));
        expect(rect.height, greaterThanOrEqualTo(96));
      }
    }

    expectContained(const [
      ValueKey('buy-promotion-shop-basket'),
      ValueKey('buy-promotion-shop-wholesale'),
    ]);

    session.openDestination(BuyV2Destination.wholesale);
    await tester.pumpAndSettle();
    expectContained(const [
      ValueKey('buy-promotion-wholesale-restock'),
      ValueKey('buy-promotion-wholesale-shop'),
    ]);
    expect(tester.takeException(), isNull);
  });
}
