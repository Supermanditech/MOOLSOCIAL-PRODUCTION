import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/screens/screen02_first_setup/first_setup_screen_v2.dart';

void main() {
  testWidgets('Screen 02 consent candidate at 360x720', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final session = JourneySession();
    addTearDown(session.dispose);
    await session.start();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
        home: FirstSetupScreenV2(session: session),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const Key('screen02-v4')),
      matchesGoldenFile('goldens/ui_v2_screen02_location-consent-360x720.png'),
    );
  });
}
