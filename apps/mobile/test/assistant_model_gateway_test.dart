import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/assistant/model_gateway.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';

const modelOwner = (
  environment: 'isolated-host',
  projectId: 'fixture-project',
  tenantId: null,
  userId: 'fixture-owner',
);
final modelAt = DateTime.utc(2026, 10, 27);
const modelInput = AssistantModelInput(
  scope: (audience: 'personal', storeId: null),
  requestId: 'fixture-request',
  requestRevision: 1,
  message: 'ચોખા / चावल',
  language: 'Auto',
  expectedEntitlementRevision: 'personal:null:1:1',
);

class ModelCredentials implements SocialContentCredentials {
  Completer<String>? delayedToken;
  int proofs = 0;
  @override
  Future<String> firebaseIdToken() =>
      delayedToken?.future ?? Future.value('fixture-token');
  @override
  Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {
    expectSync(mode, SocialAppCheckTokenMode.standard);
    proofs++;
    return 'fixture-proof';
  }
}

class ModelTransport implements SocialContentTransport {
  ModelTransport(this.reply);
  final FutureOr<SocialContentResponse> Function(Map<String, Object?>) reply;
  final calls = <Map<String, Object?>>[];
  @override
  Future<SocialContentResponse> postJson(
    Uri endpoint, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    expectSync(
      endpoint.toString(),
      'https://asia-south1-fixture-project.cloudfunctions.net/moolSocialAssistantPreparation',
    );
    expectSync(headers, {
      'Authorization': 'Bearer fixture-token',
      'X-Firebase-AppCheck': 'fixture-proof',
    });
    calls.add(body);
    return reply(body);
  }
}

Map<String, Object?> modelData(
  Map<String, Object?> payload, {
  String state = 'ready',
  bool clarification = false,
}) => state != 'ready'
    ? {'state': state}
    : {
        'state': 'ready',
        'reply': {
          'scope': payload['scope'],
          'requestId': payload['requestId'],
          'requestRevision': payload['requestRevision'],
          'entitlementRevision': 'personal:null:1:1',
          'checkedAt': modelAt.toIso8601String(),
          'validUntil': modelAt
              .add(const Duration(minutes: 1))
              .toIso8601String(),
          'outcome': clarification
              ? {'kind': 'clarification', 'text': 'कौन सा पैक?'}
              : {
                  'kind': 'proposal',
                  'id': 'fixture-proposal',
                  'actionId': 'AI-ACT-001',
                  'entityId': null,
                  'sourceRevision': 'native-fixture-1',
                  'title': 'Find a product',
                  'summary': 'Review the search.',
                  'fields': {'query': 'चावल'},
                },
        },
      };
SocialContentResponse modelResponse(Map<String, Object?> data) =>
    SocialContentResponse(
      statusCode: 200,
      body: jsonEncode({'ok': true, 'data': data}),
    );
