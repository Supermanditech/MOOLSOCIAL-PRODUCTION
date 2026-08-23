import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

void main() {
  for (final width in const [320.0, 390.0, 430.0]) {
    for (final textScale in const [1.0, 1.4]) {
      testWidgets(
        'C25F menu and rail fit ${width.toInt()} at ${textScale}x text',
        (tester) async {
          final size = Size(width, 844);
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(textScale),
                ),
                child: Scaffold(
                  body: MoolConnectedActionNavigator(
                    initialFamilyId: 'ride',
                    onOpenFamily: (_) {},
                    onDismiss: () {},
                  ),
                  bottomNavigationBar: MoolDestinationNavigationV2(
                    activeId: 'ride',
                    destinationLabel: 'Travel',
                    selectedLocalIndex: 0,
                    localActionCount: 4,
                    localNavigation: _fourActionRail(),
                    onOpenMool: null,
                    onOpenAction: (_) {},
                    onOpenChat: null,
                    onPreviousLocalAction: () {},
                    onNextLocalAction: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          for (final family in moolActionFamilies) {
            final control = find.byKey(
              ValueKey('mool-navigator-family-${family.id}'),
            );
            expect(control, findsOneWidget);
            expect(tester.getSize(control).height, greaterThanOrEqualTo(44));
          }
          for (final id in const ['bike', 'auto', 'cab', 'bus']) {
            final control = find.byKey(
              ValueKey('moolsocial-local-$id-selection'),
            );
            expect(control, findsOneWidget);
            final controlSize = tester.getSize(control);
            expect(controlSize.width, greaterThanOrEqualTo(44));
            expect(controlSize.height, greaterThanOrEqualTo(44));
          }
          expect(
            find.byKey(const Key('moolsocial-local-previous')),
            findsNothing,
          );
          expect(find.byKey(const Key('moolsocial-local-next')), findsNothing);
          expect(
            tester.getSize(find.byKey(const Key('mool-compact-launcher'))),
            const Size(54, 58),
          );
          expect(
            tester.getSize(
              find.byKey(const ValueKey('moolsocial-family-root-ride')),
            ),
            const Size(54, 58),
          );
          final rail = find.byKey(
            const Key('moolsocial-compact-destination-rail'),
          );
          expect(
            find.descendant(of: rail, matching: find.byType(Scrollable)),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('C25F Chat shortcut is semantic, tappable and 44px', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            appBar: AppBar(
              actions: [
                MoolGlobalChatShortcut(
                  keyName: 'c25f-chat',
                  onPressed: () => taps++,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final control = find.byKey(const Key('c25f-chat'));
    final controlSize = tester.getSize(control);
    expect(controlSize.width, greaterThanOrEqualTo(44));
    expect(controlSize.height, greaterThanOrEqualTo(44));
    expect(
      tester
          .getSemantics(find.byTooltip('Open Chat'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    await tester.tap(control);
    expect(taps, 1);
  });

  for (final origin in const [
    (
      id: 'social',
      route: '/app/social?sub=feed',
      chatKey: Key('social-global-chat'),
      ownerKey: Key('screen04-universal-v2'),
    ),
    (
      id: 'shop',
      route: '/app/buy?sub=shop',
      chatKey: Key('buy-global-chat'),
      ownerKey: Key('buy-v2-screen'),
    ),
    (
      id: 'food',
      route: '/app/eat/home',
      chatKey: Key('eat-global-chat'),
      ownerKey: Key('eat-home-screen'),
    ),
    (
      id: 'travel',
      route: '/app/ride/book?type=bike',
      chatKey: Key('ride-global-chat'),
      ownerKey: Key('ride-booking-screen'),
    ),
    (
      id: 'travel bus',
      route: '/app/book/bus',
      chatKey: Key('ride-global-chat'),
      ownerKey: Key('bus-booking-home'),
    ),
    (
      id: 'care',
      route: '/app/book/doctor',
      chatKey: Key('care-global-chat'),
      ownerKey: Key('doctor-discovery-home'),
    ),
    (
      id: 'care medicine',
      route: '/app/buy?sub=medicine',
      chatKey: Key('buy-global-chat'),
      ownerKey: Key('buy-v2-screen'),
    ),
    (
      id: 'work',
      route: '/app/work/earn',
      chatKey: Key('work-global-chat'),
      ownerKey: Key('work-earn-screen'),
    ),
  ]) {
    testWidgets('C25F ${origin.id} opens Chat in one tap and returns', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final journey = _signedInSession();
      final chat = ChatSession();
      addTearDown(journey.dispose);
      addTearDown(chat.dispose);
      await journey.start();

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          chatSession: chat,
          initialLocation: origin.route,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(origin.ownerKey), findsOneWidget);
      final chatControl = find.byKey(origin.chatKey);
      expect(chatControl, findsOneWidget);
      final chatSize = tester.getSize(chatControl);
      expect(chatSize.width, greaterThanOrEqualTo(44));
      expect(chatSize.height, greaterThanOrEqualTo(44));
      expect(
        tester
            .getSemantics(find.byTooltip('Open Chat'))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );

      await tester.tap(chatControl);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(origin.ownerKey), findsOneWidget);
    });
  }
}

JourneySession _signedInSession() => JourneySession(
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

MoolLocalNavigationRail _fourActionRail() => MoolLocalNavigationRail(
  familyId: 'ride',
  semanticLabel: 'Travel choices: Bike, Auto, Cab and Bus.',
  activeId: 'bike',
  actions: [
    for (final action in const [
      ('bike', 'Bike', Icons.two_wheeler_rounded),
      ('auto', 'Auto', Icons.electric_rickshaw_rounded),
      ('cab', 'Cab', Icons.local_taxi_outlined),
      ('bus', 'Bus', Icons.directions_bus_filled_outlined),
    ])
      MoolLocalNavigationAction(
        keyName: 'c25f-${action.$1}',
        id: action.$1,
        label: action.$2,
        icon: action.$3,
        onPressed: action.$1 == 'bike' ? null : () {},
      ),
  ],
);
