import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_saved_clear_sheet_motion.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
    EdgeInsets viewInsets = EdgeInsets.zero,
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
            viewInsets: viewInsets,
          ),
          child: child!,
        );
      },
      home: BuyV2Screen(
        session: session,
        initialDestination: session.destination,
        initialView: session.view,
      ),
    );
  }

  BuyV2Product productFor(BuyV2Destination destination) {
    return BuyV2Catalogue.products.firstWhere(
      (product) =>
          product.destination == destination && !product.requiresPrescription,
    );
  }

  Future<void> openSavedClearSheet(
    WidgetTester tester,
    BuyV2Session session, {
    bool disableAnimations = false,
    double textScale = 1,
    EdgeInsets viewInsets = EdgeInsets.zero,
    bool settleSheet = true,
  }) async {
    await tester.pumpWidget(
      app(
        session,
        disableAnimations: disableAnimations,
        textScale: textScale,
        viewInsets: viewInsets,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-saved-products-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-saved-clear')));
    await tester.pump();
    if (settleSheet) await tester.pumpAndSettle();
  }

  testWidgets('R56.1 policy owns bounded forward and reverse route motion', (
    tester,
  ) async {
    late AnimationStyle normal;
    late AnimationStyle reduced;
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            MediaQuery(
              data: const MediaQueryData(),
              child: Builder(
                builder: (context) {
                  normal = BuyV2SavedClearSheetMotion.resolve(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(
                builder: (context) {
                  reduced = BuyV2SavedClearSheetMotion.resolve(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );

    expect(normal.duration, BuyV2SavedClearSheetMotion.forwardDuration);
    expect(normal.reverseDuration, BuyV2SavedClearSheetMotion.reverseDuration);
    expect(normal.curve, Curves.easeOutBack);
    expect(normal.reverseCurve, Curves.easeInCubic);
    expect(
      normal.duration,
      lessThanOrEqualTo(const Duration(milliseconds: 420)),
    );
    expect(normal.reverseDuration, lessThan(normal.duration!));
    expect(reduced.duration, Duration.zero);
    expect(reduced.reverseDuration, Duration.zero);
    expect(reduced.curve, Curves.linear);
    expect(reduced.reverseCurve, Curves.linear);
  });

  testWidgets('R56.1 sheet travels finitely and Back keeps Saved unchanged', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = BuyV2Session(core: BuySession());
    addTearDown(session.dispose);
    final shop = productFor(BuyV2Destination.shop);
    session.toggleSaved(shop.id);

    await openSavedClearSheet(tester, session, settleSheet: false);
    final sheet = find.byKey(const ValueKey('buy-saved-clear-sheet'));
    expect(sheet, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 140));
    final midArrivalTop = tester.getTopLeft(sheet).dy;
    await tester.pump(const Duration(milliseconds: 140));
    await tester.pump();
    final settledTop = tester.getTopLeft(sheet).dy;
    expect(midArrivalTop, lessThan(settledTop));
    expect(settledTop - midArrivalTop, lessThan(16));
    expect(session.isSaved(shop.id), isTrue);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 219));
    expect(sheet, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    expect(session.isSaved(shop.id), isTrue);
  });

  testWidgets(
    'R56.1 reduced motion is immediate and safe dismissal never mutates',
    (tester) async {
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      final shop = productFor(BuyV2Destination.shop);
      session.toggleSaved(shop.id);

      await openSavedClearSheet(
        tester,
        session,
        disableAnimations: true,
        settleSheet: false,
      );
      final sheet = find.byKey(const ValueKey('buy-saved-clear-sheet'));
      expect(sheet, findsOneWidget);
      final immediateTop = tester.getTopLeft(sheet).dy;
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getTopLeft(sheet).dy, immediateTop);
      expect(session.isSaved(shop.id), isTrue);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(session.isSaved(shop.id), isTrue);
    },
  );

  testWidgets(
    'R56.1 compact large-text semantics stay usable without a keyboard owner',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      final shop = productFor(BuyV2Destination.shop);
      final medicine = productFor(BuyV2Destination.medicine);
      session.toggleSaved(shop.id);
      session.toggleSaved(medicine.id);
      session.addProduct(shop.id);

      await openSavedClearSheet(tester, session, textScale: 1.4);
      expect(find.bySemanticsLabel('Clear Saved in Shop'), findsOneWidget);
      expect(find.bySemanticsLabel('Keep saved'), findsWidgets);
      expect(find.bySemanticsLabel('Clear list'), findsOneWidget);
      semantics.dispose();
      expect(find.byType(TextField), findsNothing);
      expect(tester.testTextInput.isVisible, isFalse);
      expect(tester.takeException(), isNull);

      final clear = find.byKey(const ValueKey('buy-saved-confirm-clear'));
      await tester.ensureVisible(clear);
      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(session.isSaved(shop.id), isFalse);
      expect(session.isSaved(medicine.id), isTrue);
      expect(session.quantityFor(shop.id), shop.minimumOrder);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'R56.1 Saved-clear responsive evidence captures',
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
        final product = productFor(BuyV2Destination.shop);
        session.toggleSaved(product.id);
        await openSavedClearSheet(
          tester,
          session,
          disableAnimations: capture.$3,
          textScale: capture.$2,
        );
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'candidate_captures/'
            'buy-v2-r56-saved-clear-${capture.$4}-run2.png',
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
