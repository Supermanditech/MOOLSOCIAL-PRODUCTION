import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_service_home.dart';

void main() {
  test('C24B freezes the shared service-home scale', () {
    expect(MoolServiceHomeTokens.pagePadding, 16);
    expect(MoolServiceHomeTokens.sectionGap, 24);
    expect(MoolServiceHomeTokens.cardRadius, 18);
    expect(MoolServiceHomeTokens.searchHeight, 52);
    expect(MoolServiceHomeTokens.primaryActionHeight, 48);
    expect(MoolServiceHomeTokens.displaySize, 28);
    expect(MoolServiceHomeTokens.sectionTitleSize, 20);
    expect(MoolServiceHomeTokens.cardTitleSize, 16);
    expect(MoolServiceHomeTokens.bodySize, 14);
    expect(MoolServiceHomeTokens.metadataSize, 12);
  });

  for (final width in const [320.0, 390.0, 430.0]) {
    testWidgets('C24B shared hierarchy adapts at ${width.toInt()}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: MoolServiceHomeTokens.page,
            body: ListView(
              padding: const EdgeInsets.all(MoolServiceHomeTokens.pagePadding),
              children: [
                const MoolServiceSearchField(
                  key: Key('service-search'),
                  hintText: 'Search services',
                ),
                const SizedBox(height: MoolServiceHomeTokens.sectionGap),
                const MoolServiceSectionHeader(
                  title: 'Nearby services',
                  subtitle: 'Price and time before booking',
                ),
                const SizedBox(height: MoolServiceHomeTokens.cardGap),
                MoolServiceCard(
                  key: const Key('service-card'),
                  title: 'Clinic care',
                  subtitle: 'Verified provider · available today',
                  icon: Icons.medical_services_outlined,
                  semanticLabel: 'Open clinic care',
                  metadata: const [
                    MoolServiceMeta(icon: Icons.star_rounded, label: '4.8'),
                    MoolServiceMeta(
                      icon: Icons.schedule_rounded,
                      label: '12 min',
                    ),
                  ],
                  onTap: () => taps++,
                ),
                const SizedBox(height: MoolServiceHomeTokens.cardGap),
                MoolServicePrimaryButton(
                  key: const Key('service-primary'),
                  label: 'Continue',
                  onPressed: () => taps++,
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byKey(const Key('service-search'))).height,
        greaterThanOrEqualTo(MoolServiceHomeTokens.searchHeight),
      );
      expect(
        tester.getSize(find.byKey(const Key('service-primary'))).height,
        greaterThanOrEqualTo(MoolServiceHomeTokens.primaryActionHeight),
      );
      final cardNode = tester.getSemantics(
        find.bySemanticsLabel('Open clinic care'),
      );
      expect(
        cardNode.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      await tester.tap(find.byKey(const Key('service-card')));
      await tester.tap(find.byKey(const Key('service-primary')));
      expect(taps, 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('C24B large text and reduced motion remain immediate', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          textScaler: TextScaler.linear(1.4),
          disableAnimations: true,
          accessibleNavigation: true,
        ),
        child: MaterialApp(
          home: Scaffold(
            body: MoolServiceCard(
              title: 'Long service title remains readable',
              subtitle:
                  'Provider, timing and price information wraps without hiding the action.',
              icon: Icons.work_outline_rounded,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      MoolServiceHomeTokens.accessibleDuration(
        tester.element(find.byType(MoolServiceCard)),
      ),
      Duration.zero,
    );
    expect(tester.takeException(), isNull);
  });
}
