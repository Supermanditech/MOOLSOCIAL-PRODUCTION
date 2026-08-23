import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

const _cases = <(String, int)>[('eat', 2), ('ride', 3), ('social', 4)];

void main() {
  for (final entry in _cases) {
    testWidgets('C22E ${entry.$1} reverse-U spans all ${entry.$2} capsules', (
      tester,
    ) async {
      final bodyTaps = <Offset>[];
      await _mount(
        tester,
        family: entry.$1,
        actionCount: entry.$2,
        onBodyTap: bodyTaps.add,
      );

      final connector = find.byKey(
        ValueKey('moolsocial-${entry.$1}-family-wave-link'),
      );
      final rail = find.byKey(
        ValueKey('moolsocial-${entry.$1}-translucent-subaction-family-rail'),
      );
      final globalRail = find.byKey(
        const Key('moolsocial-destination-navigation-stack'),
      );
      final overlay = find.byKey(
        ValueKey('moolsocial-${entry.$1}-transparent-subaction-overlay'),
      );
      expect(connector, findsOneWidget);
      expect(
        find.ancestor(of: connector, matching: find.byType(IgnorePointer)),
        findsWidgets,
      );
      expect(
        find.ancestor(of: connector, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
      expect(
        tester.getSize(connector).height,
        moolDestinationFamilyBridgeHeight,
      );
      expect(tester.getSize(rail).height, moolDestinationFamilyRailHeight);
      expect(
        tester.getRect(rail).bottom,
        closeTo(tester.getRect(globalRail).top, .01),
      );
      expect(
        tester.getRect(overlay).bottom,
        closeTo(
          tester.getRect(globalRail).top + moolDestinationFamilyBridgeOverlap,
          .01,
        ),
      );

      final customPaint = tester.widget<CustomPaint>(connector);
      final painter = customPaint.painter! as MoolDestinationFamilyWavePainter;
      final size = tester.getSize(connector);
      final first = painter.familyFirstAnchor(size);
      final last = painter.familyLastAnchor(size);
      final crest = painter.familyCrest(size);
      expect(
        first.dx,
        closeTo(
          MoolLocalNavigationTokens.selectedCenterX(
            maxWidth: size.width,
            actionCount: entry.$2,
            selectedIndex: 0,
          ),
          .01,
        ),
      );
      expect(
        last.dx,
        closeTo(
          MoolLocalNavigationTokens.selectedCenterX(
            maxWidth: size.width,
            actionCount: entry.$2,
            selectedIndex: entry.$2 - 1,
          ),
          .01,
        ),
      );
      expect(last.dx - first.dx, greaterThan(0));
      expect(crest.dx, closeTo((first.dx + last.dx) / 2, .01));
      expect(crest.dy, lessThan(first.dy));

      final reverseU = painter.reverseUPath(size);
      final reverseUBounds = reverseU.getBounds();
      expect(reverseUBounds.left, closeTo(first.dx, .01));
      expect(reverseUBounds.right, closeTo(last.dx, .01));
      expect(reverseUBounds.top, closeTo(crest.dy, .01));
      expect(reverseUBounds.bottom, closeTo(first.dy, .01));

      final globalRect = tester.getRect(globalRail);
      final selectedMainRect = tester.getRect(
        find.byKey(Key('mool-action-${entry.$1}')),
      );
      expect(
        painter.selectedMainActionAnchor.dx,
        closeTo(selectedMainRect.center.dx - globalRect.left, 1),
      );
      final resolvedMain = painter.resolvedMainAnchor(size);
      expect(resolvedMain.dy, size.height - 1);
      final stemMetric = painter.mainStemPath(size).computeMetrics().single;
      expect(
        stemMetric.getTangentForOffset(0)!.position,
        within(distance: .01, from: resolvedMain),
      );

      if (entry.$2 == 2) {
        final connectorRect = tester.getRect(connector);
        await tester.tapAt(connectorRect.topLeft + crest);
        await tester.pump();
        expect(bodyTaps, hasLength(1));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('C22E bridge and capsules disclose as one unit', (tester) async {
    await _mount(tester, family: 'buy', actionCount: 4);
    final selectedMain = find.byKey(const Key('mool-action-buy'));
    final region = find.byKey(
      const Key('moolsocial-buy-subaction-disclosure-region'),
    );
    final connector = find.byKey(const Key('moolsocial-buy-family-wave-link'));
    final fade = tester.widget<FadeTransition>(
      find.ancestor(of: connector, matching: find.byType(FadeTransition)).first,
    );
    expect(fade.opacity.value, 1);
    expect(tester.widget<InkWell>(selectedMain).onTap, isNotNull);

    await tester.tap(selectedMain);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getSize(region).height, inExclusiveRange(0, 52));
    expect(fade.opacity.value, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(tester.getSize(region).height, 0);
    expect(fade.opacity.value, 0);
    expect(
      tester.getSemantics(selectedMain).flagsCollection.isSelected,
      Tristate.isTrue,
    );

    await tester.tap(selectedMain);
    await tester.pumpAndSettle();
    expect(tester.getSize(region).height, 52);
    expect(fade.opacity.value, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('C22E reduced motion hides bridge immediately', (tester) async {
    await _mount(tester, family: 'work', actionCount: 2, reducedMotion: true);
    final selectedMain = find.byKey(const Key('mool-action-work'));
    final region = find.byKey(
      const Key('moolsocial-work-subaction-disclosure-region'),
    );
    final connector = find.byKey(const Key('moolsocial-work-family-wave-link'));
    await tester.tap(selectedMain);
    await tester.pump();
    expect(tester.getSize(region).height, 0);
    expect(
      tester
          .widget<FadeTransition>(
            find
                .ancestor(of: connector, matching: find.byType(FadeTransition))
                .first,
          )
          .opacity
          .value,
      0,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _mount(
  WidgetTester tester, {
  required String family,
  required int actionCount,
  bool reducedMotion = false,
  ValueChanged<Offset>? onBodyTap,
}) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  MoolDestinationNavigationV2.debugResetDisclosureSession();

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: child!,
      ),
      home: Scaffold(
        extendBody: true,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: onBodyTap == null
              ? null
              : (details) => onBodyTap(details.globalPosition),
          child: const SizedBox.expand(
            child: ColoredBox(color: Color(0xFF246080)),
          ),
        ),
        bottomNavigationBar: MoolDestinationNavigationV2(
          activeId: family,
          destinationLabel: family,
          selectedLocalIndex: 0,
          localActionCount: actionCount,
          localNavigation: MoolLocalNavigationRail(
            familyId: family,
            semanticLabel: '$family options',
            activeId: 'action-0',
            actions: [
              for (var index = 0; index < actionCount; index++)
                MoolLocalNavigationAction(
                  keyName: 'c22e-$family-$index',
                  id: 'action-$index',
                  label: 'Action ${index + 1}',
                  icon: Icons.circle_outlined,
                  onPressed: index == 0 ? null : () {},
                ),
            ],
          ),
          onOpenMool: () {},
          onOpenAction: (_) {},
          onOpenChat: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
