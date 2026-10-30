import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/work/work_order_identity_gateway.dart';
import 'package:moolsocial/features/work/work_customer_feedback.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/buy/buy_v2_saved_products_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moolsocial/features/buy/buy_session.dart';
import 'package:moolsocial/features/buy/buy_v2_session.dart';
import 'package:flutter/material.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/buy/buy_v2_models.dart';
import 'package:moolsocial/features/buy/buy_v2_content_contracts.dart';
import 'package:moolsocial/ui_v2/buy/buy_v2_screen.dart';
import 'package:moolsocial/features/work/widgets/workspace_purchase_originals.dart';

// Isolated contract fixtures; no native storage, real order or provider calls.
class OrderDocumentSourceFixture extends ChangeNotifier implements WorkspaceOrderDocumentSource {
  OrderDocumentSourceFixture({this.accountUserId = 'buyer-1'});
  @override final String accountUserId;
  @override bool isCurrent = true;
  @override Object? lifetime = Object();
  int revision = 1, reads = 0, copies = 0;
  bool empty = false;
  Future<WorkspaceOrderDocumentsRead?> Function(WorkspaceOrderDocumentTarget)? onRead;
  Future<Uint8List?> Function()? onCopy;
  static Uint8List get image => base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9XkAAAAASUVORK5CYII=');
  WorkspaceOrderDocument document({String id = 'doc-order', String kind = 'purchaseOrder', List<String> links = const []}) =>
    WorkspaceOrderDocument(id: id, kind: kind, number: kind == 'orderConfirmation' ? 'OC/2026/014' : 'PO/2026/014', revision: revision,
      printedTitle: kind == 'orderConfirmation' ? 'Order confirmation' : 'Purchase order',
      date: DateTime.utc(2026, 10, 25), particulars: const {'issuer': 'Host fixture buyer', 'recipient': 'Host fixture supplier',
        'paymentTerms': 'Against delivery', 'deliveryTerms': 'Supplier delivery'}, linkedDocumentIds: links,
      copy: WorkspaceOrderDocumentCopy(fileName: 'order.png', contentType: 'image/png', sizeBytes: image.length,
        sha256Hex: sha256.convert(image).toString()));
  WorkspaceOrderDocumentsRead snapshot(WorkspaceOrderDocumentTarget target) => WorkspaceOrderDocumentsRead(
    targetBinding: target.binding, revision: revision, documents: empty ? [] : [document()]);
  @override Future<WorkspaceOrderDocumentsRead?> read(WorkspaceOrderDocumentTarget target) async {
    reads++; return onRead == null ? snapshot(target) : onRead!(target);
  }
  @override Future<Uint8List?> readCopy(WorkspaceOrderDocumentTarget target, WorkspaceOrderDocument document) async {
    copies++; return onCopy == null ? image : onCopy!();
  }
}

// Read-only host document history; never installed into device providers.
WorkspaceOrderDocument orderChangeFixture({String kind = 'orderAmendment',
  WorkspaceOrderDocumentChanges? changes, String id = 'doc-change', List<String> links = const ['doc-order']}) =>
  WorkspaceOrderDocument(id: id, kind: kind, number: kind == 'orderCancellation' ? 'CN/2026/014' : 'AM/2026/014',
    printedTitle: kind == 'orderCancellation' ? 'Order cancellation' : 'Order amendment', revision: 1,
    date: DateTime.utc(2026, 10, 25), particulars: const {'issuer': 'Host fixture supplier'}, linkedDocumentIds: links,
    changes: changes ?? WorkspaceOrderDocumentChanges(previousDocumentId: 'doc-order', previousDocumentRevision: 1,
      reason: kind == 'orderCancellation' ? 'Supplier cannot supply the balance' : 'Revised delivery and quantity', effectiveAt: DateTime.utc(2026, 10, 25, 12),
      recordedAt: DateTime.utc(2026, 10, 25, 11), recordedBy: 'Supplier authorised operator',
      outcome: kind == 'orderCancellation' ? 'Partial cancellation recorded' : 'Amendment recorded',
      terms: kind == 'orderCancellation' ? const [] : const [WorkspaceOrderTermChange(label: 'Delivery date', before: '26 October 2026', after: '27 October 2026')],
      lines: [WorkspaceOrderLineChange(lineId: 'line-one', name: 'Flour · 25 kg bag',
        action: kind == 'orderCancellation' ? 'cancelled' : 'amended', before: '10 bags',
        after: kind == 'orderCancellation' ? '2 bags cancelled; 8 bags remain' : '8 bags')]));

class DeviceSourceFixture extends ChangeNotifier implements WorkspacePurchasedUnitSource {
  DeviceSourceFixture({this.accountUserId = 'owner-1'});
  @override final String accountUserId;
  @override bool isCurrent = true;
  @override Object? lifetime = Object();
  bool owner = true, complete = true;
  int revision = 0;
  DateTime expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 5));
  List<WorkspacePurchasedUnitRow> rows = [];
  final requests = <WorkspacePurchasedLineTarget>[];
  final _grants = <WorkspacePurchasedUnitOwnerAccess>{};
  FutureOr<WorkspacePurchasedUnitsRead?> Function(WorkspacePurchasedLineTarget)? respond;
  @override bool ownerAccessCurrent(WorkspacePurchasedUnitOwnerAccess access) => isCurrent && owner &&
    _grants.contains(access) && access.ownerAccountId == accountUserId && access.expiresAt == expiresAt;
  @override Future<WorkspacePurchasedUnitsRead?> read(WorkspacePurchasedLineTarget target) async {
    requests.add(target);
    if (respond != null) return await respond!(target);
    final access = owner && target.role == WorkspaceOrderIdentityRole.seller ? WorkspacePurchasedUnitOwnerAccess(
      ownerAccountId: accountUserId, storeId: target.reference.storeId, targetBinding: target.binding, expiresAt: expiresAt) : null;
    if (access != null) _grants.add(access);
    return WorkspacePurchasedUnitsRead(target: target, revision: revision, rows: rows, complete: complete,
      observedAt: DateTime.utc(2026, 10, 1), ownerAccess: access);
  }
  void revokeOwner() { owner = false; _grants.clear(); notifyListeners(); }
  void restoreOwner() { owner = true; notifyListeners(); }
  void rotateLifetime() { lifetime = Object(); _grants.clear(); notifyListeners(); }
}

// Accepted statements/cases supplied by a host-only source, never runtime data.
class DeviceInboxFixture extends DeviceSourceFixture implements WorkspaceReceivedDeviceReportSource {
  DeviceInboxFixture({super.accountUserId});
  int feedRevision = 1;
  bool withCase = true, reportComplete = true;
  String? nextCursor;
  final cursors = <String?>[];
  void reportsChanged() => notifyListeners();
  FutureOr<WorkspaceReceivedDeviceReports?> Function(WorkspacePurchasedLineTarget, String?)? respondReports;
  WorkspaceIssueRecord caseFor(WorkspacePurchasedLineTarget target, {int revision = 1, String? realm, List<String>? lineIds}) => WorkspaceIssueRecord(
    accountScope: target.accountUserId, workspaceId: target.reference.storeId, id: 'HOST-DEVICE-CASE', referenceId: target.reference.orderId,
    target: WorkspaceIssueTarget.customerOrder, kind: WorkspaceIssueKind.deviceMismatch, state: WorkspaceIssueState.retailerReview,
    revision: revision, updatedAt: DateTime.utc(2026, 10, 21, 9, revision), reason: 'HOST buyer reported a different serial.',
    nextStep: 'Review the buyer statement and provide details.', lines: const [], permittedResponses: const [WorkspaceIssueResponse.provideDetails],
    purchaseContext: WorkspaceIssuePurchaseContext(realm: realm ?? target.realm, reference: target.reference, lineIds: lineIds ?? [target.lineFacts['lineId'] as String]));
  WorkspaceReceivedDeviceReport reportFor(WorkspacePurchasedLineTarget target, {String id = 'HOST-REPORT-1', String note = 'HOST different device\nPrinted serial differs.', WorkspaceIssueRecord? issue}) =>
    WorkspaceReceivedDeviceReport(id: id, note: note, recordedAt: DateTime.utc(2026, 10, 21, 9), deviceRevision: 1,
      deviceFingerprint: 'a' * 64, commandFingerprint: 'b' * 64,
      rows: const [WorkspacePurchasedUnitRow(id: 'HOST-DEVICE', serial: 'HOST-PACKED-SERIAL', imei1: '11111', imei2: '22222')],
      supportCase: issue ?? (withCase ? caseFor(target) : null));
  Future<WorkspaceReceivedDeviceReports> page(WorkspacePurchasedLineTarget target, {List<WorkspaceReceivedDeviceReport>? reports,
    int? revision, bool? complete, String? cursor, WorkspacePurchaseOrder? original}) async {
    final access = (await super.read(target))!.ownerAccess!;
    return WorkspaceReceivedDeviceReports(target: target, revision: revision ?? feedRevision, ownerAccess: access, original: original,
      reports: reports ?? [reportFor(target)], complete: complete ?? reportComplete, nextCursor: cursor ?? nextCursor);
  }
  @override Future<WorkspaceReceivedDeviceReports?> readReceivedReports(WorkspacePurchasedLineTarget target, {String? cursor}) async {
    cursors.add(cursor); return respondReports == null ? page(target) : await respondReports!(target, cursor);
  }
}

class DeviceCaseGatewayFixture implements WorkCanonicalIssueCommandGateway {
  final submitted = <WorkIssueCommand>[], checked = <WorkIssueCommand>[];
  Future<WorkIssueReply> Function(WorkIssueCommand)? onSubmit, onCheck;
  WorkIssueReply reply(WorkIssueCommand command, {WorkIssueReplyState state = WorkIssueReplyState.applied}) => WorkIssueReply(
    key: command.key, operationId: command.operationId, commandDigest: command.digest, state: state,
    revision: state == WorkIssueReplyState.applied ? command.draft.expectedRevision + 1 : null);
  @override Future<WorkIssueReply> submitIssueResponse(WorkIssueCommand command) async {
    submitted.add(command); return onSubmit == null ? reply(command) : onSubmit!(command);
  }
  @override Future<WorkIssueReply> reconcileIssueResponse(WorkIssueCommand command) async {
    checked.add(command); return onCheck == null ? reply(command) : onCheck!(command);
  }
}

class DeviceDraftFixture implements WorkPurchasedUnitDraftStore {
  WorkspacePurchasedUnitDraft? saved;
  bool failNextSave = false;
  Completer<void>? holdNextSave;
  int reads = 0;
  final writes = <WorkspacePurchasedUnitDraft>[];
  @override Future<WorkspacePurchasedUnitDraft?> read(WorkspacePurchasedUnitDraftKey key) async { reads++; return saved; }
  @override Future<void> save(WorkspacePurchasedUnitDraft draft, {required int? expectedRevision}) async {
    final held = holdNextSave; holdNextSave = null; await held?.future;
    if (failNextSave) { failNextSave = false; throw StateError('HOST private save unavailable'); }
    if (saved?.revision != expectedRevision) throw StateError('HOST private conflict');
    saved = draft; writes.add(draft);
  }
}

class DevicePublisherFixture extends DeviceSourceFixture implements WorkspacePurchasedUnitPublisher {
  final shares = <WorkspacePurchasedUnitPublishCommand>[], checks = <WorkspacePurchasedUnitPublishCommand>[];
  FutureOr<WorkspacePurchasedUnitPublishReply?> Function(WorkspacePurchasedLineTarget, WorkspacePurchasedUnitPublishCommand)? onShare, onCheck;
  Future<void> Function()? beforeRead;
  @override Future<WorkspacePurchasedUnitsRead?> read(WorkspacePurchasedLineTarget target) async {
    await beforeRead?.call(); return super.read(target);
  }
  WorkspacePurchasedUnitPublishReply reply(WorkspacePurchasedLineTarget target, WorkspacePurchasedUnitPublishCommand command,
    WorkspacePurchasedUnitPublishState state, {WorkspacePurchasedUnitsRead? record, String? operationId}) => WorkspacePurchasedUnitPublishReply(
      operationId: operationId ?? command.operationId, commandFingerprint: command.fingerprint, targetBinding: target.binding, state: state, record: record);
  Future<WorkspacePurchasedUnitPublishReply> apply(WorkspacePurchasedLineTarget target, WorkspacePurchasedUnitPublishCommand command) async {
    rows = List.of(command.rows); revision = command.expectedRevision + 1;
    return reply(target, command, WorkspacePurchasedUnitPublishState.applied, record: await read(target));
  }
  @override Future<WorkspacePurchasedUnitPublishReply?> share(WorkspacePurchasedLineTarget target, WorkspacePurchasedUnitPublishCommand command) async {
    shares.add(command); return onShare == null ? apply(target, command) : await onShare!(target, command);
  }
  @override Future<WorkspacePurchasedUnitPublishReply?> checkSharing(WorkspacePurchasedLineTarget target, WorkspacePurchasedUnitPublishCommand command) async {
    checks.add(command); return onCheck == null ? apply(target, command) : await onCheck!(target, command);
  }
}

class DeviceReporterFixture extends DeviceSourceFixture implements WorkspacePurchasedUnitReporter {
  DeviceReporterFixture({super.accountUserId = 'buyer-1'}) {
    revision = 1; rows = const [WorkspacePurchasedUnitRow(id: 'supplier-device-A', serial: 'HOST-SUPPLIER-SERIAL', imei1: '111111', imei2: '222222')];
  }
  bool permit = true;
  final _reportGrants = <WorkspacePurchasedUnitReportAccess>{};
  final reports = <WorkspacePurchasedUnitMismatchCommand>[], checks = <WorkspacePurchasedUnitMismatchCommand>[];
  FutureOr<WorkspacePurchasedUnitReportReply?> Function(WorkspacePurchasedLineTarget, WorkspacePurchasedUnitMismatchCommand)? onReport, onCheck;
  Future<void> Function()? beforeRead;
  @override bool reportAccessCurrent(WorkspacePurchasedUnitReportAccess access) => isCurrent && permit && _reportGrants.contains(access) &&
    access.accountUserId == accountUserId && access.expiresAt == expiresAt;
  @override Future<WorkspacePurchasedUnitsRead?> read(WorkspacePurchasedLineTarget target) async {
    await beforeRead?.call(); final read = await super.read(target); if (read == null) return null;
    final access = permit && target.role == WorkspaceOrderIdentityRole.buyer ? WorkspacePurchasedUnitReportAccess(
      accountUserId: accountUserId, targetBinding: target.binding, expiresAt: expiresAt) : null;
    if (access != null) _reportGrants.add(access);
    return WorkspacePurchasedUnitsRead(target: read.target, revision: read.revision, rows: read.rows, observedAt: read.observedAt,
      ownerAccess: read.ownerAccess, reportAccess: access, complete: read.complete);
  }
  WorkspacePurchasedUnitReportReply reply(WorkspacePurchasedLineTarget target, WorkspacePurchasedUnitMismatchCommand command,
    {WorkspacePurchasedUnitPublishState state = WorkspacePurchasedUnitPublishState.applied, String? operationId}) => WorkspacePurchasedUnitReportReply(
      operationId: operationId ?? command.operationId, commandFingerprint: command.fingerprint, targetBinding: target.binding, state: state,
      reportId: state == WorkspacePurchasedUnitPublishState.applied ? 'HOST-REPORT-1' : null,
      recordedAt: state == WorkspacePurchasedUnitPublishState.applied ? DateTime.utc(2026, 10, 21, 9) : null);
  @override Future<WorkspacePurchasedUnitReportReply?> reportMismatch(WorkspacePurchasedLineTarget target, WorkspacePurchasedUnitMismatchCommand command) async {
    reports.add(command); return onReport == null ? reply(target, command) : await onReport!(target, command);
  }
  @override Future<WorkspacePurchasedUnitReportReply?> checkMismatch(WorkspacePurchasedLineTarget target, WorkspacePurchasedUnitMismatchCommand command) async {
    checks.add(command); return onCheck == null ? reply(target, command) : await onCheck!(target, command);
  }
  void revokeReporting() { permit = false; _reportGrants.clear(); notifyListeners(); }
  void restoreReporting() { permit = true; notifyListeners(); }
  void updateDevices(List<WorkspacePurchasedUnitRow> nextRows) { rows = List.of(nextRows); revision++; notifyListeners(); }
}

class DeviceNativeStorageFixture extends FlutterSecureStorage {
  final values = <String, String>{};
  final writes = <String>[];
  Completer<void>? holdNextWrite;
  @override Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions,
    LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async => values[key];
  @override Future<void> write({required String key, required String? value, AppleOptions? iOptions, AndroidOptions? aOptions,
    LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    final held = holdNextWrite; holdNextWrite = null; writes.add(value!); await held?.future; values[key] = value;
  }
}

class WarrantyReaderFixture implements WorkspacePurchasedWarrantyReader {
  WarrantyReaderFixture({this.accountUserId = 'buyer-1'});
  @override final String accountUserId;
  @override bool isCurrent = true;
  @override Object? lifetime = Object();
  final requests = <WorkspacePurchasedWarrantyTarget>[];
  FutureOr<WorkspacePurchasedWarrantyRead?> Function(WorkspacePurchasedWarrantyTarget)? respond;
  @override Future<WorkspacePurchasedWarrantyRead?> read(WorkspacePurchasedWarrantyTarget target) async {
    requests.add(target); return await respond?.call(target);
  }
}

WorkspacePurchasedWarrantyRead warrantyRead(WorkspacePurchasedWarrantyTarget target, {
  int revision = 1, Map<String, String> fields = const {'issuer': 'HOST original issuer', 'duration': '12 months',
    'startBasis': 'From issuer activation', 'coverage': 'Manufacturing defects', 'exclusions': 'Accidental damage',
    'service': 'Contact the issuer', 'contact': 'Recorded service desk', 'reference': 'HOST-POLICY-A'}, bool noRecord = false,
}) => WorkspacePurchasedWarrantyRead(target: target, revision: revision, recordedAt: DateTime.utc(2026, 10, 1),
  terms: noRecord ? null : WorkspacePurchasedWarrantyTerms(fields: fields));

WorkspacePurchasedSkuLine warrantyLine(Map<String, Object?> raw, {String? lineId, String? skuId}) => WorkspacePurchasedSkuLine(
  lineId: lineId ?? raw['lineId'] as String, skuId: skuId ?? raw['skuId'] as String,
  canonicalProductId: raw['canonicalProductId'] as String, verifiedPackId: raw['verifiedPackId'] as String,
  offerId: raw['offerId'] as String, offerRevision: raw['offerRevision'] as String,
  name: raw['name'] as String, packLabel: raw['packLabel'] as String, quantityMilli: raw['quantityMilli'] as int,
  quantityUnit: raw['quantityUnit'] as String, unitPriceMinor: raw['unitPriceMinor'] as int, lineTotalMinor: raw['lineTotalMinor'] as int);

Map<String, dynamic> response({String role = 'buyer'}) {
  final original = {
    'currency': 'INR',
    'amountMinor': 124000,
    'lines': [
      {
        'lineId': 'atta',
        'name': 'Aashirvaad Whole Wheat Atta',
        'detail': '1 kg',
        'quantity': 2,
        'amountMinor': 11000,
      },
    ],
  };
  final fingerprint = sha256
      .convert(
        utf8.encode(
          jsonEncode({
            'storeId': 'workspace-1',
            'orderId': 'MS-2841',
            'original': original,
          }),
        ),
      )
      .toString();
  return {
    'schemaVersion': 1,
    'viewerRole': role,
    'viewerUserId': role == 'buyer' ? 'buyer-1' : 'owner-1',
    'storeId': 'workspace-1',
    'orderId': 'MS-2841',
    'state': 'linked',
    'identity': {
      'buyerId': 'customer-1',
      'purchaseId': 'purchase-1',
      'sourceRevision': 'final-1',
      'serviceRevision': 'a' * 64,
      'originalFingerprint': fingerprint,
      'original': original,
    },
  };
}

class Credentials implements SocialContentCredentials {
  Completer<String>? token;
  final modes = <SocialAppCheckTokenMode>[];
  @override
  Future<String> firebaseIdToken() async =>
      token == null ? 'host-token' : token!.future;
  @override
  Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {
    modes.add(mode);
    return 'host-appcheck';
  }
}

class Transport implements SocialContentTransport {
  Map<String, dynamic> data = response();
  Map<String, Object?>? sent;
  Completer<void>? pending;
  int status = 200, calls = 0;
  bool fail = false;
  Map<String, dynamic> Function(Map<String, Object?> body)? respond;
  Future<void> Function(Map<String, Object?> body)? beforePost;
  final requests = <Map<String, Object?>>[];
  @override
  Future<SocialContentResponse> postJson(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    calls++;
    requests.add(Map.of(body));
    sent = body;
    await beforePost?.call(body);
    await pending?.future;
    if (fail) throw StateError('host network failure');
    return SocialContentResponse(
      statusCode: status,
      body: jsonEncode({'ok': true, 'data': respond?.call(body) ?? data}),
    );
  }
}

// Isolated serialized-storage fixture, never native account/Cart injection.
final class StarsPreferences implements SharedPreferencesAsync {
  final values = <String, String>{};
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {values[key] = value;}
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected preferences operation');
}

class StarsStateStore implements BuyV2CustomerStateStore {
  StarsStateStore({this.scope = 'host-stars-account'});
  final String scope;
  @override
  String get ownerScope => scope;
  BuyV2CustomerStateSnapshot? saved;
  int writes = 0;
  final refusedWrites = <int>{};
  Future<void> Function(int)? beforeWrite;
  @override
  Future<BuyV2CustomerStateSnapshot?> read() async => saved;
  @override
  Future<bool> write(BuyV2CustomerStateSnapshot snapshot) async {
    final sequence = ++writes;
    await beforeWrite?.call(sequence);
    if (refusedWrites.contains(sequence)) return false;
    saved = snapshot; return true;
  }
}

class StarsCatalogue implements BuyV2CommerceAdapter {
  StarsCatalogue(this.product);
  final BuyV2Product product;
  @override
  Future<BuyV2CommerceSnapshot> refresh() async => BuyV2CommerceSnapshot(
    state: BuyV2CommerceLoadState.ready, products: [product], productReportsAvailable: true);
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('Unexpected host commerce operation');
}

Map<String, dynamic> completionResponse({String role = 'buyer', bool supplied = true}) {
  final original = operationalResponse(role: role);
  return {for (final key in const ['schemaVersion', 'realm', 'authNamespace', 'viewerRole', 'viewerUserId',
    'purchaseId', 'storeId', 'orderId', 'sourceRevision', 'originalFingerprint']) key: original[key],
    'state': supplied ? 'recorded' : 'not_supplied',
    'completion': supplied ? {'id': 'completion-${'a' * 64}', 'revision': 'completion-v1', 'outcome': 'delivered',
      'occurredAt': '2026-10-16T12:01:00.000Z', 'recordedAt': '2026-10-16T12:01:01.000Z'} : null};
}
Map<String, dynamic> feedbackTargetPage({String? orderLineId, Map<String, dynamic>? purchase}) {
  final data = purchase ?? publicListingPurchaseResponse(), order = data['orders'][0], line = order['original']['lines'][0];
  final listing = line['publicListing'];
  final target = <String, dynamic>{'kind': 'product', 'purchaseId': data['purchaseId'], 'storeId': order['storeId'], 'orderId': order['orderId'],
    'orderLineId': orderLineId ?? line['lineId'], 'productId': listing['listingId'], 'productLabel': line['name'], 'originalFingerprint': order['originalFingerprint'],
    'sourceRevision': data['sourceRevision'], 'purchasedListing': listing, 'completedAt': '2026-10-16T12:00:00.000Z',
    'completionId': 'completion-${'a' * 64}', 'completionRevision': 'completed-v1'};
  target['id'] = 'feedback-${sha256.convert(utf8.encode(jsonEncode([1, 'evaluation', 'firebase-default', 'buyer-1',
    target['purchaseId'], target['storeId'], target['orderId'], target['orderLineId'], target['originalFingerprint'], target['sourceRevision'], target['productLabel'],
    listing['listingId'], listing['skuId'], listing['canonicalProductId'], listing['verifiedPackId'], listing['channel'],
    target['completionId'], target['completionRevision'], target['completedAt']])))}';
  return {'schemaVersion': 1, 'realm': 'evaluation', 'authNamespace': 'firebase-default', 'viewerRole': 'buyer', 'viewerUserId': 'buyer-1',
    'coverage': 'indexed_recorded_completions', 'targets': [target], 'nextCursor': null};
}
Map<String, dynamic> starResult() => {'schemaVersion': 1, 'realm': 'evaluation', 'authNamespace': 'firebase-default',
  'viewerRole': 'buyer', 'viewerUserId': 'buyer-1', 'operationId': 'stars-save', 'state': 'saved',
  'rating': {'target': feedbackTargetPage()['targets'][0], 'stars': 1, 'revision': 1, 'updatedAt': '2026-10-19T00:00:00.000Z'}};
Map<String, dynamic> exactTargetResponse() => Map<String, dynamic>.from(feedbackTargetPage())
  ..remove('coverage')..remove('targets')..remove('nextCursor')..['target'] = feedbackTargetPage()['targets'][0];
Map<String, dynamic> starAttempt() => {'version': 1, 'target': feedbackTargetPage()['targets'][0],
  'operationId': 'original-stars-save', 'expectedRevision': 0, 'stars': 1};
Future<(BuyV2Session, Transport, StarsStateStore)> starsSession({StarsStateStore? storage,
  Object? Function()? lifetime, BuyV2CommerceAdapter? catalogue,
  ValueNotifier<BuyV2ProcurementContext?>? procurementIdentity, Map<String, dynamic>? purchase}) async {
  final wire = Transport(), store = storage ?? StarsStateStore(), core = BuySession();
  final page = feedbackTargetPage(purchase: purchase), target = page['targets'][0];
  wire.respond = (body) => switch (body['operation']) {
    'readBuyerPurchaseProjection' => purchase ?? publicListingPurchaseResponse(),
    'listBuyerProductFeedbackTargets' => page,
    'readBuyerProductFeedbackTarget' => Map<String, dynamic>.from(page)
      ..remove('coverage')..remove('targets')..remove('nextCursor')..['target'] = target,
    'readBuyerProductStars' => {'schemaVersion': 1, 'realm': 'evaluation', 'authNamespace': 'firebase-default',
      'viewerRole': 'buyer', 'viewerUserId': 'buyer-1', 'targetId': target['id'], 'rating': null},
    'submitBuyerProductStars' => starResult()..['operationId'] = body['operationId']..['rating']['stars'] = body['stars']
      ..['rating']['target'] = target,
    'reconcileBuyerProductStars' => starResult()..['operationId'] = body['operationId']..['state'] = 'not_recorded'..['rating'] = null,
    _ => throw StateError('Unexpected isolated stars operation'),
  };
  final session = BuyV2Session(core: core, customerStateStore: store, reviewDataEnabled: false,
    procurementIdentity: procurementIdentity,
    purchaseReader: projectionGateway(wire, lifetime: lifetime), purchaseRealm: 'evaluation', commerceAdapter: catalogue);
  addTearDown(session.dispose); addTearDown(core.dispose);
  await session.restoreCustomerState();
  return (session, wire, store);
}
void connectPurchaseFixture(Transport wire, bool Function() completed, {Map<String, dynamic>? purchase}) {
  final respond = wire.respond!, details = purchase ?? publicListingPurchaseResponse(), target = feedbackTargetPage(purchase: purchase)['targets'][0];
  final refs = referenceResponse(); refs['references'][0]['originalFingerprint'] = target['originalFingerprint'];
  if (details['orders'][0]['original']['purchaser']?['kind'] == 'store') {
    refs['schemaVersion'] = 3; refs['buyingStoreId'] = details['orders'][0]['original']['purchaser']['storeId'];
  }
  wire.respond = (body) {
    switch (body['operation']) {
      case 'listBuyerPurchaseReferences': return refs;
      case 'readBuyerPurchaseProjection': return details;
      case 'readBuyerOperationalOrder': throw StateError('No operational status fixture');
      case 'readBuyerOrderCompletion':
        final reply = completionResponse(supplied: completed())..['originalFingerprint'] = target['originalFingerprint'];
        if (completed()) {
          reply['completion']['id'] = target['completionId']; reply['completion']['revision'] = target['completionRevision'];
          reply['completion']['occurredAt'] = target['completedAt'];
        }
        return reply;
      default: return respond(body);
    }
  };
}

// Physical-report contract fixtures only; no courier, payment or native Stock authority.
String restockIntegrity(Object? value) {
  Object? canonical(Object? v) => v is List ? v.map(canonical).toList() : v is Map
    ? {for (final key in v.keys.cast<String>().toList()..sort()) key: canonical(v[key])} : v;
  return sha256.convert(utf8.encode(jsonEncode(canonical(value)))).toString();
}
WorkspaceGoodsArrivalCommand restockArrivalCommand({String account = 'buyer-1', String realm = 'evaluation'}) {
  final original = WorkspaceRestockPurchaseOriginal.fromJson({'schemaVersion': 1, 'realm': realm,
    'accountScope': account, 'buyingStoreId': 'buying-store', 'reference': {'purchaseId': 'purchase-arrival',
      'storeId': 'supplier-store', 'orderId': 'order-arrival', 'originalFingerprint': 'a' * 64, 'sourceRevision': 'placement-arrival'},
    'lines': [{'lineId': 'line-arrival', 'quantityMilli': 1000, 'quantityUnit': 'pack'}]});
  return WorkspaceGoodsArrivalCommand(supplierId: 'host-local-supplier', receipt: WorkspaceSupplierGoodsReceipt(
    id: 'host-arrival', expectedDeliveryId: original.deliveryGroupId, reference: 'HOST arrival', deliveredOn: '2026-10-21',
    recordedAt: DateTime.parse('2026-10-20T20:00:00.123456Z'), recordedUtcOffsetMinutes: 330, restockOriginal: original,
    lines: [WorkspaceSupplierGoodsReceiptLine(sourceLineId: 'line-arrival', productId: 'host-local-stock',
      productLabel: 'HOST Stock item', purchaseUnit: 'pack', stockUnit: 'piece', unitsPerPack: 10,
      deliveredMilli: 600, acceptedMilli: 500, damagedMilli: 100, shortMilli: 0, expectedMilli: 1000)]));
}
Map<String, dynamic> restockArrivalResponse(WorkspaceGoodsArrivalCommand command, {bool recorded = true}) {
  final source = command.receipt.restockOriginal!;
  final group = <String, dynamic>{'schemaVersion': 1, 'realm': source.realm, 'buyingStoreId': source.buyingStoreId,
    'groupId': source.deliveryGroupId, 'source': source.toJson(), 'supplierId': command.supplierId, 'revision': 1,
    'lines': [for (final line in command.receipt.lines) {'lineId': line.sourceLineId, 'deliveredMilli': line.deliveredMilli,
      'acceptedMilli': line.acceptedMilli, 'damagedMilli': line.damagedMilli, 'mapping': {
        for (final key in ['productId', 'productLabel', 'purchaseUnit', 'stockUnit', 'unitsPerPack', 'expectedMilli']) key: line.toJson()[key]}}]};
  group['integrity'] = restockIntegrity(group);
  final proof = <String, dynamic>{'schemaVersion': 1, 'realm': source.realm, 'buyingStoreId': source.buyingStoreId,
    'operationId': command.receipt.id, 'report': 'owner_reported', 'supplierId': command.supplierId, 'receipt': command.receipt.toJson(),
    'commandFingerprint': command.fingerprint, 'receiptFingerprint': command.receiptFingerprint, 'groupRevision': 1,
    'recordedAt': '2026-10-21T12:00:00.000Z'};
  proof['integrity'] = restockIntegrity(proof);
  return {'schemaVersion': 1, 'realm': source.realm, 'viewerUserId': source.accountScope,
    'buyingStoreId': source.buyingStoreId, 'state': recorded ? 'recorded' : 'not_found',
    'proof': recorded ? proof : null, 'group': recorded ? group : null};
}

Map<String, dynamic> restockClosureResponse(WorkspaceGoodsArrivalCommand command, {Map<String, dynamic>? group}) {
  final raw = restockArrivalResponse(command), proof = raw['proof'] as Map<String, dynamic>;
  proof.remove('groupRevision'); proof.remove('recordedAt'); proof.remove('integrity');
  proof['outcome'] = 'closed'; proof['closedAt'] = '2026-10-21T12:01:00.000Z';
  proof['integrity'] = restockIntegrity(proof);
  return {...raw, 'state': 'closed', 'proof': proof, 'group': group};
}

