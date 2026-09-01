import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_invoice.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_scanner.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

final _forbiddenBuyCopy = RegExp(
  r'\b(?:production|prototype|founder review|review build|sample|example|demo|'
  r'mock|placeholder|working note|internal plan|implementation|workflow|'
  r'state machine|endpoint|payload|backend|provider callback|next screen|'
  r'for (?:review|testing)|source route|product compliance|'
  r'fulfiller assigned|fulfilment|route owner|internal identifier|'
  r'debug build|ui review)\b',
  caseSensitive: false,
);

final class _FixedOffersSource implements BuyV2PublishedOffersSource {
  const _FixedOffersSource(this.publishedOffers);

  @override
  final List<BuyV2PublishedOffer> publishedOffers;
}

final class _LiveOffersSource implements BuyV2LivePublishedOffersSource {
  BuyV2PublishedOffersSnapshot snapshot;
  int calls = 0;

  _LiveOffersSource(this.snapshot);

  @override
  List<BuyV2PublishedOffer> get publishedOffers => snapshot.offers;

  @override
  Future<BuyV2PublishedOffersSnapshot> load() async {
    calls += 1;
    return snapshot;
  }
}

final class _FixedDeliveryPromiseFactsAdapter
    implements BuyV2ProductFactsAdapter {
  const _FixedDeliveryPromiseFactsAdapter(this.deliveryPromise);

  final String deliveryPromise;

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    return const BuyV2CatalogueProductFactsAdapter()
        .snapshotFor(product)
        .copyWith(
          deliveryPromise: deliveryPromise,
          orderabilityLabel: 'Available to add',
          sourceId: 'b01-t02-server-assignment',
          stale: false,
        );
  }
}

