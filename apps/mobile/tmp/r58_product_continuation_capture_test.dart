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
    required double textScale,
    required String heading,
    required String fileName,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = BuyV2Session(core: BuySession());
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(textScale),
              disableAnimations: true,
            ),
            child: child!,
          );
        },
        home: BuyV2Screen(session: session),
      ),
    );
    await tester.pumpAndSettle();
    session.openDestination(destination);
    session.openProduct(session.visibleProducts.first.id);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(heading),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -160));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('buy-v2-screen')),
      matchesGoldenFile(
        '../../../artifacts/quality/'
        'buy-product-detail-continuous-discovery-r58-1-20260803-124/'
        'captures/$fileName',
      ),
    );
  }

  testWidgets('capture Shop continuation at iOS portrait size', (tester) async {
    await capture(
      tester,
      size: const Size(390, 844),
      destination: BuyV2Destination.shop,
      textScale: 1,
      heading: 'You may also like',
      fileName: 'shop-continuation-390x844.png',
    );
  });

  testWidgets('capture Medicine continuation at Android portrait size', (
    tester,
  ) async {
    await capture(
      tester,
      size: const Size(360, 800),
      destination: BuyV2Destination.medicine,
      textScale: 1,
      heading: 'More Medicine essentials',
      fileName: 'medicine-continuation-360x800.png',
    );
  });

  testWidgets('capture large-text Shop continuation at 320px', (tester) async {
    await capture(
      tester,
      size: const Size(320, 700),
      destination: BuyV2Destination.shop,
      textScale: 1.4,
      heading: 'You may also like',
      fileName: 'shop-continuation-320x700-140.png',
    );
  });
}