void main() {
  originalPurchasedDeviceSourceTests();
  test('F2CHANGE immutable printed particulars bind full history', () {
    final source = OrderDocumentSourceFixture();
    final target = WorkspaceOrderDocumentTarget(accountUserId: 'buyer-1', role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', reference: operationalReference());
    WorkspaceOrderDocumentsRead read(WorkspaceOrderDocument d) => WorkspaceOrderDocumentsRead(targetBinding: target.binding,
      revision: 2, documents: [source.document(), d]);
    final amendment = orderChangeFixture(), first = read(orderChangeFixture());
    expect(first.validFor(target), isTrue);
    expect(read(orderChangeFixture(kind: 'orderCancellation')).validFor(target), isTrue);
    final changed = read(orderChangeFixture(changes: WorkspaceOrderDocumentChanges(previousDocumentId: 'doc-order',
      previousDocumentRevision: 1, reason: 'Another printed reason')));
    expect(changed.fingerprint, isNot(first.fingerprint));
    expect(() => amendment.changes!.lines.clear(), throwsUnsupportedError);
    expect(() => amendment.changes!.terms.clear(), throwsUnsupportedError);
    expect(source.document().number, 'PO/2026/014');
  });
  for (final invalid in ['missing', 'revision', 'unlinked', 'self', 'cycle']) {
    test('F2CHANGE rejects invalid previous document $invalid', () {
      final source = OrderDocumentSourceFixture();
      final target = WorkspaceOrderDocumentTarget(accountUserId: 'buyer-1', role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', reference: operationalReference());
      final previous = invalid == 'missing' ? 'doc-missing' : invalid == 'self' ? 'doc-change' : 'doc-order';
      final first = invalid == 'cycle' ? orderChangeFixture(id: 'doc-order', links: ['doc-change'],
        changes: WorkspaceOrderDocumentChanges(previousDocumentId: 'doc-change', previousDocumentRevision: 1)) : source.document();
      final second = orderChangeFixture(links: invalid == 'unlinked' ? [] : [previous],
        changes: WorkspaceOrderDocumentChanges(previousDocumentId: previous, previousDocumentRevision: invalid == 'revision' ? 2 : 1));
      expect(WorkspaceOrderDocumentsRead(targetBinding: target.binding, revision: 2, documents: [first, second]).validFor(target), isFalse);
    });
  }
  test('F2CHANGE validates absent partial malformed and wrong-kind particulars', () {
    expect(WorkspaceOrderDocumentChanges().valid, isFalse);
    expect(WorkspaceOrderDocumentChanges(reason: 'Printed reason only').valid, isTrue);
    expect(WorkspaceOrderDocumentChanges(previousDocumentRevision: 1).valid, isFalse);
    expect(WorkspaceOrderDocumentChanges(reason: ' ').valid, isFalse);
    expect(WorkspaceOrderDocumentChanges(reason: 'bad\u0000text').valid, isFalse);
    expect(WorkspaceOrderDocumentChanges(recordedAt: DateTime(2026)).valid, isFalse);
    expect(WorkspaceOrderDocumentChanges(terms: const [WorkspaceOrderTermChange(label: 'Payment')]).valid, isFalse);
    expect(WorkspaceOrderDocumentChanges(terms: const [WorkspaceOrderTermChange(label: 'Payment', before: 'Advance'),
      WorkspaceOrderTermChange(label: 'payment', after: 'Delivery')]).valid, isFalse);
    expect(WorkspaceOrderDocumentChanges(lines: const [WorkspaceOrderLineChange(lineId: 'line-one', name: 'Flour', action: 'invented', before: '10 bags')]).valid, isFalse);
    expect(orderChangeFixture(kind: 'supplierInvoice').valid, isFalse);
    expect(orderChangeFixture(changes: WorkspaceOrderDocumentChanges(reason: 'No line particulars')).valid, isTrue);
    final terms = [const WorkspaceOrderTermChange(label: 'Payment', after: 'Delivery')];
    final changes = WorkspaceOrderDocumentChanges(terms: terms); terms.clear(); expect(changes.terms, hasLength(1));
  });
  test('F2CHANGE changed amendment during copy read rejects original', () async {
    final source = OrderDocumentSourceFixture();
    var reason = 'Initial reason';
    source.onRead = (target) async => WorkspaceOrderDocumentsRead(targetBinding: target.binding, revision: 2,
      documents: [source.document(), orderChangeFixture(changes: WorkspaceOrderDocumentChanges(previousDocumentId: 'doc-order',
        previousDocumentRevision: 1, reason: reason))]);
    final gateway = projectionGateway(Transport()..data = purchaseResponse(), orderDocumentSource: source);
    final target = WorkspaceOrderDocumentTarget(accountUserId: 'buyer-1', role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', reference: operationalReference());
    final record = (await gateway.readOrderDocuments(target: target))!;
    source.onCopy = () async { reason = 'Replaced reason'; return OrderDocumentSourceFixture.image; };
    expect(await gateway.readOrderDocumentCopy(target: target, recorded: record, documentId: 'doc-order'), isNull);
  });
  for (final role in WorkspaceOrderIdentityRole.values) {
    test('F2DOC exact original authorises ${role.name} read and copy', () async {
      final account = role == WorkspaceOrderIdentityRole.buyer ? 'buyer-1' : 'owner-1';
      final source = OrderDocumentSourceFixture(accountUserId: account);
      final wire = Transport()..data = purchaseResponse(role: role.name);
      final gateway = projectionGateway(wire, account: account, orderDocumentSource: source);
      final target = WorkspaceOrderDocumentTarget(accountUserId: account, role: role, realm: 'evaluation', reference: operationalReference());
      final result = await gateway.readOrderDocuments(target: target);
      expect(result, isNotNull); expect(result!.documents.single.number, 'PO/2026/014');
      expect(await gateway.readOrderDocumentCopy(target: target, recorded: result, documentId: 'doc-order'), OrderDocumentSourceFixture.image);
      expect(source.copies, 1);
    });
  }
  test('F2DOC absent source differs from complete empty read', () async {
    final wire = Transport()..data = purchaseResponse();
    final target = WorkspaceOrderDocumentTarget(accountUserId: 'buyer-1', role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', reference: operationalReference());
    expect(await projectionGateway(wire).readOrderDocuments(target: target), isNull); expect(wire.calls, 0);
    final source = OrderDocumentSourceFixture()..empty = true;
    expect((await projectionGateway(wire, orderDocumentSource: source).readOrderDocuments(target: target))!.documents, isEmpty);
  });
  for (final change in ['account', 'realm', 'store', 'reference', 'binding', 'closed', 'lifetime', 'error']) {
    test('F2DOC rejects mismatched or retired read $change', () async {
      final source = OrderDocumentSourceFixture();
      final wire = Transport()..data = purchaseResponse();
      final gateway = projectionGateway(wire, orderDocumentSource: source);
      final reference = operationalReference();
      final target = WorkspaceOrderDocumentTarget(accountUserId: change == 'account' ? 'buyer-2' : 'buyer-1',
        role: WorkspaceOrderIdentityRole.buyer, realm: change == 'realm' ? 'other' : 'evaluation',
        buyingStoreId: change == 'store' ? 'other-store' : null,
        reference: change == 'reference' ? WorkspacePurchaseReference(purchaseId: reference.purchaseId, storeId: reference.storeId,
          orderId: reference.orderId, sourceRevision: 'other-revision', originalFingerprint: reference.originalFingerprint) : reference);
      source.onRead = (target) async {
        if (change == 'closed') source.isCurrent = false;
        if (change == 'lifetime') source.lifetime = Object();
        if (change == 'error') throw StateError('Host source unavailable');
        if (change == 'binding') return WorkspaceOrderDocumentsRead(targetBinding: 'other-binding', revision: 1, documents: [source.document()]);
        return source.snapshot(target);
      };
      expect(await gateway.readOrderDocuments(target: target), isNull);
    });
  }
  for (final change in ['bytes', 'digest', 'revision', 'access', 'parent', 'account-return']) {
    test('F2DOC copy rejects changed original or access $change', () async {
      bool current = true;
      Object? life = Object();
      final source = OrderDocumentSourceFixture();
      final wire = Transport()..data = purchaseResponse();
      final gateway = projectionGateway(wire, lifetime: () => life, orderDocumentSource: source);
      final target = WorkspaceOrderDocumentTarget(accountUserId: 'buyer-1', role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', reference: operationalReference());
      final record = (await gateway.readOrderDocuments(target: target))!;
      source.onCopy = () async {
        if (change == 'bytes') return Uint8List(0);
        if (change == 'digest') { final bad = OrderDocumentSourceFixture.image; bad[15] ^= 1; return bad; }
        if (change == 'revision') source.revision++;
        if (change == 'access') source.isCurrent = false;
        if (change == 'parent') current = false;
        if (change == 'account-return') life = Object();
        return OrderDocumentSourceFixture.image;
      };
      expect(await gateway.readOrderDocumentCopy(target: target, recorded: record, documentId: 'doc-order', inputCurrent: () => current), isNull);
    });
  }
  test('F2DOC validates document links, metadata, types and immutable lists', () {
    final source = OrderDocumentSourceFixture(), target = WorkspaceOrderDocumentTarget(accountUserId: 'buyer-1',
      role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: operationalReference());
    WorkspaceOrderDocumentsRead read(List<WorkspaceOrderDocument> docs) => WorkspaceOrderDocumentsRead(targetBinding: target.binding, revision: 1, documents: docs);
    expect(read([source.document(links: ['missing-doc'])]).validFor(target), isFalse);
    expect(read([source.document(), source.document()]).validFor(target), isFalse);
    expect(read([source.document(kind: 'invented-type')]).validFor(target), isFalse);
    expect(read([source.document(links: ['doc-confirm']), source.document(id: 'doc-confirm', kind: 'orderConfirmation')]).validFor(target), isTrue);
    final docs = [source.document()], result = read(docs); docs.clear();
    expect(result.documents, hasLength(1)); expect(() => result.documents.clear(), throwsUnsupportedError);
    expect(() => result.documents.single.particulars.clear(), throwsUnsupportedError);
    expect(const WorkspaceOrderDocumentCopy(fileName: '../wrong.pdf', contentType: 'application/pdf', sizeBytes: 5,
      sha256Hex: 'invalid').valid, isFalse);
  });
  for (final scenario in ['current', 'not-owner', 'expired', 'wrong-realm', 'wrong-line', 'retired', 'original']) {
    test('PF08 INBOX private accepted reports exact owner scope=$scenario', () async {
      final wire = Transport()..data = purchaseResponse(role: 'seller'), source = DeviceInboxFixture();
      final gateway = projectionGateway(wire, account: 'owner-1', purchasedUnitSource: source);
      final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: 'seller')['references'][0]);
      final original = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference))!;
      final line = original.lines.single;
      if (scenario == 'not-owner') source.owner = false;
      if (scenario == 'expired') source.expiresAt = DateTime.utc(2020);
      if (scenario == 'retired') source.isCurrent = false;
      source.respondReports = (target, _) => source.page(target, original: scenario == 'original' ? WorkspacePurchaseOrder(
        storeId: 'OUTSIDE-STORE', orderId: 'OUTSIDE-ORDER', originalFingerprint: 'f' * 64, lines: [], totals: {'totalMinor': 1}) : null,
        reports: [source.reportFor(target, issue: source.caseFor(target, realm: scenario == 'wrong-realm' ? 'production' : null,
          lineIds: scenario == 'wrong-line' ? ['outside-line'] : null))]);
      final result = await gateway.readReceivedDeviceReports(realm: 'evaluation', reference: reference, line: line);
      if (const ['current', 'original'].contains(scenario)) {
        expect(result!.original!.originalFingerprint, original.originalFingerprint); expect(result.original, isNot(same(original)));
        expect(result.original!.storeId, original.storeId); expect(result.original!.totals, original.totals);
        expect(result.reports.single.note, contains('\n')); expect(result.reports.single.supportCase!.lines, isEmpty);
        final handoff = WorkspaceDeviceCaseHandoff(gateway: gateway, source: source, target: result.target,
          original: result.original!, issue: result.reports.single.supportCase!, ownerAccess: result.ownerAccess);
        expect(handoff.current, isTrue); source.revokeOwner(); source.restoreOwner(); expect(handoff.current, isFalse);
      } else { expect(result, isNull); }
      source.dispose();
    });
  }
  for (final scenario in ['revoke', 'collapse', 'lifetime', 'timeout']) {
    testWidgets('PF08 INBOX held accepted report read retires $scenario', (tester) async {
      final wire = Transport()..data = purchaseResponse(role: 'seller'), source = DeviceInboxFixture();
      final gateway = projectionGateway(wire, account: 'owner-1', purchasedUnitSource: source);
      final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: 'seller')['references'][0]);
      final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference))!.lines.single;
      final held = Completer<WorkspaceReceivedDeviceReports?>(); WorkspaceReceivedDeviceReports? reply;
      source.respondReports = (target, _) async { reply = await source.page(target); return held.future; };
      var current = true;
      final pending = gateway.readReceivedDeviceReports(realm: 'evaluation', reference: reference, line: line, inputCurrent: () => current);
      await tester.pump(); expect(reply, isNotNull);
      if (scenario == 'revoke') { source.revokeOwner(); source.restoreOwner(); }
      if (scenario == 'collapse') current = false;
      if (scenario == 'lifetime') source.rotateLifetime();
      if (scenario == 'timeout') await tester.pump(const Duration(seconds: 16));
      held.complete(reply); await tester.pump(); expect(await pending, isNull); source.dispose();
    });
  }
  for (final scale in [1.0, 2.0]) {
    testWidgets('PF08 INBOX compact read-only pages case handoff and revoke scale=$scale', (tester) async {
      tester.view.physicalSize = const Size(360, 800); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      final wire = Transport()..data = purchaseResponse(role: 'seller'), source = DeviceInboxFixture();
      final gateway = projectionGateway(wire, account: 'owner-1', purchasedUnitSource: source);
      final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: 'seller')['references'][0]);
      final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference))!.lines.single;
      source.respondReports = (target, cursor) => source.page(target, reports: [source.reportFor(target, id: cursor == null ? 'HOST-REPORT-1' : 'HOST-REPORT-2')],
        complete: cursor != null, cursor: cursor == null ? 'HOST-NEXT' : null);
      final opened = <WorkspaceDeviceCaseHandoff>[];
      await tester.pumpWidget(MaterialApp(home: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)), child: Scaffold(
        body: SingleChildScrollView(child: WorkspaceReceivedDeviceReportPanel(gateway: gateway, realm: 'evaluation', reference: reference, line: line,
          onOpenCase: (handoff) async { opened.add(handoff); return true; }))))));
      Future<void> tapText(String text) async { final finder = find.text(text).first; await tester.ensureVisible(finder); await tester.pumpAndSettle();
        expect(finder.hitTestable(), findsOneWidget); await tester.tap(finder); await tester.pumpAndSettle(); }
      await tapText('Buyer device reports'); expect(find.text('Partial report history.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing); await tapText('Review linked case'); expect(opened.single.current, isTrue);
      await tapText('More reports'); expect(source.cursors, [null, 'HOST-NEXT']); expect(find.text('Report HOST-REPORT-2'), findsOneWidget);
      source.revokeOwner(); await tester.pumpAndSettle(); expect(find.textContaining('HOST-PACKED-SERIAL'), findsNothing);
      expect(opened.single.current, isFalse); expect(find.text('Review linked case'), findsNothing);
      expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
    });
  }
  testWidgets('PF08 INBOX private cached reports expire during a held refresh', (tester) async {
    final wire = Transport()..data = purchaseResponse(role: 'seller'), source = DeviceInboxFixture();
    source.expiresAt = DateTime.now().toUtc().add(const Duration(seconds: 2));
    final gateway = projectionGateway(wire, account: 'owner-1', purchasedUnitSource: source);
    final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: 'seller')['references'][0]);
    final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference))!.lines.single;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspaceReceivedDeviceReportPanel(
      gateway: gateway, realm: 'evaluation', reference: reference, line: line)))));
    await tester.tap(find.text('Buyer device reports')); await tester.pumpAndSettle(); expect(find.textContaining('HOST-PACKED-SERIAL'), findsOneWidget);
    final held = Completer<WorkspaceReceivedDeviceReports?>();
    source.respondReports = (_, _) => held.future;
    await tester.ensureVisible(find.text('Refresh reports')); await tester.tap(find.text('Refresh reports')); await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.textContaining('HOST-PACKED-SERIAL'), findsNothing); expect(find.text('Store owner access expired. Refresh reports.'), findsOneWidget);
    held.complete(null); await tester.pumpAndSettle(); expect(find.textContaining('HOST-PACKED-SERIAL'), findsNothing);
    expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
  });
  for (final scenario in ['altered', 'regression', 'case-regression', 'duplicate-page', 'unavailable', 'empty', 'partial', 'missing-case']) {
    testWidgets('PF08 INBOX refresh truth and highwater $scenario', (tester) async {
      final wire = Transport()..data = purchaseResponse(role: 'seller'), source = DeviceInboxFixture();
      final gateway = projectionGateway(wire, account: 'owner-1', purchasedUnitSource: source);
      final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: 'seller')['references'][0]);
      final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference))!.lines.single;
      if (scenario == 'missing-case') source.withCase = false;
      if (scenario == 'duplicate-page') { source.reportComplete = false; source.nextCursor = 'HOST-NEXT'; }
      if (const ['empty', 'partial'].contains(scenario)) source.respondReports = (t, _) => source.page(t, reports: [], complete: scenario == 'empty');
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspaceReceivedDeviceReportPanel(
        gateway: gateway, realm: 'evaluation', reference: reference, line: line, onOpenCase: (_) async => true)))));
      Future<void> tapText(String text) async { await tester.ensureVisible(find.text(text)); await tester.tap(find.text(text)); await tester.pumpAndSettle(); }
      await tapText('Buyer device reports');
      if (scenario == 'empty') { expect(find.text('No buyer device reports recorded.'), findsOneWidget); }
      else if (scenario == 'partial') { expect(find.text('No reports returned. Coverage is incomplete.'), findsOneWidget); }
      else if (scenario == 'missing-case') { expect(find.text('Support case not connected.'), findsOneWidget); expect(find.text('Review linked case'), findsNothing); }
      else {
        source.respondReports = (target, _) => scenario == 'unavailable' ? null : source.page(target,
          revision: scenario == 'regression' ? 0 : 2, reports: [source.reportFor(target,
            note: scenario == 'altered' ? 'HOST silently changed statement' : 'HOST different device\nPrinted serial differs.',
            issue: source.caseFor(target, revision: scenario == 'case-regression' ? 0 : 1))]);
        await tapText(scenario == 'duplicate-page' ? 'More reports' : 'Refresh reports');
        expect(find.text(scenario == 'unavailable' || scenario == 'case-regression' || scenario == 'regression'
          ? 'Current buyer device reports could not be verified. Try again.' : 'Reports changed. Refresh before continuing.'), findsOneWidget);
        expect(find.text('HOST silently changed statement'), findsNothing);
        expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Review linked case')).onPressed, isNull);
      }
      expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
    });
  }

  testWidgets('PF08 DEVICE original device details are unavailable without a private source', (tester) async {
    final data = purchaseResponse(), refs = referenceResponse(), order = data['orders'][0];
    final wire = Transport()..respond = (body) => switch (body['operation']) {
      'listBuyerPurchaseReferences' => refs, 'readBuyerPurchaseProjection' => data,
      _ => throw StateError('No unit or mutation service in isolated host fixture'),
    };
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspacePurchaseOriginals(
      gateway: projectionGateway(wire), role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation')))));
    await tester.tap(find.text('Saved purchase details')); await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('original-order-${order['orderId']}'))); await tester.pumpAndSettle();
    final device = find.text('Device details'); expect(device, findsOneWidget);
    await tester.ensureVisible(device); await tester.tap(device); await tester.pumpAndSettle();
    expect(find.text('Device details for this purchase are unavailable.'), findsOneWidget);
    expect(find.text('Add device'), findsNothing); expect(find.byType(TextField), findsNothing);
    expect(wire.requests, hasLength(2));
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('PF08 DEVICE owner manually enters actual devices and restores private draft scale=$scale', (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      tester.view.physicalSize = const Size(360, 800); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      final wire = Transport()..data = purchaseResponse(role: 'seller'), source = DeviceSourceFixture();
      final gateway = projectionGateway(wire, account: 'owner-1', purchasedUnitSource: source);
      final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: 'seller')['references'][0]);
      final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference))!.lines.single;
      final originalBytes = jsonEncode(line.toJson());
      Widget host() => MaterialApp(home: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: SingleChildScrollView(child: WorkspacePurchasedUnitsForLine(gateway: gateway,
          role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference, line: line)))));
      Future<void> tapText(String text) async {
        final control = find.text(text); await tester.ensureVisible(control); await tester.pumpAndSettle();
        await tester.tap(control); await tester.pumpAndSettle();
      }
      await tester.pumpWidget(host()); await tester.pumpAndSettle();
      await tapText('Device details'); await tapText('Prepare device details');
      expect(find.byType(TextFormField), findsNothing, reason: 'Original pack quantity must never generate device rows.');
      await tapText('Add device'); expect(find.byType(TextFormField), findsNWidgets(3));
      for (final (index, value) in [(0, 'HOST-SERIAL-ONE '), (1, '111111111111111'), (2, '222222222222222')]) {
        final field = find.byType(TextFormField).at(index); await tester.ensureVisible(field); await tester.pumpAndSettle();
        await tester.enterText(field, value); FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
      }
      await tapText('Add device'); expect(find.byType(TextFormField), findsNWidgets(6));
      final second = find.byType(TextFormField).at(3); await tester.ensureVisible(second); await tester.pumpAndSettle();
      await tester.enterText(second, 'HOST-SERIAL-TWO'); FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
      expect(find.text('Saved on this device · not shared'), findsOneWidget);
      expect(source.rows, isEmpty, reason: 'Private draft input is not the published supplier record.');
      final saved = await const FlutterSecureStorage().readAll(); expect(saved.keys.single, contains('purchased-unit-draft.v1'));
      final raw = jsonDecode(saved.values.single) as Map;
      expect(raw['rows'], hasLength(2)); expect(raw['rows'][0]['serial'], 'HOST-SERIAL-ONE ');
      expect(raw['rows'][0]['imei1'], '111111111111111'); expect(raw['rows'][0]['imei2'], '222222222222222');
      expect(jsonEncode(line.toJson()), originalBytes);
      await tester.pumpWidget(const SizedBox.shrink()); await tester.pumpAndSettle();
      await tester.pumpWidget(host()); await tester.pumpAndSettle();
      await tapText('Device details'); await tapText('Prepare device details');
      expect(find.byType(TextFormField), findsNWidgets(6));
      expect(tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text, 'HOST-SERIAL-ONE ');
      expect(tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text, '111111111111111');
      expect(tester.widget<TextField>(find.byType(TextField).at(2)).controller!.text, '222222222222222');
      final remove = find.byTooltip('Remove device 1'); await tester.ensureVisible(remove); await tester.pumpAndSettle();
      await tester.tap(remove); await tester.pumpAndSettle(); expect(find.byType(TextFormField), findsNWidgets(3));
      final beforeRevocation = await const FlutterSecureStorage().readAll();
      source.revokeOwner(); await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing); expect(find.text('Add device'), findsNothing);
      expect(await const FlutterSecureStorage().readAll(), beforeRevocation);
      expect(source.rows, isEmpty); expect(jsonEncode(line.toJson()), originalBytes);
      expect(wire.requests.every((r) => r['operation'] == 'readStorePurchaseProjection'), isTrue);
      expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
    });
  }
  for (final mode in ['buyer', 'no-owner', 'expired', 'partial']) {
    testWidgets('PF08 DEVICE $mode cannot edit supplier records or read its private draft', (tester) async {
      FlutterSecureStorage.setMockInitialValues({'HOST-other-private-key': 'KEEP'});
      final role = mode == 'buyer' ? WorkspaceOrderIdentityRole.buyer : WorkspaceOrderIdentityRole.seller;
      final account = role == WorkspaceOrderIdentityRole.buyer ? 'buyer-1' : 'owner-1';
      final wire = Transport()..data = purchaseResponse(role: role.name), source = DeviceSourceFixture(accountUserId: account)
        ..owner = mode != 'no-owner' ..complete = mode != 'partial' ..revision = 1
        ..rows = [const WorkspacePurchasedUnitRow(id: 'source-unit-1', serial: 'HOST-PUBLISHED-SERIAL')];
      if (mode == 'expired') source.expiresAt = DateTime.now().toUtc().subtract(const Duration(seconds: 1));
      final gateway = projectionGateway(wire, account: account, purchasedUnitSource: source);
      final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: role.name)['references'][0]);
      final line = (await gateway.readReferencedOrder(role: role, realm: 'evaluation', reference: reference))!.lines.single;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspacePurchasedUnitsForLine(
        gateway: gateway, role: role, realm: 'evaluation', reference: reference, line: line)))));
      await tester.tap(find.text('Device details')); await tester.pumpAndSettle();
      expect(find.text('Serial: HOST-PUBLISHED-SERIAL'), findsOneWidget);
      expect(find.text('Prepare device details'), findsNothing); expect(find.byType(TextFormField), findsNothing);
      expect(await const FlutterSecureStorage().readAll(), {'HOST-other-private-key': 'KEEP'});
      expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
    });
  }

  testWidgets('PF08 DEVICE recovery shows both copies and retires captured choices', (tester) async {
    final wire = Transport()..data = purchaseResponse(role: 'seller'), source = DeviceSourceFixture(), drafts = DeviceDraftFixture();
    final gateway = projectionGateway(wire, account: 'owner-1', purchasedUnitSource: source);
    final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: 'seller')['references'][0]);
    final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference))!.lines.single;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspacePurchasedUnitsForLine(
      gateway: gateway, role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference, line: line, draftStore: drafts)))));
    Future<void> tapText(String label) async {
      await tester.ensureVisible(find.text(label)); await tester.pumpAndSettle();
      await tester.tap(find.text(label)); await tester.pumpAndSettle();
    }
    VoidCallback callback(String label) => tester.widget<TextButton>(find.widgetWithText(TextButton, label)).onPressed!;
    Future<void> unsaved(String text) async {
      drafts.failNextSave = true;
      final field = find.byType(TextFormField).first; await tester.ensureVisible(field); await tester.pumpAndSettle();
      await tester.enterText(field, text); FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
    }
    await tapText('Device details'); await tapText('Prepare device details'); await tapText('Add device');
    await unsaved('HOST-KEPT-FIRST'); final oldRecover = callback('Recover private draft');
    await tapText('Recover private draft');
    expect(find.text('Your kept edits'), findsOneWidget); expect(find.text('Saved on this device'), findsOneWidget);
    expect(find.text('Serial: HOST-KEPT-FIRST'), findsOneWidget); expect(find.text('Serial: Not entered'), findsOneWidget);
    final oldSaved = callback('Use saved draft'), oldKept = callback('Save kept edits');
    await tapText('Save kept edits'); expect(drafts.saved!.rows.single.serial, 'HOST-KEPT-FIRST');
    await unsaved('HOST-KEPT-SECOND'); await tapText('Recover private draft');
    expect(find.text('Serial: HOST-KEPT-SECOND'), findsOneWidget); expect(find.text('Serial: HOST-KEPT-FIRST'), findsOneWidget);
    final reads = drafts.reads, writes = drafts.writes.length;
    oldRecover(); oldSaved(); oldKept(); await tester.pumpAndSettle();
    expect(drafts.reads, reads); expect(drafts.writes, hasLength(writes));
    expect(find.text('Use saved draft'), findsOneWidget); expect(find.text('Serial: HOST-KEPT-SECOND'), findsOneWidget);
    final currentRecoverChoice = callback('Save kept edits');
    await tapText('Device details'); currentRecoverChoice(); oldRecover(); await tester.pumpAndSettle();
    expect(drafts.reads, reads); expect(drafts.writes, hasLength(writes));
    await tapText('Device details'); await tapText('Recover private draft'); await tapText('Use saved draft');
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, 'HOST-KEPT-FIRST');
    expect(source.rows, isEmpty); expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
  });

  testWidgets('PF08 DEVICE notifying lifetime change retires edits and restores only saved copy', (tester) async {
    final wire = Transport()..data = purchaseResponse(role: 'seller'), source = DeviceSourceFixture(), drafts = DeviceDraftFixture();
    final gateway = projectionGateway(wire, account: 'owner-1', purchasedUnitSource: source);
    final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: 'seller')['references'][0]);
    final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference))!.lines.single;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspacePurchasedUnitsForLine(
      gateway: gateway, role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference, line: line, draftStore: drafts)))));
    Future<void> tapText(String label) async {
      await tester.ensureVisible(find.text(label)); await tester.pumpAndSettle();
      await tester.tap(find.text(label)); await tester.pumpAndSettle();
    }
    await tapText('Device details'); await tapText('Prepare device details'); await tapText('Add device');
    final saved = drafts.saved!.toJson(); drafts.failNextSave = true;
    await tester.enterText(find.byType(TextFormField).first, 'HOST-UNSAVED-OLD-LIFETIME');
    FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
    final oldRecover = tester.widget<TextButton>(find.widgetWithText(TextButton, 'Recover private draft')).onPressed!;
    source.rotateLifetime(); await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing); expect(drafts.saved!.toJson(), saved);
    final reads = drafts.reads; oldRecover(); await tester.pumpAndSettle(); expect(drafts.reads, reads);
    await tapText('Device details'); await tapText('Prepare device details');
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, isEmpty);
    expect(find.textContaining('HOST-UNSAVED-OLD-LIFETIME'), findsNothing);
    expect(drafts.saved!.toJson(), saved); expect(source.requests, hasLength(2));
    oldRecover(); await tester.pumpAndSettle(); expect(drafts.reads, reads + 1);
    expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
  });

  for (final access in ['current', 'revoked', 'new-lifetime']) {
  testWidgets('PF08 DEVICE latest accepted typing after disposal respects $access owner access', (tester) async {
    final wire = Transport()..data = purchaseResponse(role: 'seller'), source = DeviceSourceFixture(), drafts = DeviceDraftFixture();
    final gateway = projectionGateway(wire, account: 'owner-1', purchasedUnitSource: source);
    final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: 'seller')['references'][0]);
    final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference))!.lines.single;
    Widget host() => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspacePurchasedUnitsForLine(
      gateway: gateway, role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference, line: line, draftStore: drafts))));
    Future<void> tapText(String label) async {
      await tester.ensureVisible(find.text(label)); await tester.pumpAndSettle();
      await tester.tap(find.text(label)); await tester.pumpAndSettle();
    }
    await tester.pumpWidget(host()); await tapText('Device details'); await tapText('Prepare device details'); await tapText('Add device');
    final held = Completer<void>(); drafts.holdNextSave = held;
    await tester.enterText(find.byType(TextFormField).first, 'H'); await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, 'HOST-COMPLETE');
    FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
    expect(drafts.saved!.rows.single.serial, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    if (access == 'revoked') source.revokeOwner();
    if (access == 'new-lifetime') source.rotateLifetime();
    held.complete(); await tester.pumpAndSettle();
    final expected = access == 'current' ? 'HOST-COMPLETE' : 'H';
    expect(drafts.saved!.rows.single.serial, expected);
    expect(drafts.writes, hasLength(access == 'current' ? 3 : 2), reason: 'Revocation or a new lifetime cannot dispatch the coalesced remainder.');
    await tester.pumpWidget(host()); await tapText('Device details');
    if (access == 'revoked') {
      expect(find.text('Prepare device details'), findsNothing); expect(find.byType(TextFormField), findsNothing);
    } else {
      await tapText('Prepare device details');
      expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, expected);
    }
    expect(source.rows, isEmpty);
    expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
  });
  }

  for (final close in [true, false]) {
  testWidgets('PF08 DEVICE actual native settlement preserves latest edits beyond UI deadline close=$close', (tester) async {
    final wire = Transport()..data = purchaseResponse(role: 'seller'), source = DeviceSourceFixture(), native = DeviceNativeStorageFixture();
    final gateway = projectionGateway(wire, account: 'owner-1', purchasedUnitSource: source);
    final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: 'seller')['references'][0]);
    final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference))!.lines.single;
    final target = WorkspacePurchasedLineTarget(accountUserId: 'owner-1', role: WorkspaceOrderIdentityRole.seller,
      realm: 'evaluation', reference: reference, line: line);
    final key = WorkspacePurchasedUnitDraftKey(account: 'owner-1', realm: 'evaluation', store: reference.storeId, binding: target.binding);
    final store = SecureWorkPurchasedUnitDraftStore(accountScope: () => 'owner-1', targetScope: () => key.identity, storage: native);
    Widget host() => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspacePurchasedUnitsForLine(
      gateway: gateway, role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference, line: line, draftStore: store))));
    Future<void> tapText(String label) async {
      await tester.ensureVisible(find.text(label)); await tester.pumpAndSettle();
      await tester.tap(find.text(label)); await tester.pumpAndSettle();
    }
    await tester.pumpWidget(host()); await tapText('Device details'); await tapText('Prepare device details'); await tapText('Add device');
    final held = Completer<void>(); native.holdNextWrite = held;
    await tester.enterText(find.byType(TextFormField).first, 'H'); await tester.pump();
    await tester.enterText(find.byType(TextFormField).first, 'HOST-COMPLETE');
    FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
    if (close) await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 11)); await tester.pumpAndSettle();
    if (!close) {
      expect(find.text('Private draft save is still pending. Your edits are kept while the saved result is checked.'), findsOneWidget);
      expect(tester.widget<TextFormField>(find.byType(TextFormField).first).enabled, isFalse);
      expect(find.text('Saved on this device · not shared'), findsNothing);
    }
    expect(native.writes, hasLength(2)); held.complete(); await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink()); await tester.pumpWidget(host());
    await tapText('Device details'); await tapText('Prepare device details');
    expect(tester.widget<TextField>(find.byType(TextField).first).controller!.text, 'HOST-COMPLETE');
    expect((await store.read(key))!.rows.single.serial, 'HOST-COMPLETE'); expect(native.writes, hasLength(3));
    expect(source.rows, isEmpty); expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
  });
  }

  testWidgets('PF08 DEVICE foreign draft is never displayed or overwritten', (tester) async {
    final wire = Transport()..data = purchaseResponse(role: 'seller'), source = DeviceSourceFixture(), drafts = DeviceDraftFixture();
    final gateway = projectionGateway(wire, account: 'owner-1', purchasedUnitSource: source);
    final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: 'seller')['references'][0]);
    final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference))!.lines.single;
    drafts.saved = WorkspacePurchasedUnitDraft(key: WorkspacePurchasedUnitDraftKey(account: 'outside-owner', realm: 'evaluation',
      store: 'outside-store', binding: 'b' * 64), revision: 1, publishedRevision: 0,
      rows: const [WorkspacePurchasedUnitRow(id: 'foreign-row', serial: 'HOST-PRIVATE-OUTSIDE')]);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspacePurchasedUnitsForLine(
      gateway: gateway, role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference, line: line, draftStore: drafts)))));
    await tester.tap(find.text('Device details')); await tester.pumpAndSettle();
    await tester.tap(find.text('Prepare device details')); await tester.pumpAndSettle();
    expect(find.textContaining('HOST-PRIVATE-OUTSIDE'), findsNothing); expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Recover private draft'), findsOneWidget); expect(drafts.writes, isEmpty);
    expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
  });

  testWidgets('PF08 DEVICE partial empty source does not claim confirmed absence', (tester) async {
    final wire = Transport()..data = purchaseResponse(), source = DeviceSourceFixture(accountUserId: 'buyer-1')..complete = false;
    final gateway = projectionGateway(wire, purchasedUnitSource: source);
    final reference = WorkspacePurchaseReference.fromJson(referenceResponse()['references'][0]);
    final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference))!.lines.single;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspacePurchasedUnitsForLine(
      gateway: gateway, role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference, line: line)))));
    await tester.tap(find.text('Device details')); await tester.pumpAndSettle();
    expect(find.text('No device identifiers were returned in this partial view.'), findsOneWidget);
    expect(find.text('No device identifiers were supplied for this purchase.'), findsNothing);
    expect(find.text('Prepare device details'), findsNothing); expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
  });

  for (final scale in [1.0, 2.0]) {
  for (final outcome in ['applied', 'closed', 'pending', 'wrong-proof', 'lost-response', 'cleanup-failure']) {
  testWidgets('PF08 SHARE owner review writeahead and $outcome recovery scale=$scale', (tester) async {
    tester.view.physicalSize = const Size(360, 800); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final wire = Transport()..data = purchaseResponse(role: 'seller'), source = DevicePublisherFixture(), drafts = DeviceDraftFixture();
    final gateway = projectionGateway(wire, account: 'owner-1', purchasedUnitSource: source);
    final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: 'seller')['references'][0]);
    final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference))!.lines.single;
    final original = jsonEncode(line.toJson());
    source.onShare = (target, command) async {
      expect(drafts.saved!.pending!.toJson(), command.toJson(), reason: 'Original intent must be durable before source dispatch.');
      expect(command.rows.single.serial, 'HOST-PRIVATE-DEVICE');
      if (outcome == 'applied') return source.apply(target, command);
      if (outcome == 'closed') return source.reply(target, command, WorkspacePurchasedUnitPublishState.closed);
      if (outcome == 'lost-response') { await source.apply(target, command); return null; }
      if (outcome == 'cleanup-failure') { final reply = await source.apply(target, command); drafts.failNextSave = true; return reply; }
      return source.reply(target, command, WorkspacePurchasedUnitPublishState.pending, operationId: outcome == 'wrong-proof' ? 'f' * 32 : null);
    };
    Widget host() => MaterialApp(home: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: SingleChildScrollView(child: WorkspacePurchasedUnitsForLine(
      gateway: gateway, role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference, line: line, draftStore: drafts)))));
    Future<void> tapText(String label) async {
      await tester.ensureVisible(find.text(label)); await tester.pumpAndSettle();
      await tester.tap(find.text(label)); await tester.pumpAndSettle();
    }
    await tester.pumpWidget(host()); await tapText('Device details'); await tapText('Prepare device details'); await tapText('Add device');
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Review and share device details')).onPressed, isNull);
    await tester.enterText(find.byType(TextFormField).first, 'HOST-PRIVATE-DEVICE');
    FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
    await tapText('Review and share device details');
    expect(find.text('Serial: HOST-PRIVATE-DEVICE'), findsOneWidget); expect(source.shares, isEmpty); expect(drafts.saved!.pending, isNull);
    await tapText('Back to editing'); expect(source.shares, isEmpty);
    await tapText('Review and share device details'); await tapText('Share device details');
    expect(source.shares, hasLength(1));
    if (outcome == 'applied' || outcome == 'closed') {
      expect(drafts.saved!.pending, isNull);
      expect(find.text(outcome == 'applied' ? 'Device details shared with the buyer.' : 'Not shared. Your private draft is kept.'), findsOneWidget);
      expect(source.rows, outcome == 'applied' ? hasLength(1) : isEmpty);
    } else {
      final pending = drafts.saved!.pending!; expect(find.text('Device details shared with the buyer.'), findsNothing);
      expect(tester.widget<TextFormField>(find.byType(TextFormField).first).enabled, isFalse);
      await tester.pumpWidget(const SizedBox.shrink()); await tester.pumpWidget(host());
      await tapText('Device details'); await tapText('Prepare device details');
      expect(drafts.saved!.pending!.toJson(), pending.toJson()); expect(source.shares, hasLength(1)); expect(source.checks, isEmpty);
      await tapText('Check sharing status');
      expect(source.checks.single.toJson(), pending.toJson()); expect(source.shares, hasLength(1));
      expect(drafts.saved!.pending, isNull); expect(find.text('Device details shared with the buyer.'), findsOneWidget);
    }
    expect(jsonEncode(line.toJson()), original); expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
  });
  }
  }

  testWidgets('PF08 SHARE delayed encrypted journal save cannot dispatch after UI deadline or exit', (tester) async {
    final wire = Transport()..data = purchaseResponse(role: 'seller'), source = DevicePublisherFixture(), native = DeviceNativeStorageFixture();
    final gateway = projectionGateway(wire, account: 'owner-1', purchasedUnitSource: source);
    final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: 'seller')['references'][0]);
    final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference))!.lines.single;
    final target = WorkspacePurchasedLineTarget(accountUserId: 'owner-1', role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference, line: line);
    final key = WorkspacePurchasedUnitDraftKey(account: 'owner-1', realm: 'evaluation', store: reference.storeId, binding: target.binding);
    final store = SecureWorkPurchasedUnitDraftStore(accountScope: () => 'owner-1', targetScope: () => key.identity, storage: native);
    source.onCheck = (target, command) => source.reply(target, command, WorkspacePurchasedUnitPublishState.closed);
    Widget host() => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspacePurchasedUnitsForLine(
      gateway: gateway, role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference, line: line, draftStore: store))));
    Future<void> tapText(String label) async {
      await tester.ensureVisible(find.text(label)); await tester.pumpAndSettle();
      await tester.tap(find.text(label)); await tester.pumpAndSettle();
    }
    await tester.pumpWidget(host()); await tapText('Device details'); await tapText('Prepare device details'); await tapText('Add device');
    await tester.enterText(find.byType(TextFormField).first, 'HOST-DEVICE');
    FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
    await tapText('Review and share device details');
    final held = Completer<void>(); native.holdNextWrite = held;
    await tapText('Share device details'); expect(source.shares, isEmpty);
    await tester.pump(const Duration(seconds: 11)); await tester.pumpAndSettle();
    expect(source.shares, isEmpty); expect(find.text('Device details shared with the buyer.'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink()); held.complete(); await tester.pumpAndSettle();
    expect(source.shares, isEmpty); final pending = (await store.read(key))!.pending!;
    await tester.pumpWidget(host()); await tapText('Device details'); await tapText('Prepare device details');
    await tapText('Check sharing status'); expect(source.checks.single.toJson(), pending.toJson());
    expect(source.shares, isEmpty); expect((await store.read(key))!.pending, isNull);
    expect(find.text('Not shared. Your private draft is kept.'), findsOneWidget);
    expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
  });

  testWidgets('PF08 SHARE preflight timeout or retirement cannot dispatch later', (tester) async {
    final wire = Transport()..data = purchaseResponse(role: 'seller'), source = DevicePublisherFixture();
    final gateway = projectionGateway(wire, account: 'owner-1', purchasedUnitSource: source);
    final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: 'seller')['references'][0]);
    final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference))!.lines.single;
    final target = WorkspacePurchasedLineTarget(accountUserId: 'owner-1', role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference, line: line);
    final command = WorkspacePurchasedUnitPublishCommand(key: WorkspacePurchasedUnitDraftKey(account: 'owner-1', realm: 'evaluation', store: reference.storeId,
      binding: target.binding), operationId: 'a' * 32, expectedRevision: 0, rows: const [WorkspacePurchasedUnitRow(id: 'unit-A', serial: 'HOST-DEVICE')]);
    for (final timeout in [true, false]) {
      final held = Completer<void>(); source.beforeRead = () => held.future; var current = true;
      final sending = gateway.publishPurchasedUnits(command: command, realm: 'evaluation', reference: reference, line: line,
        reconcile: false, inputCurrent: () => current);
      await tester.pump();
      if (timeout) { await tester.pump(const Duration(seconds: 16)); expect(await sending, isNull); }
      else { current = false; }
      held.complete(); await tester.pumpAndSettle(); if (!timeout) expect(await sending, isNull);
      expect(source.shares, isEmpty); expect(source.checks, isEmpty);
    }
    source.dispose();
  });

  test('PF08 SHARE rejects contradictory operation proofs and insufficient current owner authority', () async {
    final wire = Transport()..data = purchaseResponse(role: 'seller'), source = DevicePublisherFixture();
    final gateway = projectionGateway(wire, account: 'owner-1', purchasedUnitSource: source);
    final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: 'seller')['references'][0]);
    final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference))!.lines.single;
    final target = WorkspacePurchasedLineTarget(accountUserId: 'owner-1', role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference, line: line);
    final key = WorkspacePurchasedUnitDraftKey(account: 'owner-1', realm: 'evaluation', store: reference.storeId, binding: target.binding);
    final command = WorkspacePurchasedUnitPublishCommand(key: key, operationId: 'a' * 32, expectedRevision: 0,
      rows: const [WorkspacePurchasedUnitRow(id: 'unit-A', serial: 'HOST-DEVICE')]);
    WorkspacePurchasedUnitsRead record({int revision = 1, bool complete = true, List<WorkspacePurchasedUnitRow>? rows}) =>
      WorkspacePurchasedUnitsRead(target: target, revision: revision, complete: complete, rows: rows ?? command.rows, observedAt: DateTime.utc(2026, 10, 21));
    for (final invalid in [null, record(revision: 2), record(complete: false), record(rows: const []),
      record(rows: const [WorkspacePurchasedUnitRow(id: 'unit-A', serial: 'OTHER')])]) {
      expect(source.reply(target, command, WorkspacePurchasedUnitPublishState.applied, record: invalid).validFor(command, target), isFalse);
    }
    expect(source.reply(target, command, WorkspacePurchasedUnitPublishState.applied, record: record()).validFor(command, target), isTrue);
    for (final state in [WorkspacePurchasedUnitPublishState.closed, WorkspacePurchasedUnitPublishState.pending]) {
      expect(source.reply(target, command, state, record: record()).validFor(command, target), isFalse);
    }
    for (final denial in ['no-owner', 'expired', 'partial', 'changed-revision', 'wrong-key']) {
      source.owner = denial != 'no-owner'; source.complete = denial != 'partial'; source.revision = denial == 'changed-revision' ? 1 : 0;
      source.expiresAt = DateTime.now().toUtc().add(Duration(minutes: denial == 'expired' ? -1 : 5));
      final sent = denial == 'wrong-key' ? WorkspacePurchasedUnitPublishCommand(key: WorkspacePurchasedUnitDraftKey(account: 'owner-1', realm: 'production',
        store: reference.storeId, binding: key.binding), operationId: command.operationId, expectedRevision: 0, rows: command.rows) : command;
      expect(await gateway.publishPurchasedUnits(command: sent, realm: 'evaluation', reference: reference, line: line, reconcile: false), isNull);
      expect(source.shares, isEmpty); expect(source.checks, isEmpty);
    }
    source.dispose();
  });

  testWidgets('PF08 SHARE checking another panel request keeps unsaved conflicting edits for explicit review', (tester) async {
    final wire = Transport()..data = purchaseResponse(role: 'seller'), source = DevicePublisherFixture(), drafts = DeviceDraftFixture();
    final gateway = projectionGateway(wire, account: 'owner-1', purchasedUnitSource: source);
    final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: 'seller')['references'][0]);
    final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference))!.lines.single;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspacePurchasedUnitsForLine(
      gateway: gateway, role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference, line: line, draftStore: drafts)))));
    Future<void> tapText(String label) async {
      await tester.ensureVisible(find.text(label)); await tester.pumpAndSettle();
      await tester.tap(find.text(label)); await tester.pumpAndSettle();
    }
    await tapText('Device details'); await tapText('Prepare device details'); await tapText('Add device');
    await tester.enterText(find.byType(TextFormField).first, 'HOST-FIRST');
    FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
    drafts.failNextSave = true;
    await tester.enterText(find.byType(TextFormField).first, 'HOST-KEPT-CONFLICT');
    FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
    final saved = drafts.saved!, command = WorkspacePurchasedUnitPublishCommand(key: drafts.saved!.key, operationId: 'b' * 32, expectedRevision: 0,
      rows: const [WorkspacePurchasedUnitRow(id: 'other-panel-unit', serial: 'HOST-OTHER-PANEL')]);
    // Isolated same-owner second-panel journal, not runtime storage injection.
    drafts.saved = WorkspacePurchasedUnitDraft(key: saved.key, revision: saved.revision + 1, publishedRevision: 0, rows: command.rows, pending: command);
    await tapText('Recover private draft'); await tapText('Check sharing status');
    expect(source.checks.single.toJson(), command.toJson()); expect(source.shares, isEmpty);
    expect(find.text('Your kept edits'), findsOneWidget); expect(find.text('Serial: HOST-KEPT-CONFLICT'), findsOneWidget);
    expect(find.text('Serial: HOST-OTHER-PANEL'), findsNWidgets(2), reason: 'Published supplier row and saved private comparison are separate.');
    await tapText('Save kept edits'); expect(drafts.saved!.rows.single.serial, 'HOST-KEPT-CONFLICT');
    expect(drafts.saved!.pending, isNull); expect(drafts.saved!.publishedRevision, 0);
    await tapText('Keep this draft against updated records'); expect(drafts.saved!.publishedRevision, 1);
    expect(source.rows.single.serial, 'HOST-OTHER-PANEL'); expect(source.shares, isEmpty);
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Review and share device details')).onPressed, isNotNull);
    expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
  });

  for (final scale in [1.0, 2.0]) {
  testWidgets('PF08 REPORT buyer saves reviews sends and restores recorded receipt without supplier edits scale=$scale', (tester) async {
    tester.view.physicalSize = const Size(360, 800); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    FlutterSecureStorage.setMockInitialValues({});
    final wire = Transport()..data = purchaseResponse(), source = DeviceReporterFixture();
    final gateway = projectionGateway(wire, purchasedUnitSource: source);
    final reference = WorkspacePurchaseReference.fromJson(referenceResponse()['references'][0]);
    final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference))!.lines.single;
    final supplier = jsonEncode(source.rows.map((r) => r.toJson()).toList()), original = jsonEncode(line.toJson());
    source.onReport = (target, command) async {
      final saved = WorkspacePurchasedUnitDraft.fromJson(jsonDecode((await const FlutterSecureStorage().readAll()).values.single));
      expect(saved.report!.pending!.toJson(), command.toJson());
      expect(command.rows.single.toJson(), source.rows.single.toJson()); expect(command.note, 'HOST different device received');
      return source.reply(target, command);
    };
    Widget host() => MaterialApp(home: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: SingleChildScrollView(child: WorkspacePurchasedUnitsForLine(
      gateway: gateway, role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference, line: line)))));
    Future<void> tapText(String label) async {
      await tester.ensureVisible(find.text(label)); await tester.pumpAndSettle();
      await tester.tap(find.text(label)); await tester.pumpAndSettle();
    }
    await tester.pumpWidget(host()); await tapText('Device details'); await tapText('Report a device mismatch');
    expect(find.text('Add device'), findsNothing); expect(find.byType(TextFormField), findsOneWidget);
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Review device report')).onPressed, isNull);
    await tester.ensureVisible(find.byType(CheckboxListTile)); await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile).hitTestable(), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile)); await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextFormField)); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'HOST different device received  ');
    FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink()); await tester.pumpWidget(host());
    await tapText('Device details'); await tapText('Report a device mismatch');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'HOST different device received  ');
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value, isTrue);
    await tapText('Review device report'); expect(source.reports, isEmpty);
    await tapText('Back to report'); await tapText('Review device report'); await tapText('Send device report');
    expect(source.reports, hasLength(1)); expect(source.checks, isEmpty);
    expect(find.text('Report reference: HOST-REPORT-1'), findsOneWidget); expect(find.text('Send device report'), findsNothing);
    final saved = WorkspacePurchasedUnitDraft.fromJson(jsonDecode((await const FlutterSecureStorage().readAll()).values.single));
    expect(saved.toJson()['version'], 3); expect(saved.report!.recorded, isTrue); expect(saved.report!.pending!.toJson(), source.reports.single.toJson());
    await tester.pumpWidget(const SizedBox.shrink()); await tester.pumpWidget(host());
    await tapText('Device details'); await tapText('Report a device mismatch');
    expect(find.text('Report reference: HOST-REPORT-1'), findsOneWidget); expect(find.byType(TextFormField), findsNothing);
    expect(source.reports, hasLength(1)); expect(source.checks, isEmpty);
    expect(jsonEncode(source.rows.map((r) => r.toJson()).toList()), supplier); expect(jsonEncode(line.toJson()), original);
    expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
  });
  }

  for (final outcome in ['pending', 'closed', 'wrong-proof', 'lost-response', 'cleanup-failure']) {
  testWidgets('PF08 REPORT $outcome keeps original intent and checks after restart', (tester) async {
    final wire = Transport()..data = purchaseResponse(), source = DeviceReporterFixture(), drafts = DeviceDraftFixture();
    final gateway = projectionGateway(wire, purchasedUnitSource: source);
    final reference = WorkspacePurchaseReference.fromJson(referenceResponse()['references'][0]);
    final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference))!.lines.single;
    final supplier = jsonEncode(source.rows.map((r) => r.toJson()).toList());
    source.onReport = (target, command) {
      expect(drafts.saved!.report!.pending!.toJson(), command.toJson());
      if (outcome == 'lost-response') return null;
      if (outcome == 'cleanup-failure') { drafts.failNextSave = true; return source.reply(target, command); }
      return source.reply(target, command, state: outcome == 'closed' ? WorkspacePurchasedUnitPublishState.closed : WorkspacePurchasedUnitPublishState.pending,
        operationId: outcome == 'wrong-proof' ? 'f' * 32 : null);
    };
    Widget host() => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspacePurchasedUnitsForLine(
      gateway: gateway, role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference, line: line, draftStore: drafts))));
    Future<void> tapText(String label) async {
      await tester.ensureVisible(find.text(label)); await tester.pumpAndSettle();
      await tester.tap(find.text(label)); await tester.pumpAndSettle();
    }
    await tester.pumpWidget(host()); await tapText('Device details'); await tapText('Report a device mismatch');
    await tester.tap(find.byType(CheckboxListTile)); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'HOST incorrect identifier'); FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
    await tapText('Review device report'); await tapText('Send device report');
    expect(source.reports, hasLength(1));
    if (outcome == 'closed') {
      expect(drafts.saved!.report!.pending, isNull); expect(drafts.saved!.report!.recorded, isFalse);
      expect(find.text('Report not sent. Your private draft is kept.'), findsOneWidget);
    } else {
      final original = drafts.saved!.report!.pending!;
      expect(find.text('Report reference: HOST-REPORT-1'), findsNothing); expect(find.byType(TextFormField), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink()); await tester.pumpWidget(host());
      await tapText('Device details'); await tapText('Report a device mismatch');
      expect(drafts.saved!.report!.pending!.toJson(), original.toJson()); expect(source.reports, hasLength(1));
      await tapText('Check report status'); expect(source.checks.single.toJson(), original.toJson());
      expect(drafts.saved!.report!.recorded, isTrue); expect(find.text('Report reference: HOST-REPORT-1'), findsOneWidget);
      expect(source.reports, hasLength(1));
    }
    expect(jsonEncode(source.rows.map((r) => r.toJson()).toList()), supplier);
    expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
  });
  }

  for (final mode in ['no-lease', 'expired', 'partial', 'supplier']) {
  testWidgets('PF08 REPORT $mode cannot open buyer private report or mutate identifiers', (tester) async {
    FlutterSecureStorage.setMockInitialValues({'HOST-private-other-account': 'KEEP'});
    final role = mode == 'supplier' ? WorkspaceOrderIdentityRole.seller : WorkspaceOrderIdentityRole.buyer;
    final account = role == WorkspaceOrderIdentityRole.seller ? 'owner-1' : 'buyer-1';
    final wire = Transport()..data = purchaseResponse(role: role.name), source = DeviceReporterFixture(accountUserId: account)
      ..permit = mode != 'no-lease' ..complete = mode != 'partial';
    if (mode == 'expired') source.expiresAt = DateTime.now().toUtc().subtract(const Duration(seconds: 1));
    final gateway = projectionGateway(wire, account: account, purchasedUnitSource: source);
    final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: role.name)['references'][0]);
    final line = (await gateway.readReferencedOrder(role: role, realm: 'evaluation', reference: reference))!.lines.single;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspacePurchasedUnitsForLine(
      gateway: gateway, role: role, realm: 'evaluation', reference: reference, line: line)))));
    await tester.tap(find.text('Device details')); await tester.pumpAndSettle();
    expect(find.text('Report a device mismatch'), findsNothing); expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Serial: HOST-SUPPLIER-SERIAL'), findsOneWidget); expect(source.reports, isEmpty); expect(source.checks, isEmpty);
    expect(await const FlutterSecureStorage().readAll(), {'HOST-private-other-account': 'KEEP'});
    expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
  });
  }

  testWidgets('PF08 REPORT native save keeps latest coalesced note after deadline and disposal', (tester) async {
    final wire = Transport()..data = purchaseResponse(), source = DeviceReporterFixture(), native = DeviceNativeStorageFixture();
    final gateway = projectionGateway(wire, purchasedUnitSource: source);
    final reference = WorkspacePurchaseReference.fromJson(referenceResponse()['references'][0]);
    final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference))!.lines.single;
    final target = WorkspacePurchasedLineTarget(accountUserId: 'buyer-1', role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference, line: line);
    final key = WorkspacePurchasedUnitDraftKey(account: 'buyer-1', realm: 'evaluation', store: reference.storeId, binding: target.binding);
    final store = SecureWorkPurchasedUnitDraftStore(accountScope: () => 'buyer-1', targetScope: () => key.identity, storage: native);
    Widget host() => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspacePurchasedUnitsForLine(
      gateway: gateway, role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference, line: line, draftStore: store))));
    Future<void> tapText(String label) async {
      await tester.ensureVisible(find.text(label)); await tester.pumpAndSettle();
      await tester.tap(find.text(label)); await tester.pumpAndSettle();
    }
    await tester.pumpWidget(host()); await tapText('Device details'); await tapText('Report a device mismatch');
    await tester.tap(find.byType(CheckboxListTile)); await tester.pumpAndSettle();
    final held = Completer<void>(); native.holdNextWrite = held;
    await tester.enterText(find.byType(TextFormField), 'H'); await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'HOST complete report note'); FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink()); await tester.pump(const Duration(seconds: 11));
    held.complete(); await tester.pumpAndSettle();
    expect((await store.read(key))!.report!.note, 'HOST complete report note');
    await tester.pumpWidget(host()); await tapText('Device details'); await tapText('Report a device mismatch');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'HOST complete report note');
    expect(source.reports, isEmpty); expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
  });

  for (final owner in [true, false]) {
  testWidgets('PF08 REPORT original ${owner ? 'owner' : 'buyer'} lease retires held preflight through revoke regrant', (tester) async {
    final role = owner ? WorkspaceOrderIdentityRole.seller : WorkspaceOrderIdentityRole.buyer, account = owner ? 'owner-1' : 'buyer-1';
    final wire = Transport()..data = purchaseResponse(role: role.name);
    final DeviceSourceFixture source = owner ? DevicePublisherFixture() : DeviceReporterFixture();
    final drafts = DeviceDraftFixture(), gateway = projectionGateway(wire, account: account, purchasedUnitSource: source);
    final reference = WorkspacePurchaseReference.fromJson(referenceResponse(role: role.name)['references'][0]);
    final line = (await gateway.readReferencedOrder(role: role, realm: 'evaluation', reference: reference))!.lines.single;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspacePurchasedUnitsForLine(
      gateway: gateway, role: role, realm: 'evaluation', reference: reference, line: line, draftStore: drafts)))));
    Future<void> tapText(String label) async {
      await tester.ensureVisible(find.text(label)); await tester.pumpAndSettle();
      await tester.tap(find.text(label)); await tester.pumpAndSettle();
    }
    await tapText('Device details'); await tapText(owner ? 'Prepare device details' : 'Report a device mismatch');
    if (owner) { await tapText('Add device'); } else { await tester.tap(find.byType(CheckboxListTile)); await tester.pumpAndSettle(); }
    final field = find.byType(TextFormField).first; await tester.ensureVisible(field); await tester.pumpAndSettle();
    await tester.enterText(field, 'HOST unchanged intent'); FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
    await tapText(owner ? 'Review and share device details' : 'Review device report');
    final held = Completer<void>(), entered = Completer<void>();
    Future<void> beforeRead() { if (!entered.isCompleted) entered.complete(); return held.future; }
    if (source case DevicePublisherFixture publisher) {
      publisher.beforeRead = beforeRead; publisher.onCheck = (target, command) => publisher.reply(target, command, WorkspacePurchasedUnitPublishState.closed);
    } else if (source case DeviceReporterFixture reporter) {
      reporter.beforeRead = beforeRead; reporter.onCheck = (target, command) => reporter.reply(target, command, state: WorkspacePurchasedUnitPublishState.closed);
    }
    final button = find.widgetWithText(FilledButton, owner ? 'Share device details' : 'Send device report');
    await tester.ensureVisible(button); await tester.pumpAndSettle(); final oldSend = tester.widget<FilledButton>(button).onPressed!;
    await tester.tap(button); await tester.pump(); expect(entered.isCompleted, isTrue);
    if (source case DeviceReporterFixture reporter) { reporter.revokeReporting(); } else { source.revokeOwner(); }
    await tester.pump();
    if (source case DeviceReporterFixture reporter) { reporter.restoreReporting(); reporter.beforeRead = null; }
    else if (source case DevicePublisherFixture publisher) { publisher.restoreOwner(); publisher.beforeRead = null; }
    held.complete(); await tester.pumpAndSettle();
    if (source case DevicePublisherFixture publisher) { expect(publisher.shares, isEmpty); expect(drafts.saved!.pending, isNotNull); }
    else if (source case DeviceReporterFixture reporter) { expect(reporter.reports, isEmpty); expect(drafts.saved!.report!.pending, isNotNull); }
    await tapText(owner ? 'Check sharing status' : 'Check report status'); oldSend(); await tester.pumpAndSettle();
    if (source case DevicePublisherFixture publisher) { expect(publisher.shares, isEmpty); expect(publisher.checks, hasLength(1)); }
    else if (source case DeviceReporterFixture reporter) { expect(reporter.reports, isEmpty); expect(reporter.checks, hasLength(1)); }
    expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
  });
  }

  testWidgets('PF08 REPORT Store purchase selector and delayed source cannot escape exact original binding', (tester) async {
    final data = purchaserPurchaseResponse(), wire = Transport()..data = purchaserPurchaseResponse(), source = DeviceReporterFixture();
    final gateway = projectionGateway(wire, purchasedUnitSource: source);
    final rawReference = Map<String, dynamic>.from(referenceResponse()['references'][0]); rawReference['originalFingerprint'] = data['orders'][0]['originalFingerprint'];
    final reference = WorkspacePurchaseReference.fromJson(rawReference);
    final original = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference, buyingStoreId: 'buying-store'))!;
    final target = WorkspacePurchasedLineTarget(accountUserId: 'buyer-1', role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation',
      reference: reference, line: original.lines.single, buyingStoreId: 'buying-store');
    final read = (await source.read(target))!, command = WorkspacePurchasedUnitMismatchCommand(key: WorkspacePurchasedUnitDraftKey(account: 'buyer-1',
      realm: 'evaluation', store: reference.storeId, binding: target.binding), operationId: 'a' * 32, sourceRevision: read.revision,
      sourceFingerprint: read.fingerprint, note: 'HOST observed mismatch', rows: read.rows);
    expect(await gateway.reportPurchasedUnitMismatch(command: command, realm: 'evaluation', reference: reference, line: original.lines.single,
      buyingStoreId: 'other-store', reconcile: false), isNull); expect(source.reports, isEmpty);
    final held = Completer<void>(); source.beforeRead = () => held.future;
    final pending = gateway.reportPurchasedUnitMismatch(command: command, realm: 'evaluation', reference: reference, line: original.lines.single,
      buyingStoreId: 'buying-store', reconcile: false);
    await tester.pump(); await tester.pump(const Duration(seconds: 16)); expect(await pending, isNull);
    held.complete(); await tester.pumpAndSettle(); expect(source.reports, isEmpty);
    source.beforeRead = null;
    final receipt = await gateway.reportPurchasedUnitMismatch(command: command, realm: 'evaluation', reference: reference, line: original.lines.single,
      buyingStoreId: 'buying-store', reconcile: false);
    expect(receipt!.reportId, 'HOST-REPORT-1'); expect(source.reports.single.toJson(), command.toJson());
    expect(wire.requests.last['buyingStoreId'], 'buying-store');
    source.dispose();
  });

  testWidgets('PF08 REPORT changed supplier records retire review and require explicit fresh selection', (tester) async {
    final wire = Transport()..data = purchaseResponse(), source = DeviceReporterFixture(), drafts = DeviceDraftFixture();
    final gateway = projectionGateway(wire, purchasedUnitSource: source);
    final reference = WorkspacePurchaseReference.fromJson(referenceResponse()['references'][0]);
    final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference))!.lines.single;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspacePurchasedUnitsForLine(
      gateway: gateway, role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference, line: line, draftStore: drafts)))));
    Future<void> tapText(String label) async {
      await tester.ensureVisible(find.text(label)); await tester.pumpAndSettle();
      await tester.tap(find.text(label)); await tester.pumpAndSettle();
    }
    await tapText('Device details'); await tapText('Report a device mismatch');
    await tester.tap(find.byType(CheckboxListTile)); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'HOST mismatch observation');
    FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle(); await tapText('Review device report');
    final oldSend = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Send device report')).onPressed!;
    source.updateDevices(const [WorkspacePurchasedUnitRow(id: 'supplier-device-A', serial: 'HOST-UPDATED-RECORD')]); await tester.pumpAndSettle();
    expect(find.text('Send device report'), findsNothing); oldSend(); await tester.pumpAndSettle(); expect(source.reports, isEmpty);
    expect(drafts.saved!.publishedRevision, 1); await tapText('Review latest supplier records');
    expect(drafts.saved!.publishedRevision, 2); expect(drafts.saved!.report!.selected, isEmpty);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'HOST mismatch observation');
    await tester.ensureVisible(find.byType(CheckboxListTile)); await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile)); await tester.pumpAndSettle();
    await tapText('Review device report'); await tapText('Send device report');
    expect(source.reports.single.sourceRevision, 2); expect(source.reports.single.rows.single.serial, 'HOST-UPDATED-RECORD');
    expect(source.rows.single.serial, 'HOST-UPDATED-RECORD'); expect(drafts.saved!.report!.recorded, isTrue);
    expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
  });

  testWidgets('PF08 REPORT saved purchase consumer restores and checks its genuine report intent', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final data = purchaseResponse(), refs = referenceResponse(), source = DeviceReporterFixture();
    final wire = Transport()..respond = (body) => switch (body['operation']) {
      'listBuyerPurchaseReferences' => refs, 'readBuyerPurchaseProjection' => data,
      _ => throw StateError('HOST no device report HTTP operation'),
    };
    source.onReport = (target, command) => source.reply(target, command, state: WorkspacePurchasedUnitPublishState.pending);
    final gateway = projectionGateway(wire, purchasedUnitSource: source);
    Widget host() => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspacePurchaseOriginals(
      gateway: gateway, role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation'))));
    Future<void> tapText(String label) async {
      await tester.ensureVisible(find.text(label)); await tester.pumpAndSettle();
      await tester.tap(find.text(label)); await tester.pumpAndSettle();
    }
    Future<void> open() async {
      await tapText('Saved purchase details');
      await tester.tap(find.byKey(const ValueKey('original-order-order-v2'))); await tester.pumpAndSettle();
      await tapText('Device details'); await tapText('Report a device mismatch');
    }
    await tester.pumpWidget(host()); await open();
    await tester.ensureVisible(find.byType(CheckboxListTile)); await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile)); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'HOST different physical device');
    FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
    await tapText('Review device report'); await tapText('Send device report');
    final command = source.reports.single;
    await tester.pumpWidget(const SizedBox.shrink()); await tester.pumpWidget(host()); await open();
    expect(source.reports, hasLength(1)); await tapText('Check report status');
    expect(source.checks.single.toJson(), command.toJson()); expect(source.reports, hasLength(1));
    expect(find.text('Report reference: HOST-REPORT-1'), findsOneWidget);
    expect(wire.requests.every((r) => ['listBuyerPurchaseReferences', 'readBuyerPurchaseProjection'].contains(r['operation'])), isTrue);
    expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink()); source.dispose();
  });

  testWidgets('PF07 WARRANTY original line opens unavailable details without a service', (tester) async {
    final data = purchaseResponse(), refs = referenceResponse(), order = data['orders'][0];
    final wire = Transport()..respond = (body) => switch (body['operation']) {
      'listBuyerPurchaseReferences' => refs,
      'readBuyerPurchaseProjection' => data,
      _ => throw StateError('No warranty/payment/operational service in this isolated fixture'),
    };
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspacePurchaseOriginals(
      gateway: projectionGateway(wire), role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation')))));
    await tester.tap(find.text('Saved purchase details')); await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('original-order-${order['orderId']}'))); await tester.pumpAndSettle();
    final warranty = find.text('Warranty details');
    expect(warranty, findsOneWidget);
    await tester.ensureVisible(warranty); await tester.tap(warranty); await tester.pumpAndSettle();
    expect(find.text('Warranty details for this purchase are unavailable.'), findsOneWidget);
    expect(wire.requests, hasLength(2), reason: 'An unconfigured supplement must not dispatch an invented backend operation.');
  });

  for (final fault in ['none', 'no-record', 'wrong-account', 'wrong-role', 'wrong-realm', 'wrong-buying-store',
    'wrong-original', 'wrong-revision', 'wrong-line', 'wrong-sku', 'empty', 'unsupported', 'whitespace', 'control', 'too-long', 'zero-revision']) {
    test('PF07 WARRANTY scoped supplement $fault', () async {
      final data = purchaseResponse(), wire = Transport()..data = data, reader = WarrantyReaderFixture();
      final gateway = projectionGateway(wire, purchasedWarrantyReader: reader), reference = operationalReference();
      final original = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference))!;
      final line = original.lines.single, before = jsonEncode(line.toJson());
      reader.respond = (target) {
        final changedReference = WorkspacePurchaseReference.fromJson({...target.reference.toJson(),
          if (fault == 'wrong-original') 'originalFingerprint': 'f' * 64,
          if (fault == 'wrong-revision') 'sourceRevision': 'another-source-revision'});
        final resultTarget = WorkspacePurchasedWarrantyTarget(
          accountUserId: fault == 'wrong-account' ? 'other-viewer' : target.accountUserId,
          role: fault == 'wrong-role' ? WorkspaceOrderIdentityRole.seller : target.role,
          realm: fault == 'wrong-realm' ? 'production' : target.realm,
          buyingStoreId: fault == 'wrong-buying-store' ? 'other-buying-store' : target.buyingStoreId,
          reference: changedReference, line: warrantyLine(target.lineFacts,
            lineId: fault == 'wrong-line' ? 'other-line' : null, skuId: fault == 'wrong-sku' ? 'other-sku' : null));
        return warrantyRead(resultTarget, revision: fault == 'zero-revision' ? 0 : 1, noRecord: fault == 'no-record',
          fields: switch (fault) {
            'empty' => const {}, 'unsupported' => const {'eligibility': 'approved'}, 'whitespace' => const {'issuer': ' '},
            'control' => const {'issuer': 'bad\u0000value'}, 'too-long' => {'issuer': 'x' * 2001},
            _ => const {'issuer': 'HOST original issuer', 'duration': '12 months', 'startBasis': 'From issuer activation'},
          });
      };
      final result = await gateway.readPurchasedWarranty(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference, line: line);
      expect(result != null, ['none', 'no-record'].contains(fault));
      if (fault == 'none') {
        expect(result!.terms!.fields['startBasis'], 'From issuer activation'); expect(result.terms!.startedAt, isNull);
        final copy = result.target.lineFacts..['name'] = 'Changed outside target';
        expect(copy['name'], 'Changed outside target'); expect(result.target.lineFacts['name'], line.name);
        expect(() => result.terms!.fields['issuer'] = 'changed', throwsUnsupportedError);
      }
      if (fault == 'no-record') expect(result!.terms, isNull);
      expect(jsonEncode(line.toJson()), before); expect(reader.requests, hasLength(1));
      expect(wire.requests.every((request) => request['operation'] == 'readBuyerPurchaseProjection'), isTrue);
    });
  }
  for (final fault in ['caller-retired', 'identity-retired', 'reader-retired', 'reader-lifetime-ABA']) {
    test('PF07 WARRANTY $fault while original read is held prevents supplement dispatch', () async {
      final wire = Transport()..data = purchaseResponse(), reader = WarrantyReaderFixture();
      Object? identityLifetime = Object(); var active = true;
      final gateway = projectionGateway(wire, lifetime: () => identityLifetime, purchasedWarrantyReader: reader), reference = operationalReference();
      final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference))!.lines.single;
      final entered = Completer<void>(), release = Completer<void>();
      wire.beforePost = (_) { entered.complete(); return release.future; };
      final reading = gateway.readPurchasedWarranty(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation',
        reference: reference, line: line, inputCurrent: () => active);
      await entered.future;
      if (fault == 'caller-retired') active = false;
      if (fault == 'identity-retired') identityLifetime = Object();
      if (fault == 'reader-retired') reader.isCurrent = false;
      if (fault == 'reader-lifetime-ABA') reader.lifetime = Object();
      release.complete(); expect(await reading, isNull); expect(reader.requests, isEmpty);
    });
  }
  test('PF07 WARRANTY changed original line cannot request a supplement', () async {
    final wire = Transport()..data = purchaseResponse(), reader = WarrantyReaderFixture();
    final gateway = projectionGateway(wire, purchasedWarrantyReader: reader), reference = operationalReference();
    final original = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference))!;
    final line = warrantyLine(original.lines.single.toJson(), skuId: 'different-sku');
    expect(await gateway.readPurchasedWarranty(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference, line: line), isNull);
    expect(reader.requests, isEmpty);
  });

  test('PF07 WARRANTY collapse while credentials held prevents late original HTTP', () async {
    final data = purchaseResponse(), reference = operationalReference();
    final line = (await projectionGateway(Transport()..data = data).readReferencedOrder(
      role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference))!.lines.single;
    final wire = Transport()..data = data, reader = WarrantyReaderFixture(), credentials = Credentials()..token = Completer<String>();
    var active = true;
    final gateway = AuthenticatedWorkspaceOrderIdentityGateway(endpoint: Uri.parse(
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
      accountUserId: 'buyer-1', lifetime: () => 'host-active', credentials: credentials, transport: wire, purchasedWarrantyReader: reader);
    final reading = gateway.readPurchasedWarranty(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation',
      reference: reference, line: line, inputCurrent: () => active);
    active = false; credentials.token!.complete('host-token');
    expect(await reading, isNull); expect(wire.requests, isEmpty); expect(reader.requests, isEmpty);
  });
  testWidgets('PF07 WARRANTY reader retirement hides retained terms', (tester) async {
    final wire = Transport()..data = purchaseResponse(), reader = WarrantyReaderFixture();
    reader.respond = warrantyRead;
    final gateway = projectionGateway(wire, purchasedWarrantyReader: reader), reference = operationalReference();
    final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference))!.lines.single;
    Widget host() => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspaceOriginalWarrantyForLine(
      gateway: gateway, role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference, line: line))));
    await tester.pumpWidget(host()); await tester.pumpAndSettle();
    await tester.tap(find.text('Warranty details')); await tester.pumpAndSettle();
    expect(find.text('Warranty issuer: HOST original issuer'), findsOneWidget);
    reader.isCurrent = false;
    await tester.pumpWidget(host()); await tester.pumpAndSettle();
    expect(find.text('Warranty issuer: HOST original issuer'), findsNothing);
  });

  testWidgets('PF07 WARRANTY timeout includes held credentials and retires later HTTP', (tester) async {
    final data = purchaseResponse(), reference = operationalReference();
    final line = (await projectionGateway(Transport()..data = data).readReferencedOrder(
      role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference))!.lines.single;
    final wire = Transport()..data = data, reader = WarrantyReaderFixture(), credentials = Credentials()..token = Completer<String>();
    final gateway = AuthenticatedWorkspaceOrderIdentityGateway(endpoint: Uri.parse(
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'), accountUserId: 'buyer-1',
      lifetime: () => 'host-active', credentials: credentials, transport: wire, purchasedWarrantyReader: reader);
    final reading = gateway.readPurchasedWarranty(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference, line: line);
    await tester.pump(const Duration(seconds: 16)); expect(await reading, isNull);
    credentials.token!.complete('host-token'); await tester.pumpAndSettle();
    expect(wire.requests, isEmpty); expect(reader.requests, isEmpty);
  });

  for (final role in WorkspaceOrderIdentityRole.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('PF07 WARRANTY shared original states ${role.name} scale=$scale', (tester) async {
        tester.view.physicalSize = const Size(360, 800); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final data = purchaseResponse(role: role.name), refs = referenceResponse(role: role.name), order = data['orders'][0];
        final wire = Transport()..respond = (body) => switch (body['operation']) {
          'listBuyerPurchaseReferences' || 'listStorePurchaseReferences' => refs,
          'readBuyerPurchaseProjection' || 'readStorePurchaseProjection' => data,
          _ => throw StateError('No business command in isolated warranty fixture'),
        };
        final reader = WarrantyReaderFixture(accountUserId: data['viewerUserId']), pending = Completer<WorkspacePurchasedWarrantyRead?>();
        reader.respond = (_) => pending.future;
        final gateway = projectionGateway(wire, account: data['viewerUserId'], purchasedWarrantyReader: reader);
        Widget host() => MaterialApp(home: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: SingleChildScrollView(child: WorkspacePurchaseOriginals(gateway: gateway, role: role,
            realm: 'evaluation', storeId: role == WorkspaceOrderIdentityRole.seller ? order['storeId'] : null)))));
        await tester.pumpWidget(host()); await tester.pumpAndSettle();
        await tester.tap(find.text('Saved purchase details')); await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('original-order-${order['orderId']}'))); await tester.pumpAndSettle();
        final warranty = find.text('Warranty details'); await tester.ensureVisible(warranty); await tester.pumpAndSettle();
        await tester.tap(warranty); await tester.pump(); await tester.pump(const Duration(milliseconds: 300));
        expect(reader.requests, hasLength(1)); expect(find.byType(LinearProgressIndicator), findsOneWidget);
        pending.complete(warrantyRead(reader.requests.single)); await tester.pumpAndSettle();
        for (final label in ['Warranty issuer: HOST original issuer', 'Warranty duration: 12 months',
          'Warranty start basis: From issuer activation', 'Warranty coverage: Manufacturing defects',
          'Warranty exclusions: Accidental damage', 'Warranty contact: Recorded service desk', 'Warranty reference: HOST-POLICY-A']) {
          final detail = find.text(label); await tester.ensureVisible(detail); await tester.pumpAndSettle();
          expect(detail.hitTestable(), findsOneWidget); expect(tester.takeException(), isNull);
        }
        expect(find.textContaining('Recorded warranty start:'), findsNothing, reason: 'Start basis alone is not an activation date.');
        Future<void> reopen() async {
          await tester.ensureVisible(warranty); await tester.pumpAndSettle(); await tester.tap(warranty); await tester.pumpAndSettle();
          await tester.tap(warranty); await tester.pumpAndSettle();
        }
        reader.respond = (target) => warrantyRead(target, revision: 2, noRecord: true);
        await reopen(); expect(find.text('No detailed warranty terms were supplied for this purchase.'), findsOneWidget);
        expect(find.text('Warranty issuer: HOST original issuer'), findsNothing);
        reader.respond = (_) => throw StateError('HOST unavailable'); await reopen();
        expect(find.text('Warranty details for this purchase are unavailable.'), findsOneWidget);
        expect(find.text('No detailed warranty terms were supplied for this purchase.'), findsNothing);
        final retry = find.text('Retry warranty details'); await tester.ensureVisible(retry); await tester.pumpAndSettle();
        final retryButton = find.ancestor(of: retry, matching: find.byType(TextButton));
        final staleRetry = tester.widget<TextButton>(retryButton).onPressed!;
        reader.respond = (target) => warrantyRead(target, revision: 3);
        await tester.tap(retry); await tester.pumpAndSettle();
        expect(find.text('Warranty issuer: HOST original issuer'), findsOneWidget);
        final count = reader.requests.length; staleRetry(); await tester.pumpAndSettle(); expect(reader.requests.length, count);
        reader.respond = (target) => warrantyRead(target, revision: 2); await reopen();
        expect(find.text('Warranty details for this purchase are unavailable.'), findsOneWidget, reason: 'Older terms cannot replace an observed revision.');
        await tester.pumpWidget(const SizedBox.shrink());
        reader.respond = warrantyRead; await tester.pumpWidget(host()); await tester.pumpAndSettle();
        await tester.tap(find.text('Saved purchase details')); await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('original-order-${order['orderId']}'))); await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Warranty details')); await tester.tap(find.text('Warranty details')); await tester.pumpAndSettle();
        expect(reader.requests.length, count + 2, reason: 'A restarted view rereads rather than loading an old unbound supplement.');
        expect(find.text('Warranty issuer: HOST original issuer'), findsOneWidget);
        expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  for (final retirement in ['collapse', 'collapse-reopen', 'account-ABA', 'realm-ABA', 'buying-store-ABA', 'reader-lifetime', 'dispose']) {
    testWidgets('PF07 WARRANTY late supplement cannot cross $retirement', (tester) async {
      final wire = Transport()..data = purchaseResponse(), reader = WarrantyReaderFixture(), pending = Completer<WorkspacePurchasedWarrantyRead?>();
      final gateway = projectionGateway(wire, purchasedWarrantyReader: reader), reference = operationalReference();
      final line = (await gateway.readReferencedOrder(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference))!.lines.single;
      var owner = gateway, realm = 'evaluation'; String? selector;
      reader.respond = (_) => pending.future;
      Widget host() => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WorkspaceOriginalWarrantyForLine(
        key: const ValueKey('retained-warranty-host'), gateway: owner, role: WorkspaceOrderIdentityRole.buyer,
        realm: realm, buyingStoreId: selector, reference: reference, line: line))));
      await tester.pumpWidget(host()); await tester.pumpAndSettle();
      await tester.tap(find.text('Warranty details')); await tester.pump(); await tester.pump(const Duration(milliseconds: 300));
      expect(reader.requests, hasLength(1)); final oldTarget = reader.requests.single;
      if (retirement.startsWith('collapse')) {
        await tester.tap(find.text('Warranty details')); await tester.pumpAndSettle();
      } else if (retirement == 'dispose') {
        await tester.pumpWidget(const SizedBox.shrink()); await tester.pumpAndSettle();
      } else {
        if (retirement == 'account-ABA') owner = projectionGateway(wire, account: 'another-account', purchasedWarrantyReader: reader);
        if (retirement == 'realm-ABA') realm = 'production';
        if (retirement == 'buying-store-ABA') selector = 'another-store';
        if (retirement == 'reader-lifetime') reader.lifetime = Object();
        await tester.pumpWidget(host()); await tester.pumpAndSettle();
        owner = gateway; realm = 'evaluation'; selector = null;
        await tester.pumpWidget(host()); await tester.pumpAndSettle();
      }
      reader.respond = warrantyRead;
      if (retirement != 'collapse') {
        if (retirement == 'dispose') { await tester.pumpWidget(host()); await tester.pumpAndSettle(); }
        await tester.tap(find.text('Warranty details')); await tester.pumpAndSettle();
        expect(find.text('Warranty issuer: HOST original issuer'), findsOneWidget);
      }
      pending.complete(warrantyRead(oldTarget, revision: 99, fields: const {'issuer': 'HOST late retired issuer'}));
      await tester.pumpAndSettle();
      expect(find.text('Warranty issuer: HOST late retired issuer'), findsNothing);
      if (retirement != 'collapse') expect(find.text('Warranty issuer: HOST original issuer'), findsOneWidget);
      expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  test('LF-RESTOCK-CLOSE actual emulator closure survives strict client roundtrip', () async {
    final raw = jsonDecode(File(Platform.environment['LF_RESTOCK_ARRIVAL_EXPORT']!).readAsStringSync()) as Map;
    final closure = raw['closure'] as Map, command = WorkspaceGoodsArrivalCommand.fromJson(closure['command']);
    final wire = Transport()..data = Map<String, dynamic>.from(closure['response'] as Map);
    final gateway = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire, account: command.receipt.restockOriginal!.accountScope));
    final result = await gateway.reconcileBuyerGoodsArrival(command);
    expect(result?.closed, isTrue); expect(result!.recorded, isFalse); expect(result.proof, isNull);
    expect(WorkspaceGoodsArrivalResult.fromJson(result.toJson(), command).toJson(), wire.data);
  }, skip: Platform.environment['LF_RESTOCK_ARRIVAL_EXPORT'] == null);
  test('LF-RESTOCK-CLOSE explicit close uses limited-use token and delayed record preserves closure', () async {
    final command = restockArrivalCommand(), wire = Transport()..data = restockClosureResponse(restockArrivalCommand());
    final identity = projectionGateway(wire), gateway = AuthenticatedWorkspaceOrderOperationsGateway(identity);
    final closed = await gateway.closeBuyerGoodsArrival(command);
    expect(closed?.closed, isTrue); expect(closed!.closure!.command.fingerprint, command.fingerprint);
    expect(wire.sent, {'operation': 'closeBuyerGoodsArrival', ...command.toJson()});
    expect((identity.credentials as Credentials).modes.last, SocialAppCheckTokenMode.limitedUse);
    expect((await gateway.recordBuyerGoodsArrival(command))!.closure!.toJson(), closed.closure!.toJson());
    expect((await gateway.reconcileBuyerGoodsArrival(command))!.closure!.toJson(), closed.closure!.toJson());
    expect((identity.credentials as Credentials).modes.last, SocialAppCheckTokenMode.standard);
    wire.data = restockArrivalResponse(command);
    expect((await gateway.closeBuyerGoodsArrival(command))!.recorded, isTrue, reason: 'A record winner cannot be reversed.');
    wire.data = restockArrivalResponse(command, recorded: false);
    expect(await gateway.closeBuyerGoodsArrival(command), isNull, reason: 'Not found is not an acknowledged close.');
  });
  for (final fault in ['owner', 'realm', 'store', 'operation', 'supplier', 'command', 'receipt', 'outcome', 'time', 'extra', 'integrity']) {
    test('LF-RESTOCK-CLOSE rejects changed closure $fault', () async {
      final command = restockArrivalCommand(), raw = restockClosureResponse(restockArrivalCommand());
      final proof = raw['proof'] as Map<String, dynamic>;
      switch (fault) {
        case 'owner': raw['viewerUserId'] = 'other-buyer';
        case 'realm': proof['realm'] = 'production';
        case 'store': proof['buyingStoreId'] = 'other-store';
        case 'operation': proof['operationId'] = 'other-receipt';
        case 'supplier': proof['supplierId'] = 'other-supplier';
        case 'command': proof['commandFingerprint'] = 'b' * 64;
        case 'receipt': proof['receipt']['reference'] = 'changed';
        case 'outcome': proof['outcome'] = 'recorded';
        case 'time': proof['closedAt'] = '2026-02-30T12:01:00.000Z';
        case 'extra': proof['stockReversed'] = true;
        case 'integrity': proof['integrity'] = 'b' * 64;
      }
      if (fault != 'integrity') { proof.remove('integrity'); proof['integrity'] = restockIntegrity(proof); }
      final wire = Transport()..data = raw;
      expect(await AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire)).reconcileBuyerGoodsArrival(command), isNull);
    });
  }
  test('LF-RESTOCK-WIRE accepts actual emulator-produced receipt including reporting date and cumulative proof', () async {
    final evidence = jsonDecode(File(Platform.environment['LF_RESTOCK_ARRIVAL_EXPORT']!).readAsStringSync()) as Map<String, dynamic>;
    expect(evidence['schemaVersion'], 1); expect(evidence['evidence'], 'isolated_firestore_emulator_owner_report');
    final command = WorkspaceGoodsArrivalCommand.fromJson(evidence['command']);
    final wire = Transport()..data = Map<String, dynamic>.from(evidence['response'] as Map);
    final gateway = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire, account: command.receipt.restockOriginal!.accountScope));
    final recovered = await gateway.reconcileBuyerGoodsArrival(command);
    expect(recovered?.recorded, isTrue); expect(recovered!.proof!.toJson(), wire.data['proof']);
    expect(recovered.group!.includes(command), isTrue); expect(recovered.proof!.groupRevision, 2);
    expect(command.receipt.recordedUtcOffsetMinutes, 330); expect(command.receipt.deliveredOn, '2026-10-21');
    expect(WorkspaceGoodsArrivalResult.fromJson(recovered.toJson(), command).toJson(), recovered.toJson());
  }, skip: Platform.environment['LF_RESTOCK_ARRIVAL_EXPORT'] == null);
  test('LF-RESTOCK-WIRE cumulative server reports are independent of one arrival Stock delta limit', () async {
    final evidence = jsonDecode(File(Platform.environment['LF_RESTOCK_ARRIVAL_EXPORT']!).readAsStringSync()) as Map<String, dynamic>;
    final raw = evidence['cumulative'] as Map, command = WorkspaceGoodsArrivalCommand.fromJson(raw['command']);
    final wire = Transport()..data = Map<String, dynamic>.from(raw['response'] as Map);
    final gateway = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire, account: command.receipt.restockOriginal!.accountScope));
    expect(command.receipt.lines.single.acceptedStockUnits, 1500000000);
    final result = await gateway.reconcileBuyerGoodsArrival(command);
    expect(result?.recorded, isTrue);
    expect(result!.group!.lines.single.acceptedStockUnits, 3000000000);
  }, skip: Platform.environment['LF_RESTOCK_ARRIVAL_EXPORT'] == null);
  test('LF-RESTOCK-WIRE frozen command uses limited-use record and standard exact reconciliation', () async {
    final command = restockArrivalCommand(), wire = Transport()..data = restockArrivalResponse(restockArrivalCommand());
    final identity = projectionGateway(wire), gateway = AuthenticatedWorkspaceOrderOperationsGateway(identity);
    expect(WorkspaceGoodsArrivalCommand.fromJson(command.toJson()).fingerprint, command.fingerprint);
    final leaked = command.toJson(); (leaked['receipt'] as Map)['reference'] = 'changed';
    expect(command.toJson()['receipt'], command.receipt.toJson());
    final recorded = await gateway.recordBuyerGoodsArrival(command);
    expect(recorded?.recorded, isTrue); expect(recorded!.proof!.command.fingerprint, command.fingerprint);
    expect(recorded.group!.lines.single.acceptedStockUnits, 5);
    expect(wire.sent, {'operation': 'recordBuyerGoodsArrival', ...command.toJson()});
    expect((identity.credentials as Credentials).modes.last, SocialAppCheckTokenMode.limitedUse);
    expect((await gateway.reconcileBuyerGoodsArrival(command))!.proof!.toJson(), recorded.proof!.toJson());
    expect(wire.sent, {'operation': 'reconcileBuyerGoodsArrival', ...command.toJson()});
    expect((identity.credentials as Credentials).modes.last, SocialAppCheckTokenMode.standard);
    final read = Map<String, dynamic>.of(wire.data)..remove('state')..remove('proof'); wire.data = read;
    expect((await gateway.readBuyerGoodsReceiving(command.receipt.restockOriginal!))!.group!.includes(command), isTrue);
    wire.data = restockArrivalResponse(command, recorded: false);
    expect((await gateway.reconcileBuyerGoodsArrival(command))!.recorded, isFalse);
    expect(await gateway.recordBuyerGoodsArrival(command), isNull);
    wire.fail = true;
    final before = wire.calls; expect(await gateway.recordBuyerGoodsArrival(command), isNull);
    expect(wire.calls, before + 1, reason: 'Unknown reply cannot automatically create or retry an operation.');
  });
  for (final fault in ['owner', 'realm', 'store', 'extra', 'group-supplier', 'mapping', 'counts', 'proof-operation',
    'proof-command', 'proof-receipt', 'group-revision', 'integrity', 'payment']) {
    test('LF-RESTOCK-WIRE rejects changed $fault even with recalculated checksums', () async {
      final command = restockArrivalCommand(), raw = restockArrivalResponse(restockArrivalCommand());
      final group = raw['group'] as Map<String, dynamic>, proof = raw['proof'] as Map<String, dynamic>;
      switch (fault) {
        case 'owner': raw['viewerUserId'] = 'other-buyer';
        case 'realm': raw['realm'] = 'production';
        case 'store': raw['buyingStoreId'] = 'other-store';
        case 'extra': raw['courierVerified'] = true;
        case 'group-supplier': group['supplierId'] = 'other-supplier';
        case 'mapping': group['lines'][0]['mapping']['productId'] = 'other-stock';
        case 'counts': group['lines'][0]['deliveredMilli'] = 100; group['lines'][0]['acceptedMilli'] = 0;
        case 'proof-operation': proof['operationId'] = 'other-arrival';
        case 'proof-command': proof['commandFingerprint'] = 'b' * 64;
        case 'proof-receipt': proof['receipt']['reference'] = 'changed reference';
        case 'group-revision': proof['groupRevision'] = 2;
        case 'integrity': proof['integrity'] = 'b' * 64;
        case 'payment': proof['paid'] = true;
      }
      group.remove('integrity'); group['integrity'] = restockIntegrity(group);
      if (fault != 'integrity') {proof.remove('integrity'); proof['integrity'] = restockIntegrity(proof);}
      final wire = Transport()..data = raw;
      expect(await AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire)).reconcileBuyerGoodsArrival(command), isNull);
      expect(wire.calls, 1);
    });
  }
  test('LF-RESTOCK-WIRE retired account blocks dispatch and late replies', () async {
    final command = restockArrivalCommand(), wire = Transport()..data = restockArrivalResponse(restockArrivalCommand());
    Object? lifetime = Object(); final identity = projectionGateway(wire, lifetime: () => lifetime);
    final gateway = AuthenticatedWorkspaceOrderOperationsGateway(identity);
    expect(await gateway.recordBuyerGoodsArrival(restockArrivalCommand(account: 'other-buyer')), isNull);
    expect(wire.calls, 0);
    wire.pending = Completer<void>(); final pending = gateway.recordBuyerGoodsArrival(command);
    await Future<void>.delayed(Duration.zero); lifetime = null; wire.pending!.complete();
    expect(await pending, isNull);
    final before = wire.calls; expect(await gateway.reconcileBuyerGoodsArrival(command), isNull); expect(wire.calls, before);
  });
  const storeStarsContext = BuyV2ProcurementContext(accountId: 'buyer-1', storeId: 'buying-store',
    purpose: BuyV2ProcurementPurpose.restock, originOperationId: 'host-stars-origin');
  test('LF-STARS-STORE actual persisted completion and original recovery cross shared client', () async {
    const marker = 'LF_STORE_PURCHASE_FEEDBACK_CAPTURE=';
    final line = File(Platform.environment['LF_STORE_FEEDBACK_LOG']!).readAsLinesSync().where((l) => l.contains(marker)).single;
    final data = jsonDecode(line.substring(line.indexOf(marker) + marker.length)) as Map<String, dynamic>;
    final buyer = data['buyer'] as Map<String, dynamic>, rawTarget = data['targetRead']['target'] as Map<String, dynamic>;
    final context = BuyV2ProcurementContext(accountId: buyer['viewerUserId'],
      storeId: buyer['orders'][0]['original']['purchaser']['storeId'], purpose: BuyV2ProcurementPurpose.restock,
      originOperationId: 'host-actual-stars-origin');
    final identity = ValueNotifier<BuyV2ProcurementContext?>(context); addTearDown(identity.dispose);
    final command = data['command'] as Map<String, dynamic>;
    final attempt = BuyV2ProductStarsAttempt.fromJson({'version': 1, 'target': rawTarget,
      'operationId': command['operationId'], 'expectedRevision': command['expectedRevision'], 'stars': command['stars']});
    final store = StarsStateStore(scope: context.customerStateOwnerScope)
      ..saved = BuyV2CustomerStateSnapshot(productStarAttempts: {rawTarget['id']: attempt});
    final wire = Transport()..respond = ((body) => switch (body['operation']) {
      'readBuyerPurchaseProjection' => buyer,
      'readBuyerProductFeedbackTarget' => data['targetRead'],
      'readBuyerProductStars' => data['afterStars'],
      'reconcileBuyerProductStars' => data['recoveredStars'],
      _ => throw StateError('Actual recovery must not place or send a replacement rating'),
    });
    final reader = projectionGateway(wire, account: context.accountId), core = BuySession();
    final session = BuyV2Session(core: core, procurementIdentity: identity, customerStateStore: store,
      reviewDataEnabled: false, purchaseReader: reader, purchaseRealm: buyer['realm']);
    addTearDown(core.dispose); addTearDown(session.dispose);
    await session.restoreCustomerState();
    final purchase = (await reader.readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
      realm: buyer['realm'], purchaseId: buyer['purchaseId'], buyingStoreId: context.storeId))!;
    final order = purchase.orders.singleWhere((o) => o.orderId == rawTarget['orderId']);
    final purchased = order.lines.singleWhere((l) => l.lineId == rawTarget['orderLineId']);
    final target = AuthenticatedWorkspaceOrderOperationsGateway(reader).restoreProductFeedbackTarget(rawTarget, realm: buyer['realm'])!;
    expect(await session.loadPrivateStarsFor(target.reference, purchased), isTrue);
    expect(session.privateStarAttempt(target.id)!.toJson(), attempt.toJson());
    expect(await session.checkPrivateStars(target.id), isTrue);
    final sent = wire.requests.singleWhere((r) => r['operation'] == 'reconcileBuyerProductStars');
    expect(Map<String, Object?>.of(sent)..remove('operation'), command);
    expect(session.privateStarRating(target.id)!.stars, command['stars']);
    expect(store.saved!.productStarAttempts, isEmpty);
    expect(wire.requests.where((r) => r['operation'] == 'submitBuyerProductStars'), isEmpty);
    expect(session.cartLines, isEmpty); expect(session.availablePaymentMethods, isEmpty);
    final empty = data['emptyPersonalPage'] as Map<String, dynamic>;
    final page = await AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(Transport()..data = empty,
      account: context.accountId)).listProductFeedbackTargets(realm: buyer['realm']);
    expect(page, isNotNull); expect(page!.targets, isEmpty); expect(page.nextCursor, empty['nextCursor']);
  }, skip: Platform.environment['LF_STORE_FEEDBACK_LOG'] == null);
  for (final purpose in BuyV2ProcurementPurpose.values) {
    test('LF-STARS-STORE completed original rates independently of catalogue purpose=$purpose', () async {
      final context = BuyV2ProcurementContext(accountId: 'buyer-1', storeId: 'buying-store',
        purpose: purpose, originOperationId: 'host-stars-origin');
      final identity = ValueNotifier<BuyV2ProcurementContext?>(context);
      addTearDown(identity.dispose);
      final data = purchaserPurchaseResponse(), storage = StarsStateStore(scope: context.customerStateOwnerScope);
      final (session, wire, store) = await starsSession(storage: storage, procurementIdentity: identity, purchase: data);
      final purchase = (await projectionGateway(Transport()..data = data).readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: data['purchaseId'], buyingStoreId: context.storeId))!;
      final target = AuthenticatedWorkspaceOrderOperationsGateway(session.purchaseReader!).restoreProductFeedbackTarget(
        feedbackTargetPage(purchase: data)['targets'][0], realm: 'evaluation')!;
      expect(session.procurementUnavailableMessage, isNotNull, reason: 'Historical rating needs no current supplier catalogue grant.');
      expect(session.privateStarsAvailable, isTrue);
      expect(await session.loadPrivateStars(), isFalse, reason: 'Store detail must not use account-wide personal discovery.');
      expect(wire.requests, isEmpty);
      expect(await session.loadPrivateStarsFor(target.reference, purchase.orders.single.lines.first), isTrue);
      expect(wire.requests.first, {'operation': 'readBuyerPurchaseProjection', 'purchaseId': data['purchaseId'], 'buyingStoreId': context.storeId});
      expect(session.privateStarTargets(reference: target.reference).single.id, target.id);
      expect(await session.savePrivateStars(target.id, 4), isTrue);
      expect(session.privateStarRating(target.id)!.stars, 4);
      expect(store.saved!.productStarAttempts, isEmpty);
      expect(wire.requests.where((r) => r['operation'] == 'submitBuyerProductStars'), hasLength(1));
      expect(wire.requests.where((r) => r['operation'] == 'listBuyerProductFeedbackTargets'), isEmpty);
      expect(session.cartLines, isEmpty); expect(session.availablePaymentMethods, isEmpty);
    });
  }
  for (final fault in ['personal', 'other-store', 'completion']) {
    test('LF-STARS-STORE rejects $fault before admitting a rating', () async {
      final identity = ValueNotifier<BuyV2ProcurementContext?>(storeStarsContext);
      addTearDown(identity.dispose);
      final data = purchaserPurchaseResponse(), storage = StarsStateStore(scope: storeStarsContext.customerStateOwnerScope);
      final original = (await projectionGateway(Transport()..data = data).readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: data['purchaseId'], buyingStoreId: 'buying-store'))!;
      final target = feedbackTargetPage(purchase: data)['targets'][0];
      final (session, wire, _) = await starsSession(storage: storage, procurementIdentity: identity, purchase: data);
      final respond = wire.respond!;
      wire.respond = (body) {
        if (body['operation'] == 'readBuyerPurchaseProjection' && fault != 'completion') {
          final denied = purchaserPurchaseResponse(kind: fault == 'personal' ? 'personal' : 'store');
          if (fault == 'other-store') {
            denied['orders'][0]['original']['purchaser']['storeId'] = 'other-buying-store';
            rehashPurchaseOrder(denied['orders'][0]);
          }
          return denied;
        }
        if (body['operation'] == 'readBuyerProductFeedbackTarget' && fault == 'completion') throw StateError('No recorded completion');
        return respond(body);
      };
      expect(await session.loadPrivateStarsFor(WorkspacePurchaseReference.fromJson({
        for (final key in ['purchaseId', 'storeId', 'orderId', 'originalFingerprint', 'sourceRevision']) key: target[key]}),
        original.orders.single.lines.first), isFalse);
      expect(session.privateStarTargets(), isEmpty);
      expect(wire.requests.where((r) => r['operation'] == 'readBuyerProductStars' || r['operation'] == 'submitBuyerProductStars'), isEmpty);
      expect(wire.requests.where((r) => r['operation'] == 'readBuyerPurchaseProjection'), hasLength(1));
    });
  }
  test('LF-STARS-STORE filtered empty personal page retains an advancing cursor', () async {
    final wire = Transport()..data = (feedbackTargetPage()..['targets'] = []..['nextCursor'] = 'host-advancing-cursor');
    final gateway = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire));
    final first = await gateway.listProductFeedbackTargets(realm: 'evaluation');
    expect(first, isNotNull); expect(first!.targets, isEmpty); expect(first.nextCursor, 'host-advancing-cursor');
    wire.data = feedbackTargetPage();
    expect((await gateway.listProductFeedbackTargets(realm: 'evaluation', cursor: first.nextCursor))!.targets, hasLength(1));
    wire.data = feedbackTargetPage()..['targets'] = []..['nextCursor'] = first.nextCursor;
    expect(await gateway.listProductFeedbackTargets(realm: 'evaluation', cursor: first.nextCursor), isNull);
  });
  for (final cycle in [false, true]) {
    test('LF-STARS-STORE personal discovery advances filtered pages and rejects cycle=$cycle', () async {
      final (session, wire, _) = await starsSession();
      final respond = wire.respond!;
      wire.respond = (body) {
        if (body['operation'] != 'listBuyerProductFeedbackTargets') return respond(body);
        if (body['cursor'] == null) return feedbackTargetPage()..['targets'] = []..['nextCursor'] = 'filtered-first';
        if (body['cursor'] == 'filtered-first') return feedbackTargetPage()..['targets'] = []..['nextCursor'] = 'filtered-second';
        return cycle ? (feedbackTargetPage()..['targets'] = []..['nextCursor'] = 'filtered-first') : feedbackTargetPage();
      };
      expect(await session.loadPrivateStars(), isTrue); expect(session.privateStarTargets(), isEmpty);
      expect(session.privateStarsHasMore, isTrue);
      expect(await session.loadPrivateStars(more: true), isTrue); expect(session.privateStarTargets(), isEmpty);
      expect(await session.loadPrivateStars(more: true), !cycle);
      expect(session.privateStarTargets(), cycle ? isEmpty : hasLength(1));
      expect(wire.requests.where((r) => r['operation'] == 'listBuyerProductFeedbackTargets'), hasLength(3));
    });
  }
  test('LF-STARS-STORE misplaced other-Store recovery remains unsent and unchanged', () async {
    final identity = ValueNotifier<BuyV2ProcurementContext?>(storeStarsContext); addTearDown(identity.dispose);
    final data = purchaserPurchaseResponse(); data['orders'][0]['original']['purchaser']['storeId'] = 'other-buying-store';
    rehashPurchaseOrder(data['orders'][0]);
    final target = feedbackTargetPage(purchase: data)['targets'][0];
    final attempt = BuyV2ProductStarsAttempt.fromJson({'version': 1, 'target': target, 'operationId': 'other-store-original',
      'expectedRevision': 0, 'stars': 2});
    final store = StarsStateStore(scope: storeStarsContext.customerStateOwnerScope)
      ..saved = BuyV2CustomerStateSnapshot(productStarAttempts: {target['id']: attempt});
    final (session, wire, _) = await starsSession(storage: store, procurementIdentity: identity, purchase: data);
    expect(await session.checkPrivateStars(target['id']), isFalse);
    expect(await session.checkPrivateStars(target['id'], retryOriginal: true), isFalse);
    expect(wire.requests.every((r) => r['operation'] == 'readBuyerPurchaseProjection'), isTrue);
    expect(store.saved!.productStarAttempts[target['id']]!.toJson(), attempt.toJson());
  });
  for (final phase in ['original', 'target', 'saved', 'submit', 'reconcile']) {
    for (final changed in ['account', 'store', 'aba', 'reader', 'realm']) {
      test('LF-STARS-STORE late $phase reply cannot cross $changed', () async {
        final identity = ValueNotifier<BuyV2ProcurementContext?>(storeStarsContext); addTearDown(identity.dispose);
        final data = purchaserPurchaseResponse(), store = StarsStateStore(scope: storeStarsContext.customerStateOwnerScope);
        final (session, wire, _) = await starsSession(storage: store, procurementIdentity: identity, purchase: data);
        final reader = projectionGateway(Transport()..data = data);
        final original = (await reader.readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
          realm: 'evaluation', purchaseId: data['purchaseId'], buyingStoreId: 'buying-store'))!;
        final target = AuthenticatedWorkspaceOrderOperationsGateway(reader).restoreProductFeedbackTarget(
          feedbackTargetPage(purchase: data)['targets'][0], realm: 'evaluation')!;
        final line = original.orders.single.lines.first;
        if (phase == 'submit' || phase == 'reconcile') expect(await session.loadPrivateStarsFor(target.reference, line), isTrue);
        final respond = wire.respond!;
        if (phase == 'reconcile') {
          wire.respond = (body) => body['operation'] == 'submitBuyerProductStars' ? throw StateError('Lost original response') : respond(body);
          expect(await session.savePrivateStars(target.id, 4), isFalse);
          wire.respond = respond;
        }
        final entered = Completer<void>(), release = Completer<void>();
        final operation = {'original': 'readBuyerPurchaseProjection', 'target': 'readBuyerProductFeedbackTarget',
          'saved': 'readBuyerProductStars', 'submit': 'submitBuyerProductStars', 'reconcile': 'reconcileBuyerProductStars'}[phase];
        wire.beforePost = (body) async {if (body['operation'] == operation) {entered.complete(); await release.future;}};
        final pending = phase == 'submit' ? session.savePrivateStars(target.id, 4) : phase == 'reconcile'
          ? session.checkPrivateStars(target.id) : session.loadPrivateStarsFor(target.reference, line);
        await entered.future;
        final attempt = session.privateStarAttempt(target.id)?.toJson();
        if (changed == 'reader') {
          expect(session.rebindStorePurchaseReader(reader: projectionGateway(Transport()), realm: 'evaluation'), isTrue);
        } else if (changed == 'realm') {
          expect(session.rebindStorePurchaseReader(reader: session.purchaseReader, realm: 'production'), isTrue);
        } else {
          identity.value = BuyV2ProcurementContext(accountId: changed == 'account' ? 'other-account' : storeStarsContext.accountId,
            storeId: changed == 'account' ? storeStarsContext.storeId : 'other-buying-store',
            purpose: storeStarsContext.purpose, originOperationId: storeStarsContext.originOperationId);
          if (changed == 'aba') identity.value = storeStarsContext;
        }
        release.complete();
        expect(await pending, isFalse);
        expect(session.privateStarRating(target.id), isNull, reason: 'A late reply must not become a saved rating.');
        expect(session.canSavePrivateStars(target.id), isFalse);
        if (attempt != null) {
          if (session.privateStarsAvailable && session.purchaseRealm == target.purchasedListing.realm) {
            expect(session.privateStarTargets().single.id, target.id, reason: 'The same owner retains its original recovery target.');
          } else {
            expect(session.privateStarTargets(), isEmpty);
          }
          expect(store.saved!.productStarAttempts[target.id]!.toJson(), attempt);
          final sent = wire.requests.where((r) => r['operation'] == 'submitBuyerProductStars').toList();
          expect(sent, hasLength(1));
          expect(sent.single['operationId'], attempt['operationId']);
          if (phase == 'reconcile') {
            expect(Map<String, Object?>.of(wire.requests.last)..remove('operation'), Map<String, Object?>.of(sent.single)..remove('operation'));
          }
        } else {
          expect(session.privateStarTargets(), isEmpty);
          expect(wire.requests.where((r) => r['operation'] == 'submitBuyerProductStars'), isEmpty);
        }
        expect(session.cartLines, isEmpty); expect(session.availablePaymentMethods, isEmpty);
      });
    }
  }
  test('LF-STARS-STORE original save survives restart and exact ownership denial', () async {
    final identity = ValueNotifier<BuyV2ProcurementContext?>(storeStarsContext); addTearDown(identity.dispose);
    final data = purchaserPurchaseResponse(), store = StarsStateStore(scope: storeStarsContext.customerStateOwnerScope);
    final (session, wire, _) = await starsSession(storage: store, procurementIdentity: identity, purchase: data);
    final reader = projectionGateway(Transport()..data = data);
    final original = (await reader.readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', purchaseId: data['purchaseId'], buyingStoreId: 'buying-store'))!;
    final target = AuthenticatedWorkspaceOrderOperationsGateway(reader).restoreProductFeedbackTarget(
      feedbackTargetPage(purchase: data)['targets'][0], realm: 'evaluation')!;
    expect(await session.loadPrivateStarsFor(target.reference, original.orders.single.lines.first), isTrue);
    final respond = wire.respond!;
    wire.respond = (body) => body['operation'] == 'submitBuyerProductStars' ? throw StateError('Lost reply') : respond(body);
    expect(await session.savePrivateStars(target.id, 3), isFalse);
    final command = Map<String, Object?>.of(wire.requests.last), attempt = store.saved!.productStarAttempts[target.id]!.toJson();
    final (resumed, next, _) = await starsSession(storage: store, procurementIdentity: identity, purchase: data);
    final nextReply = next.respond!;
    next.respond = (body) => body['operation'] == 'readBuyerPurchaseProjection' ? throw StateError('Current Store ownership denied') : nextReply(body);
    expect(await resumed.checkPrivateStars(target.id), isFalse);
    expect(next.requests.where((r) => r['operation'] == 'reconcileBuyerProductStars'), isEmpty);
    expect(store.saved!.productStarAttempts[target.id]!.toJson(), attempt);
    next.respond = nextReply;
    expect(await resumed.checkPrivateStars(target.id), isFalse, reason: 'A not-recorded read must retain the original save.');
    expect(Map<String, Object?>.of(next.requests.last)..remove('operation'), Map<String, Object?>.of(command)..remove('operation'));
    expect(await resumed.checkPrivateStars(target.id, retryOriginal: true), isTrue);
    expect(next.requests.last, command);
    expect(store.saved!.productStarAttempts, isEmpty);
  });
  for (final scale in [1.0, 2.0]) {
    for (final changed in ['none', 'reader', 'realm', 'store', 'closed']) {
      testWidgets('LF-STARS-STORE compact completed purchase sheet scale=$scale change=$changed', (tester) async {
        final identity = ValueNotifier<BuyV2ProcurementContext?>(storeStarsContext); addTearDown(identity.dispose);
        final data = purchaserPurchaseResponse(), store = StarsStateStore(scope: storeStarsContext.customerStateOwnerScope);
        final (session, wire, _) = await starsSession(storage: store, procurementIdentity: identity, purchase: data);
        final target = feedbackTargetPage(purchase: data)['targets'][0];
        var completed = false; connectPurchaseFixture(wire, () => completed, purchase: data);
        tester.view.physicalSize = const Size(320, 800); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(),
          builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
          home: BuyV2Screen(session: session, initialDestination: BuyV2Destination.orders)));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Saved purchase details')); await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('original-order-${target['orderId']}'))); await tester.pumpAndSettle();
        final action = find.byKey(ValueKey('purchase-rate-item-${target['orderId']}-${target['orderLineId']}'));
        final update = find.text('Check order update');
        await tester.ensureVisible(update); await tester.tap(update); await tester.pumpAndSettle();
        expect(action, findsNothing);
        completed = true;
        await tester.ensureVisible(update); await tester.tap(update); await tester.pumpAndSettle();
        await tester.ensureVisible(action); await tester.pumpAndSettle();
        expect(action.hitTestable(), findsOneWidget);
        await tester.tap(action); await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('buy-product-review-sheet')), findsOneWidget);
        expect(find.text('Choose 1–5 stars. Only this Store can see your rating.'), findsOneWidget);
        expect(find.byType(TextFormField), findsNothing);
        if (scale == 2) {tester.view.viewInsets = const FakeViewPadding(bottom: 220); await tester.pumpAndSettle();}
        final scroll = find.descendant(of: find.byKey(const ValueKey('buy-product-review-fields-scroll')), matching: find.byType(Scrollable)).first;
        final star = find.byKey(ValueKey('buy-private-star-${target['id']}-4'));
        await tester.scrollUntilVisible(star, 120, scrollable: scroll); await tester.tap(star); await tester.pumpAndSettle();
        final submit = find.byKey(const ValueKey('buy-submit-private-stars'));
        await tester.scrollUntilVisible(submit, 120, scrollable: scroll); await tester.pumpAndSettle();
        final staleSubmit = tester.widget<FilledButton>(submit).onPressed!;
        final staleStar = tester.widget<IconButton>(star).onPressed!;
        final staleRefresh = tester.widget<TextButton>(find.byKey(const ValueKey('buy-private-stars-refresh'))).onPressed!;
        if (changed == 'none') {
          await tester.tap(submit); await tester.pumpAndSettle();
          expect(session.privateStarRating(target['id'])!.stars, 4);
          expect(store.saved!.productStarAttempts, isEmpty);
          expect(wire.requests.where((r) => r['operation'] == 'submitBuyerProductStars'), hasLength(1));
        } else {
          final next = Transport()..respond = wire.respond;
          if (changed == 'reader') {
            expect(session.rebindStorePurchaseReader(reader: projectionGateway(next), realm: 'evaluation'), isTrue);
            final reference = WorkspacePurchaseReference.fromJson({for (final key in
              ['purchaseId', 'storeId', 'orderId', 'originalFingerprint', 'sourceRevision']) key: target[key]});
            final purchase = (await session.purchaseReader!.readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
              realm: 'evaluation', purchaseId: data['purchaseId'], buyingStoreId: 'buying-store'))!;
            expect(await session.loadPrivateStarsFor(reference, purchase.orders.single.lines.first), isTrue);
          } else if (changed == 'realm') {
            expect(session.rebindStorePurchaseReader(reader: projectionGateway(next), realm: 'production'), isTrue);
          } else if (changed == 'closed') {
            final close = find.byKey(const ValueKey('buy-close-product-review'));
            await tester.ensureVisible(close); await tester.pumpAndSettle();
            await tester.tap(close);
          } else {
            identity.value = const BuyV2ProcurementContext(accountId: 'buyer-1', storeId: 'other-buying-store',
              purpose: BuyV2ProcurementPurpose.restock, originOperationId: 'host-stars-origin');
          }
          await tester.pumpAndSettle();
          if (changed == 'store' || changed == 'closed') {
            expect(find.byKey(const ValueKey('buy-product-review-sheet')), findsNothing);
          } else {
            expect(find.text('Purchase access changed. Reopen your purchase to rate it.'), findsOneWidget);
          }
          final calls = wire.calls, nextCalls = next.calls;
          staleStar(); staleSubmit(); staleRefresh(); await tester.pumpAndSettle();
          expect(wire.calls, calls); expect(next.calls, nextCalls);
          expect(wire.requests.where((r) => r['operation'] == 'submitBuyerProductStars'), isEmpty);
          expect(next.requests.where((r) => r['operation'] == 'submitBuyerProductStars'), isEmpty);
        }
        expect(session.cartLines, isEmpty); expect(session.availablePaymentMethods, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  for (final kind in ['personal', 'store']) {
    test('LF-PURCHASER strict original reader preserves $kind purchaser', () async {
      final data = purchaserPurchaseResponse(kind: kind), wire = Transport()..data = data;
      final result = await projectionGateway(wire).readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', purchaseId: data['purchaseId'], buyingStoreId: kind == 'store' ? 'buying-store' : null);
      expect(result, isNotNull); expect(result!.orders.single.factsVersion, 11);
      expect(result.orders.single.purchaser!.toJson(), data['orders'][0]['original']['purchaser']);
      expect(wire.sent!.containsKey('buyingStoreId'), kind == 'store');
      expect(result.orders.single.totals['totalMinor'], data['orders'][0]['original']['totals']['totalMinor']);
    });
  }
  for (final mismatch in ['personal reader', 'wrong Store', 'private field', 'missing purchaser', 'unknown purpose', 'changed hash']) {
    test('LF-PURCHASER rejects $mismatch before admitting original', () async {
      final data = purchaserPurchaseResponse(), order = data['orders'][0];
      switch (mismatch) {
        case 'private field': order['original']['purchaser']['accountId'] = 'buyer-1'; rehashPurchaseOrder(order);
        case 'missing purchaser': order['original'].remove('purchaser'); rehashPurchaseOrder(order);
        case 'unknown purpose': order['original']['purchaser']['purpose'] = 'anything'; rehashPurchaseOrder(order);
        case 'changed hash': order['original']['purchaser']['name'] = 'Changed Store';
      }
      final wire = Transport()..data = data;
      expect(await projectionGateway(wire).readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', purchaseId: data['purchaseId'],
        buyingStoreId: mismatch == 'personal reader' ? null : mismatch == 'wrong Store' ? 'other-store' : 'buying-store'), isNull);
    });
  }
  test('LF-PURCHASER Store reference page echoes buyer selector without restricting supplier IDs', () async {
    final data = purchaserReferenceResponse(), wire = Transport()..data = data;
    final page = await projectionGateway(wire).listPurchaseReferences(role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', buyingStoreId: 'buying-store');
    expect(page, isNotNull); expect(page!.references.single.storeId, 'store-one');
    expect(wire.sent!['buyingStoreId'], 'buying-store'); expect(wire.sent!.containsKey('storeId'), isFalse);
    data['buyingStoreId'] = 'other-store';
    expect(await projectionGateway(wire).listPurchaseReferences(role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', buyingStoreId: 'buying-store'), isNull);
  });
  test('LF-PURCHASER buyer Store cannot admit legacy personal or seller-selected originals', () async {
    final wire = Transport()..data = purchaseResponse();
    final gateway = projectionGateway(wire);
    expect(await gateway.readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation',
      purchaseId: 'purchase-v2', buyingStoreId: 'buying-store'), isNull);
    final calls = wire.calls;
    expect(await gateway.listPurchaseReferences(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation',
      storeId: 'store-one', buyingStoreId: 'buying-store'), isNull);
    expect(wire.calls, calls);
  });
  if (Platform.environment['LF_PURCHASER_LOG'] case final path?) {
    test('LF-PURCHASER actual persisted backend originals and operations decode unchanged', () async {
      const marker = 'LF_PURCHASER_PROJECTION=';
      final lines = File(path).readAsLinesSync().where((l) => l.contains(marker)).toList(); expect(lines, hasLength(1));
      final packet = (jsonDecode(lines.single.substring(lines.single.indexOf(marker) + marker.length)) as Map).cast<String, dynamic>();
      for (final role in WorkspaceOrderIdentityRole.values) {
        final data = (packet[role == WorkspaceOrderIdentityRole.buyer ? 'buyer' : 'seller'] as Map).cast<String, dynamic>();
        final account = data['viewerUserId'] as String, order = data['orders'][0];
        final wire = Transport()..data = data, gateway = projectionGateway(wire, account: account);
        final result = await gateway.readPurchaseProjection(role: role, realm: 'evaluation', purchaseId: data['purchaseId'],
          buyingStoreId: role == WorkspaceOrderIdentityRole.buyer ? 'buying-store' : null,
          storeId: role == WorkspaceOrderIdentityRole.seller ? order['storeId'] : null,
          orderId: role == WorkspaceOrderIdentityRole.seller ? order['orderId'] : null);
        expect(result, isNotNull); expect(result!.orders.first.purchaser!.storeId, 'buying-store');
        expect(result.orders.first.originalFingerprint, order['originalFingerprint']);
      }
      final op = (packet['operational'] as Map).cast<String, dynamic>(), wire = Transport()..data = op;
      final ref = WorkspacePurchaseReference(purchaseId: op['purchaseId'], storeId: op['storeId'], orderId: op['orderId'],
        originalFingerprint: op['originalFingerprint'], sourceRevision: op['sourceRevision']);
      final result = await AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire, account: op['viewerUserId']))
        .read(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: ref);
      expect(result, isNotNull); expect(result!.original.purchaser!.storeId, 'buying-store');
    });
  }
  if (Platform.environment['LF13_STARS_RECOVERY_LOG'] case final path?) {
    for (final phase in ['before-commit', 'after-commit']) {
      test('LF13-RECOVERY actual service original survives lost $phase response through strict client', () async {
        const marker = 'LF13_RECOVERY_PROJECTION=';
        final rows = File(path).readAsLinesSync().where((line) => line.contains(marker))
          .map((line) => (jsonDecode(line.substring(line.indexOf(marker) + marker.length)) as Map).cast<String, dynamic>())
          .where((row) => row['phase'] == phase).toList();
        expect(rows, hasLength(1));
        final capture = rows.single, raw = capture['recovered'] as Map<String, dynamic>;
        final command = (capture['command'] as Map).cast<String, dynamic>();
        final wire = Transport()..data = raw..status = 500;
        final gateway = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire, account: raw['viewerUserId']));
        final target = gateway.restoreProductFeedbackTarget(capture['target'], realm: raw['realm']);
        expect(target, isNotNull);
        Future<WorkspaceProductStarsResult?> request({required bool reconcile}) => gateway.submitProductStars(
          target: target!, stars: command['stars'], expectedRevision: command['expectedRevision'],
          operationId: command['operationId'], reconcile: reconcile);
        // Isolated failed transport followed by actual captured service readback;
        // never a fabricated saved result, new operation ID or runtime injection.
        expect(await request(reconcile: false), isNull);
        final original = Map<String, Object?>.of(wire.sent!);
        wire.status = 200;
        final recovered = await request(reconcile: true);
        expect(recovered, isNotNull);
        expect(wire.sent!['operation'], 'reconcileBuyerProductStars');
        expect(Map<String, Object?>.of(wire.sent!)..remove('operation'), command);
        expect(capture['receiptCountAfterRecovery'], capture['receiptCountAfterFailure']);
        if (phase == 'after-commit') {
          expect(recovered!.rating!.stars, command['stars']);
          expect(recovered.rating!.revision, command['expectedRevision'] + 1);
          expect(capture['receiptCountAfterFailure'], capture['receiptCountBefore'] + 1);
        } else {
          expect(recovered!.rating, isNull); expect(recovered.supersededByRevision, isNull);
          expect(capture['receiptCountAfterFailure'], capture['receiptCountBefore']);
          wire.data = capture['retried'] as Map<String, dynamic>;
          final retried = await request(reconcile: false);
          expect(retried!.rating!.stars, command['stars']);
          expect(wire.sent, original, reason: 'Explicit retry must use the unchanged original request.');
        }
        wire.data = raw;
        final other = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire, account: 'other-buyer'));
        expect(await other.submitProductStars(target: target!, stars: command['stars'],
          expectedRevision: command['expectedRevision'], operationId: command['operationId'], reconcile: true), isNull);
      });
    }
  }
  if (Platform.environment['LF_EXACT_PRODUCT_TARGET_LOG'] case final path?) {
    test('LF-STARS actual100-line backend target passes exact buyer-bound Dart read', () async {
      final entry = File(path).readAsLinesSync().singleWhere((l) => l.startsWith('LF_EXACT_PRODUCT_TARGET='));
      final data = (jsonDecode(entry.substring('LF_EXACT_PRODUCT_TARGET='.length)) as Map).cast<String, dynamic>();
      final raw = data['target'] as Map, listing = BuyV2PublicListingIdentity.fromJson(raw['purchasedListing'])!;
      final ref = WorkspacePurchaseReference(purchaseId: raw['purchaseId'], storeId: raw['storeId'], orderId: raw['orderId'],
        sourceRevision: raw['sourceRevision'], originalFingerprint: raw['originalFingerprint']);
      // Other money/quantity values are isolated client fixture facts, not backend acceptance.
      final line = WorkspacePurchasedSkuLine(lineId: raw['orderLineId'], skuId: listing.skuId,
        canonicalProductId: listing.canonicalProductId, verifiedPackId: listing.verifiedPackId, offerId: 'fixture-offer',
        offerRevision: 'fixture-revision', name: raw['productLabel'], packLabel: 'fixture-pack', quantityMilli: 1000,
        quantityUnit: 'pack', unitPriceMinor: 100, lineTotalMinor: 100, hasPublicListingSnapshot: true, publicListing: listing);
      final wire = Transport()..data = data;
      final gateway = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire, account: data['viewerUserId']));
      final target = await gateway.readProductFeedbackTarget(realm: data['realm'], reference: ref, line: line);
      expect(target, isNotNull); expect(target!.toJson(), raw);
      expect(wire.sent!['operation'], 'readBuyerProductFeedbackTarget');
      expect(wire.sent!['orderLineId'], raw['orderLineId']);
    });
  }
  test('LF-STARS one hundred retained originals cannot poison storage with attempt101', () async {
    final attempts = <String, BuyV2ProductStarsAttempt>{};
    for (var i = 0; i < 100; i++) {
      final target = feedbackTargetPage(orderLineId: 'held-line-$i')['targets'][0];
      attempts[target['id']] = BuyV2ProductStarsAttempt.fromJson({...starAttempt(), 'target': target, 'operationId': 'held-$i'});
    }
    final storage = StarsStateStore()..saved = BuyV2CustomerStateSnapshot(productStarAttempts: attempts);
    final (session, wire, store) = await starsSession(storage: storage);
    expect(await session.loadPrivateStars(), isTrue);
    final target = feedbackTargetPage()['targets'][0];
    expect(session.canSavePrivateStars(target['id']), isFalse);
    expect(await session.savePrivateStars(target['id'], 5), isFalse);
    expect(wire.requests.where((r) => r['operation'] == 'submitBuyerProductStars'), isEmpty);
    expect(store.saved!.productStarAttempts, hasLength(100));
    expect(session.privateStarAttempt(attempts.keys.first), isNotNull);
    final writes = store.writes;
    expect(session.submitSearch('retained rice'), isTrue);
    await session.retainedAccountState();
    expect(store.writes, greaterThan(writes));
    expect(store.saved!.recentSearches.values.expand((v) => v), contains('retained rice'));
    expect(store.saved!.productStarAttempts, hasLength(100));
  });
  test('LF-STARS selected purchased line loads directly without searching global pages and retains an uncertain original on read failure', () async {
    final (session, wire, store) = await starsSession();
    final reader = projectionGateway(Transport()..data = publicListingPurchaseResponse());
    final purchase = (await reader.readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', purchaseId: 'purchase-v2'))!;
    final line = purchase.orders.single.lines.first;
    final target = AuthenticatedWorkspaceOrderOperationsGateway(reader).restoreProductFeedbackTarget(feedbackTargetPage()['targets'][0], realm: 'evaluation')!;
    final respond = wire.respond!;
    wire.respond = (body) {
      if (body['operation'] == 'listBuyerProductFeedbackTargets') throw StateError('Must not page unrelated purchases');
      return respond(body);
    };
    expect(await session.loadPrivateStarsFor(target.reference, line), isTrue);
    expect(wire.requests.first['operation'], 'readBuyerProductFeedbackTarget');
    expect(wire.requests.first['orderLineId'], line.lineId);
    wire.fail = true;
    expect(await session.savePrivateStars(target.id, 2), isFalse);
    expect(await session.loadPrivateStarsFor(target.reference, line), isFalse);
    expect(session.privateStarAttempt(target.id)!.stars, 2);
    expect(store.saved!.productStarAttempts[target.id]!.stars, 2);
    expect(session.canSavePrivateStars(target.id), isFalse);
  });
  for (final fault in <String, void Function(Map<String, dynamic>)>{
    'realm': (d) => d['realm'] = 'production',
    'owner': (d) => d['viewerUserId'] = 'buyer-2',
    'role': (d) => d['viewerRole'] = 'seller',
    'extra': (d) => d['publicRating'] = 5,
    'line': (d) => d['target']['orderLineId'] = 'other-line',
    'name': (d) => d['target']['productLabel'] = 'Changed name',
    'fingerprint': (d) => d['target']['originalFingerprint'] = 'b' * 64,
  }.entries) {
    test('LF-STARS exact purchased-line reader rejects changed ${fault.key}', () async {
      final reader = projectionGateway(Transport()..data = publicListingPurchaseResponse());
      final purchase = (await reader.readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', purchaseId: 'purchase-v2'))!;
      final target = AuthenticatedWorkspaceOrderOperationsGateway(reader).restoreProductFeedbackTarget(feedbackTargetPage()['targets'][0], realm: 'evaluation')!;
      final changed = exactTargetResponse(); fault.value(changed);
      final gateway = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(Transport()..data = changed));
      expect(await gateway.readProductFeedbackTarget(realm: 'evaluation', reference: target.reference, line: purchase.orders.single.lines.first), isNull);
    });
  }
  test('LF-STARS real session loads independently of commerce and durably saves private stars', () async {
    final (session, wire, store) = await starsSession();
    expect(await session.loadPrivateStars(), isTrue);
    final target = session.privateStarTargets().single;
    expect(session.canSavePrivateStars(target.id), isTrue);
    expect(await session.savePrivateStars(target.id, 1), isTrue);
    expect(session.privateStarRating(target.id)!.stars, 1);
    expect(session.privateStarAttempt(target.id), isNull);
    expect(store.saved!.productStarAttempts, isEmpty);
    expect(wire.requests.where((r) => r['operation'] == 'submitBuyerProductStars'), hasLength(1));
  });
  test('LF-STARS session storage failure cannot dispatch and preserves original beside legacy draft', () async {
    final storage = StarsStateStore()..saved = const BuyV2CustomerStateSnapshot(reviewDrafts: {
      'legacy': BuyV2ProductReviewDraft(rating: 3, comment: 'Do not submit or remove')});
    final (session, wire, store) = await starsSession(storage: storage);
    expect(await session.loadPrivateStars(), isTrue);
    final target = session.privateStarTargets().single;
    store.refusedWrites.add(store.writes + 1);
    expect(await session.savePrivateStars(target.id, 2), isFalse);
    expect(wire.requests.where((r) => r['operation'] == 'submitBuyerProductStars'), isEmpty);
    expect(session.privateStarAttempt(target.id)!.stars, 2);
    expect(session.canSavePrivateStars(target.id), isFalse);
  });
  test('LF-STARS uncertain save survives session restart and retries only its original body', () async {
    final (session, wire, store) = await starsSession();
    expect(await session.loadPrivateStars(), isTrue); final target = session.privateStarTargets().single;
    final respond = wire.respond!;
    wire.respond = (body) => body['operation'] == 'submitBuyerProductStars' ? throw StateError('lost reply') : respond(body);
    expect(await session.savePrivateStars(target.id, 1), isFalse);
    final original = wire.requests.last;
    final (resumed, next, _) = await starsSession(storage: store);
    expect(resumed.privateStarAttempt(target.id)!.stars, 1);
    expect(await resumed.checkPrivateStars(target.id), isFalse);
    expect(next.requests.last['operation'], 'reconcileBuyerProductStars');
    expect(await resumed.checkPrivateStars(target.id, retryOriginal: true), isTrue);
    expect(next.requests.last, original);
    expect(store.saved!.productStarAttempts, isEmpty);
  });
  test('LF-STARS superseded attempt closes only after saved cleanup and requires fresh read', () async {
    final (session, wire, store) = await starsSession();
    expect(await session.loadPrivateStars(), isTrue); final target = session.privateStarTargets().single;
    final respond = wire.respond!;
    wire.respond = (body) => body['operation'] == 'submitBuyerProductStars' ? throw StateError('conflict') : respond(body);
    expect(await session.savePrivateStars(target.id, 1), isFalse);
    wire.respond = (body) => body['operation'] == 'reconcileBuyerProductStars'
      ? (starResult()..['operationId'] = body['operationId']..['state'] = 'superseded'..['rating'] = null
        ..['targetId'] = target.id..['observedRevision'] = 2) : respond(body);
    store.refusedWrites.add(store.writes + 1);
    expect(await session.checkPrivateStars(target.id), isFalse);
    expect(session.privateStarAttempt(target.id), isNotNull);
    expect(await session.checkPrivateStars(target.id), isTrue);
    expect(session.privateStarAttempt(target.id), isNull);
    expect(session.canSavePrivateStars(target.id), isFalse);
    expect(session.privateStarsMessage, contains('not accepted'));
    expect(store.saved!.productStarAttempts, isEmpty);
  });
  test('LF-STARS account retirement during cleanup hands back the original, not a cleared snapshot', () async {
    Object? life = 'active';
    final (session, _, store) = await starsSession(lifetime: () => life);
    await session.loadPrivateStars(); final target = session.privateStarTargets().single;
    final cleanupStarted = Completer<void>(), cleanup = Completer<void>();
    final cleanupSequence = store.writes + 2;
    store.beforeWrite = (n) async {if (n == cleanupSequence) {cleanupStarted.complete(); await cleanup.future;}};
    final save = session.savePrivateStars(target.id, 1);
    await cleanupStarted.future;
    life = 'retired';
    final retained = session.retainedAccountState();
    cleanup.complete();
    expect(await save, isFalse);
    final recovery = await retained;
    expect(recovery!.productStarAttempts[target.id]!.stars, 1);
    expect(session.privateStarTargets(), isEmpty);
  });
  for (final changed in ['pack', 'canonical']) {
    test('LF-STARS product entry rejects changed $changed while original purchase retains rating target', () async {
      final target = feedbackTargetPage()['targets'][0];
      final rawListing = Map<String, dynamic>.from(target['purchasedListing'] as Map);
      rawListing[changed == 'pack' ? 'verifiedPackId' : 'canonicalProductId'] = 'changed-current-facts';
      final listing = BuyV2PublicListingIdentity.fromJson(rawListing)!;
      final product = BuyV2Catalogue.allProducts.first.copyWith(id: listing.listingId, storeId: listing.storeId,
        canonicalId: listing.canonicalProductId, offerClass: listing.channel, publicListingIdentity: listing);
      final (session, _, _) = await starsSession(catalogue: StarsCatalogue(product));
      await session.restoreCommerce(); expect(await session.loadPrivateStars(), isTrue);
      expect(session.privateStarTargets(productId: product.id), isEmpty);
      expect(session.privateStarTargets(purchaseId: target['purchaseId']).single.id, target['id']);
    });
  }
  for (final scale in [1.0, 1.6]) {
    testWidgets('LF-STARS completed purchased item alone opens stars sheet at text scale $scale', (tester) async {
      final target = feedbackTargetPage()['targets'][0];
      final listing = BuyV2PublicListingIdentity.fromJson(target['purchasedListing'])!;
      final product = BuyV2Catalogue.allProducts.firstWhere((p) => p.id == 's-milk').copyWith(
        id: listing.listingId, storeId: listing.storeId, canonicalId: listing.canonicalProductId,
        publicListingIdentity: listing, offerClass: listing.channel);
      final storage = StarsStateStore()..saved = const BuyV2CustomerStateSnapshot(reviewDrafts: {
        'legacy': BuyV2ProductReviewDraft(rating: 2, comment: 'Must remain private and untouched')});
      final (session, wire, store) = await starsSession(storage: storage, catalogue: StarsCatalogue(product));
      await session.restoreCommerce();
      var completed = false;
      connectPurchaseFixture(wire, () => completed);
      tester.view.physicalSize = const Size(360, 780); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(theme: MoolTheme.light(),
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
        home: BuyV2Screen(session: session, productId: product.id)));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('buy-review-product-${product.id}')), findsNothing);
      expect(find.byKey(ValueKey('buy-report-product-${product.id}')), findsNothing);
      expect(find.text('Rate purchase'), findsNothing);
      session.openDestination(BuyV2Destination.orders); await tester.pumpAndSettle();
      await tester.tap(find.text('Saved purchase details')); await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('original-order-${target['orderId']}'))); await tester.pumpAndSettle();
      final button = find.byKey(ValueKey('purchase-rate-item-${target['orderId']}-${target['orderLineId']}'));
      expect(button, findsNothing);
      final update = find.text('Check order update');
      await tester.ensureVisible(update); await tester.tap(update); await tester.pumpAndSettle();
      expect(button, findsNothing, reason: 'No rating for an order without trusted completion');
      completed = true;
      await tester.ensureVisible(update); await tester.tap(update); await tester.pumpAndSettle();
      expect(button, findsOneWidget);
      final stale = tester.widget<TextButton>(button).onPressed!;
      completed = false;
      await tester.ensureVisible(update); await tester.tap(update); await tester.pumpAndSettle();
      stale(); await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('buy-product-review-sheet')), findsNothing);
      completed = true;
      await tester.ensureVisible(update); await tester.tap(update); await tester.pumpAndSettle();
      await tester.ensureVisible(button); await tester.pumpAndSettle();
      await tester.tap(button); await tester.pumpAndSettle();
      expect(find.text('Rate your purchase'), findsOneWidget);
      expect(find.text('Choose 1–5 stars. Only this Store can see your rating.'), findsOneWidget);
      expect(find.text('Private product rating'), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.textContaining('Must remain private'), findsNothing);
      final star = find.byKey(ValueKey('buy-private-star-${target['id']}-1'));
      final sheetScroll = find.descendant(of: find.byKey(const ValueKey('buy-product-review-fields-scroll')), matching: find.byType(Scrollable)).first;
      await tester.scrollUntilVisible(star, 120, scrollable: sheetScroll); await tester.tap(star); await tester.pumpAndSettle();
      final submit = find.byKey(const ValueKey('buy-submit-private-stars'));
      await tester.scrollUntilVisible(submit, 120, scrollable: sheetScroll); await tester.tap(submit); await tester.pumpAndSettle();
      expect(wire.requests.where((r) => r['operation'] == 'submitBuyerProductStars').single['stars'], 1);
      expect(store.saved!.reviewDrafts['legacy']!.comment, 'Must remain private and untouched');
      expect(store.saved!.productStarAttempts, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('LF-STARS retained purchased-line callback cannot enter a replacement buyer widget', (tester) async {
    final (_, wire, _) = await starsSession(); connectPurchaseFixture(wire, () => true);
    final target = feedbackTargetPage()['targets'][0], gatewayA = projectionGateway(wire), gatewayB = projectionGateway(wire, account: 'buyer-2');
    var calls = 0;
    Widget host(AuthenticatedWorkspaceOrderIdentityGateway gateway) => MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: WorkspacePurchaseOriginals(key: const ValueKey('same-originals-state'), gateway: gateway,
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', onRatePurchasedItem: (_, _, _) => calls++))));
    await tester.pumpWidget(host(gatewayA)); await tester.pumpAndSettle();
    await tester.tap(find.text('Saved purchase details')); await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('original-order-${target['orderId']}'))); await tester.pumpAndSettle();
    final update = find.text('Check order update'); await tester.ensureVisible(update); await tester.tap(update); await tester.pumpAndSettle();
    final action = find.byKey(ValueKey('purchase-rate-item-${target['orderId']}-${target['orderLineId']}'));
    final stale = tester.widget<TextButton>(action).onPressed!;
    await tester.pumpWidget(host(gatewayB)); await tester.pumpAndSettle();
    stale(); await tester.pumpAndSettle(); expect(calls, 0);
    expect(tester.takeException(), isNull);
  });
  for (final fault in <String, void Function(Map<String, dynamic>)>{
    'same revision': (r) => r['observedRevision'] = 0,
    'fractional revision': (r) => r['observedRevision'] = 2.5,
    'wrong target': (r) => r['targetId'] = 'other',
    'wrong account': (r) => r['viewerUserId'] = 'other',
    'wrong attempt': (r) => r['operationId'] = 'other',
    'non-null rating': (r) => r['rating'] = starResult()['rating'],
  }.entries) {
    test('LF-STARS rejects unproven supersession ${fault.key}', () async {
      final wire = Transport(), gateway = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire));
      final target = gateway.restoreProductFeedbackTarget(starAttempt()['target'], realm: 'evaluation')!;
      wire.data = starResult()..['state'] = 'superseded'..['rating'] = null..['targetId'] = target.id..['observedRevision'] = 2;
      fault.value(wire.data);
      expect(await gateway.submitProductStars(target: target, stars: 1, expectedRevision: 0, operationId: 'stars-save', reconcile: true), isNull);
    });
  }
  test('LF-STARS serialized original survives storage restart beside Cart and written drafts', () async {
    final prefs = StarsPreferences(), original = BuyV2ProductStarsAttempt.fromJson(starAttempt());
    BuyV2SharedPreferencesCustomerStateStore store() => BuyV2SharedPreferencesCustomerStateStore(prefs, ownerScope: 'host-stars-account');
    expect(await store().write(BuyV2CustomerStateSnapshot(cartQuantities: const {'saved-item': 2},
      reviewDrafts: const {'legacy-target': BuyV2ProductReviewDraft(rating: 3, comment: 'Retain this private draft')},
      productStarAttempts: {original.targetId: original})), isTrue);
    final restored = (await store().read())!;
    expect(restored.productStarAttempts[original.targetId]!.toJson(), original.toJson());
    expect(restored.reviewDrafts['legacy-target']!.comment, 'Retain this private draft'); expect(restored.cartQuantities, {'saved-item': 2});
    final exposed = original.target; exposed['productLabel'] = 'changed outside DTO';
    expect(original.target['productLabel'], feedbackTargetPage()['targets'][0]['productLabel']);
    final before = Map<String, String>.of(prefs.values);
    expect(await store().write(BuyV2CustomerStateSnapshot(productStarAttempts: {'wrong-target': original})), isFalse);
    expect(prefs.values, before);
    final key = prefs.values.keys.single, raw = (jsonDecode(prefs.values[key]!) as Map).cast<String, dynamic>();
    raw['productStarAttempts']['version'] = 2; prefs.values[key] = jsonEncode(raw); final malformed = prefs.values[key];
    await expectLater(store().read(), throwsFormatException); expect(prefs.values[key], malformed);
  });
  test('LF-STARS legacy snapshots omit star journal and invalid procurement cannot erase a supplied original', () async {
    final prefs = StarsPreferences(), store = BuyV2SharedPreferencesCustomerStateStore(prefs, ownerScope: 'host-stars-account');
    expect(await store.write(const BuyV2CustomerStateSnapshot()), isTrue);
    final key = prefs.values.keys.single, raw = (jsonDecode(prefs.values[key]!) as Map).cast<String, dynamic>();
    expect(raw.containsKey('productStarAttempts'), isFalse); expect((await store.read())!.productStarAttempts, isEmpty);
    final original = BuyV2ProductStarsAttempt.fromJson(starAttempt());
    raw['procurementDraft'] = {'invalid': true};
    raw['productStarAttempts'] = {'version': 1, 'records': {original.targetId: original.toJson()}};
    prefs.values[key] = jsonEncode(raw); final before = prefs.values[key];
    await expectLater(store.read(), throwsFormatException); expect(prefs.values[key], before);
  });
  for (final change in <String, void Function(Map<String, dynamic>)>{
    'schema float': (r) => r['version'] = 1.0,
    'comment': (r) => r['comment'] = 'not collected',
    'zero stars': (r) => r['stars'] = 0,
    'float stars': (r) => r['stars'] = 1.5,
    'negative revision': (r) => r['expectedRevision'] = -1,
    'wrong listing': (r) => r['target']['purchasedListing']['storeId'] = 'another-store',
    'missing completion': (r) => r['target'].remove('completedAt'),
    'private buyer': (r) => r['target']['buyerUserId'] = 'private',
  }.entries) {
    test('LF-STARS original command rejects ${change.key}', () {
      final raw = starAttempt(); change.value(raw); expect(() => BuyV2ProductStarsAttempt.fromJson(raw), throwsFormatException);
    });
  }
  test('LF-STARS saved stars read is independent from original receipts and restored target is buyer-bound', () async {
    final wire = Transport(), gateway = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire));
    final target = gateway.restoreProductFeedbackTarget(starAttempt()['target'], realm: 'evaluation')!;
    expect(gateway.restoreProductFeedbackTarget(starAttempt()['target'], realm: 'production'), isNull);
    expect(AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire, account: 'another-buyer'))
      .restoreProductFeedbackTarget(starAttempt()['target'], realm: 'evaluation'), isNull);
    wire.data = {'schemaVersion': 1, 'realm': 'evaluation', 'authNamespace': 'firebase-default', 'viewerRole': 'buyer',
      'viewerUserId': 'buyer-1', 'targetId': target.id, 'rating': null};
    final empty = await gateway.readProductStars(target); expect(empty, isNotNull); expect(empty!.rating, isNull);
    wire.data['rating'] = starResult()['rating'];
    expect((await gateway.readProductStars(target))!.rating!.revision, 1);
    wire.data['viewerUserId'] = 'another-buyer'; expect(await gateway.readProductStars(target), isNull);
    wire.data['viewerUserId'] = 'buyer-1'; wire.data['targetId'] = 'another-target'; expect(await gateway.readProductStars(target), isNull);
  });
  test('LF-STARS private submit uses limited-use token and read-only reconcile never submits', () async {
    final wire = Transport()..data = feedbackTargetPage();
    final identity = projectionGateway(wire), credentials = identity.credentials as Credentials;
    final gateway = AuthenticatedWorkspaceOrderOperationsGateway(identity);
    final target = (await gateway.listProductFeedbackTargets(realm: 'evaluation'))!.targets.single;
    wire.data = starResult();
    final saved = await gateway.submitProductStars(target: target, stars: 1, expectedRevision: 0, operationId: 'stars-save');
    expect(saved!.rating!.stars, 1);
    expect(wire.sent, {'operation': 'submitBuyerProductStars', 'targetId': target.id, 'stars': 1, 'expectedRevision': 0, 'operationId': 'stars-save'});
    expect(credentials.modes.last, SocialAppCheckTokenMode.limitedUse);
    wire.data = starResult()..['state'] = 'not_recorded'..['rating'] = null;
    final missing = await gateway.submitProductStars(target: target, stars: 1, expectedRevision: 0, operationId: 'stars-save', reconcile: true);
    expect(missing, isNotNull); expect(missing!.rating, isNull);
    expect(wire.sent!['operation'], 'reconcileBuyerProductStars'); expect(credentials.modes.last, SocialAppCheckTokenMode.standard);
    expect(await gateway.submitProductStars(target: target, stars: 1, expectedRevision: 0, operationId: 'stars-save'), isNull);
  });
  for (final fault in <String, void Function(Map<String, dynamic>)>{
    'public field': (r) => r['public'] = true,
    'comment': (r) => r['rating']['comment'] = 'not part of MVP',
    'wrong owner': (r) => r['viewerUserId'] = 'other',
    'wrong realm': (r) => r['realm'] = 'production',
    'wrong attempt': (r) => r['operationId'] = 'another-save',
    'float stars': (r) => r['rating']['stars'] = 1.0,
    'zero stars': (r) => r['rating']['stars'] = 0,
    'wrong stars': (r) => r['rating']['stars'] = 5,
    'wrong revision': (r) => r['rating']['revision'] = 2,
    'wrong line': (r) => r['rating']['target']['orderLineId'] = 'another-line',
    'wrong target': (r) => r['rating']['target']['id'] = 'feedback-${'b' * 64}',
    'future': (r) => r['rating']['updatedAt'] = '2099-01-01T00:00:00.000Z',
  }.entries) {
    test('LF-STARS rejects changed ${fault.key} without retry', () async {
      final wire = Transport()..data = feedbackTargetPage(), gateway = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire));
      final target = (await gateway.listProductFeedbackTargets(realm: 'evaluation'))!.targets.single;
      wire.data = starResult(); fault.value(wire.data);
      expect(await gateway.submitProductStars(target: target, stars: 1, expectedRevision: 0, operationId: 'stars-save'), isNull);
      expect(wire.calls, 2);
    });
  }
  test('LF-STARS private Store reader includes one-star ratings and no public/reply contract', () async {
    final wire = Transport()..data = {'schemaVersion': 1, 'realm': 'evaluation', 'authNamespace': 'firebase-default',
      'viewerRole': 'seller', 'viewerUserId': 'owner-1', 'storeId': 'store-one',
      'coverage': 'recorded_private_product_stars', 'ratings': [starResult()['rating']], 'nextCursor': null};
    final gateway = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire, account: 'owner-1'));
    expect((await gateway.listStoreProductStars(realm: 'evaluation', storeId: 'store-one'))!.ratings.single.stars, 1);
    wire.data['buyerUserId'] = 'private-leak';
    expect(await gateway.listStoreProductStars(realm: 'evaluation', storeId: 'store-one'), isNull);
    wire.data.remove('buyerUserId'); wire.data['storeId'] = 'another-store';
    expect(await gateway.listStoreProductStars(realm: 'evaluation', storeId: 'store-one'), isNull);
  });
  test('LF-STARS Store adapter resolves later identity and fences retired replies without exposing actions', () async {
    final wire = Transport()..data = {'schemaVersion': 1, 'realm': 'evaluation', 'authNamespace': 'firebase-default',
      'viewerRole': 'seller', 'viewerUserId': 'owner-1', 'storeId': 'store-one',
      'coverage': 'recorded_private_product_stars', 'ratings': [starResult()['rating']], 'nextCursor': null};
    AuthenticatedWorkspaceOrderIdentityGateway? reader;
    var realm = 'evaluation';
    final adapter = WorkspacePrivateStarsFeedbackAdapter(reader: () => reader, realm: () => realm);
    const scope = (account: 'owner-1', store: 'store-one');
    expect((await adapter.load(scope)).coverage, StoreFeedbackCoverage.unavailable); expect(wire.calls, 0);
    reader = projectionGateway(wire, account: 'owner-1');
    final page = await adapter.load(scope), value = page.entries.single;
    expect(value.stars, 1); expect(value.text, isEmpty); expect(value.authorLabel, 'Customer');
    expect(value.replyAudiences, isEmpty); expect(value.canReport, isFalse); expect(adapter.commandRecoveryReady, isFalse);
    expect(page.coverage, StoreFeedbackCoverage.partial);
    expect((await adapter.load((account: 'other', store: 'store-one'))).coverage, StoreFeedbackCoverage.unavailable);
    wire.pending = Completer<void>(); final pending = adapter.load(scope);
    for (var i = 0; i < 100 && wire.calls < 2; i++) {await Future<void>.delayed(Duration.zero);}
    expect(wire.calls, 2); reader = projectionGateway(wire, account: 'owner-1'); wire.pending!.complete();
    expect((await pending).coverage, StoreFeedbackCoverage.unavailable);
    realm = 'production'; wire.pending = null;
    expect((await adapter.load(scope)).coverage, StoreFeedbackCoverage.unavailable);
  });
  if (Platform.environment['LF_PRIVATE_PRODUCT_STARS_LOG'] case final path?) {
    test('LF-STARS actual saved private backend stars cross buyer and seller strict readers', () async {
      const marker = 'LF_PRIVATE_PRODUCT_STARS=';
      final rows = File(path).readAsLinesSync().where((line) => line.contains(marker)).toList(); expect(rows, hasLength(1));
      final data = (jsonDecode(rows.single.substring(rows.single.indexOf(marker) + marker.length)) as Map).cast<String, dynamic>();
      final buyer = data['buyer'] as Map<String, dynamic>, targetPage = {'schemaVersion': 1, 'realm': buyer['realm'],
        'authNamespace': 'firebase-default', 'viewerRole': 'buyer', 'viewerUserId': buyer['viewerUserId'],
        'coverage': 'indexed_recorded_completions', 'targets': [data['target']], 'nextCursor': null};
      final wire = Transport()..data = targetPage;
      final gateway = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire, account: buyer['viewerUserId']));
      final target = (await gateway.listProductFeedbackTargets(realm: buyer['realm']))!.targets.single;
      wire.data = buyer;
      final saved = await gateway.submitProductStars(target: target, stars: buyer['rating']['stars'],
        expectedRevision: buyer['rating']['revision'] - 1, operationId: buyer['operationId'], reconcile: true);
      expect(saved!.rating!.stars, 1);
      final seller = (data['seller'] as Map).cast<String, dynamic>(); wire.data = seller;
      final privatePage = await AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire, account: seller['viewerUserId']))
        .listStoreProductStars(realm: seller['realm'], storeId: seller['storeId']);
      expect(privatePage, isNotNull); expect(privatePage!.ratings.any((r) => r.target.id == target.id && r.stars == 1), isTrue);
    });
  }
  test('LF-FEEDBACK target page retains full historical identity without granting publication or commerce', () async {
    final data = feedbackTargetPage(), wire = Transport()..data = data;
    final page = await AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire)).listProductFeedbackTargets(realm: 'evaluation');
    expect(page, isNotNull); expect(page!.targets.single.productId, data['targets'][0]['productId']);
    expect(page.targets.single.purchasedListing.toJson(), data['targets'][0]['purchasedListing']);
    expect(wire.sent, {'operation': 'listBuyerProductFeedbackTargets', 'limit': 5, 'cursor': null});
    wire.data = feedbackTargetPage()..['targets'] = <Object>[];
    expect((await AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire)).listProductFeedbackTargets(realm: 'evaluation'))!.targets, isEmpty);
  });
  for (final fault in <String, void Function(Map<String, dynamic>)>{
    'schema': (d) => d['schemaVersion'] = 1.0,
    'realm': (d) => d['realm'] = 'production',
    'namespace': (d) => d['authNamespace'] = 'tenant-other',
    'viewer': (d) => d['viewerUserId'] = 'other-account',
    'role': (d) => d['viewerRole'] = 'seller',
    'coverage': (d) => d['coverage'] = 'all_purchases',
    'null targets': (d) => d['targets'] = null,
    'missing listing': (d) => d['targets'][0].remove('purchasedListing'),
    'changed ID': (d) => d['targets'][0]['id'] = 'feedback-${'b' * 64}',
    'changed line': (d) => d['targets'][0]['orderLineId'] = 'another-line',
    'changed Store': (d) => d['targets'][0]['storeId'] = 'another-store',
    'changed canonical': (d) => d['targets'][0]['purchasedListing']['canonicalProductId'] = 'another-product',
    'changed pack': (d) => d['targets'][0]['purchasedListing']['verifiedPackId'] = 'another-pack',
    'changed completion': (d) => d['targets'][0]['completionRevision'] = 'another-completion',
    'future completion': (d) => d['targets'][0]['completedAt'] = '2099-10-16T12:00:00.000Z',
    'duplicate target': (d) => (d['targets'] as List).add(d['targets'][0]),
    'private proof': (d) => d['targets'][0]['proof'] = 'private-proof',
    'public permission': (d) => d['canPublish'] = true,
    'empty cursor': (d) => d['nextCursor'] = '',
  }.entries) {
    test('LF-FEEDBACK strict target page rejects ${fault.key}', () async {
      final data = feedbackTargetPage(); fault.value(data);
      expect(await AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(Transport()..data = data))
        .listProductFeedbackTargets(realm: 'evaluation'), isNull);
    });
  }
  test('LF-FEEDBACK retired A B A account cannot admit target results or issue another call', () async {
    Object? generation = Object(); final wire = Transport()..data = feedbackTargetPage()..pending = Completer<void>();
    final gateway = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire, lifetime: () => generation));
    final pending = gateway.listProductFeedbackTargets(realm: 'evaluation');
    for (var i = 0; i < 100 && wire.calls == 0; i++) {await Future<void>.delayed(Duration.zero);}
    expect(wire.calls, 1); generation = Object(); generation = Object(); wire.pending!.complete();
    expect(await pending, isNull); expect(await gateway.listProductFeedbackTargets(realm: 'evaluation'), isNull); expect(wire.calls, 1);
  });
  if (Platform.environment['LF_PRODUCT_TARGET_PROJECTION_LOG'] case final path?) {
    test('LF-FEEDBACK actual completion producer target pages cross strict private Dart reader', () async {
      const marker = 'LF_PRODUCT_TARGET_PROJECTION=';
      final rows = File(path).readAsLinesSync().where((line) => line.contains(marker)).toList();
      expect(rows, hasLength(2)); var supplied = 0, absent = 0;
      for (final row in rows) {
        final data = (jsonDecode(row.substring(row.indexOf(marker) + marker.length)) as Map).cast<String, dynamic>();
        final page = await AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(Transport()..data = data, account: data['viewerUserId']))
          .listProductFeedbackTargets(realm: 'evaluation');
        expect(page, isNotNull); expect(page!.targets.length, (data['targets'] as List).length);
        if (page.targets.isEmpty) {absent++;} else {supplied++; expect(page.targets.single.purchasedListing.toJson(), data['targets'][0]['purchasedListing']);}
      }
      expect(supplied, 1); expect(absent, 1);
    });
  }
  for (final role in WorkspaceOrderIdentityRole.values) {
    test('LF-COMMODITY-ORIGINAL frozen direct price ${role.name} remains readable after expiry', () async {
      final data = commodityPurchaseResponse(role: role.name), order = data['orders'][0];
      final saved = await projectionGateway(Transport()..data = data, account: data['viewerUserId'])
        .readPurchaseProjection(role: role, realm: 'evaluation', purchaseId: data['purchaseId'],
          storeId: role == WorkspaceOrderIdentityRole.seller ? order['storeId'] : null,
          orderId: role == WorkspaceOrderIdentityRole.seller ? order['orderId'] : null);
      expect(saved, isNotNull); expect(saved!.orders.single.factsVersion, 10);
      final line = saved.orders.single.lines.single;
      expect(line.toJson(), order['original']['lines'][0]);
      expect(line.commodityPriceSnapshot!.agreedAt, DateTime.utc(2026, 10, 1, 12, 10));
      expect(saved.orders.single.supplierQuote, isNull);
      expect(saved.orders.single.totals, order['original']['totals']);
      final copy = line.commodityPriceSnapshot!.toJson()..['priceMinor'] = 1;
      expect(copy['priceMinor'], 1); expect(line.commodityPriceSnapshot!.toJson()['priceMinor'], line.unitPriceMinor);
      order['original']['lines'][0]['commodityPriceSnapshot']['incrementPacks'] = 1000000;
      rehashPurchaseOrder(order);
      expect(await projectionGateway(Transport()..data = data, account: data['viewerUserId']).readPurchaseProjection(
        role: role, realm: 'evaluation', purchaseId: data['purchaseId'],
        storeId: role == WorkspaceOrderIdentityRole.seller ? order['storeId'] : null,
        orderId: role == WorkspaceOrderIdentityRole.seller ? order['orderId'] : null), isNotNull);
    });
    for (final scale in [1.0, 2.0]) {
      testWidgets('LF-COMMODITY-ORIGINAL purchased disclosure ${role.name} scale=$scale', (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 844)); addTearDown(() => tester.binding.setSurfaceSize(null));
        final data = commodityPurchaseResponse(role: role.name), order = data['orders'][0], refs = referenceResponse(role: role.name);
        refs['references'][0]['originalFingerprint'] = order['originalFingerprint'];
        final wire = Transport()..respond = (body) => (body['operation'] as String).startsWith('list') ? refs : data;
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: SingleChildScrollView(child: WorkspacePurchaseOriginals(gateway: projectionGateway(wire, account: data['viewerUserId']),
            role: role, realm: 'evaluation', storeId: role == WorkspaceOrderIdentityRole.seller ? order['storeId'] : null))))));
        await tester.tap(find.text('Saved purchase details')); await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('original-order-${order['orderId']}'))); await tester.pumpAndSettle();
        final disclosure = find.byKey(const ValueKey('original-commodity-price-line-one'));
        await tester.ensureVisible(disclosure); await tester.pumpAndSettle();
        final text = tester.widget<Text>(disclosure);
        expect(text.data, contains('Agreed supplier price ₹100.51 per selling pack'));
        expect(text.data, contains('Supplier confirmed')); expect(text.data, isNot(contains('pending')));
        expect(text.maxLines, isNull); expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  for (final entry in <String, void Function(Map<String, dynamic>)>{
    'missing': (l) => l.remove('commodityPriceSnapshot'),
    'null Bulk': (l) => l['commodityPriceSnapshot'] = null,
    'version': (l) => l['commodityPriceSnapshot']['schemaVersion'] = 2,
    'revision': (l) => l['commodityPriceSnapshot']['confirmationRevision'] = 3,
    'terms': (l) => l['commodityPriceSnapshot']['termsRevision'] = 'commodity-2-BBBBBBBBBBBBBBBB',
    'agreement expiry': (l) => l['commodityPriceSnapshot']['agreedAt'] = l['commodityPriceSnapshot']['validUntil'],
    'future confirmation': (l) => l['commodityPriceSnapshot']['confirmedAt'] = '2026-10-01T13:00:00.000Z',
    'minimum': (l) => l['commodityPriceSnapshot']['minimumPacks'] = 2,
    'tier price': (l) => l['commodityPriceSnapshot']['priceMinor'] = 1,
    'measured unit': (l) => l['quantityUnit'] = 'L',
    'paid claim': (l) => l['commodityPriceSnapshot']['paid'] = true,
  }.entries) {
    test('LF-COMMODITY-ORIGINAL rejects ${entry.key} even with a recomputed fingerprint', () async {
      final data = commodityPurchaseResponse(), order = data['orders'][0] as Map<String,dynamic>;
      entry.value(order['original']['lines'][0]); rehashPurchaseOrder(order);
      expect(await projectionGateway(Transport()..data = data).readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', purchaseId: data['purchaseId']), isNull);
    });
  }
  test('LF-COMMODITY-ORIGINAL mixed quote covers exactly its legacy Bulk subset', () async {
    final data = supplierQuotePurchaseResponse(), order = data['orders'][0] as Map<String,dynamic>;
    data['schemaVersion'] = 10; order['factsVersion'] = 10;
    final lines = order['original']['lines'] as List;
    for (final l in lines) { l['supplierTaxSnapshot'] = null; l['commodityPriceSnapshot'] = null; }
    final direct = commodityPurchaseResponse()['orders'][0]['original']['lines'][0] as Map<String,dynamic>;
    direct['lineId'] = 'z-direct-line'; direct['skuId'] = 'direct-sku'; direct['publicListing']['skuId'] = 'direct-sku';
    direct['publicListing']['listingId'] = 'listing-${sha256.convert(utf8.encode(jsonEncode([1,'evaluation',order['storeId'],'direct-sku','bulk'])))}';
    lines.add(direct); order['original']['totals']['itemsMinor'] += direct['lineTotalMinor'];
    order['original']['totals']['totalMinor'] += direct['lineTotalMinor']; rehashPurchaseOrder(order);
    Future<WorkspacePurchaseProjection?> read() => projectionGateway(Transport()..data = data).readPurchaseProjection(
      role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: data['purchaseId']);
    expect(await read(), isNotNull);
    order['original']['supplierQuote']['lines'].add({'lineId': direct['lineId'], 'quoteLineId': 'quote-direct-line'});
    rehashPurchaseOrder(order); expect(await read(), isNull);
  });
  test('LF-COMMODITY-ORIGINAL direct Wholesale requires its confirmed-price provenance', () async {
    final data = commodityPurchaseResponse(), order = data['orders'][0] as Map<String,dynamic>, line = order['original']['lines'][0];
    line['publicListing']['channel'] = 'wholesale';
    line['publicListing']['listingId'] = 'listing-${sha256.convert(utf8.encode(jsonEncode(
      [1,'evaluation',order['storeId'],line['skuId'],'wholesale'])))}';
    rehashPurchaseOrder(order);
    Future<WorkspacePurchaseProjection?> read() => projectionGateway(Transport()..data = data).readPurchaseProjection(
      role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: data['purchaseId']);
    expect(await read(), isNotNull);
    line['commodityPriceSnapshot'] = null; rehashPurchaseOrder(order); expect(await read(), isNull);
  });
  if (Platform.environment['LF_COMMODITY_ORIGINAL_LOG'] case final path?) {
    test('LF-COMMODITY-ORIGINAL actual restarted materializer crosses buyer Store and operational decoders', () async {
      const marker = 'LF_COMMODITY_ORIGINAL_PROJECTION=';
      final row = File(path).readAsLinesSync().singleWhere((line) => line.startsWith(marker));
      final packet = (jsonDecode(row.substring(marker.length)) as Map).cast<String,dynamic>();
      for (final data in [packet['buyer'], ...(packet['sellers'] as List)]) {
        final role = data['viewerRole'] == 'buyer' ? WorkspaceOrderIdentityRole.buyer : WorkspaceOrderIdentityRole.seller;
        final order = data['orders'][0];
        final saved = await projectionGateway(Transport()..data = data, account: data['viewerUserId']).readPurchaseProjection(
          role: role, realm: 'evaluation', purchaseId: data['purchaseId'],
          storeId: role == WorkspaceOrderIdentityRole.seller ? order['storeId'] : null,
          orderId: role == WorkspaceOrderIdentityRole.seller ? order['orderId'] : null);
        expect(saved, isNotNull);
        for (final original in saved!.orders) {
          expect(original.factsVersion, 10);
          final raw = (data['orders'] as List).singleWhere((o) => o['orderId'] == original.orderId);
          for (final line in original.lines) expect(line.toJson(), (raw['original']['lines'] as List).singleWhere((l) => l['lineId'] == line.lineId));
        }
      }
      for (final data in packet['operational'] as List) {
        final role = data['viewerRole'] == 'buyer' ? WorkspaceOrderIdentityRole.buyer : WorkspaceOrderIdentityRole.seller;
        final reference = WorkspacePurchaseReference(purchaseId: data['purchaseId'], storeId: data['storeId'], orderId: data['orderId'],
          sourceRevision: data['sourceRevision'], originalFingerprint: data['originalFingerprint']);
        final saved = await AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(Transport()..data = data,
          account: data['viewerUserId'])).read(role: role, realm: 'evaluation', reference: reference);
        expect(saved, isNotNull); expect(saved!.original.factsVersion, 10);
        expect(saved.original.lines.map((l) => l.toJson()), data['original']['lines']);
      }
    });
  }
  for (final role in WorkspaceOrderIdentityRole.values) {
    for (final declaration in [null, {'version': 2, 'rateBasisPoints': 0, 'basis': 'additional'},
      {'version': 2, 'rateBasisPoints': 500, 'basis': 'included'}, {'version': 1, 'amountMinor': 7, 'basis': 'additional'}]) {
      test('LF-GST-ORIGINAL strict frozen source ${role.name} declaration=$declaration', () async {
        final data = supplierTaxPurchaseResponse(role: role.name, declaration: declaration), order = data['orders'][0];
        final saved = await projectionGateway(Transport()..data = data, account: data['viewerUserId'])
          .readPurchaseProjection(role: role, realm: 'evaluation', purchaseId: data['purchaseId'],
            storeId: role == WorkspaceOrderIdentityRole.seller ? order['storeId'] : null,
            orderId: role == WorkspaceOrderIdentityRole.seller ? order['orderId'] : null);
        expect(saved, isNotNull); expect(saved!.orders.single.factsVersion, 9);
        expect(saved.orders.single.lines.single.toJson()['supplierTaxSnapshot'], order['original']['lines'][0]['supplierTaxSnapshot']);
        expect(saved.orders.single.totals, order['original']['totals']);
      });
    }
  }
  for (final entry in <String, void Function(Map<String, dynamic>)>{
    'missing': (l) => l.remove('supplierTaxSnapshot'),
    'boolean': (l) => l['supplierTaxSnapshot'] = false,
    'revision': (l) => l['supplierTaxSnapshot']['termsRevision'] = '',
    'time': (l) => l['supplierTaxSnapshot']['observedAt'] = 'invalid',
    'reversed expiry': (l) => l['supplierTaxSnapshot']['expiresAt'] = '2026-10-01T11:00:00.000Z',
    'null declaration': (l) => l['supplierTaxSnapshot']['declaration'] = null,
    'fractional rate': (l) => l['supplierTaxSnapshot']['declaration']['rateBasisPoints'] = 5.5,
    'overflow': (l) => l['supplierTaxSnapshot']['declaration']['rateBasisPoints'] = 10001,
    'amount overflow': (l) => l['supplierTaxSnapshot']['declaration'] = {'version': 1, 'amountMinor': 1000000000001, 'basis': 'additional'},
    'unbound amount unit': (l) {
      l['quantityUnit'] = 'kg';
      l['supplierTaxSnapshot']['declaration'] = {'version': 1, 'amountMinor': 7, 'basis': 'additional'};
    },
    'extra amount': (l) => l['supplierTaxSnapshot']['declaration']['amountMinor'] = 7,
    'claim': (l) => l['supplierTaxSnapshot']['verifiedRegistration'] = true,
  }.entries) {
    test('LF-GST-ORIGINAL strict read rejects ${entry.key} despite rehashed original', () async {
      final data = supplierTaxPurchaseResponse(), order = data['orders'][0];
      entry.value(order['original']['lines'][0] as Map<String, dynamic>); rehashPurchaseOrder(order);
      expect(await projectionGateway(Transport()..data = data).readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', purchaseId: data['purchaseId']), isNull);
    });
  }
  for (final unit in ['kg', 'L', 'count']) {
    test('LF-GST-ORIGINAL percentage retains the ordered $unit basis', () async {
      final data = supplierTaxPurchaseResponse(), order = data['orders'][0];
      order['original']['lines'][0]['quantityUnit'] = unit; rehashPurchaseOrder(order);
      final result = await projectionGateway(Transport()..data = data).readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', purchaseId: data['purchaseId']);
      expect(result, isNotNull); expect(result!.orders.single.lines.single.quantityUnit, unit);
    });
  }
  if (Platform.environment['LF_GST_ORIGINAL_LOG'] case final path?) {
    test('LF-GST-ORIGINAL consumes actual persisted materializer buyer and Store readbacks', () async {
      const marker = 'LF_GST_ORIGINAL_PROJECTION=';
      final row = File(path).readAsLinesSync().singleWhere((line) => line.startsWith(marker));
      final packet = (jsonDecode(row.substring(marker.length)) as Map).cast<String, dynamic>();
      var unknown = 0, zero = 0, known = 0, legacy = 0;
      for (final data in [packet['buyer'], ...(packet['sellers'] as List)]) {
        final role = data['viewerRole'] == 'buyer' ? WorkspaceOrderIdentityRole.buyer : WorkspaceOrderIdentityRole.seller,
          order = data['orders'][0];
        final saved = await projectionGateway(Transport()..data = data, account: data['viewerUserId'])
          .readPurchaseProjection(role: role, realm: 'evaluation', purchaseId: data['purchaseId'],
            storeId: role == WorkspaceOrderIdentityRole.seller ? order['storeId'] : null,
            orderId: role == WorkspaceOrderIdentityRole.seller ? order['orderId'] : null);
        expect(saved, isNotNull);
        for (final original in saved!.orders) {
          expect(original.factsVersion, 9);
          final raw = (data['orders'] as List).singleWhere((o) => o['orderId'] == original.orderId);
          expect(original.totals, raw['original']['totals']);
          for (final line in original.lines) {
            final before = (raw['original']['lines'] as List).singleWhere((l) => l['lineId'] == line.lineId);
            expect(line.toJson(), before);
            final snapshot = line.supplierTaxSnapshot;
            if (snapshot == null) {unknown++;} else if (snapshot.legacyAmount != null) {legacy++;}
            else if (snapshot.gst!.rateBasisPoints == 0) {zero++;} else {known++;}
          }
        }
      }
      expect([unknown, zero, known, legacy], [2, 2, 4, 2]);
    });
  }
  for (final role in WorkspaceOrderIdentityRole.values) {
    for (final scale in [1.0, 2.0]) {
      for (final unknown in [false, true]) {
        testWidgets('LF-GST-ORIGINAL buyer and Store disclose frozen terms ${role.name} scale=$scale unknown=$unknown', (tester) async {
          await tester.binding.setSurfaceSize(scale == 1 ? const Size(320, 844) : const Size(640, 360));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final data = unknown ? supplierTaxPurchaseResponse(role: role.name, declaration: null) : supplierTaxPurchaseResponse(role: role.name),
            order = data['orders'][0], refs = referenceResponse(role: role.name);
          refs['references'][0]['originalFingerprint'] = order['originalFingerprint'];
          final wire = Transport()..respond = (body) => (body['operation'] as String).startsWith('list') ? refs : data;
          await tester.pumpWidget(MaterialApp(home: Scaffold(body: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: SingleChildScrollView(child: WorkspacePurchaseOriginals(
              gateway: projectionGateway(wire, account: data['viewerUserId']), role: role, realm: 'evaluation',
              storeId: role == WorkspaceOrderIdentityRole.seller ? order['storeId'] : null))))));
          await tester.tap(find.text('Saved purchase details')); await tester.pumpAndSettle();
          await tester.tap(find.byKey(ValueKey('original-order-${order['orderId']}'))); await tester.pumpAndSettle();
          final declaration = find.byKey(const ValueKey('original-supplier-gst-line-one'));
          await tester.ensureVisible(declaration); await tester.pumpAndSettle();
          expect(tester.widget<Text>(declaration).data, unknown ? 'Supplier GST not recorded for this purchase'
            : 'Supplier-declared GST 5% · Included in the ordered price');
          expect(tester.widget<Text>(declaration).maxLines, isNull);
          expect(wire.requests.every((r) => (r['operation'] as String).startsWith('read') || (r['operation'] as String).startsWith('list')), isTrue);
          expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
  for (final role in WorkspaceOrderIdentityRole.values) {
    for (final unknown in [false, true]) {
      test('LF-BULK ORIGINAL strict purchased agreement version8 ${role.name} unknown=$unknown', () async {
        final data = supplierQuotePurchaseResponse(role: role.name, unknown: unknown), order = data['orders'][0];
        final result = await projectionGateway(Transport()..data = data, account: data['viewerUserId'])
          .readPurchaseProjection(role: role, realm: 'evaluation', purchaseId: data['purchaseId'],
            storeId: role == WorkspaceOrderIdentityRole.seller ? order['storeId'] : null,
            orderId: role == WorkspaceOrderIdentityRole.seller ? order['orderId'] : null);
        expect(result, isNotNull); final saved = result!.orders.single;
        expect(saved.factsVersion, 8); expect(saved.hasSupplierQuoteSnapshot, isTrue);
        expect(saved.supplierQuote?.toJson(), order['original']['supplierQuote']);
        if (!unknown) {
          final quote = saved.supplierQuote!;
          expect(quote.merchandiseMinor, saved.totals['itemsMinor']);
          expect(() => quote.quoteLineByPurchasedLineId['other-line'] = 'other', throwsUnsupportedError);
          final copy = quote.toJson(); copy['merchandiseMinor'] = 1;
          expect(quote.merchandiseMinor, saved.totals['itemsMinor']);
        }
      });
    }
  }
  for (final entry in <String, void Function(Map<String, dynamic>)>{
    'missing field': (d) => (d['orders'][0]['original'] as Map).remove('supplierQuote'),
    'missing Bulk agreement': (d) => d['orders'][0]['original']['supplierQuote'] = null,
    'foreign realm': (d) => d['orders'][0]['original']['supplierQuote']['realm'] = 'production',
    'false revision': (d) => d['orders'][0]['original']['supplierQuote']['acceptedRevision'] = 20,
    'invalid expiry': (d) => d['orders'][0]['original']['supplierQuote']['validUntil'] = '2026-10-19T00:00:00.000Z',
    'foreign purchased line': (d) => d['orders'][0]['original']['supplierQuote']['lines'][0]['lineId'] = 'other-line',
    'wrong subtotal': (d) => d['orders'][0]['original']['supplierQuote']['merchandiseMinor'] = 1,
    'private identity leak': (d) => d['orders'][0]['original']['supplierQuote']['buyerUserId'] = 'private-id',
  }.entries) {
    test('LF-BULK ORIGINAL rejects ${entry.key} despite recomputed envelope fingerprint', () async {
      final data = supplierQuotePurchaseResponse(); entry.value(data); rehashPurchaseOrder(data['orders'][0]);
      expect(await projectionGateway(Transport()..data = data).readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', purchaseId: data['purchaseId']), isNull);
    });
  }
  if (Platform.environment['LF_BULK_PURCHASE_LOG'] case final path?) {
    test('LF-BULK ORIGINAL reads actual persisted buyer and Store agreement projections', () async {
      const marker = 'LF_BULK_PURCHASE_PROJECTION=';
      final row = File(path).readAsLinesSync().singleWhere((line) => line.startsWith(marker));
      final packet = (jsonDecode(row.substring(marker.length)) as Map).cast<String, dynamic>();
      for (final data in [packet['buyer'], packet['seller']]) {
        final role = data['viewerRole'] == 'buyer' ? WorkspaceOrderIdentityRole.buyer : WorkspaceOrderIdentityRole.seller,
          order = data['orders'][0];
        final saved = await projectionGateway(Transport()..data = data, account: data['viewerUserId'])
          .readPurchaseProjection(role: role, realm: 'evaluation', purchaseId: data['purchaseId'],
            storeId: role == WorkspaceOrderIdentityRole.seller ? order['storeId'] : null,
            orderId: role == WorkspaceOrderIdentityRole.seller ? order['orderId'] : null);
        expect(saved, isNotNull); expect(saved!.orders.single.factsVersion, 8);
        expect(saved.orders.single.supplierQuote!.toJson(), order['original']['supplierQuote']);
      }
    });
  }
  for (final role in WorkspaceOrderIdentityRole.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('LF-BULK ORIGINAL buyer and Store navigate to frozen quote prices ${role.name} scale=$scale', (tester) async {
        final data = supplierQuotePurchaseResponse(role: role.name), order = data['orders'][0],
          refs = referenceResponse(role: role.name);
        refs['references'][0]['originalFingerprint'] = order['originalFingerprint'];
        final wire = Transport()..respond = (body) => switch (body['operation']) {
          'listBuyerPurchaseReferences' || 'listStorePurchaseReferences' => refs,
          'readBuyerPurchaseProjection' || 'readStorePurchaseProjection' => data,
          _ => throw StateError('No payment or operational fixture'),
        };
        await tester.pumpWidget(MaterialApp(home: MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: SingleChildScrollView(child: WorkspacePurchaseOriginals(
            gateway: projectionGateway(wire, account: data['viewerUserId']), role: role, realm: 'evaluation',
            storeId: role == WorkspaceOrderIdentityRole.seller ? order['storeId'] : null))))));
        await tester.tap(find.text('Saved purchase details')); await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('original-order-${order['orderId']}'))); await tester.pumpAndSettle();
        final agreed = find.byKey(ValueKey('original-supplier-quote-${order['orderId']}'));
        await tester.ensureVisible(agreed); await tester.pumpAndSettle();
        expect(agreed, findsOneWidget); expect(find.text('Agreed Bulk product prices'), findsOneWidget);
        expect(find.text('From the supplier quote accepted for this order.'), findsOneWidget);
        expect(find.text('Pay now'), findsNothing); expect(find.text('Credit approved'), findsNothing);
        expect(wire.requests.every((body) => (body['operation'] as String).startsWith('read') ||
          (body['operation'] as String).startsWith('list')), isTrue);
        expect(tester.takeException(), isNull); await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  for (final role in WorkspaceOrderIdentityRole.values) {
    for (final unknown in [false, true]) {
      test('LF-CONTEXT strict original reader retains version7 including null ${role.name} unknown=$unknown', () async {
        final data = fulfilmentPurchaseResponse(role: role.name, unknown: unknown), wire = Transport()..data = data;
        final result = await projectionGateway(wire, account: role == WorkspaceOrderIdentityRole.buyer ? 'buyer-1' : 'owner-1')
          .readPurchaseProjection(role: role, realm: 'evaluation', purchaseId: data['purchaseId'],
            storeId: role == WorkspaceOrderIdentityRole.seller ? 'store-one' : null,
            orderId: role == WorkspaceOrderIdentityRole.seller ? data['orders'][0]['orderId'] : null);
        expect(result, isNotNull);
        expect(result!.orders.single.factsVersion, 7);
        final saved = result.orders.single;
        expect(saved.hasFulfilmentContextSnapshot, isTrue);
        expect(saved.fulfilmentContext?.toJson(), data['orders'][0]['original']['fulfilmentContext']);
        if (!unknown) expect(() => saved.fulfilmentContext!.instructions['another-line'] = 'Changed', throwsUnsupportedError);
      });
    }
  }
  for (final fault in <String, void Function(Map<String, dynamic>)>{
    'missing context': (d) => (d['orders'][0]['original'] as Map).remove('fulfilmentContext'),
    'old version': (d) {d['schemaVersion'] = 6; d['orders'][0]['factsVersion'] = 6;},
    'foreign line': (d) => d['orders'][0]['original']['fulfilmentContext']['instructions'][0]['lineId'] = 'another-Store-line',
    'duplicate note': (d) {final notes = d['orders'][0]['original']['fulfilmentContext']['instructions'] as List; notes.add(notes[0]);},
    'empty note': (d) => d['orders'][0]['original']['fulfilmentContext']['instructions'][0]['text'] = '',
    'account identifier': (d) => d['orders'][0]['original']['fulfilmentContext']['recipient']['userId'] = 'private-id',
    'address book identifier': (d) => d['orders'][0]['original']['fulfilmentContext']['address']['id'] = 'address-id',
    'invalid phone': (d) => d['orders'][0]['original']['fulfilmentContext']['recipient']['phone'] = 'not-a-phone',
    'control character': (d) => d['orders'][0]['original']['fulfilmentContext']['instructions'][0]['text'] = 'note\u0000',
    'collection address': (d) => d['orders'][0]['original']['fulfilmentContext']['method'] = 'collection',
  }.entries) {
    test('LF-CONTEXT strict reader rejects rehashed ${fault.key}', () async {
      final data = fulfilmentPurchaseResponse(); fault.value(data); rehashPurchaseOrder(data['orders'][0]);
      expect(await projectionGateway(Transport()..data = data).readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', purchaseId: data['purchaseId']), isNull);
    });
  }
  if (Platform.environment['LF10_CONTEXT_LOG'] case final path?) {
    test('LF-CONTEXT actual saved two-Store and operational projections retain exact private details', () async {
      const marker = 'LF10_CONTEXT_PROJECTION=';
      final row = File(path).readAsLinesSync().singleWhere((line) => line.startsWith(marker));
      final captured = (jsonDecode(row.substring(marker.length)) as Map).cast<String, dynamic>();
      for (final data in [captured['buyer'], ...captured['seller'] as List]) {
        final wire = Transport()..data = data, role = data['viewerRole'] == 'buyer' ? WorkspaceOrderIdentityRole.buyer : WorkspaceOrderIdentityRole.seller;
        final order = data['orders'][0];
        final result = await projectionGateway(wire, account: data['viewerUserId']).readPurchaseProjection(role: role,
          realm: 'evaluation', purchaseId: data['purchaseId'], storeId: role == WorkspaceOrderIdentityRole.seller ? order['storeId'] : null,
          orderId: role == WorkspaceOrderIdentityRole.seller ? order['orderId'] : null);
        expect(result, isNotNull);
        for (final saved in result!.orders) {
          final raw = (data['orders'] as List).singleWhere((v) => v['orderId'] == saved.orderId);
          expect(saved.factsVersion, 7); expect(saved.fulfilmentContext!.toJson(), raw['original']['fulfilmentContext']);
          expect(saved.lines.any((line) => saved.fulfilmentContext!.instructions.containsKey(line.lineId)), isTrue);
        }
      }
      for (final data in captured['operations'] as List) {
        final reference = WorkspacePurchaseReference(purchaseId: data['purchaseId'], storeId: data['storeId'], orderId: data['orderId'],
          originalFingerprint: data['originalFingerprint'], sourceRevision: data['sourceRevision']);
        final gateway = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(Transport()..data = data, account: data['viewerUserId']),
          now: () => DateTime.utc(2026, 10, 16, 12));
        final saved = await gateway.read(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation', reference: reference);
        expect(saved, isNotNull); expect(saved!.original.factsVersion, 7);
        expect(saved.original.fulfilmentContext!.toJson(), data['original']['fulfilmentContext']);
      }
    });
  }
  for (final role in WorkspaceOrderIdentityRole.values) {
    for (final allNull in [false, true]) {
      test('LF-LISTING strict originals retain version6 and nullable provenance ${role.name} $allNull', () async {
        final data = publicListingPurchaseResponse(role: role.name, allNull: allNull), wire = Transport()..data = data;
        final result = await projectionGateway(wire, account: role == WorkspaceOrderIdentityRole.buyer ? 'buyer-1' : 'owner-1').readPurchaseProjection(
          role: role, realm: 'evaluation', purchaseId: data['purchaseId'], storeId: role == WorkspaceOrderIdentityRole.seller ? 'store-one' : null,
          orderId: role == WorkspaceOrderIdentityRole.seller ? data['orders'][0]['orderId'] : null);
        expect(result, isNotNull); final order = result!.orders.single;
        expect(order.factsVersion, 6);
        expect(order.lines.single.toJson(), data['orders'][0]['original']['lines'][0]);
        expect(order.lines.single.toJson().containsKey('publicListing'), isTrue);
      });
    }
  }
  for (final fault in <String, void Function(Map<String, dynamic>)>{
    'missing': (d) => d['orders'][0]['original']['lines'][0].remove('publicListing'),
    'realm': (d) => d['orders'][0]['original']['lines'][0]['publicListing']['realm'] = 'production',
    'Store': (d) => d['orders'][0]['original']['lines'][0]['publicListing']['storeId'] = 'other-store',
    'SKU': (d) => d['orders'][0]['original']['lines'][0]['publicListing']['skuId'] = 'other-sku',
    'canonical': (d) => d['orders'][0]['original']['lines'][0]['publicListing']['canonicalProductId'] = 'other-product',
    'pack': (d) => d['orders'][0]['original']['lines'][0]['publicListing']['verifiedPackId'] = 'other-pack',
    'stable ID': (d) => d['orders'][0]['original']['lines'][0]['publicListing']['listingId'] = 'listing-${'a' * 64}',
    'extra field': (d) => d['orders'][0]['original']['lines'][0]['publicListing']['purchaseCost'] = 50,
    'inherited Schedule': (d) => d['orders'][0]['original']['lines'][0].remove('scheduledFulfilment'),
    'old marker': (d) {d['schemaVersion'] = 5; d['orders'][0]['factsVersion'] = 5;},
  }.entries) {
    test('LF-LISTING rejects rehashed ${fault.key} rather than substituting current catalogue identity', () async {
      final data = publicListingPurchaseResponse(); fault.value(data); rehashPurchaseOrder(data['orders'][0]);
      expect(await projectionGateway(Transport()..data = data).readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', purchaseId: data['purchaseId']), isNull);
    });
  }
  for (final role in WorkspaceOrderIdentityRole.values) {
    for (final supplied in [false, true]) {
      test('LF-COMPLETE strict ${role.name} projection distinguishes absent evidence supplied=$supplied', () async {
        final wire = Transport()..data = completionResponse(role: role.name, supplied: supplied);
        final gateway = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire,
          account: role == WorkspaceOrderIdentityRole.buyer ? 'buyer-1' : 'owner-1'), now: () => DateTime.utc(2026, 10, 19));
        final result = await gateway.readCompletion(role: role, realm: 'evaluation', reference: operationalReference());
        expect(result, isNotNull); expect(result!.reference.orderId, operationalReference().orderId);
        expect(result.completion != null, supplied);
        if (supplied) {expect(result.completion!.outcome, 'delivered'); expect(result.completion!.revision, 'completion-v1');}
        expect(wire.sent!['operation'], role == WorkspaceOrderIdentityRole.buyer ? 'readBuyerOrderCompletion' : 'readStoreOrderCompletion');
      });
    }
  }
  for (final fault in <String, void Function(Map<String, dynamic>)>{
    'schema type': (d) => d['schemaVersion'] = 1.0,
    'realm': (d) => d['realm'] = 'production',
    'namespace': (d) => d['authNamespace'] = 'tenant-other',
    'viewer': (d) => d['viewerUserId'] = 'another-account',
    'role': (d) => d['viewerRole'] = 'seller',
    'purchase': (d) => d['purchaseId'] = 'another-purchase',
    'Store': (d) => d['storeId'] = 'another-store',
    'order': (d) => d['orderId'] = 'another-order',
    'fingerprint': (d) => d['originalFingerprint'] = 'b' * 64,
    'source revision': (d) => d['sourceRevision'] = 'another-original',
    'unknown state': (d) => d['state'] = 'delivered',
    'missing evidence': (d) => d['completion'] = null,
    'absent with evidence': (d) => d['state'] = 'not_supplied',
    'unknown outcome': (d) => d['completion']['outcome'] = 'ready',
    'unknown ID': (d) => d['completion']['id'] = 'owner-confirmed',
    'blank revision': (d) => d['completion']['revision'] = '',
    'future': (d) => d['completion']['recordedAt'] = '2099-10-16T12:01:01.000Z',
    'reversed dates': (d) => d['completion']['recordedAt'] = '2026-10-16T12:00:00.000Z',
    'time precision': (d) => d['completion']['occurredAt'] = '2026-10-16T12:01:00.000001Z',
    'private proof': (d) => d['completion']['proof'] = 'private-provider-proof',
    'invented payment': (d) => d['paymentVerified'] = true,
  }.entries) {
    test('LF-COMPLETE rejects ${fault.key}', () async {
      final data = completionResponse(); fault.value(data);
      final wire = Transport()..data = data;
      expect(await AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire)).readCompletion(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: operationalReference()), isNull);
    });
  }
  test('LF-COMPLETE retired A B A response cannot enter the replacement session', () async {
    Object? generation = Object();
    final wire = Transport()..data = completionResponse()..pending = Completer<void>();
    final gateway = AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire, lifetime: () => generation));
    final pending = gateway.readCompletion(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: operationalReference());
    for (var i = 0; i < 100 && wire.calls == 0; i++) {await Future<void>.delayed(Duration.zero);}
    expect(wire.calls, 1); generation = Object(); generation = Object();
    wire.pending!.complete(); expect(await pending, isNull);
    expect(await gateway.readCompletion(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: operationalReference()), isNull);
    expect(wire.calls, 1);
  });
  if (Platform.environment['LF_LISTING_PROJECTION_LOG'] case final path?) {
    test('LF-LISTING actual local producer crosses both original readers and operational decoder', () async {
      const marker = 'LF_LISTING_PROJECTION=';
      final rows = File(path).readAsLinesSync().where((line) => line.contains(marker)).toList();
      expect(rows, hasLength(2));
      for (final row in rows) {
        final payload = (jsonDecode(row.substring(row.indexOf(marker) + marker.length)) as Map).cast<String, dynamic>();
        for (final role in WorkspaceOrderIdentityRole.values) {
          final data = (payload[role.name] as Map).cast<String, dynamic>();
          final firstOrder = data['orders'][0];
          final result = await projectionGateway(Transport()..data = data, account: data['viewerUserId']).readPurchaseProjection(
            role: role, realm: 'evaluation', purchaseId: data['purchaseId'],
            storeId: role == WorkspaceOrderIdentityRole.seller ? firstOrder['storeId'] : null,
            orderId: role == WorkspaceOrderIdentityRole.seller ? firstOrder['orderId'] : null);
          expect(result, isNotNull);
          for (final order in result!.orders) {
            final raw = (data['orders'] as List).singleWhere((r) => r['orderId'] == order.orderId);
            expect(order.factsVersion, 6);
            expect(order.lines.map((line) => line.toJson()).toList(), raw['original']['lines']);
          }
        }
        final data = (payload['operational'] as Map).cast<String, dynamic>();
        final ref = WorkspacePurchaseReference(purchaseId: data['purchaseId'], storeId: data['storeId'],
          orderId: data['orderId'], sourceRevision: data['sourceRevision'], originalFingerprint: data['originalFingerprint']);
        final result = await AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(Transport()..data = data,
          account: data['viewerUserId'])).read(role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: ref);
        expect(result, isNotNull);
        expect(result!.original.factsVersion, 6);
        expect(result.original.lines.map((line) => line.toJson()).toList(), data['original']['lines']);
      }
    });
  }
  if (Platform.environment['LF_COMPLETION_PROJECTION_LOG'] case final path?) {
    test('LF-COMPLETE actual local completion producer crosses strict Dart readback for both roles and fulfilments', () async {
      const marker = 'LF_COMPLETION_PROJECTION=';
      final rows = File(path).readAsLinesSync().where((line) => line.contains(marker)).toList();
      expect(rows, hasLength(2)); final outcomes = <String>{};
      for (final row in rows) {
        final payload = (jsonDecode(row.substring(row.indexOf(marker) + marker.length)) as Map).cast<String, dynamic>();
        for (final role in WorkspaceOrderIdentityRole.values) {
          final data = (payload[role == WorkspaceOrderIdentityRole.buyer ? 'buyer' : 'seller'] as Map).cast<String, dynamic>();
          final wire = Transport()..data = data;
          final ref = WorkspacePurchaseReference(purchaseId: data['purchaseId'], storeId: data['storeId'],
            orderId: data['orderId'], sourceRevision: data['sourceRevision'], originalFingerprint: data['originalFingerprint']);
          final result = await AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire, account: data['viewerUserId'])).readCompletion(
            role: role, realm: 'evaluation', reference: ref);
          expect(result, isNotNull); expect(result!.completion, isNotNull);
          outcomes.add(result.completion!.outcome);
          expect(result.completion!.id, data['completion']['id']);
        }
      }
      expect(outcomes, {'delivered', 'collected'});
    });
  }
  if (Platform.environment['LF_SCHEDULE_PROJECTION_LOG'] case final path?) {
    test('LF-SCHEDULE actual emulator originals preserve exact requested context across Dart', () async {
      const marker = 'LF_SCHEDULE_PROJECTION=';
      final captured = File(path).readAsLinesSync().singleWhere((line) => line.contains(marker));
      final data = (jsonDecode(captured.split(marker).last) as Map).cast<String, dynamic>();
      final wire = Transport()..data = data;
      final result = await projectionGateway(wire, account: data['viewerUserId'] as String).readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: data['purchaseId'] as String);
      expect(result, isNotNull);
      var selected = 0, unselected = 0;
      for (final order in result!.orders) {
        expect(order.factsVersion, 5);
        final raw = (data['orders'] as List).singleWhere((row) => row['orderId'] == order.orderId);
        for (final line in order.lines) {
          final original = (raw['original']['lines'] as List).singleWhere((row) => row['lineId'] == line.lineId);
          expect(line.toJson(), original);
          expect(line.hasScheduledFulfilmentSnapshot, isTrue);
          if (line.scheduledFulfilment == null) { unselected++; } else {
            selected++;
            expect(line.scheduledFulfilment!.startsAt.microsecond, 456);
            expect(line.scheduledFulfilment!.listing.storeId, order.storeId);
            final copy = line.scheduledFulfilment!.toJson();
            copy['slotId'] = 'later-mutable-feed';
            expect(line.scheduledFulfilment!.slotId, 'slot-original-one');
          }
        }
      }
      expect(selected, 1); expect(unselected, 2);
    });
  }
  test('LF-SCHEDULE all-null originals preserve new-version presence while legacy stays unknown', () async {
    final wire = Transport()..data = scheduledPurchaseResponse(selected: false);
    final gateway = projectionGateway(wire);
    final result = (await gateway.readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', purchaseId: 'purchase-v2'))!.orders.single;
    expect(result.factsVersion, 5);
    expect(result.lines.single.hasScheduledFulfilmentSnapshot, isTrue);
    expect(result.lines.single.toJson().containsKey('scheduledFulfilment'), isTrue);
    expect(result.lines.single.scheduledFulfilment, isNull);
    wire.data = variantPurchaseResponse();
    final legacy = (await gateway.readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', purchaseId: 'purchase-v2'))!.orders.single;
    expect(legacy.factsVersion, 4);
    expect(legacy.lines.single.hasScheduledFulfilmentSnapshot, isFalse);
    expect(legacy.lines.single.toJson().containsKey('scheduledFulfilment'), isFalse);
  });
  for (final dates in [
    ('2026-10-15T23:59:59.123456Z', '2026-10-15T23:59:59.123457Z'),
    ('2026-10-15T23:59:59.123Z', '2026-10-16T00:00:00.000Z'),
    ('0000-02-29T23:59:59.000001Z', '0000-03-01T00:00:00.000Z'),
    ('-0001-01-01T00:00:00.000001Z', '-0001-01-01T00:00:00.000002Z'),
    ('+010000-01-01T00:00:00.123456Z', '+010000-01-01T00:00:00.123457Z'),
    ('+275760-09-12T23:59:59.999999Z', '+275760-09-13T00:00:00.000Z'),
  ]) {
    test('LF-SCHEDULE canonical microsecond range remains exact ${dates.$1}', () async {
      final data = scheduledPurchaseResponse(), order = data['orders'][0];
      final selected = order['original']['lines'][0]['scheduledFulfilment'];
      selected['startsAt'] = dates.$1; selected['endsAt'] = dates.$2;
      rehashPurchaseOrder(order as Map<String, dynamic>);
      final wire = Transport()..data = data;
      final result = await projectionGateway(wire).readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', purchaseId: 'purchase-v2');
      expect(result, isNotNull);
      expect(result!.orders.single.lines.single.scheduledFulfilment!.toJson(), selected);
    });
  }
  for (final fault in ['missing', 'boolean', 'array', 'object', 'version', 'method', 'nested-version', 'realm', 'store', 'sku', 'product', 'pack', 'listing', 'channel', 'revision', 'location', 'slot', 'extra', 'invalid-day', 'invalid-hour', 'offset', 'precision', 'redundant-zero', 'equal', 'micro-before', 'range-overflow', 'old-version', 'mixed-version']) {
    test('LF-SCHEDULE rejects $fault even with recomputed original hash', () async {
      final data = scheduledPurchaseResponse(), order = data['orders'][0];
      final line = order['original']['lines'][0], s = line['scheduledFulfilment'];
      if (fault == 'missing') line.remove('scheduledFulfilment');
      if (fault == 'boolean') line['scheduledFulfilment'] = false;
      if (fault == 'array') line['scheduledFulfilment'] = [];
      if (fault == 'object') line['scheduledFulfilment'] = {};
      if (fault == 'version') s['schemaVersion'] = true;
      if (fault == 'method') s['method'] = 'quick';
      if (fault == 'nested-version') s['listing']['schemaVersion'] = 2;
      if (fault == 'realm') s['listing']['realm'] = 'production';
      if (fault == 'store') s['listing']['storeId'] = 'other-store';
      if (fault == 'sku') s['listing']['skuId'] = 'other-sku';
      if (fault == 'product') s['listing']['canonicalProductId'] = 'other-product';
      if (fault == 'pack') s['listing']['verifiedPackId'] = 'other-pack';
      if (fault == 'listing') s['listing']['listingId'] = 'made-up';
      if (fault == 'channel') s['listing']['channel'] = 'unknown';
      if (fault == 'revision') s['sourceRevision'] = ' ';
      if (fault == 'location') s.remove('locationKey');
      if (fault == 'slot') s['slotId'] = null;
      if (fault == 'extra') s['booked'] = true;
      if (fault == 'invalid-day') s['startsAt'] = '2026-02-30T00:00:00.000Z';
      if (fault == 'invalid-hour') s['startsAt'] = '2026-10-15T24:00:00.000Z';
      if (fault == 'offset') s['startsAt'] = '2026-10-15T23:59:59.123456+00:00';
      if (fault == 'precision') s['startsAt'] = '2026-10-15T23:59:59.1234567Z';
      if (fault == 'redundant-zero') s['startsAt'] = '2026-10-15T23:59:59.123000Z';
      if (fault == 'equal') s['endsAt'] = s['startsAt'];
      if (fault == 'micro-before') s['endsAt'] = '2026-10-15T23:59:59.123455Z';
      if (fault == 'range-overflow') {s['startsAt'] = '+275760-09-12T23:59:59.999999Z'; s['endsAt'] = '+275760-09-13T00:00:00.000001Z';}
      if (fault == 'old-version') {data['schemaVersion'] = 4; order['factsVersion'] = 4;}
      if (fault == 'mixed-version') data['schemaVersion'] = 4;
      rehashPurchaseOrder(order as Map<String, dynamic>);
      final wire = Transport()..data = data;
      expect(await projectionGateway(wire).readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', purchaseId: 'purchase-v2'), isNull);
    });
  }
  test('LF-SCHEDULE changing a requested slot cannot reuse the original fingerprint', () async {
    final data = scheduledPurchaseResponse();
    data['orders'][0]['original']['lines'][0]['scheduledFulfilment']['slotId'] = 'changed-slot';
    final wire = Transport()..data = data;
    expect(await projectionGateway(wire).readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', purchaseId: 'purchase-v2'), isNull);
  });
  test('LF-SCHEDULE original consumes exact supplied desired window without current eligibility', () async {
    final wire = Transport()..data = scheduledPurchaseResponse();
    final result = await projectionGateway(wire).readPurchaseProjection(
      role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: 'purchase-v2');
    expect(result, isNotNull);
    expect(result!.orders.single.factsVersion, 5);
    expect((result.orders.single.lines.single.toJson()['scheduledFulfilment'] as Map)['startsAt'], '2026-10-15T23:59:59.123456Z');
  });
  if (Platform.environment['LF_VARIANT_PROJECTION_LOG'] case final path?) {
    test('LF-VARIANT actual emulator originals cross the strict Dart boundary with immutable descriptions', () async {
      const marker = 'LF_VARIANT_PROJECTION=';
      final captured = File(path).readAsLinesSync().singleWhere((line) => line.contains(marker));
      final data = (jsonDecode(captured.split(marker).last) as Map).cast<String, dynamic>();
      final wire = Transport()..data = data;
      final result = await projectionGateway(wire, account: data['viewerUserId'] as String).readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: data['purchaseId'] as String);
      expect(result, isNotNull);
      expect(result!.orders, hasLength(2));
      final variants = <String?>[];
      for (final order in result.orders) {
        expect(order.factsVersion, 4);
        final source = (data['orders'] as List).singleWhere((raw) => raw['orderId'] == order.orderId);
        for (final line in order.lines) {
          final raw = (source['original']['lines'] as List).singleWhere((row) => row['lineId'] == line.lineId);
          expect(line.toJson(), raw);
          variants.add(line.variant);
          raw['variant'] = 'Later catalogue text';
          expect(line.variant, isNot('Later catalogue text'));
        }
      }
      expect(variants, unorderedEquals(['गुलाबी\n128 GB', 'Blue · 512 GB', '']));
    });
  }
  for (final variant in ['', 'गुलाबी\n128 GB', 'Pink\t128 GB', 'x' * 240]) {
    test('LF-VARIANT valid optional original text remains exact ${variant.length}', () async {
      final wire = Transport()..data = variantPurchaseResponse(variant: variant);
      final result = await projectionGateway(wire).readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: 'purchase-v2');
      expect(result!.orders.single.lines.single.variant, variant);
      expect(result.orders.single.factsVersion, 4);
    });
  }
  for (final fault in <String, void Function(Map<String, dynamic>)>{
    'missing': (d) => d['orders'][0]['original']['lines'][0].remove('variant'),
    'null': (d) => d['orders'][0]['original']['lines'][0]['variant'] = null,
    'boolean': (d) => d['orders'][0]['original']['lines'][0]['variant'] = false,
    'array': (d) => d['orders'][0]['original']['lines'][0]['variant'] = ['Pink'],
    'object': (d) => d['orders'][0]['original']['lines'][0]['variant'] = {'label': 'Pink'},
    'outer whitespace': (d) => d['orders'][0]['original']['lines'][0]['variant'] = ' Pink',
    'whitespace': (d) => d['orders'][0]['original']['lines'][0]['variant'] = '\n',
    'control': (d) => d['orders'][0]['original']['lines'][0]['variant'] = 'Pink\u0000',
    'oversize': (d) => d['orders'][0]['original']['lines'][0]['variant'] = 'x' * 241,
    'legacy downgrade': (d) {d['schemaVersion'] = 3; d['orders'][0]['factsVersion'] = 3;},
    'mixed versions': (d) => d['schemaVersion'] = 3,
    'missing benefits': (d) => d['orders'][0]['original'].remove('benefitAttribution'),
  }.entries) {
    test('LF-VARIANT rejects ${fault.key} even with recomputed original hash', () async {
      final data = (jsonDecode(jsonEncode(variantPurchaseResponse())) as Map).cast<String, dynamic>(); fault.value(data);
      rehashPurchaseOrder(data['orders'][0] as Map<String, dynamic>);
      final wire = Transport()..data = data;
      expect(await projectionGateway(wire).readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: 'purchase-v2'), isNull);
    });
  }
  test('LF-VARIANT supplied variant cannot change beneath the original fingerprint', () async {
    final data = variantPurchaseResponse(); data['orders'][0]['original']['lines'][0]['variant'] = 'Blue · 512 GB';
    final wire = Transport()..data = data;
    expect(await projectionGateway(wire).readPurchaseProjection(
      role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: 'purchase-v2'), isNull);
  });
  test('LF-VARIANT original purchased descriptions decode without current catalogue lookup', () async {
    final wire = Transport()..data = variantPurchaseResponse();
    final result = await projectionGateway(wire).readPurchaseProjection(
      role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: 'purchase-v2');
    expect(result, isNotNull);
    expect(result!.orders.single.lines.single.toJson()['variant'], 'Pink · 128 GB');
    expect(result.orders.single.factsVersion, 4);
  });
  if (Platform.environment['LF_ATTR_PROJECTION_LOG'] case final path?) {
    test('LF-ATTR actual emulator response crosses the strict Dart fingerprint boundary', () async {
      const marker = 'LF_ATTR_PROJECTION=';
      final row = File(path).readAsLinesSync().singleWhere((line) => line.contains(marker));
      final data = (jsonDecode(row.substring(row.indexOf(marker) + marker.length)) as Map).cast<String, dynamic>();
      final wire = Transport()..data = data;
      final result = await projectionGateway(wire, account: data['viewerUserId'] as String).readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', purchaseId: data['purchaseId'] as String);
      expect(result, isNotNull); expect(result!.orders, hasLength(2));
      for (final order in result.orders) {
        final original = (data['orders'] as List).singleWhere((raw) => raw['orderId'] == order.orderId);
        expect(order.benefitAttribution!.toJson(), original['original']['benefitAttribution']);
        expect(order.originalFingerprint, original['originalFingerprint']);
      }
    });
  }
  for (final fault in <String, void Function(Map<String, dynamic>)>{
    'missing attribution': (d) => d['orders'][0]['original'].remove('benefitAttribution'),
    'null attribution': (d) => d['orders'][0]['original']['benefitAttribution'] = null,
    'unknown attribution version': (d) => d['orders'][0]['original']['benefitAttribution']['schemaVersion'] = 2,
    'unlabelled cashback basis': (d) => d['orders'][0]['original']['benefitAttribution']['components'][1]['amountBasis'] = 'applied',
    'discount basis': (d) => d['orders'][0]['original']['benefitAttribution']['components'][0]['amountBasis'] = 'quoted',
    'cross-line allocation': (d) => d['orders'][0]['original']['benefitAttribution']['components'][0]['allocations'][0]['lineId'] = 'foreign-line',
    'fractional paise': (d) => d['orders'][0]['original']['benefitAttribution']['components'][0]['amountMinor'] = 51.5,
    'negative paise': (d) => d['orders'][0]['original']['benefitAttribution']['components'][0]['amountMinor'] = -1,
    'inconsistent component sum': (d) => d['orders'][0]['original']['benefitAttribution']['components'][0]['allocations'][0]['amountMinor'] = 50,
    'extra claimed payment': (d) => d['orders'][0]['original']['benefitAttribution']['components'][1]['paid'] = true,
    'legacy downgrade': (d) {d['schemaVersion'] = 2; d['orders'][0]['factsVersion'] = 2;},
    'contradictory envelope version': (d) => d['schemaVersion'] = 2,
  }.entries) {
    test('LF-ATTR rejects ${fault.key} even with a recomputed untrusted envelope hash', () async {
      final data = (jsonDecode(jsonEncode(attributedPurchaseResponse())) as Map).cast<String, dynamic>();
      fault.value(data);
      rehashPurchaseOrder(data['orders'][0] as Map<String, dynamic>);
      final wire = Transport()..data = data;
      expect(await projectionGateway(wire).readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation', purchaseId: 'purchase-v2'), isNull);
    });
  }
  for (final marker in [null, 2, true, 3.0]) {
    test('LF-ATTR invalid operational original version cannot silently downgrade $marker', () async {
      final raw = attributedOperationalResponse()..['originalFactsVersion'] = marker;
      final order = attributedPurchaseResponse()['orders'][0];
      final reference = WorkspacePurchaseReference(purchaseId: 'purchase-v2', storeId: 'store-one', orderId: 'order-v2',
        sourceRevision: 'revision-1', originalFingerprint: order['originalFingerprint']);
      final wire = Transport()..data = raw;
      expect(await AuthenticatedWorkspaceOrderOperationsGateway(projectionGateway(wire)).read(
        role: WorkspaceOrderIdentityRole.buyer, realm: 'evaluation', reference: reference), isNull);
    });
  }
  test('LF-ATTR known none and unknown legacy remain distinct and immutable', () async {
    final wire = Transport()..data = attributedPurchaseResponse(empty: true);
    final gateway = projectionGateway(wire);
    final known = (await gateway.readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', purchaseId: 'purchase-v2'))!;
    expect(known.orders.single.benefitAttribution!.components, isEmpty);
    expect(() => known.orders.single.benefitAttribution!.components.clear(), throwsUnsupportedError);
    wire.data = purchaseResponse();
    final legacy = (await gateway.readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', purchaseId: 'purchase-v2'))!;
    expect(legacy.orders.single.benefitAttribution, isNull);
    wire.data = attributedPurchaseResponse();
    final supplied = (await gateway.readPurchaseProjection(role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation', purchaseId: 'purchase-v2'))!;
    expect(() => supplied.orders.single.benefitAttribution!.components.first.allocations.clear(), throwsUnsupportedError);
  });
  for (final role in ['buyer', 'seller']) {
    test('LF-SCHEDULE operational $role readback retains only requested context', () async {
      final raw = scheduledOperationalResponse(role: role);
      final reference = WorkspacePurchaseReference(purchaseId: 'purchase-v2', storeId: 'store-one', orderId: 'order-v2',
        sourceRevision: 'revision-1', originalFingerprint: raw['originalFingerprint']);
      final wire = Transport()..data = raw;
      final result = await AuthenticatedWorkspaceOrderOperationsGateway(
        projectionGateway(wire, account: role == 'buyer' ? 'buyer-1' : 'owner-1')).read(
          role: role == 'buyer' ? WorkspaceOrderIdentityRole.buyer : WorkspaceOrderIdentityRole.seller,
          realm: 'evaluation', reference: reference);
      expect(result, isNotNull);
      expect(result!.original.factsVersion, 5);
      expect(result.original.lines.single.scheduledFulfilment!.slotId, 'slot-original-one');
      expect(result.original.totals['totalMinor'], 10015);
    });
    test('LF-VARIANT operational $role consumer preserves exact original variant', () async {
      final raw = variantOperationalResponse(role: role);
      final reference = WorkspacePurchaseReference(purchaseId: 'purchase-v2', storeId: 'store-one', orderId: 'order-v2',
        sourceRevision: 'revision-1', originalFingerprint: raw['originalFingerprint']);
      final wire = Transport()..data = raw;
      final result = await AuthenticatedWorkspaceOrderOperationsGateway(
        projectionGateway(wire, account: role == 'buyer' ? 'buyer-1' : 'owner-1')).read(
          role: role == 'buyer' ? WorkspaceOrderIdentityRole.buyer : WorkspaceOrderIdentityRole.seller,
          realm: 'evaluation', reference: reference);
      expect(result, isNotNull);
      expect(result!.original.lines.single.variant, 'Pink · 128 GB');
      expect(result.original.factsVersion, 4);
      expect(result.original.totals['totalMinor'], 10015);
    });
    test('LF-ATTR original $role consumer admits source supplied attribution without changing money', () async {
      final wire = Transport()..data = attributedPurchaseResponse(role: role);
      final value = await projectionGateway(wire, account: role == 'buyer' ? 'buyer-1' : 'owner-1').readPurchaseProjection(
        role: role == 'buyer' ? WorkspaceOrderIdentityRole.buyer : WorkspaceOrderIdentityRole.seller,
        realm: 'evaluation', purchaseId: 'purchase-v2', storeId: role == 'seller' ? 'store-one' : null,
        orderId: role == 'seller' ? 'order-v2' : null);
      expect(value, isNotNull);
      expect(value!.orders.single.totals['totalMinor'], 10015);
    });
    test('LF-ATTR operational $role consumer retains original new-version facts', () async {
      final purchase = attributedPurchaseResponse(role: role), order = purchase['orders'][0];
      final raw = operationalResponse(role: role)..['originalFactsVersion'] = 3
        ..['original'] = order['original'] ..['originalFingerprint'] = order['originalFingerprint'];
      final wire = Transport()..data = raw;
      final reference = WorkspacePurchaseReference(purchaseId: 'purchase-v2', storeId: 'store-one', orderId: 'order-v2',
        sourceRevision: 'revision-1', originalFingerprint: order['originalFingerprint']);
      final result = await AuthenticatedWorkspaceOrderOperationsGateway(
        projectionGateway(wire, account: role == 'buyer' ? 'buyer-1' : 'owner-1')).read(
          role: role == 'buyer' ? WorkspaceOrderIdentityRole.buyer : WorkspaceOrderIdentityRole.seller,
          realm: 'evaluation', reference: reference);
      expect(result, isNotNull);
      expect(result!.original.totals['totalMinor'], 10015);
    });
  }
  for (final reconcile in [false, true]) {
    for (final action in ['accept', 'ready', 'reject']) {
      test(
        'operational acknowledgment must match action=$action reconcile=$reconcile',
        () async {
          final response = operationalResponse(role: 'seller')
            ..['revision'] = 2
            ..['stage'] = action == 'reject' ? 'Rejected' : 'Confirmed'
            ..['permittedActions'] = <String>[];
          if (action == 'reject') {
            response['rejectionReason'] = 'A different reason';
          }
          final wire = Transport()
            ..data = {
              'schemaVersion': 1,
              'operationId': 'bound-operation',
              'state': 'applied',
              'snapshot': response,
            };
          final gateway = AuthenticatedWorkspaceOrderOperationsGateway(
            projectionGateway(wire, account: 'owner-1'),
          );
          expect(
            await gateway.command(
              realm: 'evaluation',
              reference: operationalReference(),
              operationId: 'bound-operation',
              expectedRevision: 1,
              action: action,
              reason: action == 'reject' ? 'Original reason' : null,
              reconcile: reconcile,
            ),
            isNull,
          );
        },
      );
    }
  }
  test(
    'operational reader preserves exact originals and unknown financial authority',
    () async {
      final wire = Transport()..data = operationalResponse();
      final identity = projectionGateway(wire);
      final gateway = AuthenticatedWorkspaceOrderOperationsGateway(identity);
      final order = await gateway.read(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        reference: operationalReference(),
      );
      expect(order, isNotNull);
      expect(order!.original.totals['totalMinor'], 10015);
      expect(order.original.lines.single.verifiedPackId, 'pack-one');
      expect(order.customerLabel, isNull);
      expect(order.permittedActions, isEmpty);
      expect(wire.sent!['operation'], 'readBuyerOperationalOrder');
      expect(
        (identity.credentials as Credentials).modes.single,
        SocialAppCheckTokenMode.standard,
      );
    },
  );
  for (final entry in <String, void Function(Map<String, dynamic>)>{
    'cross account': (d) => d['viewerUserId'] = 'foreign-user',
    'cross Store': (d) => d['storeId'] = 'foreign-store',
    'different original': (d) => d['original']['totals']['totalMinor']++,
    'wrong source revision': (d) => d['sourceRevision'] = 'foreign-revision',
    'array stage': (d) => d['stage'] = ['Confirmed'],
    'array action': (d) => d['permittedActions'] = [
      ['accept'],
    ],
    'buyer recipient leak': (d) => d['address'] = 'Private recipient address',
    'claimed payment authority': (d) => d['paymentVerification'] = 'paid',
    'claimed Stock authority': (d) => d['stockVerification'] = 'reserved',
  }.entries) {
    test('operational reader rejects ${entry.key}', () async {
      final wire = Transport()..data = operationalResponse();
      entry.value(wire.data);
      final gateway = AuthenticatedWorkspaceOrderOperationsGateway(
        projectionGateway(wire),
      );
      expect(
        await gateway.read(
          role: WorkspaceOrderIdentityRole.buyer,
          realm: 'evaluation',
          reference: operationalReference(),
        ),
        isNull,
      );
    });
  }
  test(
    'operational command uses limited token; reconciliation retains original identity',
    () async {
      final snapshot = operationalResponse(role: 'seller')
        ..['revision'] = 2
        ..['stage'] = 'Preparing'
        ..['permittedActions'] = ['ready'];
      final wire = Transport()
        ..data = {
          'schemaVersion': 1,
          'operationId': 'STORE-ORDER-host_nonce==',
          'state': 'applied',
          'snapshot': snapshot,
        };
      final identity = projectionGateway(wire, account: 'owner-1');
      final gateway = AuthenticatedWorkspaceOrderOperationsGateway(identity);
      final first = await gateway.command(
        realm: 'evaluation',
        reference: operationalReference(),
        operationId: 'STORE-ORDER-host_nonce==',
        expectedRevision: 1,
        action: 'accept',
      );
      expect(first?.state, 'applied');
      final originalBody = Map<String, Object?>.from(wire.sent!)
        ..remove('operation');
      expect(
        (identity.credentials as Credentials).modes.last,
        SocialAppCheckTokenMode.limitedUse,
      );
      final recovered = await gateway.command(
        realm: 'evaluation',
        reference: operationalReference(),
        operationId: 'STORE-ORDER-host_nonce==',
        expectedRevision: 1,
        action: 'accept',
        reconcile: true,
      );
      expect(recovered?.snapshot.revision, 2);
      expect(wire.sent!['operation'], 'reconcileStoreOrderCommand');
      expect(
        Map<String, Object?>.from(wire.sent!)..remove('operation'),
        originalBody,
      );
      expect(
        (identity.credentials as Credentials).modes.last,
        SocialAppCheckTokenMode.standard,
      );
      wire.data['operationId'] = 'wrong-operation';
      expect(
        await gateway.command(
          realm: 'evaluation',
          reference: operationalReference(),
          operationId: 'STORE-ORDER-host_nonce==',
          expectedRevision: 1,
          action: 'accept',
          reconcile: true,
        ),
        isNull,
      );
    },
  );
  test(
    'operational read ignores retired lifetime and unknown command response',
    () async {
      Object? owner = Object();
      final wire = Transport()
        ..data = operationalResponse()
        ..pending = Completer<void>();
      final identity = projectionGateway(wire, lifetime: () => owner);
      final gateway = AuthenticatedWorkspaceOrderOperationsGateway(identity);
      final pending = gateway.read(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        reference: operationalReference(),
      );
      await Future<void>.delayed(Duration.zero);
      owner = null;
      wire.pending!.complete();
      expect(await pending, isNull);
      final before = wire.calls;
      expect(
        await gateway.command(
          realm: 'evaluation',
          reference: operationalReference(),
          operationId: 'STORE-ORDER-host_nonce==',
          expectedRevision: 1,
          action: 'accept',
        ),
        isNull,
      );
      expect(wire.calls, before);
    },
  );
  for (final entry in <String, void Function(Map<String, dynamic>)>{
    'other account': (d) => d['viewerUserId'] = 'other-buyer',
    'other realm': (d) => d['realm'] = 'production',
    'wrong coverage': (d) => d['coverage'] = 'all_orders',
    'foreign Store': (d) => d['storeId'] = 'other-store',
    'private fields': (d) => d['buyerUserId'] = 'private-user',
    'duplicate reference': (d) => d['references'].add(d['references'][0]),
    'bad fingerprint': (d) =>
        d['references'][0]['originalFingerprint'] = 'not-a-hash',
  }.entries) {
    test('reference discovery rejects ${entry.key}', () async {
      final wire = Transport()..data = referenceResponse();
      entry.value(wire.data);
      expect(
        await projectionGateway(wire).listPurchaseReferences(
          role: WorkspaceOrderIdentityRole.buyer,
          realm: 'evaluation',
        ),
        isNull,
      );
    });
  }
  test(
    'reference discovery can advance an empty scanned page without claiming no orders',
    () async {
      final wire = Transport()
        ..data = referenceResponse()
        ..data['references'] = []
        ..data['nextCursor'] = 'next-page';
      final page = await projectionGateway(wire).listPurchaseReferences(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
      );
      expect(page!.references, isEmpty);
      expect(page.nextCursor, 'next-page');
      expect(page.coverage, 'saved_original_facts');
    },
  );
  test('reference discovery discards response after owner retires', () async {
    Object? lifetime = Object();
    final wire = Transport()
      ..data = referenceResponse()
      ..pending = Completer<void>();
    final gateway = projectionGateway(wire, lifetime: () => lifetime);
    final pending = gateway.listPurchaseReferences(
      role: WorkspaceOrderIdentityRole.buyer,
      realm: 'evaluation',
    );
    await Future<void>.delayed(Duration.zero);
    lifetime = Object();
    wire.pending!.complete();
    expect(await pending, isNull);
  });
  test(
    'discovers scoped references without converting them into legacy orders',
    () async {
      final wire = Transport()..data = referenceResponse();
      final client = projectionGateway(wire);
      final page = await client.listPurchaseReferences(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
      );
      expect(page!.references.single.orderId, 'order-v2');
      expect(page.coverage, 'saved_original_facts');
      expect(wire.sent!['operation'], 'listBuyerPurchaseReferences');
      wire.data = purchaseResponse();
      final details = await client.readReferencedOrder(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        reference: page.references.single,
      );
      expect(details!.totals['totalMinor'], 10015);
      wire.data['orders'][0]['orderId'] = 'another-order';
      expect(
        await client.readReferencedOrder(
          role: WorkspaceOrderIdentityRole.buyer,
          realm: 'evaluation',
          reference: page.references.single,
        ),
        isNull,
      );
    },
  );
  test(
    'actual Firestore service v2 response decodes both immutable Store partitions',
    () async {
      // Captured from readBuyer on the actual local emulator, not generated in Dart.
      const raw =
          r'''{"schemaVersion":2,"realm":"evaluation","authNamespace":"firebase-default","viewerRole":"buyer","viewerUserId":"new-buyer-c013b044-e69f-42f5-b5c9-82a70e35fbaf","purchaseId":"purchase-2f7efd65-b8fa-48df-a81d-87322f929825","buyerId":"buyer-87291824-42fb-4368-a74f-c0e0b2c098e8","sourceRevision":"revision-1","state":"original_facts","orders":[{"factsVersion":2,"storeId":"store-c013b044-e69f-42f5-b5c9-82a70e35fbaf-0","orderId":"order-f742ce0f-9bc6-4e4f-92bd-08520cf504a6","original":{"currency":"INR","lines":[{"lineId":"line-b8405fac-3efd-47b6-b951-64b1cfe1934c","skuId":"sku-one","canonicalProductId":"product-one","verifiedPackId":"pack-one","offerId":"offer-one","offerRevision":"offer-revision-1","name":"दाल","packLabel":"1 kg","quantityMilli":1000,"quantityUnit":"pack","unitPriceMinor":10051,"lineTotalMinor":10051}],"totals":{"itemsMinor":10051,"discountMinor":51,"taxMinor":5,"deliveryMinor":10,"freightMinor":0,"paymentFeeMinor":0,"tipMinor":0,"totalMinor":10015}},"originalFingerprint":"df39f39c6753d00554d8380ec8942e0893da4bae3b4b84d2e5bc4c24e631844f"},{"factsVersion":2,"storeId":"store-c013b044-e69f-42f5-b5c9-82a70e35fbaf-1","orderId":"order-6f1e7540-8d9e-4f10-8cc0-6c3168e690d5","original":{"currency":"INR","lines":[{"lineId":"line-154f8a75-863f-4239-8105-9d371750f2cb","skuId":"sku-two","canonicalProductId":"product-two","verifiedPackId":"pack-two","offerId":"offer-two","offerRevision":"offer-revision-1","name":"दाल","packLabel":"1 kg","quantityMilli":1000,"quantityUnit":"pack","unitPriceMinor":10051,"lineTotalMinor":10051}],"totals":{"itemsMinor":10051,"discountMinor":51,"taxMinor":5,"deliveryMinor":10,"freightMinor":0,"paymentFeeMinor":0,"tipMinor":0,"totalMinor":10015}},"originalFingerprint":"b12424b5fe481aa3c164692b27e2cda71862aa9d08e713cae5ae2df7ba032130"}]}''';
      final wire = Transport()
        ..data = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final gateway = projectionGateway(
        wire,
        account: wire.data['viewerUserId'] as String,
      );
      final result = await gateway.readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        purchaseId: wire.data['purchaseId'] as String,
      );
      expect(result!.orders.length, 2);
      expect(result.orders.first.lines.single.name, 'दाल');
      expect(result.orders.last.lines.single.verifiedPackId, 'pack-two');
      expect(
        result.orders.every((o) => o.totals['totalMinor'] == 10015),
        isTrue,
      );
      expect(() => result.orders.clear(), throwsUnsupportedError);
      expect(() => result.orders.first.totals.clear(), throwsUnsupportedError);
    },
  );
  for (final entry in <String, void Function(Map<String, dynamic>)>{
    'wrong account': (d) => d['viewerUserId'] = 'other-buyer',
    'wrong purchase': (d) => d['purchaseId'] = 'other-purchase',
    'wrong realm': (d) => d['realm'] = 'production',
    'tenant namespace': (d) => d['authNamespace'] = 'tenant-one',
    'legacy response': (d) => d['schemaVersion'] = 1,
    'private owner leak': (d) => d['ownerUserId'] = 'owner-other',
    'empty success': (d) => d['orders'] = [],
    'duplicate Store': (d) =>
        (d['orders'] as List).add((d['orders'] as List).first),
    'tampered fingerprint': (d) =>
        d['orders'][0]['originalFingerprint'] = '0' * 64,
    'money mismatch': (d) =>
        d['orders'][0]['original']['totals']['totalMinor']++,
    'unit price mismatch': (d) =>
        d['orders'][0]['original']['lines'][0]['unitPriceMinor'] = 1,
    'malformed quantity unit': (d) =>
        d['orders'][0]['original']['lines'][0]['quantityUnit'] = ['pack'],
    'missing pack': (d) =>
        d['orders'][0]['original']['lines'][0].remove('verifiedPackId'),
  }.entries) {
    test(
      'v2 rejects ${entry.key} without falling back to legacy orders',
      () async {
        final wire = Transport()..data = purchaseResponse();
        entry.value(wire.data);
        expect(
          await projectionGateway(wire).readPurchaseProjection(
            role: WorkspaceOrderIdentityRole.buyer,
            realm: 'evaluation',
            purchaseId: 'purchase-v2',
          ),
          isNull,
        );
        expect(wire.calls, 1);
      },
    );
  }
  test(
    'v2 seller requires exact purchase Store and order, with no other partition',
    () async {
      final wire = Transport()..data = purchaseResponse(role: 'seller');
      final gateway = projectionGateway(wire, account: 'owner-1');
      expect(
        await gateway.readPurchaseProjection(
          role: WorkspaceOrderIdentityRole.seller,
          realm: 'evaluation',
          purchaseId: 'purchase-v2',
          storeId: 'store-one',
          orderId: 'order-v2',
        ),
        isNotNull,
      );
      expect(wire.sent!['operation'], 'readStorePurchaseProjection');
      expect(
        await gateway.readPurchaseProjection(
          role: WorkspaceOrderIdentityRole.seller,
          realm: 'evaluation',
          purchaseId: 'purchase-v2',
          storeId: 'store-other',
          orderId: 'order-v2',
        ),
        isNull,
      );
      expect(
        await gateway.readPurchaseProjection(
          role: WorkspaceOrderIdentityRole.seller,
          realm: 'evaluation',
          purchaseId: 'purchase-v2',
          storeId: 'store-one',
          orderId: 'order-other',
        ),
        isNull,
      );
      wire.data['orders'].add(wire.data['orders'][0]);
      expect(
        await gateway.readPurchaseProjection(
          role: WorkspaceOrderIdentityRole.seller,
          realm: 'evaluation',
          purchaseId: 'purchase-v2',
          storeId: 'store-one',
          orderId: 'order-v2',
        ),
        isNull,
      );
    },
  );
  test(
    'v2 fences late responses and all future calls after original lifetime retires',
    () async {
      Object? lifetime = Object();
      final wire = Transport()
        ..data = purchaseResponse()
        ..pending = Completer<void>();
      final gateway = projectionGateway(wire, lifetime: () => lifetime);
      final pending = gateway.readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        purchaseId: 'purchase-v2',
      );
      await Future<void>.delayed(Duration.zero);
      lifetime = Object();
      wire.pending!.complete();
      expect(await pending, isNull);
      final calls = wire.calls;
      expect(
        await gateway.readPurchaseProjection(
          role: WorkspaceOrderIdentityRole.buyer,
          realm: 'evaluation',
          purchaseId: 'purchase-v2',
        ),
        isNull,
      );
      expect(wire.calls, calls);
    },
  );
  test('v2 invalid request scope never reaches transport', () async {
    final wire = Transport()..data = purchaseResponse();
    final gateway = projectionGateway(wire);
    expect(
      await gateway.readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        purchaseId: 'purchase-v2',
        storeId: 'store-one',
      ),
      isNull,
    );
    expect(
      await gateway.readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.seller,
        realm: 'evaluation',
        purchaseId: 'purchase-v2',
      ),
      isNull,
    );
    expect(
      await gateway.readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'unknown',
        purchaseId: 'purchase-v2',
      ),
      isNull,
    );
    expect(wire.calls, 0);
  });
  test(
    'v2 retires during credentials before any request is dispatched',
    () async {
      Object? owner = Object();
      final credentials = Credentials()..token = Completer<String>();
      final wire = Transport()..data = purchaseResponse();
      final gateway = AuthenticatedWorkspaceOrderIdentityGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
        ),
        accountUserId: 'buyer-1',
        lifetime: () => owner,
        credentials: credentials,
        transport: wire,
      );
      final pending = gateway.readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        purchaseId: 'purchase-v2',
      );
      owner = Object();
      credentials.token!.complete('host-token');
      expect(await pending, isNull);
      expect(wire.calls, 0);
      expect(credentials.modes, isEmpty);
    },
  );
  test('v2 unavailable transport is not an empty purchase', () async {
    final wire = Transport()
      ..data = purchaseResponse()
      ..fail = true;
    final gateway = projectionGateway(wire);
    expect(
      await gateway.readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        purchaseId: 'purchase-v2',
      ),
      isNull,
    );
    wire.fail = false;
    wire.status = 503;
    expect(
      await gateway.readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        purchaseId: 'purchase-v2',
      ),
      isNull,
    );
  });
  test(
    'v2 reader consumes exact Store references and paise without legacy ID inference',
    () async {
      final transport = Transport()..data = purchaseResponse();
      final owner = Object();
      final gateway = AuthenticatedWorkspaceOrderIdentityGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
        ),
        accountUserId: 'buyer-1',
        lifetime: () => owner,
        credentials: Credentials(),
        transport: transport,
      );
      final result = await gateway.readPurchaseProjection(
        role: WorkspaceOrderIdentityRole.buyer,
        realm: 'evaluation',
        purchaseId: 'purchase-v2',
      );
      expect(result!.orders.single.orderId, 'order-v2');
      expect(result.orders.single.totals['totalMinor'], 10015);
      expect(result.orders.single.lines.single.verifiedPackId, 'pack-one');
      expect(transport.sent, {
        'operation': 'readBuyerPurchaseProjection',
        'purchaseId': 'purchase-v2',
      });
    },
  );
  test(
    'backend-produced Unicode response preserves cross-language fingerprint',
    () async {
      // Generated by the actual TypeScript bindFinalPurchase/readIdentity service.
      // Isolated source fixture; this is not native/live-order acceptance.
      const raw =
          r'''{"ok":true,"data":{"schemaVersion":1,"viewerRole":"buyer","viewerUserId":"buyer-1","storeId":"workspace-1","orderId":"MS-interop","state":"linked","identity":{"buyerId":"customer-1","purchaseId":"purchase-1","sourceRevision":"final-1","serviceRevision":"574cd1c2006b279b774537e9052ef5507c573f9916930e1c4f9981dadfaaaecd","originalFingerprint":"08053f9c98991dc380083d62f9fd02361a35fd390f49f6527c4efa4f7026e135","original":{"currency":"INR","amountMinor":124000,"lines":[{"lineId":"a-1","name":"É oil","detail":"500 ml","quantity":1,"amountMinor":5000},{"lineId":"z-1","name":"दाल \"A\"","detail":"1 kg\nsealed","quantity":2,"amountMinor":11000}]}}}}''';
      final wire = Transport()
        ..data = (jsonDecode(raw)['data'] as Map).cast<String, dynamic>();
      final life = Object();
      final client = AuthenticatedWorkspaceOrderIdentityGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
        ),
        accountUserId: 'buyer-1',
        lifetime: () => life,
        credentials: Credentials(),
        transport: wire,
      );
      final result = await client.read(
        role: WorkspaceOrderIdentityRole.buyer,
        storeId: 'workspace-1',
        orderId: 'MS-interop',
        purchaseId: 'purchase-1',
      );
      expect(result.state, WorkspaceOrderIdentityState.linked);
      expect(
        result.identity!.originalFingerprint,
        '08053f9c98991dc380083d62f9fd02361a35fd390f49f6527c4efa4f7026e135',
      );
      expect(result.identity!.lines.last.name, 'दाल "A"');
      expect(result.identity!.lines.last.detail, '1 kg\nsealed');
    },
  );
  late Object? context;
  late Transport transport;
  late Credentials credentials;
  late AuthenticatedWorkspaceOrderIdentityGateway gateway;
  setUp(() {
    context = Object();
    transport = Transport();
    credentials = Credentials();
    gateway = AuthenticatedWorkspaceOrderIdentityGateway(
      endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
      ),
      accountUserId: 'buyer-1',
      lifetime: () => context,
      credentials: credentials,
      transport: transport,
    );
  });
  Future<WorkspaceOrderIdentityResult> read() => gateway.read(
    role: WorkspaceOrderIdentityRole.buyer,
    storeId: 'workspace-1',
    orderId: 'MS-2841',
    purchaseId: 'purchase-1',
  );

  test(
    'an old gateway cannot start a read after its lifetime is retired',
    () async {
      context = Object(); // New A generation after A-B-A, same actor ID.
      expect((await read()).state, WorkspaceOrderIdentityState.unavailable);
      expect(transport.calls, 0);
    },
  );

  test(
    'exact buyer tuple and immutable original facts decode without commerce mutation',
    () async {
      final result = await read();
      expect(result.state, WorkspaceOrderIdentityState.linked);
      expect(result.identity!.buyerId, 'customer-1');
      expect(result.identity!.amountMinor, 124000);
      expect(result.identity!.lines.single.quantity, 2);
      expect(transport.sent, {
        'operation': 'readBuyerOrderIdentity',
        'storeId': 'workspace-1',
        'orderId': 'MS-2841',
        'purchaseId': 'purchase-1',
      });
      expect(credentials.modes, [SocialAppCheckTokenMode.standard]);
      expect(() => result.identity!.lines.clear(), throwsUnsupportedError);
    },
  );

  for (final key in [
    'schemaVersion',
    'viewerRole',
    'viewerUserId',
    'storeId',
    'orderId',
    'state',
  ]) {
    test('mismatched $key is unavailable, never a different order', () async {
      transport.data[key] = 'wrong';
      expect((await read()).state, WorkspaceOrderIdentityState.unavailable);
    });
  }
  for (final key in [
    'purchaseId',
    'buyerId',
    'sourceRevision',
    'serviceRevision',
    'originalFingerprint',
  ]) {
    test('missing identity $key is unavailable', () async {
      (transport.data['identity'] as Map).remove(key);
      expect((await read()).state, WorkspaceOrderIdentityState.unavailable);
    });
  }
  test(
    'changed purchased facts or different expected fingerprint cannot bind',
    () async {
      ((transport.data['identity'] as Map)['original'] as Map)['amountMinor'] =
          0;
      expect((await read()).state, WorkspaceOrderIdentityState.unavailable);
      transport.data = response();
      expect(
        (await gateway.read(
          role: WorkspaceOrderIdentityRole.buyer,
          storeId: 'workspace-1',
          orderId: 'MS-2841',
          purchaseId: 'purchase-1',
          expectedOriginalFingerprint: 'b' * 64,
        )).state,
        WorkspaceOrderIdentityState.unavailable,
      );
    },
  );
  test(
    'seller may read legacy unlinked; buyer cannot treat it as linked',
    () async {
      final seller = AuthenticatedWorkspaceOrderIdentityGateway(
        endpoint: gateway.endpoint,
        accountUserId: 'owner-1',
        lifetime: () => context,
        credentials: credentials,
        transport: transport,
      );
      transport.data = response(role: 'seller')..remove('identity');
      transport.data['state'] = 'unlinked';
      expect(
        (await seller.read(
          role: WorkspaceOrderIdentityRole.seller,
          storeId: 'workspace-1',
          orderId: 'MS-2841',
        )).state,
        WorkspaceOrderIdentityState.unlinked,
      );
      transport.data = response()..remove('identity');
      transport.data['state'] = 'unlinked';
      expect((await read()).state, WorkspaceOrderIdentityState.unavailable);
    },
  );
  test('retirement during credentials prevents dispatch', () async {
    final token = Completer<String>();
    credentials.token = token;
    final pending = read();
    context = null;
    token.complete('host-token');
    expect((await pending).state, WorkspaceOrderIdentityState.unavailable);
    expect(transport.calls, 0);
  });
  test('late response after A-B-A generation change is discarded', () async {
    transport.pending = Completer<void>();
    final pending = read();
    await Future<void>.delayed(Duration.zero);
    context = Object();
    transport.pending!.complete();
    expect((await pending).state, WorkspaceOrderIdentityState.unavailable);
  });
  test(
    'network failure, HTTP denial and invalid request do not become empty success',
    () async {
      transport.fail = true;
      expect((await read()).state, WorkspaceOrderIdentityState.unavailable);
      transport.fail = false;
      transport.status = 404;
      expect((await read()).state, WorkspaceOrderIdentityState.unavailable);
      transport.status = 200;
      expect(
        (await gateway.read(
          role: WorkspaceOrderIdentityRole.buyer,
          storeId: 'workspace-1',
          orderId: 'MS-2841',
        )).state,
        WorkspaceOrderIdentityState.unavailable,
      );
      expect(transport.calls, 2);
    },
  );
}

