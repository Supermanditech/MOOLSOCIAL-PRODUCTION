import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/book/book_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
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

  test('runtime Book choices match the versioned R08 contract', () {
    final contractFile = File.fromUri(
      Directory.current.uri.resolve(
        '../../config/mvp-personal-book-exposure-interaction-v1.json',
      ),
    );
    final contract = jsonDecode(contractFile.readAsStringSync()) as Map;
    final actions = (contract['actions'] as List).cast<Map>();

    expect(
      personalBookActionChoices
          .map((action) => [action.id, action.label, action.route])
          .toList(),
      actions
          .map((action) => [action['id'], action['label'], action['route']])
          .toList(),
    );
    expect(personalBookActionChoices.map((action) => action.id), [
      'doctor',
      'salon',
    ]);
    expect(contract['excludedActions'], [
      'get_it_done',
      'clinic',
      'hospital',
      'home_beauty',
    ]);
    expect(contract['presentationOwner'], 'MvpActionChoiceRootV2');
    expect(contract['newScreenOwners'], 0);
    expect(contract['newRouteOwners'], 0);
    expect(contract['newBackendOwners'], 0);
  });

  for (final destination in const [
    (id: 'doctor', ownerKey: Key('book-doctor')),
    (id: 'medicine', ownerKey: ValueKey('buy-v2-screen')),
    (id: 'salon', ownerKey: Key('review-salon-slot')),
  ]) {
    testWidgets(
      'production Care root opens Doctor and ${destination.id} stays connected',
      (tester) async {
        final journey = signedInSession();
        final book = BookSession();
        addTearDown(journey.dispose);
        addTearDown(book.dispose);
        await journey.start();

        await tester.pumpWidget(
          MoolSocialApp(
            session: journey,
            bookSession: book,
            initialLocation: '/app/book',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('book-doctor')), findsOneWidget);
        expect(
          find.byKey(const Key('care-book-local-navigation')),
          findsOneWidget,
        );
        for (final action in const ['doctor', 'medicine', 'salon']) {
          expect(find.byKey(Key('care-local-$action')), findsOneWidget);
        }
        expect(find.byKey(const Key('care-local-bus')), findsNothing);
        expect(find.byKey(const Key('mvp-action-root-book')), findsNothing);
        expect(find.byKey(const Key('book-local-get-it-done')), findsNothing);
        expect(find.byKey(const Key('book-local-clinic')), findsNothing);
        expect(find.byKey(const Key('book-local-hospital')), findsNothing);
        expect(find.byKey(const Key('book-local-home-beauty')), findsNothing);

        if (destination.id != 'doctor') {
          await tester.tap(find.byKey(Key('care-local-${destination.id}')));
          await tester.pumpAndSettle();
        }

        expect(find.byKey(destination.ownerKey), findsOneWidget);

        expect(find.byKey(const Key('mvp-action-root-book')), findsNothing);

        expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
      },
    );
  }

  for (final destination in const [
    (
      id: 'doctor',
      route: '/app/book/doctor',
      ownerKey: Key('book-doctor'),
      localNavigationKey: Key('care-book-local-navigation'),
    ),
    (
      id: 'medicine',
      route: '/app/buy?sub=medicine',
      ownerKey: ValueKey('buy-v2-screen'),
      localNavigationKey: ValueKey('care-local-destination-tabs'),
    ),
    (
      id: 'salon',
      route: '/app/book/salon',
      ownerKey: Key('review-salon-slot'),
      localNavigationKey: Key('care-book-local-navigation'),
    ),
  ]) {
    testWidgets(
      'direct ${destination.id} exposes its owner and connected launcher',
      (tester) async {
        final journey = signedInSession();
        final book = BookSession();
        addTearDown(journey.dispose);
        addTearDown(book.dispose);
        await journey.start();

        await tester.pumpWidget(
          MoolSocialApp(
            session: journey,
            bookSession: book,
            initialLocation: destination.route,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(destination.ownerKey), findsOneWidget);
        expect(find.byKey(const Key('book-local-navigation')), findsNothing);
        expect(find.byKey(destination.localNavigationKey), findsOneWidget);
        expect(find.byKey(const Key('mool-compact-launcher')), findsOneWidget);
        expect(find.byKey(const Key('mvp-action-root-book')), findsNothing);
      },
    );
  }

  testWidgets('Book chooser Back restores the exact default owner', (
    tester,
  ) async {
    final journey = signedInSession();
    final book = BookSession();
    addTearDown(journey.dispose);
    addTearDown(book.dispose);
    await journey.start();

    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        bookSession: book,
        initialLocation: '/app/book',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('book-doctor')), findsOneWidget);

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('book-doctor')), findsOneWidget);
    expect(find.byKey(const Key('book-local-navigation')), findsNothing);
    expect(find.byKey(const Key('care-book-local-navigation')), findsOneWidget);
  });
}
