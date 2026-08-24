import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  testWidgets('Buy keeps one compact launcher and one local destination rail', (
    tester,
  ) async {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    var chatTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(session: session, onOpenChat: () => chatTaps += 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-local-destination-tabs')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('buy-persistent-dock')), findsNothing);
    for (final keyName in const [
      'buy-local-tab-wholesale',
      'buy-local-tab-orders',
      'buy-local-tab-offers',
    ]) {
      final action = find.byKey(ValueKey(keyName));
      expect(action, findsOneWidget);
      expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
    }

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-offers-publisher-summary')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('mool-global-chat-tap')));
    await tester.pumpAndSettle();
    expect(chatTaps, 1);

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('buy-offers-publisher-summary')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Buy Medicine survives product depth and system Back', (
    tester,
  ) async {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: BuyV2Destination.medicine,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search medicines and wellness'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('care-local-destination-tabs')),
      findsOneWidget,
    );
    final product = session.visibleProducts.first;
    session.openProduct(product.id);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.medicine);
    expect(session.view, BuyV2View.catalogue);
    expect(find.text('Search medicines and wellness'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('care-local-destination-tabs')),
      findsOneWidget,
    );
  });
}
