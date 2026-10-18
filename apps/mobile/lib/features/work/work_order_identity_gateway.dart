import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../shared/social_content_gateway.dart';

enum WorkspaceOrderIdentityState { linked, unlinked, unavailable }

enum WorkspaceOrderIdentityRole { buyer, seller }

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
  bool get isCurrent => _ownerLifetime != null && lifetime() == _ownerLifetime;

  Future<WorkspacePurchaseReferencePage?> listPurchaseReferences({
    required WorkspaceOrderIdentityRole role,
    required String realm,
    String? storeId,
    String? cursor,
  }) async {
    if (!isCurrent ||
        !['evaluation', 'production'].contains(realm) ||
        (role == WorkspaceOrderIdentityRole.seller
            ? !_id(storeId)
            : storeId != null) ||
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
      final data = _exactMap(envelope['data'], const [
        'schemaVersion',
        'realm',
        'authNamespace',
        'viewerRole',
        'viewerUserId',
        'storeId',
        'coverage',
        'references',
        'nextCursor',
      ]);
      if (data['schemaVersion'] != 2 ||
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
  }) async {
    final result = await readPurchaseProjection(
      role: role,
      realm: realm,
      purchaseId: reference.purchaseId,
      storeId: role == WorkspaceOrderIdentityRole.seller
          ? reference.storeId
          : null,
      orderId: role == WorkspaceOrderIdentityRole.seller
          ? reference.orderId
          : null,
    );
    if (result == null ||
        !isCurrent ||
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
  }) async {
    bool current() => _ownerLifetime != null && lifetime() == _ownerLifetime;
    if (!current() ||
        !['evaluation', 'production'].contains(realm) ||
        !_id(purchaseId) ||
        (role == WorkspaceOrderIdentityRole.seller
            ? !_id(storeId) || !_id(orderId)
            : storeId != null || orderId != null)) {
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
      if (data['schemaVersion'] is! int || !const [2, 3].contains(data['schemaVersion']) ||
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
      final orders = rawOrders.map(_decodePurchaseOrder).toList();
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

/// Explicit operational adapter; the composed identity reader stays read-only.
/// No automatic retries. The existing Store journal/controller owns command
/// persistence and uncertain-attempt recovery before this adapter is bound.
class AuthenticatedWorkspaceOrderOperationsGateway {
  const AuthenticatedWorkspaceOrderOperationsGateway(this.identity);
  final AuthenticatedWorkspaceOrderIdentityGateway identity;
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
    if (enriched && (source['originalFactsVersion'] is! int || source['originalFactsVersion'] != 3)) {
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
      'factsVersion': enriched ? 3 : 2,
      'storeId': ref.storeId,
      'orderId': ref.orderId,
      'originalFingerprint': ref.originalFingerprint,
      'original': data['original'],
    });
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
  }) : lines = List.unmodifiable(lines),
       totals = Map.unmodifiable(totals);
  final String storeId, orderId, originalFingerprint;
  final List<WorkspacePurchasedSkuLine> lines;
  final Map<String, int> totals;
  final WorkspaceOriginalBenefitAttribution? benefitAttribution;
  int get factsVersion => benefitAttribution == null ? 2 : 3;
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
  });
  final String lineId,
      skuId,
      canonicalProductId,
      verifiedPackId,
      offerId,
      offerRevision;
  final String name, packLabel, quantityUnit;
  final int quantityMilli, unitPriceMinor, lineTotalMinor;
  String get quantityLabel {
    final fraction = quantityMilli % 1000;
    final digits = fraction == 0 ? '' : '.${fraction.toString().padLeft(3, '0').replaceFirst(RegExp(r'0+$'), '')}';
    return '${quantityMilli ~/ 1000}$digits $quantityUnit';
  }
  Map<String, Object> toJson() => {
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

WorkspacePurchaseOrder _decodePurchaseOrder(Object? value) {
  final data = _exactMap(value, const [
    'factsVersion',
    'storeId',
    'orderId',
    'original',
    'originalFingerprint',
  ]);
  final version = data['factsVersion'];
  if (version is! int || !const [2, 3].contains(version) ||
      !_id(data['storeId']) ||
      !_id(data['orderId'])) {
    throw const FormatException('Unsupported order reference.');
  }
  final original = _exactMap(data['original'], [
    'currency',
    'lines',
    'totals',
    if (version == 3) 'benefitAttribution',
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
    final l = _exactMap(raw, _purchaseLineKeys);
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
  final attribution = version == 3 ? _decodeBenefits(original['benefitAttribution'], lines, totals['discountMinor']!) : null;
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
  );
}
