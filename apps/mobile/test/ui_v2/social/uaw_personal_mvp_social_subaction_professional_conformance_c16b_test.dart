import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_design_system.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'C29N Social keeps four middle actions between global white edges',
    (tester) async {
      await _mount(tester, textScale: 1.4);

      final dock = find.byKey(const Key('screen04-context-tabs'));
      final mool = find.byKey(const Key('mool-compact-launcher'));
      final chat = find.byKey(const Key('social-global-chat'));
      expect(dock, findsOneWidget);
      expect(mool, findsOneWidget);
      expect(chat, findsOneWidget);
      expect(find.byType(MoolLocalNavigationRail), findsNothing);
      expect(
        find.descendant(of: dock, matching: find.byType(BackdropFilter)),
        findsNothing,
      );
      expect(MoolLocalNavigationTokens.destinationRailHeight, 58);
      expect(tester.getSize(mool).width, 44);
      expect(tester.getSize(mool).height, greaterThanOrEqualTo(44));
      expect(tester.getSize(chat).width, 44);
      expect(tester.getSize(chat).height, greaterThanOrEqualTo(44));
      expect(tester.getCenter(mool).dx, lessThan(tester.getCenter(chat).dx));
      expect(
        tester
            .widget<Material>(
              find.byKey(const Key('mool-compact-launcher-white-surface')),
            )
            .color,
        Colors.white,
      );
      expect(
        tester
            .widget<Material>(
              find.byKey(const Key('mool-global-chat-white-surface')),
            )
            .color,
        Colors.white,
      );

      for (final id in const ['videos', 'shorts', 'create', 'feed']) {
        final action = find.byKey(Key('screen04-rail-$id'));
        final size = tester.getSize(action);
        expect(size.width, greaterThanOrEqualTo(44), reason: id);
        expect(size.height, greaterThanOrEqualTo(44), reason: id);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('C29N Social preserves ownership semantics and reduced motion', (
    tester,
  ) async {
    await _mount(tester, textScale: 1.4, reducedMotion: true);

    final shorts = find.byKey(const Key('screen04-rail-shorts'));
    final home = find.byKey(const Key('screen04-rail-videos'));
    var node = tester.getSemantics(shorts);
    expect(node.label, 'Shorts, current, YouTube');
    expect(node.flagsCollection.isSelected, Tristate.isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    node = tester.getSemantics(home);
    expect(node.label, 'Open Home, YouTube');
    expect(node.flagsCollection.isSelected, Tristate.isFalse);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    final selection = tester.widget<AnimatedContainer>(
      find.descendant(of: shorts, matching: find.byType(AnimatedContainer)),
    );
    expect(selection.duration, Duration.zero);

    await tester.tap(home);
    await tester.pump();
    node = tester.getSemantics(home);
    expect(node.label, 'Home, current, YouTube');
    expect(node.flagsCollection.isSelected, Tristate.isTrue);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _mount(
  WidgetTester tester, {
  double textScale = 1,
  bool reducedMotion = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 568);
  addTearDown(tester.view.reset);
  final owners = _Owners();
  addTearDown(owners.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
          accessibleNavigation: reducedMotion,
        ),
        child: child!,
      ),
      home: SocialUniversalV2(
        session: owners.journey,
        creatorSession: owners.creator,
        retailerSession: owners.retailer,
        sharedSession: owners.shared,
        initialSubAction: 'shorts',
        youtubePublicAccessOverride: false,
        youtubeCreatorAccessOverride: false,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Owners {
  final journey = JourneySession();
  final creator = CreatorSession();
  final retailer = RetailerSession();
  final shared = SharedSession();

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
  }
}
