import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/creator/creator_session.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/retailer/retailer_session.dart';
import 'package:moolsocial/features/shared/shared_session.dart';
import 'package:moolsocial/ui_v2/social/screen04_universal_components.dart';
import 'package:moolsocial/ui_v2/social/social_v2_consumer.dart';
import 'package:moolsocial/ui_v2/universal/mool_global_navigation_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('C29N keeps white Mool left and white Chat right globally', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: MoolDestinationNavigationV2(
            activeId: 'buy',
            destinationLabel: 'Buy',
            selectedLocalIndex: 0,
            localActionCount: 2,
            localNavigation: const Row(
              children: [
                Expanded(child: Center(child: Text('Shop'))),
                Expanded(child: Center(child: Text('Offers'))),
              ],
            ),
            onOpenMool: () {},
            onOpenAction: (_) {},
            onOpenChat: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final mool = find.byKey(const Key('mool-compact-launcher'));
    final chat = find.byKey(const Key('mool-global-chat'));
    expect(mool, findsOneWidget);
    expect(chat, findsOneWidget);
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
    expect(tester.getSemantics(mool).rect.height, greaterThanOrEqualTo(44));
    expect(tester.getSemantics(chat).rect.height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets('C29N Social plus exposes every creator outcome in one tap', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    final owners = _Owners();
    addTearDown(owners.dispose);

    await tester.pumpWidget(_app(owners.consumer(state: 'home')));
    await tester.pumpAndSettle();

    expect(find.byType(Screen04Header), findsNothing);
    for (final key in const [
      'screen04-create-tool-post',
      'screen04-create-tool-image',
      'screen04-create-tool-carousel',
      'screen04-create-tool-image-poll',
      'screen04-create-tool-quick-poll',
      'screen04-create-tool-quiz',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    expect(
      find.byKey(const Key('screen04-create-youtube-short')),
      findsNothing,
    );
    expect(find.text('Create a MoolSocial post'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('C29N composer remains actionable above an open keyboard', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.reset);
    final owners = _Owners();
    addTearDown(owners.dispose);

    await tester.pumpWidget(_app(owners.consumer(state: 'text')));
    await tester.pumpAndSettle();

    final publish = find.byKey(const Key('screen04-create-publish-post'));
    final text = find.byKey(const Key('screen04-create-post-text'));
    final formats = find.byKey(const Key('screen04-create-tool-post'));
    final carousel = find.byKey(const Key('screen04-create-tool-carousel'));
    expect(publish, findsOneWidget);
    expect(text, findsOneWidget);
    expect(formats, findsOneWidget);
    expect(tester.getSemantics(formats).rect.height, greaterThanOrEqualTo(44));
    expect(tester.getSemantics(carousel).rect.height, greaterThanOrEqualTo(44));
    expect(find.byKey(const Key('screen04-context-tabs')), findsNothing);
    expect(find.byType(Screen04Header), findsNothing);

    await tester.enterText(text, 'Keyboard-safe founder review post');
    await tester.pump();
    final keyboardTop = 844 - 320;
    expect(tester.getBottomRight(publish).dy, lessThanOrEqualTo(keyboardTop));
    expect(tester.getBottomRight(formats).dy, lessThanOrEqualTo(keyboardTop));
    expect(tester.takeException(), isNull);
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

  SocialUniversalV2 consumer({required String state}) => SocialUniversalV2(
    session: journey,
    creatorSession: creator,
    retailerSession: retailer,
    sharedSession: shared,
    initialSubAction: 'create',
    initialState: state,
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
