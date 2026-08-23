import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    'C30D Social footer is flat divider-free and keeps OPPO targets safe',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.viewPadding = const FakeViewPadding(top: 41, bottom: 44);
      addTearDown(tester.view.reset);
      final semantics = tester.ensureSemantics();
      final owners = _Owners();
      addTearDown(owners.dispose);

      await tester.pumpWidget(_app(owners.consumer()));
      await tester.pumpAndSettle();

      final systemUi = tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byKey(const Key('screen04-system-ui-style')),
          )
          .value;
      expect(systemUi.systemNavigationBarDividerColor, Colors.transparent);
      expect(systemUi.systemNavigationBarContrastEnforced, isFalse);

      final surface = tester.widget<Material>(
        find.byKey(const Key('moolsocial-compact-destination-rail')),
      );
      expect(surface.color, const Color(0xFF0F0F0F));
      expect(surface.elevation, 0);
      expect(surface.shadowColor, Colors.transparent);
      expect(surface.surfaceTintColor, Colors.transparent);

      final rail = find.byKey(const Key('screen04-context-tabs'));
      expect(tester.widget(rail), isA<SizedBox>());
      expect(
        tester.getSize(rail).height,
        MoolLocalNavigationTokens.destinationRailHeight,
      );
      for (final key in const [
        Key('screen04-rail-videos'),
        Key('screen04-rail-shorts'),
        Key('screen04-rail-create'),
        Key('screen04-rail-feed'),
        Key('social-global-chat'),
      ]) {
        expect(
          tester.getSemantics(find.byKey(key)).rect.height,
          greaterThanOrEqualTo(44),
          reason: key.toString(),
        );
      }
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Open MoolSocial main menu'))
            .rect
            .height,
        greaterThanOrEqualTo(44),
      );
      semantics.dispose();
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('C30D footer fits 320x568 at 140 percent text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);
    final owners = _Owners();
    addTearDown(owners.dispose);

    await tester.pumpWidget(
      _app(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.4),
          ),
          child: owners.consumer(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in const ['Home', 'Shorts', 'Create', 'Feed']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      tester.getRect(find.byKey(const Key('mool-compact-launcher'))).left,
      0,
    );
    expect(
      tester.getRect(find.byKey(const Key('social-global-chat'))).right,
      320,
    );
    expect(tester.takeException(), isNull);
  });

  test('C30D source removes the old Social footer line and elevation only', () {
    final source = File(
      'lib/ui_v2/social/social_v2_consumer.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('elevation: 12')));
    expect(
      source,
      isNot(contains('Border(top: BorderSide(color: Color(0xFF272727)))')),
    );
    expect(source, contains('systemNavigationBarDividerColor:'));
    expect(source, contains('systemNavigationBarContrastEnforced:'));
    expect(source, contains('moolAndroidExportedSemanticsClearance('));
  });
}

Widget _app(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(useMaterial3: true),
  home: child,
);

class _Owners {
  final journey = JourneySession();
  final creator = CreatorSession();
  final retailer = RetailerSession();
  final shared = SharedSession();

  SocialUniversalV2 consumer() => SocialUniversalV2(
    session: journey,
    creatorSession: creator,
    retailerSession: retailer,
    sharedSession: shared,
    initialSubAction: 'videos',
    youtubePublicAccessOverride: false,
    youtubeCreatorAccessOverride: false,
  );

  void dispose() {
    journey.dispose();
    creator.dispose();
    retailer.dispose();
    shared.dispose();
  }
}
