import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/screens/screen03_login/login_screen_v2.dart';

void main() {
  const productionProviders = <SocialAuthProvider>{
    SocialAuthProvider.google,
    SocialAuthProvider.youtube,
  };

  Future<JourneySession> mountProductionLogin(
    WidgetTester tester,
    ReviewSocialAuthGateway gateway,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 720);
    addTearDown(tester.view.reset);
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'current',
          currentAreaLabel: 'Jodhpur, Rajasthan',
          setupComplete: true,
        ),
      ),
      socialAuthGateway: gateway,
      availableSocialAuthProviders: productionProviders,
    );
    addTearDown(session.dispose);
    await session.start();
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreenV2(session: session),
      ),
    );
    await tester.pumpAndSettle();
    return session;
  }

  testWidgets(
    'production unsupported identity taps stay local with zero gateway dispatch',
    (tester) async {
      final gateway = ReviewSocialAuthGateway(
        defaultResult: const SocialAuthResult.authenticated('must-not-run'),
      );
      final session = await mountProductionLogin(tester, gateway);

      for (final provider in const <SocialAuthProvider>[
        SocialAuthProvider.apple,
        SocialAuthProvider.x,
        SocialAuthProvider.instagram,
        SocialAuthProvider.facebook,
      ]) {
        await tester.tap(
          find.byKey(Key('screen03-provider-${provider.name}')),
        );
        await tester.pumpAndSettle();

        expect(gateway.signInCount, 0, reason: provider.name);
        expect(session.socialAuthProvider, provider, reason: provider.name);
        expect(session.socialAuthState, SocialAuthState.failed);
        expect(session.errorMessage, contains('not available right now'));
        expect(session.errorMessage, contains('Choose another method'));
        expect(find.byKey(const Key('social-auth-message')), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('social-auth-change-method')),
        );
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'production Google and YouTube identity taps reach the Google-backed gateway',
    (tester) async {
      final gateway = ReviewSocialAuthGateway();
      final session = await mountProductionLogin(tester, gateway);

      for (final provider in const <SocialAuthProvider>[
        SocialAuthProvider.google,
        SocialAuthProvider.youtube,
      ]) {
        await tester.tap(
          find.byKey(Key('screen03-provider-${provider.name}')),
        );
        await tester.pumpAndSettle();

        expect(gateway.lastProvider, provider);
        expect(session.socialAuthProvider, provider);
        expect(session.socialAuthState, SocialAuthState.cancelled);
        expect(session.errorMessage, contains('wasn’t completed'));
        await tester.tap(
          find.byKey(const Key('social-auth-change-method')),
        );
        await tester.pumpAndSettle();
      }
      expect(gateway.signInCount, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
