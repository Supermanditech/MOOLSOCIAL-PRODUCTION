import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_scanner.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

final _forbiddenBuyCopy = RegExp(
  r'\b(?:production|prototype|founder review|review build|sample|example|demo|'
  r'mock|placeholder|working note|internal plan|implementation|workflow|'
  r'state machine|endpoint|payload|backend|provider callback|next screen|'
  r'for (?:review|testing))\b',
  caseSensitive: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    double textScale = 1,
    EdgeInsets safePadding = EdgeInsets.zero,
    bool disableAnimations = false,
    BuyV2ScannerLauncher scannerLauncher = showBuyV2ProductScanner,
  }) {
    return MaterialApp(
      theme: MoolTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(textScale),
            padding: safePadding,
            viewPadding: safePadding,
            disableAnimations: disableAnimations,
          ),
          child: child!,
        );
      },
      home: BuyV2Screen(session: session, scannerLauncher: scannerLauncher),
    );
  }

  testWidgets('persistent dock keeps every Buy destination visible', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    for (final label in [
      'Mool',
      'Shop',
      'Wholesale',
      'Medicine',
      'Orders',
      'Chat',
    ]) {
      expect(
        find.byKey(ValueKey('buy-dock-${label.toLowerCase()}')),
        findsOneWidget,
      );
    }

    await tester.tap(find.byKey(const ValueKey('buy-dock-wholesale')));
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.wholesale);
    expect(
      find.byKey(ValueKey('buy-product-${session.visibleProducts.first.id}')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('buy-dock-shop')), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-dock-medicine')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buy-dock-medicine')));
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.medicine);
    expect(
      find.byKey(ValueKey('buy-product-${session.visibleProducts.first.id}')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('buy-dock-wholesale')), findsOneWidget);
  });

  testWidgets('vertical changes acknowledge work before building the grid', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-dock-medicine')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('buy-destination-progress')),
      findsOneWidget,
    );
    expect(find.text('Opening Medicine'), findsOneWidget);

    await tester.pump();
    expect(
      find.byKey(const ValueKey('buy-destination-progress')),
      findsOneWidget,
    );

    await tester.pump();
    expect(
      find.byKey(const ValueKey('buy-destination-progress')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('buy-product-${session.visibleProducts.first.id}')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('buy-dock-chat')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('buy-destination-progress')),
      findsOneWidget,
    );
    expect(find.text('Opening MoolSocial Assist'), findsOneWidget);

    await tester.pump();
    expect(
      find.byKey(const ValueKey('buy-destination-progress')),
      findsOneWidget,
    );

    await tester.pump();
    expect(
      find.byKey(const ValueKey('buy-destination-progress')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('buy-assist-hero')), findsOneWidget);
  });

  testWidgets('Mool palette stays native and keeps Buy immediately available', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final dockBefore = tester.getRect(
      find.byKey(const ValueKey('buy-dock-mool')),
    );

    await tester.tap(find.byKey(const ValueKey('buy-dock-mool')));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsNothing);
    for (final action in [
      'social',
      'buy',
      'eat',
      'ride',
      'book',
      'pay',
      'work',
    ]) {
      expect(find.byKey(ValueKey('buy-mool-$action')), findsOneWidget);
    }
    final palette = tester.getRect(find.byKey(const ValueKey('buy-mool-buy')));
    expect(palette.top, dockBefore.top);
    expect(palette.bottom, dockBefore.bottom);

    await tester.tap(find.byKey(const ValueKey('buy-mool-buy')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-mool-buy')), findsNothing);
    expect(session.destination, BuyV2Destination.shop);
    expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
  });

  testWidgets(
    'approved Buy shell fits representative small and large devices',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      final session = BuyV2Session(core: BuySession());

      for (final size in const [
        Size(320, 568),
        Size(360, 640),
        Size(360, 800),
        Size(375, 667),
        Size(384, 854),
        Size(390, 844),
        Size(393, 852),
        Size(412, 915),
        Size(430, 932),
        Size(480, 960),
        Size(600, 960),
        Size(768, 1024),
        Size(844, 390),
        Size(932, 430),
        Size(1024, 768),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(app(session));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'viewport $size');
        expect(find.byKey(const ValueKey('buy-dock-medicine')), findsOneWidget);
        expect(find.byKey(const ValueKey('buy-dock-orders')), findsOneWidget);
      }
    },
  );

  testWidgets(
    'discovery hierarchy leads with one horizontal product-image collection',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-featured-products')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-featured-product-list')),
        findsOneWidget,
      );
      final products = session.visibleProducts.take(2).toList();
      final rects = [
        for (final product in products)
          tester.getRect(find.byKey(ValueKey('buy-product-${product.id}'))),
      ];
      expect(rects[0].top, lessThanOrEqualTo(290));
      expect(rects[1].top, rects[0].top);
      expect(rects[0].left, lessThan(rects[1].left));
      final featuredPhoto = find.byKey(
        ValueKey('buy-featured-packshot-${products.first.id}'),
      );
      expect(tester.getSize(featuredPhoto).width, greaterThanOrEqualTo(145));
      expect(tester.getSize(featuredPhoto).height, greaterThanOrEqualTo(110));
      expect(
        find.byKey(const ValueKey('buy-more-products-heading')),
        findsOneWidget,
      );

      final category = session.categories[1];
      expect(find.byKey(const ValueKey('buy-category-rail')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-category-grid')), findsOneWidget);
      final categoryLabel = find.byKey(
        ValueKey('buy-category-label-${category.id}'),
      );
      expect(categoryLabel, findsOneWidget);
      expect(tester.getSize(categoryLabel).width, greaterThanOrEqualTo(70));
      expect(tester.widget<Text>(categoryLabel).textAlign, TextAlign.center);
      expect(
        find.byKey(ValueKey('buy-category-${category.id}')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(ValueKey('buy-category-${category.id}')));
      await tester.pumpAndSettle();
      expect(session.selectedCategoryId, category.id);
      expect(find.byKey(const ValueKey('buy-category-picker')), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-category-grid')), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-catalogue-promotions')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('buy-featured-products')), findsNothing);
      expect(find.byType(BuyV2ProductCard), findsWidgets);
    },
  );

  testWidgets('search expands into a dedicated responsive results owner', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;

    for (final viewport in const [
      (
        size: Size(360, 800),
        safePadding: EdgeInsets.symmetric(vertical: 24),
        label: 'Android 360x800',
      ),
      (
        size: Size(390, 844),
        safePadding: EdgeInsets.only(top: 47, bottom: 34),
        label: 'iOS 390x844',
      ),
      (
        size: Size(430, 932),
        safePadding: EdgeInsets.only(top: 59, bottom: 34),
        label: 'iOS 430x932',
      ),
    ]) {
      tester.view.physicalSize = viewport.size;
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session, safePadding: viewport.safePadding));
      await tester.pumpAndSettle();

      final header = tester.getRect(
        find.byKey(const ValueKey('buy-shared-header')),
      );
      final toolbar = tester.getRect(
        find.byKey(const ValueKey('buy-catalogue-toolbar')),
      );
      final restingSearch = tester.getRect(
        find.byKey(const ValueKey('buy-search-control')),
      );
      final dock = tester.getRect(
        find.byKey(const ValueKey('buy-persistent-dock')),
      );
      final safeBodyHeight =
          viewport.size.height -
          viewport.safePadding.top -
          viewport.safePadding.bottom;
      final topChromeHeight = toolbar.bottom - header.top;
      final productRegionHeight = dock.top - toolbar.bottom;

      expect(
        topChromeHeight / safeBodyHeight,
        lessThanOrEqualTo(.25),
        reason: '${viewport.label} top chrome',
      );
      expect(
        restingSearch.width / viewport.size.width,
        inInclusiveRange(.72, .86),
        reason: '${viewport.label} resting search width',
      );
      expect(
        restingSearch.height,
        44,
        reason: '${viewport.label} resting search target',
      );
      expect(find.byKey(const ValueKey('buy-open-scanner')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      final activeSearch = tester.getRect(
        find.byKey(const ValueKey('buy-search-control')),
      );
      expect(
        activeSearch.width / viewport.size.width,
        greaterThanOrEqualTo(.90),
        reason: '${viewport.label} active search width',
      );
      expect(activeSearch.height, 48);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-search-band')),
          matching: find.byIcon(Icons.arrow_back_rounded),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-search-close')),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('buy-search-close'))).height,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('buy-search-field'))).width /
            activeSearch.width,
        greaterThanOrEqualTo(.60),
        reason: '${viewport.label} active search typing width',
      );
      expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-search-results-surface')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-search-suggestion-list')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('buy-search-ready-card')), findsNothing);
      expect(find.text('Shop suggestions'), findsNothing);
      expect(
        find.text('Find products, brands, sellers and product codes.'),
        findsNothing,
      );
      expect(find.byIcon(Icons.manage_search_rounded), findsNothing);
      expect(find.byIcon(Icons.north_west_rounded), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-search-suggestion-list')),
          matching: find.byIcon(Icons.history_rounded),
        ),
        findsNothing,
      );
      for (var index = 0; index < 4; index++) {
        final suggestion = find.byKey(
          ValueKey('buy-search-suggestion-shop-$index'),
        );
        expect(suggestion, findsOneWidget);
        expect(
          tester.getSize(suggestion).height,
          44,
          reason:
              '${viewport.label} suggestion $index uses the dense accessible target',
        );
      }
      expect(find.byKey(const ValueKey('buy-catalogue-toolbar')), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-catalogue-promotions')),
        findsNothing,
      );
      await tester.enterText(
        find.byKey(const ValueKey('buy-search-field')),
        'milk',
      );
      await tester.pumpAndSettle();
      expect(session.query, 'milk');
      expect(find.textContaining('match'), findsWidgets);
      expect(find.byType(BuyV2ProductCard), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('buy-search-close')));
      await tester.pumpAndSettle();
      expect(session.query, 'milk');
      expect(
        tester.getSize(find.byKey(const ValueKey('buy-search-control'))),
        restingSearch.size,
      );
      expect(
        find.byKey(const ValueKey('buy-catalogue-toolbar')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-clear')));
      await tester.pumpAndSettle();
      expect(session.query, isEmpty);
      expect(
        find.byKey(const ValueKey('buy-search-suggestion-list')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('buy-search-close')));
      await tester.pumpAndSettle();
      expect(
        dock.height / safeBodyHeight,
        lessThanOrEqualTo(.08),
        reason: '${viewport.label} navigation',
      );
      expect(
        productRegionHeight / safeBodyHeight,
        greaterThanOrEqualTo(.67),
        reason: '${viewport.label} product region',
      );
      expect(tester.takeException(), isNull, reason: viewport.label);
    }
  });

  testWidgets(
    'expanded search offers flat separate Shop Wholesale and Medicine lists',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
      ]) {
        session.openDestination(destination);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-search-control')));
        await tester.pumpAndSettle();

        final suggestions = session.searchSuggestions;
        expect(suggestions, hasLength(4), reason: destination.name);
        expect(
          find.byKey(const ValueKey('buy-search-suggestion-list')),
          findsOneWidget,
        );
        expect(find.text('${destination.label} suggestions'), findsNothing);
        final first = find.byKey(
          ValueKey('buy-search-suggestion-${destination.name}-0'),
        );
        expect(first, findsOneWidget);
        expect(tester.getSize(first).height, greaterThanOrEqualTo(44));
        await tester.ensureVisible(first);
        await tester.tap(first);
        await tester.pumpAndSettle();

        expect(session.query, suggestions.first);
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('buy-search-field')))
              .controller
              ?.text,
          suggestions.first,
        );
        expect(session.visibleProducts, isNotEmpty);
        expect(
          session.visibleProducts.every(
            (product) => product.destination == destination,
          ),
          isTrue,
        );
        expect(find.byType(BuyV2ProductCard), findsWidgets);

        await tester.tap(find.byKey(const ValueKey('buy-search-clear')));
        await tester.pumpAndSettle();
        expect(session.query, isEmpty);
        expect(
          find.byKey(ValueKey('buy-search-suggestion-${destination.name}-0')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('buy-search-close')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: destination.name);
      }

      session.openDestination(BuyV2Destination.orders);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Orders suggestions'), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-search-suggestion-list')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('buy-search-suggestion-orders-0')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'responsive search surface is shared across every Buy destination',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      for (final destination in BuyV2Destination.values) {
        session.openDestination(destination);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-open-scanner')),
          destination == BuyV2Destination.orders
              ? findsNothing
              : findsOneWidget,
          reason: '${destination.name} resting scanner owner',
        );
        await tester.tap(find.byKey(const ValueKey('buy-search-control')));
        await tester.pumpAndSettle();

        final activeSearch = tester.getRect(
          find.byKey(const ValueKey('buy-search-control')),
        );
        expect(
          tester.getRect(find.byKey(const ValueKey('buy-search-field'))).width /
              activeSearch.width,
          greaterThanOrEqualTo(.60),
          reason: '${destination.name} typing width at 320 / 140 percent',
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('buy-search-band')),
            matching: find.byIcon(Icons.arrow_back_rounded),
          ),
          findsNothing,
          reason: destination.name,
        );
        expect(find.byKey(const ValueKey('buy-search-close')), findsOneWidget);
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
        expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);

        await tester.enterText(
          find.byKey(const ValueKey('buy-search-field')),
          'a',
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('buy-search-clear')), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const ValueKey('buy-search-clear'))).height,
          greaterThanOrEqualTo(44),
          reason: destination.name,
        );
        await tester.tap(find.byKey(const ValueKey('buy-search-clear')));
        await tester.pumpAndSettle();
        expect(session.query, isEmpty);
        await tester.tap(find.byKey(const ValueKey('buy-search-close')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('buy-search-field')), findsNothing);
        expect(tester.takeException(), isNull, reason: destination.name);
      }

      session.openDestination(BuyV2Destination.shop);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('buy-search-field')),
        'milk',
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-search-field')), findsNothing);
      expect(session.query, 'milk');
      expect(session.destination, BuyV2Destination.shop);

      session.updateQuery('');
      await tester.pumpWidget(
        app(session, textScale: 1.4, disableAnimations: true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pump();
      expect(
        tester.getSize(find.byKey(const ValueKey('buy-search-control'))).height,
        48,
      );
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(const ValueKey('buy-search-band')),
            )
            .duration,
        Duration.zero,
      );
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(const ValueKey('buy-search-control')),
            )
            .duration,
        Duration.zero,
      );
    },
  );

  testWidgets('Account and product depth close the active search owner', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-search-field')),
      'milk',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-search-results-surface')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('buy-open-account')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.account);
    expect(
      find.byKey(const ValueKey('buy-search-results-surface')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('buy-account-orders')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buy-open-account')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.catalogue);
    expect(session.query, 'milk');
    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    final product = session.visibleProducts.first;
    await tester.tap(find.byKey(ValueKey('buy-product-${product.id}')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(
      find.byKey(const ValueKey('buy-search-results-surface')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('buy-product-packshot-${product.id}')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'category action is compact and its first-party feature reuses filters',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      final categoryAction = find.byKey(const ValueKey('buy-category-picker'));
      expect(tester.getSize(categoryAction), const Size(44, 44));
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-owned-feature')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('buy-owned-feature')));
      await tester.pumpAndSettle();
      expect(session.selectedFilter, 'lowest');
      await tester.tap(find.byKey(const ValueKey('buy-owned-feature')));
      await tester.pumpAndSettle();
      expect(session.selectedFilter, isNull);
    },
  );

  testWidgets('MoolSocial brand mark uses a high-contrast white tile', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    final tile = tester.widget<Container>(
      find.byKey(const ValueKey('buy-brand-tile')),
    );
    final decoration = tile.decoration! as BoxDecoration;
    expect(decoration.color, Colors.white);
    expect(
      tester.getSize(find.byKey(const ValueKey('buy-brand-tile'))).height,
      44,
    );
  });

  testWidgets(
    'shared brand and account controls stay in bounds at every depth',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      for (final entry in <(String, VoidCallback)>[
        ('shop', () => session.openDestination(BuyV2Destination.shop)),
        (
          'wholesale',
          () => session.openDestination(BuyV2Destination.wholesale),
        ),
        ('medicine', () => session.openDestination(BuyV2Destination.medicine)),
        ('orders', session.openOrders),
        ('product', () => session.openProduct(product.id)),
        (
          'cart',
          () {
            session.addProduct(product.id);
            session.openCart();
          },
        ),
        ('checkout', session.openCheckout),
        ('tracking', () => session.openTracking('MS-240782')),
        ('assist', session.openAssist),
        ('account', session.openAccount),
      ]) {
        entry.$2();
        await tester.pumpAndSettle();
        final header = tester.getRect(
          find.byKey(const ValueKey('buy-shared-header')),
        );
        final brand = tester.getRect(
          find.byKey(const ValueKey('buy-brand-tile')),
        );
        final account = tester.getRect(
          find.byKey(const ValueKey('buy-open-account')),
        );
        expect(header.contains(brand.topLeft), isTrue, reason: entry.$1);
        expect(header.contains(brand.bottomRight), isTrue, reason: entry.$1);
        expect(header.contains(account.topLeft), isTrue, reason: entry.$1);
        expect(header.contains(account.bottomRight), isTrue, reason: entry.$1);
      }
    },
  );

  testWidgets(
    'category glass ends above the dock with only search and separate close',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
      await tester.pumpAndSettle();

      expect(find.text('Find a category'), findsOneWidget);
      expect(find.text('Shop categories'), findsNothing);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('buy-category-search')))
            .height,
        44,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('buy-category-close'))),
        const Size(44, 44),
      );
      final surface = tester.getRect(
        find.byKey(const ValueKey('buy-category-sheet-surface')),
      );
      final dock = tester.getRect(
        find.byKey(const ValueKey('buy-persistent-dock')),
      );
      expect((surface.bottom - dock.top).abs(), lessThanOrEqualTo(1));
      expect(
        find.byKey(ValueKey('buy-product-${session.visibleProducts.first.id}')),
        findsOneWidget,
      );
    },
  );

  test('every approved Buy category has a specific visual icon', () {
    final categories = {
      ...BuyV2Catalogue.shopCategories,
      ...BuyV2Catalogue.wholesaleCategories,
      ...BuyV2Catalogue.medicineCategories,
    };
    for (final category in categories) {
      expect(
        buyV2CategoryIconFor(category.id),
        isNot(Icons.category_outlined),
        reason: category.id,
      );
    }
  });

  testWidgets(
    'category selector fits 320 at 140 percent and finds a late category',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
      await tester.pumpAndSettle();
      final categoryGrid = find.byKey(const ValueKey('buy-category-grid'));
      expect(categoryGrid, findsOneWidget);
      expect(
        tester.widget<GridView>(categoryGrid).scrollDirection,
        Axis.vertical,
      );
      expect(find.byKey(const ValueKey('buy-category-rail')), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey('buy-category-search')),
        'shop supplies',
      );
      await tester.pumpAndSettle();
      final lateCategory = find.byKey(
        const ValueKey('buy-category-shop-supplies'),
      );
      expect(lateCategory, findsOneWidget);
      expect(tester.getSize(lateCategory).height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'catalogue keeps vertical discovery and lazy horizontal products',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-catalogue-promotions')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-featured-products')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('buy-horizontal-product-grid')),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final horizontalGrid = find.byKey(
        const ValueKey('buy-horizontal-product-grid'),
      );
      final horizontalScrollable = find.descendant(
        of: horizontalGrid,
        matching: find.byType(Scrollable),
      );
      expect(horizontalScrollable, findsNWidgets(2));
      final upperLane = find.byKey(
        const ValueKey('buy-horizontal-product-lane-0'),
      );
      final lowerLane = find.byKey(
        const ValueKey('buy-horizontal-product-lane-1'),
      );
      final upperScrollable = find.descendant(
        of: upperLane,
        matching: find.byType(Scrollable),
      );
      final lowerScrollable = find.descendant(
        of: lowerLane,
        matching: find.byType(Scrollable),
      );
      final upperState = tester.state<ScrollableState>(upperScrollable);
      final lowerState = tester.state<ScrollableState>(lowerScrollable);
      expect(upperState.position.axis, Axis.horizontal);
      expect(lowerState.position.axis, Axis.horizontal);
      expect(upperState.position.pixels, 0);
      expect(lowerState.position.pixels, 0);

      final dockTop = tester
          .getRect(find.byKey(const ValueKey('buy-persistent-dock')))
          .top;
      expect(tester.getRect(horizontalGrid).top, lessThan(dockTop));
      await tester.drag(upperLane, const Offset(-520, 0));
      await tester.pumpAndSettle();
      expect(upperState.position.pixels, greaterThan(0));
      expect(lowerState.position.pixels, 0);
      await tester.drag(lowerLane, const Offset(-520, 0));
      await tester.pumpAndSettle();
      expect(upperState.position.pixels, greaterThan(0));
      expect(lowerState.position.pixels, greaterThan(0));
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is ListView &&
              widget.scrollDirection == Axis.horizontal &&
              widget.childrenDelegate is SliverChildBuilderDelegate,
        ),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('single-product results reserve only one horizontal lane', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    session.updateQuery('Rice and milk baby cereal');
    await tester.pumpAndSettle();

    expect(session.visibleProducts, hasLength(1));
    expect(
      find.byKey(const ValueKey('buy-horizontal-product-lane-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-horizontal-product-lane-1')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('140 percent text keeps navigation reachable', (tester) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (final label in const [
      'Mool',
      'Shop',
      'Wholesale',
      'Medicine',
      'Orders',
      'Chat',
    ]) {
      final cell = find.byKey(ValueKey('buy-dock-${label.toLowerCase()}'));
      final visibleLabel = find.descendant(
        of: cell,
        matching: find.text(label),
      );
      expect(cell, findsOneWidget);
      expect(visibleLabel, findsOneWidget);
      final cellRect = tester.getRect(cell);
      final labelRect = tester.getRect(visibleLabel);
      expect(cellRect.contains(labelRect.topLeft), isTrue, reason: label);
      expect(cellRect.contains(labelRect.bottomRight), isTrue, reason: label);
      expect(
        labelRect.left,
        greaterThanOrEqualTo(cellRect.left + 2),
        reason: '$label left separation',
      );
      expect(
        labelRect.right,
        lessThanOrEqualTo(cellRect.right - 2),
        reason: '$label right separation',
      );
    }
  });

  testWidgets('accessible featured cards keep purchase actions in bounds', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();

    final product = session.visibleProducts.first;
    final card = tester.getRect(
      find.byKey(ValueKey('buy-product-${product.id}')),
    );
    final action = tester.getRect(
      find.byKey(ValueKey('buy-add-${product.id}')),
    );
    expect(action.size, const Size(44, 44));
    expect(card.contains(action.center), isTrue);
    expect(action.right, lessThanOrEqualTo(card.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('destination tool menus remain usable at 140 percent text', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();

    for (final entry in const [
      (BuyV2Destination.shop, 'returns'),
      (BuyV2Destination.wholesale, 'manufacturer'),
      (BuyV2Destination.medicine, 'manufacturer'),
    ]) {
      session.openDestination(entry.$1);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
      await tester.pumpAndSettle();
      final option = find.byKey(ValueKey('buy-filter-${entry.$2}'));
      expect(option, findsOneWidget);
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: entry.$1.label);
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(session.selectedFilter, entry.$2);
      expect(session.visibleProducts, isNotEmpty);
    }
  });

  testWidgets('purchase and navigation actions meet the 44 pixel target', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final product = session.visibleProducts.first;

    final add = find.byKey(ValueKey('buy-add-${product.id}'));
    expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
    for (final key in const [
      ValueKey('buy-dock-mool'),
      ValueKey('buy-dock-shop'),
      ValueKey('buy-dock-wholesale'),
      ValueKey('buy-dock-medicine'),
      ValueKey('buy-dock-orders'),
    ]) {
      expect(tester.getSize(find.byKey(key)).height, greaterThanOrEqualTo(44));
    }
  });

  testWidgets('critical Buy journeys fit compact and large phone widths', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;

    for (final size in const [Size(320, 568), Size(430, 932)]) {
      tester.view.physicalSize = size;
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      final shop = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      final wholesale = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.wholesale,
      );
      final medicine = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.medicine &&
            !item.requiresPrescription,
      );

      for (final action in <VoidCallback>[
        () => session.openDestination(BuyV2Destination.wholesale),
        () => session.openDestination(BuyV2Destination.medicine),
        () => session.openProduct(shop.id),
        () {
          session.addProduct(shop.id);
          session.addProduct(wholesale.id);
          session.addProduct(medicine.id);
          session.openCart();
        },
        session.openCheckout,
        session.openOrders,
        () => session.openTracking('MS-240782'),
        session.openAssist,
      ]) {
        action();
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'critical Buy view at $size',
        );
        expect(find.byKey(const ValueKey('buy-dock-medicine')), findsOneWidget);
      }
    }
  });

  testWidgets('product detail exposes purchase decision information', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.wholesale,
    );
    session.openProduct(product.id);
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: BuyV2Destination.wholesale,
          initialView: BuyV2View.product,
          productId: product.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(product.title), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pack, delivery and seller'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Pack, delivery and seller'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Wholesale terms'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Wholesale terms'), findsOneWidget);
    final primary = find.byKey(ValueKey('buy-product-primary-${product.id}'));
    expect(primary, findsOneWidget);
    expect(
      find.descendant(of: primary, matching: find.byIcon(Icons.add_rounded)),
      findsOneWidget,
    );
    expect(find.text('Add to cart'), findsNothing);
  });

  testWidgets(
    'product detail uses packshot partner role reviews and reporting',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      session.openProduct(product.id);
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey('buy-product-packshot-${product.id}')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Mool Retail Partner'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Mool Retail Partner'), findsOneWidget);
      expect(find.textContaining('Verified'), findsNothing);

      final reviews = find.byKey(ValueKey('buy-product-reviews-${product.id}'));
      await tester.scrollUntilVisible(
        reviews,
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(ValueKey('buy-review-product-${product.id}')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('buy-review-rating-${product.id}-4')),
      );
      await tester.enterText(
        find.byKey(ValueKey('buy-review-comment-${product.id}')),
        'Fresh pack and the delivery promise was clear.',
      );
      await tester.tap(find.byKey(ValueKey('buy-submit-review-${product.id}')));
      await tester.pumpAndSettle();
      expect(
        find.text('Fresh pack and the delivery promise was clear.'),
        findsOneWidget,
      );
      expect(session.customerReviewFor(product.id)?.rating, 4);

      await tester.tap(
        find.byKey(ValueKey('buy-report-product-${product.id}')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-report-reason-0')));
      final submitReport = find.byKey(
        ValueKey('buy-submit-report-${product.id}'),
      );
      await tester.ensureVisible(submitReport);
      await tester.pumpAndSettle();
      await tester.tap(submitReport);
      await tester.pumpAndSettle();
      expect(find.text('Reported'), findsOneWidget);
      expect(session.hasReportedProduct(product.id), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('packshot atlas isolates one exact cell per product', (
    tester,
  ) async {
    final tomato = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.shop &&
          item.canonicalId == 'tomato',
    );
    final rice = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.shop &&
          item.canonicalId == 'rice',
    );
    final medicine = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.medicine &&
          item.visualKind == 'medicine-box',
    );
    final milk = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.shop &&
          item.title.toLowerCase().contains('milk'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            for (final product in [tomato, rice, medicine, milk])
              SizedBox(
                width: 64,
                height: 56,
                child: BuyV2ProductPackshot(product: product),
              ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    Positioned cellFor(BuyV2Product product) {
      final source = BuyV2ProductPackshot.resolveMedia(product)!;
      return tester.widget<Positioned>(
        find.byKey(
          ValueKey(
            'buy-packshot-sprite-${product.id}-'
            '${source.assetPath}-${source.cell}',
          ),
        ),
      );
    }

    final tomatoCell = cellFor(tomato);
    final riceCell = cellFor(rice);
    final medicineCell = cellFor(medicine);
    final milkCell = cellFor(milk);
    expect((tomatoCell.left, tomatoCell.top), (0, 0));
    expect((riceCell.left, riceCell.top), (-64, 0));
    expect((medicineCell.left, medicineCell.top), (0, 0));
    expect((milkCell.left, milkCell.top), (-128, -56));
    for (final cell in [tomatoCell, riceCell, medicineCell, milkCell]) {
      expect(cell.width, 256);
      expect(cell.height, 168);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'every seeded product resolves to exact or truthful category media',
    (tester) async {
      final eggs = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.shop &&
            item.canonicalId == 'eggs',
      );
      final resolutions = {
        for (final product in BuyV2Catalogue.products)
          product.id: BuyV2ProductPackshot.resolveMedia(product),
      };
      expect(resolutions.values, isNot(contains(null)));
      expect(
        resolutions.values.where(
          (source) => source?.kind == BuyV2ProductMediaKind.exactProduct,
        ),
        isNotEmpty,
      );
      expect(
        resolutions.values.where(
          (source) => source?.kind == BuyV2ProductMediaKind.category,
        ),
        isNotEmpty,
      );
      final eggsSource = resolutions[eggs.id]!;
      expect(eggsSource.kind, BuyV2ProductMediaKind.category);
      expect(eggsSource.assetPath, BuyV2ProductPackshot.categoryAtlasAPath);
      expect(eggsSource.cell, 2);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 86,
            height: 64,
            child: BuyV2ProductPackshot(product: eggs),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey('buy-product-media-fallback-${eggs.id}')),
        findsNothing,
      );
      expect(
        find.byKey(
          ValueKey(
            'buy-packshot-sprite-${eggs.id}-'
            '${eggsSource.assetPath}-${eggsSource.cell}',
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'featured products lead with a dominant photo and keep dense filtered grids',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      final product = session.visibleProducts.first;
      final photo = find.byKey(ValueKey('buy-featured-packshot-${product.id}'));
      expect(photo, findsOneWidget);
      expect(tester.getSize(photo).width, greaterThanOrEqualTo(145));
      expect(tester.getSize(photo).height, greaterThanOrEqualTo(110));

      await tester.tap(find.byKey(ValueKey('buy-add-${product.id}')));
      await tester.pumpAndSettle();
      expect(session.quantityFor(product.id), 1);
      expect(
        find.byKey(ValueKey('buy-quantity-${product.id}')),
        findsOneWidget,
      );

      session.chooseCategory(product.categoryId);
      await tester.pumpAndSettle();
      final densePhoto = find.byKey(
        ValueKey('buy-grid-packshot-${product.id}'),
      );
      expect(densePhoto, findsOneWidget);
      expect(tester.getSize(densePhoto), const Size(86, 64));
      expect(find.byType(BuyV2ProductCard), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('featured press and quantity motion respect reduced motion', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, disableAnimations: true));
    await tester.pumpAndSettle();

    final product = session.visibleProducts.first;
    final animatedCard = find.byKey(
      ValueKey('buy-featured-product-${product.id}'),
    );
    expect(tester.widget<AnimatedScale>(animatedCard).duration, Duration.zero);

    await tester.tap(find.byKey(ValueKey('buy-add-${product.id}')));
    await tester.pump();
    expect(session.quantityFor(product.id), 1);
    expect(find.byKey(ValueKey('buy-quantity-${product.id}')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('product detail keeps a large upload-ready media tile', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openProduct(product.id);
    await tester.pumpAndSettle();

    final gallery = find.byKey(ValueKey('buy-product-gallery-${product.id}'));
    final firstImage = find.byKey(
      const ValueKey('buy-product-gallery-image-0'),
    );
    expect(gallery, findsOneWidget);
    expect(tester.getSize(firstImage).width, greaterThanOrEqualTo(270));
    expect(tester.getSize(firstImage).height, greaterThanOrEqualTo(180));
    expect(
      find.byKey(const ValueKey('buy-product-gallery-count')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('buy-product-gallery-dot-0')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tracking Items opens an order item and returns to that order', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openTracking('MS-240782');
    await tester.pumpAndSettle();

    final itemsAction = find.text('Items');
    await tester.scrollUntilVisible(
      itemsAction,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(itemsAction);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.orderItems);
    expect(
      find.byKey(const ValueKey('buy-order-items-MS-240782')),
      findsOneWidget,
    );
    final product = session.productsForOrder(session.selectedOrder).first;
    await tester.tap(find.byKey(ValueKey('buy-order-product-${product.id}')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, product.id);

    session.goBack();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.orderItems);
    expect(session.selectedOrder.id, 'MS-240782');
  });

  testWidgets(
    'Shop Wholesale and Medicine details fit compact Android and iOS sizes',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      for (final viewport in const [
        Size(320, 568),
        Size(390, 844),
        Size(430, 932),
      ]) {
        tester.view.physicalSize = viewport;
        for (final destination in const [
          BuyV2Destination.shop,
          BuyV2Destination.wholesale,
          BuyV2Destination.medicine,
        ]) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          final session = BuyV2Session(core: BuySession());
          final product = BuyV2Catalogue.products.firstWhere(
            (item) =>
                item.destination == destination && !item.requiresPrescription,
          );
          await tester.pumpWidget(app(session, textScale: 1.4));
          await tester.pumpAndSettle();
          session.openProduct(product.id);
          await tester.pumpAndSettle();

          expect(
            find.byKey(ValueKey('buy-product-packshot-${product.id}')),
            findsOneWidget,
            reason: '$destination at $viewport',
          );
          await tester.scrollUntilVisible(
            find.text(product.partnerRole),
            140,
            scrollable: find.byType(Scrollable).first,
          );
          expect(
            find.text(product.partnerRole),
            findsOneWidget,
            reason: '$destination at $viewport',
          );
          expect(find.textContaining('Verified'), findsNothing);
          await tester.scrollUntilVisible(
            find.byKey(ValueKey('buy-product-reviews-${product.id}')),
            180,
            scrollable: find.byType(Scrollable).first,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$destination at $viewport',
          );
        }
      }
    },
  );

  testWidgets('DC and Chat repeat taps return to the exact purchase depth', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.wholesale,
    );
    await tester.pumpWidget(app(session));
    session.openProduct(product.id);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-open-account')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.account);
    await tester.tap(find.byKey(const ValueKey('buy-open-account')));
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.wholesale);
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, product.id);

    session.openTracking('MS-240782');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-dock-chat')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.assist);
    await tester.tap(find.byKey(const ValueKey('buy-dock-chat')));
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.orders);
    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, 'MS-240782');
  });

  testWidgets(
    'Account Orders Prescription and Wholesale actions complete and return',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-open-account')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Verified'), findsNothing);
      expect(find.textContaining('VERIFIED'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('buy-account-orders')));
      await tester.pumpAndSettle();
      expect(session.destination, BuyV2Destination.orders);
      expect(session.canReturnToAccount, isTrue);
      final ordersReturn = find.byKey(
        const ValueKey('buy-orders-return-account'),
      );
      await tester.tapAt(
        tester.getTopLeft(ordersReturn) + const Offset(24, 20),
      );
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.account);

      await tester.tap(find.byKey(const ValueKey('buy-account-prescriptions')));
      await tester.pumpAndSettle();
      final addPrescription = find.byKey(
        const ValueKey('buy-prescription-add-new'),
      );
      expect(addPrescription, findsOneWidget);
      expect(tester.getSize(addPrescription).height, greaterThanOrEqualTo(44));
      await tester.tap(addPrescription);
      await tester.pumpAndSettle();
      expect(session.prescriptionAttached, isTrue);
      expect(session.approvedPrescriptionProductCount, 3);
      expect(find.text('3 matched medicines available'), findsOneWidget);

      final wholesaleWorkspace = find.byKey(
        const ValueKey('buy-account-workspace'),
      );
      await tester.ensureVisible(wholesaleWorkspace);
      await tester.tap(wholesaleWorkspace);
      await tester.pumpAndSettle();
      expect(session.destination, BuyV2Destination.wholesale);
      expect(session.view, BuyV2View.catalogue);
      expect(
        find.byKey(const ValueKey('buy-catalogue-return-account')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-catalogue-return-account')),
      );
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.account);

      await tester.tap(find.byKey(const ValueKey('buy-open-account')));
      await tester.pumpAndSettle();
      expect(session.destination, BuyV2Destination.shop);
      expect(session.view, BuyV2View.catalogue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('each Buy vertical category uses lazy horizontal products', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    for (final destination in const [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ]) {
      session.openDestination(destination);
      final category = session.categories.firstWhere(
        (item) => item.id != 'all',
      );
      session.chooseCategory(category.id);
      await tester.pumpAndSettle();

      final horizontalGrid = find.byKey(
        const ValueKey('buy-horizontal-product-grid'),
      );
      expect(horizontalGrid, findsOneWidget, reason: destination.name);
      final scrollable = find.descendant(
        of: horizontalGrid,
        matching: find.byType(Scrollable),
      );
      expect(scrollable, findsWidgets, reason: destination.name);
      for (final element in scrollable.evaluate()) {
        expect(
          tester
              .state<ScrollableState>(
                find.byElementPredicate(
                  (candidate) => identical(candidate, element),
                ),
              )
              .position
              .axis,
          Axis.horizontal,
          reason: destination.name,
        );
      }
      expect(tester.takeException(), isNull, reason: destination.name);
    }
  });

  testWidgets('catalogue plus becomes an inline quantity stepper and returns', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final product = session.visibleProducts.first;
    final add = find.byKey(ValueKey('buy-add-${product.id}'));

    expect(find.text('ADD'), findsNothing);
    expect(
      find.descendant(of: add, matching: find.byIcon(Icons.add_rounded)),
      findsOneWidget,
    );
    await tester.tap(add);
    await tester.pumpAndSettle();
    final quantity = find.byKey(ValueKey('buy-quantity-${product.id}'));
    expect(quantity, findsOneWidget);
    expect(session.quantityFor(product.id), 1);

    await tester.tap(
      find.descendant(of: quantity, matching: find.byTooltip('Remove one')),
    );
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), 0);
    expect(add, findsOneWidget);
  });

  testWidgets('product and Cart keep plus and minus quantity controls', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    session.openProduct(product.id);
    await tester.pumpAndSettle();

    final primary = find.byKey(ValueKey('buy-product-primary-${product.id}'));
    await tester.tap(primary);
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('buy-product-quantity-${product.id}')),
      findsOneWidget,
    );

    session.openCart(scope: BuyV2CartScope.shop);
    await tester.pumpAndSettle();
    final line = find.byKey(ValueKey('buy-cart-line-${product.id}'));
    expect(line, findsOneWidget);
    await tester.tap(
      find.descendant(of: line, matching: find.byTooltip('Add one')),
    );
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), 2);
    await tester.tap(
      find.descendant(of: line, matching: find.byTooltip('Remove one')),
    );
    await tester.pumpAndSettle();
    expect(session.quantityFor(product.id), 1);
  });

  testWidgets('add confirmation is owned by the Cart bar, not the top toast', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );

    session.addProduct(product.id);
    await tester.pump();

    expect(session.notice, isNull);
    expect(session.cartAcknowledgement, '${product.title} added · 1 item');
    expect(
      find.byKey(const ValueKey('buy-cart-acknowledgement')),
      findsOneWidget,
    );
    expect(find.text(session.cartAcknowledgement!), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-live-notice')), findsNothing);
  });

  testWidgets('non-empty Cart becomes a prominent reserved conversion bar', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    session.addProduct(product.id);
    await tester.pump();

    final miniCart = find.byKey(const ValueKey('buy-compact-cart-indicator'));
    expect(miniCart, findsOneWidget);
    expect(tester.getSize(miniCart).height, greaterThanOrEqualTo(64));
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('${product.title} added · 1 item'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pumpAndSettle();
    expect(find.text('1 item ready'), findsOneWidget);
    expect(find.text('View cart'), findsOneWidget);
    expect(find.text(buyV2Money(session.cartTotal)), findsWidgets);

    await tester.tap(miniCart);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    expect(miniCart, findsNothing);
  });

  testWidgets(
    'Cart stays aggregate across Shop Wholesale Medicine and Orders',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      final shop = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.shop,
      );
      final wholesale = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == BuyV2Destination.wholesale,
      );
      final medicine = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.medicine &&
            !item.requiresPrescription,
      );
      session.addProduct(shop.id);
      session.addProduct(wholesale.id);
      session.addProduct(medicine.id);
      session.clearCartAcknowledgement();
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      session.openDestination(BuyV2Destination.wholesale);
      await tester.pumpAndSettle();
      expect(find.text('Cart'), findsOneWidget);
      expect(
        find.text(
          '${session.itemCount} '
          '${session.itemCount == 1 ? 'item' : 'items'} ready',
        ),
        findsOneWidget,
      );
      expect(find.text(buyV2Money(session.cartTotal)), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('buy-compact-cart-indicator')),
      );
      await tester.pumpAndSettle();
      expect(session.cartScope, BuyV2CartScope.all);
      expect(session.cartLines, hasLength(3));

      session.openDestination(BuyV2Destination.orders);
      await tester.pumpAndSettle();
      expect(find.text('Cart'), findsOneWidget);
      expect(
        find.text(
          '${session.itemCount} '
          '${session.itemCount == 1 ? 'item' : 'items'} ready',
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-compact-cart-indicator')),
      );
      await tester.pumpAndSettle();
      expect(session.cartScope, BuyV2CartScope.all);
      expect(session.cartLines, hasLength(3));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'compact brand and Cart total remain whole at 320 and 140 percent',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      final products = BuyV2Catalogue.products
          .where((item) => item.destination == BuyV2Destination.shop)
          .take(2);
      for (final product in products) {
        session.addProduct(product.id);
      }
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      final brand = find.text('MoolSocial · Deliver to');
      expect(brand, findsOneWidget);
      final brandMark = find.byKey(const ValueKey('buy-brand-mark'));
      expect(brandMark, findsOneWidget);
      final brandMarkSize = tester.getSize(brandMark);
      expect(brandMarkSize, const Size(32, 24));
      expect(
        brandMarkSize.width / brandMarkSize.height,
        greaterThanOrEqualTo(1.3),
      );
      final brandRect = tester.getRect(brand);
      final headerRect = tester.getRect(
        find.byKey(const ValueKey('buy-shared-header')),
      );
      expect(headerRect.contains(brandRect.topLeft), isTrue);
      expect(headerRect.contains(brandRect.bottomRight), isTrue);

      session.openCart();
      await tester.pumpAndSettle();
      final actionBar = find.byKey(const ValueKey('buy-cart-action-bar'));
      final total = find.descendant(
        of: actionBar,
        matching: find.text(buyV2Money(session.scopedCartTotal)),
      );
      expect(total, findsOneWidget);
      expect(tester.widget<Text>(total).maxLines, 1);
      final actionRect = tester.getRect(actionBar);
      final totalRect = tester.getRect(total);
      expect(actionRect.contains(totalRect.topLeft), isTrue);
      expect(actionRect.contains(totalRect.bottomRight), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('saved destination and payment remain separate decisions', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.addProduct(product.id);
    session.openCheckout();
    session.clearNotice();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-saved-address-reminder')),
      findsOneWidget,
    );
    expect(find.text('Delivering to Home'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Payment · UPI'), findsOneWidget);
    expect(find.textContaining('Delivery & payment'), findsNothing);
    expect(find.textContaining('delivery and payment'), findsNothing);
  });

  testWidgets('tracking shows live progress, next step and working alerts', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openTracking('MS-240782');
    await tester.pumpAndSettle();

    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('54%'), findsOneWidget);
    expect(find.text('NOW'), findsOneWidget);
    expect(find.text('What happens next'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('buy-tracking-alerts')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Order updates'), findsOneWidget);
    expect(find.text('Live status alerts are on'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buy-tracking-alerts-toggle')));
    await tester.pump();
    expect(session.trackingAlertsEnabled, isFalse);
    expect(find.text('Live status alerts are paused'), findsOneWidget);
  });

  testWidgets('compact cart never covers tracking or support actions', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    session.addProduct(product.id);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    session.openTracking('MS-240782');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Help'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Help'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-compact-cart-indicator')),
      findsNothing,
    );

    session.openAssist();
    await tester.pumpAndSettle();
    expect(find.text('Chat in app'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-compact-cart-indicator')),
      findsNothing,
    );
  });

  testWidgets(
    'Buy Chat presents order progress honest intents and secure channels',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();

      session.openAssist();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('buy-assist-hero')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('buy-assist-current-order')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-assist-order-progress')),
        findsOneWidget,
      );
      expect(find.textContaining('% complete'), findsOneWidget);

      final intent = find.byKey(
        const ValueKey('buy-assist-intent-Where is my order?'),
      );
      await tester.ensureVisible(intent);
      await tester.tap(intent);
      await tester.pumpAndSettle();
      expect(find.textContaining('selected. Add details'), findsOneWidget);

      final prepare = find.byKey(const ValueKey('buy-assist-prepare-question'));
      expect(tester.widget<IconButton>(prepare).onPressed, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('buy-assist-composer-field')),
        'The delivery time changed',
      );
      await tester.pump();
      expect(tester.widget<IconButton>(prepare).onPressed, isNotNull);
      await tester.tap(prepare);
      await tester.pump();
      expect(
        session.notice,
        'Question ready. Choose Chat in app to continue securely.',
      );

      final chat = find.byKey(const ValueKey('buy-assist-channel-Chat in app'));
      final call = find.byKey(const ValueKey('buy-assist-channel-Call in app'));
      expect(chat, findsOneWidget);
      expect(call, findsOneWidget);
      expect(tester.getSize(chat).height, greaterThanOrEqualTo(44));
      expect(tester.getSize(call).height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cart item count uses correct singular and plural copy', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final products = BuyV2Catalogue.products
        .where((item) => item.destination == BuyV2Destination.shop)
        .take(2)
        .toList();
    session.addProduct(products.first.id);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openCart();
    await tester.pumpAndSettle();

    expect(find.textContaining('1 product ·'), findsOneWidget);
    expect(find.textContaining('1 products'), findsNothing);

    session.addProduct(products.last.id);
    await tester.pumpAndSettle();
    expect(find.textContaining('2 products ·'), findsOneWidget);
  });

  testWidgets('Buy prices use locked Indian currency grouping', (tester) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openOrders();
    await tester.pumpAndSettle();

    expect(find.text('₹4,839'), findsOneWidget);
    expect(find.text('₹4,200'), findsOneWidget);
    expect(find.text('₹4839'), findsNothing);
    expect(find.text('₹4200'), findsNothing);
  });

  testWidgets('order card body performs its advertised primary action', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openOrders();
    await tester.pumpAndSettle();

    final activeCard = find.byKey(const ValueKey('buy-order-card-MS-240782'));
    final activeRect = tester.getRect(activeCard);
    await tester.tapAt(activeRect.topLeft + const Offset(60, 60));
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, 'MS-240782');

    session.openOrders();
    session.showOrdersTab(BuyV2OrdersTab.delivered);
    await tester.pumpAndSettle();
    final deliveredCard = find.byKey(
      const ValueKey('buy-order-card-MS-240741'),
    );
    final deliveredRect = tester.getRect(deliveredCard);
    await tester.tapAt(deliveredRect.topLeft + const Offset(60, 60));
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.cart);
    expect(session.cartScope, BuyV2CartScope.shop);
    expect(session.cartLines, isNotEmpty);
  });

  testWidgets('Orders opens at the top after Checkout was scrolled', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.addProduct(product.id);
    session.openCheckout();
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-dock-orders')));
    await tester.pumpAndSettle();

    expect(find.text('PURCHASES'), findsOneWidget);
    expect(find.text('Orders'), findsWidgets);
    expect(find.text('Active'), findsWidgets);
  });

  testWidgets('saved and product-code header actions complete visibly', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    var scannerCalls = 0;
    final scannedProduct = session.visibleProducts.last;
    await tester.pumpWidget(
      app(
        session,
        scannerLauncher: (_) async {
          scannerCalls += 1;
          return scannedProduct.id;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-saved-products-button')));
    await tester.pumpAndSettle();
    final savedProduct = session.savedProductsFor(BuyV2Destination.shop).first;
    expect(find.byType(BottomSheet), findsNothing);
    await tester.tap(find.byKey(ValueKey('buy-product-${savedProduct.id}')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);

    session.returnToCatalogue();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-open-scanner')));
    await tester.pumpAndSettle();

    expect(scannerCalls, 1);
    expect(session.query, scannedProduct.id);
    expect(session.selectedProductId, scannedProduct.id);
    expect(session.view, BuyV2View.product);
  });

  testWidgets('scanner shows genuine progress and blocks repeated launch', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final scannedProduct = session.visibleProducts.first;
    final result = Completer<String?>();
    var scannerCalls = 0;
    await tester.pumpWidget(
      app(
        session,
        scannerLauncher: (_) {
          scannerCalls += 1;
          return result.future;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-open-scanner')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(scannerCalls, 1);

    await tester.tap(find.byKey(const ValueKey('buy-open-scanner')));
    await tester.pump();
    expect(scannerCalls, 1);

    result.complete(scannedProduct.id);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(session.selectedProductId, scannedProduct.id);
    expect(session.view, BuyV2View.product);
  });

  testWidgets('products save at the grid and appear in the Saved owner', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final product = session.visibleProducts.first;
    if (session.isSaved(product.id)) {
      session.toggleSaved(product.id);
    }
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    final card = find.byKey(ValueKey('buy-product-${product.id}'));
    final save = find.byKey(ValueKey('buy-save-${product.id}'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    expect(tester.getRect(card).contains(tester.getCenter(save)), isTrue);

    await tester.tap(save);
    await tester.pump();
    expect(session.isSaved(product.id), isTrue);
    final notice = find.byKey(const ValueKey('buy-live-notice'));
    expect(notice, findsOneWidget);
    final noticeRect = tester.getRect(notice);
    final contentRight = tester
        .getRect(find.byKey(const ValueKey('buy-shared-header')))
        .right;
    expect(noticeRect.width, lessThanOrEqualTo(248));
    expect(noticeRect.right, contentRight - 8);

    await tester.tap(find.byKey(const ValueKey('buy-saved-products-button')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byKey(ValueKey('buy-product-${product.id}')), findsOneWidget);
  });

  testWidgets('category and search actions cannot strand the Saved grid', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-category-rail')), findsNothing);
    expect(find.byKey(const ValueKey('buy-category-picker')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-category-search')),
      'shop supplies',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-category-shop-supplies')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('buy-category-shop-supplies')));
    await tester.pumpAndSettle();
    expect(session.selectedCategoryId, 'shop-supplies');
    expect(find.byKey(const ValueKey('buy-category-grid')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-search-field')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-search-results-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-saved-products-button')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('buy-search-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-saved-products-button')));
    await tester.pumpAndSettle();
    for (final product in session.savedProductsFor(BuyV2Destination.shop)) {
      expect(find.byKey(ValueKey('buy-product-${product.id}')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual scanner recovery is compact and returns a code', (
    tester,
  ) async {
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showBuyV2ManualCodeSheet(context);
              },
              child: const Text('Open scanner fallback'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open scanner fallback'));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSize(find.byKey(const ValueKey('buy-manual-code-panel')))
          .height,
      lessThanOrEqualTo(238),
    );
    await tester.enterText(
      find.byKey(const ValueKey('buy-product-code-field')),
      'shop-atta',
    );
    await tester.tap(find.byKey(const ValueKey('buy-use-product-code')));
    await tester.pumpAndSettle();
    expect(result, 'shop-atta');
  });

  testWidgets(
    'featured card exposes seller context and a stable purchase action',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      final product = session.visibleProducts.first;
      final card = find.byKey(ValueKey('buy-product-${product.id}'));
      final add = find.byKey(ValueKey('buy-add-${product.id}'));
      final seller = find.textContaining(product.seller);

      expect(add, findsOneWidget);
      expect(seller, findsWidgets);
      final cardRect = tester.getRect(card);
      expect(cardRect.contains(tester.getCenter(add)), isTrue);
      expect(cardRect.contains(tester.getCenter(seller.last)), isTrue);
      expect(tester.getSize(add), const Size(44, 44));
    },
  );

  testWidgets('checkout renders only the fulfilment families being purchased', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final shop = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.addProduct(shop.id);
    session.openCart(scope: BuyV2CartScope.shop);
    session.openCheckout();
    await tester.pumpAndSettle();

    expect(find.textContaining('Shop fulfilment ·'), findsOneWidget);
    expect(find.textContaining('Wholesale fulfilment ·'), findsNothing);
    expect(find.textContaining('Medicine fulfilment ·'), findsNothing);
  });

  testWidgets(
    'order confirmation preserves family identifiers then opens Orders',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      final products = [
        BuyV2Catalogue.products.firstWhere(
          (item) => item.destination == BuyV2Destination.shop,
        ),
        BuyV2Catalogue.products.firstWhere(
          (item) => item.destination == BuyV2Destination.wholesale,
        ),
      ];
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      for (final product in products) {
        session.addProduct(product.id);
      }
      session.openCart();
      session.openCheckout();
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Place order'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('buy-confirmation')), findsOneWidget);
      expect(find.text('Shop order confirmed'), findsOneWidget);
      expect(find.text('Wholesale order confirmed'), findsOneWidget);
      expect(find.text('Medicine order confirmed'), findsNothing);
      expect(
        find.textContaining(session.confirmedOrders.first.partner),
        findsWidgets,
      );

      await tester.tap(find.byKey(const ValueKey('buy-confirmation-orders')));
      await tester.pumpAndSettle();
      expect(find.text('PURCHASES'), findsOneWidget);
      expect(
        find.textContaining(session.confirmedOrders.first.id),
        findsWidgets,
      );
    },
  );

  testWidgets('delivered Orders are reachable and expose one Reorder action', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openOrders();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-orders-tab-delivered')));
    await tester.pumpAndSettle();

    expect(session.ordersTab, BuyV2OrdersTab.delivered);
    expect(find.text('Delivered'), findsWidgets);
    expect(find.text('Reorder'), findsWidgets);
    expect(find.text('Track order'), findsNothing);
  });

  testWidgets('shared search filters Orders by an existing order ID', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.orders);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-search-band')), findsOneWidget);
    expect(find.text('Search orders, sellers or ID'), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-search-field')),
      'MS-240782',
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-order-card-MS-240782')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-order-card-MS-240783')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('buy-order-card-MS-240784')),
      findsNothing,
    );
  });

  testWidgets('first-party promotions use established Buy actions', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-promotion-shop-basket')));
    await tester.pumpAndSettle();
    expect(find.text('Monthly home basket'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.wholesale);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-promotion-wholesale-restock')),
    );
    await tester.pumpAndSettle();
    expect(session.selectedFilter, 'moq');

    session.openDestination(BuyV2Destination.medicine);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-promotion-medicine-prescription')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Prescription centre'), findsWidgets);
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.orders);
    await tester.pumpAndSettle();
    final firstOrder = session.visibleOrders.first;
    expect(
      find.byKey(ValueKey('buy-order-card-${firstOrder.id}')),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('buy-orders-promotions')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('buy-orders-promotions')), findsOneWidget);
  });

  testWidgets(
    'promotion and featured product remain usable at 320 and 140 percent',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-catalogue-promotions')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-featured-products')),
        findsOneWidget,
      );
      final product = session.visibleProducts.first;
      final dockTop = tester
          .getRect(find.byKey(const ValueKey('buy-persistent-dock')))
          .top;
      final rect = tester.getRect(
        find.byKey(ValueKey('buy-product-${product.id}')),
      );
      expect(rect.top, lessThan(dockTop));
      expect(dockTop - rect.top, greaterThanOrEqualTo(180));
      final action = tester.getRect(
        find.byKey(ValueKey('buy-add-${product.id}')),
      );
      expect(action.size, const Size(44, 44));
      expect(rect.contains(action.center), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('all six recovery states fit and return without an extra page', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();

    for (final kind in BuyV2RecoveryKind.values) {
      session.openRecovery(kind);
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('buy-recovery-${kind.name}')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: kind.name);
      await tester.tap(find.byKey(const ValueKey('buy-recovery-primary')));
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.catalogue);
    }
  });

  testWidgets('140 percent text fits every primary Buy state at 320 width', (
    tester,
  ) async {
    final originalErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      debugPrint(details.toString());
      originalErrorHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalErrorHandler);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, textScale: 1.4));
    await tester.pumpAndSettle();

    final shop = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    final medicine = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.medicine &&
          !item.requiresPrescription,
    );
    for (final entry in <(String, VoidCallback)>[
      ('Shop', () => session.openDestination(BuyV2Destination.shop)),
      ('Wholesale', () => session.openDestination(BuyV2Destination.wholesale)),
      ('Medicine', () => session.openDestination(BuyV2Destination.medicine)),
      ('Product', () => session.openProduct(shop.id)),
      (
        'Cart',
        () {
          session.addProduct(shop.id);
          session.addProduct(medicine.id);
          session.openCart();
        },
      ),
      ('Checkout', session.openCheckout),
      ('Confirmation', session.confirmOrder),
      ('Orders', session.openOrders),
      (
        'Delivered Orders',
        () => session.showOrdersTab(BuyV2OrdersTab.delivered),
      ),
      ('Tracking', () => session.openTracking('MS-240782')),
      ('Assist', session.openAssist),
      (
        'Recovery',
        () => session.openRecovery(BuyV2RecoveryKind.networkInterruption),
      ),
    ]) {
      entry.$2();
      await tester.pumpAndSettle();
      final failure = tester.takeException();
      if (failure is FlutterError) {
        debugPrint(failure.toStringDeep());
      }
      expect(failure, isNull, reason: entry.$1);
      expect(find.byKey(const ValueKey('buy-dock-shop')), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-dock-wholesale')), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-dock-medicine')), findsOneWidget);
      expect(find.byKey(const ValueKey('buy-dock-orders')), findsOneWidget);
    }
  });

  testWidgets('every primary Buy state contains only customer-facing copy', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final shop = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    final wholesale = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.wholesale,
    );
    final medicine = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.medicine &&
          !item.requiresPrescription,
    );
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    for (final action in <VoidCallback>[
      () => session.openDestination(BuyV2Destination.shop),
      () => session.openDestination(BuyV2Destination.wholesale),
      () => session.openDestination(BuyV2Destination.medicine),
      () => session.openProduct(shop.id),
      () {
        session.addProduct(shop.id);
        session.addProduct(wholesale.id);
        session.addProduct(medicine.id);
        session.openCart();
      },
      session.openCheckout,
      session.confirmOrder,
      session.openOrders,
      () => session.showOrdersTab(BuyV2OrdersTab.delivered),
      () => session.openTracking('MS-240782'),
      session.openAssist,
      () => session.openRecovery(BuyV2RecoveryKind.paymentFailed),
    ]) {
      action();
      await tester.pumpAndSettle();
      _expectCustomerFacingBuyCopy(tester);
    }
  });
}

void _expectCustomerFacingBuyCopy(WidgetTester tester) {
  final root = find.byKey(const ValueKey('buy-v2-screen'));
  expect(root, findsOneWidget);
  final copy = <String>[];
  for (final text in tester.widgetList<Text>(
    find.descendant(of: root, matching: find.byType(Text)),
  )) {
    copy.add(text.data ?? text.textSpan?.toPlainText() ?? '');
  }
  for (final field in tester.widgetList<TextField>(
    find.descendant(of: root, matching: find.byType(TextField)),
  )) {
    copy.addAll([
      field.decoration?.labelText ?? '',
      field.decoration?.hintText ?? '',
      field.decoration?.helperText ?? '',
    ]);
  }
  for (final semantics in tester.widgetList<Semantics>(
    find.descendant(of: root, matching: find.byType(Semantics)),
  )) {
    copy.add(semantics.properties.label ?? '');
    copy.add(semantics.properties.hint ?? '');
  }
  final visible = copy.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  final match = _forbiddenBuyCopy.firstMatch(visible);
  expect(
    match,
    isNull,
    reason:
        'Forbidden customer-facing wording "${match?.group(0)}". '
        'Visible Buy copy: $visible',
  );
  expect(tester.takeException(), isNull);
}
