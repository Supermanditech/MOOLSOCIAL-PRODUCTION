import 'dart:ui' show SemanticsAction, Tristate;
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_payment_sheet_motion.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';
import 'buy_v2_qualified_provider_fixture.dart';
import 'buy_v2_discovery_refinement_test.dart' show BuyTestEligibilityFacts;

class _T06WidgetCustomerState implements BuyV2CustomerStateStore {
  @override
  String get ownerScope => 'isolated-t06-widget-buyer';
  BuyV2CustomerStateSnapshot? snapshot;
  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => snapshot;
  @override
  Future<bool> write(BuyV2CustomerStateSnapshot value) async {
    snapshot = value;
    return true;
  }
}

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

  Future<void> captureGroups(WidgetTester tester, String label) async {
    const directory = String.fromEnvironment('BUY_T06_VISUAL_DIRECTORY');
    if (directory.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('buy-t06-group-screen')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final folder = Directory(directory);
        await folder.create(recursive: true);
        final file = File('${folder.path}/$label.png');
        expect(await file.exists(), isFalse);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });
  }

  for (final size in [const Size(320, 800), const Size(640, 360)]) {
    for (final scale in [1.0, 2.0]) {
      for (final keyOnly in [false, true]) {
        testWidgets(
          'T07 recovery amount and check action fit ${size.width} text $scale keyOnly $keyOnly',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = size;
            addTearDown(tester.view.reset);
            const address = BuyV2Address(
              id: 't07-address',
              kind: BuyV2AddressKind.home,
              label: 'Home',
              recipient: 'Test buyer',
              phone: '9000000000',
              line: 'Test street',
              area: 'Jodhpur',
              pinCode: '342003',
              landmark: '',
            );
            final core = BuySession();
            final commerce = TestLegacyRecoveryCommerce()
              ..snapshot = testPaymentSnapshot(
                null,
                addresses: const [address],
              );
            final store = _T06WidgetCustomerState();
            if (keyOnly) {
              store.snapshot = const BuyV2CustomerStateSnapshot(
                cartQuantities: {'s-tomato': 1},
                checkoutIdempotencyKey: 'original-key-only',
                checkoutSubmissionState: 'paymentPending',
                addresses: [address],
                selectedAddressId: 't07-address',
              );
            }
            final session = BuyV2Session(
              core: core,
              commerceAdapter: commerce,
              customerStateStore: store,
              productFactsAdapter: const BuyTestEligibilityFacts(),
              checkoutQuoteAdapter: TestPaymentQuote(),
              reviewDataEnabled: false,
            );
            addTearDown(session.dispose);
            addTearDown(core.dispose);
            await session.restoreCommerce();
            await session.restoreCustomerState();
            if (!keyOnly) {
              expect(session.addProduct('s-tomato'), isTrue);
              session.openCart();
              expect(session.openCheckout(), isTrue);
              await session.refreshCheckoutQuote();
              expect(await session.submitOrder(), isFalse);
              expect(session.legacyCheckoutAttempt, isNotNull);
            }
            session.checkoutStep = BuyV2CheckoutStep.payment;
            final gst = BuyV2GstInvoiceController();
            addTearDown(gst.dispose);
            await tester.pumpWidget(
              app(
                session,
                textScale: scale,
                disableAnimations: true,
                home: RepaintBoundary(
                  key: const ValueKey('buy-t06-group-screen'),
                  child: Scaffold(
                    body: BuyV2CheckoutView(
                      session: session,
                      gstInvoiceController: gst,
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final primary = find.byKey(
              const ValueKey('buy-checkout-primary-payment'),
            );
            expect(primary, findsOneWidget);
            expect(
              find.descendant(
                of: primary,
                matching: find.text('Check payment'),
              ),
              findsOneWidget,
            );
            expect(find.textContaining('Pay ₹'), findsNothing);
            if (keyOnly) {
              expect(find.text('Amount needs checking'), findsOneWidget);
            } else {
              expect(
                session.checkoutPaymentActionAmount,
                commerce.requests.single.amountDueNow,
              );
            }
            expect(tester.takeException(), isNull);
            await captureGroups(
              tester,
              't07-${size.width.toInt()}x${size.height.toInt()}-$scale-keyonly-$keyOnly',
            );
            await tester.tap(primary);
            await tester.pumpAndSettle();
            expect(commerce.requests.length, keyOnly ? 0 : 1);
            expect(session.checkoutRequiresResolution, isTrue);
            expect(tester.takeException(), isNull);
            expect(tester.getSize(primary).height, greaterThanOrEqualTo(44));
          },
        );
      }
    }
  }

  for (final size in [const Size(320, 800), const Size(640, 360)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'T06 group scopes and payment count fit ${size.width} text $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.reset);
          final core = BuySession();
          final commerce = TestGroupedPaymentCommerce();
          const address = BuyV2Address(
            id: 'test-groups-address',
            kind: BuyV2AddressKind.home,
            label: 'Home',
            recipient: 'Test buyer',
            phone: '9000000000',
            line: 'Test street',
            area: 'Jodhpur',
            pinCode: '342003',
            landmark: '',
          );
          commerce.snapshot = BuyV2CommerceSnapshot(
            state: BuyV2CommerceLoadState.ready,
            products: [
              for (final product in testPaymentProducts)
                product.id == 's-rice'
                    ? product.copyWith(storeId: 'test-second-store')
                    : product,
            ],
            paymentMethods: const {'UPI', 'Card'},
            addresses: const [address],
            selectedAddressId: address.id,
          );
          final quote = TestPaymentQuote()
            ..groupsFor = (lines, method) => [
              for (var i = 0; i < lines.length; i++)
                BuyV2CheckoutPaymentGroup(
                  id: 'test-group-$i',
                  fulfilmentKeys: {lines[i].fulfilmentKey},
                  paymentMethod: method,
                  total: lines[i].total,
                  amountDueNow: lines[i].total,
                ),
            ];
          final session = BuyV2Session(
            core: core,
            commerceAdapter: commerce,
            productFactsAdapter: const BuyTestEligibilityFacts(),
            checkoutQuoteAdapter: quote,
            reviewDataEnabled: false,
            customerStateStore: _T06WidgetCustomerState(),
          );
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          await session.restoreCommerce();
          expect(session.addProduct('s-tomato'), isTrue);
          expect(session.addProduct('s-rice'), isTrue);
          session.openCart();
          expect(session.openCheckout(), isTrue);
          await session.refreshCheckoutQuote();
          session.checkoutStep = BuyV2CheckoutStep.payment;
          final gst = BuyV2GstInvoiceController();
          addTearDown(gst.dispose);
          await tester.pumpWidget(
            app(
              session,
              textScale: scale,
              disableAnimations: true,
              home: RepaintBoundary(
                key: const ValueKey('buy-t06-group-screen'),
                child: Scaffold(
                  body: BuyV2CheckoutView(
                    session: session,
                    gstInvoiceController: gst,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('buy-checkout-payment-groups')),
            180,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(find.text('2 separate payments · 2 orders'), findsOneWidget);
          expect(find.textContaining('Payment 1 of 2'), findsOneWidget);
          expect(
            find.textContaining('Completed orders are kept'),
            findsOneWidget,
          );
          expect(commerce.requests, isEmpty);
          expect(tester.takeException(), isNull);
          await captureGroups(
            tester,
            'groups-${size.width.toInt()}x${size.height.toInt()}-$scale-review',
          );
          if (size.width == 320 && scale == 1) {
            commerce.onGroup = (request) => testGroupedPlacement(request);
            expect(await session.submitOrder(), isFalse);
            await tester.pumpAndSettle();
            expect(find.textContaining('Payment 2 of 2'), findsOneWidget);
            expect(find.text('Checkout total needs a refresh'), findsNothing);
            expect(
              find.byKey(const ValueKey('buy-checkout-committed-totals')),
              findsOneWidget,
            );
            expect(find.text('Agreed total'), findsOneWidget);
            expect(find.text('Placed orders'), findsOneWidget);
            expect(find.text('Remaining orders'), findsOneWidget);
            expect(find.textContaining('with UPI · Placed'), findsOneWidget);
            expect(session.orders, hasLength(1));
            await captureGroups(tester, 'groups-first-completed');
            commerce.onGroup = (request) => testGroupedPlacement(
              request,
              outcome: BuyV2OrderPlacementOutcome.failed,
            );
            expect(await session.submitOrder(), isFalse);
            await tester.pumpAndSettle();
            expect(find.textContaining('with UPI · Placed'), findsOneWidget);
            expect(find.text('Check payment'), findsWidgets);
            expect(session.orders, hasLength(1));
            expect(commerce.requests, hasLength(2));
            expect(tester.takeException(), isNull);
            await captureGroups(tester, 'groups-second-payment-failed');
          }
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  for (final size in [const Size(320, 800), const Size(640, 360)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'T05 crore payment bounds fit ${size.width.toInt()}x${size.height.toInt()} text $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.reset);
          final core = BuySession();
          final commerce = TestPaymentCommerce();
          final product = testPaymentProducts
              .firstWhere((p) => p.id == 's-tomato')
              .copyWith(price: 10000000);
          commerce.snapshot = BuyV2CommerceSnapshot(
            state: BuyV2CommerceLoadState.ready,
            products: [product],
            paymentMethods: const {'UPI', 'Card'},
          );
          final session = BuyV2Session(
            core: core,
            commerceAdapter: commerce,
            reviewDataEnabled: false,
            productFactsAdapter: const QualifiedTestProductFacts({'s-tomato'}),
          );
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          await session.restoreCommerce();
          expect(session.addProduct(product.id), isTrue);
          session.openCart();
          session.openCheckout();
          commerce.snapshot = BuyV2CommerceSnapshot(
            state: BuyV2CommerceLoadState.ready,
            products: [product],
            paymentMethods: const {'UPI', 'Card'},
            paymentCapabilities: [
              testPaymentCapability(
                session,
                minimumMinor: 1000,
                maximumMinor: 10000000,
              ),
              testPaymentCapability(
                session,
                method: 'Card',
                minimumMinor: 0,
                maximumMinor: 1000000000,
              ),
            ],
          );
          await session.restoreCommerce();
          expect(session.choosePayment('Card'), isTrue);
          expect(session.checkoutPaymentAmountMinor, 1000000000);
          await openSheet(
            tester,
            session,
            textScale: scale,
            disableAnimations: scale == 2,
          );
          final card = find.byKey(const ValueKey('buy-payment-Card'));
          final upi = find.byKey(const ValueKey('buy-payment-UPI'));
          expect(tester.widget<InkWell>(card).onTap, isNotNull);
          expect(tester.widget<InkWell>(upi).onTap, isNull);
          expect(
            tester.getTopLeft(card).dy,
            lessThan(tester.getTopLeft(upi).dy),
          );
          expect(
            find.textContaining('Pay to: Test purchase recipient.'),
            findsNWidgets(2),
          );
          expect(find.textContaining('Maximum: ₹1,00,00,000.'), findsOneWidget);
          expect(
            find.textContaining('Amount exceeds this method’s payment limit.'),
            findsOneWidget,
          );
          expect(find.textContaining('Remaining limit:'), findsNothing);
          expect(find.textContaining('Quoted payment charge:'), findsNothing);
          expect(tester.takeException(), isNull);
          const directory = String.fromEnvironment('BUY_T05_VISUAL_DIRECTORY');
          if (directory.isNotEmpty) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('buy-payment-sheet-repaint-boundary')),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 2);
              try {
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final folder = Directory(directory);
                await folder.create(recursive: true);
                final file = File(
                  '${folder.path}/payment-${size.width.toInt()}x${size.height.toInt()}-$scale.png',
                );
                expect(await file.exists(), isFalse);
                await file.writeAsBytes(bytes!.buffer.asUint8List());
              } finally {
                image.dispose();
              }
            });
          }
          commerce.snapshot = BuyV2CommerceSnapshot(
            state: BuyV2CommerceLoadState.ready,
            products: [product],
            paymentMethods: const {'UPI', 'Card'},
            paymentCapabilities: [
              testPaymentCapability(
                session,
                method: 'Card',
                maximumMinor: 100,
                revision: 'test-v2',
              ),
            ],
          );
          await session.restoreCommerce();
          await tester.pumpAndSettle();
          expect(tester.widget<InkWell>(card).onTap, isNull);
          expect(session.selectedPayment, 'Card');
          await tester.tap(find.byKey(const ValueKey('buy-payment-close')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-payment-sheet-route')),
            findsNothing,
          );
          expect(session.cartLines, hasLength(1));
          expect(commerce.requests, isEmpty);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('UPI QR transport and navy GST fit at $scale text', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      session.addProduct('s-tomato');
      session.openCart();
      session.openCheckout();
      final gstController = BuyV2GstInvoiceController()
        ..setRequested(BuyV2Destination.shop, true);
      addTearDown(gstController.dispose);
      await tester.pumpWidget(
        app(
          session,
          textScale: scale,
          home: Scaffold(
            body: BuyV2CheckoutView(
              session: session,
              gstInvoiceController: gstController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final change = find.byKey(const ValueKey('buy-invoice-change'));
      expect(gstController.requestedFor(BuyV2Destination.shop), isTrue);
      expect(find.byKey(const ValueKey('buy-gst-request-shop')), findsNothing);
      await tester.ensureVisible(change);
      await tester.pumpAndSettle();
      expect(change.hitTestable(), findsOneWidget);
      expect(tester.getSize(change).height, greaterThanOrEqualTo(44));
      await tester.tap(change);
      await tester.pumpAndSettle();
      final personal = find.byKey(const ValueKey('buy-invoice-personal'));
      expect(personal.hitTestable(), findsOneWidget);
      await tester.tap(personal);
      await tester.pumpAndSettle();
      expect(gstController.requestedFor(BuyV2Destination.shop), isFalse);
      expect(find.text('Personal purchase'), findsOneWidget);
      expect(gstController.savedProfiles, isEmpty);
      expect(session.cartLines, hasLength(1));
      expect(session.checkoutAmountDueNow, 37);
      expect(find.byKey(const ValueKey('buy-upi-use-qr')), findsNothing);
      session.upiQrAvailable = true;
      session.chooseUpiQr(false);
      await tester.pumpAndSettle();
      final qr = find.byKey(const ValueKey('buy-upi-use-qr'));
      await tester.scrollUntilVisible(
        qr,
        180,
        maxScrolls: 50,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('buy-checkout-unified')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.ensureVisible(qr);
      await tester.pumpAndSettle();
      await tester.tap(qr);
      await tester.pumpAndSettle();
      expect(session.useUpiQr, isTrue);
      expect(session.cartLines, hasLength(1));
      expect(find.byKey(const ValueKey('buy-upi-order-qr')), findsNothing);
      expect(find.byKey(const ValueKey('buy-payment-PhonePe')), findsNothing);
      expect(tester.getSize(qr).height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
    });
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

  testWidgets('Checkout embeds payment choices and Account retains its sheet', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    session.addProduct(product.id);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);

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
    final paymentSummary = find.byKey(
      const ValueKey('buy-checkout-confirm-payment'),
    );
    await tester.scrollUntilVisible(paymentSummary, 150);
    await tester.tap(paymentSummary);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-checkout-payment-stage')), findsOne);
    expect(find.byKey(const ValueKey('buy-payment-UPI')), findsOne);
    expect(find.byKey(const ValueKey('buy-payment-sheet-route')), findsNothing);

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

    await tester.tap(find.byKey(const ValueKey('buy-payment-Card')));
    await tester.pump();
    expect(session.selectedPayment, 'UPI');
    await tester.pump(const Duration(milliseconds: 219));
    expect(session.selectedPayment, 'UPI');
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(session.selectedPayment, 'Card');
    expect(find.byKey(const ValueKey('buy-payment-sheet-route')), findsNothing);
  });

  testWidgets('retail Checkout hides and rejects Purchase order', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final shopProduct = BuyV2Catalogue.products.firstWhere(
      (product) =>
          product.destination == BuyV2Destination.shop &&
          !product.requiresPrescription,
    );
    expect(session.addProduct(shopProduct.id), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    expect(session.purchaseOrderEligibleForCheckout, isFalse);

    await openSheet(tester, session);
    expect(
      find.byKey(const ValueKey('buy-payment-Purchase order')),
      findsNothing,
    );
    expect(find.textContaining('Purchase order'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.selectedPayment, 'UPI');

    // A stale or restored client selection cannot bypass the visible guard.
    session.selectedPayment = 'Purchase order';
    expect(await session.submitOrder(), isFalse);
    expect(session.notice, 'Choose an available payment method to continue.');
    expect(session.confirmedPurchaseId, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wholesale keeps Purchase order separate from payment', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final wholesaleProduct = BuyV2Catalogue.products.firstWhere(
      (product) => product.destination == BuyV2Destination.wholesale,
    );
    expect(session.addProduct(wholesaleProduct.id), isTrue);
    session.openCart(scope: BuyV2CartScope.wholesale);
    expect(session.openCheckout(), isTrue);
    expect(session.purchaseOrderEligibleForCheckout, isTrue);
    await openSheet(tester, session);
    expect(
      find.byKey(const ValueKey('buy-payment-Purchase order')),
      findsNothing,
    );
    expect(session.choosePayment('Purchase order'), isFalse);
    expect(session.selectedPayment, 'UPI');
    expect(
      find.byKey(const ValueKey('buy-purchase-order-reference')),
      findsNothing,
    );
    session.selectedPayment = 'Purchase order';
    session.purchaseOrderReference = 'LEGACY-PO';
    expect(await session.submitOrder(), isFalse);
    expect(session.confirmedPurchaseId, isNull);
  });

  testWidgets('every payment method clears the OPPO navigation inset', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.viewPadding = const FakeViewPadding(top: 41, bottom: 44);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);

    await openSheet(tester, session);
    for (final name in const ['UPI', 'Card']) {
      final action = find.byKey(ValueKey('buy-payment-$name'));
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      final rect = tester.getRect(action);
      expect(rect.height, greaterThanOrEqualTo(44), reason: name);
      expect(rect.bottom, lessThanOrEqualTo(729), reason: name);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Back, Close and lifecycle preserve the existing choice', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession())..choosePayment('Card');
    addTearDown(session.dispose);
    await openSheet(tester, session);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(session.selectedPayment, 'Card');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.selectedPayment, 'Card');

    await tester.tap(find.byKey(const ValueKey('open-payment-sheet')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-payment-close')));
    await tester.pumpAndSettle();
    expect(session.selectedPayment, 'Card');
  });

  testWidgets('stale destination or view cannot receive a payment choice', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    await openSheet(tester, session);

    session.openDestination(BuyV2Destination.medicine);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buy-payment-Card')));
    await tester.pumpAndSettle();
    expect(session.selectedPayment, 'UPI');

    session.openDestination(BuyV2Destination.shop);
    await tester.tap(find.byKey(const ValueKey('open-payment-sheet')));
    await tester.pumpAndSettle();
    session.openAccount();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buy-payment-Card')));
    await tester.pumpAndSettle();
    expect(session.selectedPayment, 'UPI');
  });

  testWidgets('named route and selected option expose one semantic owner', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = BuyV2Session(core: BuySession())..choosePayment('Card');
    addTearDown(session.dispose);
    await openSheet(tester, session);

    final route = find.byKey(const ValueKey('buy-payment-sheet-route'));
    expect(tester.getSemantics(route).label, 'Payment methods');
    final selected = tester.getSemantics(
      find.byKey(const ValueKey('buy-payment-semantics-Card')),
    );
    expect(selected.label, contains('Card, selected'));
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

    final target = find.byKey(const ValueKey('buy-payment-Card'));
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

    await tester.tap(find.byKey(const ValueKey('buy-payment-Card')));
    await tester.pump();
    await tester.pump();
    expect(session.selectedPayment, 'Card');
    expect(find.byKey(const ValueKey('buy-payment-sheet-route')), findsNothing);
  });

  testWidgets('address selection continues directly from Cart to Checkout', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    expect(session.addProduct(product.id), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              key: const ValueKey('open-address-to-checkout'),
              onPressed: () => showBuyV2AddressSheet(
                context,
                session,
                continueToCheckoutAfterSelection: true,
              ),
              child: const Text('Choose address'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-address-to-checkout')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-address-work')));
    await tester.pumpAndSettle();

    expect(session.selectedAddressId, 'work');
    expect(session.view, BuyV2View.checkout);
    expect(find.byKey(const ValueKey('buy-address-sheet-route')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'UPI collection preserves pending until payment connector confirms',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      expect(session.addProduct(product.id), isTrue);
      session.openCart(scope: BuyV2CartScope.shop);
      expect(session.openCheckout(), isTrue);
      expect(session.selectedPayment, 'UPI');
      final handedOff = <Uri>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(
            session: session,
            paymentHandoff: (uri) async {
              handedOff.add(uri);
              return true;
            },
            initialDestination: BuyV2Destination.shop,
            initialView: BuyV2View.checkout,
            initialCartScope: BuyV2CartScope.shop,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('buy-checkout-primary-address')),
      );
      await tester.pumpAndSettle();
      expect(handedOff, hasLength(1));
      expect(handedOff.single.scheme, 'https');
      expect(handedOff.single.host, 'payments.moolsocial.app');
      expect(session.confirmedOrders, isEmpty);
      expect(session.cartLines, hasLength(1));
      expect(
        session.checkoutSubmissionState,
        BuyV2CheckoutSubmissionState.paymentPending,
      );
      expect(find.text('Payment confirmation pending'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('buy-checkout-primary-payment')),
      );
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.checkout);
      expect(find.text('Order placed'), findsNothing);
      expect(session.confirmedOrders, isEmpty);
      expect(session.cartLines, hasLength(1));
      expect(
        session.checkoutSubmissionState,
        BuyV2CheckoutSubmissionState.paymentPending,
      );
      expect(tester.takeException(), isNull);
    },
  );

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
      final session = BuyV2Session(core: BuySession())..choosePayment('Card');
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
