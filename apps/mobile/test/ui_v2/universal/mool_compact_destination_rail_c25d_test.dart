import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

void main() {
  testWidgets('C29N fits both edge controls and four Social actions at 320', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var previousTaps = 0;
    var nextTaps = 0;
    final routes = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.4),
          ),
          child: Scaffold(
            body: const ColoredBox(
              key: Key('destination-content'),
              color: Color(0xFFF5F5F7),
            ),
            bottomNavigationBar: MoolDestinationNavigationV2(
              activeId: 'social',
              destinationLabel: 'Social',
              selectedLocalIndex: 0,
              localActionCount: 4,
              localNavigation: _rail(4),
              onOpenMool: null,
              onOpenAction: (action) => routes.add(action.route),
              onOpenChat: null,
              onPreviousLocalAction: () => previousTaps++,
              onNextLocalAction: () => nextTaps++,
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .getSize(find.byKey(const Key('moolsocial-compact-destination-rail')))
          .height,
      58,
    );
    for (final id in const ['a', 'b', 'c', 'd']) {
      final control = find.byKey(ValueKey('moolsocial-local-$id-selection'));
      expect(control, findsOneWidget);
      expect(tester.getSize(control).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(control).height, greaterThanOrEqualTo(44));
    }
    final edgeSize = tester.getSize(
      find.byKey(const Key('mool-compact-launcher')),
    );
    expect(edgeSize.width, closeTo(320 / 6, .01));
    expect(edgeSize.height, 58);
    expect(tester.getSize(find.byKey(const Key('mool-global-chat'))), edgeSize);
    for (final id in const ['a', 'b', 'c', 'd']) {
      expect(
        tester
            .getSize(find.byKey(ValueKey('moolsocial-local-$id-selection')))
            .width,
        closeTo(edgeSize.width, .01),
      );
    }
    expect(
      tester.getCenter(find.byKey(const Key('mool-compact-launcher'))).dx,
      lessThan(tester.getCenter(find.byKey(const Key('mool-global-chat'))).dx),
    );
    expect(
      find.byKey(const ValueKey('moolsocial-family-root-social')),
      findsNothing,
    );
    expect(find.byKey(const Key('moolsocial-local-previous')), findsNothing);
    expect(find.byKey(const Key('moolsocial-local-next')), findsNothing);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Open MoolSocial main menu'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    expect(previousTaps, 0);
    expect(nextTaps, 0);

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mool-navigator-family-eat')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('mool-navigator-eat-order')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('mool-navigator-family-eat')));
    await tester.pumpAndSettle();
    expect(routes, ['/app/eat/home']);
  });

  testWidgets('C25D keeps sparse two-action cluster compact', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MoolDestinationNavigationV2(
            activeId: 'eat',
            destinationLabel: 'Food',
            selectedLocalIndex: 0,
            localActionCount: 2,
            localNavigation: _rail(2),
            onOpenMool: null,
            onOpenAction: (_) {},
            onOpenChat: null,
            onPreviousLocalAction: () {},
            onNextLocalAction: () {},
          ),
        ),
      ),
    );

    final cluster = tester.getSize(
      find.byKey(const Key('moolsocial-local-navigation-compact-cluster')),
    );
    expect(cluster.width, 156);
    expect(cluster.width, lessThan(200));
    const uniformCell = 390 / 5;
    expect(
      tester.getSize(find.byKey(const ValueKey('moolsocial-family-root-eat'))),
      const Size(uniformCell, 58),
    );
    expect(
      tester.getSize(find.byKey(const Key('mool-global-chat'))),
      const Size(uniformCell, 58),
    );
  });
}

MoolLocalNavigationRail _rail(int count) => MoolLocalNavigationRail(
  familyId: 'social',
  semanticLabel: 'Test actions',
  activeId: 'a',
  actions: [
    for (var index = 0; index < count; index++)
      MoolLocalNavigationAction(
        keyName: 'test-action-$index',
        id: String.fromCharCode(97 + index),
        label: switch (index) {
          0 => 'Products',
          1 => 'Wholesale',
          2 => 'Orders',
          _ => 'Saved',
        },
        icon: Icons.circle_outlined,
        onPressed: index == 0 ? null : () {},
      ),
  ],
);
