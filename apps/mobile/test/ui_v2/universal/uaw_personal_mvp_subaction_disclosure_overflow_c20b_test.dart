import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

const _familyCounts = <String, int>{
  'social': 4,
  'buy': 4,
  'eat': 2,
  'ride': 3,
  'book': 2,
  'work': 2,
};

String _labelFor(String family) => switch (family) {
  'social' => 'Social',
  'buy' => 'Buy',
  'eat' => 'Eat',
  'ride' => 'Ride',
  'book' => 'Book',
  'work' => 'Work',
  _ => throw ArgumentError.value(family),
};

void main() {
  setUp(MoolDestinationNavigationV2.debugResetDisclosureSession);

  Future<void> mountDestination(
    WidgetTester tester, {
    required String family,
    bool reducedMotion = false,
    ValueChanged<PersonalMoolActionSpec>? onOpenAction,
    ValueChanged<int>? onOpenLocal,
  }) async {
    const size = Size(390, 360);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final actionCount = _familyCounts[family]!;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            disableAnimations: reducedMotion,
            accessibleNavigation: reducedMotion,
          ),
          child: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: MoolDestinationNavigationV2(
              activeId: family,
              destinationLabel: _labelFor(family),
              selectedLocalIndex: 0,
              localActionCount: actionCount,
              onOpenMool: () {},
              onOpenAction: onOpenAction ?? (_) {},
              onOpenChat: () {},
              localNavigation: MoolLocalNavigationRail(
                familyId: family,
                semanticLabel: '${_labelFor(family)} choices',
                activeId: '$family-0',
                actions: [
                  for (var index = 0; index < actionCount; index++)
                    MoolLocalNavigationAction(
                      keyName: 'c20b-local-$family-$index',
                      id: '$family-$index',
                      label: 'Choice ${index + 1}',
                      icon: Icons.circle_outlined,
                      onPressed: index == 0
                          ? null
                          : () => onOpenLocal?.call(index),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final family in _familyCounts.keys) {
    testWidgets(
      '$family defaults expanded and selected main action restores options',
      (tester) async {
        var mainNavigations = 0;
        var localNavigations = 0;
        await mountDestination(
          tester,
          family: family,
          onOpenAction: (_) => mainNavigations += 1,
          onOpenLocal: (_) => localNavigations += 1,
        );

        final label = _labelFor(family);
        final selectedMain = find.byKey(Key('mool-action-$family'));
        final region = find.byKey(
          Key('moolsocial-$family-subaction-disclosure-region'),
        );
        expect(tester.getSize(region).height, 52);
        expect(tester.getSize(selectedMain).height, greaterThanOrEqualTo(48));
        final hideSemantics = find.bySemanticsLabel(
          '$label, current. Hide $label options',
        );
        expect(hideSemantics, findsOneWidget);
        expect(
          tester
              .getSemantics(hideSemantics)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isTrue,
        );
        final badge = find.byKey(
          Key('mool-action-$family-subaction-disclosure-badge'),
        );
        expect(badge, findsOneWidget);
        expect(tester.getSize(badge), const Size(18, 18));
        expect(
          tester.getRect(selectedMain).contains(tester.getRect(badge).topLeft),
          isTrue,
        );
        expect(
          tester
              .getRect(selectedMain)
              .contains(
                tester.getRect(badge).bottomRight - const Offset(.1, .1),
              ),
          isTrue,
        );
        final badgeDecoration =
            tester.widget<AnimatedContainer>(badge).decoration!
                as BoxDecoration;
        expect(badgeDecoration.shape, BoxShape.circle);
        expect(badgeDecoration.gradient, isA<LinearGradient>());
        expect(badgeDecoration.border, isNotNull);
        expect(
          find.descendant(
            of: badge,
            matching: find.byIcon(Icons.keyboard_arrow_down_rounded),
          ),
          findsOneWidget,
        );

        if (_familyCounts[family]! > 1) {
          await tester.tap(find.byKey(Key('c20b-local-$family-1')));
          await tester.pump();
          expect(localNavigations, 1);
        }

        await tester.tap(selectedMain);
        await tester.pumpAndSettle();

        expect(tester.getSize(region).height, 0);
        expect(mainNavigations, 0);
        expect(
          find.bySemanticsLabel('$label, current. Show $label options'),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: badge,
            matching: find.byIcon(Icons.keyboard_arrow_up_rounded),
          ),
          findsOneWidget,
        );
        final excludedSemantics = find.descendant(
          of: region,
          matching: find.byType(ExcludeSemantics),
        );
        final ignoredPointers = find.descendant(
          of: region,
          matching: find.byType(IgnorePointer),
        );
        expect(
          tester
              .widgetList<ExcludeSemantics>(excludedSemantics)
              .any((widget) => widget.excluding),
          isTrue,
        );
        expect(
          tester
              .widgetList<IgnorePointer>(ignoredPointers)
              .any((widget) => widget.ignoring),
          isTrue,
        );

        await tester.tap(selectedMain);
        await tester.pumpAndSettle();
        expect(tester.getSize(region).height, 52);
        expect(mainNavigations, 0);
      },
    );
  }

  testWidgets('normal disclosure is finite and reduced motion is immediate', (
    tester,
  ) async {
    await mountDestination(tester, family: 'social');
    final selectedMain = find.byKey(const Key('mool-action-social'));
    final region = find.byKey(
      const Key('moolsocial-social-subaction-disclosure-region'),
    );

    await tester.tap(selectedMain);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getSize(region).height, inExclusiveRange(0, 52));
    await tester.pumpAndSettle();
    expect(tester.getSize(region).height, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    MoolDestinationNavigationV2.debugResetDisclosureSession();
    await mountDestination(tester, family: 'social', reducedMotion: true);
    final reducedSelectedMain = find.byKey(const Key('mool-action-social'));
    final reducedRegion = find.byKey(
      const Key('moolsocial-social-subaction-disclosure-region'),
    );
    await tester.tap(reducedSelectedMain);
    await tester.pump();
    expect(tester.getSize(reducedRegion).height, 0);
  });

  testWidgets('family connector stays restrained and owns no interaction', (
    tester,
  ) async {
    await mountDestination(tester, family: 'ride');
    expect(MoolLocalNavigationTokens.connectionLineStrokeWidth, 1.25);
    expect(MoolLocalNavigationTokens.connectionLineMaximumOpacity, .24);
    expect(MoolLocalNavigationTokens.connectionDotRadius, 1.5);
    final connector = find.byKey(const Key('moolsocial-ride-family-wave-link'));
    expect(connector, findsOneWidget);
    expect(
      find.ancestor(of: connector, matching: find.byType(IgnorePointer)),
      findsWidgets,
    );
    expect(
      find.ancestor(of: connector, matching: find.byType(ExcludeSemantics)),
      findsWidgets,
    );
  });

  testWidgets('collapsed family state is session-only and recoverable', (
    tester,
  ) async {
    await mountDestination(tester, family: 'buy');
    final selectedMain = find.byKey(const Key('mool-action-buy'));
    await tester.tap(selectedMain);
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await mountDestination(tester, family: 'buy');
    expect(
      tester
          .getSize(
            find.byKey(const Key('moolsocial-buy-subaction-disclosure-region')),
          )
          .height,
      0,
    );
    expect(
      find.bySemanticsLabel('Buy, current. Show Buy options'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    MoolDestinationNavigationV2.debugResetDisclosureSession();
    await mountDestination(tester, family: 'buy');
    expect(
      tester
          .getSize(
            find.byKey(const Key('moolsocial-buy-subaction-disclosure-region')),
          )
          .height,
      52,
    );
  });

  testWidgets('overflow arrows are truthful 44px non-overlapping buttons', (
    tester,
  ) async {
    const size = Size(320, 180);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: size),
          child: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: MoolGlobalNavigationV2(
              activeId: 'social',
              onOpenMool: () {},
              onOpenAction: (_) {},
              onOpenChat: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final back = find.byKey(const Key('mool-main-rail-overflow-back'));
    final next = find.byKey(const Key('mool-main-rail-overflow-cue'));
    final viewport = find.byKey(const Key('mool-root-main-actions'));
    expect(tester.getSize(back).width, 44);
    expect(tester.getSize(next).width, 44);
    expect(tester.getSize(back).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(next).height, greaterThanOrEqualTo(48));
    expect(find.bySemanticsLabel('Previous main actions'), findsNothing);
    final nextSemantics = find.bySemanticsLabel('Next main actions');
    expect(nextSemantics, findsOneWidget);
    expect(
      tester
          .getSemantics(nextSemantics)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(
      tester.getRect(back).right,
      lessThanOrEqualTo(tester.getRect(viewport).left),
    );
    expect(
      tester.getRect(viewport).right,
      lessThanOrEqualTo(tester.getRect(next).left),
    );

    await tester.tap(find.bySemanticsLabel('Next main actions'));
    await tester.pumpAndSettle();

    final backSemantics = find.bySemanticsLabel('Previous main actions');
    expect(backSemantics, findsOneWidget);
    expect(
      tester
          .getSemantics(backSemantics)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(tester.widget<AnimatedOpacity>(back).opacity, 1);
    expect(tester.takeException(), isNull);
  });
}