final class _T01CMutableDeliveryFactsAdapter
    implements BuyV2ProductFactsAdapter {
  final promises = <BuyV2Destination, (String, String)>{
    BuyV2Destination.shop: ('within 5 min', 'by 6:35 PM'),
    BuyV2Destination.wholesale: ('within 1 day', 'by tomorrow 4:00 PM'),
  };

  void updateShop({required String promise, required String promisedBy}) {
    promises[BuyV2Destination.shop] = (promise, promisedBy);
  }

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    final quote = promises[product.destination];
    return const BuyV2CatalogueProductFactsAdapter()
        .snapshotFor(product)
        .copyWith(
          deliveryPromise: quote?.$1 ?? product.deliveryPromise,
          promisedByLabel: quote?.$2,
          sourceId: 'b01-t01c-ui-quote',
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Finder scrollableWithin(Key ownerKey) => find.descendant(
    of: find.byKey(ownerKey),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up),
    ),
  );

  Widget app(
    BuyV2Session session, {
    double textScale = 1,
    EdgeInsets safePadding = EdgeInsets.zero,
    bool disableAnimations = false,
    BuyV2ScannerLauncher scannerLauncher = showBuyV2ProductScanner,
    VoidCallback? onOpenMool,
    VoidCallback? onOpenChat,
    BuyV2InvoiceDownloader? invoiceDownloader,
    AuthenticatedAccountIdentity? accountIdentity,
    bool accountAuthenticated = false,
    BuyV2PublishedOffersSource offersSource =
        const BuyV2CataloguePublishedOffersSource(),
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
      home: BuyV2Screen(
        session: session,
        accountIdentity: accountIdentity,
        accountAuthenticated: accountAuthenticated,
        scannerLauncher: scannerLauncher,
        onOpenMool: onOpenMool,
        onOpenChat: onOpenChat,
        invoiceDownloader: invoiceDownloader,
        offersSource: offersSource,
        onOpenMainAction: (action) {
          final uri = Uri.parse(action.route);
          if (uri.path != '/app/buy') return;
          switch (uri.queryParameters['sub']) {
            case 'wholesale':
              session.openDestination(BuyV2Destination.wholesale);
              return;
            case 'medicine':
              session.openDestination(BuyV2Destination.medicine);
              return;
            case 'orders':
              session.openOrders();
              return;
            default:
              session.openDestination(BuyV2Destination.shop);
              return;
          }
        },
      ),
    );
  }

  testWidgets('persistent Buy navigation preserves one destination surface', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-local-destination-tabs')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-wholesale')));
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.wholesale);
    expect(
      find.byKey(ValueKey('buy-product-${session.visibleProducts.first.id}')),
      findsOneWidget,
    );
    session.openDestination(BuyV2Destination.medicine);
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.medicine);
    expect(
      find.byKey(ValueKey('buy-product-${session.visibleProducts.first.id}')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
  });

  testWidgets('vertical changes transition the real surface without a wait', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    session.openDestination(BuyV2Destination.medicine);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('buy-destination-progress')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('buy-navigation-surface-current')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-navigation-surface-outgoing')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('buy-product-${session.visibleProducts.first.id}')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('buy-shared-header')), findsNothing);
    expect(
      find.byKey(const ValueKey('buy-local-destination-tabs')),
      findsNothing,
    );

    await tester.pumpAndSettle();

    final settledSequence = session.navigationMotionSequence;
    session.openDestination(BuyV2Destination.medicine);
    await tester.pump();
    expect(session.navigationMotionSequence, settledSequence);
    expect(
      find.byKey(const ValueKey('buy-navigation-surface-outgoing')),
      findsNothing,
    );

    session.openOrders();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-orders-assist')), findsNothing);
    session.openAssist();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('buy-destination-progress')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('buy-assist-hero')), findsNothing);
    expect(
      find.byKey(PageStorageKey('buy-tracking-${session.assistOrder.id}')),
      findsOneWidget,
    );
    expect(
      session.navigationMotionDirection,
      BuyV2NavigationMotionDirection.forward,
    );
  });

  testWidgets('MoolSocial opens connected actions without replacing Buy', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    var moolTaps = 0;
    await tester.pumpWidget(app(session, onOpenMool: () => moolTaps += 1));
    await tester.pumpAndSettle();
    session.openDestination(BuyV2Destination.medicine);
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.medicine);

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();

    expect(moolTaps, 0);
    expect(session.destination, BuyV2Destination.medicine);
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.byKey(const ValueKey('mool-connected-action-navigator')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mool-navigator-family-buy')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('buy-mool-social')), findsNothing);
    expect(find.byKey(const ValueKey('buy-mool-buy')), findsNothing);
    expect(find.text('Pay'), findsNothing);
    await tester.drag(
      find.byKey(const Key('mool-connected-action-navigator-drag-surface')),
      const Offset(0, 80),
    );
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.medicine);
    expect(
      find.byKey(const ValueKey('mool-connected-action-navigator')),
      findsNothing,
    );
    expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
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
        expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
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
      expect(
        rects[0].top,
        lessThanOrEqualTo(304),
        reason: 'the expanded motion stage must remain compact',
      );
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

      final searchBand = tester.getRect(
        find.byKey(const ValueKey('buy-search-band')),
      );
      final toolbar = tester.getRect(
        find.byKey(const ValueKey('buy-catalogue-toolbar')),
      );
      final restingSearch = tester.getRect(
        find.byKey(const ValueKey('buy-search-control')),
      );
      final dock = tester.getRect(
        find.byKey(const Key('moolsocial-compact-destination-rail')),
      );
      final dockSurface = tester.getRect(
        find.byKey(const Key('mool-compact-launcher')),
      );
      final safeBodyHeight =
          viewport.size.height -
          viewport.safePadding.top -
          viewport.safePadding.bottom;
      final topChromeHeight = toolbar.bottom - searchBand.top;
      final productRegionHeight = dock.top - toolbar.bottom;

      expect(
        searchBand.top,
        viewport.safePadding.top,
        reason: '${viewport.label} search starts at the safe-area top',
      );

      expect(
        topChromeHeight / safeBodyHeight,
        lessThanOrEqualTo(.25),
        reason: '${viewport.label} top chrome',
      );
      expect(
        restingSearch.width / viewport.size.width,
        inInclusiveRange(.65, .76),
        reason:
            '${viewport.label} resting search width with location and account',
      );
      expect(
        restingSearch.height,
        44,
        reason: '${viewport.label} resting search target',
      );
      final restingSearchDecoration =
          tester
                  .widget<AnimatedContainer>(
                    find.byKey(const ValueKey('buy-search-control')),
                  )
                  .decoration!
              as BoxDecoration;
      expect(restingSearchDecoration.color, Colors.transparent);
      expect(restingSearchDecoration.border, isNull);
      expect(restingSearchDecoration.boxShadow, isNull);
      expect(
        find.byKey(const ValueKey('buy-open-scanner')),
        findsOneWidget,
        reason: '${viewport.label} resting scanner owner',
      );
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
      expect(activeSearch.height, 70);
      final activeSearchDecoration =
          tester
                  .widget<AnimatedContainer>(
                    find.byKey(const ValueKey('buy-search-control')),
                  )
                  .decoration!
              as BoxDecoration;
      expect(activeSearchDecoration.color, Colors.transparent);
      expect(activeSearchDecoration.border, isNull);
      expect(activeSearchDecoration.boxShadow, isNull);
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
      expect(
        find.byKey(const ValueKey('buy-open-scanner')),
        findsNothing,
        reason: '${viewport.label} scanner yields to active query',
      );
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
        dockSurface.height / safeBodyHeight,
        lessThanOrEqualTo(.14),
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
        expect(
          find.byKey(const ValueKey('buy-open-scanner')),
          findsNothing,
          reason: '${destination.name} scanner yields to active query',
        );

        await tester.enterText(
          find.byKey(const ValueKey('buy-search-field')),
          'a long product sentence that must remain readable without hiding its beginning',
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byKey(const ValueKey('buy-search-field')))
              .maxLines,
          6,
        );
        expect(
          tester
              .getSize(find.byKey(const ValueKey('buy-search-control')))
              .height,
          162,
          reason: '${destination.name} long-query control grows progressively',
        );
        expect(
          tester.getSize(find.byKey(const ValueKey('buy-search-band'))).height,
          174,
          reason: '${destination.name} long-query band owns all wrapped text',
        );
        expect(find.byKey(const ValueKey('buy-open-scanner')), findsNothing);
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
        70,
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

    session.openAccount();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.account);
    expect(
      find.byKey(const ValueKey('buy-search-results-surface')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('buy-account-orders')), findsOneWidget);

    session.closeAccount();
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

  testWidgets(
    'every Buy destination keeps one global profile and exact Back return',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      const safePadding = EdgeInsets.only(top: 24, bottom: 24);
      final session = BuyV2Session(core: BuySession());

      await tester.pumpWidget(
        app(session, safePadding: safePadding, disableAnimations: true),
      );
      await tester.pumpAndSettle();

      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.medicine,
        BuyV2Destination.orders,
      ]) {
        if (destination == BuyV2Destination.orders) {
          session.openOrders();
        } else {
          session.openDestination(destination);
        }
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('buy-shared-header')),
          findsNothing,
          reason: destination.name,
        );
        expect(
          find.byKey(const ValueKey('buy-contextual-glass-header')),
          findsNothing,
          reason: destination.name,
        );
        expect(
          find.byKey(const ValueKey('buy-header-visual-creative-reel')),
          findsNothing,
          reason: destination.name,
        );
        final searchBand = find.byKey(const ValueKey('buy-search-band'));
        expect(searchBand, findsOneWidget, reason: destination.name);
        expect(
          tester.getTopLeft(searchBand).dy,
          safePadding.top,
          reason: '${destination.name} begins at the safe-area top',
        );
        final accountAction = find.byKey(const ValueKey('buy-open-account'));
        expect(accountAction, findsOneWidget, reason: destination.name);
        expect(
          tester.getSize(accountAction),
          const Size(44, 44),
          reason: '${destination.name} account target remains accessible',
        );
        final searchBandRect = tester.getRect(searchBand);
        final accountRect = tester.getRect(accountAction);
        expect(
          accountRect.right,
          searchBandRect.right - 8,
          reason: '${destination.name} keeps account access at top right',
        );
        expect(
          accountRect.top,
          closeTo(searchBandRect.top + 5, 1),
          reason: '${destination.name} keeps account access in the top row',
        );

        await tester.tap(accountAction);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.catalogue, reason: destination.name);
        expect(
          find.byKey(const Key('global-profile-panel-v2')),
          findsOneWidget,
          reason: destination.name,
        );
        expect(
          find.bySemanticsLabel('Open your MoolSocial profile'),
          findsOneWidget,
          reason: destination.name,
        );
        expect(
          find.byKey(const ValueKey('buy-profile-avatar')),
          findsNothing,
          reason: destination.name,
        );
        final contextId = switch (destination) {
          BuyV2Destination.shop => 'shop-active-orders',
          BuyV2Destination.wholesale => 'wholesale-discovery',
          BuyV2Destination.medicine => 'medicine-discovery',
          BuyV2Destination.orders => 'shop-orders',
        };
        expect(
          find.byKey(Key('global-profile-context-$contextId')),
          findsOneWidget,
          reason: destination.name,
        );
        expect(find.byKey(const ValueKey('buy-search-band')), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.destination, destination);
        expect(session.view, BuyV2View.catalogue);
      }

      expect(find.byKey(const ValueKey('buy-v2-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Shop uses the shared global profile and exact Back recovery', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = BuyV2Session(core: BuySession());

    await tester.pumpWidget(app(session, disableAnimations: true));
    await tester.pumpAndSettle();

    final profileAction = find.byKey(const ValueKey('buy-open-account'));
    expect(
      find.bySemanticsLabel('Open your MoolSocial profile'),
      findsOneWidget,
    );
    expect(profileAction, findsOneWidget);
    expect(tester.getSize(profileAction), const Size(44, 44));
    expect(find.byKey(const ValueKey('buy-profile-avatar')), findsNothing);

    await tester.tap(profileAction);
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.catalogue);
    expect(find.byKey(const Key('global-profile-panel-v2')), findsOneWidget);
    expect(find.text('Your MoolSocial profile'), findsOneWidget);
    expect(
      find.byKey(const Key('global-profile-context-shop-active-orders')),
      findsOneWidget,
    );
    expect(find.text('Open orders'), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-search-band')), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(session.destination, BuyV2Destination.shop);
    expect(session.view, BuyV2View.catalogue);
    expect(find.byKey(const Key('global-profile-panel-v2')), findsNothing);
    expect(find.byKey(const ValueKey('buy-search-band')), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-open-account')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Shop profile context opens the current order destination', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session, disableAnimations: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-open-account')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('global-profile-context-action-shop-active-orders')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const Key('global-profile-context-action-shop-active-orders')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('global-profile-panel-v2')), findsNothing);
    expect(session.destination, BuyV2Destination.orders);
    expect(session.view, BuyV2View.catalogue);
    expect(
      find.byKey(const PageStorageKey<String>('buy-orders')),
      findsOneWidget,
    );
  });

  testWidgets('inactive sponsored placement consumes no catalogue height', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: const Scaffold(
          body: Column(
            children: [
              BuyV2SponsoredSlot(
                key: ValueKey('inactive-sponsored-slot'),
                content: null,
              ),
              Text('Products continue'),
            ],
          ),
        ),
      ),
    );

    final slot = find.byKey(const ValueKey('inactive-sponsored-slot'));
    expect(slot, findsOneWidget);
    expect(tester.getSize(slot).height, 0);
    expect(find.text('Products continue'), findsOneWidget);
    expect(find.text('Sponsored'), findsNothing);
    expect(find.text('Advertisement'), findsNothing);
  });

  testWidgets(
    'category glass ends above the dock with compact heading and close',
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
      expect(find.text('Shop categories'), findsOneWidget);
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
        find.byKey(const Key('moolsocial-compact-destination-rail')),
      );
      expect((surface.bottom - dock.top).abs(), lessThanOrEqualTo(24));
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
        scrollable: scrollableWithin(
          PageStorageKey(
            'buy-${session.destination.name}-'
            '${session.selectedCategoryId}-all',
          ),
        ),
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
          .getRect(find.byKey(const Key('moolsocial-compact-destination-rail')))
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
    for (final entry in const [
      (keyName: 'mool-compact-launcher', label: 'Mool'),
      (keyName: 'moolsocial-family-root-buy-tap', label: 'Shop'),
      (keyName: 'buy-local-tab-wholesale', label: 'Wholesale'),
      (keyName: 'buy-local-tab-orders', label: 'Orders'),
      (keyName: 'buy-local-tab-offers', label: 'Offers'),
      (keyName: 'mool-global-chat-tap', label: 'Chat'),
    ]) {
      final cell = find.byKey(ValueKey(entry.keyName));
      final visibleLabel = find.descendant(
        of: cell,
        matching: find.text(entry.label),
      );
      expect(cell, findsOneWidget);
      expect(visibleLabel, findsOneWidget);
      final cellRect = tester.getRect(cell);
      final labelRect = tester.getRect(visibleLabel);
      expect(cellRect.contains(labelRect.topLeft), isTrue, reason: entry.label);
      expect(
        cellRect.contains(labelRect.bottomRight),
        isTrue,
        reason: entry.label,
      );
      expect(
        labelRect.left,
        greaterThanOrEqualTo(cellRect.left + 2),
        reason: '${entry.label} left separation',
      );
      expect(
        labelRect.right,
        lessThanOrEqualTo(cellRect.right - 2),
        reason: '${entry.label} right separation',
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
    expect(action.height, 44);
    expect(action.width, greaterThanOrEqualTo(60));
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
      await tester.scrollUntilVisible(
        option,
        160,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('buy-filter-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(option, findsOneWidget);
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
    expect(
      tester.getSize(find.byKey(const Key('mool-compact-launcher'))).height,
      greaterThanOrEqualTo(44),
    );
    for (final keyName in const [
      'mool-compact-launcher',
      'moolsocial-family-root-buy-tap',
      'buy-local-tab-wholesale',
      'buy-local-tab-orders',
      'buy-local-tab-offers',
      'mool-global-chat-tap',
    ]) {
      expect(
        tester.getSize(find.byKey(ValueKey(keyName))).height,
        greaterThanOrEqualTo(44),
      );
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
        expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
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
    expect(
      find.byKey(ValueKey('buy-product-inline-action-${product.id}')),
      findsNothing,
    );
    expect(
      find.byKey(ValueKey('buy-wholesale-action-dock-${product.id}')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('buy-product-action-bar')), findsNothing);
    final productScrollable = scrollableWithin(
      PageStorageKey('buy-product-${product.id}'),
    );
    await tester.scrollUntilVisible(
      find.byKey(ValueKey('buy-wholesale-trade-decision-${product.id}')),
      220,
      scrollable: productScrollable,
    );
    expect(find.text('WHOLESALE PRICE'), findsOneWidget);
    expect(find.text('Order details'), findsOneWidget);
    final primary = find.byKey(ValueKey('buy-product-primary-${product.id}'));
    expect(primary, findsOneWidget);
    expect(
      find.descendant(
        of: primary,
        matching: find.byIcon(Icons.add_shopping_cart_rounded),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: primary, matching: find.text(product.title)),
      findsNothing,
    );
    expect(
      find.descendant(of: primary, matching: find.text('Add to Cart')),
      findsOneWidget,
    );
    expect(find.text('Buy now'), findsNothing);
  });

  testWidgets(
    'product detail uses automatic fulfilment reviews and reporting',
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
      final productScrollable = scrollableWithin(
        PageStorageKey('buy-product-${product.id}'),
      );
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('buy-automatic-fulfilment-${product.id}')),
        220,
        scrollable: productScrollable,
      );
      expect(find.textContaining(product.seller), findsWidgets);
      expect(find.textContaining('Verified'), findsNothing);

      final reviews = find.byKey(ValueKey('buy-product-reviews-${product.id}'));
      await tester.scrollUntilVisible(
        reviews,
        240,
        scrollable: productScrollable,
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
      await tester.pump();
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

  testWidgets(
    'B01 T02 keeps one product while server promises 3 5 and 10 minutes',
    (tester) async {
      for (final testCase in const [
        (productId: 's-oil', destination: BuyV2Destination.shop, minutes: 3),
        (productId: 's-tomato', destination: BuyV2Destination.shop, minutes: 5),
        (
          productId: 'w-oil',
          destination: BuyV2Destination.wholesale,
          minutes: 10,
        ),
      ]) {
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          productFactsAdapter: _FixedDeliveryPromiseFactsAdapter(
            'within ${testCase.minutes} min',
          ),
        );
        final product = session.product(testCase.productId);

        await tester.pumpWidget(app(session));
        await tester.pumpAndSettle();
        session.openDestination(testCase.destination);
        session.openProduct(product.id);
        await tester.pumpAndSettle();
        final productScrollable = scrollableWithin(
          PageStorageKey('buy-product-${product.id}'),
        );
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('buy-automatic-fulfilment-${product.id}')),
          220,
          scrollable: productScrollable,
        );

        expect(find.text('Delivered in ${testCase.minutes} min'), findsWidgets);
        expect(find.textContaining(product.seller), findsWidgets);
        expect(
          find.byKey(ValueKey('buy-shop-seller-action-${product.id}')),
          findsNothing,
        );
        expect(
          find.byKey(ValueKey('buy-wholesale-supplier-action-${product.id}')),
          findsNothing,
        );

        expect(session.addProduct(product.id), isTrue);
        session.openCart();
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Delivered in ${testCase.minutes} min'),
          findsOneWidget,
        );
        expect(find.text(product.seller), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        session.dispose();
        core.dispose();
      }
    },
  );

  test(
    'B01 T02 promise copy fails closed for checking stale and unavailable',
    () {
      final product = BuyV2Catalogue.products;
      final base = const BuyV2CatalogueProductFactsAdapter().snapshotFor(
        product.first,
      );
      expect(
        buyV2BuyerDeliveryPromise(
          base.copyWith(orderabilityLabel: 'Checking serviceability'),
        ),
        'Checking delivery time',
      );
      expect(
        buyV2BuyerDeliveryPromise(base.copyWith(stale: true)),
        'Delivery time needs review',
      );
      expect(
        buyV2BuyerDeliveryPromise(
          base.copyWith(orderabilityLabel: 'Currently unavailable'),
        ),
        'Currently unavailable',
      );
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
    'featured products lead with a dominant photo and readable filtered cards',
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
      expect(tester.getSize(densePhoto), const Size(78, 70));
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
    final selectedProduct = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    expect(session.addProduct(selectedProduct.id), isTrue);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    expect(session.confirmOrder(), isTrue);
    final order = session.confirmedOrders.single;
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openTracking(order.id);
    await tester.pumpAndSettle();

    final invoiceAction = find.byKey(
      ValueKey('buy-tracking-invoice-${order.id}'),
    );
    await tester.scrollUntilVisible(
      invoiceAction,
      220,
      scrollable: scrollableWithin(PageStorageKey('buy-tracking-${order.id}')),
    );
    await tester.tap(invoiceAction);
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('buy-invoice-page-${order.id}')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, order.id);

    final itemsAction = find.text('Items');
    await tester.scrollUntilVisible(
      itemsAction,
      220,
      scrollable: scrollableWithin(PageStorageKey('buy-tracking-${order.id}')),
    );
    await tester.tap(itemsAction);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.orderItems);
    expect(find.byKey(ValueKey('buy-order-items-${order.id}')), findsOneWidget);
    final product = session.productsForOrder(session.selectedOrder).first;
    await tester.tap(find.byKey(ValueKey('buy-order-product-${product.id}')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, product.id);

    session.goBack();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.orderItems);
    expect(session.selectedOrder.id, order.id);
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
          final productScrollable = scrollableWithin(
            PageStorageKey('buy-product-${product.id}'),
          );
          final decisionOwner = destination == BuyV2Destination.medicine
              ? find.text(product.partnerRole)
              : find.byKey(ValueKey('buy-automatic-fulfilment-${product.id}'));
          await tester.scrollUntilVisible(
            decisionOwner,
            140,
            scrollable: productScrollable,
          );
          expect(
            decisionOwner,
            findsOneWidget,
            reason: '$destination at $viewport',
          );
          expect(find.textContaining('Verified'), findsNothing);
          await tester.scrollUntilVisible(
            find.byKey(ValueKey('buy-product-reviews-${product.id}')),
            180,
            scrollable: productScrollable,
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

  testWidgets('Account and shared Chat preserve the exact purchase depth', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    var chatOpens = 0;
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.wholesale,
    );
    await tester.pumpWidget(app(session, onOpenChat: () => chatOpens += 1));
    session.openProduct(product.id);
    await tester.pumpAndSettle();

    session.openAccount();
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.account);
    session.closeAccount();
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.wholesale);
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, product.id);

    session.openTracking('MS-240782');
    await tester.pumpAndSettle();
    final trackingHelp = find.byKey(const ValueKey('buy-tracking-help'));
    await tester.scrollUntilVisible(
      trackingHelp,
      180,
      scrollable: scrollableWithin(
        const PageStorageKey('buy-tracking-MS-240782'),
      ),
    );
    await tester.tap(trackingHelp);
    await tester.pumpAndSettle();
    expect(chatOpens, 1);
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

      session.openAccount();
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

      session.closeAccount();
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
    final productScroll = find
        .descendant(
          of: find.byKey(PageStorageKey('buy-product-${product.id}')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(primary, 180, scrollable: productScroll);
    await tester.pumpAndSettle();
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

  testWidgets('T01A Cart hides Medicine in Shop and preserves Care Medicine', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    for (final destination in const [
      BuyV2Destination.shop,
      BuyV2Destination.wholesale,
      BuyV2Destination.medicine,
    ]) {
      final product = BuyV2Catalogue.products.firstWhere(
        (item) => item.destination == destination && !item.requiresPrescription,
      );
      session.addProduct(product.id);
    }
    session.openDestination(BuyV2Destination.wholesale);
    session.openCart(scope: BuyV2CartScope.wholesale);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.text('Medicine'), findsNothing);

    session.openDestination(BuyV2Destination.medicine);
    session.openCart(scope: BuyV2CartScope.medicine);
    await tester.pumpAndSettle();
    expect(find.text('Medicine'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Care Medicine never exposes an unrelated Shop basket', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    final shop = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    final medicine = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == BuyV2Destination.medicine &&
          !item.requiresPrescription,
    );
    session.addProduct(shop.id);
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openDestination(BuyV2Destination.medicine);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-compact-cart-indicator')),
      findsNothing,
    );

    session.addProduct(medicine.id);
    await tester.pumpAndSettle();
    final miniCart = find.byKey(const ValueKey('buy-compact-cart-indicator'));
    expect(miniCart, findsOneWidget);
    expect(
      tester.getSemantics(miniCart).label,
      contains(buyV2Money(medicine.price)),
    );
    expect(
      tester.getSemantics(miniCart).label,
      isNot(contains(buyV2Money(shop.price + medicine.price))),
    );

    await tester.tap(miniCart);
    await tester.pumpAndSettle();
    expect(session.cartScope, BuyV2CartScope.medicine);
    expect(session.cartLines, hasLength(1));
    expect(session.cartLines.single.product.id, medicine.id);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact Buy surface and Cart total remain whole at 320 and 140 percent',
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

      expect(find.byKey(const ValueKey('buy-change-location')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('buy-search-band'))).dy,
        0,
      );

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

  testWidgets('tracking shows current progress, next step and working alerts', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    session.openTracking('MS-240782');
    await tester.pumpAndSettle();

    expect(find.text('CURRENT'), findsOneWidget);
    expect(find.text('LIVE'), findsNothing);
    expect(find.text('54%'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey('buy-tracking-progress')),
          )
          .value,
      .54,
    );
    expect(find.text('NOW'), findsOneWidget);
    final nextStep = find.text('What happens next');
    final trackingScrollable = scrollableWithin(
      const PageStorageKey('buy-tracking-MS-240782'),
    );
    await tester.scrollUntilVisible(
      nextStep,
      180,
      scrollable: trackingScrollable,
    );
    expect(nextStep, findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('buy-tracking-alerts')),
      180,
      scrollable: trackingScrollable,
    );
    expect(find.text('Order updates'), findsOneWidget);
    expect(find.text('Order alerts are on'), findsOneWidget);

    final alertsToggle = find.byKey(
      const ValueKey('buy-tracking-alerts-toggle'),
    );
    await tester.scrollUntilVisible(
      alertsToggle,
      180,
      scrollable: trackingScrollable,
    );
    await tester.drag(trackingScrollable, const Offset(0, -72));
    await tester.pumpAndSettle();
    await tester.tap(alertsToggle);
    await tester.pump();
    expect(session.trackingAlertsEnabled, isFalse);
    expect(find.text('Order alerts are paused'), findsOneWidget);
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
      scrollable: scrollableWithin(
        const PageStorageKey('buy-tracking-MS-240782'),
      ),
    );
    expect(find.text('Help'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-compact-cart-indicator')),
      findsNothing,
    );

    session.openAssist();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-assist-hero')), findsNothing);
    expect(
      find.byKey(PageStorageKey('buy-tracking-${session.assistOrder.id}')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-compact-cart-indicator')),
      findsNothing,
    );
  });

  testWidgets('retired Assist state uses tracking and shared Chat only', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    var chatOpens = 0;
    await tester.pumpWidget(app(session, onOpenChat: () => chatOpens += 1));
    await tester.pumpAndSettle();

    session.openAssist();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-assist-hero')), findsNothing);
    expect(
      find.byKey(PageStorageKey('buy-tracking-${session.assistOrder.id}')),
      findsOneWidget,
    );
    final help = find.byKey(const ValueKey('buy-tracking-help'));
    await tester.scrollUntilVisible(
      help,
      240,
      scrollable: scrollableWithin(
        PageStorageKey('buy-tracking-${session.assistOrder.id}'),
      ),
    );
    await tester.tap(help);
    await tester.pumpAndSettle();
    expect(chatOpens, 1);
    expect(find.text('Call in app'), findsNothing);
    expect(tester.takeException(), isNull);
  });

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

    expect(session.view, BuyV2View.tracking);
    expect(session.selectedOrder.id, 'MS-240741');
    expect(session.ordersTab, BuyV2OrdersTab.delivered);
    expect(session.cartLines, isEmpty);
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
    session.openOrders();
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
    final savedProduct = session.visibleProducts.first;
    session.toggleSaved(savedProduct.id);
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
        .getRect(find.byKey(const ValueKey('buy-theme-canvas')))
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
    'featured card exposes automatic delivery and a stable purchase action',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      final product = session.visibleProducts.first;
      final card = find.byKey(ValueKey('buy-product-${product.id}'));
      final add = find.byKey(ValueKey('buy-add-${product.id}'));
      final fullPromise = buyV2BuyerDeliveryPromise(
        session.productFactsFor(product),
      );
      final promisedMinutes = RegExp(r'(\d+)\s*min').firstMatch(fullPromise);
      expect(promisedMinutes, isNotNull);
      final promise = find.descendant(
        of: card,
        matching: find.textContaining('${promisedMinutes!.group(1)} min'),
      );

      expect(add, findsOneWidget);
      expect(promise, findsOneWidget);
      expect(find.textContaining(product.seller), findsOneWidget);
      final cardRect = tester.getRect(card);
      expect(cardRect.contains(tester.getCenter(add)), isTrue);
      expect(cardRect.contains(tester.getCenter(promise)), isTrue);
      expect(tester.getSize(add).height, 44);
      expect(tester.getSize(add).width, greaterThanOrEqualTo(60));
    },
  );

  testWidgets(
    'checkout payment recovery states stay actionable at compact size',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      await tester.pumpWidget(app(session, textScale: 1.4));
      await tester.pumpAndSettle();
      session.addProduct('s-tomato');
      session.openCart(scope: BuyV2CartScope.shop);
      session.openCheckout();
      await tester.pumpAndSettle();

      for (final state in const [
        BuyV2CheckoutSubmissionState.submitting,
        BuyV2CheckoutSubmissionState.paymentActionRequired,
        BuyV2CheckoutSubmissionState.paymentPending,
        BuyV2CheckoutSubmissionState.paymentUnknown,
        BuyV2CheckoutSubmissionState.cancelled,
        BuyV2CheckoutSubmissionState.failed,
        BuyV2CheckoutSubmissionState.unavailable,
      ]) {
        session.checkoutSubmissionState = state;
        session.notifyListeners();
        await tester.pump(const Duration(milliseconds: 120));

        expect(
          find.byKey(ValueKey('buy-checkout-submission-${state.name}')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: state.name);
        if (state == BuyV2CheckoutSubmissionState.submitting) continue;
        final actionKey = switch (state) {
          BuyV2CheckoutSubmissionState.paymentActionRequired => const ValueKey(
            'buy-checkout-continue-payment',
          ),
          BuyV2CheckoutSubmissionState.paymentPending ||
          BuyV2CheckoutSubmissionState.paymentUnknown => const ValueKey(
            'buy-checkout-check-payment',
          ),
          _ => const ValueKey('buy-checkout-retry-order'),
        };
        expect(find.byKey(actionKey), findsOneWidget);
        expect(
          tester.getSize(find.byKey(actionKey)).height,
          greaterThanOrEqualTo(44),
        );
      }
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

    expect(find.text('Delivery plan'), findsOneWidget);
    expect(find.textContaining('Delivery 1 ·'), findsOneWidget);
    expect(session.checkoutDestinations, {BuyV2Destination.shop});
    expect(session.checkoutFulfilmentGroups, hasLength(1));
    expect(
      find.byKey(
        ValueKey(
          'buy-checkout-delivery-plan-${session.checkoutFulfilmentGroups.single.key}',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'T01C carries exact mixed delivery promises through one purchase',
    (tester) async {
      final adapter = _T01CMutableDeliveryFactsAdapter();
      final session = BuyV2Session(
        core: BuySession(),
        productFactsAdapter: adapter,
      );
      final shop = session.product('s-tomato');
      final wholesale = session.product('w-oil');
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      expect(session.addProduct(shop.id), isTrue);
      expect(session.addProduct(wholesale.id), isTrue);
      session.openCart();
      expect(session.openCheckout(), isTrue);
      await tester.pumpAndSettle();

      expect(find.text('Delivery plan'), findsOneWidget);
      expect(
        find.textContaining('Delivered in 5 min · by 6:35 PM'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Delivered in 1 day · by tomorrow 4:00 PM'),
        findsOneWidget,
      );
      expect(find.text(shop.seller), findsNothing);
      expect(find.text(wholesale.seller), findsNothing);
      expect(find.text('Place order'), findsOneWidget);

      await tester.tap(find.text('Place order'));
      await tester.pumpAndSettle();

      expect(find.text('Order placed'), findsOneWidget);
      expect(find.text('Your deliveries'), findsOneWidget);
      expect(find.text('Delivery 1 of 2'), findsOneWidget);
      expect(find.text('Delivery 2 of 2'), findsOneWidget);
      expect(
        find.text('Promised at Checkout · Delivered in 5 min · by 6:35 PM'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Promised at Checkout · Delivered in 1 day · by tomorrow 4:00 PM',
        ),
        findsOneWidget,
      );
      expect(find.textContaining(shop.seller), findsWidgets);
      expect(find.textContaining(wholesale.seller), findsWidgets);
      expect(session.confirmedPurchaseId, 'BUY-NEW-01');
      expect(session.confirmedOrders.map((order) => order.purchaseId).toSet(), {
        'BUY-NEW-01',
      });
    },
  );

  testWidgets('T01C blocks and explains a changed pre-commit promise', (
    tester,
  ) async {
    final adapter = _T01CMutableDeliveryFactsAdapter();
    final session = BuyV2Session(
      core: BuySession(),
      productFactsAdapter: adapter,
    );
    final shop = session.product('s-tomato');
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    expect(session.addProduct(shop.id), isTrue);
    session.openCart();
    expect(session.openCheckout(), isTrue);
    await tester.pumpAndSettle();

    adapter.updateShop(promise: 'within 10 min', promisedBy: 'by 6:40 PM');
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-checkout-promise-change-review')),
      findsOneWidget,
    );
    expect(
      find.text('Previous · Delivered in 5 min · by 6:35 PM'),
      findsOneWidget,
    );
    expect(
      find.text('Updated · Delivered in 10 min · by 6:40 PM'),
      findsOneWidget,
    );
    expect(session.confirmedOrders, isEmpty);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Place order'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.byKey(const ValueKey('buy-accept-updated-delivery-times')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-checkout-promise-change-review')),
      findsNothing,
    );
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();
    expect(find.text('Order placed'), findsOneWidget);
    expect(
      find.text('Promised at Checkout · Delivered in 10 min · by 6:40 PM'),
      findsOneWidget,
    );
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
      session.increase(products.first.id);
      session.openCart();
      session.openCheckout();
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Place order'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('buy-confirmation')), findsOneWidget);
      expect(find.text('Your deliveries'), findsOneWidget);
      expect(find.text('Delivery 1 of 2'), findsOneWidget);
      expect(find.text('Delivery 2 of 2'), findsOneWidget);
      expect(find.text('Delivery 3 of 3'), findsNothing);
      expect(find.textContaining('Promised at Checkout'), findsNWidgets(2));
      expect(find.textContaining('Purchase BUY-NEW-01'), findsOneWidget);
      expect(
        find.textContaining(session.confirmedOrders.first.partner),
        findsWidgets,
      );
      final shopOrder = session.confirmedOrders.firstWhere(
        (order) => order.destination == BuyV2Destination.shop,
      );
      final wholesaleOrder = session.confirmedOrders.firstWhere(
        (order) => order.destination == BuyV2Destination.wholesale,
      );
      expect(shopOrder.lines.single.product.id, products.first.id);
      expect(shopOrder.lines.single.quantity, 2);
      expect(wholesaleOrder.lines.single.product.id, products.last.id);
      expect(wholesaleOrder.lines.single.quantity, products.last.minimumOrder);

      final invoiceAction = find.byKey(
        ValueKey('buy-confirmation-invoice-${shopOrder.id}'),
      );
      await tester.ensureVisible(invoiceAction);
      await tester.tap(invoiceAction);
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey('buy-invoice-page-${shopOrder.id}')),
        findsOneWidget,
      );
      expect(find.text(products.first.title), findsOneWidget);
      expect(find.text('2×'), findsOneWidget);
      expect(find.byKey(const Key('mool-compact-launcher')), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-confirmation')), findsOneWidget);

      final ordersAction = find.byKey(
        const ValueKey('buy-confirmation-orders'),
      );
      await tester.ensureVisible(ordersAction);
      await tester.tap(ordersAction);
      await tester.pumpAndSettle();
      expect(find.text('PURCHASES'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('buy-purchase-group-BUY-NEW-01')),
        findsOneWidget,
      );
      expect(
        find.textContaining(session.confirmedOrders.first.id),
        findsWidgets,
      );
    },
  );

  testWidgets('invoice download uses the placed-order document contract', (
    tester,
  ) async {
    BuyV2InvoiceDocument? requestedInvoice;
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.shop,
    );
    await tester.pumpWidget(
      app(
        session,
        disableAnimations: true,
        invoiceDownloader: (invoice) async {
          requestedInvoice = invoice;
          return BuyV2InvoiceDownloadOutcome.saved;
        },
      ),
    );
    await tester.pumpAndSettle();

    session.addProduct(product.id);
    session.increase(product.id);
    session.openCart(scope: BuyV2CartScope.shop);
    expect(session.openCheckout(), isTrue);
    expect(session.confirmOrder(), isTrue);
    await tester.pumpAndSettle();
    final order = session.confirmedOrders.single;

    final invoiceAction = find.byKey(
      ValueKey('buy-confirmation-invoice-${order.id}'),
    );
    await tester.ensureVisible(invoiceAction);
    await tester.tap(invoiceAction);
    await tester.pumpAndSettle();

    final download = find.byKey(ValueKey('buy-download-invoice-${order.id}'));
    await tester.scrollUntilVisible(
      download,
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(download, findsOneWidget);
    expect(tester.getSize(download).height, 48);
    await tester.tap(download);
    await tester.pumpAndSettle();

    expect(requestedInvoice, isNotNull);
    expect(requestedInvoice!.order.id, order.id);
    expect(requestedInvoice!.order.lines.single.quantity, 2);
    expect(
      requestedInvoice!.suggestedFileName,
      'MoolSocial-invoice-${order.id}.pdf',
    );
    expect(find.text('Invoice saved to this device.'), findsOneWidget);
  });

  testWidgets(
    'Orders opens an honest full-page invoice at compact accessible size',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      final session = BuyV2Session(core: BuySession());
      await tester.pumpWidget(
        app(session, textScale: 1.4, disableAnimations: true),
      );
      await tester.pumpAndSettle();
      session.openOrders();
      await tester.pumpAndSettle();
      final order = session.visibleOrders.first;

      final invoiceAction = find.byKey(
        ValueKey('buy-order-invoice-${order.id}'),
      );
      await tester.ensureVisible(invoiceAction);
      await tester.tap(invoiceAction);
      await tester.pumpAndSettle();

      final invoicePage = find.byKey(ValueKey('buy-invoice-page-${order.id}'));
      expect(invoicePage, findsOneWidget);
      expect(find.text('Order invoice'), findsOneWidget);
      expect(find.text(order.itemSummary), findsOneWidget);
      expect(find.byKey(const Key('mool-compact-launcher')), findsNothing);
      final invoiceCopy = tester
          .widgetList<Text>(
            find.descendant(of: invoicePage, matching: find.byType(Text)),
          )
          .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
          .join(' ');
      expect(_forbiddenBuyCopy.hasMatch(invoiceCopy), isFalse);
      expect(tester.takeException(), isNull);

      final download = find.byKey(ValueKey('buy-download-invoice-${order.id}'));
      await tester.scrollUntilVisible(
        download,
        240,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(download);
      await tester.pumpAndSettle();
      await tester.tap(download);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Invoice download is not available for this order yet. You can still view it here.',
        ),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.destination, BuyV2Destination.orders);
      expect(session.view, BuyV2View.catalogue);
      expect(find.byKey(const PageStorageKey('buy-orders')), findsOneWidget);
    },
  );

  testWidgets('delivered Orders expose non-mutating order inspection', (
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
    expect(find.text('View order'), findsWidgets);
    expect(find.text('Reorder'), findsNothing);
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
    expect(find.text('Search orders or ID'), findsOneWidget);
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
      scrollable: scrollableWithin(const PageStorageKey('buy-orders')),
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
          .getRect(find.byKey(const Key('moolsocial-compact-destination-rail')))
          .top;
      final rect = tester.getRect(
        find.byKey(ValueKey('buy-product-${product.id}')),
      );
      expect(rect.top, lessThan(dockTop));
      expect(dockTop - rect.top, greaterThanOrEqualTo(180));
      final action = tester.getRect(
        find.byKey(ValueKey('buy-add-${product.id}')),
      );
      expect(action.height, 44);
      expect(action.width, greaterThanOrEqualTo(60));
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
      expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
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

  testWidgets('Buy footer subactions keep one equal interaction geometry', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    final wholesale = find.byKey(const ValueKey('buy-local-tab-wholesale'));
    final orders = find.byKey(const ValueKey('buy-local-tab-orders'));
    final offers = find.byKey(const ValueKey('buy-local-tab-offers'));
    final rectangles = [
      tester.getRect(wholesale),
      tester.getRect(orders),
      tester.getRect(offers),
    ];

    for (final rectangle in rectangles.skip(1)) {
      expect(rectangle.width, closeTo(rectangles.first.width, .01));
      expect(rectangle.height, closeTo(rectangles.first.height, .01));
    }
    expect(rectangles.every((rect) => rect.height >= 44), isTrue);
    expect(
      rectangles[1].left - rectangles[0].right,
      closeTo(rectangles[2].left - rectangles[1].right, .01),
    );

    await tester.tap(wholesale);
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.wholesale);
    expect(tester.widget<InkWell>(wholesale).onTap, isNotNull);
    await tester.tap(wholesale);
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.wholesale);

    await tester.tap(orders);
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.orders);
    expect(tester.widget<InkWell>(orders).onTap, isNotNull);
    await tester.tap(orders);
    await tester.pumpAndSettle();
    expect(session.destination, BuyV2Destination.orders);

    await tester.tap(offers);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-offers-publisher-summary')),
      findsOneWidget,
    );
    expect(tester.widget<InkWell>(offers).onTap, isNotNull);
    await tester.tap(offers);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-offers-publisher-summary')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'live Offers recover from offline without static production data',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      final source = _LiveOffersSource(
        const BuyV2PublishedOffersSnapshot(
          state: BuyV2PublishedOffersLoadState.offline,
          customerMessage: 'Offers could not refresh.',
        ),
      );
      await tester.pumpWidget(app(session, offersSource: source));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
      await tester.pumpAndSettle();

      expect(find.text('Offers could not refresh'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('buy-live-offers-retry')),
        findsOneWidget,
      );
      source.snapshot = const BuyV2PublishedOffersSnapshot(
        state: BuyV2PublishedOffersLoadState.ready,
        offers: [
          BuyV2PublishedOffer(
            productId: 's-tomato',
            publisherType: BuyV2OfferPublisherType.retailer,
            headline: 'Fresh price',
          ),
        ],
      );
      await tester.tap(find.byKey(const ValueKey('buy-live-offers-retry')));
      await tester.pumpAndSettle();

      expect(source.calls, 2);
      expect(
        find.byKey(const ValueKey('buy-offers-publisher-summary')),
        findsOneWidget,
      );
      expect(find.text('Fresh tomatoes'), findsWidgets);
    },
  );

  testWidgets('Offers accepts an ordered published catalogue seam', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    const source = _FixedOffersSource([
      BuyV2PublishedOffer(
        productId: 'w-rice',
        publisherType: BuyV2OfferPublisherType.wholesaler,
        headline: 'Published trade price',
      ),
      BuyV2PublishedOffer(
        productId: 'missing-product',
        publisherType: BuyV2OfferPublisherType.retailer,
        headline: 'Unavailable placement',
      ),
    ]);
    await tester.pumpWidget(app(session, offersSource: source));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-product-w-rice')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-product-missing-product')),
      findsNothing,
    );
    final grid = tester.widget<Semantics>(
      find.byKey(const ValueKey('buy-horizontal-product-grid')),
    );
    expect(grid.properties.label, contains('Showing 1 of 1'));
    expect(grid.properties.label, contains('All products loaded'));
  });

  testWidgets('Offers completes product Cart and Checkout navigation', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-product-w-oil')));
    await tester.pumpAndSettle();
    expect(session.selectedProduct?.id, 'w-oil');
    expect(session.view, BuyV2View.product);
    expect(find.text('Offers'), findsWidgets);
    expect(find.text('Wholesale'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buy-product-primary-w-oil')));
    await tester.pumpAndSettle();
    expect(session.quantityFor('w-oil'), 2);

    await tester.tap(find.byKey(const ValueKey('buy-compact-cart-indicator')));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.cart);
    expect(find.byKey(const ValueKey('buy-cart-browse-more')), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Review order'));
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.checkout);
    expect(
      find.byKey(const ValueKey('buy-checkout-action-bar')),
      findsOneWidget,
    );
  });

  testWidgets('Offers source filters are real, reversible and channel-safe', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();

    final retail = find.byKey(const ValueKey('buy-offers-filter-retailer'));
    expect(retail, findsOneWidget);
    await tester.tap(retail);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-product-s-tomato')), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-product-w-oil')), findsNothing);

    await tester.tap(retail);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-product-w-oil')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Shop Orders excludes Care-owned Medicine and stale promises', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-local-tab-orders')));
    await tester.pumpAndSettle();

    expect(session.activeOrderCount, 2);
    expect(session.deliveredOrderCount, 2);
    expect(find.text('Medicine order'), findsNothing);
    expect(find.textContaining('29 Jul'), findsNothing);
    expect(find.textContaining('30 Jul'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cart can return to Offers and add another product', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-add-w-oil')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-compact-cart-indicator')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-cart-browse-more')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-offers-publisher-summary')),
      findsOneWidget,
    );
    expect(session.quantityFor('w-oil'), 2);

    final tomatoAdd = find.byKey(const ValueKey('buy-add-s-tomato'));
    await tester.scrollUntilVisible(
      tomatoAdd,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-offers')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(tomatoAdd);
    await tester.pumpAndSettle();
    await tester.tap(tomatoAdd);
    await tester.pumpAndSettle();
    expect(session.quantityFor('s-tomato'), 1);
    expect(session.itemCount, 3);
  });

  testWidgets('Shop Wholesale Orders and Offers page product grids', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('buy-featured-products')), findsOneWidget);
    expect(
      find.byKey(
        ValueKey('buy-featured-product-${session.visibleProducts.first.id}'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-wholesale')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-featured-products')), findsOneWidget);
    expect(
      find.byKey(
        ValueKey('buy-featured-product-${session.visibleProducts.first.id}'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-orders')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(
        const ValueKey('buy-progressive-product-count-buy-orders-products'),
      ),
      240,
      scrollable: scrollableWithin(const PageStorageKey('buy-orders')),
    );
    String progressLabel() => tester
        .widget<Semantics>(
          find.byKey(const ValueKey('buy-horizontal-product-grid')),
        )
        .properties
        .label!;
    expect(progressLabel(), contains('Showing 8 of 18'));

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();
    expect(progressLabel(), contains('Showing 8 of 24'));
    await tester.fling(
      find.byKey(const ValueKey('buy-horizontal-product-lane-0')),
      const Offset(-1200, 0),
      2200,
    );
    await tester.pumpAndSettle();
    expect(progressLabel(), isNot(contains('Showing 8 of 24')));
    expect(progressLabel(), contains('of 24'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Offers search stays inside the published mixed catalogue', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    expect(find.text('Search offers, products and sellers'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('buy-search-field')),
      'rice',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buy-product-w-rice')), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-product-w-oil')), findsNothing);
    expect(
      find.byKey(const ValueKey('buy-offers-publisher-summary')),
      findsOneWidget,
    );
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
