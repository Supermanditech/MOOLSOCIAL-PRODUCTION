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
    required String categoryId,
    required String query,
    required double textScale,
    required String fileName,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = BuyV2Session(core: BuySession());
    session.openDestination(destination);
    session.chooseCategory(categoryId);
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
        home: BuyV2Screen(session: session, initialDestination: destination),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy-search-control')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('buy-search-field')),
      query,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('buy-search-all-${destination.name}')),
      findsOneWidget,
    );
    await expectLater(
      find.byKey(const ValueKey('buy-v2-screen')),
      matchesGoldenFile(
        '../../../artifacts/quality/'
        'buy-search-result-recovery-r58-2-20260803-125/'
        'captures/$fileName',
      ),
    );
  }

  testWidgets('capture Shop scoped recovery at iOS portrait size', (
    tester,
  ) async {
    await capture(
      tester,
      size: const Size(390, 844),
      destination: BuyV2Destination.shop,
      categoryId: 'school-office',
      query: 'tomato',
      textScale: 1,
      fileName: 'shop-search-recovery-390x844.png',
    );
  });

  testWidgets('capture Medicine scoped recovery at Android portrait size', (
    tester,
  ) async {
    await capture(
      tester,
      size: const Size(360, 800),
      destination: BuyV2Destination.medicine,
      categoryId: 'devices',
      query: 'paracetamol',
      textScale: 1,
      fileName: 'medicine-search-recovery-360x800.png',
    );
  });

  testWidgets('capture Shop recovery at 320px and 140 percent', (tester) async {
    await capture(
      tester,
      size: const Size(320, 700),
      destination: BuyV2Destination.shop,
      categoryId: 'school-office',
      query: 'tomato',
      textScale: 1.4,
      fileName: 'shop-search-recovery-320x700-140.png',
    );
  });
}
