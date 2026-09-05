import 'dart:io';
import 'dart:ui' show ImageByteFormat, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_cart_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_invoice.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

class _R66OrderCustomerStore implements BuyV2CustomerStateStore {
  @override
  String get ownerScope => 'r66-order-group-customer';

  BuyV2CustomerStateSnapshot? snapshot;

  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => snapshot;

  @override
  Future<bool> write(BuyV2CustomerStateSnapshot value) async {
    snapshot = value;
    return true;
  }
}

class _MemoryGstInvoiceProfileStore implements BuyV2GstInvoiceProfileStore {
  @override
  String? ownerScope = 'account-a';
  bool acceptWrites = true;
  final Map<String, BuyV2GstInvoiceProfileSnapshot> snapshots = {};

  @override
  Future<BuyV2GstInvoiceProfileSnapshot?> read() async {
    final scope = ownerScope;
    return scope == null ? null : snapshots[scope];
  }

  @override
  Future<bool> write(BuyV2GstInvoiceProfileSnapshot snapshot) async {
    final scope = ownerScope;
    if (scope == null || !acceptWrites) return false;
    snapshots[scope] = snapshot;
    return true;
  }
}

class _PaymentTermsAdapter implements BuyV2CommercialPaymentTermsAdapter {
  BuyV2CommerceLoadState state = BuyV2CommerceLoadState.ready;
  String? customerMessage;

  @override
  Future<BuyV2CommercialPaymentTermsSnapshot> loadTerms({
    required List<BuyV2FulfilmentGroup> groups,
    required String selectedPaymentMethod,
    required Map<String, int> quotedTotalsByFulfilmentKey,
  }) async {
    if (state != BuyV2CommerceLoadState.ready) {
      return BuyV2CommercialPaymentTermsSnapshot(
        state: state,
        customerMessage: customerMessage,
      );
    }
    int totalFor(BuyV2FulfilmentGroup group) =>
        quotedTotalsByFulfilmentKey[group.key] ?? group.total;
    return BuyV2CommercialPaymentTermsSnapshot(
      state: state,
      terms: [
        for (final group in groups)
          if (group.destination != BuyV2Destination.wholesale)
            BuyV2CommercialPaymentTerm(
              id: 'retail-advance-${group.destination.name}',
              fulfilmentKey: group.key,
              destination: group.destination,
              supplierName: group.partner,
              kind: BuyV2CommercialPaymentTermKind.retailAdvance,
              orderTotal: totalFor(group),
              amountDueNow: totalFor(group),
              balanceDue: 0,
              balanceDueLabel: 'Paid in full',
              sourceId: 'retail-terms-source',
            )
          else ...[
            BuyV2CommercialPaymentTerm(
              id: 'wholesale-advance',
              fulfilmentKey: group.key,
              destination: group.destination,
              supplierName: group.partner,
              kind: BuyV2CommercialPaymentTermKind.wholesaleAdvance,
              orderTotal: totalFor(group),
              amountDueNow: totalFor(group),
              balanceDue: 0,
              balanceDueLabel: 'Paid in full',
              sourceId: 'workspace-terms-source',
              supplierIsMicroOrSmall: true,
            ),
            BuyV2CommercialPaymentTerm(
              id: 'wholesale-booking-delivery',
              fulfilmentKey: group.key,
              destination: group.destination,
              supplierName: group.partner,
              kind: BuyV2CommercialPaymentTermKind.bookingBalanceOnDelivery,
              orderTotal: totalFor(group),
              amountDueNow: totalFor(group) ~/ 4,
              balanceDue: totalFor(group) - (totalFor(group) ~/ 4),
              balanceDueLabel: 'at delivery',
              sourceId: 'workspace-terms-source',
              supplierIsMicroOrSmall: true,
            ),
            BuyV2CommercialPaymentTerm(
              id: 'wholesale-credit-30',
              fulfilmentKey: group.key,
              destination: group.destination,
              supplierName: group.partner,
              kind: BuyV2CommercialPaymentTermKind.supplierCredit,
              orderTotal: totalFor(group),
              amountDueNow: 0,
              balanceDue: totalFor(group),
              balanceDueLabel: 'within 30 days of delivery',
              sourceId: 'workspace-terms-source',
              supplierIsMicroOrSmall: true,
              netDays: 30,
            ),
            BuyV2CommercialPaymentTerm(
              id: 'invalid-msme-credit-90',
              fulfilmentKey: group.key,
              destination: group.destination,
              supplierName: group.partner,
              kind: BuyV2CommercialPaymentTermKind.supplierCredit,
              orderTotal: totalFor(group),
              amountDueNow: 0,
              balanceDue: totalFor(group),
              balanceDueLabel: 'within 90 days of delivery',
              sourceId: 'workspace-terms-source',
              supplierIsMicroOrSmall: true,
              netDays: 90,
            ),
            BuyV2CommercialPaymentTerm(
              id: 'regulated-credit-90',
              fulfilmentKey: group.key,
              destination: group.destination,
              supplierName: group.partner,
              kind: BuyV2CommercialPaymentTermKind.regulatedCredit,
              orderTotal: totalFor(group),
              amountDueNow: 0,
              balanceDue: totalFor(group),
              balanceDueLabel: 'to the financier over 90 days',
              sourceId: 'regulated-credit-source',
              supplierIsMicroOrSmall: true,
              netDays: 90,
              financierName: 'Partner Bank',
              annualPercentageRate: 12.5,
              keyFactsUri: Uri.parse('https://bank.example/kfs/offer-1'),
            ),
          ],
      ],
    );
  }
}

class _CheckoutQuoteAdapter implements BuyV2CheckoutQuoteAdapter {
  BuyV2CommerceLoadState state = BuyV2CommerceLoadState.ready;
  String? customerMessage;

  @override
  Future<BuyV2CheckoutQuoteSnapshot> loadQuote({
    required List<BuyV2FulfilmentGroup> groups,
    required BuyV2Address address,
    required String selectedPaymentMethod,
    required List<BuyV2CartBenefit> selectedBenefits,
    required Map<String, int> tipAmountsByFulfilmentKey,
  }) async {
    if (state != BuyV2CommerceLoadState.ready) {
      return BuyV2CheckoutQuoteSnapshot(
        state: state,
        customerMessage: customerMessage,
      );
    }
    final couponByDestination = {
      for (final benefit in selectedBenefits)
        if (benefit.kind == BuyV2CartBenefitKind.coupon)
          benefit.destination: benefit.savingAmount,
    };
    final lines = <BuyV2CheckoutQuoteLine>[];
    for (final group in groups) {
      final availableCoupon = couponByDestination[group.destination] ?? 0;
      final coupon = availableCoupon > group.total
          ? group.total
          : availableCoupon;
      couponByDestination[group.destination] = availableCoupon - coupon;
      final tax = group.total * 5 ~/ 100;
      final freight = group.destination == BuyV2Destination.wholesale ? 20 : 0;
      final deliveryFee = group.destination == BuyV2Destination.shop ? 10 : 0;
      final tip = tipAmountsByFulfilmentKey[group.key] ?? 0;
      lines.add(
        BuyV2CheckoutQuoteLine(
          fulfilmentKey: group.key,
          itemSubtotal: group.total,
          couponSaving: coupon,
          tax: tax,
          freight: freight,
          deliveryFee: deliveryFee,
          tip: tip,
          paymentCharge: 0,
          total: group.total - coupon + tax + freight + deliveryFee + tip,
        ),
      );
    }
    final evaluatedAt = DateTime.now();
    return BuyV2CheckoutQuoteSnapshot(
      state: state,
      quote: BuyV2CheckoutQuote(
        id: 'QUOTE-TEST-1',
        sourceId: 'checkout-quote-source',
        evaluatedAt: evaluatedAt,
        validUntil: evaluatedAt.add(const Duration(minutes: 15)),
        lines: lines,
        total: lines.fold(0, (total, line) => total + line.total),
      ),
    );
  }
}

