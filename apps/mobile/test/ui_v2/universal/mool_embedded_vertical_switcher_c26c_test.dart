import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

void main() {
  testWidgets('C26C Mool opens one connected vertical six-family switcher', (
    tester,
  ) async {
    final routes = <String>[];
    await _mount(tester, onOpenRoute: routes.add);
    final content = find.byKey(const Key('c26c-content'));
    final before = tester.getRect(content);
    final baselineBarrierCount = find.byType(ModalBarrier).evaluate().length;

    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(ModalBarrier).evaluate().length, baselineBarrierCount);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(tester.getRect(content), before);

    var previousY = -1.0;
    for (final family in moolActionFamilies) {
      final row = find.byKey(ValueKey('mool-navigator-family-${family.id}'));
      expect(row, findsOneWidget);
      expect(tester.getSize(row).height, 56);
      expect(tester.getCenter(row).dy, greaterThan(previousY));
      previousY = tester.getCenter(row).dy;
    }
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Close MoolSocial main menu'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('mool-navigator-family-work')));
    await tester.pumpAndSettle();
    expect(routes, ['/app/work/earn']);
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );
  });

  testWidgets('C26C swipe, outside tap and system Back dismiss in place', (
    tester,
  ) async {
    await _mount(tester, onOpenRoute: (_) {});
    final launcher = find.byKey(const Key('mool-compact-launcher'));

    await tester.drag(launcher, const Offset(0, -90));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const Key('mool-connected-action-navigator-drag-surface')),
      const Offset(0, 90),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );

    await tester.tap(launcher);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mool-switcher-outside-dismiss')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );

    await tester.tap(launcher);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );
    expect(find.byKey(const Key('c26c-content')), findsOneWidget);
  });

  testWidgets('C26C reduced motion opens and closes immediately', (
    tester,
  ) async {
    await _mount(tester, disableAnimations: true, onOpenRoute: (_) {});
    await tester.tap(find.byKey(const Key('mool-compact-launcher')));
    await tester.pump();
    final arrival = tester.widget<ScaleTransition>(
      find.byKey(const Key('moolsocial-main-menu-arrival-motion')),
    );
    expect(arrival.scale.value, 1);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _mount(
  WidgetTester tester, {
  required ValueChanged<String> onOpenRoute,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.4),
          disableAnimations: disableAnimations,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: const SizedBox.expand(
          key: Key('c26c-content'),
          child: ColoredBox(color: Color(0xFFE8ECF4)),
        ),
        bottomNavigationBar: MoolDestinationNavigationV2(
          activeId: 'buy',
          destinationLabel: 'Shop',
          selectedLocalIndex: 0,
          localActionCount: 3,
          localNavigation: MoolLocalNavigationRail(
            familyId: 'buy',
            semanticLabel: 'Shop actions',
            activeId: 'products',
            actions: [
              MoolLocalNavigationAction(
                keyName: 'c26c-products',
                id: 'products',
                label: 'Products',
                icon: Icons.shopping_bag_outlined,
                onPressed: null,
              ),
              MoolLocalNavigationAction(
                keyName: 'c26c-wholesale',
                id: 'wholesale',
                label: 'Wholesale',
                icon: Icons.inventory_2_outlined,
                onPressed: () {},
              ),
              MoolLocalNavigationAction(
                keyName: 'c26c-orders',
                id: 'orders',
                label: 'Orders',
                icon: Icons.receipt_long_outlined,
                onPressed: () {},
              ),
            ],
          ),
          onOpenMool: null,
          onOpenAction: (action) => onOpenRoute(action.route),
          onOpenChat: null,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
