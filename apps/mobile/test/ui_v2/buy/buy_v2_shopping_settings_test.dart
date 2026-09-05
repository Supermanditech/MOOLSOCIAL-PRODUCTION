import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final scale in [1.0, 2.0]) {
    testWidgets('R66 current delivery filter is truthful at $scale', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.view.viewPadding = const FakeViewPadding(bottom: 32);
      tester.view.padding = const FakeViewPadding(bottom: 32);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(core.dispose);
      addTearDown(session.dispose);
      session.addProduct('s-milk');
      final quantity = session.quantityFor('s-milk');

      Future<void> openSettings(BuyV2Session current) async {
        await tester.pumpWidget(
          MaterialApp(
            key: ObjectKey(current),
            theme: MoolTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showBuyV2ShoppingSettings(context, current),
                  child: const Text('Open settings'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open settings'));
        await tester.pumpAndSettle();
      }

      Future<void> openFilter() async {
        final settings = find.byKey(const ValueKey('buy-shopping-settings'));
        final row = find.byKey(const ValueKey('buy-settings-delivery'));
        await tester.scrollUntilVisible(
          row,
          120,
          scrollable: find
              .descendant(of: settings, matching: find.byType(Scrollable))
              .first,
        );
        expect(
          find.descendant(of: row, matching: find.text('Delivery filter')),
          findsOneWidget,
        );
        expect(find.textContaining('Preferred delivery'), findsNothing);
        await tester.tap(row);
        await tester.pumpAndSettle();
        expect(find.text('For current browsing only.'), findsOneWidget);
        expect(find.text('No preference'), findsNothing);
        expect(tester.takeException(), isNull);
      }

      await openSettings(session);
      for (final option in [
        ('quick-local', BuyV2FulfilmentMode.quickLocal),
        ('standard-courier', BuyV2FulfilmentMode.standardCourier),
        ('bulk-freight', BuyV2FulfilmentMode.bulkFreight),
        ('any', null),
      ]) {
        await openFilter();
        final action = find.byKey(
          ValueKey('buy-settings-delivery-${option.$1}'),
        );
        await tester.scrollUntilVisible(
          action,
          100,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        final bounds = tester.getRect(action);
        expect(bounds.height, greaterThanOrEqualTo(44));
        expect(bounds.bottom, lessThanOrEqualTo(668));
        final text = find.descendant(
          of: action,
          matching: find.byType(RichText),
        );
        for (final paragraph in tester.renderObjectList<RenderParagraph>(
          text,
        )) {
          expect(paragraph.didExceedMaxLines, isFalse);
          final topLeft = paragraph.localToGlobal(Offset.zero);
          expect(topLeft.dy, greaterThanOrEqualTo(bounds.top));
          expect(
            topLeft.dy + paragraph.size.height,
            lessThanOrEqualTo(bounds.bottom),
          );
        }
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(session.selectedFulfilmentMode, option.$2);
        expect(session.quantityFor('s-milk'), quantity);
        expect(
          find.byKey(const ValueKey('buy-shopping-settings')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
      await openFilter();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.selectedFulfilmentMode, isNull);
      session.chooseFulfilmentMode(BuyV2FulfilmentMode.quickLocal);
      final freshCore = BuySession();
      final fresh = BuyV2Session(core: freshCore);
      addTearDown(freshCore.dispose);
      addTearDown(fresh.dispose);
      await openSettings(fresh);
      await openFilter();
      expect(fresh.selectedFulfilmentMode, isNull);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('buy-settings-delivery-any')),
          matching: find.text('All delivery types'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shopping settings reuse owners and fit at 320 large text', (
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
    expect(session.openProduct('s-milk'), isTrue);
    session.closeProduct();
    session.toggleSaved('s-milk');

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MoolTheme.light(),
        home: BuyV2Screen(session: session),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
    await tester.pumpAndSettle();
    final openSettings = find.byKey(
      const ValueKey('buy-shopping-settings-button'),
    );
    await tester.scrollUntilVisible(
      openSettings,
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(openSettings);
    await tester.pumpAndSettle();

    final settings = find.byKey(const ValueKey('buy-shopping-settings'));
    final settingsScroll = find
        .descendant(of: settings, matching: find.byType(Scrollable))
        .first;
    expect(settings, findsOneWidget);
    expect(find.text('Shopping settings'), findsOneWidget);
    for (final keyName in const [
      'buy-settings-addresses',
      'buy-settings-payment',
      'buy-settings-delivery',
      'buy-settings-order-alerts',
      'buy-settings-saved',
      'buy-settings-recently-viewed',
      'buy-settings-messages',
      'buy-settings-privacy',
      'buy-settings-security',
      'buy-settings-help',
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey(keyName)),
        160,
        scrollable: settingsScroll,
      );
      expect(find.byKey(ValueKey(keyName)), findsOneWidget);
    }

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('buy-settings-delivery')),
      -180,
      scrollable: settingsScroll,
    );
    await tester.tap(find.byKey(const ValueKey('buy-settings-delivery')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('buy-settings-delivery-quick-local')),
    );
    await tester.pumpAndSettle();
    expect(session.selectedFulfilmentMode, BuyV2FulfilmentMode.quickLocal);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('buy-settings-order-alerts')),
      160,
      scrollable: settingsScroll,
    );
    expect(session.trackingAlertsEnabled, isTrue);
    await tester.tap(find.byKey(const ValueKey('buy-settings-order-alerts')));
    await tester.pumpAndSettle();
    expect(session.trackingAlertsEnabled, isFalse);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('buy-settings-recently-viewed')),
      160,
      scrollable: settingsScroll,
    );
    await tester.tap(
      find.byKey(const ValueKey('buy-settings-recently-viewed')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-recently-viewed-info-sheet')),
      findsOneWidget,
    );
    expect(find.text('Clear recently viewed?'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('buy-recently-viewed-sheet-clear')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Clear recently viewed?'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('buy-settings-recently-viewed-confirm')),
    );
    await tester.pumpAndSettle();
    expect(session.recentlyViewedProductsFor(session.destination), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tools exposes Recently viewed without hiding it in settings', (
    tester,
  ) async {
    final core = BuySession();
    final session = BuyV2Session(core: core);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-milk'), isTrue);
    session.closeProduct();

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(session: session),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
    await tester.pumpAndSettle();

    final recentlyViewed = find.byKey(
      const ValueKey('buy-recently-viewed-button'),
    );
    await tester.scrollUntilVisible(
      recentlyViewed,
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(recentlyViewed);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('buy-recently-viewed-info-sheet')),
      findsOneWidget,
    );
    final add = find.byKey(const ValueKey('buy-recently-viewed-add-s-milk'));
    expect(add, findsOneWidget);
    expect(tester.getSize(add).height, greaterThanOrEqualTo(44));
    await tester.tap(add);
    await tester.pumpAndSettle();
    expect(session.quantityFor('s-milk'), 1);
    expect(find.text('Added'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-settings-recently-viewed')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Shopping settings reopens an exact recently viewed product and returns',
    (tester) async {
      final core = BuySession();
      final session = BuyV2Session(core: core);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct('s-milk'), isTrue);
      session.closeProduct();

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          home: BuyV2Screen(session: session),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('buy-filter-button')));
      await tester.pumpAndSettle();
      final openSettings = find.byKey(
        const ValueKey('buy-shopping-settings-button'),
      );
      await tester.scrollUntilVisible(
        openSettings,
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(openSettings);
      await tester.pumpAndSettle();

      final settings = find.byKey(const ValueKey('buy-shopping-settings'));
      final settingsScroll = find
          .descendant(of: settings, matching: find.byType(Scrollable))
          .first;
      final recentlyViewed = find.byKey(
        const ValueKey('buy-settings-recently-viewed'),
      );
      await tester.scrollUntilVisible(
        recentlyViewed,
        160,
        scrollable: settingsScroll,
      );
      await tester.tap(recentlyViewed);
      await tester.pumpAndSettle();

      expect(settings, findsNothing);
      expect(
        find.byKey(const ValueKey('buy-recently-viewed-info-sheet')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
          const ValueKey('buy-settings-recently-viewed-product-s-milk'),
        ),
      );
      await tester.pumpAndSettle();

      expect(session.view, BuyV2View.product);
      expect(session.selectedProductId, 's-milk');
      expect(
        find.byKey(const ValueKey('buy-recently-viewed-info-sheet')),
        findsNothing,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.catalogue);
      expect(session.destination, BuyV2Destination.shop);
      expect(tester.takeException(), isNull);
    },
  );
}
