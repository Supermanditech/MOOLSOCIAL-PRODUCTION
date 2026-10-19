import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_product_feedback_sheet_motion.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';
import '../../work_order_identity_gateway_test.dart' as fixtures;

// Isolated host account/order/storage fixtures, never native evaluation data.
// Founder superseded the public-SKU written-review/report composer: entry now
// belongs to an exact purchased item after authoritative completion.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(BuyV2Session, fixtures.Transport, fixtures.StarsStateStore)>
  openRating(
    WidgetTester tester, {
    double scale = 1,
    bool reduced = false,
    bool settle = true,
    Size size = const Size(360, 800),
    Object? Function()? lifetime,
    fixtures.StarsStateStore? storage,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (session, wire, store) = await fixtures.starsSession(
      storage: storage,
      lifetime: lifetime,
    );
    // Settle the real unavailable commerce adapter, not an invented ready order.
    await session.restoreCommerce();
    fixtures.connectPurchaseFixture(wire, () => true);
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduced,
            textScaler: TextScaler.linear(scale),
            viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: BuyV2OrdersView(session: session, onOpenOrderHelp: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final target = fixtures.feedbackTargetPage()['targets'][0];
    await tester.tap(find.text('Saved purchase details'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('original-order-${target['orderId']}')),
    );
    await tester.pumpAndSettle();
    final update = find.text('Check order update');
    await tester.ensureVisible(update);
    await tester.tap(update);
    await tester.pumpAndSettle();
    final entry = find.byKey(
      ValueKey(
        'purchase-rate-item-${target['orderId']}-${target['orderLineId']}',
      ),
    );
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    await tester.tap(entry);
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
    return (session, wire, store);
  }

  Future<void> selectStar(WidgetTester tester, int stars) async {
    final target = fixtures.feedbackTargetPage()['targets'][0];
    final star = find.byKey(
      ValueKey('buy-private-star-${target['id']}-$stars'),
    );
    await tester.ensureVisible(star);
    await tester.pumpAndSettle();
    await tester.tap(star);
    await tester.pumpAndSettle();
  }

  testWidgets('R56.5 policy is bounded and reduced motion resolves static', (
    tester,
  ) async {
    late AnimationStyle normal;
    late AnimationStyle reduced;
    late Duration normalInset;
    late Duration reducedInset;
    late Duration normalState;
    late Duration reducedState;
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            MediaQuery(
              data: const MediaQueryData(),
              child: Builder(
                builder: (context) {
                  normal = BuyV2ProductFeedbackSheetMotion.resolve(context);
                  normalInset =
                      BuyV2ProductFeedbackSheetMotion.resolveKeyboardInsetDuration(
                        context,
                      );
                  normalState =
                      BuyV2ProductFeedbackSheetMotion.resolveFormStateDuration(
                        context,
                      );
                  return const SizedBox.shrink();
                },
              ),
            ),
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  reduced = BuyV2ProductFeedbackSheetMotion.resolve(context);
                  reducedInset =
                      BuyV2ProductFeedbackSheetMotion.resolveKeyboardInsetDuration(
                        context,
                      );
                  reducedState =
                      BuyV2ProductFeedbackSheetMotion.resolveFormStateDuration(
                        context,
                      );
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );

    expect(normal.duration, BuyV2ProductFeedbackSheetMotion.forwardDuration);
    expect(
      normal.reverseDuration,
      BuyV2ProductFeedbackSheetMotion.reverseDuration,
    );
    expect(normal.curve, Curves.easeOutBack);
    expect(normal.reverseCurve, Curves.easeInCubic);
    expect(normalInset, BuyV2ProductFeedbackSheetMotion.keyboardInsetDuration);
    expect(normalState, BuyV2ProductFeedbackSheetMotion.formStateDuration);
    expect(reduced.duration, Duration.zero);
    expect(reduced.reverseDuration, Duration.zero);
    expect(reduced.curve, Curves.linear);
    expect(reduced.reverseCurve, Curves.linear);
    expect(reducedInset, Duration.zero);
    expect(reducedState, Duration.zero);
  });

  testWidgets(
    'completed-purchase sheet has finite arrival and reverse; dismissal sends nothing',
    (tester) async {
      final (_, wire, _) = await openRating(tester, settle: false);
      final sheet = find.byKey(const ValueKey('buy-product-review-sheet'));
      expect(sheet, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 280));
      await tester.pumpAndSettle();
      final settled = tester.getTopLeft(sheet).dy;
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getTopLeft(sheet).dy, settled);
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 219));
      expect(sheet, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(
        wire.requests.where((r) => r['operation'] == 'submitBuyerProductStars'),
        isEmpty,
      );
    },
  );

  testWidgets(
    'completed-purchase reduced motion resolves immediate entry and exit',
    (tester) async {
      await openRating(tester, reduced: true, settle: false);
      final sheet = find.byKey(const ValueKey('buy-product-review-sheet'));
      final top = tester.getTopLeft(sheet).dy;
      await tester.pumpAndSettle();
      final settled = tester.getTopLeft(sheet).dy;
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getTopLeft(sheet).dy, settled);
      expect(top, isNonNegative);
      await tester.tap(find.byKey(const ValueKey('buy-close-product-review')));
      await tester.pump();
      expect(sheet, findsNothing);
    },
  );

  for (final (size, scale) in const [
    (Size(320, 700), 1.0),
    (Size(320, 700), 1.4),
    (Size(320, 700), 2.0),
    (Size(640, 360), 1.4),
  ]) {
    testWidgets(
      'purchased-item stars are readable and actionable at $size text $scale',
      (tester) async {
        final (_, wire, _) = await openRating(tester, size: size, scale: scale);
        final semantics = tester.ensureSemantics();
        try {
          expect(find.text('Rate your purchase'), findsOneWidget);
          expect(
            find.text('Choose 1–5 stars. Only this Store can see your rating.'),
            findsOneWidget,
          );
          expect(find.byType(TextFormField), findsNothing);
          for (var i = 1; i <= 5; i++) {
            final star = find.byTooltip('$i ${i == 1 ? 'star' : 'stars'}');
            await tester.ensureVisible(star);
            await tester.pumpAndSettle();
            expect(tester.getSize(star).height, greaterThanOrEqualTo(48));
            expect(star.hitTestable(), findsOneWidget);
          }
          await selectStar(tester, 1);
          final submit = find.byKey(const ValueKey('buy-submit-private-stars'));
          await tester.ensureVisible(submit);
          await tester.pumpAndSettle();
          expect(tester.getSize(submit).height, greaterThanOrEqualTo(48));
          expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
          expect(submit.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
          expect(
            wire.requests.where(
              (r) => r['operation'] == 'submitBuyerProductStars',
            ),
            isEmpty,
          );
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  testWidgets(
    'stars-only submit preserves legacy text and sends one exact purchase rating',
    (tester) async {
      final storage = fixtures.StarsStateStore()
        ..saved = const BuyV2CustomerStateSnapshot(
          reviewDrafts: {
            'legacy-written': BuyV2ProductReviewDraft(
              rating: 2,
              comment: 'Keep without publishing',
            ),
          },
        );
      final (_, wire, store) = await openRating(tester, storage: storage);
      await selectStar(tester, 1);
      final submit = find.byKey(const ValueKey('buy-submit-private-stars'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      final calls = wire.requests
          .where((r) => r['operation'] == 'submitBuyerProductStars')
          .toList();
      expect(calls, hasLength(1));
      expect(calls.single['stars'], 1);
      expect(calls.single.containsKey('comment'), isFalse);
      expect(
        store.saved!.reviewDrafts['legacy-written']!.comment,
        'Keep without publishing',
      );
      expect(store.saved!.productStarAttempts, isEmpty);
      expect(find.byType(TextFormField), findsNothing);
    },
  );

  testWidgets(
    'unconfirmed rating locks editing and checks only the original request',
    (tester) async {
      final (session, wire, _) = await openRating(tester);
      final respond = wire.respond!;
      wire.respond = (body) => body['operation'] == 'submitBuyerProductStars'
          ? throw StateError('lost host reply')
          : respond(body);
      await selectStar(tester, 2);
      final submit = find.byKey(const ValueKey('buy-submit-private-stars'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      final target = fixtures.feedbackTargetPage()['targets'][0],
          original = wire.requests.last;
      expect(session.privateStarAttempt(target['id'])!.stars, 2);
      final check = find.text('Check original save');
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(wire.requests.last['operation'], 'reconcileBuyerProductStars');
      expect(wire.requests.last['operationId'], original['operationId']);
      expect(wire.requests.last['stars'], 2);
      expect(session.canSavePrivateStars(target['id']), isFalse);
      expect(
        wire.requests.where((r) => r['operation'] == 'submitBuyerProductStars'),
        hasLength(1),
      );
    },
  );

  testWidgets(
    'a retained Send callback cannot rate after the original account is retired',
    (tester) async {
      Object? life = 'first';
      final (_, wire, _) = await openRating(tester, lifetime: () => life);
      await selectStar(tester, 5);
      final submit = find.byKey(const ValueKey('buy-submit-private-stars'));
      final oldCallback = tester.widget<FilledButton>(submit).onPressed!;
      life = 'retired';
      oldCallback();
      await tester.pumpAndSettle();
      expect(
        wire.requests.where((r) => r['operation'] == 'submitBuyerProductStars'),
        isEmpty,
      );
    },
  );

  for (final id in const ['s-eggs', 'w-eggs']) {
    testWidgets(
      'public SKU $id has no post-purchase rating or issue composer',
      (tester) async {
        final core = BuySession(), session = BuyV2Session(core: core);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        expect(session.openProduct(id), isTrue);
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            home: Scaffold(body: BuyV2ProductView(session: session)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('buy-review-product-$id')), findsNothing);
        expect(find.byKey(ValueKey('buy-report-product-$id')), findsNothing);
        expect(find.byKey(ValueKey('buy-product-reviews-$id')), findsNothing);
        expect(
          find.byKey(const ValueKey('buy-product-review-sheet')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
