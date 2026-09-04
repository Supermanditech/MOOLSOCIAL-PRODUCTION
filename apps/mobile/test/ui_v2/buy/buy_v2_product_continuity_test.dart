import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
  }) {
    return MaterialApp(
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
      home: BuyV2Screen(session: session),
    );
  }

  Future<void> openFirstProduct(
    WidgetTester tester,
    BuyV2Session session, {
    bool disableAnimations = false,
  }) async {
    await tester.pumpWidget(app(session, disableAnimations: disableAnimations));
    await tester.pumpAndSettle();
    session.openProduct(session.visibleProducts.first.id);
    await tester.pumpAndSettle();
  }

  Future<void> pinchOpen(WidgetTester tester, Finder zoomOwner) async {
    final center = tester.getCenter(zoomOwner);
    final left = await tester.startGesture(center - const Offset(24, 0));
    final right = await tester.startGesture(center + const Offset(24, 0));
    await tester.pump();
    await left.moveTo(center - const Offset(72, 0));
    await right.moveTo(center + const Offset(72, 0));
    await tester.pump();
    await left.up();
    await right.up();
    await tester.pump();
  }

  testWidgets('detail media zoom is explicit, bounded and resettable', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await openFirstProduct(tester, session);
    final product = session.selectedProduct!;
    final zoom = find.byKey(ValueKey('buy-product-media-zoom-${product.id}'));
    final reset = find.byKey(ValueKey('buy-product-media-reset-${product.id}'));

    expect(zoom, findsOneWidget);
    expect(reset, findsNothing);
    expect(
      find.byKey(const ValueKey('buy-product-gallery-count')),
      findsNothing,
    );

    await pinchOpen(tester, zoom);

    expect(reset, findsOneWidget);
    final viewer = tester.widget<InteractiveViewer>(zoom);
    expect(viewer.minScale, 1);
    expect(viewer.maxScale, 2.5);
    expect(viewer.panEnabled, isTrue);
    expect(session.selectedProduct, product);
    expect(session.cartLines, isEmpty);

    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(reset, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one-finger drag at 1x remains owned by product page scroll', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await openFirstProduct(tester, session);
    final product = session.selectedProduct!;
    final zoom = find.byKey(ValueKey('buy-product-media-zoom-${product.id}'));
    final reset = find.byKey(ValueKey('buy-product-media-reset-${product.id}'));
    final before = tester.getTopLeft(zoom).dy;

    await tester.drag(zoom, const Offset(0, -180));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(zoom).dy, lessThan(before));
    expect(reset, findsNothing);
    expect(session.selectedProduct, product);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion resets zoom immediately without route change', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await openFirstProduct(tester, session, disableAnimations: true);
    final product = session.selectedProduct!;
    final zoom = find.byKey(ValueKey('buy-product-media-zoom-${product.id}'));
    final reset = find.byKey(ValueKey('buy-product-media-reset-${product.id}'));

    await pinchOpen(tester, zoom);
    expect(reset, findsOneWidget);
    await tester.tap(reset);
    await tester.pumpAndSettle();

    expect(reset, findsNothing);
    expect(session.selectedProduct, product);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('decoded-frame fade is scoped to the truthful detail packshot', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await openFirstProduct(tester, session);
    final product = session.selectedProduct!;
    final packshot = find.byKey(ValueKey('buy-product-packshot-${product.id}'));
    final images = tester.widgetList<Image>(
      find.descendant(of: packshot, matching: find.byType(Image)),
    );

    expect(images, isNotEmpty);
    final image = images.single;
    final frameBuilder = image.frameBuilder;
    expect(frameBuilder, isNotNull);
    final imageContext = tester.element(
      find.descendant(of: packshot, matching: find.byType(Image)).first,
    );
    final pending =
        frameBuilder!(
              imageContext,
              const SizedBox(key: ValueKey('decoded-child')),
              null,
              false,
            )
            as AnimatedOpacity;
    final decoded =
        frameBuilder(
              imageContext,
              const SizedBox(key: ValueKey('decoded-child')),
              0,
              false,
            )
            as AnimatedOpacity;
    expect(pending.opacity, 0);
    expect(decoded.opacity, 1);
    expect(decoded.duration, const Duration(milliseconds: 180));
    expect(
      find.byKey(ValueKey('buy-packshot-decoded-frame-${product.id}')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('product detail continues directly through genuine products', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    session.updateQuery('tomato');
    final origin = session.visibleProducts.first;
    await tester.pumpWidget(app(session));
    session.openProduct(origin.id);
    await tester.pumpAndSettle();

    final firstNext = session.productContinuationsFor(origin).first;
    final firstSection = find.byKey(
      ValueKey('buy-product-continuations-${origin.id}'),
    );
    final firstCard = find.byKey(
      ValueKey('buy-product-continuation-${firstNext.id}'),
    );
    await tester.scrollUntilVisible(
      find.text('You may also like'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(
        ValueKey('buy-product-continuation-${firstNext.id}'),
        skipOffstage: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(firstSection, findsOneWidget);
    expect(find.text('You may also like'), findsOneWidget);
    expect(find.text('More products selected for you'), findsOneWidget);
    expect(
      find.byKey(ValueKey('buy-product-continuation-${origin.id}')),
      findsNothing,
    );
    final firstCardSemantics = tester
        .getSemantics(firstCard)
        .getSemanticsData();
    expect(firstCardSemantics.label, 'View ${firstNext.title} product details');
    expect(firstCardSemantics.hasAction(SemanticsAction.tap), isTrue);

    await tester.tap(firstCard);
    await tester.pumpAndSettle();
    expect(session.selectedProductId, firstNext.id);
    expect(session.view, BuyV2View.product);

    final secondNext = session.productContinuationsFor(firstNext).first;
    final secondSection = find.byKey(
      ValueKey('buy-product-continuations-${firstNext.id}'),
    );
    final secondCard = find.byKey(
      ValueKey('buy-product-continuation-${secondNext.id}'),
    );
    await tester.scrollUntilVisible(
      find.text('You may also like'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(
        ValueKey('buy-product-continuation-${secondNext.id}'),
        skipOffstage: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(secondSection, findsOneWidget);
    await tester.tap(secondCard);
    await tester.pumpAndSettle();

    expect(session.selectedProductId, secondNext.id);
    session.closeProduct();
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.shop);
    expect(session.view, BuyV2View.catalogue);
    expect(session.query, 'tomato');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Medicine continuation is isolated and not medical advice', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openDestination(BuyV2Destination.medicine);
    session.openProduct(session.visibleProducts.first.id);
    await tester.pumpAndSettle();
    final product = session.selectedProduct!;
    final section = find.byKey(
      ValueKey('buy-product-continuations-${product.id}'),
    );
    await tester.scrollUntilVisible(
      find.text('More Medicine essentials'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(section, findsOneWidget);

    expect(find.text('More Medicine essentials'), findsOneWidget);
    expect(
      find.text('From the Medicine catalogue · not medical advice'),
      findsOneWidget,
    );
    expect(
      session.productContinuationsFor(product),
      everyElement(
        predicate<BuyV2Product>(
          (candidate) =>
              candidate.destination == BuyV2Destination.medicine &&
              candidate.id != product.id,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wholesale continuation uses only current trade-pack products', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openDestination(BuyV2Destination.wholesale);
    session.openProduct(session.visibleProducts.first.id);
    await tester.pumpAndSettle();
    final product = session.selectedProduct!;
    await tester.scrollUntilVisible(
      find.text('More for business restocking'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('More for business restocking'), findsOneWidget);
    expect(find.text('Trade packs for your next order'), findsOneWidget);
    expect(
      session.productContinuationsFor(product),
      everyElement(
        predicate<BuyV2Product>(
          (candidate) =>
              candidate.destination == BuyV2Destination.wholesale &&
              candidate.id != product.id,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('continuation is static with reduced motion at 320px and 140%', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(
      app(session, disableAnimations: true, textScale: 1.4),
    );
    session.openProduct(session.visibleProducts.first.id);
    await tester.pumpAndSettle();
    final product = session.selectedProduct!;
    final section = find.byKey(
      ValueKey('buy-product-continuations-${product.id}'),
    );
    await tester.scrollUntilVisible(
      find.text('You may also like'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(section, findsOneWidget);
    final lane = find.byKey(
      ValueKey('buy-product-continuation-lane-${product.id}'),
    );
    expect(lane, findsOneWidget);
    expect(tester.getSize(lane).width, lessThanOrEqualTo(282));
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
