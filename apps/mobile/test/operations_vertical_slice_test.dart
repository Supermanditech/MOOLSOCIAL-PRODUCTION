import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/operations/operations_services.dart';
import 'package:moolsocial/features/operations/operations_session.dart';

void main() {
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 40),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 6),
  );

  Future<OperationsSession> mount(
    WidgetTester tester, {
    required String route,
    OperationsSession? operationsSession,
    Size size = const Size(412, 915),
  }) async {
    await tester.binding.setSurfaceSize(size);
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
    final operations = operationsSession ?? OperationsSession();
    await journey.start();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      operations.dispose();
    });
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        operationsSession: operations,
        initialLocation: route,
      ),
    );
    await settle(tester);
    return operations;
  }

  Future<Finder> reveal(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    if (finder.evaluate().isEmpty) {
      final scrollables = find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            {
              AxisDirection.down,
              AxisDirection.up,
            }.contains(widget.axisDirection),
      );
      for (final state
          in scrollables
              .evaluate()
              .whereType<StatefulElement>()
              .map((element) => element.state)
              .whereType<ScrollableState>()) {
        if (state.position.maxScrollExtent <= state.position.minScrollExtent) {
          continue;
        }
        state.position.jumpTo(state.position.minScrollExtent);
        await tester.pump();
        for (
          var attempt = 0;
          attempt < 60 && finder.evaluate().isEmpty;
          attempt += 1
        ) {
          state.position.jumpTo(
            (state.position.pixels + 240).clamp(
              state.position.minScrollExtent,
              state.position.maxScrollExtent,
            ),
          );
          await tester.pump();
        }
        if (finder.evaluate().isNotEmpty) break;
      }
    }
    expect(finder, findsOneWidget, reason: 'Missing target $key');
    await tester.ensureVisible(finder);
    await settle(tester);
    return finder;
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(await reveal(tester, key));
    await settle(tester);
  }

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    await tester.enterText(await reveal(tester, key), value);
    await settle(tester);
  }

  Future<void> go(WidgetTester tester, String route) async {
    tester.element(find.byType(Scaffold).first).go(route);
    await settle(tester);
  }

  String location(WidgetTester tester) => GoRouterState.of(
    tester.element(find.byType(Scaffold).first),
  ).uri.toString();

  testWidgets(
    'screen 133 covers every opportunity, filter and exact apply retry',
    (tester) async {
      final gateway = ReviewOperationsGateway()..failApplication = true;
      final session = OperationsSession(gateway: gateway);
      await mount(tester, route: '/app/earn', operationsSession: session);
      expect(
        find.byKey(const Key('earn-opportunities-screen')),
        findsOneWidget,
      );
      await tap(tester, const Key('earn-opportunity-filters'));
      await tap(tester, const Key('earn-filter-sheet-delivery'));
      await tap(tester, const Key('earn-filter-close'));
      expect(session.opportunityFilter, EarnOpportunityFilter.delivery);

      for (final opportunity in reviewEarnOpportunities) {
        await tap(tester, Key('earn-opportunity-${opportunity.id}'));
        expect(session.selectedOpportunityId, opportunity.id);
        await tap(tester, const Key('earn-opportunity-close'));
      }

      await tap(tester, const Key('earn-opportunity-retailer'));
      await tap(tester, const Key('earn-opportunity-apply'));
      expect(gateway.applicationCalls, 0);
      await tap(tester, const Key('earn-opportunity-terms'));
      await tap(tester, const Key('earn-opportunity-apply'));
      expect(session.applicationId, isNull);
      await tap(tester, const Key('earn-opportunity-apply'));
      expect(session.applicationId, 'EARN-APP-133-retailer');
      expect(gateway.applicationCalls, 2);
      await tap(tester, const Key('earn-opportunity-apply'));
      expect(gateway.applicationCalls, 2);
      await tap(tester, const Key('earn-opportunity-open-work'));
      expect(location(tester), '/app/earn/applications');
    },
  );

  testWidgets('screen 134 covers tabs, states and exact approved-work retry', (
    tester,
  ) async {
    final gateway = ReviewOperationsGateway()..failWorkStart = true;
    final session = OperationsSession(gateway: gateway);
    await mount(
      tester,
      route: '/app/earn/applications',
      operationsSession: session,
    );
    for (final tab in EarnApplicationTab.values) {
      await tap(tester, Key('earn-app-tab-${tab.name}'));
      expect(session.applicationTab, tab);
    }
    await tap(tester, const Key('earn-app-tab-applied'));
    await tap(tester, const Key('earn-application-review'));
    await tap(tester, const Key('earn-application-close'));
    await tap(tester, const Key('earn-application-approved'));
    await tap(tester, const Key('earn-work-start'));
    expect(session.workStartId, isNull);
    await tap(tester, const Key('earn-work-start'));
    expect(session.workStartId, 'WRK-4821');
    expect(gateway.workStartCalls, 2);
    expect(location(tester), '/app/earn/active');
  });

  testWidgets('screen 135 keeps bounded work, proof and exact support retry', (
    tester,
  ) async {
    final gateway = ReviewOperationsGateway()..failEarnSupport = true;
    final session = OperationsSession(gateway: gateway);
    await mount(tester, route: '/app/earn/active', operationsSession: session);
    await tap(tester, const Key('earn-work-support'));
    await tap(tester, const Key('earn-support-submit'));
    expect(gateway.earnSupportCalls, 0);
    await enter(
      tester,
      const Key('earn-support-details'),
      'The business is closed and I need a safe reschedule.',
    );
    await tap(tester, const Key('earn-support-submit'));
    expect(session.earnSupportId, isNull);
    await tap(tester, const Key('earn-support-submit'));
    expect(session.earnSupportId, 'EARN-CASE-135-4821');
    expect(gateway.earnSupportCalls, 2);
    await tap(tester, const Key('earn-support-close'));
    await tap(tester, const Key('earn-work-continue-proof'));
    expect(location(tester), '/app/earn/proof');
  });

  testWidgets('screen 136 covers proof invalid, help and exact outcome retry', (
    tester,
  ) async {
    final gateway = ReviewOperationsGateway()..failOutcome = true;
    final session = OperationsSession(gateway: gateway);
    await mount(tester, route: '/app/earn/proof', operationsSession: session);
    await tap(tester, const Key('earn-proof-help'));
    await tap(tester, const Key('earn-proof-help-close'));
    await tap(tester, const Key('earn-proof-owner-otp'));
    await tap(tester, const Key('earn-proof-truth'));
    await tap(tester, const Key('earn-proof-submit'));
    expect(gateway.outcomeCalls, 0);
    await tap(tester, const Key('earn-proof-owner-otp'));
    await tap(tester, const Key('earn-proof-truth'));
    await tap(tester, const Key('earn-proof-submit'));
    expect(session.outcomeId, isNull);
    await tap(tester, const Key('earn-proof-submit'));
    expect(session.outcomeId, 'EARN-OUTCOME-136-4821');
    expect(gateway.outcomeCalls, 2);
    await tap(tester, const Key('earn-outcome-open-earnings'));
    expect(location(tester), '/app/earn/earnings');
  });

  testWidgets(
    'screens 137 and 138 cover ledger, statement and all history owners',
    (tester) async {
      final gateway = ReviewOperationsGateway()..failStatement = true;
      final session = OperationsSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/earn/earnings',
        operationsSession: session,
      );
      for (final id in [
        'retailer-4818',
        'qr-4807',
        'retailer-4821',
        'payout-0710',
      ]) {
        await tap(tester, Key('earn-ledger-$id'));
        await tap(tester, const Key('earn-ledger-close'));
      }
      await tap(tester, const Key('earn-statement-open'));
      await tap(tester, const Key('earn-statement-prepare'));
      expect(session.statementId, isNull);
      await tap(tester, const Key('earn-statement-prepare'));
      expect(session.statementId, 'EARN-STMT-137-0719');
      expect(gateway.statementCalls, 2);
      await tap(tester, const Key('earn-statement-prepare'));
      expect(gateway.statementCalls, 2);
      await tap(tester, const Key('earn-statement-close'));
      await tap(tester, const Key('earn-open-history'));
      for (final tab in EarnHistoryTab.values) {
        await tap(tester, Key('earn-history-tab-${tab.name}'));
        expect(session.historyTab, tab);
      }
      await tap(tester, const Key('earn-history-tab-history'));
      await tap(tester, const Key('earn-history-4818'));
      await tap(tester, const Key('earn-record-close'));
    },
  );

  testWidgets('screen 139 opens every provider workspace owner route', (
    tester,
  ) async {
    await mount(tester, route: '/app/provider');
    final routes = <Key, String>{
      const Key('provider-home-requests'): '/app/provider/requests',
      const Key('provider-home-services'): '/app/provider/catalogue',
      const Key('provider-home-availability'): '/app/provider/availability',
      const Key('provider-home-business'): '/app/provider/business',
      const Key('provider-priority-request'): '/app/provider/requests',
      const Key('provider-priority-capacity'): '/app/provider/availability',
      const Key('provider-priority-readiness'): '/app/provider/control',
      const Key('provider-home-growth'): '/app/provider/growth',
      const Key('provider-home-controls'): '/app/provider/control',
    };
    for (final entry in routes.entries) {
      await go(tester, '/app/provider');
      await tap(tester, entry.key);
      expect(location(tester), entry.value);
    }
  });

  testWidgets(
    'screen 140 covers service states, preview, invalid and save retry',
    (tester) async {
      final gateway = ReviewOperationsGateway()..failServiceSave = true;
      final session = OperationsSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/provider/catalogue',
        operationsSession: session,
      );
      for (final tab in ProviderCatalogueTab.values) {
        await tap(tester, Key('provider-catalogue-tab-${tab.name}'));
        expect(session.catalogueTab, tab);
      }
      await tap(tester, const Key('provider-catalogue-tab-live'));
      await tap(tester, const Key('provider-service-standard-preview'));
      await tap(tester, const Key('provider-service-preview-close'));
      await tap(tester, const Key('provider-service-add'));
      await tap(tester, const Key('provider-service-save'));
      expect(gateway.serviceSaveCalls, 0);
      await enter(tester, const Key('provider-service-name'), 'Home visit');
      await enter(tester, const Key('provider-service-price'), '650');
      await enter(tester, const Key('provider-service-time'), '60');
      await enter(
        tester,
        const Key('provider-service-scope'),
        'One verified home visit with completion receipt.',
      );
      await tap(tester, const Key('provider-service-save'));
      expect(session.serviceId, isNull);
      await tap(tester, const Key('provider-service-save'));
      expect(session.serviceId, 'PROV-SVC-140-0719');
      expect(gateway.serviceSaveCalls, 2);
      await tap(tester, const Key('provider-service-save'));
      expect(gateway.serviceSaveCalls, 2);
      await tap(tester, const Key('provider-service-close'));
    },
  );

  testWidgets(
    'screen 141 covers day, safe pause and exact availability retry',
    (tester) async {
      final gateway = ReviewOperationsGateway()..failAvailability = true;
      final session = OperationsSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/provider/availability',
        operationsSession: session,
      );
      await tap(tester, const Key('provider-day-monday'));
      await tap(tester, const Key('provider-day-save'));
      await tap(tester, const Key('provider-availability-pause'));
      await tap(tester, const Key('provider-pause-2-hours'));
      await tap(tester, const Key('provider-pause-apply'));
      expect(session.acceptNewDemand, isFalse);
      await tap(tester, const Key('provider-availability-save'));
      expect(session.availabilityId, isNull);
      await tap(tester, const Key('provider-availability-save'));
      expect(session.availabilityId, 'PROV-CAP-141-0719');
      expect(gateway.availabilityCalls, 2);
    },
  );

  testWidgets(
    'screen 142 covers tabs, failed accept and decline exact replays',
    (tester) async {
      final gateway = ReviewOperationsGateway()
        ..failRequestAccept = true
        ..failRequestDecline = true;
      final session = OperationsSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/provider/requests',
        operationsSession: session,
      );
      for (final tab in ProviderRequestTab.values) {
        await tap(tester, Key('provider-request-tab-${tab.name}'));
        expect(session.requestTab, tab);
      }
      await tap(tester, const Key('provider-request-tab-newRequests'));
      await tap(tester, const Key('provider-request-RQ-2401-accept'));
      await tap(tester, const Key('provider-request-accept'));
      expect(gateway.requestAcceptCalls, 0);
      await tap(tester, const Key('provider-request-terms'));
      await tap(tester, const Key('provider-request-accept'));
      expect(session.requestAcceptanceId, isNull);
      await tap(tester, const Key('provider-request-accept'));
      expect(session.requestAcceptanceId, 'PROV-ACCEPT-142-RQ-2401');
      expect(gateway.requestAcceptCalls, 2);
      expect(location(tester), '/app/provider/fulfilment');

      await go(tester, '/app/provider/requests');
      await tap(tester, const Key('provider-request-RQ-2402-decline'));
      await tap(tester, const Key('provider-request-decline'));
      expect(gateway.requestDeclineCalls, 0);
      await enter(
        tester,
        const Key('provider-request-decline-reason'),
        'No capacity at this time',
      );
      await tap(tester, const Key('provider-request-decline'));
      expect(session.requestDeclineId, isNull);
      await tap(tester, const Key('provider-request-decline'));
      expect(session.requestDeclineId, 'PROV-DECLINE-142-RQ-2402');
      expect(gateway.requestDeclineCalls, 2);
    },
  );

  testWidgets('screen 143 covers message, privacy and exact completion retry', (
    tester,
  ) async {
    final gateway = ReviewOperationsGateway()..failFulfilment = true;
    final session = OperationsSession(gateway: gateway);
    await mount(
      tester,
      route: '/app/provider/fulfilment',
      operationsSession: session,
    );
    await tap(tester, const Key('provider-message-customer'));
    await tap(tester, const Key('provider-message-send'));
    await tap(tester, const Key('provider-fulfilment-privacy'));
    await tap(tester, const Key('provider-privacy-close'));
    await tap(tester, const Key('provider-fulfilment-complete'));
    expect(gateway.fulfilmentCalls, 0);
    await tap(tester, const Key('provider-arrival-confirm'));
    await tap(tester, const Key('provider-outcome-confirm'));
    await tap(tester, const Key('provider-fulfilment-complete'));
    expect(session.fulfilmentId, isNull);
    await tap(tester, const Key('provider-fulfilment-complete'));
    expect(session.fulfilmentId, 'PROV-DONE-143-2401');
    expect(gateway.fulfilmentCalls, 2);
    await tap(tester, const Key('provider-fulfilment-open-money'));
    expect(location(tester), '/app/provider/business');
  });

  testWidgets('screen 144 covers tabs, records and exact export retry', (
    tester,
  ) async {
    final gateway = ReviewOperationsGateway()..failExport = true;
    final session = OperationsSession(gateway: gateway);
    await mount(
      tester,
      route: '/app/provider/business',
      operationsSession: session,
    );
    for (final tab in ProviderBusinessTab.values) {
      await tap(tester, Key('provider-business-tab-${tab.name}'));
      expect(session.businessTab, tab);
    }
    for (final id in ['payment-2401', 'receipt-2941', 'expected-2402']) {
      await tap(tester, Key('provider-business-$id'));
      await tap(tester, const Key('provider-business-record-close'));
    }
    await tap(tester, const Key('provider-export-open'));
    await tap(tester, const Key('provider-export-receipts'));
    await tap(tester, const Key('provider-export-generate'));
    expect(session.exportId, isNull);
    await tap(tester, const Key('provider-export-generate'));
    expect(session.exportId, 'PROV-EXPORT-144-RECEIPTS');
    expect(gateway.exportCalls, 2);
    await tap(tester, const Key('provider-export-generate'));
    expect(gateway.exportCalls, 2);
  });

  testWidgets('screen 145 covers filters, each model and exact funded retry', (
    tester,
  ) async {
    final gateway = ReviewOperationsGateway()..failGrowthAccept = true;
    final session = OperationsSession(gateway: gateway);
    await mount(
      tester,
      route: '/app/provider/growth',
      operationsSession: session,
    );
    for (final tab in ProviderGrowthTab.values) {
      await tap(tester, Key('provider-growth-tab-${tab.name}'));
      expect(session.growthTab, tab);
    }
    await tap(tester, const Key('provider-growth-campaign-review'));
    expect(find.text('Submit Growth Campaign'), findsOneWidget);
    await tap(tester, const Key('provider-growth-accept'));
    expect(gateway.growthAcceptCalls, 0);
    await tap(tester, const Key('provider-growth-terms'));
    await tap(tester, const Key('provider-growth-accept'));
    expect(session.growthAcceptanceId, isNull);
    await tap(tester, const Key('provider-growth-accept'));
    expect(session.growthAcceptanceId, 'PROV-GROW-145-campaign');
    expect(
      session.noticeMessage,
      'Growth campaign submitted. No charge is made until final confirmation.',
    );
    expect(gateway.growthAcceptCalls, 2);
    await tap(tester, const Key('provider-growth-accept'));
    expect(gateway.growthAcceptCalls, 2);
  });

  testWidgets(
    'screen 146 covers every control, exact save and support retries',
    (tester) async {
      final gateway = ReviewOperationsGateway()
        ..failControls = true
        ..failProviderSupport = true;
      final session = OperationsSession(gateway: gateway);
      await mount(
        tester,
        route: '/app/provider/control',
        operationsSession: session,
      );
      for (final id in [
        'identity',
        'document',
        'payment',
        'owner',
        'operations',
        'accounts',
      ]) {
        await tap(tester, Key('provider-control-$id'));
        await tap(tester, const Key('provider-control-detail-close'));
      }
      await tap(tester, const Key('provider-toggle-alerts'));
      await tap(tester, const Key('provider-toggle-capacity'));
      await tap(tester, const Key('provider-toggle-reminders'));
      await tap(tester, const Key('provider-control-save'));
      expect(session.controlsVersionId, isNull);
      await tap(tester, const Key('provider-control-save'));
      expect(session.controlsVersionId, 'PROV-CONTROL-146-0719');
      expect(gateway.controlsCalls, 2);

      await tap(tester, const Key('provider-control-support'));
      await tap(tester, const Key('provider-support-submit'));
      expect(gateway.providerSupportCalls, 0);
      await enter(
        tester,
        const Key('provider-support-details'),
        'Operations staff cannot open today requests.',
      );
      await tap(tester, const Key('provider-support-submit'));
      expect(session.providerSupportId, isNull);
      await tap(tester, const Key('provider-support-submit'));
      expect(session.providerSupportId, 'SUP-146-2048');
      expect(gateway.providerSupportCalls, 2);
    },
  );

  testWidgets('offline and permission-denied commands preserve outcomes', (
    tester,
  ) async {
    final gateway = ReviewOperationsGateway();
    final session = OperationsSession(gateway: gateway)
      ..opportunityTermsAccepted = true
      ..selectedOpportunityId = 'retailer'
      ..selectedApplication = 'approved'
      ..outcomeTruthConfirmed = true
      ..serviceName = 'Service'
      ..servicePrice = '500'
      ..serviceTime = '60'
      ..serviceScope = 'Complete customer service and receipt'
      ..pauseConfirmed = true
      ..selectedRequestId = 'RQ-2401'
      ..requestTermsConfirmed = true
      ..arrivalConfirmed = true
      ..outcomeCompleted = true
      ..selectedGrowthId = 'serve'
      ..growthTermsAccepted = true
      ..providerSupportDetails = 'A complete support description';
    await mount(tester, route: '/app/earn', operationsSession: session);
    session.setOnline(false);
    expect(await tester.runAsync(session.applyOpportunity), isFalse);
    expect(await tester.runAsync(session.startApprovedWork), isFalse);
    expect(await tester.runAsync(session.submitOutcome), isFalse);
    expect(await tester.runAsync(session.saveService), isFalse);
    expect(await tester.runAsync(session.saveAvailability), isFalse);
    expect(await tester.runAsync(session.acceptRequest), isFalse);
    expect(await tester.runAsync(session.completeFulfilment), isFalse);
    expect(await tester.runAsync(session.acceptGrowth), isFalse);
    expect(await tester.runAsync(session.saveControls), isFalse);
    expect(await tester.runAsync(session.openProviderSupport), isFalse);
    session.setOnline(true);
    session.authorized = false;
    expect(await tester.runAsync(session.prepareStatement), isFalse);
    expect([
      gateway.applicationCalls,
      gateway.workStartCalls,
      gateway.outcomeCalls,
      gateway.serviceSaveCalls,
      gateway.availabilityCalls,
      gateway.requestAcceptCalls,
      gateway.fulfilmentCalls,
      gateway.growthAcceptCalls,
      gateway.controlsCalls,
      gateway.providerSupportCalls,
      gateway.statementCalls,
    ], everyElement(0));
  });
}
