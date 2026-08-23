import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  group('FIX1A shared brokered authentication return', () {
    test(
      'foreground X callback completes bootstrap and exact return',
      () async {
        final gateway = _CallbackSocialAuthGateway(
          provider: SocialAuthProvider.x,
          callbackBase: Uri.parse('moolsocial://auth/x'),
        );
        final bootstrap = ReviewAccountBootstrapGateway();
        final session = JourneySession(
          store: MemoryJourneyStore(snapshot: _signedOutSnapshot()),
          socialAuthGateway: gateway,
          availableSocialAuthProviders: const <SocialAuthProvider>{
            SocialAuthProvider.x,
          },
          accountBootstrapGateway: bootstrap,
        );
        await session.start();
        session.beginSignIn(returnLocation: '/app/social?sub=videos');

        expect(await session.signInWithSocial(SocialAuthProvider.x), isFalse);
        expect(session.socialAuthState, SocialAuthState.pending);
        expect(gateway.beginCount, 1);
        expect(bootstrap.prepareCount, 0);

        final handled = await session.prepareSocialAuthReturn(
          'moolsocial://auth/x?state=fixture-state&code=fixture-code',
        );

        expect(handled, isTrue);
        expect(gateway.foregroundCompleteCount, 1);
        expect(gateway.coldCompleteCount, 0);
        expect(bootstrap.prepareCount, 1);
        expect(session.isReady, isTrue);
        expect(
          session.takeCompletedSocialAuthReturnRoute(),
          '/app/social?sub=videos',
        );
      },
    );

    test(
      'cold Instagram callback restores the protected return once',
      () async {
        final gateway = _CallbackSocialAuthGateway(
          provider: SocialAuthProvider.instagram,
          callbackBase: Uri.parse('moolsocial://auth/instagram'),
        );
        final bootstrap = ReviewAccountBootstrapGateway();
        final session = JourneySession(
          store: MemoryJourneyStore(
            snapshot: _signedOutSnapshot(pendingRoute: '/app/social?sub=feed'),
          ),
          socialAuthGateway: gateway,
          availableSocialAuthProviders: const <SocialAuthProvider>{
            SocialAuthProvider.instagram,
          },
          accountBootstrapGateway: bootstrap,
        );

        final handled = await session.prepareSocialAuthReturn(
          'moolsocial://auth/instagram?state=fixture-state&code=fixture-code',
        );

        expect(handled, isTrue);
        expect(gateway.coldCompleteCount, 1);
        expect(gateway.foregroundCompleteCount, 0);
        expect(bootstrap.prepareCount, 1);
        expect(session.isReady, isTrue);
        expect(
          session.takeCompletedSocialAuthReturnRoute(),
          '/app/social?sub=feed',
        );
        expect(session.takeCompletedSocialAuthReturnRoute(), isNull);
      },
    );

    test(
      'bootstrap failure rolls back the brokered Firebase session',
      () async {
        final gateway = _CallbackSocialAuthGateway(
          provider: SocialAuthProvider.x,
          callbackBase: Uri.parse('moolsocial://auth/x'),
        );
        final session = JourneySession(
          store: MemoryJourneyStore(
            snapshot: _signedOutSnapshot(pendingRoute: '/app/chat'),
          ),
          socialAuthGateway: gateway,
          availableSocialAuthProviders: const <SocialAuthProvider>{
            SocialAuthProvider.x,
          },
          accountBootstrapGateway: ReviewAccountBootstrapGateway(
            failure: StateError('synthetic bootstrap failure'),
          ),
        );

        final handled = await session.prepareSocialAuthReturn(
          'moolsocial://auth/x?state=fixture-state&code=fixture-code',
        );

        expect(handled, isTrue);
        expect(session.isReady, isFalse);
        expect(session.stage, JourneyStage.signIn);
        expect(session.socialAuthState, SocialAuthState.failed);
        expect(gateway.signOutCount, 1);
        expect(gateway.signedIn, isFalse);
        expect(session.takeCompletedSocialAuthReturnRoute(), isNull);
      },
    );

    test(
      'unowned callback stays outside the authentication lifecycle',
      () async {
        final gateway = _CallbackSocialAuthGateway(
          provider: SocialAuthProvider.x,
          callbackBase: Uri.parse('moolsocial://auth/x'),
        );
        final session = JourneySession(
          store: MemoryJourneyStore(snapshot: _signedOutSnapshot()),
          socialAuthGateway: gateway,
        );

        expect(
          await session.prepareSocialAuthReturn(
            'moolsocial://auth/instagram?state=fixture&code=fixture',
          ),
          isFalse,
        );
        expect(gateway.foregroundCompleteCount, 0);
        expect(gateway.coldCompleteCount, 0);
      },
    );

    test('Apple capability and broker callback platform owners are exact', () {
      final entitlements = File(
        'ios/Runner/Runner.entitlements',
      ).readAsStringSync();
      final project = File(
        'ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      final androidManifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(_occurrences(entitlements, 'com.apple.developer.applesignin'), 1);
      expect(_occurrences(project, 'com.apple.SignInWithApple'), 1);
      expect(
        _occurrences(
          project,
          'CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;',
        ),
        3,
      );
      expect(_occurrences(androidManifest, 'android:path="/x"'), 1);
      expect(_occurrences(androidManifest, 'android:path="/instagram"'), 1);
    });
  });
}

JourneySnapshot _signedOutSnapshot({String? pendingRoute}) => JourneySnapshot(
  languageCode: 'en',
  areaMode: 'manual',
  areaLabel: 'Fixture area',
  setupComplete: true,
  pendingRoute: pendingRoute,
);

final class _CallbackSocialAuthGateway
    implements SocialAuthGateway, SocialAuthCallbackGateway {
  _CallbackSocialAuthGateway({
    required this.provider,
    required this.callbackBase,
  });

  final SocialAuthProvider provider;
  final Uri callbackBase;
  bool signedIn = false;
  int beginCount = 0;
  int foregroundCompleteCount = 0;
  int coldCompleteCount = 0;
  int signOutCount = 0;

  @override
  Future<bool> hasAuthenticatedUser() async => signedIn;

  @override
  Future<SocialAuthResult> signIn(SocialAuthProvider selected) async {
    expect(selected, provider);
    beginCount += 1;
    return const SocialAuthResult.authorizationPending();
  }

  @override
  SocialAuthProvider? providerForCallback(Uri callbackUri) =>
      _sameBase(callbackUri, callbackBase) ? provider : null;

  @override
  Future<SocialAuthResult> completeForegroundCallback(Uri callbackUri) async {
    expect(providerForCallback(callbackUri), provider);
    foregroundCompleteCount += 1;
    signedIn = true;
    return const SocialAuthResult.authenticated('fixture-user');
  }

  @override
  Future<SocialAuthResult> completeColdStartCallback(Uri callbackUri) async {
    expect(providerForCallback(callbackUri), provider);
    coldCompleteCount += 1;
    signedIn = true;
    return const SocialAuthResult.authenticated('fixture-user');
  }

  @override
  Future<void> signOut() async {
    signOutCount += 1;
    signedIn = false;
  }
}

bool _sameBase(Uri left, Uri right) =>
    left.scheme == right.scheme &&
    left.host == right.host &&
    left.port == right.port &&
    left.path == right.path;

int _occurrences(String body, String value) =>
    RegExp(RegExp.escape(value)).allMatches(body).length;
