import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
  }) {
    return MaterialApp(
      theme: MoolTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            disableAnimations: disableAnimations,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        );
      },
      home: BuyV2Screen(session: session),
    );
  }

  Future<void> openScopedNoMatch(
    WidgetTester tester,
    BuyV2Session session, {
    String query = 'tomato',
  }) async {
    session.chooseCategory('school-office');
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-search-field')),
      query,
    );
    await tester.pumpAndSettle();
  }

  test('scope broadening preserves query and never crosses verticals', () {
    final session = BuyV2Session(core: BuySession());
    session.chooseCategory('school-office');
    session.chooseFilter('lowest');
    session.updateQuery('tomato');

    expect(session.visibleProducts, isEmpty);
    expect(session.hasNarrowedProductSearchScope, isTrue);
    expect(session.broadenProductSearchScope(), isTrue);
    expect(session.query, 'tomato');
    expect(session.selectedCategoryId, 'all');
    expect(session.selectedFilter, isNull);
    expect(session.visibleProducts, isNotEmpty);
    expect(
      session.visibleProducts.every(
        (product) => product.destination == BuyV2Destination.shop,
      ),
      isTrue,
    );

    session.openDestination(BuyV2Destination.orders);
    session.updateQuery('ORD-240731');
    expect(session.hasNarrowedProductSearchScope, isFalse);
    expect(session.broadenProductSearchScope(), isFalse);
    expect(session.query, 'ORD-240731');
  });

  testWidgets('no-match result broadens to a genuine current-vertical result', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await openScopedNoMatch(tester, session);

    expect(find.text('No matches for “tomato”'), findsOneWidget);
    final action = find.byKey(const ValueKey('buy-search-all-shop'));
    expect(action, findsOneWidget);
    expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
    final semantics = tester.getSemantics(action).getSemanticsData();
    expect(semantics.label, contains('Search all Shop'));
    expect(semantics.hasAction(SemanticsAction.tap), isTrue);
    expect(find.byKey(const ValueKey('buy-search-clear')), findsOneWidget);

    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(session.query, 'tomato');
    expect(session.selectedCategoryId, 'all');
    expect(
      session.visibleProducts.map((product) => product.id),
      contains('s-tomato'),
    );
    expect(
      session.visibleProducts.every(
        (product) => product.destination == BuyV2Destination.shop,
      ),
      isTrue,
    );
    expect(find.byKey(const ValueKey('buy-product-s-tomato')), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-search-all-shop')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scope recovery is static at 320px and 140% reduced motion', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);

    final session = BuyV2Session(core: BuySession());
    session.chooseCategory('school-office');
    await tester.pumpWidget(
      app(session, disableAnimations: true, textScale: 1.4),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-search-field')),
      'tomato',
    );
    await tester.pump();

    final action = find.byKey(const ValueKey('buy-search-all-shop'));
    expect(action, findsOneWidget);
    expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);

    await tester.tap(action);
    await tester.pump();
    expect(
      session.visibleProducts.map((product) => product.id),
      contains('s-tomato'),
    );
    expect(find.byKey(const ValueKey('buy-product-s-tomato')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
