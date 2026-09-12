import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  JourneySession signedInSession() => JourneySession(
    store: MemoryJourneyStore(
      snapshot: const JourneySnapshot(
        languageCode: 'en',
        areaMode: 'current',
        currentAreaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
        setupComplete: true,
        setupExperienceVersion: approvedSetupExperienceVersion,
      ),
    ),
    otpGateway: ReviewOtpGateway(signedIn: true),
  );

  test('R11 contract declares every retained Personal Chat origin', () {
    final contractFile = File.fromUri(
      Directory.current.uri.resolve(
        '../../config/mvp-personal-global-chat-continuity-v1.json',
      ),
    );
    final contract = jsonDecode(contractFile.readAsStringSync()) as Map;
    final origins = (contract['origins'] as List).cast<Map>();

    expect(origins.map((origin) => origin['id']), [
      'mool',
      'eat',
      'ride',
      'book',
      'work',
    ]);
    expect(contract['chatOwnerRoute'], '/app/chat/inbox');
    expect(contract['runtimeDisposition'], 'production_acceptance');
    expect(contract['newScreenOwners'], 0);
    expect(contract['newRouteOwners'], 0);
    expect(contract['newBackendOwners'], 0);
  });

  for (final origin in const [
    (
      id: 'mool',
      entryRoute: '/app/mool',
      returnOwnerKey: Key('personal-mool-root-v2'),
      chatKey: Key('mool-home-chat'),
    ),
    (
      id: 'social',
      entryRoute: '/app/social?sub=feed',
      returnOwnerKey: Key('screen04-universal-v2'),
      chatKey: Key('social-global-chat'),
    ),
    (
      id: 'buy',
      entryRoute: '/app/buy?sub=shop',
      returnOwnerKey: Key('buy-v2-screen'),
      chatKey: Key('mool-global-chat-tap'),
    ),
    (
      id: 'eat',
      entryRoute: '/app/eat/home',
      returnOwnerKey: Key('eat-home-screen'),
      chatKey: Key('eat-global-chat'),
    ),
    (
      id: 'ride',
      entryRoute: '/app/ride/book?type=bike',
      returnOwnerKey: Key('ride-booking-screen'),
      chatKey: Key('ride-global-chat'),
    ),
    (
      id: 'book',
      entryRoute: '/app/book/doctor',
      returnOwnerKey: Key('doctor-discovery-home'),
      chatKey: Key('care-global-chat'),
    ),
    (
      id: 'work',
      entryRoute: '/app/work/earn',
      returnOwnerKey: Key('work-earn-screen'),
      chatKey: Key('mool-global-chat-tap'),
    ),
  ]) {
    testWidgets('Chat returns to exact ${origin.id} origin', (tester) async {
      final journey = signedInSession();
      final chat = ChatSession();
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      await journey.start();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          chatSession: chat,
          initialLocation: origin.entryRoute,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(origin.returnOwnerKey), findsOneWidget);
      await tester.tap(find.byKey(origin.chatKey));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
      expect(find.text('WhatsApp'), findsNothing);
      expect(find.byKey(const Key('chat-back')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(origin.returnOwnerKey), findsOneWidget);
      expect(
        GoRouterState.of(
          tester.element(find.byType(Scaffold).first),
        ).uri.toString(),
        origin.entryRoute,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Buy supplier Chat retains its unsent draft and exact product return',
    (tester) async {
      final journey = signedInSession();
      final chat = ChatSession();
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      await journey.start();
      final product = BuyV2Catalogue.products.firstWhere(
        (item) =>
            item.destination == BuyV2Destination.wholesale &&
            item.sellerType.toLowerCase().contains('manufacturer'),
      );
      final origin = Uri(
        path: '/app/buy',
        queryParameters: {
          'sub': 'wholesale',
          'view': 'product',
          'product': product.id,
        },
      ).toString();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          chatSession: chat,
          initialLocation: origin,
        ),
      );
      await tester.pumpAndSettle();
      final productPage = find.byKey(
        PageStorageKey('buy-product-${product.id}'),
      );
      final productScroll = find
          .descendant(of: productPage, matching: find.byType(Scrollable))
          .first;
      final ask = find.bySemanticsLabel('Ask manufacturer');
      await tester.scrollUntilVisible(ask, 220, scrollable: productScroll);
      await tester.tap(ask);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
      final field = find.byKey(const Key('chat-message-field'));
      final prepared = tester.widget<TextField>(field).controller!.text;
      expect(prepared, contains(product.seller));
      expect(prepared, contains('SKU: ${product.id}'));
      expect(prepared, contains('Quantity: ${product.minimumOrder}'));
      final chatUri = GoRouterState.of(
        tester.element(find.byType(Scaffold).first),
      ).uri;
      expect(chatUri.queryParameters['return'], origin);
      final threadId = chatUri.pathSegments.last;
      final messagesBefore = chat.messages(threadId).length;
      final draft = '$prepared\nPlease help with this purchase';
      await tester.enterText(field, draft);
      await tester.pump();
      expect(chat.draftTextForSession(threadId), draft);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(productPage, findsOneWidget);
      expect(
        GoRouterState.of(
          tester.element(find.byType(Scaffold).first),
        ).uri.toString(),
        origin,
      );
      await tester.scrollUntilVisible(ask, 220, scrollable: productScroll);
      await tester.tap(ask);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
      expect(tester.widget<TextField>(field).controller!.text, draft);
      expect(chat.draftTextForSession(threadId), draft);
      expect(chat.messages(threadId), hasLength(messagesBefore));
      expect(tester.takeException(), isNull);
    },
  );
}
