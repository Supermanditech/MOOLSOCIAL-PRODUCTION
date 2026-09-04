import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/ui_v2/universal/legacy_route_containment_screen_v2.dart';

void main() {
  JourneySession signedInSession() {
    return JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'current',
          currentAreaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
  }

  Future<void> mount(
    WidgetTester tester, {
    required String route,
    WorkSession? workSession,
  }) async {
    final journey = signedInSession();
    addTearDown(journey.dispose);
    if (workSession != null) addTearDown(workSession.dispose);
    await journey.start();
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        workSession: workSession,
        initialLocation: route,
      ),
    );
    await tester.pumpAndSettle();
  }

  test('machine inventory and pure policy contain every declared old path', () {
    final contractFile = File.fromUri(
      Directory.current.uri.resolve(
        '../../config/mvp-personal-legacy-route-containment-v1.json',
      ),
    );
    final contract = jsonDecode(contractFile.readAsStringSync()) as Map;
    final families = (contract['blockedFamilies'] as List).cast<Map>();

    expect(families.map((family) => family['id']), [
      'tiffin',
      'get-it-done',
      'standalone-pay',
      'delivery',
      'onboard',
      'verify',
    ]);
    for (final family in families) {
      for (final path in (family['exactPaths'] as List).cast<String>()) {
        expect(
          legacyRouteContainmentFor(Uri.parse(path))?.id,
          family['id'],
          reason: path,
        );
      }
      for (final prefix in (family['prefixPaths'] as List).cast<String>()) {
        expect(
          legacyRouteContainmentFor(Uri.parse('${prefix}legacy-record'))?.id,
          family['id'],
          reason: prefix,
        );
      }
    }
    expect(contract['recoveryOwner']['newScreenOwners'], 1);
    expect(contract['recoveryOwner']['newRouteOwners'], 1);
    expect(contract['recoveryOwner']['newBackendOwners'], 0);
  });

  test('pure policy contains query aliases and preserves exact owners', () {
    final blockedAliases = <String, String>{
      '/app/eat?sub=tiffin': 'tiffin',
      '/app/social?world=book&sub=get-done': 'get-it-done',
      '/app/social?world=pay&sub=recharge': 'standalone-pay',
      '/app/social?world=work&sub=delivery': 'delivery',
      '/app/social?world=work&sub=onboard': 'onboard',
      '/app/social?world=work&sub=verify': 'verify',
    };
    for (final entry in blockedAliases.entries) {
      expect(
        legacyRouteContainmentFor(Uri.parse(entry.key))?.id,
        entry.value,
        reason: entry.key,
      );
    }

    for (final route in const [
      '/app/eat/home',
      '/app/book/doctor',
      '/app/book/salon',
      '/app/pay/request/REQ-1/confirm',
      '/app/pay/payment/PAY-1/receipt',
      '/app/pay/payment/PAY-1/status',
      '/app/pay/payment/PAY-1/outcome',
      '/app/work/opportunity/mool-explainer',
      '/app/work/workspace/choose',
      '/app/work/workspace/proof',
    ]) {
      expect(
        legacyRouteContainmentFor(Uri.parse(route)),
        isNull,
        reason: route,
      );
    }
  });

  for (final legacy in const [
    (
      id: 'tiffin',
      route: '/app/eat/tiffin/legacy-plan',
      rootKey: Key('eat-home-screen'),
    ),
    (
      id: 'get-it-done',
      route: '/app/book/task/live',
      rootKey: Key('book-doctor'),
    ),
    (
      id: 'standalone-pay',
      route: '/app/pay/scan',
      rootKey: Key('personal-mool-root-v2'),
    ),
    (
      id: 'delivery',
      route: '/app/work/opportunity/delivery',
      rootKey: Key('work-earn-screen'),
    ),
    (
      id: 'onboard',
      route: '/app/work/choose',
      rootKey: Key('work-choose-screen'),
    ),
    (
      id: 'verify',
      route: '/app/social?world=work&sub=verify',
      rootKey: Key('work-choose-screen'),
    ),
  ]) {
    testWidgets('${legacy.id} old link reaches truthful shared recovery', (
      tester,
    ) async {
      await mount(tester, route: legacy.route);

      expect(
        find.byKey(Key('legacy-route-containment-${legacy.id}')),
        findsOneWidget,
      );
      expect(
        find.text(
          '${legacyRouteContainmentSpecs[legacy.id]!.label} is not available here',
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('legacy-route-containment-primary')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(legacy.rootKey), findsOneWidget);
    });
  }

  testWidgets('transaction-owned Pay record route remains exact and truthful', (
    tester,
  ) async {
    await mount(tester, route: '/app/pay/payment/missing/receipt');

    expect(find.text('Payment record not found'), findsOneWidget);
    expect(
      find.byKey(const Key('legacy-route-containment-standalone-pay')),
      findsNothing,
    );
  });

  testWidgets('exact funded Work opportunity route remains owned by Work', (
    tester,
  ) async {
    await mount(tester, route: '/app/work/opportunity/mool-explainer');

    expect(find.byKey(const Key('work-opportunity-screen')), findsOneWidget);
    expect(find.text('Make one MoolSocial explainer video'), findsOneWidget);
  });

  testWidgets('canonical Work workspace choose route remains operational', (
    tester,
  ) async {
    await mount(tester, route: '/app/work/workspace/choose');

    expect(find.byKey(const Key('work-choose-screen')), findsOneWidget);
  });

  testWidgets('canonical Work workspace proof route remains operational', (
    tester,
  ) async {
    final work = WorkSession()
      ..startMyWork()
      ..selectFamily('products-trade')
      ..selectProfile('retailer-grocery');
    await mount(tester, route: '/app/work/workspace/proof', workSession: work);

    expect(find.byKey(const Key('work-proof-screen')), findsOneWidget);
  });
}
