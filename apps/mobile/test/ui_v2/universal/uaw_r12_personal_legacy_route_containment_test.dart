import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/features/work/work_models.dart';
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
    JourneySession? journeySession,
  }) async {
    final journey = journeySession ?? signedInSession();
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

  test(
    'unapproved retailer families are contained but customer list stays owned',
    () {
      for (final entry in const {
        '/app/retailer/services': 'retailer-services',
        '/app/retailer/services/delivery?stage=review': 'retailer-services',
        '/app/retailer/services/delivery?stage=active': 'retailer-services',
        '/app/retailer/customers/sharma': 'retailer-customer-detail',
        '/app/retailer/campaigns?filter=active': 'retailer-campaigns',
        '/app/retailer/campaigns/new': 'retailer-campaigns',
      }.entries) {
        expect(
          legacyRouteContainmentFor(Uri.parse(entry.key))?.id,
          entry.value,
          reason: entry.key,
        );
      }
      expect(
        legacyRouteContainmentFor(
          Uri.parse('/app/retailer/customers?filter=all'),
        ),
        isNull,
      );
      expect(
        legacyRouteContainmentFor(Uri.parse('/app/work/workspace/dashboard')),
        isNull,
      );
    },
  );

  testWidgets(
    'retailer cold links use truthful recovery and current Work fallback',
    (tester) async {
      await mount(
        tester,
        route: '/app/retailer/services/delivery?stage=active',
      );
      expect(
        find.byKey(const Key('legacy-route-containment-retailer-services')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('legacy-route-containment-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-choose-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'retailer pushed recovery Back retains the exact existing origin',
    (tester) async {
      await mount(tester, route: '/app/work/my-work');
      final origin = tester.element(
        find.byKey(const Key('work-choose-screen')),
      );
      final router = GoRouter.of(origin);
      final originMatch =
          router.routerDelegate.currentConfiguration.matches.last;
      router.push<void>('/app/retailer/campaigns/new');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('legacy-route-containment-retailer-campaigns')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('legacy-route-containment-back')));
      await tester.pumpAndSettle();
      expect(
        identical(
          router.routerDelegate.currentConfiguration.matches.last,
          originMatch,
        ),
        isTrue,
      );
      expect(find.byKey(const Key('work-choose-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'host fixture customer list retains scroll and unfinished counter fields',
    (tester) async {
      tester.view.physicalSize = const Size(430, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final work = WorkSession()
        ..workspaceCounterCount = 3
        ..workspaceOrderItems = 'Unfinished host-fixture entry';
      await mount(tester, route: '/app/retailer/customers', workSession: work);
      final list = find.byKey(const Key('customers-screen'));
      expect(list, findsOneWidget);
      final scroll = tester.state<ScrollableState>(
        find.descendant(of: list, matching: find.byType(Scrollable)).first,
      );
      expect(scroll.position.maxScrollExtent, greaterThan(0));
      scroll.position.jumpTo(scroll.position.maxScrollExtent / 2);
      await tester.pump();
      final offset = scroll.position.pixels;
      final router = GoRouter.of(tester.element(list));
      router.push<void>('/app/retailer/customers/sharma');
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const Key('legacy-route-containment-retailer-customer-detail'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('legacy-route-containment-back')));
      await tester.pumpAndSettle();
      expect(
        identical(
          tester.state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)).first,
          ),
          scroll,
        ),
        isTrue,
      );
      expect(scroll.position.pixels, offset);
      expect(work.workspaceCounterCount, 3);
      expect(work.workspaceOrderItems, 'Unfinished host-fixture entry');
      expect(tester.takeException(), isNull);
    },
  );

  const fixtureA = WorkWorkspace(
    id: 'unit-store-a',
    name: 'Host fixture A',
    profileId: 'retailer-grocery',
    profileLabel: 'Grocery',
    area: 'Jaipur',
    verified: false,
  );
  const fixtureB = WorkWorkspace(
    id: 'unit-store-b',
    name: 'Host fixture B',
    profileId: 'retailer-grocery',
    profileLabel: 'Grocery',
    area: 'Jaipur',
    verified: false,
  );

  test('read-only navigation revision catches unnotified ABA and disposal', () {
    final work = WorkSession();
    final initial = work.navigationScopeRevision!;
    work.activeWorkspace = fixtureA;
    final first = work.navigationScopeRevision!;
    work.activeWorkspace = fixtureB;
    work.activeWorkspace = fixtureA;
    expect(work.navigationScopeRevision, greaterThan(first));
    expect(first, greaterThan(initial));
    final unchanged = work.navigationScopeRevision;
    work.activeWorkspace = fixtureA;
    work.notifyListeners();
    expect(work.navigationScopeRevision, unchanged);
    work.dispose();
    expect(work.navigationScopeRevision, isNull);
  });

  testWidgets(
    'unchanged principal and workspace refresh preserve retained Back',
    (tester) async {
      final journey = signedInSession();
      final work = WorkSession();
      await mount(
        tester,
        route: '/app/work/my-work',
        workSession: work,
        journeySession: journey,
      );
      final router = GoRouter.of(
        tester.element(find.byKey(const Key('work-choose-screen'))),
      );
      final origin = router.routerDelegate.currentConfiguration.matches.last;
      final generation = journey.navigationAuthenticationGeneration;
      final originElement = tester.element(
        find.byKey(const Key('work-choose-screen')),
      );
      router.push<void>('/app/retailer/services');
      await tester.pumpAndSettle();
      journey.confirmReadyRoute('/app/work/my-work');
      work.notifyListeners();
      router.refresh();
      await tester.pumpAndSettle();
      expect(journey.navigationAuthenticationGeneration, generation);
      await tester.tap(find.byKey(const Key('legacy-route-containment-back')));
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.matches.last, origin);
      expect(
        identical(
          tester.element(find.byKey(const Key('work-choose-screen'))),
          originElement,
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ABA Store change does not pop into an old retained scope', (
    tester,
  ) async {
    final work = WorkSession()..activeWorkspace = fixtureA;
    await mount(tester, route: '/app/work/my-work', workSession: work);
    final router = GoRouter.of(
      tester.element(find.byKey(const Key('work-choose-screen'))),
    );
    final origin = router.routerDelegate.currentConfiguration.matches.last;
    router.push<void>('/app/retailer/services');
    await tester.pumpAndSettle();
    // Deliberately unnotified host-fixture changes prove the monotonic boundary.
    work.activeWorkspace = fixtureB;
    work.activeWorkspace = fixtureA;
    await tester.tap(find.byKey(const Key('legacy-route-containment-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-choose-screen')), findsOneWidget);
    expect(
      identical(
        router.routerDelegate.currentConfiguration.matches.last,
        origin,
      ),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('stale recovery callback cannot replace a newer route', (
    tester,
  ) async {
    await mount(tester, route: '/app/work/my-work');
    final router = GoRouter.of(
      tester.element(find.byKey(const Key('work-choose-screen'))),
    );
    router.push<void>('/app/retailer/campaigns');
    await tester.pumpAndSettle();
    final back = tester
        .widget<LegacyRouteContainmentScreenV2>(
          find.byType(LegacyRouteContainmentScreenV2),
        )
        .onBack!;
    router.go('/app/book/doctor');
    await tester.pumpAndSettle();
    back();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('book-doctor')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'double Back is consumed once and disposed screen callback is inert',
    (tester) async {
      await mount(tester, route: '/app/work/my-work');
      final router = GoRouter.of(
        tester.element(find.byKey(const Key('work-choose-screen'))),
      );
      router.push<void>('/app/retailer/services');
      await tester.pumpAndSettle();
      final back = tester
          .widget<IconButton>(
            find.byKey(const Key('legacy-route-containment-back')),
          )
          .onPressed!;
      back();
      back();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-choose-screen')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      back();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'covered recovery rejects a stale tap without locking later Back',
    (tester) async {
      await mount(tester, route: '/app/work/my-work');
      final router = GoRouter.of(
        tester.element(find.byKey(const Key('work-choose-screen'))),
      );
      router.push<void>('/app/retailer/services');
      await tester.pumpAndSettle();
      final back = tester
          .widget<IconButton>(
            find.byKey(const Key('legacy-route-containment-back')),
          )
          .onPressed!;
      router.push<void>('/app/book/doctor');
      await tester.pumpAndSettle();
      back();
      expect(find.byKey(const Key('book-doctor')), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('legacy-route-containment-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-choose-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sign-out takes precedence over a stale retained return', (
    tester,
  ) async {
    final journey = signedInSession();
    await mount(tester, route: '/app/work/my-work', journeySession: journey);
    final router = GoRouter.of(
      tester.element(find.byKey(const Key('work-choose-screen'))),
    );
    router.push<void>('/app/retailer/services');
    await tester.pumpAndSettle();
    final back = tester
        .widget<LegacyRouteContainmentScreenV2>(
          find.byType(LegacyRouteContainmentScreenV2),
        )
        .onBack!;
    expect(await journey.signOut(), isTrue);
    await tester.pumpAndSettle();
    expect(journey.navigationAuthenticationGeneration, isNull);
    final route = router.routerDelegate.currentConfiguration.uri;
    back();
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri, route);
    expect(find.byType(LegacyRouteContainmentScreenV2), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('setup takes precedence over a cold legacy services link', (
    tester,
  ) async {
    final journey = JourneySession(
      store: MemoryJourneyStore(),
      otpGateway: ReviewOtpGateway(),
    );
    await mount(
      tester,
      route: '/app/retailer/services?legacyPresentationForTestsOnly=true',
      journeySession: journey,
    );
    expect(journey.stage, JourneyStage.setup);
    expect(find.byType(LegacyRouteContainmentScreenV2), findsNothing);
    expect(tester.takeException(), isNull);
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
      rootKey: Key('buy-v2-screen'),
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
    final work = WorkSession();
    await mount(
      tester,
      route: '/app/work/opportunity/content-creator',
      workSession: work,
    );

    expect(find.byKey(const Key('work-opportunity-screen')), findsOneWidget);
    expect(find.text('Content Creator'), findsOneWidget);
    expect(work.selectedOpportunity?.id, 'content-creator');
    expect(find.text('This paid-work link is unavailable'), findsNothing);
    await tester.tap(find.byKey(const Key('work-apply-opportunity')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-choose-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'retired Work opportunity has honest recovery without substitution',
    (tester) async {
      final work = WorkSession();
      await mount(
        tester,
        route: '/app/work/opportunity/mool-explainer',
        workSession: work,
      );

      expect(find.byKey(const Key('work-opportunity-screen')), findsNothing);
      expect(find.text('This paid-work link is unavailable'), findsOneWidget);
      expect(find.byKey(const Key('work-apply-opportunity')), findsNothing);
      expect(work.selectedOpportunity, isNull);
      await tester.tap(find.text('Open Earn Today'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

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