Map<String, dynamic> purchaseResponse({String role = 'buyer'}) {
  final original = <String, Object>{
    'currency': 'INR',
    'lines': [
      <String, Object>{
        'lineId': 'line-one',
        'skuId': 'sku-one',
        'canonicalProductId': 'product-one',
        'verifiedPackId': 'pack-one',
        'offerId': 'offer-one',
        'offerRevision': 'offer-revision-1',
        'name': 'दाल',
        'packLabel': '1 kg',
        'quantityMilli': 1000,
        'quantityUnit': 'pack',
        'unitPriceMinor': 10051,
        'lineTotalMinor': 10051,
      },
    ],
    'totals': <String, int>{
      'itemsMinor': 10051,
      'discountMinor': 51,
      'taxMinor': 5,
      'deliveryMinor': 10,
      'freightMinor': 0,
      'paymentFeeMinor': 0,
      'tipMinor': 0,
      'totalMinor': 10015,
    },
  };
  return {
    'schemaVersion': 2,
    'realm': 'evaluation',
    'authNamespace': 'firebase-default',
    'viewerRole': role,
    'viewerUserId': role == 'buyer' ? 'buyer-1' : 'owner-1',
    'purchaseId': 'purchase-v2',
    'buyerId': 'opaque-buyer',
    'sourceRevision': 'revision-1',
    'state': 'original_facts',
    'orders': [
      {
        'factsVersion': 2,
        'storeId': 'store-one',
        'orderId': 'order-v2',
        'original': original,
        'originalFingerprint': sha256
            .convert(
              utf8.encode(
                jsonEncode({
                  'factsVersion': 2,
                  'storeId': 'store-one',
                  'orderId': 'order-v2',
                  'original': original,
                }),
              ),
            )
            .toString(),
      },
    ],
  };
}

