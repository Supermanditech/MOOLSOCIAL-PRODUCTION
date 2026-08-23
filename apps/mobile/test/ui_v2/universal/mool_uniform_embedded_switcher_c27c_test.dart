import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

void main() {
  const backgrounds = <Color>[
    Color(0xFF05055C),
    Color(0xFFFFD6AD),
    Color(0xFFF4F6FA),
    Colors.white,
    Color(0xFF003D48),
    Color(0xFFF7F7FA),
  ];

  testWidgets('C27C every family uses one embedded switcher visual system', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    expect(MoolLocalNavigationTokens.switcherWidth, 136);
    expect(MoolLocalNavigationTokens.switcherRadius, 16);
    expect(MoolLocalNavigationTokens.switcherRowHeight, 56);
    expect(MoolLocalNavigationTokens.switcherIconSize, 22);

    for (
      var selectedIndex = 0;
      selectedIndex < moolActionFamilies.length;
      selectedIndex++
    ) {
      final selectedFamily = moolActionFamilies[selectedIndex];
      await _mountPanel(
        tester,
        family: selectedFamily,
        background: backgrounds[selectedIndex],
      );

      final panel = find.byKey(const Key('mool-connected-action-navigator'));
      expect(tester.getSize(panel).width, 136);
      expect(tester.getSize(panel).height, 344);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(
        find.descendant(of: panel, matching: find.byType(BackdropFilter)),
        findsOneWidget,
      );

      final glass = tester.widget<DecoratedBox>(
        find.byKey(const Key('moolsocial-uniform-switcher-glass')),
      );
      final glassDecoration = glass.decoration as BoxDecoration;
      expect(glassDecoration.color, MoolLocalNavigationTokens.switcherCanvas);
      expect(
        (glassDecoration.border as Border).top.color,
        MoolLocalNavigationTokens.switcherBorder,
      );
      expect(glassDecoration.gradient, isNull);

      for (final family in moolActionFamilies) {
        final row = find.byKey(ValueKey('mool-navigator-family-${family.id}'));
        expect(tester.getSize(row).height, 56);

        final label = tester.widget<Text>(
          find.descendant(of: row, matching: find.text(family.label)),
        );
        expect(label.style?.fontFamily, 'Inter');
        expect(label.style?.fontSize, 10.5);
        expect(
          label.style?.fontWeight,
          family.id == selectedFamily.id ? FontWeight.w800 : FontWeight.w700,
        );

        final icon = tester.widget<Icon>(
          find.descendant(of: row, matching: find.byIcon(family.icon)),
        );
        expect(icon.size, 22);
        expect(
          icon.color,
          MoolLocalNavigationTokens.navigationAccentForFamily(family.id),
        );

        final indicator = find.byKey(
          ValueKey('mool-navigator-family-${family.id}-indicator'),
        );
        if (family.id == selectedFamily.id) {
          expect(tester.getSize(indicator), const Size(2, 18));
        } else {
          expect(indicator, findsNothing);
        }
      }
    }
  });

  testWidgets('C27C switcher keeps approved motion and dismissal behavior', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _mount(
      tester,
      family: moolActionFamilyById('buy'),
      background: Colors.black,
      disableAnimations: true,
    );
    await tester.drag(
      find.byKey(const Key('mool-compact-launcher')),
      const Offset(0, -90),
    );
    await tester.pump();
    final arrival = tester.widget<ScaleTransition>(
      find.byKey(const Key('moolsocial-main-menu-arrival-motion')),
    );
    expect(arrival.scale.value, 1);

    await tester.tap(find.byKey(const Key('mool-switcher-outside-dismiss')));
    await tester.pump();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );
  });
}

Future<void> _mountPanel(
  WidgetTester tester, {
  required MoolActionFamilySpec family,
  required Color background,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: background)),
            Align(
              alignment: Alignment.bottomLeft,
              child: SizedBox(
                width: MoolLocalNavigationTokens.switcherWidth,
                child: MoolConnectedActionNavigator(
                  initialFamilyId: family.id,
                  onOpenFamily: (_) {},
                  onDismiss: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _mount(
  WidgetTester tester, {
  required MoolActionFamilySpec family,
  required Color background,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: Scaffold(
        body: ColoredBox(color: background),
        bottomNavigationBar: MoolDestinationNavigationV2(
          activeId: family.id,
          destinationLabel: family.label,
          selectedLocalIndex: 0,
          localActionCount: family.actions.length,
          localNavigation: MoolLocalNavigationRail(
            familyId: family.id,
            semanticLabel: '${family.label} actions',
            activeId: family.actions.first.id,
            actions: [
              for (var index = 0; index < family.actions.length; index++)
                MoolLocalNavigationAction(
                  keyName: 'c27c-${family.id}-${family.actions[index].id}',
                  id: family.actions[index].id,
                  label: family.actions[index].label,
                  icon: family.actions[index].icon,
                  onPressed: index == 0 ? null : () {},
                ),
            ],
          ),
          onOpenMool: null,
          onOpenAction: (_) {},
          onOpenChat: null,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
