import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
    EdgeInsets safeArea = EdgeInsets.zero,
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: safeArea,
          viewPadding: safeArea,
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

  testWidgets('delivered Tracking owns direct exact-order Help', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = newSession();
    addTearDown(session.dispose);
    expect(session.openTracking('MS-240741'), isTrue);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    final help = find.byKey(const ValueKey('buy-tracking-delivered-help'));
    await tester.scrollUntilVisible(
      help,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(help, findsOneWidget);
    expect(find.text('Reorder'), findsOneWidget);
    final semantics = tester.getSemantics(help).getSemanticsData();
    expect(semantics.hasAction(SemanticsAction.tap), isTrue);

    await tester.tap(help);
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.assist);
    expect(session.assistOrder.id, 'MS-240741');
    expect(find.textContaining('MS-240741'), findsOneWidget);
    expect(find.text('Return, replacement or refund'), findsOneWidget);
    expect(find.text('Cancel or change order'), findsNothing);
    expect(
      find.text('Topics prepare support; no order changes happen here.'),
      findsOneWidget,
    );
    expect(find.text('Cancellation · return · refund help'), findsOneWidget);
  });

  testWidgets(
    'active Assist exposes cancellation preparation without mutation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = newSession();
      addTearDown(session.dispose);
      expect(session.openTracking('PO-240783'), isTrue);
      final itemCount = session.itemCount;
      final cartTotal = session.cartTotal;
      final activeCount = session.activeOrderCount;
      session.openAssist();

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      final cancel = find.text('Cancel or change order');
      expect(cancel, findsOneWidget);
      expect(find.text('Return, replacement or refund'), findsNothing);

      await tester.tap(cancel);
      await tester.pumpAndSettle();

      expect(session.assistOrder.id, 'PO-240783');
      expect(session.selectedOrder.id, 'PO-240783');
      expect(session.itemCount, itemCount);
      expect(session.cartTotal, cartTotal);
      expect(session.activeOrderCount, activeCount);
      expect(session.view, BuyV2View.assist);
      expect(find.textContaining('selected. Add details'), findsOneWidget);
    },
  );

  testWidgets('visible Assist return restores exact Tracking and Items depth', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = newSession();
    addTearDown(session.dispose);

    for (final origin in [BuyV2View.tracking, BuyV2View.orderItems]) {
      if (origin == BuyV2View.tracking) {
        expect(session.openTracking('PO-240783'), isTrue);
      } else {
        expect(session.openOrderItems('PO-240783'), isTrue);
      }
      session.openAssist();
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(session.view, origin);
      expect(session.selectedOrder.id, 'PO-240783');
    }
  });

  testWidgets('Assist Back semantic centre is compact and physically active', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = newSession();
    addTearDown(session.dispose);
    expect(session.openTracking('MS-240741'), isTrue);
    session.openAssist();

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    final back = find.byKey(const ValueKey('buy-assist-return'));
    final semanticNode = tester.getSemantics(back);
    final semanticData = semanticNode.getSemanticsData();
    expect(semanticData.hasAction(SemanticsAction.tap), isTrue);
    expect(semanticNode.rect.width, lessThan(140));

    await tester.tapAt(tester.getCenter(back));
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, 'MS-240741');
    expect(
      find.byKey(const PageStorageKey('buy-tracking-MS-240741')),
      findsOneWidget,
    );
  });

  testWidgets('general Assist visible return preserves catalogue query', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = newSession();
    addTearDown(session.dispose);
    session.openDestination(BuyV2Destination.wholesale);
    session.updateQuery('rice');
    session.openAssist();

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(session.destination, BuyV2Destination.wholesale);
    expect(session.view, BuyV2View.catalogue);
    expect(session.query, 'rice');
  });

  testWidgets('320px 140% reduced motion stays stable and state-appropriate', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = newSession();
    addTearDown(session.dispose);
    expect(session.openTracking('RX-240719'), isTrue);
    session.openAssist();

    await tester.pumpWidget(app(session, textScale: 1.4, reducedMotion: true));
    await tester.pump();

    expect(find.text('Return, replacement or refund'), findsOneWidget);
    expect(find.text('Medicine support'), findsOneWidget);
    expect(find.text('Cancel or change order'), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('buy-v2-screen'))).width,
      lessThanOrEqualTo(320),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('R58.8.4 responsive founder captures', (tester) async {
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
      expect(session.openTracking('MS-240741'), isTrue);
      session.openAssist();
      await tester.pumpWidget(
        app(
          session,
          textScale: viewport.textScale,
          reducedMotion: viewport.reduced,
          safeArea: viewport.safe,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Return, replacement or refund'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('buy-v2-screen')),
        matchesGoldenFile(
          'candidate_captures/'
          'buy-v2-r58-8-4-order-issue-${viewport.label}.png',
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      session.dispose();
    }
  }, skip: true);
}
