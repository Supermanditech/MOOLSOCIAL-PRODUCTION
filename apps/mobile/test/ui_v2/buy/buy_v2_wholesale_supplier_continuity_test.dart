import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_supplier_sheet_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget app(
    BuyV2Session session, {
    double textScale = 1,
    bool reducedMotion = false,
  }) {
    return MaterialApp(
      theme: MoolTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reducedMotion,
          ),
          child: child!,
        );
      },
      home: BuyV2Screen(
        session: session,
        initialDestination: BuyV2Destination.wholesale,
        initialView: session.view,
      ),
    );
  }

  BuyV2Session wholesaleProductSession([String productId = 'w-oil']) {
    final session = BuyV2Session(core: BuySession());
    session.openDestination(BuyV2Destination.wholesale);
    session.openProduct(productId);
    return session;
  }

  Future<void> revealSupplierAction(WidgetTester tester, Finder action) async {
    final productScroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(action, 180, scrollable: productScroll);
    await tester.pumpAndSettle();
    final viewportHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final actionCenter = tester.getCenter(action).dy;
    if (actionCenter < 100) {
      await tester.drag(
        productScroll,
        Offset(0, (100 - actionCenter).clamp(0.0, 120.0)),
      );
    } else if (actionCenter > viewportHeight - 100) {
      await tester.drag(
        productScroll,
        Offset(0, -(actionCenter - (viewportHeight - 100)).clamp(0.0, 120.0)),
      );
    }
    await tester.pumpAndSettle();
  }

  test('supplier selector is exact, deterministic and fail closed', () {
    final session = wholesaleProductSession();
    final sunflower = session.product('w-oil');

    expect(session.supplierContinuationsFor(sunflower).map((item) => item.id), [
      'w-mustard-oil',
      'w-groundnut-oil',
      'w-ghee',
    ]);
    expect(
      session
          .supplierContinuationsFor(sunflower)
          .every(
            (item) =>
                item.destination == BuyV2Destination.wholesale &&
                item.seller == sunflower.seller &&
                item.id != sunflower.id,
          ),
      isTrue,
    );
    expect(session.supplierContinuationsFor(session.product('s-oil')), isEmpty);
    expect(
      session.supplierContinuationsFor(session.product('w-atta')),
      isEmpty,
    );
    expect(session.supplierContinuationsFor(sunflower, limit: 0), isEmpty);
  });

  testWidgets(
    'supplier action exposes exact packs and selects only after reverse',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final semantics = tester.ensureSemantics();
      final session = wholesaleProductSession();

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      final action = find.byKey(
        const ValueKey('buy-wholesale-supplier-action-w-oil'),
      );
      await revealSupplierAction(tester, action);
      expect(action, findsOneWidget);
      final semanticAction = find.bySemanticsLabel(
        'View 3 more products from Surya Oils India in the current '
        'Wholesale catalogue',
      );
      expect(semanticAction, findsOneWidget);
      expect(
        tester
            .getSemantics(semanticAction)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );

      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text('More from Surya Oils India'), findsOneWidget);
      expect(find.textContaining('listed pack, MOQ'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('buy-wholesale-supplier-product-w-mustard-oil'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('buy-wholesale-supplier-product-w-groundnut-oil'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-wholesale-supplier-product-w-ghee')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-wholesale-supplier-product-w-oil')),
        findsNothing,
      );
      expect(find.text('Stone-ground wheat atta'), findsNothing);

      final mustard = find.byKey(
        const ValueKey('buy-wholesale-supplier-product-w-mustard-oil'),
      );
      await tester.tap(mustard);
      await tester.pump();
      expect(session.selectedProductId, 'w-oil');
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.product);
      expect(session.selectedProductId, 'w-mustard-oil');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.catalogue);
      expect(session.destination, BuyV2Destination.wholesale);
      semantics.dispose();
    },
  );

  testWidgets('supplier dismissal does not change product or catalogue state', (
    tester,
  ) async {
    final session = wholesaleProductSession();
    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();

    final action = find.byKey(
      const ValueKey('buy-wholesale-supplier-action-w-oil'),
    );
    await revealSupplierAction(tester, action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(session.view, BuyV2View.product);
    expect(session.selectedProductId, 'w-oil');
    expect(session.destination, BuyV2Destination.wholesale);
    expect(session.query, isEmpty);
    expect(session.selectedFilter, isNull);

    await tester.scrollUntilVisible(
      find.text('More for business restocking'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey('buy-product-continuations-w-oil')),
      findsOneWidget,
    );
  });

  testWidgets('supplier sheet is static and stable at 320px 140 percent', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = wholesaleProductSession();

    await tester.pumpWidget(app(session, textScale: 1.4, reducedMotion: true));
    await tester.pumpAndSettle();
    final action = find.byKey(
      const ValueKey('buy-wholesale-supplier-action-w-oil'),
    );
    await revealSupplierAction(tester, action);
    final listener = tester.widget<Listener>(
      find.descendant(of: action, matching: find.byType(Listener)).first,
    );
    expect(listener.onPointerDown, isNull);

    final motion = BuyV2SupplierSheetMotion.resolve(tester.element(action));
    expect(motion.duration, Duration.zero);
    expect(motion.reverseDuration, Duration.zero);
    await tester.tap(action);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('buy-wholesale-supplier-sheet-w-oil')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('buy-wholesale-supplier-product-w-ghee')),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
