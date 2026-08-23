import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  Future<String> canonicalPersistedContext(String? candidateRoute) async {
    final store = MemoryJourneyStore(
      snapshot: const JourneySnapshot(
        languageCode: 'en',
        areaMode: 'current',
        currentAreaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
        setupComplete: true,
      ),
    );
    final session = JourneySession(
      store: store,
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    await session.start();
    if (candidateRoute != null) {
      session.confirmReadyRoute(candidateRoute);
      await Future<void>.delayed(Duration.zero);
    }
    final route = store.snapshot?.lastReadyRoute ?? '/app/social';
    session.dispose();
    return route;
  }

  test('machine contract safely canonicalizes main and sub-actions', () async {
    final contractFile = File.fromUri(
      Directory.current.uri.resolve(
        '../../config/mvp-personal-context-restore-v1.json',
      ),
    );
    final contract = jsonDecode(contractFile.readAsStringSync()) as Map;
    final contexts = (contract['contexts'] as List).cast<Map>();

    expect(
      contract['runtimeOwner'],
      'JourneySession_pending_route_then_social_cold_launch',
    );
    expect(
      contract['contextCanonicalizationOwner'],
      'JourneySession_canonical_persisted_ready_route',
    );
    expect(
      contract['storageOwner'],
      'existing_JourneySnapshot_lastReadyRoute_diagnostic_not_cold_launch',
    );
    expect(contract['coldLaunchRoute'], '/app/social');
    expect(contract['pendingRoutePrecedence'], isTrue);
    expect(
      contract['lastReadyRouteLaunchBehavior'],
      'ignored_without_an_explicit_pending_route',
    );
    expect(contract['fallbackRoute'], '/app/social');
    expect(contract['newScreenOwners'], 0);
    expect(contract['newRouteOwners'], 0);
    expect(contract['newStoreOwners'], 0);
    expect(contract['newBackendOwners'], 0);
    expect(contexts.map((context) => context['id']), [
      'social',
      'buy',
      'mool',
      'eat',
      'ride',
      'book',
      'work',
    ]);

    for (final context in contexts) {
      final root = context['root'] as String;
      expect(
        await canonicalPersistedContext(root),
        root,
        reason: '${context['id']} root',
      );
      final subActions = context['subActions'];
      if (subActions is Map) {
        for (final entry in subActions.entries) {
          final route = entry.value as String;
          expect(
            await canonicalPersistedContext(route),
            route,
            reason: '${context['id']} ${entry.key}',
          );
        }
      }
    }
  });

  test(
    'deeper workflow routes reduce to safe identifier-free context',
    () async {
      const expectations = <String, String>{
        '/app/eat/order/ORDER-PRIVATE/completed?token=secret': '/app/eat/home',
        '/app/eat/basket?coupon=private': '/app/eat/home',
        '/app/eat/table/BOOKING-PRIVATE': '/app/eat/table',
        '/app/ride/trip/TRIP-PRIVATE/support': '/app/ride',
        '/app/book/doctor/details?doctor=PRIVATE': '/app/book/doctor',
        '/app/book/salon/confirmed?booking=PRIVATE': '/app/book/salon',
        '/app/work/opportunity/FUNDED-PRIVATE': '/app/work/earn',
        '/app/work/workspace/proof?record=PRIVATE': '/app/work/my-work',
      };

      for (final entry in expectations.entries) {
        expect(
          await canonicalPersistedContext(entry.key),
          entry.value,
          reason: entry.key,
        );
        expect(
          await canonicalPersistedContext(entry.key),
          isNot(contains('PRIVATE')),
          reason: entry.key,
        );
      }
    },
  );

  test(
    'Chat interruption restores only a canonical permitted return',
    () async {
      for (final returnRoute in const [
        '/app/mool',
        '/app/eat',
        '/app/ride/book?type=auto',
        '/app/book/salon',
        '/app/work/my-work',
      ]) {
        final chatRoute = Uri(
          path: '/app/chat/inbox',
          queryParameters: {'return': returnRoute},
        ).toString();
        expect(
          await canonicalPersistedContext(chatRoute),
          returnRoute,
          reason: chatRoute,
        );
      }

      final threadRoute = Uri(
        path: '/app/chat/thread/PRIVATE-THREAD',
        queryParameters: {'return': '/app/book/doctor/details?doctor=PRIVATE'},
      ).toString();
      expect(await canonicalPersistedContext(threadRoute), '/app/book/doctor');

      for (final unsafeReturn in const [
        'https://example.com/app/work',
        '/app/pay',
        '/app/chat/inbox?return=/app/work',
        '/app/unknown',
      ]) {
        final chatRoute = Uri(
          path: '/app/chat/inbox',
          queryParameters: {'return': unsafeReturn},
        ).toString();
        expect(
          await canonicalPersistedContext(chatRoute),
          '/app/social',
          reason: chatRoute,
        );
      }
    },
  );

  test('legacy recovery restores its current safe owning root', () async {
    const reasonRoots = <String, String>{
      'tiffin': '/app/eat',
      'get-it-done': '/app/book',
      'standalone-pay': '/app/mool',
      'delivery': '/app/work',
      'onboard': '/app/work',
      'verify': '/app/work',
    };
    for (final entry in reasonRoots.entries) {
      expect(
        await canonicalPersistedContext(
          '/app/action-unavailable?reason=${entry.key}',
        ),
        entry.value,
        reason: entry.key,
      );
    }
  });

  test(
    'removed malformed external and unknown locations fail closed',
    () async {
      for (final route in const [
        '/app/pay',
        '/app/eat/tiffin',
        '/app/book/task/live',
        '/app/work/opportunity/delivery',
        '/app/work/choose',
        '/app/work/proof',
        '/app/ride/book?type=helicopter',
        '/app/social?sub=admin&workspace=other',
        '/app/unknown?capability=granted',
        '/app/../work',
        'https://example.com/app/work',
      ]) {
        expect(
          await canonicalPersistedContext(route),
          '/app/social',
          reason: route,
        );
      }
    },
  );

  test(
    'interrupted persistence is canonical and survives a new session',
    () async {
      final store = MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'current',
          currentAreaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
          setupComplete: true,
        ),
      );
      final first = JourneySession(
        store: store,
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      await first.start();
      final interruptedChat = Uri(
        path: '/app/chat/thread/PRIVATE-THREAD',
        queryParameters: {'return': '/app/ride/book?type=cab'},
      ).toString();
      first.confirmReadyRoute(interruptedChat);
      await Future<void>.delayed(Duration.zero);
      expect(store.snapshot?.lastReadyRoute, '/app/ride/book?type=cab');
      first.dispose();

      final relaunched = JourneySession(
        store: store,
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      await relaunched.start();
      expect(relaunched.readyRoute(), '/app/social');
      relaunched.dispose();
    },
  );

  testWidgets(
    'production cold boot starts Social despite canonical Ride context',
    (tester) async {
      final session = JourneySession(
        store: MemoryJourneyStore(
          snapshot: const JourneySnapshot(
            languageCode: 'en',
            areaMode: 'current',
            currentAreaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
            setupComplete: true,
            lastReadyRoute: '/app/ride/book?type=auto',
          ),
        ),
        otpGateway: ReviewOtpGateway(signedIn: true),
      );
      addTearDown(session.dispose);
      await session.start();
      await tester.pumpWidget(
        MoolSocialApp(session: session, initialLocation: '/boot'),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('screen04-universal-v2')), findsOneWidget);
      expect(find.byKey(const Key('ride-booking-screen')), findsNothing);
    },
  );
}
