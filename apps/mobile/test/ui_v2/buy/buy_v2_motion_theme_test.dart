import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_design.dart';

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = foreground == lighter ? background : foreground;
  return (lighter.computeLuminance() + .05) / (darker.computeLuminance() + .05);
}

void main() {
  group('Buy V2 motion and theme foundations', () {
    test('motion tokens are finite, restrained and ordered by intent', () {
      const durations = [
        BuyV2Motion.press,
        BuyV2Motion.selection,
        BuyV2Motion.stateChange,
        BuyV2Motion.contentChange,
        BuyV2Motion.expandCollapse,
        BuyV2Motion.routeChange,
        BuyV2Motion.success,
        BuyV2Motion.recovery,
        BuyV2Motion.brandReveal,
      ];

      expect(durations.every((duration) => duration > Duration.zero), isTrue);
      expect(
        durations.every(
          (duration) => duration <= const Duration(milliseconds: 420),
        ),
        isTrue,
      );
      expect(BuyV2Motion.press, lessThan(BuyV2Motion.routeChange));
      expect(BuyV2Motion.pressScale, inInclusiveRange(.98, 1));
    });

    test('each commerce vertical has a distinct related theme', () {
      final themes = {
        for (final destination in BuyV2Destination.values)
          destination: BuyV2ThemeSpec.resolve(destination, BuyV2View.catalogue),
      };

      expect(themes.values.map((theme) => theme.canvas).toSet(), hasLength(4));
      expect(themes.values.map((theme) => theme.accent).toSet(), hasLength(4));
      for (final theme in themes.values) {
        expect(_contrastRatio(Colors.white, theme.headerStart), greaterThan(7));
        expect(_contrastRatio(Colors.white, theme.headerEnd), greaterThan(7));
      }
    });

    test('tertiary surfaces use stable semantic theme families', () {
      final catalogue = BuyV2ThemeSpec.resolve(
        BuyV2Destination.wholesale,
        BuyV2View.catalogue,
      );
      final cart = BuyV2ThemeSpec.resolve(
        BuyV2Destination.wholesale,
        BuyV2View.cart,
      );
      final tracking = BuyV2ThemeSpec.resolve(
        BuyV2Destination.wholesale,
        BuyV2View.tracking,
      );
      final assist = BuyV2ThemeSpec.resolve(
        BuyV2Destination.wholesale,
        BuyV2View.assist,
      );

      expect(cart.accent, BuyV2Colors.orange);
      expect(tracking.accent, BuyV2Colors.green);
      expect(assist.accent, BuyV2Colors.royal);
      expect(catalogue.canvas, isNot(cart.canvas));
      expect(tracking.canvas, isNot(assist.canvas));
    });
  });
}
