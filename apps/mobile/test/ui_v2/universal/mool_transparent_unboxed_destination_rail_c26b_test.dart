import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

void main() {
  const families = [
    _FamilyCase('social', 'Social', '/app/social', 4),
    _FamilyCase('buy', 'Shop', '/app/buy?sub=shop', 3),
    _FamilyCase('eat', 'Food', '/app/eat/home', 2),
    _FamilyCase('ride', 'Travel', '/app/ride/book?type=bike', 4),
    _FamilyCase('book', 'Care', '/app/book/doctor', 3),
    _FamilyCase('work', 'Work', '/app/work/earn', 2),
  ];

  for (final family in families) {
    testWidgets(
      'FSC01 ${family.label} fits Mool and direct actions without scroll at 320',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final openedRoutes = <String>[];

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 568),
                textScaler: TextScaler.linear(1.4),
              ),
              child: Scaffold(
                body: const SizedBox.expand(),
                bottomNavigationBar: MoolDestinationNavigationV2(
                  activeId: family.id,
                  destinationLabel: family.label,
                  selectedLocalIndex: 0,
                  localActionCount: family.actionCount,
                  localNavigation: _rail(family),
                  onOpenMool: null,
                  onOpenAction: (action) => openedRoutes.add(action.route),
                  onOpenChat: null,
                ),
              ),
            ),
          ),
        );

        final destinationRail = find.byKey(
          const Key('moolsocial-compact-destination-rail'),
        );
        expect(destinationRail, findsOneWidget);
        expect(tester.getSize(destinationRail).height, 58);
        expect(
          find.descendant(
            of: destinationRail,
            matching: find.byType(SingleChildScrollView),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: destinationRail,
            matching: find.byType(BackdropFilter),
          ),
          findsNothing,
        );
        expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
        expect(find.text('Mool'), findsOneWidget);

        final root = find.byKey(
          ValueKey('moolsocial-family-root-${family.id}'),
        );
        if (family.id == 'social') {
          expect(find.text(family.label), findsNothing);
          expect(root, findsNothing);
          expect(openedRoutes, isEmpty);
        } else {
          expect(find.text(family.label), findsOneWidget);
          expect(tester.getSize(root), const Size(54, 58));
          await tester.tap(root);
          expect(openedRoutes, [family.defaultRoute]);
        }

        for (var index = 0; index < family.actionCount; index++) {
          final control = find.byKey(
            ValueKey('moolsocial-local-action-$index-selection'),
          );
          expect(control, findsOneWidget);
          final size = tester.getSize(control);
          expect(size.width, greaterThanOrEqualTo(44));
          expect(size.height, greaterThanOrEqualTo(44));
        }
      },
    );
  }

  testWidgets('C26B sparse actions remain compact and transparent at 430', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
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
            localNavigation: _rail(families[2]),
            onOpenMool: null,
            onOpenAction: (_) {},
            onOpenChat: null,
          ),
        ),
      ),
    );

    final cluster = tester.getSize(
      find.byKey(const Key('moolsocial-local-navigation-compact-cluster')),
    );
    expect(cluster.width, 152);
    expect(cluster.width, lessThan(200));
  });
}

MoolLocalNavigationRail _rail(_FamilyCase family) => MoolLocalNavigationRail(
  familyId: family.id,
  semanticLabel: '${family.label} actions',
  activeId: 'action-0',
  actions: [
    for (var index = 0; index < family.actionCount; index++)
      MoolLocalNavigationAction(
        keyName: 'c26b-${family.id}-action-$index',
        id: 'action-$index',
        label: switch (index) {
          0 => 'First',
          1 => 'Second',
          2 => 'Third',
          _ => 'Fourth',
        },
        icon: Icons.circle_outlined,
        onPressed: index == 0 ? null : () {},
      ),
  ],
);

class _FamilyCase {
  const _FamilyCase(this.id, this.label, this.defaultRoute, this.actionCount);

  final String id;
  final String label;
  final String defaultRoute;
  final int actionCount;
}
