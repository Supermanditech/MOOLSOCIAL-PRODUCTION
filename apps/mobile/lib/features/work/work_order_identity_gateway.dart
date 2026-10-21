import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../buy/buy_v2_models.dart';
import '../shared/social_content_gateway.dart';
import 'work_customer_feedback.dart';
import 'work_models.dart' show WorkspaceRestockPurchaseOriginal, WorkspaceSupplierGoodsReceipt, WorkspacePurchasedUnitRow,
  WorkspacePurchasedUnitPublishCommand, WorkspacePurchasedUnitMismatchCommand, WorkspaceIssueRecord;

enum WorkspaceOrderIdentityState { linked, unlinked, unavailable }

enum WorkspaceOrderIdentityRole { buyer, seller }

/// Read-only bridge into the existing Store inbox. Reader/account/realm are
/// resolved per request, never captured from a retired root session.
class WorkspacePrivateStarsFeedbackAdapter implements StoreStarsOnlyFeedbackAdapter {
  const WorkspacePrivateStarsFeedbackAdapter({required this.reader, required this.realm});
  final AuthenticatedWorkspaceOrderIdentityGateway? Function() reader;
  final String Function() realm;
  @override
  bool get commandRecoveryReady => false;
  @override
  Future<StoreFeedbackPage> load(StoreFeedbackScope scope, {String? cursor}) async {
    StoreFeedbackPage unavailable() => StoreFeedbackPage(scope: scope, coverage: StoreFeedbackCoverage.unavailable);
    final identity = reader(), sourceRealm = realm();
    if (identity == null || !identity.isCurrent || identity.accountUserId != scope.account ||
        !const ['evaluation', 'production'].contains(sourceRealm)) {
      return unavailable();
    }
    final page = await AuthenticatedWorkspaceOrderOperationsGateway(identity)
      .listStoreProductStars(realm: sourceRealm, storeId: scope.store, cursor: cursor);
    if (page == null || !identity.isCurrent || !identical(reader(), identity) || realm() != sourceRealm) return unavailable();
    return StoreFeedbackPage(scope: scope, coverage: StoreFeedbackCoverage.partial, nextCursor: page.nextCursor,
      entries: page.ratings.map((rating) => StoreFeedbackEntry(storeId: scope.store, id: rating.target.id,
        version: rating.revision.toString(), kind: StoreFeedbackKind.product, authorLabel: 'Customer',
        text: '', stars: rating.stars, orderId: rating.target.reference.orderId,
        productId: rating.target.productId, productLabel: rating.target.productLabel)).toList());
  }
  // Old uncertain reply/report requests remain in their original journals.
  // This stars-only reader cannot acknowledge, discard or resubmit them.
  @override
  Future<StoreFeedbackResult> submit(StoreFeedbackCommand command) async =>
    StoreFeedbackResult(command: command, outcome: StoreFeedbackOutcome.unknown);
  @override
  Future<StoreFeedbackResult> reconcile(StoreFeedbackCommand original) async =>
    StoreFeedbackResult(command: original, outcome: StoreFeedbackOutcome.unknown);
}

/// Identity only: not payment, fulfilment, document or seller-action authority.
class WorkspaceOrderIdentityResult {
  const WorkspaceOrderIdentityResult(this.state, {this.identity});
  final WorkspaceOrderIdentityState state;
  final WorkspacePurchasedOrderIdentity? identity;
}

class WorkspacePurchasedOrderIdentity {
  WorkspacePurchasedOrderIdentity({
    required this.buyerId,
    required this.purchaseId,
    required this.storeId,
    required this.orderId,
    required this.sourceRevision,
    required this.serviceRevision,
    required this.originalFingerprint,
    required this.amountMinor,
    required List<WorkspaceOriginalOrderLine> lines,
  }) : lines = List.unmodifiable(lines);
  final String buyerId, purchaseId, storeId, orderId;
  final String sourceRevision, serviceRevision, originalFingerprint;
  final int amountMinor;
  final List<WorkspaceOriginalOrderLine> lines;
}

class WorkspaceOriginalOrderLine {
  const WorkspaceOriginalOrderLine({
    required this.lineId,
    required this.name,
    required this.detail,
    required this.quantity,
    required this.amountMinor,
  });
  final String lineId, name, detail;
  // Original legacy line amount, not an inferred SKU, unit price or quote.
  final int quantity, amountMinor;
  Map<String, Object> toJson() => {
    'lineId': lineId,
    'name': name,
    'detail': detail,
    'quantity': quantity,
    'amountMinor': amountMinor,
  };
}

/// Concrete read-only client for the approved identity contract. Each instance
/// belongs to one authenticated actor/lifetime. Caller must retire the lifetime
/// on auth generation changes (including A-B-A); never pass display/contact IDs.
/// Not injected into order feeds until the genuine purchase producer is ready.
class AuthenticatedWorkspaceOrderIdentityGateway {
  AuthenticatedWorkspaceOrderIdentityGateway({
    required this.endpoint,
    required this.accountUserId,
    required this.lifetime,
    required this.credentials,
    required this.transport,
    this.purchasedWarrantyReader,
    this.purchasedUnitSource,
  }) : _ownerLifetime = lifetime() {
    if (endpoint.scheme != 'https' ||
        endpoint.host !=
            'asia-south1-moolsocial-dev-503018.cloudfunctions.net' ||
        endpoint.path != '/moolSocialWorkspace' ||
        endpoint.hasPort ||
        endpoint.hasQuery ||
        endpoint.hasFragment ||
        endpoint.userInfo.isNotEmpty ||
        !_id(accountUserId)) {
      throw ArgumentError('Invalid order identity scope.');
    }
  }
  final Uri endpoint;
  final String accountUserId;
  final Object? Function() lifetime;
  final Object? _ownerLifetime;
  final SocialContentCredentials credentials;
  final SocialContentTransport transport;
  /// Proposed frontend supplement only. No warranty endpoint is configured here.
  final WorkspacePurchasedWarrantyReader? purchasedWarrantyReader;
  final WorkspacePurchasedUnitSource? purchasedUnitSource;
  bool get isCurrent => _ownerLifetime != null && lifetime() == _ownerLifetime;

  Future<WorkspacePurchasedWarrantyRead?> readPurchasedWarranty({
    required WorkspaceOrderIdentityRole role,
    required String realm,
    required WorkspacePurchaseReference reference,
    required WorkspacePurchasedSkuLine line,
    String? buyingStoreId,
    bool Function()? inputCurrent,
  }) async {
    final reader = purchasedWarrantyReader;
    final readerLifetime = reader?.lifetime;
    if (reader == null) return null;
    return _readPurchasedLineSupplement<WorkspacePurchasedWarrantyRead>(role: role, realm: realm, reference: reference,
      line: line, buyingStoreId: buyingStoreId, inputCurrent: inputCurrent,
      sourceCurrent: () => reader.isCurrent && readerLifetime != null && reader.lifetime == readerLifetime && reader.accountUserId == accountUserId,
      read: (target, _) => reader.read(target), valid: (result, target) => result.validFor(target));
  }

  Future<WorkspacePurchasedUnitsRead?> readPurchasedUnits({required WorkspaceOrderIdentityRole role, required String realm,
    required WorkspacePurchaseReference reference, required WorkspacePurchasedSkuLine line, String? buyingStoreId, bool Function()? inputCurrent}) {
    final source = purchasedUnitSource, owner = purchasedUnitSource?.lifetime;
    if (source == null) return Future.value(null);
    return _readPurchasedLineSupplement<WorkspacePurchasedUnitsRead>(role: role, realm: realm, reference: reference,
      line: line, buyingStoreId: buyingStoreId, inputCurrent: inputCurrent,
      sourceCurrent: () => source.isCurrent && owner != null && source.lifetime == owner && source.accountUserId == accountUserId,
      read: (target, _) => source.read(target), valid: (result, target) => result.validFor(target));
  }

  /// Proposed owner-only publisher boundary. No HTTP operation is implemented.
  /// A recovered original command is checked; it is never automatically resent.
  Future<WorkspacePurchasedUnitPublishReply?> publishPurchasedUnits({required WorkspacePurchasedUnitPublishCommand command,
    required String realm, required WorkspacePurchaseReference reference, required WorkspacePurchasedSkuLine line,
    required bool reconcile, bool Function()? inputCurrent}) {
    final source = purchasedUnitSource, lifetime = purchasedUnitSource?.lifetime;
    if (source is! WorkspacePurchasedUnitPublisher || !command.valid) return Future.value(null);
    WorkspacePurchasedUnitOwnerAccess? grant;
    bool authorised() => grant != null && source.ownerAccessCurrent(grant!) && grant!.allows(
      WorkspacePurchasedLineTarget(accountUserId: accountUserId, role: WorkspaceOrderIdentityRole.seller,
        realm: realm, reference: reference, line: line), DateTime.now().toUtc());
    return _readPurchasedLineSupplement<WorkspacePurchasedUnitPublishReply>(role: WorkspaceOrderIdentityRole.seller,
      realm: realm, reference: reference, line: line, inputCurrent: inputCurrent,
      sourceCurrent: () => source.isCurrent && lifetime != null && source.lifetime == lifetime && source.accountUserId == accountUserId,
      read: (target, current) async {
        if (command.key.account != accountUserId || command.key.realm != realm || command.key.store != reference.storeId || command.key.binding != target.binding) return null;
        final fresh = await source.read(target);
        if (!current() || fresh == null || !fresh.validFor(target) || !fresh.complete ||
          !reconcile && fresh.revision != command.expectedRevision) {
          return null;
        }
        grant = fresh.ownerAccess;
        if (!authorised()) return null;
        return reconcile ? source.checkSharing(target, command) : source.share(target, command);
      }, valid: (reply, target) => authorised() && reply.validFor(command, target));
  }

  Future<WorkspacePurchasedUnitReportReply?> reportPurchasedUnitMismatch({required WorkspacePurchasedUnitMismatchCommand command,
    required String realm, required WorkspacePurchaseReference reference, required WorkspacePurchasedSkuLine line,
    String? buyingStoreId, required bool reconcile, bool Function()? inputCurrent}) {
    final source = purchasedUnitSource, lifetime = purchasedUnitSource?.lifetime;
    if (source is! WorkspacePurchasedUnitReporter || !command.valid) return Future.value(null);
    final target = WorkspacePurchasedLineTarget(accountUserId: accountUserId, role: WorkspaceOrderIdentityRole.buyer,
      realm: realm, reference: reference, line: line, buyingStoreId: buyingStoreId);
    WorkspacePurchasedUnitReportAccess? grant;
    bool authorised() => grant != null && source.reportAccessCurrent(grant!) && grant!.allows(target, DateTime.now().toUtc());
    return _readPurchasedLineSupplement<WorkspacePurchasedUnitReportReply>(role: WorkspaceOrderIdentityRole.buyer,
      realm: realm, reference: reference, line: line, buyingStoreId: buyingStoreId, inputCurrent: inputCurrent,
      sourceCurrent: () => source.isCurrent && lifetime != null && source.lifetime == lifetime && source.accountUserId == accountUserId,
      read: (target, current) async {
        if (command.key.account != accountUserId || command.key.realm != realm || command.key.store != reference.storeId || command.key.binding != target.binding) return null;
        final fresh = await source.read(target);
        if (!current() || fresh == null || !fresh.validFor(target) || !fresh.complete || !reconcile &&
          (fresh.revision != command.sourceRevision || fresh.fingerprint != command.sourceFingerprint ||
            !command.rows.every((row) => fresh.rows.any((r) => jsonEncode(r.toJson()) == jsonEncode(row.toJson()))))) {
          return null;
        }
        grant = fresh.reportAccess;
        if (!authorised()) return null;
        return reconcile ? source.checkMismatch(target, command) : source.reportMismatch(target, command);
      }, valid: (reply, target) => authorised() && reply.validFor(command, target));
  }

  Future<WorkspaceReceivedDeviceReports?> readReceivedDeviceReports({required String realm, required WorkspacePurchaseReference reference,
    required WorkspacePurchasedSkuLine line, String? cursor, bool Function()? inputCurrent}) {
    final source = purchasedUnitSource, lifetime = purchasedUnitSource?.lifetime;
    if (source is! WorkspaceReceivedDeviceReportSource || cursor != null && (cursor.isEmpty || cursor.length > 512)) return Future.value(null);
    WorkspacePurchaseOrder? original;
    WorkspacePurchasedUnitOwnerAccess? grant;
    return _readPurchasedLineSupplement<WorkspaceReceivedDeviceReports>(role: WorkspaceOrderIdentityRole.seller, realm: realm,
      reference: reference, line: line, inputCurrent: inputCurrent, onOriginal: (value) => original = value,
      sourceCurrent: () => source.isCurrent && lifetime != null && source.lifetime == lifetime && source.accountUserId == accountUserId,
      read: (target, current) async {
        final access = await source.read(target);
        if (!current() || access == null || !access.validFor(target)) return null;
        grant = access.ownerAccess;
        if (grant == null || !source.ownerAccessCurrent(grant!) || !grant!.allows(target, DateTime.now().toUtc())) return null;
        final result = await source.readReceivedReports(target, cursor: cursor);
        if (!current() || result == null || !source.ownerAccessCurrent(grant!) || !grant!.allows(target, DateTime.now().toUtc())) return null;
        return WorkspaceReceivedDeviceReports(target: result.target, revision: result.revision, ownerAccess: result.ownerAccess,
          original: original, reports: result.reports, complete: result.complete, nextCursor: result.nextCursor);
      }, valid: (result, target) => original != null && result.validFor(target, original!) &&
        source.ownerAccessCurrent(result.ownerAccess) && result.ownerAccess.allows(target, DateTime.now().toUtc()) &&
        source.ownerAccessCurrent(grant!) && grant!.allows(target, DateTime.now().toUtc()));
  }

  Future<T?> _readPurchasedLineSupplement<T>({required WorkspaceOrderIdentityRole role, required String realm,
    required WorkspacePurchaseReference reference, required WorkspacePurchasedSkuLine line, String? buyingStoreId,
    bool Function()? inputCurrent, void Function(WorkspacePurchaseOrder)? onOriginal, required bool Function() sourceCurrent,
    required Future<T?> Function(WorkspacePurchasedLineTarget, bool Function()) read, required bool Function(T, WorkspacePurchasedLineTarget) valid}) async {
    var active = true;
    bool current() => active && isCurrent && sourceCurrent() && inputCurrent?.call() != false;
    // Absence is unavailable, not an invented operation against the order API.
    if (!current() || !reference.valid) return null;
    try {
      final target = WorkspacePurchasedLineTarget(accountUserId: accountUserId, role: role, realm: realm,
        buyingStoreId: buyingStoreId, reference: reference, line: line);
      final result = await (() async {
        final original = await readReferencedOrder(role: role, realm: realm, reference: reference,
          buyingStoreId: buyingStoreId, inputCurrent: current);
        if (!current() || original == null) return null;
        final savedLine = original.lines.where((candidate) => candidate.lineId == line.lineId).singleOrNull;
        if (savedLine == null || jsonEncode(savedLine.toJson()) != jsonEncode(line.toJson())) return null;
        onOriginal?.call(original);
        return read(target, current);
      })().timeout(const Duration(seconds: 15));
      return current() && result != null && valid(result, target) ? result : null;
    } on Object { return null; }
    finally { active = false; }
  }

