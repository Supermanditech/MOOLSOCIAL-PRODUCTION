import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

void main() {
  testWidgets(
    'C24B3 connected navigator candidate capture at OPPO-class viewport',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _mountDestination(
        tester,
        activeId: 'buy',
        onOpenMool: () {},
        onOpenRoute: (_) {},
      );
      await tester.tap(find.byKey(const Key('mool-compact-launcher')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Overlay).first,
        matchesGoldenFile(
          'candidate_captures/mool-connected-navigator-c24b3-oppo-360x800.png',
        ),
      );
    },
    // Run explicitly with --run-skipped --update-goldens for visual evidence.
    skip: true,
  );

  testWidgets(
    'C24B3 MoolSocial opens connected chooser and routes without Home',
    (tester) async {
      var homeTaps = 0;
      final routes = <String>[];
      await _mountDestination(
        tester,
        activeId: 'buy',
        onOpenMool: () => homeTaps++,
        onOpenRoute: routes.add,
      );

      final launcher = find.byKey(const Key('mool-compact-launcher'));
      expect(launcher, findsOneWidget);
      expect(tester.getSize(launcher).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(launcher).height, greaterThanOrEqualTo(44));
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Open MoolSocial main menu'))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );

      await tester.tap(launcher);
      await tester.pumpAndSettle();

      expect(homeTaps, 0);
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('destination-state')), findsOneWidget);
      for (final family in const [
        'social',
        'buy',
        'eat',
        'ride',
        'book',
        'work',
      ]) {
        expect(
          find.byKey(ValueKey('mool-navigator-family-$family')),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(const ValueKey('mool-navigator-buy-shop')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('mool-navigator-family-social')),
      );
      await tester.pumpAndSettle();

      expect(routes, ['/app/social']);
      expect(homeTaps, 0);
      expect(
        find.byKey(const Key('mool-connected-action-navigator')),
        findsNothing,
      );
      expect(find.byKey(const Key('destination-state')), findsOneWidget);
    },
  );

  testWidgets('C24B3 System Back dismisses to unchanged destination', (
    tester,
  ) async {
    var homeTaps = 0;
    final routes = <String>[];
    await _mountDestination(
      tester,
      activeId: 'ride',
      onOpenMool: () => homeTaps++,
      onOpenRoute: routes.add,
    );

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );
    expect(find.byKey(const Key('destination-state')), findsOneWidget);
    expect(routes, isEmpty);
    expect(homeTaps, 0);
  });

  testWidgets('C25F Chat opens directly from destination header', (
    tester,
  ) async {
    var chatTaps = 0;
    await _mountDestination(
      tester,
      activeId: 'social',
      onOpenMool: () {},
      onOpenRoute: (_) {},
      onOpenChat: () => chatTaps++,
    );

    final chat = find.byKey(const Key('destination-global-chat'));
    expect(chat, findsOneWidget);
    expect(tester.getSize(chat).height, greaterThanOrEqualTo(44));
    expect(
      tester
          .getSemantics(find.byTooltip('Open Chat'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    await tester.tap(chat);
    await tester.pumpAndSettle();
    expect(chatTaps, 1);
    expect(find.byKey(const Key('destination-state')), findsOneWidget);
  });

  testWidgets('C24B3 reaches every family directly from one destination', (
    tester,
  ) async {
    var homeTaps = 0;
    final routes = <String>[];
    await _mountDestination(
      tester,
      activeId: 'buy',
      onOpenMool: () => homeTaps++,
      onOpenRoute: routes.add,
    );

    for (final family in moolActionFamilies) {
      await tester.tap(find.byKey(const Key('mool-compact-launcher')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('mool-navigator-family-${family.id}')),
      );
      await tester.pumpAndSettle();
    }

    expect(routes, [for (final family in moolActionFamilies) family.route]);
    expect(homeTaps, 0);
    expect(find.byKey(const Key('destination-state')), findsOneWidget);
  });

  for (final viewport in const [
    (size: Size(320, 568), textScale: 1.4),
    (size: Size(390, 844), textScale: 1.0),
    (size: Size(430, 932), textScale: 1.3),
  ]) {
    testWidgets(
      'C24B3 chooser fits ${viewport.size.width.toInt()}x${viewport.size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = viewport.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _mountDestination(
          tester,
          activeId: 'work',
          textScale: viewport.textScale,
          onOpenMool: () {},
          onOpenRoute: (_) {},
        );

        await tester.tap(find.byKey(const Key('mool-compact-launcher')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('mool-connected-action-navigator')),
          findsOneWidget,
        );
        expect(
          tester.getSize(find.byKey(const Key('mool-compact-launcher'))).height,
          greaterThanOrEqualTo(44),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('C24B3 reduced motion opens and dismisses immediately', (
    tester,
  ) async {
    await _mountDestination(
      tester,
      activeId: 'eat',
      disableAnimations: true,
      onOpenMool: () {},
      onOpenRoute: (_) {},
    );

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pump();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('mool-switcher-outside-dismiss')));
    await tester.pump();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _mountDestination(
  WidgetTester tester, {
  required String activeId,
  required VoidCallback onOpenMool,
  required ValueChanged<String> onOpenRoute,
  VoidCallback? onOpenChat,
  double textScale = 1,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: child!,
      ),
      home: Scaffold(
        appBar: onOpenChat == null
            ? null
            : AppBar(
                actions: [
                  MoolGlobalChatShortcut(
                    keyName: 'destination-global-chat',
                    onPressed: onOpenChat,
                  ),
                ],
              ),
        body: const SizedBox.expand(
          key: Key('destination-state'),
          child: ColoredBox(color: Color(0xFFE8ECF4)),
        ),
        bottomNavigationBar: MoolDestinationNavigationV2(
          activeId: activeId,
          destinationLabel: activeId,
          selectedLocalIndex: 0,
          localActionCount: moolActionFamilies
              .firstWhere((family) => family.id == activeId)
              .actions
              .length,
          localNavigation: const SizedBox.shrink(),
          onOpenMool: onOpenMool,
          onOpenAction: (action) => onOpenRoute(action.route),
          onOpenChat: onOpenChat ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
