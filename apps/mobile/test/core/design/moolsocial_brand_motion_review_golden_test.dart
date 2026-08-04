import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_colors.dart';
import 'package:moolsocial/core/design/moolsocial_brand_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('founder full-wordmark application review', (tester) async {
    await tester.binding.setSurfaceSize(const Size(560, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Inter'),
        home: const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: _FounderReviewBoard()),
        ),
      ),
    );

    await expectLater(
      find.byKey(const ValueKey('brand-founder-review-board')),
      matchesGoldenFile('goldens/moolsocial-sleek-wordmark-review.png'),
    );
  });

  for (final phase in <(String, Duration)>[
    ('start', Duration.zero),
    ('wordmark-arrival', Duration(milliseconds: 320)),
    ('identity-line', Duration(milliseconds: 680)),
    ('settled', MoolSocialBrandMotion.duration),
  ]) {
    testWidgets('founder full-wordmark motion phase ${phase.$1}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 140));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Inter'),
          home: const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: _MotionPhaseCard()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(phase.$2);

      await expectLater(
        find.byKey(const ValueKey('brand-motion-phase-card')),
        matchesGoldenFile('goldens/moolsocial-sleek-wordmark-${phase.$1}.png'),
      );
    });
  }
}

class _MotionPhaseCard extends StatelessWidget {
  const _MotionPhaseCard();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const ValueKey('brand-motion-phase-card'),
      child: Container(
        width: 296,
        height: 112,
        decoration: BoxDecoration(
          color: MoolColors.navy,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: MoolSocialBrandMotion(
            width: 190,
            height: 52,
            fontSize: 25,
            onDarkBackground: true,
          ),
        ),
      ),
    );
  }
}

class _FounderReviewBoard extends StatelessWidget {
  const _FounderReviewBoard();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const ValueKey('brand-founder-review-board'),
      child: Container(
        width: 536,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: MoolColors.navy.withValues(alpha: .12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'MoolSocial sleek wordmark motion',
              style: TextStyle(
                color: MoolColors.navy,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'One complete identity · one signature · fixed owner',
              style: TextStyle(
                color: MoolColors.navy.withValues(alpha: .65),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 112,
              decoration: BoxDecoration(
                color: MoolColors.navy,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(
                child: MoolSocialBrandMotion(
                  autoPlay: false,
                  width: 190,
                  height: 52,
                  fontSize: 25,
                  onDarkBackground: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                  child: _SurfaceCard(
                    title: 'Shared header',
                    width: 124,
                    height: 48,
                    fontSize: 14,
                    dark: true,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _SurfaceCard(
                    title: 'Buy tile',
                    width: 118,
                    height: 44,
                    fontSize: 10,
                    dark: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.title,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.dark,
  });

  final String title;
  final double width;
  final double height;
  final double fontSize;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? MoolColors.navy : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MoolColors.navy.withValues(alpha: .16)),
      ),
      child: Column(
        children: [
          MoolSocialBrandMotion(
            autoPlay: false,
            width: width,
            height: height,
            fontSize: fontSize,
            onDarkBackground: dark,
            surfaceColor: dark ? null : Colors.white,
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: dark ? Colors.white : MoolColors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