  Future<WorkspacePurchaseReferencePage?> listPurchaseReferences({
    required WorkspaceOrderIdentityRole role,
    required String realm,
    String? storeId,
    String? buyingStoreId,
    String? cursor,
  }) async {
    if (!isCurrent ||
        !['evaluation', 'production'].contains(realm) ||
        (role == WorkspaceOrderIdentityRole.seller
            ? !_id(storeId) || buyingStoreId != null
            : storeId != null || buyingStoreId != null && !_id(buyingStoreId)) ||
        cursor != null && (cursor.isEmpty || cursor.length > 512)) {
      return null;
    }
    try {
      final token = await credentials.firebaseIdToken();
      if (!isCurrent) return null;
      final appCheck = await credentials.appCheckToken(
        SocialAppCheckTokenMode.standard,
      );
      if (!isCurrent) return null;
      final reply = await transport
          .postJson(
            endpoint,
            headers: {
              'accept': 'application/json',
              'authorization': 'Bearer $token',
              'x-firebase-appcheck': appCheck,
              'x-request-id': List.generate(
                16,
                (_) => Random.secure()
                    .nextInt(256)
                    .toRadixString(16)
                    .padLeft(2, '0'),
              ).join(),
            },
            body: {
              'operation': role == WorkspaceOrderIdentityRole.buyer
                  ? 'listBuyerPurchaseReferences'
                  : 'listStorePurchaseReferences',
              'limit': 5,
              'cursor': cursor,
              'storeId': ?storeId,
              'buyingStoreId': ?buyingStoreId,
            },
          )
          .timeout(const Duration(seconds: 20));
      if (!isCurrent ||
          reply.statusCode != 200 ||
          utf8.encode(reply.body).length > 128 * 1024) {
        return null;
      }
      final envelope = _map(jsonDecode(reply.body));
      if (envelope['ok'] != true) return null;
      final data = _exactMap(envelope['data'], [
        'schemaVersion',
        'realm',
        'authNamespace',
        'viewerRole',
        'viewerUserId',
        'storeId',
        'coverage',
        'references',
        'nextCursor',
        if (buyingStoreId != null) 'buyingStoreId',
      ]);
      if (data['schemaVersion'] != (buyingStoreId == null ? 2 : 3) ||
          buyingStoreId != null && data['buyingStoreId'] != buyingStoreId ||
          data['realm'] != realm ||
          data['authNamespace'] != 'firebase-default' ||
          data['viewerRole'] != role.name ||
          data['viewerUserId'] != accountUserId ||
          data['storeId'] != storeId ||
          data['coverage'] !=
              (role == WorkspaceOrderIdentityRole.buyer
                  ? 'saved_original_facts'
                  : 'indexed_original_facts')) {
        return null;
      }
      final raw = data['references'];
      final next = data['nextCursor'];
      if (raw is! List ||
          raw.length > (role == WorkspaceOrderIdentityRole.buyer ? 50 : 5) ||
          next != null &&
              (next is! String ||
                  next.isEmpty ||
                  next.length > 512 ||
                  next == cursor)) {
        return null;
      }
      final references = <WorkspacePurchaseReference>[];
      for (final value in raw) {
        final r = _exactMap(value, const [
          'purchaseId',
          'storeId',
          'orderId',
          'originalFingerprint',
          'sourceRevision',
        ]);
        if ([
              'purchaseId',
              'storeId',
              'orderId',
              'sourceRevision',
            ].any((k) => !_id(r[k])) ||
            r['originalFingerprint'] is! String ||
            !RegExp(
              r'^[a-f0-9]{64}$',
            ).hasMatch(r['originalFingerprint'] as String) ||
            storeId != null && r['storeId'] != storeId) {
          return null;
        }
        references.add(
          WorkspacePurchaseReference(
            purchaseId: r['purchaseId'] as String,
            storeId: r['storeId'] as String,
            orderId: r['orderId'] as String,
            originalFingerprint: r['originalFingerprint'] as String,
            sourceRevision: r['sourceRevision'] as String,
          ),
        );
      }
      if (references
                  .map((r) => (r.purchaseId, r.storeId, r.orderId))
                  .toSet()
                  .length !=
              references.length ||
          !isCurrent) {
        return null;
      }
      return WorkspacePurchaseReferencePage(
        coverage: data['coverage'] as String,
        references: references,
        nextCursor: next as String?,
      );
    } on Object {
      return null;
    }
  }

  Future<WorkspacePurchaseOrder?> readReferencedOrder({
    required WorkspaceOrderIdentityRole role,
    required String realm,
    required WorkspacePurchaseReference reference,
    String? buyingStoreId,
    bool Function()? inputCurrent,
  }) async {
    final result = await readPurchaseProjection(
      role: role,
      realm: realm,
      purchaseId: reference.purchaseId,
      buyingStoreId: buyingStoreId,
      inputCurrent: inputCurrent,
      storeId: role == WorkspaceOrderIdentityRole.seller
          ? reference.storeId
          : null,
      orderId: role == WorkspaceOrderIdentityRole.seller
          ? reference.orderId
          : null,
    );
    if (result == null ||
        !isCurrent ||
        inputCurrent?.call() == false ||
        result.sourceRevision != reference.sourceRevision) {
      return null;
    }
    return result.orders
        .where(
          (o) =>
              o.storeId == reference.storeId &&
              o.orderId == reference.orderId &&
              o.originalFingerprint == reference.originalFingerprint,
        )
        .firstOrNull;
  }

  /// Explicit v2 original-facts reader. Buyer receives authoritative per-Store
  /// references from the purchase; seller must already have its exact tuple.
  /// Never infer these IDs from legacy Buy/Counter orders or enable actions.
  Future<WorkspacePurchaseProjection?> readPurchaseProjection({
    required WorkspaceOrderIdentityRole role,
    required String realm,
    required String purchaseId,
    String? storeId,
    String? orderId,
    String? buyingStoreId,
    bool Function()? inputCurrent,
  }) async {
    bool current() => _ownerLifetime != null && lifetime() == _ownerLifetime && inputCurrent?.call() != false;
    if (!current() ||
        !['evaluation', 'production'].contains(realm) ||
        !_id(purchaseId) ||
        (role == WorkspaceOrderIdentityRole.seller
            ? !_id(storeId) || !_id(orderId) || buyingStoreId != null
            : storeId != null || orderId != null || buyingStoreId != null && !_id(buyingStoreId))) {
      return null;
    }
    try {
      final token = await credentials.firebaseIdToken();
      if (!current()) return null;
      final appCheck = await credentials.appCheckToken(
        SocialAppCheckTokenMode.standard,
      );
      if (!current()) return null;
      final reply = await transport
          .postJson(
            endpoint,
            headers: {
              'accept': 'application/json',
              'authorization': 'Bearer $token',
              'x-firebase-appcheck': appCheck,
              'x-request-id': List.generate(
                16,
                (_) => Random.secure()
                    .nextInt(256)
                    .toRadixString(16)
                    .padLeft(2, '0'),
              ).join(),
            },
            body: {
              'operation': role == WorkspaceOrderIdentityRole.buyer
                  ? 'readBuyerPurchaseProjection'
                  : 'readStorePurchaseProjection',
              'purchaseId': purchaseId,
              'storeId': ?storeId,
              'orderId': ?orderId,
              'buyingStoreId': ?buyingStoreId,
            },
          )
          .timeout(const Duration(seconds: 20));
      if (!current() ||
          reply.statusCode != 200 ||
          utf8.encode(reply.body).length > 512 * 1024) {
        return null;
      }
      final envelope = _map(jsonDecode(reply.body));
      if (envelope['ok'] != true) return null;
      final data = _exactMap(envelope['data'], const [
        'schemaVersion',
        'realm',
        'authNamespace',
        'viewerRole',
        'viewerUserId',
        'purchaseId',
        'buyerId',
        'sourceRevision',
        'state',
        'orders',
      ]);
      if (data['schemaVersion'] is! int || !const [2, 3, 4, 5, 6, 7, 8, 9, 10, 11].contains(data['schemaVersion']) ||
          data['realm'] != realm ||
          data['authNamespace'] != 'firebase-default' ||
          data['viewerRole'] != role.name ||
          data['viewerUserId'] != accountUserId ||
          data['purchaseId'] != purchaseId ||
          data['state'] != 'original_facts' ||
          !_id(data['buyerId']) ||
          !_id(data['sourceRevision'])) {
        return null;
      }
      final rawOrders = data['orders'];
      if (rawOrders is! List ||
          rawOrders.isEmpty ||
          rawOrders.length > 10 ||
          role == WorkspaceOrderIdentityRole.seller && rawOrders.length != 1) {
        return null;
      }
      final orders = rawOrders.map((order) => _decodePurchaseOrder(order, realm)).toList();
      final purchaser = orders.first.purchaser;
      if (orders.any((o) => jsonEncode(o.purchaser?.toJson()) != jsonEncode(purchaser?.toJson())) ||
          role == WorkspaceOrderIdentityRole.buyer && (buyingStoreId == null
            ? purchaser?.kind == 'store'
            : purchaser?.kind != 'store' || purchaser?.storeId != buyingStoreId)) {
        return null;
      }
      if (orders.any((o) => o.factsVersion != data['schemaVersion']) ||
          orders.map((o) => o.storeId).toSet().length != orders.length ||
          orders.map((o) => o.orderId).toSet().length != orders.length ||
          orders.fold<int>(0, (sum, o) => sum + o.lines.length) > 200 ||
          role == WorkspaceOrderIdentityRole.seller &&
              (orders.single.storeId != storeId ||
                  orders.single.orderId != orderId) ||
          !current()) {
        return null;
      }
      return WorkspacePurchaseProjection(
        realm: realm,
        purchaseId: purchaseId,
        buyerId: data['buyerId'] as String,
        sourceRevision: data['sourceRevision'] as String,
        orders: orders,
      );
    } on Object {
      // Unavailable is not an empty feed, a legacy fallback or payment success.
      return null;
    }
  }

  Future<WorkspaceOrderIdentityResult> read({
    required WorkspaceOrderIdentityRole role,
    required String storeId,
    required String orderId,
    String? purchaseId,
    String? expectedOriginalFingerprint,
  }) async {
    const unavailable = WorkspaceOrderIdentityResult(
      WorkspaceOrderIdentityState.unavailable,
    );
    final origin = _ownerLifetime;
    bool current() => origin != null && lifetime() == origin;
    if (!current() ||
        !_id(storeId) ||
        !_id(orderId) ||
        (role == WorkspaceOrderIdentityRole.buyer
            ? !_id(purchaseId)
            : purchaseId != null)) {
      return unavailable;
    }
    try {
      final token = await credentials.firebaseIdToken();
      if (!current()) return unavailable;
      final appCheck = await credentials.appCheckToken(
        SocialAppCheckTokenMode.standard,
      );
      if (!current()) return unavailable;
      final reply = await transport
          .postJson(
            endpoint,
            headers: {
              'accept': 'application/json',
              'authorization': 'Bearer $token',
              'x-firebase-appcheck': appCheck,
              'x-request-id': List.generate(
                16,
                (_) => Random.secure()
                    .nextInt(256)
                    .toRadixString(16)
                    .padLeft(2, '0'),
              ).join(),
            },
            body: {
              'operation': role == WorkspaceOrderIdentityRole.buyer
                  ? 'readBuyerOrderIdentity'
                  : 'readStoreOrderIdentity',
              'storeId': storeId,
              'orderId': orderId,
              'purchaseId': ?purchaseId,
            },
          )
          .timeout(const Duration(seconds: 20));
      if (!current() ||
          reply.statusCode != 200 ||
          reply.body.length > 512 * 1024) {
        return unavailable;
      }
      final envelope = _map(jsonDecode(reply.body));
      if (envelope['ok'] != true) return unavailable;
      final data = _map(envelope['data']);
      if (data['schemaVersion'] != 1 ||
          data['viewerRole'] != role.name ||
          data['viewerUserId'] != accountUserId ||
          data['storeId'] != storeId ||
          data['orderId'] != orderId) {
        return unavailable;
      }
      if (data['state'] == 'unlinked') {
        return role == WorkspaceOrderIdentityRole.seller &&
                !data.containsKey('identity')
            ? const WorkspaceOrderIdentityResult(
                WorkspaceOrderIdentityState.unlinked,
              )
            : unavailable;
      }
      if (data['state'] != 'linked') return unavailable;
      final identity = _map(data['identity']);
      for (final k in ['buyerId', 'purchaseId', 'sourceRevision']) {
        if (!_id(identity[k])) return unavailable;
      }
      if (purchaseId != null && identity['purchaseId'] != purchaseId) {
        return unavailable;
      }
      for (final k in ['serviceRevision', 'originalFingerprint']) {
        if (identity[k] is! String ||
            !RegExp(r'^[a-f0-9]{64}$').hasMatch(identity[k] as String)) {
          return unavailable;
        }
      }
      final original = _map(identity['original']);
      if (original['currency'] != 'INR' || !_money(original['amountMinor'])) {
        return unavailable;
      }
      final rawLines = original['lines'];
      if (rawLines is! List || rawLines.isEmpty || rawLines.length > 500) {
        return unavailable;
      }
      final lines = <WorkspaceOriginalOrderLine>[];
      for (final raw in rawLines) {
        final line = _map(raw);
        if (!_id(line['lineId']) ||
            line['name'] is! String ||
            (line['name'] as String).trim().isEmpty ||
            (line['name'] as String).length > 500 ||
            line['detail'] is! String ||
            (line['detail'] as String).length > 2000 ||
            line['quantity'] is! int ||
            (line['quantity'] as int) <= 0 ||
            (line['quantity'] as int) > 9007199254740991 ||
            !_money(line['amountMinor'])) {
          return unavailable;
        }
        lines.add(
          WorkspaceOriginalOrderLine(
            lineId: line['lineId'] as String,
            name: line['name'] as String,
            detail: line['detail'] as String,
            quantity: line['quantity'] as int,
            amountMinor: line['amountMinor'] as int,
          ),
        );
      }
      if (lines.map((l) => l.lineId).toSet().length != lines.length) {
        return unavailable;
      }
      lines.sort((a, b) => a.lineId.compareTo(b.lineId));
      final fingerprint = sha256
          .convert(
            utf8.encode(
              jsonEncode({
                'storeId': storeId,
                'orderId': orderId,
                'original': {
                  'currency': 'INR',
                  'amountMinor': original['amountMinor'],
                  'lines': lines.map((l) => l.toJson()).toList(),
                },
              }),
            ),
          )
          .toString();
      if (fingerprint != identity['originalFingerprint'] ||
          expectedOriginalFingerprint != null &&
              fingerprint != expectedOriginalFingerprint ||
          !current()) {
        return unavailable;
      }
      return WorkspaceOrderIdentityResult(
        WorkspaceOrderIdentityState.linked,
        identity: WorkspacePurchasedOrderIdentity(
          buyerId: identity['buyerId'] as String,
          purchaseId: identity['purchaseId'] as String,
          storeId: storeId,
          orderId: orderId,
          sourceRevision: identity['sourceRevision'] as String,
          serviceRevision: identity['serviceRevision'] as String,
          originalFingerprint: fingerprint,
          amountMinor: original['amountMinor'] as int,
          lines: lines,
        ),
      );
    } on Object {
      // No provider diagnostics, empty-success fallback or cache mutation.
      return unavailable;
    }
  }
}

bool _id(Object? v) =>
    v is String && RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$').hasMatch(v);
bool _money(Object? v) => v is int && v >= 0 && v <= 9007199254740991;
Map<String, dynamic> _map(Object? v) => (v as Map).cast<String, dynamic>();

/// Operational source facts are separate from immutable originals and from
/// payment/Stock authority. Construction follows strict authenticated decoding.
class WorkspaceOperationalOrderSnapshot {
  WorkspaceOperationalOrderSnapshot._({
    required this.realm,
    required this.viewerRole,
    required this.viewerUserId,
    required this.reference,
    required this.original,
    required this.operationalSourceRevision,
    required this.revision,
    required this.stage,
    required this.fulfilment,
    required this.placedAt,
    required this.acceptanceDeadline,
    required this.fulfilmentDeadline,
    required Set<String> permittedActions,
    required this.customerLabel,
    required this.address,
    required this.rejectionReason,
  }) : permittedActions = Set.unmodifiable(permittedActions);
  final WorkspacePurchaseReference reference;
  final String realm, viewerUserId;
  final WorkspaceOrderIdentityRole viewerRole;
  final WorkspacePurchaseOrder original;
  final String operationalSourceRevision, stage, fulfilment;
  final int revision;
  final DateTime placedAt;
  final DateTime? acceptanceDeadline, fulfilmentDeadline;
  final Set<String> permittedActions;
  final String? customerLabel, address, rejectionReason;
  bool permits(String action, DateTime now) =>
      fulfilment != 'collection' &&
      permittedActions.contains(action) &&
      (action == 'ready'
          ? stage == 'Preparing'
          : stage == 'Confirmed' && acceptanceDeadline?.isAfter(now) == true);
}

class WorkspaceOperationalCommandResult {
  const WorkspaceOperationalCommandResult(
    this.operationId,
    this.state,
    this.snapshot,
  );
  final String operationId, state;
  final WorkspaceOperationalOrderSnapshot snapshot;
}

/// A received trusted completion projection, separate from mutable preparation,
/// payment/Stock authority and rating permission. Null is no supplied evidence,
/// not proof that delivery/collection did not happen.
class WorkspaceOrderCompletionSnapshot {
  const WorkspaceOrderCompletionSnapshot._({required this.reference, required this.realm,
    required this.viewerRole, required this.viewerUserId, required this.completion});
  final WorkspacePurchaseReference reference;
  final String realm, viewerUserId;
  final WorkspaceOrderIdentityRole viewerRole;
  final WorkspaceOrderCompletion? completion;
}
class WorkspaceOrderCompletion {
  const WorkspaceOrderCompletion._({required this.id, required this.revision, required this.outcome,
    required this.occurredAt, required this.recordedAt});
  final String id, revision, outcome;
  final DateTime occurredAt, recordedAt;
  @override
  bool operator ==(Object other) => other is WorkspaceOrderCompletion && id == other.id && revision == other.revision &&
    outcome == other.outcome && occurredAt == other.occurredAt && recordedAt == other.recordedAt;
  @override
  int get hashCode => Object.hash(id, revision, outcome, occurredAt, recordedAt);
}

