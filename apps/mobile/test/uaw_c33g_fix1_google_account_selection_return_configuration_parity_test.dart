import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  test(
    'ambiguous Google account-selection return stays incomplete and retryable',
    () async {
      final session = JourneySession(
        socialAuthGateway: ReviewSocialAuthGateway(
          results: const <SocialAuthProvider, SocialAuthResult>{
            SocialAuthProvider.google: SocialAuthResult.cancelled(),
          },
        ),
        availableSocialAuthProviders: const <SocialAuthProvider>{
          SocialAuthProvider.google,
          SocialAuthProvider.youtube,
        },
      );

      final completed = await session.signInWithSocial(
        SocialAuthProvider.google,
      );

      expect(completed, isFalse);
      expect(session.isAuthenticated, isFalse);
      expect(session.socialAuthState, SocialAuthState.cancelled);
      expect(session.errorMessage, contains('wasn’t completed'));
      expect(session.errorMessage, contains('Try again'));
      expect(session.errorMessage, isNot(contains('was cancelled')));

      session.clearSocialAuthResult();

      expect(session.socialAuthState, SocialAuthState.idle);
      expect(session.errorMessage, isNull);
      session.dispose();
    },
  );

  test('supported Google-backed identity methods remain exact', () {
    final session = JourneySession(
      availableSocialAuthProviders: const <SocialAuthProvider>{
        SocialAuthProvider.google,
        SocialAuthProvider.youtube,
      },
    );

    expect(
      SocialAuthProvider.values.where(session.isSocialAuthProviderAvailable),
      <SocialAuthProvider>[
        SocialAuthProvider.google,
        SocialAuthProvider.youtube,
      ],
    );
    for (final provider in const <SocialAuthProvider>{
      SocialAuthProvider.apple,
      SocialAuthProvider.x,
      SocialAuthProvider.instagram,
      SocialAuthProvider.facebook,
    }) {
      expect(session.isSocialAuthProviderAvailable(provider), isFalse);
    }
    session.dispose();
  });
}
