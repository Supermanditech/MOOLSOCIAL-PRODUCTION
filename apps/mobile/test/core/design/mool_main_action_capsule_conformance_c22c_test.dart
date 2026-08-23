import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';

void main() {
  testWidgets('C22C gives all six middle main actions the C22B capsule', (
    tester,
  ) async {
    final actions = <MoolDockAction>[
      for (final entry in const [
        ('social', 'Social', Icons.people_outline_rounded),
        ('buy', 'Buy', Icons.shopping_bag_outlined),
        ('eat', 'Eat', Icons.restaurant_outlined),
        ('ride', 'Ride', Icons.directions_car_outlined),
        ('book', 'Book', Icons.calendar_month_outlined),
        ('work', 'Work', Icons.work_outline_rounded),
      ])
        MoolDockAction(
          keyName: 'mool-action-${entry.$1}',
          id: entry.$1,
          label: entry.$2,
          icon: entry.$3,
          semanticLabel: entry.$1 == 'social'
              ? 'Social, current. Hide Social options'
              : 'Open ${entry.$2}',
          disclosureExpanded: entry.$1 == 'social' ? true : null,
          onPressed: () {},
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MoolOutcomeDock(
            semanticLabel: 'MoolSocial navigation',
            activeId: 'social',
            showOverflowCue: true,
            mool: MoolDockAction(
              keyName: 'mool-root-selected',
              id: 'mool',
              label: 'Mool',
              icon: MoolBrand.moolLauncherIcon,
              onPressed: () {},
            ),
            actions: actions,
            chat: MoolDockAction(
              keyName: 'mool-root-chat',
              id: 'chat',
              label: 'Chat',
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    var priorX = -1.0;
    for (final entry in actions) {
      final button = find.byKey(Key(entry.keyName));
      expect(button, findsOneWidget);
      expect(
        tester.getSize(button),
        const Size(
          MoolLocalNavigationTokens.capsuleWidth,
          MoolLocalNavigationTokens.controlHeight,
        ),
      );
      final x = tester.getCenter(button).dx;
      expect(x, greaterThan(priorX));
      priorX = x;

      final label = tester.widget<Text>(
        find.descendant(of: button, matching: find.text(entry.label)),
      );
      expect(label.style?.fontSize, MoolLocalNavigationTokens.labelFontSize);
      expect(
        label.style?.fontWeight,
        MoolLocalNavigationTokens.labelFontWeight,
      );
      expect(label.style?.color, MoolLocalNavigationTokens.neutralForeground);

      final icon = tester.widget<Icon>(
        find.descendant(of: button, matching: find.byIcon(entry.icon)),
      );
      expect(icon.size, MoolLocalNavigationTokens.iconSize);
      expect(icon.color, MoolLocalNavigationTokens.neutralForeground);
    }

    final selectedCapsule = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('mool-action-social-capsule')),
    );
    final selectedDecoration = selectedCapsule.decoration! as BoxDecoration;
    expect(
      selectedDecoration.borderRadius,
      BorderRadius.circular(MoolLocalNavigationTokens.controlRadius),
    );
    expect(
      selectedDecoration.gradient,
      MoolLocalNavigationTokens.glassGradient(
        tone: MoolLocalNavigationSurfaceTone.media,
        selected: true,
        pressed: false,
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('mool-root-selected'))),
      const Size.square(MoolMetrics.minimumTapTarget),
    );
    expect(
      tester.getSize(find.byKey(const Key('mool-root-chat'))),
      const Size.square(MoolMetrics.minimumTapTarget),
    );
    expect(
      tester
          .getSemantics(find.byKey(const Key('mool-action-social')))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