/// Exact private purchased-product context, not a published rating or consent.
class WorkspaceProductFeedbackTarget {
  const WorkspaceProductFeedbackTarget._({required this.id, required this.reference,
    required this.orderLineId, required this.productId, required this.productLabel,
    required this.purchasedListing, required this.completedAt, required this.completionId, required this.completionRevision});
  final String id, orderLineId, productId, productLabel, completionId, completionRevision;
  final WorkspacePurchaseReference reference;
  final BuyV2PublicListingIdentity purchasedListing;
  final DateTime completedAt;
  Map<String, Object?> toJson() => {'id': id, 'kind': 'product', 'purchaseId': reference.purchaseId,
    'storeId': reference.storeId, 'orderId': reference.orderId, 'orderLineId': orderLineId,
    'productId': productId, 'productLabel': productLabel, 'originalFingerprint': reference.originalFingerprint,
    'sourceRevision': reference.sourceRevision, 'purchasedListing': purchasedListing.toJson(),
    'completedAt': completedAt.toUtc().toIso8601String(), 'completionId': completionId, 'completionRevision': completionRevision};
}

/// Private stars only; deliberately contains no comment, author or public count.
class WorkspaceProductStars {
  const WorkspaceProductStars._({required this.target, required this.stars, required this.revision, required this.updatedAt});
  final WorkspaceProductFeedbackTarget target;
  final int stars, revision;
  final DateTime updatedAt;
}
class WorkspaceProductStarsResult {
  const WorkspaceProductStarsResult._({required this.operationId, required this.rating, this.supersededByRevision});
  final String operationId;
  // Null without supersession is a missing original receipt, not a failed read.
  final WorkspaceProductStars? rating;
  final int? supersededByRevision;
}
class WorkspaceBuyerProductStarsSnapshot {
  const WorkspaceBuyerProductStarsSnapshot._({required this.target, required this.rating});
  final WorkspaceProductFeedbackTarget target;
  // A successful authenticated read may report no saved rating yet.
  final WorkspaceProductStars? rating;
}
class WorkspaceStoreProductStarsPage {
  WorkspaceStoreProductStarsPage._({required this.storeId, required List<WorkspaceProductStars> ratings,
    required this.nextCursor}) : ratings = List.unmodifiable(ratings);
  final String storeId;
  final List<WorkspaceProductStars> ratings;
  final String? nextCursor;
}

/// This bounded index covers recorded exact-product completions only. It is not
/// publication consent, a public rating, nor complete historical purchase coverage.
class WorkspaceProductFeedbackTargetPage {
  WorkspaceProductFeedbackTargetPage._({required this.realm, required this.viewerUserId,
    required List<WorkspaceProductFeedbackTarget> targets, required this.nextCursor}) : targets = List.unmodifiable(targets);
  final String realm, viewerUserId;
  final List<WorkspaceProductFeedbackTarget> targets;
  final String? nextCursor;
}

/// Explicit operational adapter; the composed identity reader stays read-only.
/// No automatic retries. The existing Store journal/controller owns command
/// persistence and uncertain-attempt recovery before this adapter is bound.
class AuthenticatedWorkspaceOrderOperationsGateway {
  const AuthenticatedWorkspaceOrderOperationsGateway(this.identity, {this.now = DateTime.now});
  final AuthenticatedWorkspaceOrderIdentityGateway identity;
  final DateTime Function() now;
  bool get isCurrent => identity.isCurrent;
  bool _validReference(String realm, WorkspacePurchaseReference ref) =>
      isCurrent &&
      ['evaluation', 'production'].contains(realm) &&
      [
        ref.purchaseId,
        ref.storeId,
        ref.orderId,
        ref.sourceRevision,
      ].every(_id) &&
      RegExp(r'^[a-f0-9]{64}$').hasMatch(ref.originalFingerprint);
  Future<Map<String, dynamic>?> _call(
    String operation,
    Map<String, Object?> body, {
    bool mutation = false,
  }) async {
    if (!isCurrent) return null;
    try {
      final token = await identity.credentials.firebaseIdToken();
      if (!isCurrent) return null;
      final appCheck = await identity.credentials.appCheckToken(
        mutation
            ? SocialAppCheckTokenMode.limitedUse
            : SocialAppCheckTokenMode.standard,
      );
      if (!isCurrent) return null;
      final reply = await identity.transport
          .postJson(
            identity.endpoint,
            headers: {
              'accept': 'application/json',
              'authorization': 'Bearer $token',
              'x-firebase-appcheck': appCheck,
              'x-request-id': List.generate(
                16,
                (_) => Random.secure()
                    .nextInt(256)
                    .toRadixString(16)
                    .padLeft(2, '0'),
              ).join(),
            },
            body: {'operation': operation, ...body},
          )
          .timeout(const Duration(seconds: 20));
      if (!isCurrent ||
          reply.statusCode != 200 ||
          utf8.encode(reply.body).length > 512 * 1024) {
        return null;
      }
      final envelope = _map(jsonDecode(reply.body));
      return envelope['ok'] == true ? _map(envelope['data']) : null;
    } on Object {
      return null;
    }
  }

  /// Purchaser-reported physical arrivals, independent of operational completion
  /// and money. The caller must durably retain the exact command before record.
  Future<WorkspaceGoodsReceivingRead?> readBuyerGoodsReceiving(WorkspaceRestockPurchaseOriginal original) async {
    if (!isCurrent || original.accountScope != identity.accountUserId) return null;
    final raw = await _call('readBuyerGoodsReceiving', {'schemaVersion': 1,
      'buyingStoreId': original.buyingStoreId, 'reference': original.reference});
    if (raw == null || !isCurrent) return null;
    try {
      final r = _exactMap(raw, const ['schemaVersion', 'realm', 'viewerUserId', 'buyingStoreId', 'group']);
      _goodsScope(r, original);
      return WorkspaceGoodsReceivingRead._(original, r['group'] == null ? null
        : WorkspaceGoodsReceivingGroup._decode(r['group'], original));
    } on Object { return null; }
  }

  Future<WorkspaceGoodsArrivalResult?> recordBuyerGoodsArrival(WorkspaceGoodsArrivalCommand command) =>
    _goodsArrival(command, reconcile: false);
  Future<WorkspaceGoodsArrivalResult?> reconcileBuyerGoodsArrival(WorkspaceGoodsArrivalCommand command) =>
    _goodsArrival(command, reconcile: true);
  Future<WorkspaceGoodsArrivalResult?> closeBuyerGoodsArrival(WorkspaceGoodsArrivalCommand command) =>
    _goodsArrival(command, reconcile: false, close: true);
  Future<WorkspaceGoodsArrivalResult?> _goodsArrival(WorkspaceGoodsArrivalCommand command, {required bool reconcile, bool close = false}) async {
    final original = command.receipt.restockOriginal!;
    if (!isCurrent || original.accountScope != identity.accountUserId) return null;
    final raw = await _call(close ? 'closeBuyerGoodsArrival' : reconcile ? 'reconcileBuyerGoodsArrival' : 'recordBuyerGoodsArrival',
      command.toJson(), mutation: !reconcile);
    if (raw == null || !isCurrent) return null;
    try {
      final result = WorkspaceGoodsArrivalResult.fromJson(raw, command);
      return result.recorded || result.closed || reconcile ? result : null;
    } on Object { return null; }
  }

  DateTime _date(Object? value) {
    if (value is! String || value.length != 24) throw const FormatException();
    final parsed = DateTime.parse(value);
    if (parsed.toUtc().toIso8601String() != value) {
      throw const FormatException();
    }
    return parsed;
  }

  WorkspaceOperationalOrderSnapshot _decode(
    Object? value,
    WorkspaceOrderIdentityRole role,
    String realm,
    WorkspacePurchaseReference ref,
  ) {
    final source = _map(value);
    final enriched = source.containsKey('originalFactsVersion');
    if (enriched && (source['originalFactsVersion'] is! int || !const [3, 4, 5, 6, 7, 8, 9, 10, 11].contains(source['originalFactsVersion']))) {
      throw const FormatException('Unsupported original facts.');
    }
    final data = _exactMap(source, [
      'schemaVersion',
      'realm',
      'authNamespace',
      'viewerRole',
      'viewerUserId',
      'purchaseId',
      'storeId',
      'orderId',
      'sourceRevision',
      'originalFingerprint',
      'original',
      if (enriched) 'originalFactsVersion',
      'operationalSourceRevision',
      'revision',
      'stage',
      'fulfilment',
      'placedAt',
      'acceptanceDeadline',
      'fulfilmentDeadline',
      'permittedActions',
      'paymentVerification',
      'stockVerification',
      'rejectionReason',
      if (role == WorkspaceOrderIdentityRole.seller) ...[
        'customerLabel',
        'address',
      ],
    ]);
    if (data['schemaVersion'] != 1 ||
        data['realm'] != realm ||
        data['authNamespace'] != 'firebase-default' ||
        data['viewerRole'] != role.name ||
        data['viewerUserId'] != identity.accountUserId ||
        data['purchaseId'] != ref.purchaseId ||
        data['storeId'] != ref.storeId ||
        data['orderId'] != ref.orderId ||
        data['sourceRevision'] != ref.sourceRevision ||
        data['originalFingerprint'] != ref.originalFingerprint ||
        !_id(data['operationalSourceRevision']) ||
        data['revision'] is! int ||
        data['revision'] < 1 ||
        data['revision'] > 9007199254740991 ||
        !const [
          'Confirmed',
          'Preparing',
          'Ready',
          'Rejected',
        ].contains(data['stage']) ||
        !const ['delivery', 'collection'].contains(data['fulfilment']) ||
        data['paymentVerification'] != 'not_supplied' ||
        data['stockVerification'] != 'not_supplied') {
      throw const FormatException();
    }
    final actions = data['permittedActions'];
    if (actions is! List ||
        actions.length > 3 ||
        actions.any((a) => !const ['accept', 'ready', 'reject'].contains(a)) ||
        actions.toSet().length != actions.length ||
        role == WorkspaceOrderIdentityRole.buyer && actions.isNotEmpty ||
        data['fulfilment'] == 'collection' && actions.isNotEmpty) {
      throw const FormatException();
    }
    final placed = _date(data['placedAt']);
    final acceptance = data['acceptanceDeadline'] == null
        ? null
        : _date(data['acceptanceDeadline']);
    final fulfilment = data['fulfilmentDeadline'] == null
        ? null
        : _date(data['fulfilmentDeadline']);
    if (acceptance != null && !acceptance.isAfter(placed) ||
        fulfilment != null &&
            (!fulfilment.isAfter(placed) ||
                acceptance != null && acceptance.isAfter(fulfilment)) ||
        actions.any(
          (a) => a == 'ready'
              ? data['stage'] != 'Preparing'
              : data['stage'] != 'Confirmed' || acceptance == null,
        )) {
      throw const FormatException();
    }
    bool text(Object? v, int max) =>
        v is String &&
        v.trim() == v &&
        v.isNotEmpty &&
        v.length <= max &&
        !RegExp(r'[\x00-\x1f]').hasMatch(v);
    if (role == WorkspaceOrderIdentityRole.seller &&
            (!text(data['customerLabel'], 200) ||
                !text(data['address'], 2000)) ||
        data['rejectionReason'] != null &&
            (!text(data['rejectionReason'], 160) ||
                (data['rejectionReason'] as String).length < 3 ||
                data['stage'] != 'Rejected')) {
      throw const FormatException();
    }
    final original = _decodePurchaseOrder({
      'factsVersion': enriched ? source['originalFactsVersion'] : 2,
      'storeId': ref.storeId,
      'orderId': ref.orderId,
      'originalFingerprint': ref.originalFingerprint,
      'original': data['original'],
    }, realm);
    if (original.fulfilmentContext != null && original.fulfilmentContext!.method != data['fulfilment']) {
      throw const FormatException('Original and operational fulfilment disagree.');
    }
    return WorkspaceOperationalOrderSnapshot._(
      realm: realm,
      viewerRole: role,
      viewerUserId: identity.accountUserId,
      reference: ref,
      original: original,
      operationalSourceRevision: data['operationalSourceRevision'],
      revision: data['revision'],
      stage: data['stage'],
      fulfilment: data['fulfilment'],
      placedAt: placed,
      acceptanceDeadline: acceptance,
      fulfilmentDeadline: fulfilment,
      permittedActions: actions.cast<String>().toSet(),
      customerLabel: data['customerLabel'],
      address: data['address'],
      rejectionReason: data['rejectionReason'],
    );
  }

  Future<WorkspaceOrderCompletionSnapshot?> readCompletion({
    required WorkspaceOrderIdentityRole role, required String realm,
    required WorkspacePurchaseReference reference,
  }) async {
    if (!_validReference(realm, reference)) return null;
    try {
      final raw = await _call(role == WorkspaceOrderIdentityRole.buyer
        ? 'readBuyerOrderCompletion' : 'readStoreOrderCompletion', {
          'purchaseId': reference.purchaseId, 'storeId': reference.storeId, 'orderId': reference.orderId,
        });
      if (raw == null || !isCurrent) return null;
      final data = _exactMap(raw, const ['schemaVersion', 'realm', 'authNamespace', 'viewerRole', 'viewerUserId',
        'purchaseId', 'storeId', 'orderId', 'sourceRevision', 'originalFingerprint', 'state', 'completion']);
      if (data['schemaVersion'] is! int || data['schemaVersion'] != 1 || data['realm'] != realm ||
          data['authNamespace'] != 'firebase-default' || data['viewerRole'] != role.name ||
          data['viewerUserId'] != identity.accountUserId || data['purchaseId'] != reference.purchaseId ||
          data['storeId'] != reference.storeId || data['orderId'] != reference.orderId ||
          data['sourceRevision'] != reference.sourceRevision || data['originalFingerprint'] != reference.originalFingerprint) {
        throw const FormatException('Completion scope mismatch.');
      }
      WorkspaceOrderCompletion? completion;
      if (data['state'] == 'recorded') {
        final value = _exactMap(_map(data['completion']), const ['id', 'revision', 'outcome', 'occurredAt', 'recordedAt']);
        if (value['id'] is! String || !RegExp(r'^completion-[a-f0-9]{64}$').hasMatch(value['id']) ||
            !_id(value['revision']) || !const ['delivered', 'collected'].contains(value['outcome'])) {
          throw const FormatException('Invalid completion evidence.');
        }
        final occurredAt = _date(value['occurredAt']), recordedAt = _date(value['recordedAt']);
        if (occurredAt.isAfter(recordedAt) || recordedAt.isAfter(now().toUtc())) throw const FormatException();
        completion = WorkspaceOrderCompletion._(id: value['id'], revision: value['revision'], outcome: value['outcome'],
          occurredAt: occurredAt, recordedAt: recordedAt);
      } else if (data['state'] != 'not_supplied' || data['completion'] != null) {
        throw const FormatException('Unavailable completion evidence.');
      }
      return WorkspaceOrderCompletionSnapshot._(reference: reference, realm: realm, viewerRole: role,
        viewerUserId: identity.accountUserId, completion: completion);
    } on Object {return null;}
  }

