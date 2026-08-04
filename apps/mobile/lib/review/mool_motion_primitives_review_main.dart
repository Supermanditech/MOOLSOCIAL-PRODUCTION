import 'package:flutter/material.dart';

import '../core/design/mool_design_system.dart';
import '../core/design/mool_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MoolMotionPrimitivesReviewApp());
}

/// Evidence-only entrypoint for DES-001. Production continues through
/// `main.dart`; this target makes the isolated primitives reviewable on-device.
class MoolMotionPrimitivesReviewApp extends StatelessWidget {
  const MoolMotionPrimitivesReviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MoolSocial motion review',
      theme: MoolTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
      home: const MoolMotionPrimitivesReviewScreen(),
    );
  }
}

class MoolMotionPrimitivesReviewScreen extends StatefulWidget {
  const MoolMotionPrimitivesReviewScreen({super.key});

  @override
  State<MoolMotionPrimitivesReviewScreen> createState() =>
      _MoolMotionPrimitivesReviewScreenState();
}

class _MoolMotionPrimitivesReviewScreenState
    extends State<MoolMotionPrimitivesReviewScreen> {
  int stage = 0;

  static const gradients = MoolBrandGradient.values;
  static const labels = <String>[
    'Ready',
    'Text changed',
    'Icon changed',
    'State settled',
  ];
  static const icons = <IconData>[
    Icons.motion_photos_on_outlined,
    Icons.text_fields_rounded,
    Icons.auto_awesome_motion_rounded,
    Icons.check_circle_outline_rounded,
  ];

  void next() => setState(() => stage = (stage + 1) % gradients.length);

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width <= 340;
    final contentWidth = compact ? 288.0 : 336.0;
    return Scaffold(
      backgroundColor: MoolBrand.identityWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MoolSpacing.md),
            child: Semantics(
              container: true,
              label: 'Shared motion primitives review',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'MoolSocial',
                    style: TextStyle(
                      color: MoolBrand.identityNavy,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                  const Text(
                    'Shared finite motion',
                    style: TextStyle(
                      color: MoolBrand.identityNavy,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.lg),
                  SizedBox(
                    width: contentWidth,
                    height: 236,
                    child: MoolFiniteGradientTransition(
                      key: const Key('motion-review-gradient'),
                      gradient: gradients[stage],
                      borderRadius: BorderRadius.circular(MoolRadii.card),
                      padding: const EdgeInsets.all(MoolSpacing.lg),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: MoolBrand.identityWhite,
                          borderRadius: BorderRadius.circular(
                            MoolRadii.control,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            MoolFiniteIconTransition(
                              key: const Key('motion-review-icon'),
                              stateKey: stage,
                              icon: icons[stage],
                              semanticLabel: '${labels[stage]} icon',
                              iconSize: 30,
                            ),
                            const SizedBox(height: MoolSpacing.sm),
                            MoolFiniteTextTransition(
                              key: const Key('motion-review-text'),
                              stateKey: stage,
                              text: labels[stage],
                              ownerSize: Size(contentWidth - 72, 44),
                              style: const TextStyle(
                                color: MoolBrand.identityNavy,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: MoolSpacing.xs),
                            MoolFiniteStateTransition(
                              key: const Key('motion-review-state'),
                              stateKey: stage,
                              ownerSize: Size(contentWidth - 72, 36),
                              semanticLabel: 'State ${stage + 1} of 4',
                              child: Text(
                                'Finite · event-driven · ${stage + 1}/4',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: MoolBrand.identityGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.lg),
                  SizedBox(
                    width: contentWidth,
                    child: FilledButton.icon(
                      key: const Key('motion-primitives-next'),
                      onPressed: next,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Show next state'),
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  Text(
                    MoolMotion.isReduced(context)
                        ? 'Reduced motion · immediate final state'
                        : 'Motion settles once after each tap',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: MoolBrand.identityNavy,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
