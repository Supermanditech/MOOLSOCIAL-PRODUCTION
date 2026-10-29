import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  test('AGG02 preview version survives request copies without altering legacy requests', () {
    final input=AssistantModelInput(scope:(audience:'workspace',storeId:'store-one'),requestId:'host-preview',
      requestRevision:1,message:'Preview saved copy',language:'English',expectedEntitlementRevision:'host-paid');
    expect(input.toJson().containsKey('nativeProductPreviewVersion'),isFalse);
    final modern=input.withProductPreviewVersion(1).withCatalogueListingIds(null).withNativeTargets(null)
      .withNativeTargetMask(null).withNativeOriginalCaptures(null);
    expect(modern.toJson()['nativeProductPreviewVersion'],1);
    expect(modern.withProductPreviewVersion(null).toJson(),input.toJson());
    expect(()=>input.withProductPreviewVersion(2),throwsA(isA<AssistantModelFailure>()));
    expect(()=>modelInput.withProductPreviewVersion(1),throwsA(isA<AssistantModelFailure>()));
    const invalid=AssistantModelInput(scope:(audience:'workspace',storeId:'store-one'),requestId:'host-invalid',
      requestRevision:1,message:'Invalid version',language:'English',expectedEntitlementRevision:'host-paid',nativeProductPreviewVersion:2);
    expect(invalid.toJson,throwsA(isA<AssistantModelFailure>()));
  });
  test('Frozen original captures survive every input copy and remain closed workspace-only hints', () {
    final captures=[(actionId:'AI-ACT-374',digest:'b'*64),(actionId:'AI-ACT-225',digest:'a'*64)];
    final input=AssistantModelInput(scope:(audience:'workspace',storeId:'store-one'),requestId:'host-original',
      requestRevision:1,message:'Check my retained request',language:'English',expectedEntitlementRevision:'host-paid')
      .withNativeOriginalCaptures(captures).withCatalogueListingIds(null).withNativeTargets(null).withNativeTargetMask(null);
    captures.clear();
    expect(input.toJson()['nativeOriginalCaptures'],[
      {'actionId':'AI-ACT-225','digest':'a'*64},{'actionId':'AI-ACT-374','digest':'b'*64}]);
    expect(()=>input.nativeOriginalCaptures!.clear(),throwsUnsupportedError);
    for(final values in [
      [(actionId:'AI-ACT-225',digest:'a'*64),(actionId:'AI-ACT-225',digest:'b'*64)],
      [(actionId:'AI-ACT-226',digest:'a'*64)],[(actionId:'AI-ACT-225',digest:'A'*64)],
      [(actionId:'AI-ACT-225',digest:'a'*63)]]) {
      expect(()=>assistantNativeOriginalCaptureSelection(values),throwsA(isA<AssistantModelFailure>()));
    }
    expect(()=>modelInput.withNativeOriginalCaptures([(actionId:'AI-ACT-225',digest:'a'*64)]).toJson(),
      throwsA(isA<AssistantModelFailure>()));
  });
  test('Compact Store readiness has canonical bounded bytes and survives immutable input copies', () {
    final mask = AssistantNativeTargetMask(fingerprint: 'a' * 64, bits: 'AQ');
    final input = AssistantModelInput(scope: (audience: 'workspace', storeId: 'store-one'), requestId: 'host-mask',
      requestRevision: 1, message: 'Original product', language: 'Auto', expectedEntitlementRevision: 'host-paid', nativeTargetMask: mask);
    expect(input.withNativeTargets([]).withCatalogueListingIds(null).toJson()['nativeTargetMask'],
      {'version': 1, 'fingerprint': 'a' * 64, 'bits': 'AQ'});
    expect(() => modelInput.withNativeTargetMask(mask).toJson(), throwsA(isA<AssistantModelFailure>()));
    for (final invalid in ['AR', 'AQ==', 'A', 'a' * (assistantNativeMaskMaxCharacters + 1)]) {
      expect(() => AssistantNativeTargetMask(fingerprint: 'a' * 64, bits: invalid), throwsA(isA<AssistantModelFailure>()));
    }
    expect(AssistantNativeTargetMask(fingerprint: 'a' * 64,
      bits: base64Url.encode(List.filled(assistantNativeMaskMaxBytes, 0)).replaceAll('=', '')).bits.length, 5000);
  });
  test('Full serialized request exceeding64KiB cannot create a pending record or request credentials', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final credentials = ModelCredentials(), wire = ModelTransport((_) => throw StateError('No dispatch'));
    final gateway = AssistantModelGateway(owner: modelOwner, isCurrent: () => true, credentials: credentials, transport: wire, clock: () => modelAt);
    addTearDown(gateway.dispose);
    final input = AssistantModelInput(scope: modelInput.scope, requestId: 'host-too-large', requestRevision: 1,
      message: 'Original task', language: 'Auto', expectedEntitlementRevision: modelInput.expectedEntitlementRevision,
      history: [for (var n = 0; n < 20; n++) {'role': 'user', 'text': 'x' * 8000}]);
    await expectLater(gateway.prepare(input, () => true), throwsA(isA<AssistantModelFailure>()));
    expect(wire.calls, isEmpty); expect(credentials.proofs, 0);
    expect(await gateway.pending(input.scope, () => true), isNull);
  });
  test('Native target hints freeze exact IDs without source permissions or alternate task codes', () {
    final hints = <AssistantNativeTargetHint>[(actionId: 'AI-ACT-001', entityId: null)];
    final input = modelInput.withNativeTargets(hints); hints.clear();
    expect(input.toJson()['nativeTargets'], [{'actionId': 'AI-ACT-001', 'entityId': null}]);
    expect(() => input.nativeTargets!.clear(), throwsUnsupportedError);
    expect(input.withCatalogueListingIds([]).nativeTargets, input.nativeTargets);
    for (final invalid in <List<AssistantNativeTargetHint>>[
      [(actionId: 'AI-ACT-001', entityId: null), (actionId: 'AI-ACT-001', entityId: null)],
      [(actionId: 'run-code', entityId: null)], [(actionId: 'AI-ACT-001', entityId: '../foreign')],
      List.generate(5001, (index) => (actionId: 'AI-ACT-001', entityId: 'item-$index')),
    ]) {
      expect(() => assistantNativeTargetSelection(invalid), throwsA(isA<AssistantModelFailure>()));
    }
    expect(modelInput.toJson().containsKey('nativeTargets'), false);
  });
  test('Catalogue read hints are immutable original listing IDs, never record payloads', () {
    final id = 'listing-${List.filled(64, 'a').join()}';
    final selected = <String>[id];
    final input = modelInput.withCatalogueListingIds(selected);
    selected.clear();
    expect(input.toJson()['catalogueListingIds'], [id]);
    expect(() => input.catalogueListingIds!.clear(), throwsUnsupportedError);
    for (final value in <Object?>[null, [id, id], ['invented-product'], [{'id': id}], List.filled(501, id)]) {
      expect(() => assistantCatalogueListingSelection(value), throwsA(isA<AssistantModelFailure>()));
    }
    expect(modelInput.toJson().containsKey('catalogueListingIds'), false);
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
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
