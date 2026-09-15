import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

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
    'Wholesale keeps automatic fulfilment and exact supplier continuity',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = wholesaleProductSession();

      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      final supplier = find.byKey(
        const ValueKey('buy-wholesale-store-action-w-oil'),
      );
      await revealSupplierAction(tester, supplier);
      expect(supplier, findsOneWidget);
      expect(find.textContaining(session.product('w-oil').seller), findsWidgets);
      expect(find.text('Surya Oils India'), findsOneWidget);
      expect(find.textContaining('Surya Oils India'), findsWidgets);
      await tester.tap(supplier);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('buy-wholesale-supplier-sheet-w-oil')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('buy-horizontal-product-grid')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('buy-product-w-oil')), findsOneWidget);
      final continuation = session
          .supplierContinuationsFor(session.product('w-oil'))
          .first;
      expect(
        find.byKey(ValueKey('buy-product-${continuation.id}')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('buy-wholesale-supplier-sheet-close')),
      );
      await tester.pumpAndSettle();
      expect(session.view, BuyV2View.product);
      expect(session.selectedProductId, 'w-oil');
    },
  );

  testWidgets('canonical recommendations preserve Wholesale product state', (
    tester,
  ) async {
    final session = wholesaleProductSession();
    await tester.pumpWidget(app(session));
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

  testWidgets('unverified business sees one Workspace recovery and no Add', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = wholesaleProductSession()..businessVerified = false;

    await tester.pumpWidget(app(session));
    await tester.pumpAndSettle();
    final verification = find.byKey(
      const ValueKey('buy-wholesale-verification-unavailable'),
    );
    await revealSupplierAction(tester, verification);
    expect(verification, findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-wholesale-open-workspace')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-wholesale-verify-business-w-oil')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('buy-product-primary-w-oil')),
      findsNothing,
    );
  });

  testWidgets('automatic fulfilment is stable at 320px 140 percent', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = wholesaleProductSession();

    await tester.pumpWidget(app(session, textScale: 1.4, reducedMotion: true));
    await tester.pumpAndSettle();
    final supplier = find.byKey(
      const ValueKey('buy-wholesale-store-action-w-oil'),
    );
    await revealSupplierAction(tester, supplier);
    expect(supplier, findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
