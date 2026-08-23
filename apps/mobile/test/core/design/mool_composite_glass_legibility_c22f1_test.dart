import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';

const _families = ['social', 'buy', 'eat', 'ride', 'book', 'work'];
const _backgrounds = <Color>[
  Colors.white,
  Color(0xFFFFA24A),
  Color(0xFF111827),
  Color(0xFFFF8A00),
  MoolBrand.identityNavy,
];

void main() {
  test('C22F1 keeps the neutral smoked glass visibly nonopaque', () {
    expect(MoolLocalNavigationTokens.neutralGlassTop, const Color(0xB30D1326));
    expect(
      MoolLocalNavigationTokens.neutralGlassBottom,
      const Color(0xAB050816),
    );
    for (final color in [
      MoolLocalNavigationTokens.neutralGlassTop,
      MoolLocalNavigationTokens.neutralGlassBottom,
    ]) {
      expect(color.a, lessThan(1));
      expect(
        1 - color.a,
        greaterThanOrEqualTo(
          MoolLocalNavigationTokens.minimumNeutralDestinationTransmission,
        ),
      );
    }
  });

  test('C22F1 qualifies white foreground through every composite state', () {
    const states = <({bool selected, bool pressed})>[
      (selected: false, pressed: false),
      (selected: true, pressed: false),
      (selected: false, pressed: true),
      (selected: true, pressed: true),
    ];

    for (final family in _families) {
      final emission = MoolLocalNavigationTokens.innerEmissionGradient(family);
      expect(
        emission.colors.first.a,
        lessThanOrEqualTo(MoolLocalNavigationTokens.maximumInnerEmissionAlpha),
      );
      for (final state in states) {
        final base = MoolLocalNavigationTokens.glassGradient(
          tone: MoolLocalNavigationSurfaceTone.media,
          selected: state.selected,
          pressed: state.pressed,
        );
        for (final background in _backgrounds) {
          for (final baseStop in base.colors) {
            final baseComposite = Color.alphaBlend(baseStop, background);
            final emissionStops = state.selected || state.pressed
                ? emission.colors
                : const [Colors.transparent];
            for (final emissionStop in emissionStops) {
              var composite = baseComposite;
              if (state.selected) {
                composite = Color.alphaBlend(emissionStop, composite);
              }
              if (state.pressed) {
                composite = Color.alphaBlend(
                  emissionStop.withValues(
                    alpha:
                        emissionStop.a *
                        MoolLocalNavigationTokens.pressedEmissionOpacity,
                  ),
                  composite,
                );
              }
              expect(
                _contrastRatio(
                  MoolLocalNavigationTokens.neutralForeground,
                  composite,
                ),
                greaterThanOrEqualTo(
                  MoolLocalNavigationTokens.minimumWhiteForegroundContrast,
                ),
                reason:
                    '$family selected=${state.selected} '
                    'pressed=${state.pressed} background=$background '
                    'base=$baseStop emission=$emissionStop',
              );
            }
          }
        }
      }
    }
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + .05) / (darker + .05);
}
