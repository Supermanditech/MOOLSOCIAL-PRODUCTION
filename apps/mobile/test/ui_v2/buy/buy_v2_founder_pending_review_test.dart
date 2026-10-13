import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

class _Source extends BuyV2DevelopmentCatalogueSource {
  _Source(BuyV2Destination destination)
    : super(destination: destination, providerCount: 4, skusPerStore: 120);
  Completer<void>? productsWait;
  Completer<void>? storesWait;
  bool failStores = false;
  final pages = <BuyV2CataloguePage<BuyV2Product>>[];

  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    if (query.query.isNotEmpty && productsWait != null) {
      await productsWait!.future;
    }
    final page = await super.loadProducts(
      query,
      cursor: cursor,
      pageSize: pageSize,
    );
    pages.add(page);
    return page;
  }

  @override
  Future<BuyV2CataloguePage<BuyV2StoreListing>> loadStores(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    if (query.query.isNotEmpty && storesWait != null) {
      await storesWait!.future;
    }
    if (failStores) throw StateError('Store lookup unavailable');
    return super.loadStores(query, cursor: cursor, pageSize: pageSize);
  }
}

Widget _app(BuyV2Session session, {bool reducedMotion = false}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: MoolTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
    child: RepaintBoundary(
      key: const ValueKey('pending-review-capture'),
      child: child!,
    ),
  ),
  home: BuyV2Screen(session: session, initialDestination: session.destination),
);

