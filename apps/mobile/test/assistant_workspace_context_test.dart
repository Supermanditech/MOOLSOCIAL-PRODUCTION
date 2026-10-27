import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moolsocial/features/assistant/mool_assistant.dart';
import 'package:moolsocial/features/assistant/model_gateway.dart';
import 'package:moolsocial/features/assistant/profile_context.dart';
import 'package:moolsocial/features/journey01/journey_services.dart';
import 'package:moolsocial/features/journey01/journey_session.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/ui_v2/assistant/profile_context_adapter.dart';
import 'account_profile_gateway_test.dart' show Credentials;

const _workspaceUrl = String.fromEnvironment('MOOLSOCIAL_WORKSPACE_URL');
const _qualified = _workspaceUrl == 'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace';
class _Identity extends ReviewAuthenticatedAccountIdentityGateway implements AuthenticatedAccountPrincipalSource {
  _Identity() : super(identity: const AuthenticatedAccountIdentity(firebaseUserId: 'owner-a',
    firebaseProjectId: 'moolsocial-dev-503018', displayName: 'Host fixture owner'));
  final changes = StreamController<void>.broadcast(sync: true);
  @override ({String projectId, String? tenantId, String userId})? get currentFirebasePrincipal => identity?.firebasePrincipal;
  @override Stream<void> get firebasePrincipalChanges => changes.stream;
  @override String get persistenceEnvironment => 'firebase-service';
}
class _Scope implements WorkPendingProofStore {
  @override String? accountScope = 'owner-a';
  @override Future<Map<String, Object?>?> read(String scope) async => null;
  @override Future<void> save(String scope, Map<String, Object?> draft) async {}
  @override Future<void> clear(String scope) async {}
}
/** All network calls are intercepted here. No token or request reaches Google. */
class _Wire implements SocialContentTransport {
  bool active = true;
  String account = 'owner-a';
  int version = 1, calls = 0;
  @override Future<SocialContentResponse> postJson(Uri endpoint, {required Map<String, String> headers,
      required Map<String, Object?> body}) async {
    calls++;
    expect(body['operation'], 'listWorkspaces');
    final checked = DateTime.fromMillisecondsSinceEpoch(DateTime.now().toUtc().millisecondsSinceEpoch, isUtc: true);
    return SocialContentResponse(statusCode: 200, body: jsonEncode({'ok': true, 'data': {'workspaces': [{
      'caseId': 'case-a', 'workspaceId': 'store-a', 'profileId': 'retailer-grocery', 'name': 'Host fixture Store',
      'area': 'Host fixture area', 'primaryActivity': 'Groceries', 'status': 'approved', 'plan': 'free',
      'access': {'schemaVersion': 1, 'state': active ? 'active' : 'denied', if (active) ...{
        'accountId': account, 'workspaceId': 'store-a', 'caseId': 'case-a', 'profileId': 'retailer-grocery',
        'applicationUpdatedAt': '2026-10-27T00:00:00.000Z', 'checkedAt': checked.toIso8601String(),
        'membership': {'schemaVersion': 1, 'membershipId': 'member-a', 'state': 'active', 'version': version,
          'workspaceId': 'store-a', 'workspaceProfileId': 'retailer-grocery', 'effectiveFrom': '2026-10-26T00:00:00.000Z'}}},
    }]}}));
  }
}
Future<({JourneySession session, WorkSession work, _Wire wire, _Identity identity})> _fixture() async {
  final identity = _Identity();
  final session = JourneySession(store: MemoryJourneyStore(snapshot: const JourneySnapshot(languageCode: 'en',
    areaMode: 'skipped', setupComplete: true)), otpGateway: ReviewOtpGateway(signedIn: true), accountIdentityGateway: identity);
  await session.start();
  final wire = _Wire();
  final work = WorkSession(gateway: AuthenticatedWorkGateway(endpoint: Uri.parse('https://example.invalid/moolSocialWorkspace'),
    credentials: Credentials(), transport: wire), contactDraftStore: _Scope());
  await work.refreshFeed();
  return (session: session, work: work, wire: wire, identity: identity);
}
void main() {
  setUp(() {SharedPreferences.setMockInitialValues({}); FlutterSecureStorage.setMockInitialValues({});});
  test('THIN-B03 Workspace revision is identical to the backend canonical fixture', () {
    expect(assistantWorkspaceSourceRevision(workspaceId: 'store-a', membershipId: 'member-a', version: 1,
      applicationUpdatedAt: DateTime.parse('2026-10-27T00:00:00.000Z')),
      'workspace:6e71ffe550175578a8b42bfbecfc44754bedfd28607b95b9bf67634fb02dcd1e');
    final long = assistantWorkspaceSourceRevision(workspaceId: 'a' * 128, membershipId: 'b' * 128, version: 123,
      applicationUpdatedAt: DateTime.utc(2026, 10, 27));
    expect(long.length, 74);
  });
  test('THIN-B03 unqualified original Workspace connection stays closed', () async {
    final f = await _fixture();
    addTearDown(() async {f.work.dispose(); f.session.dispose(); await f.identity.changes.close();});
    final context = MoolAssistantContext(accountScope: f.session.authenticatedBuyPersistenceIdentity,
      authenticationRevision: f.session.navigationAuthenticationGeneration, workspaceId: 'store-a',
      workspaceRevision: 1, workspaceApproved: true, storeWorkspace: true);
    final reader = AssistantOriginalContextReader(session: f.session, work: f.work, rootCurrent: () => true);
    final calls = f.wire.calls;
    await expectLater(reader.read(context, () => true), throwsA(isA<AssistantModelFailure>()));
    expect(f.wire.calls, calls);
  }, skip: _qualified);
  test('THIN-B03 actual authenticated Workspace gateway supplies scoped canonical revisions', () async {
    final f = await _fixture();
    addTearDown(() async {f.work.dispose(); f.session.dispose(); await f.identity.changes.close();});
    expect(f.work.activeWorkspace?.id, 'store-a');
    final context = MoolAssistantContext(accountScope: f.session.authenticatedBuyPersistenceIdentity,
      authenticationRevision: f.session.navigationAuthenticationGeneration, workspaceId: 'store-a',
      workspaceRevision: 1, workspaceApproved: true, storeWorkspace: true);
    final reader = AssistantOriginalContextReader(session: f.session, work: f.work, rootCurrent: () => true);
    final first = await reader.read(context, () => true);
    expect(first.revisions.keys.toList(), [('AI-ACT-317', 'store-a')]);
    expect(first.revisions.values.single, 'workspace:6e71ffe550175578a8b42bfbecfc44754bedfd28607b95b9bf67634fb02dcd1e');
    f.wire.version = 2;
    expect((await reader.read(context, () => true)).revisions.values.single, isNot(first.revisions.values.single));
    f.wire.active = false;
    await expectLater(reader.read(context, () => true), throwsA(isA<AssistantModelFailure>()));
    expect(f.work.subscriptionPlan, 'free');
  }, skip: !_qualified);
  test('THIN-B03 foreign Workspace proof and changed selected Store cannot become context', () async {
    final f = await _fixture();
    addTearDown(() async {f.work.dispose(); f.session.dispose(); await f.identity.changes.close();});
    final context = MoolAssistantContext(accountScope: f.session.authenticatedBuyPersistenceIdentity,
      authenticationRevision: f.session.navigationAuthenticationGeneration, workspaceId: 'store-a',
      workspaceRevision: 1, workspaceApproved: true, storeWorkspace: true);
    final reader = AssistantOriginalContextReader(session: f.session, work: f.work, rootCurrent: () => true);
    f.wire.account = 'owner-b';
    await expectLater(reader.read(context, () => true), throwsA(isA<AssistantModelFailure>()));
    final other = MoolAssistantContext(accountScope: context.accountScope, authenticationRevision: context.authenticationRevision,
      workspaceId: 'store-b', workspaceRevision: 1, workspaceApproved: true, storeWorkspace: true);
    final calls = f.wire.calls;
    await expectLater(reader.read(other, () => true), throwsA(isA<AssistantModelFailure>()));
    expect(f.wire.calls, calls);
  }, skip: !_qualified);
}
