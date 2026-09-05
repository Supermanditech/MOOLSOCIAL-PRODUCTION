import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
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
    return RepaintBoundary(
      key: const ValueKey('r66-order-address-app-capture'),
      child: MaterialApp(
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
      ),
    );
  }

  Future<void> openDeliverySheet(
    WidgetTester tester,
    BuyV2Session session, {
    VoidCallback? onOpenChat,
    double textScale = 1,
    EdgeInsets safeArea = EdgeInsets.zero,
  }) async {
    await tester.pumpWidget(
      app(
        session,
        onOpenChat: onOpenChat,
        textScale: textScale,
        safeArea: safeArea,
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
  }

  for (final width in [320.0, 390.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('R66 order address remains complete at $width / $scale', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 844));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        for (final wholesale in [false, true]) {
          const captureFamily = String.fromEnvironment(
            'BUY_R66_ADDRESS_FAMILY',
          );
          if (captureFamily.isNotEmpty &&
              captureFamily != (wholesale ? 'wholesale' : 'retail')) {
            continue;
          }
          final core = BuySession();
          final session = BuyV2Session(core: core)..chooseAddress('work');
          final address = session.selectedAddress;
          expect(
            session.addProduct(wholesale ? 'w-notebook' : 's-tomato'),
            isTrue,
          );
          session.openCart(
            scope: wholesale ? BuyV2CartScope.wholesale : BuyV2CartScope.shop,
          );
          expect(session.openCheckout(), isTrue);
          expect(session.confirmOrder(), isTrue);
          final order = session.confirmedOrders.single;
          expect(
            order.addressLine,
            '${address.line}, ${address.area} ${address.pinCode}',
          );
          session.chooseAddress('home');
          expect(session.openTracking(order.id), isTrue);
          await openDeliverySheet(
            tester,
            session,
            textScale: scale,
            safeArea: const EdgeInsets.only(top: 24, bottom: 34),
          );
          final facts = find.byKey(const ValueKey('buy-order-delivery-facts'));
          for (final label in [
            'Recipient',
            'Delivering to',
            'Delivery window',
            'Delivery partner',
            'Recorded instruction',
          ]) {
            final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(of: facts, matching: find.text(label)),
            );
            for (final word in label.split(' ')) {
              final painter = TextPainter(
                text: TextSpan(text: word, style: paragraph.text.style),
                textDirection: paragraph.textDirection,
                textScaler: paragraph.textScaler,
              )..layout();
              expect(
                paragraph.size.width + 0.01,
                greaterThanOrEqualTo(painter.width),
              );
              painter.dispose();
            }
          }
          for (final value in [order.recipient!, order.addressLine!]) {
            final text = find.descendant(of: facts, matching: find.text(value));
            expect(text, findsOneWidget);
            final paragraph = tester.renderObject<RenderParagraph>(text);
            expect(paragraph.didExceedMaxLines, isFalse);
            expect(paragraph.size.width, lessThan(width));
          }
          expect(
            find.descendant(
              of: facts,
              matching: find.textContaining(session.selectedAddress.line),
            ),
            findsNothing,
          );
          if (const bool.fromEnvironment('BUY_R66_ADDRESS_CAPTURE')) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('r66-order-address-app-capture')),
            );
            boundary.markNeedsPaint();
            await tester.pump();
            await tester.runAsync(() async {
              final directory = Directory(
                'build/r66-order-address-v3-20260905',
              );
              await directory.create(recursive: true);
              final file = File(
                '${directory.path}/address-$width-$scale-${wholesale ? 'wholesale' : 'retail'}.png',
              );
              if (await file.exists()) {
                throw StateError('Capture already exists');
              }
              final image = await boundary.toImage(pixelRatio: 1);
              try {
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await file.writeAsBytes(bytes!.buffer.asUint8List());
              } finally {
                image.dispose();
              }
            });
          }
          final help = find.byKey(const ValueKey('buy-order-delivery-help'));
          await tester.scrollUntilVisible(
            help,
            160,
            scrollable: find.descendant(
              of: find.byKey(const ValueKey('buy-order-delivery-list')),
              matching: find.byType(Scrollable),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.getSize(help).height, greaterThanOrEqualTo(44));
          expect(tester.getRect(help).bottom, lessThanOrEqualTo(844 - 34));
          expect(tester.takeException(), isNull);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.tracking);
          expect(session.selectedOrderId, order.id);
          expect(session.selectedOrder.addressLine, order.addressLine);
          expect(session.selectedAddressId, 'home');
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          session.dispose();
          core.dispose();
        }
      });
    }
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
      if (order.addressLine == null) {
        expect(
          find.text('Full address unavailable for this order.'),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('buy-order-delivery-facts')),
            matching: find.textContaining(session.selectedAddress.line),
          ),
          findsNothing,
        );
      }
      if (order.recipient == null) {
        expect(find.text('Not available for this order'), findsOneWidget);
      }
      expect(find.text(order.destinationLabel), findsWidgets);
      expect(find.text(buyV2OrderPromiseSummary(order)), findsWidgets);
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

  testWidgets('order Help continues after reverse with exact Chat context', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = newSession();
    addTearDown(session.dispose);
    expect(session.openTracking('RX-240784'), isTrue);
    var chatOpens = 0;
    await openDeliverySheet(tester, session, onOpenChat: () => chatOpens += 1);

    final help = find.byKey(const ValueKey('buy-order-delivery-help'));
    await tester.ensureVisible(help);
    await tester.tap(help);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-order-delivery-sheet')),
      findsNothing,
    );
    expect(chatOpens, 1);
    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, 'RX-240784');
    expect(find.byKey(const ValueKey('buy-assist-hero')), findsNothing);
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