class _DeliveryPromiseFactsAdapter implements BuyV2ProductFactsAdapter {
  @override
  BuyV2ProductFactsSnapshot snapshotFor(
    BuyV2Product product,
  ) => const BuyV2CatalogueProductFactsAdapter()
      .snapshotFor(product)
      .copyWith(
        promisedByLabel: 'by tomorrow 4:00 PM',
        dispatchPromise: product.destination == BuyV2Destination.wholesale
            ? 'Dispatch within one business day'
            : 'Dispatch after packing',
        deliveryProviderName: product.destination == BuyV2Destination.wholesale
            ? 'Rajasthan Freight Network'
            : 'Mool Local Delivery',
        deliveryServiceLevel: product.destination == BuyV2Destination.wholesale
            ? 'Business freight · tracked'
            : 'Local tracked delivery',
        sourceId: 'provider-delivery-promise-source',
      );
}

class _BalancePaymentAdapter implements BuyV2BalancePaymentAdapter {
  int startCalls = 0;
  int reconcileCalls = 0;
  int amountDue = 100;

  @override
  Future<BuyV2BalancePaymentResult> loadBalance({
    required String orderId,
  }) async => BuyV2BalancePaymentResult(
    state: BuyV2BalancePaymentState.due,
    amountDue: amountDue,
    dueLabel: 'due today',
    customerMessage: 'The supplier confirmed this balance is due.',
  );

  @override
  Future<BuyV2BalancePaymentResult> startPayment({
    required String orderId,
    required int amountDue,
    required String idempotencyKey,
  }) async {
    startCalls += 1;
    return BuyV2BalancePaymentResult(
      state: BuyV2BalancePaymentState.paymentActionRequired,
      amountDue: amountDue,
      dueLabel: 'due today',
      customerMessage: 'Continue to the payment app.',
      paymentReference: 'BALANCE-PAY-1',
      paymentActionUri: Uri.parse('upi://pay?pa=supplier@example'),
    );
  }

  @override
  Future<BuyV2BalancePaymentResult> reconcilePayment({
    required String orderId,
    required String paymentReference,
  }) async {
    reconcileCalls += 1;
    return const BuyV2BalancePaymentResult(
      state: BuyV2BalancePaymentState.paid,
      amountDue: 0,
      dueLabel: 'Paid now',
      customerMessage: 'Balance payment confirmed.',
      paymentReference: 'BALANCE-PAY-1',
    );
  }
}

class _DeliveryExceptionAdapter implements BuyV2DeliveryExceptionAdapter {
  BuyV2DeliveryExceptionSnapshot snapshot =
      const BuyV2DeliveryExceptionSnapshot(
        state: BuyV2CommerceLoadState.ready,
        customerMessage: 'Choose another delivery time.',
        exceptionId: 'DELIVERY-EX-1',
        kind: BuyV2DeliveryExceptionKind.rescheduleAvailable,
        headline: 'Delivery needs a new time',
        detail: 'The previous delivery attempt could not be completed.',
        rescheduleSlots: ['Tomorrow · 10 am–12 pm', 'Tomorrow · 2–4 pm'],
      );
  int rescheduleCalls = 0;
  int disputeCalls = 0;

  @override
  Future<BuyV2DeliveryExceptionSnapshot> loadException({
    required String orderId,
  }) async => snapshot;

  @override
  Future<BuyV2DeliveryExceptionSnapshot> rescheduleDelivery({
    required String orderId,
    required String exceptionId,
    required String slot,
  }) async {
    rescheduleCalls += 1;
    snapshot = BuyV2DeliveryExceptionSnapshot(
      state: BuyV2CommerceLoadState.ready,
      customerMessage: 'Delivery rescheduled for $slot.',
      exceptionId: exceptionId,
      kind: BuyV2DeliveryExceptionKind.dispatchDelayed,
      headline: 'New delivery time confirmed',
      detail: slot,
    );
    return snapshot;
  }

  @override
  Future<BuyV2DeliveryExceptionSnapshot> disputeProofOfDelivery({
    required String orderId,
    required String exceptionId,
    required String proofReference,
  }) async {
    disputeCalls += 1;
    snapshot = BuyV2DeliveryExceptionSnapshot(
      state: BuyV2CommerceLoadState.ready,
      customerMessage: 'Delivery problem reported for review.',
      exceptionId: exceptionId,
      kind: BuyV2DeliveryExceptionKind.proofOfDeliveryDisputed,
      headline: 'Proof of delivery is under review',
      detail: 'Keep this order available while the delivery is checked.',
      proofReference: proofReference,
    );
    return snapshot;
  }
}

Future<bool> _submitAndCompleteReviewPayment(BuyV2Session session) async {
  if (await session.submitOrder()) return true;
  if (session.checkoutSubmissionState !=
      BuyV2CheckoutSubmissionState.paymentActionRequired) {
    return false;
  }
  if (!await session.continuePayment((_) async => true)) return false;
  return session.reconcilePayment();
}