Map<String, dynamic> purchaserPurchaseResponse({String role = 'buyer', String kind = 'store'}) {
  final data = commodityPurchaseResponse(role: role)..['schemaVersion'] = 11;
  final order = data['orders'][0] as Map<String, dynamic>; order['factsVersion'] = 11;
  order['original']['purchaser'] = kind == 'personal' ? {'schemaVersion': 1, 'kind': kind} : {
    'schemaVersion': 1, 'kind': kind, 'storeId': 'buying-store', 'name': 'Evaluation buying Store', 'purpose': 'restock'};
  rehashPurchaseOrder(order); return data;
}
Map<String, dynamic> purchaserReferenceResponse() {
  final data = referenceResponse()..['schemaVersion'] = 3 ..['buyingStoreId'] = 'buying-store';
  data['references'][0]['originalFingerprint'] = purchaserPurchaseResponse()['orders'][0]['originalFingerprint']; return data;
}

Map<String, dynamic> commodityPurchaseResponse({String role = 'buyer'}) {
  final data = supplierTaxPurchaseResponse(role: role, declaration: null)..['schemaVersion'] = 10;
  final order = data['orders'][0] as Map<String,dynamic>; order['factsVersion'] = 10;
  for (final l in order['original']['lines']) {
    l['scheduledFulfilment'] = null; l['publicListing']['channel'] = 'bulk';
    l['publicListing']['listingId'] = 'listing-${sha256.convert(utf8.encode(jsonEncode([1,'evaluation',order['storeId'],l['skuId'],'bulk'])))}';
    l['offerRevision'] = 'commodity-2-AAAAAAAAAAAAAAAA';
    l['commodityPriceSnapshot'] = {'schemaVersion': 1, 'termsRevision': l['offerRevision'], 'confirmationRevision': 2,
      'confirmedAt': '2026-10-01T12:00:00.000Z', 'validUntil': '2026-10-01T14:00:00.000Z', 'frequent': true,
      'agreedAt': '2026-10-01T12:10:00.000Z', 'priceMinor': l['unitPriceMinor'], 'minimumPacks': 1, 'incrementPacks': 1, 'tiers': []};
  }
  rehashPurchaseOrder(order); return data;
}

