import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Screen03FrameV2 extends StatelessWidget {
  const Screen03FrameV2({
    required this.child,
    required this.screenKey,
    super.key,
  });

  final Widget child;
  final Key screenKey;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Screen03Colors.navy,
        systemNavigationBarColor: Screen03Colors.navy,
      ),
      child: Scaffold(
        key: screenKey,
        backgroundColor: Screen03Colors.navy,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _BrandHeader(),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  child: ColoredBox(color: Colors.white, child: child),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 116,
      child: Padding(
        padding: EdgeInsets.fromLTRB(27, 20, 27, 14),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MoolSocial',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontSize: 25,
                  height: .95,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              SizedBox(height: 11),
              _IdentityLine(),
              SizedBox(height: 11),
              Text(
                'India Ka Socio Commerce App',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontSize: 12,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityLine extends StatelessWidget {
  const _IdentityLine();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: const SizedBox(
        width: 126,
        height: 4,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 45,
              child: ColoredBox(color: Screen03Colors.saffron),
            ),
            Expanded(flex: 14, child: ColoredBox(color: Colors.white)),
            Expanded(flex: 41, child: ColoredBox(color: Screen03Colors.green)),
          ],
        ),
      ),
    );
  }
}

abstract final class Screen03Colors {
  static const navy = Color(0xFF080090);
  static const green = Color(0xFF079216);
  static const saffron = Color(0xFFFFA51A);
  static const muted = Color(0xFF4C4C62);
  static const borderSoft = Color(0x24000080);
  static const pale = Color(0xFFF5F6FF);
  static const danger = Color(0xFFC62828);
}

abstract final class Screen03Text {
  static const title = TextStyle(
    color: Screen03Colors.navy,
    fontFamily: 'Inter',
    fontSize: 29,
    height: 1.05,
    fontWeight: FontWeight.w900,
  );

  static const body = TextStyle(
    color: Screen03Colors.navy,
    fontFamily: 'Inter',
    fontSize: 13,
    height: 1.42,
  );

  static const cardLabel = TextStyle(
    color: Screen03Colors.green,
    fontFamily: 'Inter',
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w900,
  );
}
