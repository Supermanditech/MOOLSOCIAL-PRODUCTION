import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

void main() {
  const familyBackgrounds = <String, Color>{
    'social': Color(0xFF05055C),
    'buy': Color(0xFFFFD6AD),
    'eat': Color(0xFFF4F6FA),
    'ride': Colors.white,
    'book': Color(0xFF003D48),
    'work': Color(0xFFF7F7FA),
  };

  testWidgets('C27B all six families use one fixed visual token system', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    expect(MoolLocalNavigationTokens.railHeight, 58);
    expect(MoolLocalNavigationTokens.destinationRailHeight, 58);
    expect(MoolLocalNavigationTokens.destinationFixedCellWidth, 54);
    expect(MoolLocalNavigationTokens.destinationMinimumFixedCellWidth, 44);
    expect(MoolLocalNavigationTokens.destinationFixedCellWidthFor(320), 44);
    expect(MoolLocalNavigationTokens.destinationFixedCellWidthFor(390), 54);
    expect(MoolLocalNavigationTokens.destinationIconSize, 22);
    expect(MoolLocalNavigationTokens.destinationLabelSize, 10.5);
    expect(MoolLocalNavigationTokens.destinationFontFamily, 'Inter');

    for (final family in moolActionFamilies) {
      await _mount(
        tester,
        family: family,
        width: 320,
        background: familyBackgrounds[family.id]!,
      );

      final canvas = tester.widget<DecoratedBox>(
        find.byKey(const Key('moolsocial-uniform-destination-canvas')),
      );
      final decoration = canvas.decoration as BoxDecoration;
      expect(decoration.color, MoolLocalNavigationTokens.destinationCanvas);
      expect(decoration.gradient, isNull);
      expect(decoration.boxShadow, isNull);
      expect(decoration.borderRadius, isNull);

      final dock = find.byKey(const Key('moolsocial-compact-destination-rail'));
      expect(tester.getSize(dock).height, 58);
      expect(
        find.descendant(of: dock, matching: find.byType(FittedBox)),
        findsNothing,
      );
      expect(
        find.descendant(of: dock, matching: find.byType(BackdropFilter)),
        findsNothing,
      );
      expect(
        find.descendant(of: dock, matching: find.byType(Scrollable)),
        findsNothing,
      );

      expect(
        tester.getSize(find.byKey(const Key('mool-compact-launcher'))),
        const Size(44, 58),
      );
      expect(
        tester.getSize(find.byKey(const Key('mool-global-chat'))),
        const Size(44, 58),
      );
      expect(
        find.byKey(const Key('mool-compact-launcher-icon-label')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
      expect(find.text('Mool'), findsOneWidget);
      final familyRoot = find.byKey(
        ValueKey('moolsocial-family-root-${family.id}'),
      );
      if (family.id == 'social') {
        expect(familyRoot, findsNothing);
      } else {
        expect(tester.getSize(familyRoot), const Size(44, 58));
      }

      for (var index = 0; index < family.actions.length; index++) {
        final action = family.actions[index];
        final control = find.byKey(
          ValueKey('moolsocial-local-${action.id}-selection'),
        );
        final size = tester.getSize(control);
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, 58);

        final text = tester.widget<Text>(
          find.descendant(of: control, matching: find.text(action.label)),
        );
        expect(text.maxLines, 2);
        expect(text.style?.fontFamily, 'Inter');
        expect(text.style?.fontSize, 10.5);
        expect(
          text.style?.fontWeight,
          index == 0 ? FontWeight.w800 : FontWeight.w700,
        );
      }
    }
  });

  for (final width in const [320.0, 390.0, 430.0]) {
    testWidgets('C27B sparse actions stay compact and leading at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final familyId in const ['eat', 'buy', 'ride', 'work']) {
        final family = moolActionFamilyById(familyId);
        await _mount(
          tester,
          family: family,
          width: width,
          background: Colors.black,
        );

        final layout = find.byKey(
          const Key('moolsocial-local-navigation-adaptive-layout'),
        );
        final cluster = find.byKey(
          const Key('moolsocial-local-navigation-compact-cluster'),
        );
        expect(tester.getTopLeft(cluster).dx, tester.getTopLeft(layout).dx);
        if (family.actions.length == 2) {
          expect(tester.getSize(cluster).width, 152);
        } else if (family.actions.length == 3 && width >= 390) {
          expect(tester.getSize(cluster).width, 232);
        }
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('C27B keeps semantic controls above persistent bottom inset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final family = moolActionFamilyById('book');
    await _mount(
      tester,
      family: family,
      width: 360,
      background: Colors.black,
      bottomViewPadding: 24,
    );

    final shell = find.byKey(
      const Key('moolsocial-single-home-launcher-shell'),
    );
    expect(tester.getSize(shell).height, 82);
    expect(
      tester.getSize(find.bySemanticsLabel('Open MoolSocial main menu')),
      const Size(54, 58),
    );
    expect(
      tester.getSize(find.bySemanticsLabel('Open Care home')),
      const Size(54, 58),
    );
    expect(
      tester.getSize(find.byKey(const Key('mool-global-chat'))),
      const Size(54, 58),
    );
    expect(
      tester.getBottomRight(find.byKey(const Key('mool-compact-launcher'))).dy,
      tester.getBottomRight(shell).dy - 24,
    );

    final selected = find.byKey(
      const ValueKey('moolsocial-local-doctor-selected-indicator'),
    );
    expect(tester.getSize(selected), const Size(14, 2));
    final moolIndicator = tester.widget<AnimatedOpacity>(
      find.byKey(const Key('mool-launcher-expanded-indicator')),
    );
    expect(moolIndicator.opacity, 0);
  });
}

Future<void> _mount(
  WidgetTester tester, {
  required MoolActionFamilySpec family,
  required double width,
  required Color background,
  double bottomViewPadding = 0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 844),
          textScaler: const TextScaler.linear(1.4),
          viewPadding: EdgeInsets.only(bottom: bottomViewPadding),
        ),
        child: Scaffold(
          extendBody: true,
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
                    keyName: 'c27b-${family.id}-${family.actions[index].id}',
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
    ),
  );
  await tester.pumpAndSettle();
}