Map<String, dynamic> supplierTaxPurchaseResponse({String role = 'buyer', Map<String, Object>? declaration = const {
  'version': 2, 'rateBasisPoints': 500, 'basis': 'included'}}) {
  final data = supplierQuotePurchaseResponse(role: role, unknown: true)..['schemaVersion'] = 9;
  final order = data['orders'][0] as Map<String, dynamic>; order['factsVersion'] = 9;
  for (final line in order['original']['lines']) {
    line['supplierTaxSnapshot'] = declaration == null ? null : {
      'schemaVersion': 1, 'termsRevision': 'purchased-terms-v1',
      'observedAt': '2026-10-01T12:00:00.000Z', 'expiresAt': '2026-10-02T12:00:00.000Z',
      'declaration': declaration,
    };
  }
  rehashPurchaseOrder(order);
  return (jsonDecode(jsonEncode(data)) as Map).cast<String, dynamic>();
}

Map<String, dynamic> supplierQuotePurchaseResponse({String role = 'buyer', bool unknown = false}) {
  // Controlled host fixture, not an owner-created native record or real quote.
  final data = fulfilmentPurchaseResponse(role: role)..['schemaVersion'] = 8;
  final order = data['orders'][0] as Map<String, dynamic>; order['factsVersion'] = 8;
  final lines = order['original']['lines'] as List;
  if (!unknown) {
    for (final line in lines) {
      line['scheduledFulfilment'] = null;
      line['publicListing']['channel'] = 'bulk';
      line['publicListing']['listingId'] = 'listing-${sha256.convert(utf8.encode(jsonEncode([1, 'evaluation', order['storeId'], line['skuId'], 'bulk'])))}';
    }
  }
  order['original']['supplierQuote'] = unknown ? null : {'schemaVersion': 1, 'realm': 'evaluation',
    'quoteId': 'bulk-${'a' * 64}', 'acceptedRevision': 3, 'agreementFingerprint': 'b' * 64,
    'offerRevision': 2, 'acceptedAt': '2026-10-20T12:00:00.000Z', 'validUntil': '2026-10-20T13:00:00.000Z',
    'merchandiseMinor': order['original']['totals']['itemsMinor'],
    'lines': [for (var i = 0; i < lines.length; i++) {'lineId': lines[i]['lineId'], 'quoteLineId': 'quote-line-$i'}]};
  rehashPurchaseOrder(order);
  return (jsonDecode(jsonEncode(data)) as Map).cast<String, dynamic>();
}

