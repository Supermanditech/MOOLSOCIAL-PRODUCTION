import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/journey01/review_journey_services.dart';

void main() {
  group('C33E FIX3 independent Social authentication cleanup', () {
    test('successful cleanup retains Firebase then Google order', () async {
      final events = <String>[];
      final gateway = FirebaseSocialAuthGateway.forTesting(
        authClient: _CleanupAuthClient(events: events),
        googleIdentityGateway: _CleanupGoogleGateway(events: events),
      );

      await gateway.signOut();

      expect(events, ['firebase-sign-out', 'google-sign-out']);
    });

    test('Firebase cleanup failure still attempts Google cleanup', () async {
      final events = <String>[];
      final firebaseFailure = StateError('synthetic Firebase cleanup failure');
      final gateway = FirebaseSocialAuthGateway.forTesting(
        authClient: _CleanupAuthClient(
          events: events,
          signOutFailure: firebaseFailure,
        ),
        googleIdentityGateway: _CleanupGoogleGateway(events: events),
      );

      await expectLater(gateway.signOut(), throwsA(same(firebaseFailure)));

      expect(events, ['firebase-sign-out', 'google-sign-out']);
    });

    test('Google cleanup failure follows completed Firebase cleanup', () async {
      final events = <String>[];
      final googleFailure = StateError('synthetic Google cleanup failure');
      final gateway = FirebaseSocialAuthGateway.forTesting(
        authClient: _CleanupAuthClient(events: events),
        googleIdentityGateway: _CleanupGoogleGateway(
          events: events,
          signOutFailure: googleFailure,
        ),
      );

      await expectLater(gateway.signOut(), throwsA(same(googleFailure)));

      expect(events, ['firebase-sign-out', 'google-sign-out']);
    });

    test(
      'bootstrap and cleanup failure retains signed-out origin recovery',
      () async {
        const origin = '/app/social?sub=create&composer=text';
        final social = _ThrowingRollbackSocialGateway();
        final session = JourneySession(
          store: MemoryJourneyStore(
            snapshot: const JourneySnapshot(
              languageCode: 'en',
              areaMode: 'current',
              currentAreaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
              setupComplete: true,
            ),
          ),
          allowGuestReady: true,
          socialAuthGateway: social,
          accountBootstrapGateway: ReviewAccountBootstrapGateway(
            failure: const JourneyServiceException(
              'Your account service is unavailable. Please retry.',
            ),
          ),
        );
        addTearDown(session.dispose);
        await session.start();
        expect(session.stage, JourneyStage.ready);
        expect(session.isAuthenticated, isFalse);
        session.beginSignIn(returnLocation: origin, cancelLocation: origin);

        expect(
          await session.signInWithSocial(SocialAuthProvider.google),
          isFalse,
        );

        expect(social.signInCount, 1);
        expect(social.signOutCount, 1);
        expect(session.isAuthenticated, isFalse);
        expect(session.stage, JourneyStage.signIn);
        expect(session.socialAuthState, SocialAuthState.failed);
        expect(session.busy, isFalse);
        expect(session.returnTo, origin);
        expect(session.readyRoute(), origin);
        expect(
          session.errorMessage,
          contains('account service is unavailable'),
        );
        expect(session.errorMessage, isNot(contains('cleanup')));
      },
    );
  });
}

class _CleanupAuthClient implements FirebaseSocialAuthClient {
  _CleanupAuthClient({required this.events, this.signOutFailure});

  final List<String> events;
  final Object? signOutFailure;

  @override
  String? get currentUserId => null;

  @override
  Future<String?> signInWithGoogleIdToken(String idToken) async => 'unused';

  @override
  Future<String?> signInWithProvider(AuthProvider provider) async => 'unused';

  @override
  Future<void> signOut() async {
    events.add('firebase-sign-out');
    if (signOutFailure case final failure?) throw failure;
  }
}

class _CleanupGoogleGateway implements GoogleIdentityGateway {
  _CleanupGoogleGateway({required this.events, this.signOutFailure});

  final List<String> events;
  final Object? signOutFailure;

  @override
  Future<String?> authenticateIdToken() async => null;

  @override
  Future<void> signOut() async {
    events.add('google-sign-out');
    if (signOutFailure case final failure?) throw failure;
  }
}

class _ThrowingRollbackSocialGateway implements SocialAuthGateway {
  int signInCount = 0;
  int signOutCount = 0;

  @override
  Future<bool> hasAuthenticatedUser() async => false;

  @override
  Future<SocialAuthResult> signIn(SocialAuthProvider provider) async {
    signInCount += 1;
    return const SocialAuthResult.authenticated('synthetic-user');
  }

  @override
  Future<void> signOut() async {
    signOutCount += 1;
    throw StateError('synthetic combined cleanup failure');
  }
}