  Future<WorkspaceProductFeedbackTargetPage?> listProductFeedbackTargets({required String realm, String? cursor}) async {
    if (!isCurrent || !const ['evaluation', 'production'].contains(realm) ||
        cursor != null && (cursor.isEmpty || cursor.length > 512)) {
      return null;
    }
    try {
      final raw = await _call('listBuyerProductFeedbackTargets', {'limit': 5, 'cursor': cursor});
      if (raw == null || !isCurrent) return null;
      final data = _exactMap(raw, const ['schemaVersion', 'realm', 'authNamespace', 'viewerRole', 'viewerUserId', 'coverage', 'targets', 'nextCursor']);
      if (data['schemaVersion'] is! int || data['schemaVersion'] != 1 || data['realm'] != realm ||
          data['authNamespace'] != 'firebase-default' || data['viewerRole'] != 'buyer' || data['viewerUserId'] != identity.accountUserId ||
          data['coverage'] != 'indexed_recorded_completions' || data['targets'] is! List || (data['targets'] as List).length > 5 ||
          data['nextCursor'] != null && (data['nextCursor'] is! String || (data['nextCursor'] as String).isEmpty ||
            (data['nextCursor'] as String).length > 512 || data['nextCursor'] == cursor)) {
        throw const FormatException('Invalid feedback target page.');
      }
      final targets = <WorkspaceProductFeedbackTarget>[], ids = <String>{};
      for (final raw in data['targets'] as List) {
        final t = _exactMap(raw, const ['id', 'kind', 'purchaseId', 'storeId', 'orderId', 'orderLineId', 'productId',
          'productLabel', 'originalFingerprint', 'sourceRevision', 'purchasedListing', 'completedAt', 'completionId', 'completionRevision']);
        if (t['kind'] != 'product' || !['purchaseId', 'storeId', 'orderId', 'orderLineId', 'sourceRevision', 'completionRevision'].every((k) => _id(t[k])) ||
            t['originalFingerprint'] is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(t['originalFingerprint']) ||
            t['completionId'] is! String || !RegExp(r'^completion-[a-f0-9]{64}$').hasMatch(t['completionId']) ||
            t['productLabel'] is! String || (t['productLabel'] as String).trim().isEmpty ||
            (t['productLabel'] as String).trim() != t['productLabel'] || (t['productLabel'] as String).length > 240) {
          throw const FormatException('Invalid purchased target.');
        }
        final listing = BuyV2PublicListingIdentity.fromJson(t['purchasedListing']), completedAt = _date(t['completedAt']);
        if (listing == null || listing.realm != realm || listing.storeId != t['storeId'] || listing.listingId != t['productId'] ||
            listing.listingId != 'listing-${sha256.convert(utf8.encode(jsonEncode([1, realm, listing.storeId, listing.skuId, listing.channel.name])))}' ||
            completedAt.isAfter(now().toUtc())) {
          throw const FormatException('Unbound completed target.');
        }
        final expected = 'feedback-${sha256.convert(utf8.encode(jsonEncode([1, realm, 'firebase-default', identity.accountUserId,
          t['purchaseId'], t['storeId'], t['orderId'], t['orderLineId'], t['originalFingerprint'], t['sourceRevision'], t['productLabel'],
          listing.listingId, listing.skuId, listing.canonicalProductId, listing.verifiedPackId, listing.channel.name,
          t['completionId'], t['completionRevision'], t['completedAt']])))}';
        if (t['id'] != expected || !ids.add(expected)) throw const FormatException('Changed feedback target.');
        targets.add(WorkspaceProductFeedbackTarget._(id: expected,
          reference: WorkspacePurchaseReference(purchaseId: t['purchaseId'], storeId: t['storeId'], orderId: t['orderId'],
            sourceRevision: t['sourceRevision'], originalFingerprint: t['originalFingerprint']),
          orderLineId: t['orderLineId'], productId: t['productId'], productLabel: t['productLabel'], purchasedListing: listing,
          completedAt: completedAt, completionId: t['completionId'], completionRevision: t['completionRevision']));
      }
      return WorkspaceProductFeedbackTargetPage._(realm: realm, viewerUserId: identity.accountUserId,
        targets: targets, nextCursor: data['nextCursor']);
    } on Object {return null;}
  }

  WorkspaceProductFeedbackTarget _privateStarsTarget(Object? raw, String realm) {
    final t = _exactMap(_map(raw), const ['id', 'kind', 'purchaseId', 'storeId', 'orderId', 'orderLineId', 'productId',
      'productLabel', 'originalFingerprint', 'sourceRevision', 'purchasedListing', 'completedAt', 'completionId', 'completionRevision']);
    if (t['kind'] != 'product' || t['id'] is! String || !RegExp(r'^feedback-[a-f0-9]{64}$').hasMatch(t['id']) ||
        !['purchaseId', 'storeId', 'orderId', 'orderLineId', 'sourceRevision', 'completionRevision'].every((k) => _id(t[k])) ||
        t['originalFingerprint'] is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(t['originalFingerprint']) ||
        t['completionId'] is! String || !RegExp(r'^completion-[a-f0-9]{64}$').hasMatch(t['completionId']) ||
        t['productLabel'] is! String || (t['productLabel'] as String).trim().isEmpty ||
        t['productLabel'] != (t['productLabel'] as String).trim() || (t['productLabel'] as String).length > 240) {
      throw const FormatException('Invalid private stars context.');
    }
    final listing = BuyV2PublicListingIdentity.fromJson(t['purchasedListing']), completedAt = _date(t['completedAt']);
    if (listing == null || listing.realm != realm || listing.storeId != t['storeId'] || listing.listingId != t['productId'] ||
        listing.listingId != 'listing-${sha256.convert(utf8.encode(jsonEncode([1, realm, listing.storeId, listing.skuId, listing.channel.name])))}' ||
        completedAt.isAfter(now().toUtc())) {
      throw const FormatException('Unbound private stars context.');
    }
    // Seller receives an opaque target ID, never the buyer UID used to derive it.
    return WorkspaceProductFeedbackTarget._(id: t['id'],
      reference: WorkspacePurchaseReference(purchaseId: t['purchaseId'], storeId: t['storeId'], orderId: t['orderId'],
        sourceRevision: t['sourceRevision'], originalFingerprint: t['originalFingerprint']),
      orderLineId: t['orderLineId'], productId: t['productId'], productLabel: t['productLabel'], purchasedListing: listing,
      completedAt: completedAt, completionId: t['completionId'], completionRevision: t['completionRevision']);
  }
  WorkspaceProductStars _privateStars(Object? value, String realm) {
    final r = _exactMap(_map(value), const ['target', 'stars', 'revision', 'updatedAt']);
    if (r['stars'] is! int || r['stars'] < 1 || r['stars'] > 5 || r['revision'] is! int ||
        r['revision'] < 1 || r['revision'] > 9007199254740991) {
      throw const FormatException('Invalid stars.');
    }
    final target = _privateStarsTarget(r['target'], realm), updatedAt = _date(r['updatedAt']);
    if (updatedAt.isBefore(target.completedAt) || updatedAt.isAfter(now().toUtc())) {
      throw const FormatException('Invalid stars date.');
    }
    return WorkspaceProductStars._(target: target, stars: r['stars'], revision: r['revision'], updatedAt: updatedAt);
  }
  /// Restores an original command's exact target without depending on current
  /// catalogue availability. Scope/hash validation is not server save authority.
  WorkspaceProductFeedbackTarget? restoreProductFeedbackTarget(Object? value, {required String realm}) {
    if (!isCurrent || !const ['evaluation', 'production'].contains(realm)) return null;
    try {
      final target = _privateStarsTarget(value, realm), t = target.toJson(), listing = target.purchasedListing;
      final expected = 'feedback-${sha256.convert(utf8.encode(jsonEncode([1, realm, 'firebase-default', identity.accountUserId,
        t['purchaseId'], t['storeId'], t['orderId'], t['orderLineId'], t['originalFingerprint'], t['sourceRevision'], t['productLabel'],
        listing.listingId, listing.skuId, listing.canonicalProductId, listing.verifiedPackId, listing.channel.name,
        t['completionId'], t['completionRevision'], t['completedAt']])))}';
      return target.id == expected ? target : null;
    } on Object {return null;}
  }
  Future<WorkspaceProductFeedbackTarget?> readProductFeedbackTarget({required String realm,
    required WorkspacePurchaseReference reference, required WorkspacePurchasedSkuLine line}) async {
    if (!_validReference(realm, reference) || !_id(line.lineId) || line.publicListing == null) return null;
    try {
      final raw = await _call('readBuyerProductFeedbackTarget', {'purchaseId': reference.purchaseId,
        'storeId': reference.storeId, 'orderId': reference.orderId, 'originalFingerprint': reference.originalFingerprint,
        'sourceRevision': reference.sourceRevision, 'orderLineId': line.lineId});
      if (raw == null || !isCurrent) return null;
      final data = _exactMap(raw, const ['schemaVersion', 'realm', 'authNamespace', 'viewerRole', 'viewerUserId', 'target']);
      if (data['schemaVersion'] is! int || data['schemaVersion'] != 1 || data['realm'] != realm ||
          data['authNamespace'] != 'firebase-default' || data['viewerRole'] != 'buyer' || data['viewerUserId'] != identity.accountUserId) {
        return null;
      }
      final target = restoreProductFeedbackTarget(data['target'], realm: realm), t = target?.reference;
      if (target == null || t!.purchaseId != reference.purchaseId || t.storeId != reference.storeId ||
          t.orderId != reference.orderId || t.originalFingerprint != reference.originalFingerprint ||
          t.sourceRevision != reference.sourceRevision || target.orderLineId != line.lineId ||
          target.productLabel != line.name || target.purchasedListing != line.publicListing) {
        return null;
      }
      return target;
    } on Object {return null;}
  }
  Future<WorkspaceBuyerProductStarsSnapshot?> readProductStars(WorkspaceProductFeedbackTarget target) async {
    final realm = target.purchasedListing.realm;
    if (restoreProductFeedbackTarget(target.toJson(), realm: realm) == null) return null;
    try {
      final raw = await _call('readBuyerProductStars', {'targetId': target.id});
      if (raw == null || !isCurrent) return null;
      final r = _exactMap(raw, const ['schemaVersion', 'realm', 'authNamespace', 'viewerRole', 'viewerUserId', 'targetId', 'rating']);
      if (r['schemaVersion'] is! int || r['schemaVersion'] != 1 || r['realm'] != realm ||
          r['authNamespace'] != 'firebase-default' || r['viewerRole'] != 'buyer' ||
          r['viewerUserId'] != identity.accountUserId || r['targetId'] != target.id) {
        throw const FormatException('Wrong saved-stars owner.');
      }
      final rating = r['rating'] == null ? null : _privateStars(r['rating'], realm);
      if (rating != null && jsonEncode(rating.target.toJson()) != jsonEncode(target.toJson())) {
        throw const FormatException('Changed saved-stars target.');
      }
      return WorkspaceBuyerProductStarsSnapshot._(target: target, rating: rating);
    } on Object {return null;}
  }
  Future<WorkspaceProductStarsResult?> submitProductStars({required WorkspaceProductFeedbackTarget target,
    required int stars, required int expectedRevision, required String operationId, bool reconcile = false}) async {
    final realm = target.purchasedListing.realm;
    if (!_validReference(realm, target.reference) || !_id(operationId) || stars < 1 || stars > 5 ||
        expectedRevision < 0 || expectedRevision >= 9007199254740991) {
      return null;
    }
    try {
      final raw = await _call(reconcile ? 'reconcileBuyerProductStars' : 'submitBuyerProductStars', {
        'targetId': target.id, 'expectedRevision': expectedRevision, 'operationId': operationId, 'stars': stars,
      }, mutation: !reconcile);
      if (raw == null || !isCurrent) return null;
      final superseded = raw['state'] == 'superseded';
      final r = _exactMap(raw, ['schemaVersion', 'realm', 'authNamespace', 'viewerRole', 'viewerUserId', 'operationId', 'state', 'rating',
        if (superseded) ...['targetId', 'observedRevision']]);
      if (r['schemaVersion'] is! int || r['schemaVersion'] != 1 || r['realm'] != realm || r['authNamespace'] != 'firebase-default' ||
          r['viewerRole'] != 'buyer' || r['viewerUserId'] != identity.accountUserId || r['operationId'] != operationId) {
        throw const FormatException('Wrong stars receipt owner.');
      }
      WorkspaceProductStars? saved;
      if (r['state'] == 'saved') {
        saved = _privateStars(r['rating'], realm);
        if (jsonEncode(saved.target.toJson()) != jsonEncode(target.toJson()) || saved.stars != stars ||
            saved.revision != expectedRevision + 1) {
          throw const FormatException('Changed stars receipt.');
        }
      } else if (superseded) {
        if (!reconcile || r['rating'] != null || r['targetId'] != target.id || r['observedRevision'] is! int ||
            (r['observedRevision'] as int) <= expectedRevision || (r['observedRevision'] as int) > 9007199254740991) {
          throw const FormatException('Unproven superseded stars attempt.');
        }
      } else if (!reconcile || r['state'] != 'not_recorded' || r['rating'] != null) {
        throw const FormatException('Unknown stars outcome.');
      }
      return WorkspaceProductStarsResult._(operationId: operationId, rating: saved,
        supersededByRevision: superseded ? r['observedRevision'] as int : null);
    } on Object {return null;}
  }
  Future<WorkspaceStoreProductStarsPage?> listStoreProductStars({required String realm, required String storeId, String? cursor}) async {
    if (!isCurrent || !const ['evaluation', 'production'].contains(realm) || !_id(storeId) ||
        cursor != null && (cursor.isEmpty || cursor.length > 512)) {
      return null;
    }
    try {
      final raw = await _call('listStoreProductStars', {'storeId': storeId, 'limit': 5, 'cursor': cursor});
      if (raw == null || !isCurrent) return null;
      final r = _exactMap(raw, const ['schemaVersion', 'realm', 'authNamespace', 'viewerRole', 'viewerUserId', 'storeId', 'coverage', 'ratings', 'nextCursor']);
      if (r['schemaVersion'] is! int || r['schemaVersion'] != 1 || r['realm'] != realm || r['authNamespace'] != 'firebase-default' ||
          r['viewerRole'] != 'seller' || r['viewerUserId'] != identity.accountUserId || r['storeId'] != storeId ||
          r['coverage'] != 'recorded_private_product_stars' || r['ratings'] is! List || (r['ratings'] as List).length > 5 ||
          r['nextCursor'] != null && (r['nextCursor'] is! String || (r['nextCursor'] as String).isEmpty ||
            (r['nextCursor'] as String).length > 512 || r['nextCursor'] == cursor || (r['ratings'] as List).isEmpty)) {
        throw const FormatException('Wrong private Store stars page.');
      }
      final ratings = <WorkspaceProductStars>[], ids = <String>{};
      for (final value in r['ratings'] as List) {
        final rating = _privateStars(value, realm);
        if (rating.target.reference.storeId != storeId || !ids.add(rating.target.id)) throw const FormatException('Wrong Store.');
        ratings.add(rating);
      }
      return WorkspaceStoreProductStarsPage._(storeId: storeId, ratings: ratings, nextCursor: r['nextCursor']);
    } on Object {return null;}
  }

  Future<WorkspaceOperationalOrderSnapshot?> read({
    required WorkspaceOrderIdentityRole role,
    required String realm,
    required WorkspacePurchaseReference reference,
  }) async {
    if (!_validReference(realm, reference)) return null;
    try {
      final result = await _call(
        role == WorkspaceOrderIdentityRole.buyer
            ? 'readBuyerOperationalOrder'
            : 'readStoreOperationalOrder',
        {
          'purchaseId': reference.purchaseId,
          'storeId': reference.storeId,
          'orderId': reference.orderId,
        },
      );
      return result == null || !isCurrent
          ? null
          : _decode(result, role, realm, reference);
    } on Object {
      return null;
    }
  }

  Future<WorkspaceOperationalCommandResult?> command({
    required String realm,
    required WorkspacePurchaseReference reference,
    required String operationId,
    required int expectedRevision,
    required String action,
    String? reason,
    bool reconcile = false,
  }) async {
    if (!_validReference(realm, reference) ||
        !RegExp(
          r'^[A-Za-z0-9][A-Za-z0-9._:=+-]{2,159}$',
        ).hasMatch(operationId) ||
        expectedRevision < 1 ||
        expectedRevision > 9007199254740991 ||
        !const ['accept', 'ready', 'reject'].contains(action)) {
      return null;
    }
    try {
      final result = await _call(
        reconcile ? 'reconcileStoreOrderCommand' : 'submitStoreOrderCommand',
        {
          'version': 2,
          'purchaseId': reference.purchaseId,
          'storeId': reference.storeId,
          'orderId': reference.orderId,
          'operationId': operationId,
          'expectedRevision': expectedRevision,
          'action': action,
          'reason': reason,
        },
        mutation: !reconcile,
      );
      if (result == null || !isCurrent) return null;
      final data = _exactMap(result, const [
        'schemaVersion',
        'operationId',
        'state',
        'snapshot',
      ]);
      if (data['schemaVersion'] != 1 ||
          data['operationId'] != operationId ||
          !const ['applied', 'rejected', 'pending'].contains(data['state'])) {
        return null;
      }
      final snapshot = _decode(
        data['snapshot'],
        WorkspaceOrderIdentityRole.seller,
        realm,
        reference,
      );
      if (snapshot.revision < expectedRevision ||
          data['state'] == 'applied' &&
              snapshot.revision != expectedRevision + 1) {
        return null;
      }
      if (data['state'] == 'applied' &&
          (snapshot.stage !=
                  const {
                    'accept': 'Preparing',
                    'ready': 'Ready',
                    'reject': 'Rejected',
                  }[action] ||
              action == 'reject' && snapshot.rejectionReason != reason)) {
        return null;
      }
      return WorkspaceOperationalCommandResult(
        operationId,
        data['state'],
        snapshot,
      );
    } on Object {
      return null;
    }
  }
}

/// Exact original facts only, intentionally not a Buy order/Work action record.
class WorkspacePurchaseProjection {
  WorkspacePurchaseProjection({
    required this.realm,
    required this.purchaseId,
    required this.buyerId,
    required this.sourceRevision,
    required List<WorkspacePurchaseOrder> orders,
  }) : orders = List.unmodifiable(orders);
  final String realm, purchaseId, buyerId, sourceRevision;
  final List<WorkspacePurchaseOrder> orders;
}

class WorkspacePurchaseReference {
  const WorkspacePurchaseReference({
    required this.purchaseId,
    required this.storeId,
    required this.orderId,
    required this.originalFingerprint,
    required this.sourceRevision,
  });
  final String purchaseId,
      storeId,
      orderId,
      originalFingerprint,
      sourceRevision;
  bool get valid => [purchaseId, storeId, orderId, sourceRevision].every(_id) &&
      RegExp(r'^[a-f0-9]{64}$').hasMatch(originalFingerprint);
  Map<String, Object> toJson() => {
    'purchaseId': purchaseId, 'storeId': storeId, 'orderId': orderId,
    'originalFingerprint': originalFingerprint, 'sourceRevision': sourceRevision,
  };
  static WorkspacePurchaseReference fromJson(Object? value) {
    final data = _exactMap(value, const ['purchaseId', 'storeId', 'orderId', 'originalFingerprint', 'sourceRevision']);
    final reference = WorkspacePurchaseReference(
      purchaseId: data['purchaseId'] as String, storeId: data['storeId'] as String,
      orderId: data['orderId'] as String, originalFingerprint: data['originalFingerprint'] as String,
      sourceRevision: data['sourceRevision'] as String,
    );
    if (!reference.valid) throw const FormatException('Invalid purchased-order reference');
    return reference;
  }
}

