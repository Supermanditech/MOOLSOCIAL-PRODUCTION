import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_scanner.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_shop_chat.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Buy V2 R33 search-media-chat local candidate captures',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);

      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.symmetric(vertical: 24),
              viewPadding: const EdgeInsets.symmetric(vertical: 24),
            ),
            child: child!,
          ),
          home: BuyV2Screen(
            session: session,
            scannerLauncher: showBuyV2ManualCodeSheet,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _capture(tester, 'shop');

      await tester.tap(find.byKey(const ValueKey('buy-open-scanner')));
      await tester.pump(const Duration(milliseconds: 400));
      await _captureOverlay(tester, 'scanner-manual');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      final shopCategory = session.categories[1];
      await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
      await tester.pumpAndSettle();
      await _captureOverlay(tester, 'category-picker');
      await tester.tap(find.byKey(ValueKey('buy-category-${shopCategory.id}')));
      await tester.pumpAndSettle();
      await _capture(tester, 'shop-category');
      await tester.drag(
        find.byKey(const ValueKey('buy-horizontal-product-lane-0')),
        const Offset(-260, 0),
      );
      await tester.pumpAndSettle();
      await _capture(tester, 'shop-category-horizontal');
      await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-category-all')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-search-control')));
      await tester.pumpAndSettle();
      await _capture(tester, 'shop-search');
      await tester.enterText(
        find.byKey(const ValueKey('buy-search-field')),
        'milk',
      );
      await tester.pumpAndSettle();
      await _capture(tester, 'shop-search-results');
      await tester.tap(find.byKey(const ValueKey('buy-search-clear')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-search-close')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-saved-products-button')));
      await tester.pumpAndSettle();
      await _capture(tester, 'shop-saved');

      session.openDestination(BuyV2Destination.wholesale);
      await tester.pumpAndSettle();
      await _capture(tester, 'wholesale');

      session.openDestination(BuyV2Destination.medicine);
      await tester.pumpAndSettle();
      await _capture(tester, 'medicine');
      await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-prescription-button')));
      await tester.pumpAndSettle();
      await _captureOverlay(tester, 'medicine-prescription');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      final shop = BuyV2Catalogue.products.firstWhere(
        (product) => product.destination == BuyV2Destination.shop,
      );
      final wholesale = BuyV2Catalogue.products.firstWhere(
        (product) => product.destination == BuyV2Destination.wholesale,
      );
      final medicine = BuyV2Catalogue.products.firstWhere(
        (product) =>
            product.destination == BuyV2Destination.medicine &&
            !product.requiresPrescription,
      );

      session.openProduct(shop.id);
      await tester.pumpAndSettle();
      await _capture(tester, 'product');

      session.addProduct(shop.id);
      session.returnToCatalogue();
      session.clearNotice();
      await tester.pumpAndSettle();
      await _capture(tester, 'shop-cart-focus');

      session.addProduct(wholesale.id);
      session.addProduct(medicine.id);
      session.openCart();
      session.clearNotice();
      await tester.pumpAndSettle();
      await _capture(tester, 'cart');

      session.openCheckout();
      await tester.pumpAndSettle();
      await _capture(tester, 'checkout');
      await tester.tap(find.text('Change').first);
      await tester.pumpAndSettle();
      await _captureOverlay(tester, 'checkout-address');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change').last);
      await tester.pumpAndSettle();
      await _captureOverlay(tester, 'checkout-payment');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      session.confirmOrder();
      await tester.pumpAndSettle();
      await _capture(tester, 'confirmation');

      session.openOrders();
      await tester.pumpAndSettle();
      await _capture(tester, 'orders');

      session.openTracking('MS-240782');
      await tester.pumpAndSettle();
      await _capture(tester, 'tracking');

      session.openAssist();
      await tester.pumpAndSettle();
      await _capture(tester, 'assist');
      await tester.tap(
        find.byKey(const ValueKey('buy-assist-intent-Where is my order?')),
      );
      await tester.pumpAndSettle();
      await _capture(tester, 'assist-intent');

      session.openAccount();
      await tester.pumpAndSettle();
      await _capture(tester, 'account');

      await tester.tap(find.byKey(const ValueKey('buy-account-orders')));
      await tester.pumpAndSettle();
      await _capture(tester, 'account-orders');
      session.returnToAccount();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-account-prescriptions')));
      await tester.pumpAndSettle();
      await _captureOverlay(tester, 'account-prescription');
      await tester.tap(find.byKey(const ValueKey('buy-prescription-add-new')));
      await tester.pumpAndSettle();
      await _capture(tester, 'account-prescription-added');

      final workspace = find.byKey(const ValueKey('buy-account-workspace'));
      await tester.ensureVisible(workspace);
      await tester.tap(workspace);
      await tester.pumpAndSettle();
      await _capture(tester, 'account-wholesale');
      session.returnToAccount();
      await tester.pumpAndSettle();

      session.closeAccount();
      await tester.pumpAndSettle();

      session.openDestination(BuyV2Destination.shop);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-root-selected')));
      await tester.pumpAndSettle();
      await _capture(tester, 'mool-rail');

      expect(tester.takeException(), isNull);
    },
    // Run explicitly with --run-skipped --update-goldens for evidence.
    skip: true,
  );

  testWidgets(
    'Buy V2 R33 search-media-chat responsive journey captures',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      for (final viewport in const [
        (
          size: Size(320, 568),
          safe: EdgeInsets.symmetric(vertical: 24),
          textScale: 1.0,
          label: '320x568',
        ),
        (
          size: Size(390, 844),
          safe: EdgeInsets.only(top: 47, bottom: 34),
          textScale: 1.0,
          label: '390x844-ios',
        ),
        (
          size: Size(430, 932),
          safe: EdgeInsets.only(top: 59, bottom: 34),
          textScale: 1.0,
          label: '430x932-ios',
        ),
        (
          size: Size(320, 568),
          safe: EdgeInsets.symmetric(vertical: 24),
          textScale: 1.4,
          label: '320x568-a11y140',
        ),
      ]) {
        tester.view.physicalSize = viewport.size;
        final core = BuySession();
        final session = BuyV2Session(core: core);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MoolTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: viewport.safe,
                viewPadding: viewport.safe,
                textScaler: TextScaler.linear(viewport.textScale),
              ),
              child: child!,
            ),
            home: BuyV2Screen(
              session: session,
              scannerLauncher: (_) async => null,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _captureResponsive(tester, 'shop', viewport.label);
        await tester.tap(find.byKey(const ValueKey('buy-category-picker')));
        await tester.pumpAndSettle();
        await _captureResponsiveOverlay(
          tester,
          'category-picker',
          viewport.label,
        );
        await tester.tap(find.byKey(const ValueKey('buy-category-close')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-search-control')));
        await tester.pumpAndSettle();
        await _captureResponsive(tester, 'shop-search', viewport.label);
        await tester.enterText(
          find.byKey(const ValueKey('buy-search-field')),
          'milk',
        );
        await tester.pumpAndSettle();
        await _captureResponsive(tester, 'shop-search-results', viewport.label);
        await tester.tap(find.byKey(const ValueKey('buy-search-clear')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('buy-search-close')));
        await tester.pumpAndSettle();
        session.openDestination(BuyV2Destination.wholesale);
        await tester.pumpAndSettle();
        await _captureResponsive(tester, 'wholesale', viewport.label);
        session.openDestination(BuyV2Destination.medicine);
        await tester.pumpAndSettle();
        await _captureResponsive(tester, 'medicine', viewport.label);
        session.openOrders();
        await tester.pumpAndSettle();
        await _captureResponsive(tester, 'orders', viewport.label);

        final shop = BuyV2Catalogue.products.firstWhere(
          (product) => product.destination == BuyV2Destination.shop,
        );
        final wholesale = BuyV2Catalogue.products.firstWhere(
          (product) => product.destination == BuyV2Destination.wholesale,
        );
        final medicine = BuyV2Catalogue.products.firstWhere(
          (product) =>
              product.destination == BuyV2Destination.medicine &&
              !product.requiresPrescription,
        );
        session.openProduct(shop.id);
        await tester.pumpAndSettle();
        await _captureResponsive(tester, 'product', viewport.label);
        session.addProduct(shop.id);
        session.addProduct(wholesale.id);
        session.addProduct(medicine.id);
        session.openCart();
        session.clearNotice();
        await tester.pumpAndSettle();
        await _captureResponsive(tester, 'cart', viewport.label);
        session.openCheckout();
        await tester.pumpAndSettle();
        await _captureResponsive(tester, 'checkout', viewport.label);
        session.confirmOrder();
        await tester.pumpAndSettle();
        await _captureResponsive(tester, 'confirmation', viewport.label);
        session.openTracking('MS-240782');
        await tester.pumpAndSettle();
        await _captureResponsive(tester, 'tracking', viewport.label);
        session.openAssist();
        await tester.pumpAndSettle();
        await _captureResponsive(tester, 'assist', viewport.label);
        session.openAccount();
        await tester.pumpAndSettle();
        await _captureResponsive(tester, 'account', viewport.label);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        session.dispose();
        core.dispose();
      }
      expect(tester.takeException(), isNull);
    },
    // Run explicitly with --run-skipped --update-goldens for evidence.
    skip: true,
  );

  testWidgets(
    'Buy V2 R33 horizontal and Account supplement captures',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);

      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.symmetric(vertical: 24),
              viewPadding: const EdgeInsets.symmetric(vertical: 24),
            ),
            child: child!,
          ),
          home: BuyV2Screen(
            session: session,
            scannerLauncher: (_) async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final horizontalGrid = find.byKey(
        const ValueKey('buy-horizontal-product-grid'),
      );
      await tester.scrollUntilVisible(
        horizontalGrid,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await _capture(tester, 'shop-products-before-swipe');

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
      final upperPosition = tester
          .state<ScrollableState>(upperScrollable)
          .position;
      final lowerPosition = tester
          .state<ScrollableState>(lowerScrollable)
          .position;
      await tester.drag(upperLane, const Offset(-520, 0));
      await tester.pumpAndSettle();
      expect(upperPosition.pixels, greaterThan(0));
      expect(lowerPosition.pixels, 0);
      await _capture(tester, 'shop-products-after-swipe');
      await tester.drag(lowerLane, const Offset(-520, 0));
      await tester.pumpAndSettle();
      expect(upperPosition.pixels, greaterThan(0));
      expect(lowerPosition.pixels, greaterThan(0));
      await _capture(tester, 'shop-products-lower-lane-after-swipe');

      session.openAccount();
      await tester.pumpAndSettle();
      await _capture(tester, 'account-without-verified');
      expect(find.textContaining('Verified'), findsNothing);
      expect(tester.takeException(), isNull);
    },
    // Run explicitly with --run-skipped --update-goldens for evidence.
    skip: true,
  );

  testWidgets(
    'Buy V2 R35.1 dense flat vertical search suggestion captures',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      for (final viewport in const [
        (
          size: Size(320, 568),
          safe: EdgeInsets.symmetric(vertical: 24),
          textScale: 1.0,
          label: '320x568',
        ),
        (
          size: Size(390, 844),
          safe: EdgeInsets.only(top: 47, bottom: 34),
          textScale: 1.0,
          label: '390x844-ios',
        ),
        (
          size: Size(430, 932),
          safe: EdgeInsets.only(top: 59, bottom: 34),
          textScale: 1.0,
          label: '430x932-ios',
        ),
        (
          size: Size(320, 568),
          safe: EdgeInsets.symmetric(vertical: 24),
          textScale: 1.4,
          label: '320x568-a11y140',
        ),
      ]) {
        tester.view.physicalSize = viewport.size;
        final core = BuySession();
        final session = BuyV2Session(core: core);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MoolTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: viewport.safe,
                viewPadding: viewport.safe,
                textScaler: TextScaler.linear(viewport.textScale),
              ),
              child: child!,
            ),
            home: BuyV2Screen(
              session: session,
              scannerLauncher: (_) async => null,
            ),
          ),
        );
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
          await _captureR34SearchSuggestions(
            tester,
            destination.name,
            viewport.label,
          );
          await tester.tap(find.byKey(const ValueKey('buy-search-close')));
          await tester.pumpAndSettle();
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        session.dispose();
        core.dispose();
      }
      expect(tester.takeException(), isNull);
    },
    // Run explicitly with --run-skipped --update-goldens for additive evidence.
    skip: true,
  );

  testWidgets(
    'OPPO installed baseline header removal review captures',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);

      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
        BuyV2Destination.orders,
      ]) {
        final core = BuySession();
        final session = BuyV2Session(core: core);
        final reviewRootKey = ValueKey(
          'buy-header-removal-review-root-${destination.name}',
        );

        await tester.pumpWidget(
          RepaintBoundary(
            key: reviewRootKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: MoolTheme.light(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  viewPadding: const EdgeInsets.symmetric(vertical: 24),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: BuyV2Screen(session: session),
            ),
          ),
        );
        await tester.pumpAndSettle();

        if (destination == BuyV2Destination.orders) {
          session.openOrders();
          await tester.pumpAndSettle();
        } else if (destination != BuyV2Destination.shop) {
          session.openDestination(destination);
          await tester.pumpAndSettle();
        }

        await _captureHeaderRemovalReview(
          tester,
          destination.name,
          reviewRootKey,
        );
        expect(
          find.byKey(const ValueKey('buy-header-visual-creative-reel')),
          findsNothing,
          reason: destination.name,
        );
        expect(
          find.byKey(const ValueKey('buy-open-account')),
          findsOneWidget,
          reason: destination.name,
        );

        if (destination == BuyV2Destination.shop) {
          await tester.tap(find.byKey(const ValueKey('buy-open-account')));
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('buy-account-hub')), findsOneWidget);
          expect(find.byKey(const ValueKey('buy-search-band')), findsNothing);
          await _captureHeaderRemovalReview(tester, 'account', reviewRootKey);
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        session.dispose();
        core.dispose();
      }

      expect(tester.takeException(), isNull);
    },
    // Run explicitly with --run-skipped --update-goldens for review evidence.
    skip: true,
  );

  testWidgets(
    'post-order confirmation and invoice review captures',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);

      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      const reviewRootKey = ValueKey('buy-post-order-review-root');

      await tester.pumpWidget(
        RepaintBoundary(
          key: reviewRootKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MoolTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.symmetric(vertical: 24),
                viewPadding: const EdgeInsets.symmetric(vertical: 24),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: BuyV2Screen(session: session),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final shop = BuyV2Catalogue.products.firstWhere(
        (product) => product.destination == BuyV2Destination.shop,
      );
      final wholesale = BuyV2Catalogue.products.firstWhere(
        (product) => product.destination == BuyV2Destination.wholesale,
      );
      session.addProduct(shop.id);
      session.increase(shop.id);
      session.addProduct(wholesale.id);
      session.openCart();
      session.openCheckout();
      session.confirmOrder();
      await tester.pumpAndSettle();

      await _capturePostOrderReview(
        tester,
        'confirmation-shop-wholesale',
        reviewRootKey,
      );
      final shopOrder = session.confirmedOrders.firstWhere(
        (order) => order.destination == BuyV2Destination.shop,
      );
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

      await _capturePostOrderReview(tester, 'invoice-shop', reviewRootKey);
      expect(tester.takeException(), isNull);
    },
    // Run explicitly with --run-skipped --update-goldens for review evidence.
    skip: true,
  );

  testWidgets(
    'Offers progressive browsing laptop review captures',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      const reviewRootKey = ValueKey('buy-offers-review-root');

      await tester.pumpWidget(
        RepaintBoundary(
          key: reviewRootKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MoolTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.symmetric(vertical: 24),
                viewPadding: const EdgeInsets.symmetric(vertical: 24),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: BuyV2Screen(session: session),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
      await tester.pumpAndSettle();
      await _captureOffersReview(tester, 'offers', reviewRootKey);

      await tester.fling(
        find.byKey(const ValueKey('buy-horizontal-product-lane-0')),
        const Offset(-1200, 0),
        2200,
      );
      await tester.pumpAndSettle();
      await _captureOffersReview(tester, 'offers-paged', reviewRootKey);

      session.openProduct('w-oil');
      await tester.pumpAndSettle();
      await _captureOffersReview(tester, 'offer-product', reviewRootKey);

      session.addProduct('w-oil');
      session.openCart();
      await tester.pumpAndSettle();
      await _captureOffersReview(tester, 'cart-browse-more', reviewRootKey);

      await tester.tap(find.byKey(const ValueKey('buy-cart-browse-more')));
      await tester.pumpAndSettle();
      await _captureOffersReview(tester, 'offers-cart-active', reviewRootKey);

      session.openOrders();
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const PageStorageKey('buy-orders')),
        const Offset(0, -520),
      );
      await tester.pumpAndSettle();
      await _captureOffersReview(tester, 'orders-browse', reviewRootKey);
      expect(tester.takeException(), isNull);
    },
    // Run explicitly with --run-skipped --update-goldens for review evidence.
    skip: true,
  );

  testWidgets(
    'Shop Chat professional tap-journey review captures',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      const reviewRootKey = ValueKey('buy-shop-chat-review-root');

      await tester.pumpWidget(
        RepaintBoundary(
          key: reviewRootKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: MoolTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.symmetric(vertical: 24),
                viewPadding: const EdgeInsets.symmetric(vertical: 24),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: BuyV2Screen(
              session: session,
              onOpenChat: () {},
              shopChatSource: const _CaptureShopChatSource(),
              onShopChatAction: (_) async =>
                  const BuyV2ShopChatActionResult.accepted(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('buy-shop-chat')), findsOneWidget);
      await _captureShopChatReview(tester, 'shop-inbox', reviewRootKey);

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-local-tab-orders')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await _captureShopChatReview(tester, 'orders-inbox', reviewRootKey);

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-local-tab-offers')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await _captureShopChatReview(tester, 'offers-inbox', reviewRootKey);

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-back')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-local-tab-wholesale')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
      await tester.pumpAndSettle();
      await _captureShopChatReview(tester, 'partners-inbox', reviewRootKey);

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-new')));
      await tester.pumpAndSettle();
      await _captureShopChatReview(tester, 'new-conversation', reviewRootKey);
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-new-retail-live')),
      );
      await tester.pumpAndSettle();
      await _captureShopChatReview(tester, 'conversation', reviewRootKey);

      await tester.enterText(
        find.byKey(const ValueKey('buy-shop-chat-composer-field')),
        'Can this arrive tomorrow morning?',
      );
      await tester.pump();
      await _captureShopChatReview(tester, 'composer-draft', reviewRootKey);
      await tester.enterText(
        find.byKey(const ValueKey('buy-shop-chat-composer-field')),
        '',
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-emoji')));
      await tester.pumpAndSettle();
      await _captureShopChatReview(tester, 'emoji-tray', reviewRootKey);
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-emoji')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
      await tester.pumpAndSettle();
      await _captureShopChatReview(tester, 'attachments', reviewRootKey);
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-attach')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-more')));
      await tester.pumpAndSettle();
      await _captureShopChatReview(tester, 'thread-menu', reviewRootKey);
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-menu-search')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('buy-shop-chat-message-search-field')),
        'basket',
      );
      await tester.pumpAndSettle();
      await _captureShopChatReview(
        tester,
        'conversation-search',
        reviewRootKey,
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-shop-chat-message-search-close')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-thread-info')));
      await tester.pumpAndSettle();
      await _captureShopChatReview(tester, 'business-info', reviewRootKey);
      await tester.tap(find.byKey(const ValueKey('buy-shop-chat-info-back')));
      await tester.pumpAndSettle();

      await tester.longPress(
        find.byKey(const ValueKey('buy-shop-chat-message-received-text')),
      );
      await tester.pumpAndSettle();
      await _captureShopChatReview(tester, 'message-actions', reviewRootKey);
      expect(tester.takeException(), isNull);
    },
    // Run explicitly with --run-skipped --update-goldens for review evidence.
    skip: true,
  );

  testWidgets(
    'B01 T01A remove Medicine tab founder capture',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);

      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      for (final destination in const [
        BuyV2Destination.shop,
        BuyV2Destination.wholesale,
      ]) {
        final product = BuyV2Catalogue.products.firstWhere(
          (item) =>
              item.destination == destination && !item.requiresPrescription,
        );
        session.addProduct(product.id);
      }
      session.openDestination(BuyV2Destination.wholesale);
      session.openCart(scope: BuyV2CartScope.wholesale);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.symmetric(vertical: 24),
              viewPadding: const EdgeInsets.symmetric(vertical: 24),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: BuyV2Screen(
            session: session,
            initialDestination: BuyV2Destination.wholesale,
            initialView: BuyV2View.cart,
            initialCartScope: BuyV2CartScope.wholesale,
            scannerLauncher: (_) async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Shop'), findsWidgets);
      expect(find.text('Wholesale'), findsWidgets);
      expect(find.textContaining('Medicine'), findsNothing);
      await expectLater(
        find.byKey(const ValueKey('buy-v2-screen')),
        matchesGoldenFile(
          'candidate_captures/'
          'buy-b01-t01a-remove-medicine-only-360x800.png',
        ),
      );
      expect(tester.takeException(), isNull);
    },
    // Founder-review evidence only; run explicitly with --run-skipped.
    skip: true,
  );

  testWidgets(
    'B01 T01B optional GST invoice founder capture',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      final product = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.wholesale &&
            !item.requiresPrescription,
      );
      session.addProduct(product.id);
      session.openDestination(BuyV2Destination.wholesale);
      session.openCart(scope: BuyV2CartScope.wholesale);
      expect(session.openCheckout(), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          home: BuyV2Screen(
            session: session,
            initialDestination: BuyV2Destination.wholesale,
            initialView: BuyV2View.checkout,
            initialCartScope: BuyV2CartScope.wholesale,
            scannerLauncher: (_) async => null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-gst-request-wholesale')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-gst-add-wholesale')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('buy-gst-legal-name')),
        'Shree Balaji Retail',
      );
      await tester.enterText(
        find.byKey(const ValueKey('buy-gst-gstin')),
        '08ABCDE1234F1Z5',
      );
      await tester.enterText(
        find.byKey(const ValueKey('buy-gst-billing-address')),
        '12 Market Road, Jodhpur 342003',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('buy-gst-save')));
      await tester.tap(find.byKey(const ValueKey('buy-gst-save')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Personal'), findsNothing);
      expect(find.textContaining('Business purchase'), findsNothing);
      await expectLater(
        find.byKey(const ValueKey('buy-v2-screen')),
        matchesGoldenFile(
          'candidate_captures/'
          'buy-b01-t01b-optional-gst-invoice-390x844.png',
        ),
      );
      expect(tester.takeException(), isNull);
    },
    // Founder-review evidence only; run explicitly with --run-skipped.
    skip: true,
  );
}

