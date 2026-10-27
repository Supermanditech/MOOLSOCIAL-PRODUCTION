import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:moolsocial/features/assistant/mool_assistant.dart';
import 'package:moolsocial/features/journey01/account_plans_gateway.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';

const owner = (
  environment: 'isolated-host',
  projectId: 'fixture-project',
  tenantId: null,
  userId: 'fixture-owner',
);
const personal = (audience: 'personal', storeId: null);
const workspace = (audience: 'workspace', storeId: 'fixture-store');
final at = DateTime.utc(2026, 10, 27, 8);
Map<String, Object?> plansFixture({
  AccountPlansScope scope = personal,
  bool assigned = true,
  int count = 1,
}) => {
  'schemaVersion': 1,
  'owner': {'userId': owner.userId, 'projectId': owner.projectId},
  'scope': {'audience': scope.audience, 'storeId': scope.storeId},
  'catalogueRevision': 1,
  'subscriptionRevision': assigned ? 1 : 0,
  'checkedAt': at.toIso8601String(),
  'validUntil': at.add(const Duration(minutes: 1)).toIso8601String(),
  'offers': List.generate(
    count,
    (i) => {
      'id': 'fixture-plan-$i',
      'version': 'v1',
      'name': 'Host fixture plan $i',
      'priceLabel': 'Fixture price',
      'features': ['Fixture benefit'],
      'featureIds': ['mool_ai'],
      'eligible': true,
      'recommended': i == 0,
    },
  ),
  'subscription': assigned
      ? {
          'ownerUid': owner.userId,
          'scope': {'audience': scope.audience, 'storeId': scope.storeId},
          'revision': 1,
          'planId': 'fixture-plan-0',
          'planVersion': 'v1',
          'name': 'Host fixture plan 0',
          'state': 'active',
          'validFrom': at.subtract(const Duration(days: 1)).toIso8601String(),
          'validUntil': at.add(const Duration(days: 1)).toIso8601String(),
          'featureIds': ['mool_ai'],
        }
      : null,
  'activeFeatureIds': assigned ? ['mool_ai'] : <String>[],
};

class PlansCredentials implements SocialContentCredentials {
  final modes = <SocialAppCheckTokenMode>[];
  @override
  Future<String> firebaseIdToken() async => 'fixture-token';
  @override
  Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {
    modes.add(mode);
    return 'fixture-proof';
  }
}

class PlansTransport implements SocialContentTransport {
  PlansTransport(this.respond);
  final FutureOr<SocialContentResponse> Function(Map<String, Object?> body)
  respond;
  int calls = 0;
  @override
  Future<SocialContentResponse> postJson(
    Uri endpoint, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    expectSync(
      endpoint.toString(),
      'https://asia-south1-fixture-project.cloudfunctions.net/moolSocialAccountPlans',
    );
    expectSync(headers, {
      'Authorization': 'Bearer fixture-token',
      'X-Firebase-AppCheck': 'fixture-proof',
    });
    calls++;
    return respond(body);
  }
}

SocialContentResponse plansReply(Map<String, Object?> data) =>
    SocialContentResponse(
      statusCode: 200,
      body: jsonEncode({'ok': true, 'data': data}),
    );

