import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mountSocial(WidgetTester tester) async {
    final journey = JourneySession(
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
    addTearDown(journey.dispose);
    await journey.start();
    await tester.pumpWidget(
      MoolSocialApp(session: journey, initialLocation: '/app/social'),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openWorkAction(WidgetTester tester, String action) async {
    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mool-navigator-family-work')));
    await tester.pumpAndSettle();
    if (action != 'earn') {
      await tester.tap(find.byKey(Key('work-local-$action')));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('Social Work opens the exact canonical Earn owner', (
    tester,
  ) async {
    await mountSocial(tester);
    await openWorkAction(tester, 'earn');

    expect(find.byKey(const Key('work-earn-screen')), findsOneWidget);
    expect(find.byKey(const Key('work-local-earn')), findsOneWidget);
    expect(find.byKey(const Key('work-local-workspace')), findsOneWidget);
    expect(find.byKey(const Key('mool-root-selected')), findsNothing);
    expect(find.byKey(const Key('mvp-action-root-work')), findsNothing);
    expect(find.text('Delivery Work'), findsNothing);
    expect(find.text('Onboard'), findsNothing);
    expect(find.text('Verify'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Social Work Workspace opens its existing exact owner', (
    tester,
  ) async {
    await mountSocial(tester);
    await openWorkAction(tester, 'workspace');

    expect(find.byKey(const Key('my-work-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
