import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_chat_route_adapter.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

final class _R669PhotoContentAdapter implements BuyV2ProductContentAdapter {
  const _R669PhotoContentAdapter(this.available);
  final bool available;

  @override
  BuyV2ProductContentSnapshot snapshotFor(BuyV2Product product) =>
      BuyV2ProductContentSnapshot(
        productId: product.id,
        state: BuyV2ProductContentState.ready,
        sourceId: 'host-media-fixture',
        media: [
          BuyV2ProductMediaAsset(
            id: '${product.id}-supplied',
            label: 'Supplied SKU photo',
            semanticLabel: 'Fixture supplied SKU photo',
            kind: BuyV2ProductContentMediaKind.asset,
            source: available
                ? BuyV2ProductPackshot.productAtlasPath
                : 'assets/host-fixture-missing-photo.png',
          ),
        ],
      );
}

final class _R669ReviewCommerce implements BuyV2CommerceAdapter {
  bool eligible = false;
  bool reject = false;
  int submissions = 0;
  BuyV2CommerceLoadState state = BuyV2CommerceLoadState.ready;
  Completer<void>? refreshGate;

  @override
  Future<BuyV2CommerceSnapshot> refresh() async {
    await refreshGate?.future;
    return BuyV2CommerceSnapshot(
      state: state,
      products: BuyV2Catalogue.allProducts,
      businessVerified: true,
      businessVerificationState: BuyV2BusinessVerificationState.verified,
      productReportsAvailable: true,
      reviewableProductIds: eligible ? {'s-milk'} : {},
    );
  }

  @override
  Future<BuyV2OrderAlertsResult> loadOrderAlerts() async =>
      const BuyV2OrderAlertsResult(
        available: true,
        enabled: false,
        customerMessage: '',
      );

