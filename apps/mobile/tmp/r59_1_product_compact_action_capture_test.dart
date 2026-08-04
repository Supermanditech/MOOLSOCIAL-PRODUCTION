import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> capture(
    WidgetTester tester, {
    required Size size,
    required BuyV2Destination destination,
    required bool quantityState,
    required bool prescriptionState,
    required double textScale,
    required bool reducedMotion,
    required String fileName,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = BuyV2Session(core: BuySession());
    final product = BuyV2Catalogue.products.firstWhere(
      (item) =>
          item.destination == destination &&
          (!prescriptionState || item.requiresPrescription),
    );
    session.openDestination(destination);
    session.openProduct(product.id);
    if (quantityState) {
      session.addProduct(product.id);
    }

    await tester.pumpWidget(
      MaterialApp(
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
          initialDestination: destination,
          initialView: BuyV2View.product,
          productId: product.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final panel = find.byKey(
      ValueKey('buy-product-inline-action-${product.id}'),
    );
    final scrollable = find
        .descendant(
          of: find.byKey(PageStorageKey('buy-product-${product.id}')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(panel, 220, scrollable: scrollable);
    await tester.pumpAndSettle();
    final action = quantityState
        ? find.byKey(ValueKey('buy-product-quantity-${product.id}'))
        : find.byKey(ValueKey('buy-product-add-shell-${product.id}'));
    final slot = find.byKey(ValueKey('buy-product-action-slot-${product.id}'));
    expect(find.byKey(const ValueKey('buy-product-action-bar')), findsNothing);
    expect(panel, findsOneWidget);
    expect(slot, findsOneWidget);
    expect(action, findsOneWidget);
    expect(find.descendant(of: panel, matching: action), findsOneWidget);
    expect(find.text(product.title), findsOneWidget);
    if (!quantityState) {
      final primary = find.byKey(ValueKey('buy-product-primary-${product.id}'));
      expect(
        find.descendant(of: primary, matching: find.text(product.title)),
        findsNothing,
      );
    }
    expect(tester.getSize(action).height, 44);
    expect(tester.getSize(slot), const Size(148, 44));
    expect(tester.getTopRight(action), tester.getTopRight(slot));
    expect(
      tester.getTopRight(action).dx,
      closeTo(tester.getTopRight(panel).dx - 10, 0.01),
    );
    expect(tester.takeException(), isNull);

    await expectLater(
      find.byType(Overlay).first,
      matchesGoldenFile(
        '../../../artifacts/quality/'
        'buy-product-detail-compact-action-r59-1-fix6-20260803-136/'
        'captures/$fileName',
      ),
    );
  }

  testWidgets('Shop compact Add at iOS portrait size', (tester) async {
    await capture(
      tester,
      size: const Size(390, 844),
      destination: BuyV2Destination.shop,
      quantityState: false,
      prescriptionState: false,
      textScale: 1,
      reducedMotion: false,
      fileName: 'shop-compact-add-390x844.png',
    );
  });

  testWidgets('Wholesale compact quantity at Android portrait size', (
    tester,
  ) async {
    await capture(
      tester,
      size: const Size(360, 800),
      destination: BuyV2Destination.wholesale,
      quantityState: true,
      prescriptionState: false,
      textScale: 1,
      reducedMotion: false,
      fileName: 'wholesale-compact-quantity-360x800.png',
    );
  });

  testWidgets('Medicine compact prescription at 320 140 percent reduced', (
    tester,
  ) async {
    await capture(
      tester,
      size: const Size(320, 700),
      destination: BuyV2Destination.medicine,
      quantityState: false,
      prescriptionState: true,
      textScale: 1.4,
      reducedMotion: true,
      fileName: 'medicine-compact-prescription-320x700-140-reduced.png',
    );
  });
}
