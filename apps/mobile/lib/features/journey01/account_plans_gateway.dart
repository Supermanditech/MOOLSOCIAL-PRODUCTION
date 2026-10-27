import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../assistant/mool_assistant.dart';
import '../shared/social_content_gateway.dart';
import 'account_profile_gateway.dart' show AccountProfileOwner;

class AccountPlansFailure implements Exception {
  const AccountPlansFailure(this.code);
  final String code;
  @override
  String toString() => 'Plans are not available right now. Try again later.';
}

typedef AccountPlansScope = ({String audience, String? storeId});

abstract interface class AccountPlansGatewaySource {
  AccountPlansGateway? plansGateway(
    AccountProfileOwner owner,
    bool Function() isCurrent,
  );
}

Map<String, Object?> _map(Object? value, [Set<String>? keys]) {
  if (value is! Map<String, Object?> ||
      (keys != null &&
          (value.length != keys.length || !value.keys.every(keys.contains)))) {
    throw const AccountPlansFailure('invalid_plans_response');
  }
  return value;
}

String _text(Object? value, {int max = 320}) {
  if (value is! String ||
      value.trim().isEmpty ||
      value != value.trim() ||
      value.length > max ||
      RegExp(r'[\x00-\x1f]').hasMatch(value)) {
    throw const AccountPlansFailure('invalid_plans_response');
  }
  return value;
}

String _id(Object? value) {
  final text = _text(value, max: 128);
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]*$').hasMatch(text)) {
    throw const AccountPlansFailure('invalid_plans_response');
  }
  return text;
}

int _revision(Object? value, {int minimum = 1}) {
  if (value is! int || value < minimum || value > 9007199254740991) {
    throw const AccountPlansFailure('invalid_plans_response');
  }
  return value;
}

DateTime _stamp(Object? value) {
  if (value is! String) {
    throw const AccountPlansFailure('invalid_plans_response');
  }
  final stamp = DateTime.tryParse(value);
  if (stamp == null || !stamp.isUtc || stamp.toIso8601String() != value) {
    throw const AccountPlansFailure('invalid_plans_response');
  }
  return stamp;
}

List<String> _strings(Object? value, {bool ids = false}) {
  if (value is! List) throw const AccountPlansFailure('invalid_plans_response');
  final result = value.map((item) => ids ? _id(item) : _text(item)).toList();
  if (result.toSet().length != result.length) {
    throw const AccountPlansFailure('invalid_plans_response');
  }
  return List.unmodifiable(result);
}

AccountPlansScope _scope(Object? value) {
  final row = _map(value, {'audience', 'storeId'});
  if (row['audience'] == 'personal' && row['storeId'] == null) {
    return (audience: 'personal', storeId: null);
  }
  if (row['audience'] == 'workspace') {
    return (audience: 'workspace', storeId: _id(row['storeId']));
  }
  throw const AccountPlansFailure('invalid_plans_response');
}

class AccountPlansOffer {
  AccountPlansOffer._(Map<String, Object?> row)
    : id = _id(row['id']),
      version = _id(row['version']),
      name = _text(row['name'], max: 180),
      priceLabel = _text(row['priceLabel'], max: 240),
      features = _strings(row['features']),
      featureIds = _strings(row['featureIds'], ids: true),
      eligible = row['eligible'] as bool,
      recommended = row['recommended'] as bool;
  final String id, version, name, priceLabel;
  final List<String> features, featureIds;
  final bool eligible, recommended;
}

class AccountPlansSubscription {
  const AccountPlansSubscription._({
    required this.planId,
    required this.planVersion,
    required this.name,
    required this.state,
    required this.validFrom,
    required this.validUntil,
    required this.featureIds,
    required this.revision,
  });
  final String planId, planVersion, name, state;
  final DateTime validFrom, validUntil;
  final List<String> featureIds;
  final int revision;
}

