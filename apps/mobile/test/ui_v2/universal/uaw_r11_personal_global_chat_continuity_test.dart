import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
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
      chatKey: Key('work-global-chat'),
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
    });
  }
}
