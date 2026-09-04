import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/ui_v2/universal/mvp_action_choice_root_v2.dart';

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

  test('runtime Work choices match the versioned R10 contract', () {
    final contractFile = File.fromUri(
      Directory.current.uri.resolve(
        '../../config/mvp-personal-work-exposure-interaction-v1.json',
      ),
    );
    final contract = jsonDecode(contractFile.readAsStringSync()) as Map;
    final actions = (contract['actions'] as List).cast<Map>();

    expect(
      personalWorkActionChoices
          .map((action) => [action.id, action.label, action.route])
          .toList(),
      actions
          .map((action) => [action['id'], action['label'], action['route']])
          .toList(),
    );
    expect(personalWorkActionChoices.map((action) => action.id), [
      'earn-today',
      'workspace',
    ]);
    expect(contract['excludedActions'], ['delivery_work', 'onboard', 'verify']);
    expect(contract['newScreenOwners'], 0);
    expect(contract['newRouteOwners'], 0);
    expect(contract['newBackendOwners'], 0);
  });

  for (final destination in const [
    (id: 'earn', ownerKey: Key('work-earn-screen'), label: 'Earn Today'),
    (id: 'workspace', ownerKey: Key('work-choose-screen'), label: 'Workspace'),
  ]) {
    testWidgets(
      'production Work root reaches ${destination.label} in one connected tap',
      (tester) async {
        final journey = signedInSession();
        final work = WorkSession();
        addTearDown(journey.dispose);
        addTearDown(work.dispose);
        await journey.start();

        await tester.pumpWidget(
          MoolSocialApp(
            session: journey,
            workSession: work,
            initialLocation: '/app/work',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
        expect(find.byKey(const Key('work-local-navigation')), findsOneWidget);
        expect(find.byKey(const Key('work-local-earn')), findsOneWidget);
        expect(find.byKey(const Key('work-local-workspace')), findsOneWidget);
        expect(find.byKey(const Key('mvp-action-root-work')), findsNothing);
        expect(find.text('Delivery Work'), findsNothing);
        expect(find.text('Onboard'), findsNothing);
        expect(find.text('Verify'), findsNothing);

        if (destination.id != 'earn') {
          await tester.tap(find.byKey(Key('work-local-${destination.id}')));
          await tester.pumpAndSettle();
        }

        expect(find.byKey(destination.ownerKey), findsOneWidget);
        expect(find.text(destination.label), findsWidgets);
        expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final destination in const [
    (route: '/app/work/earn', ownerKey: Key('work-earn-screen')),
    (route: '/app/work/my-work', ownerKey: Key('work-choose-screen')),
  ]) {
    testWidgets(
      'direct ${destination.route} exposes its owner and connected launcher',
      (tester) async {
        final journey = signedInSession();
        final work = WorkSession();
        addTearDown(journey.dispose);
        addTearDown(work.dispose);
        await journey.start();

        await tester.pumpWidget(
          MoolSocialApp(
            session: journey,
            workSession: work,
            initialLocation: destination.route,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(destination.ownerKey), findsOneWidget);
        expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
        expect(find.byKey(const Key('work-local-navigation')), findsOneWidget);
        expect(find.byKey(const Key('work-local-earn')), findsOneWidget);
        expect(find.byKey(const Key('work-local-workspace')), findsOneWidget);
        expect(find.byKey(const Key('mvp-action-root-work')), findsNothing);
      },
    );
  }

  testWidgets('Work chooser Back restores the exact unchanged owner', (
    tester,
  ) async {
    final journey = signedInSession();
    final work = WorkSession();
    addTearDown(journey.dispose);
    addTearDown(work.dispose);
    await journey.start();

    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        workSession: work,
        initialLocation: '/app/work/earn',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );
    expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
    expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
  });
}
