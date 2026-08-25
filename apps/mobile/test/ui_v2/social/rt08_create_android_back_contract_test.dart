import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/shared/social_create_draft_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RT-08 untouched Create Back unwinds to Create then Mool', (
    tester,
  ) async {
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
    addTearDown(journey.dispose);
    await journey.start();
    final draftBinding = socialCreateDraftState.beginPrincipalBindingAttempt();
    await socialCreateDraftState.configureDurability(
      _MemoryDraftRepository(),
      bindingAttempt: draftBinding,
    );
    addTearDown(() {
      socialCreateDraftState.beginPrincipalBindingAttempt();
    });

    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        initialLocation: '/app/social?sub=create&state=text',
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('social-v2-create-workbench')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('screen04-context-tabs')), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('screen04-create-home')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('social-v2-create-workbench')),
      findsNothing,
    );
    expect(find.byKey(const Key('screen04-rail-create')), findsOneWidget);
    final landingPopScope = tester.widget<PopScope<Object?>>(
      find.ancestor(
        of: find.byKey(const Key('screen04-universal-v2')),
        matching: find.byType(PopScope<Object?>),
      ),
    );
    expect(landingPopScope.canPop, isFalse);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('personal-mool-root-v2')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-create-home')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('social-v2-create-workbench')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('screen04-create-post-entry')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('social-v2-create-workbench')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('screen04-create-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-create-home')), findsOneWidget);

    await tester.tap(find.byKey(const Key('screen04-create-carousel-entry')));
    await tester.pumpAndSettle();
    expect(find.text('New carousel'), findsOneWidget);
    expect(
      find.byKey(const Key('screen04-create-carousel-add')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('screen04-create-home')), findsOneWidget);

    await tester.tap(find.byKey(const Key('screen04-create-post-entry')));
    await tester.pumpAndSettle();
    expect(find.text('New text post'), findsOneWidget);
    expect(find.byKey(const Key('screen04-create-carousel-add')), findsNothing);

    await tester.tap(find.byKey(const Key('screen04-create-tool-quick-poll')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('screen04-create-quick-poll-choice-0')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('screen04-create-draft-entry')));
    await tester.pumpAndSettle();
    expect(find.text('New quick poll'), findsOneWidget);
    expect(
      find.byKey(const Key('screen04-create-quick-poll-choice-0')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('screen04-create-post-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('screen04-create-tool-image-poll')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('screen04-create-image-poll-choice-0')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('screen04-create-draft-entry')));
    await tester.pumpAndSettle();
    expect(find.text('New image poll'), findsOneWidget);
    expect(
      find.byKey(const Key('screen04-create-image-poll-choice-0')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

final class _MemoryDraftRepository implements SocialCreateDraftRepository {
  SocialCreateDraftSnapshot? snapshot;

  @override
  Future<SocialCreateDraftRead> read() async => SocialCreateDraftRead(
    freshness: snapshot == null
        ? SocialCreateDraftFreshness.missing
        : SocialCreateDraftFreshness.fresh,
    snapshot: snapshot,
  );

  @override
  Future<void> write(SocialCreateDraftSnapshot value) async {
    snapshot = value;
  }

  @override
  Future<void> clear() async {
    snapshot = null;
  }
}
