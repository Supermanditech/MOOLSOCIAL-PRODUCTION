import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/ui_v2/profile/global_personal_profile_v2.dart';
import 'package:moolsocial/features/journey01/account_profile_gateway.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';

// Isolated host fixtures only. They are never installed in the evaluation app.
const owner = (
  environment: 'fixture',
  projectId: 'fixture-project',
  tenantId: null,
  userId: 'owner-a',
);
Map<String, Object?> profile({
  String uid = 'owner-a',
  int revision = 0,
  String name = 'Original name',
}) => {
  'ownerUid': uid,
  'revision': revision,
  'updatedAt': '2026-10-27T00:00:00.000Z',
  'displayName': name,
  'addresses': <Object?>[],
  'selectedAddressId': null,
  'invoiceProfiles': <Object?>[],
};
Map<String, Object?> receipt({
  String requestId = 'request-one',
  String uid = 'owner-a',
}) => {
  'ownerUid': uid,
  'requestId': requestId,
  'fingerprint': sha256
      .convert(
        utf8.encode(
          jsonEncode({
            'expectedRevision': 0,
            'change': {'kind': 'name', 'displayName': 'New name'},
          }),
        ),
      )
      .toString(),
  'profile': profile(uid: uid, revision: 1, name: 'New name'),
};

class Credentials implements SocialContentCredentials {
  final modes = <SocialAppCheckTokenMode>[];
  String token = 'fixture-token';
  @override
  Future<String> firebaseIdToken() async => token;
  @override
  Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {
    modes.add(mode);
    return 'fixture-app-check';
  }
}

class Journal implements AccountProfilePendingStore {
  final values = <String, String>{};
  bool failWrite = false;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (failWrite) throw StateError('fixture disk failure');
    values[key] = value;
  }

  @override
  Future<void> clear(String key) async {
    values.remove(key);
  }
}

class Transport implements SocialContentTransport {
  final responses = <Object?>[];
  final calls = <Map<String, Object?>>[];
  final urls = <Uri>[];
  @override
  Future<SocialContentResponse> postJson(
    Uri endpoint, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    urls.add(endpoint);
    calls.add(jsonDecode(jsonEncode(body)) as Map<String, dynamic>);
    expect(headers.keys, containsAll(['Authorization', 'X-Firebase-AppCheck']));
    if (responses.isEmpty) throw StateError('fixture exhausted');
    final next = responses.removeAt(0);
    if (next is Exception) throw next;
    if (next is Completer<SocialContentResponse>) return next.future;
    if (next is SocialContentResponse) return next;
    return SocialContentResponse(
      statusCode: 200,
      body: jsonEncode({'ok': true, 'data': next}),
    );
  }
}

class Rig {
  final journal = Journal(),
      transport = Transport(),
      credentials = Credentials();
  bool current = true;
  late final gateway = newGateway();
  AccountProfileGateway newGateway({AccountProfileOwner scope = owner}) =>
      AccountProfileGateway(
        owner: scope,
        isCurrent: () => current,
        credentials: credentials,
        pendingStore: journal,
        transport: transport,
        requestId: () => 'request-one',
      );
  Future<void> read() async {
    transport.responses.add(profile());
    await gateway.read();
  }
}

class ProfileIdentity extends ReviewAuthenticatedAccountIdentityGateway
    implements
        AuthenticatedAccountPrincipalSource,
        AccountProfileGatewaySource {
  ProfileIdentity(this.rig)
    : super(
        identity: const AuthenticatedAccountIdentity(
          firebaseUserId: 'owner-a',
          firebaseProjectId: 'fixture-project',
          displayName: 'Provider name',
          emailAddress: 'fixture@example.invalid',
        ),
      );
  final Rig rig;
  final changes = StreamController<void>.broadcast(sync: true);
  @override
  ({String projectId, String? tenantId, String userId})?
  get currentFirebasePrincipal => identity?.firebasePrincipal;
  @override
  Stream<void> get firebasePrincipalChanges => changes.stream;
  @override
  String get persistenceEnvironment => 'fixture';
  @override
  AccountProfileGateway? profileGateway(
    AccountProfileOwner owner,
    bool Function() isCurrent,
  ) => AccountProfileGateway(
    owner: owner,
    isCurrent: isCurrent,
    credentials: rig.credentials,
    pendingStore: rig.journal,
    transport: rig.transport,
    requestId: () => 'request-one',
  );
}

JourneySession sessionFixture(ProfileIdentity identity) => JourneySession(
  store: MemoryJourneyStore(
    snapshot: const JourneySnapshot(
      languageCode: 'en',
      areaMode: 'skipped',
      setupComplete: true,
      profileDisplayName: 'Ownerless device alias',
    ),
  ),
  otpGateway: ReviewOtpGateway(signedIn: true),
  accountIdentityGateway: identity,
);

Matcher failure(String code) =>
    isA<AccountProfileFailure>().having((e) => e.code, 'code', code);
const change = {'kind': 'name', 'displayName': 'New name'};
const delivery = BuyV2Address(
  id: 'address-one',
  kind: BuyV2AddressKind.work,
  label: 'Work',
  recipient: 'Fixture recipient',
  phone: '9999999999',
  line: 'Fixture street',
  area: 'Jaipur',
  pinCode: '302001',
  landmark: 'Fixture landmark',
);
Map<String, Object?> deliveryRow() => {
  'id': delivery.id,
  'kind': delivery.kind.name,
  'label': delivery.label,
  'recipient': delivery.recipient,
  'phone': delivery.phone,
  'line': delivery.line,
  'area': delivery.area,
  'pinCode': delivery.pinCode,
  'landmark': delivery.landmark,
};
Map<String, Object?> receiptFor(
  Map<String, Object?> change,
  Map<String, Object?> saved,
) => {
  'ownerUid': 'owner-a',
  'requestId': 'request-one',
  'fingerprint': sha256
      .convert(
        utf8.encode(jsonEncode({'expectedRevision': 0, 'change': change})),
      )
      .toString(),
  'profile': saved,
};

class CustomerStore implements BuyV2CustomerStateStore {
  CustomerStore(this.ownerScope);
  @override
  final String? ownerScope;
  BuyV2CustomerStateSnapshot? saved;
  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => saved;
  @override
  Future<bool> write(BuyV2CustomerStateSnapshot snapshot) async {
    saved = snapshot;
    return true;
  }
}

// Isolated combined-controller fixtures; never injected into the device app.
class _CombinedWorkScope implements WorkPendingProofStore {
  @override String? accountScope = 'owner-a';
  final saved = <String, Map<String, Object?>>{};
  @override Future<Map<String, Object?>?> read(String scope) async =>
    scope == accountScope ? saved[scope] : null;
  @override Future<void> save(String scope, Map<String, Object?> draft) async {
    if (scope == accountScope) saved[scope] = Map.of(draft);
  }
  @override Future<void> clear(String scope) async {
    if (scope == accountScope) saved.remove(scope);
  }
}

