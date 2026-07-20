import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/chat/chat_models.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openRoute(WidgetTester tester, String route) async {
    tester.element(find.byType(Scaffold).first).go(route);
    await tester.pumpAndSettle();
  }

  Future<void> verifyShortcut(
    WidgetTester tester, {
    required ChatSession chat,
    required String route,
    required Key shortcut,
  }) async {
    await openRoute(tester, route);
    expect(find.byKey(shortcut), findsOneWidget);
    await tester.tap(find.byKey(shortcut));
    await tester.pumpAndSettle();
    expect(chat.selectedFilter, ChatThreadType.support);
    expect(
      find.byKey(const Key('chat-open-thread-order-support')),
      findsOneWidget,
    );
  }

  testWidgets('physical Book Work and Pay help open the owned Support inbox', (
    tester,
  ) async {
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
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await journey.start();

    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        chatSession: chat,
        initialLocation: '/app/book/home',
      ),
    );
    await tester.pumpAndSettle();
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();

    await verifyShortcut(
      tester,
      chat: chat,
      route: '/app/book/home',
      shortcut: const Key('book-help'),
    );
    await verifyShortcut(
      tester,
      chat: chat,
      route: '/app/work/my-work',
      shortcut: const Key('work-help'),
    );
    await verifyShortcut(
      tester,
      chat: chat,
      route: '/app/pay/home',
      shortcut: const Key('pay-help-shortcut'),
    );
    await binding.takeScreenshot('support-029-book-work-pay');
  });
}
