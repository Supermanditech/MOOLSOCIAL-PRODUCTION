import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/mool_theme.dart';

class JourneyFrame extends StatelessWidget {
  const JourneyFrame({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.child,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MoolColors.navy,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const PrototypeBrandHeader(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (eyebrow.isNotEmpty) ...[
                          Text(
                            eyebrow.toUpperCase(),
                            style: const TextStyle(
                              color: MoolColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          title,
                          style: const TextStyle(
                            color: MoolColors.navy,
                            fontSize: 29,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          description,
                          style: const TextStyle(
                            color: MoolColors.navy,
                            fontSize: 13,
                            height: 1.42,
                          ),
                        ),
                        const SizedBox(height: 14),
                        child,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PrototypeBrandHeader extends StatelessWidget {
  const PrototypeBrandHeader({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MoolColors.navy,
      padding: compact
          ? const EdgeInsets.fromLTRB(12, 10, 12, 9)
          : const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MoolSocial',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              height: .95,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 5 : 10),
          PrototypeIdentityLine(
            width: compact ? 118 : 126,
            height: compact ? 3 : 4,
          ),
          if (!compact) ...[
            const SizedBox(height: 10),
            const Text(
              'India Ka Socio Commerce App',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PrototypeIdentityLine extends StatelessWidget {
  const PrototypeIdentityLine({
    super.key,
    this.width = 126,
    this.height = 4,
    this.saffronFlex = 45,
    this.whiteFlex = 14,
    this.greenFlex = 41,
  });

  final double width;
  final double height;
  final int saffronFlex;
  final int whiteFlex;
  final int greenFlex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: saffronFlex,
              child: const ColoredBox(color: MoolColors.orange),
            ),
            Expanded(
              flex: whiteFlex,
              child: const ColoredBox(color: Colors.white),
            ),
            Expanded(
              flex: greenFlex,
              child: const ColoredBox(color: MoolColors.success),
            ),
          ],
        ),
      ),
    );
  }
}
