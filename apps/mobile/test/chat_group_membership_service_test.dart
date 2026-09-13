import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/app/moolsocial_app.dart';
import 'package:moolsocial/features/chat/chat_models.dart';
import 'package:moolsocial/features/chat/chat_services.dart';
import 'package:moolsocial/features/chat/chat_session.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';

void main() {
  Future<JourneySession> readyJourney() async {
    final session = JourneySession(
      store: MemoryJourneyStore(
        snapshot: const JourneySnapshot(
          languageCode: 'en',
          areaMode: 'manual',
          areaLabel: 'Sardarpura',
          setupComplete: true,
        ),
      ),
      otpGateway: ReviewOtpGateway(signedIn: true),
    );
    await session.start();
    return session;
  }

  Future<(_GroupGateway, ChatSession)> mount(
    WidgetTester tester, {
    String location = '/app/chat/thread/group-1?return=/app/mool',
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    final journey = await readyJourney();
    final gateway = _GroupGateway();
    final chat = ChatSession.production(gateway: gateway);
    addTearDown(journey.dispose);
    addTearDown(chat.dispose);
    await tester.pumpWidget(
      MoolSocialApp(
        session: journey,
        chatSession: chat,
        initialLocation: location,
      ),
    );
    await tester.pumpAndSettle();
    return (gateway, chat);
  }

  Future<void> openGroupInfo(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('chat-conversation-info')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-info-group-info')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const Key('chat-group-info-list')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('admin invites connected person and updates permissions', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final (gateway, _) = await mount(tester);
    await openGroupInfo(tester);

    await tester.tap(find.byKey(const Key('chat-group-invite')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-group-invite-picker')), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('chat-group-invite-person-member-4')),
    );
    await tester.pumpAndSettle();
    expect(gateway.invited, [('group-1', 'member-4')]);

    await tester.tap(find.byKey(const Key('chat-group-permissions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-group-permission-members')));
    await tester.pumpAndSettle();
    expect(gateway.permission, ChatGroupInvitePermission.members);
    expect(find.text('All members can invite people.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('group invitation is accepted and leave requires confirmation', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final (gateway, _) = await mount(
      tester,
      location: '/app/chat/inbox?return=/app/mool',
    );
    await tester.tap(find.byKey(const Key('chat-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-more-settings')));
    await tester.pumpAndSettle();
    final invites = find.byKey(const Key('chat-settings-group-invites'));
    await tester.drag(
      find.byKey(const Key('chat-settings-list')),
      const Offset(0, -950),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(invites);
    await tester.pumpAndSettle();
    await tester.tap(invites);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('chat-group-invite-accept-invite-1')),
    );
    await tester.pumpAndSettle();
    expect(gateway.responses, [('invite-1', true)]);
    expect(find.byKey(const Key('chat-group-invites-empty')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chat-open-thread-group-1')));
    await tester.pumpAndSettle();
    await openGroupInfo(tester);
    await tester.tap(find.byKey(const Key('chat-group-leave')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-group-leave-confirmation')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('chat-group-leave-confirm')));
    await tester.pumpAndSettle();
    expect(gateway.leftGroups, ['group-1']);
    expect(tester.takeException(), isNull);
  });
}

class _GroupGateway implements ChatGateway, ChatGroupGateway {
  ChatGroupInvitePermission permission = ChatGroupInvitePermission.admins;
  final invited = <(String, String)>[];
  final responses = <(String, bool)>[];
  final leftGroups = <String>[];
  final invites = <ChatGroupInvite>[groupInvite];

  @override
  Future<ChatGroupInfo> getGroupInfo({required String threadId}) async =>
      groupInfo(permission);

  @override
  Future<ChatGroupInvite> inviteGroupMember({
    required String threadId,
    required String targetUserId,
  }) async {
    invited.add((threadId, targetUserId));
    return groupInvite;
  }

  @override
  Future<ChatGroupInfo> updateGroupPermissions({
    required String threadId,
    required ChatGroupInvitePermission invitePermission,
  }) async {
    permission = invitePermission;
    return groupInfo(permission);
  }

  @override
  Future<bool> leaveGroup({required String threadId}) async {
    leftGroups.add(threadId);
    return true;
  }

  @override
  Future<List<ChatGroupInvite>> listGroupInvites() async => List.of(invites);

  @override
  Future<bool> respondToGroupInvite({
    required String inviteId,
    required bool accepted,
  }) async {
    responses.add((inviteId, accepted));
    invites.removeWhere((invite) => invite.id == inviteId);
    return accepted;
  }

  @override
  Future<List<ChatThread>> listThreads({int limit = 30}) async => const [
    groupThread,
    candidateThread,
  ];

  @override
  Future<List<ChatMessage>> listMessages({
    required String threadId,
    int limit = 50,
  }) async => const [];

  @override
  Future<ChatThread> createDirectThread({required String targetUserId}) async =>
      candidateThread;

  @override
  Future<void> markThreadRead({required String threadId}) async {}

  @override
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String text,
    required String idempotencyKey,
    String? replyToMessageId,
  }) => Future.error(UnimplementedError());

  @override
  Future<ChatMessage> setReaction({
    required String threadId,
    required String messageId,
    required bool reacted,
  }) => Future.error(UnimplementedError());

  @override
  Future<ChatMessage> forwardMessage({
    required String sourceThreadId,
    required String sourceMessageId,
    required String targetThreadId,
    required String idempotencyKey,
  }) => Future.error(UnimplementedError());
}

ChatGroupInfo groupInfo(ChatGroupInvitePermission permission) => ChatGroupInfo(
  threadId: 'group-1',
  title: 'Home Group',
  description: 'Coordinate together.',
  members: groupMembers,
  invitePermission: permission,
  canInvite: true,
  canManage: true,
  canLeave: true,
);

const groupMembers = [
  ChatParticipant(
    id: 'current-user',
    name: 'You',
    subtitle: '@you',
    isMe: true,
    isAdmin: true,
  ),
  ChatParticipant(id: 'member-2', name: 'Amit', subtitle: '@amit'),
  ChatParticipant(id: 'member-3', name: 'Neha', subtitle: '@neha'),
];

const groupThread = ChatThread(
  id: 'group-1',
  title: 'Home Group',
  subtitle: '3 members',
  preview: 'Welcome',
  timeLabel: 'Now',
  type: ChatThreadType.people,
  participants: groupMembers,
  groupDescription: 'Coordinate together.',
);

const candidateThread = ChatThread(
  id: 'direct-4',
  title: 'Rakesh',
  subtitle: '@rakesh',
  preview: 'Connected',
  timeLabel: 'Now',
  type: ChatThreadType.people,
  targetUserId: 'member-4',
);

final groupInvite = ChatGroupInvite(
  id: 'invite-1',
  threadId: 'group-1',
  groupTitle: 'Home Group',
  invitedByUserId: 'member-2',
  invitedByName: 'Amit',
  invitedAt: DateTime.utc(2026, 8, 29),
);