Future<void> _capture(WidgetTester tester, String state) async {
  await tester.pump(const Duration(milliseconds: 120));
  await expectLater(
    find.byKey(const ValueKey('buy-v2-screen')),
    matchesGoldenFile(
      'candidate_captures/buy-v2-r33-search-media-chat-local-$state-360x800.png',
    ),
  );
}

Future<void> _captureHeaderRemovalReview(
  WidgetTester tester,
  String destination,
  Key reviewRootKey,
) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  await expectLater(
    find.byKey(reviewRootKey),
    matchesGoldenFile(
      'candidate_captures/'
      'buy-v2-oppo-baseline-header-removed-$destination-360x800.png',
    ),
  );
}

Future<void> _capturePostOrderReview(
  WidgetTester tester,
  String state,
  Key reviewRootKey,
) async {
  await tester.pump(const Duration(milliseconds: 120));
  await tester.pumpAndSettle();
  await expectLater(
    find.byKey(reviewRootKey),
    matchesGoldenFile(
      'candidate_captures/buy-v2-post-order-$state-360x800.png',
    ),
  );
}

Future<void> _captureOffersReview(
  WidgetTester tester,
  String state,
  Key reviewRootKey,
) async {
  await tester.pump(const Duration(milliseconds: 120));
  await tester.pumpAndSettle();
  await expectLater(
    find.byKey(reviewRootKey),
    matchesGoldenFile(
      'candidate_captures/buy-v2-offers-progressive-$state-390x844.png',
    ),
  );
}

