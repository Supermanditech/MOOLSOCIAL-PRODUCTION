import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_connect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'YouTube callback returns to the connect screen and dismisses confirmation',
    (tester) async {
      final session = CreatorSession();
      addTearDown(session.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SocialYouTubeConnectV2Screen(
            session: session,
            youtubeConnectResult: 'complete',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text(
          'YouTube is connected to your MoolSocial account. '
          'You can now use eligible YouTube videos and Shorts in MoolSocial.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('youtube-connect-return-message')),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('youtube-connect-return-message')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('youtube-connect-source')),
        findsOneWidget,
      );
    },
  );

  testWidgets('YouTube callback failure offers a transient retry message', (
    tester,
  ) async {
    final session = CreatorSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SocialYouTubeConnectV2Screen(
          session: session,
          youtubeConnectResult: 'failed',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text(
        'YouTube was not connected. '
        'Try again or choose another Google account.',
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('youtube-connect-return-message')),
      findsNothing,
    );
  });

  testWidgets(
    'cold protected callback preserves the safe result through app startup',
    (tester) async {
      final session = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'current',
            setupComplete: true,
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      addTearDown(session.dispose);

      await tester.pumpWidget(
        MoolSocialApp(
          session: session,
          initialLocation:
              '/app/creator/youtube-connect?youtubeConnect=complete',
        ),
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byKey(const ValueKey('youtube-connect-source')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('youtube-connect-return-message')),
        findsOneWidget,
      );
      expect(
        find.text(
          'YouTube is connected to your MoolSocial account. '
          'You can now use eligible YouTube videos and Shorts in MoolSocial.',
        ),
        findsOneWidget,
      );
      expect(session.returnTo, isNull);

      await tester.pump(const Duration(seconds: 6));
      expect(
        find.byKey(const Key('youtube-connect-return-message')),
        findsNothing,
      );
    },
  );
}