Map<String, dynamic> fulfilmentPurchaseResponse({String role = 'buyer', bool unknown = false}) {
  final data = publicListingPurchaseResponse(role: role)..['schemaVersion'] = 7;
  final order = data['orders'][0] as Map<String, dynamic>; order['factsVersion'] = 7;
  order['original']['fulfilmentContext'] = unknown ? null : {
    'schemaVersion': 1, 'method': 'delivery', 'recipient': {'name': 'Evaluation recipient', 'phone': '9876501234'},
    'address': {'line': 'Evaluation house 12', 'area': 'Evaluation area', 'pinCode': '342003', 'landmark': ''},
    'instructions': [{'lineId': order['original']['lines'][0]['lineId'], 'text': 'दरवाज़े पर दें'}],
  };
  rehashPurchaseOrder(order);
  return (jsonDecode(jsonEncode(data)) as Map).cast<String, dynamic>();
}

Map<String, dynamic> publicListingPurchaseResponse({String role = 'buyer', bool allNull = false}) {
  final data = scheduledPurchaseResponse(role: role)..['schemaVersion'] = 6;
  final order = data['orders'][0] as Map<String, dynamic>;
  order['factsVersion'] = 6;
  for (final line in order['original']['lines']) {
    line['publicListing'] = allNull ? null : jsonDecode(jsonEncode(line['scheduledFulfilment']['listing']));
  }
  rehashPurchaseOrder(order);
  return data;
}

