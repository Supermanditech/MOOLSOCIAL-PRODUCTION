import 'package:flutter/material.dart';

abstract final class BuyV2Colors {
  static const navy = Color(0xFF000080);
  static const royal = Color(0xFF1515B8);
  static const orange = Color(0xFFFF9933);
  static const green = Color(0xFF138808);
  static const ink = Color(0xFF11132F);
  static const muted = Color(0xFF626780);
  static const line = Color(0xFFE0E2EE);
  static const canvas = Color(0xFFF4F5FB);
  static const softOrange = Color(0xFFFFF0DE);
  static const softGreen = Color(0xFFEAF7E8);
  static const softBlue = Color(0xFFEDECFF);
}

abstract final class BuyV2Metrics {
  static const maxWidth = 520.0;
  static const railWidth = 94.0;
  static const dockHeight = 72.0;
  static const radius = 18.0;
  static const compactRadius = 13.0;
  static const minimumTap = 44.0;
}

class BuyV2TricolourLine extends StatelessWidget {
  const BuyV2TricolourLine({super.key, this.height = 3});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Row(
        children: [
          Expanded(child: ColoredBox(color: BuyV2Colors.orange)),
          Expanded(child: ColoredBox(color: Colors.white)),
          Expanded(child: ColoredBox(color: BuyV2Colors.green)),
        ],
      ),
    );
  }
}

BoxDecoration buyV2CardDecoration({
  Color color = Colors.white,
  Color border = BuyV2Colors.line,
  double radius = BuyV2Metrics.radius,
  bool shadow = false,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border),
    boxShadow: shadow
        ? const [
            BoxShadow(
              color: Color(0x13000040),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ]
        : null,
  );
}

extension BuyV2TextStyles on BuildContext {
  TextStyle get buyEyebrow => const TextStyle(
    color: BuyV2Colors.muted,
    fontSize: 10,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: .55,
  );

  TextStyle get buyTitle => const TextStyle(
    color: BuyV2Colors.ink,
    fontSize: 22,
    height: 1.08,
    fontWeight: FontWeight.w900,
    letterSpacing: -.5,
  );

  TextStyle get buyBody => const TextStyle(
    color: BuyV2Colors.ink,
    fontSize: 12,
    height: 1.25,
    fontWeight: FontWeight.w600,
  );

  TextStyle get buyMeta => const TextStyle(
    color: BuyV2Colors.muted,
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );
}
