import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';

void main() {
  test('C22B freezes one fixed medicine-capsule geometry', () {
    expect(MoolLocalNavigationTokens.capsuleWidth, 72);
    expect(MoolLocalNavigationTokens.controlHeight, 48);
    expect(MoolLocalNavigationTokens.controlRadius, 24);
    expect(MoolLocalNavigationTokens.itemGap, 8);
    expect(MoolLocalNavigationTokens.iconSize, 18);
    expect(MoolLocalNavigationTokens.labelFontSize, 12);
    expect(MoolLocalNavigationTokens.labelFontWeight, FontWeight.w800);

    expect(MoolLocalNavigationTokens.clusterWidth(320, 2), 152);
    expect(MoolLocalNavigationTokens.clusterWidth(320, 3), 232);
    expect(MoolLocalNavigationTokens.clusterWidth(320, 4), 312);
    expect(MoolLocalNavigationTokens.clusterWidth(412, 2), 152);
    expect(MoolLocalNavigationTokens.clusterWidth(412, 3), 232);
    expect(MoolLocalNavigationTokens.clusterWidth(412, 4), 312);
    for (final count in [2, 3, 4]) {
      expect(MoolLocalNavigationTokens.cellWidth(320, count), 72);
      expect(MoolLocalNavigationTokens.cellWidth(412, count), 72);
    }
  });

  test('C22B removes family tone from the neutral capsule base', () {
    for (final selected in [false, true]) {
      for (final pressed in [false, true]) {
        final light = MoolLocalNavigationTokens.glassGradient(
          tone: MoolLocalNavigationSurfaceTone.light,
          selected: selected,
          pressed: pressed,
        );
        final media = MoolLocalNavigationTokens.glassGradient(
          tone: MoolLocalNavigationSurfaceTone.media,
          selected: selected,
          pressed: pressed,
        );
        expect(light.colors, media.colors);
        expect(light.colors.first.a, lessThan(0.79));
        expect(light.colors.last.a, lessThan(0.76));
      }
    }

    expect(
      1 - MoolLocalNavigationTokens.neutralGlassTop.a,
      greaterThanOrEqualTo(
        MoolLocalNavigationTokens.minimumNeutralDestinationTransmission,
      ),
    );
    expect(
      1 - MoolLocalNavigationTokens.neutralGlassBottom.a,
      greaterThanOrEqualTo(
        MoolLocalNavigationTokens.minimumNeutralDestinationTransmission,
      ),
    );

    expect(
      MoolLocalNavigationTokens.foreground(
        MoolLocalNavigationSurfaceTone.light,
      ),
      MoolBrand.identityWhite,
    );
    expect(
      MoolLocalNavigationTokens.foreground(
        MoolLocalNavigationSurfaceTone.media,
      ),
      MoolBrand.identityWhite,
    );
  });

  testWidgets('C22B renders four equal clipped glass capsules at 320 px', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: 320,
              child: MoolLocalNavigationRail(
                familyId: 'buy',
                semanticLabel: 'Buy options',
                activeId: 'shop',
                actions: [
                  for (final entry in const [
                    ('shop', 'Shop', Icons.shopping_bag_outlined),
                    ('wholesale', 'Wholesale', Icons.inventory_2_outlined),
                    ('medicine', 'Medicine', Icons.medical_services_outlined),
                    ('orders', 'Orders', Icons.receipt_long_outlined),
                  ])
                    MoolLocalNavigationAction(
                      keyName: 'c22b-${entry.$1}',
                      id: entry.$1,
                      label: entry.$2,
                      icon: entry.$3,
                      onPressed: entry.$1 == 'shop' ? null : () {},
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final id in ['shop', 'wholesale', 'medicine', 'orders']) {
      expect(tester.getSize(find.byKey(Key('c22b-$id'))), const Size(72, 48));
      final glass = tester.widget<AnimatedContainer>(
        find.byKey(ValueKey('moolsocial-local-$id-glass-control')),
      );
      final decoration = glass.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(24));
      expect(decoration.gradient, isA<LinearGradient>());
    }

    expect(
      find.byKey(const ValueKey('moolsocial-local-shop-selected-indicator')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
