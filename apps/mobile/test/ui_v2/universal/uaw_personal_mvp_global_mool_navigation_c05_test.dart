import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/chat/chat_models.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/shared/shared_models.dart';
import 'package:moolsocial/features/shared/shared_session.dart';

void main() {
  Future<({JourneySession journey, ChatSession chat, SharedSession shared})>
  mount(
    WidgetTester tester, {
    required String route,
    ChatSession? chatSession,
    SharedSession? sharedSession,
  }) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
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
    final chat = chatSession ?? ChatSession();
    final shared = sharedSession ?? SharedSession();
    await journey.start();
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      journey.dispose();
      chat.dispose();
      shared.dispose();
    });
    await tester.pumpWidget(
      MoolSocialApp(
        key: UniqueKey(),
        session: journey,
        chatSession: chat,
        sharedSession: shared,
        initialLocation: route,
      ),
    );
    await tester.pumpAndSettle();
    return (journey: journey, chat: chat, shared: shared);
  }

  Future<void> openMoolAndSystemBack(WidgetTester tester, Key moolKey) async {
    await tester.ensureVisible(find.byKey(moolKey));
    await tester.tap(find.byKey(moolKey));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('mool-connected-action-navigator')),
      findsNothing,
    );
  }

  test('C05 removes every Chat replacement and Shared Social alias', () {
    final inbox = File.fromUri(
      Directory.current.uri.resolve(
        'lib/features/chat/screens/chat_inbox_screen.dart',
      ),
    ).readAsStringSync();
    final thread = File.fromUri(
      Directory.current.uri.resolve(
        'lib/features/chat/screens/chat_thread_screen.dart',
      ),
    ).readAsStringSync();
    final shared = File.fromUri(
      Directory.current.uri.resolve(
        'lib/features/shared/screens/shared_screens.dart',
      ),
    ).readAsStringSync();

    expect(inbox, isNot(contains("context.go('/app/mool')")));
    expect(thread, isNot(contains("context.go('/app/mool')")));
    expect(shared, contains('MoolGlobalNavigationV2('));
    expect(shared, contains("onOpenMool: () => context.push('/app/mool')"));
    expect(shared, isNot(contains('shared-dock-')));
  });

  testWidgets('filtered Chat inbox Mool Back restores filter and search', (
    tester,
  ) async {
    final owners = await mount(
      tester,
      route: '/app/chat/inbox?type=orders&return=/app/buy',
    );
    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
    expect(owners.chat.selectedFilter, ChatThreadType.order);
    await tester.enterText(find.byKey(const Key('chat-search-field')), 'Rasoi');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-open-thread-rasoi')), findsOneWidget);

    await openMoolAndSystemBack(tester, const Key('mool-compact-launcher'));

    expect(find.byKey(const Key('chat-inbox-screen')), findsOneWidget);
    expect(owners.chat.selectedFilter, ChatThreadType.order);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-search-field')))
          .controller
          ?.text,
      'Rasoi',
    );
    expect(find.byKey(const Key('chat-open-thread-rasoi')), findsOneWidget);
  });

  testWidgets('Chat thread Mool Back restores only the exact text draft', (
    tester,
  ) async {
    await mount(
      tester,
      route: '/app/chat/thread/home-basket?return=/app/social',
    );
    await tester.enterText(
      find.byKey(const Key('chat-message-field')),
      'Unsent exact draft',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-reply-preview')), findsNothing);
    expect(find.byKey(const Key('chat-attachment-preview')), findsNothing);

    await openMoolAndSystemBack(tester, const Key('mool-compact-launcher'));

    expect(find.byKey(const Key('chat-thread-screen')), findsOneWidget);
    expect(find.byKey(const Key('chat-reply-preview')), findsNothing);
    expect(find.byKey(const Key('chat-attachment-preview')), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-message-field')))
          .controller
          ?.text,
      'Unsent exact draft',
    );
  });

  const sharedRoutes = <int, String>{
    157: '/app/activity',
    158: '/app/account/identity',
    159: '/app/ask',
    160: '/app/files',
    161: '/app/account/security',
    162: '/app/account/workspaces',
    165: '/app/account/workspaces/preferences',
  };

  for (final entry in sharedRoutes.entries) {
    testWidgets('Shared ${entry.key} Mool Back restores exact owner', (
      tester,
    ) async {
      final owners = await mount(tester, route: entry.value);
      final spec = sharedScreenSpec(entry.key);
      final retainedFilter = spec.filters.last;
      owners.shared.setFilter(entry.key, retainedFilter);
      await tester.pumpAndSettle();
      expect(find.byKey(Key('shared-screen-${entry.key}')), findsOneWidget);

      await openMoolAndSystemBack(tester, const Key('mool-home-launcher'));

      expect(find.byKey(Key('shared-screen-${entry.key}')), findsOneWidget);
      expect(owners.shared.filterFor(spec), retainedFilter);
    });
  }
}
