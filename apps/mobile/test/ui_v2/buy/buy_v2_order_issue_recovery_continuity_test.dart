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
    VoidCallback? onOpenChat,
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
        onOpenChat: onOpenChat,
      ),
    );
  }

  testWidgets('delivered Tracking owns direct exact-order Chat Help', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = newSession();
    addTearDown(session.dispose);
    expect(session.openTracking('MS-240741'), isTrue);
    var chatOpens = 0;

    await tester.pumpWidget(app(session, onOpenChat: () => chatOpens += 1));
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

    expect(chatOpens, 1);
    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, 'MS-240741');
    expect(find.byKey(const ValueKey('buy-assist-hero')), findsNothing);
  });

  testWidgets('retired active Assist exposes Manage order without mutation', (
    tester,
  ) async {
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
    final manage = find.byKey(
      const ValueKey('buy-tracking-manage-order-PO-240783'),
    );
    await tester.scrollUntilVisible(
      manage,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(manage, findsOneWidget);
    expect(find.byKey(const PageStorageKey('buy-assist')), findsNothing);

    await tester.tap(manage);
    await tester.pumpAndSettle();

    expect(session.assistOrder.id, 'PO-240783');
    expect(session.selectedOrder.id, 'PO-240783');
    expect(session.itemCount, itemCount);
    expect(session.cartTotal, cartTotal);
    expect(session.activeOrderCount, activeCount);
    expect(session.view, BuyV2View.assist);
    expect(
      find.byKey(const ValueKey('buy-order-resolution-sheet')),
      findsOneWidget,
    );
    expect(find.text('Manage order'), findsWidgets);
  });

  testWidgets('retired Assist compatibility restores exact prior order depth', (
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

      expect(find.byKey(const PageStorageKey('buy-assist')), findsNothing);
      expect(
        find.byKey(const PageStorageKey('buy-tracking-PO-240783')),
        findsOneWidget,
      );
      session.closeAssist();
      await tester.pumpAndSettle();

      expect(session.view, origin);
      expect(session.selectedOrder.id, 'PO-240783');
    }
  });

  testWidgets(
    'retired Assist exact-order Help is semantic and physically active',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = newSession();
      addTearDown(session.dispose);
      expect(session.openTracking('MS-240741'), isTrue);
      session.openAssist();
      var chatOpens = 0;

      await tester.pumpWidget(app(session, onOpenChat: () => chatOpens += 1));
      await tester.pumpAndSettle();

      final help = find.byKey(const ValueKey('buy-tracking-delivered-help'));
      await tester.scrollUntilVisible(
        help,
        240,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.drag(find.byType(Scrollable).last, const Offset(0, -180));
      await tester.pumpAndSettle();
      final semanticNode = tester.getSemantics(help);
      final semanticData = semanticNode.getSemanticsData();
      expect(semanticData.hasAction(SemanticsAction.tap), isTrue);

      await tester.tap(help);
      await tester.pumpAndSettle();

      expect(chatOpens, 1);
      expect(session.view, BuyV2View.assist);
      expect(session.selectedOrder.id, 'MS-240741');
      expect(
        find.byKey(const PageStorageKey('buy-tracking-MS-240741')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'retired general Assist preserves catalogue query without local UI',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = newSession();
      addTearDown(session.dispose);
      session.openDestination(BuyV2Destination.wholesale);
      session.updateQuery('rice');
      session.openAssist();

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      expect(session.destination, BuyV2Destination.wholesale);
      expect(session.view, BuyV2View.assist);
      expect(session.query, 'rice');
      expect(find.byKey(const PageStorageKey('buy-assist')), findsNothing);
    },
  );

  testWidgets('320px 140% retired Assist keeps exact Tracking stable', (
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

    expect(
      find.byKey(const PageStorageKey('buy-tracking-RX-240719')),
      findsOneWidget,
    );
    expect(find.byKey(const PageStorageKey('buy-assist')), findsNothing);
    expect(find.textContaining('RX-240719'), findsOneWidget);
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
