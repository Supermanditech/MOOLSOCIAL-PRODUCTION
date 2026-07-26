import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/social/social_v2_creator.dart';
import 'package:moolsocial/ui_v2/social/social_v2_plans_promotion.dart';
import 'package:moolsocial/ui_v2/social/social_v2_youtube_connect.dart';

final _forbiddenSocialCopy = RegExp(
  r'\b(?:production|prototype|founder review|review build|sample|example|demo|'
  r'mock|placeholder|working note|internal plan|implementation|workflow|'
  r'state machine|endpoint|payload|backend|provider callback|next screen|'
  r'for (?:review|testing))\b|dharmendra|@dharmendra',
  caseSensitive: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Social consumer and every Creator owner use customer-ready copy',
    (tester) async {
      final journey = JourneySession();
      final creator = CreatorSession()..creatorWorkspaceActive = true;
      final retailer = RetailerSession();
      final shared = SharedSession();
      addTearDown(journey.dispose);
      addTearDown(creator.dispose);
      addTearDown(retailer.dispose);
      addTearDown(shared.dispose);

      await _mount(
        tester,
        SocialUniversalV2(
          session: journey,
          creatorSession: creator,
          retailerSession: retailer,
          sharedSession: shared,
        ),
      );
      _expectCustomerCopy(tester, 'Social Shorts');

      for (final tab in const ['videos', 'feed', 'create']) {
        final action = find.byKey(Key('screen04-rail-$tab'));
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        _expectCustomerCopy(tester, 'Social $tab');
      }

      for (final state in const <String>[
        'post',
        'reel-source',
        'reel-camera',
        'reel-edit',
        'carousel',
        'drafts',
        'publishing',
        'failure',
        'success',
      ]) {
        await _mount(
          tester,
          SocialUniversalV2(
            session: journey,
            creatorSession: creator,
            retailerSession: retailer,
            sharedSession: shared,
            initialSubAction: 'create',
            initialState: state,
          ),
        );
        _expectCustomerCopy(tester, 'Social Create $state');
      }

      for (final owner in CreatorSocialV2Owner.values) {
        await _mount(
          tester,
          CreatorSocialV2Screen(session: creator, owner: owner),
        );
        _expectCustomerCopy(tester, 'Creator ${owner.name}');
      }

      for (final state in const <String>[
        'destinations',
        'preview',
        'publishing',
        'partial',
        'success',
      ]) {
        await _mount(
          tester,
          CreatorSocialV2Screen(
            session: creator,
            owner: CreatorSocialV2Owner.publish,
            initialState: state,
          ),
        );
        _expectCustomerCopy(tester, 'Creator publish $state');
      }

      final inactive = CreatorSession();
      addTearDown(inactive.dispose);
      await _mount(
        tester,
        CreatorSocialV2Screen(
          session: inactive,
          owner: CreatorSocialV2Owner.home,
          initialState: 'activate',
        ),
      );
      _expectCustomerCopy(tester, 'Creator activation');
    },
  );

  testWidgets('YouTube Connect copy stays customer-ready through every step', (
    tester,
  ) async {
    final session = CreatorSession()..creatorWorkspaceActive = true;
    addTearDown(session.dispose);
    await _mount(tester, SocialYouTubeConnectV2Screen(session: session));
    _expectCustomerCopy(tester, 'YouTube source');

    session.setYouTubeUrl('https://youtube.com/watch?v=moolsocial');
    expect(await tester.runAsync(session.validateYouTubeSource), isTrue);
    expect(session.continueToYouTubeAction(), isTrue);
    await tester.pump();
    _expectCustomerCopy(tester, 'YouTube action');

    session
      ..selectYouTubeAction('buy')
      ..confirmYouTubeRights(true)
      ..confirmYouTubeActionTruth(true);
    expect(session.continueToYouTubeReview(), isTrue);
    await tester.pump();
    _expectCustomerCopy(tester, 'YouTube check');

    expect(await tester.runAsync(session.publishYouTubeConnection), isTrue);
    await tester.pump();
    _expectCustomerCopy(tester, 'YouTube complete');
  });

  testWidgets('plans and Social promotion use customer-ready copy', (
    tester,
  ) async {
    final journey = JourneySession();
    final creator = CreatorSession()..creatorWorkspaceActive = true;
    final retailer = RetailerSession();
    final shared = SharedSession();
    addTearDown(journey.dispose);
    addTearDown(creator.dispose);
    addTearDown(retailer.dispose);
    addTearDown(shared.dispose);

    await _mount(
      tester,
      SocialPlansV2Screen(
        sharedSession: shared,
        retailerSession: retailer,
        creatorSession: creator,
      ),
    );
    _expectCustomerCopy(tester, 'Plans');

    await _mount(tester, SocialPromotionV2Screen(session: retailer));
    _expectCustomerCopy(tester, 'Social promotion');
    for (final state in const <(int?, String?)>[
      (2, null),
      (3, null),
      (4, null),
      (5, null),
      (null, 'failure'),
      (null, 'live'),
    ]) {
      await _mount(
        tester,
        SocialPromotionV2Screen(
          session: retailer,
          initialStep: state.$1,
          initialState: state.$2,
        ),
      );
      _expectCustomerCopy(tester, 'Social promotion $state');
    }
  });
}

Future<void> _mount(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      key: UniqueKey(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
      home: child,
    ),
  );
  await tester.pump();
}

void _expectCustomerCopy(WidgetTester tester, String owner) {
  final copy = <String>[];
  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    copy.add(text.data ?? text.textSpan?.toPlainText() ?? '');
  }
  for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
    final decoration = field.decoration;
    copy.addAll([
      decoration?.labelText ?? '',
      decoration?.hintText ?? '',
      decoration?.helperText ?? '',
      decoration?.prefixText ?? '',
      decoration?.suffixText ?? '',
    ]);
  }
  for (final semantics in tester.widgetList<Semantics>(
    find.byType(Semantics),
  )) {
    copy.add(semantics.properties.label ?? '');
    copy.add(semantics.properties.hint ?? '');
  }
  final visible = copy.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  final match = _forbiddenSocialCopy.firstMatch(visible);
  expect(
    match,
    isNull,
    reason:
        'Forbidden customer-facing wording "${match?.group(0)}" found in $owner. Visible copy: $visible',
  );
  expect(tester.takeException(), isNull, reason: owner);
}