Map<String, dynamic> scheduledPurchaseResponse({String role = 'buyer', bool selected = true}) {
  final response = (jsonDecode(jsonEncode(variantPurchaseResponse(role: role))) as Map).cast<String, dynamic>();
  response['schemaVersion'] = 5;
  final order = response['orders'][0] as Map<String, dynamic>;
  order['factsVersion'] = 5;
  final line = order['original']['lines'][0] as Map<String, dynamic>;
  line['scheduledFulfilment'] = selected ? {
    'schemaVersion': 1, 'method': 'scheduled', 'listing': {
      'schemaVersion': 1, 'realm': 'evaluation',
      'listingId': 'listing-${sha256.convert(utf8.encode(jsonEncode([1, 'evaluation', order['storeId'], line['skuId'], 'retail'])))}',
      'storeId': order['storeId'], 'skuId': line['skuId'], 'canonicalProductId': line['canonicalProductId'],
      'verifiedPackId': line['verifiedPackId'], 'channel': 'retail'},
    'sourceRevision': 'eligibility-original-one', 'locationKey': 'opaque-destination-one', 'slotId': 'slot-original-one',
    'startsAt': '2026-10-15T23:59:59.123456Z', 'endsAt': '2026-10-16T00:00:00.000001Z',
  } : null;
  rehashPurchaseOrder(order);
  // Represent actual decoded JSON, including malformed nullable fields in tests.
  return (jsonDecode(jsonEncode(response)) as Map).cast<String, dynamic>();
}

