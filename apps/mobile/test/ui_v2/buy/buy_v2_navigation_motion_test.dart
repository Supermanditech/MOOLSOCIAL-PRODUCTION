import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  BuyV2Session newSession() => BuyV2Session(core: BuySession());

  Widget app(
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
    BuyV2Destination initialDestination = BuyV2Destination.shop,
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
      home: BuyV2Screen(
        session: session,
        initialDestination: initialDestination,
      ),
    );
  }

  test('session emits motion metadata only for real navigation outcomes', () {
    final session = newSession();
    final initial = session.navigationMotionSequence;

    session.showNotice('Ready');
    expect(session.navigationMotionSequence, initial);

    session.openDestination(BuyV2Destination.wholesale);
    expect(session.navigationMotionSequence, initial + 1);

    session.openOrders();
    expect(session.navigationMotionSequence, initial + 2);
    session.openOrders();
    expect(session.navigationMotionSequence, initial + 2);

    session.openDestination(BuyV2Destination.wholesale);
    expect(session.navigationMotionSequence, initial + 3);
    expect(
      session.navigationMotionDirection,
      BuyV2NavigationMotionDirection.replace,
    );

    session.openDestination(BuyV2Destination.wholesale);
    expect(session.navigationMotionSequence, initial + 3);

    final product = session.visibleProducts.first;
    expect(session.openProduct(product.id), isTrue);
    expect(session.navigationMotionSequence, initial + 4);
    expect(
      session.navigationMotionDirection,
      BuyV2NavigationMotionDirection.forward,
    );

    session.goBack();
    expect(session.navigationMotionSequence, initial + 5);
    expect(
      session.navigationMotionDirection,
      BuyV2NavigationMotionDirection.back,
    );

    session.chooseCategory(session.categories.last.id);
    session.updateQuery('bulk');
    session.chooseFilter('moq');
    expect(session.navigationMotionSequence, initial + 5);
  });

  test('invalid and repeated same-surface actions never replay motion', () {
    final session = newSession();
    final initial = session.navigationMotionSequence;

    expect(session.openProduct('missing-product'), isFalse);
    expect(session.navigationMotionSequence, initial);

    final first = session.visibleProducts.first;
    final second = session.visibleProducts.skip(1).first;
    expect(session.openProduct(first.id), isTrue);
    final firstProductSequence = session.navigationMotionSequence;
    expect(session.openProduct(first.id), isTrue);
    expect(session.navigationMotionSequence, firstProductSequence);

    expect(session.openProduct(second.id), isTrue);
    expect(session.navigationMotionSequence, firstProductSequence + 1);

    session.goBack();
    expect(session.addProduct(first.id), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    final cartSequence = session.navigationMotionSequence;
    expect(session.restoreSelectedAddressId(null), isFalse);
    expect(session.openCheckout(), isTrue);
    expect(session.view, BuyV2View.checkout);
    expect(session.navigationMotionSequence, cartSequence + 1);
    final checkoutSequence = session.navigationMotionSequence;
    expect(session.openCheckout(), isTrue);
    expect(session.navigationMotionSequence, checkoutSequence);

    session.openOrders();
    final ordersSequence = session.navigationMotionSequence;
    expect(session.openTracking('missing-order'), isFalse);
    expect(session.view, BuyV2View.catalogue);
    expect(session.navigationMotionSequence, ordersSequence);
  });

  test('same-view real detail replacement advances the motion identity', () {
    final session = newSession();
    expect(session.openTracking('MS-240782'), isTrue);
    final firstSequence = session.navigationMotionSequence;

    expect(session.openTracking('MS-240782'), isTrue);
    expect(session.navigationMotionSequence, firstSequence);

    expect(session.openTracking('PO-240783'), isTrue);
    expect(session.view, BuyV2View.tracking);
    expect(session.navigationMotionSequence, firstSequence + 1);
    expect(
      session.navigationMotionDirection,
      BuyV2NavigationMotionDirection.forward,
    );
  });

  testWidgets('rapid replacement keeps only the newest real surface', (
    tester,
  ) async {
    final session = newSession();
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.wholesale);
    await tester.pump(const Duration(milliseconds: 40));
    session.openDestination(BuyV2Destination.medicine);
    await tester.pump(const Duration(milliseconds: 40));

    expect(session.destination, BuyV2Destination.medicine);
    expect(
      find.byKey(const ValueKey('buy-navigation-surface-current')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-navigation-surface-outgoing')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('buy-navigation-surface-current')),
        matching: find.byKey(
          ValueKey('buy-product-${session.visibleProducts.first.id}'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-local-destination-tabs')),
      findsNothing,
    );

    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-navigation-surface-outgoing')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion replaces immediately with no outgoing owner', (
    tester,
  ) async {
    final session = newSession();
    await tester.pumpWidget(app(session, disableAnimations: true));
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.medicine);
    await tester.pump();

    expect(session.destination, BuyV2Destination.medicine);
    expect(
      find.byKey(const ValueKey('buy-navigation-surface-current')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-navigation-surface-outgoing')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('buy-product-${session.visibleProducts.first.id}')),
      findsOneWidget,
    );
  });

  testWidgets('forward back and replacement use distinct bounded axes', (
    tester,
  ) async {
    final session = newSession();
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    Offset translation() {
      final transform = tester.widget<Transform>(
        find.byKey(const ValueKey('buy-navigation-surface-translation')),
      );
      return Offset(
        transform.transform.storage[12],
        transform.transform.storage[13],
      );
    }

    session.openDestination(BuyV2Destination.medicine);
    await tester.pump();
    expect(translation().dx, closeTo(0, .001));
    expect(translation().dy, closeTo(5, .001));
    await tester.pumpAndSettle();

    final product = session.visibleProducts.first;
    session.openProduct(product.id);
    await tester.pump();
    expect(translation().dx, closeTo(18, .001));
    expect(translation().dy, closeTo(0, .001));
    await tester.pumpAndSettle();

    session.goBack();
    await tester.pump();
    expect(translation().dx, closeTo(-18, .001));
    expect(translation().dy, closeTo(0, .001));
  });

  testWidgets(
    'restored initial destination does not replay navigation motion',
    (tester) async {
      final session = newSession()..openDestination(BuyV2Destination.wholesale);
      await tester.pumpWidget(
        app(session, initialDestination: BuyV2Destination.wholesale),
      );
      await tester.pump();

      final transform = tester.widget<Transform>(
        find.byKey(const ValueKey('buy-navigation-surface-translation')),
      );
      expect(transform.transform.storage[12], closeTo(0, .001));
      expect(transform.transform.storage[13], closeTo(0, .001));
      expect(session.destination, BuyV2Destination.wholesale);
    },
  );

  testWidgets(
    'compact large-text navigation keeps fixed chrome and no overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = newSession();
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-local-destination-tabs')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-local-destination-tabs-overflow-cue')),
        findsNothing,
      );
      session.openOrders();
      await tester.pumpAndSettle();

      expect(session.destination, BuyV2Destination.orders);
      expect(find.byKey(const ValueKey('buy-shared-header')), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-local-destination-tabs')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-orders-tab-active')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