Future<void> _capture(WidgetTester tester, String name) async {
  const directory = String.fromEnvironment('FOUNDER_PENDING_CAPTURE_DIR');
  if (directory.isEmpty) return;
  final images = find.byType(Image).evaluate().toList();
  await tester.runAsync(() async {
    for (final element in images) {
      if (!element.mounted) continue;
      final provider = (element.widget as Image).image;
      ImageProvider source = provider;
      while (source is ResizeImage) {
        source = source.imageProvider;
      }
      if (source is AssetImage) await precacheImage(provider, element);
    }
  });
  await tester.pump(const Duration(milliseconds: 200));
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('pending-review-capture')),
  );
  await tester.runAsync(() async {
    await Directory(directory).create(recursive: true);
    final image = await boundary.toImage(pixelRatio: 1.5);
    try {
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      await File(
        '$directory/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    await font.load();
  });

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final reduced in [false, true]) {
      testWidgets(
        'C04 ${destination.name} whole grid follows finger reduced=$reduced',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(390, 844);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final source = _Source(destination);
          final session = BuyV2Session(
            core: core,
            reviewDataEnabled: true,
            cataloguePageSource: source,
            initialCatalogueRegionId: 'jodhpur',
          )..destination = destination;
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          await tester.pumpWidget(_app(session, reducedMotion: reduced));
          await tester.pumpAndSettle();
          final products = source.pages.first.items;
          final cards = products
              .take(3)
              .map((p) => find.byKey(ValueKey('buy-product-${p.id}')))
              .toList();
          final before = cards.map(tester.getTopLeft).toList();
          await _capture(tester, 'c04-${destination.name}-$reduced-before');
          final rect = tester.getRect(cards[1]);
          final gesture = await tester.startGesture(
            Offset(rect.center.dx, rect.top + 50),
          );
          await gesture.moveBy(const Offset(-25, 0));
          await tester.pump();
          await gesture.moveBy(const Offset(-70, 0));
          await tester.pump();
          for (var i = 0; i < cards.length; i++) {
            expect(
              tester.getTopLeft(cards[i]).dx - before[i].dx,
              closeTo(-70, 1),
            );
            expect(tester.getTopLeft(cards[i]).dy, closeTo(before[i].dy, 1));
          }
          final incoming = source.pages.firstWhere((p) => p.startIndex == 40);
          final incomingCard = find.byKey(
            ValueKey('buy-product-${incoming.items.first.id}'),
          );
          expect(incomingCard, findsOneWidget);
          final incomingRect = tester.getRect(incomingCard);
          expect(incomingRect.left, lessThan(390));
          expect(incomingRect.right, greaterThan(320));
          final status = find.byKey(
            ValueKey('buy-page-status-catalogue-${destination.name}'),
          );
          expect(
            tester.widget<Semantics>(status).properties.label,
            startsWith('1–'),
          );

          await _capture(tester, 'c04-${destination.name}-$reduced-during');
          await gesture.moveBy(const Offset(-100, 0));
          await tester.pump();
          expect(tester.getRect(incomingCard).left, lessThan(240));
          await _capture(tester, 'c04-${destination.name}-$reduced-halfway');
          await gesture.up();
          await tester.pumpAndSettle();
          expect(
            tester.widget<Semantics>(status).properties.label,
            startsWith('41–'),
          );
          await _capture(tester, 'c04-${destination.name}-$reduced-after');
          final grid = find.byKey(
            ValueKey('buy-paged-vertical-grid-catalogue-${destination.name}'),
          );
          final settledX = tester.getTopLeft(grid).dx;
          final returnGesture = await tester.startGesture(
            Offset(100, rect.top + 50),
          );
          await returnGesture.moveBy(const Offset(25, 0));
          await tester.pump();
          await returnGesture.moveBy(const Offset(70, 0));
          await tester.pump();
          expect(tester.getTopLeft(grid).dx - settledX, closeTo(70, 1));
          await returnGesture.up();
          await tester.pumpAndSettle();
          expect(
            tester.widget<Semantics>(status).properties.label,
            startsWith('1–'),
          );
          expect(session.itemCount, 0);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final surface in ['store', 'supplier', 'offers']) {
    testWidgets('C04 $surface shared grid follows finger and changes page', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final destination = surface == 'supplier'
          ? BuyV2Destination.wholesale
          : BuyV2Destination.shop;
      final core = BuySession();
      final source = _Source(destination);
      final now = DateTime.utc(2026, 9, 18);
      final session = BuyV2Session(
        core: core,
        reviewDataEnabled: true,
        cataloguePageSource: source,
        initialCatalogueRegionId: 'jodhpur',
        publishedCatalogueSource: BuyV2DevelopmentPublishedCatalogueSource(
          now: () => now,
        ),
        catalogueNow: () => now,
      )..destination = destination;
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      var scope = 'published-offers';
      if (surface == 'offers') {
        await tester.pumpWidget(_app(session));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
      } else {
        final page = await source.loadProducts(
          session.catalogueQuery(),
          pageSize: 40,
        );
        final storeId = page.items.first.storeId!;
        scope = 'store-${destination.name}-$storeId';
        await tester.pumpWidget(
          MaterialApp(
            theme: MoolTheme.light(),
            home: Scaffold(
              body: BuyV2PagedProductCatalogue(
                session: session,
                scopeKey: scope,
                storeContext: true,
                query: session.catalogueQuery(storeId: storeId),
              ),
            ),
          ),
        );
      }
      await tester.pumpAndSettle();
      final grid = find.byKey(ValueKey('buy-paged-vertical-grid-$scope'));
      final scroll = find.byKey(ValueKey('buy-paged-scroll-$scope'));
      final controller = tester.widget<ListView>(scroll).controller!;
      if (tester.getRect(grid).top > tester.getRect(scroll).bottom - 100) {
        controller.jumpTo(
          (tester.getRect(grid).top - tester.getRect(scroll).top).clamp(
            0,
            controller.position.maxScrollExtent,
          ),
        );
        await tester.pumpAndSettle();
      }
      final before = tester.getTopLeft(grid);
      final y = (before.dy + 70)
          .clamp(
            tester.getRect(scroll).top + 50,
            tester.getRect(scroll).bottom - 50,
          )
          .toDouble();
      final gesture = await tester.startGesture(Offset(270, y));
      await gesture.moveBy(const Offset(-25, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-70, 0));
      await tester.pump();
      expect(tester.getTopLeft(grid).dx - before.dx, closeTo(-70, 1));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-incoming-grid')),
          matching: find.byType(BuyV2ProductCard),
        ),
        findsWidgets,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Semantics>(find.byKey(ValueKey('buy-page-status-$scope')))
            .properties
            .label,
        startsWith('41'),
      );
      expect(session.itemCount, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('C04 cancelling a drag restores the same grid and page', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final source = _Source(BuyV2Destination.shop);
    final session = BuyV2Session(
      core: core,
      reviewDataEnabled: true,
      cataloguePageSource: source,
      initialCatalogueRegionId: 'jodhpur',
    );
    addTearDown(core.dispose);
    addTearDown(session.dispose);
    await tester.pumpWidget(_app(session));
    await tester.pumpAndSettle();
    final grid = find.byKey(
      const ValueKey('buy-paged-vertical-grid-catalogue-shop'),
    );
    final initial = tester.getTopLeft(grid);
    final gesture = await tester.startGesture(Offset(260, initial.dy + 60));
    await gesture.moveBy(const Offset(-25, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-90, 0));
    await tester.pump();
    expect(find.byKey(const ValueKey('buy-incoming-grid')), findsOneWidget);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(grid), initial);
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey('buy-page-status-catalogue-shop')),
          )
          .properties
          .label,
      startsWith('1–'),
    );
    expect(find.byKey(const ValueKey('buy-incoming-grid')), findsNothing);
    expect(session.itemCount, 0);
    expect(tester.takeException(), isNull);
  });

  for (final productsFirst in [true, false]) {
    testWidgets(
      'C06 one progress line with independent requests productsFirst=$productsFirst',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final source = _Source(BuyV2Destination.shop);
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: true,
          cataloguePageSource: source,
          initialCatalogueRegionId: 'jodhpur',
        );
        addTearDown(core.dispose);
        addTearDown(session.dispose);
        await tester.pumpWidget(_app(session));
        await tester.pumpAndSettle();
        source.productsWait = Completer<void>();
        source.storesWait = Completer<void>();
        addTearDown(() {
          if (!source.productsWait!.isCompleted) {
            source.productsWait!.complete();
          }
          if (!source.storesWait!.isCompleted) source.storesWait!.complete();
        });
        await tester.tap(find.byKey(const ValueKey('buy-search-control')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('buy-search-field')),
          'milk',
        );
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        final loadingLines = find.descendant(
          of: find.byKey(const ValueKey('buy-page-status-search-shop')),
          matching: find.byType(LinearProgressIndicator),
        );
        expect(loadingLines, findsOneWidget);
        await _capture(tester, 'c06-$productsFirst-both-loading');
        (productsFirst ? source.productsWait : source.storesWait)!.complete();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        expect(loadingLines, findsOneWidget);
        await _capture(tester, 'c06-$productsFirst-one-loading');
        (productsFirst ? source.storesWait : source.productsWait)!.complete();
        await tester.pumpAndSettle();
        expect(loadingLines, findsNothing);
        expect(session.query, 'milk');
        await _capture(tester, 'c06-$productsFirst-complete');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'C07 actual Buy route retains search and stays closed across rotation',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final journey = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'manual',
            areaLabel: 'Sardarpura',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      final core = BuySession();
      addTearDown(journey.dispose);
      addTearDown(core.dispose);
      await journey.start();
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('pending-review-capture'),
          child: MoolSocialApp(
            session: journey,
            buySession: core,
            initialLocation: '/app/buy?sub=shop',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final screen = tester.widget<BuyV2Screen>(find.byType(BuyV2Screen));
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('buy-search-field')),
        'milk',
      );
      await tester.pumpAndSettle();
      final category = screen.session.selectedCategoryId;
      for (var round = 0; round < 3; round++) {
        for (final size in [const Size(844, 390), const Size(390, 844)]) {
          tester.view.physicalSize = size;
          await tester.pumpAndSettle();
          expect(find.byType(BuyV2Screen), findsOneWidget);
          expect(
            identical(
              tester.widget<BuyV2Screen>(find.byType(BuyV2Screen)).session,
              screen.session,
            ),
            isTrue,
          );
          expect(screen.session.query, 'milk');
          expect(screen.session.selectedCategoryId, category);
          expect(screen.session.destination, BuyV2Destination.shop);
          expect(
            find.byKey(const Key('mool-navigator-family-buy')),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
          if (round == 0) {
            await _capture(tester, 'c07-route-${size.width.toInt()}');
          }
        }
      }
    },
  );

  testWidgets(
    'C07 rotation cancels an old launcher drag, fresh tap still works',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomLeft,
              child: MoolGlobalNavigationV2(
                activeId: 'buy',
                compact: true,
                onOpenMool: () {},
                onOpenAction: (_) {},
                onOpenChat: null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final launcher = find.byKey(const Key('mool-compact-launcher'));
      final gesture = await tester.startGesture(tester.getCenter(launcher));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      tester.view.physicalSize = const Size(844, 390);
      await tester.pump();
      await gesture.moveBy(const Offset(0, -50));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mool-navigator-family-buy')), findsNothing);
      await tester.tap(launcher);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mool-navigator-family-buy')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