Map<String, dynamic> variantPurchaseResponse({String role = 'buyer', String variant = 'Pink · 128 GB'}) {
  final response = attributedPurchaseResponse(role: role)..['schemaVersion'] = 4;
  final order = response['orders'][0] as Map<String, dynamic>;
  order['factsVersion'] = 4;
  ((order['original'] as Map)['lines'] as List).single['variant'] = variant;
  rehashPurchaseOrder(order);
  return response;
}

Map<String, dynamic> attributedPurchaseResponse({String role = 'buyer', bool empty = false}) {
  final response = purchaseResponse(role: role)..['schemaVersion'] = 3;
  final order = response['orders'][0] as Map<String, dynamic>;
  order['factsVersion'] = 3;
  final original = order['original'] as Map<String, Object>;
  original['benefitAttribution'] = {'schemaVersion': 1, 'components': empty ? <Object>[] : [
    {'componentId': 'discount-component', 'benefitId': 'supplier-coupon', 'benefitRevision': 'benefit-v1',
      'label': 'Supplier saving', 'publisherType': 'supplier', 'effect': 'instant_discount', 'amountBasis': 'applied',
      'sourceReference': 'trusted-benefit-one', 'funderReference': 'private-funder-one', 'amountMinor': 51,
      'allocations': [{'lineId': 'line-one', 'amountMinor': 51}]},
    {'componentId': 'cashback-component', 'benefitId': 'payment-offer', 'benefitRevision': 'benefit-v2',
      'label': 'Payment cashback offer', 'publisherType': 'payment', 'effect': 'cashback_offer', 'amountBasis': 'maximum',
      'sourceReference': 'trusted-benefit-two', 'funderReference': 'private-funder-two', 'amountMinor': 25,
      'allocations': [{'lineId': 'line-one', 'amountMinor': 25}]},
  ]};
  if (empty) {
    final totals = original['totals'] as Map<String, int>;
    totals['discountMinor'] = 0; totals['totalMinor'] = 10066;
  }
  rehashPurchaseOrder(order);
  return response;
}

void rehashPurchaseOrder(Map<String, dynamic> order) {
  order['originalFingerprint'] = sha256.convert(utf8.encode(jsonEncode({
    'factsVersion': order['factsVersion'], 'storeId': order['storeId'], 'orderId': order['orderId'], 'original': order['original'],
  }))).toString();
}

Map<String, dynamic> attributedOperationalResponse({String role = 'buyer'}) {
  final order = attributedPurchaseResponse(role: role)['orders'][0];
  return operationalResponse(role: role)..['originalFactsVersion'] = 3
    ..['original'] = order['original'] ..['originalFingerprint'] = order['originalFingerprint'];
}

Map<String, dynamic> variantOperationalResponse({String role = 'buyer'}) {
  final order = variantPurchaseResponse(role: role)['orders'][0];
  return operationalResponse(role: role)..['originalFactsVersion'] = 4
    ..['original'] = order['original'] ..['originalFingerprint'] = order['originalFingerprint'];
}

Map<String, dynamic> scheduledOperationalResponse({String role = 'buyer'}) {
  final order = scheduledPurchaseResponse(role: role)['orders'][0];
  return operationalResponse(role: role)..['originalFactsVersion'] = 5
    ..['original'] = order['original'] ..['originalFingerprint'] = order['originalFingerprint'];
}

Map<String, dynamic> referenceResponse({String role = 'buyer'}) {
  final purchase = purchaseResponse(role: role);
  final order = purchase['orders'][0];
  return {
    'schemaVersion': 2,
    'realm': 'evaluation',
    'authNamespace': 'firebase-default',
    'viewerRole': role,
    'viewerUserId': role == 'buyer' ? 'buyer-1' : 'owner-1',
    'storeId': role == 'seller' ? 'store-one' : null,
    'coverage': role == 'buyer'
        ? 'saved_original_facts'
        : 'indexed_original_facts',
    'references': [
      {
        'purchaseId': purchase['purchaseId'],
        'storeId': order['storeId'],
        'orderId': order['orderId'],
        'originalFingerprint': order['originalFingerprint'],
        'sourceRevision': purchase['sourceRevision'],
      },
    ],
    'nextCursor': null,
  };
}

AuthenticatedWorkspaceOrderIdentityGateway projectionGateway(
  Transport wire, {
  String account = 'buyer-1',
  Object? Function()? lifetime,
  WorkspacePurchasedWarrantyReader? purchasedWarrantyReader,
  WorkspacePurchasedUnitSource? purchasedUnitSource,
  WorkspaceOrderDocumentSource? orderDocumentSource,
}) => AuthenticatedWorkspaceOrderIdentityGateway(
  endpoint: Uri.parse(
    'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
  ),
  accountUserId: account,
  lifetime: lifetime ?? () => 'fixed-host-lifetime',
  credentials: Credentials(),
  transport: wire,
  purchasedWarrantyReader: purchasedWarrantyReader,
  purchasedUnitSource: purchasedUnitSource,
  orderDocumentSource: orderDocumentSource,
);

WorkspacePurchaseReference operationalReference() {
  final raw = referenceResponse()['references'][0];
  return WorkspacePurchaseReference(
    purchaseId: raw['purchaseId'],
    storeId: raw['storeId'],
    orderId: raw['orderId'],
    originalFingerprint: raw['originalFingerprint'],
    sourceRevision: raw['sourceRevision'],
  );
}

Map<String, dynamic> operationalResponse({String role = 'buyer'}) {
  final original = purchaseResponse(role: role);
  final order = original['orders'][0];
  return {
    'schemaVersion': 1,
    'realm': 'evaluation',
    'authNamespace': 'firebase-default',
    'viewerRole': role,
    'viewerUserId': role == 'buyer' ? 'buyer-1' : 'owner-1',
    'purchaseId': original['purchaseId'],
    'storeId': order['storeId'],
    'orderId': order['orderId'],
    'sourceRevision': original['sourceRevision'],
    'originalFingerprint': order['originalFingerprint'],
    'original': order['original'],
    'operationalSourceRevision': 'operational-v1',
    'revision': 1,
    'stage': 'Confirmed',
    'fulfilment': 'delivery',
    'placedAt': '2026-10-16T12:00:00.000Z',
    'acceptanceDeadline': '2026-10-16T12:05:00.000Z',
    'fulfilmentDeadline': '2026-10-16T13:00:00.000Z',
    'permittedActions': role == 'seller' ? ['accept', 'reject'] : <String>[],
    'paymentVerification': 'not_supplied',
    'stockVerification': 'not_supplied',
    'rejectionReason': null,
    if (role == 'seller') 'customerLabel': 'Evaluation buyer',
    if (role == 'seller') 'address': 'Evaluation address',
  };
}

void originalPurchasedDeviceSourceTests() {
  test('AGG08-DEVICE native trimmed text rejects edge NEL while preserving literal interiors', () {
    const plain = WorkspacePurchasedUnitRow(id: 'host-unit', serial: 'printed serial');
    for (final field in ['id', 'serial', 'imei1', 'imei2']) {
      for (final edge in ['\u0085X', 'X\u0085', '\u0085']) {
        final fields = {...plain.toJson(), field: edge};
        final row = WorkspacePurchasedUnitRow(id: fields['id'] as String, serial: fields['serial'] as String,
          imei1: fields['imei1'] as String, imei2: fields['imei2'] as String);
        expect(row.ready, isFalse, reason: 'Published $field must follow native trimmed text.');
      }
    }
    const literal = WorkspacePurchasedUnitRow(id: 'unit\u0085middle', serial: '\u180eprinted\u0085serial',
      imei1: 'printed\ufeffinside');
    expect(literal.ready, isTrue);
    expect(WorkspacePurchasedUnitRow.fromJson(literal.toJson()).toJson(), literal.toJson());
  });
  const capture = String.fromEnvironment('AGG08_DEVICE_WIRE_EXPORT_PATH');
  // This file is emitted by the actual SDK loopback run, not a phone provider.
  Map<String, dynamic> load() => (jsonDecode(File(capture).readAsStringSync()) as Map).cast<String, dynamic>();
  for (final role in WorkspaceOrderIdentityRole.values) {
    test('AGG08-DEVICE actual SDK wire native ${role.name} read and original status recovery', () async {
      final data = load(), targetData = (data[role.name] as Map).cast<String, dynamic>();
      final account = (role == WorkspaceOrderIdentityRole.seller ? data['sellerProjection'] : data['before'])['viewerUserId'] as String;
      final reference = targetData['reference'] as Map;
      final credentials = Credentials(); var visit = Object();
      final wire = Transport()..respond = (body) {
        switch (body['operation']) {
          case 'readBuyerPurchaseProjection': return Map<String, dynamic>.from(data['before']);
          case 'readStorePurchaseProjection': return Map<String, dynamic>.from(data['sellerProjection']);
          case 'readPurchasedUnits': return Map<String, dynamic>.from(data[role == WorkspaceOrderIdentityRole.seller ? 'sellerRead' : 'buyerRead']);
          case 'reconcilePurchasedUnits': return Map<String, dynamic>.from(data['shareResult']);
          case 'reconcilePurchasedUnitMismatch': return Map<String, dynamic>.from(data['reportResult']);
          case 'readReceivedDeviceReports': return Map<String, dynamic>.from(data['inbox']);
          default: throw StateError('Unexpected original-device operation');
        }
      };
      final base = AuthenticatedWorkspaceOrderIdentityGateway(endpoint: Uri.parse('https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace'),
        accountUserId: account, lifetime: () => visit, credentials: credentials, transport: wire);
      final source = AuthenticatedWorkspacePurchasedUnitSource(base, now: DateTime.now);
      final gateway = AuthenticatedWorkspaceOrderIdentityGateway(endpoint: base.endpoint, accountUserId: account,
        lifetime: () => visit, credentials: credentials, transport: wire, purchasedUnitSource: source);
      final projection = await gateway.readPurchaseProjection(role: role, realm: 'evaluation', purchaseId: reference['purchaseId'],
        storeId: role == WorkspaceOrderIdentityRole.seller ? reference['storeId'] : null,
        orderId: role == WorkspaceOrderIdentityRole.seller ? reference['orderId'] : null);
      expect(projection, isNotNull);
      final ref = WorkspacePurchaseReference(purchaseId: reference['purchaseId'], storeId: reference['storeId'], orderId: reference['orderId'],
        originalFingerprint: reference['originalFingerprint'], sourceRevision: reference['sourceRevision']);
      final line = projection!.orders.first.lines.first;
      final target = WorkspacePurchasedLineTarget(accountUserId: account, role: role, realm: 'evaluation', reference: ref, line: line);
      expect(target.binding, targetData['binding']);
      final read = await gateway.readPurchasedUnits(role: role, realm: 'evaluation', reference: ref, line: line);
      expect(read, isNotNull); expect(read!.rows.single.toJson(), data['buyerRead']['record']['rows'].single);
      expect(wire.sent!['target'], targetData);
      if (role == WorkspaceOrderIdentityRole.seller) {
        final grant = read.ownerAccess!;
        final result = await gateway.publishPurchasedUnits(command: WorkspacePurchasedUnitPublishCommand.fromJson(data['command']),
          realm: 'evaluation', reference: ref, line: line, reconcile: true);
        expect(result?.state, WorkspacePurchasedUnitPublishState.applied); expect(result!.record!.rows, hasLength(1));
        expect(source.ownerAccessCurrent(grant), isTrue, reason: 'An authorized refresh does not retire a still-current permission grant.');
        final inbox = await gateway.readReceivedDeviceReports(realm: 'evaluation', reference: ref, line: line);
        expect(inbox!.reports.single.note, data['reportCommand']['note']);
        expect(inbox.reports.single.supportCase, isNull);
      } else {
        final result = await gateway.reportPurchasedUnitMismatch(command: WorkspacePurchasedUnitMismatchCommand.fromJson(data['reportCommand']),
          realm: 'evaluation', reference: ref, line: line, reconcile: true);
        expect(result?.state, WorkspacePurchasedUnitPublishState.applied); expect(result?.reportId, data['reportResult']['reportId']);
      }
      expect(wire.requests.where((r) => ['sharePurchasedUnits', 'reportPurchasedUnitMismatch'].contains(r['operation'])), isEmpty);
      expect(credentials.modes, everyElement(SocialAppCheckTokenMode.standard));
      final calls = wire.calls; visit = Object();
      expect(source.isCurrent, isFalse);
      expect(await source.read(target), isNull); expect(wire.calls, calls);
    }, skip: capture.isEmpty ? 'Requires explicit actual SDK host capture; never inject on OPPO.' : false);
  }
  test('AGG08-DEVICE configured source opt-in keeps review and unavailable construction unchanged', () {
    final gateway = projectionGateway(Transport());
    expect(gateway.purchasedUnitSource, isNull);
    final configured = AuthenticatedWorkspaceOrderIdentityGateway(endpoint: gateway.endpoint, accountUserId: gateway.accountUserId,
      lifetime: () => 'isolated-native-visit', credentials: Credentials(), transport: Transport(), enableOriginalDeviceSource: true);
    expect(configured.purchasedUnitSource, isA<AuthenticatedWorkspacePurchasedUnitSource>());
    expect(identical(configured.purchasedUnitSource, configured.purchasedUnitSource), isTrue);
  });
  for (final fault in ['account', 'binding', 'realm', 'extra', 'duplicate', 'expired', 'invalid-time', 'incomplete']) {
    test('AGG08-DEVICE native rejects $fault without granting access', () async {
      final wire = Transport()..data = purchaseResponse(role: 'seller');
      final gateway = projectionGateway(wire, account: 'owner-1');
      final original = await gateway.readPurchaseProjection(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation',
        purchaseId: 'purchase-v2', storeId: 'store-one', orderId: 'order-v2');
      final line = original!.orders.first.lines.first;
      final target = WorkspacePurchasedLineTarget(accountUserId: 'owner-1', role: WorkspaceOrderIdentityRole.seller,
        realm: 'evaluation', reference: WorkspacePurchaseReference(purchaseId: original.purchaseId,
          storeId: original.orders.first.storeId, orderId: original.orders.first.orderId,
          originalFingerprint: original.orders.first.originalFingerprint, sourceRevision: original.sourceRevision), line: line);
      final r = <String, dynamic>{'schemaVersion': 1, 'realm': 'evaluation', 'viewerUserId': 'owner-1', 'targetBinding': target.binding,
        'record': {'revision': 1, 'rows': [{'id': 'device-one', 'serial': 'literal', 'imei1': '', 'imei2': ''}],
          'observedAt': '2026-10-16T12:00:00.000Z', 'accessExpiresAt': '2026-10-16T12:05:00.000Z', 'complete': true}};
      switch (fault) {
        case 'account': r['viewerUserId'] = 'another-account';
        case 'binding': r['targetBinding'] = 'a' * 64;
        case 'realm': r['realm'] = 'production';
        case 'extra': r['permission'] = true;
        case 'duplicate': r['record']['rows'] = [r['record']['rows'].first, r['record']['rows'].first];
        case 'expired': r['record']['accessExpiresAt'] = '2026-10-16T12:00:00.000Z';
        case 'invalid-time': r['record']['observedAt'] = '2026-10-16';
        case 'incomplete': r['record']['complete'] = false;
      }
      wire.data = r;
      final source = AuthenticatedWorkspacePurchasedUnitSource(gateway, now: () => DateTime.utc(2026, 10, 16, 12));
      expect(await source.read(target), isNull);
    });
  }
  test('AGG08-DEVICE expired grant cannot revive after refresh or clock correction', () async {
    final wire = Transport()..data = purchaseResponse(role: 'seller'), gateway = projectionGateway(wire, account: 'owner-1');
    final original = (await gateway.readPurchaseProjection(role: WorkspaceOrderIdentityRole.seller, realm: 'evaluation',
      purchaseId: 'purchase-v2', storeId: 'store-one', orderId: 'order-v2'))!;
    final target = WorkspacePurchasedLineTarget(accountUserId: 'owner-1', role: WorkspaceOrderIdentityRole.seller,
      realm: 'evaluation', reference: WorkspacePurchaseReference(purchaseId: original.purchaseId,
        storeId: original.orders.first.storeId, orderId: original.orders.first.orderId,
        originalFingerprint: original.orders.first.originalFingerprint, sourceRevision: original.sourceRevision), line: original.orders.first.lines.first);
    var time = DateTime.utc(2026, 10, 16, 12);
    wire.data = {'schemaVersion': 1, 'realm': 'evaluation', 'viewerUserId': 'owner-1', 'targetBinding': target.binding,
      'record': {'revision': 0, 'rows': [], 'observedAt': '2026-10-16T12:00:00.000Z', 'accessExpiresAt': '2026-10-16T12:05:00.000Z', 'complete': true}};
    final source = AuthenticatedWorkspacePurchasedUnitSource(gateway, now: () => time);
    final old = (await source.read(target))!.ownerAccess!;
    expect(source.ownerAccessCurrent(old), isTrue);
    time = time.add(const Duration(minutes: 6)); expect(source.ownerAccessCurrent(old), isFalse);
    time = DateTime.utc(2026, 10, 16, 12);
    final next = (await source.read(target))!.ownerAccess!;
    expect(identical(old, next), isFalse); expect(source.ownerAccessCurrent(old), isFalse); expect(source.ownerAccessCurrent(next), isTrue);
  });
}
