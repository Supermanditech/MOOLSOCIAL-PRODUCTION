import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/work/widgets/store_product_thumbnail.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';

void main() {
  setUpAll(() async {
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    await font.load();
  });
  testWidgets('Store preserves actual Buy illustration mapping and disclosure', (
    tester,
  ) async {
    final buy = BuyV2Catalogue.products.firstWhere(
      (item) => item.canonicalId == 'oil',
    );
    // Test the same public SKU identity, not a bottle substituted for a branded pouch.
    final product = workspaceMasterCatalogue.first.copyWith(
      canonicalId: buy.canonicalId,
      categoryId: buy.categoryId,
      title: buy.title,
      brand: buy.brand,
      pack: buy.pack,
      variant: buy.variant,
    );
    for (final extent in [95.0, 32.0]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: Scaffold(
            body: Center(
              child: StoreProductThumbnail(product: product, extent: extent),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rendered = tester.widget<BuyV2ProductPackshot>(
        find.byType(BuyV2ProductPackshot),
      );
      final reference = BuyV2ProductPackshot.resolveMedia(buy)!;
      final actual = BuyV2ProductPackshot.resolveMedia(rendered.product)!;
      expect(actual.assetPath, reference.assetPath);
      expect(actual.sourceRect, reference.sourceRect);
      if (extent >= 70) {
        expect(find.text('Illustration'), findsOneWidget);
      } else {
        expect(find.byType(BuyV2ProductPhotoUnavailable), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }
  });

  test('Store square grid stays smaller than Buy at every screen width', () {
    expect(StoreProductThumbnail.gridExtent(109.333), 64);
    expect(StoreProductThumbnail.gridExtent(60), 56);
    expect(StoreProductThumbnail.gridExtent(300), 64);
  });

  for (final extent in [
    32.0,
    40.0,
    42.0,
    44.0,
    48.0,
    56.0,
    64.0,
    95.333,
    130.0,
  ]) {
    testWidgets('Store thumbnail $extent preserves Buy media and square fit', (
      tester,
    ) async {
      final product = workspaceMasterCatalogue.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StoreProductThumbnail(
                key: const Key('frame'),
                product: product,
                extent: extent,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const Key('frame'))),
        Size.square(extent),
      );
      final renderer = tester.widget<BuyV2ProductPackshot>(
        find.byType(BuyV2ProductPackshot),
      );
      final expected = product.toCataloguePreviewProduct();
      expect(renderer.product.id, expected.id);
      expect(renderer.product.canonicalId, expected.canonicalId);
      expect(renderer.product.pack, expected.pack);
      expect(renderer.product.variant, expected.variant);
      expect(renderer.borderRadius, extent >= 70 ? 8 : 4);
      expect(
        BuyV2ProductPackshot.resolveMedia(renderer.product)?.assetPath,
        BuyV2ProductPackshot.resolveMedia(expected)?.assetPath,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
