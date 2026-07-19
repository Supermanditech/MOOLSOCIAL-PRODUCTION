import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/operations/operations_session.dart';

void main() {
  Future<void> verifyScreen(
    WidgetTester tester, {
    required String route,
    required String golden,
    void Function(OperationsSession session)? prepare,
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
    final operations = OperationsSession();
    prepare?.call(operations);
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
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold).first, matchesGoldenFile(golden));
  }

  final screens = <(String, String, String)>[
    ('Earn opportunities 133', '/app/earn', 'earn-133-opportunities'),
    (
      'Earn applications 134',
      '/app/earn/applications',
      'earn-134-applications',
    ),
    ('Earn active work 135', '/app/earn/active', 'earn-135-active-work'),
    ('Earn proof 136', '/app/earn/proof', 'earn-136-proof'),
    ('Earn earnings 137', '/app/earn/earnings', 'earn-137-earnings'),
    ('Earn history 138', '/app/earn/history', 'earn-138-history'),
    ('Provider home 139', '/app/provider', 'provider-139-home'),
    (
      'Provider catalogue 140',
      '/app/provider/catalogue',
      'provider-140-catalogue',
    ),
    (
      'Provider availability 141',
      '/app/provider/availability',
      'provider-141-availability',
    ),
    (
      'Provider requests 142',
      '/app/provider/requests',
      'provider-142-requests',
    ),
    (
      'Provider fulfilment 143',
      '/app/provider/fulfilment',
      'provider-143-fulfilment',
    ),
    (
      'Provider business 144',
      '/app/provider/business',
      'provider-144-business',
    ),
    ('Provider growth 145', '/app/provider/growth', 'provider-145-growth'),
    ('Provider control 146', '/app/provider/control', 'provider-146-control'),
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
}