class WorkspacePurchaseReferencePage {
  WorkspacePurchaseReferencePage({
    required this.coverage,
    required List<WorkspacePurchaseReference> references,
    required this.nextCursor,
  }) : references = List.unmodifiable(references);
  final String coverage;
  final List<WorkspacePurchaseReference> references;
  final String? nextCursor;
}

/// Frontend proposal for a separately authorised, purchase-bound warranty read.
/// Implementations must authenticate the viewer and retire their lifetime on
/// account changes. This interface supplies no backend operation or entitlement.
abstract interface class WorkspacePurchasedWarrantyReader {
  String get accountUserId;
  bool get isCurrent;
  /// Stable during this authenticated visit; changes even for account A-B-A.
  Object? get lifetime;
  Future<WorkspacePurchasedWarrantyRead?> read(WorkspacePurchasedWarrantyTarget target);
}

class WorkspacePurchasedLineTarget {
  WorkspacePurchasedLineTarget({required this.accountUserId, required this.role, required this.realm,
    required this.reference, required WorkspacePurchasedSkuLine line, this.buyingStoreId})
    : _lineFacts = jsonEncode(line.toJson());
  final String accountUserId, realm;
  final WorkspaceOrderIdentityRole role;
  final String? buyingStoreId;
  final WorkspacePurchaseReference reference;
  final String _lineFacts;
  Map<String, Object?> get lineFacts => (jsonDecode(_lineFacts) as Map).cast<String, Object?>();
  String get binding => _goodsFingerprint([accountUserId, role.name, realm, buyingStoreId, reference.toJson(), jsonDecode(_lineFacts)]);
}

typedef WorkspacePurchasedWarrantyTarget = WorkspacePurchasedLineTarget;

/// Proposed private device reader; no network implementation exists here.
/// Source implementations must verify the authenticated purchase/owner.
abstract interface class WorkspacePurchasedUnitSource {
  String get accountUserId;
  bool get isCurrent;
  Object? get lifetime;
  /// Notify when records, owner access or the authenticated lifetime changes.
  void addListener(void Function() listener);
  void removeListener(void Function() listener);
  /// Must retire an expired/revoked owner grant even when the reader survives.
  bool ownerAccessCurrent(WorkspacePurchasedUnitOwnerAccess access);
  Future<WorkspacePurchasedUnitsRead?> read(WorkspacePurchasedLineTarget target);
}

/// A proposed integration capability, separate from read-only sources. The
/// provider must enforce owner membership, revision checks and operation IDs.
abstract interface class WorkspacePurchasedUnitPublisher implements WorkspacePurchasedUnitSource {
  Future<WorkspacePurchasedUnitPublishReply?> share(WorkspacePurchasedLineTarget target, WorkspacePurchasedUnitPublishCommand command);
  Future<WorkspacePurchasedUnitPublishReply?> checkSharing(WorkspacePurchasedLineTarget target, WorkspacePurchasedUnitPublishCommand command);
}

/// Accepted buyer statements only; never the buyer's private report draft.
abstract interface class WorkspaceReceivedDeviceReportSource implements WorkspacePurchasedUnitSource {
  Future<WorkspaceReceivedDeviceReports?> readReceivedReports(WorkspacePurchasedLineTarget target, {String? cursor});
}

/// Exact owner-authorised handoff to the existing Store case response UI.
/// Contains an existing source case, never a request to create a local case.
class WorkspaceDeviceCaseHandoff {
  WorkspaceDeviceCaseHandoff({required this.gateway, required this.source, required this.target,
    required this.original, required this.issue, required this.ownerAccess}) : lifetime = source.lifetime;
  final AuthenticatedWorkspaceOrderIdentityGateway gateway;
  final WorkspaceReceivedDeviceReportSource source;
  final WorkspacePurchasedLineTarget target;
  final WorkspacePurchaseOrder original;
  final WorkspaceIssueRecord issue;
  final WorkspacePurchasedUnitOwnerAccess ownerAccess;
  final Object? lifetime;
  bool get current {
    try {
      final context = issue.purchaseContext;
      return gateway.isCurrent && gateway.accountUserId == target.accountUserId && identical(gateway.purchasedUnitSource, source) &&
        source.isCurrent && source.accountUserId == target.accountUserId && lifetime != null && source.lifetime == lifetime &&
        source.ownerAccessCurrent(ownerAccess) && ownerAccess.allows(target, DateTime.now().toUtc()) &&
        issue.valid && issue.accountScope == target.accountUserId && issue.workspaceId == target.reference.storeId && context != null &&
        context.realm == target.realm && jsonEncode(context.reference.toJson()) == jsonEncode(target.reference.toJson()) &&
        context.lineIds.contains(target.lineFacts['lineId']) && context.lineIds.every((id) => original.lines.any((line) => line.lineId == id)) &&
        original.storeId == target.reference.storeId && original.orderId == target.reference.orderId &&
        original.originalFingerprint == target.reference.originalFingerprint &&
        original.lines.any((line) => jsonEncode(line.toJson()) == jsonEncode(target.lineFacts));
    } on Object { return false; }
  }
}

class WorkspaceReceivedDeviceReport {
  WorkspaceReceivedDeviceReport({required this.id, required this.note, required this.recordedAt, required this.deviceRevision,
    required this.deviceFingerprint, required this.commandFingerprint, required List<WorkspacePurchasedUnitRow> rows, this.supportCase}) : rows = List.unmodifiable(rows);
  final String id, note, deviceFingerprint, commandFingerprint;
  final int deviceRevision;
  final DateTime recordedAt;
  final List<WorkspacePurchasedUnitRow> rows;
  final WorkspaceIssueRecord? supportCase;
  String get fingerprint => _goodsFingerprint([id, note, recordedAt.toUtc().toIso8601String(), deviceRevision, deviceFingerprint,
    commandFingerprint, rows.map((r) => r.toJson()).toList()]);
  bool validFor(WorkspacePurchasedLineTarget target, WorkspacePurchaseOrder original) {
    final context = supportCase?.purchaseContext;
    return _purchaseText(id) && !RegExp(r'[\x7f]').hasMatch(id) && note.isNotEmpty && note == note.trim() && note.length <= 2000 &&
      !RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]').hasMatch(note) && deviceRevision > 0 && deviceRevision <= 2147483647 &&
      RegExp(r'^[a-f0-9]{64}$').hasMatch(deviceFingerprint) && RegExp(r'^[a-f0-9]{64}$').hasMatch(commandFingerprint) &&
      rows.isNotEmpty && rows.length <= 1000 && rows.every((r) => r.ready) && rows.map((r) => r.id).toSet().length == rows.length &&
      (supportCase == null || supportCase!.valid && supportCase!.accountScope == target.accountUserId && supportCase!.workspaceId == target.reference.storeId &&
        context != null && context.realm == target.realm && jsonEncode(context.reference.toJson()) == jsonEncode(target.reference.toJson()) &&
        context.lineIds.contains(target.lineFacts['lineId']) && context.lineIds.every((id) => original.lines.any((line) => line.lineId == id)));
  }
}

class WorkspaceReceivedDeviceReports {
  WorkspaceReceivedDeviceReports({required this.target, required this.revision, required this.ownerAccess,
    this.original, required List<WorkspaceReceivedDeviceReport> reports, this.complete = false, this.nextCursor}) : reports = List.unmodifiable(reports);
  final WorkspacePurchasedLineTarget target;
  final WorkspacePurchasedUnitOwnerAccess ownerAccess;
  /// Filled by the gateway's existing authenticated original read, never trusted
  /// from a report-source payload.
  final WorkspacePurchaseOrder? original;
  final int revision;
  final List<WorkspaceReceivedDeviceReport> reports;
  final bool complete;
  final String? nextCursor;
  bool validFor(WorkspacePurchasedLineTarget expected, WorkspacePurchaseOrder verified) => expected.role == WorkspaceOrderIdentityRole.seller &&
    target.binding == expected.binding && ownerAccess.boundTo(expected) && revision >= 0 && revision <= 2147483647 && (revision > 0 || reports.isEmpty) &&
    reports.length <= 50 && reports.map((r) => r.id).toSet().length == reports.length && reports.every((r) => r.validFor(expected, verified)) &&
    (nextCursor == null || nextCursor!.isNotEmpty && nextCursor!.length <= 512) && (!complete || nextCursor == null);
}

enum WorkspacePurchasedUnitPublishState { applied, pending, closed }

/// Purchase-linked reporting grants no supplier editing or publishing rights.
class WorkspacePurchasedUnitReportAccess {
  const WorkspacePurchasedUnitReportAccess({required this.accountUserId, required this.targetBinding, required this.expiresAt});
  final String accountUserId, targetBinding;
  final DateTime expiresAt;
  bool boundTo(WorkspacePurchasedLineTarget target) => target.role == WorkspaceOrderIdentityRole.buyer &&
    accountUserId == target.accountUserId && targetBinding == target.binding;
  bool allows(WorkspacePurchasedLineTarget target, DateTime now) => boundTo(target) && expiresAt.isAfter(now.toUtc());
}

abstract interface class WorkspacePurchasedUnitReporter implements WorkspacePurchasedUnitSource {
  /// Retire revoked/expired grants permanently and notify listeners even if this
  /// source object survives. A renewed grant cannot revive an old submission.
  bool reportAccessCurrent(WorkspacePurchasedUnitReportAccess access);
  Future<WorkspacePurchasedUnitReportReply?> reportMismatch(WorkspacePurchasedLineTarget target, WorkspacePurchasedUnitMismatchCommand command);
  Future<WorkspacePurchasedUnitReportReply?> checkMismatch(WorkspacePurchasedLineTarget target, WorkspacePurchasedUnitMismatchCommand command);
}

/// A recorded report is not a resolution, accepted return, refund or replacement.
/// Closed guarantees never recorded now or later; missing/not-found is pending.
class WorkspacePurchasedUnitReportReply {
  const WorkspacePurchasedUnitReportReply({required this.operationId, required this.commandFingerprint, required this.targetBinding,
    required this.state, this.reportId, this.recordedAt});
  final String operationId, commandFingerprint, targetBinding;
  final WorkspacePurchasedUnitPublishState state;
  final String? reportId;
  final DateTime? recordedAt;
  bool validFor(WorkspacePurchasedUnitMismatchCommand command, WorkspacePurchasedLineTarget target) =>
    command.valid && target.role == WorkspaceOrderIdentityRole.buyer && targetBinding == target.binding && command.key.binding == target.binding &&
    command.key.account == target.accountUserId && command.key.realm == target.realm && command.key.store == target.reference.storeId &&
    operationId == command.operationId && commandFingerprint == command.fingerprint &&
    (state == WorkspacePurchasedUnitPublishState.applied ? reportId != null && reportId!.isNotEmpty && reportId == reportId!.trim() &&
      reportId!.length <= 240 && !RegExp(r'[\x00-\x1f\x7f]').hasMatch(reportId!) && recordedAt != null : reportId == null && recordedAt == null);
}

class WorkspacePurchasedUnitPublishReply {
  const WorkspacePurchasedUnitPublishReply({required this.operationId, required this.commandFingerprint,
    required this.targetBinding, required this.state, this.record});
  final String operationId, commandFingerprint, targetBinding;
  final WorkspacePurchasedUnitPublishState state;
  final WorkspacePurchasedUnitsRead? record;
  /// Closed is authoritative: this operation did not apply and cannot apply
  /// later. Missing/not-found/transport failure is pending, never closed.
  bool validFor(WorkspacePurchasedUnitPublishCommand command, WorkspacePurchasedLineTarget target) =>
    command.valid && targetBinding == target.binding && command.key.binding == target.binding && command.key.account == target.accountUserId &&
    command.key.realm == target.realm && command.key.store == target.reference.storeId &&
    operationId == command.operationId && commandFingerprint == command.fingerprint &&
    (state == WorkspacePurchasedUnitPublishState.applied ? record != null && record!.validFor(target) && record!.complete &&
      record!.revision == command.expectedRevision + 1 && jsonEncode(record!.rows.map((r) => r.toJson()).toList()) ==
      jsonEncode(command.rows.map((r) => r.toJson()).toList()) : record == null);
}

class WorkspacePurchasedUnitOwnerAccess {
  const WorkspacePurchasedUnitOwnerAccess({required this.ownerAccountId, required this.storeId, required this.targetBinding, required this.expiresAt});
  final String ownerAccountId, storeId, targetBinding;
  final DateTime expiresAt;
  bool boundTo(WorkspacePurchasedLineTarget target) => target.role == WorkspaceOrderIdentityRole.seller &&
    target.accountUserId == ownerAccountId && target.reference.storeId == storeId && target.binding == targetBinding;
  bool allows(WorkspacePurchasedLineTarget target, DateTime now) => boundTo(target) && expiresAt.isAfter(now.toUtc());
}

class WorkspacePurchasedUnitsRead {
  WorkspacePurchasedUnitsRead({required this.target, required this.revision, required List<WorkspacePurchasedUnitRow> rows,
    required this.observedAt, this.ownerAccess, this.reportAccess, this.complete = false}) : rows = List.unmodifiable(rows);
  final WorkspacePurchasedLineTarget target;
  final int revision;
  final List<WorkspacePurchasedUnitRow> rows;
  final DateTime observedAt;
  final WorkspacePurchasedUnitOwnerAccess? ownerAccess;
  final WorkspacePurchasedUnitReportAccess? reportAccess;
  final bool complete;
  String get fingerprint => _goodsFingerprint([target.binding, revision, rows.map((r) => r.toJson()).toList(), complete]);
  bool validFor(WorkspacePurchasedLineTarget expected) => target.binding == expected.binding && revision >= 0 && revision <= 2147483647 &&
    (revision > 0 || rows.isEmpty) && rows.length <= 1000 && rows.every((r) => r.ready) &&
    rows.map((r) => r.id).toSet().length == rows.length && (ownerAccess == null || ownerAccess!.boundTo(expected)) &&
    (reportAccess == null || reportAccess!.boundTo(expected));
}

/// Literal recorded terms only; no coverage decision or calculated expiry.
class WorkspacePurchasedWarrantyTerms {
  WorkspacePurchasedWarrantyTerms({required Map<String, String> fields, this.startedAt}) : fields = Map.unmodifiable(fields);
  final Map<String, String> fields;
  final DateTime? startedAt;
  static const labels = <String, String>{'issuer': 'Warranty issuer', 'duration': 'Warranty duration',
    'startBasis': 'Warranty start basis', 'coverage': 'Warranty coverage', 'exclusions': 'Warranty exclusions',
    'service': 'Warranty service', 'contact': 'Warranty contact', 'reference': 'Warranty reference'};
  bool get valid => fields.isNotEmpty && fields.keys.every(labels.containsKey) && fields.values.every((value) =>
    value.isNotEmpty && value == value.trim() && value.length <= 2000 && !RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]').hasMatch(value)) &&
    (startedAt == null || fields.containsKey('startBasis'));
}

class WorkspacePurchasedWarrantyRead {
  const WorkspacePurchasedWarrantyRead({required this.target, required this.revision, required this.recordedAt, this.terms});
  final WorkspacePurchasedWarrantyTarget target;
  final int revision;
  final DateTime recordedAt;
  /// Null means the source explicitly returned no detailed terms for this line.
  /// A failed/missing source must return an unavailable read, not this outcome.
  final WorkspacePurchasedWarrantyTerms? terms;
  String get fingerprint => _goodsFingerprint([target.binding, revision, recordedAt.toUtc().toIso8601String(),
    terms?.fields, terms?.startedAt?.toUtc().toIso8601String()]);
  bool validFor(WorkspacePurchasedWarrantyTarget expected) => target.binding == expected.binding &&
    revision > 0 && revision <= 2147483647 && (terms == null || terms!.valid);
}

Object? _goodsCanonical(Object? value) => value is List ? value.map(_goodsCanonical).toList()
  : value is Map ? {for (final key in value.keys.cast<String>().toList()..sort()) key: _goodsCanonical(value[key])} : value;
String _goodsFingerprint(Object? value) => sha256.convert(utf8.encode(jsonEncode(_goodsCanonical(value)))).toString();
bool _goodsText(String value, [int max = 240]) => value.isNotEmpty && value == value.trim() && value.length <= max &&
  !RegExp(r'[\x00-\x1f\x7f]').hasMatch(value);