class AccountPlansSnapshot {
  const AccountPlansSnapshot._({
    required this.owner,
    required this.scope,
    required this.catalogueRevision,
    required this.subscriptionRevision,
    required this.checkedAt,
    required this.validUntil,
    required this.offers,
    required this.subscription,
    required this.activeFeatureIds,
    required this.catalogueBinding,
    required this.subscriptionBinding,
  });
  final AccountProfileOwner owner;
  final AccountPlansScope scope;
  final int catalogueRevision, subscriptionRevision;
  final DateTime checkedAt, validUntil;
  final List<AccountPlansOffer> offers;
  final AccountPlansSubscription? subscription;
  final List<String> activeFeatureIds;
  final String catalogueBinding, subscriptionBinding;
  String get revision => '$catalogueRevision:$subscriptionRevision';

  static AccountPlansSnapshot decode(
    Object? value,
    AccountProfileOwner owner,
    AccountPlansScope scope,
    DateTime now,
    Duration roundTrip,
  ) {
    final row = _map(value, {
      'schemaVersion',
      'owner',
      'scope',
      'catalogueRevision',
      'subscriptionRevision',
      'checkedAt',
      'validUntil',
      'offers',
      'subscription',
      'activeFeatureIds',
    });
    final identity = _map(row['owner'], {'userId', 'projectId'});
    final checked = _stamp(row['checkedAt']), until = _stamp(row['validUntil']);
    if (row['schemaVersion'] != 1 ||
        identity['userId'] != owner.userId ||
        identity['projectId'] != owner.projectId ||
        _scope(row['scope']) != scope ||
        !until.isAfter(checked) ||
        until.difference(checked) > const Duration(minutes: 1) ||
        checked.isAfter(now.add(const Duration(seconds: 5))) ||
        !until.isAfter(now) ||
        roundTrip >= until.difference(checked) ||
        row['offers'] is! List) {
      throw const AccountPlansFailure('invalid_plans_response');
    }
    final offers = <AccountPlansOffer>[];
    for (final value in row['offers'] as List) {
      final item = _map(value, {
        'id',
        'version',
        'name',
        'priceLabel',
        'features',
        'featureIds',
        'eligible',
        'recommended',
      });
      if (item['eligible'] is! bool || item['recommended'] is! bool) {
        throw const AccountPlansFailure('invalid_plans_response');
      }
      offers.add(AccountPlansOffer._(item));
    }
    if (offers.map((offer) => offer.id).toSet().length != offers.length) {
      throw const AccountPlansFailure('invalid_plans_response');
    }
    final subRevision = _revision(row['subscriptionRevision'], minimum: 0);
    AccountPlansSubscription? subscription;
    if (row['subscription'] != null) {
      final sub = _map(row['subscription'], {
        'ownerUid',
        'scope',
        'revision',
        'planId',
        'planVersion',
        'name',
        'state',
        'validFrom',
        'validUntil',
        'featureIds',
      });
      final from = _stamp(sub['validFrom']), end = _stamp(sub['validUntil']);
      if (sub['ownerUid'] != owner.userId ||
          _scope(sub['scope']) != scope ||
          _revision(sub['revision']) != subRevision ||
          !end.isAfter(from) ||
          !{
            'active',
            'cancelled',
            'pending',
            'expired',
            'revoked',
          }.contains(sub['state'])) {
        throw const AccountPlansFailure('invalid_plans_response');
      }
      subscription = AccountPlansSubscription._(
        planId: _id(sub['planId']),
        planVersion: _id(sub['planVersion']),
        name: _text(sub['name'], max: 180),
        state: sub['state'] as String,
        validFrom: from,
        validUntil: end,
        featureIds: _strings(sub['featureIds'], ids: true),
        revision: subRevision,
      );
    } else if (subRevision != 0) {
      throw const AccountPlansFailure('invalid_plans_response');
    }
    final active = _strings(row['activeFeatureIds'], ids: true);
    final assignedActive =
        subscription != null &&
        {'active', 'cancelled'}.contains(subscription.state) &&
        !subscription.validFrom.isAfter(checked) &&
        subscription.validUntil.isAfter(checked);
    final expected = assignedActive
        ? subscription.featureIds
        : const <String>[];
    if (active.length != expected.length ||
        !active.every(expected.contains) ||
        (assignedActive && until.isAfter(subscription.validUntil))) {
      throw const AccountPlansFailure('invalid_plans_response');
    }
    // Age the grant conservatively by the measured request duration as well as
    // the wall-clock check. A replay cannot gain another full freshness window.
    final localLimit = now.add(until.difference(checked) - roundTrip);
    return AccountPlansSnapshot._(
      owner: owner,
      scope: scope,
      catalogueRevision: _revision(row['catalogueRevision']),
      subscriptionRevision: subRevision,
      checkedAt: checked,
      validUntil: until.isBefore(localLimit) ? until : localLimit,
      offers: List.unmodifiable(offers),
      subscription: subscription,
      activeFeatureIds: active,
      catalogueBinding: jsonEncode(row['offers']),
      subscriptionBinding: jsonEncode(row['subscription']),
    );
  }
}

