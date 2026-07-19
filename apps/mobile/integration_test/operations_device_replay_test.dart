import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/operations/operations_services.dart';
import 'package:moolsocial/features/operations/operations_session.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
      expect(scrollables, findsWidgets, reason: 'No scrollable for $key');
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
    await tester.pumpAndSettle();
    return finder;
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    await tester.tap(await reveal(tester, key));
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, Key key, String value) async {
    await tester.enterText(await reveal(tester, key), value);
    await tester.pumpAndSettle();
  }

  Future<void> openRoute(WidgetTester tester, String route) async {
    tester.element(find.byType(Scaffold).first).go(route);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'physical Earn and provider operations replay every original failed command',
    (tester) async {
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
      final gateway = ReviewOperationsGateway()
        ..failApplication = true
        ..failWorkStart = true
        ..failEarnSupport = true
        ..failOutcome = true
        ..failStatement = true
        ..failServiceSave = true
        ..failAvailability = true
        ..failRequestAccept = true
        ..failFulfilment = true
        ..failExport = true
        ..failGrowthAccept = true
        ..failControls = true
        ..failProviderSupport = true;
      final operations = OperationsSession(gateway: gateway);
      addTearDown(journey.dispose);
      addTearDown(operations.dispose);
      await journey.start();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          operationsSession: operations,
          initialLocation: '/app/earn',
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('earn-opportunities-screen')),
        findsOneWidget,
      );
      await binding.takeScreenshot('operations-133-funded-work');
      await tapVisible(tester, const Key('earn-opportunity-retailer'));
      await tapVisible(tester, const Key('earn-opportunity-apply'));
      expect(gateway.applicationCalls, 0);
      await tapVisible(tester, const Key('earn-opportunity-terms'));
      await tapVisible(tester, const Key('earn-opportunity-apply'));
      expect(operations.applicationId, isNull);
      await tapVisible(tester, const Key('earn-opportunity-apply'));
      expect(operations.applicationId, 'EARN-APP-133-retailer');
      expect(gateway.applicationCalls, 2);
      await tapVisible(tester, const Key('earn-opportunity-open-work'));

      await tapVisible(tester, const Key('earn-application-approved'));
      await tapVisible(tester, const Key('earn-work-start'));
      expect(operations.workStartId, isNull);
      await tapVisible(tester, const Key('earn-work-start'));
      expect(operations.workStartId, 'WRK-4821');
      expect(gateway.workStartCalls, 2);

      await tapVisible(tester, const Key('earn-work-support'));
      await enter(
        tester,
        const Key('earn-support-details'),
        'The business is closed and I need a safe reschedule.',
      );
      await tapVisible(tester, const Key('earn-support-submit'));
      expect(operations.earnSupportId, isNull);
      await tapVisible(tester, const Key('earn-support-submit'));
      expect(operations.earnSupportId, 'EARN-CASE-135-4821');
      expect(gateway.earnSupportCalls, 2);
      await tapVisible(tester, const Key('earn-support-close'));
      await tapVisible(tester, const Key('earn-work-continue-proof'));

      await tapVisible(tester, const Key('earn-proof-truth'));
      await tapVisible(tester, const Key('earn-proof-submit'));
      expect(operations.outcomeId, isNull);
      await tapVisible(tester, const Key('earn-proof-submit'));
      expect(operations.outcomeId, 'EARN-OUTCOME-136-4821');
      expect(gateway.outcomeCalls, 2);
      await tapVisible(tester, const Key('earn-outcome-open-earnings'));
      await tapVisible(tester, const Key('earn-statement-open'));
      await tapVisible(tester, const Key('earn-statement-prepare'));
      expect(operations.statementId, isNull);
      await tapVisible(tester, const Key('earn-statement-prepare'));
      expect(operations.statementId, 'EARN-STMT-137-0719');
      expect(gateway.statementCalls, 2);
      await tapVisible(tester, const Key('earn-statement-close'));

      await openRoute(tester, '/app/provider/catalogue');
      await tapVisible(tester, const Key('provider-service-add'));
      await enter(
        tester,
        const Key('provider-service-name'),
        'Verified home visit',
      );
      await enter(tester, const Key('provider-service-price'), '650');
      await enter(tester, const Key('provider-service-time'), '60');
      await enter(
        tester,
        const Key('provider-service-scope'),
        'One verified home visit with completion receipt.',
      );
      await tapVisible(tester, const Key('provider-service-save'));
      expect(operations.serviceId, isNull);
      await tapVisible(tester, const Key('provider-service-save'));
      expect(operations.serviceId, 'PROV-SVC-140-0719');
      expect(gateway.serviceSaveCalls, 2);
      await tapVisible(tester, const Key('provider-service-close'));

      await openRoute(tester, '/app/provider/availability');
      await tapVisible(tester, const Key('provider-availability-save'));
      expect(operations.availabilityId, isNull);
      await tapVisible(tester, const Key('provider-availability-save'));
      expect(operations.availabilityId, 'PROV-CAP-141-0719');
      expect(gateway.availabilityCalls, 2);

      await openRoute(tester, '/app/provider/requests');
      await tapVisible(tester, const Key('provider-request-RQ-2401-accept'));
      await tapVisible(tester, const Key('provider-request-terms'));
      await tapVisible(tester, const Key('provider-request-accept'));
      expect(operations.requestAcceptanceId, isNull);
      await tapVisible(tester, const Key('provider-request-accept'));
      expect(operations.requestAcceptanceId, 'PROV-ACCEPT-142-RQ-2401');
      expect(gateway.requestAcceptCalls, 2);

      await tapVisible(tester, const Key('provider-arrival-confirm'));
      await tapVisible(tester, const Key('provider-outcome-confirm'));
      await tapVisible(tester, const Key('provider-fulfilment-complete'));
      expect(operations.fulfilmentId, isNull);
      await tapVisible(tester, const Key('provider-fulfilment-complete'));
      expect(operations.fulfilmentId, 'PROV-DONE-143-2401');
      expect(gateway.fulfilmentCalls, 2);
      await binding.takeScreenshot('operations-143-outcome-complete');
      await tapVisible(tester, const Key('provider-fulfilment-open-money'));

      await tapVisible(tester, const Key('provider-export-open'));
      await tapVisible(tester, const Key('provider-export-receipts'));
      await tapVisible(tester, const Key('provider-export-generate'));
      expect(operations.exportId, isNull);
      await tapVisible(tester, const Key('provider-export-generate'));
      expect(operations.exportId, 'PROV-EXPORT-144-RECEIPTS');
      expect(gateway.exportCalls, 2);
      await tapVisible(tester, const Key('provider-export-close'));

      await openRoute(tester, '/app/provider/growth');
      await tapVisible(tester, const Key('provider-growth-campaign-review'));
      expect(find.text('Submit Growth Campaign'), findsOneWidget);
      await tapVisible(tester, const Key('provider-growth-terms'));
      await tapVisible(tester, const Key('provider-growth-accept'));
      expect(operations.growthAcceptanceId, isNull);
      await tapVisible(tester, const Key('provider-growth-accept'));
      expect(operations.growthAcceptanceId, 'PROV-GROW-145-campaign');
      expect(gateway.growthAcceptCalls, 2);
      await binding.takeScreenshot('operations-145-growth-submitted');
      await tapVisible(tester, const Key('provider-growth-close'));

      await openRoute(tester, '/app/provider/control');
      await tapVisible(tester, const Key('provider-toggle-reminders'));
      await tapVisible(tester, const Key('provider-control-save'));
      expect(operations.controlsVersionId, isNull);
      await tapVisible(tester, const Key('provider-control-save'));
      expect(operations.controlsVersionId, 'PROV-CONTROL-146-0719');
      expect(gateway.controlsCalls, 2);
      await tapVisible(tester, const Key('provider-control-support'));
      await enter(
        tester,
        const Key('provider-support-details'),
        'Operations staff cannot open today requests.',
      );
      await tapVisible(tester, const Key('provider-support-submit'));
      expect(operations.providerSupportId, isNull);
      await tapVisible(tester, const Key('provider-support-submit'));
      expect(operations.providerSupportId, 'SUP-146-2048');
      expect(gateway.providerSupportCalls, 2);
      await binding.takeScreenshot('operations-146-support-open');

      expect([
        gateway.applicationCalls,
        gateway.workStartCalls,
        gateway.earnSupportCalls,
        gateway.outcomeCalls,
        gateway.statementCalls,
        gateway.serviceSaveCalls,
        gateway.availabilityCalls,
        gateway.requestAcceptCalls,
        gateway.fulfilmentCalls,
        gateway.exportCalls,
        gateway.growthAcceptCalls,
        gateway.controlsCalls,
        gateway.providerSupportCalls,
      ], everyElement(2));
    },
  );
}