Future<void> _captureR66Checkout(
  WidgetTester tester,
  int amount,
  double width,
  double scale,
  String stage,
) async {
  if (!const bool.fromEnvironment('BUY_R66_CHECKOUT_CAPTURE')) return;
  const requestedStage = String.fromEnvironment(
    'BUY_R66_CHECKOUT_CAPTURE_STAGE',
  );
  if (!['address', 'payment', 'confirm', 'action'].contains(requestedStage)) {
    throw StateError('Choose one exact checkout capture stage');
  }
  if (stage != requestedStage) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('r66-checkout-review-capture')),
  );
  await tester.runAsync(() async {
    final directory = Directory('build/r66-checkout-review-v3-20260905');
    await directory.create(recursive: true);
    final output = File(
      '${directory.path}/$stage-INR$amount-width$width-text$scale.png',
    );
    if (await output.exists()) {
      throw StateError('Checkout capture already exists');
    }
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ImageByteFormat.png);
      if (data == null) throw StateError('Checkout capture encoding failed');
      await output.writeAsBytes(data.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

class _R66CheckoutAmountFixture extends BuyV2Session {
  _R66CheckoutAmountFixture(this.displayAmount, {required super.core});

  final int displayAmount;

  @override
  int get checkoutAmountDueNow => displayAmount;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    Size size = const Size(390, 844),
    double textScale = 1,
    bool reducedMotion = false,
    EdgeInsets safeArea = EdgeInsets.zero,
    EdgeInsets viewInsets = EdgeInsets.zero,
    BuyV2PaymentHandoff? paymentHandoff,
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: size,
          padding: safeArea,
          viewPadding: safeArea,
          viewInsets: viewInsets,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
        ),
        child: const bool.fromEnvironment('BUY_R66_CHECKOUT_CAPTURE')
            ? RepaintBoundary(
                key: const ValueKey('r66-checkout-review-capture'),
                child: child!,
              )
            : child!,
      ),
      home: BuyV2Screen(
        session: session,
        initialDestination: session.destination,
        initialView: session.view,
        initialCartScope: session.cartScope,
        paymentHandoff: paymentHandoff,
      ),
    );
  }

  BuyV2Product productFor(BuyV2Destination destination) =>
      BuyV2Catalogue.products.firstWhere(
        (product) =>
            product.destination == destination && !product.requiresPrescription,
      );

  BuyV2Session mixedSession({
    BuyV2GstInvoiceProfileStore? gstInvoiceProfileStore,
  }) {
    final session = BuyV2Session(
      core: BuySession(),
      gstInvoiceProfileStore: gstInvoiceProfileStore,
    );
    for (final destination in const [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ]) {
      expect(session.addProduct(productFor(destination).id), isTrue);
    }
    return session;
  }

  void advanceCheckoutToConfirm(BuyV2Session session) {
    expect(session.continueCheckoutFromAddress(), isTrue);
    expect(session.continueCheckoutFromPayment(), isTrue);
    expect(session.checkoutStep, BuyV2CheckoutStep.confirm);
  }

  for (final width in [320.0, 360.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final amount in [1, 10000000]) {
        testWidgets(
          'R66 checkout complete action INR$amount at $width text$scale',
          (tester) async {
            final size = Size(width, 800);
            await tester.binding.setSurfaceSize(size);
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final core = BuySession();
            final session = _R66CheckoutAmountFixture(amount, core: core);
            addTearDown(session.dispose);
            addTearDown(core.dispose);
            expect(session.addProduct('w-notebook'), isTrue);
            session.openCart(scope: BuyV2CartScope.wholesale);
            expect(session.openCheckout(), isTrue);
            expect(session.choosePayment('PhonePe'), isTrue);
            await tester.pumpWidget(
              app(
                session,
                size: size,
                textScale: scale,
                safeArea: const EdgeInsets.only(top: 24, bottom: 32),
                paymentHandoff: (_) async => true,
              ),
            );
            await tester.pumpAndSettle();

            void expectCompleteFooter(String label) {
              final progress = find.byKey(
                ValueKey('buy-checkout-progress-${session.checkoutStep.name}'),
              );
              final cellHeights = <double>[];
              for (final stepLabel in ['Address', 'Payment', 'Confirm order']) {
                final text = find.descendant(
                  of: progress,
                  matching: find.text(stepLabel),
                );
                final paragraph = tester.renderObject<RenderParagraph>(text);
                for (final word in stepLabel.split(' ')) {
                  final wordPainter = TextPainter(
                    text: TextSpan(text: word, style: paragraph.text.style),
                    textDirection: paragraph.textDirection,
                    textScaler: paragraph.textScaler,
                  )..layout();
                  expect(
                    paragraph.size.width + .1,
                    greaterThanOrEqualTo(wordPainter.width),
                    reason: 'Unbroken checkout word: $word',
                  );
                  wordPainter.dispose();
                }
                expect(
                  paragraph.didExceedMaxLines,
                  isFalse,
                  reason: 'Complete checkout step: $stepLabel',
                );
                cellHeights.add(
                  tester
                      .getSize(
                        find
                            .ancestor(
                              of: text,
                              matching: find.byType(AnimatedContainer),
                            )
                            .first,
                      )
                      .height,
                );
              }
              expect(cellHeights.toSet(), hasLength(1));
              final bar = find.byKey(const ValueKey('buy-checkout-action-bar'));
              final action = find.byKey(
                ValueKey('buy-checkout-primary-${session.checkoutStep.name}'),
              );
              final actionRect = tester.getRect(action);
              expect(actionRect.height, greaterThanOrEqualTo(44));
              expect(actionRect.left, greaterThanOrEqualTo(0));
              expect(actionRect.right, lessThanOrEqualTo(width));
              expect(actionRect.bottom, lessThanOrEqualTo(768));
              expect(
                find.descendant(of: action, matching: find.text(label)),
                findsOneWidget,
              );
              expect(
                find.descendant(
                  of: bar,
                  matching: find.text(buyV2Money(amount)),
                ),
                findsOneWidget,
              );
              for (final finder
                  in find
                      .descendant(of: bar, matching: find.byType(RichText))
                      .evaluate()
                      .map(
                        (element) => find.byElementPredicate(
                          (candidate) => identical(candidate, element),
                        ),
                      )) {
                final paragraph = tester.renderObject<RenderParagraph>(finder);
                expect(
                  paragraph.didExceedMaxLines,
                  isFalse,
                  reason: paragraph.text.toPlainText(),
                );
                final natural = TextPainter(
                  text: paragraph.text,
                  textDirection: paragraph.textDirection,
                  textScaler: paragraph.textScaler,
                )..layout(maxWidth: paragraph.size.width);
                expect(
                  paragraph.size.height + .1,
                  greaterThanOrEqualTo(natural.height),
                  reason: paragraph.text.toPlainText(),
                );
                natural.dispose();
                final textRect = tester.getRect(finder);
                expect(textRect.left, greaterThanOrEqualTo(0));
                expect(textRect.right, lessThanOrEqualTo(width));
                expect(textRect.bottom, lessThanOrEqualTo(768));
              }
              expect(tester.takeException(), isNull);
            }

            expectCompleteFooter('Continue to payment');
            await _captureR66Checkout(tester, amount, width, scale, 'address');
            await tester.tap(
              find.byKey(const ValueKey('buy-checkout-primary-address')),
            );
            await tester.pumpAndSettle();
            expect(session.checkoutStep, BuyV2CheckoutStep.payment);
            expectCompleteFooter('Review order');
            await _captureR66Checkout(tester, amount, width, scale, 'payment');
            await tester.tap(
              find.byKey(const ValueKey('buy-checkout-primary-payment')),
            );
            await tester.pumpAndSettle();
            expect(session.checkoutStep, BuyV2CheckoutStep.confirm);
            expectCompleteFooter('Place order');
            await _captureR66Checkout(tester, amount, width, scale, 'confirm');
            expect(await session.submitOrder(), isFalse);
            await tester.pumpAndSettle();
            expect(
              session.checkoutSubmissionState,
              BuyV2CheckoutSubmissionState.paymentActionRequired,
            );
            expectCompleteFooter('Pay ${buyV2Money(amount)}');
            await _captureR66Checkout(tester, amount, width, scale, 'action');
            expect(session.confirmedOrders, isEmpty);
            expect(session.quantityFor('w-notebook'), 1);
          },
        );
      }
    }
  }

  testWidgets(
    'R66 checkout hides footer for IME without losing stage or Back',
    (tester) async {
      const size = Size(320, 568);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.addProduct('w-notebook'), isTrue);
      session.openCart(scope: BuyV2CartScope.wholesale);
      expect(session.openCheckout(), isTrue);
      expect(session.choosePayment('PhonePe'), isTrue);
      for (final step in [
        BuyV2CheckoutStep.address,
        BuyV2CheckoutStep.payment,
      ]) {
        if (step == BuyV2CheckoutStep.payment) {
          expect(session.continueCheckoutFromAddress(), isTrue);
        }
        for (final keyboard in [true, false]) {
          await tester.pumpWidget(
            app(
              session,
              size: size,
              textScale: 2,
              safeArea: const EdgeInsets.only(top: 24, bottom: 24),
              viewInsets: EdgeInsets.only(bottom: keyboard ? 260 : 0),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-checkout-action-bar')),
            keyboard ? findsNothing : findsOneWidget,
          );
          expect(session.checkoutStep, step);
          expect(session.cartScope, BuyV2CartScope.wholesale);
          expect(session.selectedPayment, 'PhonePe');
          expect(session.quantityFor('w-notebook'), 1);
          expect(tester.takeException(), isNull);
        }
      }
      await tester.tap(find.byKey(const ValueKey('buy-checkout-back')));
      await tester.pumpAndSettle();
      expect(session.checkoutStep, BuyV2CheckoutStep.address);
      await tester.tap(find.byKey(const ValueKey('buy-checkout-return-cart')));
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.cart);
      expect(session.cartScope, BuyV2CartScope.wholesale);
      expect(session.quantityFor('w-notebook'), 1);
      expect(tester.takeException(), isNull);
    },
  );

  Future<BuyV2Session> mountPaymentAction(
    WidgetTester tester,
    String provider, {
    BuyV2PaymentHandoff? handoff,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.addProduct('w-notebook'), isTrue);
    session.openCart(scope: BuyV2CartScope.wholesale);
    await tester.pumpWidget(app(session, paymentHandoff: handoff));
    await tester.pumpAndSettle();
    expect(session.openCheckout(), isTrue);
    expect(session.choosePayment(provider), isTrue);
    advanceCheckoutToConfirm(session);
    expect(await session.submitOrder(), isFalse);
    await tester.pumpAndSettle();
    expect(
      session.checkoutSubmissionState,
      BuyV2CheckoutSubmissionState.paymentActionRequired,
    );
    return session;
  }

  for (final provider in ['PhonePe', 'Paytm', 'Pine Labs']) {
    testWidgets('R66 missing $provider handoff cannot simulate payment', (
      tester,
    ) async {
      final session = await mountPaymentAction(tester, provider);
      final reference = session.paymentReference;
      final attempt = session.checkoutIdempotencyKey;
      expect(find.text('Payment unavailable right now'), findsOneWidget);
      expect(find.text('Ready for secure payment'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('buy-checkout-primary-payment')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-payment-handoff-completed')),
        findsNothing,
      );
      expect(find.text('Payment completed'), findsNothing);
      expect(
        session.checkoutSubmissionState,
        BuyV2CheckoutSubmissionState.paymentActionRequired,
      );
      expect(session.paymentReference, reference);
      expect(session.checkoutIdempotencyKey, attempt);
      expect(session.confirmedOrders, isEmpty);
      expect(session.quantityFor('w-notebook'), 1);
      final cancel = find.byKey(const ValueKey('buy-checkout-cancel-payment'));
      await tester.ensureVisible(cancel);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(
        session.checkoutSubmissionState,
        BuyV2CheckoutSubmissionState.cancelled,
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-checkout-primary-payment')),
      );
      await tester.pumpAndSettle();
      expect(
        session.checkoutSubmissionState,
        BuyV2CheckoutSubmissionState.idle,
      );
      expect(session.quantityFor('w-notebook'), 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('R66 injected handoff launches once and remains unconfirmed', (
    tester,
  ) async {
    final opened = <Uri>[];
    final session = await mountPaymentAction(
      tester,
      'PhonePe',
      handoff: (uri) async {
        opened.add(uri);
        return true;
      },
    );
    expect(find.text('Ready for secure payment'), findsOneWidget);
    final expectedUri = session.paymentActionUri;
    await tester.tap(
      find.byKey(const ValueKey('buy-checkout-primary-payment')),
    );
    await tester.pumpAndSettle();
    expect(opened, [expectedUri]);
    expect(
      session.checkoutSubmissionState,
      BuyV2CheckoutSubmissionState.paymentPending,
    );
    expect(session.confirmedOrders, isEmpty);
    expect(
      find.byKey(const ValueKey('buy-payment-handoff-completed')),
      findsNothing,
    );
    expect(session.quantityFor('w-notebook'), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('R66 confirmed purchase opens only its own retained deliveries', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = _R66OrderCustomerStore();
    final earlierCore = BuySession();
    final earlier = BuyV2Session(core: earlierCore, customerStateStore: store);
    expect(earlier.addProduct('w-notebook'), isTrue);
    earlier.openCart(scope: BuyV2CartScope.wholesale);
    expect(earlier.openCheckout(), isTrue);
    expect(earlier.choosePayment('Purchase order'), isTrue);
    earlier.purchaseOrderReference = 'R66-LOCAL-PO';
    advanceCheckoutToConfirm(earlier);
    expect(await earlier.submitOrder(), isTrue);
    final previousPurchase = earlier.confirmedPurchaseId!;
    final previousOrder = earlier.confirmedOrders.single;
    await tester.pump();
    earlier.dispose();
    earlierCore.dispose();

    final core = BuySession();
    final session = BuyV2Session(core: core, customerStateStore: store);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    await session.restoreCustomerState();
    final retail = session.product('s-tomato');
    final anotherStore = BuyV2Catalogue.products.firstWhere(
      (product) =>
          product.destination == BuyV2Destination.shop &&
          product.seller != retail.seller &&
          !product.requiresPrescription,
    );
    expect(session.addProduct(retail.id), isTrue);
    expect(session.addProduct(anotherStore.id), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    expect(session.choosePayment('Cash on Delivery'), isTrue);
    advanceCheckoutToConfirm(session);
    final total = session.checkoutPayableTotal;
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-checkout-primary-confirm')),
    );
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.confirmation);
    expect(session.confirmedOrders, hasLength(2));
    final purchase = session.confirmedPurchaseId!;
    expect(purchase, isNot(previousPurchase));
    final details = find.byKey(
      const ValueKey('buy-confirmation-order-details'),
    );
    await tester.scrollUntilVisible(
      details,
      250,
      scrollable: find
          .descendant(
            of: find.byType(BuyV2ConfirmationView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(details);
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.orders);
    expect(session.view, BuyV2View.catalogue);
    final group = find.byKey(ValueKey('buy-purchase-group-$purchase'));
    expect(group, findsOneWidget);
    expect(
      find.descendant(
        of: group,
        matching: find.text('2 deliveries · ${buyV2Money(total)}'),
      ),
      findsOneWidget,
    );
    final oldGroup = find.byKey(
      ValueKey('buy-purchase-group-$previousPurchase'),
    );
    expect(
      find.descendant(
        of: oldGroup,
        matching: find.text('1 delivery · ${buyV2Money(previousOrder.total)}'),
      ),
      findsOneWidget,
    );
    final delivery = session.confirmedOrders.first;
    final track = find.byKey(ValueKey('buy-order-primary-${delivery.id}'));
    await tester.scrollUntilVisible(
      track,
      200,
      scrollable: find
          .descendant(
            of: find.byType(BuyV2OrdersView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(track);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrderId, delivery.id);
    expect(session.selectedOrderOrNull!.purchaseId, purchase);
    expect(session.selectedOrderOrNull!.total, delivery.total);
    expect(session.selectedOrderOrNull!.partner, delivery.partner);
    expect(tester.takeException(), isNull);
  });

  testWidgets('visible Checkout return restores every exact Cart scope', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();

    for (final scope in BuyV2CartScope.values) {
      final session = mixedSession();
      addTearDown(session.dispose);
      session.openCart(scope: scope);
      session.rememberCartScrollOffset(scope, 37);
      expect(session.openCheckout(), isTrue, reason: scope.name);
      final itemCount = session.checkoutItemCount;
      final total = session.checkoutPayableTotal;
      final addressId = session.selectedAddress.id;
      final payment = session.selectedPayment;

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      final returnOwner = find.byKey(
        const ValueKey('buy-checkout-return-cart'),
      );
      expect(returnOwner, findsOneWidget, reason: scope.name);
      final semanticNode = tester.getSemantics(returnOwner);
      final semanticData = semanticNode.getSemanticsData();
      expect(semanticData.label, 'Cart', reason: scope.name);
      expect(
        semanticData.hasAction(SemanticsAction.tap),
        isTrue,
        reason: scope.name,
      );
      expect(semanticNode.rect.width, lessThan(140), reason: scope.name);
      expect(semanticNode.rect.height, greaterThanOrEqualTo(44));

      await tester.tapAt(tester.getCenter(returnOwner));
      await tester.pumpAndSettle();

      expect(session.view, BuyV2View.cart, reason: scope.name);
      expect(session.cartScope, scope, reason: scope.name);
      expect(session.scopedItemCount, itemCount, reason: scope.name);
      expect(session.scopedPayableTotal, total, reason: scope.name);
      expect(session.selectedAddress.id, addressId, reason: scope.name);
      expect(session.selectedPayment, payment, reason: scope.name);
      expect(session.cartScrollOffsetFor(scope), 37, reason: scope.name);
      expect(tester.takeException(), isNull, reason: scope.name);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
    semantics.dispose();
  });

  testWidgets('visible return and Android Back preserve identical Shop state', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    BuyV2Session checkout() {
      final session = mixedSession();
      session.openCart(scope: BuyV2CartScope.shop);
      expect(session.openCheckout(), isTrue);
      return session;
    }

    final visible = checkout();
    final android = checkout();
    addTearDown(visible.dispose);
    addTearDown(android.dispose);

    await tester.pumpWidget(app(visible));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-checkout-return-cart')));
    await tester.pumpAndSettle();

    android.goBack();

    expect(visible.view, android.view);
    expect(visible.cartScope, android.cartScope);
    expect(visible.scopedItemCount, android.scopedItemCount);
    expect(visible.scopedPayableTotal, android.scopedPayableTotal);
    expect(visible.selectedAddress.id, android.selectedAddress.id);
    expect(visible.selectedPayment, android.selectedPayment);
    expect(
      {for (final line in visible.cartLines) line.product.id: line.quantity},
      {for (final line in android.cartLines) line.product.id: line.quantity},
    );
  });

  testWidgets('T01B adds optional GST details without buyer categories', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final gstStore = _MemoryGstInvoiceProfileStore();
    final session = mixedSession(gstInvoiceProfileStore: gstStore);
    addTearDown(session.dispose);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    advanceCheckoutToConfirm(session);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(find.text('Add GST details'), findsOneWidget);
    expect(find.textContaining('Personal'), findsNothing);
    expect(find.textContaining('Business purchase'), findsNothing);
    expect(find.text('Place order'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buy-gst-request-shop')));
    await tester.pumpAndSettle();
    expect(find.text('Add GST details'), findsWidgets);
    expect(find.byKey(const ValueKey('buy-gst-add-shop')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buy-gst-add-shop')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-gst-legal-name')),
      'Shree Balaji Retail',
    );
    await tester.enterText(
      find.byKey(const ValueKey('buy-gst-gstin')),
      '08ABCDE1234F1Z5',
    );
    await tester.enterText(
      find.byKey(const ValueKey('buy-gst-billing-address')),
      '12 Market Road, Jodhpur 342003',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('buy-gst-save')));
    await tester.tap(find.byKey(const ValueKey('buy-gst-save')));
    await tester.pumpAndSettle();

    expect(find.text('GST added'), findsOneWidget);
    expect(find.text('Shree Balaji Retail'), findsWidgets);
    expect(find.textContaining('08ABCDE1234F1Z5'), findsOneWidget);
    expect(find.text('Place order'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-gst-profile-gst-profile-1')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Retail advance and Wholesale terms retain exact payment schedule',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final adapter = _PaymentTermsAdapter();
      final session = BuyV2Session(
        core: BuySession(),
        commercialPaymentTermsAdapter: adapter,
      );
      addTearDown(session.dispose);
      final shop = productFor(BuyV2Destination.shop);
      final wholesale = productFor(BuyV2Destination.wholesale);
      expect(session.addProduct(shop.id), isTrue);
      expect(session.addProduct(wholesale.id), isTrue);
      session.openCart();
      expect(session.openCheckout(), isTrue);
      advanceCheckoutToConfirm(session);
      await session.refreshCommercialPaymentTerms();

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-checkout-payment-terms')),
        findsOneWidget,
      );
      expect(find.text('Full advance'), findsWidgets);
      expect(find.textContaining('Supplier credit · 30 days'), findsOneWidget);
      expect(
        find.textContaining('Partner Bank credit · 90 days'),
        findsOneWidget,
      );
      expect(find.textContaining('Supplier credit · 90 days'), findsNothing);
      expect(session.checkoutPaymentTermsReviewRequired, isTrue);

      final booking = find.byKey(
        const ValueKey('buy-payment-term-wholesale-booking-delivery'),
      );
      await tester.ensureVisible(booking);
      await tester.tap(booking);
      await tester.pumpAndSettle();
      expect(session.checkoutPaymentTermsReviewRequired, isFalse);
      expect(session.checkoutBalanceDue, greaterThan(0));
      expect(
        find.byKey(const ValueKey('buy-checkout-amount-due-now')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-checkout-balance-due')),
        findsOneWidget,
      );

      expect(await _submitAndCompleteReviewPayment(session), isTrue);
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.confirmation);
      expect(
        find.byKey(const ValueKey('buy-confirmation-payment-schedule')),
        findsOneWidget,
      );
      final wholesaleOrder = session.confirmedOrders.firstWhere(
        (order) => order.destination == BuyV2Destination.wholesale,
      );
      expect(wholesaleOrder.paymentTermLabel, contains('balance at delivery'));
      expect(wholesaleOrder.amountPaidNow, greaterThan(0));
      expect(wholesaleOrder.balanceDue, greaterThan(0));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('payment terms offline state blocks Checkout and retries', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final adapter = _PaymentTermsAdapter()
      ..state = BuyV2CommerceLoadState.offline
      ..customerMessage = 'Reconnect to check supplier payment terms.';
    final session = BuyV2Session(
      core: BuySession(),
      commercialPaymentTermsAdapter: adapter,
    );
    addTearDown(session.dispose);
    expect(session.addProduct(productFor(BuyV2Destination.shop).id), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    advanceCheckoutToConfirm(session);
    await session.refreshCommercialPaymentTerms();

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-checkout-payment-terms-offline')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-checkout-payment-terms-retry')),
      findsOneWidget,
    );
    expect(session.checkoutPaymentTermsReviewRequired, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live Checkout quote retains tax freight delivery and total', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final quoteAdapter = _CheckoutQuoteAdapter();
    final session = BuyV2Session(
      core: BuySession(),
      checkoutQuoteAdapter: quoteAdapter,
      commercialPaymentTermsAdapter: _PaymentTermsAdapter(),
    );
    addTearDown(session.dispose);
    expect(session.addProduct(productFor(BuyV2Destination.shop).id), isTrue);
    expect(
      session.addProduct(productFor(BuyV2Destination.wholesale).id),
      isTrue,
    );
    session.openCart();
    expect(session.openCheckout(), isTrue);
    advanceCheckoutToConfirm(session);
    expect(await session.refreshCheckoutQuote(), isTrue);
    await session.refreshCommercialPaymentTerms();
    final wholesaleGroup = session.checkoutFulfilmentGroups.firstWhere(
      (group) => group.destination == BuyV2Destination.wholesale,
    );
    final wholesaleAdvance = session
        .commercialPaymentTermsFor(wholesaleGroup.key)
        .firstWhere(
          (term) =>
              term.kind == BuyV2CommercialPaymentTermKind.wholesaleAdvance,
        );
    expect(session.chooseCommercialPaymentTerm(wholesaleAdvance), isTrue);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-checkout-live-quote')),
      findsOneWidget,
    );
    expect(find.text('GST and taxes'), findsOneWidget);
    expect(find.text('Freight'), findsOneWidget);
    expect(find.text('Delivery fee'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-checkout-quote-validity')),
      findsOneWidget,
    );
    final quotedTotal = session.checkoutQuote!.total;
    expect(quotedTotal, greaterThan(session.checkoutTotal));

    expect(await _submitAndCompleteReviewPayment(session), isTrue);
    await tester.pumpAndSettle();
    expect(session.confirmedTotal, quotedTotal);
    expect(
      session.confirmedOrders.fold<int>(
        0,
        (total, order) => total + order.total,
      ),
      quotedTotal,
    );
    expect(session.confirmedOrders.any((order) => order.tax > 0), isTrue);
    expect(session.confirmedOrders.any((order) => order.freight > 0), isTrue);
    expect(
      session.confirmedOrders.any((order) => order.deliveryFee > 0),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Checkout quote offline state blocks payment and retries', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final adapter = _CheckoutQuoteAdapter()
      ..state = BuyV2CommerceLoadState.offline
      ..customerMessage = 'Reconnect to check the current total.';
    final session = BuyV2Session(
      core: BuySession(),
      checkoutQuoteAdapter: adapter,
    );
    addTearDown(session.dispose);
    expect(session.addProduct(productFor(BuyV2Destination.shop).id), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    advanceCheckoutToConfirm(session);
    expect(await session.refreshCheckoutQuote(), isFalse);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-checkout-quote-offline')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-checkout-quote-retry')),
      findsOneWidget,
    );
    expect(session.checkoutQuoteReviewRequired, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'provider promise continues from product to Checkout and Tracking',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = BuyV2Session(
        core: BuySession(),
        productFactsAdapter: _DeliveryPromiseFactsAdapter(),
      );
      addTearDown(session.dispose);
      final product = productFor(BuyV2Destination.wholesale);
      session.openDestination(BuyV2Destination.wholesale);
      expect(session.openProduct(product.id), isTrue);

      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();
      final automatic = find.byKey(
        ValueKey('buy-automatic-fulfilment-${product.id}'),
      );
      await tester.scrollUntilVisible(
        automatic,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Dispatch within one business day'), findsOneWidget);
      expect(find.text('Rajasthan Freight Network'), findsOneWidget);
      expect(find.text('Business freight · tracked'), findsOneWidget);

      expect(session.addProduct(product.id), isTrue);
      session.openCart(scope: BuyV2CartScope.wholesale);
      expect(session.openCheckout(), isTrue);
      advanceCheckoutToConfirm(session);
      await tester.pumpAndSettle();
      expect(find.text('Dispatches'), findsOneWidget);
      expect(find.text('Dispatch within one business day'), findsOneWidget);
      expect(find.text('Handled by'), findsOneWidget);
      expect(find.text('Rajasthan Freight Network'), findsOneWidget);
      expect(tester.takeException(), isNull);

      expect(await _submitAndCompleteReviewPayment(session), isTrue);
      final order = session.confirmedOrders.single;
      expect(order.deliveryPartnerName, 'Rajasthan Freight Network');
      expect(order.dispatchPromise, 'Dispatch within one business day');
      expect(session.openTracking(order.id), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Rajasthan Freight Network'), findsOneWidget);
      expect(find.text('Business freight · tracked'), findsOneWidget);
      expect(find.text('Dispatch within one business day'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('R66 missing balance handoff preserves the unpaid balance', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final balanceAdapter = _BalancePaymentAdapter();
    final core = BuySession();
    final session = BuyV2Session(
      core: core,
      commercialPaymentTermsAdapter: _PaymentTermsAdapter(),
      balancePaymentAdapter: balanceAdapter,
    );
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(
      session.addProduct(productFor(BuyV2Destination.wholesale).id),
      isTrue,
    );
    session.openCart(scope: BuyV2CartScope.wholesale);
    expect(session.openCheckout(), isTrue);
    await session.refreshCommercialPaymentTerms();
    final group = session.checkoutFulfilmentGroups.single;
    final booking = session
        .commercialPaymentTermsFor(group.key)
        .firstWhere(
          (term) =>
              term.kind ==
              BuyV2CommercialPaymentTermKind.bookingBalanceOnDelivery,
        );
    expect(session.chooseCommercialPaymentTerm(booking), isTrue);
    expect(await _submitAndCompleteReviewPayment(session), isTrue);
    final order = session.confirmedOrders.single;
    balanceAdapter.amountDue = order.balanceDue;
    expect(session.openTracking(order.id), isTrue);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-tracking-balance-pay-balance')),
    );
    await tester.pumpAndSettle();
    expect(balanceAdapter.startCalls, 1);
    expect(find.text('Balance payment unavailable'), findsOneWidget);
    expect(find.text('Ready for payment'), findsNothing);
    expect(
      find.byKey(const ValueKey('buy-tracking-balance-continue-payment')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('buy-payment-handoff-completed')),
      findsNothing,
    );
    expect(balanceAdapter.reconcileCalls, 0);
    expect(order.balanceDue, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'later balance pays once and reconciles without duplicate payment',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final balanceAdapter = _BalancePaymentAdapter();
      final session = BuyV2Session(
        core: BuySession(),
        commercialPaymentTermsAdapter: _PaymentTermsAdapter(),
        balancePaymentAdapter: balanceAdapter,
      );
      addTearDown(session.dispose);
      final product = productFor(BuyV2Destination.wholesale);
      expect(session.addProduct(product.id), isTrue);
      session.openCart(scope: BuyV2CartScope.wholesale);
      expect(session.openCheckout(), isTrue);
      await session.refreshCommercialPaymentTerms();
      final group = session.checkoutFulfilmentGroups.single;
      final booking = session
          .commercialPaymentTermsFor(group.key)
          .firstWhere(
            (term) =>
                term.kind ==
                BuyV2CommercialPaymentTermKind.bookingBalanceOnDelivery,
          );
      expect(session.chooseCommercialPaymentTerm(booking), isTrue);
      expect(await _submitAndCompleteReviewPayment(session), isTrue);
      final order = session.confirmedOrders.single;
      balanceAdapter.amountDue = order.balanceDue;
      expect(session.openTracking(order.id), isTrue);

      await tester.pumpWidget(app(session, paymentHandoff: (_) async => true));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-tracking-balance-payment')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-tracking-balance-payment')),
          matching: find.text('Balance due'),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-tracking-balance-pay-balance')),
      );
      await tester.pumpAndSettle();
      expect(balanceAdapter.startCalls, 1);
      expect(await session.startBalancePayment(order.id), isFalse);

      await tester.tap(
        find.byKey(const ValueKey('buy-tracking-balance-continue-payment')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Payment pending'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('buy-tracking-balance-check-payment')),
      );
      await tester.pumpAndSettle();
      expect(balanceAdapter.reconcileCalls, 1);
      expect(find.text('Balance paid'), findsOneWidget);
      expect(find.text('No balance remains.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('corrected tax invoice exposes exact legal and GST details', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final product = productFor(BuyV2Destination.shop);
    final line = BuyV2CartLine(product: product, quantity: 1);
    final order = BuyV2Order(
      id: 'ORDER-TAX-1',
      destination: BuyV2Destination.shop,
      title: 'Shop order',
      itemSummary: '1 product',
      total: line.total + 90,
      partner: product.seller,
      partnerType: product.partnerRole,
      promise: product.deliveryPromise,
      destinationLabel: 'Sardarpura · 342003',
      progress: 1,
      status: BuyV2OrderStatus.delivered,
      lines: [line],
      tax: 90,
      taxInvoiceState: BuyV2TaxInvoiceState.corrected,
      taxInvoiceDetails: BuyV2TaxInvoiceDetails(
        invoiceNumber: 'TAX-INV-1001-R1',
        issuedAt: DateTime(2026, 8, 29, 18, 30),
        sellerLegalName: 'Mool Retail Partner Private Limited',
        sellerAddress: 'Jodhpur, Rajasthan 342003',
        sellerGstin: '08ABCDE1234F1Z5',
        buyerGstin: '08AAAAA0000A1Z5',
        placeOfSupply: 'Rajasthan (08)',
        sourceId: 'seller-tax-invoice-source',
        revisionLabel: 'Corrected seller address',
        lines: const [
          BuyV2TaxInvoiceLine(
            description: 'Shop products',
            hsnSac: '19059090',
            taxableValue: 1000,
            gstRate: 9,
            cgst: 45,
            sgst: 45,
            igst: 0,
            cess: 0,
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: BuyV2InvoicePage(order: order),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Corrected tax invoice'), findsOneWidget);
    expect(find.text('TAX-INV-1001-R1'), findsWidgets);
    expect(find.text('08ABCDE1234F1Z5'), findsOneWidget);
    expect(find.text('08AAAAA0000A1Z5'), findsOneWidget);
    expect(find.text('Rajasthan (08)'), findsOneWidget);
    expect(find.text('19059090'), findsOneWidget);
    expect(find.text('CGST'), findsOneWidget);
    expect(find.text('SGST'), findsOneWidget);
    final download = find.byKey(
      const ValueKey('buy-download-invoice-ORDER-TAX-1'),
    );
    await tester.scrollUntilVisible(
      download,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.widget<FilledButton>(download).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delivery exception reschedules and disputes proof in place', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final adapter = _DeliveryExceptionAdapter();
    final session = BuyV2Session(
      core: BuySession(),
      deliveryExceptionAdapter: adapter,
    );
    addTearDown(session.dispose);
    final order = session.orders.first;
    expect(session.openTracking(order.id), isTrue);

    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-delivery-exception-rescheduleAvailable')),
      findsOneWidget,
    );
    const slot = 'Tomorrow · 10 am–12 pm';
    final slotChoice = find.byKey(const ValueKey('buy-delivery-slot-$slot'));
    await tester.scrollUntilVisible(
      slotChoice,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(slotChoice);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-delivery-confirm-reschedule')),
    );
    await tester.pumpAndSettle();
    expect(adapter.rescheduleCalls, 1);
    expect(find.text('New delivery time confirmed'), findsOneWidget);

    adapter.snapshot = const BuyV2DeliveryExceptionSnapshot(
      state: BuyV2CommerceLoadState.ready,
      customerMessage: 'Proof of delivery is available.',
      exceptionId: 'DELIVERY-EX-2',
      kind: BuyV2DeliveryExceptionKind.proofOfDeliveryAvailable,
      headline: 'Delivery marked complete',
      detail: 'Review the recorded proof if this does not look right.',
      proofReference: 'POD-REF-1001',
    );
    expect(await session.restoreDeliveryException(order.id), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Proof reference · POD-REF-1001'), findsOneWidget);
    final dispute = find.byKey(const ValueKey('buy-delivery-dispute-proof'));
    await tester.ensureVisible(dispute);
    await tester.tap(dispute);
    await tester.pumpAndSettle();
    expect(adapter.disputeCalls, 1);
    expect(find.text('Proof of delivery is under review'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('buy-delivery-exception-proofOfDeliveryDisputed'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'GST profiles restore per account and reject false save success',
    () async {
      final store = _MemoryGstInvoiceProfileStore();
      final first = BuyV2GstInvoiceController(store: store);
      addTearDown(first.dispose);

      expect(
        await first.save(
          destination: BuyV2Destination.wholesale,
          legalName: 'Shree Balaji Retail',
          gstin: '08ABCDE1234F1Z5',
          billingAddress: '12 Market Road, Jodhpur 342003',
          remember: true,
        ),
        isTrue,
      );
      expect(first.savedProfiles, hasLength(1));

      final restored = BuyV2GstInvoiceController(store: store);
      addTearDown(restored.dispose);
      await restored.restore();
      expect(restored.savedProfiles.single.legalName, 'Shree Balaji Retail');
      restored.selectSaved(
        BuyV2Destination.shop,
        restored.savedProfiles.single,
      );

      store.acceptWrites = false;
      expect(
        await restored.save(
          destination: BuyV2Destination.shop,
          legalName: 'Changed before acknowledgement',
          gstin: '08ABCDE1234F1Z5',
          billingAddress: '12 Market Road, Jodhpur 342003',
          remember: true,
        ),
        isFalse,
      );
      expect(
        restored.detailsFor(BuyV2Destination.shop)?.legalName,
        'Shree Balaji Retail',
      );
      expect(restored.message, 'GST details could not be saved. Try again.');

      store.ownerScope = 'account-b';
      final otherAccount = BuyV2GstInvoiceController(store: store);
      addTearDown(otherAccount.dispose);
      await otherAccount.restore();
      expect(otherAccount.savedProfiles, isEmpty);

      store.ownerScope = 'account-a';
      store.acceptWrites = true;
      expect(await restored.removeSaved(restored.savedProfiles.single), isTrue);
      expect(restored.savedProfiles, isEmpty);
      expect(restored.detailsFor(BuyV2Destination.shop), isNull);
    },
  );

  testWidgets('GST save failure keeps entered details and supports retry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = _MemoryGstInvoiceProfileStore()..acceptWrites = false;
    final session = mixedSession(gstInvoiceProfileStore: store);
    addTearDown(session.dispose);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    advanceCheckoutToConfirm(session);

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-gst-request-shop')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-gst-add-shop')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-gst-legal-name')),
      'Shree Balaji Retail',
    );
    await tester.enterText(
      find.byKey(const ValueKey('buy-gst-gstin')),
      '08ABCDE1234F1Z5',
    );
    await tester.enterText(
      find.byKey(const ValueKey('buy-gst-billing-address')),
      '12 Market Road, Jodhpur 342003',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('buy-gst-save')));
    await tester.tap(find.byKey(const ValueKey('buy-gst-save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-gst-invoice-sheet')), findsOneWidget);
    expect(
      find.text('GST details could not be saved. Try again.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('buy-gst-legal-name')))
          .controller
          ?.text,
      'Shree Balaji Retail',
    );

    store.acceptWrites = true;
    await tester.tap(find.byKey(const ValueKey('buy-gst-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-gst-invoice-sheet')), findsNothing);
    expect(find.text('Shree Balaji Retail'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('T01B GST action stays reachable across Android and iOS insets', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const viewports = [
      (
        label: 'Redmi navigation',
        size: Size(360, 800),
        safeArea: EdgeInsets.only(top: 34, bottom: 81),
        viewInsets: EdgeInsets.zero,
        textScale: 1.0,
      ),
      (
        label: 'compact Android keyboard',
        size: Size(320, 568),
        safeArea: EdgeInsets.only(top: 24, bottom: 24),
        viewInsets: EdgeInsets.only(bottom: 260),
        textScale: 1.4,
      ),
      (
        label: 'modern iOS keyboard',
        size: Size(390, 844),
        safeArea: EdgeInsets.only(top: 47, bottom: 34),
        viewInsets: EdgeInsets.only(bottom: 336),
        textScale: 1.2,
      ),
      (
        label: 'compact iOS keyboard',
        size: Size(320, 568),
        safeArea: EdgeInsets.only(top: 20),
        viewInsets: EdgeInsets.only(bottom: 216),
        textScale: 1.0,
      ),
    ];

    for (final viewport in viewports) {
      tester.view.physicalSize = viewport.size;
      tester.view.padding = FakeViewPadding(
        left: viewport.safeArea.left,
        top: viewport.safeArea.top,
        right: viewport.safeArea.right,
        bottom: viewport.safeArea.bottom,
      );
      tester.view.viewPadding = FakeViewPadding(
        left: viewport.safeArea.left,
        top: viewport.safeArea.top,
        right: viewport.safeArea.right,
        bottom: viewport.safeArea.bottom,
      );
      final gstStore = _MemoryGstInvoiceProfileStore();
      final session = mixedSession(gstInvoiceProfileStore: gstStore);
      session.openCart(scope: BuyV2CartScope.wholesale);
      expect(session.openCheckout(), isTrue, reason: viewport.label);
      advanceCheckoutToConfirm(session);

      await tester.pumpWidget(
        app(
          session,
          size: viewport.size,
          safeArea: viewport.safeArea,
          viewInsets: viewport.viewInsets,
          textScale: viewport.textScale,
          reducedMotion: true,
        ),
      );
      await tester.pump();
      final request = find.byKey(const ValueKey('buy-gst-request-wholesale'));
      await tester.ensureVisible(request);
      await tester.pump();
      await tester.tap(request);
      await tester.pumpAndSettle();
      final add = find.byKey(const ValueKey('buy-gst-add-wholesale'));
      await tester.ensureVisible(add);
      await tester.pump();
      await tester.tap(add);
      await tester.pumpAndSettle();

      final save = find.byKey(const ValueKey('buy-gst-save'));
      expect(save, findsOneWidget, reason: viewport.label);
      final saveRect = tester.getRect(save);
      final usableBottom =
          viewport.size.height -
          viewport.safeArea.bottom -
          viewport.viewInsets.bottom;
      expect(
        saveRect.bottom,
        lessThanOrEqualTo(usableBottom + 1),
        reason: '${viewport.label} bottom-safe action',
      );
      expect(
        saveRect.height,
        greaterThanOrEqualTo(44),
        reason: '${viewport.label} action height',
      );
      expect(
        find.byKey(const ValueKey('buy-gst-form-scroll')),
        findsOneWidget,
        reason: viewport.label,
      );

      await tester.enterText(
        find.byKey(const ValueKey('buy-gst-legal-name')),
        'Shree Balaji Retail',
      );
      await tester.enterText(
        find.byKey(const ValueKey('buy-gst-gstin')),
        '08ABCDE1234F1Z5',
      );
      await tester.enterText(
        find.byKey(const ValueKey('buy-gst-billing-address')),
        '12 Market Road, Jodhpur 342003',
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-gst-profile-gst-profile-1')),
        findsOneWidget,
        reason: viewport.label,
      );
      expect(tester.takeException(), isNull, reason: viewport.label);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      session.dispose();
    }
  });

  testWidgets('T01B GST fields are named and follow keyboard order', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    final session = mixedSession();
    addTearDown(session.dispose);
    session.openCart(scope: BuyV2CartScope.wholesale);
    expect(session.openCheckout(), isTrue);
    advanceCheckoutToConfirm(session);

    await tester.pumpWidget(app(session, reducedMotion: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-gst-request-wholesale')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-gst-add-wholesale')));
    await tester.pumpAndSettle();

    for (final target in const [
      (key: 'buy-gst-legal-name', label: 'Legal name'),
      (key: 'buy-gst-gstin', label: 'GSTIN'),
      (key: 'buy-gst-billing-address', label: 'Billing address'),
    ]) {
      final field = find.byKey(ValueKey(target.key));
      expect(field, findsOneWidget, reason: target.label);
      final data = tester.getSemantics(field).getSemanticsData();
      expect(data.label, contains(target.label), reason: target.label);
      expect(data.flagsCollection.isTextField, isTrue, reason: target.label);
      expect(data.hasAction(SemanticsAction.tap), isTrue, reason: target.label);
      expect(
        data.hasAction(SemanticsAction.focus),
        isTrue,
        reason: target.label,
      );
    }
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('buy-gst-gstin')))
          .getSemanticsData()
          .maxValueLength,
      15,
    );

    final legalName = tester.widget<TextField>(
      find.byKey(const ValueKey('buy-gst-legal-name')),
    );
    final gstin = tester.widget<TextField>(
      find.byKey(const ValueKey('buy-gst-gstin')),
    );
    final billingAddress = tester.widget<TextField>(
      find.byKey(const ValueKey('buy-gst-billing-address')),
    );

    await tester.tap(find.byKey(const ValueKey('buy-gst-legal-name')));
    await tester.pump();
    expect(legalName.focusNode!.hasFocus, isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(gstin.focusNode!.hasFocus, isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(billingAddress.focusNode!.hasFocus, isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(billingAddress.focusNode!.hasFocus, isFalse);

    final save = find.bySemanticsLabel('Use GST details');
    expect(save, findsOneWidget);
    final saveData = tester.getSemantics(save).getSemanticsData();
    expect(saveData.flagsCollection.isButton, isTrue);
    expect(saveData.flagsCollection.isEnabled, Tristate.isTrue);
    expect(tester.getSize(save).height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('320px 140% reduced motion keeps one static compact owner', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    final session = mixedSession();
    addTearDown(session.dispose);
    session.openCart(scope: BuyV2CartScope.medicine);
    expect(session.openCheckout(), isTrue);

    await tester.pumpWidget(
      app(
        session,
        size: const Size(320, 568),
        textScale: 1.4,
        reducedMotion: true,
      ),
    );
    await tester.pump();

    final owner = find.byKey(const ValueKey('buy-checkout-return-cart'));
    expect(owner, findsOneWidget);
    final semanticNode = tester.getSemantics(owner);
    expect(
      semanticNode.getSemanticsData().hasAction(SemanticsAction.tap),
      true,
    );
    expect(semanticNode.rect.width, lessThan(150));
    expect(semanticNode.rect.height, greaterThanOrEqualTo(44));
    advanceCheckoutToConfirm(session);
    await tester.pump();
    expect(find.text('Deliveries'), findsOneWidget);
    expect(session.checkoutFulfilmentGroups, hasLength(1));
    expect(
      session.checkoutFulfilmentGroups.single.destination,
      BuyV2Destination.medicine,
    );
    expect(
      find.byKey(
        ValueKey(
          'buy-checkout-confirm-delivery-${session.checkoutFulfilmentGroups.single.key}',
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

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
    testWidgets(
      'R58.8.6 responsive ${viewport.label} candidate capture',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        tester.view.physicalSize = viewport.size;
        final session = mixedSession();
        addTearDown(session.dispose);
        session.openCart(scope: BuyV2CartScope.shop);
        expect(session.openCheckout(), isTrue);

        await tester.pumpWidget(
          app(
            session,
            size: viewport.size,
            textScale: viewport.textScale,
            reducedMotion: viewport.reduced,
            safeArea: viewport.safe,
          ),
        );
        await tester.pumpAndSettle();
        final owner = find.byKey(const ValueKey('buy-checkout-return-cart'));
        expect(owner, findsOneWidget, reason: viewport.label);
        expect(
          tester.getRect(owner).height,
          greaterThanOrEqualTo(44),
          reason: viewport.label,
        );
        expect(tester.takeException(), isNull, reason: viewport.label);
        await expectLater(
          find.byKey(const ValueKey('buy-v2-screen')),
          matchesGoldenFile(
            'candidate_captures/'
            'buy-v2-r58-8-6-c24f-checkout-cart-return-${viewport.label}.png',
          ),
        );
      },
      tags: 'protected-reference',
    );
  }
}
