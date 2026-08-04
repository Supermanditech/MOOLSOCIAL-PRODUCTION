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
    required String prescriptionId,
    required double textScale,
    required String fileName,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = BuyV2Session(core: BuySession());
    session.openDestination(BuyV2Destination.medicine);
    expect(session.approveSavedPrescription(prescriptionId), isTrue);
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
        home: BuyV2Screen(
          session: session,
          initialDestination: BuyV2Destination.medicine,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('buy-prescription-match-lane')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(BuyV2Screen),
      matchesGoldenFile(
        '../../../artifacts/quality/'
        'buy-medicine-continuation-r58-5-audit-20260803-128/'
        'captures/$fileName',
      ),
    );
  }

  testWidgets('capture Meera matches at iOS portrait size', (tester) async {
    await capture(
      tester,
      size: const Size(390, 844),
      prescriptionId: 'meera',
      textScale: 1,
      fileName: 'meera-prescription-matches-390x844.png',
    );
  });

  testWidgets('capture Arvind matches at Android portrait size', (
    tester,
  ) async {
    await capture(
      tester,
      size: const Size(360, 800),
      prescriptionId: 'arvind',
      textScale: 1,
      fileName: 'arvind-prescription-matches-360x800.png',
    );
  });

  testWidgets('capture matches at 320px 140 percent reduced motion', (
    tester,
  ) async {
    await capture(
      tester,
      size: const Size(320, 700),
      prescriptionId: 'meera',
      textScale: 1.4,
      fileName: 'meera-prescription-matches-320x700-140.png',
    );
  });
}
