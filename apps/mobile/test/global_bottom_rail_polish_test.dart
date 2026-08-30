import 'dart:ui' show Tristate;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

void main() {
  testWidgets('customer rail has equal actions and clear selected treatment', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final opened = <String>[];
    var chatTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MoolDestinationNavigationV2(
            activeId: 'buy',
            destinationLabel: 'Shop',
            familyRootSelected: false,
            selectedLocalIndex: 1,
            localActionCount: 3,
            onOpenMool: () => opened.add('/app/mool'),
            onOpenAction: (action) => opened.add(action.route),
            onOpenChat: () => chatTaps += 1,
            localNavigation: MoolLocalNavigationRail(
              familyId: 'buy',
              semanticLabel: 'Shop choices',
              activeId: 'orders',
              actions: [
                MoolLocalNavigationAction(
                  keyName: 'rail-shop',
                  id: 'shop',
                  label: 'Shop',
                  icon: Icons.storefront_outlined,
                  onPressed: () => opened.add('shop'),
                ),
                MoolLocalNavigationAction(
                  keyName: 'rail-orders',
                  id: 'orders',
                  label: 'Orders',
                  icon: Icons.receipt_long_outlined,
                  onPressed: () => opened.add('orders'),
                ),
                MoolLocalNavigationAction(
                  keyName: 'rail-offers',
                  id: 'offers',
                  label: 'Offers',
                  icon: Icons.local_offer_outlined,
                  onPressed: () => opened.add('offers'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selections = [
      for (final id in const ['shop', 'orders', 'offers'])
        find.byKey(ValueKey('moolsocial-local-$id-selection')),
    ];
    final widths = [
      for (final selection in selections) tester.getSize(selection).width,
    ];
    expect(widths[0], closeTo(widths[1], .01));
    expect(widths[1], closeTo(widths[2], .01));
    for (final selection in selections) {
      expect(tester.getSize(selection).height, greaterThanOrEqualTo(44));
    }

    final selected = tester.widget<AnimatedContainer>(selections[1]);
    final unselected = tester.widget<AnimatedContainer>(selections[0]);
    final familyRoot = tester.widget<Material>(
      find.byKey(const ValueKey('moolsocial-family-root-buy-surface')),
    );
    expect((selected.decoration! as BoxDecoration).color!.a, greaterThan(0));
    expect((unselected.decoration! as BoxDecoration).color!.a, 0);
    expect(familyRoot.color!.a, 0);
    final fullRailWidths = [
      tester.getSize(find.byKey(const Key('mool-compact-launcher'))).width,
      tester
          .getSize(find.byKey(const ValueKey('moolsocial-family-root-buy-tap')))
          .width,
      for (final key in const ['rail-shop', 'rail-orders', 'rail-offers'])
        tester.getSize(find.byKey(Key(key))).width,
      tester.getSize(find.byKey(const Key('mool-global-chat-tap'))).width,
    ];
    for (final width in fullRailWidths.skip(1)) {
      expect(width, closeTo(fullRailWidths.first, .01));
    }
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Orders, current'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );

    for (final key in const ['rail-shop', 'rail-orders', 'rail-offers']) {
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('mool-global-chat')));
    await tester.pumpAndSettle();
    expect(opened, containsAllInOrder(['shop', 'orders', 'offers']));
    expect(chatTaps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('family home owns the selected cue only while it is current', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MoolDestinationNavigationV2(
            activeId: 'buy',
            destinationLabel: 'Shop',
            familyRootSelected: true,
            selectedLocalIndex: 0,
            localActionCount: 1,
            onOpenMool: () {},
            onOpenAction: (_) {},
            onOpenChat: () {},
            localNavigation: MoolLocalNavigationRail(
              familyId: 'buy',
              semanticLabel: 'Shop choices',
              activeId: 'none',
              actions: const [
                MoolLocalNavigationAction(
                  keyName: 'root-test-wholesale',
                  id: 'wholesale',
                  label: 'Wholesale',
                  icon: Icons.inventory_2_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final familyRoot = tester.widget<Material>(
      find.byKey(const ValueKey('moolsocial-family-root-buy-surface')),
    );
    expect(familyRoot.color!.a, greaterThan(0));
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Shop home, current'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    expect(
      tester
          .widget<AnimatedContainer>(
            find.byKey(const ValueKey('moolsocial-local-wholesale-selection')),
          )
          .decoration,
      isA<BoxDecoration>().having((value) => value.color!.a, 'alpha', 0),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Workspace dock distributes three subactions equally', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final taps = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MoolOutcomeDock(
            semanticLabel: 'Workspace navigation',
            activeId: 'stock',
            mool: MoolDockAction(
              keyName: 'dock-mool',
              id: 'mool',
              label: 'Mool',
              icon: Icons.grid_view_rounded,
              onPressed: () => taps.add('mool'),
            ),
            actions: [
              for (final item in const [
                ('orders', 'Orders', Icons.receipt_long_outlined),
                ('stock', 'Stock', Icons.inventory_2_outlined),
                ('sales', 'Sales', Icons.trending_up_rounded),
              ])
                MoolDockAction(
                  keyName: 'dock-${item.$1}',
                  id: item.$1,
                  label: item.$2,
                  icon: item.$3,
                  onPressed: () => taps.add(item.$1),
                ),
            ],
            chat: MoolDockAction(
              keyName: 'dock-chat',
              id: 'chat',
              label: 'Chat',
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: () => taps.add('chat'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final actionRects = [
      for (final id in const ['mool', 'orders', 'stock', 'sales', 'chat'])
        tester.getRect(find.byKey(Key('dock-$id'))),
    ];
    for (final rect in actionRects.skip(1)) {
      expect(rect.width, closeTo(actionRects.first.width, .01));
    }
    for (final rect in actionRects) {
      expect(rect.height, greaterThanOrEqualTo(44));
    }
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.byKey(const ValueKey('mool-action-stock-selected-indicator')),
          )
          .opacity,
      1,
    );

    for (final key in const [
      'dock-mool',
      'dock-orders',
      'dock-stock',
      'dock-sales',
      'dock-chat',
    ]) {
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }
    expect(taps, ['mool', 'orders', 'stock', 'sales', 'chat']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Social rail uses explicit coloured selection and one-tap moves',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.view.reset);
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
      await journey.start();
      addTearDown(journey.dispose);

      await tester.pumpWidget(
        MoolSocialApp(
          session: journey,
          initialLocation: '/app/social?sub=feed',
        ),
      );
      await tester.pumpAndSettle();

      final feedIndicator = tester.widget<AnimatedScale>(
        find.byKey(const ValueKey('social-rail-Feed-selected-indicator')),
      );
      expect(feedIndicator.scale, 1);
      for (final key in const [
        'screen04-rail-videos',
        'screen04-rail-shorts',
        'screen04-rail-create',
        'screen04-rail-feed',
      ]) {
        final size = tester.getSize(find.byKey(Key(key)));
        expect(size.width, greaterThanOrEqualTo(44), reason: key);
        expect(size.height, greaterThanOrEqualTo(44), reason: key);
      }
      final socialWidths = [
        tester.getSize(find.byKey(const Key('mool-compact-launcher'))).width,
        for (final key in const [
          'screen04-rail-videos',
          'screen04-rail-shorts',
          'screen04-rail-create',
          'screen04-rail-feed',
        ])
          tester.getSize(find.byKey(Key(key))).width,
        tester.getSize(find.byKey(const Key('social-global-chat'))).width,
      ];
      for (final width in socialWidths.skip(1)) {
        expect(width, closeTo(socialWidths.first, .01));
      }

      await tester.tap(find.byKey(const Key('screen04-rail-videos')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedScale>(
              find.byKey(const ValueKey('social-rail-Home-selected-indicator')),
            )
            .scale,
        1,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('landscape rails clear OPPO side semantics symmetrically', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 360);
    tester.view.viewPadding = const FakeViewPadding(left: 41, right: 44);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MoolDestinationNavigationV2(
            activeId: 'buy',
            destinationLabel: 'Shop',
            selectedLocalIndex: 1,
            localActionCount: 3,
            onOpenMool: () {},
            onOpenAction: (_) {},
            onOpenChat: () {},
            localNavigation: MoolLocalNavigationRail(
              familyId: 'buy',
              semanticLabel: 'Shop choices',
              activeId: 'orders',
              actions: const [
                MoolLocalNavigationAction(
                  keyName: 'side-wholesale',
                  id: 'wholesale',
                  label: 'Wholesale',
                  icon: Icons.inventory_2_outlined,
                ),
                MoolLocalNavigationAction(
                  keyName: 'side-orders',
                  id: 'orders',
                  label: 'Orders',
                  icon: Icons.receipt_long_outlined,
                ),
                MoolLocalNavigationAction(
                  keyName: 'side-offers',
                  id: 'offers',
                  label: 'Offers',
                  icon: Icons.local_offer_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;

    final mool = tester.getRect(find.byKey(const Key('mool-compact-launcher')));
    final chat = tester.getRect(find.byKey(const Key('mool-global-chat')));
    expect(mool.left, greaterThanOrEqualTo(30));
    expect(chat.right, lessThanOrEqualTo(770));
    expect(mool.width, closeTo(chat.width, .01));
    expect(mool.height, greaterThanOrEqualTo(44));
    expect(chat.height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });
}