bool _goodsInt(Object? value, {int min = 0, int max = 2147483647}) => value is int && value >= min && value <= max;
void _goodsScope(Map<String, dynamic> r, WorkspaceRestockPurchaseOriginal original) {
  if (r['schemaVersion'] is! int || r['schemaVersion'] != 1 || r['realm'] != original.realm ||
      r['viewerUserId'] != original.accountScope || r['buyingStoreId'] != original.buyingStoreId) {
    throw const FormatException('Receiving scope changed.');
  }
}
Map<String, dynamic> _goodsChecked(Object? raw, List<String> keys) {
  final r = _exactMap(raw, [...keys, 'integrity']), body = Map<String, dynamic>.of(r)..remove('integrity');
  if (r['integrity'] != _goodsFingerprint(body)) throw const FormatException('Receiving record needs recovery.');
  return r;
}

/// Immutable operation; storage/recovery owns this identity before any dispatch.
class WorkspaceGoodsArrivalCommand {
  WorkspaceGoodsArrivalCommand._(this.supplierId, this.receipt, this._bytes);
  factory WorkspaceGoodsArrivalCommand({required String supplierId, required WorkspaceSupplierGoodsReceipt receipt}) {
    final frozen = WorkspaceSupplierGoodsReceipt.fromJson(receipt.toJson()), source = frozen.restockOriginal;
    if (source == null || frozen.recordedUtcOffsetMinutes == null || frozen.lines.length > 100 || !_goodsText(supplierId) ||
        ![frozen.id, frozen.expectedDeliveryId, frozen.reference].every(_goodsText) || frozen.lines.any((line) =>
          ![line.productId, line.productLabel, line.purchaseUnit, line.stockUnit].every(_goodsText) ||
          line.priorStockUnits.keys.any((key) => !_goodsText(key, 512)))) {
      throw const FormatException('Review the original purchase and reporting date before receiving.');
    }
    final bytes = jsonEncode({'schemaVersion': 1, 'buyingStoreId': source.buyingStoreId,
      'supplierId': supplierId, 'receipt': frozen.toJson()});
    if (utf8.encode(bytes).length > 60 * 1024) throw const FormatException('Receiving report is too large.');
    return WorkspaceGoodsArrivalCommand._(supplierId, frozen, bytes);
  }
  final String supplierId, _bytes;
  final WorkspaceSupplierGoodsReceipt receipt;
  String get fingerprint => _goodsFingerprint(toJson());
  String get receiptFingerprint => _goodsFingerprint(receipt.toJson());
  Map<String, Object?> toJson() => Map<String, Object?>.from(jsonDecode(_bytes) as Map);
  static WorkspaceGoodsArrivalCommand fromJson(Object? raw) {
    final r = _exactMap(raw, const ['schemaVersion', 'buyingStoreId', 'supplierId', 'receipt']);
    final result = WorkspaceGoodsArrivalCommand(supplierId: r['supplierId'] as String,
      receipt: WorkspaceSupplierGoodsReceipt.fromJson(r['receipt']));
    if (r['schemaVersion'] is! int || r['schemaVersion'] != 1 ||
        r['buyingStoreId'] != result.receipt.restockOriginal!.buyingStoreId ||
        _goodsFingerprint(r) != result.fingerprint) { throw const FormatException('Receiving command changed.'); }
    return result;
  }
}

class WorkspaceGoodsReceivingRead {
  const WorkspaceGoodsReceivingRead._(this.original, this.group);
  factory WorkspaceGoodsReceivingRead.fromResult(WorkspaceGoodsArrivalResult result) =>
    WorkspaceGoodsReceivingRead._(result.command.receipt.restockOriginal!, result.group);
  final WorkspaceRestockPurchaseOriginal original;
  final WorkspaceGoodsReceivingGroup? group;
}

/// Cumulative quantities are bounded by the ordered amount, not one arrival's
/// Stock delta. Goods can have been sold between two physical arrivals.
class WorkspaceGoodsReceivingLine {
  WorkspaceGoodsReceivingLine._(Map<String, dynamic> line, Map<String, dynamic> mapping)
    : sourceLineId = line['lineId'] as String, deliveredMilli = line['deliveredMilli'] as int,
      acceptedMilli = line['acceptedMilli'] as int, damagedMilli = line['damagedMilli'] as int,
      productId = mapping['productId'] as String, productLabel = mapping['productLabel'] as String,
      purchaseUnit = mapping['purchaseUnit'] as String, stockUnit = mapping['stockUnit'] as String,
      unitsPerPack = mapping['unitsPerPack'] as int, expectedMilli = mapping['expectedMilli'] as int;
  final String sourceLineId, productId, productLabel, purchaseUnit, stockUnit;
  final int deliveredMilli, acceptedMilli, damagedMilli, unitsPerPack, expectedMilli;
  int get acceptedStockUnits => acceptedMilli * unitsPerPack ~/ 1000;
  Object get mappingIdentity => (productId, productLabel, purchaseUnit, stockUnit, unitsPerPack, expectedMilli);
  static WorkspaceGoodsReceivingLine _decode(Object? raw) {
    final line = _exactMap(raw, const ['lineId', 'deliveredMilli', 'acceptedMilli', 'damagedMilli', 'mapping']);
    final mapping = _exactMap(line['mapping'], const ['productId', 'productLabel', 'purchaseUnit', 'stockUnit', 'unitsPerPack', 'expectedMilli']);
    if (!_id(line['lineId']) || !['productId', 'productLabel', 'purchaseUnit', 'stockUnit'].every((key) =>
        mapping[key] is String && _goodsText(mapping[key] as String)) ||
        !_goodsInt(line['deliveredMilli'], min: 1) || !_goodsInt(line['acceptedMilli']) || !_goodsInt(line['damagedMilli']) ||
        !_goodsInt(mapping['expectedMilli'], min: 1) || !_goodsInt(mapping['unitsPerPack'], min: 1, max: 1000000)) {
      throw const FormatException('Receiving totals changed.');
    }
    final result = WorkspaceGoodsReceivingLine._(line, mapping);
    if (result.deliveredMilli != result.acceptedMilli + result.damagedMilli || result.deliveredMilli > result.expectedMilli ||
        result.acceptedMilli * result.unitsPerPack % 1000 != 0) { throw const FormatException('Receiving totals changed.'); }
    return result;
  }
}

/// Server cumulative physical reports; not current on-hand or sellable Stock.
class WorkspaceGoodsReceivingGroup {
  WorkspaceGoodsReceivingGroup._(this.original, this.supplierId, this.revision, List<WorkspaceGoodsReceivingLine> lines,
    this._bytes) : lines = List.unmodifiable(lines);
  final WorkspaceRestockPurchaseOriginal original;
  final String supplierId, _bytes;
  final int revision;
  final List<WorkspaceGoodsReceivingLine> lines;
  Map<String, Object?> toJson() => Map<String, Object?>.from(jsonDecode(_bytes) as Map);
  static WorkspaceGoodsReceivingGroup _decode(Object? raw, WorkspaceRestockPurchaseOriginal original) {
    final r = _goodsChecked(raw, const ['schemaVersion', 'realm', 'buyingStoreId', 'groupId', 'source', 'supplierId', 'revision', 'lines']);
    if (r['schemaVersion'] is! int || r['schemaVersion'] != 1 || r['realm'] != original.realm ||
        r['buyingStoreId'] != original.buyingStoreId || r['groupId'] != original.deliveryGroupId ||
        _goodsFingerprint(r['source']) != _goodsFingerprint(original.toJson()) || r['supplierId'] is! String ||
        !_goodsText(r['supplierId'] as String) || !_goodsInt(r['revision'], min: 1, max: 9007199254740991) ||
        r['lines'] is! List || (r['lines'] as List).isEmpty || (r['lines'] as List).length > 100) {
      throw const FormatException('Receiving group changed.');
    }
    final lines = <WorkspaceGoodsReceivingLine>[];
    for (final rawLine in r['lines'] as List) {
      final line = WorkspaceGoodsReceivingLine._decode(rawLine);
      final expected = original.lines[line.sourceLineId];
      if (expected == null || expected.quantityMilli != line.expectedMilli || expected.quantityUnit != line.purchaseUnit ||
          ![line.productId, line.productLabel, line.purchaseUnit, line.stockUnit].every(_goodsText) ||
          lines.any((previous) => previous.sourceLineId == line.sourceLineId)) { throw const FormatException('Receiving line changed.'); }
      lines.add(line);
    }
    return WorkspaceGoodsReceivingGroup._(original, r['supplierId'] as String, r['revision'] as int, lines, jsonEncode(r));
  }
  bool includes(WorkspaceGoodsArrivalCommand command) => supplierId == command.supplierId &&
    _goodsFingerprint(original.toJson()) == _goodsFingerprint(command.receipt.restockOriginal!.toJson()) &&
    command.receipt.lines.every((line) => lines.any((total) => total.sourceLineId == line.sourceLineId &&
      total.mappingIdentity == line.mappingIdentity && total.deliveredMilli >= line.deliveredMilli &&
      total.acceptedMilli >= line.acceptedMilli && total.damagedMilli >= line.damagedMilli));
}

class WorkspaceGoodsArrivalProof {
  WorkspaceGoodsArrivalProof._(this.command, this.groupRevision, this.recordedAt, this.integrity, this._bytes);
  final WorkspaceGoodsArrivalCommand command;
  final int groupRevision;
  final DateTime recordedAt;
  final String integrity, _bytes;
  Map<String, Object?> toJson() => Map<String, Object?>.from(jsonDecode(_bytes) as Map);
  static WorkspaceGoodsArrivalProof _decode(Object? raw, WorkspaceGoodsArrivalCommand command, WorkspaceGoodsReceivingGroup group) {
    final r = _goodsChecked(raw, const ['schemaVersion', 'realm', 'buyingStoreId', 'operationId', 'report', 'supplierId',
      'receipt', 'commandFingerprint', 'receiptFingerprint', 'groupRevision', 'recordedAt']);
    final original = command.receipt.restockOriginal!;
    if (r['schemaVersion'] is! int || r['schemaVersion'] != 1 || r['realm'] != original.realm ||
        r['buyingStoreId'] != original.buyingStoreId || r['operationId'] != command.receipt.id || r['report'] != 'owner_reported' ||
        r['supplierId'] != command.supplierId || r['commandFingerprint'] != command.fingerprint ||
        r['receiptFingerprint'] != command.receiptFingerprint || _goodsFingerprint(r['receipt']) != command.receiptFingerprint ||
        !_goodsInt(r['groupRevision'], min: 1, max: group.revision) || !group.includes(command) || r['recordedAt'] is! String) {
      throw const FormatException('Receiving proof changed.');
    }
    final recordedAt = DateTime.parse(r['recordedAt'] as String);
    if (recordedAt.toUtc().toIso8601String() != r['recordedAt']) throw const FormatException('Receiving proof date changed.');
    return WorkspaceGoodsArrivalProof._(command, r['groupRevision'] as int, recordedAt, r['integrity'] as String, jsonEncode(r));
  }
}

/// A server fence closes one immutable receiving attempt; it never reverses
/// goods, changes Stock, cancels the purchase or authorises a financial refund.
class WorkspaceGoodsArrivalClosure {
  WorkspaceGoodsArrivalClosure._(this.command, this.closedAt, this.integrity, this._bytes);
  final WorkspaceGoodsArrivalCommand command;
  final DateTime closedAt;
  final String integrity, _bytes;
  Map<String, Object?> toJson() => Map<String, Object?>.from(jsonDecode(_bytes) as Map);
  static WorkspaceGoodsArrivalClosure _decode(Object? raw, WorkspaceGoodsArrivalCommand command) {
    final r = _goodsChecked(raw, const ['schemaVersion', 'realm', 'buyingStoreId', 'operationId', 'report', 'supplierId',
      'receipt', 'commandFingerprint', 'receiptFingerprint', 'outcome', 'closedAt']);
    final original = command.receipt.restockOriginal!;
    if (r['schemaVersion'] is! int || r['schemaVersion'] != 1 || r['realm'] != original.realm ||
        r['buyingStoreId'] != original.buyingStoreId || r['operationId'] != command.receipt.id ||
        r['report'] != 'owner_reported' || r['supplierId'] != command.supplierId || r['outcome'] != 'closed' ||
        r['commandFingerprint'] != command.fingerprint || r['receiptFingerprint'] != command.receiptFingerprint ||
        _goodsFingerprint(r['receipt']) != command.receiptFingerprint || r['closedAt'] is! String) {
      throw const FormatException('Receiving closure changed.');
    }
    final closedAt = DateTime.parse(r['closedAt'] as String);
    if (closedAt.toUtc().toIso8601String() != r['closedAt']) throw const FormatException('Receiving closure date changed.');
    return WorkspaceGoodsArrivalClosure._(command, closedAt, r['integrity'] as String, jsonEncode(r));
  }
}

class WorkspaceGoodsArrivalResult {
  const WorkspaceGoodsArrivalResult._(this.command, this.proof, this.group, [this.closure]);
  final WorkspaceGoodsArrivalCommand command;
  final WorkspaceGoodsArrivalProof? proof;
  final WorkspaceGoodsReceivingGroup? group;
  final WorkspaceGoodsArrivalClosure? closure;
  bool get recorded => proof != null;
  bool get closed => closure != null;
  Map<String, Object?> toJson() => {'schemaVersion': 1, 'realm': command.receipt.restockOriginal!.realm,
    'viewerUserId': command.receipt.restockOriginal!.accountScope, 'buyingStoreId': command.receipt.restockOriginal!.buyingStoreId,
    'state': recorded ? 'recorded' : closed ? 'closed' : 'not_found',
    'proof': proof?.toJson() ?? closure?.toJson(), 'group': group?.toJson()};
  static WorkspaceGoodsArrivalResult fromJson(Object? raw, WorkspaceGoodsArrivalCommand command) {
    final original = command.receipt.restockOriginal!;
    final r = _exactMap(raw, const ['schemaVersion', 'realm', 'viewerUserId', 'buyingStoreId', 'state', 'proof', 'group']);
    _goodsScope(r, original);
    final group = r['group'] == null ? null : WorkspaceGoodsReceivingGroup._decode(r['group'], original);
    if (r['state'] == 'not_found' && r['proof'] == null) return WorkspaceGoodsArrivalResult._(command, null, group);
    if (r['state'] == 'closed') {
      return WorkspaceGoodsArrivalResult._(command, null, group, WorkspaceGoodsArrivalClosure._decode(r['proof'], command));
    }
    if (r['state'] != 'recorded' || group == null) throw const FormatException('Receiving result needs recovery.');
    return WorkspaceGoodsArrivalResult._(command, WorkspaceGoodsArrivalProof._decode(r['proof'], command, group), group);
  }
}

/// Explicit configuration only. Review/guest/unsupported tenants never acquire
/// a provider or another account's records. No configuration/deployment occurs.
AuthenticatedWorkspaceOrderIdentityGateway? configuredWorkspacePurchaseReader({
  required String environment,
  required String projectId,
  required String? tenantId,
  required String accountUserId,
  required Object? Function() lifetime,
}) {
  const realm = String.fromEnvironment('MOOLSOCIAL_PURCHASE_REALM');
  if (!['evaluation', 'production'].contains(realm) ||
      environment != 'firebase-service' ||
      projectId != 'moolsocial-dev-503018' ||
      tenantId != null) {
    return null;
  }
  return AuthenticatedWorkspaceOrderIdentityGateway(
    endpoint: Uri.parse(
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
    ),
    accountUserId: accountUserId,
    lifetime: lifetime,
    credentials: FirebaseSocialContentCredentials(),
    transport: IoSocialContentTransport(),
  );
}

class WorkspacePurchaseOrder {
  WorkspacePurchaseOrder({
    required this.storeId,
    required this.orderId,
    required this.originalFingerprint,
    required List<WorkspacePurchasedSkuLine> lines,
    required Map<String, int> totals,
    this.benefitAttribution,
    this.hasFulfilmentContextSnapshot = false,
    this.fulfilmentContext,
    this.hasSupplierQuoteSnapshot = false,
    this.supplierQuote,
    this.purchaser,
  }) : lines = List.unmodifiable(lines),
       totals = Map.unmodifiable(totals);
  final String storeId, orderId, originalFingerprint;
  final List<WorkspacePurchasedSkuLine> lines;
  final Map<String, int> totals;
  final WorkspaceOriginalBenefitAttribution? benefitAttribution;
  final bool hasFulfilmentContextSnapshot;
  final WorkspaceOriginalFulfilmentContext? fulfilmentContext;
  final bool hasSupplierQuoteSnapshot;
  final WorkspaceOriginalSupplierQuote? supplierQuote;
  final WorkspaceOriginalPurchaser? purchaser;
  int get factsVersion => purchaser != null ? 11 : lines.any((line) => line.hasCommodityPriceSnapshot) ? 10 : lines.any((line) => line.hasSupplierTaxSnapshot) ? 9 : hasSupplierQuoteSnapshot ? 8 : hasFulfilmentContextSnapshot ? 7 : lines.any((line) => line.hasPublicListingSnapshot) ? 6 :
    lines.any((line) => line.hasScheduledFulfilmentSnapshot) ? 5 :
    lines.any((line) => line.variant != null) ? 4 : benefitAttribution == null ? 2 : 3;
}

