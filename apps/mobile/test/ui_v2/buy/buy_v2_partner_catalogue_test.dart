import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

import 'buy_v2_screen_test.dart' show captureR66Visual, r66VisualCaptureRoot;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
        final range = find.byKey(const ValueKey('buy-page-range-$scope'));
        final next = find.byKey(const ValueKey('buy-page-next-$scope'));
        final vertical = find.byKey(const ValueKey('buy-paged-scroll-$scope'));
        Future<void> reveal(Finder target, {bool header = false}) async {
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
              Offset(0, header ? 100 : -100),
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

        await capture('header');
        await reveal(range);
        expect(tester.widget<Text>(range).data, '1–40 of 20,000,000 offers');
        final countParagraph = tester.renderObject<RenderParagraph>(range);
        final countStart = tester
            .widget<Text>(range)
            .data!
            .indexOf('20,000,000');
        final countBoxes = countParagraph.getBoxesForSelection(
          TextSelection(baseOffset: countStart, extentOffset: countStart + 10),
        );
        expect(
          countBoxes,
          hasLength(1),
          reason: 'The result count must not split inside its number',
        );
        expect(published.pages.single.items.length, 40);
        await capture('initial');
        final original = published.pages.single.items;
        final retailProduct = original
            .firstWhere(
              (offer) => offer.product.destination == BuyV2Destination.shop,
            )
            .product;
        final tradeProduct = original
            .firstWhere(
              (offer) =>
                  offer.product.destination == BuyV2Destination.wholesale,
            )
            .product;
        for (final product in [retailProduct, tradeProduct]) {
          final lane = find.byKey(
            ValueKey(
              'buy-paged-lane-$scope-${product.destination == BuyV2Destination.shop ? 0 : 1}',
            ),
          );
          await reveal(lane);
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
        await reveal(next, header: true);
        published.failNext = true;
        await tester.tap(next);
        await tester.pumpAndSettle();
        final retry = find.widgetWithText(TextButton, 'Try again');
        await reveal(range, header: true);
        expect(tester.widget<Text>(range).data, '1–40 of 20,000,000 offers');
        await reveal(retry);
        expect(find.text('Results could not refresh'), findsOneWidget);
        await capture('retry');
        published.failNext = false;
        await tester.tap(retry);
        await tester.pumpAndSettle();
        await reveal(range, header: true);
        expect(tester.widget<Text>(range).data, '41–80 of 20,000,000 offers');
        final pageProduct = published.pages.last.items.first.product;
        await reveal(find.byKey(const ValueKey('buy-paged-lane-$scope-0')));
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
        final maker = find.byKey(
          const ValueKey('buy-offers-filter-manufacturer'),
        );
        await reveal(maker, header: true);
        await tester.tap(maker);
        await tester.pumpAndSettle();
        expect(
          published.queries.last.offerPublisher,
          BuyV2OfferPublisherType.manufacturer,
        );
        expect(published.pages.last.totalCount, 5000000);
        expect(
          published.pages.last.items.every(
            (offer) =>
                offer.publisherType == BuyV2OfferPublisherType.manufacturer,
          ),
          isTrue,
        );
        final makerName = published.pages.last.items.first.publisherName;
        await reveal(find.byKey(const ValueKey('buy-published-offer-facts')));
        expect(find.textContaining('Published by $makerName'), findsWidgets);
        await capture('publisher');
        final makerProduct = published.pages.last.items.first.product;
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
        final storeAction = find.byKey(
          ValueKey('buy-wholesale-store-action-${makerProduct.id}'),
        );
        await _revealProductAction(tester, makerProduct.id, storeAction);
        await tester.tap(storeAction);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('buy-public-store-name')))
              .data,
          makerProduct.seller,
        );
        expect(
          session.catalogueStore(makerProduct.storeId!)?.id,
          makerProduct.storeId,
        );
        expect(
          find.byKey(const ValueKey('buy-public-store-collection-benefit')),
          findsOneWidget,
        );
        await capture('store');
        await tester.tap(
          find.byKey(const ValueKey('buy-wholesale-supplier-sheet-close')),
        );
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(published.queries.length, filteredRequests);
        expect(
          session.retainedCatalogueOffersQuery(scope)?.offerPublisher,
          BuyV2OfferPublisherType.manufacturer,
        );
        await reveal(maker, header: true);
        await tester.tap(maker);
        await tester.pumpAndSettle();
        expect(published.queries.last.offerPublisher, isNull);
        final categoryControl = find.byKey(
          const ValueKey('buy-offers-category-control'),
        );
        await reveal(categoryControl, header: true);
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
        expect(published.pages.last.items, isNotEmpty);
        expect(
          published.pages.last.items.every(
            (offer) => offer.product.categoryId == category.id,
          ),
          isTrue,
        );
        expect(session.selectedCategoryId, originalCategory);
        await reveal(categoryControl, header: true);
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
        expect(published.pages.last.items, isNotEmpty);
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
          published.pages.last.items.every(
            (offer) => offer.isCurrent(now: now),
          ),
          isTrue,
        );
        await reveal(find.byKey(const ValueKey('buy-paged-lane-$scope-0')));
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
          await tester.tap(firstName);
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<Text>(
                  find.byKey(const ValueKey('buy-public-store-name')),
                )
                .data,
            'Mool Market',
          );
          expect(
            find.byKey(const ValueKey('buy-public-store-collection-benefit')),
            findsOneWidget,
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
                of: find.byKey(ValueKey('$owner-sheet-list')),
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
            find.byKey(ValueKey('$owner-view-more-$relatedProductId')),
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
          await tester.scrollUntilVisible(
            viewAll,
            -100,
            scrollable: publicScroll,
          );
          await tester.pumpAndSettle();
          await tester.tap(viewAll);
          await tester.pumpAndSettle();
          final storeScope = 'store-${destination.name}-$firstStoreId';
          final range = find.byKey(ValueKey('buy-page-range-$storeScope'));
          expect(tester.widget<Text>(range).data, '1–40 of 5,000');
          expect(source.productQueries.last.storeId, firstStoreId);
          expect(source.productQueries.last.query, '');
          expect(source.productQueries.last.categoryId, 'all');
          await captureR66Visual(tester, 'r5-store-$profile-full');

          final next = find.byKey(ValueKey('buy-page-next-$storeScope'));
          await _revealPagedHeader(tester, storeScope, next);
          source.failStorePage = true;
          await tester.tap(next);
          await tester.pumpAndSettle();
          expect(find.text('Results could not refresh'), findsOneWidget);
          await captureR66Visual(tester, 'r5-store-$profile-retry');
          source.failStorePage = false;
          final retry = find.widgetWithText(TextButton, 'Try again');
          await tester.ensureVisible(retry);
          await tester.pumpAndSettle();
          await tester.tap(retry);
          await tester.pumpAndSettle();
          expect(tester.widget<Text>(range).data, '41–80 of 5,000');
          final product = source.productIdAt(0, 40);
          final image = find.byKey(ValueKey('buy-grid-packshot-$product'));
          await tester.ensureVisible(image);
          await tester.pumpAndSettle();
          const imageAction = Alignment(-.5, .55);
          expect(image.hitTestable(at: imageAction), findsOneWidget);
          final requestCount = source.productQueries.length;
          await tester.tapAt(imageAction.withinRect(tester.getRect(image)));
          await tester.pumpAndSettle();
          expect(session.selectedProductId, product);
          expect(session.selectedProduct?.storeId, firstStoreId);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(source.productQueries.length, requestCount);
          await captureR66Visual(tester, 'r5-store-$profile-return');
          await _revealPagedHeader(tester, storeScope, range);
          expect(tester.widget<Text>(range).data, '41–80 of 5,000');

          final storeField = find.byKey(
            const ValueKey('buy-store-product-search'),
          );
          await _revealPagedHeader(tester, storeScope, storeField);
          await tester.enterText(storeField, 'sku 4999');
          await tester.pumpAndSettle();
          final lastProduct = source.productIdAt(0, 4998);
          expect(tester.widget<Text>(range).data, '1–1 of 1');
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
          final categoryControl = find.byKey(
            const ValueKey('buy-store-category-control'),
          );
          await _revealPagedHeader(tester, storeScope, categoryControl);
          await tester.tap(categoryControl);
          await tester.pumpAndSettle();
          final category = session
              .categoriesFor(destination)
              .firstWhere((value) => value.id != 'all');
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
          await tester.pumpAndSettle();
          await tester.tap(choice);
          await tester.pumpAndSettle();
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
            find.byKey(ValueKey('buy-paged-lane-$storeScope-0')),
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
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
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
            find.byKey(ValueKey('$owner-view-more-$secondProductId')),
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
          final range = find.byKey(ValueKey('buy-page-range-$scope'));
          expect(tester.widget<Text>(range).data, startsWith('1–40 of '));
          expect(source.requests.length, 1);
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

          final next = find.byKey(ValueKey('buy-page-next-$scope'));
          await _revealPagedHeader(tester, scope, next);
          source.failNext = true;
          await tester.tap(next);
          await tester.pumpAndSettle();
          expect(find.text('Results could not refresh'), findsOneWidget);
          expect(tester.widget<Text>(range).data, startsWith('1–40 of '));
          expect(session.quantityFor(first.id), first.minimumOrder);
          await captureR66Visual(tester, 'r5-paged-$profile-retry');
          source.failNext = false;
          final retry = find.widgetWithText(TextButton, 'Try again');
          await tester.ensureVisible(retry);
          await tester.pumpAndSettle();
          await tester.tap(retry);
          await tester.pumpAndSettle();
          expect(tester.widget<Text>(range).data, startsWith('41–80 of '));
          expect(session.isSaved(first.id), isTrue);
          expect(session.quantityFor(first.id), first.minimumOrder);

          final lane = find.byKey(ValueKey('buy-paged-lane-$scope-0'));
          final packshots = find.descendant(
            of: lane,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget.key is ValueKey<String> &&
                  (widget.key! as ValueKey<String>).value.startsWith(
                    'buy-grid-packshot-',
                  ),
            ),
          );
          await tester.ensureVisible(packshots.first);
          await tester.pumpAndSettle();
          // Use the uncovered image below the badge and Save hit area. A tall
          // card's centre can sit outside the short landscape viewport.
          const imageAction = Alignment(-.5, .55);
          expect(packshots.first.hitTestable(at: imageAction), findsOneWidget);
          await tester.dragFrom(
            imageAction.withinRect(tester.getRect(packshots.first)),
            const Offset(-330, 0),
          );
          await tester.pumpAndSettle();
          final laneOffset = tester.widget<ListView>(lane).controller!.offset;
          expect(laneOffset, greaterThan(0));
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
          final requestCount = source.requests.length;
          await captureR66Visual(tester, 'r5-paged-$profile-page2');
          await tester.tapAt(
            imageAction.withinRect(tester.getRect(visibleImage)),
          );
          await tester.pumpAndSettle();
          expect(session.selectedProductId, opened.id);
          expect(session.view, BuyV2View.product);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(session.view, BuyV2View.catalogue);
          expect(source.requests.length, requestCount);
          expect(
            tester.widget<ListView>(vertical).controller!.offset,
            closeTo(verticalOffset, 1),
          );
          expect(
            tester.widget<ListView>(lane).controller!.offset,
            closeTo(laneOffset, 1),
          );
          expect(session.quantityFor(first.id), first.minimumOrder);
          await captureR66Visual(tester, 'r5-paged-$profile-return');

          await _revealPagedHeader(tester, scope, next);
          expect(tester.widget<Text>(range).data, startsWith('41–80 of '));
          final area = find.byKey(const ValueKey('buy-change-location'));
          await _revealPagedHeader(tester, scope, area);
          await tester.tap(area);
          await tester.pumpAndSettle();
          final field = find.byKey(const ValueKey('buy-catalogue-area-search'));
          await tester.enterText(field, 'Mum');
          tester.view.viewInsets = const FakeViewPadding(bottom: 180);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await captureR66Visual(tester, 'r5-paged-$profile-area-keyboard');
          final mumbai = find.byKey(
            const ValueKey('buy-catalogue-area-mumbai'),
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
          expect(tester.widget<Text>(range).data, startsWith('1–40 of '));
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
      testWidgets('R5 collection visibility keeps the exact branch $profile', (
        tester,
      ) async {
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
        expect(benefit, findsOneWidget);
        final text = find.descendant(
          of: benefit,
          matching: find.text('Order ahead. Scan & collect.'),
        );
        expect(text, findsOneWidget);
        final bounds = tester.getRect(benefit);
        expect(bounds.top, greaterThanOrEqualTo(24));
        expect(bounds.bottom, lessThanOrEqualTo(size.height - 34));
        final viewport = tester.getRect(
          find.ancestor(of: benefit, matching: find.byType(Scrollable)).first,
        );
        expect(bounds.top, greaterThanOrEqualTo(viewport.top));
        expect(bounds.bottom, lessThanOrEqualTo(viewport.bottom));
        final paragraph = tester.renderObject<RenderParagraph>(text);
        final natural = TextPainter(
          text: paragraph.text,
          textDirection: paragraph.textDirection,
          textScaler: paragraph.textScaler,
        )..layout(maxWidth: paragraph.size.width);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(
          paragraph.size.height + .1,
          greaterThanOrEqualTo(natural.height),
        );
        natural.dispose();
        await captureR66Visual(tester, 'collect-header-$profile-supported');

        // Identical display names cannot mix different branches' products.
        expect(
          session.partnerCatalogueFor(current).map((product) => product.id),
          [current.id, setup.products[1].id],
        );
        expect(session.product(current.id).storeId, 'collection-store-a');
        expect(session.product(current.id).pack, '500 ml pouch');
        expect(session.quantityFor(other.id), 1);
        expect(session.isSaved(other.id), isTrue);
        final close = find.byKey(const ValueKey('buy-shop-seller-sheet-close'));
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
        expect(tester.takeException(), isNull);
      });
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
        find.byKey(const ValueKey('buy-public-store-name')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-public-store-collection-benefit')),
        findsNothing,
      );
      expect(find.text('Order ahead. Scan & collect.'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'R5 collection visibility updates and expires on the same Store',
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
      expect(benefit, findsOneWidget);

      setup.facts.capability = null;
      expect(session.refreshProductFacts(current.id), isTrue);
      await tester.pumpAndSettle();
      expect(benefit, findsNothing);

      setup.facts.capability = setup.supported(
        validUntil: tester.binding.clock.now().add(const Duration(seconds: 5)),
      );
      expect(session.refreshProductFacts(current.id), isTrue);
      await tester.pumpAndSettle();
      expect(benefit, findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(benefit, findsNothing);
      expect(session.selectedProductId, current.id);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('R5 collection visibility withdraws after an invalid refresh', (
    tester,
  ) async {
    final setup = await _CollectionHeaderFixture.create(tester);
    addTearDown(setup.dispose);
    final current = setup.products.first;
    setup.session.addProduct(setup.products.last.id);
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
    expect(benefit, findsOneWidget);
    setup.facts.wrongProduct = true;
    expect(setup.session.refreshProductFacts(current.id), isFalse);
    await tester.pumpAndSettle();
    expect(benefit, findsNothing);
    expect(setup.session.quantityFor(setup.products.last.id), 1);
    setup.facts.wrongProduct = false;
    expect(setup.session.refreshProductFacts(current.id), isTrue);
    await tester.pumpAndSettle();
    expect(benefit, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('R5 collection visibility rechecks capability on app resume', (
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
    expect(benefit, findsOneWidget);
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
          expect(item.minimumOrder > 2, product.minimumOrder > 2);
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
        void expectCompleteRiceEta(Finder owner) {
          if (id != 'w-rice-50kg') return;
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
                  widget.text.toPlainText().contains('5:00'),
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

        expectCompleteRiceEta(sheet);
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
        expectCompleteRiceEta(full);
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
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(PageStorageKey('buy-product-$id')), findsWidgets);
        await tester.tap(find.byKey(const ValueKey('buy-store-cart-bar')));
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        expect(
          session.cartScope,
          shop ? BuyV2CartScope.shop : BuyV2CartScope.wholesale,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(PageStorageKey('buy-product-$id')), findsWidgets);
        expect(
          find.byKey(const ValueKey('buy-store-cart-bar')),
          findsOneWidget,
        );
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
        await tester.tap(cartProduct);
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.product);
        expect(session.selectedProductId, id);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(session.view, BuyV2View.cart);
        await tester.tap(find.widgetWithText(FilledButton, 'Review order'));
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
        await tester.tap(find.byKey(ValueKey('$prefix-full-catalogue-close')));
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
        await tester.tap(find.byKey(ValueKey('$prefix-sheet-close')));
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

  test('store and brand catalogues remain exact and destination-scoped', () {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);

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
    final brandProducts = session.brandCatalogueFor(tomato);
    expect(brandProducts.first.id, tomato.id);
    expect(brandProducts.length, greaterThan(1));
    expect(
      brandProducts.every(
        (product) =>
            product.destination == BuyV2Destination.shop &&
            product.brand == tomato.brand &&
            product.catalogueListing,
      ),
      isTrue,
    );
    expect(
      session.partnerCatalogueFor(session.product('m-paracetamol-500')),
      isEmpty,
    );
  });

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
    expect(find.text('Store products'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-horizontal-product-grid')),
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
      expect(tester.getSize(fullEggs).width, lessThan(130));

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
      await tester.tap(related);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-shop-seller-sheet-s-tomato')),
        findsOneWidget,
      );
      expect(find.text('Shree Balaji Fresh'), findsWidgets);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-shop-seller-sheet-s-tomato')),
          matching: find.text('Store products'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('four-product store fills one three-SKU row without dead width', (
    tester,
  ) async {
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
    expect(
      find.descendant(
        of: sheet,
        matching: find.byKey(const ValueKey('buy-horizontal-product-lane-0')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sheet,
        matching: find.byKey(const ValueKey('buy-horizontal-product-lane-1')),
      ),
      findsNothing,
    );
    for (final product in products.take(3)) {
      final card = find
          .descendant(
            of: sheet,
            matching: find.byKey(ValueKey('buy-product-${product.id}')),
          )
          .first;
      expect(card, findsOneWidget);
      expect(tester.getRect(card).right, lessThanOrEqualTo(378));
    }
    expect(
      find.byKey(const ValueKey('buy-shop-seller-view-more-s-curd')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
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
      productFactsAdapter: facts,
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
    final page = await super.loadOffers(
      query,
      cursor: cursor,
      pageSize: pageSize,
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
  _StoreJourneySource(BuyV2Destination destination)
    : super(destination: destination);
  bool failStorePage = false;
  final storeQueries = <BuyV2CatalogueQuery>[];
  final productQueries = <BuyV2CatalogueQuery>[];
  // The same display name deliberately identifies different Store branches.
  BuyV2Product _named(BuyV2Product product) =>
      product.copyWith(seller: 'Mool Market');
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
          name: 'Mool Market',
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
  _PagedWidgetSource(BuyV2Destination destination)
    : super(destination: destination, providerCount: 40);
  bool failNext = false;
  final requests = <BuyV2CatalogueQuery>[];

  @override
  Future<BuyV2CataloguePage<BuyV2Product>> loadProducts(
    BuyV2CatalogueQuery query, {
    String? cursor,
    required int pageSize,
  }) async {
    requests.add(query);
    if (failNext && cursor != null) throw StateError('Page source unavailable');
    return super.loadProducts(query, cursor: cursor, pageSize: pageSize);
  }
}

Widget _app(BuyV2Session session, {double textScale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: MoolTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
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
