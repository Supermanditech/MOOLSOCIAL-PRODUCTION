import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';

void main() {
  testWidgets(
    'Buy uses one connected MoolSocial launcher without local rails',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final session = BuyV2Session(core: BuySession());
      addTearDown(session.dispose);
      final routes = <String>[];
      var chatTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: BuyV2Screen(
            session: session,
            onOpenMainAction: (action) => routes.add(action.route),
            onOpenChat: () => chatTaps += 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mool-home-launcher')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('buy-local-destination-tabs')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('buy-persistent-dock')), findsNothing);
      expect(find.text('MoolSocial'), findsOneWidget);

      await tester.tap(find.byKey(const Key('mool-home-launcher')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsOneWidget,
      );
      for (final action in const ['shop', 'wholesale', 'medicine', 'orders']) {
        final target = find.byKey(ValueKey('mool-navigator-buy-$action'));
        expect(target, findsOneWidget);
        expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
      }
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Medicine'))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );

      await tester.tap(
        find.byKey(const ValueKey('mool-navigator-buy-medicine')),
      );
      await tester.pumpAndSettle();
      expect(routes, ['/app/buy?sub=medicine']);
      expect(session.destination.name, 'shop');

      session.openAssist();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mool-home-launcher')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('mool-connected-navigator-chat')));
      await tester.pumpAndSettle();
      expect(chatTaps, 1);
      expect(session.view.name, 'assist');
      semantics.dispose();
    },
  );

  testWidgets('Buy Medicine survives chooser dismissal and system Back', (
    tester,
  ) async {
    final journey = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'current',
          currentAreaLabel: 'Khema-Ka-Kuwa, Jodhpur, Rajasthan',
          setupComplete: true,
          setupExperienceVersion: approvedSetupExperienceVersion,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    addTearDown(journey.dispose);
    await journey.start();
    await tester.pumpWidget(
      MoolSocialApp(session: journey, initialLocation: '/app/buy?sub=medicine'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search medicines and wellness'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mool-home-launcher')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );
    expect(find.byKey(const Key('buy-v2-screen')), findsOneWidget);
    expect(find.text('Search medicines and wellness'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('buy-local-destination-tabs')),
      findsNothing,
    );
  });
}
