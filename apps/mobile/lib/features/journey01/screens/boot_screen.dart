import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design/mool_theme.dart';
import '../journey_session.dart';
import '../widgets/journey_frame.dart';

class BootScreen extends StatefulWidget {
  const BootScreen({required this.session, super.key});

  final JourneySession session;

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(
      const Duration(milliseconds: 650),
      widget.session.start,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MoolColors.navy,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: MoolColors.navy,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MoolColors.navy,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: widget.session,
            builder: (context, _) => Semantics(
              label: 'MoolSocial is opening',
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 34, 26, 26),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                            const SizedBox(height: 10),
                            const PrototypeIdentityLine(width: 126),
                            const SizedBox(height: 10),
                            Container(
                              constraints: const BoxConstraints(minHeight: 30),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'India Ka Socio Commerce App',
                                style: TextStyle(
                                  color: MoolColors.navy,
                                  fontSize: 12,
                                  height: 1.35,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (widget.session.stage ==
                                JourneyStage.bootFailure) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .08),
                                  border: Border.all(color: Colors.white),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      widget.session.errorMessage ??
                                          'MoolSocial could not open safely.',
                                      key: const Key('boot-error'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    FilledButton.tonal(
                                      key: const Key('retry-boot'),
                                      onPressed: widget.session.busy
                                          ? null
                                          : widget.session.retryBoot,
                                      child: const Text('Try again'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (widget.session.stage != JourneyStage.bootFailure) ...[
                      const Row(
                        children: [
                          SizedBox(
                            width: 9,
                            height: 9,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: MoolColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Opening your MoolSocial space',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const PrototypeIdentityLine(
                        width: 340,
                        height: 5,
                        saffronFlex: 46,
                        greenFlex: 40,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
