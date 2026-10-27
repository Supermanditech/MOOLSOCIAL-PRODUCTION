import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/assistant/mool_assistant.dart';
import 'package:moolsocial/features/assistant/model_gateway.dart';
import 'package:moolsocial/features/journey01/account_plans_gateway.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moolsocial/features/work/work_services.dart'
    show WorkProofPicker, WorkProofSource, WorkPickedProof;
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/ui_v2/assistant/mool_assistant_v2.dart';
import 'assistant_model_gateway_test.dart'
    show
        modelOwner,
        modelAt,
        ModelCredentials,
        ModelTransport,
        modelData,
        modelResponse;

const _localPort = int.fromEnvironment('AI_B01_LOCAL_PORT');

class _RealLocalHttp extends HttpOverrides {}

class _LoopbackModelTransport implements SocialContentTransport {
  _LoopbackModelTransport({Duration timeout = const Duration(seconds: 10)})
    : inner = IoSocialContentTransport(
        client: HttpOverrides.runWithHttpOverrides(
          () => HttpClient(),
          _RealLocalHttp(),
        ),
        followRedirects: false,
        timeout: timeout,
        maximumResponseBytes: 1024 * 1024,
      );
  final IoSocialContentTransport inner;
  @override
  Future<SocialContentResponse> postJson(
    Uri endpoint, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) {
    expectSync(endpoint.host, 'asia-south1-fixture-project.cloudfunctions.net');
    expectSync(
      {
        '/moolSocialAccountPlans',
        '/moolSocialAssistantPreparation',
      }.contains(endpoint.path),
      true,
    );
    return inner.postJson(
      Uri.http('127.0.0.1:$_localPort', endpoint.path),
      headers: headers,
      body: body,
    );
  }
}

Future<Map<String, Object?>> _localControl(Map<String, String> query) async {
  final client = HttpOverrides.runWithHttpOverrides(
    () => HttpClient(),
    _RealLocalHttp(),
  );
  try {
    final request = await client.getUrl(
      Uri.http('127.0.0.1:$_localPort', '/__fixture__', query),
    );
    final response = await request.close();
    expect(response.statusCode, 200);
    return Map<String, Object?>.from(
      jsonDecode(await response.transform(utf8.decoder).join()) as Map,
    );
  } finally {
    client.close(force: true);
  }
}

class _CaptureGuard implements MoolAssistantPreparationGuard {
 bool fail = true;
 bool live = false;
 @override bool get current => live;
 @override void retire() {live=false;}
 @override Future<void> capture(MoolAssistantContext context, bool Function() current) async {
  if(fail) throw const AssistantModelFailure('context_unavailable');
  live=current();
 }
}

class ModelEntitlements extends ChangeNotifier
    implements MoolAssistantEntitlementSource {
  MoolAssistantAccess access = MoolAssistantAccess.active;
  @override
  Future<MoolAssistantEntitlement> read(Object accountScope) async =>
      MoolAssistantEntitlement(
        accountScope: accountScope,
        access: access,
        revision: 'personal:null:1:1',
        validUntil: modelAt.add(const Duration(minutes: 1)),
      );
}

class _HostProofPicker implements WorkProofPicker {
  @override
  Future<WorkPickedProof?> pick(WorkProofSource source) async =>
      WorkPickedProof(
        fileName: 'host-only.pdf',
        contentType: 'application/pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
      );
}

class ModelNativeAdapter implements MoolAssistantNativeAdapter {
  ModelNativeAdapter(this.context);
  final MoolAssistantContext Function() context;
  String source = 'native-fixture-1';
  int opened = 0;
  Map<String, Object?>? fields;
  @override
  String get actionId => 'AI-ACT-001';
  @override
  Set<String> get allowedFields => {'query'};
  @override
  String? validateFields(Map<String, Object?> f) =>
      f.length == 1 && f['query'] is String ? null : 'invalid';
  @override
  Future<MoolAssistantNativeSnapshot?> snapshot(
    MoolAssistantContext c,
    String? id,
  ) async => MoolAssistantNativeSnapshot(
    binding: c.binding,
    sourceRevision: source,
    permitted: true,
  );
  @override
  Future<MoolAssistantReviewResult> openReview(
    MoolAssistantProposal p,
    bool Function() current,
  ) async {
    if (!current()) return MoolAssistantReviewResult.stale;
    opened++;
    fields = p.fields;
    return MoolAssistantReviewResult.opened;
  }
}

Future<
  ({
    MoolAssistantController c,
    ValueNotifier<MoolAssistantContext> context,
    ModelEntitlements paid,
    ModelNativeAdapter native,
  })
