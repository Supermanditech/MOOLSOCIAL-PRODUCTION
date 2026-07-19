import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';

void main() {
  Future<void> verifyScreen(
    WidgetTester tester, {
    required String route,
    required String golden,
    Future<void> Function(WidgetTester tester)? prepare,
    bool captureOverlay = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
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
    final shared = SharedSession();
    await journey.start();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      shared.dispose();
    });
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        sharedSession: shared,
        initialLocation: route,
      ),
    );
    await tester.pumpAndSettle();
    await prepare?.call(tester);
    await tester.pumpAndSettle();
    await expectLater(
      captureOverlay ? find.byType(Overlay).first : find.byType(Scaffold).first,
      matchesGoldenFile(golden),
    );
  }

  final screens = <(String, String, String)>[
    ('Activity 157', '/app/activity', 'shared-157-activity'),
    ('Identity 158', '/app/account/identity', 'shared-158-identity'),
    ('Ask 159', '/app/ask', 'shared-159-ask'),
    ('Files 160', '/app/files', 'shared-160-files'),
    ('Security 161', '/app/account/security', 'shared-161-security'),
    ('Workspaces 162', '/app/account/workspaces', 'shared-162-workspaces'),
    (
      'Controls 165',
      '/app/account/workspaces/preferences',
      'shared-165-controls',
    ),
  ];

  for (final screen in screens) {
    testWidgets('${screen.$1} phone visual baseline', (tester) async {
      await verifyScreen(
        tester,
        route: screen.$2,
        golden: 'goldens/${screen.$3}-412x915.png',
      );
    });
  }

  testWidgets('Activity nested intent phone visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/activity',
      golden: 'goldens/shared-157-activity-detail-412x915.png',
      captureOverlay: true,
      prepare: (tester) async {
        await tester.tap(
          find.byKey(const Key('shared-157-item-pharmacy-renewal')),
        );
      },
    );
  });

  testWidgets('Ask exact result phone visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/ask',
      golden: 'goldens/shared-159-ask-result-412x915.png',
      prepare: (tester) async {
        await tester.enterText(
          find.byKey(const Key('shared-159-input')),
          'atta under ₹300 delivered today',
        );
        await tester.tap(find.byKey(const Key('shared-159-submit')));
      },
    );
  });

  testWidgets('Controls nested intent phone visual baseline', (tester) async {
    await verifyScreen(
      tester,
      route: '/app/account/workspaces/preferences',
      golden: 'goldens/shared-165-controls-detail-412x915.png',
      captureOverlay: true,
      prepare: (tester) async {
        final list = find.byKey(const Key('shared-165-list'));
        for (
          var attempt = 0;
          attempt < 5 &&
              find
                  .byKey(const Key('shared-165-item-creator'))
                  .evaluate()
                  .isEmpty;
          attempt += 1
        ) {
          await tester.drag(list, const Offset(0, -260));
          await tester.pumpAndSettle();
        }
        await tester.drag(list, const Offset(0, -180));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('shared-165-item-creator')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('shared-165-detail-creator')),
          findsOneWidget,
        );
      },
    );
  });
}