Future<void> _captureShopChatReview(
  WidgetTester tester,
  String state,
  Key reviewRootKey,
) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
  await expectLater(
    find.byKey(reviewRootKey),
    matchesGoldenFile(
      'candidate_captures/buy-v2-shop-chat-enhanced-$state-390x844.png',
    ),
  );
}

Future<void> _captureOverlay(WidgetTester tester, String state) async {
  await tester.pump(const Duration(milliseconds: 120));
  await expectLater(
    find.byType(Overlay).first,
    matchesGoldenFile(
      'candidate_captures/buy-v2-r33-search-media-chat-local-$state-360x800.png',
    ),
  );
}

Future<void> _captureResponsive(
  WidgetTester tester,
  String state,
  String viewport,
) async {
  await tester.pump(const Duration(milliseconds: 80));
  await expectLater(
    find.byKey(const ValueKey('buy-v2-screen')),
    matchesGoldenFile(
      'candidate_captures/buy-v2-r33-search-media-chat-local-$state-$viewport.png',
    ),
  );
}

Future<void> _captureResponsiveOverlay(
  WidgetTester tester,
  String state,
  String viewport,
) async {
  await tester.pump(const Duration(milliseconds: 80));
  await expectLater(
    find.byType(Overlay).first,
    matchesGoldenFile(
      'candidate_captures/buy-v2-r33-search-media-chat-local-$state-$viewport.png',
    ),
  );
}

