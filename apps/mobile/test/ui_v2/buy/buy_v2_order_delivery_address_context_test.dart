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

  Future<void> openDeliverySheet(
    WidgetTester tester,
    BuyV2Session session,
  ) async {
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final address = find.byKey(const ValueKey('buy-tracking-address'));
    await tester.scrollUntilVisible(
      address,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(address);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-order-delivery-sheet')),
      findsOneWidget,
    );
  }

  testWidgets('three order families expose exact immutable delivery facts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final id in ['MS-240782', 'PO-240783', 'RX-240784']) {
      final session = newSession()..chooseAddress('home');
      final order = session.orders.firstWhere(
        (candidate) => candidate.id == id,
      );
      expect(session.openTracking(id), isTrue);
      await openDeliverySheet(tester, session);

      expect(find.textContaining(id), findsWidgets);
      expect(find.text(order.destinationLabel), findsWidgets);
      expect(find.text(order.promise), findsWidgets);
      expect(
        find.text('No delivery instruction was recorded for this order.'),
        findsOneWidget,
      );
      expect(find.textContaining('future checkout only'), findsOneWidget);
      for (final key in const [
        ValueKey('buy-order-delivery-manage-future'),
        ValueKey('buy-order-delivery-help'),
      ]) {
        final semantics = tester.getSemantics(find.byKey(key));
        expect(
          semantics.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
      }
      expect(session.selectedAddressId, 'home');
      expect(session.selectedOrder.id, id);

      await tester.tap(find.byKey(const ValueKey('buy-order-delivery-close')));
      await tester.pumpAndSettle();
      expect(session.selectedAddressId, 'home');
      expect(session.view, BuyV2View.tracking);
      expect(session.selectedOrder.id, id);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      session.dispose();
    }
  });

  testWidgets('future address continuation waits for reverse and is explicit', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = newSession()..chooseAddress('home');
    addTearDown(session.dispose);
    expect(session.openTracking('PO-240783'), isTrue);
    final immutableDestination = session.selectedOrder.destinationLabel;
    await openDeliverySheet(tester, session);

    final manage = find.byKey(
      const ValueKey('buy-order-delivery-manage-future'),
    );
    await tester.ensureVisible(manage);
    await tester.tap(manage);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-order-delivery-sheet')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('buy-address-sheet-route')),
      findsOneWidget,
    );
    expect(session.selectedAddressId, 'home');
    expect(session.selectedOrder.id, 'PO-240783');
    await tester.tap(find.byKey(const ValueKey('buy-address-work')));
    await tester.pumpAndSettle();

    expect(session.selectedAddressId, 'work');
    expect(session.selectedOrder.id, 'PO-240783');
    expect(session.selectedOrder.destinationLabel, immutableDestination);
    expect(session.view, BuyV2View.tracking);
  });

  testWidgets('order Help continues after reverse with exact Assist context', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = newSession();
    addTearDown(session.dispose);
    expect(session.openTracking('RX-240784'), isTrue);
    await openDeliverySheet(tester, session);

    final help = find.byKey(const ValueKey('buy-order-delivery-help'));
    await tester.ensureVisible(help);
    await tester.tap(help);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-order-delivery-sheet')),
      findsNothing,
    );
    expect(session.view, BuyV2View.assist);
    expect(session.assistOrder.id, 'RX-240784');
    expect(find.textContaining('RX-240784'), findsOneWidget);
    expect(find.textContaining('MS-240782'), findsNothing);
  });

  testWidgets('Back and reduced motion retain Tracking at 320px and 140%', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = newSession()..chooseAddress('work');
    addTearDown(session.dispose);
    expect(session.openTracking('MS-240782'), isTrue);

    await tester.pumpWidget(app(session, textScale: 1.4, reducedMotion: true));
    await tester.pump();
    final address = find.byKey(const ValueKey('buy-tracking-address'));
    await tester.scrollUntilVisible(
      address,
      180,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('buy-tracking-MS-240782')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              (widget.axisDirection == AxisDirection.down ||
                  widget.axisDirection == AxisDirection.up),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(address);
    await tester.pump();

    final sheet = find.byKey(const ValueKey('buy-order-delivery-sheet'));
    expect(sheet, findsOneWidget);
    expect(tester.getSize(sheet).width, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(sheet, findsNothing);
    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, 'MS-240782');
    expect(session.selectedAddressId, 'work');
    expect(tester.takeException(), isNull);
  });

  testWidgets('R58.8.3 delivery context responsive founder captures', (
    tester,
  ) async {
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
      await tester.pumpWidget(
        app(
          session,
          textScale: viewport.textScale,
          reducedMotion: viewport.reduced,
          safeArea: viewport.safe,
        ),
      );
      await tester.pumpAndSettle();
      final address = find.byKey(const ValueKey('buy-tracking-address'));
      await tester.scrollUntilVisible(
        address,
        240,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(address);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-order-delivery-sheet')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'candidate_captures/'
          'buy-v2-r58-8-3-order-delivery-${viewport.label}.png',
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      session.dispose();
    }
  }, skip: true);
}
