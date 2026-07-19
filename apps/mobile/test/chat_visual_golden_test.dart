import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  Future<void> verifyScreen(
    WidgetTester tester, {
    required String route,
    required String golden,
  }) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    final journey = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Jodhpur',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    final chat = ChatSession();
    await journey.start();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      chat.dispose();
    });
    await tester.pumpWidget(
      MoolSocialApp(
        key: ValueKey(route),
        session: journey,
        chatSession: chat,
        initialLocation: route,
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold).first, matchesGoldenFile(golden));
  }

  final screens = <(String, String, String)>[
    ('Chat inbox 023', '/app/chat/inbox', 'chat-023-inbox'),
    (
      'Chat order support 022',
      '/app/chat/thread/order-support',
      'chat-022-order-support',
    ),
    ('Chat business 024', '/app/chat/thread/mahadev', 'chat-024-business'),
    ('Chat people 025', '/app/chat/thread/home-basket', 'chat-025-people'),
  ];

  for (final screen in screens) {
    testWidgets('${screen.$1} phone visual baseline', (tester) async {
      await verifyScreen(
        tester,
        route: screen.$2,
        golden: 'goldens/${screen.$3}-412x915.png',
      );
    });
  }
}
