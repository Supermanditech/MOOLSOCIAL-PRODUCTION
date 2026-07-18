import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/journey01/universal_intent_catalog.dart';

void main() {
  Future<JourneySession> readySession() async {
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'skipped',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    await session.start();
    return session;
  }

  Future<void> openSection(
    WidgetTester tester,
    JourneySession session,
    String section,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    await tester.pumpWidget(
      MoolSocialApp(session: session, initialLocation: '/app/$section'),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    expect(finder, findsOneWidget, reason: 'Missing tap target $key');
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  for (final section in const [
    'buy',
    'eat',
    'ride',
    'book',
    'pay',
    'work',
    'chat',
  ]) {
    testWidgets('$section completes every sub-action and option branch', (
      tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = await readySession();
      addTearDown(session.dispose);
      await openSection(tester, session, section);

      for (final spec in UniversalIntentCatalog.forSection(section)) {
        if ((section == 'buy' &&
                const {'grocery', 'categories', 'basket'}.contains(spec.id)) ||
            (section == 'eat' &&
                const {
                  'order-food',
                  'book-table',
                  'tiffin',
                }.contains(spec.id))) {
          continue;
        }
        await tapVisible(tester, Key('sub-action-$section-${spec.id}'));
        expect(find.text(spec.title), findsOneWidget);

        await tapVisible(tester, Key('open-intent-${spec.id}'));
        await tapVisible(tester, Key('intent-cancel-${spec.id}'));
        expect(find.text(spec.title), findsOneWidget);

        for (var option = 0; option < spec.options.length; option += 1) {
          await tapVisible(tester, Key('open-intent-${spec.id}'));
          await tapVisible(tester, Key('intent-option-${spec.id}-$option'));
          expect(find.text(spec.options[option].label), findsWidgets);
          await tapVisible(tester, Key('intent-confirm-${spec.id}'));
          expect(find.text(spec.resultTitle), findsOneWidget);
          await tapVisible(tester, Key('intent-done-${spec.id}'));
          expect(find.text(spec.title), findsOneWidget);
        }
      }
    });
  }

  testWidgets('Buy production entries open catalogue and basket routes', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = await readySession();
    addTearDown(session.dispose);
    await openSection(tester, session, 'buy');

    await tapVisible(tester, const Key('sub-action-buy-grocery'));
    await tapVisible(tester, const Key('open-intent-grocery'));
    expect(find.byKey(const Key('buy-catalog-screen')), findsOneWidget);

    await tapVisible(tester, const Key('buy-back'));
    expect(find.byKey(const Key('section-buy')), findsOneWidget);
    final horizontalActions = find.byWidgetPredicate(
      (widget) =>
          widget is ListView && widget.scrollDirection == Axis.horizontal,
    );
    await tester.drag(horizontalActions.first, const Offset(-240, 0));
    await tester.pumpAndSettle();
    await tapVisible(tester, const Key('sub-action-buy-basket'));
    await tapVisible(tester, const Key('open-intent-basket'));
    expect(find.byKey(const Key('buy-basket-screen')), findsOneWidget);
  });

  testWidgets('Eat production entries open order, table and tiffin routes', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = await readySession();
    addTearDown(session.dispose);
    await openSection(tester, session, 'eat');

    await tapVisible(tester, const Key('sub-action-eat-order-food'));
    await tapVisible(tester, const Key('open-intent-order-food'));
    expect(find.byKey(const Key('eat-order-screen')), findsOneWidget);

    await tapVisible(tester, const Key('eat-back'));
    expect(find.byKey(const Key('eat-home-screen')), findsOneWidget);
    await tapVisible(tester, const Key('eat-home-table'));
    expect(find.byKey(const Key('eat-table-screen')), findsOneWidget);

    await tapVisible(tester, const Key('eat-dock-tiffin'));
    expect(find.byKey(const Key('eat-tiffin-screen')), findsOneWidget);
  });

  testWidgets('Mool palette reaches every main action and returns safely', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = await readySession();
    addTearDown(session.dispose);
    await openSection(tester, session, 'social');

    for (final section in const [
      'buy',
      'eat',
      'ride',
      'book',
      'pay',
      'work',
      'social',
    ]) {
      await tapVisible(tester, const Key('nav-mool'));
      expect(find.byKey(Key('mool-action-$section')), findsOneWidget);
      await tapVisible(tester, Key('mool-action-$section'));
      expect(find.byKey(Key('section-$section')), findsOneWidget);
    }

    await tapVisible(tester, const Key('nav-mool'));
    await tapVisible(tester, const Key('close-mool'));
    expect(find.byKey(const Key('section-social')), findsOneWidget);
  });

  testWidgets('Social completes every tab, card action and action-rail tap', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = await readySession();
    addTearDown(session.dispose);
    await openSection(tester, session, 'social');

    Future<void> completeSheet(String primaryKey) async {
      final option = find.byKey(Key('social-action-option-$primaryKey-0'));
      if (option.evaluate().isNotEmpty) {
        await tapVisible(tester, Key('social-action-option-$primaryKey-0'));
      }
      final input = find.byKey(Key('social-action-input-$primaryKey'));
      if (input.evaluate().isNotEmpty) {
        await tester.enterText(input, 'A clear and useful response');
        await tester.pumpAndSettle();
      }
      await tapVisible(tester, Key('social-action-continue-$primaryKey'));
      await tapVisible(tester, Key('social-action-done-$primaryKey'));
    }

    Future<void> completeCardAction(String titleKey, String actionKey) async {
      await tapVisible(tester, Key('card-action-$titleKey-$actionKey'));
      await completeSheet(actionKey);
    }

    await tapVisible(tester, const Key('social-open-video'));
    await completeSheet('open-connected-video');
    await tapVisible(tester, const Key('social-how-it-works'));
    await completeSheet('got-it');

    await tapVisible(tester, const Key('social-tab-shorts'));
    await tapVisible(tester, const Key('social-open-short'));
    await completeSheet('play-video');
    for (final action in const ['record', 'caption', 'post']) {
      await completeCardAction('create-short', action);
    }
    await tapVisible(tester, const Key('social-action-follow'));
    await tapVisible(tester, const Key('social-action-follow'));
    await tapVisible(tester, const Key('social-action-like'));
    await tapVisible(tester, const Key('social-action-like'));
    for (final action in const [
      ('comments', 'write-reply'),
      ('share', 'choose-destination'),
      ('remix', 'start-remix'),
    ]) {
      await tapVisible(tester, Key('social-action-${action.$1}'));
      await completeSheet(action.$2);
    }
    await tapVisible(tester, const Key('social-action-save'));
    await tapVisible(tester, const Key('social-action-save'));
    await tapVisible(tester, const Key('social-action-more'));
    await completeSheet('choose-action');

    await tapVisible(tester, const Key('social-tab-videos'));
    await tapVisible(tester, const Key('social-open-short'));
    await completeSheet('play-video');
    for (final action in const ['resume', 'channel', 'save']) {
      await completeCardAction('continue-watching', action);
    }
    await tapVisible(tester, const Key('social-action-like'));
    await tapVisible(tester, const Key('social-action-comments'));
    await completeSheet('write-reply');
    await tapVisible(tester, const Key('social-action-share'));
    await completeSheet('choose-destination');
    await tapVisible(tester, const Key('social-action-follow'));
    await tapVisible(tester, const Key('social-action-follow'));
    await tapVisible(tester, const Key('social-action-save'));
    await tapVisible(tester, const Key('social-action-save'));
    await tapVisible(tester, const Key('social-action-more'));
    await completeSheet('choose-action');

    await tapVisible(tester, const Key('social-tab-feed'));
    for (final action in const ['like', 'comment', 'share']) {
      await completeCardAction('local-feed-post', action);
    }
    for (final action in const ['text', 'photo', 'area']) {
      await completeCardAction('create-post', action);
    }
    await tapVisible(tester, const Key('social-action-like'));
    await tapVisible(tester, const Key('social-action-reply'));
    await completeSheet('write-reply');
    await tapVisible(tester, const Key('social-action-repost'));
    await completeSheet('review-repost');
    await tapVisible(tester, const Key('social-action-share'));
    await completeSheet('choose-destination');
    await tapVisible(tester, const Key('social-action-save'));
    await tapVisible(tester, const Key('social-action-save'));
    await tapVisible(tester, const Key('social-action-profile'));
    await completeSheet('open-profile');

    await tapVisible(tester, const Key('social-tab-create'));
    for (final action in const ['text', 'photo', 'video', 'proof']) {
      await completeCardAction('create-social-post', action);
    }
    await tapVisible(tester, const Key('social-action-post'));
    await completeSheet('review-post');
    await tapVisible(tester, const Key('social-action-upload'));
    await completeSheet('choose-file');
    await tapVisible(tester, const Key('social-action-help'));
    await completeSheet('continue');
  });

  testWidgets('Social empty, unselected and cancelled actions stay safe', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = await readySession();
    addTearDown(session.dispose);
    await openSection(tester, session, 'social');

    await tapVisible(tester, const Key('social-action-comments'));
    await tapVisible(tester, const Key('social-action-continue-write-reply'));
    expect(find.text('Enter text to continue.'), findsOneWidget);
    await tapVisible(tester, const Key('social-action-cancel-write-reply'));
    expect(find.byKey(const Key('section-social')), findsOneWidget);

    await tapVisible(tester, const Key('social-action-share'));
    await tapVisible(
      tester,
      const Key('social-action-continue-choose-destination'),
    );
    expect(find.text('Choose an option to continue.'), findsOneWidget);
    await tapVisible(
      tester,
      const Key('social-action-cancel-choose-destination'),
    );
    expect(find.byKey(const Key('section-social')), findsOneWidget);
  });

  testWidgets('search, code, voice, profile and chat return cover recovery', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = await readySession();
    addTearDown(session.dispose);
    await openSection(tester, session, 'social');

    await tapVisible(tester, const Key('open-search'));
    await tester.enterText(find.byKey(const Key('search-field')), 'no match');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-result-buy')), findsNothing);
    expect(find.byKey(const Key('search-empty')), findsOneWidget);
    await tapVisible(tester, const Key('close-search'));

    await tapVisible(tester, const Key('open-search'));
    await tester.enterText(find.byKey(const Key('search-field')), 'medicine');
    await tester.pumpAndSettle();
    await tapVisible(tester, const Key('search-result-buy-medicine'));
    expect(find.text('Find medicine safely'), findsOneWidget);

    await tapVisible(tester, const Key('open-scan'));
    await tapVisible(tester, const Key('continue-scan'));
    expect(find.text('Enter or scan a code to continue.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('scan-code-field')),
      'moolsocial-pay-123',
    );
    await tapVisible(tester, const Key('continue-scan'));
    expect(find.byKey(const Key('section-pay')), findsOneWidget);

    await tapVisible(tester, const Key('open-voice'));
    await tapVisible(tester, const Key('continue-voice-search'));
    expect(find.text('Enter or say what you want to find.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('voice-search-field')),
      'book a doctor',
    );
    await tapVisible(tester, const Key('continue-voice-search'));
    expect(find.byKey(const Key('section-book')), findsOneWidget);
    expect(find.text('Book a doctor appointment'), findsOneWidget);

    await tapVisible(tester, const Key('open-profile'));
    await tapVisible(tester, const Key('profile-language'));
    await tapVisible(tester, const Key('profile-language-hi'));
    expect(session.languageCode, 'hi');

    await tapVisible(tester, const Key('profile-area'));
    await tapVisible(tester, const Key('profile-area-manual'));
    await tester.enterText(find.byKey(const Key('profile-area-field')), '');
    await tapVisible(tester, const Key('profile-area-save'));
    expect(
      find.text('Enter at least 3 characters for your area.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('profile-area-field')),
      'Sardarpura',
    );
    await tapVisible(tester, const Key('profile-area-save'));
    expect(session.manualArea, 'Sardarpura');

    await tapVisible(tester, const Key('close-profile'));
    await tapVisible(tester, const Key('nav-chat'));
    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
    await tapVisible(tester, const Key('chat-back'));
    expect(find.byKey(const Key('section-book')), findsOneWidget);
  });

  testWidgets('compact screen, larger text and reduce motion remain usable', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final session = await readySession();
    addTearDown(session.dispose);
    await tester.binding.setSurfaceSize(const Size(360, 800));
    await tester.pumpWidget(
      MoolSocialApp(session: session, initialLocation: '/app/social'),
    );
    await tester.pumpAndSettle();

    for (final key in const [
      Key('open-profile'),
      Key('open-search'),
      Key('open-scan'),
      Key('open-voice'),
      Key('social-tab-shorts'),
      Key('social-action-follow'),
      Key('nav-mool'),
      Key('nav-chat'),
    ]) {
      final size = tester.getSize(find.byKey(key));
      expect(size.width, greaterThanOrEqualTo(44), reason: '$key width');
      expect(size.height, greaterThanOrEqualTo(44), reason: '$key height');
    }

    await tapVisible(tester, const Key('nav-mool'));
    expect(find.byKey(const Key('mool-action-work')), findsOneWidget);
    await tapVisible(tester, const Key('mool-action-work'));
    expect(find.byKey(const Key('section-work')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
