import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  Future<JourneySession> readySession() async {
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'skipped',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    await session.start();
    return session;
  }

  testWidgets('universal screen 412x915 visual baseline', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = await readySession();
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MoolSocialApp(session: session, initialLocation: '/app/social'),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/universal-social-412x915.png'),
    );
  });

  testWidgets('universal screen 360x800 visual baseline', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = await readySession();
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MoolSocialApp(session: session, initialLocation: '/app/social'),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/universal-social-360x800.png'),
    );
  });

  testWidgets('Mool command palette 412x915 visual baseline', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = await readySession();
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MoolSocialApp(session: session, initialLocation: '/app/social'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-mool')));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/universal-mool-412x915.png'),
    );
  });

  testWidgets('Buy intent 412x915 visual baseline', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = await readySession();
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MoolSocialApp(session: session, initialLocation: '/app/buy'),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/universal-buy-412x915.png'),
    );
  });
}