class _CombinedWorkTransport implements SocialContentTransport {
  final responses = <Object?>[];
  final dispatched = <Map<String, Object?>>[];
  @override Future<SocialContentResponse> postJson(Uri endpoint, {
      required Map<String, String> headers, required Map<String, Object?> body}) async {
    expect(endpoint.path, '/moolSocialWorkspace');
    expect(headers['authorization'], startsWith('Bearer '));
    dispatched.add(Map.of(body));
    final next = responses.removeAt(0);
    if (next is Completer<SocialContentResponse>) return next.future;
    return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': next}));
  }
}

Map<String, Object?> _combinedWorkRead({bool active = true}) {
  final checked = DateTime.fromMillisecondsSinceEpoch(
    DateTime.now().toUtc().subtract(const Duration(seconds: 1)).millisecondsSinceEpoch, isUtc: true);
  return {'workspaces': [{'caseId': 'case-combined-001', 'status': 'approved', 'plan': 'free',
    'workspaceId': 'store-combined-001', 'profileId': 'retailer-grocery',
    'name': 'Isolated combined Store', 'area': 'Host fixture area', 'primaryActivity': 'Groceries',
    'access': {'schemaVersion': 1, 'state': active ? 'active' : 'denied',
      if (active) ...{'accountId': 'owner-a', 'caseId': 'case-combined-001',
        'workspaceId': 'store-combined-001', 'profileId': 'retailer-grocery',
        'checkedAt': checked.toIso8601String(),
        'applicationUpdatedAt': checked.subtract(const Duration(minutes: 1)).toIso8601String(),
        'membership': {'schemaVersion': 1, 'membershipId': 'member-combined-001', 'state': 'active',
          'workspaceId': 'store-combined-001', 'workspaceProfileId': 'retailer-grocery', 'version': 1,
          'effectiveFrom': checked.subtract(const Duration(days: 1)).toIso8601String(),
          'expiresAt': checked.add(const Duration(hours: 1)).toIso8601String()}}}}]};
}

