import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart';

Widget reviewHost(
  BuyV2Session session, {
  bool reduced = false,
  double textScale = 1,
}) {
  return MaterialApp(
    theme: MoolTheme.light(),
    builder: (context, child) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: media.copyWith(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(textScale),
        ),
        child: RepaintBoundary(
          key: const ValueKey('buy-product-depth-review-boundary'),
          child: child!,
        ),
      );
    },
    home: BuyV2Screen(
      session: session,
      initialDestination: session.destination,
      initialView: session.view,
    ),
  );
}

Widget detailReviewHost(BuyV2Session session) {
  return MaterialApp(
    theme: MoolTheme.light(),
    home: MediaQuery(
      data: const MediaQueryData(size: Size(390, 844)),
      child: RepaintBoundary(
        key: const ValueKey('buy-product-depth-review-boundary'),
        child: Scaffold(body: BuyV2ProductView(session: session)),
      ),
    ),
  );
}

void main() {
  testWidgets('product hold and detail reveal review phases', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(reviewHost(session));
    await tester.pumpAndSettle();
    final imageContext = tester.element(
      find.byKey(const ValueKey('buy-product-depth-review-boundary')),
    );
    await tester.runAsync(() async {
      for (final asset in const {
        BuyV2ProductPackshot.productAtlasPath,
        BuyV2ProductPackshot.categoryAtlasAPath,
        BuyV2ProductPackshot.categoryAtlasBPath,
        BuyV2ProductPackshot.categoryAtlasCPath,
        BuyV2ProductPackshot.medicineAtlasPath,
      }) {
        await precacheImage(AssetImage(asset), imageContext);
      }
    });
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    final product = session.visibleProducts.first;
    final productAction = find.byKey(ValueKey('buy-product-${product.id}'));

    final gesture = await tester.startGesture(
      tester.getTopLeft(productAction) + const Offset(265, 85),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 55));
    await expectLater(
      find.byKey(const ValueKey('buy-product-depth-review-boundary')),
      matchesGoldenFile('goldens/buy-product-depth-held.png'),
    );
    await gesture.cancel();
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('buy-product-depth-review-boundary')),
      matchesGoldenFile('goldens/buy-product-depth-settled.png'),
    );

    session.openProduct(product.id);
    await tester.pumpWidget(detailReviewHost(session));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 45));
    await expectLater(
      find.byKey(const ValueKey('buy-product-depth-review-boundary')),
      matchesGoldenFile('goldens/buy-product-detail-reveal-mid.png'),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('buy-product-depth-review-boundary')),
      matchesGoldenFile('goldens/buy-product-detail-reveal-settled.png'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced product detail at 320 and 140 percent', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) => item.destination == BuyV2Destination.medicine,
    );
    session.openProduct(product.id);
    await tester.pumpWidget(reviewHost(session, reduced: true, textScale: 1.4));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey('buy-product-depth-review-boundary')),
      matchesGoldenFile('goldens/buy-product-detail-reduced-320-140.png'),
    );
    expect(tester.takeException(), isNull);
  });
}
