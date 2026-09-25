import 'buy_v2_qualified_provider_fixture.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;
import 'buy_v2_discovery_refinement_test.dart' show BuyTestEligibilityFacts;

class _FixtureCustomerStore implements BuyV2CustomerStateStore {
  BuyV2CustomerStateSnapshot? snapshot;
  @override
  String get ownerScope => 'rv6-fixture-test';
  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => snapshot;
  @override
  Future<bool> write(BuyV2CustomerStateSnapshot value) async {
    snapshot = value;
    return true;
  }
}

void main() {
  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Cursor eight tickets Store parity ${destination.name} $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(scale == 1 ? 390 : 320, 844);
          tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final source = _StoreJourneySource(destination);
          final session = BuyV2Session(
            core: core,
            reviewDataEnabled: true,
            cataloguePageSource: source,
            initialCatalogueRegionId: 'jodhpur',
          );
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          final id = source.productIdAt(0, 0);
          await session.openLinkedProduct(id);
          session.openProduct(id);
          await tester.pumpWidget(
            _app(session, textScale: scale, disableAnimations: true),
          );
          await tester.pumpAndSettle();
          final action = find.byKey(
            ValueKey(
              destination == BuyV2Destination.shop
                  ? 'buy-shop-seller-action-$id'
                  : 'buy-wholesale-store-action-$id',
            ),
          );
          await _revealProductAction(tester, id, action);
          await tester.tap(action);
          await tester.pumpAndSettle();
          final scope = 'store-${destination.name}-${source.storeIdAt(0)}';
          final close = find.byKey(const ValueKey('buy-paged-store-close'));
          expect(close.hitTestable(), findsOneWidget);
          expect(
            tester.widget<IconButton>(close).style!.side!.resolve({}),
            BorderSide.none,
          );
          expect(tester.getSize(close).shortestSide, greaterThanOrEqualTo(44));
          expect(tester.widget<IconButton>(close).tooltip, 'Close store');
          final field = find.byKey(const ValueKey('buy-store-product-search'));
          expect(field.hitTestable(), findsOneWidget);
          final width = tester.getSize(field).width;
          final decoration = tester.widget<TextField>(field).decoration!;
          expect(decoration.border, InputBorder.none);
          expect(
            find.byKey(ValueKey('buy-paged-vertical-grid-$scope')),
            findsOneWidget,
          );
          await captureR66Visual(
            tester,
            'eight-store-${destination.name}-$scale',
          );
          final storeTile = find.byKey(ValueKey('buy-grid-packshot-$id'));
          await tester.ensureVisible(storeTile);
          await tester.pumpAndSettle();
          await tester.tapAt(
            Alignment(-.5, .55).withinRect(tester.getRect(storeTile)),
          );
          await tester.pumpAndSettle();
          expect(session.selectedProductId, id);
          expect(session.view, BuyV2View.product);
          final page = find.byKey(PageStorageKey('buy-product-$id')).last;
          final details = find.descendant(
            of: page,
            matching: find.byKey(ValueKey('buy-automatic-fulfilment-$id')),
          );
          await tester.scrollUntilVisible(
            details,
            160,
            scrollable: find
                .descendant(of: page, matching: find.byType(Scrollable))
                .first,
          );
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: details,
              matching: find.byKey(ValueKey('buy-product-hero-store-$id')),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: details,
              matching: find.text('Delivery & seller'),
            ),
            findsOneWidget,
          );
          await captureR66Visual(
            tester,
            'approved-store-product-${destination.name}-$scale',
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          await _revealPagedHeader(tester, scope, field);
          expect(field.hitTestable(), findsOneWidget);
          await tester.tap(field);
          await tester.enterText(field, 'sku 4999');
          await tester.pumpAndSettle();
          expect(tester.getSize(field).width, greaterThan(width + 30));
          expect(
            find.byKey(const ValueKey('buy-store-info-control')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('buy-store-catalogue-toolbar')),
            findsNothing,
          );
          expect(
            session.retainedCatalogueQuery(scope)?.storeId,
            source.storeIdAt(0),
          );
          expect(
            session.retainedCatalogueQuery(scope)?.destination,
            destination,
          );
          expect(session.retainedCatalogueQuery(scope)?.query, 'sku 4999');
          tester.view.viewInsets = const FakeViewPadding(bottom: 290);
          await tester.pumpAndSettle();
          expect(tester.getRect(field).bottom, lessThan(844 - 290));
          await captureR66Visual(
            tester,
            'eight-store-search-${destination.name}-$scale',
          );
          await tester.tap(
            find.byKey(const ValueKey('buy-store-product-search-clear')),
          );
          tester.view.resetViewInsets();
          tester.testTextInput.hide();
          await tester.tap(
            find.byKey(const ValueKey('buy-store-search-finish')),
          );
          await tester.pumpAndSettle();
          expect(tester.getSize(field).width, closeTo(width, .1));
          await tester.tap(
            find.byKey(const ValueKey('buy-store-category-control')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-category-sheet-surface')),
            findsOneWidget,
          );
          expect(find.byType(BuyV2CategoryThumbnail), findsWidgets);
          await captureR66Visual(
            tester,
            'eight-store-categories-${destination.name}-$scale',
          );
          final surface = find.byKey(
            const ValueKey('buy-category-sheet-surface'),
          );
          final before = tester.getRect(surface);
          await tester.drag(
            find.byKey(const ValueKey('buy-category-drag-handle')),
            const Offset(0, -360),
          );
          await tester.pumpAndSettle();
          expect(tester.getRect(surface).top, lessThan(before.top - 100));
          expect(tester.getRect(surface).top, lessThanOrEqualTo(30));
          expect(find.text('Choose one to update products'), findsNothing);
          expect(find.text('Category search'), findsNothing);
          final categorySearch = find.byKey(
            const ValueKey('buy-category-search'),
          );
          await tester.tap(categorySearch);
          await tester.enterText(categorySearch, 'no-such-category');
          tester.view.viewInsets = const FakeViewPadding(bottom: 290);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('buy-category-empty')),
            findsOneWidget,
          );
          expect(tester.getRect(categorySearch).bottom, lessThan(554));
          expect(tester.getRect(surface).bottom, lessThanOrEqualTo(554));
          await tester.tap(
            find.byKey(const ValueKey('buy-category-search-clear')),
          );
          tester.view.resetViewInsets();
          tester.testTextInput.hide();
          tester.widget<TextField>(categorySearch).focusNode!.unfocus();
          await tester.pumpAndSettle();

          await captureR66Visual(
            tester,
            'eight-store-categories-full-${destination.name}-$scale',
          );

          final category = session
              .categoriesFor(destination)
              .firstWhere((c) => c.id != 'all');
          await tester.tap(
            find.byKey(ValueKey('buy-store-category-${category.id}')),
          );
          await tester.pumpAndSettle();
          expect(
            session.retainedCatalogueQuery(scope)?.categoryId,
            category.id,
          );
          expect(session.selectedCategoryId, 'all');
          await _revealPagedHeader(
            tester,
            scope,
            find.byKey(const ValueKey('buy-store-saved-control')),
          );
          await tester.tap(
            find.byKey(const ValueKey('buy-store-saved-control')),
          );
          await tester.pumpAndSettle();
          await tester.tap(field);
          await tester.enterText(field, 'rice');
          await tester.pumpAndSettle();
          expect(tester.getSize(field).width, greaterThan(width + 30));
          tester.testTextInput.hide();
          await tester.pumpAndSettle();
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(field, findsOneWidget);
          expect(
            find.byKey(const ValueKey('buy-store-search-finish')),
            findsNothing,
          );

          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  for (final profile in const [
    (360.0, 1.0, false),
    (390.0, 1.0, false),
    (320.0, 2.0, false),
    (390.0, 1.0, true),
  ]) {
    testWidgets(
      'Cursor storefront scoped controls and navigation ${profile.$1} ${profile.$2} reduced ${profile.$3}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(profile.$1, 800);
        tester.view.viewPadding = const FakeViewPadding(top: 34, bottom: 48);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final source = _StoreJourneySource(
          BuyV2Destination.shop,
          name: profile.$1 == 320
              ? 'Shree Radha Krishna Supermarket and General Store Jodhpur'
              : 'Mool Market',
        );
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: true,
          cataloguePageSource: source,
          initialCatalogueRegionId: 'jodhpur',
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        final id = source.productIdAt(0, 0);
        final otherId = source.productIdAt(10, 0);
        await session.openLinkedProduct(otherId);
        session.toggleSaved(otherId);
        await session.openLinkedProduct(id);
        session.toggleSaved(id);
        final homeQuery = session.catalogueQuery().key;
        session.openProduct(id);
        await tester.pumpWidget(
          _app(session, textScale: profile.$2, disableAnimations: profile.$3),
        );
        await tester.pumpAndSettle();
        final action = find.byKey(ValueKey('buy-shop-seller-action-$id'));
        await _revealProductAction(tester, id, action);
        await tester.tap(action);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        final nameMotion = find.byKey(
          ValueKey('buy-store-name-motion-${source.storeIdAt(0)}'),
        );
        expect(nameMotion, profile.$3 ? findsNothing : findsOneWidget);
        await tester.pumpAndSettle();
        if (!profile.$3) {
          final bounds = tester.getRect(nameMotion);
          for (var cycle = 0; cycle < 2; cycle++) {
            await tester.pump(const Duration(milliseconds: 3600));
            await tester.pump(const Duration(milliseconds: 800));
            for (final prefix in ['name']) {
              final sheen = find.byKey(
                ValueKey('buy-store-$prefix-motion-${source.storeIdAt(0)}'),
              );
              final builder = tester.widget<AnimatedBuilder>(
                find
                    .ancestor(of: sheen, matching: find.byType(AnimatedBuilder))
                    .first,
              );
              final animation = builder.animation as Animation<double>;
              expect(animation.value, allOf(greaterThan(0), lessThan(1)));
            }
            expect(tester.getRect(nameMotion), bounds);
            await tester.pumpAndSettle();
          }
        }
        for (final state in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
        if (!profile.$3) {
          final builder = tester.widget<AnimatedBuilder>(
            find
                .ancestor(
                  of: nameMotion,
                  matching: find.byType(AnimatedBuilder),
                )
                .first,
          );
          final controller = builder.animation as AnimationController;
          expect(controller.isAnimating, isFalse);
          expect(controller.value, 1);
        }
        for (final state in [
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
        ]) {
          tester.binding.handleAppLifecycleStateChanged(state);
        }
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(nameMotion, profile.$3 ? findsNothing : findsOneWidget);
        await tester.pumpAndSettle();
        final scope = 'store-shop-${source.storeIdAt(0)}';
        expect(
          find.byKey(const ValueKey('buy-store-catalogue-toolbar')),
          findsOneWidget,
        );
        expect(source.productQueries.last.storeId, source.storeIdAt(0));
        expect(
          find.byKey(ValueKey('buy-public-store-truth-$id')),
          findsNothing,
        );
        final info = find.byKey(const ValueKey('buy-store-info-control'));
        await tester.tap(info);
        await tester.pumpAndSettle();
        final details = find.byKey(const ValueKey('buy-store-info-scroll'));
        final name = find.descendant(
          of: details,
          matching: find.byKey(const ValueKey('buy-store-details-name')),
        );
        expect(
          name,
          findsOneWidget,
          reason:
              'C10-A01 current Store name is visible exactly once in details',
        );
        final heading = tester.widget<Text>(
          find.byKey(const ValueKey('buy-store-details-name')),
        );
        expect(heading.data, source.name);
        expect(
          find.descendant(
            of: find.byKey(ValueKey('buy-public-store-truth-$id')),
            matching: find.text(source.name),
          ),
          findsNothing,
          reason: 'The current Store panel must not repeat its heading',
        );
        expect(heading.maxLines, isNull);
        expect(heading.overflow, isNot(TextOverflow.ellipsis));
        expect(
          tester.getRect(name).right,
          lessThanOrEqualTo(
            tester.getRect(find.byTooltip('Close store details')).left,
          ),
        );
        await captureR66Visual(
          tester,
          'C10-A01-store-name-${profile.$1}-${profile.$2}-${profile.$3}',
        );
        final detailsWidget = tester.widget<SingleChildScrollView>(details);
        expect(
          (detailsWidget.padding! as EdgeInsets).bottom,
          greaterThanOrEqualTo(60),
        );
        final detailsScrollable = find
            .descendant(of: details, matching: find.byType(Scrollable))
            .first;
        final detailsPosition = tester
            .state<ScrollableState>(detailsScrollable)
            .position;
        detailsPosition.jumpTo(detailsPosition.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byWidget(detailsWidget.child!)).bottom,
          lessThanOrEqualTo(752),
        );
        await captureR66Visual(
          tester,
          'store-details-safe-bottom-${profile.$1}-${profile.$2}-${profile.$3}',
        );
        detailsPosition.jumpTo(0);
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey('buy-public-store-truth-$id')),
          findsOneWidget,
        );
        await tester.tap(find.byTooltip('Close store details'));
        await tester.pumpAndSettle();
        final collect = find.byKey(
          const ValueKey('buy-public-store-order-collection'),
        );
        expect(collect, findsNothing);
        expect(find.text('Shop now\nPick up when ready'), findsNothing);
        final storeName = tester.widget<Text>(
          find.byKey(const ValueKey('buy-store-toolbar-name')),
        );
        expect(storeName.data, source.name);
        expect(storeName.maxLines, isNull);
        expect(storeName.softWrap, isTrue);
        final field = find.byKey(const ValueKey('buy-store-product-search'));
        expect(tester.widget<TextField>(field).decoration?.label, isNull);
        await _revealPagedHeader(tester, scope, field);
        await captureR66Visual(
          tester,
          'store-unboxed-search-${profile.$1}-${profile.$2}-${profile.$3}',
        );
        await tester.enterText(field, 'sku 4999');
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-store-toolbar-name')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('buy-store-search-finish')),
          findsOneWidget,
        );
        expect(source.productQueries.last.query, 'sku 4999');
        expect(source.productQueries.last.storeId, source.storeIdAt(0));
        expect(session.catalogueQuery().key, homeQuery);
        await tester.enterText(field, '');
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-store-search-finish')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('buy-store-toolbar-name')),
          findsOneWidget,
        );
        final filter = find.byKey(const ValueKey('buy-store-filter-control'));
        await _revealPagedHeader(tester, scope, filter);
        await tester.tap(filter);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-store-price-100')));
        final apply = find.byKey(const ValueKey('buy-store-filters-apply'));
        expect(apply.hitTestable(), findsOneWidget);
        expect(tester.getSize(apply).width, greaterThanOrEqualTo(120));
        expect(tester.getSize(apply).height, lessThanOrEqualTo(100));
        expect(tester.getRect(apply).bottom, lessThanOrEqualTo(752));
        if (profile.$2 == 1) {
          expect(
            tester.getSize(find.byType(BottomSheet).last).height,
            lessThan(430),
          );
        }
        await captureR66Visual(
          tester,
          "store-repair-filter-${profile.$1}-${profile.$2}-${profile.$3}",
        );
        await tester.tap(apply);
        await tester.pumpAndSettle();
        expect(source.productQueries.last.maximumPrice, 100);
        expect(source.productQueries.last.storeId, source.storeIdAt(0));
        expect(session.catalogueQuery().key, homeQuery);
        await _revealPagedHeader(tester, scope, filter);
        await tester.tap(filter);
        await tester.pumpAndSettle();
        final reset = find.text('Reset store filters');
        await tester.ensureVisible(reset);
        await tester.tap(reset);
        await tester.ensureVisible(apply);
        await tester.tap(apply);
        await tester.pumpAndSettle();
        final category = find.byKey(
          const ValueKey('buy-store-category-control'),
        );
        await _revealPagedHeader(tester, scope, category);
        await tester.tap(category);
        await tester.pumpAndSettle();
        final categoryId = session.product(id).categoryId;
        final choice = find.byKey(ValueKey('buy-store-category-$categoryId'));
        await tester.ensureVisible(choice);
        await tester.tap(choice);
        await tester.pumpAndSettle();
        expect(source.productQueries.last.categoryId, categoryId);
        expect(session.catalogueQuery().key, homeQuery);
        final saved = find.byKey(const ValueKey('buy-store-saved-control'));
        await _revealPagedHeader(tester, scope, saved);
        await tester.tap(saved);
        await tester.pumpAndSettle();
        final savedList = find.byKey(
          ValueKey('buy-store-saved-list-${source.storeIdAt(0)}'),
        );
        expect(savedList, findsOneWidget);
        expect(
          find.descendant(
            of: savedList,
            matching: find.byKey(ValueKey('buy-product-$otherId')),
          ),
          findsNothing,
        );
        final card = find.descendant(
          of: savedList,
          matching: find.byKey(ValueKey('buy-product-$id')),
        );
        expect(card, findsOneWidget);
        await tester.ensureVisible(card);
        await tester.tap(
          find.descendant(
            of: card,
            matching: find.byKey(ValueKey('buy-grid-packshot-$id')),
          ),
        );
        await tester.pumpAndSettle();
        expect(session.selectedProductId, id);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(savedList, findsOneWidget);
        final otherStore = find.byKey(
          ValueKey('buy-store-more-${source.storeIdAt(10)}'),
        );
        final savedScroll = find
            .descendant(of: savedList, matching: find.byType(Scrollable))
            .first;
        await tester.scrollUntilVisible(
          otherStore,
          400,
          scrollable: savedScroll,
        );
        await captureR66Visual(
          tester,
          "store-repair-more-${profile.$1}-${profile.$2}-${profile.$3}",
        );
        await tester.tap(otherStore);
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            ValueKey('buy-paged-scroll-store-shop-${source.storeIdAt(10)}'),
          ),
          findsOneWidget,
        );
        expect(source.productQueries.last.storeId, source.storeIdAt(10));
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(savedList, findsOneWidget);
        final close = find.byKey(const ValueKey('buy-paged-store-close'));
        await tester.scrollUntilVisible(close, -400, scrollable: savedScroll);
        await tester.pumpAndSettle();
        expect(close.hitTestable(), findsOneWidget);
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('buy-shop-seller-sheet-$id')), findsNothing);
        expect(session.catalogueQuery().key, homeQuery);
        expect(session.isSaved(otherId), isTrue);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
  setUpAll(() async {
    const fontPath = String.fromEnvironment('BUY_SKU_DEVANAGARI_FONT');
    if (fontPath.isEmpty) return;
    final loader = FontLoader('NotoSansDevanagari')
      ..addFont(
        File(fontPath).readAsBytes().then((bytes) => bytes.buffer.asByteData()),
      );
    await loader.load();
  });
  for (final width in [320.0, 360.0, 390.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('SKU prescription metadata complete $width $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.reset);
        final ids = [
          'm-telmisartan-40',
          'm-atorvastatin-10',
          'm-metformin-500',
        ];
        final names = [
          'Long provider medicine name with exact model 40 and extended release product information',
          'हनुमाना Pharmacy दवा product model 500 preserved exactly',
          'PROVIDERPRODUCTIDENTIFIERABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        ];
        final products = [
          for (var index = 0; index < ids.length; index++)
            BuyV2Catalogue.allProducts
                .firstWhere((product) => product.id == ids[index])
                .copyWith(
                  title: names[index],
                  pack:
                      'Three individually sealed strips of ten tablets in each pack',
                ),
        ];
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: false,
          commerceAdapter: _CollectionHeaderCommerce(products),
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        await session.restoreCommerce();
        session.openDestination(BuyV2Destination.medicine);
        expect(session.approveSavedPrescription('meera'), isTrue);
        expect(session.approveSavedPrescription('arvind'), isTrue);
        expect(session.matchedPrescriptionProducts, hasLength(3));
        await tester.pumpWidget(_app(session, textScale: scale));
        await tester.pumpAndSettle();
        final links = [
          for (final product in products)
            find.byKey(ValueKey('buy-prescription-match-action-${product.id}')),
        ];
        for (var index = 0; index < products.length; index++) {
          final link = links[index];
          expect(link, findsOneWidget);
          expect(tester.getSize(link).width, greaterThanOrEqualTo(44));
          expect(tester.getSize(link).height, greaterThanOrEqualTo(44));
          for (final content in [
            products[index].title,
            products[index].pack,
            buyV2Money(products[index].price),
          ]) {
            final field = find.descendant(
              of: link,
              matching: find.text(content),
            );
            expect(field, findsOneWidget);
            final paragraph = tester.renderObject<RenderParagraph>(field);
            expect(paragraph.didExceedMaxLines, isFalse);
            final natural = TextPainter(
              text: paragraph.text,
              textDirection: paragraph.textDirection,
              textScaler: paragraph.textScaler,
            )..layout(maxWidth: paragraph.size.width);
            expect(
              paragraph.size.height + 1,
              greaterThanOrEqualTo(natural.height),
            );
            natural.dispose();
            expect(
              tester.getRect(link).contains(tester.getRect(field).topLeft),
              isTrue,
            );
            expect(
              tester.getRect(link).contains(tester.getRect(field).bottomRight),
              isTrue,
            );
          }
        }
        final bounds = links.map(tester.getRect).toList();
        for (var index = 1; index < bounds.length; index++) {
          if (scale == 1.0) {
            expect(bounds[index].top, closeTo(bounds.first.top, 1));
            expect(bounds[index].left, greaterThan(bounds[index - 1].right));
          } else {
            expect(bounds[index].top, greaterThan(bounds[index - 1].bottom));
          }
        }
        expect(bounds.last.right, lessThanOrEqualTo(width));
        final firstTitle = find.descendant(
          of: links.first,
          matching: find.text(names.first),
        );
        await tester.ensureVisible(firstTitle);
        await tester.pumpAndSettle();
        expect(firstTitle.hitTestable(), findsOneWidget);
        await captureR66Visual(
          tester,
          'sku-prescription-${width.toInt()}-$scale',
        );
        await tester.tap(firstTitle);
        await tester.pumpAndSettle();
        expect(session.selectedProductId, ids.first);
        expect(session.view, BuyV2View.product);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.catalogue);
        expect(session.itemCount, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final width in [320.0, 360.0, 390.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      for (final withLines in [true, false]) {
        for (final largeTotal in [false, true]) {
          testWidgets(
            'SKU order snapshot preview $width $scale lines $withLines large $largeTotal',
            (tester) async {
              tester.view.devicePixelRatio = 1;
              tester.view.physicalSize = Size(width, 800);
              addTearDown(tester.view.reset);
              final base = BuyV2Catalogue.allProducts
                  .firstWhere((p) => p.id == 's-eggs')
                  .copyWith(price: largeTotal ? 16666666 : null);
              final archived = base.copyWith(
                title:
                    'Original हनुमाना free-range eggs family selection model 30 preserved',
                pack:
                    'Tray of 30 individually protected eggs in reusable family packaging',
              );
              final order = BuyV2Order(
                id: 'MS-SKU-TEST',
                destination: BuyV2Destination.shop,
                title: 'Shop order',
                itemSummary: '3 products',
                total: withLines || largeTotal ? base.price * 6 : 1234,
                partner: 'hanumana ram beniwal sardarpura jodhpure store',
                partnerType: 'Retailer',
                promise:
                    'Delivery after all packages have been checked and accepted by the regional freight provider',
                destinationLabel: 'Home',
                progress: .4,
                status: BuyV2OrderStatus.preparing,
                lines: withLines
                    ? [
                        BuyV2CartLine(product: archived, quantity: 2),
                        BuyV2CartLine(
                          product: base.copyWith(
                            id: 'snapshot-b',
                            title: 'Second original product',
                          ),
                          quantity: 3,
                        ),
                        BuyV2CartLine(
                          product: base.copyWith(
                            id: 'snapshot-c',
                            title: 'Third original product',
                          ),
                          quantity: 1,
                        ),
                      ]
                    : const [],
              );
              final core = BuySession();
              final session = BuyV2Session(
                core: core,
                reviewDataEnabled: false,
                commerceAdapter: _SkuSnapshotCommerce(
                  order,
                  base.copyWith(title: 'Changed live catalogue name'),
                ),
              );
              addTearDown(session.dispose);
              addTearDown(core.dispose);
              await session.restoreCommerce();
              session.openOrders();
              await tester.pumpWidget(_app(session, textScale: scale));
              await tester.pumpAndSettle();
              final card = find.byKey(
                const ValueKey('buy-order-card-MS-SKU-TEST'),
              );
              expect(card, findsOneWidget);
              if (withLines) {
                expect(
                  find.descendant(
                    of: card,
                    matching: find.text(archived.title),
                  ),
                  findsOneWidget,
                );
                expect(
                  find.descendant(
                    of: card,
                    matching: find.textContaining('Quantity 2'),
                  ),
                  findsOneWidget,
                );
                expect(
                  find.descendant(
                    of: card,
                    matching: find.text('+ 1 more product'),
                  ),
                  findsOneWidget,
                );
                expect(
                  find.descendant(
                    of: card,
                    matching: find.text('Changed live catalogue name'),
                  ),
                  findsNothing,
                );
                expect(order.lines.first.product.title, archived.title);
              } else {
                expect(
                  find.descendant(of: card, matching: find.text('Shop order')),
                  findsOneWidget,
                );
                expect(
                  find.descendant(
                    of: card,
                    matching: find.textContaining('Quantity'),
                  ),
                  findsNothing,
                );
              }
              for (final element
                  in find
                      .descendant(of: card, matching: find.byType(RichText))
                      .evaluate()) {
                final render = element.renderObject;
                if (render is RenderParagraph) {
                  expect(render.didExceedMaxLines, isFalse);
                  final natural = TextPainter(
                    text: render.text,
                    textDirection: render.textDirection,
                    textScaler: render.textScaler,
                  )..layout(maxWidth: render.size.width);
                  expect(
                    render.size.height + 1,
                    greaterThanOrEqualTo(natural.height),
                    reason: render.text.toPlainText(),
                  );
                  natural.dispose();
                }
              }
              expect(tester.takeException(), isNull);
              await captureR66Visual(
                tester,
                'sku-orders-$width-$scale-$withLines-$largeTotal',
              );
              final provider = find.descendant(
                of: card,
                matching: find.text('${order.partner} · ${order.partnerType}'),
              );
              expect(provider, findsOneWidget);
              await tester.ensureVisible(provider);
              await tester.pumpAndSettle();
              expect(provider.hitTestable(), findsOneWidget);
              await captureR66Visual(
                tester,
                'sku-orders-provider-$width-$scale-$withLines-$largeTotal',
              );
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final width in [320.0, 360.0, 390.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets(
          'SKU provider names adaptive ${destination.name} $width $scale',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = Size(width, 800);
            addTearDown(tester.view.reset);
            final core = BuySession();
            final source = _PagedWidgetSource(
              destination,
              providerMetadata: true,
            );
            final session = BuyV2Session(
              core: core,
              reviewDataEnabled: true,
              cataloguePageSource: source,
              initialCatalogueRegionId: 'jodhpur',
            )..destination = destination;
            addTearDown(session.dispose);
            addTearDown(core.dispose);
            await tester.pumpWidget(_app(session, textScale: scale));
            await tester.pumpAndSettle();
            for (final product in source.pages.first.items.take(3)) {
              final card = find.byKey(ValueKey('buy-product-${product.id}'));
              final seller = find.descendant(
                of: card,
                matching: find.text(product.seller),
              );
              expect(seller, findsOneWidget);
              final paragraph = tester.renderObject<RenderParagraph>(seller);
              expect(paragraph.didExceedMaxLines, isFalse);
              final natural = TextPainter(
                text: paragraph.text,
                textDirection: paragraph.textDirection,
                textScaler: paragraph.textScaler,
              )..layout(maxWidth: paragraph.size.width);
              expect(
                paragraph.size.height + 1,
                greaterThanOrEqualTo(natural.height),
              );
              natural.dispose();
              expect(
                tester
                    .getRect(card)
                    .contains(tester.getRect(seller).bottomRight),
                isTrue,
              );
              await tester.ensureVisible(seller);
              await tester.pumpAndSettle();
              await captureR66Visual(
                tester,
                'provider-name-${destination.name}-$width-$scale-${product.id}',
              );
            }
            if (scale == 1.0 && destination == BuyV2Destination.shop) {
              final products = source.pages.first.items;
              final first = tester.getSize(
                find.byKey(ValueKey('buy-product-${products.first.id}')),
              );
              final next = tester.getSize(
                find.byKey(ValueKey('buy-product-${products[3].id}')),
              );
              expect(
                first.height,
                greaterThan(next.height),
                reason:
                    'Long first-row provider does not pad later product rows',
              );
            }
            final firstProduct = source.pages.first.items.first;
            expect(session.addProduct(firstProduct.id), isTrue);
            final quantity = session.quantityFor(firstProduct.id);
            source.updatedProviderName =
                'hanumana ram beniwal sardarpura jodhpure store regional distribution and delivery centre';
            final pagesBeforeRefresh = source.pages.length;
            final refresh = find.byKey(
              ValueKey('buy-page-status-catalogue-${destination.name}'),
            );
            await _performCatalogueAction(tester, refresh, 'Refresh products');
            await tester.pumpAndSettle();
            expect(source.pages.length, greaterThan(1));
            final refreshedFirstPage = source.pages
                .skip(pagesBeforeRefresh)
                .singleWhere((page) => page.startIndex == 0);
            expect(refreshedFirstPage.items.first.id, firstProduct.id);
            expect(
              refreshedFirstPage.items.first.seller,
              source.updatedProviderName,
            );
            final updatedCard = find.byKey(
              ValueKey('buy-product-${firstProduct.id}'),
            );
            final updatedName = find.descendant(
              of: updatedCard,
              matching: find.text(source.updatedProviderName!),
            );
            expect(updatedName, findsOneWidget);
            expect(session.quantityFor(firstProduct.id), quantity);
            final updatedParagraph = tester.renderObject<RenderParagraph>(
              updatedName,
            );
            expect(updatedParagraph.didExceedMaxLines, isFalse);
            expect(
              tester
                  .getRect(updatedCard)
                  .contains(tester.getRect(updatedName).bottomRight),
              isTrue,
            );
            await tester.ensureVisible(updatedName);
            await tester.pumpAndSettle();
            await captureR66Visual(
              tester,
              'provider-update-${destination.name}-$width-$scale',
            );
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
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'SKU swipe pages and compact navigation ${destination.name} $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(360, 800);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final source = _PagedWidgetSource(
            destination,
            contrastingPagePrices: true,
          );
          final session = BuyV2Session(
            core: core,
            reviewDataEnabled: true,
            cataloguePageSource: source,
            initialCatalogueRegionId: 'jodhpur',
          )..destination = destination;
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          await tester.pumpWidget(_app(session, textScale: scale));
          await tester.pumpAndSettle();
          final scope = 'catalogue-${destination.name}';
          final scroll = find.byKey(ValueKey('buy-paged-scroll-$scope'));
          final controller = tester.widget<ListView>(scroll).controller!;
          final status = find.byKey(ValueKey('buy-page-status-$scope'));
          addTearDown(() => session.releaseCatalogueProducts(scope));
          final initialQuery = source.requests.first;
          Future<void> expectStart(int start) async {
            controller.jumpTo(0);
            await tester.pumpAndSettle();
            expect(
              tester.widget<Semantics>(status).properties.label,
              startsWith('${start + 1}'),
            );
            expect(find.byKey(ValueKey('buy-page-range-$scope')), findsNothing);
            expect(
              find.byKey(ValueKey('buy-page-range-$scope-bottom')),
              findsNothing,
            );
            expect(
              find.textContaining(RegExp(r'[0-9]+–[0-9]+ of ')),
              findsNothing,
            );
            expect(session.itemCount, 0);
            expect(session.view, BuyV2View.catalogue);
            expect(source.requests.last, initialQuery);
            expect(tester.takeException(), isNull);
          }

          Future<void> swipe(double dx, {bool settle = true}) async {
            controller.jumpTo(0);
            await tester.pump();
            final viewport = tester.getRect(scroll);
            final y = viewport.top + 230;
            await tester.dragFrom(Offset(dx < 0 ? 280 : 80, y), Offset(dx, 0));
            if (settle) {
              await tester.pumpAndSettle();
            } else {
              await tester.pump(const Duration(milliseconds: 100));
            }
          }

          await expectStart(0);
          final topGrid = find.byKey(
            ValueKey('buy-paged-vertical-grid-$scope'),
          );
          expect(
            tester.getRect(topGrid).top - tester.getRect(scroll).top,
            closeTo(6, 1),
          );
          double? previewWidth;
          String? previewId;
          if (scale == 1) {
            final firstPage = source.pages.firstWhere((p) => p.startIndex == 0);
            final nextPage = source.pages.lastWhere((p) => p.startIndex == 40);
            List<Rect> cards(Finder grid, Iterable<BuyV2Product> items) => [
              for (final product in items.take(3))
                tester.getRect(
                  find.descendant(
                    of: grid,
                    matching: find.byKey(ValueKey('buy-product-${product.id}')),
                  ),
                ),
            ];
            final currentRects = cards(topGrid, firstPage.items);
            expect(currentRects[1].top, closeTo(currentRects.first.top, 1));
            expect(currentRects[2].top, greaterThan(currentRects.first.bottom));
            final viewport = tester.getRect(scroll);
            final gesture = await tester.startGesture(
              Offset(280, viewport.top + 230),
            );
            await gesture.moveBy(const Offset(-30, 0));
            await tester.pump();
            await gesture.moveBy(const Offset(-120, 0));
            await tester.pump();
            final incoming = find.byKey(const ValueKey('buy-incoming-grid'));
            expect(incoming, findsOneWidget);
            final previewRects = cards(incoming, nextPage.items);
            expect(previewRects[1].top, closeTo(previewRects[0].top, 1));
            expect(previewRects[2].top, greaterThan(previewRects[0].top));
            expect(
              previewRects[0].width,
              greaterThanOrEqualTo(currentRects[0].width),
            );
            previewId = nextPage.items.first.id;
            previewWidth = previewRects.first.width;
            final highlight = find.descendant(
              of: incoming,
              matching: find.byKey(ValueKey('buy-price-highlight-$previewId')),
            );
            final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(of: highlight, matching: find.byType(RichText)),
            );
            final boxes = paragraph.getBoxesForSelection(
              TextSelection(
                baseOffset: 0,
                extentOffset: paragraph.text.toPlainText().length,
              ),
            );
            expect(boxes, isNotEmpty);
            for (final box in boxes) {
              expect(box.top, closeTo(boxes.first.top, .1));
            }
            await gesture.cancel();
            await tester.pumpAndSettle();
          }
          await _performCatalogueAction(tester, status, 'Next products');
          await expectStart(40);
          if (previewWidth != null) {
            expect(
              tester
                  .getSize(find.byKey(ValueKey('buy-product-$previewId')))
                  .width,
              closeTo(previewWidth, .1),
            );
          }
          await _performCatalogueAction(tester, status, 'Previous products');
          await expectStart(0);
          final beforePull = source.requests.length;
          final pullRect = tester.getRect(scroll);
          await tester.dragFrom(
            Offset(pullRect.center.dx, pullRect.top + 30),
            const Offset(0, 300),
          );
          await tester.pumpAndSettle();
          expect(source.requests.length, beforePull + 2);
          await expectStart(0);
          final initialRequests = source.requests.length;
          await swipe(170);
          expect(source.requests.length, initialRequests);
          await swipe(-30);
          expect(source.requests.length, initialRequests);
          final viewport = tester.getRect(scroll);
          await tester.dragFrom(
            Offset(180, viewport.top + 430),
            const Offset(0, -200),
          );
          await tester.pumpAndSettle();
          expect(controller.offset, greaterThan(0));
          expect(source.requests.length, initialRequests);
          await expectStart(0);

          final delay = Completer<void>();
          addTearDown(() {
            if (!delay.isCompleted) delay.complete();
          });
          source.pageDelay = delay;
          final pager = session.acquireCatalogueProducts(scope);
          source.pageDelay = null;
          await pager.refresh();
          source.pageDelay = delay;
          await tester.pump(const Duration(milliseconds: 50));
          final delayedRequests = source.requests.length;
          await swipe(-170, settle: false);
          expect(source.requests.length, delayedRequests);
          await swipe(-170, settle: false);
          expect(source.requests.length, delayedRequests);
          source.pageDelay = null;
          delay.complete();
          await tester.pumpAndSettle();
          await expectStart(40);
          await swipe(170);
          await expectStart(0);
          await swipe(-170);
          await expectStart(40);
          source.failNext = true;
          // Discard the successful speculative neighbour before exercising failure.
          await pager.refresh();
          await tester.pumpAndSettle();
          await swipe(-170);
          expect(find.text('Results could not refresh'), findsOneWidget);
          await expectStart(0);
          source.failNext = false;
          final retry = find.widgetWithText(TextButton, 'Try again');
          await tester.ensureVisible(retry);
          await tester.pumpAndSettle();
          expect(retry.hitTestable(), findsOneWidget);
          await tester.tap(retry);
          await tester.pumpAndSettle();
          await expectStart(40);
          await swipe(170);
          await expectStart(0);
          controller.jumpTo(0);
          await tester.pumpAndSettle();
          await captureR66Visual(
            tester,
            'sku-swipe-${destination.name}-$scale-top',
          );
          controller.jumpTo(controller.position.maxScrollExtent);
          await tester.pumpAndSettle();
          for (final suffix in ['', '-bottom']) {
            for (final control in ['next', 'previous', 'refresh', 'range']) {
              expect(
                find.byKey(ValueKey('buy-page-$control-$scope$suffix')),
                findsNothing,
              );
            }
          }
          final grid = find.byKey(ValueKey('buy-paged-vertical-grid-$scope'));
          final listRect = tester.getRect(scroll);
          expect(
            tester.getRect(grid).bottom,
            lessThanOrEqualTo(listRect.bottom),
          );
          expect(
            listRect.bottom - tester.getRect(grid).bottom,
            lessThanOrEqualTo(20),
          );
          await captureR66Visual(
            tester,
            'sku-swipe-${destination.name}-$scale-bottom',
          );
          await tester.dragFrom(
            Offset(listRect.right - 70, listRect.bottom - 80),
            const Offset(-170, 0),
          );
          await tester.pumpAndSettle();
          await expectStart(40);
        },
      );
    }
  }
  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    testWidgets('SKU swipe final page ${destination.name}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final source = _PagedWidgetSource(
        destination,
        providerCount: 1,
        skusPerStore: 20,
      );
      final session = BuyV2Session(
        core: core,
        reviewDataEnabled: true,
        cataloguePageSource: source,
        initialCatalogueRegionId: 'jodhpur',
      )..destination = destination;
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      await tester.pumpWidget(_app(session));
      await tester.pumpAndSettle();
      expect(source.pages.single.items, isNotEmpty);
      expect(source.pages.single.nextCursor, isNull);
      expect(source.pages.single.previousCursor, isNull);
      final scope = 'catalogue-${destination.name}';
      final viewport = tester.getRect(
        find.byKey(ValueKey('buy-paged-scroll-$scope')),
      );
      for (final dx in [-170.0, 170.0]) {
        await tester.dragFrom(
          Offset(dx < 0 ? 280 : 80, viewport.top + 230),
          Offset(dx, 0),
        );
        await tester.pumpAndSettle();
        expect(source.requests.length, 1);
        expect(session.itemCount, 0);
        expect(session.view, BuyV2View.catalogue);
      }
      final actions = tester
          .widget<Semantics>(find.byKey(ValueKey('buy-page-status-$scope')))
          .properties
          .customSemanticsActions!;
      expect(
        actions.keys.any((action) => action.label == 'Next products'),
        isFalse,
      );
      expect(
        actions.keys.any((action) => action.label == 'Previous products'),
        isFalse,
      );
      for (final direction in ['next', 'previous']) {
        expect(
          find.byKey(ValueKey('buy-page-$direction-$scope')),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
  for (final scale in [1.0, 2.0]) {
    for (final fixture in [true, false]) {
      testWidgets('SKU M02 ratings seller identity $fixture $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 800);
        addTearDown(tester.view.reset);
        final original = BuyV2Catalogue.allProducts.firstWhere(
          (product) => product.destination == BuyV2Destination.wholesale,
        );
        final product = original.copyWith(
          storeId: fixture
              ? 'buy-catalogue-dev-v1-wholesale-store-000001'
              : 'supplier-store-000001',
          seller: 'Mool Market 000001',
          sellerType: 'Manufacturer',
        );
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: false,
          commerceAdapter: _CollectionHeaderCommerce([product]),
          marketplaceTrustAdapter:
              const BuyV2CatalogueMarketplaceTrustAdapter(),
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        await session.restoreCommerce();
        session.openDestination(BuyV2Destination.wholesale);
        expect(session.openProduct(product.id), isTrue);
        await tester.pumpWidget(_app(session, textScale: scale));
        await tester.pumpAndSettle();
        final panel = find.byKey(
          ValueKey('buy-product-hero-store-${product.id}'),
        );
        final expected = fixture ? 'Mool Market 1' : 'Mool Market 000001';
        final seller = find.descendant(
          of: panel,
          matching: find.text(expected),
        );
        await tester.scrollUntilVisible(
          panel,
          240,
          scrollable: find
              .descendant(
                of: find.byKey(PageStorageKey('buy-product-${product.id}')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.ensureVisible(seller);
        await tester.pumpAndSettle();
        expect(seller.hitTestable(), findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(seller).didExceedMaxLines,
          isFalse,
        );
        expect(
          tester.getRect(panel).contains(tester.getRect(seller).bottomRight),
          isTrue,
        );
        if (fixture) {
          expect(
            find.descendant(
              of: panel,
              matching: find.text('Mool Market 000001'),
            ),
            findsNothing,
          );
        }
        expect(
          session.marketplaceTrustFor(product).partnerName,
          'Mool Market 000001',
        );
        expect(session.selectedProductId, product.id);
        expect(session.selectedProduct?.storeId, product.storeId);
        expect(session.itemCount, 0);
        expect(tester.takeException(), isNull);
        await captureR66Visual(tester, 'sku-m02-trust-seller-$fixture-$scale');
      });
    }
  }
  test('SKU metadata strips only exact development decoration', () {
    final base = BuyV2Catalogue.products.firstWhere(
      (p) => p.destination == BuyV2Destination.shop,
    );
    final fixture = base.copyWith(
      id: 'buy-catalogue-dev-v1-shop-store-000001-sku-0081',
      storeId: 'buy-catalogue-dev-v1-shop-store-000001',
      canonicalId: 'buy-catalogue-dev-v1-shop-product-81',
      title: 'Phone 15 Pro 81',
      variant: '256 GB · SKU 81',
    );
    expect(fixture.customerTitle, 'Phone 15 Pro');
    expect(fixture.customerVariant, '256 GB');
    expect(fixture.customerContent(fixture.variant), '256 GB');
    expect(fixture.customerContent('Phone 15 Pro 81'), 'Phone 15 Pro');
    expect(
      fixture.customerContent('Compatible with SKU 81'),
      'Compatible with SKU 81',
    );
    expect(fixture.customerContent('Mool Market 000001'), 'Mool Market 1');
    final description =
        '${fixture.title} \u00b7 ${fixture.variant}. '
        '${fixture.pack} at ${fixture.unitPrice}.';
    expect(
      fixture.customerContent(description),
      'Phone 15 Pro \u00b7 256 GB. ${fixture.pack} at ${fixture.unitPrice}.',
    );
    expect(
      fixture.customerContent('$description Supplier note SKU 81'),
      '$description Supplier note SKU 81',
    );
    expect(fixture.title, 'Phone 15 Pro 81');
    expect(fixture.customerSeller('Mool Market 000001'), 'Mool Market 1');
    expect(fixture.customerSeller('Real Store 000001'), 'Real Store 000001');
    expect(
      buyV2CustomerStoreName('Mool Market 000001', 'real-store'),
      'Mool Market 000001',
    );
    expect(
      buyV2CustomerStoreName(
        'Mool Market 000000',
        'buy-catalogue-dev-v1-shop-store-000000',
      ),
      'Mool Market 000000',
    );

    for (final invalid in [
      fixture.copyWith(id: 'supplier-product-81'),
      fixture.copyWith(storeId: 'different-store'),
      fixture.copyWith(canonicalId: 'supplier-model-81'),
      fixture.copyWith(
        id: 'buy-catalogue-dev-v1-wholesale-store-000001-sku-0081',
      ),
    ]) {
      expect(invalid.customerTitle, invalid.title);
      expect(invalid.customerVariant, invalid.variant);
      expect(invalid.customerContent(invalid.variant), invalid.variant);
      expect(invalid.customerContent(description), description);
    }
    expect(
      fixture.copyWith(title: 'Phone 81 Pro').customerTitle,
      'Phone 81 Pro',
    );
    expect(
      fixture.copyWith(variant: 'SKU 81 compatible').customerVariant,
      'SKU 81 compatible',
    );
  });
  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final width in [320.0, 360.0, 390.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('SKU metadata glance ${destination.name} $width $scale', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 800);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final source = _PagedWidgetSource(destination);
          final session = BuyV2Session(
            core: core,
            reviewDataEnabled: true,
            cataloguePageSource: source,
            initialCatalogueRegionId: 'jodhpur',
          )..destination = destination;
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          await tester.pumpWidget(_app(session, textScale: scale));
          await tester.pumpAndSettle();
          expect(source.pages, isNotEmpty);
          final product = source.pages.first.items.first;
          final card = find.byKey(ValueKey('buy-product-${product.id}'));
          expect(card, findsOneWidget);
          final title = find.descendant(
            of: card,
            matching: find.text(product.customerTitle),
          );
          expect(title, findsOneWidget);
          final mediaLabels = find
              .descendant(of: card, matching: find.byType(Semantics))
              .evaluate()
              .map(
                (element) =>
                    (element.widget as Semantics).properties.label ?? '',
              )
              .where(
                (label) =>
                    label.contains('Supplier photo') ||
                    label.contains('Product photo'),
              );
          expect(mediaLabels, isNotEmpty);
          for (final label in mediaLabels) {
            expect(label, contains(product.customerTitle));
            if (product.title != product.customerTitle) {
              expect(label, isNot(contains(product.title)));
            }
          }
          final cardRect = tester.getRect(card);
          final priceHighlight = find.byKey(
            ValueKey('buy-price-highlight-${product.id}'),
          );
          final highlight = tester.widget<Container>(priceHighlight);
          final decoration = highlight.decoration! as BoxDecoration;
          expect(decoration.gradient, isNull);
          expect(decoration.color, const Color(0xFFFFE082));
          expect(
            tester.getSize(priceHighlight).width,
            lessThanOrEqualTo(cardRect.width - 12),
          );
          if (scale == 1.0) {
            final firstProducts = source.pages.first.items.take(4).toList();
            expect(firstProducts.length, 4);
            final rects = firstProducts
                .map(
                  (item) => tester.getRect(
                    find.byKey(ValueKey('buy-product-${item.id}')),
                  ),
                )
                .toList();
            final columns =
                destination == BuyV2Destination.wholesale && width == 320
                ? 1
                : 2;
            if (columns > 1) {
              expect(rects[1].top, closeTo(rects[0].top, 1));
              expect(rects[1].left, greaterThan(rects[0].right));
            }
            if (columns == 3) {
              expect(rects[2].top, closeTo(rects[0].top, 1));
              expect(rects[2].left, greaterThan(rects[1].right));
            }
            expect(rects[columns - 1].right, lessThanOrEqualTo(width));
            expect(rects[columns].top, closeTo(rects[0].bottom + 10, 1));
          }
          expect(cardRect.contains(tester.getRect(title).topLeft), isTrue);
          expect(cardRect.contains(tester.getRect(title).bottomRight), isTrue);
          for (final element
              in find
                  .descendant(of: card, matching: find.byType(RichText))
                  .evaluate()) {
            final render = element.renderObject;
            if (render is RenderParagraph) {
              expect(
                render.didExceedMaxLines,
                isFalse,
                reason: (element.widget as RichText).text.toPlainText(),
              );
            }
          }
          expect(tester.takeException(), isNull);
          await captureR66Visual(
            tester,
            'sku-baseline-${destination.name}-${width.toInt()}-$scale',
          );
        });
      }
    }
  }
  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('SKU long metadata ${destination.name} $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 844);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final source = _PagedWidgetSource(destination, longMetadata: true);
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: true,
          cataloguePageSource: source,
          initialCatalogueRegionId: 'jodhpur',
        )..destination = destination;
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        await tester.pumpWidget(_app(session, textScale: scale));
        await tester.pumpAndSettle();
        final product = source.pages.first.items.first;
        final card = find.byKey(ValueKey('buy-product-${product.id}'));
        expect(card, findsOneWidget);
        for (final text in [
          product.title,
          product.pack,
          product.unitPrice,
          product.seller,
        ]) {
          final field = find.descendant(of: card, matching: find.text(text));
          expect(field, findsOneWidget);
          expect(
            tester.getRect(card).contains(tester.getRect(field).topLeft),
            isTrue,
          );
          expect(
            tester.getRect(card).contains(tester.getRect(field).bottomRight),
            isTrue,
          );
        }
        for (final element
            in find
                .descendant(of: card, matching: find.byType(RichText))
                .evaluate()) {
          final paragraph = element.renderObject;
          if (paragraph is RenderParagraph) {
            expect(
              paragraph.didExceedMaxLines,
              isFalse,
              reason: paragraph.text.toPlainText(),
            );
          }
        }
        final price = find.descendant(
          of: card,
          matching: find.text('\u20b91 crore'),
        );
        expect(price, findsOneWidget);
        expect(product.price, 10000000);
        expect(
          find
              .ancestor(of: price, matching: find.byType(Semantics))
              .evaluate()
              .any(
                (element) =>
                    (element.widget as Semantics).properties.label?.contains(
                      buyV2Money(product.price),
                    ) ??
                    false,
              ),
          isTrue,
          reason:
              'The exact full amount remains available to assistive technology.',
        );
        expect(
          tester.widget<Text>(price).style!.fontSize,
          greaterThanOrEqualTo(12),
        );
        expect(
          find.ancestor(of: price, matching: find.byType(FittedBox)),
          findsNothing,
        );
        final priceParagraph = tester.renderObject<RenderParagraph>(price);
        final measuredPrice = TextPainter(
          text: priceParagraph.text,
          textDirection: priceParagraph.textDirection,
          textScaler: priceParagraph.textScaler,
        )..layout(maxWidth: priceParagraph.size.width);
        expect(
          priceParagraph.size.height + .1,
          greaterThanOrEqualTo(measuredPrice.height),
        );
        expect(
          measuredPrice.computeLineMetrics(),
          hasLength(1),
          reason:
              'The exact large fixture amount must not split its digit groups.',
        );
        measuredPrice.dispose();
        await tester.ensureVisible(price);
        await tester.pumpAndSettle();
        await captureR66Visual(
          tester,
          'sku-long-price-${destination.name}-$scale',
        );
        final add = find.byKey(ValueKey('buy-add-${product.id}'));
        await tester.ensureVisible(add);
        await tester.pumpAndSettle();
        expect(add.hitTestable(), findsOneWidget);
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(session.quantityFor(product.id), product.minimumOrder);
        expect(tester.takeException(), isNull);
        await captureR66Visual(tester, 'sku-long-${destination.name}-$scale');
        session.openCart();
        await tester.pumpAndSettle();
        final cartLine = find.byKey(ValueKey('buy-cart-line-${product.id}'));
        expect(cartLine, findsOneWidget);
        final pack = find.descendant(
          of: cartLine,
          matching: find.text(
            '${product.customerVariant} \u00b7 ${product.pack}',
          ),
        );
        expect(pack, findsOneWidget);
        expect(
          tester.widget<Text>(pack).style?.fontSize,
          greaterThanOrEqualTo(11),
        );
        void expectComplete(Finder owner) {
          for (final element
              in find
                  .descendant(of: owner, matching: find.byType(RichText))
                  .evaluate()) {
            // Icon glyphs use their explicit square constraints, not the
            // natural line height used to verify complete product metadata.
            var iconGlyph = false;
            element.visitAncestorElements((ancestor) {
              if (ancestor.widget is Icon) iconGlyph = true;
              return !iconGlyph;
            });
            if (iconGlyph) continue;
            final paragraph = element.renderObject;
            if (paragraph is RenderParagraph) {
              expect(
                paragraph.didExceedMaxLines,
                isFalse,
                reason: paragraph.text.toPlainText(),
              );
              final full = TextPainter(
                text: paragraph.text,
                textDirection: paragraph.textDirection,
                textScaler: paragraph.textScaler,
                strutStyle: paragraph.strutStyle,
                textHeightBehavior: paragraph.textHeightBehavior,
                locale: paragraph.locale,
              )..layout(maxWidth: paragraph.size.width);
              expect(
                paragraph.size.height + .1,
                greaterThanOrEqualTo(full.height),
                reason: paragraph.text.toPlainText(),
              );
              full.dispose();
            }
          }
        }

        expectComplete(cartLine);
        expect(session.quantityFor(product.id), product.minimumOrder);
        expect(tester.takeException(), isNull);
        await captureR66Visual(
          tester,
          'sku-long-cart-${destination.name}-$scale',
        );
        final details = find.byKey(
          ValueKey('buy-cart-product-details-${product.id}'),
        );
        final visibleTitle = find.descendant(
          of: details,
          matching: find.text(product.customerTitle),
        );
        await Scrollable.ensureVisible(
          tester.element(visibleTitle),
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        );
        await tester.pumpAndSettle();
        expect(visibleTitle.hitTestable(), findsOneWidget);
        await tester.tap(visibleTitle);
        await tester.pumpAndSettle();
        expect(session.selectedProductId, product.id);
        final report = find.byKey(ValueKey('buy-report-product-${product.id}'));
        final productScroll = find
            .descendant(
              of: find.byKey(PageStorageKey('buy-product-${product.id}')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          report,
          240,
          scrollable: productScroll,
          maxScrolls: 40,
        );
        await tester.pumpAndSettle();
        expect(report.hitTestable(), findsOneWidget);
        await tester.tap(report);
        await tester.pumpAndSettle();
        final identity = find.byKey(
          ValueKey('buy-feedback-product-${product.id}'),
        );
        expect(identity, findsOneWidget);
        expectComplete(identity);
        expect(
          find.descendant(
            of: identity,
            matching: find.text(product.customerTitle),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await captureR66Visual(
          tester,
          'sku-long-report-${destination.name}-$scale',
        );
        final reportViewport = find.byKey(
          const ValueKey('buy-product-report-reasons-scroll'),
        );
        for (final field
            in find
                .descendant(of: identity, matching: find.byType(Text))
                .evaluate()) {
          await Scrollable.ensureVisible(field, alignment: .5);
          await tester.pumpAndSettle();
          final bounds = tester.getRect(find.byWidget(field.widget));
          final viewport = tester.getRect(reportViewport);
          expect(bounds.top, greaterThanOrEqualTo(viewport.top - .1));
          expect(bounds.bottom, lessThanOrEqualTo(viewport.bottom + .1));
        }
        await captureR66Visual(
          tester,
          'sku-long-report-facts-${destination.name}-$scale',
        );
        final close = find.byKey(const ValueKey('buy-close-product-report'));
        await tester.ensureVisible(close);
        await tester.pumpAndSettle();
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(identity, findsNothing);
        expect(session.quantityFor(product.id), product.minimumOrder);
      });
    }
  }
  for (final id in ['s-dog-food', 's-shampoo']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('RV6 fixture access $id text $scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 844);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          customerStateStore: _FixtureCustomerStore(),
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        await tester.pumpWidget(_app(session, textScale: scale));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
        await tester.pumpAndSettle();
        final scroll = find
            .descendant(
              of: find.byKey(const ValueKey('buy-discovery-refinement-list')),
              matching: find.byType(Scrollable),
            )
            .first;
        final tools = find.byKey(const ValueKey('buy-refine-section-tools'));
        await tester.scrollUntilVisible(tools, 160, scrollable: scroll);
        final title = find.descendant(
          of: tools,
          matching: find.text('Shopping tools'),
        );
        await Scrollable.ensureVisible(tester.element(title), alignment: .5);
        await tester.pumpAndSettle();
        await tester.tap(title);
        await tester.pumpAndSettle();
        final action = find.byKey(ValueKey('buy-rv6-review-fixture-$id'));
        const enabled =
            bool.fromEnvironment('MOOLSOCIAL_UI_REVIEW_ONLY') &&
            bool.fromEnvironment('MOOLSOCIAL_DEVICE_REVIEW') &&
            String.fromEnvironment('MOOLSOCIAL_CANDIDATE_ID') ==
                'UAW-CURSOR-REDMI-RV6-FIXTURE-20260914';
        if (!enabled) {
          expect(action, findsNothing);
          expect(session.view, BuyV2View.catalogue);
          return;
        }
        await tester.scrollUntilVisible(action, 100, scrollable: scroll);
        await Scrollable.ensureVisible(tester.element(action), alignment: .5);
        await tester.pumpAndSettle();
        await captureR66Visual(tester, 'rv6-fixture-$id-tools-$scale');
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.product);
        expect(session.selectedProductId, id);
        expect(session.quantityFor(id), 0);
        expect(
          session.addProduct(id),
          isFalse,
          reason: 'Fixture access must preserve original orderability',
        );
        expect(session.quantityFor(id), 0);
        expect(
          session
              .recentlyViewedProductsFor(BuyV2Destination.shop)
              .any((product) => product.id == id),
          isTrue,
        );
        await captureR66Visual(tester, 'rv6-fixture-$id-product-$scale');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.catalogue);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final id in ['s-eggs', 'w-notebook']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'RV6 D002 last Store item removal retains catalogue $id text $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(390, 844);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          session.addProduct(id);
          final product = session.product(id);
          session.openProduct(id);
          await tester.pumpWidget(_app(session, textScale: scale));
          await tester.pumpAndSettle();
          final shop = product.destination == BuyV2Destination.shop;
          final prefix = shop ? 'buy-shop-seller' : 'buy-wholesale-supplier';
          final storeAction = find.byKey(
            ValueKey(
              '${shop ? 'buy-shop-seller-action' : 'buy-wholesale-store-action'}-$id',
            ),
          );
          await _revealProductAction(tester, id, storeAction);
          await tester.tap(storeAction);
          await tester.pumpAndSettle();
          Future<void> browseAll() async {
            final action = find.byKey(ValueKey('$prefix-view-more-$id'));
            await tester.ensureVisible(action);
            await tester.tap(action);
            await tester.pumpAndSettle();
          }

          await browseAll();
          final full = find.byKey(ValueKey('$prefix-full-catalogue-list'));
          expect(full, findsOneWidget);
          await tester.tap(
            find.byKey(const ValueKey('buy-store-cart-bar')).hitTestable(),
          );
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.cart);
          final continueStore = find.byKey(
            const ValueKey('buy-cart-continue-store'),
          );
          await tester.scrollUntilVisible(
            continueStore,
            160,
            scrollable: find
                .descendant(
                  of: find.byKey(
                    PageStorageKey('buy-cart-${session.cartScope.name}'),
                  ),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pumpAndSettle();
          expect(continueStore.hitTestable(), findsOneWidget);
          await tester.tap(continueStore);
          await tester.pumpAndSettle();
          await browseAll();
          final card = find.descendant(
            of: full,
            matching: find.byKey(ValueKey('buy-product-$id')),
          );
          final remove = find.descendant(
            of: card,
            matching: find.byTooltip('Remove from Cart'),
          );
          await tester.ensureVisible(remove);
          await tester.tap(remove);
          await tester.pumpAndSettle();
          expect(session.quantityFor(id), 0);
          expect(
            full,
            findsOneWidget,
            reason: 'Removing a cart line must not leave the Store',
          );
          expect(
            find.byKey(const ValueKey('buy-store-cart-bar')).hitTestable(),
            findsNothing,
          );
          expect(
            find.descendant(
              of: full,
              matching: find.byKey(ValueKey('buy-add-$id')),
            ),
            findsOneWidget,
          );
          await tester.pump(const Duration(seconds: 4));
          await tester.pumpAndSettle();
          expect(
            full,
            findsOneWidget,
            reason: 'Later basket feedback must also retain the Store',
          );
          await captureR66Visual(
            tester,
            'rv6-d002-$id-text-$scale-empty-store',
          );
          final add = find.descendant(
            of: full,
            matching: find.byKey(ValueKey('buy-add-$id')),
          );
          await tester.ensureVisible(add);
          await tester.pumpAndSettle();
          await tester.ensureVisible(add);
          await tester.pumpAndSettle();
          expect(add.hitTestable(), findsOneWidget);
          await tester.tap(add);
          await tester.pumpAndSettle();
          expect(session.quantityFor(id), product.minimumOrder);
          expect(full, findsOneWidget);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.byKey(ValueKey('$prefix-sheet-$id')), findsOneWidget);
          session.openDestination(
            shop ? BuyV2Destination.wholesale : BuyV2Destination.shop,
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(ValueKey('$prefix-sheet-$id')),
            findsNothing,
            reason: 'Explicit destination changes must still leave the Store',
          );
          expect(session.quantityFor(id), product.minimumOrder);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'RV6 D002 paged Store last item retains category ${destination.name} text $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(390, 844);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final source = _StoreJourneySource(destination);
          final id = source.productIdAt(0, 0);
          final session = BuyV2Session(
            core: core,
            reviewDataEnabled: true,
            cataloguePageSource: source,
            initialCatalogueRegionId: 'jodhpur',
          )..destination = destination;
          await session.openLinkedProduct(id);
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          session.addProduct(id);
          final product = session.product(id);
          session.openProduct(id);
          await tester.pumpWidget(_app(session, textScale: scale));
          await tester.pumpAndSettle();
          final shop = product.destination == BuyV2Destination.shop;
          final prefix = shop ? 'buy-shop-seller' : 'buy-wholesale-supplier';
          final storeAction = find.byKey(
            ValueKey(
              '${shop ? 'buy-shop-seller-action' : 'buy-wholesale-store-action'}-$id',
            ),
          );
          await _revealProductAction(tester, id, storeAction);
          await tester.tap(storeAction);
          await tester.pumpAndSettle();
          Future<void> browseAll() async {
            if (session.pagedCatalogueEnabled) {
              expect(
                find.byKey(const ValueKey('buy-store-catalogue-toolbar')),
                findsOneWidget,
              );
              return;
            }
            final action = find.byKey(ValueKey('$prefix-view-more-$id'));
            await tester.ensureVisible(action);
            await tester.tap(action);
            await tester.pumpAndSettle();
          }

          await browseAll();
          final storeScope = 'store-${destination.name}-${source.storeIdAt(0)}';
          final full = find.byKey(ValueKey('buy-paged-scroll-$storeScope'));
          final categoryControl = find.byKey(
            const ValueKey('buy-store-category-control'),
          );
          await _revealPagedHeader(tester, storeScope, categoryControl);
          await tester.tap(categoryControl);
          await tester.pumpAndSettle();
          final category = find.byKey(
            ValueKey('buy-store-category-${product.categoryId}'),
          );
          await tester.ensureVisible(category);
          await tester.tap(category);
          await tester.pumpAndSettle();
          expect(source.productQueries.last.categoryId, product.categoryId);
          expect(full, findsOneWidget);
          await tester.tap(
            find.byKey(const ValueKey('buy-store-cart-bar')).hitTestable(),
          );
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.cart);
          final continueStore = find.byKey(
            const ValueKey('buy-cart-continue-store'),
          );
          await tester.scrollUntilVisible(
            continueStore,
            160,
            scrollable: find
                .descendant(
                  of: find.byKey(
                    PageStorageKey('buy-cart-${session.cartScope.name}'),
                  ),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.pumpAndSettle();
          expect(continueStore.hitTestable(), findsOneWidget);
          await tester.tap(continueStore);
          await tester.pumpAndSettle();
          await browseAll();
          expect(source.productQueries.last.categoryId, product.categoryId);
          final card = find.descendant(
            of: full,
            matching: find.byKey(ValueKey('buy-product-$id')),
          );
          final remove = find.descendant(
            of: card,
            matching: find.byTooltip('Remove from Cart'),
          );
          await tester.ensureVisible(remove);
          await tester.tap(remove);
          await tester.pumpAndSettle();
          expect(session.quantityFor(id), 0);
          expect(
            full,
            findsOneWidget,
            reason: 'Removing a cart line must not leave the Store',
          );
          expect(
            find.byKey(const ValueKey('buy-store-cart-bar')).hitTestable(),
            findsNothing,
          );
          expect(
            find.descendant(
              of: full,
              matching: find.byKey(ValueKey('buy-add-$id')),
            ),
            findsOneWidget,
          );
          await tester.pump(const Duration(seconds: 4));
          await tester.pumpAndSettle();
          expect(
            full,
            findsOneWidget,
            reason: 'Later basket feedback must also retain the Store',
          );
          await captureR66Visual(
            tester,
            'rv6-d002-paged-${destination.name}-text-$scale-empty-store',
          );
          final add = find.descendant(
            of: full,
            matching: find.byKey(ValueKey('buy-add-$id')),
          );
          await tester.ensureVisible(add);
          await tester.pumpAndSettle();
          await tester.ensureVisible(add);
          await tester.pumpAndSettle();
          expect(add.hitTestable(), findsOneWidget);
          await tester.tap(add);
          await tester.pumpAndSettle();
          expect(session.quantityFor(id), product.minimumOrder);
          expect(full, findsOneWidget);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.selectedProductId, id);
          // Both public channels now use the direct Store catalogue route.
          // Removing its last cart line leaves the covered root catalogue.
          expect(session.view, BuyV2View.catalogue);
          expect(find.byType(BuyV2CatalogueView), findsOneWidget);
          expect(find.byKey(ValueKey('$prefix-sheet-$id')), findsNothing);
          session.openDestination(
            shop ? BuyV2Destination.wholesale : BuyV2Destination.shop,
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(ValueKey('$prefix-sheet-$id')),
            findsNothing,
            reason: 'Explicit destination changes must still leave the Store',
          );
          expect(session.quantityFor(id), product.minimumOrder);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  TestWidgetsFlutterBinding.ensureInitialized();

  for (final id in ['s-curd', 'w-notebook']) {
    for (final size in [const Size(320, 711), const Size(711, 320)]) {
      for (final scale in [1.0, 2.0]) {
        final profile =
            '$id-${size.width.toInt()}x${size.height.toInt()}-$scale';
        testWidgets('R669 small full catalogue exposes every SKU $profile', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
          tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(core: core);
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          final product = session.product(id);
          final shop = product.destination == BuyV2Destination.shop;
          final otherId = shop ? 'w-rice' : 's-tomato';
          expect(session.addProduct(otherId), isTrue);
          final otherQuantity = session.quantityFor(otherId);
          expect(session.openProduct(id), isTrue);
          await tester.pumpWidget(_app(session, textScale: scale));
          await tester.pumpAndSettle();
          final prefix = shop ? 'buy-shop-seller' : 'buy-wholesale-supplier';
          final action = find.byKey(
            ValueKey(
              '${shop ? 'buy-shop-seller-action' : 'buy-wholesale-store-action'}-$id',
            ),
          );
          await _revealProductAction(tester, id, action);
          expect(action.hitTestable(), findsOneWidget);
          await tester.tap(action);
          await tester.pumpAndSettle();
          final preview = find.byKey(ValueKey('$prefix-sheet-$id'));
          final viewAll = find.byKey(ValueKey('$prefix-view-more-$id'));
          await tester.scrollUntilVisible(
            viewAll,
            100,
            scrollable: find
                .descendant(
                  of: find.byKey(ValueKey('$prefix-sheet-list')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.ensureVisible(viewAll);
          await tester.pumpAndSettle();
          expect(viewAll.hitTestable(), findsOneWidget);
          await tester.tap(viewAll);
          await tester.pumpAndSettle();
          final full = find.byKey(ValueKey('$prefix-full-catalogue-list'));
          expect(full, findsOneWidget);
          final products = session.partnerCatalogueFor(product);
          expect(products, hasLength(4));
          final horizontal = find.descendant(
            of: full,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.right,
            ),
          );
          expect(
            horizontal,
            findsNothing,
            reason: 'Every SKU is reached through the outer vertical list.',
          );
          final grid = find.descendant(
            of: full,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics &&
                  widget.key.toString().contains(
                    'buy-vertical-product-summary-',
                  ),
            ),
          );
          final label = tester.widget<Semantics>(grid).properties.label!;
          expect(label, contains('Showing 4 of 4 products.'));
          expect(label, contains('Scroll up or down'));
          expect(label, isNot(contains('Swipe left or right')));
          final viewport = tester.getRect(full);
          for (final entry in products) {
            final card = find.descendant(
              of: full,
              matching: find.byKey(ValueKey('buy-product-${entry.id}')),
            );
            expect(card, findsOneWidget);
            expect(
              tester.getRect(card).left,
              greaterThanOrEqualTo(viewport.left + 12),
            );
            expect(
              tester.getRect(card).right,
              lessThanOrEqualTo(viewport.right - 12),
            );
          }
          await captureR66Visual(tester, 'r669-small-catalogue-$profile-open');
          final last = products.last;
          final add = find.descendant(
            of: full,
            matching: find.byKey(ValueKey('buy-add-${last.id}')),
          );
          await tester.ensureVisible(add);
          await tester.pumpAndSettle();
          expect(add.hitTestable(), findsOneWidget);
          expect(
            tester.getRect(add).bottom,
            lessThanOrEqualTo(viewport.bottom),
          );
          await captureR66Visual(tester, 'r669-small-catalogue-$profile-last');
          await tester.tap(add);
          await tester.pumpAndSettle();
          expect(session.quantityFor(last.id), last.minimumOrder);
          expect(session.quantityFor(otherId), otherQuantity);
          final packshot = find.descendant(
            of: full,
            matching: find.byKey(ValueKey('buy-grid-packshot-${last.id}')),
          );
          await tester.ensureVisible(packshot);
          await tester.pumpAndSettle();
          const imageAction = Alignment(-.5, .55);
          expect(packshot.hitTestable(at: imageAction), findsOneWidget);
          await tester.tapAt(imageAction.withinRect(tester.getRect(packshot)));
          await tester.pumpAndSettle();
          expect(session.selectedProductId, last.id);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(full, findsOneWidget);
          expect(session.quantityFor(last.id), last.minimumOrder);
          final close = find.byKey(ValueKey('$prefix-full-catalogue-close'));
          await tester.scrollUntilVisible(
            close,
            -100,
            scrollable: find
                .descendant(of: full, matching: find.byType(Scrollable))
                .first,
          );
          await tester.ensureVisible(close);
          await tester.pumpAndSettle();
          expect(close.hitTestable(), findsOneWidget);
          await tester.tap(close);
          await tester.pumpAndSettle();
          expect(preview, findsOneWidget);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.selectedProductId, id);
          expect(session.quantityFor(otherId), otherQuantity);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final size in [const Size(320, 711), const Size(711, 320)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'R669 current location confirmation clears Android navigation $size $scale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
          tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
          addTearDown(tester.view.reset);
          final core = BuySession();
          final session = BuyV2Session(
            core: core,
            shoppingAreaSource: TestCurrentLocationSource('chennai', 'Chennai'),
            cataloguePageSource: _PagedWidgetSource(BuyV2Destination.shop),
            catalogueAreas: {
              'jodhpur': 'Jodhpur',
              for (var index = 1; index <= 30; index++)
                'fixture-$index': 'Expanded area fixture $index',
              'chennai': 'Chennai',
            },
            initialCatalogueRegionId: 'jodhpur',
          );
          addTearDown(core.dispose);
          addTearDown(session.dispose);
          await tester.pumpWidget(_app(session, textScale: scale));
          await tester.pumpAndSettle();
          unawaited(
            showBuyV2CatalogueArea(
              tester.element(find.byType(BuyV2Screen)),
              session,
            ),
          );
          await tester.pumpAndSettle();
          final list = find.byKey(const ValueKey('buy-catalogue-area-list'));
          final last = find.byKey(
            const ValueKey('buy-current-location-confirm'),
          );
          await tester.scrollUntilVisible(
            last,
            180,
            maxScrolls: 50,
            scrollable: find
                .descendant(of: list, matching: find.byType(Scrollable))
                .first,
          );
          await tester.drag(list, const Offset(0, -600));
          await tester.pumpAndSettle();
          final bounds = tester.getRect(last);
          expect(bounds.top, greaterThanOrEqualTo(tester.getRect(list).top));
          expect(bounds.bottom, lessThanOrEqualTo(size.height - 34));
          expect(bounds.height, greaterThanOrEqualTo(44));
          expect(last.hitTestable(), findsOneWidget);
          await captureR66Visual(tester, 'r669-area-last-${size.width}-$scale');
          await tester.tap(last);
          await tester.pumpAndSettle();
          expect(list, findsNothing);
          expect(session.catalogueRegionId, 'chennai');
          expect(session.catalogueAreaScope, BuyV2CatalogueAreaScope.regional);
          expect(session.itemCount, 0);
          unawaited(
            showBuyV2CatalogueArea(
              tester.element(find.byType(BuyV2Screen)),
              session,
            ),
          );
          await tester.pumpAndSettle();
          expect(list, findsOneWidget);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(list, findsNothing);
          expect(session.catalogueRegionId, 'chennai');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final size in [const Size(320, 844), const Size(640, 360)]) {
    for (final scale in [1.0, 2.0]) {
      final profile = '${size.width.toInt()}x${size.height.toInt()}-$scale';
      testWidgets('R5 paged published Offers journey $profile', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
        tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
        addTearDown(tester.view.reset);
        var now = DateTime.utc(2026, 9, 8);
        final published = _OffersJourneySource(now: () => now);
        final catalogue = _OffersJourneyCatalogueSource(now: () => now);
        final core = BuySession();
        final session = BuyV2Session(
          core: core,
          reviewDataEnabled: true,
          cataloguePageSource: catalogue,
          publishedCatalogueSource: published,
          catalogueNow: () => now,
          catalogueAreas: const {'jodhpur': 'Jodhpur', 'mumbai': 'Mumbai'},
          initialCatalogueRegionId: 'jodhpur',
        );
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        await tester.pumpWidget(_app(session, textScale: scale));
        await tester.pumpAndSettle();
        addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
        await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
        await tester.pumpAndSettle();
        const scope = 'published-offers';
        final pager = session.acquireCatalogueOffers(scope);
        addTearDown(() => session.releaseCatalogueOffers(scope));
        final range = find.byKey(const ValueKey('buy-page-status-$scope'));
        final next = find.byKey(const ValueKey('buy-page-status-$scope'));
        final vertical = find.byKey(const ValueKey('buy-paged-scroll-$scope'));
        Future<void> reveal(Finder target) async {
          // Both pagination bars share state; explicitly return to the top
          // before finding a header or traversing down to a product action.
          tester.widget<ListView>(vertical).controller!.jumpTo(0);
          await tester.pumpAndSettle();
          // The floating Cart can cover the viewport centre. Drag the visible
          // left gutter and verify movement instead of sending a missed hit.
          for (
            var attempt = 0;
            target.evaluate().isEmpty && attempt < 45;
            attempt++
          ) {
            final bounds = tester.getRect(vertical);
            final controller = tester.widget<ListView>(vertical).controller!;
            final before = controller.offset;
            await tester.dragFrom(
              Offset(bounds.left + 4, bounds.center.dy),
              const Offset(0, -100),
            );
            await tester.pumpAndSettle();
            expect(
              controller.offset,
              isNot(before),
              reason: 'Unobscured Offers scroll must move',
            );
          }
          expect(target, findsOneWidget);
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          // A tall lane can exceed landscape's viewport. Its actual Add/image
          // control is checked at the subsequent tap, not its offscreen centre.
          if (tester.getSize(target).height <=
              tester.getSize(vertical).height) {
            expect(target.hitTestable(), findsOneWidget);
          }
        }

        Future<void> capture(String state) async {
          expect(tester.takeException(), isNull);
          await captureR66Visual(tester, 'r5-offers-$profile-$state');
        }

        Future<void> checkAdditionalBenefits(
          BuyV2Product product,
          String publisher,
        ) async {
          expect(session.selectedProductId, product.id);
          expect(session.selectedProduct?.storeId, product.storeId);
          expect(session.selectedProduct?.pack, product.pack);
          expect(session.productFactsFor(product).price, product.price);
          final itemCount = session.itemCount;
          final saving = session.scopedCouponSaving;
          // Ready + empty benefits have no promotional panel in the approved
          // compact product layout. Keep the provider and cart assertions.
          expect(session.productBenefitsFor(product), isEmpty);
          expect(
            find.byKey(ValueKey('buy-product-benefits-empty-${product.id}')),
            findsNothing,
          );
          expect(
            find.byKey(ValueKey('buy-product-benefits-ready-${product.id}')),
            findsNothing,
          );
          expect(find.text('Additional checkout benefits'), findsNothing);
          expect(session.itemCount, itemCount);
          expect(session.scopedCouponSaving, saving);
          await captureR66Visual(
            tester,
            'r669-additional-benefits-$profile-$publisher',
          );
        }

        await capture('header');
        expect(
          find.byKey(const ValueKey('buy-page-status-$scope')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('buy-offers-filter-manufacturer')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('buy-offers-filter-wholesaler')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('buy-offers-filter-retailer')),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('buy-offers-category-control')),
            matching: find.byIcon(Icons.menu_rounded),
          ),
          findsOneWidget,
        );
        await reveal(next);
        expect(
          tester.widget<Semantics>(range).properties.label,
          '1–40 of 10,000,000 offers',
        );
        expect(published.pages.first.items.length, 40);
        await capture('initial');
        final original = published.pages.first.items;
        final retailProduct = original
            .firstWhere(
              (offer) =>
                  offer.product.destination == BuyV2Destination.shop &&
                  offer.publisherType != BuyV2OfferPublisherType.moolSocial,
            )
            .product;
        final tradeProduct = original
            .firstWhere(
              (offer) =>
                  offer.product.destination == BuyV2Destination.wholesale,
            )
            .product;
        final retailOffer = original.firstWhere(
          (offer) => offer.product.id == retailProduct.id,
        );
        await reveal(find.byKey(const ValueKey('buy-published-offer-facts')));
        expect(find.text(retailOffer.headline), findsOneWidget);
        final retailCta = find.byKey(
          ValueKey('buy-offer-promotion-cta-${retailProduct.id}'),
        );
        await tester
            .widget<ListView>(vertical)
            .controller!
            .position
            .ensureVisible(tester.renderObject(retailCta), alignment: .5);
        await tester.pumpAndSettle();
        if (retailCta.hitTestable().evaluate().isEmpty) {
          final controller = tester.widget<ListView>(vertical).controller!;
          final delta =
              tester.getRect(retailCta).center.dy -
              tester.getRect(vertical).center.dy;
          controller.jumpTo(
            (controller.offset + delta).clamp(
              0.0,
              controller.position.maxScrollExtent,
            ),
          );
          await tester.pumpAndSettle();
        }
        expect(retailCta.hitTestable(), findsOneWidget);
        final retailRequests = published.queries.length;
        await tester.tap(retailCta);
        await tester.pumpAndSettle();
        await checkAdditionalBenefits(retailProduct, 'retailer');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(vertical, findsOneWidget);
        expect(published.queries.length, retailRequests);
        expect(session.itemCount, 0);
        for (final product in [retailProduct, tradeProduct]) {
          await reveal(
            find.byKey(const ValueKey('buy-paged-vertical-grid-$scope')),
          );
          final add = find.byKey(ValueKey('buy-add-${product.id}'));
          await tester.ensureVisible(add);
          await tester.pumpAndSettle();
          expect(add.hitTestable(), findsOneWidget);
          await tester.tap(add);
          await tester.pumpAndSettle();
          expect(session.quantityFor(product.id), product.minimumOrder);
        }
        final save = find.byKey(ValueKey('buy-save-${tradeProduct.id}'));
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(session.isSaved(tradeProduct.id), isTrue);
        await capture('products');
        await reveal(next);
        published.failNext = true;
        await pager.refresh();
        await tester.pumpAndSettle();
        await _performCatalogueAction(tester, next, 'Next products');
        await tester.pumpAndSettle();
        final retry = find.widgetWithText(TextButton, 'Try again');
        await reveal(next);
        expect(
          tester.widget<Semantics>(range).properties.label,
          '1–40 of 10,000,000 offers',
        );
        await reveal(retry);
        expect(find.text('Results could not refresh'), findsOneWidget);
        await capture('retry');
        published.failNext = false;
        await tester.tap(retry);
        await tester.pumpAndSettle();
        await reveal(next);
        expect(
          tester.widget<Semantics>(range).properties.label,
          '41–80 of 10,000,000 offers',
        );
        final pageProduct = pager.page!.items.first.product;
        await reveal(
          find.byKey(const ValueKey('buy-paged-vertical-grid-$scope')),
        );
        final packshot = find.byKey(
          ValueKey('buy-grid-packshot-${pageProduct.id}'),
        );
        await tester.ensureVisible(packshot);
        await tester.pumpAndSettle();
        const imageAction = Alignment(-.5, .55);
        expect(packshot.hitTestable(at: imageAction), findsOneWidget);
        final offset = tester.widget<ListView>(vertical).controller!.offset;
        final requests = published.queries.length;
        await tester.tapAt(imageAction.withinRect(tester.getRect(packshot)));
        await tester.pumpAndSettle();
        expect(session.selectedProductId, pageProduct.id);
        expect(session.selectedProduct?.storeId, pageProduct.storeId);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(published.queries.length, requests);
        expect(
          tester.widget<ListView>(vertical).controller!.offset,
          closeTo(offset, 1),
        );
        await capture('return');
        final supplierOffers = pager.page!.items
            .where(
              (offer) =>
                  offer.publisherType != BuyV2OfferPublisherType.moolSocial,
            )
            .toList();
        final makerIndex = supplierOffers.indexWhere(
          (offer) =>
              offer.publisherType == BuyV2OfferPublisherType.manufacturer,
        );
        expect(makerIndex, greaterThanOrEqualTo(0));
        final promotionCarousel = find.byType(PageView);
        final promotionRequests = published.queries.length;
        await reveal(find.byKey(const ValueKey('buy-published-offer-facts')));
        for (var index = 0; index < makerIndex; index++) {
          final visible = tester
              .getRect(promotionCarousel)
              .intersect(tester.getRect(vertical));
          await tester.dragFrom(
            Offset(visible.right - 20, visible.top + 30),
            Offset(-visible.width * .8, 0),
          );
          await tester.pumpAndSettle();
        }
        expect(published.queries.length, promotionRequests);
        expect(published.queries.last.offerPublisher, isNull);
        expect(published.queries.last.supplierOffersOnly, isTrue);
        expect(pager.page!.totalCount, 10000000);
        final makerPublication = supplierOffers[makerIndex];
        expect(
          session.featuredOfferPublicationId,
          makerPublication.publicationId,
        );
        final makerName = makerPublication.publisherName;
        await reveal(find.byKey(const ValueKey('buy-published-offer-facts')));
        expect(
          find.textContaining(
            'From ${makerPublication.product.customerSeller(makerName)}',
          ),
          findsWidgets,
        );
        await capture('publisher');
        final makerProduct = makerPublication.product;
        final makerOffer = find.byKey(
          ValueKey('buy-published-offer-${makerProduct.id}'),
        );
        final makerHeadline = find.descendant(
          of: makerOffer,
          matching: find.text('Manufacturer price'),
        );
        await tester.ensureVisible(makerHeadline);
        await tester.pumpAndSettle();
        expect(makerHeadline.hitTestable(), findsOneWidget);
        final filteredRequests = published.queries.length;
        await tester.tap(makerHeadline);
        await tester.pumpAndSettle();
        expect(session.selectedProductId, makerProduct.id);
        await checkAdditionalBenefits(makerProduct, 'manufacturer');
        final storeAction = find.byKey(
          ValueKey('buy-wholesale-store-action-${makerProduct.id}'),
        );
        await tester.scrollUntilVisible(
          storeAction,
          180,
          scrollable: find
              .descendant(
                of: find.byKey(
                  PageStorageKey('buy-product-${makerProduct.id}'),
                ),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await Scrollable.ensureVisible(
          tester.element(storeAction),
          alignment: .4,
        );
        await tester.pumpAndSettle();
        expect(storeAction.hitTestable(), findsOneWidget);
        await tester.tap(storeAction);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('buy-store-toolbar-name')),
              )
              .data,
          makerProduct.customerSeller(makerProduct.seller),
        );
        expect(
          session.catalogueStore(makerProduct.storeId!)?.id,
          makerProduct.storeId,
        );
        expect(
          find.byKey(const ValueKey('buy-public-store-collection-benefit')),
          findsNothing,
        );
        await capture('store');
        await tester.tap(find.byKey(const ValueKey('buy-paged-store-close')));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(published.queries.length, filteredRequests);
        expect(
          session.retainedCatalogueOffersQuery(scope)?.offerPublisher,
          isNull,
        );
        expect(
          session.featuredOfferPublicationId,
          makerPublication.publicationId,
        );
        expect(published.queries.last.offerPublisher, isNull);
        final categoryControl = find.byKey(
          const ValueKey('buy-offers-category-control'),
        );
        await reveal(categoryControl);
        final originalCategory = session.selectedCategoryId;
        await tester.tap(categoryControl);
        await tester.pumpAndSettle();
        await capture('categories');
        final category = session
            .categoriesFor(BuyV2Destination.shop)
            .firstWhere((category) => category.id != 'all');
        final categoryTarget = find.byKey(
          ValueKey('buy-offers-category-${category.id}'),
        );
        final categoryScroll = find
            .descendant(
              of: find.byKey(const ValueKey('buy-offers-category-list')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          categoryTarget,
          100,
          scrollable: categoryScroll,
        );
        await tester.pumpAndSettle();
        await tester.tap(categoryTarget);
        await tester.pumpAndSettle();
        expect(published.queries.last.categoryId, category.id);
        expect(pager.page!.items, isNotEmpty);
        expect(
          pager.page!.items.every(
            (offer) => offer.product.categoryId == category.id,
          ),
          isTrue,
        );
        expect(session.selectedCategoryId, originalCategory);
        await reveal(categoryControl);
        await tester.tap(categoryControl);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-offers-category-all')));
        await tester.pumpAndSettle();
        final search = find.byKey(const ValueKey('buy-search-control'));
        await tester.ensureVisible(search);
        await tester.pumpAndSettle();
        await tester.tap(search);
        await tester.pumpAndSettle();
        final searchField = find.byKey(const ValueKey('buy-search-field'));
        await tester.enterText(searchField, 'SKU 46');
        tester.view.viewInsets = FakeViewPadding(
          bottom: size.height < 400 ? 80 : 180,
        );
        await tester.pumpAndSettle();
        expect(published.queries.last.query, 'SKU 46');
        expect(pager.page!.items, isNotEmpty);
        await capture('search-keyboard');
        tester.view.viewInsets = const FakeViewPadding();
        await tester.enterText(searchField, '');
        await tester.tap(find.byKey(const ValueKey('buy-search-close')));
        await tester.pumpAndSettle();
        now = now.add(const Duration(minutes: 16));
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();
        final refresh = find.widgetWithText(TextButton, 'Refresh offers');
        await reveal(refresh);
        expect(find.byType(BuyV2ProductCard), findsNothing);
        expect(find.text('Offers need refreshing'), findsOneWidget);
        await capture('expired');
        await tester.tap(refresh);
        await tester.pumpAndSettle();
        expect(
          pager.page!.items.every((offer) => offer.isCurrent(now: now)),
          isTrue,
        );
        await reveal(
          find.byKey(const ValueKey('buy-paged-vertical-grid-$scope')),
        );
        expect(find.byType(BuyV2ProductCard), findsWidgets);
        expect(
          session.quantityFor(retailProduct.id),
          retailProduct.minimumOrder,
        );
        expect(session.quantityFor(tradeProduct.id), tradeProduct.minimumOrder);
        expect(session.isSaved(tradeProduct.id), isTrue);
        await capture('recovered');
      });
    }
  }

  for (final destination in [
    BuyV2Destination.shop,
    BuyV2Destination.wholesale,
  ]) {
    for (final size in [const Size(320, 844), const Size(640, 360)]) {
      for (final scale in [1.0, 2.0]) {
        final profile =
            '${destination.name}-${size.width.toInt()}x${size.height.toInt()}-$scale';
        testWidgets('R5 store-first catalogue journey $profile', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
          tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
          addTearDown(tester.view.reset);
          final source = _StoreJourneySource(destination);
          final core = BuySession();
          final session = BuyV2Session(
            core: core,
            reviewDataEnabled: true,
            cataloguePageSource: source,
            catalogueAreas: const {'jodhpur': 'Jodhpur', 'mumbai': 'Mumbai'},
            initialCatalogueRegionId: 'jodhpur',
          )..destination = destination;
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          await tester.pumpWidget(_app(session, textScale: scale));
          await tester.pumpAndSettle();
          addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
          final rootScope = 'catalogue-${destination.name}';
          final searchControl = find.byKey(
            const ValueKey('buy-search-control'),
          );
          await _revealPagedHeader(tester, rootScope, searchControl);
          await tester.tap(searchControl);
          await tester.pumpAndSettle();
          final searchField = find.byKey(const ValueKey('buy-search-field'));
          await tester.enterText(searchField, 'Mool Market');
          await tester.pumpAndSettle();
          await _revealPagedHeader(
            tester,
            'search-${destination.name}',
            searchField,
          );
          final editable = tester
              .state<EditableTextState>(
                find.descendant(
                  of: searchField,
                  matching: find.byType(EditableText),
                ),
              )
              .renderEditable;
          final queryBoxes = editable.getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 11),
          );
          expect(queryBoxes, isNotEmpty);
          for (final box in queryBoxes) {
            expect(
              box.top,
              greaterThanOrEqualTo(-.1),
              reason:
                  'Rendered query ${editable.size}; '
                  'offset ${editable.offset.pixels}; '
                  'field ${tester.getSize(searchField)}; '
                  'control ${tester.getSize(searchControl)}; '
                  'style ${editable.text?.style}',
            );
            expect(box.bottom, lessThanOrEqualTo(editable.size.height + .1));
          }
          final storeRange = find.byKey(
            ValueKey('buy-page-range-store-search-${destination.name}'),
          );
          expect(tester.widget<Text>(storeRange).data, '1–40 of 10,000 stores');
          expect(source.storeQueries.last.query, 'Mool Market');
          await captureR66Visual(tester, 'r5-store-$profile-search-open');
          final finish = find.byKey(const ValueKey('buy-search-close'));
          await _revealPagedHeader(
            tester,
            'search-${destination.name}',
            finish,
          );
          final storeRequests = source.storeQueries.length;
          await tester.tap(finish);
          await tester.pumpAndSettle();
          expect(source.storeQueries.length, storeRequests);
          expect(tester.widget<Text>(storeRange).data, '1–40 of 10,000 stores');
          expect(session.query, 'Mool Market');

          final firstStoreId = source.storeIdAt(0);
          final firstProductId = source.productIdAt(0, 0);
          final firstStore = find.byKey(
            ValueKey('buy-store-search-open-$firstStoreId'),
          );
          final firstName = find.descendant(
            of: firstStore,
            matching: find.text('Mool Market'),
          );
          await tester.ensureVisible(firstName);
          await tester.pumpAndSettle();
          expect(firstName.hitTestable(), findsOneWidget);
          final storeSurface = tester.widget<Ink>(
            find.byKey(ValueKey('buy-store-search-surface-$firstStoreId')),
          );
          expect(
            (storeSurface.decoration! as BoxDecoration).gradient,
            isNotNull,
          );
          expect(
            find.descendant(
              of: firstStore,
              matching: find.textContaining('Visit'),
            ),
            findsOneWidget,
          );
          await tester.tap(firstName);
          await tester.pumpAndSettle();
          final storefront =
              destination == BuyV2Destination.shop ||
              destination == BuyV2Destination.wholesale;
          if (storefront) {
            await tester.tap(
              find.byKey(const ValueKey('buy-store-info-control')),
            );
            await tester.pumpAndSettle();
          }
          expect(
            tester
                .widget<Text>(
                  find.byKey(const ValueKey('buy-store-toolbar-name')),
                )
                .data,
            'Mool Market',
          );
          expect(
            find.byKey(const ValueKey('buy-public-store-collection-benefit')),
            findsNothing,
          );
          expect(
            session.partnerCatalogueFor(session.product(firstProductId)).length,
            greaterThanOrEqualTo(6),
          );
          expect(
            session
                .otherStorePreviewsFor(session.product(firstProductId))
                .every(
                  (product) =>
                      product.storeId != firstStoreId &&
                      session.catalogueStore(product.storeId!)?.regionId ==
                          'jodhpur',
                ),
            isTrue,
          );
          await captureR66Visual(tester, 'r5-store-$profile-public');
          final owner = destination == BuyV2Destination.shop
              ? 'buy-shop-seller'
              : 'buy-wholesale-supplier';
          final relatedProductId = source.productIdAt(10, 0);
          final relatedBranch = find.byKey(
            ValueKey('buy-related-store-branch-$relatedProductId'),
          );
          final publicScroll = find
              .descendant(
                of: find.byKey(
                  ValueKey(
                    storefront ? 'buy-store-info-scroll' : '$owner-sheet-list',
                  ),
                ),
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(
            relatedBranch,
            100,
            scrollable: publicScroll,
          );
          await tester.pumpAndSettle();
          expect(
            tester.widget<Text>(relatedBranch).data,
            session.catalogueStore(source.storeIdAt(10))!.address,
          );
          expect(relatedBranch.hitTestable(), findsOneWidget);
          await captureR66Visual(tester, 'r5-store-$profile-related-branches');
          await tester.tap(relatedBranch);
          await tester.pumpAndSettle();
          expect(
            find.byKey(
              ValueKey(
                storefront
                    ? '$owner-sheet-$relatedProductId'
                    : '$owner-view-more-$relatedProductId',
              ),
            ),
            findsOneWidget,
          );
          expect(
            session.product(relatedProductId).storeId,
            source.storeIdAt(10),
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          final viewAll = find.byKey(
            ValueKey('$owner-view-more-$firstProductId'),
          );
          if (!storefront) {
            expect(
              find.byKey(ValueKey('$owner-sheet-$firstProductId')),
              findsOneWidget,
              reason: 'Back from the related branch must restore its caller',
            );
            tester.state<ScrollableState>(publicScroll).position.jumpTo(0);
            await tester.pumpAndSettle();
            expect(viewAll.hitTestable(), findsOneWidget);
            await tester.tap(viewAll);
            await tester.pumpAndSettle();
          }
          final storeScope = 'store-${destination.name}-$firstStoreId';
          final range = find.byKey(ValueKey('buy-page-status-$storeScope'));
          expect(
            tester.widget<Semantics>(range).properties.label,
            '1–40 of 5,000',
          );
          expect(
            session.retainedCatalogueQuery(storeScope)?.storeId,
            firstStoreId,
          );
          expect(session.retainedCatalogueQuery(storeScope)?.query, '');
          expect(session.retainedCatalogueQuery(storeScope)?.categoryId, 'all');
          await captureR66Visual(tester, 'r5-store-$profile-full');

          final next = find.byKey(ValueKey('buy-page-status-$storeScope'));
          await _revealPagedHeader(tester, storeScope, next);
          source.failStorePage = true;
          // Invalidate the successfully prefetched next page through the real
          // refresh action before simulating the failed next-page request.
          await _performCatalogueAction(tester, next, 'Refresh products');
          await tester.pumpAndSettle();
          await _performCatalogueAction(tester, next, 'Next products');
          await tester.pumpAndSettle();
          expect(find.text('Results could not refresh'), findsOneWidget);
          await captureR66Visual(tester, 'r5-store-$profile-retry');
          source.failStorePage = false;
          final retry = find.widgetWithText(TextButton, 'Try again');
          await tester.ensureVisible(retry);
          await tester.pumpAndSettle();
          await tester.tap(retry);
          await tester.pumpAndSettle();
          expect(
            tester.widget<Semantics>(range).properties.label,
            '41–80 of 5,000',
          );
          final product = source.productIdAt(0, 40);
          final image = find.byKey(ValueKey('buy-grid-packshot-$product'));
          await tester.ensureVisible(image);
          await tester.pumpAndSettle();
          const imageAction = Alignment(-.5, .55);
          expect(image.hitTestable(at: imageAction), findsOneWidget);
          await tester.tapAt(imageAction.withinRect(tester.getRect(image)));
          await tester.pumpAndSettle();
          expect(session.selectedProductId, product);
          expect(session.selectedProduct?.storeId, firstStoreId);
          // Product discovery may query; returning must not reload the catalogue.
          final requestCount = source.productQueries.length;
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(source.productQueries.length, requestCount);
          await captureR66Visual(tester, 'r5-store-$profile-return');
          await _revealPagedHeader(tester, storeScope, next);
          expect(
            tester.widget<Semantics>(range).properties.label,
            '41–80 of 5,000',
          );

          final storeField = find.byKey(
            const ValueKey('buy-store-product-search'),
          );
          await _revealPagedHeader(tester, storeScope, storeField);
          await tester.enterText(storeField, 'sku 4999');
          await tester.pumpAndSettle();
          final lastProduct = source.productIdAt(0, 4998);
          expect(tester.widget<Semantics>(range).properties.label, '1–1 of 1');
          expect(session.findProduct(lastProduct)?.storeId, firstStoreId);
          expect(session.query, 'Mool Market');
          tester.view.viewInsets = FakeViewPadding(
            bottom: size.height < 400 ? 140 : 260,
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(storeField);
          await tester.pumpAndSettle();
          final keyboardTop = size.height - (size.height < 400 ? 140 : 260);
          expect(
            tester.getRect(storeField).bottom,
            lessThanOrEqualTo(keyboardTop),
          );
          expect(
            tester
                .getRect(find.byKey(ValueKey('buy-paged-scroll-$storeScope')))
                .bottom,
            lessThanOrEqualTo(keyboardTop),
          );
          expect(tester.takeException(), isNull);
          await captureR66Visual(tester, 'r5-store-$profile-search-keyboard');
          tester.view.resetViewInsets();
          tester.testTextInput.hide();
          await tester.pumpAndSettle();
          // A keyboard dismissal must survive a nested product round trip.
          final lastImage = find.byKey(
            ValueKey('buy-grid-packshot-$lastProduct'),
          );
          await tester.ensureVisible(lastImage);
          await tester.pumpAndSettle();
          expect(lastImage.hitTestable(at: imageAction), findsOneWidget);
          await tester.tapAt(imageAction.withinRect(tester.getRect(lastImage)));
          await tester.pumpAndSettle();
          expect(session.selectedProductId, lastProduct);
          final retainedRequests = source.productQueries.length;
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(tester.testTextInput.isVisible, isFalse);
          await _revealPagedHeader(tester, storeScope, storeField);
          expect(
            tester.widget<TextField>(storeField).focusNode!.hasFocus,
            isFalse,
          );
          expect(
            tester.widget<TextField>(storeField).controller!.text,
            'sku 4999',
          );
          expect(tester.widget<Semantics>(range).properties.label, '1–1 of 1');
          expect(source.productQueries.length, retainedRequests);
          final add = find.byKey(ValueKey('buy-add-$lastProduct'));
          await tester.ensureVisible(add);
          await tester.pumpAndSettle();
          expect(add.hitTestable(), findsOneWidget);
          await tester.tap(add);
          await tester.pumpAndSettle();
          final quantity = session.product(lastProduct).minimumOrder;
          expect(session.quantityFor(lastProduct), quantity);
          final save = find.byKey(ValueKey('buy-save-$lastProduct'));
          await tester.ensureVisible(save);
          await tester.pumpAndSettle();
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(session.isSaved(lastProduct), isTrue);

          final clear = find.byKey(
            const ValueKey('buy-store-product-search-clear'),
          );
          await _revealPagedHeader(tester, storeScope, clear);
          await tester.tap(clear);
          await tester.pumpAndSettle();
          if (storefront) {
            await tester.tap(
              find.byKey(const ValueKey('buy-store-search-finish')),
            );
            await tester.pumpAndSettle();
          }
          final categoryControl = find.byKey(
            const ValueKey('buy-store-category-control'),
          );
          await _revealPagedHeader(tester, storeScope, categoryControl);
          final searchHint = find.descendant(
            of: storeField,
            matching: find.text(
              scale > 1.25 || (storefront && size.width < 360)
                  ? 'Search'
                  : 'Search this store',
            ),
          );
          expect(searchHint, findsOneWidget);
          expect(
            tester.renderObject<RenderParagraph>(searchHint).didExceedMaxLines,
            isFalse,
          );
          expect(
            tester.getSize(categoryControl).height,
            greaterThanOrEqualTo(44),
          );
          if (storefront) {
            expect(
              tester.getRect(categoryControl).top,
              greaterThanOrEqualTo(tester.getRect(storeField).bottom),
            );
          } else {
            expect(
              tester.getRect(categoryControl).center.dy,
              closeTo(tester.getRect(storeField).center.dy, .1),
            );
          }
          expect(
            find.descendant(
              of: categoryControl,
              matching: find.byIcon(Icons.menu_rounded),
            ),
            findsOneWidget,
          );
          await _revealPagedHeader(tester, storeScope, storeField);
          await tester.tap(storeField);
          await tester.pumpAndSettle();
          expect(tester.testTextInput.isVisible, isTrue);
          tester.testTextInput.hide();
          await tester.pumpAndSettle();
          if (storefront) {
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(
              find.byKey(const ValueKey('buy-store-search-finish')),
              findsNothing,
            );
          }
          await _revealPagedHeader(tester, storeScope, categoryControl);
          await tester.tap(categoryControl);
          await tester.pumpAndSettle();
          final category = session
              .categoriesFor(destination)
              .lastWhere((value) => value.id != 'all');
          final choice = find.byKey(
            ValueKey('buy-store-category-${category.id}'),
          );
          final categoryScroll = find
              .descendant(
                of: find.byKey(const ValueKey('buy-store-category-list')),
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(
            choice,
            100,
            scrollable: categoryScroll,
          );
          await tester.drag(
            find.byKey(const ValueKey('buy-store-category-list')),
            const Offset(0, -600),
          );
          await tester.pumpAndSettle();
          expect(
            tester.getRect(choice).bottom,
            lessThanOrEqualTo(size.height - 34),
          );
          expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
          expect(choice.hitTestable(), findsOneWidget);
          await captureR66Visual(tester, 'r669-store-last-category-$profile');
          await tester.tap(choice);
          await tester.pumpAndSettle();
          expect(tester.testTextInput.isVisible, isFalse);
          await _revealPagedHeader(tester, storeScope, storeField);
          expect(
            tester.widget<TextField>(storeField).focusNode!.hasFocus,
            isFalse,
          );
          expect(find.text('All products'), findsNothing);
          await captureR66Visual(
            tester,
            'r669-store-compact-category-$profile',
          );
          expect(source.productQueries.last.categoryId, category.id);
          expect(session.selectedCategoryId, 'all');
          expect(session.query, 'Mool Market');
          final visibleCards = find.descendant(
            of: find.byKey(ValueKey('buy-paged-scroll-$storeScope')),
            matching: find.byType(BuyV2ProductCard),
          );
          final productScroll = find
              .descendant(
                of: find.byKey(ValueKey('buy-paged-scroll-$storeScope')),
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(
            find.byKey(ValueKey('buy-paged-vertical-grid-$storeScope')),
            100,
            scrollable: productScroll,
          );
          await tester.pumpAndSettle();
          final cards = tester.widgetList<BuyV2ProductCard>(visibleCards);
          expect(cards, isNotEmpty);
          expect(
            cards.every(
              (card) =>
                  card.product.storeId == firstStoreId &&
                  card.product.categoryId == category.id,
            ),
            isTrue,
          );
          expect(session.quantityFor(lastProduct), quantity);
          expect(session.isSaved(lastProduct), isTrue);
          await captureR66Visual(tester, 'r5-store-$profile-category');

          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          if (!storefront) {
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
          }
          expect(session.query, 'Mool Market');
          final secondStoreId = source.storeIdAt(10);
          final secondStore = find.byKey(
            ValueKey('buy-store-search-open-$secondStoreId'),
          );
          final secondName = find.descendant(
            of: secondStore,
            matching: find.text('Mool Market'),
          );
          await tester.ensureVisible(secondName);
          await tester.pumpAndSettle();
          expect(secondName.hitTestable(), findsOneWidget);
          await tester.tap(secondName);
          await tester.pumpAndSettle();
          final secondProductId = source.productIdAt(10, 0);
          expect(
            find.byKey(
              ValueKey(
                storefront
                    ? '$owner-sheet-$secondProductId'
                    : '$owner-view-more-$secondProductId',
              ),
            ),
            findsOneWidget,
          );
          expect(session.product(secondProductId).storeId, secondStoreId);
          expect(session.quantityFor(lastProduct), quantity);
          expect(session.isSaved(lastProduct), isTrue);
          expect(tester.takeException(), isNull);
          await captureR66Visual(tester, 'r5-store-$profile-other-branch');
        });

        testWidgets('R5 paged catalogue user actions $profile', (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
          tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
          addTearDown(tester.view.reset);
          final source = _PagedWidgetSource(destination);
          final core = BuySession();
          final session = BuyV2Session(
            core: core,
            shoppingAreaSource: TestCurrentLocationSource('mumbai', 'Mumbai'),
            reviewDataEnabled: true,
            cataloguePageSource: source,
            catalogueAreas: const {'jodhpur': 'Jodhpur', 'mumbai': 'Mumbai'},
            initialCatalogueRegionId: 'jodhpur',
          )..destination = destination;
          // Existing review orders and verified trade state model this positive
          // UI journey; no live commerce or verification result is claimed.
          addTearDown(session.dispose);
          addTearDown(core.dispose);
          await tester.pumpWidget(_app(session, textScale: scale));
          await tester.pumpAndSettle();
          addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
          final scope = 'catalogue-${destination.name}';
          final range = find.byKey(ValueKey('buy-page-status-$scope'));
          final currentPager = session.acquireCatalogueProducts(scope);
          addTearDown(() => session.releaseCatalogueProducts(scope));
          void expectPage(int start) {
            expect(currentPager.page!.startIndex, start);
            expect(
              tester.widget<Semantics>(range).properties.label,
              startsWith('${start + 1}\u2013${start + 40} of '),
            );
          }

          Future<void> revealControls(Finder target) async {
            final viewport = find.byKey(ValueKey('buy-paged-scroll-$scope'));
            final controller = tester.widget<ListView>(viewport).controller!;
            controller.jumpTo(0);
            await tester.pumpAndSettle();
            await tester.ensureVisible(target);
            await tester.pumpAndSettle();
            expect(target.hitTestable(), findsOneWidget);
          }

          expectPage(0);
          expect(
            find.byKey(ValueKey('buy-paged-vertical-grid-$scope')),
            findsOneWidget,
          );
          expect(find.byKey(ValueKey('buy-paged-lane-$scope-0')), findsNothing);
          expect(source.requests.length, inInclusiveRange(1, 2));
          expect(tester.takeException(), isNull);
          await captureR66Visual(tester, 'r5-paged-$profile-initial');

          final first = tester
              .widget<BuyV2ProductCard>(find.byType(BuyV2ProductCard).first)
              .product;
          final save = find.byKey(ValueKey('buy-save-${first.id}'));
          await tester.ensureVisible(save);
          await tester.pumpAndSettle();
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(session.isSaved(first.id), isTrue);
          final add = find.byKey(ValueKey('buy-add-${first.id}'));
          await tester.ensureVisible(add);
          await tester.pumpAndSettle();
          expect(add.hitTestable(), findsOneWidget);
          await tester.tap(add);
          await tester.pumpAndSettle();
          expect(session.quantityFor(first.id), first.minimumOrder);

          final next = find.byKey(ValueKey('buy-page-status-$scope'));
          await revealControls(next);
          await captureR66Visual(tester, 'r669-page-controls-$profile-first');
          source.failNext = true;
          await currentPager.refresh();
          await tester.pumpAndSettle();
          await _performCatalogueAction(tester, next, 'Next products');
          await tester.pumpAndSettle();
          expect(find.text('Results could not refresh'), findsOneWidget);
          expectPage(0);
          expect(session.quantityFor(first.id), first.minimumOrder);
          await captureR66Visual(tester, 'r5-paged-$profile-retry');
          source.failNext = false;
          final retry = find.widgetWithText(TextButton, 'Try again');
          await tester.ensureVisible(retry);
          await tester.pumpAndSettle();
          await tester.tap(retry);
          await tester.pumpAndSettle();
          expectPage(40);
          expect(session.isSaved(first.id), isTrue);
          expect(session.quantityFor(first.id), first.minimumOrder);

          final grid = find.byKey(ValueKey('buy-paged-vertical-grid-$scope'));
          final packshots = find.descendant(
            of: grid,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget.key is ValueKey<String> &&
                  (widget.key! as ValueKey<String>).value.startsWith(
                    'buy-grid-packshot-',
                  ),
            ),
          );
          await tester.ensureVisible(packshots.at(3));
          await tester.pumpAndSettle();
          const imageAction = Alignment(-.5, .55);
          final visibleImage = packshots.hitTestable(at: imageAction).first;
          final visible = find.ancestor(
            of: visibleImage,
            matching: find.byType(BuyV2ProductCard),
          );
          final opened = tester.widget<BuyV2ProductCard>(visible).product;
          final vertical = find.byKey(ValueKey('buy-paged-scroll-$scope'));
          final verticalOffset = tester
              .widget<ListView>(vertical)
              .controller!
              .offset;
          expect(verticalOffset, greaterThan(0));
          await captureR66Visual(tester, 'r5-paged-$profile-page2');
          await tester.tapAt(
            imageAction.withinRect(tester.getRect(visibleImage)),
          );
          await tester.pumpAndSettle();
          expect(session.selectedProductId, opened.id);
          expect(session.view, BuyV2View.product);
          // Include product discovery before measuring the return-path requests.
          final requestCount = source.requests.length;
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.catalogue);
          expect(source.requests.length, requestCount);
          expect(
            tester.widget<ListView>(vertical).controller!.offset,
            closeTo(verticalOffset, 1),
          );
          expect(session.quantityFor(first.id), first.minimumOrder);
          await captureR66Visual(tester, 'r5-paged-$profile-return');

          await revealControls(next);
          expectPage(40);
          final previous = find.byKey(ValueKey('buy-page-status-$scope'));
          await _performCatalogueAction(tester, previous, 'Previous products');
          await tester.pumpAndSettle();
          await revealControls(next);
          expectPage(0);
          expect(
            tester
                .widget<Semantics>(previous)
                .properties
                .customSemanticsActions!
                .keys
                .any((action) => action.label == 'Previous products'),
            isFalse,
          );
          final refresh = find.byKey(ValueKey('buy-page-status-$scope'));
          final beforeRefresh = source.requests.length;
          await _performCatalogueAction(tester, refresh, 'Refresh products');
          await tester.pumpAndSettle();
          expect(
            source.requests.length,
            inInclusiveRange(beforeRefresh + 1, beforeRefresh + 2),
          );
          await revealControls(next);
          expectPage(0);
          expect(session.quantityFor(first.id), first.minimumOrder);
          expect(session.isSaved(first.id), isTrue);
          final controller = tester.widget<ListView>(vertical).controller!;
          controller.jumpTo(controller.position.maxScrollExtent);
          await tester.pumpAndSettle();
          expect(
            find.byKey(ValueKey('buy-page-next-$scope-bottom')),
            findsNothing,
          );
          expect(
            find.byKey(ValueKey('buy-page-status-$scope-bottom')),
            findsNothing,
          );
          await _performCatalogueAction(tester, range, 'Next products');
          await tester.pumpAndSettle();
          await revealControls(previous);
          expectPage(40);
          await _performCatalogueAction(tester, previous, 'Previous products');
          await tester.pumpAndSettle();
          await revealControls(next);
          expectPage(0);
          expect(session.isSaved(first.id), isTrue);
          expect(session.quantityFor(first.id), first.minimumOrder);
          final area = find.byKey(const ValueKey('buy-change-location'));
          await _revealPagedHeader(tester, scope, area);
          await tester.tap(area);
          await tester.pumpAndSettle();
          final field = find.byKey(const ValueKey('buy-catalogue-area-search'));
          expect(field, findsNothing);
          expect(
            find.byKey(const ValueKey('buy-current-location-result')),
            findsOneWidget,
          );
          tester.view.viewInsets = const FakeViewPadding(bottom: 180);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await captureR66Visual(tester, 'r5-paged-$profile-area-keyboard');
          final mumbai = find.byKey(
            const ValueKey('buy-current-location-confirm'),
          );
          final areaScroll = find
              .descendant(
                of: find.byKey(const ValueKey('buy-catalogue-area-list')),
                matching: find.byType(Scrollable),
              )
              .first;
          await tester.scrollUntilVisible(mumbai, 80, scrollable: areaScroll);
          await tester.pumpAndSettle();
          expect(mumbai.hitTestable(), findsOneWidget);
          await tester.tap(mumbai);
          tester.view.viewInsets = const FakeViewPadding();
          await tester.pumpAndSettle();
          expect(session.catalogueRegionId, 'mumbai');
          expect(source.requests.last.regionId, 'mumbai');
          expectPage(0);
          expect(session.isSaved(first.id), isTrue);
          expect(session.quantityFor(first.id), first.minimumOrder);
          expect(tester.takeException(), isNull);
          await captureR66Visual(tester, 'r5-paged-$profile-area-result');
        });
      }
    }
  }

  for (final size in [const Size(320, 844), const Size(640, 360)]) {
    for (final scale in [1.0, 2.0]) {
      final profile = '${size.width.toInt()}x${size.height.toInt()}-$scale';
      testWidgets(
        'Local cutoff checkout does not invent a missing Store address $profile',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
          tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
          addTearDown(tester.view.reset);
          final setup = await _CollectionHeaderFixture.create(tester);
          addTearDown(setup.dispose);
          final session = setup.session;
          final current = setup.products.first;
          final other = setup.products.last;
          session.addProduct(other.id);
          session.toggleSaved(other.id);
          expect(session.openProduct(current.id), isTrue);
          await tester.pumpWidget(_app(session, textScale: scale));
          await tester.pumpAndSettle();
          addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
          final seller = find.byKey(
            ValueKey('buy-shop-seller-action-${current.id}'),
          );
          await _revealProductAction(tester, current.id, seller);
          await tester.ensureVisible(seller);
          await tester.pumpAndSettle();
          expect(seller.hitTestable(), findsOneWidget);
          await tester.tap(seller);
          await tester.pumpAndSettle();

          final benefit = find.byKey(
            const ValueKey('buy-public-store-collection-benefit'),
          );
          expect(benefit, findsNothing);
          expect(find.text('Order & Collect'), findsNothing);
          expect(
            find.byKey(const ValueKey('buy-public-store-order-collection')),
            findsNothing,
          );
          final ordersBefore = session.orders.length;
          expect(session.quantityFor(current.id), 0);
          expect(session.collectionCheckoutSelected, isFalse);
          await captureR66Visual(
            tester,
            'collect-header-$profile-no-promotion',
          );

          // Identical display names cannot mix different branches' products.
          expect(
            session.partnerCatalogueFor(current).map((product) => product.id),
            [current.id, setup.products[1].id],
          );
          expect(session.product(current.id).storeId, 'collection-store-a');
          expect(session.product(current.id).pack, '500 ml pouch');
          expect(session.quantityFor(other.id), 1);
          expect(session.isSaved(other.id), isTrue);
          final close = find.byKey(
            const ValueKey('buy-shop-seller-sheet-close'),
          );
          await tester.scrollUntilVisible(
            close,
            -120,
            scrollable: find
                .descendant(
                  of: find.byKey(const ValueKey('buy-shop-seller-sheet-list')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.ensureVisible(close);
          await tester.pumpAndSettle();
          expect(close.hitTestable(), findsOneWidget);
          await tester.tap(close);
          await tester.pumpAndSettle();
          expect(benefit, findsNothing);
          expect(session.selectedProductId, current.id);
          expect(session.product(current.id).storeId, 'collection-store-a');
          expect(session.quantityFor(other.id), 1);
          expect(session.isSaved(other.id), isTrue);
          expect(session.addProduct(current.id), isTrue);
          session.openCart();
          expect(session.openCheckout(), isTrue);
          expect(session.collectionCheckoutSelected, isFalse);
          // This legacy fixture has product identities but no Store record.
          // Keep both branches in Cart; never manufacture a pickup address.
          expect(session.collectionCheckoutStores, isEmpty);
          expect(
            session.chooseCheckoutCollection(true, storeId: current.storeId),
            isFalse,
          );
          expect(session.chooseCheckoutCollection(true), isTrue);
          expect(session.collectionCheckoutSelected, isTrue);
          expect(session.checkoutLines, isEmpty);
          expect(session.quantityFor(current.id), current.minimumOrder);
          expect(session.quantityFor(other.id), 1);
          expect(session.orders.length, ordersBefore);
          expect(
            session.collectionCheckoutMessage,
            contains('account could not be verified'),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final invalid in [
    'unsupported',
    'absent',
    'wrong-branch',
    'expired',
    'future-observation',
    'blank-source',
    'stale-facts',
    'wrong-product',
  ]) {
    testWidgets('R5 collection visibility hides $invalid capability', (
      tester,
    ) async {
      final setup = await _CollectionHeaderFixture.create(tester);
      addTearDown(setup.dispose);
      final now = tester.binding.clock.now();
      setup.facts.capability = invalid == 'absent'
          ? null
          : BuyV2StoreCollectionCapability(
              storeId: invalid == 'wrong-branch'
                  ? 'collection-store-b'
                  : 'collection-store-a',
              supportsCollection: invalid != 'unsupported',
              sourceId: invalid == 'blank-source' ? '' : 'collection-header-v1',
              observedAt: invalid == 'future-observation'
                  ? now.add(const Duration(hours: 1))
                  : now.subtract(const Duration(seconds: 1)),
              validUntil: invalid == 'expired'
                  ? now
                  : now.add(const Duration(hours: 2)),
            );
      setup.facts.stale = invalid == 'stale-facts';
      setup.facts.wrongProduct = invalid == 'wrong-product';
      final current = setup.products.first;
      expect(setup.session.openProduct(current.id), isTrue);
      await tester.pumpWidget(_app(setup.session));
      await tester.pumpAndSettle();
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      final seller = find.byKey(
        ValueKey('buy-shop-seller-action-${current.id}'),
      );
      await _revealProductAction(tester, current.id, seller);
      await tester.ensureVisible(seller);
      await tester.pumpAndSettle();
      await tester.tap(seller);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-shop-seller-sheet-header')),
          matching: find.text(current.customerSeller(current.seller)),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('buy-public-store-name')), findsNothing);
      expect(
        find.byKey(const ValueKey('buy-public-store-collection-benefit')),
        findsNothing,
      );
      expect(find.text('Order & Collect'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Local cutoff collection promotion stays absent after capability changes',
    (tester) async {
      final setup = await _CollectionHeaderFixture.create(tester);
      addTearDown(setup.dispose);
      final session = setup.session;
      final current = setup.products.first;
      expect(session.openProduct(current.id), isTrue);
      await tester.pumpWidget(_app(session));
      await tester.pumpAndSettle();
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      final seller = find.byKey(
        ValueKey('buy-shop-seller-action-${current.id}'),
      );
      await _revealProductAction(tester, current.id, seller);
      await tester.ensureVisible(seller);
      await tester.pumpAndSettle();
      await tester.tap(seller);
      await tester.pumpAndSettle();
      final benefit = find.byKey(
        const ValueKey('buy-public-store-collection-benefit'),
      );
      expect(benefit, findsNothing);

      setup.facts.capability = null;
      expect(session.refreshProductFacts(current.id), isTrue);
      await tester.pumpAndSettle();
      expect(benefit, findsNothing);

      setup.facts.capability = setup.supported(
        validUntil: tester.binding.clock.now().add(const Duration(seconds: 5)),
      );
      expect(session.refreshProductFacts(current.id), isTrue);
      await tester.pumpAndSettle();
      expect(benefit, findsNothing);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(benefit, findsNothing);
      expect(session.selectedProductId, current.id);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Local cutoff invalid refresh preserves Cart without collection promotion',
    (tester) async {
      final setup = await _CollectionHeaderFixture.create(tester);
      addTearDown(setup.dispose);
      final current = setup.products.first;
      setup.session.addProduct(setup.products.last.id);
      expect(setup.session.openProduct(current.id), isTrue);
      await tester.pumpWidget(_app(setup.session));
      await tester.pumpAndSettle();
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      final seller = find.byKey(
        ValueKey('buy-shop-seller-action-${current.id}'),
      );
      await _revealProductAction(tester, current.id, seller);
      await tester.ensureVisible(seller);
      await tester.pumpAndSettle();
      await tester.tap(seller);
      await tester.pumpAndSettle();
      final benefit = find.byKey(
        const ValueKey('buy-public-store-collection-benefit'),
      );
      expect(benefit, findsNothing);
      setup.facts.wrongProduct = true;
      expect(setup.session.refreshProductFacts(current.id), isFalse);
      await tester.pumpAndSettle();
      expect(benefit, findsNothing);
      expect(setup.session.quantityFor(setup.products.last.id), 1);
      setup.facts.wrongProduct = false;
      expect(setup.session.refreshProductFacts(current.id), isTrue);
      await tester.pumpAndSettle();
      expect(benefit, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Local cutoff resume does not restore collection promotion', (
    tester,
  ) async {
    var now = tester.binding.clock.now();
    final setup = await _CollectionHeaderFixture.create(tester, now: () => now);
    addTearDown(setup.dispose);
    final current = setup.products.first;
    expect(setup.session.openProduct(current.id), isTrue);
    await tester.pumpWidget(_app(setup.session));
    await tester.pumpAndSettle();
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    final seller = find.byKey(ValueKey('buy-shop-seller-action-${current.id}'));
    await _revealProductAction(tester, current.id, seller);
    await tester.ensureVisible(seller);
    await tester.pumpAndSettle();
    await tester.tap(seller);
    await tester.pumpAndSettle();
    final benefit = find.byKey(
      const ValueKey('buy-public-store-collection-benefit'),
    );
    expect(benefit, findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(hours: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(benefit, findsNothing);
    expect(setup.session.selectedProductId, current.id);
    expect(tester.takeException(), isNull);
  });

  for (final id in ['s-milk-500ml', 's-milk-2l', 'w-rice-50kg', 'w-oil-10l']) {
    test('R66 supplier catalogue retains exact entry variant $id', () {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final product = session.product(id);
      expect(product.catalogueListing, isFalse);
      final products = session.partnerCatalogueFor(product);
      expect(products.map((item) => item.id), contains(id));
      expect(products.first, same(product));
      expect(session.partnerCatalogueFor(product, limit: 1), [product]);
      expect(session.partnerCatalogueFor(product, limit: 0), isEmpty);
      expect(products.map((item) => item.id).toSet().length, products.length);
      for (final item in products) {
        expect(item, same(session.product(item.id)));
        expect(item.seller, product.seller);
        expect(item.destination, product.destination);
        expect(item.catalogueListing || item.id == id, isTrue);
        if (product.destination == BuyV2Destination.wholesale) {
          expect(item.offerClass, product.offerClass);
        }
      }
      expect(product.catalogueListing, isFalse);
      final main = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.canonicalId == product.canonicalId &&
            item.destination == product.destination,
      );
      expect(
        session
            .partnerCatalogueFor(main)
            .every((item) => item.catalogueListing),
        isTrue,
        reason: 'A variant visit must not change the main catalogue listing',
      );
      expect(
        session
            .partnerCatalogueFor(product.copyWith(id: 'unlisted-$id'))
            .any((item) => item.id == 'unlisted-$id'),
        isFalse,
        reason: 'Never manufacture a catalogue entry from a caller object',
      );
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('R66 supplier variant journey $id text $scale', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(scale == 2 ? 320 : 390, 844);
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.reset);
        final core = BuySession();
        final session = BuyV2Session(core: core);
        addTearDown(session.dispose);
        addTearDown(core.dispose);
        final product = session.product(id);
        final otherId = product.destination == BuyV2Destination.shop
            ? 'w-notebook'
            : 's-eggs';
        session.addProduct(otherId);
        final otherQuantity = session.quantityFor(otherId);
        expect(session.openProduct(id), isTrue);
        await tester.pumpWidget(_app(session, textScale: scale));
        await tester.pumpAndSettle();
        final shop = product.destination == BuyV2Destination.shop;
        final prefix = shop ? 'buy-shop-seller' : 'buy-wholesale-supplier';
        void expectNestedStatusContrast() {
          final regions = find.byType(AnnotatedRegion<SystemUiOverlayStyle>);
          expect(regions, findsWidgets);
          expect(
            tester
                .widget<AnnotatedRegion<SystemUiOverlayStyle>>(regions.last)
                .value
                .statusBarIconBrightness,
            Brightness.light,
          );
          final bars = find.byWidgetPredicate(
            (widget) =>
                widget is ColoredBox && widget.color == BuyV2Colors.navy,
          );
          expect(
            bars.evaluate().any((element) {
              final box = element.renderObject;
              if (box is! RenderBox || !box.hasSize) return false;
              return (box.localToGlobal(Offset.zero) & box.size).contains(
                Offset(tester.view.physicalSize.width / 2, 12),
              );
            }),
            isTrue,
            reason:
                'R665 D03: light status icons must have a painted dark inset.',
          );
        }

        final action = find.byKey(
          ValueKey(
            '${shop ? 'buy-shop-seller-action' : 'buy-wholesale-store-action'}-$id',
          ),
        );
        await _revealProductAction(tester, id, action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        final sheet = find.byKey(ValueKey('$prefix-sheet-$id'));
        expect(sheet, findsOneWidget);
        Future<void> expectCompleteRiceEta(Finder owner) async {
          if (id != 'w-rice-50kg') return;
          final card = find.descendant(
            of: owner,
            matching: find.byKey(ValueKey('buy-product-$id')),
          );
          if (card.evaluate().isEmpty) {
            final horizontal = find
                .descendant(
                  of: owner,
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is Scrollable &&
                        widget.axisDirection == AxisDirection.right,
                  ),
                )
                .first;
            await tester.ensureVisible(horizontal);
            await tester.pumpAndSettle();
            await tester.ensureVisible(card);
            await tester.pumpAndSettle();
          }
          final unitPrice = find.descendant(
            of: find.descendant(
              of: owner,
              matching: find.byKey(ValueKey('buy-product-$id')),
            ),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is RichText &&
                  widget.text.toPlainText() == product.unitPrice,
            ),
          );
          expect(unitPrice, findsOneWidget);
          final unitParagraph = tester.renderObject<RenderParagraph>(unitPrice);
          expect(
            unitParagraph.didExceedMaxLines,
            isFalse,
            reason: 'Supplier unit price must remain complete at enlarged text',
          );
          final unitNatural = TextPainter(
            text: unitParagraph.text,
            textDirection: unitParagraph.textDirection,
            textScaler: unitParagraph.textScaler,
          )..layout(maxWidth: unitParagraph.size.width);
          expect(
            unitParagraph.size.height + .1,
            greaterThanOrEqualTo(unitNatural.height),
          );
          unitNatural.dispose();
          final promises = find.descendant(
            of: find.descendant(
              of: owner,
              matching: find.byKey(ValueKey('buy-product-$id')),
            ),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is RichText &&
                  widget.text.toPlainText().toLowerCase().contains(
                    'at checkout',
                  ),
            ),
          );
          expect(promises, findsOneWidget);
          final paragraph = tester.renderObject<RenderParagraph>(promises);
          expect(paragraph.didExceedMaxLines, isFalse);
          final natural = TextPainter(
            text: paragraph.text,
            textDirection: paragraph.textDirection,
            textScaler: paragraph.textScaler,
          )..layout(maxWidth: paragraph.size.width);
          expect(
            paragraph.size.height + .1,
            greaterThanOrEqualTo(natural.height),
          );
          natural.dispose();
        }

        await expectCompleteRiceEta(sheet);
        if (id == 'w-rice-50kg') {
          await captureR66Visual(tester, '025-rice-preview-text-$scale');
        }
        expect(
          find.descendant(
            of: sheet,
            matching: find.byKey(ValueKey('buy-product-$id')),
          ),
          findsOneWidget,
        );
        final viewAll = find.byKey(ValueKey('$prefix-view-more-$id'));
        await tester.ensureVisible(viewAll);
        final viewAllLabel = find.descendant(
          of: viewAll,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('View all'),
          ),
        );
        expect(viewAllLabel, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(viewAllLabel).didExceedMaxLines,
          isFalse,
          reason: 'The complete View all label must be visible',
        );
        await tester.tap(viewAll);
        await tester.pumpAndSettle();
        final full = find.byKey(ValueKey('$prefix-full-catalogue-list'));
        expect(full, findsOneWidget);
        await expectCompleteRiceEta(full);
        if (id == 'w-rice-50kg') {
          await captureR66Visual(tester, '025-rice-full-text-$scale');
        }
        final card = find.descendant(
          of: full,
          matching: find.byKey(ValueKey('buy-product-$id')),
        );
        expect(card, findsOneWidget);
        final add = find.descendant(
          of: card,
          matching: find.byKey(ValueKey('buy-add-$id')),
        );
        await tester.ensureVisible(add);
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(session.quantityFor(id), product.minimumOrder);
        expect(session.quantityFor(otherId), otherQuantity);
        final packshot = find.descendant(
          of: card,
          matching: find.byKey(ValueKey('buy-grid-packshot-$id')),
        );
        await tester.ensureVisible(packshot);
        await tester.pumpAndSettle();
        const imageAction = Alignment(-.5, .55);
        expect(packshot.hitTestable(at: imageAction), findsOneWidget);
        await tester.tapAt(imageAction.withinRect(tester.getRect(packshot)));
        await tester.pumpAndSettle();
        expect(session.selectedProductId, id);
        expect(tester.takeException(), isNull);
        expect(find.byKey(PageStorageKey('buy-product-$id')), findsWidgets);
        expectNestedStatusContrast();
        expect(find.byKey(const ValueKey('buy-store-cart-bar')), findsNothing);
        final productCart = find.byKey(
          const ValueKey('buy-cart-navigation-button'),
        );
        expect(productCart.hitTestable(), findsOneWidget);
        await tester.tap(productCart);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expectNestedStatusContrast();
        expect(
          session.cartScope,
          shop ? BuyV2CartScope.shop : BuyV2CartScope.wholesale,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(PageStorageKey('buy-product-$id')), findsWidgets);
        expectNestedStatusContrast();
        expect(productCart.hitTestable(), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(full, findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byKey(ValueKey('$prefix-full-catalogue-sheet')),
            matching: find.byKey(const ValueKey('buy-store-cart-bar')),
          ),
        );
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(
          session.cartScope,
          shop ? BuyV2CartScope.shop : BuyV2CartScope.wholesale,
        );
        final cartProduct = find.byKey(
          ValueKey('buy-cart-product-details-$id'),
        );
        await tester.ensureVisible(cartProduct);
        await tester.pumpAndSettle();
        expect(cartProduct.hitTestable(), findsOneWidget);
        await tester.tap(cartProduct);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.product);
        expect(session.selectedProductId, id);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        await tester.tap(find.widgetWithText(FilledButton, 'Checkout'));
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.checkout);
        await tester.tap(
          find.byKey(const ValueKey('buy-checkout-return-cart')),
        );
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(full, findsOneWidget);
        final close = find.byKey(ValueKey('$prefix-full-catalogue-close'));
        await tester.scrollUntilVisible(
          close,
          -100,
          scrollable: find
              .descendant(of: full, matching: find.byType(Scrollable))
              .first,
        );
        await tester.ensureVisible(close);
        await tester.pumpAndSettle();
        expect(close.hitTestable(), findsOneWidget);
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(sheet, findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byKey(ValueKey('$prefix-route-$id')),
            matching: find.byKey(const ValueKey('buy-store-cart-bar')),
          ),
        );
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(sheet, findsOneWidget);
        final storeClose = find.byKey(ValueKey('$prefix-sheet-close'));
        expect(storeClose.hitTestable(), findsOneWidget);
        expect(
          tester.widget<IconButton>(storeClose).style!.side!.resolve({}),
          BorderSide.none,
        );
        expect(
          tester.getSize(storeClose).shortestSide,
          greaterThanOrEqualTo(44),
        );
        await tester.tap(storeClose);
        await tester.pumpAndSettle();
        expect(session.selectedProductId, id);
        expect(session.quantityFor(id), product.minimumOrder);
        expect(session.quantityFor(otherId), otherQuantity);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final firstId in ['s-eggs', 'w-notebook']) {
    testWidgets('R66 Cart store continuation stays scoped after $firstId', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      session.addProduct('s-eggs');
      session.addProduct('w-notebook');
      final first = session.product(firstId);
      final other = session.product(
        firstId == 's-eggs' ? 'w-notebook' : 's-eggs',
      );
      expect(session.openProduct(first.id), isTrue);
      await tester.pumpWidget(_app(session));
      await tester.pumpAndSettle();

      Future<void> visitAndClose(BuyV2Product product) async {
        final prefix = product.destination == BuyV2Destination.shop
            ? 'buy-shop-seller'
            : 'buy-wholesale-supplier';
        final action = find.byKey(
          ValueKey(
            '${product.destination == BuyV2Destination.shop ? 'buy-shop-seller-action' : 'buy-wholesale-store-action'}-${product.id}',
          ),
        );
        await _revealProductAction(tester, product.id, action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey('$prefix-sheet-${product.id}')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(ValueKey('$prefix-sheet-close')));
        await tester.pumpAndSettle();
      }

      await visitAndClose(first);
      session.openCart();
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('buy-cart-scope-${other.destination.name}')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-cart-continue-store')),
        findsNothing,
        reason: 'An unvisited scope must not offer the other scope store',
      );

      expect(session.openProduct(other.id), isTrue);
      await tester.pumpAndSettle();
      await visitAndClose(other);
      session.openCart();
      await tester.pumpAndSettle();
      for (final product in [first, other]) {
        await tester.tap(
          find.byKey(ValueKey('buy-cart-scope-${product.destination.name}')),
        );
        await tester.pumpAndSettle();
        final action = find.byKey(const ValueKey('buy-cart-continue-store'));
        expect(action, findsOneWidget);
        expect(
          find.descendant(of: action, matching: find.text(product.seller)),
          findsOneWidget,
        );
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        final prefix = product.destination == BuyV2Destination.shop
            ? 'buy-shop-seller'
            : 'buy-wholesale-supplier';
        expect(
          find.byKey(ValueKey('$prefix-sheet-${product.id}')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(ValueKey('$prefix-sheet-close')));
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
      }
      await tester.tap(find.byKey(const ValueKey('buy-cart-scope-all')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-cart-continue-store')),
          matching: find.text(other.seller),
        ),
        findsOneWidget,
        reason: 'All-scope Cart retains the most recently visited store',
      );
      expect(session.quantityFor('s-eggs'), 1);
      expect(session.quantityFor('w-notebook'), 1);
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'store and brand catalogues remain exact and destination-scoped',
    () async {
      final core = BuySession();
      final products = BuyV2Catalogue.products
          .map(
            (product) =>
                const {'s-milk', 's-curd', 'w-milk'}.contains(product.id)
                ? product.copyWith(brand: 'Published dairy brand')
                : product,
          )
          .toList();
      final session = BuyV2Session(
        core: core,
        reviewDataEnabled: false,
        commerceAdapter: _CollectionHeaderCommerce(products),
      );
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      await session.restoreCommerce();

      final eggs = session.product('s-eggs');
      final storeProducts = session.partnerCatalogueFor(eggs);
      expect(storeProducts.first.id, eggs.id);
      expect(
        storeProducts.map((product) => product.id),
        containsAll(['s-eggs', 's-chicken']),
      );
      expect(
        storeProducts.every(
          (product) =>
              product.destination == BuyV2Destination.shop &&
              product.seller == 'Safe Protein Store' &&
              product.catalogueListing,
        ),
        isTrue,
      );

      final tomato = session.product('s-tomato');
      expect(tomato.brand, isEmpty);
      expect(session.brandCatalogueFor(tomato), isEmpty);
      final milk = session.product('s-milk');
      final brandProducts = session.brandCatalogueFor(milk);
      expect(brandProducts.first.id, milk.id);
      expect(brandProducts.length, greaterThan(1));
      expect(brandProducts.map((product) => product.id), contains('s-curd'));
      expect(
        brandProducts.map((product) => product.id),
        isNot(contains('w-milk')),
      );
      expect(
        brandProducts.every(
          (product) =>
              product.destination == BuyV2Destination.shop &&
              product.brand == milk.brand &&
              product.catalogueListing,
        ),
        isTrue,
      );
      expect(
        session.partnerCatalogueFor(session.product('m-paracetamol-500')),
        isEmpty,
      );
    },
  );

  testWidgets('Shop store catalogue reuses product cards and opens one item', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-eggs'), isTrue);

    await tester.pumpWidget(_app(session));
    await tester.pumpAndSettle();
    final sellerAction = find.byKey(
      const ValueKey('buy-shop-seller-action-s-eggs'),
    );
    await _revealProductAction(tester, 's-eggs', sellerAction);
    await tester.tap(sellerAction);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-shop-seller-sheet-s-eggs')),
      findsOneWidget,
    );
    expect(find.text('Safe Protein Store'), findsWidgets);
    expect(find.text('Store products'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.key.toString().contains('buy-vertical-product-summary-'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('buy-product-s-eggs')), findsOneWidget);
    final chicken = find.byKey(const ValueKey('buy-product-s-chicken'));
    expect(chicken, findsOneWidget);
    await tester.tap(chicken);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-shop-seller-sheet-s-eggs')),
      findsNothing,
    );
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, 's-chicken');
    expect(tester.takeException(), isNull);
  });

  testWidgets('product details keeps Visit store as the single store route', (
    tester,
  ) async {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    final product = session.product('s-eggs');
    expect(session.openProduct(product.id), isTrue);

    await tester.pumpWidget(_app(session));
    await tester.pumpAndSettle();
    final sellerAction = find.byKey(
      ValueKey('buy-shop-seller-action-${product.id}'),
    );
    await _revealProductAction(tester, product.id, sellerAction);

    expect(find.text('Visit store'), findsOneWidget);
    expect(
      find.byKey(ValueKey('buy-brand-action-${product.id}')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('store grid keeps one full-size Add action', (tester) async {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-eggs'), isTrue);

    await tester.pumpWidget(_app(session));
    await tester.pumpAndSettle();
    final sellerAction = find.byKey(
      const ValueKey('buy-shop-seller-action-s-eggs'),
    );
    await _revealProductAction(tester, 's-eggs', sellerAction);
    await tester.tap(sellerAction);
    await tester.pumpAndSettle();

    final add = find.byKey(const ValueKey('buy-add-s-chicken'));
    await tester.scrollUntilVisible(
      add,
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('buy-shop-seller-sheet-s-eggs')),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  (widget.axisDirection == AxisDirection.down ||
                      widget.axisDirection == AxisDirection.up),
            ),
          )
          .first,
    );
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    expect(add, findsOneWidget);
    expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
    expect(
      find.byKey(const ValueKey('buy-grid-buy-now-s-chicken')),
      findsNothing,
    );

    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(session.quantityFor('s-chicken'), 1);
    expect(
      find.byKey(const ValueKey('buy-shop-seller-sheet-s-eggs')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'store grid Add keeps the shopper in the store and updates Cart',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct('s-eggs'), isTrue);

      await tester.pumpWidget(_app(session));
      await tester.pumpAndSettle();
      final sellerAction = find.byKey(
        const ValueKey('buy-shop-seller-action-s-eggs'),
      );
      await _revealProductAction(tester, 's-eggs', sellerAction);
      await tester.tap(sellerAction);
      await tester.pumpAndSettle();

      final add = find.byKey(const ValueKey('buy-add-s-chicken'));
      await tester.scrollUntilVisible(
        add,
        180,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('buy-shop-seller-sheet-s-eggs')),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    (widget.axisDirection == AxisDirection.down ||
                        widget.axisDirection == AxisDirection.up),
              ),
            )
            .first,
      );
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();

      expect(session.quantityFor('s-chicken'), 1);
      expect(
        find.byKey(const ValueKey('buy-shop-seller-sheet-s-eggs')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'store catalogue exposes full products and exact related-store continuation',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct('s-eggs'), isTrue);

      await tester.pumpWidget(_app(session));
      await tester.pumpAndSettle();
      final sellerAction = find.byKey(
        const ValueKey('buy-shop-seller-action-s-eggs'),
      );
      await _revealProductAction(tester, 's-eggs', sellerAction);
      await tester.tap(sellerAction);
      await tester.pumpAndSettle();

      final storeSheet = find.byKey(
        const ValueKey('buy-shop-seller-sheet-s-eggs'),
      );
      final storeScroll = find
          .descendant(of: storeSheet, matching: find.byType(Scrollable))
          .first;
      final viewMore = find.byKey(
        const ValueKey('buy-shop-seller-view-more-s-eggs'),
      );
      await tester.scrollUntilVisible(viewMore, 220, scrollable: storeScroll);
      await tester.tap(viewMore);
      await tester.pumpAndSettle();
      final fullCatalogue = find.byKey(
        const ValueKey('buy-shop-seller-full-catalogue-list'),
      );
      expect(fullCatalogue, findsOneWidget);
      final catalogueBounds = tester.getRect(fullCatalogue);
      expect(catalogueBounds.top, greaterThanOrEqualTo(0));
      expect(catalogueBounds.bottom, lessThanOrEqualTo(844));
      expect(catalogueBounds.height, greaterThan(0));
      expect(
        find
            .byKey(const ValueKey('buy-shop-seller-full-catalogue-close'))
            .hitTestable(),
        findsOneWidget,
      );
      expect(find.text('Safe Protein Store'), findsWidgets);
      final fullEggs = find
          .descendant(
            of: fullCatalogue,
            matching: find.byKey(const ValueKey('buy-product-s-eggs')),
          )
          .first;
      expect(fullEggs, findsOneWidget);
      expect(tester.getSize(fullEggs).width, inInclusiveRange(90, 390 / 3));
      expect(tester.getSize(fullEggs).width, lessThanOrEqualTo(390));

      await tester.tap(
        find.byKey(const ValueKey('buy-shop-seller-full-catalogue-close')),
      );
      await tester.pumpAndSettle();
      final relatedStores = find.byKey(
        const ValueKey('buy-shop-seller-other-stores'),
      );
      await tester.scrollUntilVisible(
        relatedStores,
        220,
        scrollable: storeScroll,
      );
      expect(relatedStores, findsOneWidget);
      final related = find.byKey(
        const ValueKey('buy-shop-seller-other-store-s-tomato'),
      );
      await Scrollable.ensureVisible(tester.element(related), alignment: .4);
      await tester.pumpAndSettle();
      expect(related.hitTestable(), findsOneWidget);
      await tester.tap(related);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-seller-sheet-s-tomato')),
        findsOneWidget,
      );
      expect(find.text('Shree Balaji Fresh'), findsWidgets);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-shop-seller-sheet-header')),
          matching: find.text('Shree Balaji Fresh'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'four-product store keeps readable previews and all products reachable',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct('s-curd'), isTrue);

      await tester.pumpWidget(_app(session));
      await tester.pumpAndSettle();
      final sellerAction = find.byKey(
        const ValueKey('buy-shop-seller-action-s-curd'),
      );
      await _revealProductAction(tester, 's-curd', sellerAction);
      await tester.tap(sellerAction);
      await tester.pumpAndSettle();

      final products = session.partnerCatalogueFor(session.product('s-curd'));
      expect(products.length, 4);
      final sheet = find.byKey(const ValueKey('buy-shop-seller-sheet-s-curd'));
      final previewCards = [
        for (final product in products)
          find.descendant(
            of: sheet,
            matching: find.byKey(ValueKey('buy-product-${product.id}')),
          ),
      ];
      final firstRow = previewCards.take(3).map(tester.getRect).toList();
      expect(firstRow[1].top, closeTo(firstRow[0].top, .5));
      expect(firstRow[2].top, greaterThan(firstRow[0].bottom));
      expect(
        tester.getRect(previewCards[3]).top,
        greaterThan(firstRow[0].bottom),
      );
      for (final product in products.take(2)) {
        final card = find
            .descendant(
              of: sheet,
              matching: find.byKey(ValueKey('buy-product-${product.id}')),
            )
            .first;
        expect(card, findsOneWidget);
        expect(tester.getRect(card).right, lessThanOrEqualTo(378));
      }
      final vertical = find
          .descendant(
            of: sheet,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            ),
          )
          .first;
      expect(vertical, findsOneWidget);
      for (final product in products) {
        final card = find.descendant(
          of: sheet,
          matching: find.byKey(ValueKey('buy-product-${product.id}')),
        );
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        expect(card, findsOneWidget);
        expect(tester.getSize(card).width, inInclusiveRange(134, 390 / 2));
        final title = find.descendant(
          of: card,
          matching: find.text(product.customerTitle),
        );
        expect(title, findsOneWidget);
      }
      final viewMore = find.byKey(
        const ValueKey('buy-shop-seller-view-more-s-curd'),
      );
      tester.state<ScrollableState>(vertical).position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(viewMore, 140, scrollable: vertical);
      await tester.ensureVisible(viewMore);
      await tester.pumpAndSettle();
      expect(viewMore.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

final class _SkuSnapshotCommerce implements BuyV2CommerceAdapter {
  _SkuSnapshotCommerce(this.order, this.currentProduct);
  final BuyV2Order order;
  final BuyV2Product currentProduct;
  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready,
    products: [currentProduct],
    orders: [order],
  );
  @override
  Future<BuyV2OrderAlertsResult> loadOrderAlerts() async =>
      const BuyV2OrderAlertsResult(
        available: true,
        enabled: false,
        customerMessage: '',
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
    'Unexpected commerce action in snapshot presentation test',
  );
}

final class _CollectionHeaderCommerce implements BuyV2CommerceAdapter {
  _CollectionHeaderCommerce(this.products);
  final List<BuyV2Product> products;

  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready,
    products: products,
  );

  @override
  Future<BuyV2OrderAlertsResult> loadOrderAlerts() async =>
      const BuyV2OrderAlertsResult(
        available: true,
        enabled: false,
        customerMessage: '',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected commerce call in Store header test');
}

final class _CollectionHeaderFacts implements BuyV2ProductFactsAdapter {
  _CollectionHeaderFacts(this.now);
  final DateTime Function() now;
  BuyV2StoreCollectionCapability? capability;
  bool stale = false;
  bool wrongProduct = false;

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    final base = const BuyV2CatalogueProductFactsAdapter().snapshotFor(product);
    return BuyV2ProductFactsSnapshot(
      productId: wrongProduct ? 'unrelated-product' : product.id,
      price: base.price,
      deliveryPromise: base.deliveryPromise,
      partner: base.partner,
      orderabilityLabel: base.orderabilityLabel,
      sourceId: 'collection-header-v1',
      storeOperatingState: BuyV2StoreOperatingState.open,
      storeCollection: capability,
      observedAt: now(),
      stale: stale,
    );
  }
}

final class _CollectionHeaderFixture {
  _CollectionHeaderFixture(this.core, this.session, this.facts, this.products);
  final BuySession core;
  final BuyV2Session session;
  final _CollectionHeaderFacts facts;
  final List<BuyV2Product> products;

  BuyV2StoreCollectionCapability supported({DateTime? validUntil}) =>
      BuyV2StoreCollectionCapability(
        storeId: 'collection-store-a',
        supportsCollection: true,
        sourceId: 'collection-header-v1',
        observedAt: facts.now(),
        validUntil: validUntil ?? facts.now().add(const Duration(hours: 1)),
      );

  static Future<_CollectionHeaderFixture> create(
    WidgetTester tester, {
    DateTime Function()? now,
  }) async {
    final core = BuySession();
    final clock = now ?? tester.binding.clock.now;
    final facts = _CollectionHeaderFacts(clock);
    BuyV2Product seed(String id) =>
        BuyV2Catalogue.allProducts.firstWhere((product) => product.id == id);
    final products = [
      seed('s-milk-500ml').copyWith(storeId: 'collection-store-a'),
      seed('s-milk').copyWith(storeId: 'collection-store-a'),
      seed(
        's-milk',
      ).copyWith(id: 'other-branch-milk', storeId: 'collection-store-b'),
    ];
    final session = BuyV2Session(
      core: core,
      commerceAdapter: _CollectionHeaderCommerce(products),
      productFactsAdapter: BuyTestEligibilityFacts(delegate: facts, now: clock),
      catalogueNow: clock,
      reviewDataEnabled: false,
    );
    final result = _CollectionHeaderFixture(core, session, facts, products);
    facts.capability = result.supported();
    await session.restoreCommerce();
    return result;
  }

  void dispose() {
    session.dispose();
    core.dispose();
  }
}

Future<void> _revealPagedHeader(
  WidgetTester tester,
  String scope,
  Finder target,
) async {
  final scrollable = find
      .descendant(
        of: find.byKey(ValueKey('buy-paged-scroll-$scope')),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(target, -100, scrollable: scrollable);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
}

class _OffersJourneySource extends BuyV2DevelopmentPublishedCatalogueSource {
  _OffersJourneySource({required super.now});
  bool failNext = false;
  final queries = <BuyV2CatalogueQuery>[];
  final pages = <BuyV2CataloguePage<BuyV2PublishedCatalogueOffer>>[];
  @override
  Future<BuyV2CataloguePage<BuyV2PublishedCatalogueOffer>> loadOffers(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    queries.add(query);
    if (failNext && cursor != null) throw StateError('Offer page unavailable');
    final sourcePage = await super.loadOffers(
      query,
      cursor: cursor,
      pageSize: pageSize,
    );
    // This journey exercises supplier publication, not the separate MoolSocial
    // group. Keep explicit supplier fixtures as development cohorts evolve.
    final page = BuyV2CataloguePage<BuyV2PublishedCatalogueOffer>(
      queryKey: sourcePage.queryKey,
      snapshotId: sourcePage.snapshotId,
      startIndex: sourcePage.startIndex,
      totalCount: sourcePage.totalCount,
      previousCursor: sourcePage.previousCursor,
      nextCursor: sourcePage.nextCursor,
      items: sourcePage.items.map((offer) {
        final retail = offer.product.destination == BuyV2Destination.shop;
        return BuyV2PublishedCatalogueOffer(
          publicationId: offer.publicationId,
          product: offer.product,
          publisherType: retail
              ? BuyV2OfferPublisherType.retailer
              : BuyV2OfferPublisherType.manufacturer,
          publisherId: offer.product.storeId!,
          publisherName: offer.product.seller,
          headline: retail ? 'Store offer' : 'Manufacturer price',
          sourceId: offer.sourceId,
          observedAt: offer.observedAt,
          validUntil: offer.validUntil,
        );
      }),
    );
    pages.add(page);
    return page;
  }
}

class _OffersJourneyCatalogueSource implements BuyV2CataloguePageSource {
  _OffersJourneyCatalogueSource({required DateTime Function() now})
    : shop = BuyV2DevelopmentCatalogueSource(
        destination: BuyV2Destination.shop,
        now: now,
      ),
      wholesale = BuyV2DevelopmentCatalogueSource(
        destination: BuyV2Destination.wholesale,
        now: now,
      );
  final BuyV2DevelopmentCatalogueSource shop;
  final BuyV2DevelopmentCatalogueSource wholesale;
  BuyV2DevelopmentCatalogueSource _source(BuyV2CatalogueQuery query) =>
      query.destination == BuyV2Destination.shop ? shop : wholesale;
  @override
  Future<BuyV2CataloguePage<BuyV2StoreListing>> loadStores(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) => _source(query).loadStores(query, cursor: cursor, pageSize: pageSize);
  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) => _source(query).loadProducts(query, cursor: cursor, pageSize: pageSize);
  @override
  Future<List<BuyV2Product>> resolveProducts(Set<String> productIds) async => [
    ...await shop.resolveProducts(
      productIds.where((id) => id.contains('-shop-')).toSet(),
    ),
    ...await wholesale.resolveProducts(
      productIds.where((id) => id.contains('-wholesale-')).toSet(),
    ),
  ];
}

class _StoreJourneySource extends BuyV2DevelopmentCatalogueSource {
  _StoreJourneySource(BuyV2Destination destination, {this.name = 'Mool Market'})
    : super(destination: destination);
  final String name;
  bool failStorePage = false;
  final storeQueries = <BuyV2CatalogueQuery>[];
  final productQueries = <BuyV2CatalogueQuery>[];
  // The same display name deliberately identifies different Store branches.
  BuyV2Product _named(BuyV2Product product) => product.copyWith(seller: name);
  BuyV2CataloguePage<T> _copyPage<T>(
    BuyV2CataloguePage<dynamic> page,
    Iterable<T> items,
  ) => BuyV2CataloguePage<T>(
    queryKey: page.queryKey,
    snapshotId: page.snapshotId,
    items: items,
    startIndex: page.startIndex,
    totalCount: page.totalCount,
    previousCursor: page.previousCursor,
    nextCursor: page.nextCursor,
  );

  @override
  Future<BuyV2CataloguePage<BuyV2StoreListing>> loadStores(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    storeQueries.add(query);
    final page = await super.loadStores(
      query,
      cursor: cursor,
      pageSize: pageSize,
    );
    return _copyPage(
      page,
      page.items.map(
        (store) => BuyV2StoreListing(
          id: store.id,
          name: name,
          area: store.area,
          address: store.address,
          regionId: store.regionId,
          distanceMeters: store.distanceMeters,
          collection: store.collection,
          previewProduct: store.previewProduct == null
              ? null
              : _named(store.previewProduct!),
        ),
      ),
    );
  }

  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    productQueries.add(query);
    if (failStorePage && query.storeId != null && cursor != null) {
      throw StateError('Store page unavailable');
    }
    final page = await super.loadProducts(
      query,
      cursor: cursor,
      pageSize: pageSize,
    );
    return _copyPage(page, page.items.map(_named));
  }
}

class _PagedWidgetSource extends BuyV2DevelopmentCatalogueSource {
  _PagedWidgetSource(
    BuyV2Destination destination, {
    this.longMetadata = false,
    this.contrastingPagePrices = false,
    this.providerMetadata = false,
    super.providerCount = 40,
    super.skusPerStore = 5000,
  }) : super(destination: destination);
  final bool longMetadata;
  final bool contrastingPagePrices;
  final bool providerMetadata;
  String? updatedProviderName;
  bool failNext = false;
  Completer<void>? pageDelay;
  final requests = <BuyV2CatalogueQuery>[];
  final pages = <BuyV2CataloguePage<BuyV2Product>>[];

  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    requests.add(query);
    if (pageDelay case final delay?) await delay.future;
    if (failNext && cursor != null) throw StateError('Page source unavailable');
    var page = await super.loadProducts(
      query,
      cursor: cursor,
      pageSize: pageSize,
    );
    if (contrastingPagePrices) {
      page = BuyV2CataloguePage(
        queryKey: page.queryKey,
        snapshotId: page.snapshotId,
        startIndex: page.startIndex,
        totalCount: page.totalCount,
        previousCursor: page.previousCursor,
        nextCursor: page.nextCursor,
        items: page.items.map(
          (product) =>
              product.copyWith(price: page.startIndex == 0 ? 1 : 12345),
        ),
      );
    }
    if (longMetadata) {
      page = BuyV2CataloguePage(
        queryKey: page.queryKey,
        snapshotId: page.snapshotId,
        startIndex: page.startIndex,
        totalCount: page.totalCount,
        previousCursor: page.previousCursor,
        nextCursor: page.nextCursor,
        items: page.items.map(
          (product) => product.copyWith(
            title:
                'Premium organically grown family selection with extra-long consumer product name',
            pack:
                'Case of 120 individually sealed family packs, 500 grams each',
            seller:
                'Neighbourhood Family Farmers and Wholefoods Cooperative Store',
            price: 10000000,
            unitPrice: 'INR 166666.67 per kilogram',
          ),
        ),
      );
    }
    if (providerMetadata) {
      page = BuyV2CataloguePage(
        queryKey: page.queryKey,
        snapshotId: page.snapshotId,
        startIndex: page.startIndex,
        totalCount: page.totalCount,
        previousCursor: page.previousCursor,
        nextCursor: page.nextCursor,
        items: page.items.indexed.map((entry) {
          final (index, product) = entry;
          if (index > 2) return product;
          return product.copyWith(
            seller:
                updatedProviderName ??
                (index == 0
                    ? 'supermandi tech priate limited'
                    : index == 1
                    ? 'hanumana ram beniwal sardarpura jodhpure store'
                    : 'हनुमाना Wholesale दुकान PROVIDERIDENTIFIERABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'),
          );
        }),
      );
    }
    pages.add(page);
    return page;
  }
}

ThemeData _skuFixtureTheme() {
  final theme = MoolTheme.light();
  if (const String.fromEnvironment('BUY_SKU_DEVANAGARI_FONT').isEmpty) {
    return theme;
  }
  return theme.copyWith(
    textTheme: theme.textTheme.apply(
      fontFamilyFallback: const ['NotoSansDevanagari'],
    ),
    primaryTextTheme: theme.primaryTextTheme.apply(
      fontFamilyFallback: const ['NotoSansDevanagari'],
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: theme.outlinedButtonTheme.style!.copyWith(
        textStyle: WidgetStateProperty.resolveWith(
          (states) => theme.outlinedButtonTheme.style!.textStyle!
              .resolve(states)!
              .copyWith(fontFamilyFallback: const ['NotoSansDevanagari']),
        ),
      ),
    ),
  );
}

Widget _app(
  BuyV2Session session, {
  double textScale = 1,
  bool? disableAnimations,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: _skuFixtureTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      disableAnimations: disableAnimations,
    ),
    child: r66VisualCaptureRoot(child!),
  ),
  home: BuyV2Screen(
    session: session,
    initialDestination: session.destination,
    initialView: session.view,
    productId: session.selectedProductId,
  ),
);

Future<void> _revealProductAction(
  WidgetTester tester,
  String productId,
  Finder action,
) async {
  final scrollable = find
      .descendant(
        of: find.byKey(PageStorageKey('buy-product-$productId')),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(action, 220, scrollable: scrollable);
  await tester.pumpAndSettle();
  expect(action, findsOneWidget);
}

Future<void> _performCatalogueAction(
  WidgetTester tester,
  Finder catalogue,
  String label,
) async {
  final handle = tester.ensureSemantics();
  try {
    await tester.pump();
    final semantics = tester.widget<Semantics>(catalogue);
    final actions = semantics.properties.customSemanticsActions!;
    final action = actions.keys.singleWhere((action) => action.label == label);
    final node = tester.getSemantics(catalogue);
    node.owner!.performAction(
      node.id,
      SemanticsAction.customAction,
      CustomSemanticsAction.getIdentifier(action),
    );
    await tester.pumpAndSettle();
  } finally {
    handle.dispose();
  }
}