  @override
  Future<BuyV2MutationResult> submitProductReview({
    required BuyV2Product product,
    required int rating,
    required String comment,
  }) async {
    submissions++;
    return BuyV2MutationResult(
      accepted: !reject,
      customerMessage: reject
          ? 'Review could not be saved. Try again.'
          : 'Review saved.',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected review fixture operation');
}

Future<BuyV2Session> _mountR669Review(
  WidgetTester tester,
  _R669ReviewCommerce adapter, {
  Size size = const Size(320, 711),
  double scale = 1,
  double bottomInset = 34,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = FakeViewPadding(top: 24, bottom: bottomInset);
  tester.view.viewPadding = FakeViewPadding(top: 24, bottom: bottomInset);
  addTearDown(tester.view.reset);
  final core = BuySession();
  final session = BuyV2Session(
    core: core,
    commerceAdapter: adapter,
    reviewDataEnabled: false,
  );
  addTearDown(core.dispose);
  addTearDown(session.dispose);
  await session.restoreCommerce();
  expect(session.addProduct('w-notebook'), isTrue);
  session.toggleSaved('s-milk');
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MoolTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: r66VisualCaptureRoot(child!),
      ),
      home: BuyV2Screen(session: session, productId: 's-milk'),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  await _openR669Review(tester);
  return session;
}

Future<void> _openR669Review(WidgetTester tester) async {
  final action = find.byKey(const ValueKey('buy-review-product-s-milk'));
  await tester.scrollUntilVisible(
    action,
    160,
    scrollable: find
        .descendant(
          of: find.byKey(const PageStorageKey('buy-product-s-milk')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.ensureVisible(action);
  await tester.pumpAndSettle();
  expect(tester.widget<OutlinedButton>(action).onPressed, isNotNull);
  await tester.tap(action);
  await tester.pumpAndSettle();
}

void main() {
  for (final eligible in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('R669 review complete action clears bottom navigation $eligible $scale', (tester) async {
        final adapter = _R669ReviewCommerce()..eligible = eligible;
        await _mountR669Review(tester, adapter, size: const Size(320, 568), scale: scale, bottomInset: 72);
        final action = find.byKey(ValueKey(eligible ? 'buy-submit-review-s-milk' : 'buy-review-check-eligibility'));
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        expect(tester.getRect(action).bottom, lessThanOrEqualTo(496), reason: 'Complete action must clear Android navigation, not only its tap centre.');
        expect(tester.takeException(), isNull);
        await captureR66Visual(tester, 'r669-review-bottom-clearance-$eligible-$scale');
        expect(adapter.submissions, 0);
      });
    }
  }

  testWidgets('R669 review draft survives Android Back and explicit close', (tester) async {
    final adapter = _R669ReviewCommerce()..eligible = true;
    final session = await _mountR669Review(tester, adapter);
    final comment = find.byKey(const ValueKey('buy-review-comment-s-milk'));
    final rating = find.byKey(const ValueKey('buy-review-rating-s-milk-4'));
    await tester.tap(rating);
    await tester.enterText(comment, 'Keep this unsent review.');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-product-review-sheet')), findsNothing);
    expect(adapter.submissions, 0);
    await _openR669Review(tester);
    expect(tester.widget<TextFormField>(comment).controller!.text, 'Keep this unsent review.');
    expect((tester.widget<IconButton>(rating).icon as Icon).icon, Icons.star_rounded);
    await captureR66Visual(tester, 'r669-review-draft-back-restored');
    await tester.tap(find.byKey(const ValueKey('buy-close-product-review')));
    await tester.pumpAndSettle();
    await _openR669Review(tester);
    expect(tester.widget<TextFormField>(comment).controller!.text, 'Keep this unsent review.');
    expect(session.productReviewDraft('s-milk')?.rating, 4);
    expect(adapter.submissions, 0);
    expect(tester.takeException(), isNull);
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  for (final size in [const Size(320, 711), const Size(711, 320)]) {
    for (final scale in [1.0, 2.0]) {
      for (final eligible in [false, true]) {
        final profile = '${size.width.toInt()}-$scale-$eligible';
        testWidgets('R669 review entry is actionable $profile', (tester) async {
          final adapter = _R669ReviewCommerce()..eligible = eligible;
          final session = await _mountR669Review(
            tester,
            adapter,
            size: size,
            scale: scale,
          );
          final quantity = session.quantityFor('w-notebook');
          expect(tester.takeException(), isNull);
          final title = find.descendant(
            of: find.byKey(
              ValueKey(
                eligible
                    ? 'buy-product-review-sheet'
                    : 'buy-product-review-eligibility',
              ),
            ),
            matching: find.text(
              eligible ? 'Write a review' : 'Review your purchase',
            ),
          );
          final heading = tester.renderObject<RenderParagraph>(title);
          expect(heading.didExceedMaxLines, isFalse);
          if (!eligible) {
            expect(
              find.byKey(const ValueKey('buy-product-review-eligibility')),
              findsOneWidget,
            );
            expect(find.textContaining('No eligible purchase'), findsOneWidget);
            expect(
              find.byKey(const ValueKey('buy-product-review-sheet')),
              findsNothing,
            );
            expect(
              await session.submitProductReviewOnline(
                productId: 's-milk',
                rating: 4,
                comment: 'Not eligible',
              ),
              isFalse,
            );
            expect(adapter.submissions, 0);
            final retry = find.byKey(
              const ValueKey('buy-review-check-eligibility'),
            );
            await tester.ensureVisible(retry);
            await tester.pumpAndSettle();
            expect(retry.hitTestable(), findsOneWidget);
            await captureR66Visual(tester, 'r669-review-$profile-eligibility');
            await tester.tap(retry);
            await tester.pumpAndSettle();
            expect(
              find.descendant(
                of: find.byKey(
                  const ValueKey('buy-product-review-eligibility'),
                ),
                matching: find.textContaining('No eligible purchase'),
              ),
              findsOneWidget,
            );
          } else {
            expect(
              find.byKey(const ValueKey('buy-product-review-sheet')),
              findsOneWidget,
            );
            await captureR66Visual(tester, 'r669-review-$profile-editor');
            final rating = find.byKey(
              const ValueKey('buy-review-rating-s-milk-4'),
            );
            await tester.ensureVisible(rating);
            await tester.tap(rating);
            final comment = find.byKey(
              const ValueKey('buy-review-comment-s-milk'),
            );
            await tester.ensureVisible(comment);
            await tester.enterText(
              comment,
              'The pack arrived in good condition.',
            );
            await tester.pumpAndSettle();
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('buy-product-review-sheet')),
              findsOneWidget,
            );
            final save = find.byKey(const ValueKey('buy-submit-review-s-milk'));
            await tester.ensureVisible(save);
            await tester.pumpAndSettle();
            expect(save.hitTestable(), findsOneWidget);
            final cancelText = find.descendant(
              of: find.byKey(const ValueKey('buy-cancel-product-review')),
              matching: find.text('Cancel'),
            );
            final cancelParagraph = tester.renderObject<RenderParagraph>(
              cancelText,
            );
            final cancelNatural = TextPainter(
              text: cancelParagraph.text,
              textDirection: cancelParagraph.textDirection,
              textScaler: cancelParagraph.textScaler,
            )..layout();
            expect(
              cancelParagraph.size.width + .1,
              greaterThanOrEqualTo(cancelNatural.width),
            );
            cancelNatural.dispose();
            await captureR66Visual(tester, 'r669-review-$profile-ready');
            await tester.tap(save);
            await tester.pumpAndSettle();
            expect(adapter.submissions, 1);
            expect(session.customerReviewFor('s-milk')?.rating, 4);
            await _openR669Review(tester);
            expect(
              tester.widget<TextFormField>(comment).controller!.text,
              'The pack arrived in good condition.',
            );
            await tester.enterText(comment, 'Discard this edit.');
            await tester.pumpAndSettle();
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            final cancel = find.byKey(
              const ValueKey('buy-cancel-product-review'),
            );
            await tester.ensureVisible(cancel);
            await tester.tap(cancel);
            await tester.pumpAndSettle();
            expect(adapter.submissions, 1);
            expect(
              session.customerReviewFor('s-milk')?.comment,
              'The pack arrived in good condition.',
            );
          }
          if (!eligible) {
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
          }
          expect(session.selectedProductId, 's-milk');
          expect(session.view, BuyV2View.product);
          expect(session.quantityFor('w-notebook'), quantity);
          expect(session.isSaved('s-milk'), isTrue);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final state in [
    BuyV2CommerceLoadState.offline,
    BuyV2CommerceLoadState.unavailable,
  ]) {
    testWidgets('R669 review retry distinguishes ${state.name} and recovers', (
      tester,
    ) async {
      final adapter = _R669ReviewCommerce();
      final session = await _mountR669Review(tester, adapter);
      adapter.state = state;
      await session.restoreCommerce();
      await tester.pumpAndSettle();
      expect(
        find.text(session.productReviewUnavailableReason('s-milk')!),
        findsOneWidget,
      );
      expect(find.textContaining('No eligible purchase'), findsNothing);
      expect(
        await session.submitProductReviewOnline(
          productId: 's-milk',
          rating: 4,
          comment: 'Unavailable',
        ),
        isFalse,
      );
      expect(adapter.submissions, 0);
      await captureR66Visual(tester, 'r669-review-${state.name}');
      adapter.refreshGate = Completer<void>();
      final retry = find.byKey(const ValueKey('buy-review-check-eligibility'));
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pump();
      expect(find.text('Checking purchase'), findsOneWidget);
      expect(tester.widget<OutlinedButton>(retry).onPressed, isNull);
      adapter.state = BuyV2CommerceLoadState.ready;
      adapter.eligible = true;
      adapter.refreshGate!.complete();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-product-review-sheet')),
        findsOneWidget,
      );
      expect(adapter.submissions, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'R669 review retains draft after eligibility changes and rejected save',
    (tester) async {
      final adapter = _R669ReviewCommerce()..eligible = true;
      final session = await _mountR669Review(tester, adapter);
      final comment = find.byKey(const ValueKey('buy-review-comment-s-milk'));
      await tester.tap(
        find.byKey(const ValueKey('buy-review-rating-s-milk-5')),
      );
      await tester.enterText(comment, 'Keep this draft.');
      adapter.eligible = false;
      await session.restoreCommerce();
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(comment).controller!.text,
        'Keep this draft.',
      );
      final save = find.byKey(const ValueKey('buy-submit-review-s-milk'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(adapter.submissions, 0);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-product-review-sheet')),
          matching: find.textContaining('No eligible purchase'),
        ),
        findsOneWidget,
      );
      adapter.eligible = true;
      adapter.reject = true;
      await session.restoreCommerce();
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(adapter.submissions, 1);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-product-review-sheet')),
          matching: find.text('Review could not be saved. Try again.'),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<TextFormField>(comment).controller!.text,
        'Keep this draft.',
      );
      adapter.reject = false;
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(adapter.submissions, 2);
      expect(session.customerReviewFor('s-milk')?.comment, 'Keep this draft.');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('R669 media complete illustration crops', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(650, 600);
    addTearDown(tester.view.reset);
    final products =
        [
              's-tomato',
              's-rice',
              's-atta',
              's-oil',
              's-soap',
              'w-notebook',
              's-milk',
              's-bread',
              's-water',
            ]
            .map(
              (id) => BuyV2Catalogue.allProducts.firstWhere((p) => p.id == id),
            )
            .toList();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        builder: (context, child) => r66VisualCaptureRoot(child!),
        home: Scaffold(
          body: Wrap(
            children: [
              for (final product in products)
                SizedBox(
                  width: 210,
                  height: 190,
                  child: BuyV2ProductPackshot(product: product),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Illustration'), findsNWidgets(9));
    await captureR66Visual(tester, 'r669-media-complete-crops');
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('R669 media illustration thumbnails preserve ratio at $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(711, 600);
      addTearDown(tester.view.reset);
      final products = ['s-milk', 'w-printer-paper', 's-cumin', 's-carry-bags']
          .map((id) => BuyV2Catalogue.allProducts.firstWhere((p) => p.id == id))
          .toList();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: r66VisualCaptureRoot(child!),
          ),
          home: Scaffold(
            body: Column(
              children: [
                for (final size in [
                  const Size(140, 150),
                  const Size(120, 80),
                  const Size(48, 32),
                ])
                  Row(
                    children: [
                      for (final product in products)
                        SizedBox(
                          width: size.width,
                          height: size.height,
                          child: BuyV2ProductPackshot(product: product),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final product in products) {
        expect(
          find.byKey(ValueKey('buy-product-illustration-${product.id}')),
          findsWidgets,
        );
        expect(
          find.byKey(ValueKey('buy-product-photo-unavailable-${product.id}')),
          findsWidgets,
        );
      }
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        final asset = image.image as AssetImage;
        final size = tester.getSize(find.byWidget(image));
        final expected =
            asset.assetName == BuyV2ProductPackshot.productAtlasPath
            ? 1.5
            : 4 / 3;
        expect(
          size.width / size.height,
          closeTo(expected, .0001),
          reason: 'The decoded atlas must retain its published aspect ratio',
        );
      }
      await captureR66Visual(tester, 'r669-media-thumbnails-$scale');
      expect(tester.takeException(), isNull);
    });
  }

  for (final size in [const Size(320, 711), const Size(711, 320)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'R669 media detail illustrations retain SKU and Back ${size.width}-$scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: MoolTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  padding: const EdgeInsets.only(top: 24, bottom: 34),
                  viewPadding: const EdgeInsets.only(top: 24, bottom: 34),
                  disableAnimations: true,
                ),
                child: r66VisualCaptureRoot(child!),
              ),
              home: BuyV2Screen(session: session),
            ),
          );
          await tester.pumpAndSettle();
          for (final id in [
            'w-printer-paper',
            's-cumin',
            's-carry-bags',
            's-milk',
            's-milk-500ml',
          ]) {
            expect(session.openProduct(id), isTrue);
            await tester.pumpAndSettle();
            final disclosure = find.byKey(
              ValueKey('buy-product-illustration-$id'),
            );
            final scroll = find
                .descendant(
                  of: find.byKey(PageStorageKey('buy-product-$id')),
                  matching: find.byType(Scrollable),
                )
                .first;
            await tester.scrollUntilVisible(
              disclosure,
              100,
              scrollable: scroll,
            );
            await tester.pumpAndSettle();
            expect(disclosure.hitTestable(), findsOneWidget);
            final product = session.product(id);
            expect(
              tester.widget<Text>(disclosure).data,
              id.startsWith('s-milk')
                  ? 'Illustration'
                  : 'Category illustration',
            );
            expect(session.selectedProductId, id);
            expect(session.cartLines, isEmpty);
            final semantics = tester.ensureSemantics();
            await tester.pump();
            expect(
              find.bySemanticsLabel(
                RegExp('Supplier photo of this pack is unavailable'),
              ),
              findsWidgets,
            );
            expect(
              find.bySemanticsLabel('Product photo of ${product.title}'),
              findsNothing,
            );
            semantics.dispose();
            if (id == 'w-printer-paper' || id == 's-cumin') {
              await captureR66Visual(
                tester,
                'r669-media-$id-${size.width.toInt()}-$scale',
              );
              await tester.ensureVisible(
                find.byKey(ValueKey('buy-product-packshot-$id')),
              );
              await tester.pumpAndSettle();
              await captureR66Visual(
                tester,
                'r669-media-$id-${size.width.toInt()}-$scale-gallery',
              );
            }
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.catalogue);
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  for (final available in [true, false]) {
    testWidgets(
      'R669 media supplied photo preferred with honest error $available',
      (tester) async {
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          productContentAdapter: _R669PhotoContentAdapter(available),
        );
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            home: BuyV2Screen(session: session, productId: 's-milk'),
          ),
        );
        await tester.pumpAndSettle();
        final gallery = find.byKey(
          const ValueKey('buy-product-packshot-s-milk'),
        );
        expect(gallery, findsOneWidget);
        expect(
          find.descendant(
            of: gallery,
            matching: find.byType(BuyV2ProductPackshot),
          ),
          findsNothing,
        );
        final semantics = tester.ensureSemantics();
        await tester.pump();
        if (available) {
          expect(
            find.bySemanticsLabel(RegExp('Fixture supplied SKU photo')),
            findsWidgets,
          );
          final image = tester.widget<Image>(
            find.byKey(
              const ValueKey('buy-product-gallery-asset-s-milk-supplied'),
            ),
          );
          expect(image.fit, BoxFit.contain);
        } else {
          expect(find.text('Photo unavailable'), findsOneWidget);
          expect(
            find.bySemanticsLabel(RegExp('Fixture supplied SKU photo')),
            findsNothing,
          );
        }
        semantics.dispose();
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('R669 landscape quantity digits remain visible with keyboard $scale', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(640, 360);
      tester.view.viewPadding = const FakeViewPadding(top: 34, right: 47);
      tester.view.padding = const FakeViewPadding(top: 34, right: 47);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      expect(session.addProduct('w-rice'), isTrue);
      expect(session.setCartQuantity('w-rice', '13'), isTrue);
      await tester.pumpWidget(MaterialApp(
        theme: MoolTheme.light(),
        builder: (context, child) => r66VisualCaptureRoot(child!),
        home: BuyV2Screen(session: session, initialDestination: BuyV2Destination.wholesale,
            initialView: BuyV2View.product, productId: 'w-rice'),
      ));
      await tester.pumpAndSettle();
      final edit = find.byKey(const ValueKey('buy-product-edit-quantity'));
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      final input = find.byKey(const ValueKey('buy-quantity-input'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      await tester.pumpAndSettle();
      await tester.enterText(input, '14');
      await tester.pumpAndSettle();
      final editable = find.descendant(of: input, matching: find.byType(EditableText));
      final render = tester.state<EditableTextState>(editable).renderEditable;
      final caret = render.getLocalRectForCaret(const TextPosition(offset: 1)).shift(render.localToGlobal(Offset.zero));
      final viewport = tester.getRect(find.ancestor(of: input, matching: find.byType(SingleChildScrollView)).first);
      await captureR66Visual(tester, 'r669-quantity-keyboard-digits-$scale');
      expect(caret.top, greaterThanOrEqualTo(viewport.top));
      expect(caret.bottom, lessThanOrEqualTo(viewport.bottom), reason: 'The complete enlarged digit line must fit inside the editor viewport while typing.');
      expect(caret.bottom, lessThanOrEqualTo(160));
      expect(session.quantityFor('w-rice'), 13);
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('buy-quantity-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(session.quantityFor('w-rice'), 14);
      expect(input, findsNothing);
      expect(session.view, BuyV2View.product);
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.0, 2.0]) {
    for (final id in ['s-milk', 'w-notebook']) {
      testWidgets('R669 direct quantity product and Cart $id scale $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 711);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        final product = session.product(id);
        expect(session.addProduct(id), isTrue);
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            builder: (context, child) => r66VisualCaptureRoot(child!),
            home: BuyV2Screen(
              session: session,
              initialDestination: product.destination,
              initialView: BuyV2View.product,
              productId: id,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final edit = find.byKey(const ValueKey('buy-product-edit-quantity'));
        await tester.ensureVisible(edit);
        await tester.pumpAndSettle();
        await tester.tap(edit);
        await tester.pumpAndSettle();
        final input = find.byKey(const ValueKey('buy-quantity-input'));
        final save = find.byKey(const ValueKey('buy-quantity-save'));
        expect(input, findsOneWidget);
        tester.view.viewInsets = const FakeViewPadding(bottom: 240);
        await tester.pumpAndSettle();
        await tester.enterText(input, '0');
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(find.textContaining('Minimum order:'), findsOneWidget);
        expect(session.quantityFor(id), product.minimumOrder);
        await captureR66Visual(
          tester,
          'r669-product-$id-$scale-invalid-quantity',
        );
        await tester.enterText(input, '28736');
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        expect(save.hitTestable(), findsOneWidget);
        final updatePoint = tester.getCenter(save);
        await tester.tapAt(updatePoint);
        await tester.tapAt(updatePoint);
        tester.view.viewInsets = const FakeViewPadding();
        await tester.pumpAndSettle();
        expect(input, findsNothing);
        expect(find.byType(BuyV2Screen), findsOneWidget);
        expect(session.quantityFor(id), 28736);
        expect(session.view, BuyV2View.product);
        expect(tester.takeException(), isNull);
        await captureR66Visual(
          tester,
          'r669-product-$id-$scale-large-quantity',
        );

        session.openCart();
        await tester.pumpAndSettle();
        final cartEdit = find.byKey(ValueKey('buy-cart-edit-quantity-$id'));
        await tester.ensureVisible(cartEdit);
        await tester.pumpAndSettle();
        expect(cartEdit.hitTestable(), findsOneWidget);
        await tester.tap(cartEdit);
        await tester.pumpAndSettle();
        await tester.enterText(input, '1000');
        await tester.ensureVisible(find.text('Cancel'));
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(session.quantityFor(id), 28736);
        await tester.tap(cartEdit);
        await tester.pumpAndSettle();
        await tester.enterText(input, '1000');
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(session.quantityFor(id), 1000);
        expect(session.view, BuyV2View.cart);
        session.goBack();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.product);
        expect(session.selectedProductId, id);
        expect(tester.takeException(), isNull);
      });
    }
  }

  test('product question opens shared Chat with exact product return', () {
    final product = BuyV2Catalogue.allProducts.firstWhere(
      (candidate) => candidate.id == 's-milk-2l',
    );
    final location = const BuyV2ChatRouteAdapter().productQuestionLocationFor(
      product: product,
    );
    final uri = Uri.parse(location);

    expect(uri.path, startsWith('/app/chat/thread/shop-partner-shop-'));
    expect(uri.queryParameters['supplier'], product.seller);
    expect(uri.queryParameters['draft'], contains('Toned fresh milk'));
    expect(uri.queryParameters['draft'], contains('2 × 1 L pouches'));
    expect(uri.queryParameters['directReturn'], 'true');
    final returnUri = Uri.parse(uri.queryParameters['return']!);
    expect(returnUri.path, '/app/buy');
    expect(returnUri.queryParameters['sub'], 'shop');
    expect(returnUri.queryParameters['view'], 'product');
    expect(returnUri.queryParameters['product'], 's-milk-2l');
  });

  test('Cart keeps the exact product origin before checkout', () {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-milk-2l'), isTrue);

    expect(session.addProduct('s-milk-2l'), isTrue);
    expect(session.view, BuyV2View.product);
    expect(session.quantityFor('s-milk-2l'), 1);
    expect(session.quantityFor('s-milk'), 0);

    session.openCart();
    expect(session.view, BuyV2View.cart);
    session.goBack();
    expect(session.view, BuyV2View.product);
    expect(session.destination, BuyV2Destination.shop);
    expect(session.selectedProductId, 's-milk-2l');
  });

  testWidgets('Shop Wholesale and Offers use one Cart-first product action', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    for (final entry
        in <({String productId, BuyV2Destination destination, bool offers})>[
          (
            productId: 's-milk',
            destination: BuyV2Destination.shop,
            offers: false,
          ),
          (
            productId: 'w-onion',
            destination: BuyV2Destination.wholesale,
            offers: false,
          ),
          (
            productId: 's-milk',
            destination: BuyV2Destination.shop,
            offers: true,
          ),
        ]) {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(
            session: session,
            initialDestination: entry.destination,
            initialOffersActive: entry.offers,
            initialView: BuyV2View.product,
            productId: entry.productId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find
          .descendant(
            of: find.byKey(PageStorageKey('buy-product-${entry.productId}')),
            matching: find.byType(Scrollable),
          )
          .first;
      final add = find.byKey(
        ValueKey('buy-product-primary-${entry.productId}'),
      );
      await tester.scrollUntilVisible(add, 220, scrollable: scrollable);
      await tester.pumpAndSettle();

      expect(add, findsOneWidget);
      expect(find.text('Buy now'), findsNothing);
      expect(
        tester
            .getSemantics(add)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      expect(tester.takeException(), isNull, reason: '$entry');

      await tester.pumpWidget(const SizedBox.shrink());
      session.dispose();
      core.dispose();
    }
  });

  testWidgets('product actions fit, compare and retain exact Back at 320', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    var chatOpened = false;
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-milk'), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: BuyV2Destination.shop,
          initialView: BuyV2View.product,
          productId: 's-milk',
          onOpenChat: () => chatOpened = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final productScroll = find
        .descendant(
          of: find.byKey(const PageStorageKey('buy-product-s-milk')),
          matching: find.byType(Scrollable),
        )
        .first;
    final actions = find.byKey(
      const ValueKey('buy-product-quick-actions-s-milk'),
    );
    await tester.scrollUntilVisible(actions, 180, scrollable: productScroll);
    expect(actions, findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-product-action-save-s-milk')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-product-action-share-s-milk')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-product-action-compare-s-milk')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-product-action-ask-seller-s-milk')),
      findsOneWidget,
    );
    for (final label in const ['Save', 'Share', 'Compare', 'Ask seller']) {
      final semanticAction = find.descendant(
        of: actions,
        matching: find.bySemanticsLabel(label),
      );
      expect(semanticAction, findsOneWidget);
      expect(
        tester
            .getSemantics(semanticAction)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
    }

    final save = find.byKey(const ValueKey('buy-product-action-save-s-milk'));
    await tester.ensureVisible(save);
    await tester.drag(productScroll, const Offset(0, -160));
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(session.isSaved('s-milk'), isTrue);
    expect(
      find.byKey(const ValueKey('buy-product-action-saved-s-milk')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('buy-product-action-compare-s-milk')),
    );
    await tester.tap(
      find.byKey(const ValueKey('buy-product-action-compare-s-milk')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Compare prices'), findsOneWidget);
    expect(
      find.text(
        'Prices from other suppliers are unavailable right now. Try again.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-product-compare-s-milk')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('buy-product-compare-s-milk-500ml')),
      findsNothing,
    );
    await tester.tap(find.text('Refresh comparison'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Prices from other suppliers are unavailable right now. Try again.',
      ),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, 's-milk');
    expect(session.isSaved('s-milk'), isTrue);

    await tester.ensureVisible(
      find.byKey(const ValueKey('buy-product-action-ask-seller-s-milk')),
    );
    await tester.tap(
      find.byKey(const ValueKey('buy-product-action-ask-seller-s-milk')),
    );
    await tester.pumpAndSettle();
    expect(chatOpened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'manufacturer Chat action stays readable and fails safely at 140 percent',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final product = BuyV2Catalogue.products.firstWhere(
        (candidate) =>
            candidate.destination == BuyV2Destination.wholesale &&
            candidate.sellerType.toLowerCase().contains('manufacturer'),
      );
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct(product.id), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(
            session: session,
            initialDestination: product.destination,
            initialView: BuyV2View.product,
            productId: product.id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final productScroll = find
          .descendant(
            of: find.byKey(PageStorageKey('buy-product-${product.id}')),
            matching: find.byType(Scrollable),
          )
          .first;
      final actions = find.byKey(
        ValueKey('buy-product-quick-actions-${product.id}'),
      );
      final ask = find.byKey(
        ValueKey('buy-product-action-ask-manufacturer-${product.id}'),
      );
      await tester.scrollUntilVisible(ask, 220, scrollable: productScroll);
      await tester.pumpAndSettle();
      await tester.ensureVisible(ask);
      await tester.pumpAndSettle();

      expect(actions, findsOneWidget);
      expect(tester.getSize(actions).height, greaterThanOrEqualTo(44));
      expect(ask.hitTestable(), findsOneWidget);
      expect(tester.getRect(ask).bottom, lessThanOrEqualTo(700));
      expect(find.bySemanticsLabel('Ask manufacturer'), findsOneWidget);
      await tester.tap(ask);
      await tester.pumpAndSettle();
      expect(
        session.notice,
        'Supplier Chat is unavailable right now. Your product is unchanged.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Cart action remains reachable and Back restores product at 320',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct('s-milk'), isTrue);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          home: BuyV2Screen(
            session: session,
            initialDestination: BuyV2Destination.shop,
            initialView: BuyV2View.product,
            productId: 's-milk',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final productScroll = find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-product-s-milk')),
            matching: find.byType(Scrollable),
          )
          .first;
      final add = find.byKey(const ValueKey('buy-product-primary-s-milk'));
      await tester.dragUntilVisible(add, productScroll, const Offset(0, -220));
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.product);
      expect(session.quantityFor('s-milk'), 1);

      session.openCart();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.product);
      expect(session.selectedProductId, 's-milk');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Wholesale Cart action preserves MOQ and exact product return', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('w-rice-50kg'), isTrue);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: BuyV2Destination.wholesale,
          initialView: BuyV2View.product,
          productId: 'w-rice-50kg',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final add = find.byKey(const ValueKey('buy-product-primary-w-rice-50kg'));
    expect(add, findsOneWidget);
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(session.quantityFor('w-rice-50kg'), 1);

    session.openCart();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, 'w-rice-50kg');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shop seller products open and return to the exact product', (
    tester,
  ) async {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final product = BuyV2Catalogue.products.firstWhere(
      (candidate) =>
          candidate.destination == BuyV2Destination.shop &&
          session.sellerContinuationsFor(candidate).isNotEmpty,
    );
    expect(session.openProduct(product.id), isTrue);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: BuyV2Destination.shop,
          initialView: BuyV2View.product,
          productId: product.id,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final productScroll = find
        .descendant(
          of: find.byKey(PageStorageKey('buy-product-${product.id}')),
          matching: find.byType(Scrollable),
        )
        .first;
    final seller = find.byKey(ValueKey('buy-shop-seller-action-${product.id}'));
    await tester.scrollUntilVisible(seller, 220, scrollable: productScroll);
    await tester.ensureVisible(seller);
    await tester.pumpAndSettle();
    for (var attempt = 0; attempt < 3; attempt += 1) {
      final rect = tester.getRect(seller);
      if (rect.top >= 0 && rect.bottom <= 600) break;
      await tester.drag(productScroll, Offset(0, rect.top < 0 ? 180 : -180));
      await tester.pumpAndSettle();
    }
    expect(tester.getRect(seller).top, greaterThanOrEqualTo(0));
    expect(tester.getRect(seller).bottom, lessThanOrEqualTo(600));
    await tester.tap(seller);
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('buy-shop-seller-sheet-${product.id}')),
      findsOneWidget,
    );
    expect(find.text('Store products'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-horizontal-product-grid')),
      findsOneWidget,
    );
    final continuation = session.sellerContinuationsFor(product).first;
    expect(
      find.byKey(ValueKey('buy-product-${continuation.id}')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, product.id);
    expect(tester.takeException(), isNull);
  });
}