void main() {
  test(
    'B02 an outstanding or failed refresh retires previously confirmed paid authority',
    () async {
      final pending = Completer<SocialContentResponse>();
      var refresh = false;
      final gateway = AccountPlansGateway(
        owner: owner,
        isCurrent: () => true,
        credentials: PlansCredentials(),
        transport: PlansTransport(
          (_) => refresh ? pending.future : plansReply(plansFixture()),
        ),
        clock: () => at,
      );
      final source = AccountPlansAssistantEntitlements(
        readGateway: () => gateway,
      );
      final changes = ChangeNotifier();
      final controller = MoolAssistantController(
        currentContext: () => const MoolAssistantContext(
          accountScope: owner,
          authenticationRevision: 1,
        ),
        contextChanges: changes,
        entitlements: source,
        clock: () => at,
      );
      addTearDown(controller.dispose);
      addTearDown(changes.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(controller.access, MoolAssistantAccess.active);
      refresh = true;
      final request = gateway.read(personal, fresh: true);
      await Future<void>.delayed(Duration.zero);
      final whilePending = controller.access;
      pending.complete(
        const SocialContentResponse(statusCode: 503, body: '{"ok":false}'),
      );
      await expectLater(request, throwsA(isA<AccountPlansFailure>()));
      await Future<void>.delayed(Duration.zero);
      expect(whilePending, MoolAssistantAccess.checking);
      expect(controller.access, MoolAssistantAccess.unavailable);
      expect(controller.paidAccessCurrent, false);
    },
  );
  test(
    'B02 a newly confirmed revocation retires an already-open assistant without a context change',
    () async {
      var row = plansFixture();
      final gateway = AccountPlansGateway(
        owner: owner,
        isCurrent: () => true,
        credentials: PlansCredentials(),
        transport: PlansTransport((_) => plansReply(row)),
        clock: () => at,
      );
      final source = AccountPlansAssistantEntitlements(
        readGateway: () => gateway,
      );
      final changes = ChangeNotifier();
      final controller = MoolAssistantController(
        currentContext: () => const MoolAssistantContext(
          accountScope: owner,
          authenticationRevision: 1,
        ),
        contextChanges: changes,
        entitlements: source,
        clock: () => at,
      );
      addTearDown(controller.dispose);
      addTearDown(changes.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(controller.access, MoolAssistantAccess.active);
      row = plansFixture();
      row['subscriptionRevision'] = 2;
      (row['subscription'] as Map<String, Object?>)['revision'] = 2;
      (row['subscription'] as Map<String, Object?>)['state'] = 'revoked';
      row['activeFeatureIds'] = <String>[];
      await gateway.read(personal, fresh: true);
      await Future<void>.delayed(Duration.zero);
      expect(controller.access, MoolAssistantAccess.revoked);
      expect(controller.paidAccessCurrent, false);
    },
  );
  test(
    'B02 gateway connects exact read contract; duplicate reads share one request',
    () async {
      final pending = Completer<SocialContentResponse>(),
          credentials = PlansCredentials();
      final transport = PlansTransport((body) {
        expect(body, {
          'operation': 'read',
          'payload': {'audience': 'personal', 'storeId': null},
        });
        return pending.future;
      });
      final gateway = AccountPlansGateway(
        owner: owner,
        isCurrent: () => true,
        credentials: credentials,
        transport: transport,
        clock: () => at,
      );
      final first = gateway.read(personal), second = gateway.read(personal);
      expect(identical(first, second), true);
      pending.complete(plansReply(plansFixture(count: 251)));
      final result = await first;
      expect((await second).offers.length, 251);
      expect(result.activeFeatureIds, ['mool_ai']);
      expect(credentials.modes, [SocialAppCheckTokenMode.standard]);
      expect(transport.calls, 1);
    },
  );
  test(
    'B02 gateway retires delayed replies after account/session change',
    () async {
      final pending = Completer<SocialContentResponse>();
      var current = true;
      final gateway = AccountPlansGateway(
        owner: owner,
        isCurrent: () => current,
        credentials: PlansCredentials(),
        transport: PlansTransport((_) => pending.future),
        clock: () => at,
      );
      final read = gateway.read(personal);
      final result = expectLater(read, throwsA(isA<AccountPlansFailure>()));
      await Future<void>.delayed(Duration.zero);
      current = false;
      pending.complete(plansReply(plansFixture()));
      await result;
    },
  );
  test(
    'B02 gateway expiry, missing catalogue and errors never become free/paid success',
    () async {
      for (final response in [
        SocialContentResponse(statusCode: 503, body: '{"ok":false}'),
        plansReply({...plansFixture(), 'validUntil': at.toIso8601String()}),
        plansReply({...plansFixture(), 'offers': null}),
      ]) {
        final gateway = AccountPlansGateway(
          owner: owner,
          isCurrent: () => true,
          credentials: PlansCredentials(),
          transport: PlansTransport((_) => response),
          clock: () => at,
        );
        await expectLater(
          gateway.read(personal),
          throwsA(isA<AccountPlansFailure>()),
        );
      }
    },
  );
  test(
    'B02 gateway rejects owner, Store, duplicate, unknown-state and forged-feature responses',
    () async {
      final variants = <Map<String, Object?>>[
        {
          ...plansFixture(),
          'owner': {'userId': 'other', 'projectId': owner.projectId},
        },
        {
          ...plansFixture(),
          'scope': {'audience': 'workspace', 'storeId': 'foreign-store'},
        },
        {
          ...plansFixture(),
          'activeFeatureIds': ['mool_ai', 'unassigned-feature'],
        },
        {...plansFixture(), 'subscriptionRevision': 0},
        {
          ...plansFixture(),
          'offers': [
            ...(plansFixture()['offers'] as List),
            ...(plansFixture()['offers'] as List),
          ],
        },
        {
          ...plansFixture(),
          'subscription': {
            ...(plansFixture()['subscription'] as Map<String, Object?>),
            'state': 'unknown',
          },
        },
      ];
      for (final row in variants) {
        final gateway = AccountPlansGateway(
          owner: owner,
          isCurrent: () => true,
          credentials: PlansCredentials(),
          transport: PlansTransport((_) => plansReply(row)),
          clock: () => at,
        );
        await expectLater(
          gateway.read(personal),
          throwsA(isA<AccountPlansFailure>()),
        );
      }
    },
  );
  test(
    'B02 gateway rejects rollback and same-revision changed benefits; new versions are accepted',
    () async {
      var row = plansFixture();
      final gateway = AccountPlansGateway(
        owner: owner,
        isCurrent: () => true,
        credentials: PlansCredentials(),
        transport: PlansTransport((_) => plansReply(row)),
        clock: () => at,
      );
      await gateway.read(personal);
      row = {...plansFixture(), 'catalogueRevision': 2};
      await gateway.read(personal);
      row = plansFixture();
      await expectLater(
        gateway.read(personal),
        throwsA(isA<AccountPlansFailure>()),
      );
      row = {...plansFixture(), 'catalogueRevision': 2, 'offers': []};
      await expectLater(
        gateway.read(personal),
        throwsA(isA<AccountPlansFailure>()),
      );
    },
  );
  test(
    'B02 connected assistant reads exact context; personal paid grant never activates Store',
    () async {
      final requests = <Object?>[];
      final gateway = AccountPlansGateway(
        owner: owner,
        isCurrent: () => true,
        credentials: PlansCredentials(),
        clock: () => at,
        transport: PlansTransport((body) {
          final scope = body['payload'] as Map<String, Object?>;
          requests.add(scope);
          return plansReply(
            scope['audience'] == 'personal'
                ? plansFixture()
                : plansFixture(scope: workspace, assigned: false),
          );
        }),
      );
      final source = AccountPlansAssistantEntitlements(
        readGateway: () => gateway,
      );
      expect((await source.read(owner)).access, MoolAssistantAccess.active);
      final result = await source.readForContext(
        const MoolAssistantContext(
          accountScope: owner,
          authenticationRevision: 1,
          workspaceId: 'fixture-store',
          workspaceRevision: 1,
          workspaceApproved: true,
          storeWorkspace: true,
        ),
      );
      expect(result.access, MoolAssistantAccess.subscriptionRequired);
      expect(requests.length, 2);
      expect(requests.last, {
        'audience': 'workspace',
        'storeId': 'fixture-store',
      });
    },
  );
  test(
    'B02 catalogue and subscription revisions each protect their own content',
    () async {
      for (final changingCatalogue in [true, false]) {
        var row = plansFixture();
        final gateway = AccountPlansGateway(
          owner: owner,
          isCurrent: () => true,
          credentials: PlansCredentials(),
          transport: PlansTransport((_) => plansReply(row)),
          clock: () => at,
        );
        await gateway.read(personal);
        row = plansFixture();
        if (changingCatalogue) {
          row['subscriptionRevision'] = 2;
          (row['subscription'] as Map<String, Object?>)['revision'] = 2;
          ((row['offers'] as List).first
                  as Map<String, Object?>)['priceLabel'] =
              'Changed fixture price';
        } else {
          row['catalogueRevision'] = 2;
          (row['subscription'] as Map<String, Object?>)['featureIds'] = [
            'mool_ai',
            'fixture-extra',
          ];
          row['activeFeatureIds'] = ['mool_ai', 'fixture-extra'];
        }
        await expectLater(
          gateway.read(personal),
          throwsA(isA<AccountPlansFailure>()),
        );
      }
    },
  );
  test(
    'B02 assistant missing gateway is unavailable; unsigned context never reads',
    () async {
      final source = AccountPlansAssistantEntitlements(readGateway: () => null);
      expect(
        (await source.read(owner)).access,
        MoolAssistantAccess.unavailable,
      );
      await expectLater(
        source.readForContext(
          const MoolAssistantContext(
            accountScope: null,
            authenticationRevision: null,
          ),
        ),
        throwsA(isA<AccountPlansFailure>()),
      );
    },
  );
}
