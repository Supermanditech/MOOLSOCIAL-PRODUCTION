import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'product gallery and details use one authoritative content owner',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final core = BuySession();
      final adapter = _ContentAdapter();
      final session = BuyV2Session(core: core, productContentAdapter: adapter);
      addTearDown(session.dispose);
      addTearDown(core.dispose);
      expect(session.openProduct('s-milk'), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: MoolTheme.light(),
          home: BuyV2Screen(
            session: session,
            initialDestination: session.destination,
            initialView: session.view,
            productId: session.selectedProductId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('buy-product-gallery-count')),
        findsOneWidget,
      );
      expect(find.text('1 of 2'), findsOneWidget);
      final ready = find.byKey(
        const ValueKey('buy-product-content-ready-s-milk'),
      );
      await tester.scrollUntilVisible(
        ready,
        220,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('buy-product-s-milk')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Highlights'), findsOneWidget);
      expect(find.text('Cold-chain quality checked'), findsOneWidget);
      expect(find.text('Specifications'), findsOneWidget);
      expect(find.text('Shelf life'), findsOneWidget);
      expect(find.text('2 days'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(
        find.text('Fresh toned milk supplied in a sealed pouch.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unavailable product details retry without changing Cart', (
    tester,
  ) async {
    final core = BuySession();
    final adapter = _ContentAdapter()..available = false;
    final session = BuyV2Session(core: core, productContentAdapter: adapter);
    addTearDown(session.dispose);
    addTearDown(core.dispose);
    expect(session.openProduct('s-milk'), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: BuyV2Screen(
          session: session,
          initialDestination: session.destination,
          initialView: session.view,
          productId: session.selectedProductId,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final retry = find.byKey(
      const ValueKey('buy-product-content-retry-s-milk'),
    );
    await tester.scrollUntilVisible(
      retry,
      220,
      scrollable: find
          .descendant(
            of: find.byKey(const PageStorageKey('buy-product-s-milk')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Product details unavailable'), findsOneWidget);
    expect(
      find.text('Product information could not be loaded.'),
      findsOneWidget,
    );
    adapter.available = true;
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-product-content-ready-s-milk')),
      findsOneWidget,
    );
    expect(session.cartLines, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

final class _ContentAdapter implements BuyV2ProductContentAdapter {
  bool available = true;

  @override
  BuyV2ProductContentSnapshot snapshotFor(BuyV2Product product) {
    if (!available) {
      return BuyV2ProductContentSnapshot(
        productId: product.id,
        state: BuyV2ProductContentState.offline,
        sourceId: 'product-content-test',
        customerMessage: 'Product information could not be loaded.',
      );
    }
    return BuyV2ProductContentSnapshot(
      productId: product.id,
      state: BuyV2ProductContentState.ready,
      sourceId: 'product-content-test',
      media: [
        for (final id in const ['front', 'pack'])
          BuyV2ProductMediaAsset(
            id: '${product.id}-$id',
            label: id == 'front' ? 'Front of pack' : 'Pack details',
            semanticLabel:
                '${product.title}, ${id == 'front' ? 'front of pack' : 'pack details'}',
            kind: BuyV2ProductContentMediaKind.cataloguePackshot,
          ),
      ],
      highlights: const ['Cold-chain quality checked', 'Sealed pouch'],
      specifications: const [
        BuyV2ProductSpecification(label: 'Shelf life', value: '2 days'),
        BuyV2ProductSpecification(label: 'Processing', value: 'Pasteurized'),
      ],
      description: 'Fresh toned milk supplied in a sealed pouch.',
    );
  }
}
