import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_payment_sheet_motion.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
    Widget? home,
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      home:
          home ??
          Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                key: const ValueKey('open-payment-sheet'),
                onPressed: () => showBuyV2PaymentSheet(context, session),
                child: const Text('Payment methods'),
              ),
            ),
          ),
    );
  }

  Future<void> openSheet(
    WidgetTester tester,
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      app(session, disableAnimations: disableAnimations, textScale: textScale),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-payment-sheet')));
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets('R56.7 route policy is finite and reduced motion is static', (
    tester,
  ) async {
    late AnimationStyle normal;
    late AnimationStyle reduced;
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            MediaQuery(
              data: const MediaQueryData(),
              child: Builder(
                builder: (context) {
                  normal = BuyV2PaymentSheetMotion.resolve(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  reduced = BuyV2PaymentSheetMotion.resolve(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );

    expect(normal.duration, const Duration(milliseconds: 280));
    expect(normal.reverseDuration, const Duration(milliseconds: 220));
    expect(normal.curve, Curves.easeOutBack);
    expect(normal.reverseCurve, Curves.easeInCubic);
    expect(reduced.duration, Duration.zero);
    expect(reduced.reverseDuration, Duration.zero);
    expect(reduced.curve, Curves.linear);
    expect(reduced.reverseCurve, Curves.linear);
  });

  testWidgets('real Checkout and Account callers reach the R56.7 sheet', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    session.addProduct(product.id);

    await tester.pumpWidget(
      app(
        session,
        home: Scaffold(
          body: BuyV2CheckoutView(
            session: session,
            gstInvoiceController: BuyV2GstInvoiceController(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-payment-sheet-route')), findsOne);
    await tester.tap(find.byKey(const ValueKey('buy-payment-close')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      app(
        session,
        home: Scaffold(body: BuyV2AccountView(session: session)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-account-payment')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-payment-sheet-route')), findsOne);
  });

  testWidgets('selection commits once only after the reverse route', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session);

    await tester.tap(find.byKey(const ValueKey('buy-payment-Bank transfer')));
    await tester.pump();
    expect(session.selectedPayment, 'UPI');
    await tester.pump(const Duration(milliseconds: 219));
    expect(session.selectedPayment, 'UPI');
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(session.selectedPayment, 'Bank transfer');
    expect(find.byKey(const ValueKey('buy-payment-sheet-route')), findsNothing);
  });

  testWidgets('Back, Close and lifecycle preserve the existing choice', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession())
      ..choosePayment('Purchase order');
    addTearDown(session.dispose);
    await openSheet(tester, session);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(session.selectedPayment, 'Purchase order');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.selectedPayment, 'Purchase order');

    await tester.tap(find.byKey(const ValueKey('open-payment-sheet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-payment-close')));
    await tester.pumpAndSettle();
    expect(session.selectedPayment, 'Purchase order');
  });

  testWidgets('stale destination or view cannot receive a payment choice', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session);

    session.openDestination(BuyV2Destination.medicine);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buy-payment-Bank transfer')));
    await tester.pumpAndSettle();
    expect(session.selectedPayment, 'UPI');

    session.openDestination(BuyV2Destination.shop);
    await tester.tap(find.byKey(const ValueKey('open-payment-sheet')));
    await tester.pumpAndSettle();
    session.openAccount();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buy-payment-Purchase order')));
    await tester.pumpAndSettle();
    expect(session.selectedPayment, 'UPI');
  });

  testWidgets('named route and selected option expose one semantic owner', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = BuyV2Session(core: BuySession())
      ..choosePayment('Bank transfer');
    addTearDown(session.dispose);
    await openSheet(tester, session);

    final route = find.byKey(const ValueKey('buy-payment-sheet-route'));
    expect(tester.getSemantics(route).label, 'Payment methods');
    final selected = tester.getSemantics(
      find.byKey(const ValueKey('buy-payment-semantics-Bank transfer')),
    );
    expect(selected.label, contains('Bank transfer, selected'));
    expect(selected.flagsCollection.isButton, isTrue);
    expect(selected.flagsCollection.isSelected, Tristate.isTrue);
    expect(selected.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(
      tester.getSize(find.byKey(const ValueKey('buy-payment-close'))).height,
      greaterThanOrEqualTo(44),
    );
    semantics.dispose();
  });

  testWidgets('compact 140 percent keeps every payment choice reachable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session, textScale: 1.4);

    final target = find.byKey(const ValueKey('buy-payment-Purchase order'));
    await tester.scrollUntilVisible(
      target,
      120,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('buy-payment-sheet-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    expect(target, findsOneWidget);
    expect(tester.getSize(target).height, greaterThanOrEqualTo(58));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion applies and selection resolves immediately', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session, disableAnimations: true, settle: false);
    expect(find.byKey(const ValueKey('buy-payment-sheet-route')), findsOne);

    await tester.tap(find.byKey(const ValueKey('buy-payment-Purchase order')));
    await tester.pump();
    await tester.pump();
    expect(session.selectedPayment, 'Purchase order');
    expect(find.byKey(const ValueKey('buy-payment-sheet-route')), findsNothing);
  });

  testWidgets('R56.7 payment-sheet responsive evidence captures', (
    tester,
  ) async {
    const cases = [
      (Size(320, 700), 1.4, false, 'compact-320x700-text140'),
      (Size(360, 800), 1.0, false, 'android-360x800'),
      (Size(390, 844), 1.0, false, 'ios-390x844'),
      (Size(390, 844), 1.0, true, 'reduced-ios-390x844'),
    ];
    for (final capture in cases) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = capture.$1;
      final session = BuyV2Session(core: BuySession())
        ..choosePayment('Bank transfer');
      await openSheet(
        tester,
        session,
        disableAnimations: capture.$3,
        textScale: capture.$2,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'candidate_captures/buy-v2-r56-7-payment-${capture.$4}.png',
        ),
      );
      session.dispose();
    }
    tester.view.reset();
  }, skip: true);
}