/// Frozen accepted buyer entity. It supplies attribution, never current access,
/// payment, delivery or permission to post received goods into Stock.
class WorkspaceOriginalPurchaser {
  const WorkspaceOriginalPurchaser._(this.kind, this.storeId, this.name, this.purpose);
  final String kind;
  final String? storeId, name, purpose;
  Map<String, Object> toJson() => {'schemaVersion': 1, 'kind': kind,
    if (kind == 'store') ...{'storeId': storeId!, 'name': name!, 'purpose': purpose!}};
  static WorkspaceOriginalPurchaser fromJson(Object? value) {
    final raw = _map(value), data = _exactMap(raw, ['schemaVersion', 'kind',
      if (raw['kind'] == 'store') ...['storeId', 'name', 'purpose']]);
    if (data['schemaVersion'] != 1) throw const FormatException('Unsupported purchaser.');
    if (data['kind'] == 'personal') return const WorkspaceOriginalPurchaser._('personal', null, null, null);
    if (data['kind'] != 'store' || !_id(data['storeId']) || !_purchaseText(data['name']) ||
        (data['name'] as String).length > 200 || !const ['restock', 'buyDirect', 'groupBulkBuying'].contains(data['purpose'])) {
      throw const FormatException('Invalid purchasing Store.');
    }
    return WorkspaceOriginalPurchaser._('store', data['storeId'] as String, data['name'] as String, data['purpose'] as String);
  }
}

/// Immutable purchased merchandise attribution; not current payment or credit
/// eligibility. Expiry limits first purchase, not historical original readback.
class WorkspaceOriginalSupplierQuote {
  WorkspaceOriginalSupplierQuote._(this._encoded);
  final String _encoded;
  Map<String, dynamic> toJson() => _map(jsonDecode(_encoded));
  String get quoteId => toJson()['quoteId'] as String;
  String get agreementFingerprint => toJson()['agreementFingerprint'] as String;
  int get acceptedRevision => toJson()['acceptedRevision'] as int;
  int get merchandiseMinor => toJson()['merchandiseMinor'] as int;
  DateTime get validUntil => DateTime.parse(toJson()['validUntil'] as String).toUtc();
  Map<String, String> get quoteLineByPurchasedLineId => Map.unmodifiable({
    for (final b in toJson()['lines'] as List) b['lineId'] as String: b['quoteLineId'] as String});
}

/// Private frozen customer input, not verified address, eligibility or assignment.
class WorkspaceOriginalFulfilmentContext {
  WorkspaceOriginalFulfilmentContext._({required this.method, required this.recipient, required this.address,
    required Map<String, String> instructions}) : instructions = Map.unmodifiable(instructions);
  final String method;
  final ({String name, String phone})? recipient;
  final ({String line, String area, String pinCode, String landmark})? address;
  final Map<String, String> instructions;
  Map<String, Object?> toJson() => {'schemaVersion': 1, 'method': method,
    'recipient': recipient == null ? null : {'name': recipient!.name, 'phone': recipient!.phone},
    'address': address == null ? null : {'line': address!.line, 'area': address!.area,
      'pinCode': address!.pinCode, 'landmark': address!.landmark},
    'instructions': instructions.entries.map((i) => {'lineId': i.key, 'text': i.value}).toList()};
}

/// Frozen final-placement facts, not current coupons or cashback entitlement.
class WorkspaceOriginalBenefitAttribution {
  WorkspaceOriginalBenefitAttribution._(List<WorkspaceOriginalBenefitComponent> components)
    : components = List.unmodifiable(components);
  final List<WorkspaceOriginalBenefitComponent> components;
  Map<String, Object> toJson() => {'schemaVersion': 1, 'components': components.map((c) => c.toJson()).toList()};
}

class WorkspaceOriginalBenefitComponent {
  WorkspaceOriginalBenefitComponent._({required this.componentId, required this.benefitId,
    required this.benefitRevision, required this.label, required this.publisherType,
    required this.effect, required this.amountBasis, required this.sourceReference,
    required this.funderReference, required this.amountMinor, required Map<String, int> allocations})
    : allocations = Map.unmodifiable(allocations);
  final String componentId, benefitId, benefitRevision, label, publisherType, effect, amountBasis;
  // Opaque provenance only. Never render internal references as customer copy.
  final String sourceReference, funderReference;
  final int amountMinor;
  final Map<String, int> allocations;
  bool get isCashbackOffer => effect == 'cashback_offer';
  Map<String, Object> toJson() => {'componentId': componentId, 'benefitId': benefitId,
    'benefitRevision': benefitRevision, 'label': label, 'publisherType': publisherType,
    'effect': effect, 'amountBasis': amountBasis, 'sourceReference': sourceReference,
    'funderReference': funderReference, 'amountMinor': amountMinor,
    'allocations': allocations.entries.map((a) => {'lineId': a.key, 'amountMinor': a.value}).toList()};
}

/// Supplier-declared terms frozen with the purchase, not a charged tax amount
/// or verified registration. Historical readback never consults today's SKU.
class WorkspaceOriginalSupplierTaxSnapshot {
  const WorkspaceOriginalSupplierTaxSnapshot._({required this.termsRevision,
    required this.observedAt, required this.expiresAt, this.gst, this.legacyAmount});
  final String termsRevision, observedAt;
  final String? expiresAt;
  final BuyV2SupplierGstRate? gst;
  final BuyV2SupplierTaxAmount? legacyAmount;
  Map<String, Object?> toJson() => {'schemaVersion': 1, 'termsRevision': termsRevision,
    'observedAt': observedAt, 'expiresAt': expiresAt,
    'declaration': gst?.toChannelJson() ?? legacyAmount!.toJson()};
  static WorkspaceOriginalSupplierTaxSnapshot fromJson(Object? value) {
    final s = _exactMap(value, const ['schemaVersion', 'termsRevision', 'observedAt', 'expiresAt', 'declaration']);
    if (s['schemaVersion'] is! int || s['schemaVersion'] != 1 || !_id(s['termsRevision'])) {
      throw const FormatException('Invalid original supplier declaration.');
    }
    DateTime time(Object? raw) {
      if (raw is! String || raw.length != 24) throw const FormatException('Invalid original supplier time.');
      final parsed = DateTime.parse(raw).toUtc();
      if (parsed.toIso8601String() != raw) throw const FormatException('Invalid original supplier time.');
      return parsed;
    }
    final observed = time(s['observedAt']), expires = s['expiresAt'] == null ? null : time(s['expiresAt']);
    if (expires != null && !expires.isAfter(observed)) throw const FormatException('Invalid original supplier expiry.');
    final d = _map(s['declaration']);
    final gst = d['version'] == 2 ? BuyV2SupplierGstRate.fromChannelJson(d) : null;
    final amount = gst == null ? BuyV2SupplierTaxAmount.fromJson(d) : null;
    if (gst == null && amount == null) throw const FormatException('Missing original supplier declaration.');
    if (amount != null && amount.amountMinor > 1000000000000) {
      throw const FormatException('Original supplier amount exceeds the purchase limit.');
    }
    return WorkspaceOriginalSupplierTaxSnapshot._(termsRevision: s['termsRevision'] as String,
      observedAt: s['observedAt'] as String, expiresAt: s['expiresAt'] as String?, gst: gst, legacyAmount: amount);
  }
}

/// Historical supplier price, not current catalogue, payment or reservation.
class WorkspaceOriginalCommodityPriceSnapshot {
  WorkspaceOriginalCommodityPriceSnapshot._(this._encoded);
  final String _encoded;
  Map<String, dynamic> toJson() => _map(jsonDecode(_encoded));
  DateTime get confirmedAt => DateTime.parse(toJson()['confirmedAt']);
  DateTime get agreedAt => DateTime.parse(toJson()['agreedAt']);
  DateTime get validUntil => DateTime.parse(toJson()['validUntil']);
  int get confirmationRevision => toJson()['confirmationRevision'] as int;
  static WorkspaceOriginalCommodityPriceSnapshot fromJson(Object? value, {
    required String termsRevision, required BuyV2PublicListingIdentity? listing,
    required int quantityMilli, required String quantityUnit, required int unitPriceMinor,
  }) {
    Never bad() => throw const FormatException('Purchased supplier price needs checking.');
    int bounded(Object? v, int max) { if (v is! int || v < 1 || v > max) bad(); return v; }
    DateTime time(Object? v) {
      if (v is! String || v.length != 24) bad();
      final parsed = DateTime.tryParse(v)?.toUtc();
      if (parsed == null || parsed.toIso8601String() != v) bad();
      return parsed;
    }
    final r = _exactMap(value, const ['schemaVersion', 'termsRevision', 'confirmationRevision', 'confirmedAt', 'validUntil',
      'frequent', 'agreedAt', 'priceMinor', 'minimumPacks', 'incrementPacks', 'tiers']);
    final revision = bounded(r['confirmationRevision'], 1000000000);
    final confirmed = time(r['confirmedAt']), expiry = time(r['validUntil']), agreed = time(r['agreedAt']);
    if (r['schemaVersion'] is! int || r['schemaVersion'] != 1 || r['frequent'] is! bool || r['termsRevision'] != termsRevision ||
        !RegExp('^commodity-$revision-[A-F0-9]{16}\$').hasMatch(termsRevision) || listing == null ||
        !const [BuyV2OfferClass.wholesale, BuyV2OfferClass.bulk].contains(listing.channel) ||
        quantityUnit != 'pack' || quantityMilli % 1000 != 0 || confirmed.isAfter(agreed) || !agreed.isBefore(expiry) ||
        r['tiers'] is! List || (r['tiers'] as List).length > 20) bad();
    final price = bounded(r['priceMinor'], 99999999900), minimum = bounded(r['minimumPacks'], 100000000),
      increment = bounded(r['incrementPacks'], 100000000), quantity = quantityMilli ~/ 1000;
    if (quantity < minimum || (quantity - minimum) % increment != 0) bad();
    int lastMinimum = 0, lastPrice = price, selectedPrice = price;
    final tiers = <Map<String, int>>[];
    for (final raw in r['tiers'] as List) {
      final t = _exactMap(raw, const ['minimumPacks', 'unitPriceMinor']);
      final count = bounded(t['minimumPacks'], 999999), amount = bounded(t['unitPriceMinor'], 99999999900);
      if (count <= lastMinimum || count < minimum || (count - minimum) % increment != 0 || amount > lastPrice ||
          tiers.isEmpty && (count != minimum || amount != price)) bad();
      lastMinimum = count; lastPrice = amount;
      if (count <= quantity) selectedPrice = amount;
      tiers.add({'minimumPacks': count, 'unitPriceMinor': amount});
    }
    if (selectedPrice != unitPriceMinor) bad();
    return WorkspaceOriginalCommodityPriceSnapshot._(jsonEncode({'schemaVersion': 1, 'termsRevision': termsRevision,
      'confirmationRevision': revision, 'confirmedAt': r['confirmedAt'], 'validUntil': r['validUntil'], 'frequent': r['frequent'],
      'agreedAt': r['agreedAt'], 'priceMinor': price, 'minimumPacks': minimum, 'incrementPacks': increment, 'tiers': tiers}));
  }
}

class WorkspacePurchasedSkuLine {
  const WorkspacePurchasedSkuLine({
    required this.lineId,
    required this.skuId,
    required this.canonicalProductId,
    required this.verifiedPackId,
    required this.offerId,
    required this.offerRevision,
    required this.name,
    required this.packLabel,
    required this.quantityMilli,
    required this.quantityUnit,
    required this.unitPriceMinor,
    required this.lineTotalMinor,
    this.variant,
    this.hasScheduledFulfilmentSnapshot = false,
    this.scheduledFulfilment,
    this.hasPublicListingSnapshot = false,
    this.publicListing,
    this.hasSupplierTaxSnapshot = false,
    this.supplierTaxSnapshot,
    this.hasCommodityPriceSnapshot = false,
    this.commodityPriceSnapshot,
  });
  final String lineId,
      skuId,
      canonicalProductId,
      verifiedPackId,
      offerId,
      offerRevision;
  final String name, packLabel, quantityUnit;
  /// Null is legacy unknown; empty is a supplied original with no extra variant.
  final String? variant;
  /// Presence is retained even for an explicit null; legacy omission is unknown.
  final bool hasScheduledFulfilmentSnapshot;
  final BuyV2ScheduledFulfilment? scheduledFulfilment;
  /// Explicit null is retained in facts6. Never infer from desired scheduling
  /// or today’s catalogue; this is historical identity, not permission to buy.
  final bool hasPublicListingSnapshot;
  final BuyV2PublicListingIdentity? publicListing;
  final bool hasSupplierTaxSnapshot;
  final WorkspaceOriginalSupplierTaxSnapshot? supplierTaxSnapshot;
  final bool hasCommodityPriceSnapshot;
  final WorkspaceOriginalCommodityPriceSnapshot? commodityPriceSnapshot;
  final int quantityMilli, unitPriceMinor, lineTotalMinor;
  String get quantityLabel {
    final fraction = quantityMilli % 1000;
    final digits = fraction == 0 ? '' : '.${fraction.toString().padLeft(3, '0').replaceFirst(RegExp(r'0+$'), '')}';
    return '${quantityMilli ~/ 1000}$digits $quantityUnit';
  }
  Map<String, Object?> toJson() => {
    'lineId': lineId,
    'skuId': skuId,
    'canonicalProductId': canonicalProductId,
    'verifiedPackId': verifiedPackId,
    'offerId': offerId,
    'offerRevision': offerRevision,
    'name': name,
    'packLabel': packLabel,
    'quantityMilli': quantityMilli,
    'quantityUnit': quantityUnit,
    'unitPriceMinor': unitPriceMinor,
    'lineTotalMinor': lineTotalMinor,
    'variant': ?variant,
    if (hasScheduledFulfilmentSnapshot) 'scheduledFulfilment': scheduledFulfilment?.toJson(),
    if (hasPublicListingSnapshot) 'publicListing': publicListing?.toJson(),
    if (hasSupplierTaxSnapshot) 'supplierTaxSnapshot': supplierTaxSnapshot?.toJson(),
    if (hasCommodityPriceSnapshot) 'commodityPriceSnapshot': commodityPriceSnapshot?.toJson(),
  };
}

const _purchaseTotalKeys = [
  'itemsMinor',
  'discountMinor',
  'taxMinor',
  'deliveryMinor',
  'freightMinor',
  'paymentFeeMinor',
  'tipMinor',
  'totalMinor',
];
const _purchaseLineKeys = [
  'lineId',
  'skuId',
  'canonicalProductId',
  'verifiedPackId',
  'offerId',
  'offerRevision',
  'name',
  'packLabel',
  'quantityMilli',
  'quantityUnit',
  'unitPriceMinor',
  'lineTotalMinor',
];

Map<String, dynamic> _exactMap(Object? v, List<String> keys) {
  final m = _map(v);
  if (m.length != keys.length || keys.any((k) => !m.containsKey(k))) {
    throw const FormatException('Unsupported purchase facts.');
  }
  return m;
}

bool _purchaseMoney(Object? v) => v is int && v >= 0 && v <= 1000000000000;
bool _purchaseText(Object? v) =>
    v is String &&
    v.isNotEmpty &&
    v.trim() == v &&
    v.length <= 240 &&
    !RegExp(r'[\x00-\x1f]').hasMatch(v);

WorkspaceOriginalBenefitAttribution _decodeBenefits(Object? value, List<WorkspacePurchasedSkuLine> lines, int discountMinor) {
  final group = _exactMap(value, const ['schemaVersion', 'components']);
  final raw = group['components'];
  if (group['schemaVersion'] is! int || group['schemaVersion'] != 1 || raw is! List || raw.length > 32) {
    throw const FormatException('Unsupported original benefits.');
  }
  final gross = {for (final line in lines) line.lineId: BigInt.from(line.lineTotalMinor)};
  final discounts = <String, BigInt>{}, ids = <String>{};
  var totalDiscount = BigInt.zero;
  final components = <WorkspaceOriginalBenefitComponent>[];
  for (final item in raw) {
    final c = _exactMap(item, const ['componentId', 'benefitId', 'benefitRevision', 'label',
      'publisherType', 'effect', 'amountBasis', 'sourceReference', 'funderReference', 'amountMinor', 'allocations']);
    if (const ['componentId', 'benefitId', 'benefitRevision', 'sourceReference', 'funderReference'].any((key) => !_id(c[key])) ||
        !ids.add(c['componentId'] as String) || !_purchaseText(c['label']) || !_purchaseMoney(c['amountMinor']) ||
        !const ['supplier', 'platform', 'payment'].contains(c['publisherType']) ||
        !const ['instant_discount', 'cashback_offer'].contains(c['effect']) ||
        (c['effect'] == 'instant_discount' ? c['amountBasis'] != 'applied' :
          !const ['quoted', 'maximum'].contains(c['amountBasis']))) {
      throw const FormatException('Invalid original benefit.');
    }
    final values = c['allocations'];
    if (values is! List || values.isEmpty || values.length > 100) throw const FormatException('Invalid original allocations.');
    final allocations = <String, int>{};
    var sum = BigInt.zero;
    for (final value in values) {
      final a = _exactMap(value, const ['lineId', 'amountMinor']);
      if (!_id(a['lineId']) || !_purchaseMoney(a['amountMinor']) ||
          !gross.containsKey(a['lineId']) || allocations.containsKey(a['lineId'])) {
        throw const FormatException('Invalid original allocation.');
      }
      final lineId = a['lineId'] as String, amount = a['amountMinor'] as int;
      allocations[lineId] = amount;
      sum += BigInt.from(amount);
      if (c['effect'] == 'instant_discount') discounts[lineId] = (discounts[lineId] ?? BigInt.zero) + BigInt.from(amount);
    }
    if (sum != BigInt.from(c['amountMinor'] as int)) throw const FormatException('Contradictory original allocation.');
    if (c['effect'] == 'instant_discount') totalDiscount += sum;
    components.add(WorkspaceOriginalBenefitComponent._(componentId: c['componentId'] as String,
      benefitId: c['benefitId'] as String, benefitRevision: c['benefitRevision'] as String,
      label: c['label'] as String, publisherType: c['publisherType'] as String,
      effect: c['effect'] as String, amountBasis: c['amountBasis'] as String,
      sourceReference: c['sourceReference'] as String, funderReference: c['funderReference'] as String,
      amountMinor: c['amountMinor'] as int, allocations: allocations));
  }
  if (totalDiscount != BigInt.from(discountMinor) || discounts.entries.any((entry) => entry.value > gross[entry.key]!)) {
    throw const FormatException('Contradictory original discounts.');
  }
  return WorkspaceOriginalBenefitAttribution._(components);
}

