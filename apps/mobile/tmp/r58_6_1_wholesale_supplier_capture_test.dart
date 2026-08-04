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
    required double textScale,
    required bool reducedMotion,
    required String fileName,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = BuyV2Session(core: BuySession());
    session.openDestination(BuyV2Destination.wholesale);
    session.openProduct('w-oil');
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
          initialDestination: BuyV2Destination.wholesale,
          initialView: BuyV2View.product,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final action = find.byKey(
      const ValueKey('buy-wholesale-supplier-action-w-oil'),
    );
    final productScroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(action, 180, scrollable: productScroll);
    await tester.pumpAndSettle();
    final actionCenter = tester.getCenter(action).dy;
    if (actionCenter > size.height - 100) {
      await tester.drag(
        productScroll,
        Offset(0, -(actionCenter - (size.height - 100)).clamp(0.0, 120.0)),
      );
      await tester.pumpAndSettle();
    }
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-wholesale-supplier-sheet-w-oil')),
      findsOneWidget,
    );
    expect(find.text('More from Surya Oils India'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(Overlay).first,
      matchesGoldenFile(
        '../../../artifacts/quality/'
        'buy-wholesale-continuation-r58-6-audit-20260803-129/'
        'captures/$fileName',
      ),
    );
  }

  testWidgets('capture supplier continuation at iOS portrait size', (
    tester,
  ) async {
    await capture(
      tester,
      size: const Size(390, 844),
      textScale: 1,
      reducedMotion: false,
      fileName: 'supplier-continuation-390x844.png',
    );
  });

  testWidgets('capture supplier continuation at Android portrait size', (
    tester,
  ) async {
    await capture(
      tester,
      size: const Size(360, 800),
      textScale: 1,
      reducedMotion: false,
      fileName: 'supplier-continuation-360x800.png',
    );
  });

  testWidgets('capture supplier continuation at 320px 140 percent reduced', (
    tester,
  ) async {
    await capture(
      tester,
      size: const Size(320, 700),
      textScale: 1.4,
      reducedMotion: true,
      fileName: 'supplier-continuation-320x700-140-reduced.png',
    );
  });
}