>
fixture(
  ModelTransport transport, {
  MoolAssistantAccess access = MoolAssistantAccess.active,
  bool widgetOwned = false,
  WorkProofPicker? picker,
  MoolAssistantPreparationGuard? preparationGuard,
}) async {
  final context = ValueNotifier(
    const MoolAssistantContext(
      accountScope: modelOwner,
      authenticationRevision: 1,
    ),
  );
  final paid = ModelEntitlements()..access = access;
  final gateway = AssistantModelGateway(
    owner: modelOwner,
    isCurrent: () =>
        context.value.accountScope == modelOwner &&
        context.value.authenticationRevision == 1,
    credentials: ModelCredentials(),
    transport: transport,
    clock: () => modelAt,
  );
  final native = ModelNativeAdapter(() => context.value);
  final c = MoolAssistantController(
    currentContext: () => context.value,
    contextChanges: context,
    entitlements: paid,
    attachments: picker,
    preparationGuard: preparationGuard,
    nativeAdapters: [native],
    readModelSource: () => gateway,
    clock: () => modelAt,
  );
  await c.refreshAccess();
  c.setDraft('चावल खोजें');
  addTearDown(() {
    if (!widgetOwned) c.dispose();
    gateway.dispose();
    paid.dispose();
    context.dispose();
  });
  return (c: c, context: context, paid: paid, native: native);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('THIN-B03 unsent capture failure permits fresh explicit prepare without status recovery', () async {
    final guard=_CaptureGuard();
    final t=ModelTransport((b)=>modelResponse(modelData(Map<String,Object?>.from(b['payload'] as Map))));
    final f=await fixture(t,preparationGuard:guard);
    expect(await f.c.sendRequest(),false);expect(t.calls,isEmpty);expect(f.c.modelBusy,false);
    guard.fail=false;
    expect(await f.c.sendRequest(),true);
    expect(t.calls.map((b)=>b['operation']),['prepare']);
  });


  test('AI-B01 authoritative not-found status permits a new explicit request without a retry loop',() async {
    var prepares=0;
    final transport=ModelTransport((body){
      if(body['operation']=='status') return SocialContentResponse(statusCode:404,body:jsonEncode({'ok':false,'error':{'code':'request_not_found'}}));
      prepares++;
      if(prepares==1)return SocialContentResponse(statusCode:503,body:jsonEncode({'ok':false,'error':{'code':'assistant_unavailable'}}));
      return modelResponse(modelData(Map<String,Object?>.from(body['payload'] as Map)));
    });
    final f=await fixture(transport);
    expect(await f.c.sendRequest(),isFalse);expect(await f.c.sendRequest(),isFalse);
    expect(await f.c.sendRequest(),isTrue);
    expect(transport.calls.map((b)=>b['operation']),['prepare','status','prepare']);
  });
  test(
    'AI-B01 local real HTTP timeout recovers original preparation without another model call',
    () async {
      await _localControl({
        'reset': '1',
        'source': 'native-fixture-1',
        'delay': '1',
      });
      final context = ValueNotifier(
        const MoolAssistantContext(
          accountScope: modelOwner,
          authenticationRevision: 1,
        ),
      );
      final plans = AccountPlansGateway(
        owner: modelOwner,
        isCurrent: () => true,
        credentials: ModelCredentials(),
        transport: _LoopbackModelTransport(),
      );
      final paid = AccountPlansAssistantEntitlements(readGateway: () => plans);
      final source = AssistantModelGateway(
        owner: modelOwner,
        isCurrent: () => true,
        credentials: ModelCredentials(),
        transport: _LoopbackModelTransport(
          timeout: const Duration(milliseconds: 150),
        ),
      );
      final c = MoolAssistantController(
        currentContext: () => context.value,
        contextChanges: context,
        entitlements: paid,
        nativeAdapters: [ModelNativeAdapter(() => context.value)],
        readModelSource: () => source,
      );
      try {
        await c.refreshAccess();
        c.setDraft('चावल खोजें');
        expect(await c.sendRequest(), isFalse);
        expect(c.proposal, isNull);
        expect(await c.sendRequest(), isTrue);
        expect(c.proposal, isNotNull);
        expect((await _localControl({}))['modelCalls'], 1);
      } finally {
        c.dispose();
        source.dispose();
        paid.dispose();
        plans.dispose();
        context.dispose();
      }
    },
    skip: _localPort == 0
        ? 'Explicit loopback-only integration; no real model.'
        : false,
  );
  test(
    'AI-B01 selected document is never silently dropped or uploaded through the text-only gateway',
    () async {
      final transport = ModelTransport(
        (_) => throw StateError('No upload/model request permitted'),
      );
      final f = await fixture(transport, picker: _HostProofPicker());
      await f.c.pickAttachment(WorkProofSource.upload);
      expect(f.c.selectedAttachments.length, 1);
      expect(f.c.canSend, isFalse);
      expect(await f.c.sendRequest(), isFalse);
      expect(transport.calls, isEmpty);
    },
  );
  for (final retirement in ['draft', 'background']) {
    test(
      'AI-B01 $retirement change retires an in-flight request and preserves the correct draft',
      () async {
        final pending = Completer<SocialContentResponse>(),
            started = Completer<void>();
        final transport = ModelTransport((body) {
          if (body['operation'] == 'cancel')
            return modelResponse({'state': 'cancelled'});
          started.complete();
          return pending.future;
        });
        final f = await fixture(transport);
        final sending = f.c.sendRequest();
        await started.future;
        if (retirement == 'draft') {
          f.c.setDraft('दाल खोजें');
        } else {
          f.c.setForeground(false);
        }
        pending.complete(
          modelResponse(
            modelData(
              Map<String, Object?>.from(
                transport.calls.first['payload'] as Map,
              ),
            ),
          ),
        );
        expect(await sending, isFalse);
        expect(f.c.proposal, isNull);
        expect(f.c.modelBusy, isFalse);
        expect(f.c.draft, retirement == 'draft' ? 'दाल खोजें' : 'चावल खोजें');
      },
    );
  }
  testWidgets(
    'AI-B01 local real-code gateway/backend/model seam prefills the actual native Buy search without saving',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 915);
      addTearDown(tester.view.reset);
      final context = ValueNotifier(
        const MoolAssistantContext(
          accountScope: modelOwner,
          authenticationRevision: 1,
        ),
      );
      final core = BuySession();
      final buy = BuyV2Session(core: core, reviewDataEnabled: false);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text('Original Buy owner')),
        ),
      );
      final native = BuySearchNativeAdapter(
        session: buy,
        navigator: navigator.currentState!,
        currentContext: () => context.value,
        isRootCurrent: () => true,
        scopeOwner: context,
        accountIdentity: () => null,
        accountAuthenticated: () => true,
      );
      final snapshot = await native.snapshot(context.value, null);
      expect(snapshot, isNotNull);
      await tester.runAsync(
        () => _localControl({'reset': '1', 'source': snapshot!.sourceRevision}),
      );
      final plans = AccountPlansGateway(
        owner: modelOwner,
        isCurrent: () => true,
        credentials: ModelCredentials(),
        transport: _LoopbackModelTransport(),
      );
      final paid = AccountPlansAssistantEntitlements(readGateway: () => plans);
      final gateway = AssistantModelGateway(
        owner: modelOwner,
        isCurrent: () => true,
        credentials: ModelCredentials(),
        transport: _LoopbackModelTransport(),
      );
      // Keep actual socket/credential futures out of Flutter's fake event loop.
      final c = (await tester.runAsync(() async {
        final controller = MoolAssistantController(
          currentContext: () => context.value,
          contextChanges: context,
          entitlements: paid,
          nativeAdapters: [native],
          readModelSource: () => gateway,
        );
        try {
          await controller.refreshAccess().timeout(const Duration(seconds: 10));
        } on Object {
          controller.dispose();
          rethrow;
        }
        return controller;
      }))!;
      try {
        await tester.pump();
        expect(c.paidAccessCurrent, isTrue);
        c.setDraft('चावल खोजें');
        expect(
          await tester.runAsync(
            () => c.sendRequest().timeout(const Duration(seconds: 10)),
          ),
          isTrue,
        );
        expect(c.proposal, isNotNull);
        expect(buy.query, isEmpty);
        final review = c.reviewProposal();
        await tester.pumpAndSettle();
        expect(find.byType(BuyV2Screen), findsOneWidget);
        expect(
          tester
              .widgetList<EditableText>(find.byType(EditableText))
              .any((w) => w.controller.text == 'चावल'),
          isTrue,
        );
        expect(
          buy.query,
          isEmpty,
          reason:
              'A model suggestion must not submit native search or save anything.',
        );
        navigator.currentState!.pop();
        await tester.pumpAndSettle();
        await review;
        final count = await tester.runAsync(() => _localControl({}));
        expect(count!['modelCalls'], 1);
        expect(tester.takeException(), isNull);
      } finally {
        c.dispose();
        gateway.dispose();
        paid.dispose();
        plans.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
        buy.dispose();
        core.dispose();
        context.dispose();
      }
    },
    // Explicitly opt in only to the loopback service; never a live provider.
    skip: _localPort == 0,
  );
  test(
    'AI-B01 typed gateway feeds existing proposal and only Review opens original form',
    () async {
      final transport = ModelTransport(
        (body) => modelResponse(
          modelData(Map<String, Object?>.from(body['payload'] as Map)),
        ),
      );
      final f = await fixture(transport);
      expect(f.c.canSend, isTrue);
      expect(await f.c.sendRequest(), isTrue);
      expect(f.native.opened, 0);
      expect(f.c.proposal!.fields, {'query': 'चावल'});
      expect(await f.c.reviewProposal(), MoolAssistantReviewResult.opened);
      expect(f.native.opened, 1);
      expect(f.native.fields, {'query': 'चावल'});
    },
  );
  for (final state in [
    MoolAssistantAccess.subscriptionRequired,
    MoolAssistantAccess.purchasePending,
    MoolAssistantAccess.expired,
    MoolAssistantAccess.revoked,
    MoolAssistantAccess.unavailable,
  ]) {
    test('AI-B01 $state makes zero preparation calls', () async {
      final t = ModelTransport((_) => throw StateError('must not send'));
      final f = await fixture(t, access: state);
      expect(f.c.canSend, isFalse);
      expect(await f.c.sendRequest(), isFalse);
      expect(t.calls, isEmpty);
    });
  }
  test(
    'AI-B01 changed native source blocks stale Review without posting',
    () async {
      final t = ModelTransport(
        (b) => modelResponse(
          modelData(Map<String, Object?>.from(b['payload'] as Map)),
        ),
      );
      final f = await fixture(t);
      await f.c.sendRequest();
      f.native.source = 'new';
      expect(await f.c.reviewProposal(), MoolAssistantReviewResult.stale);
      expect(f.native.opened, 0);
    },
  );
  test('AI-B01 A-B-A retirement discards a late model result', () async {
    final pending = Completer<SocialContentResponse>();
    final started = Completer<void>();
    final t = ModelTransport((body) {
      if (body['operation'] == 'cancel')
        return modelResponse({'state': 'cancelled'});
      started.complete();
      return pending.future;
    });
    final f = await fixture(t);
    final sent = f.c.sendRequest();
    await started.future;
    f.context.value = const MoolAssistantContext(
      accountScope: 'other',
      authenticationRevision: 2,
    );
    f.context.value = const MoolAssistantContext(
      accountScope: modelOwner,
      authenticationRevision: 3,
    );
    final payload = Map<String, Object?>.from(t.calls.first['payload'] as Map);
    pending.complete(modelResponse(modelData(payload)));
    expect(await sent, isFalse);
    expect(f.c.proposal, isNull);
    expect(f.native.opened, 0);
    expect(f.c.canSend, isFalse);
  });
  test(
    'AI-B01 pending and transport uncertainty check the same request instead of preparing twice',
    () async {
      final t = ModelTransport((b) => modelResponse({'state': 'pending'}));
      final f = await fixture(t);
      expect(await f.c.sendRequest(), isFalse);
      expect(await f.c.sendRequest(), isFalse);
      expect(t.calls.map((v) => v['operation']), ['prepare', 'status']);
      expect(
        (t.calls[0]['payload'] as Map)['requestId'],
        (t.calls[1]['payload'] as Map)['requestId'],
      );
    },
  );
  test(
    'AI-B01 clarification stays in current conversation and sends original follow-up with ephemeral history',
    () async {
      final t = ModelTransport(
        (b) => modelResponse(
          modelData(
            Map<String, Object?>.from(b['payload'] as Map),
            clarification: true,
          ),
        ),
      );
      final f = await fixture(t);
      expect(await f.c.sendRequest(), isTrue);
      expect(f.c.messages.length, 2);
      f.c.setDraft('पाँच किलो');
      expect(await f.c.sendRequest(), isTrue);
      final payload = t.calls.last['payload'] as Map;
      expect(payload['message'], 'पाँच किलो');
      expect((payload['history'] as List).length, 2);
    },
  );
  testWidgets(
    'AI-B01 composer retains original Send slot and exposes cancel only during preparation',
    (tester) async {
      final pending = Completer<SocialContentResponse>();
      final t = ModelTransport(
        (b) => b['operation'] == 'cancel'
            ? modelResponse({'state': 'cancelled'})
            : pending.future,
      );
      final f = await fixture(t, widgetOwned: true);
      await tester.pumpWidget(
        MaterialApp(
          home: MoolAssistantPage(controller: f.c, disposeController: true),
        ),
      );
      await tester.tap(find.byKey(const Key('mool-assistant-send')));
      await tester.pump();
      expect(find.byTooltip('Cancel preparation'), findsOneWidget);
      expect(find.text('Preparing…'), findsOneWidget);
      await tester.tap(find.byKey(const Key('mool-assistant-send')));
      await tester.pump();
      pending.complete(modelResponse({'state': 'cancelled'}));
      await tester.pumpAndSettle();
      expect(f.c.proposal, isNull);
      expect(f.c.modelBusy, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
