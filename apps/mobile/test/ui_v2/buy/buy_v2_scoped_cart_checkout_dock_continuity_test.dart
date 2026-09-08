import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

class _R5DockArrivalSound implements BuyV2DeliveryArrivalSound {
  @override
  Future<bool> prepare() async => true;

  @override
  Future<bool> play() async => true;

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _R66StoreStatusSession extends BuyV2Session {
  _R66StoreStatusSession({required super.core, required this.quiet}) {
    order = visibleOrders.firstWhere(
      (value) =>
          value.destination ==
          (quiet ? BuyV2Destination.wholesale : BuyV2Destination.shop),
    );
  }

  final bool quiet;
  late final BuyV2Order order;

  @override
  BuyV2Order? get activeQuickDeliveryOrder => quiet ? null : order;

  @override
  BuyV2Order? get activeQuietDeliveryOrder => quiet ? order : null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('R5 006 parked Cart reuses a newly clear preferred position', (
    tester,
  ) async {
    final ownerKey = GlobalKey();
    late BuyV2CartAvoidanceLayout layout;
    late StateSetter updateObstacles;
    var blocked = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuyV2CartAvoidanceScope(
            child: Builder(
              builder: (context) {
                layout = BuyV2CartAvoidanceScope.of(context)!;
                return StatefulBuilder(
                  builder: (context, setState) {
                    updateObstacles = setState;
                    return Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        key: ownerKey,
                        width: 320,
                        height: 400,
                        child: Stack(
                          children: [
                            if (blocked)
                              const Positioned.fill(
                                child: BuyV2CartAvoidanceRegion(
                                  child: ColoredBox(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final owner = ownerKey.currentContext!.findRenderObject()! as RenderBox;
    const preferred = Offset(30, 60);
    const cart = Size(80, 48);
    layout.place(preferred, cart, owner.size, owner);
    expect(layout.dockHeight, greaterThan(0));
    updateObstacles(() => blocked = false);
    await tester.pumpAndSettle();
    expect(layout.place(preferred, cart, owner.size, owner), preferred);
    expect(layout.dockHeight, 0);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  Future<void> settleVisibleImages(WidgetTester tester) async {
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await tester.runAsync(
        () => precacheImage(image.image, tester.element(find.byWidget(image))),
      );
    }
    await tester.pumpAndSettle();
  }

  Future<void> revealDeliveryRailControl(
    WidgetTester tester,
    Finder control,
  ) async {
    if (control.hitTestable().evaluate().isEmpty) {
      final viewport = find.byKey(
        const PageStorageKey('buy-compact-cart-local-navigation-scroll'),
      );
      expect(viewport, findsOneWidget);
      expect(
        tester.getRect(viewport).contains(tester.getCenter(control)),
        isFalse,
        reason: 'A control obscured inside the visible rail is a defect',
      );
      await tester.drag(viewport, const Offset(-120, 0));
      await tester.pumpAndSettle();
    }
    expect(control.hitTestable(), findsOneWidget);
  }

  Widget app(
    BuyV2Session session, {
    Size size = const Size(390, 844),
    double textScale = 1,
    bool reducedMotion = false,
    EdgeInsets safeArea = EdgeInsets.zero,
    ValueChanged<PersonalMoolActionSpec>? onOpenMainAction,
    BuyV2DeliveryArrivalSound? deliveryArrivalSound,
  }) {
    return RepaintBoundary(
      key: const ValueKey('r66-cart-feedback-capture'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: size,
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
          initialCartScope: session.cartScope,
          onOpenMainAction: onOpenMainAction,
          deliveryArrivalSound: deliveryArrivalSound,
        ),
      ),
    );
  }

  Future<void> capture(
    WidgetTester tester,
    String name, {
    bool store = false,
    bool obstruction = false,
  }) async {
    const currentDirectory = String.fromEnvironment(
      'BUY_R664_VISUAL_DIRECTORY',
    );
    if (currentDirectory.isEmpty &&
        !(obstruction
            ? const bool.fromEnvironment('BUY_R66_CART_OBSTRUCTION_CAPTURE')
            : store
            ? const bool.fromEnvironment('BUY_R66_STORE_RETURN_CAPTURE')
            : const bool.fromEnvironment('BUY_R66_CART_FEEDBACK_CAPTURE'))) {
      return;
    }
    if (currentDirectory.isNotEmpty) await settleVisibleImages(tester);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('r66-cart-feedback-capture')),
    );
    boundary.markNeedsPaint();
    await tester.pump();
    await tester.runAsync(() async {
      final directory = Directory(
        currentDirectory.isNotEmpty
            ? currentDirectory
            : obstruction
            ? 'build/r66-cart-obstruction-v3-20260905'
            : store
            ? 'build/r66-store-return-v2-20260905'
            : 'build/r66-cart-feedback-v1-20260905',
      );
      await directory.create(recursive: true);
      final file = File('${directory.path}/$name.png');
      if (await file.exists()) throw StateError('Capture already exists');
      final image = await boundary.toImage(pixelRatio: 1);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });
  }

  BuyV2Product productFor(BuyV2Destination destination) =>
      BuyV2Catalogue.products.firstWhere(
        (product) =>
            product.destination == destination && !product.requiresPrescription,
      );

  Future<void> revealR5ProductContent(
    WidgetTester tester,
    Finder target,
  ) async {
    final scroll = find
        .descendant(
          of: find.byType(BuyV2ProductView),
          matching: find.byType(Scrollable),
        )
        .first;
    var seekingTop = true;
    for (
      var attempt = 0;
      attempt < 50 && target.evaluate().isEmpty;
      attempt++
    ) {
      if (tester.state<ScrollableState>(scroll).position.pixels <= .1) {
        seekingTop = false;
      }
      final viewport = tester
          .getRect(scroll)
          .intersect(
            tester.getRect(
              find.byKey(const ValueKey('buy-cart-content-viewport')),
            ),
          );
      final cart = find.byKey(const ValueKey('buy-mini-cart-drag-handle'));
      final blocked = cart.evaluate().isEmpty
          ? Rect.zero
          : tester.getRect(cart).inflate(8);
      final start = [
        Offset(viewport.left + 14, viewport.center.dy),
        Offset(viewport.right - 14, viewport.center.dy),
      ].firstWhere((point) => !blocked.contains(point));
      await tester.dragFrom(start, Offset(0, seekingTop ? 220 : -220));
      await tester.pumpAndSettle();
    }
    expect(
      target,
      findsOneWidget,
      reason: 'Product content is reachable by an unobstructed scroll.',
    );
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }

  for (final scenario in [
    for (final size in [
      const Size(320, 700),
      const Size(360, 800),
      const Size(430, 900),
      const Size(640, 360),
    ])
      for (final scale in [1.0, 2.0]) (size, scale),
  ]) {
    final size = scenario.$1;
    final scale = scenario.$2;
    final label = '${size.width.toInt()}x${size.height.toInt()}-$scale';
    testWidgets(
      'R5 004 product description survives Compare and Cart return $label',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core)
          ..openDestination(BuyV2Destination.wholesale)
          ..openProduct('w-oil');
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        final description = session
            .productContentFor(session.product('w-oil'))
            .description!;
        await tester.pumpWidget(app(session, size: size, textScale: scale));
        await tester.pumpAndSettle();
        final detail = find.text(description);
        await revealR5ProductContent(tester, detail);
        session.addProduct('s-tomato');
        session.addProduct('w-notebook');
        await tester.pumpAndSettle();
        final cart = find.byKey(const ValueKey('buy-mini-cart-drag-handle'));
        expect(cart.hitTestable(), findsOneWidget);
        final parked = find.byKey(const ValueKey('buy-cart-navigation-button'));
        if (parked.evaluate().isEmpty) {
          await tester.drag(
            cart,
            tester.getCenter(detail) - tester.getCenter(cart),
          );
          await tester.pumpAndSettle();
        } else {
          expect(tester.getSize(parked), const Size(44, 44));
          expect(parked.hitTestable(), findsOneWidget);
          expect(
            tester
                .getRect(
                  find.byKey(const ValueKey('buy-cart-content-viewport')),
                )
                .bottom,
            tester
                .getRect(
                  find.byKey(const ValueKey('buy-navigation-overlay-stack')),
                )
                .bottom,
          );
        }
        expect(tester.getRect(cart).overlaps(tester.getRect(detail)), isFalse);
        await capture(tester, 'r5-description-before-compare-$label');
        await revealR5ProductContent(tester, find.text('Compare'));
        await tester.tap(find.text('Compare'));
        await tester.pumpAndSettle();
        final alternate = find.byKey(
          const ValueKey('buy-product-compare-view-w-oil-10l'),
        );
        await Scrollable.ensureVisible(
          tester.element(alternate),
          alignment: .5,
        );
        await tester.pumpAndSettle();
        expect(alternate.hitTestable(), findsOneWidget);
        await tester.tap(alternate);
        await tester.pumpAndSettle();
        expect(session.selectedProduct?.id, 'w-oil-10l');
        await tester.tap(cart);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.selectedProduct?.id, 'w-oil-10l');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.selectedProduct?.id, 'w-oil');
        await revealR5ProductContent(tester, detail);
        expect(tester.getRect(cart).overlaps(tester.getRect(detail)), isFalse);
        await capture(tester, 'r5-description-after-compare-$label');
        expect(session.quantityFor('s-tomato'), 1);
        expect(session.quantityFor('w-notebook'), 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final saved in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'R5 004 empty content stays clear ${destination.name} saved=$saved text=$scale',
          (tester) async {
            const size = Size(360, 800);
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final core = BuySession();
            final session = BuyV2Session(core: core);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            session.addProduct('s-tomato');
            session.addProduct('w-notebook');
            session.openDestination(destination);
            if (saved) {
              session.showSavedProducts(true);
            } else {
              session.updateQuery('r5-no-matching-product');
            }
            final retainedShop = session.quantityFor('s-tomato');
            final retainedWholesale = session.quantityFor('w-notebook');
            await tester.pumpWidget(
              app(
                session,
                size: size,
                textScale: scale,
                safeArea: const EdgeInsets.only(top: 24, bottom: 24),
              ),
            );
            await tester.pumpAndSettle();
            final title = find.text(
              saved ? 'No saved products yet' : 'No matching products',
            );
            final detail = find.text(
              saved
                  ? 'Save products from this grid for instant access.'
                  : 'Check the product code or search by product name.',
            );
            final recovery = find.text(
              saved ? 'Show all products' : 'Clear search',
            );
            final cart = find.byKey(
              const ValueKey('buy-mini-cart-drag-handle'),
            );
            expect(title, findsOneWidget);
            expect(cart.hitTestable(), findsOneWidget);
            expect(
              find.byKey(const ValueKey('buy-cart-navigation-button')),
              findsNothing,
              reason: 'The seeded empty page has free space for the Cart.',
            );
            await tester.drag(
              cart,
              tester.getCenter(title) - tester.getCenter(cart),
            );
            await tester.pumpAndSettle();
            for (final text in [title, detail, recovery]) {
              expect(
                tester.getRect(cart).overlaps(tester.getRect(text)),
                isFalse,
                reason: 'Cart must not cover empty-state facts or recovery.',
              );
            }
            expect(recovery.hitTestable(), findsOneWidget);

            final displayedBeforeDrag = tester.getTopLeft(cart);
            final nextDrag = await tester.startGesture(tester.getCenter(cart));
            const firstDelta = Offset(24, 24);
            try {
              await nextDrag.moveBy(firstDelta);
              await tester.pump();
              const nextDelta = Offset(12, 16);
              await nextDrag.moveBy(nextDelta);
              await tester.pump();
              expect(
                (tester.getTopLeft(cart) - displayedBeforeDrag).distance,
                inInclusiveRange(
                  5,
                  firstDelta.distance + nextDelta.distance + 1,
                ),
                reason:
                    'Cart must follow the new finger movement from its displayed position.',
              );
            } finally {
              await nextDrag.up();
              await tester.pumpAndSettle();
            }

            for (final text in [title, detail, recovery]) {
              expect(
                tester.getRect(cart).overlaps(tester.getRect(text)),
                isFalse,
              );
            }
            final stable = tester.getTopLeft(cart);
            final stableSize = tester.getSize(cart);
            final stableTitle = tester.getRect(title);
            final stableViewport = tester.getRect(
              find.byKey(const ValueKey('buy-navigation-overlay-stack')),
            );
            await capture(tester, 'r5-empty-${destination.name}-$saved-$scale');
            await tester.tap(cart);
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.cart);
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(title, findsOneWidget);
            expect(
              tester.getTopLeft(cart),
              stable,
              reason:
                  'Cart size $stableSize -> ${tester.getSize(cart)}; '
                  'title $stableTitle -> ${tester.getRect(title)}; '
                  'viewport $stableViewport -> ${tester.getRect(find.byKey(const ValueKey('buy-navigation-overlay-stack')))}',
            );
            expect(session.quantityFor('s-tomato'), retainedShop);
            expect(session.quantityFor('w-notebook'), retainedWholesale);
            await tester.tap(recovery);
            await tester.pumpAndSettle();
            expect(title, findsNothing);
            expect(session.quantityFor('s-tomato'), retainedShop);
            expect(session.quantityFor('w-notebook'), retainedWholesale);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final size in [
    const Size(320, 700),
    const Size(430, 900),
    const Size(640, 360),
  ]) {
    for (final scale in [1.0, 2.0]) {
      for (final destination in [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
      ]) {
        final label =
            '${destination.name}-${size.width.toInt()}x${size.height.toInt()}-$scale';
        testWidgets(
          'R5 004 Saved clear keeps Cart and recovery usable $label',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final core = BuySession();
            final session = BuyV2Session(core: core);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            final product = productFor(destination);
            final other = productFor(
              destination == BuyV2Destination.shop
                  ? BuyV2Destination.wholesale
                  : BuyV2Destination.shop,
            );
            session.toggleSaved(product.id);
            session.toggleSaved(other.id);
            session.addProduct(product.id);
            session.addProduct(other.id);
            session.openDestination(destination);
            final retained = session.quantityFor(product.id);
            final retainedOther = session.quantityFor(other.id);
            await tester.pumpWidget(
              app(
                session,
                size: size,
                textScale: scale,
                safeArea: const EdgeInsets.only(top: 24, bottom: 24),
              ),
            );
            await tester.pumpAndSettle();
            await tester.tap(
              find.byKey(const ValueKey('buy-saved-products-button')),
            );
            await tester.pumpAndSettle();
            final clear = find.byKey(const ValueKey('buy-saved-clear'));
            await tester.tap(clear);
            await tester.pumpAndSettle();
            final keep = find.byKey(const ValueKey('buy-saved-keep'));
            final confirm = find.byKey(
              const ValueKey('buy-saved-confirm-clear'),
            );
            expect(keep.hitTestable(), findsOneWidget);
            expect(confirm.hitTestable(), findsOneWidget);
            await capture(tester, 'r5-saved-confirm-$label');
            Future<void> revealDecisionActions() async {
              final sheet = find.byKey(const ValueKey('buy-saved-clear-sheet'));
              final scroll = find.descendant(
                of: sheet,
                matching: find.byType(Scrollable),
              );
              for (
                var attempt = 0;
                attempt < 4 &&
                    tester.getRect(confirm).bottom > size.height - 24;
                attempt++
              ) {
                final bounds = tester.getRect(scroll);
                await tester.dragFrom(
                  Offset(bounds.right - 12, bounds.center.dy),
                  const Offset(0, -100),
                );
                await tester.pumpAndSettle();
              }
              for (final action in [keep, confirm]) {
                final bounds = tester.getRect(action);
                expect(bounds.top, greaterThanOrEqualTo(24));
                expect(bounds.bottom, lessThanOrEqualTo(size.height - 24));
                expect(bounds.height, greaterThanOrEqualTo(48));
                expect(action.hitTestable(), findsOneWidget);
              }
            }

            await revealDecisionActions();
            if (size.height < 400) {
              await capture(tester, 'r5-saved-confirm-actions-$label');
            }
            await tester.tap(keep);
            await tester.pumpAndSettle();
            expect(session.isSaved(product.id), isTrue);
            expect(session.isSaved(other.id), isTrue);
            await tester.tap(clear);
            await tester.pumpAndSettle();
            await revealDecisionActions();
            await tester.tap(confirm);
            await tester.pumpAndSettle();
            expect(session.isSaved(product.id), isFalse);
            expect(session.isSaved(other.id), isTrue);

            final cart = find.byKey(
              const ValueKey('buy-mini-cart-drag-handle'),
            );
            final title = find.text('No saved products yet');
            final detail = find.text(
              'Save products from this grid for instant access.',
            );
            final recovery = find.text('Show all products');
            final emptyParts = [title, detail, recovery];
            for (var index = 0; index < emptyParts.length; index++) {
              final part = emptyParts[index];
              await Scrollable.ensureVisible(
                tester.element(part),
                alignment: .5,
              );
              await tester.pumpAndSettle();
              expect(part.hitTestable(), findsOneWidget);
              expect(cart.hitTestable(), findsOneWidget);
              expect(
                tester.getRect(cart).overlaps(tester.getRect(part)),
                isFalse,
                reason:
                    'Each empty-page fact remains readable while scrolling.',
              );
              final viewport = tester.getRect(
                find.byKey(const ValueKey('buy-navigation-overlay-stack')),
              );
              final cartBounds = tester.getRect(cart);
              final parked = find.byKey(
                const ValueKey('buy-cart-navigation-button'),
              );
              if (parked.evaluate().isNotEmpty) {
                expect(tester.getSize(parked), const Size(44, 44));
                expect(cartBounds.left, greaterThanOrEqualTo(0));
                expect(cartBounds.right, lessThanOrEqualTo(size.width));
                expect(cartBounds.top, greaterThanOrEqualTo(viewport.bottom));
                expect(cartBounds.bottom, lessThanOrEqualTo(size.height - 24));
              } else {
                expect(cartBounds.left, greaterThanOrEqualTo(viewport.left));
                expect(cartBounds.right, lessThanOrEqualTo(viewport.right));
                expect(cartBounds.top, greaterThanOrEqualTo(viewport.top));
                expect(cartBounds.bottom, lessThanOrEqualTo(viewport.bottom));
              }
              expect(
                tester
                    .getRect(
                      find.byKey(const ValueKey('buy-cart-content-viewport')),
                    )
                    .bottom,
                viewport.bottom,
                reason:
                    'Cart must not reserve an extra strip above navigation.',
              );
              if (size.height < 400 || index == emptyParts.length - 1) {
                await capture(tester, 'r5-saved-empty-$index-$label');
              }
            }
            final stable = tester.getTopLeft(cart);
            await tester.tap(cart);
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.cart);
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(title, findsOneWidget);
            expect(tester.getTopLeft(cart), stable);
            expect(recovery.hitTestable(), findsOneWidget);
            await tester.tap(recovery);
            await tester.pumpAndSettle();
            expect(title, findsNothing);
            expect(session.quantityFor(product.id), retained);
            expect(session.quantityFor(other.id), retainedOther);
            expect(session.isSaved(other.id), isTrue);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final size in [const Size(360, 800), const Size(800, 360)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('R664 Mool menu stays inside safe area at $size / $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        expect(session.addProduct('w-notebook'), isTrue);
        session.openDestination(BuyV2Destination.medicine);
        final opened = <String>[];
        void recordAction(PersonalMoolActionSpec action) =>
            opened.add(action.id);
        const safe = EdgeInsets.fromLTRB(12, 24, 12, 16);
        await tester.pumpWidget(
          app(
            session,
            size: size,
            textScale: scale,
            safeArea: safe,
            onOpenMainAction: recordAction,
          ),
        );
        await tester.pumpAndSettle();
        final launcher = find.byKey(const Key('mool-compact-launcher'));
        final menu = find.byKey(const Key('mool-connected-action-navigator'));
        void expectBounds(Size viewport) {
          final rect = tester.getRect(menu);
          expect(rect.top, greaterThanOrEqualTo(safe.top));
          expect(rect.left, greaterThanOrEqualTo(safe.left));
          expect(rect.right, lessThanOrEqualTo(viewport.width - safe.right));
          expect(rect.bottom, lessThanOrEqualTo(viewport.height - safe.bottom));
        }

        Future<void> openMenu() async {
          await tester.tap(launcher);
          await tester.pumpAndSettle();
          expect(menu, findsOneWidget);
        }

        await openMenu();
        final label = 'r664-menu-${size.width}-${size.height}-$scale';
        await capture(tester, '$label-open');
        expectBounds(size);
        final scrollable = find.descendant(
          of: menu,
          matching: find.byType(Scrollable),
        );
        if (size.height < 400) {
          expect(scrollable, findsOneWidget);
          final scroll = tester.state<ScrollableState>(scrollable).position;
          expect(scroll.maxScrollExtent, greaterThan(0));
          await tester.drag(menu, const Offset(0, -120));
          await tester.pumpAndSettle();
          expect(menu, findsOneWidget);
          expect(scroll.pixels, greaterThan(0));
          await capture(tester, '$label-scrolled');
        }
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(menu, findsNothing);
        expect(session.destination, BuyV2Destination.medicine);
        expect(opened, isEmpty);
        await openMenu();
        await tester.tapAt(Offset(size.width - safe.right - 20, safe.top + 20));
        await tester.pumpAndSettle();
        expect(menu, findsNothing);
        await openMenu();
        await tester.drag(menu, const Offset(0, 70));
        await tester.pumpAndSettle();
        expect(menu, findsNothing);
        expect(opened, isEmpty);
        for (final family in moolActionFamilies.reversed) {
          await openMenu();
          final choice = find.byKey(
            ValueKey('mool-navigator-family-${family.id}'),
          );
          await tester.ensureVisible(choice);
          await tester.pumpAndSettle();
          final choiceRect = tester.getRect(choice);
          final menuRect = tester.getRect(menu);
          expect(choiceRect.top, greaterThanOrEqualTo(menuRect.top));
          expect(choiceRect.bottom, lessThanOrEqualTo(menuRect.bottom));
          expect(choice.hitTestable(), findsOneWidget);
          expect(choiceRect.height, greaterThanOrEqualTo(44));
          final text = find.descendant(
            of: choice,
            matching: find.text(family.label),
          );
          expect(
            tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
            isFalse,
          );
          await tester.tap(choice);
          await tester.pumpAndSettle();
          expect(menu, findsNothing);
          if (family.id == 'buy') {
            expect(session.destination, BuyV2Destination.shop);
            session.openDestination(BuyV2Destination.medicine);
            await tester.pumpAndSettle();
          } else {
            expect(opened.last, family.id);
            expect(session.destination, BuyV2Destination.medicine);
          }
          expect(session.quantityFor('w-notebook'), 1);
          expect(tester.takeException(), isNull);
        }
        if (size.height > size.width) {
          await openMenu();
          const landscape = Size(800, 360);
          tester.view.physicalSize = landscape;
          await tester.pumpWidget(
            app(
              session,
              size: landscape,
              textScale: scale,
              safeArea: safe,
              onOpenMainAction: recordAction,
            ),
          );
          await tester.pumpAndSettle();
          expect(menu, findsOneWidget);
          expectBounds(landscape);
          await capture(tester, '$label-rotated');
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(menu, findsNothing);
          expect(session.destination, BuyV2Destination.medicine);
          expect(session.quantityFor('w-notebook'), 1);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final compact in [false, true]) {
    for (final size in [const Size(320, 568), const Size(800, 360)]) {
      testWidgets('R664 standalone Mool bounds $size compact=$compact', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final opened = <String>[];
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('r66-cart-feedback-capture'),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: MoolTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.fromLTRB(12, 24, 12, 16),
                  viewPadding: const EdgeInsets.fromLTRB(12, 24, 12, 16),
                  viewInsets: const EdgeInsets.only(bottom: 120),
                  textScaler: const TextScaler.linear(2),
                ),
                child: child!,
              ),
              home: Scaffold(
                body: const ColoredBox(
                  color: Color(0xFFF5F7FC),
                  child: SizedBox.expand(),
                ),
                bottomNavigationBar: Align(
                  alignment: Alignment.bottomRight,
                  heightFactor: 1,
                  child: SizedBox(
                    width: compact ? 60 : size.width,
                    child: MoolGlobalNavigationV2(
                      activeId: 'book',
                      onOpenMool: null,
                      onOpenAction: (action) => opened.add(action.id),
                      onOpenChat: null,
                      compact: compact,
                      compactOverlayAlignEnd: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final launcher = find.byKey(
          Key(compact ? 'mool-compact-launcher' : 'mool-home-launcher'),
        );
        final menu = find.byKey(const Key('mool-connected-action-navigator'));
        if (!compact) {
          final label = find.descendant(
            of: launcher,
            matching: find.text('Mool'),
          );
          final labelRect = tester.getRect(label);
          final launcherRect = tester.getRect(launcher);
          final paragraph = tester.renderObject<RenderParagraph>(label);
          expect(launcherRect.size, const Size(64, 56));
          expect(labelRect.left, greaterThanOrEqualTo(launcherRect.left));
          expect(labelRect.right, lessThanOrEqualTo(launcherRect.right));
          expect(labelRect.bottom, lessThanOrEqualTo(launcherRect.bottom));
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(
            paragraph.getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 4),
            ),
            hasLength(1),
          );
          expect(MediaQuery.textScalerOf(tester.element(label)).scale(10), 20);
        }
        for (final family in moolActionFamilies.reversed) {
          await tester.tap(launcher);
          await tester.pumpAndSettle();
          final rect = tester.getRect(menu);
          expect(rect.top, greaterThanOrEqualTo(24));
          expect(rect.left, greaterThanOrEqualTo(12));
          expect(rect.right, lessThanOrEqualTo(size.width - 12));
          expect(rect.bottom, lessThanOrEqualTo(size.height - 120));
          final row = find.byKey(
            ValueKey('mool-navigator-family-${family.id}'),
          );
          await tester.ensureVisible(row);
          await tester.pumpAndSettle();
          final rowRect = tester.getRect(row);
          expect(rowRect.top, greaterThanOrEqualTo(rect.top));
          expect(rowRect.bottom, lessThanOrEqualTo(rect.bottom));
          if (family == moolActionFamilies.last) {
            await capture(
              tester,
              'r664-menu-standalone-${size.width}-${size.height}-$compact',
            );
          }
          await tester.tap(row);
          await tester.pumpAndSettle();
          expect(opened.last, family.id);
          expect(menu, findsNothing);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final size in [
    const Size(360, 800),
    const Size(320, 800),
    const Size(800, 360),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('R664 Cart protects Orders tab at $size / $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = _R66StoreStatusSession(core: core, quiet: false);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        expect(session.addProduct('s-tomato'), isTrue);
        session.openCart(scope: BuyV2CartScope.shop);
        expect(session.openCheckout(), isTrue);
        expect(session.confirmOrder(), isTrue);
        final purchaseId = session.confirmedOrders.single.purchaseId!;
        expect(session.addProduct('w-notebook'), isTrue);
        session.openDestination(BuyV2Destination.wholesale);
        await tester.pumpWidget(app(session, size: size, textScale: scale));
        await tester.pumpAndSettle();
        session.openOrders();
        await tester.pumpAndSettle();
        final cart = find.byKey(const ValueKey('buy-mini-cart-drag-handle'));
        final delivered = find.byKey(
          const ValueKey('buy-orders-tab-delivered'),
        );
        expect(cart, findsOneWidget);
        expect(delivered.hitTestable(), findsOneWidget);
        for (final label in ['Active', 'Delivered']) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(label),
          );
          expect(paragraph.text.style?.fontFamily, 'Inter');
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(
            paragraph.getMaxIntrinsicWidth(paragraph.size.height),
            lessThanOrEqualTo(paragraph.size.width + .5),
            reason: '$label must remain a readable, complete tab label',
          );
        }
        expect(
          tester.getRect(cart).overlaps(tester.getRect(delivered)),
          isFalse,
        );
        final purchase = find.text('Purchase $purchaseId');
        final ordersScroll = find
            .descendant(
              of: find.byKey(const PageStorageKey('buy-orders')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          purchase,
          120,
          scrollable: ordersScroll,
        );
        await tester.pumpAndSettle();
        await tester.drag(
          cart,
          tester.getCenter(purchase) - tester.getCenter(cart),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getRect(cart).overlaps(tester.getRect(purchase)),
          isFalse,
        );
        await capture(tester, 'r664-purchase-$size-$scale');
        await tester.scrollUntilVisible(
          delivered,
          -120,
          scrollable: ordersScroll,
        );
        await tester.pumpAndSettle();
        expect(delivered.hitTestable(), findsOneWidget);
        expect(
          tester
              .getRect(find.byKey(const ValueKey('buy-cart-content-viewport')))
              .bottom,
          closeTo(
            tester
                .getRect(
                  find.byKey(const ValueKey('buy-navigation-overlay-stack')),
                )
                .bottom,
            .1,
          ),
          reason:
              'Orders content must reach navigation without a full-width Cart strip',
        );
        final parked = find.byKey(const ValueKey('buy-cart-navigation-button'));
        expect(parked.hitTestable(), findsOneWidget);
        expect(tester.getSize(parked), const Size(44, 44));
        final progress = find.byKey(
          const ValueKey('buy-quick-delivery-toggle'),
        );
        await tester.ensureVisible(progress);
        await tester.pumpAndSettle();
        expect(progress.hitTestable(), findsOneWidget);
        expect(tester.getSize(progress), const Size(44, 44));
        await tester.tap(progress);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-quick-delivery-status-expanded')),
          findsOneWidget,
        );
        await tester.ensureVisible(progress);
        await tester.tap(progress);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-quick-delivery-status-expanded')),
          findsNothing,
        );
        await tester.tap(
          find.byKey(const ValueKey('buy-compact-cart-indicator')),
        );
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(session.cartScope, BuyV2CartScope.all);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.catalogue);
        expect(session.destination, BuyV2Destination.orders);
        await capture(tester, 'r664-orders-tabs-$size-$scale');
        await tester.tap(delivered);
        await tester.pumpAndSettle();
        expect(session.ordersTab, BuyV2OrdersTab.delivered);
        expect(session.view, isNot(BuyV2View.cart));
        expect(session.quantityFor('w-notebook'), 1);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'R664 Cart protects Recent heading and Clear at $size / $scale',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = _R66StoreStatusSession(core: core, quiet: false);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          expect(session.addProduct('s-tomato'), isTrue);
          expect(session.addProduct('w-notebook'), isTrue);
          session.openProduct('s-tomato');
          session.openDestination(BuyV2Destination.shop);
          await tester.pumpWidget(app(session, size: size, textScale: scale));
          await tester.pumpAndSettle();
          final heading = find.byKey(
            const ValueKey('buy-recently-viewed-heading'),
          );
          final clear = find.byKey(const ValueKey('buy-recently-viewed-clear'));
          await tester.scrollUntilVisible(
            clear,
            140,
            scrollable: find
                .descendant(
                  of: find.byType(BuyV2CatalogueView),
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is Scrollable &&
                        widget.axisDirection == AxisDirection.down,
                  ),
                )
                .first,
          );
          await tester.ensureVisible(clear);
          await tester.pumpAndSettle();
          final cart = find.byKey(const ValueKey('buy-mini-cart-drag-handle'));
          for (final target in [heading, clear]) {
            expect(
              tester.getRect(cart).overlaps(tester.getRect(target)),
              isFalse,
            );
          }
          final facts = find.byKey(
            const ValueKey('buy-recently-viewed-facts-s-tomato'),
          );
          await tester.ensureVisible(facts);
          await tester.pumpAndSettle();
          final viewport = tester.getRect(
            find.byKey(const ValueKey('buy-cart-content-viewport')),
          );
          final visibleFacts = tester.getRect(facts).intersect(viewport);
          expect(visibleFacts.height, greaterThan(0));
          await tester.drag(cart, visibleFacts.center - tester.getCenter(cart));
          await tester.pumpAndSettle();
          expect(tester.getRect(cart).overlaps(visibleFacts), isFalse);
          await capture(tester, 'r664-recent-facts-$size-$scale');
          await tester.ensureVisible(clear);
          await tester.pumpAndSettle();
          expect(clear.hitTestable(), findsOneWidget);
          await capture(tester, 'r664-recent-clear-$size-$scale');
          await tester.tap(clear);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-recently-viewed')),
            findsNothing,
          );
          expect(session.view, BuyV2View.catalogue);
          expect(session.quantityFor('s-tomato'), 1);
          expect(session.quantityFor('w-notebook'), 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final width in [320.0, 360.0]) {
    testWidgets('R664 Wholesale footer keeps freight and invoice at $width', (
      tester,
    ) async {
      final size = Size(width, 800);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      expect(session.addProduct('w-notebook'), isTrue);
      session.openCart(scope: BuyV2CartScope.wholesale);
      await tester.pumpWidget(app(session, size: size));
      await tester.pumpAndSettle();
      final note = find.text('Freight included · GST invoice at checkout');
      expect(note, findsOneWidget);
      final paragraph = tester.renderObject<RenderParagraph>(note);
      expect(paragraph.didExceedMaxLines, isFalse);
      final review = find.widgetWithText(FilledButton, 'Review order');
      expect(review.hitTestable(), findsOneWidget);
      expect(tester.getRect(note).overlaps(tester.getRect(review)), isFalse);
      await capture(tester, 'r664-wholesale-footer-$width');
      await tester.tap(review);
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.checkout);
      expect(session.quantityFor('w-notebook'), 1);
      expect(tester.takeException(), isNull);
    });
  }

  void expectWordsFit(WidgetTester tester, Finder textFinder) {
    final text = tester.widget<Text>(textFinder);
    final paragraph = tester.renderObject<RenderParagraph>(textFinder);
    expect(paragraph.didExceedMaxLines, isFalse);
    for (final word in text.data!.split(RegExp(r'\s+'))) {
      final measure = TextPainter(
        text: TextSpan(text: word, style: paragraph.text.style),
        textDirection: TextDirection.ltr,
        textScaler: paragraph.textScaler,
      )..layout();
      expect(
        paragraph.size.width + .5,
        greaterThanOrEqualTo(measure.width),
        reason: 'Complete word: $word',
      );
      measure.dispose();
    }
  }

  void expectCartClearOf(WidgetTester tester, Finder target) {
    expect(target, findsOneWidget);
    final visible = tester
        .getRect(target)
        .intersect(
          tester.getRect(
            find.byKey(const ValueKey('buy-cart-content-viewport')),
          ),
        );
    if (!visible.isEmpty) {
      expect(
        tester
            .getRect(find.byKey(const ValueKey('buy-mini-cart-drag-handle')))
            .overlaps(visible),
        isFalse,
        reason:
            'Cart must leave the full visible content region clear: $target',
      );
    }
  }

  for (final seed in [
    <String>[],
    ['s-tomato'],
    ['w-notebook'],
    ['s-tomato', 'w-notebook'],
  ]) {
    for (final activeOrder in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'R664 cross-destination Cart remains available $seed / $activeOrder / $scale',
          (tester) async {
            const size = Size(320, 800);
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final core = BuySession();
            final session = activeOrder
                ? _R66StoreStatusSession(core: core, quiet: false)
                : BuyV2Session(core: core);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            for (final id in seed) {
              expect(session.addProduct(id), isTrue);
            }
            final quantities = {
              for (final id in seed) id: session.quantityFor(id),
            };
            await tester.pumpWidget(app(session, size: size, textScale: scale));
            await tester.pumpAndSettle();
            final semantics = tester.ensureSemantics();
            try {
              var stepNumber = 0;
              for (final step in [
                (
                  key: 'moolsocial-family-root-buy-tap',
                  destination: BuyV2Destination.shop,
                  aggregate: false,
                ),
                (
                  key: 'buy-local-tab-wholesale',
                  destination: BuyV2Destination.wholesale,
                  aggregate: false,
                ),
                (
                  key: 'buy-local-tab-orders',
                  destination: BuyV2Destination.orders,
                  aggregate: true,
                ),
                (
                  key: 'buy-local-tab-offers',
                  destination: BuyV2Destination.shop,
                  aggregate: true,
                ),
                (
                  key: 'moolsocial-family-root-buy-tap',
                  destination: BuyV2Destination.shop,
                  aggregate: false,
                ),
              ]) {
                await tester.tap(find.byKey(ValueKey(step.key)));
                await tester.pumpAndSettle();
                expect(
                  session.view,
                  BuyV2View.catalogue,
                  reason: 'Navigation must not open Cart',
                );
                final indicator = find.byKey(
                  const ValueKey('buy-compact-cart-indicator'),
                );
                expect(indicator, seed.isEmpty ? findsNothing : findsOneWidget);
                expect(
                  find.byKey(const ValueKey('buy-quick-delivery-toggle')),
                  activeOrder ? findsOneWidget : findsNothing,
                );
                expect(
                  tester
                      .getRect(
                        find.byKey(const ValueKey('buy-cart-content-viewport')),
                      )
                      .bottom,
                  closeTo(
                    tester
                        .getRect(
                          find.byKey(
                            const ValueKey('buy-navigation-overlay-stack'),
                          ),
                        )
                        .bottom,
                    .1,
                  ),
                  reason:
                      'Buy destination content must reach navigation without a Cart strip',
                );
                if (seed.isNotEmpty) {
                  final parked = find.byKey(
                    const ValueKey('buy-cart-navigation-button'),
                  );
                  if (parked.evaluate().isNotEmpty) {
                    expect(parked.hitTestable(), findsOneWidget);
                    expect(tester.getSize(parked), const Size(44, 44));
                  }
                  if (step.key == 'buy-local-tab-offers') {
                    final header = find.byKey(
                      const ValueKey('buy-offers-publisher-summary'),
                    );
                    expectCartClearOf(tester, header);
                    for (final type in BuyV2OfferPublisherType.values) {
                      final filter = find.byKey(
                        ValueKey('buy-offers-filter-${type.name}'),
                      );
                      expectCartClearOf(tester, filter);
                      if (parked.evaluate().isEmpty) {
                        await tester.drag(
                          find.byKey(
                            const ValueKey('buy-mini-cart-drag-handle'),
                          ),
                          tester.getCenter(filter) -
                              tester.getCenter(indicator),
                        );
                        await tester.pumpAndSettle();
                        expectCartClearOf(tester, header);
                        expectCartClearOf(tester, filter);
                      }
                      await tester.tap(filter);
                      await tester.pumpAndSettle();
                      expect(session.view, BuyV2View.catalogue);
                      expect(
                        tester.widget<Semantics>(filter).properties.selected,
                        isTrue,
                      );
                      expectCartClearOf(tester, header);
                      await tester.tap(filter);
                      await tester.pumpAndSettle();
                      expect(
                        tester.widget<Semantics>(filter).properties.selected,
                        isFalse,
                      );
                    }
                  }
                  final fallback =
                      !step.aggregate &&
                      session.countForDestination(step.destination) == 0;
                  final aggregate = step.aggregate || fallback;
                  final expectedTotal = aggregate
                      ? session.cartTotal
                      : session.totalForDestination(step.destination);
                  final expectedCount = aggregate
                      ? session.itemCount
                      : session.countForDestination(step.destination);
                  final label = tester.getSemantics(indicator).label;
                  expect(label, contains(buyV2Money(expectedTotal)));
                  expect(
                    label,
                    contains(
                      '$expectedCount ${expectedCount == 1 ? 'item' : 'items'}',
                    ),
                  );
                  expect(label, isNot(contains('Preparing')));
                  if (fallback) {
                    expect(label, contains('All carts'));
                    if (parked.evaluate().isEmpty) {
                      expect(
                        find.descendant(
                          of: indicator,
                          matching: find.text('All carts'),
                        ),
                        findsOneWidget,
                      );
                    } else {
                      final tooltip = tester.widget<Tooltip>(
                        find.descendant(
                          of: indicator,
                          matching: find.byType(Tooltip),
                        ),
                      );
                      expect(tooltip.message, label);
                    }
                  }
                  if (seed.length == 1 &&
                      seed.single == 'w-notebook' &&
                      activeOrder) {
                    await capture(
                      tester,
                      'r664-cross-cart-$stepNumber-${step.key}-$scale',
                    );
                  }
                  await tester.tap(indicator);
                  await tester.pumpAndSettle();
                  expect(session.view, BuyV2View.cart);
                  expect(
                    session.cartScope,
                    aggregate
                        ? BuyV2CartScope.all
                        : step.destination == BuyV2Destination.shop
                        ? BuyV2CartScope.shop
                        : BuyV2CartScope.wholesale,
                  );
                  await tester.binding.handlePopRoute();
                  await tester.pumpAndSettle();
                  expect(session.view, BuyV2View.catalogue);
                  expect(indicator, findsOneWidget);
                }
                for (final entry in quantities.entries) {
                  expect(session.quantityFor(entry.key), entry.value);
                }
                expect(tester.takeException(), isNull);
                stepNumber++;
              }
            } finally {
              semantics.dispose();
            }
          },
        );
      }
    }
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'R664 Care Cart keeps its own basket and full viewport at $scale',
      (tester) async {
        const size = Size(320, 800);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        expect(session.addProduct('s-tomato'), isTrue);
        final product = productFor(BuyV2Destination.medicine);
        session.openDestination(BuyV2Destination.medicine);
        await tester.pumpWidget(app(session, size: size, textScale: scale));
        await tester.pumpAndSettle();
        final cart = find.byKey(const ValueKey('buy-compact-cart-indicator'));
        expect(
          cart,
          findsNothing,
          reason: 'Care must not claim the Shop basket',
        );
        expect(session.addProduct(product.id), isTrue);
        session.openProduct(product.id);
        await tester.pumpAndSettle();
        final quantity = find.byKey(
          ValueKey('buy-product-quantity-${product.id}'),
        );
        final scroll = find
            .descendant(
              of: find.byKey(PageStorageKey('buy-product-${product.id}')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(quantity, 180, scrollable: scroll);
        await tester.pumpAndSettle();
        final pharmacy = find.byKey(
          ValueKey('buy-medicine-pharmacy-action-${product.id}'),
        );
        expect(pharmacy, findsOneWidget);
        for (final label in tester.widgetList<Text>(
          find.descendant(of: pharmacy, matching: find.byType(Text)),
        )) {
          expectWordsFit(tester, find.byWidget(label));
        }
        final promiseChip = find
            .ancestor(
              of: find.text('Delivery promise shown'),
              matching: find.byType(Container),
            )
            .first;
        expectCartClearOf(tester, promiseChip);
        expect(cart.hitTestable(), findsOneWidget);
        expect(
          tester
              .getRect(find.byKey(const ValueKey('buy-cart-content-viewport')))
              .bottom,
          closeTo(
            tester
                .getRect(
                  find.byKey(const ValueKey('buy-navigation-overlay-stack')),
                )
                .bottom,
            .1,
          ),
        );
        await capture(tester, 'r664-care-cart-$scale');
        await tester.tap(cart);
        await tester.pumpAndSettle();
        expect(session.cartScope, BuyV2CartScope.medicine);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.selectedProductId, product.id);
        expect(session.view, BuyV2View.product);
        expect(session.quantityFor('s-tomato'), 1);
        expect(session.quantityFor(product.id), product.minimumOrder);
        await tester.ensureVisible(pharmacy);
        await tester.pumpAndSettle();
        final originOffset = tester
            .state<ScrollableState>(scroll)
            .position
            .pixels;
        expect(pharmacy.hitTestable(), findsOneWidget);
        expect(tester.getSize(pharmacy).height, greaterThanOrEqualTo(44));
        await tester.tap(pharmacy);
        await tester.pumpAndSettle();
        final store = find.byKey(
          ValueKey('buy-medicine-pharmacy-sheet-${product.id}'),
        );
        expect(store, findsOneWidget);
        final storeCards = tester
            .widgetList<BuyV2ProductCard>(
              find.descendant(
                of: store,
                matching: find.byType(BuyV2ProductCard),
              ),
            )
            .toList();
        expect(storeCards, isNotEmpty);
        for (final card in storeCards) {
          expect(card.product.seller, product.seller);
          expect(card.product.destination, BuyV2Destination.medicine);
          for (final label in tester.widgetList<Text>(
            find.descendant(
              of: find.byWidget(card),
              matching: find.byType(Text),
            ),
          )) {
            expectWordsFit(tester, find.byWidget(label));
          }
        }
        expect(tester.takeException(), isNull);
        await capture(tester, 'r664-care-store-$scale');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(store, findsNothing);
        expect(session.view, BuyV2View.product);
        expect(session.selectedProductId, product.id);
        expect(
          tester.state<ScrollableState>(scroll).position.pixels,
          closeTo(originOffset, .1),
        );
        expect(session.quantityFor('s-tomato'), 1);
        expect(session.quantityFor(product.id), product.minimumOrder);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final size in [const Size(320, 800), const Size(800, 360)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('R664 compact order choices $size / $scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = _R66StoreStatusSession(core: core, quiet: false);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        expect(session.addProduct('s-tomato'), isTrue);
        await tester.pumpWidget(
          app(
            session,
            size: size,
            textScale: scale,
            deliveryArrivalSound: _R5DockArrivalSound(),
          ),
        );
        await tester.pumpAndSettle();
        final toggle = find.byKey(const ValueKey('buy-quick-delivery-toggle'));
        final expanded = find.byKey(
          const ValueKey('buy-quick-delivery-status-expanded'),
        );
        expect(toggle.hitTestable(), findsOneWidget);
        expect(tester.getSize(toggle).width, lessThanOrEqualTo(48));
        expect(tester.getSize(toggle).height, lessThanOrEqualTo(48));
        final content = find.byKey(const ValueKey('buy-cart-content-viewport'));
        final contentRect = tester.getRect(content);
        await capture(tester, 'r664-order-icon-$size-$scale');
        expect(
          tester.getRect(toggle).top,
          greaterThanOrEqualTo(contentRect.bottom),
        );
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(expanded, findsOneWidget);
        expect(find.text(session.order.id), findsOneWidget);
        final cart = find.byKey(const ValueKey('buy-mini-cart-drag-handle'));
        expect(cart, findsOneWidget);
        final visiblePanel = tester
            .getRect(expanded)
            .intersect(
              tester.getRect(
                find.byKey(const ValueKey('buy-quick-delivery-choices-scroll')),
              ),
            );
        expect(tester.getRect(cart).overlaps(visiblePanel), isFalse);
        final expandedContentRect = tester.getRect(content);
        expect(
          expandedContentRect,
          contentRect,
          reason: 'Order choices and parked Cart must not shrink the viewport',
        );
        await capture(tester, 'r664-order-expanded-$size-$scale');
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(expanded, findsNothing);
        expect(
          tester.getRect(content),
          contentRect,
          reason: 'Collapsing choices restores the original usable area',
        );
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        final choices = find.byKey(
          const ValueKey('buy-quick-delivery-choices-scroll'),
        );
        final gesture = await tester.startGesture(tester.getCenter(choices));
        await gesture.moveBy(const Offset(0, -24));
        await tester.pump();
        await tester.pump(const Duration(seconds: 60));
        expect(
          expanded,
          findsOneWidget,
          reason: 'A held gesture must not lose its order controls',
        );
        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(seconds: 44));
        expect(expanded, findsOneWidget);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(expanded, findsNothing);
        expect(
          tester.getRect(content),
          contentRect,
          reason: 'Automatic collapse also releases temporary Cart parking',
        );
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        Future<void> revealChoice(Finder target) async {
          final scroll = tester.state<ScrollableState>(
            find
                .descendant(of: choices, matching: find.byType(Scrollable))
                .first,
          );
          await scroll.position.ensureVisible(tester.renderObject(target));
          await tester.pumpAndSettle();
          expect(target.hitTestable(), findsOneWidget);
        }

        final sound = find.byKey(const ValueKey('buy-quick-delivery-sound'));
        await revealChoice(sound);
        await tester.tap(sound);
        await tester.pumpAndSettle();
        expect(tester.widget<FilterChip>(sound).selected, isTrue);
        final hide = find.byKey(const ValueKey('buy-quick-delivery-hide'));
        await revealChoice(hide);
        await tester.tap(hide);
        await tester.pumpAndSettle();
        expect(expanded, findsNothing);
        expect(tester.getRect(content), contentRect);
        expect(toggle, findsNothing);
        session.openTracking(session.order.id);
        await tester.pumpAndSettle();
        final restore = find.byKey(
          const ValueKey('buy-quick-delivery-restore'),
        );
        await tester.ensureVisible(restore);
        await tester.pumpAndSettle();
        await tester.tap(restore);
        await tester.pumpAndSettle();
        expect(session.selectedOrderId, session.order.id);
        expect(session.view, BuyV2View.tracking);
        expect(restore, findsNothing);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await revealDeliveryRailControl(tester, toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(tester.widget<FilterChip>(sound).selected, isTrue);
        final track = find.byKey(const ValueKey('buy-quick-delivery-open'));
        await revealChoice(track);
        await tester.tap(track);
        await tester.pumpAndSettle();
        expect(session.selectedOrderId, session.order.id);
        expect(session.view, BuyV2View.tracking);
        expect(expanded, findsNothing);
        await tester.pump(const Duration(seconds: 46));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 46));
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final width in [320.0, 360.0]) {
    for (final orderId in ['MS-240782', 'MS-240741']) {
      testWidgets('R664 tracking labels fit $orderId at $width', (
        tester,
      ) async {
        final size = Size(width, 800);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        session.openTracking(orderId);
        await tester.pumpWidget(app(session, size: size, textScale: 2));
        await tester.pumpAndSettle();
        final label = find.text('Delivering to');
        await tester.ensureVisible(label);
        await tester.pumpAndSettle();
        expectWordsFit(tester, label);
        final value = find
            .text(session.selectedOrderOrNull!.destinationLabel)
            .last;
        final labelRect = tester.getRect(label);
        final valueRect = tester.getRect(value);
        expect(
          valueRect.top >= labelRect.bottom + 2 ||
              valueRect.left >= labelRect.right + 6,
          isTrue,
          reason: 'A visible gutter separates the field label and value',
        );
        await capture(tester, 'r664-tracking-$orderId-$width');
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('R664 checkout arrival label fits at $width', (tester) async {
      final size = Size(width, 800);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      expect(session.addProduct('w-notebook'), isTrue);
      session.openCart(scope: BuyV2CartScope.wholesale);
      session.openCheckout();
      await tester.pumpWidget(app(session, size: size, textScale: 2));
      await tester.pumpAndSettle();
      expect(session.showCheckoutStep(BuyV2CheckoutStep.confirm), isTrue);
      await tester.pumpAndSettle();
      final arrives = find.text('Arrives');
      await tester.ensureVisible(arrives);
      await tester.pumpAndSettle();
      expectWordsFit(tester, arrives);
      await capture(tester, 'r664-checkout-arrives-$width');
      expect(session.quantityFor('w-notebook'), 1);
      expect(tester.takeException(), isNull);
    });
    for (final scale in [1.0, 2.0]) {
      testWidgets('R664 Saved badge fits at $width / $scale', (tester) async {
        final size = Size(width, 800);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        session.toggleSaved('s-tomato');
        session.addProduct('s-tomato');
        await tester.pumpWidget(app(session, size: size, textScale: scale));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('buy-saved-products-button')),
        );
        await tester.pumpAndSettle();
        final tile = find.byKey(const ValueKey('buy-product-s-tomato'));
        await tester.ensureVisible(tile);
        await tester.pumpAndSettle();
        final badge = find.descendant(of: tile, matching: find.text('Lowest'));
        expectWordsFit(tester, badge);
        final remove = find.byKey(const ValueKey('buy-save-s-tomato'));
        expect(tester.getRect(badge).overlaps(tester.getRect(remove)), isFalse);
        expect(remove.hitTestable(), findsOneWidget);
        await capture(tester, 'r664-saved-badge-$width-$scale');
        await tester.tap(remove);
        await tester.pumpAndSettle();
        expect(session.isSaved('s-tomato'), isFalse);
        expect(session.quantityFor('s-tomato'), 1);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final size in [const Size(320, 800), const Size(800, 360)]) {
    testWidgets('R664 order choices remain reachable with keyboard $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = _R66StoreStatusSession(core: core, quiet: false);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      await tester.pumpWidget(app(session, size: size, textScale: 2));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-search-field')), findsOneWidget);
      tester.view.viewInsets = FakeViewPadding(
        bottom: size.height > size.width ? 300 : 140,
      );
      await tester.pumpAndSettle();
      final toggle = find.byKey(const ValueKey('buy-quick-delivery-toggle'));
      expect(toggle.hitTestable(), findsOneWidget);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      final choices = find.byKey(
        const ValueKey('buy-quick-delivery-choices-scroll'),
      );
      final rect = tester.getRect(choices);
      await capture(tester, 'r664-order-keyboard-header-$size');
      expect(
        rect.bottom,
        lessThanOrEqualTo(size.height - tester.view.viewInsets.bottom),
      );
      final hide = find.byKey(const ValueKey('buy-quick-delivery-hide'));
      final scroll = tester.state<ScrollableState>(
        find.descendant(of: choices, matching: find.byType(Scrollable)).first,
      );
      await scroll.position.ensureVisible(tester.renderObject(hide));
      await tester.pumpAndSettle();
      expect(hide.hitTestable(), findsOneWidget);
      await capture(tester, 'r664-order-keyboard-actions-$size');
      await tester.tap(hide);
      await tester.pumpAndSettle();
      expect(choices, findsNothing);
      expect(session.view, BuyV2View.catalogue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 46));
      expect(tester.takeException(), isNull);
    });
  }

  for (final mixed in [false, true]) {
    for (final id in ['s-tomato', 's-atta', 'w-tomato', 'w-rice']) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'R66 floating Cart avoids product controls $id at $scale mixed=$mixed',
          (tester) async {
            final size = Size(scale == 1 ? 360 : 320, 800);
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final core = BuySession();
            final session = BuyV2Session(core: core);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            final product = session.product(id);
            final retainedId = product.destination == BuyV2Destination.shop
                ? 'w-tomato'
                : 's-tomato';
            if (mixed) expect(session.addProduct(retainedId), isTrue);
            final retained = session.quantityFor(retainedId);
            session.openDestination(product.destination);
            if (product.destination == BuyV2Destination.shop) {
              session.chooseShopSaleType(
                id == 's-tomato'
                    ? BuyV2ShopSaleType.quickDelivery
                    : BuyV2ShopSaleType.courier,
              );
            } else {
              session.chooseWholesaleSaleType(
                id == 'w-rice'
                    ? BuyV2WholesaleSaleType.bulk
                    : BuyV2WholesaleSaleType.wholesale,
              );
            }
            session.openProduct(id);
            await tester.pumpWidget(app(session, size: size, textScale: scale));
            await tester.pumpAndSettle();
            final allActions = find.byKey(
              ValueKey('buy-product-action-slot-$id'),
            );
            final productScroll = find
                .descendant(
                  of: find.byType(BuyV2ProductView),
                  matching: find.byType(Scrollable),
                )
                .first;
            for (
              var attempt = 0;
              attempt < 30 && allActions.evaluate().isEmpty;
              attempt++
            ) {
              await tester.drag(productScroll, const Offset(0, -240));
              await tester.pumpAndSettle();
            }
            expect(allActions, findsWidgets);
            final actions = allActions.first;
            await tester.ensureVisible(actions);
            await tester.pumpAndSettle();
            final scroll = tester.state<ScrollableState>(
              find
                  .descendant(
                    of: find.byType(BuyV2ProductView),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            final overlay = find.byKey(
              const ValueKey('buy-navigation-overlay-stack'),
            );
            final targetBottom = tester.getRect(overlay).bottom - 16;
            scroll.position.jumpTo(
              (scroll.position.pixels +
                      tester.getRect(actions).bottom -
                      targetBottom)
                  .clamp(0.0, scroll.position.maxScrollExtent),
            );
            await tester.pumpAndSettle();
            final add = find.descendant(
              of: actions,
              matching: find.byKey(ValueKey('buy-product-primary-$id')),
            );
            await tester.tap(add);
            await tester.pump();
            expect(session.quantityFor(id), product.minimumOrder);
            final cart = find.byKey(
              const ValueKey('buy-mini-cart-drag-handle'),
            );
            expect(cart, findsOneWidget);
            final increase = find.descendant(
              of: actions,
              matching: find.byTooltip('Add one'),
            );
            expect(increase, findsOneWidget);
            expect(
              tester.getRect(cart).overlaps(tester.getRect(increase)),
              isFalse,
            );
            await tester.pumpAndSettle();
            final contentViewport = find.byKey(
              const ValueKey('buy-cart-content-viewport'),
            );
            void expectVisibleClear(Finder target) {
              final rect = tester
                  .getRect(target)
                  .intersect(tester.getRect(contentViewport));
              if (rect.width > 0 && rect.height > 0) {
                expect(tester.getRect(cart).overlaps(rect), isFalse);
              }
            }

            void expectRegionsClear() {
              for (final region
                  in find.byType(BuyV2CartAvoidanceRegion).evaluate()) {
                expectVisibleClear(
                  find.byElementPredicate((element) => element == region),
                );
              }
            }

            expectRegionsClear();
            await capture(
              tester,
              '$id-$scale-$mixed-default',
              obstruction: true,
            );
            expect(increase.hitTestable(), findsOneWidget);
            await tester.tapAt(tester.getCenter(increase));
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.product);
            expect(session.quantityFor(id), product.minimumOrder + 1);
            expect(session.quantityFor(retainedId), retained);
            for (final delta in [32.0, -64.0, 32.0]) {
              scroll.position.jumpTo(
                (scroll.position.pixels + delta).clamp(
                  0.0,
                  scroll.position.maxScrollExtent,
                ),
              );
              await tester.pumpAndSettle();
              expectVisibleClear(increase);
              expectRegionsClear();
            }
            final beforeDrag = tester.getTopLeft(cart);
            final productOffset = scroll.position.pixels;
            final parked = find.byKey(
              const ValueKey('buy-cart-navigation-button'),
            );
            if (parked.evaluate().isNotEmpty) {
              expect(parked.hitTestable(), findsOneWidget);
              expect(tester.getSize(parked), const Size(44, 44));
              expect(
                tester.getRect(contentViewport).bottom,
                closeTo(
                  tester
                      .getRect(
                        find.byKey(
                          const ValueKey('buy-navigation-overlay-stack'),
                        ),
                      )
                      .bottom,
                  .1,
                ),
              );
              final tooltip = tester.widget<Tooltip>(
                find.ancestor(of: parked, matching: find.byType(Tooltip)).first,
              );
              expect(
                tooltip.message,
                contains(
                  buyV2Money(session.totalForDestination(product.destination)),
                ),
              );
            } else {
              expect(
                beforeDrag.dx,
                greaterThanOrEqualTo(tester.getRect(contentViewport).left),
                reason:
                    'Floating Cart $beforeDrag ${tester.getSize(cart)}; viewport ${tester.getRect(contentViewport)}; overlay ${tester.getRect(find.byKey(const ValueKey('buy-navigation-overlay-stack')))}',
              );
              final drag = await tester.startGesture(tester.getCenter(cart));
              final viewport = tester.getRect(contentViewport);
              final dx = beforeDrag.dx - viewport.left > 60 ? -1.0 : 1.0;
              final dy = beforeDrag.dy - viewport.top > 130 ? -1.0 : 1.0;
              await drag.moveBy(Offset(12 * dx, 28 * dy));
              await tester.pump();
              await drag.moveBy(Offset(36 * dx, 82 * dy));
              await tester.pump();
              final held = tester.getTopLeft(cart);
              expect((held.dx - beforeDrag.dx) * dx, greaterThan(25));
              expect((held.dy - beforeDrag.dy) * dy, greaterThan(75));
              expect(scroll.position.pixels, closeTo(productOffset, .01));
              await drag.up();
              await tester.pumpAndSettle();
            }
            if (find
                .byKey(const ValueKey('buy-cart-navigation-button'))
                .evaluate()
                .isEmpty) {
              final displayed = tester.getTopLeft(cart);
              final secondDrag = await tester.startGesture(
                tester.getCenter(cart),
              );
              const firstMove = Offset(24, 24);
              await secondDrag.moveBy(firstMove);
              await tester.pump();
              expect(
                (tester.getTopLeft(cart) - displayed).distance,
                lessThanOrEqualTo(firstMove.distance + 1),
                reason:
                    'A new drag starts at the displayed Cart, without jumping to an older preference.',
              );
              await secondDrag.up();
              await tester.pumpAndSettle();
            }
            final dragged = tester.getTopLeft(cart);
            expectVisibleClear(increase);
            expectRegionsClear();
            expect(scroll.position.pixels, closeTo(productOffset, .01));
            await tester.tap(cart);
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.cart);
            expect(session.activeDockDestination, product.destination);
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.product);
            expect(session.selectedProduct?.id, id);
            expect(tester.getTopLeft(cart), dragged);
            final restoredScroll = tester.state<ScrollableState>(
              find
                  .descendant(
                    of: find.byType(BuyV2ProductView),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            expect(restoredScroll.position.pixels, closeTo(productOffset, .01));
            expect(session.quantityFor(id), product.minimumOrder + 1);
            expect(session.quantityFor(retainedId), retained);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  BuyV2Session mixedSession() {
    final session = BuyV2Session(core: BuySession());
    for (final destination in const [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ]) {
      expect(session.addProduct(productFor(destination).id), isTrue);
    }
    return session;
  }

  void expectConnectedOwner(
    WidgetTester tester,
    BuyV2Session session,
    BuyV2Destination expected,
  ) {
    expect(session.activeDockDestination, expected);
    expect(find.byKey(const Key('mool-home-launcher')), findsOneWidget);
    expect(find.byKey(const Key('buy-scoped-purchase-owner')), findsNothing);
    if (expected == BuyV2Destination.medicine) {
      expect(
        find.byKey(const Key('care-local-destination-tabs')),
        findsOneWidget,
      );
      for (final key in const [
        'care-local-tab-doctor',
        'care-local-tab-medicine',
        'care-local-tab-salon',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
      }
    } else {
      expect(
        find.byKey(const Key('buy-local-destination-tabs')),
        findsOneWidget,
      );
      for (final key in const [
        'buy-local-tab-wholesale',
        'buy-local-tab-orders',
        'buy-local-tab-offers',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
      }
    }
  }

  const cases = [
    (
      scope: BuyV2CartScope.shop,
      last: BuyV2Destination.medicine,
      expected: BuyV2Destination.shop,
    ),
    (
      scope: BuyV2CartScope.wholesale,
      last: BuyV2Destination.shop,
      expected: BuyV2Destination.wholesale,
    ),
    (
      scope: BuyV2CartScope.medicine,
      last: BuyV2Destination.wholesale,
      expected: BuyV2Destination.medicine,
    ),
  ];

  for (final size in [
    const Size(320, 700),
    const Size(430, 900),
    const Size(640, 360),
  ]) {
    for (final scale in [1.0, 2.0]) {
      for (final id in ['s-tomato', 'w-notebook']) {
        testWidgets('R5 023 Offers last quantity $id $size at $scale', (
          tester,
        ) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          await tester.pumpWidget(
            app(
              session,
              size: size,
              textScale: scale,
              safeArea: const EdgeInsets.only(top: 24, bottom: 24),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
          await tester.pumpAndSettle();
          final offers = find.byKey(const PageStorageKey('buy-offers'));
          final publisher = find.byKey(
            ValueKey(
              'buy-offers-filter-${id == 'w-notebook' ? 'manufacturer' : 'retailer'}',
            ),
          );
          await tester.ensureVisible(publisher);
          await tester.pumpAndSettle();
          expect(publisher.hitTestable(), findsOneWidget);
          await tester.tap(publisher);
          await tester.pumpAndSettle();
          final scroll = find
              .descendant(of: offers, matching: find.byType(Scrollable))
              .first;
          final add = find.byKey(ValueKey('buy-add-$id'));
          await tester.scrollUntilVisible(
            add,
            160,
            maxScrolls: 60,
            scrollable: scroll,
          );
          await tester.ensureVisible(add);
          await tester.pumpAndSettle();
          expect(add.hitTestable(), findsOneWidget);
          await tester.tap(add);
          await tester.pumpAndSettle();
          final product = session.product(id);
          expect(session.quantityFor(id), product.minimumOrder);
          final card = find.byKey(ValueKey('buy-product-$id'));
          final plus = find.descendant(
            of: card,
            matching: find.byTooltip('Add one'),
          );
          final minus = find.descendant(
            of: card,
            matching: find.byTooltip('Remove one'),
          );
          await Scrollable.ensureVisible(tester.element(plus), alignment: .5);
          await tester.pumpAndSettle();
          expect(plus.hitTestable(), findsOneWidget);
          await tester.tap(plus);
          await tester.pumpAndSettle();
          expect(session.quantityFor(id), product.minimumOrder + 1);
          await tester.tap(minus);
          await tester.pumpAndSettle();
          expect(session.quantityFor(id), product.minimumOrder);
          final state = tester.state<ScrollableState>(scroll);
          final offset = state.position.pixels;
          final cardTop = tester.getTopLeft(card).dy;
          final frame =
              'r5-offers-$id-${size.width.toInt()}-${size.height.toInt()}-$scale';
          await capture(tester, '$frame-before');
          expect(minus.hitTestable(), findsOneWidget);
          await tester.tap(minus);
          await tester.pumpAndSettle();
          expect(session.itemCount, 0);
          expect(session.destination, BuyV2Destination.shop);
          expect(session.view, BuyV2View.catalogue);
          expect(offers, findsOneWidget);
          expect(state.mounted, isTrue);
          expect(state.position.pixels, closeTo(offset, .1));
          expect(tester.getTopLeft(card).dy, closeTo(cardTop, .1));
          expect(add.hitTestable(), findsOneWidget);
          expect(
            find.byKey(const ValueKey('buy-mini-cart-drag-handle')),
            findsNothing,
          );
          await capture(tester, '$frame-after');
          await tester.tap(add);
          await tester.pumpAndSettle();
          expect(session.quantityFor(id), product.minimumOrder);
          expect(offers, findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final scale in [1.0, 2.0]) {
      for (final (search, partialHeader) in [
        (false, false),
        (false, true),
        (true, false),
        (true, true),
      ]) {
        testWidgets(
          'R5 007 landscape visible search returns ${destination.name} $search partial $partialHeader at $scale',
          (tester) async {
            const size = Size(800, 360);
            await tester.binding.setSurfaceSize(size);
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final core = BuySession();
            final session = BuyV2Session(core: core);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            session.openDestination(destination);
            for (final item
                in BuyV2Catalogue.products
                    .where(
                      (product) =>
                          product.destination == destination &&
                          !product.requiresPrescription,
                    )
                    .take(8)) {
              session.addProduct(item.id);
            }
            if (search) {
              session.updateQuery(
                destination == BuyV2Destination.shop ? 'tomato' : 'rice',
              );
            }
            final query = session.query;
            final count = session.itemCount;
            await tester.pumpWidget(
              app(
                session,
                size: size,
                textScale: scale,
                safeArea: const EdgeInsets.only(top: 24, bottom: 24),
              ),
            );
            await tester.pumpAndSettle();
            final header = find.byKey(const ValueKey('buy-search-band'));
            if (partialHeader) {
              await tester.dragFrom(
                Offset(size.width - 12, tester.getCenter(header).dy),
                const Offset(0, -30),
              );
              await tester.pumpAndSettle();
            }
            final before = tester.state<NestedScrollViewState>(
              find.byType(NestedScrollView),
            );
            final initialRect = tester.getRect(header);
            final outer = before.outerController.offset;
            final inner = before.innerController.offset;
            if (partialHeader) {
              expect(outer, greaterThan(0));
              expect(
                outer,
                lessThan(before.outerController.position.maxScrollExtent),
              );
              expect(inner, closeTo(0, .1));
            } else {
              expect(outer, closeTo(0, .1));
              expect(initialRect.top, greaterThanOrEqualTo(24));
            }
            final frame =
                'r5-landscape-search-${destination.name}-$search-$partialHeader-$scale';
            await capture(tester, '$frame-before');
            final cart = find.byKey(
              const ValueKey('buy-mini-cart-drag-handle'),
            );
            expect(cart.hitTestable(), findsOneWidget);
            await tester.tap(cart);
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.cart);
            final scroll = find
                .descendant(
                  of: find.byType(BuyV2CartView),
                  matching: find.byType(Scrollable),
                )
                .first;
            final review = find.widgetWithText(FilledButton, 'Review order');
            await tester.scrollUntilVisible(
              review,
              180,
              maxScrolls: 60,
              scrollable: scroll,
            );
            await tester.ensureVisible(review);
            await tester.pumpAndSettle();
            expect(
              tester.state<ScrollableState>(scroll).position.pixels,
              greaterThan(0),
            );
            expect(review.hitTestable(), findsOneWidget);
            await capture(tester, '$frame-cart');
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.catalogue);
            expect(session.destination, destination);
            expect(session.query, query);
            expect(session.itemCount, count);
            final after = tester.state<NestedScrollViewState>(
              find.byType(NestedScrollView),
            );
            expect(after.outerController.offset, closeTo(outer, .1));
            expect(after.innerController.offset, closeTo(inner, .1));
            expect(tester.getRect(header), initialRect);
            await capture(tester, '$frame-after');
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final size in [const Size(360, 800), const Size(640, 360)]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'R5 007 related Store Cart has no phantom visit ${destination.name} $size at $scale',
          (tester) async {
            await tester.binding.setSurfaceSize(size);
            addTearDown(() => tester.binding.setSurfaceSize(null));
            final core = BuySession();
            final session = BuyV2Session(core: core);
            addTearDown(core.dispose);
            addTearDown(session.dispose);
            session.addProduct('s-tomato');
            session.addProduct('w-rice');
            session.openDestination(destination);
            final isShop = destination == BuyV2Destination.shop;
            final product = session.product(isShop ? 's-tomato' : 'w-rice');
            await tester.pumpWidget(
              app(
                session,
                size: size,
                textScale: scale,
                safeArea: const EdgeInsets.only(top: 24, bottom: 24),
              ),
            );
            session.openProduct(product.id);
            await tester.pumpAndSettle();
            final productScroll = find
                .descendant(
                  of: find.byKey(PageStorageKey('buy-product-${product.id}')),
                  matching: find.byType(Scrollable),
                )
                .first;
            final supplier = find.byKey(
              ValueKey(
                '${isShop ? 'buy-shop-seller-action' : 'buy-wholesale-store-action'}-${product.id}',
              ),
            );
            await tester.scrollUntilVisible(
              supplier,
              180,
              maxScrolls: 60,
              scrollable: productScroll,
            );
            await tester.ensureVisible(supplier);
            await tester.pumpAndSettle();
            final productOffset = tester
                .state<ScrollableState>(productScroll)
                .position
                .pixels;
            final supplierRect = tester.getRect(supplier);
            final recent = session
                .recentlyViewedProductsFor(destination)
                .map((item) => item.id)
                .toList();
            final total = session.itemCount;
            final prefix = isShop
                ? 'buy-shop-seller'
                : 'buy-wholesale-supplier';
            final frame =
                'r5-related-${destination.name}-${size.width.toInt()}-$scale';
            await capture(tester, '$frame-origin');
            await tester.tap(supplier);
            await tester.pumpAndSettle();
            final outerStore = find.byKey(
              ValueKey('$prefix-sheet-${product.id}'),
            );
            final outerScroll = find
                .descendant(of: outerStore, matching: find.byType(Scrollable))
                .first;
            final relatedCards = find.descendant(
              of: outerStore,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget.key is ValueKey<String> &&
                    (widget.key! as ValueKey<String>).value.startsWith(
                      '$prefix-other-store-',
                    ),
              ),
            );
            await tester.scrollUntilVisible(
              find.byKey(ValueKey('$prefix-other-stores')),
              180,
              maxScrolls: 60,
              scrollable: outerScroll,
            );
            final related = relatedCards.first;
            await tester.ensureVisible(related);
            await tester.pumpAndSettle();
            final outerState = tester.state<ScrollableState>(outerScroll);
            final outerOffset = outerState.position.pixels;
            final relatedId = (tester.widget(related).key! as ValueKey<String>)
                .value
                .substring('$prefix-other-store-'.length);
            expect(relatedId, isNot(product.id));
            expect(related.hitTestable(), findsOneWidget);
            await tester.tap(related);
            await tester.pumpAndSettle();
            final innerStore = find.byKey(ValueKey('$prefix-sheet-$relatedId'));
            final innerRoute = find.byKey(ValueKey('$prefix-route-$relatedId'));
            final innerState = tester.state<ScrollableState>(
              find
                  .descendant(of: innerStore, matching: find.byType(Scrollable))
                  .first,
            );
            final innerOffset = innerState.position.pixels;
            await capture(tester, '$frame-related');
            for (var visit = 0; visit < 2; visit++) {
              final cart = find.descendant(
                of: innerRoute,
                matching: find.byKey(const ValueKey('buy-store-cart-bar')),
              );
              expect(cart.hitTestable(), findsOneWidget);
              await tester.tap(cart);
              await tester.pumpAndSettle();
              expect(session.view, BuyV2View.cart);
              await tester.binding.handlePopRoute();
              await tester.pumpAndSettle();
              expect(innerStore, findsOneWidget);
              expect(innerState.mounted, isTrue);
              expect(innerState.position.pixels, closeTo(innerOffset, .1));
              expect(
                session
                    .recentlyViewedProductsFor(destination)
                    .map((item) => item.id),
                recent,
              );
            }
            await capture(tester, '$frame-related-return');
            if (scale == 1) {
              final close = find.descendant(
                of: innerStore,
                matching: find.byTooltip(
                  isShop ? 'Close store' : 'Close supplier products',
                ),
              );
              await tester.ensureVisible(close);
              await tester.pumpAndSettle();
              expect(close.hitTestable(), findsOneWidget);
              await tester.tap(close);
            } else {
              await tester.binding.handlePopRoute();
            }
            await tester.pumpAndSettle();
            expect(outerStore, findsOneWidget);
            expect(outerState.position.pixels, closeTo(outerOffset, .1));
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.product);
            expect(session.selectedProductId, product.id);
            expect(
              tester.state<ScrollableState>(productScroll).position.pixels,
              closeTo(productOffset, .1),
            );
            expect(tester.getRect(supplier), supplierRect);
            await capture(tester, '$frame-product-return');
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.catalogue);
            expect(session.destination, destination);
            expect(session.itemCount, total);
            expect(
              session
                  .recentlyViewedProductsFor(destination)
                  .map((item) => item.id),
              recent,
            );
            await capture(tester, '$frame-final');
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
  for (final lane in [
    'shop',
    'wholesale',
    'bulk',
    'shop-all',
    'shop-live',
    'wholesale-quiet',
    'shop-wide',
    'shop-root-return',
    'shop-root-cart-first',
    'shop-root-live-cart-first',
    'wholesale-root-cart-first',
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('R66 nested Store Cart returns $lane at $scale', (
        tester,
      ) async {
        final size = lane == 'shop-wide'
            ? const Size(1024, 768)
            : const Size(320, 844);
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        addTearDown(tester.view.resetViewInsets);
        final core = BuySession();
        final hasStatus = lane.contains('live') || lane == 'wholesale-quiet';
        final session = hasStatus
            ? _R66StoreStatusSession(
                core: core,
                quiet: lane == 'wholesale-quiet',
              )
            : BuyV2Session(core: core);
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        final isShop = lane.startsWith('shop');
        final destination = isShop
            ? BuyV2Destination.shop
            : BuyV2Destination.wholesale;
        final product = session.product(
          lane == 'shop-all'
              ? 's-turmeric'
              : isShop
              ? 's-tomato'
              : 'w-rice',
        );
        final retained = session.product(isShop ? 'w-tomato' : 's-tomato');
        session.addProduct(retained.id);
        final retainedQuantity = session.quantityFor(retained.id);
        session.openDestination(destination);
        if (lane == 'bulk') {
          session.chooseWholesaleSaleType(BuyV2WholesaleSaleType.bulk);
        }
        await tester.pumpWidget(
          app(
            session,
            size: size,
            textScale: scale,
            reducedMotion: lane == 'bulk',
          ),
        );
        session.openProduct(product.id);
        await tester.pumpAndSettle();
        Finder productScroll() => find
            .descendant(
              of: find.byKey(PageStorageKey('buy-product-${product.id}')),
              matching: find.byType(Scrollable),
            )
            .first;
        final supplier = find.byKey(
          ValueKey(
            '${isShop ? 'buy-shop-seller-action' : 'buy-wholesale-store-action'}-${product.id}',
          ),
        );
        await tester.scrollUntilVisible(
          supplier,
          180,
          scrollable: productScroll(),
        );
        await tester.ensureVisible(supplier);
        await tester.pumpAndSettle();
        final rootProductOffset = tester
            .state<ScrollableState>(productScroll())
            .position
            .pixels;
        if (lane.contains('root-')) {
          if (isShop) {
            expectCartClearOf(
              tester,
              find.byKey(ValueKey('buy-product-benefits-ready-${product.id}')),
            );
          }
          await capture(tester, '$lane-root-origin-$scale', store: true);
        }
        await tester.tap(supplier);
        await tester.pumpAndSettle();
        var store = find.byKey(
          ValueKey(
            '${isShop ? 'buy-shop-seller' : 'buy-wholesale-supplier'}-sheet-${product.id}',
          ),
        );
        expect(store, findsOneWidget);
        if (lane == 'shop-all') {
          await tester.tap(
            find.byKey(ValueKey('buy-shop-seller-view-more-${product.id}')),
          );
          await tester.pumpAndSettle();
          store = find.byKey(
            const ValueKey('buy-shop-seller-full-catalogue-sheet'),
          );
          expect(store, findsOneWidget);
        }
        if (lane.endsWith('cart-first')) {
          session.addProduct(product.id);
          await tester.pumpAndSettle();
          final cart = find.byKey(const ValueKey('buy-store-cart-bar'));
          expect(cart.hitTestable(), findsOneWidget);
          await tester.tap(cart);
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.cart);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(store, findsOneWidget);
        }
        final storeSku = find.descendant(
          of: store,
          matching: find.byKey(ValueKey('buy-product-${product.id}')),
        );
        await tester.ensureVisible(storeSku);
        await tester.pumpAndSettle();
        final storeScroll = tester.state<ScrollableState>(
          find.descendant(of: store, matching: find.byType(Scrollable)).first,
        );
        final storeOffset = storeScroll.position.pixels;
        expect(storeSku.hitTestable(), findsOneWidget);
        await tester.tap(storeSku);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.product);
        expect(
          find.byKey(const ValueKey('buy-store-product-surface-owner')),
          findsOneWidget,
        );
        if (lane == 'shop-root-live-cart-first') {
          final toggle = find.byKey(
            const ValueKey('buy-quick-delivery-toggle'),
          );
          expect(toggle.hitTestable(), findsOneWidget);
          await tester.tap(toggle);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-quick-delivery-status-expanded')),
            findsOneWidget,
          );
          await tester.pump(const Duration(seconds: 46));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-quick-delivery-status-expanded')),
            findsNothing,
          );
        }
        final primary = lane.endsWith('cart-first')
            ? find.descendant(
                of: find.byKey(ValueKey('buy-product-quantity-${product.id}')),
                matching: find.byTooltip('Add one'),
              )
            : find.byKey(ValueKey('buy-product-primary-${product.id}'));
        await tester.scrollUntilVisible(
          primary,
          180,
          scrollable: productScroll(),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(primary);
        await tester.pumpAndSettle();
        expect(primary.hitTestable(), findsOneWidget);
        await tester.tap(primary);
        await tester.pumpAndSettle();
        final productState = tester.state<ScrollableState>(productScroll());
        final productOffset = productState.position.pixels;
        final count = session.quantityFor(product.id);
        await tester.tap(find.byKey(const ValueKey('buy-store-cart-bar')));
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(find.byType(BuyV2CartView, skipOffstage: false), findsOneWidget);
        expect(
          session.cartScope,
          isShop ? BuyV2CartScope.shop : BuyV2CartScope.wholesale,
        );
        expect(
          find.byKey(const ValueKey('buy-local-destination-tabs')),
          findsOneWidget,
        );
        expect(
          tester
              .getSize(
                find.byKey(const ValueKey('buy-store-product-surface-owner')),
              )
              .width,
          lessThanOrEqualTo(BuyV2Metrics.maxWidth),
        );
        if (lane == 'bulk') {
          tester.view.viewInsets = FakeViewPadding(
            bottom: 280 * tester.view.devicePixelRatio,
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-local-destination-tabs')),
            findsNothing,
          );
          expect(
            find.widgetWithText(FilledButton, 'Review order').hitTestable(),
            findsOneWidget,
          );
          tester.view.resetViewInsets();
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-local-destination-tabs')),
            findsOneWidget,
          );
        }
        if (lane == 'shop-live') {
          final expand = find.byKey(
            const ValueKey('buy-quick-delivery-expand'),
          );
          expect(expand, findsOneWidget);
          await tester.tap(expand);
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('buy-quick-delivery-hide')),
          );
          await tester.pumpAndSettle();
          final restore = find.byKey(
            const ValueKey('buy-quick-delivery-restore'),
          );
          expect(restore, findsNothing);
          expect(
            find.byKey(const ValueKey('buy-quick-delivery-toggle')),
            findsNothing,
          );
        } else if (lane == 'wholesale-quiet') {
          expect(
            find.byKey(const ValueKey('buy-quiet-delivery-status')),
            findsOneWidget,
          );
        }
        await capture(tester, '$lane-cart-$scale', store: true);
        session.showNotice('Your products are unchanged.');
        await tester.pumpAndSettle();
        expect(find.text('Your products are unchanged.'), findsOneWidget);
        session.clearNotice();
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Review order'));
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.checkout);
        expect(
          find.byType(BuyV2CheckoutView, skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('buy-checkout-address-stage')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('buy-checkout-return-cart')),
        );
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.product);
        expect(session.selectedProductId, product.id);
        expect(
          find.byKey(const ValueKey('buy-local-destination-tabs')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('buy-store-cart-bar')),
          findsOneWidget,
        );
        expect(
          tester.state<ScrollableState>(productScroll()).position.pixels,
          closeTo(productOffset, .1),
        );
        await capture(tester, '$lane-return-product-$scale', store: true);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(store, findsOneWidget);
        expect(storeScroll.mounted, isTrue);
        expect(storeScroll.position.pixels, closeTo(storeOffset, .1));
        if (lane.contains('cart-first')) {
          final relatedCards = find.byWidgetPredicate(
            (widget) =>
                widget.key is ValueKey<String> &&
                (widget.key! as ValueKey<String>).value.startsWith(
                  'buy-related-store-card-',
                ),
          );
          expect(relatedCards, findsWidgets);
          for (final card in relatedCards.evaluate()) {
            final cardFinder = find.byWidget(card.widget);
            final labels = find.descendant(
              of: cardFinder,
              matching: find.byType(Text),
            );
            expect(labels, findsWidgets);
            for (final label in tester.widgetList<Text>(labels)) {
              expectWordsFit(tester, find.byWidget(label));
            }
          }
        }
        await capture(tester, '$lane-return-store-$scale', store: true);
        if (lane.contains('root-')) {
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(store, findsNothing);
          expect(session.view, BuyV2View.product);
          expect(session.selectedProductId, product.id);
          expect(
            find.byKey(const ValueKey('buy-local-destination-tabs')),
            findsOneWidget,
          );
          expect(
            tester.state<ScrollableState>(productScroll()).position.pixels,
            closeTo(rootProductOffset, .1),
          );
          final trust = find.byKey(
            ValueKey('buy-marketplace-trust-ready-${product.id}'),
          );
          if (scale == 1 || product.destination == BuyV2Destination.wholesale) {
            expect(trust, findsOneWidget);
          }
          if (trust.evaluate().isNotEmpty) {
            final visibleTrust = tester
                .getRect(trust)
                .intersect(
                  tester.getRect(
                    find.byKey(const ValueKey('buy-cart-content-viewport')),
                  ),
                );
            if (!visibleTrust.isEmpty) {
              expect(
                tester
                    .getRect(
                      find.byKey(const ValueKey('buy-mini-cart-drag-handle')),
                    )
                    .overlaps(visibleTrust),
                isFalse,
                reason: 'Restored policy text must remain clear of Cart',
              );
            }
          }
          if (isShop) {
            expectCartClearOf(
              tester,
              find.byKey(ValueKey('buy-product-benefits-ready-${product.id}')),
            );
          }
          await capture(tester, '$lane-root-restored-$scale', store: true);
          final recentBeforeBack = session
              .recentlyViewedProductsFor(destination)
              .map((product) => product.id)
              .toList();
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(
            session.view,
            BuyV2View.catalogue,
            reason: 'Dismissed Store Cart visits must not reopen on Back',
          );
          expect(session.destination, destination);
          expect(session.quantityFor(product.id), count);
          expect(session.quantityFor(retained.id), retainedQuantity);
          expect(
            session
                .recentlyViewedProductsFor(destination)
                .map((item) => item.id),
            recentBeforeBack,
          );
          await capture(tester, '$lane-final-catalogue-$scale', store: true);
          expect(tester.takeException(), isNull);
          return;
        }
        await tester.tap(storeSku);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-store-cart-bar')));
        await tester.pumpAndSettle();
        final continueStore = find.byKey(
          const ValueKey('buy-cart-continue-store'),
        );
        await tester.ensureVisible(continueStore);
        await tester.pumpAndSettle();
        await tester.tap(continueStore);
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            ValueKey(
              '${isShop ? 'buy-shop-seller' : 'buy-wholesale-supplier'}-sheet-${product.id}',
            ),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(ValueKey('buy-product-${product.id}')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-store-cart-bar')));
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(find.byType(BuyV2CartView, skipOffstage: false), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.product);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(find.byType(BuyV2CartView, skipOffstage: false), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('buy-local-tab-orders')));
        await tester.pumpAndSettle();
        expect(session.destination, BuyV2Destination.orders);
        expect(session.view, BuyV2View.catalogue);
        expect(store, findsNothing);
        expect(storeScroll.mounted, isFalse);
        expect(session.quantityFor(product.id), count);
        expect(session.quantityFor(retained.id), retainedQuantity);
        if (lane == 'bulk') {
          expect(session.wholesaleSaleType, BuyV2WholesaleSaleType.bulk);
        }
        if (lane == 'shop-live') {
          expect(
            find.byKey(const ValueKey('buy-quick-delivery-toggle')),
            findsNothing,
            reason: 'Hide persists through Cart, checkout and Store returns',
          );
          final orderId = session.activeQuickDeliveryOrder!.id;
          session.openTracking(orderId);
          await tester.pumpAndSettle();
          final restore = find.byKey(
            const ValueKey('buy-quick-delivery-restore'),
          );
          await tester.ensureVisible(restore);
          await tester.pumpAndSettle();
          await tester.tap(restore);
          await tester.pumpAndSettle();
          expect(session.selectedOrderId, orderId);
          expect(session.view, BuyV2View.tracking);
          expect(restore, findsNothing);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.destination, BuyV2Destination.orders);
          expect(session.view, BuyV2View.catalogue);
          await revealDeliveryRailControl(
            tester,
            find.byKey(const ValueKey('buy-quick-delivery-toggle')),
          );
          expect(
            find
                .byKey(const ValueKey('buy-quick-delivery-toggle'))
                .hitTestable(),
            findsOneWidget,
          );
          expect(session.quantityFor(product.id), count);
          expect(session.quantityFor(retained.id), retainedQuantity);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'R66 scoped add feedback and Cart return ${destination.name} at $scale',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          final other = destination == BuyV2Destination.shop
              ? BuyV2Destination.wholesale
              : BuyV2Destination.shop;
          final product = productFor(destination);
          final retained = productFor(other);
          expect(session.addProduct(retained.id), isTrue);
          final retainedQuantity = session.quantityFor(retained.id);
          session.openDestination(destination);
          await tester.pumpWidget(
            app(session, size: const Size(320, 844), textScale: scale),
          );
          session.openProduct(product.id);
          await tester.pumpAndSettle();
          final primary = find.byKey(
            ValueKey('buy-product-primary-${product.id}'),
          );
          final scroll = find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-${product.id}')),
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(primary, 180, scrollable: scroll);
          await tester.pumpAndSettle();
          await tester.tap(primary);
          await tester.pumpAndSettle();
          final count = session.countForDestination(destination);
          final items = '$count ${count == 1 ? 'item' : 'items'}';
          final total = session.totalForDestination(destination);
          final dock = find.byKey(const ValueKey('buy-compact-cart-indicator'));
          final semantics = tester.ensureSemantics();
          try {
            expect(
              tester.getSemantics(dock).label,
              contains('${product.title} added · $items'),
            );
            expect(
              tester.getSemantics(dock).label,
              contains(buyV2Money(total)),
            );
            final parked = find.byKey(
              const ValueKey('buy-cart-navigation-button'),
            );
            if (parked.evaluate().isNotEmpty) {
              expect(parked.hitTestable(), findsOneWidget);
              expect(tester.getSize(parked), const Size(44, 44));
              final tooltip = tester.widget<Tooltip>(
                find.descendant(of: dock, matching: find.byType(Tooltip)),
              );
              expect(tooltip.message, tester.getSemantics(dock).label);
            } else {
              expect(
                find.descendant(of: dock, matching: find.text(items)),
                findsOneWidget,
              );
            }
            await capture(tester, '${destination.name}-added-$scale');
            await tester.tap(dock);
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.cart);
            expect(
              session.cartScope,
              destination == BuyV2Destination.shop
                  ? BuyV2CartScope.shop
                  : BuyV2CartScope.wholesale,
            );
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(session.view, BuyV2View.product);
            expect(session.selectedProductId, product.id);
            expect(session.countForDestination(destination), count);
            expect(session.totalForDestination(destination), total);
            expect(session.quantityFor(retained.id), retainedQuantity);
            session.openDestination(other);
            await tester.pumpAndSettle();
            expect(
              tester.getSemantics(dock).label,
              isNot(contains(product.title)),
            );
            expect(
              find.byKey(const ValueKey('buy-mini-cart-added-icon')),
              findsNothing,
            );
            await tester.tap(
              find.byKey(const ValueKey('buy-local-tab-offers')),
            );
            await tester.pumpAndSettle();
            final factsRail = find.byKey(
              const ValueKey('buy-published-offer-facts'),
            );
            final offerCards = find.descendant(
              of: factsRail,
              matching: find.byType(InkWell),
            );
            expect(offerCards, findsWidgets);
            for (final element in offerCards.evaluate()) {
              final card = find.byWidget(element.widget);
              final bounds = tester.getRect(card);
              final facts = find.descendant(
                of: card,
                matching: find.byType(Text),
              );
              expect(facts, findsNWidgets(4));
              for (final factElement in facts.evaluate()) {
                final fact = find.byWidget(factElement.widget);
                final paragraph = tester.renderObject<RenderParagraph>(fact);
                expect(paragraph.didExceedMaxLines, isFalse);
                expect(paragraph.maxLines, isNull);
                final factBounds = tester.getRect(fact);
                expect(factBounds.bottom, lessThanOrEqualTo(bounds.bottom - 7));
                expect(factBounds.right, lessThanOrEqualTo(bounds.right - 10));
              }
            }
            await capture(tester, '${destination.name}-offers-$scale');
            final allItems = '${session.itemCount} items';
            expect(tester.getSemantics(dock).label, contains(allItems));
            expect(
              tester.getSemantics(dock).label,
              contains(buyV2Money(session.cartTotal)),
            );
            await tester.tap(dock);
            await tester.pumpAndSettle();
            expect(session.cartScope, BuyV2CartScope.all);
            expect(session.quantityFor(retained.id), retainedQuantity);
          } finally {
            semantics.dispose();
          }
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'R66 Store Cart feedback stays scoped ${destination.name} at $scale',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          final other = destination == BuyV2Destination.shop
              ? BuyV2Destination.wholesale
              : BuyV2Destination.shop;
          final product = productFor(destination);
          final retained = productFor(other);
          expect(session.addProduct(retained.id), isTrue);
          final scope = destination == BuyV2Destination.shop
              ? BuyV2CartScope.shop
              : BuyV2CartScope.wholesale;
          await tester.pumpWidget(
            MaterialApp(
              theme: MoolTheme.light(),
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: AnimatedBuilder(
                    animation: session,
                    builder: (context, child) => BuyV2StoreCartBar(
                      session: session,
                      destination: destination,
                      onOpenCart: () => session.openCart(scope: scope),
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(session.addProduct(product.id), isTrue);
          await tester.pumpAndSettle();
          final count = session.countForDestination(destination);
          final items = '$count ${count == 1 ? 'item' : 'items'}';
          final bar = find.byKey(const ValueKey('buy-store-cart-bar'));
          final semantics = tester.ensureSemantics();
          try {
            expect(
              tester.getSemantics(bar).label,
              contains('${product.title} added · $items'),
            );
            expect(
              find.descendant(of: bar, matching: find.text(items)),
              findsOneWidget,
            );
            expect(tester.getSize(bar).height, greaterThanOrEqualTo(44));
            await tester.tap(bar);
            await tester.pumpAndSettle();
            expect(session.cartScope, scope);
            session.increase(retained.id);
            await tester.pumpAndSettle();
            expect(
              tester.getSemantics(bar).label,
              isNot(contains(retained.title)),
            );
            expect(
              find.descendant(of: bar, matching: find.text(items)),
              findsOneWidget,
            );
            expect(session.quantityFor(product.id), count);
          } finally {
            semantics.dispose();
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  test(
    'derived dock owner follows scoped Cart and Checkout without routing',
    () {
      for (final testCase in cases) {
        final session = mixedSession();
        addTearDown(session.dispose);
        session.openDestination(testCase.last);
        session.openCart(scope: testCase.scope);

        expect(session.destination, testCase.last);
        expect(session.activeDockDestination, testCase.expected);
        expect(session.openCheckout(), isTrue);
        expect(session.destination, testCase.last);
        expect(session.checkoutScope, testCase.scope);
        expect(session.activeDockDestination, testCase.expected);

        session.openCart(scope: session.checkoutScope);
        expect(session.destination, testCase.last);
        expect(session.cartScope, testCase.scope);
        expect(session.activeDockDestination, testCase.expected);
      }

      final combined = mixedSession();
      addTearDown(combined.dispose);
      combined.openDestination(BuyV2Destination.shop);
      combined.openCart();
      expect(combined.activeDockDestination, BuyV2Destination.shop);
      expect(combined.openCheckout(), isTrue);
      expect(combined.activeDockDestination, BuyV2Destination.shop);
      expect(combined.destination, BuyV2Destination.shop);
    },
  );

  testWidgets('scoped Cart and Checkout retain every established rail action', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();

    for (final testCase in cases) {
      final session = mixedSession();
      addTearDown(session.dispose);
      session.openDestination(testCase.last);
      session.openCart(scope: testCase.scope);

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      expectConnectedOwner(tester, session, testCase.expected);
      expect(session.destination, testCase.last);

      expect(session.openCheckout(), isTrue);
      await tester.pumpAndSettle();
      expectConnectedOwner(tester, session, testCase.expected);
      expect(session.destination, testCase.last);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.cart);
      expect(session.destination, testCase.last);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.catalogue);
      expect(session.destination, testCase.last);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
    semantics.dispose();
  });

  testWidgets('combined scope retains its valid entry vertical', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    final session = mixedSession();
    addTearDown(session.dispose);
    session.openDestination(BuyV2Destination.shop);
    session.openCart();

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expectConnectedOwner(tester, session, BuyV2Destination.shop);
    expect(session.openCheckout(), isTrue);
    await tester.pumpAndSettle();
    expectConnectedOwner(tester, session, BuyV2Destination.shop);
    expect(session.destination, BuyV2Destination.shop);
    semantics.dispose();
  });

  testWidgets(
    'compact Mool launcher opens and Back closes the menu without losing Cart',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      final session = mixedSession();
      addTearDown(session.dispose);
      session.openDestination(BuyV2Destination.shop);
      session.openCart(scope: BuyV2CartScope.wholesale);
      final cartIds = session.cartLines.map((line) => line.product.id).toList();

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      final launcher = find.byKey(const Key('mool-home-launcher'));
      expect(launcher, findsOneWidget);
      expect(tester.getSemantics(launcher).label, 'Open MoolSocial main menu');

      await tester.tap(launcher);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('moolsocial-main-menu-arrival-motion')),
        findsOneWidget,
      );
      expect(tester.getSemantics(launcher).label, 'Close MoolSocial main menu');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('moolsocial-main-menu-arrival-motion')),
        findsNothing,
      );
      expect(session.view, BuyV2View.cart);
      expect(session.cartScope, BuyV2CartScope.wholesale);
      expect(
        session.cartLines.map((line) => line.product.id),
        orderedEquals(cartIds),
      );
      semantics.dispose();
    },
  );

  testWidgets('320px 140% reduced motion is immediate and semantically exact', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    final session = mixedSession();
    addTearDown(session.dispose);
    session.openDestination(BuyV2Destination.medicine);
    session.openCart(scope: BuyV2CartScope.shop);
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
    expectConnectedOwner(tester, session, BuyV2Destination.shop);
    expect(session.destination, BuyV2Destination.medicine);
    expect(session.checkoutStep, BuyV2CheckoutStep.address);
    expect(find.text('Delivery address'), findsOneWidget);
    expect(find.text('Receiving address'), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  for (final viewport in const [
    (
      size: Size(320, 568),
      safe: EdgeInsets.symmetric(vertical: 24),
      textScale: 1.0,
      reduced: false,
      checkout: true,
      label: '320x568-android-checkout',
    ),
    (
      size: Size(360, 800),
      safe: EdgeInsets.symmetric(vertical: 24),
      textScale: 1.0,
      reduced: false,
      checkout: false,
      label: '360x800-android-cart',
    ),
    (
      size: Size(390, 844),
      safe: EdgeInsets.only(top: 47, bottom: 34),
      textScale: 1.0,
      reduced: false,
      checkout: true,
      label: '390x844-ios-checkout',
    ),
    (
      size: Size(430, 932),
      safe: EdgeInsets.only(top: 59, bottom: 34),
      textScale: 1.0,
      reduced: false,
      checkout: false,
      label: '430x932-ios-cart',
    ),
    (
      size: Size(320, 568),
      safe: EdgeInsets.symmetric(vertical: 24),
      textScale: 1.4,
      reduced: true,
      checkout: true,
      label: '320x568-a11y140-reduced',
    ),
  ]) {
    testWidgets(
      'R58.8.7 responsive ${viewport.label} candidate capture',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        tester.view.physicalSize = viewport.size;
        final session = mixedSession();
        addTearDown(session.dispose);
        session.openDestination(BuyV2Destination.medicine);
        session.openCart(scope: BuyV2CartScope.shop);
        if (viewport.checkout) {
          expect(session.openCheckout(), isTrue);
        }

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
        await settleVisibleImages(tester);
        expectConnectedOwner(tester, session, BuyV2Destination.shop);
        await expectLater(
          find.byType(BuyV2Screen),
          matchesGoldenFile(
            'candidate_captures/buy-v2-r58-8-7-c24f-${viewport.label}.png',
          ),
        );
      },
      tags: 'protected-reference',
    );
  }
}
