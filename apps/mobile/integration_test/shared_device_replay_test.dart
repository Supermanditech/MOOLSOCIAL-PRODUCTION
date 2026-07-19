import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/shared/shared_services.dart';
import 'package:moolsocial/features/shared/shared_session.dart';

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
          attempt < 80 && finder.evaluate().isEmpty;
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

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(await reveal(tester, key));
    await tester.pumpAndSettle();
  }

  Future<void> go(WidgetTester tester, String route) async {
    tester.element(find.byType(Scaffold).first).go(route);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'physical shared controls replay invalid, denied, failure, retry and duplicate',
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
      final gateway = ReviewSharedGateway();
      final shared = SharedSession(gateway: gateway);
      addTearDown(journey.dispose);
      addTearDown(shared.dispose);
      await journey.start();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          sharedSession: shared,
          initialLocation: '/app/ask',
        ),
      );
      await tester.pumpAndSettle();
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();

      await tap(tester, const Key('shared-159-submit'));
      expect(gateway.calls, isEmpty);
      shared.microphoneAllowed = false;
      await tap(tester, const Key('shared-159-voice'));
      await tap(tester, const Key('shared-microphone-use-keyboard'));
      shared.microphoneAllowed = true;
      await tap(tester, const Key('shared-159-voice'));
      expect(shared.input, contains('atta'));

      gateway
        ..failNext = true
        ..failActionId = 'SHARED-159-ASK-BUY';
      await tap(tester, const Key('shared-159-submit'));
      expect(shared.inputResult, isNull);
      await tap(tester, const Key('shared-159-submit'));
      expect(shared.inputResult?.route, '/app/buy/grocery');
      expect(gateway.calls['SHARED-159-ASK-BUY'], 2);
      await binding.takeScreenshot('shared-159-exact-ask-result');

      await go(tester, '/app/files');
      await tap(tester, const Key('shared-160-top-action'));
      await tap(tester, const Key('shared-file-add-gallery'));
      expect(shared.noticeMessage, contains('opened'));

      await go(tester, '/app/account/security');
      shared.setAuthorized(false);
      await tap(tester, const Key('shared-161-item-emergency-lock'));
      await tap(tester, const Key('shared-161-emergency-lock-confirm-primary'));
      await tap(tester, const Key('shared-161-emergency-lock-primary'));
      expect(gateway.calls['SHARED-161-EMERGENCY-LOCK-PRIMARY'] ?? 0, 0);
      shared.setAuthorized(true);
      gateway
        ..failNext = true
        ..failActionId = 'SHARED-161-EMERGENCY-LOCK-PRIMARY';
      await tap(tester, const Key('shared-161-emergency-lock-primary'));
      expect(
        shared.actionComplete('SHARED-161-EMERGENCY-LOCK-PRIMARY'),
        isFalse,
      );
      await tap(tester, const Key('shared-161-emergency-lock-primary'));
      await tap(tester, const Key('shared-161-emergency-lock-primary'));
      expect(
        shared.actionComplete('SHARED-161-EMERGENCY-LOCK-PRIMARY'),
        isTrue,
      );
      expect(gateway.calls['SHARED-161-EMERGENCY-LOCK-PRIMARY'], 2);
      await binding.takeScreenshot('shared-161-emergency-lock-complete');

      await go(tester, '/app/account/workspaces/preferences');
      await tap(tester, const Key('shared-165-item-creator'));
      await tap(tester, const Key('shared-165-creator-control-collaboration'));
      gateway
        ..failNext = true
        ..failActionId = 'SHARED-165-CREATOR-PRIMARY';
      await tap(tester, const Key('shared-165-creator-primary'));
      expect(shared.actionComplete('SHARED-165-CREATOR-PRIMARY'), isFalse);
      await tap(tester, const Key('shared-165-creator-primary'));
      await tap(tester, const Key('shared-165-creator-primary'));
      expect(shared.actionComplete('SHARED-165-CREATOR-PRIMARY'), isTrue);
      expect(gateway.calls['SHARED-165-CREATOR-PRIMARY'], 2);
      await tap(tester, const Key('shared-165-detail-creator-close'));

      await tap(tester, const Key('shared-165-item-agent'));
      await tap(tester, const Key('shared-165-agent-control-enabled'));
      expect(shared.subscriptionActive, isFalse);
      expect(shared.errorMessage, contains('monthly plan'));
      await tap(tester, const Key('shared-165-agent-control-sensitive'));
      expect(shared.errorMessage, contains('fresh, scoped owner approval'));
      expect(find.text('Runs automatically'), findsOneWidget);
      expect(find.text('Asks before action'), findsOneWidget);
      expect(find.text('Never delegated'), findsOneWidget);
      await binding.takeScreenshot('shared-165-agent-boundaries');

      expect([
        gateway.calls['SHARED-159-ASK-BUY'],
        gateway.calls['SHARED-161-EMERGENCY-LOCK-PRIMARY'],
        gateway.calls['SHARED-165-CREATOR-PRIMARY'],
      ], everyElement(2));
    },
  );
}
