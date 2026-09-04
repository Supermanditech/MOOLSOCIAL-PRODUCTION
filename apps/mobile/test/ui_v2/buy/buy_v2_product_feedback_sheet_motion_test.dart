import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_product_feedback_sheet_motion.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  BuyV2Product product() => BuyV2Catalogue.products.firstWhere(
    (item) => item.destination == BuyV2Destination.shop,
  );

  Widget app(
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
    EdgeInsets viewInsets = EdgeInsets.zero,
    EdgeInsets viewPadding = EdgeInsets.zero,
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
            viewInsets: viewInsets,
            viewPadding: viewPadding,
          ),
          child: child!,
        );
      },
      home: Scaffold(body: BuyV2ProductView(session: session)),
    );
  }

  Future<void> openProduct(
    WidgetTester tester,
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
    EdgeInsets viewInsets = EdgeInsets.zero,
    EdgeInsets viewPadding = EdgeInsets.zero,
  }) async {
    session.openProduct(product().id);
    await tester.pumpWidget(
      app(
        session,
        disableAnimations: disableAnimations,
        textScale: textScale,
        viewInsets: viewInsets,
        viewPadding: viewPadding,
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('buy-product-reviews-${product().id}')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> openReview(
    WidgetTester tester,
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
    EdgeInsets viewInsets = EdgeInsets.zero,
    EdgeInsets viewPadding = EdgeInsets.zero,
    bool settle = true,
  }) async {
    await openProduct(
      tester,
      session,
      disableAnimations: disableAnimations,
      textScale: textScale,
      viewInsets: viewInsets,
      viewPadding: viewPadding,
    );
    await tester.tap(
      find.byKey(ValueKey('buy-review-product-${product().id}')),
    );
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
  }

  Future<void> openReport(
    WidgetTester tester,
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
    EdgeInsets viewInsets = EdgeInsets.zero,
    EdgeInsets viewPadding = EdgeInsets.zero,
    bool settle = true,
  }) async {
    await openProduct(
      tester,
      session,
      disableAnimations: disableAnimations,
      textScale: textScale,
      viewInsets: viewInsets,
      viewPadding: viewPadding,
    );
    await tester.tap(
      find.byKey(ValueKey('buy-report-product-${product().id}')),
    );
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
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
    'review arrival/reverse is finite and invalid dismissal is inert',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);

      await openReview(tester, session, settle: false);
      final sheet = find.byKey(const ValueKey('buy-product-review-sheet'));
      expect(sheet, findsOneWidget);
      final submit = find.byKey(ValueKey('buy-submit-review-${product().id}'));
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      expect(
        find.text('Choose a rating and write a review to enable Save.'),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 140));
      final midArrivalTop = tester.getTopLeft(sheet).dy;
      await tester.pump(const Duration(milliseconds: 140));
      await tester.pump();
      final settledTop = tester.getTopLeft(sheet).dy;
      expect((settledTop - midArrivalTop).abs(), lessThan(40));

      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 219));
      expect(sheet, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(session.customerReviewFor(product().id), isNull);
    },
  );

  testWidgets(
    'review keyboard Back is focus-first and valid submit mutates once',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      final comment = find.byKey(
        ValueKey('buy-review-comment-${product().id}'),
      );

      await openReview(tester, session);
      await tester.tap(comment);
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);
      final semanticField = find.bySemanticsLabel('Your review');
      expect(semanticField, findsOneWidget);
      final semanticData = tester
          .getSemantics(semanticField)
          .getSemanticsData();
      expect(semanticData.flagsCollection.isTextField, isTrue);
      expect(semanticData.hasAction(SemanticsAction.focus), isTrue);
      expect(semanticData.hasAction(SemanticsAction.tap), isTrue);
      expect(semanticData.hasAction(SemanticsAction.setText), isTrue);
      expect(semanticData.maxValueLength, 500);
      expect(find.byTooltip('1 star'), findsOneWidget);
      expect(find.byTooltip('2 stars'), findsOneWidget);
      await tester.enterText(comment, 'Fresh sealed pack and clear details.');
      await tester.tap(
        find.byKey(ValueKey('buy-review-rating-${product().id}-4')),
      );
      await tester.pumpAndSettle();
      final submit = find.byKey(ValueKey('buy-submit-review-${product().id}'));
      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
      expect(find.text('Ready to save to this product.'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-product-review-sheet')), findsOne);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(session.customerReviewFor(product().id), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-product-review-sheet')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(ValueKey('buy-review-product-${product().id}')),
      );
      await tester.pumpAndSettle();
      final reopenedComment = find.byKey(
        ValueKey('buy-review-comment-${product().id}'),
      );
      await tester.enterText(
        reopenedComment,
        'Fresh sealed pack and clear details.',
      );
      await tester.tap(
        find.byKey(ValueKey('buy-review-rating-${product().id}-4')),
      );
      await tester.pumpAndSettle();
      final reopenedSubmit = find.byKey(
        ValueKey('buy-submit-review-${product().id}'),
      );
      await tester.ensureVisible(reopenedSubmit);
      await tester.tap(reopenedSubmit);
      await tester.pumpAndSettle();
      final review = session.customerReviewFor(product().id);
      expect(review?.rating, 4);
      expect(review?.comment, 'Fresh sealed pack and clear details.');
      expect(session.notice, 'Your review was added.');
    },
  );

  testWidgets(
    'report choice owns availability and sends one truthful mutation',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);

      await openReport(tester, session);
      final submit = find.byKey(ValueKey('buy-submit-report-${product().id}'));
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      expect(find.text('Choose one reason to enable Send.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('buy-close-product-report')));
      await tester.pumpAndSettle();
      expect(session.hasReportedProduct(product().id), isFalse);

      await tester.tap(
        find.byKey(ValueKey('buy-report-product-${product().id}')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-report-reason-0')));
      await tester.pumpAndSettle();
      final enabledSubmit = find.byKey(
        ValueKey('buy-submit-report-${product().id}'),
      );
      expect(tester.widget<FilledButton>(enabledSubmit).onPressed, isNotNull);
      expect(find.text('Ready to send this listing issue.'), findsOneWidget);
      await tester.ensureVisible(enabledSubmit);
      await tester.tap(enabledSubmit);
      await tester.pumpAndSettle();
      expect(session.hasReportedProduct(product().id), isTrue);
      expect(
        session.notice,
        'Report received. We will review these product details.',
      );
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('buy-product-reviews-${product().id}')),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Reported'), findsOneWidget);
    },
  );

  testWidgets('compact 140% review form keeps keyboard actions and semantics', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);

    await openReview(
      tester,
      session,
      textScale: 1.4,
      viewInsets: const EdgeInsets.only(bottom: 260),
    );
    final sheet = find.byKey(const ValueKey('buy-product-review-sheet'));
    expect(sheet, findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Review .+ form$')), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-close-product-review')), findsOne);
    final submit = find.byKey(ValueKey('buy-submit-review-${product().id}'));
    await tester.ensureVisible(submit);
    expect(submit, findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('compact 140% report form keeps choices actions and semantics', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);

    await openReport(tester, session, textScale: 1.4);
    final sheet = find.byKey(const ValueKey('buy-product-report-sheet'));
    expect(sheet, findsOneWidget);
    expect(
      find.bySemanticsLabel('Report a product issue form'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('buy-close-product-report')), findsOne);
    expect(find.byKey(const ValueKey('buy-report-reason-0')), findsOne);
    final submit = find.byKey(ValueKey('buy-submit-report-${product().id}'));
    await tester.ensureVisible(submit);
    expect(submit, findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'review exports both actions before interaction above Android navigation',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      const system = EdgeInsets.only(top: 41, bottom: 44);

      await openReview(tester, session, viewPadding: system);

      final cancel = find.byKey(const ValueKey('buy-cancel-product-review'));
      final submit = find.byKey(ValueKey('buy-submit-review-${product().id}'));
      expect(cancel, findsOneWidget);
      expect(submit, findsOneWidget);
      expect(tester.getRect(cancel).height, greaterThanOrEqualTo(44));
      expect(tester.getRect(submit).height, greaterThanOrEqualTo(44));
      expect(tester.getRect(cancel).bottom, lessThanOrEqualTo(800 - 44));
      expect(tester.getRect(submit).bottom, lessThanOrEqualTo(800 - 44));
      debugDefaultTargetPlatformOverride = null;
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'report exports both actions before selection above Android navigation',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      const system = EdgeInsets.only(top: 41, bottom: 44);

      await openReport(tester, session, viewPadding: system);

      final cancel = find.byKey(const ValueKey('buy-cancel-product-report'));
      final submit = find.byKey(ValueKey('buy-submit-report-${product().id}'));
      expect(cancel, findsOneWidget);
      expect(submit, findsOneWidget);
      expect(tester.getRect(cancel).height, greaterThanOrEqualTo(44));
      expect(tester.getRect(submit).height, greaterThanOrEqualTo(44));
      expect(tester.getRect(cancel).bottom, lessThanOrEqualTo(800 - 44));
      expect(tester.getRect(submit).bottom, lessThanOrEqualTo(800 - 44));
      debugDefaultTargetPlatformOverride = null;
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'review keyboard keeps composer and final actions above the Android boundary',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      const keyboard = EdgeInsets.only(bottom: 300);
      const system = EdgeInsets.only(top: 41, bottom: 44);

      await openReview(
        tester,
        session,
        viewInsets: keyboard,
        viewPadding: system,
      );
      final comment = find.byKey(
        ValueKey('buy-review-comment-${product().id}'),
      );
      await tester.tap(comment);
      await tester.enterText(
        comment,
        'Fresh sealed pack.\nDelivery matched the promise.',
      );
      await tester.tap(
        find.byKey(ValueKey('buy-review-rating-${product().id}-5')),
      );
      await tester.pumpAndSettle();
      final submit = find.byKey(ValueKey('buy-submit-review-${product().id}'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      final keyboardTop = 800 - keyboard.bottom;
      expect(tester.getRect(comment).bottom, lessThanOrEqualTo(keyboardTop));
      expect(tester.getRect(submit).height, greaterThanOrEqualTo(44));
      expect(tester.getRect(submit).bottom, lessThanOrEqualTo(keyboardTop));
      expect(
        find.byKey(ValueKey('buy-feedback-product-${product().id}')),
        findsOneWidget,
      );
      debugDefaultTargetPlatformOverride = null;
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Shop and Wholesale reports retain exact product identity above navigation',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final productId in const ['s-eggs', 'w-eggs']) {
        final session = BuyV2Session(core: BuySession());
        expect(session.openProduct(productId), isTrue);
        await tester.pumpWidget(
          app(session, viewPadding: const EdgeInsets.only(top: 41, bottom: 44)),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('buy-product-reviews-$productId')),
          240,
          scrollable: find.byType(Scrollable).first,
        );
        final reportAction = find.byKey(
          ValueKey('buy-report-product-$productId'),
        );
        await tester.ensureVisible(reportAction);
        await tester.pumpAndSettle();
        await tester.tap(reportAction);
        await tester.pumpAndSettle();

        expect(
          find.byKey(ValueKey('buy-feedback-product-$productId')),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey('buy-submit-report-$productId')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('buy-report-reason-0')));
        await tester.pumpAndSettle();
        final submit = find.byKey(ValueKey('buy-submit-report-$productId'));
        await tester.ensureVisible(submit);
        final rect = tester.getRect(submit);
        expect(rect.height, greaterThanOrEqualTo(44));
        expect(rect.bottom, lessThanOrEqualTo(800 - 41));
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(session.hasReportedProduct(productId), isTrue);
        session.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
      debugDefaultTargetPlatformOverride = null;
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion is immediate for both R56.5 routes', (
    tester,
  ) async {
    final reviewSession = BuyV2Session(core: BuySession());
    addTearDown(reviewSession.dispose);
    await openReview(
      tester,
      reviewSession,
      disableAnimations: true,
      settle: false,
    );
    final reviewSheet = find.byKey(const ValueKey('buy-product-review-sheet'));
    final reviewTop = tester.getTopLeft(reviewSheet).dy;
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getTopLeft(reviewSheet).dy, reviewTop);
    await tester.tap(find.byKey(const ValueKey('buy-close-product-review')));
    await tester.pump();
    expect(reviewSheet, findsNothing);

    final reportSession = BuyV2Session(core: BuySession());
    addTearDown(reportSession.dispose);
    await openReport(
      tester,
      reportSession,
      disableAnimations: true,
      settle: false,
    );
    final reportSheet = find.byKey(const ValueKey('buy-product-report-sheet'));
    final reportTop = tester.getTopLeft(reportSheet).dy;
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getTopLeft(reportSheet).dy, reportTop);
  });

  testWidgets('R56.5 responsive evidence captures', (tester) async {
    const cases = [
      (
        Size(320, 700),
        1.4,
        false,
        EdgeInsets.zero,
        'review-compact-320x700-text140',
      ),
      (Size(360, 800), 1.0, false, EdgeInsets.zero, 'review-android-360x800'),
      (Size(390, 844), 1.0, false, EdgeInsets.zero, 'review-ios-390x844'),
      (
        Size(390, 844),
        1.0,
        true,
        EdgeInsets.zero,
        'review-reduced-ios-390x844',
      ),
      (
        Size(360, 800),
        1.0,
        false,
        EdgeInsets.only(bottom: 300),
        'review-android-360x800-keyboard',
      ),
    ];
    for (final capture in cases) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = capture.$1;
      final session = BuyV2Session(core: BuySession());
      await openReview(
        tester,
        session,
        disableAnimations: capture.$3,
        textScale: capture.$2,
        viewInsets: capture.$4,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('candidate_captures/buy-v2-r56-5-${capture.$5}.png'),
      );
      session.dispose();
    }
    const reportCases = [
      (Size(320, 700), 1.4, false, 'report-compact-320x700-text140'),
      (Size(360, 800), 1.0, false, 'report-android-360x800'),
      (Size(390, 844), 1.0, true, 'report-reduced-ios-390x844'),
    ];
    for (final capture in reportCases) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = capture.$1;
      final session = BuyV2Session(core: BuySession());
      await openReport(
        tester,
        session,
        disableAnimations: capture.$3,
        textScale: capture.$2,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('candidate_captures/buy-v2-r56-5-${capture.$4}.png'),
      );
      session.dispose();
    }
    tester.view.reset();
  }, skip: true);
}