Future<void> _captureR34SearchSuggestions(
  WidgetTester tester,
  String destination,
  String viewport,
) async {
  await tester.pump(const Duration(milliseconds: 80));
  await expectLater(
    find.byKey(const ValueKey('buy-v2-screen')),
    matchesGoldenFile(
      'candidate_captures/'
      'buy-v2-r35-1-dense-flat-suggestions-$destination-$viewport.png',
    ),
  );
}

class _CaptureShopChatSource implements BuyV2ShopChatProvisioningSource {
  const _CaptureShopChatSource();

  @override
  List<BuyV2ShopChatThread> threads(BuyV2Session? session) {
    final defaults = const BuyV2SessionShopChatProvisioningSource()
        .threads(session)
        .where((thread) => thread.id != 'retail-partner');
    return [
      const BuyV2ShopChatThread(
        id: 'retail-live',
        filter: BuyV2ShopChatFilter.sellers,
        participantKind: BuyV2ShopChatParticipantKind.retailer,
        title: 'Mahadev Fresh Mart',
        subtitle: 'Retail partner · Groceries and delivery',
        detail: 'Your basket is ready to review',
        icon: Icons.storefront_outlined,
        accent: BuyV2Colors.orange,
        commerceTarget: BuyV2ShopChatCommerceTarget.shop,
        contextTitle: 'Fresh grocery basket',
        contextDetail: '5 items · Delivery to your saved address',
        previewTimeLabel: '10:42',
        unreadCount: 1,
        quickReplies: ['Is everything in stock?', 'When can it arrive?'],
        messages: [
          BuyV2ShopChatMessage(
            id: 'received-text',
            kind: BuyV2ShopChatMessageKind.text,
            fromCurrentUser: false,
            sentAtLabel: '10:36',
            body: 'Your fresh grocery basket is ready to review.',
          ),
          BuyV2ShopChatMessage(
            id: 'sent-text',
            kind: BuyV2ShopChatMessageKind.text,
            fromCurrentUser: true,
            sentAtLabel: '10:38',
            body: 'Can it arrive tomorrow morning?',
            deliveryState: BuyV2ShopChatDeliveryState.read,
          ),
          BuyV2ShopChatMessage(
            id: 'received-photo',
            kind: BuyV2ShopChatMessageKind.image,
            fromCurrentUser: false,
            sentAtLabel: '10:40',
            attachmentName: 'Basket photo',
            attachmentDetail: 'JPG · 1.8 MB',
            body: 'These are the available packs.',
          ),
          BuyV2ShopChatMessage(
            id: 'sent-document',
            kind: BuyV2ShopChatMessageKind.document,
            fromCurrentUser: true,
            sentAtLabel: '10:41',
            attachmentName: 'Monthly staples.pdf',
            attachmentDetail: 'PDF · 240 KB',
            deliveryState: BuyV2ShopChatDeliveryState.delivered,
          ),
          BuyV2ShopChatMessage(
            id: 'received-voice',
            kind: BuyV2ShopChatMessageKind.voice,
            fromCurrentUser: false,
            sentAtLabel: '10:42',
            attachmentName: 'Voice message',
            attachmentDetail: '0:18',
          ),
        ],
      ),
      ...defaults,
    ];
  }
}