void _combinedProfileWorkspaceTests() {
  WorkSession workFor(Rig r, _CombinedWorkScope scope, _CombinedWorkTransport transport) =>
    WorkSession(gateway: AuthenticatedWorkGateway(
      endpoint: Uri.parse('https://example.invalid/moolSocialWorkspace'),
      credentials: r.credentials, transport: transport), contactDraftStore: scope);

  test('COMBINED Profile address save and Store revocation retain independent outcomes', () async {
    final r = Rig(), scope = _CombinedWorkScope(), wire = _CombinedWorkTransport();
    final work = workFor(r, scope, wire);
    final buy = BuyV2Session(core: BuySession(), reviewDataEnabled: false,
      customerStateStore: CustomerStore(r.gateway.ownerScope));
    addTearDown(work.dispose); addTearDown(buy.dispose);
    buy.synchronizeAccountProfile(r.gateway);
    r.transport.responses.add(profile());
    expect(await buy.refreshAccountProfileAddresses(), isTrue);
    wire.responses.add(_combinedWorkRead());
    await work.refreshFeed();
    expect(work.hasVerifiedWorkspace, isTrue);
    final originalOrders = List.of(buy.orders);
    final expected = {'kind': 'delivery', 'addresses': [deliveryRow()], 'selectedAddressId': delivery.id};
    final saved = {...profile(revision: 1), 'addresses': [deliveryRow()], 'selectedAddressId': delivery.id};
    final reply = Completer<SocialContentResponse>();
    r.transport.responses.addAll([reply, saved]);
    final pending = buy.saveAddressConfirmed(delivery);
    for (var attempt = 0; attempt < 20 && r.transport.calls.length < 2; attempt++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(r.transport.calls.last['operation'], 'save');
    expect(r.journal.values, isNotEmpty);
    wire.responses.add(_combinedWorkRead(active: false));
    await work.refreshFeed();
    expect(work.hasVerifiedWorkspace, isFalse);
    reply.complete(SocialContentResponse(statusCode: 200,
      body: jsonEncode({'ok': true, 'data': receiptFor(expected, saved)})));
    expect(await pending, isTrue);
    expect(buy.selectedAddressId, delivery.id);
    expect(buy.addresses.single.recipient, delivery.recipient);
    expect(buy.orders, originalOrders);
    expect(r.journal.values, isEmpty);
    expect(work.hasVerifiedWorkspace, isFalse, reason: 'Profile confirmation cannot grant Store authority');
    expect(jsonEncode(scope.saved), isNot(contains('membershipId')));
  });

  test('COMBINED owner switch retires both original Profile and Workspace reads', () async {
    final r = Rig(), scope = _CombinedWorkScope(), wire = _CombinedWorkTransport();
    await r.read();
    final work = workFor(r, scope, wire);
    addTearDown(work.dispose);
    wire.responses.add(_combinedWorkRead());
    await work.refreshFeed();
    expect(work.hasVerifiedWorkspace, isTrue);
    final profileReply = Completer<SocialContentResponse>(), workReply = Completer<SocialContentResponse>();
    r.transport.responses.add(profileReply); wire.responses.add(workReply);
    final profileRead = r.gateway.read();
    final profileDenied = expectLater(profileRead, throwsA(isA<AccountProfileFailure>()));
    final workRead = work.refreshFeed();
    for (var attempt = 0; attempt < 20 && wire.dispatched.length < 2; attempt++) {
      await Future<void>.delayed(Duration.zero);
    }
    r.current = false; scope.accountScope = 'owner-b';
    profileReply.complete(SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': profile()})));
    workReply.complete(SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': _combinedWorkRead()})));
    await profileDenied; await workRead;
    expect(r.gateway.ownerScope, isNull);
    expect(work.hasVerifiedWorkspace, isFalse);
    expect(r.journal.values, isEmpty);
    expect(scope.saved.containsKey('owner-b'), isFalse);
  });

  test('COMBINED Profile refresh joins a pending Workspace access read', () async {
    final r = Rig(), scope = _CombinedWorkScope(), wire = _CombinedWorkTransport();
    await r.read();
    final work = workFor(r, scope, wire);
    addTearDown(work.dispose);
    wire.responses.add(_combinedWorkRead());
    await work.refreshFeed();
    final reply = Completer<SocialContentResponse>();
    wire.responses.add(reply);
    final inFlight = work.refreshFeed();
    for (var attempt = 0; attempt < 20 && wire.dispatched.length < 2; attempt++) {
      await Future<void>.delayed(Duration.zero);
    }
    r.transport.responses.addAll([receipt(), profile(revision: 1, name: 'New name')]);
    expect((await r.gateway.save(change)).displayName, 'New name');
    var completed = false;
    final redirected = work.revalidateWorkspaceAccess().then((value) { completed = true; return value; });
    try {
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse, reason: 'A Profile-triggered route refresh must wait for the owned access read, not send the owner to onboarding');
    } finally {
      reply.complete(SocialContentResponse(statusCode: 200,
        body: jsonEncode({'ok': true, 'data': _combinedWorkRead()})));
      await inFlight;
    }
    expect(await redirected, isTrue);
    expect(work.hasVerifiedWorkspace, isTrue);
    expect(wire.dispatched.length, 2, reason: 'Join the original read without issuing duplicates');
  });

  for (final boundary in ['revoked', 'actor changed', 'read failed']) {
    test('COMBINED joined access read remains denied when $boundary', () async {
      final r = Rig(), scope = _CombinedWorkScope(), wire = _CombinedWorkTransport();
      await r.read();
      final work = workFor(r, scope, wire);
      addTearDown(work.dispose);
      wire.responses.add(_combinedWorkRead());
      await work.refreshFeed();
      final reply = Completer<SocialContentResponse>();
      wire.responses.add(reply);
      final original = work.refreshFeed();
      for (var attempt = 0; attempt < 20 && wire.dispatched.length < 2; attempt++) {
        await Future<void>.delayed(Duration.zero);
      }
      final joined = work.revalidateWorkspaceAccess();
      if (boundary == 'actor changed') { r.current = false; scope.accountScope = 'owner-b'; }
      reply.complete(SocialContentResponse(statusCode: boundary == 'read failed' ? 403 : 200,
        body: jsonEncode({'ok': true, 'data': _combinedWorkRead(active: boundary != 'revoked')})));
      await original;
      expect(await joined, isFalse);
      expect(work.hasVerifiedWorkspace, isFalse);
      expect(wire.dispatched.length, 2);
      expect(r.transport.calls.map((call) => call['operation']), ['read']);
      expect(r.gateway.ownerScope, boundary == 'actor changed' ? isNull : isNotNull);
    });
  }
}

void main() {
  _registerLocalParity();
  _combinedProfileWorkspaceTests();
  for (final status in [401, 403]) {
    test(
      'Profile authoritative denial $status retires cached access until canonical revalidation',
      () async {
        final r = Rig();
        await r.read();
        final invoices = AccountProfileInvoiceStore(r.gateway);
        r.transport.responses.add(
          SocialContentResponse(
            statusCode: status,
            body: jsonEncode({
              'ok': false,
              'error': {
                'code': status == 401
                    ? 'authentication_required'
                    : 'account_restricted',
                'uncertain': false,
              },
            }),
          ),
        );
        await expectLater(
          r.gateway.read(),
          throwsA(isA<AccountProfileFailure>()),
        );
        expect(r.gateway.snapshot, isNull);
        expect(invoices.ownerScope, isNull);
        r.transport.responses.add(profile());
        await r.gateway.read();
        expect(r.gateway.snapshot, isNotNull);
        expect(invoices.ownerScope, isNotNull);
      },
    );
  }
  test(
    'Profile relaunch read reconciles an original save before displaying canonical fields',
    () async {
      final r = Rig();
      await r.read();
      r.transport.responses.add(Exception('fixture acknowledgement lost'));
      await expectLater(
        r.gateway.save(change),
        throwsA(isA<AccountProfileFailure>()),
      );
      r.transport.responses.addAll([
        receipt(),
        profile(revision: 1, name: 'New name'),
      ]);
      expect((await r.newGateway().read()).displayName, 'New name');
      expect(r.journal.values, isEmpty);
      expect(r.transport.calls.map((c) => c['operation']), [
        'read',
        'save',
        'reconcile',
        'read',
      ]);
    },
  );
  test(
    'Profile relaunch absent receipt replays only the exact previously confirmed request',
    () async {
      final r = Rig();
      await r.read();
      r.transport.responses.add(Exception('fixture transport lost'));
      await expectLater(
        r.gateway.save(change),
        throwsA(isA<AccountProfileFailure>()),
      );
      r.transport.responses.addAll([
        null,
        receipt(),
        profile(revision: 1, name: 'New name'),
      ]);
      expect((await r.newGateway().read()).displayName, 'New name');
      final saves = r.transport.calls
          .where((c) => c['operation'] == 'save')
          .toList();
      expect(saves.length, 2);
      expect(saves.first['payload'], saves.last['payload']);
    },
  );
  testWidgets(
    'Profile original form loads canonical name and returns only after confirmed save',
    (tester) async {
      final identity = ProfileIdentity(Rig());
      final session = sessionFixture(identity);
      addTearDown(session.dispose);
      addTearDown(identity.changes.close);
      await session.start();
      identity.rig.transport.responses.add(
        profile(name: 'Canonical existing name'),
      );
      final router = GoRouter(
        initialLocation: '/app/account/identity/name',
        routes: [
          GoRoute(
            path: '/app/account/identity/name',
            builder: (context, state) => GlobalPersonalProfileNameEditorV2(
              session: session,
              onSaveDisplayName: session.saveAccountProfileName,
            ),
          ),
          GoRoute(
            path: '/app/account/identity',
            builder: (context, state) =>
                const Scaffold(body: Text('Profile returned')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(theme: MoolTheme.light(), routerConfig: router),
      );
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('global-personal-profile-name-field'));
      expect(
        tester.widget<TextField>(field).controller!.text,
        'Canonical existing name',
      );
      await tester.enterText(field, 'New name');
      identity.rig.transport.responses.addAll([
        receipt(),
        profile(revision: 1, name: 'New name'),
      ]);
      await tester.tap(
        find.byKey(const Key('global-personal-profile-name-save')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Profile returned'), findsOneWidget);
      expect(session.accountIdentity!.displayName, 'New name');
    },
  );
  testWidgets(
    'Profile original form cannot save a provider name while canonical read is pending',
    (tester) async {
      final identity = ProfileIdentity(Rig());
      final session = sessionFixture(identity);
      addTearDown(session.dispose);
      addTearDown(identity.changes.close);
      await session.start();
      final pending = Completer<SocialContentResponse>();
      identity.rig.transport.responses.add(pending);
      await tester.pumpWidget(
        MaterialApp(
          theme: MoolTheme.light(),
          home: GlobalPersonalProfileNameEditorV2(
            session: session,
            onSaveDisplayName: session.saveAccountProfileName,
          ),
        ),
      );
      await tester.pump();
      final field = tester.widget<TextField>(
        find.byKey(const Key('global-personal-profile-name-field')),
      );
      expect(field.readOnly, isTrue);
      expect(field.controller!.text, isEmpty);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('global-personal-profile-name-save')),
            )
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      pending.complete(
        SocialContentResponse(
          statusCode: 200,
          body: jsonEncode({'ok': true, 'data': profile()}),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'Profile stale rejection requires a new canonical read and never claims success',
    () async {
      final r = Rig();
      await r.read();
      r.transport.responses.add(
        const SocialContentResponse(
          statusCode: 409,
          body:
              '{"ok":false,"error":{"code":"profile_revision_conflict","uncertain":false}}',
        ),
      );
      await expectLater(
        r.gateway.save(change),
        throwsA(failure('profile_revision_conflict')),
      );
      expect(r.journal.values, isEmpty);
      expect(r.gateway.snapshot, isNull);
    },
  );
  test(
    'Profile service failure retains pending outcome even without a reliable error body',
    () async {
      final r = Rig();
      await r.read();
      r.transport.responses.add(
        const SocialContentResponse(
          statusCode: 503,
          body:
              '{"ok":false,"error":{"code":"profile_service_unavailable","uncertain":false}}',
        ),
      );
      await expectLater(
        r.gateway.save(change),
        throwsA(
          isA<AccountProfileFailure>().having(
            (e) => e.uncertain,
            'uncertain',
            isTrue,
          ),
        ),
      );
      expect(r.journal.values, isNotEmpty);
    },
  );
  test(
    'Profile a conflicting same-revision read does not replace the canonical cache',
    () async {
      final r = Rig();
      await r.read();
      r.transport.responses.add(profile(name: 'Contradictory revision'));
      await expectLater(
        r.gateway.read(),
        throwsA(failure('profile_revision_conflict')),
      );
      expect(r.gateway.snapshot!.displayName, 'Original name');
    },
  );
  test(
    'Profile malformed pending journal is preserved and cannot become a new save',
    () async {
      final r = Rig();
      await r.read();
      r.transport.responses.add(Exception('fixture timeout'));
      await expectLater(
        r.gateway.save(change),
        throwsA(isA<AccountProfileFailure>()),
      );
      final key = r.journal.values.keys.single;
      r.journal.values[key] = 'not-json';
      final calls = r.transport.calls.length;
      await expectLater(r.gateway.save(change), throwsFormatException);
      expect(r.transport.calls.length, calls);
      expect(r.journal.values[key], 'not-json');
    },
  );
  test(
    'Profile invalid name cannot persist or dispatch a pending request',
    () async {
      final r = Rig();
      await r.read();
      await expectLater(
        r.gateway.save({'kind': 'name', 'displayName': 'x'}),
        throwsA(failure('invalid_profile_request')),
      );
      expect(r.journal.values, isEmpty);
      expect(r.transport.calls.length, 1);
    },
  );
  test(
    'Profile delivery adapter confirms canonical fields in original Buy session',
    () async {
      final r = Rig();
      final cache = CustomerStore(r.gateway.ownerScope);
      final buy = BuyV2Session(
        core: BuySession(),
        reviewDataEnabled: false,
        customerStateStore: cache,
      );
      addTearDown(buy.dispose);
      buy.synchronizeAccountProfile(r.gateway);
      r.transport.responses.add(profile());
      expect(await buy.refreshAccountProfileAddresses(), isTrue);
      final beforeOrders = List.of(buy.orders);
      final expected = {
        'kind': 'delivery',
        'addresses': [deliveryRow()],
        'selectedAddressId': delivery.id,
      };
      final saved = {
        ...profile(revision: 1),
        'addresses': [deliveryRow()],
        'selectedAddressId': delivery.id,
      };
      r.transport.responses.addAll([receiptFor(expected, saved), saved]);
      expect(await buy.saveAddressConfirmed(delivery), isTrue);
      expect(buy.selectedAddressId, delivery.id);
      expect(buy.addresses.single.landmark, delivery.landmark);
      expect(buy.addresses.single.recipient, delivery.recipient);
      expect(buy.orders, beforeOrders);
      expect(r.journal.values, isEmpty);
      expect(
        buy.chooseAddress(delivery.id),
        isFalse,
        reason: 'Synchronous path cannot bypass server confirmation',
      );
    },
  );
  test(
    'Profile invoice adapter preserves registered and unregistered recipient fields',
    () async {
      final r = Rig();
      final store = AccountProfileInvoiceStore(r.gateway);
      r.transport.responses.add(profile());
      expect((await store.read())!.profiles, isEmpty);
      final rows = [
        {
          'id': 'invoice-one',
          'registration': 'registered',
          'legalName': 'Fixture business',
          'gstin': '08ABCDE1234F1Z5',
          'billingAddress': 'Fixture billing street',
        },
        {
          'id': 'invoice-two',
          'registration': 'unregistered',
          'legalName': 'Fixture unregistered business',
          'gstin': '',
          'billingAddress': 'Fixture other billing street',
        },
      ];
      final expected = {'kind': 'invoices', 'invoiceProfiles': rows};
      final saved = {...profile(revision: 1), 'invoiceProfiles': rows};
      r.transport.responses.addAll([receiptFor(expected, saved), saved]);
      expect(
        await store.write(
          BuyV2GstInvoiceProfileSnapshot(
            profiles: rows
                .map(
                  (a) => BuyV2GstInvoiceProfileRecord(
                    id: a['id']!,
                    legalName: a['legalName']!,
                    gstin: a['gstin']!,
                    billingAddress: a['billingAddress']!,
                    registration: BuyV2BusinessInvoiceRegistration.values
                        .byName(a['registration']!),
                  ),
                )
                .toList(),
          ),
        ),
        isTrue,
      );
      r.transport.responses.add(saved);
      final restored = (await store.read())!;
      expect(restored.profiles.length, 2);
      expect(restored.profiles.first.gstin, '08ABCDE1234F1Z5');
      expect(
        restored.profiles.last.registration,
        BuyV2BusinessInvoiceRegistration.unregistered,
      );
      r.current = false;
      expect(store.ownerScope, isNull);
    },
  );
  test(
    'Profile invoice and name readers coalesce one canonical request',
    () async {
      final r = Rig();
      final pending = Completer<SocialContentResponse>();
      r.transport.responses.add(pending);
      final first = r.gateway.read(), second = r.gateway.read();
      await Future<void>.delayed(Duration.zero);
      pending.complete(
        SocialContentResponse(
          statusCode: 200,
          body: jsonEncode({'ok': true, 'data': profile()}),
        ),
      );
      expect((await first).revision, 0);
      expect((await second).revision, 0);
      expect(r.transport.calls.length, 1);
    },
  );
  test('Profile wrong original fingerprint cannot confirm a save', () async {
    final r = Rig();
    await r.read();
    r.transport.responses.add({...receipt(), 'fingerprint': 'b' * 64});
    await expectLater(
      r.gateway.save(change),
      throwsA(failure('invalid_profile_response')),
    );
    expect(r.journal.values, isNotEmpty);
    expect(r.gateway.snapshot!.revision, 0);
  });
  test(
    'Profile original name callback applies confirmed identity without changing verified contacts',
    () async {
      final identity = ProfileIdentity(Rig());
      // All responses belong to this same isolated authenticated source.
      final session = sessionFixture(identity);
      addTearDown(identity.changes.close);
      addTearDown(session.dispose);
      await session.start();
      expect(session.accountProfileGateway, isNotNull);
      identity.rig.transport.responses.addAll([
        profile(),
        receipt(),
        profile(revision: 1, name: 'New name'),
      ]);
      expect(await session.saveAccountProfileName('New name'), isTrue);
      expect(session.accountIdentity!.displayName, 'New name');
      expect(session.accountIdentity!.emailAddress, 'fixture@example.invalid');
      expect(session.profileDisplayName, 'Ownerless device alias');
    },
  );
  test(
    'Profile session drops late canonical read after sign-out/source switch',
    () async {
      final identity = ProfileIdentity(Rig());
      final session = sessionFixture(identity);
      addTearDown(identity.changes.close);
      addTearDown(session.dispose);
      await session.start();
      expect(session.accountProfileGateway, isNotNull);
      final pending = Completer<SocialContentResponse>();
      identity.rig.transport.responses.add(pending);
      final read = session.refreshAccountProfile();
      await Future<void>.delayed(Duration.zero);
      identity.identity = null;
      pending.complete(
        SocialContentResponse(
          statusCode: 200,
          body: jsonEncode({'ok': true, 'data': profile()}),
        ),
      );
      expect(await read, isFalse);
      expect(session.accountProfileGateway, isNull);
      expect(session.accountIdentity?.displayName, isNot('Original name'));
    },
  );
  test('Profile absent service keeps name writes unavailable', () async {
    final session = JourneySession();
    addTearDown(session.dispose);
    expect(session.accountProfileGateway, isNull);
    expect(await session.saveAccountProfileName('New name'), isFalse);
  });
  test(
    'Profile canonical read uses exact project endpoint and no payload owner',
    () async {
      final r = Rig();
      await r.read();
      expect(r.gateway.snapshot!.displayName, 'Original name');
      expect(
        r.transport.urls.single.toString(),
        'https://asia-south1-fixture-project.cloudfunctions.net/moolSocialAccountProfile',
      );
      expect(r.transport.calls.single, {'operation': 'read', 'payload': {}});
    },
  );
  test('Profile save needs original read before dispatch', () async {
    final r = Rig();
    await expectLater(
      r.gateway.save(change),
      throwsA(failure('profile_read_required')),
    );
    expect(r.transport.calls, isEmpty);
  });
  test(
    'Profile confirmed save refreshes canonical state and clears original request',
    () async {
      final r = Rig();
      await r.read();
      r.transport.responses.addAll([
        receipt(),
        profile(revision: 1, name: 'New name'),
      ]);
      final value = await r.gateway.save(change);
      expect(value.displayName, 'New name');
      expect(value.revision, 1);
      expect(r.journal.values, isEmpty);
      expect(r.credentials.modes, [
        SocialAppCheckTokenMode.standard,
        SocialAppCheckTokenMode.limitedUse,
        SocialAppCheckTokenMode.standard,
      ]);
    },
  );
  test(
    'Profile missing local journal acknowledgement prevents dispatch',
    () async {
      final r = Rig();
      await r.read();
      r.journal.failWrite = true;
      await expectLater(r.gateway.save(change), throwsStateError);
      expect(r.transport.calls.length, 1);
      expect(r.gateway.snapshot!.revision, 0);
    },
  );
  test(
    'Profile uncertain response preserves request across gateway recreation',
    () async {
      final r = Rig();
      await r.read();
      r.transport.responses.add(Exception('fixture response lost'));
      await expectLater(
        r.gateway.save(change),
        throwsA(failure('profile_outcome_unknown')),
      );
      expect(r.journal.values.length, 1);
      r.transport.responses.addAll([
        receipt(),
        profile(revision: 1, name: 'New name'),
      ]);
      final resumed = r.newGateway();
      final value = await resumed.save(change);
      expect(value.revision, 1);
      expect(r.journal.values, isEmpty);
      expect(r.transport.calls.map((c) => c['operation']), [
        'read',
        'save',
        'reconcile',
        'read',
      ]);
    },
  );
  test(
    'Profile absent receipt retries original identity, never a new mutation',
    () async {
      final r = Rig();
      await r.read();
      r.transport.responses.add(Exception('fixture timeout'));
      await expectLater(
        r.gateway.save(change),
        throwsA(isA<AccountProfileFailure>()),
      );
      r.transport.responses.addAll([
        null,
        receipt(),
        profile(revision: 1, name: 'New name'),
      ]);
      await r.newGateway().save(change);
      final saves = r.transport.calls
          .where((c) => c['operation'] == 'save')
          .toList();
      expect(saves[0]['payload'], saves[1]['payload']);
    },
  );
  test('Profile changed payload cannot replace an uncertain save', () async {
    final r = Rig();
    await r.read();
    r.transport.responses.add(Exception('fixture timeout'));
    await expectLater(
      r.gateway.save(change),
      throwsA(isA<AccountProfileFailure>()),
    );
    await expectLater(
      r.gateway.save({'kind': 'name', 'displayName': 'Different name'}),
      throwsA(failure('profile_original_save_pending')),
    );
    expect(r.transport.calls.length, 2);
  });
  test('Profile concurrent tap cannot dispatch twice', () async {
    final r = Rig();
    await r.read();
    final pending = Completer<SocialContentResponse>();
    r.transport.responses.add(pending);
    final first = r.gateway.save(change);
    await Future<void>.delayed(Duration.zero);
    await expectLater(
      r.gateway.save(change),
      throwsA(failure('profile_save_in_progress')),
    );
    r.transport.responses.add(profile(revision: 1, name: 'New name'));
    pending.complete(
      SocialContentResponse(
        statusCode: 200,
        body: jsonEncode({'ok': true, 'data': receipt()}),
      ),
    );
    await first;
    expect(r.transport.calls.where((c) => c['operation'] == 'save').length, 1);
  });
  test('Profile owner switch invalidates a late reply and its cache', () async {
    final r = Rig();
    final pending = Completer<SocialContentResponse>();
    r.transport.responses.add(pending);
    final first = r.gateway.read();
    await Future<void>.delayed(Duration.zero);
    r.current = false;
    pending.complete(
      SocialContentResponse(
        statusCode: 200,
        body: jsonEncode({'ok': true, 'data': profile()}),
      ),
    );
    await expectLater(first, throwsA(failure('account_scope_mismatch')));
    expect(r.gateway.snapshot, isNull);
  });
  test('Profile foreign response fails closed', () async {
    final r = Rig();
    r.transport.responses.add(profile(uid: 'owner-b'));
    await expectLater(
      r.gateway.read(),
      throwsA(failure('account_scope_mismatch')),
    );
    expect(r.gateway.snapshot, isNull);
  });
  test('Profile journal is separated by account and environment', () async {
    final r = Rig();
    await r.read();
    r.transport.responses.add(Exception('fixture timeout'));
    await expectLater(
      r.gateway.save(change),
      throwsA(isA<AccountProfileFailure>()),
    );
    for (final scope in [
      (
        environment: 'fixture',
        projectId: 'fixture-project',
        tenantId: null,
        userId: 'owner-b',
      ),
      (
        environment: 'different-fixture',
        projectId: 'fixture-project',
        tenantId: null,
        userId: 'owner-a',
      ),
    ]) {
      await expectLater(
        r.newGateway(scope: scope).save(change),
        throwsA(failure('profile_read_required')),
      );
    }
    expect(r.journal.values.length, 1);
  });
  test('Profile unsupported tenant cannot create a gateway', () {
    final r = Rig();
    expect(
      () => r.newGateway(
        scope: (
          environment: 'fixture',
          projectId: 'fixture-project',
          tenantId: 'tenant-a',
          userId: 'owner-a',
        ),
      ),
      throwsA(failure('account_scope_mismatch')),
    );
  });
  for (final broken in [
    {...profile(), 'addresses': null},
    {...profile(), 'revision': -1},
    {...profile(), 'selectedAddressId': 'missing'},
    {...profile(), 'workspaceApproved': true},
  ]) {
    test(
      'Profile malformed canonical shape is unavailable ${broken.keys.last}',
      () async {
        final r = Rig();
        r.transport.responses.add(broken);
        await expectLater(
          r.gateway.read(),
          throwsA(isA<AccountProfileFailure>()),
        );
        expect(r.gateway.snapshot, isNull);
      },
    );
  }
  test('Profile failed canonical refresh retains original request', () async {
    final r = Rig();
    await r.read();
    r.transport.responses.addAll([
      receipt(),
      Exception('fixture read failure'),
    ]);
    await expectLater(
      r.gateway.save(change),
      throwsA(failure('profile_outcome_unknown')),
    );
    expect(r.journal.values.length, 1);
    expect(r.gateway.snapshot!.revision, 0);
  });
}

// Optional dedicated host integration matrix. The runner supplies a loopback
// fixture server; no app runtime define/provider or device data is changed.
class _LocalCredentials implements SocialContentCredentials {
  _LocalCredentials(this.token);
  String token;
  bool proofValid = true;
  int sequence = 0;
  static int _namespace = 0;
  final nonce =
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${++_namespace}';
  @override
  Future<String> firebaseIdToken() async => token;
  @override
  Future<String> appCheckToken(SocialAppCheckTokenMode mode) async => proofValid
      ? 'fixture-${mode == SocialAppCheckTokenMode.limitedUse ? 'limited' : 'standard'}-$nonce-${++sequence}'
      : 'fixture-invalid';
}

class _DiskJournal implements AccountProfilePendingStore {
  _DiskJournal(String root)
    : directory = Directory(root)..createSync(recursive: true);
  final Directory directory;
  File _file(String key) {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(key))
      throw StateError('Invalid fixture namespace');
    return File('${directory.path}/$key.json');
  }

  @override
  Future<String?> read(String key) async {
    final file = _file(key);
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String key, String value) async {
    await _file(key).writeAsString(value, flush: true);
  }

  @override
  Future<void> clear(String key) async {
    final f = _file(key);
    if (await f.exists()) await f.delete();
  }

  bool get pending => directory.listSync().whereType<File>().isNotEmpty;
}

class _LocalTransport implements SocialContentTransport {
  _LocalTransport(this.base);
  final Uri base;
  final io = HttpOverrides.runWithHttpOverrides(
    () => IoSocialContentTransport(
      timeout: const Duration(seconds: 5),
      followRedirects: false,
    ),
    _LocalHttpOverrides(),
  );
  final calls = <Map<String, Object?>>[];
  @override
  Future<SocialContentResponse> postJson(
    Uri endpoint, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) {
    expect(
      endpoint.toString(),
      'https://asia-south1-fixture-project.cloudfunctions.net/moolSocialAccountProfile',
    );
    calls.add((jsonDecode(jsonEncode(body)) as Map).cast<String, Object?>());
    return io.postJson(
      base.replace(path: '/moolSocialAccountProfile'),
      headers: headers,
      body: body,
    );
  }
}

class _LocalHttpOverrides extends HttpOverrides {}

void _registerLocalParity() {
  final address = Platform.environment['MOOLSOCIAL_PROFILE_LOCAL_PARITY_URL'];
  final required =
      Platform.environment['MOOLSOCIAL_PROFILE_LOCAL_PARITY_REQUIRED'] ==
      'true';
  if (address == null) {
    if (required) throw StateError('Required loopback parity service missing');
    return;
  }
  final base = Uri.parse(address);
  if (base.scheme != 'http' ||
      base.host != '127.0.0.1' ||
      base.port < 1024 ||
      base.hasQuery ||
      base.hasFragment ||
      base.userInfo.isNotEmpty)
    throw StateError('Not an isolated loopback endpoint');
  final journalRoot =
      Platform.environment['MOOLSOCIAL_PROFILE_LOCAL_PARITY_JOURNALS'];
  if (journalRoot == null)
    throw StateError('Required local fixture journal directory missing');
  IoSocialContentTransport? controlClient;
  IoSocialContentTransport controlIo() {
    final existing = controlClient;
    if (existing != null) return existing;
    final created =
        HttpOverrides.runWithHttpOverrides<IoSocialContentTransport>(
          () => IoSocialContentTransport(
            timeout: const Duration(seconds: 10),
            followRedirects: false,
          ),
          _LocalHttpOverrides(),
        );
    controlClient = created;
    return created;
  }

  Future<Map<String, dynamic>> control(
    String action, [
    Map<String, Object?> values = const {},
  ]) async {
    final result = await controlIo().postJson(
      base.replace(path: '/control'),
      headers: {},
      body: {'action': action, ...values},
    );
    expect(result.statusCode, 200);
    return jsonDecode(result.body) as Map<String, dynamic>;
  }

  var caseSequence = 0;
  ({
    AccountProfileGateway gateway,
    _LocalTransport transport,
    _LocalCredentials credentials,
    _DiskJournal journal,
    void Function(bool) current,
    AccountProfileGateway Function() reopen,
  })
  rig({String uid = 'owner-a'}) {
    var current = true;
    final credentials = _LocalCredentials(
      uid == 'owner-a' ? 'fixture-user-a' : 'fixture-user-b',
    );
    final transport = _LocalTransport(base);
    final journal = _DiskJournal(
      '$journalRoot/case-${++caseSequence}-${DateTime.now().microsecondsSinceEpoch}',
    );
    AccountProfileGateway make() => AccountProfileGateway(
      owner: (
        environment: 'fixture-local-parity',
        projectId: 'fixture-project',
        tenantId: null,
        userId: uid,
      ),
      isCurrent: () => current,
      credentials: credentials,
      pendingStore: journal,
      transport: transport,
    );
    return (
      gateway: make(),
      transport: transport,
      credentials: credentials,
      journal: journal,
      current: (bool value) {
        current = value;
      },
      reopen: make,
    );
  }

  Map<String, dynamic> account(Map<String, dynamic> stats, String uid) =>
      (stats['accounts'] as List).cast<Map<String, dynamic>>().singleWhere(
        (a) => a['uid'] == uid,
      );
  Future<SocialContentResponse> raw(
    _LocalCredentials credentials,
    String operation,
    Map<String, Object?> payload,
  ) async => controlIo().postJson(
    base.replace(path: '/moolSocialAccountProfile'),
    headers: {
      'Authorization': 'Bearer ${await credentials.firebaseIdToken()}',
      'X-Firebase-AppCheck': await credentials.appCheckToken(
        operation == 'save'
            ? SocialAppCheckTokenMode.limitedUse
            : SocialAppCheckTokenMode.standard,
      ),
    },
    body: {'operation': operation, 'payload': payload},
  );
  Future<void> saveReachedServer() async {
    for (var i = 0; i < 80; i++) {
      final stats = await control('stats');
      if ((stats['events'] as List).any(
        (e) => e['kind'] == 'http-reply' && e['operation'] == 'save',
      ))
        return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw StateError('Original save never reached the local handler');
  }

  group('B01 LOCAL PARITY', () {
    setUp(() async {
      await control('reset');
    });
    test(
      'production gateway HTTP handler repository and Unicode fingerprint agree',
      () async {
        final r = rig();
        await r.gateway.read();
        final saved = await r.gateway.save({
          'kind': 'name',
          'displayName': '  रवि   शर्मा  ',
        });
        expect(saved.displayName, 'रवि शर्मा');
        expect(saved.revision, 1);
        expect(r.journal.pending, isFalse);
        final stats = await control('stats');
        expect(account(stats, 'owner-b')['profile_revision'], 0);
        expect(account(stats, 'owner-a')['display_name'], 'रवि शर्मा');
        expect(
          (stats['events'] as List)
              .where((e) => e['kind'] == 'proof' && e['consume'] == true)
              .length,
          1,
        );
      },
    );
    test(
      'delivery and registered/unregistered invoice interfaces round-trip together',
      () async {
        final r = rig();
        await r.gateway.read();
        final addresses = [
          for (final kind in BuyV2AddressKind.values)
            BuyV2Address(
              id: 'address-${kind.name}',
              kind: kind,
              label: kind.name,
              recipient: 'Fixture recipient',
              phone: '9999999999',
              line: 'Fixture street',
              area: 'Jaipur',
              pinCode: '302001',
              landmark: 'Fixture landmark',
            ),
        ];
        await r.gateway.saveDelivery(addresses, addresses.last.id);
        final store = AccountProfileInvoiceStore(r.gateway);
        expect(
          await store.write(
            const BuyV2GstInvoiceProfileSnapshot(
              profiles: [
                BuyV2GstInvoiceProfileRecord(
                  id: 'registered-one',
                  legalName: 'Fixture registered business',
                  gstin: '08ABCDE1234F1Z5',
                  billingAddress: 'Fixture billing street',
                ),
                BuyV2GstInvoiceProfileRecord(
                  id: 'unregistered-one',
                  legalName: 'Fixture other buyer',
                  gstin: '',
                  billingAddress: 'Fixture second billing street',
                  registration: BuyV2BusinessInvoiceRegistration.unregistered,
                ),
              ],
            ),
          ),
          isTrue,
        );
        final restored = await r.reopen().read();
        expect(restored.revision, 2);
        expect(
          restored.deliveryAddresses.map((a) => a.kind),
          BuyV2AddressKind.values,
        );
        expect(restored.selectedAddressId, addresses.last.id);
        expect(restored.invoiceProfiles.length, 2);
        expect(restored.invoiceProfiles.last['registration'], 'unregistered');
      },
    );
    test(
      'account A fields cannot populate account B or accept a forged payload owner',
      () async {
        final a = rig(), b = rig(uid: 'owner-b');
        await a.gateway.read();
        await a.gateway.save({'kind': 'name', 'displayName': 'Saved owner A'});
        expect((await b.gateway.read()).displayName, 'Other account');
        final before = await control('stats');
        expect(
          (await raw(a.credentials, 'read', {
            'ownerUid': 'owner-b',
          })).statusCode,
          400,
        );
        final after = await control('stats');
        expect(after['accounts'], before['accounts']);
        b.credentials.token = 'fixture-user-a';
        await expectLater(
          b.gateway.read(),
          throwsA(failure('account_scope_mismatch')),
        );
        expect(b.gateway.snapshot, isNull);
        expect(b.gateway.ownerScope, isNull);
      },
    );
    for (final token in [
      'fixture-expired',
      'fixture-revoked',
      'fixture-tenant',
      'fixture-project-mismatch',
      'fixture-anonymous',
    ]) {
      test(
        'credential boundary rejects $token before repository access',
        () async {
          final r = rig();
          r.credentials.token = token;
          await expectLater(
            r.gateway.read(),
            throwsA(isA<AccountProfileFailure>()),
          );
          final stats = await control('stats');
          expect(
            (stats['events'] as List).where(
              (e) => e['kind'] == 'repository-read',
            ),
            isEmpty,
          );
        },
      );
    }
    test(
      'revoked credential clears cached access and valid reauthentication restores it',
      () async {
        final r = rig();
        await r.gateway.read();
        expect(r.gateway.snapshot, isNotNull);
        r.credentials.token = 'fixture-revoked';
        await expectLater(
          r.gateway.read(),
          throwsA(isA<AccountProfileFailure>()),
        );
        expect(r.gateway.snapshot, isNull);
        expect(r.gateway.ownerScope, isNull);
        r.credentials.token = 'fixture-user-a';
        expect((await r.gateway.read()).displayName, 'Original name');
        expect(r.gateway.ownerScope, isNotNull);
      },
    );
    test(
      'rejected App Check proof removes cached invoice/Profile access',
      () async {
        final r = rig();
        await r.gateway.read();
        final invoices = AccountProfileInvoiceStore(r.gateway);
        r.credentials.proofValid = false;
        await expectLater(
          r.gateway.read(),
          throwsA(isA<AccountProfileFailure>()),
        );
        expect(r.gateway.snapshot, isNull);
        expect(invoices.ownerScope, isNull);
        r.credentials.proofValid = true;
        await r.gateway.read();
        expect(invoices.ownerScope, isNotNull);
      },
    );
    test('stale source revision cannot overwrite the newer account', () async {
      final a = rig(), b = rig();
      await a.gateway.read();
      await b.gateway.read();
      await a.gateway.save({
        'kind': 'name',
        'displayName': 'First device name',
      });
      await expectLater(
        b.gateway.save({'kind': 'name', 'displayName': 'Stale device name'}),
        throwsA(failure('profile_revision_conflict')),
      );
      expect(b.journal.pending, isFalse);
      expect(b.gateway.snapshot, isNull);
      expect(
        account(await control('stats'), 'owner-a')['display_name'],
        'First device name',
      );
    });
    test(
      'identical replay returns original receipt and changed replay conflicts',
      () async {
        final r = rig();
        await r.gateway.read();
        await r.gateway.save(change);
        final request =
            (r.transport.calls.singleWhere(
                      (c) => c['operation'] == 'save',
                    )['payload']
                    as Map)
                .cast<String, Object?>();
        final before = await control('stats');
        final same = await raw(r.credentials, 'save', request);
        expect(same.statusCode, 200);
        final changed = {
          ...request,
          'change': {'kind': 'name', 'displayName': 'Changed replay'},
        };
        expect((await raw(r.credentials, 'save', changed)).statusCode, 409);
        final after = await control('stats');
        expect(after['accounts'], before['accounts']);
      },
    );
    test('rapid repeated Save dispatches one original request', () async {
      final r = rig();
      await r.gateway.read();
      await control('fault', {
        'fault': {'delayMs': 250},
      });
      final first = r.gateway.save(change);
      await saveReachedServer();
      await expectLater(
        r.gateway.save(change),
        throwsA(failure('profile_save_in_progress')),
      );
      await first;
      expect(account(await control('stats'), 'owner-a')['profile_revision'], 1);
      expect(
        r.transport.calls.where((c) => c['operation'] == 'save').length,
        1,
      );
    });
    for (final lost in ['before', 'after', 'malformed']) {
      test(
        'lost $lost HTTP response recovers from the same durable request',
        () async {
          final r = rig();
          await r.gateway.read();
          await control('fault', {
            'fault': {'response': lost},
          });
          await expectLater(
            r.gateway.save(change),
            throwsA(isA<AccountProfileFailure>()),
          );
          expect(r.journal.pending, isTrue);
          final revision = account(
            await control('stats'),
            'owner-a',
          )['profile_revision'];
          expect(revision, lost == 'before' ? 0 : 1);
          final recovered = await r.reopen().read();
          expect(recovered.displayName, 'New name');
          expect(recovered.revision, 1);
          expect(r.journal.pending, isFalse);
          final saves = r.transport.calls
              .where((c) => c['operation'] == 'save')
              .toList();
          expect(saves.length, lost == 'before' ? 2 : 1);
          if (saves.length == 2)
            expect(saves.first['payload'], saves.last['payload']);
        },
      );
    }
    for (final timing in ['before', 'after']) {
      test(
        'repository $timing-commit failure respects the original outcome',
        () async {
          final r = rig();
          await r.gateway.read();
          await control('fault', {
            'fault': {'repository': timing},
          });
          if (timing == 'before') {
            await expectLater(
              r.gateway.save(change),
              throwsA(
                isA<AccountProfileFailure>().having(
                  (e) => e.uncertain,
                  'uncertain',
                  true,
                ),
              ),
            );
            expect(
              account(await control('stats'), 'owner-a')['profile_revision'],
              0,
            );
            expect((await r.reopen().read()).revision, 1);
          } else {
            expect((await r.gateway.save(change)).revision, 1);
          }
          expect(r.journal.pending, isFalse);
          expect(
            account(await control('stats'), 'owner-a')['profile_revision'],
            1,
          );
        },
      );
    }
    test(
      'durable database reopen retains canonical profile and original receipts',
      () async {
        final r = rig();
        await r.gateway.read();
        await r.gateway.save(change);
        final before = await control('stats');
        await control('reopen');
        expect((await r.reopen().read()).displayName, 'New name');
        expect((await control('stats'))['accounts'], before['accounts']);
      },
    );
    test(
      'owner switch invalidates the late acknowledgement without modifying another account',
      () async {
        final a = rig();
        await a.gateway.read();
        await control('fault', {
          'fault': {'delayMs': 250},
        });
        final save = a.gateway.save(change);
        await saveReachedServer();
        a.current(false);
        await expectLater(save, throwsA(failure('account_scope_mismatch')));
        expect(a.gateway.snapshot, isNull);
        final b = rig(uid: 'owner-b');
        expect((await b.gateway.read()).displayName, 'Other account');
        a.current(true);
        expect((await a.reopen().read()).displayName, 'New name');
        expect(
          account(await control('stats'), 'owner-b')['profile_revision'],
          0,
        );
      },
    );
    for (final status in ['RESTRICTED', 'DELETED']) {
      test(
        'authoritative $status revokes cached profile and blocks further writes',
        () async {
          final r = rig();
          await r.gateway.read();
          await control('status', {'uid': 'owner-a', 'status': status});
          await expectLater(
            r.gateway.read(),
            throwsA(failure('account_restricted')),
          );
          expect(r.gateway.snapshot, isNull);
          expect(r.gateway.ownerScope, isNull);
          await expectLater(
            r.gateway.save(change),
            throwsA(isA<AccountProfileFailure>()),
          );
          expect(
            account(await control('stats'), 'owner-a')['profile_revision'],
            0,
          );
        },
      );
    }
    test(
      'profile changes preserve isolated historical snapshots and unrelated owner data',
      () async {
        final r = rig();
        final before = await control('stats');
        await r.gateway.read();
        await r.gateway.save(change);
        await r.gateway.saveDelivery([delivery], delivery.id);
        final after = await control('stats');
        expect(after['historical'], before['historical']);
        expect(account(after, 'owner-b'), account(before, 'owner-b'));
      },
    );
  });
  final processPhase =
      Platform.environment['MOOLSOCIAL_PROFILE_LOCAL_PROCESS_PHASE'];
  if (processPhase != null) {
    test(
      'B01 LOCAL PROCESS $processPhase preserves the original durable save',
      () async {
        if (!{'prepare', 'recover'}.contains(processPhase))
          throw StateError('Unknown process fixture phase');
        final credentials = _LocalCredentials('fixture-user-a');
        final transport = _LocalTransport(base);
        final journal = _DiskJournal('$journalRoot/process-boundary');
        final gateway = AccountProfileGateway(
          owner: (
            environment: 'fixture-local-parity',
            projectId: 'fixture-project',
            tenantId: null,
            userId: 'owner-a',
          ),
          isCurrent: () => true,
          credentials: credentials,
          pendingStore: journal,
          transport: transport,
        );
        if (processPhase == 'prepare') {
          expect(journal.pending, isFalse);
          await control('reset');
          await gateway.read();
          await control('fault', {
            'fault': {'response': 'after'},
          });
          await expectLater(
            gateway.save(change),
            throwsA(isA<AccountProfileFailure>()),
          );
          expect(journal.pending, isTrue);
          expect(
            account(await control('stats'), 'owner-a')['profile_revision'],
            1,
          );
        } else {
          expect(journal.pending, isTrue);
          expect((await gateway.read()).displayName, 'New name');
          expect(journal.pending, isFalse);
          expect(transport.calls.map((c) => c['operation']), [
            'reconcile',
            'read',
          ]);
          final stats = await control('stats');
          expect(account(stats, 'owner-a')['profile_revision'], 1);
          expect(
            (stats['events'] as List).where(
              (e) => e['kind'] == 'commit-attempt',
            ),
            isEmpty,
          );
        }
      },
    );
  }
}
