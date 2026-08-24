import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/chat/chat_services.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<JourneySession> readyJourney() async {
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Sardarpura',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    await session.start();
    return session;
  }

  Future<({JourneySession journey, ChatSession chat})> mount(
    WidgetTester tester, {
    required String route,
    Size size = const Size(390, 844),
  }) async {
    await tester.binding.setSurfaceSize(size);
    final journey = await readyJourney();
    final chat = ChatSession(
      sendGateway: ReviewChatSendGateway(latency: Duration.zero),
    );
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        chatSession: chat,
        initialLocation: route,
      ),
    );
    await tester.pumpAndSettle();
    return (journey: journey, chat: chat);
  }

  testWidgets('Chat inbox is a standalone page with exact origin Back', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    await mount(tester, route: '/app/chat/inbox?return=/app/buy');

    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
    expect(find.byKey(const Key('chat-global-edge-navigation')), findsNothing);
    expect(find.byKey(const Key('mool-compact-launcher')), findsNothing);
    expect(find.byKey(const Key('chat-global-chat-edge')), findsNothing);
    expect(find.byKey(const Key('chat-back')), findsNothing);
    expect(find.byKey(const Key('chat-inbox-back')), findsOneWidget);
    expect(find.byTooltip('Back to previous screen'), findsOneWidget);
    expect(find.byKey(const Key('chat-open-mool')), findsNothing);
    expect(find.byKey(const Key('chat-thread-mool')), findsNothing);

    await tester.tap(find.byKey(const Key('chat-inbox-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('thread Back restores the exact live inbox query and filter', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mount(
      tester,
      route: '/app/chat/inbox?return=/app/social',
      size: const Size(360, 800),
    );

    await tester.enterText(
      find.byKey(const Key('chat-search-field')),
      'Home Basket',
    );
    await tester.tap(find.byKey(const Key('chat-filter-people')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-open-thread-home-basket')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
    expect(find.byKey(const Key('chat-back')), findsOneWidget);
    expect(find.byKey(const Key('chat-global-chat-edge')), findsNothing);

    await tester.tap(find.byKey(const Key('chat-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const Key('chat-filter-people')))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-search-field')))
          .controller
          ?.text,
      'Home Basket',
    );
    expect(find.byKey(const Key('chat-back')), findsNothing);
    expect(find.byKey(const Key('chat-inbox-back')), findsOneWidget);
  });

  testWidgets('thread keeps native composer focus without a global dock', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await mount(
      tester,
      route: '/app/chat/thread/home-basket?return=/app/social',
      size: const Size(360, 800),
    );

    final field = find.byKey(const Key('chat-message-field'));
    Finder editableField() =>
        find.descendant(of: field, matching: find.byType(EditableText));
    await tester.showKeyboard(field);
    await tester.enterText(field, 'Keep this exact draft');
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    expect(
      tester.widget<EditableText>(editableField()).focusNode.hasFocus,
      isTrue,
    );

    expect(find.byKey(const Key('mool-compact-launcher')), findsNothing);
    expect(find.byKey(const Key('chat-global-chat-edge')), findsNothing);
    await tester.pump();
    expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
    expect(
      tester.widget<TextField>(field).controller?.text,
      'Keep this exact draft',
    );
    expect(
      tester.widget<EditableText>(editableField()).focusNode.hasFocus,
      isTrue,
    );
    expect(tester.testTextInput.isVisible, isTrue);
  });
}
