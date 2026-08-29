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
    double textScale = 1,
    bool reducedMotion = false,
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
        ),
        child: child!,
      ),
      home: BuyV2Screen(
        session: session,
        initialDestination: session.destination,
        initialView: session.view,
      ),
    );
  }

  test('Tracking and Items Assist own the exact selected order', () {
    final session = newSession();
    addTearDown(session.dispose);

    for (final id in ['MS-240782', 'PO-240783', 'RX-240784']) {
      expect(session.openTracking(id), isTrue);
      session.openAssist();
      expect(session.assistOrder.id, id);
      session.closeAssist();
      expect(session.view, BuyV2View.tracking);
      expect(session.selectedOrder.id, id);
    }

    expect(session.openOrderItems('PO-240783'), isTrue);
    session.openAssist();
    expect(session.assistOrder.id, 'PO-240783');
    session.goBack();
    expect(session.view, BuyV2View.orderItems);
    expect(session.selectedOrder.id, 'PO-240783');
  });

  test('general Assist entry cannot consume a stale selected order', () {
    final session = newSession();
    addTearDown(session.dispose);
    final establishedFallback = session.orders.firstWhere(
      (order) => order.status != BuyV2OrderStatus.delivered,
    );

    expect(session.openTracking('PO-240783'), isTrue);
    session.returnToOrders();
    session.openAssist();

    expect(session.assistOrder.id, establishedFallback.id);
    expect(session.assistOrder.id, isNot('PO-240783'));
  });

  testWidgets('Wholesale Help renders and opens its exact order', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = newSession();
    addTearDown(session.dispose);
    expect(session.openTracking('PO-240783'), isTrue);
    session.openAssist();

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.textContaining('PO-240783'), findsOneWidget);
    expect(find.textContaining('MS-240782'), findsNothing);
    final currentOrder = find.byKey(const ValueKey('buy-assist-current-order'));
    expect(currentOrder, findsOneWidget);
    await tester.tap(currentOrder);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, 'PO-240783');
  });

  testWidgets('retired Assist deep link restores exact order Tracking', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = newSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: BuyV2Destination.orders,
          initialView: BuyV2View.assist,
          orderId: 'PO-240783',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.tracking);
    expect(find.byKey(const PageStorageKey('buy-assist')), findsNothing);
    expect(session.selectedOrder.id, 'PO-240783');
    expect(find.textContaining('PO-240783'), findsOneWidget);
    expect(
      find.byKey(const PageStorageKey('buy-tracking-PO-240783')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('320px 140% reduced-motion Assist remains stable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = newSession();
    addTearDown(session.dispose);
    expect(session.openTracking('RX-240784'), isTrue);
    session.openAssist();

    await tester.pumpWidget(app(session, textScale: 1.4, reducedMotion: true));
    await tester.pump();

    final currentOrder = find.byKey(const ValueKey('buy-assist-current-order'));
    expect(currentOrder, findsOneWidget);
    expect(find.textContaining('RX-240784'), findsOneWidget);
    expect(tester.getSize(currentOrder).width, lessThanOrEqualTo(300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('R58.8.2 Assist responsive founder captures', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final viewport in const [
      (
        size: Size(320, 568),
        safe: EdgeInsets.symmetric(vertical: 24),
        textScale: 1.0,
        reduced: false,
        label: '320x568-android',
      ),
      (
        size: Size(360, 800),
        safe: EdgeInsets.symmetric(vertical: 24),
        textScale: 1.0,
        reduced: false,
        label: '360x800-android',
      ),
      (
        size: Size(390, 844),
        safe: EdgeInsets.only(top: 47, bottom: 34),
        textScale: 1.0,
        reduced: false,
        label: '390x844-ios',
      ),
      (
        size: Size(430, 932),
        safe: EdgeInsets.only(top: 59, bottom: 34),
        textScale: 1.0,
        reduced: false,
        label: '430x932-ios',
      ),
      (
        size: Size(320, 568),
        safe: EdgeInsets.symmetric(vertical: 24),
        textScale: 1.4,
        reduced: true,
        label: '320x568-a11y140-reduced',
      ),
    ]) {
      tester.view.physicalSize = viewport.size;
      final session = newSession();
      expect(session.openTracking('PO-240783'), isTrue);
      session.openAssist();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: viewport.safe,
              viewPadding: viewport.safe,
              textScaler: TextScaler.linear(viewport.textScale),
              disableAnimations: viewport.reduced,
            ),
            child: child!,
          ),
          home: BuyV2Screen(
            session: session,
            initialDestination: session.destination,
            initialView: session.view,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('PO-240783'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('buy-v2-screen')),
        matchesGoldenFile(
          'candidate_captures/'
          'buy-v2-r58-8-2-order-assist-${viewport.label}.png',
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      session.dispose();
    }
  }, skip: true);
}