/// One authenticated session owns this reader. It never persists paid grants.
class AccountPlansGateway extends ChangeNotifier {
  AccountPlansGateway({
    required this.owner,
    required this.isCurrent,
    required SocialContentCredentials credentials,
    SocialContentTransport? transport,
    DateTime Function()? clock,
  }) : _credentials = credentials,
       _transport =
           transport ??
           IoSocialContentTransport(
             followRedirects: false,
             maximumResponseBytes: 1024 * 1024,
           ),
       _clock = clock ?? DateTime.now {
    if (owner.tenantId != null ||
        owner.userId.isEmpty ||
        owner.userId.length > 128 ||
        !RegExp(r'^[a-z][a-z0-9-]{4,62}$').hasMatch(owner.projectId)) {
      throw const AccountPlansFailure('account_scope_mismatch');
    }
  }
  final AccountProfileOwner owner;
  final bool Function() isCurrent;
  final SocialContentCredentials _credentials;
  final SocialContentTransport _transport;
  final DateTime Function() _clock;
  final Map<AccountPlansScope, Future<AccountPlansSnapshot>> _pending = {};
  final Map<AccountPlansScope, int> _attempts = {};
  final Map<AccountPlansScope, AccountPlansSnapshot> _highWater = {};
  bool _denied = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _highWater.clear();
    super.dispose();
  }

  void _current() {
    if (_disposed || _denied || !isCurrent()) {
      throw const AccountPlansFailure('account_scope_mismatch');
    }
  }

  Future<AccountPlansSnapshot> read(
    AccountPlansScope scope, {
    bool fresh = false,
  }) {
    _current();
    _scope({'audience': scope.audience, 'storeId': scope.storeId});
    final pending = _pending[scope];
    if (!fresh && pending != null) return pending;
    final attempt = (_attempts[scope] ?? 0) + 1;
    _attempts[scope] = attempt;
    final future = _read(scope, attempt);
    _pending[scope] = future;
    if (_highWater.containsKey(scope)) {
      // Observers retire old grants and join this pending read. Notify after a
      // caller's widget build; a failed refresh cannot leave another view paid.
      scheduleMicrotask(() {
        if (!_disposed &&
            !_denied &&
            isCurrent() &&
            _attempts[scope] == attempt) {
          notifyListeners();
        }
      });
    }
    return future;
  }

  Future<AccountPlansSnapshot> _read(
    AccountPlansScope scope,
    int attempt,
  ) async {
    final elapsed = Stopwatch()..start();
    try {
      final token = await _credentials.firebaseIdToken();
      _current();
      final proof = await _credentials.appCheckToken(
        SocialAppCheckTokenMode.standard,
      );
      _current();
      if (token.trim().isEmpty || proof.trim().isEmpty) {
        throw const AccountPlansFailure('authentication_required');
      }
      final response = await _transport.postJson(
        Uri.https(
          'asia-south1-${owner.projectId}.cloudfunctions.net',
          '/moolSocialAccountPlans',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'X-Firebase-AppCheck': proof,
        },
        body: {
          'operation': 'read',
          'payload': {'audience': scope.audience, 'storeId': scope.storeId},
        },
      );
      _current();
      if (_attempts[scope] != attempt) {
        throw const AccountPlansFailure('stale_plans_response');
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        _denied = true;
        _highWater.clear();
        notifyListeners();
      }
      if (utf8.encode(response.body).length > 1024 * 1024) {
        throw const AccountPlansFailure('invalid_plans_response');
      }
      final body = _map(jsonDecode(response.body));
      if (response.statusCode != 200 || body['ok'] != true) {
        throw const AccountPlansFailure('plans_unavailable');
      }
      if (body.length != 2 || !body.containsKey('data')) {
        throw const AccountPlansFailure('invalid_plans_response');
      }
      final snapshot = AccountPlansSnapshot.decode(
        body['data'],
        owner,
        scope,
        _clock().toUtc(),
        elapsed.elapsed,
      );
      final prior = _highWater[scope];
      if (prior != null &&
          (snapshot.catalogueRevision < prior.catalogueRevision ||
              snapshot.subscriptionRevision < prior.subscriptionRevision ||
              snapshot.checkedAt.isBefore(prior.checkedAt) ||
              (snapshot.catalogueRevision == prior.catalogueRevision &&
                  snapshot.catalogueBinding != prior.catalogueBinding) ||
              (snapshot.subscriptionRevision == prior.subscriptionRevision &&
                  snapshot.subscriptionBinding != prior.subscriptionBinding))) {
        throw const AccountPlansFailure('stale_plans_response');
      }
      _highWater[scope] = snapshot;
      return snapshot;
    } finally {
      elapsed.stop();
      if (_attempts[scope] == attempt) _pending.remove(scope);
    }
  }
}

