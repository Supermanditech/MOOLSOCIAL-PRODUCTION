import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/shared/social_create_draft_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'RT-08-02 dirty Back preserves exact draft until explicit Discard',
    (tester) async {
      final repository = _ControlledDraftRepository();
      await _bind(repository);
      addTearDown(_detach);
      final journey = await _pumpCreate(tester);
      addTearDown(journey.dispose);

      await tester.enterText(
        find.byKey(const Key('screen04-create-post-text')),
        'Keep this exact dirty draft',
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
        findsOneWidget,
      );
      expect(
        socialCreateDraftState.snapshot?.body,
        'Keep this exact dirty draft',
      );
      expect(repository.snapshot?.body, 'Keep this exact dirty draft');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('screen04-rail-create')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('screen04-create-post-text')),
            )
            .controller
            ?.text,
        'Keep this exact dirty draft',
      );

      await tester.tap(find.byKey(const Key('screen04-create-discard')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('screen04-create-discard-confirm')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('screen04-moolsocial-feed-state-empty')),
        findsOneWidget,
      );
      expect(socialCreateDraftState.snapshot, isNull);
      expect(repository.snapshot, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('RT-08-02 rapid double Back cannot skip the Create landing', (
    tester,
  ) async {
    final repository = _ControlledDraftRepository();
    await _bind(repository);
    addTearDown(_detach);
    final journey = await _pumpCreate(tester);
    addTearDown(journey.dispose);
    await tester.enterText(
      find.byKey(const Key('screen04-create-post-text')),
      'Delayed dirty draft',
    );
    final gate = Completer<void>();
    repository.writeGate = gate;

    await tester.binding.handlePopRoute();
    await tester.pump();
    await repository.writeStarted.future;
    expect(_workbenchLock(tester).ignoring, isTrue);
    await tester.tap(
      find.byKey(const Key('screen04-create-post-text')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('screen04-create-post-text')))
          .controller
          ?.text,
      'Delayed dirty draft',
    );
    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('social-v2-create-workbench')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personal-mool-root-v2')), findsNothing);
    expect(repository.snapshot?.body, 'Delayed dirty draft');
  });

  testWidgets('RT-08-02 failed confirmed flush stays in the dirty editor', (
    tester,
  ) async {
    final repository = _ControlledDraftRepository();
    await _bind(repository);
    addTearDown(_detach);
    final journey = await _pumpCreate(tester);
    addTearDown(journey.dispose);
    await tester.enterText(
      find.byKey(const Key('screen04-create-post-text')),
      'Retry this dirty draft',
    );
    repository.failNextWrite = true;

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey('social-v2-create-workbench')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('screen04-create-post-text')))
          .controller
          ?.text,
      'Retry this dirty draft',
    );
    expect(find.byKey(const Key('screen04-create-home')), findsNothing);
    expect(socialCreateDraftState.snapshot?.body, 'Retry this dirty draft');
    expect(repository.snapshot, isNull);
  });

  testWidgets('RT-08-02 dirty specialized route cannot reinterpret content', (
    tester,
  ) async {
    final repository = _ControlledDraftRepository();
    await _bind(repository);
    addTearDown(_detach);
    final journey = await _pumpCreate(tester);
    addTearDown(journey.dispose);

    await tester.tap(find.byKey(const Key('screen04-create-tool-quick-poll')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('screen04-create-post-text')),
      'Keep this poll question',
    );
    await tester.enterText(
      find.byKey(const Key('screen04-create-quick-poll-choice-0')),
      'Keep this choice',
    );

    GoRouter.of(
      tester.element(find.byKey(const Key('screen04-universal-v2'))),
    ).go('/app/social?sub=create&state=image');
    await tester.pumpAndSettle();

    expect(find.text('New quick poll'), findsOneWidget);
    expect(
      find.byKey(const Key('screen04-create-quick-poll-choice-0')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('screen04-create-post-text')))
          .controller
          ?.text,
      'Keep this poll question',
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const Key('screen04-create-quick-poll-choice-0')),
          )
          .controller
          ?.text,
      'Keep this choice',
    );
    expect(find.text('New image post'), findsNothing);
  });
}

IgnorePointer _workbenchLock(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.byKey(const ValueKey('social-v2-create-workbench')),
            )
            .child
        as IgnorePointer;

Future<void> _bind(_ControlledDraftRepository repository) async {
  final token = socialCreateDraftState.beginPrincipalBindingAttempt();
  await socialCreateDraftState.configureDurability(
    repository,
    bindingAttempt: token,
  );
}

void _detach() {
  socialCreateDraftState.beginPrincipalBindingAttempt();
}

Future<JourneySession> _pumpCreate(WidgetTester tester) async {
  final journey = JourneySession(
    store: MemoryJourneyStore(
      snapshot: const JourneySnapshot(
        languageCode: 'en',
        areaMode: 'manual',
        areaLabel: 'Jodhpur',
        setupComplete: true,
      ),
    ),
    otpGateway: ReviewOtpGateway(signedIn: true),
  );
  await journey.start();
  await tester.pumpWidget(
    MoolSocialApp(
      session: journey,
      initialLocation: '/app/social?sub=create&state=text',
    ),
  );
  await tester.pumpAndSettle();
  return journey;
}

final class _ControlledDraftRepository implements SocialCreateDraftRepository {
  SocialCreateDraftSnapshot? snapshot;
  Completer<void>? writeGate;
  bool failNextWrite = false;
  Completer<void> writeStarted = Completer<void>();

  @override
  Future<SocialCreateDraftRead> read() async => SocialCreateDraftRead(
    freshness: snapshot == null
        ? SocialCreateDraftFreshness.missing
        : SocialCreateDraftFreshness.fresh,
    snapshot: snapshot,
  );

  @override
  Future<void> write(SocialCreateDraftSnapshot value) async {
    if (!writeStarted.isCompleted) writeStarted.complete();
    final gate = writeGate;
    writeGate = null;
    if (gate != null) await gate.future;
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('synthetic durable write failure');
    }
    snapshot = value;
  }

  @override
  Future<void> clear() async {
    snapshot = null;
  }
}
