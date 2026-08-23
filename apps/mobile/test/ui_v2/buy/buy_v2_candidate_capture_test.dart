import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_scanner.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

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