void main() {
  test(
    'AI-B01 gateway sends original Unicode and exact scope without submitted owner/key',
    () async {
      final credentials = ModelCredentials();
      final transport = ModelTransport(
        (body) => modelResponse(
          modelData(Map<String, Object?>.from(body['payload'] as Map)),
        ),
      );
      final gateway = AssistantModelGateway(
        owner: modelOwner,
        isCurrent: () => true,
        credentials: credentials,
        transport: transport,
        clock: () => modelAt,
      );
      final reply = await gateway.prepare(modelInput, () => true);
      expect(reply.state, 'ready');
      expect(reply.outcome!['kind'], 'proposal');
      expect(transport.calls.single, {
        'operation': 'prepare',
        'payload': modelInput.toJson(),
      });
      expect(transport.calls.single.toString(), isNot(contains('ownerUid')));
      expect(reply.validUntil!.isAfter(modelAt), isTrue);
    },
  );
  test(
    'AI-B01 status/cancel reuse request identity without replaying its message',
    () async {
      final transport = ModelTransport(
        (body) => modelResponse({
          'state': body['operation'] == 'cancel' ? 'cancelled' : 'pending',
        }),
      );
      final gateway = AssistantModelGateway(
        owner: modelOwner,
        isCurrent: () => true,
        credentials: ModelCredentials(),
        transport: transport,
      );
      expect((await gateway.status(modelInput, () => true)).state, 'pending');
      expect((await gateway.cancel(modelInput)).state, 'cancelled');
      expect((transport.calls.first['payload'] as Map).keys.toSet(), {
        'scope',
        'requestId',
      });
    },
  );
  test(
    'AI-B01 owner/request retirement while credentials await makes zero network calls',
    () async {
      var current = true;
      final credentials = ModelCredentials()
        ..delayedToken = Completer<String>();
      final transport = ModelTransport(
        (_) => throw StateError('must not call'),
      );
      final gateway = AssistantModelGateway(
        owner: modelOwner,
        isCurrent: () => current,
        credentials: credentials,
        transport: transport,
      );
      final future = gateway.prepare(modelInput, () => true);
      current = false;
      credentials.delayedToken!.complete('fixture-token');
      await expectLater(future, throwsA(isA<AssistantModelFailure>()));
      expect(transport.calls, isEmpty);
      expect(credentials.proofs, 0);
    },
  );
  for (final corruption in [
    'requestId',
    'requestRevision',
    'scope',
    'entitlementRevision',
    'validUntil',
    'unknown',
  ]) {
    test('AI-B01 rejects malformed/retired response: $corruption', () async {
      final transport = ModelTransport((body) {
        final data = modelData(
          Map<String, Object?>.from(body['payload'] as Map),
        );
        final reply = data['reply'] as Map;
        switch (corruption) {
          case 'requestId':
            reply['requestId'] = 'other';
          case 'requestRevision':
            reply['requestRevision'] = 7;
          case 'scope':
            reply['scope'] = {'audience': 'workspace', 'storeId': 'other'};
          case 'entitlementRevision':
            reply['entitlementRevision'] = '';
          case 'validUntil':
            reply['validUntil'] = modelAt
                .subtract(const Duration(seconds: 1))
                .toIso8601String();
          case 'unknown':
            reply['execute'] = true;
        }
        return modelResponse(data);
      });
      final gateway = AssistantModelGateway(
        owner: modelOwner,
        isCurrent: () => true,
        credentials: ModelCredentials(),
        transport: transport,
        clock: () => modelAt,
      );
      await expectLater(
        gateway.prepare(modelInput, () => true),
        throwsA(isA<AssistantModelFailure>()),
      );
    });
  }
  test('AI-B01 disposed gateway cannot retain or replay a request', () async {
    final transport = ModelTransport((_) => throw StateError('no call'));
    final gateway = AssistantModelGateway(
      owner: modelOwner,
      isCurrent: () => true,
      credentials: ModelCredentials(),
      transport: transport,
    )..dispose();
    await expectLater(
      gateway.prepare(modelInput, () => true),
      throwsA(isA<AssistantModelFailure>()),
    );
    expect(transport.calls, isEmpty);
  });
  test(
    'AI-B01 an unpaid response does not permanently poison this account after upgrade',
    () async {
      var paid = false;
      final transport = ModelTransport(
        (body) => paid
            ? modelResponse(
                modelData(Map<String, Object?>.from(body['payload'] as Map)),
              )
            : SocialContentResponse(
                statusCode: 403,
                body: jsonEncode({
                  'ok': false,
                  'error': {
                    'code': 'ai_access_required',
                    'message': 'not active',
                  },
                }),
              ),
      );
      final gateway = AssistantModelGateway(
        owner: modelOwner,
        isCurrent: () => true,
        credentials: ModelCredentials(),
        transport: transport,
        clock: () => modelAt,
      );
      await expectLater(
        gateway.prepare(modelInput, () => true),
        throwsA(isA<AssistantModelFailure>()),
      );
      expect(gateway.available, isTrue);
      paid = true;
      expect((await gateway.prepare(modelInput, () => true)).state, 'ready');
    },
  );
  test(
    'AI-B01 stale server entitlement requests canonical refresh without automatic inference retry',
    () async {
      var refreshes = 0;
      final transport = ModelTransport(
        (_) => SocialContentResponse(
          statusCode: 409,
          body: jsonEncode({
            'ok': false,
            'error': {
              'code': 'stale_entitlement',
              'message': 'refresh required',
            },
          }),
        ),
      );
      final gateway = AssistantModelGateway(
        owner: modelOwner,
        isCurrent: () => true,
        credentials: ModelCredentials(),
        transport: transport,
      );
      gateway.refreshAuthority = (scope) async {
        expect(scope, modelInput.scope);
        refreshes++;
      };
      await expectLater(
        gateway.prepare(modelInput, () => true),
        throwsA(isA<AssistantModelFailure>()),
      );
      expect(refreshes, 1);
      expect(transport.calls.length, 1);
      expect(gateway.available, isTrue);
    },
  );
}
