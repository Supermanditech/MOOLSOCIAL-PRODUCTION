import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_catalogue.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_info_sheet_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
  }) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              FilledButton(
                key: const ValueKey('open-household-info-sheet'),
                onPressed: () => showBuyV2HouseholdBasket(context, session),
                child: const Text('Household'),
              ),
              FilledButton(
                key: const ValueKey('open-saved-info-sheet'),
                onPressed: () => showBuyV2SavedProducts(context, session),
                child: const Text('Saved'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BuyV2Product productFor(BuyV2Destination destination) {
    return BuyV2Catalogue.products.firstWhere(
      (product) =>
          product.destination == destination && !product.requiresPrescription,
    );
  }

  Future<void> openHousehold(
    WidgetTester tester,
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      app(session, disableAnimations: disableAnimations, textScale: textScale),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-household-info-sheet')));
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
  }

  Future<void> openSaved(
    WidgetTester tester,
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      app(session, disableAnimations: disableAnimations, textScale: textScale),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-saved-info-sheet')));
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
  }

  testWidgets('R56.4 policy is bounded and reduced motion resolves static', (
    tester,
  ) async {
    late AnimationStyle normal;
    late AnimationStyle reduced;
    late Duration normalContent;
    late Duration reducedContent;
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            MediaQuery(
              data: const MediaQueryData(),
              child: Builder(
                builder: (context) {
                  normal = BuyV2InfoSheetMotion.resolve(context);
                  normalContent = BuyV2InfoSheetMotion.resolveContentDuration(
                    context,
                  );
                  return const SizedBox.shrink();
                },
              ),
            ),
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  reduced = BuyV2InfoSheetMotion.resolve(context);
                  reducedContent = BuyV2InfoSheetMotion.resolveContentDuration(
                    context,
                  );
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );

    expect(normal.duration, BuyV2InfoSheetMotion.forwardDuration);
    expect(normal.reverseDuration, BuyV2InfoSheetMotion.reverseDuration);
    expect(normal.curve, Curves.easeOutBack);
    expect(normal.reverseCurve, Curves.easeInCubic);
    expect(normalContent, BuyV2InfoSheetMotion.contentDuration);
    expect(reduced.duration, Duration.zero);
    expect(reduced.reverseDuration, Duration.zero);
    expect(reduced.curve, Curves.linear);
    expect(reduced.reverseCurve, Curves.linear);
    expect(reducedContent, Duration.zero);
  });

  testWidgets('household arrival/reverse is finite and Back never mutates', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final featured = BuyV2Catalogue.products
        .where((product) => product.destination == BuyV2Destination.shop)
        .take(4)
        .toList(growable: false);

    await openHousehold(tester, session, settle: false);
    final sheet = find.byKey(const ValueKey('buy-household-basket-info-sheet'));
    expect(sheet, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 140));
    final midArrivalTop = tester.getTopLeft(sheet).dy;
    await tester.pump(const Duration(milliseconds: 140));
    await tester.pump();
    final settledTop = tester.getTopLeft(sheet).dy;
    expect((settledTop - midArrivalTop).abs(), lessThan(24));

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 219));
    expect(sheet, findsOneWidget);
    for (final product in featured) {
      expect(session.quantityFor(product.id), 0);
    }
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    for (final product in featured) {
      expect(session.quantityFor(product.id), 0);
    }
  });

  testWidgets('household actions apply once from the explicit modal result', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final featured = BuyV2Catalogue.products
        .where((product) => product.destination == BuyV2Destination.shop)
        .take(4)
        .toList(growable: false);

    await openHousehold(tester, session);
    await tester.tap(find.byKey(const ValueKey('buy-household-add-to-cart')));
    await tester.pump();
    for (final product in featured) {
      expect(session.quantityFor(product.id), product.minimumOrder);
    }
    await tester.pumpAndSettle();
    for (final product in featured) {
      expect(session.quantityFor(product.id), product.minimumOrder);
    }

    session.chooseCategory('fruits-vegetables');
    await openHousehold(tester, session);
    await tester.tap(find.byKey(const ValueKey('buy-household-see-products')));
    await tester.pump();
    expect(session.selectedCategoryId, 'all');
    expect(session.notice, 'Basket products are shown below');
    await tester.pumpAndSettle();
    expect(session.selectedCategoryId, 'all');
    expect(session.notice, 'Basket products are shown below');
  });

  testWidgets(
    'Saved sheet holds invocation destination and animates real owner',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      final shop = productFor(BuyV2Destination.shop);
      final medicine = productFor(BuyV2Destination.medicine);
      session.toggleSaved(shop.id);
      session.toggleSaved(medicine.id);

      await openSaved(tester, session);
      expect(find.bySemanticsLabel('Saved products in Shop'), findsOneWidget);
      expect(find.text(shop.title), findsOneWidget);
      expect(find.text(medicine.title), findsNothing);
      expect(find.bySemanticsLabel('Open ${shop.title}'), findsOneWidget);
      expect(find.byTooltip('Remove ${shop.title} from Saved'), findsOneWidget);

      session.openDestination(BuyV2Destination.medicine);
      await tester.pump();
      expect(find.text(shop.title), findsOneWidget);
      expect(find.text(medicine.title), findsNothing);

      await tester.tap(find.byKey(ValueKey('buy-unsave-${shop.id}')));
      await tester.pump();
      expect(session.isSaved(shop.id), isFalse);
      expect(session.isSaved(medicine.id), isTrue);
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      await tester.pumpAndSettle();
      expect(find.text('No Saved products yet'), findsOneWidget);
      expect(
        find.text('Save products from the Shop grid for instant access.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Saved product opens once from the explicit modal result', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final shop = productFor(BuyV2Destination.shop);
    session.toggleSaved(shop.id);

    await openSaved(tester, session);
    await tester.tap(find.byKey(ValueKey('buy-saved-${shop.id}')));
    await tester.pump();
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, shop.id);
    await tester.pumpAndSettle();
    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, shop.id);
  });

  testWidgets('compact 140% sheets keep actions, semantics and focus safe', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);

    await openHousehold(tester, session, textScale: 1.4);
    final householdSheet = find.byKey(
      const ValueKey('buy-household-basket-info-sheet'),
    );
    expect(householdSheet, findsOneWidget);
    expect(tester.getSemantics(householdSheet).label, 'Monthly home basket');
    final add = find.byKey(const ValueKey('buy-household-add-to-cart'));
    await tester.ensureVisible(add);
    expect(add, findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-saved-info-sheet')));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Saved products in Shop'), findsOneWidget);
    expect(find.text('No Saved products yet'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(tester.testTextInput.isVisible, isFalse);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('reduced motion is immediate for both R56.4 route owners', (
    tester,
  ) async {
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);

    await openHousehold(
      tester,
      session,
      disableAnimations: true,
      settle: false,
    );
    final household = find.byKey(
      const ValueKey('buy-household-basket-info-sheet'),
    );
    expect(household, findsOneWidget);
    final householdTop = tester.getTopLeft(household).dy;
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getTopLeft(household).dy, householdTop);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(household, findsNothing);

    await tester.tap(find.byKey(const ValueKey('open-saved-info-sheet')));
    await tester.pump();
    final saved = find.byKey(const ValueKey('buy-saved-products-info-sheet'));
    expect(saved, findsOneWidget);
    final savedTop = tester.getTopLeft(saved).dy;
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getTopLeft(saved).dy, savedTop);
  });

  testWidgets(
    'R56.4 household and Saved responsive evidence captures',
    (tester) async {
      const cases = [
        (Size(320, 700), 1.4, false, 'compact-320x700-text140'),
        (Size(360, 800), 1.0, false, 'android-360x800'),
        (Size(390, 844), 1.0, false, 'ios-390x844'),
        (Size(390, 844), 1.0, true, 'reduced-ios-390x844'),
      ];
      for (final capture in cases) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = capture.$1;
        final session = BuyV2Session(core: BuySession());
        final shop = productFor(BuyV2Destination.shop);
        session.toggleSaved(shop.id);

        await openHousehold(
          tester,
          session,
          disableAnimations: capture.$3,
          textScale: capture.$2,
        );
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'candidate_captures/'
            'buy-v2-r56-4-household-${capture.$4}-run2.png',
          ),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        await openSaved(
          tester,
          session,
          disableAnimations: capture.$3,
          textScale: capture.$2,
        );
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'candidate_captures/'
            'buy-v2-r56-4-saved-${capture.$4}-run2.png',
          ),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        session.dispose();
      }
      tester.view.reset();
    },
    // Run explicitly with --run-skipped --update-goldens for additive evidence.
    skip: true,
  );
}
