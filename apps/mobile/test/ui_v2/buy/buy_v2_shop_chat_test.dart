import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_chat_route_adapter.dart';

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

  test('Buy Chat adapter preserves context without a second Chat shell', () {
    const adapter = BuyV2ChatRouteAdapter();
    const cases =
        <
          ({
            BuyV2Destination destination,
            bool offersActive,
            String origin,
            String? type,
          })
        >[
          (
            destination: BuyV2Destination.shop,
            offersActive: false,
            origin: '/app/buy',
            type: null,
          ),
          (
            destination: BuyV2Destination.orders,
            offersActive: false,
            origin: '/app/buy?sub=orders',
            type: 'order',
          ),
          (
            destination: BuyV2Destination.wholesale,
            offersActive: false,
            origin: '/app/buy?sub=wholesale',
            type: 'business',
          ),
          (
            destination: BuyV2Destination.shop,
            offersActive: true,
            origin: '/app/buy?sub=offers',
            type: 'support',
          ),
        ];

    for (final entry in cases) {
      final uri = Uri.parse(
        adapter.locationFor(
          currentRoute: entry.origin,
          destination: entry.destination,
          offersActive: entry.offersActive,
        ),
      );
      expect(uri.path, '/app/chat/inbox', reason: entry.origin);
      expect(uri.queryParameters['type'], entry.type, reason: entry.origin);
      expect(uri.queryParameters['return'], entry.origin, reason: entry.origin);
    }
  });

  test('order Help opens MoolSocial Assist inside shared Chat', () {
    final uri = Uri.parse(
      const BuyV2ChatRouteAdapter().orderHelpLocationFor(orderId: 'PO-240783'),
    );

    expect(uri.path, '/app/chat/thread/shop-assist');
    expect(uri.queryParameters['draft'], 'Help with order PO-240783');
    expect(
      uri.queryParameters['return'],
      '/app/buy?sub=orders&view=tracking&order=PO-240783',
    );
    expect(uri.queryParameters['directReturn'], 'true');
  });

  testWidgets('Buy Chat action opens only the shared Chat module', (
    tester,
  ) async {
    final journey = await readyJourney();
    final chat = ChatSession();
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);

    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        chatSession: chat,
        initialLocation: '/app/buy',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mool-global-chat-tap')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
    expect(find.text('Shop Chat'), findsOneWidget);
    expect(find.byKey(const ValueKey('buy-shop-chat')), findsNothing);
    expect(find.text('Search conversations'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('order Help stays in one Assist conversation with one composer', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final journey = await readyJourney();
    final chat = ChatSession();
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);

    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        chatSession: chat,
        initialLocation: '/app/buy?sub=orders&view=tracking&order=PO-240783',
      ),
    );
    await tester.pumpAndSettle();

    final help = find.byKey(const ValueKey('buy-tracking-help'));
    await tester.scrollUntilVisible(
      help,
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(help);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
    expect(find.text('MoolSocial Assist'), findsWidgets);
    expect(find.byKey(const PageStorageKey('buy-assist')), findsNothing);
    expect(find.byKey(const Key('chat-inbox-screen')), findsNothing);
    expect(find.text('Search conversations'), findsNothing);
    expect(find.byKey(const Key('chat-suggested-prompts')), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-message-field')))
          .controller
          ?.text,
      'Help with order PO-240783',
    );

    await tester.tap(find.byKey(const Key('chat-suggested-prompt-0')));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-message-field')))
          .controller
          ?.text,
      'Help with order PO-240783\nWhere is my order?',
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-thread-screen')), findsNothing);
    expect(find.byKey(const Key('chat-inbox-screen')), findsNothing);
    expect(
      find.byKey(const PageStorageKey('buy-tracking-PO-240783')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
