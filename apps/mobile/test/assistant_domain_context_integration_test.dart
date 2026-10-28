import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moolsocial/features/assistant/domain_context_gateway.dart';
import 'package:moolsocial/features/assistant/mool_assistant.dart';
import 'package:moolsocial/features/assistant/profile_context.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_views.dart' show BuyBrowseNativeAdapter;
import 'package:moolsocial/features/journey01/journey_services.dart' show AuthenticatedAccountIdentity;
import 'package:moolsocial/features/work/screens/work_workspace_dashboard_screen.dart' show StoreProductInitialData, StoreProductDefaultsInitialData, StoreProductNativeInitial;
import 'package:moolsocial/features/work/work_publication_data.dart' show WorkspaceProductContent;

const _port = int.fromEnvironment('AI_DOMAIN_TEST_PORT');
const _storeExport = String.fromEnvironment('AI_DOMAIN_STORE_NATIVE_EXPORT_PATH');
const _owner = (environment: 'firebase-service', projectId: 'fixture-project', tenantId: null, userId: 'domain-host-a');
class _RealLoopback extends HttpOverrides {}
HttpClient _client() => HttpOverrides.runWithHttpOverrides(() => HttpClient(), _RealLoopback());
class _Credentials implements SocialContentCredentials {
  @override Future<String> firebaseIdToken() async => 'isolated-host-token';
  @override Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {
    expect(mode, SocialAppCheckTokenMode.standard); return 'isolated-host-proof';
  }
}
class _Transport implements SocialContentTransport {
  _Transport() : client = _client();
  final HttpClient client;
  Completer<void>? returned;
  @override Future<SocialContentResponse> postJson(Uri endpoint, {required Map<String, String> headers,
      required Map<String, Object?> body}) async {
    final result = await IoSocialContentTransport(client: client, followRedirects: false,
      maximumResponseBytes: 256 * 1024).postJson(Uri.http('127.0.0.1:$_port', endpoint.path), headers: headers, body: body);
    if (returned != null && !returned!.isCompleted) returned!.complete();
    return result;
  }
}
Future<Map<String, Object?>> _control(String query) async {
  final client = _client();
  try {
    final response = await (await client.getUrl(Uri.parse('http://127.0.0.1:$_port/__fixture__?$query'))).close();
    expect(response.statusCode, 200);
    return Map<String, Object?>.from(jsonDecode(await response.transform(utf8.decoder).join()) as Map);
  } finally {client.close(force: true);}
}
class _Observer extends NavigatorObserver {
  Completer<void>? pushed;
  @override void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (pushed != null && !pushed!.isCompleted) pushed!.complete();
    super.didPush(route, previousRoute);
  }
}
Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump(const Duration(milliseconds: 350));
}
class _Rig {
  final context = ValueNotifier(const MoolAssistantContext(accountScope: _owner, authenticationRevision: 1));
  final core = BuySession();
  late final buy = BuyV2Session(core: core, reviewDataEnabled: false);
  final navigator = GlobalKey<NavigatorState>(), observer = _Observer();
  final wire = _Transport();
  late final source = AssistantDomainContextGateway(owner: _owner, isCurrent: () => current,
    credentials: _Credentials(), transport: wire);
  bool current = true;
  late final native = BuySearchNativeAdapter(session: buy, navigator: navigator.currentState!,
    currentContext: () => context.value, isRootCurrent: () => current, scopeOwner: context,
    accountIdentity: () => null, accountAuthenticated: () => true);
  late final guard = AssistantProfileContextGuard(readCanonical: source.read,
    readContext: () => context.value, ownerChanges: context, nativeAdapters: [native],
    canonicalActions: assistantDomainContextActions, recoverableActions: assistantDomainContextActions);
  Future<void> mount(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({}); FlutterSecureStorage.setMockInitialValues({});
    tester.view.devicePixelRatio = 1; tester.view.physicalSize = const Size(412, 915);
    await tester.pumpWidget(MaterialApp(navigatorKey: navigator, navigatorObservers: [observer],
      home: const Scaffold(body: Text('Original Buy owner'))));
    await tester.runAsync(() => guard.capture(context.value, () => current));
  }
  Future<MoolAssistantProposal> proposal() async {
    final snapshot = await guard.adapters.single.snapshot(context.value, null);
    expect(snapshot, isNotNull);
    // Explicit host proposal fixture. It is not model execution or consent.
    return MoolAssistantProposal(id: 'host-product-search', actionId: 'AI-ACT-001', binding: context.value.binding,
      requestRevision: 1, entitlementRevision: 'host-paid-source', validUntil: DateTime.now().add(const Duration(seconds: 30)),
      sourceRevision: snapshot!.sourceRevision, title: 'Review search', summary: 'Isolated host case', fields: {'query': 'चावल'});
  }
  Future<void> close(WidgetTester tester) async {
    debugPrint('DOMAIN-HOST closing owned fixture');
    current = false; guard.dispose(); source.dispose(); wire.client.close(force: true);
    await tester.pumpWidget(const SizedBox.shrink()); buy.dispose(); core.dispose(); context.dispose(); tester.view.reset();
    debugPrint('DOMAIN-HOST owned fixture closed');
  }
}
void main() {
  test('Domain actual owned-source backend proposal maps to the original Store editor field contract', () async {
    final data = jsonDecode(await File(_storeExport).readAsString()) as Map<String, dynamic>;
    expect(data['schemaVersion'], 1); expect(data['hostOnly'], true); expect(data['noDomainWrites'], true);
    expect((data['nativeTextFields'] as List).toSet(), StoreProductInitialData.editableFields,
      reason: 'Backend suggestions must use the existing native controllers, without invented or omitted field names.');
    final reply = data['reply'] as Map<String, dynamic>, proposal = reply['outcome'] as Map<String, dynamic>;
    expect(reply['scope'], {'audience': 'workspace', 'storeId': 'store-one'});
    expect(proposal['kind'], 'proposal'); expect(proposal['actionId'], 'AI-ACT-214'); expect(proposal['entityId'], 'owned-sku-0002');
    final fields = Map<String, Object?>.from(proposal['fields'] as Map);
    final native = StoreProductInitialData.fromFields(fields);
    expect(native.sourceCanonicalId, 'canonical-one'); expect(native.sourceSku, 'OWNED-2'); expect(native.sourcePack, '1 L');
    expect(native.sourceRetailEnabled, true); expect(native.sourceWholesaleEnabled, false);
    expect(native.inputs, {'description': 'मूल उत्पाद की जानकारी', 'sellingPrice': '100.25'});
    expect(native.inputs.containsKey('stock'), false); expect(native.inputs.containsKey('purchasePrice'), false);
    fields['description'] = 'Changed after parsing';
    expect(native.inputs['description'], 'मूल उत्पाद की जानकारी');
    expect(() => native.inputs.clear(), throwsUnsupportedError);
    expect(() => StoreProductInitialData.fromFields({...fields, 'ownerUserId': 'foreign'}), throwsFormatException);
    expect((data['nativeDefaultFields'] as List).toSet(), StoreProductDefaultsInitialData.allowedFields);
    final defaults = StoreProductDefaultsInitialData.fromFields(Map<String, Object?>.from(data['defaultsInput'] as Map));
    expect(defaults.fields, {'lowStockThreshold': '0005', 'customerListingRequested': false});
    expect(defaults.fields.containsKey('stockMode'), false);
    expect(() => defaults.fields.clear(), throwsUnsupportedError);
      expect((data['nativeWarrantyLabels'] as List).toSet(), WorkspaceProductContent.warrantyGuideLabels.toSet());
      final warranty = StoreProductNativeInitial.fromFields('AI-ACT-370', Map<String, Object?>.from(data['warrantyInput'] as Map));
      expect(warranty.warranty, {'Warranty issuer': 'मूल निर्माता', 'Warranty duration': '12 महीने', 'Warranty exclusions': ''});
      expect(() => warranty.warranty.clear(), throwsUnsupportedError);
      final confirmation = StoreProductNativeInitial.fromFields('AI-ACT-220', Map<String, Object?>.from(data['priceConfirmationInput'] as Map));
      expect(confirmation.validityMinutes, '00030');
      expect(confirmation.references['sourceWholesaleEnabled'], true);
      expect(StoreProductNativeInitial.fromFields('AI-ACT-372', {}).references, isEmpty);
  }, skip: _storeExport.isEmpty);
  testWidgets('Native saved-products action rejects absent owned persistence instead of showing a false empty list', (tester) async {
    const actorContext = MoolAssistantContext(accountScope: _owner, authenticationRevision: 1);
    final core = BuySession(), scope = ValueNotifier(0), navigator = GlobalKey<NavigatorState>();
    final buy = BuyV2Session(core: core, reviewDataEnabled: false);
    try {
      await tester.pumpWidget(MaterialApp(navigatorKey: navigator, home: const Scaffold(body: Text('Original owner'))));
      final adapter = BuyBrowseNativeAdapter(actionId: 'AI-ACT-010', session: buy,
        navigator: navigator.currentState!, currentContext: () => actorContext, isRootCurrent: () => true,
        scopeOwner: scope, accountAuthenticated: () => true, accountIdentity: () => const AuthenticatedAccountIdentity(
          firebaseProjectId: 'fixture-project', firebaseUserId: 'domain-host-a'));
      expect(buy.customerStateStore, isNull);
      expect(await adapter.snapshot(actorContext, null), isNull);
      expect(find.text('Original owner'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink()); buy.dispose(); core.dispose(); scope.dispose();
    }
  });
  testWidgets('Domain actual gateway HTTP original services and guard prefill original Buy search without submitting', (tester) async {
    await tester.runAsync(() => _control('reset=1')); final rig = _Rig();
    try {
      await rig.mount(tester); debugPrint('DOMAIN-HOST original context captured');
      final p = (await tester.runAsync(rig.proposal))!;
      rig.observer.pushed = Completer<void>();
      late Future<MoolAssistantReviewResult> opening;
      await tester.runAsync(() async {
        rig.wire.returned = Completer<void>();
        opening = rig.guard.adapters.single.openReview(p, () => rig.current);
        await rig.wire.returned!.future.timeout(const Duration(seconds: 10));
        // Flush real-zone network continuations before driving Flutter frames.
        // Navigator observer delivery itself may require a fake-clock frame.
        await Future<void>.delayed(Duration.zero);
      });
      debugPrint('DOMAIN-HOST original review route pushed');
      await _frames(tester); expect(find.byType(BuyV2Screen), findsOneWidget);
      expect(rig.observer.pushed!.isCompleted, true);
      expect(tester.widgetList<EditableText>(find.byType(EditableText)).any((w) => w.controller.text == 'चावल'), true);
      expect(rig.buy.query, isEmpty, reason: 'Review cannot submit the original search or any order.');
      debugPrint('DOMAIN-HOST actual editable search prefill inspected');
      rig.navigator.currentState!.pop(); await _frames(tester);
      // The original search opens its own overlay above its Buy page. Close
      // that owned overlay and then the owned page, without submitting either.
      if (rig.navigator.currentState!.canPop()) {
        expect(find.byType(BuyV2Screen), findsOneWidget);
        rig.navigator.currentState!.pop(); await _frames(tester);
      }
      expect(find.byType(BuyV2Screen), findsNothing);
      expect(find.text('Original Buy owner'), findsOneWidget);
      await tester.runAsync(() => opening.timeout(const Duration(seconds: 10)));
      debugPrint('DOMAIN-HOST original review returned');
      final counts = (await tester.runAsync(() => _control('')))!;
      expect(counts['writes'], 0); expect(counts['modelCalls'], 0); expect(counts['domainEffects'], 0);
      expect(tester.takeException(), isNull);
    } finally {await rig.close(tester);}
  }, skip: _port == 0, timeout: const Timeout(Duration(seconds: 45)));
  testWidgets('Domain actual paid withdrawal before Review cannot open the native form', (tester) async {
    await tester.runAsync(() => _control('reset=1')); final rig = _Rig();
    try {
      await rig.mount(tester); final p = (await tester.runAsync(rig.proposal))!;
      await tester.runAsync(() => _control('deny=1'));
      await tester.runAsync(() async {
        await expectLater(rig.guard.adapters.single.openReview(p, () => rig.current), throwsA(anything));
      });
      await _frames(tester); expect(find.byType(BuyV2Screen), findsNothing); expect(rig.buy.query, isEmpty);
      final counts = (await tester.runAsync(() => _control('')))!;
      expect(counts['writes'], 0); expect(counts['domainEffects'], 0);
    } finally {await rig.close(tester);}
  }, skip: _port == 0, timeout: const Timeout(Duration(seconds: 45)));
}