WorkspacePurchaseOrder _decodePurchaseOrder(Object? value, String realm) {
  final data = _exactMap(value, const [
    'factsVersion',
    'storeId',
    'orderId',
    'original',
    'originalFingerprint',
  ]);
  final version = data['factsVersion'];
  if (version is! int || !const [2, 3, 4, 5, 6, 7, 8, 9, 10, 11].contains(version) ||
      !_id(data['storeId']) ||
      !_id(data['orderId'])) {
    throw const FormatException('Unsupported order reference.');
  }
  final original = _exactMap(data['original'], [
    'currency',
    'lines',
    'totals',
    if (version >= 3) 'benefitAttribution',
    if (version >= 7) 'fulfilmentContext',
    if (version >= 8) 'supplierQuote',
    if (version >= 11) 'purchaser',
  ]);
  final rawLines = original['lines'];
  if (original['currency'] != 'INR' ||
      rawLines is! List ||
      rawLines.isEmpty ||
      rawLines.length > 100) {
    throw const FormatException('Unsupported original lines.');
  }
  final lines = <WorkspacePurchasedSkuLine>[];
  for (final raw in rawLines) {
    final l = _exactMap(raw, [..._purchaseLineKeys, if (version >= 4) 'variant', if (version >= 5) 'scheduledFulfilment',
      if (version >= 6) 'publicListing', if (version >= 9) 'supplierTaxSnapshot', if (version >= 10) 'commodityPriceSnapshot']);
    if (version >= 4 && (l['variant'] is! String ||
        (l['variant'] as String).trim() != l['variant'] ||
        (l['variant'] as String).length > 240 ||
        RegExp(r'[\u0000-\u0008\u000b\u000c\u000e-\u001f]').hasMatch(l['variant'] as String))) {
      throw const FormatException('Invalid original variant.');
    }
    final scheduled = version >= 5 && l['scheduledFulfilment'] != null
      ? BuyV2ScheduledFulfilment.fromJson(l['scheduledFulfilment']) : null;
    if (scheduled != null && (scheduled.listing.realm != realm || scheduled.listing.storeId != data['storeId'] ||
        scheduled.listing.skuId != l['skuId'] || scheduled.listing.canonicalProductId != l['canonicalProductId'] ||
        scheduled.listing.verifiedPackId != l['verifiedPackId'])) {
      throw const FormatException('Original Scheduled selection conflicts with its purchased line.');
    }
    BuyV2PublicListingIdentity? listing;
    if (version >= 6 && l['publicListing'] != null) {
      listing = BuyV2PublicListingIdentity.fromJson(l['publicListing']);
      if (listing == null || listing.realm != realm || listing.storeId != data['storeId'] ||
          listing.skuId != l['skuId'] || listing.canonicalProductId != l['canonicalProductId'] || listing.verifiedPackId != l['verifiedPackId'] ||
          listing.listingId != 'listing-${sha256.convert(utf8.encode(jsonEncode([1, realm, data['storeId'], l['skuId'], listing.channel.name])))}' ||
          scheduled != null && listing != scheduled.listing) {
        throw const FormatException('Original public listing conflicts with its purchased line.');
      }
    }
    if ([
          'lineId',
          'skuId',
          'canonicalProductId',
          'verifiedPackId',
          'offerId',
          'offerRevision',
        ].any((k) => !_id(l[k])) ||
        !_purchaseText(l['name']) ||
        !_purchaseText(l['packLabel']) ||
        !['pack', 'kg', 'L', 'count'].contains(l['quantityUnit']) ||
        l['quantityMilli'] is! int ||
        l['quantityMilli'] < 1 ||
        l['quantityMilli'] > 1000000000 ||
        !_purchaseMoney(l['unitPriceMinor']) ||
        !_purchaseMoney(l['lineTotalMinor'])) {
      throw const FormatException('Invalid purchased line.');
    }
    final expected =
        (BigInt.from(l['unitPriceMinor'] as int) *
                BigInt.from(l['quantityMilli'] as int) +
            BigInt.from(500)) ~/
        BigInt.from(1000);
    if (expected != BigInt.from(l['lineTotalMinor'] as int)) {
      throw const FormatException('Contradictory line amount.');
    }
    final supplierTax = version >= 9 && l['supplierTaxSnapshot'] != null
      ? WorkspaceOriginalSupplierTaxSnapshot.fromJson(l['supplierTaxSnapshot']) : null;
    if (supplierTax?.legacyAmount != null && l['quantityUnit'] != 'pack') {
      throw const FormatException('Original supplier amount needs its selling pack.');
    }
    final commodityPrice = version >= 10 && l['commodityPriceSnapshot'] != null
      ? WorkspaceOriginalCommodityPriceSnapshot.fromJson(l['commodityPriceSnapshot'], termsRevision: l['offerRevision'] as String,
        listing: listing, quantityMilli: l['quantityMilli'] as int, quantityUnit: l['quantityUnit'] as String,
        unitPriceMinor: l['unitPriceMinor'] as int) : null;
    if (version >= 10 && commodityPrice == null && listing?.channel == BuyV2OfferClass.wholesale &&
        RegExp(r'^commodity-[1-9][0-9]*-[A-F0-9]{16}$').hasMatch(l['offerRevision'] as String)) {
      throw const FormatException('Missing purchased supplier price.');
    }
    lines.add(
      WorkspacePurchasedSkuLine(
        lineId: l['lineId'] as String,
        skuId: l['skuId'] as String,
        canonicalProductId: l['canonicalProductId'] as String,
        verifiedPackId: l['verifiedPackId'] as String,
        offerId: l['offerId'] as String,
        offerRevision: l['offerRevision'] as String,
        name: l['name'] as String,
        packLabel: l['packLabel'] as String,
        quantityMilli: l['quantityMilli'] as int,
        quantityUnit: l['quantityUnit'] as String,
        unitPriceMinor: l['unitPriceMinor'] as int,
        lineTotalMinor: l['lineTotalMinor'] as int,
        variant: version >= 4 ? l['variant'] as String : null,
        hasScheduledFulfilmentSnapshot: version >= 5,
        scheduledFulfilment: scheduled,
        hasPublicListingSnapshot: version >= 6,
        publicListing: listing,
        hasSupplierTaxSnapshot: version >= 9,
        supplierTaxSnapshot: supplierTax,
        hasCommodityPriceSnapshot: version >= 10,
        commodityPriceSnapshot: commodityPrice,
      ),
    );
  }
  if (lines.map((l) => l.lineId).toSet().length != lines.length) {
    throw const FormatException('Duplicate purchased line.');
  }
  lines.sort((a, b) => a.lineId.compareTo(b.lineId));
  final rawTotals = _exactMap(original['totals'], _purchaseTotalKeys);
  if (rawTotals.values.any((v) => !_purchaseMoney(v))) {
    throw const FormatException('Invalid totals.');
  }
  final totals = {for (final k in _purchaseTotalKeys) k: rawTotals[k] as int};
  final items = lines.fold<int>(0, (sum, l) => sum + l.lineTotalMinor);
  if (totals['itemsMinor'] != items ||
      totals['discountMinor']! > items ||
      totals['totalMinor'] !=
          items -
              totals['discountMinor']! +
              totals['taxMinor']! +
              totals['deliveryMinor']! +
              totals['freightMinor']! +
              totals['paymentFeeMinor']! +
              totals['tipMinor']!) {
    throw const FormatException('Contradictory order total.');
  }
  final attribution = version >= 3 ? _decodeBenefits(original['benefitAttribution'], lines, totals['discountMinor']!) : null;
  final fulfilment = version >= 7 ? _decodeFulfilmentContext(original['fulfilmentContext'], lines) : null;
  final supplierQuote = version >= 8 ? _decodeSupplierQuote(original['supplierQuote'], realm, lines, withCommodityPrice: version >= 10) : null;
  final purchaser = version >= 11 ? WorkspaceOriginalPurchaser.fromJson(original['purchaser']) : null;
  if (purchaser?.kind == 'store' && purchaser?.storeId == data['storeId']) throw const FormatException('Invalid self purchase.');
  final hash = sha256
      .convert(
        utf8.encode(
          jsonEncode({
            'factsVersion': version,
            'storeId': data['storeId'],
            'orderId': data['orderId'],
            'original': {
              'currency': 'INR',
              'lines': lines.map((l) => l.toJson()).toList(),
              'totals': totals,
              if (attribution != null) 'benefitAttribution': attribution.toJson(),
              if (version >= 7) 'fulfilmentContext': fulfilment?.toJson(),
              if (version >= 8) 'supplierQuote': supplierQuote?.toJson(),
              if (version >= 11) 'purchaser': purchaser!.toJson(),
            },
          }),
        ),
      )
      .toString();
  if (data['originalFingerprint'] != hash) {
    throw const FormatException('Original facts changed.');
  }
  return WorkspacePurchaseOrder(
    storeId: data['storeId'] as String,
    orderId: data['orderId'] as String,
    originalFingerprint: hash,
    lines: lines,
    totals: totals,
    benefitAttribution: attribution,
    hasFulfilmentContextSnapshot: version >= 7,
    fulfilmentContext: fulfilment,
    hasSupplierQuoteSnapshot: version >= 8,
    supplierQuote: supplierQuote,
    purchaser: purchaser,
  );
}

WorkspaceOriginalSupplierQuote? _decodeSupplierQuote(Object? value, String realm, List<WorkspacePurchasedSkuLine> lines, {bool withCommodityPrice = false}) {
  final bulk = lines.where((l) => l.publicListing?.channel == BuyV2OfferClass.bulk &&
    !(withCommodityPrice && l.commodityPriceSnapshot != null)).toList();
  if (value == null) {
    if (bulk.isNotEmpty) throw const FormatException('Missing purchased supplier agreement.');
    return null;
  }
  final r = _exactMap(value, const ['schemaVersion', 'realm', 'quoteId', 'acceptedRevision', 'agreementFingerprint',
    'offerRevision', 'acceptedAt', 'validUntil', 'merchandiseMinor', 'lines']);
  DateTime instant(Object? raw) {
    if (raw is! String) throw const FormatException('Invalid supplier agreement time.');
    final parsed = DateTime.parse(raw).toUtc();
    if (parsed.toIso8601String() != raw) throw const FormatException('Invalid supplier agreement time.');
    return parsed;
  }
  if (r['schemaVersion'] != 1 || r['schemaVersion'] is! int || r['realm'] != realm ||
      r['quoteId'] is! String || !RegExp(r'^bulk-[a-f0-9]{64}$').hasMatch(r['quoteId'] as String) ||
      r['agreementFingerprint'] is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(r['agreementFingerprint'] as String) ||
      r['acceptedRevision'] is! int || r['offerRevision'] is! int || r['offerRevision'] < 2 ||
      r['acceptedRevision'] > 999999999 || r['acceptedRevision'] != r['offerRevision'] + 1 ||
      !instant(r['acceptedAt']).isBefore(instant(r['validUntil'])) ||
      !_purchaseMoney(r['merchandiseMinor']) || r['merchandiseMinor'] < 1) {
    throw const FormatException('Invalid purchased supplier agreement.');
  }
  final raw = r['lines'];
  if (raw is! List || raw.isEmpty || raw.length > 100 || raw.length != bulk.length) {
    throw const FormatException('Supplier agreement lines do not match.');
  }
  final ids = <String>{}, quoteIds = <String>{}, bindings = <Map<String, String>>[];
  for (final value in raw) {
    final b = _exactMap(value, const ['lineId', 'quoteLineId']);
    if (!_id(b['lineId']) || !_id(b['quoteLineId']) || !ids.add(b['lineId'] as String) ||
        !quoteIds.add(b['quoteLineId'] as String) || !bulk.any((l) => l.lineId == b['lineId'])) {
      throw const FormatException('Supplier agreement lines do not match.');
    }
    bindings.add({'lineId': b['lineId'] as String, 'quoteLineId': b['quoteLineId'] as String});
  }
  if (bulk.fold<int>(0, (sum, l) => sum + l.lineTotalMinor) != r['merchandiseMinor']) {
    throw const FormatException('Supplier merchandise amount changed.');
  }
  bindings.sort((a,b) => a['lineId']!.compareTo(b['lineId']!));
  return WorkspaceOriginalSupplierQuote._(jsonEncode({'schemaVersion': 1, 'realm': realm, 'quoteId': r['quoteId'],
    'acceptedRevision': r['acceptedRevision'], 'agreementFingerprint': r['agreementFingerprint'], 'offerRevision': r['offerRevision'],
    'acceptedAt': r['acceptedAt'], 'validUntil': r['validUntil'], 'merchandiseMinor': r['merchandiseMinor'], 'lines': bindings}));
}

WorkspaceOriginalFulfilmentContext? _decodeFulfilmentContext(Object? value, List<WorkspacePurchasedSkuLine> lines) {
  if (value == null) return null;
  final r = _exactMap(value, const ['schemaVersion', 'method', 'recipient', 'address', 'instructions']);
  if (r['schemaVersion'] is! int || r['schemaVersion'] != 1 || !const ['delivery', 'collection'].contains(r['method']) ||
      r['method'] == 'collection' && (r['address'] != null || lines.any((l) => l.scheduledFulfilment != null))) {
    throw const FormatException('Invalid original fulfilment.');
  }
  String part(Object? v, int max, {bool multiline = true}) {
    if (v is! String || v != v.trim() || v.length > max ||
        (multiline ? RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f]') : RegExp(r'[\x00-\x1f]')).hasMatch(v)) {
      throw const FormatException('Invalid original customer detail.');
    }
    return v;
  }
  ({String name, String phone})? recipient;
  if (r['recipient'] != null) {
    final p = _exactMap(r['recipient'], const ['name', 'phone']);
    final name = part(p['name'], 240, multiline: false), phone = part(p['phone'], 30, multiline: false);
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (name.isEmpty && phone.isEmpty || phone.isNotEmpty &&
        (!RegExp(r'^\+?[0-9][0-9 ()-]*$').hasMatch(phone) || digits.length < 7 || digits.length > 15)) {
      throw const FormatException('Invalid original recipient.');
    }
    recipient = (name: name, phone: phone);
  }
  ({String line, String area, String pinCode, String landmark})? address;
  if (r['address'] != null) {
    final a = _exactMap(r['address'], const ['line', 'area', 'pinCode', 'landmark']);
    address = (line: part(a['line'], 1000), area: part(a['area'], 240), pinCode: part(a['pinCode'], 6), landmark: part(a['landmark'], 240));
    if ([address.line, address.area, address.pinCode, address.landmark].every((v) => v.isEmpty) ||
        address.pinCode.isNotEmpty && !RegExp(r'^[1-9][0-9]{5}$').hasMatch(address.pinCode)) {
      throw const FormatException('Invalid original address.');
    }
  }
  final rawNotes = r['instructions'];
  if (rawNotes is! List || rawNotes.length > lines.length) throw const FormatException('Invalid original instructions.');
  final instructions = <String, String>{};
  for (final raw in rawNotes) {
    final i = _exactMap(raw, const ['lineId', 'text']), note = part(i['text'], 1000), lineId = i['lineId'];
    if (!_id(lineId) || note.isEmpty || instructions.containsKey(lineId) || !lines.any((l) => l.lineId == lineId)) {
      throw const FormatException('Instructions do not match this order.');
    }
    instructions[lineId as String] = note;
  }
  final keys = instructions.keys.toList()..sort();
  return WorkspaceOriginalFulfilmentContext._(method: r['method'] as String, recipient: recipient, address: address,
    instructions: {for (final key in keys) key: instructions[key]!});
}