/// Existing assistant controller owns attempt/context invalidation and expiry.
/// The scoped extension prevents a personal grant being reused inside a Store.
class AccountPlansAssistantEntitlements extends ChangeNotifier
    implements MoolAssistantScopedEntitlementSource {
  AccountPlansAssistantEntitlements({required this.readGateway});
  final AccountPlansGateway? Function() readGateway;
  AccountPlansGateway? _observed;
  bool _disposed = false;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void _observe(AccountPlansGateway? gateway) {
    if (identical(gateway, _observed)) return;
    _observed?.removeListener(_changed);
    _observed = gateway;
    _observed?.addListener(_changed);
  }

  @override
  void dispose() {
    _disposed = true;
    _observed?.removeListener(_changed);
    _observed = null;
    super.dispose();
  }

  @override
  Future<MoolAssistantEntitlement> read(Object accountScope) => readForContext(
    MoolAssistantContext(accountScope: accountScope, authenticationRevision: 0),
  );
  @override
  Future<MoolAssistantEntitlement> readForContext(
    MoolAssistantContext context,
  ) async {
    if (_disposed) throw const AccountPlansFailure('stale_plans_response');
    final gateway = readGateway();
    _observe(gateway);
    final account = context.accountScope;
    if (account == null)
      throw const AccountPlansFailure('authentication_required');
    if (gateway == null ||
        gateway.owner != context.accountScope ||
        !context.signedIn ||
        (context.workspaceId != null &&
            (!context.inWorkspace || !context.storeWorkspace))) {
      return MoolAssistantEntitlement(
        accountScope: account,
        access: MoolAssistantAccess.unavailable,
        revision: 'unavailable',
      );
    }
    final scope = (
      audience: context.inWorkspace ? 'workspace' : 'personal',
      storeId: context.inWorkspace ? context.workspaceId : null,
    );
    final value = await gateway.read(scope);
    if (_disposed || !gateway.isCurrent() || value.scope != scope) {
      throw const AccountPlansFailure('stale_plans_response');
    }
    final sub = value.subscription;
    final access = value.activeFeatureIds.contains('mool_ai')
        ? MoolAssistantAccess.active
        : sub?.state == 'pending'
        ? MoolAssistantAccess.purchasePending
        : sub?.state == 'revoked'
        ? MoolAssistantAccess.revoked
        : sub != null &&
              {'expired', 'cancelled', 'active'}.contains(sub.state) &&
              !sub.validUntil.isAfter(value.checkedAt)
        ? MoolAssistantAccess.expired
        : MoolAssistantAccess.subscriptionRequired;
    return MoolAssistantEntitlement(
      accountScope: gateway.owner,
      access: access,
      revision:
          '${value.scope.audience}:${value.scope.storeId}:${value.revision}',
      validUntil: value.validUntil,
    );
  }
}
