import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../shared/social_content_gateway.dart';
import '../buy/buy_v2_content_contracts.dart' show BuyV2AdvertisedBenefitTerms;

typedef StorePromotionScope = ({String account, String store, String realm});

Map<String, dynamic> _map(Object? raw, List<String> keys) {
  if (raw is! Map<String, dynamic> ||
      raw.length != keys.length ||
      keys.any((k) => !raw.containsKey(k))) {
    throw const FormatException('Promotion details could not be checked.');
  }
  return raw;
}

String _text(Object? raw, int maximum) {
  if (raw is! String ||
      raw.isEmpty ||
      raw != raw.trim() ||
      raw.length > maximum ||
      RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f]').hasMatch(raw)) {
    throw const FormatException('Check the promotion details.');
  }
  return raw;
}

String _id(Object? raw) {
  final value = _text(raw, 128);
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{2,127}$').hasMatch(value)) {
    throw const FormatException('Check the selected promotion.');
  }
  return value;
}

int _revision(Object? raw, [int minimum = 0]) {
  if (raw is! int || raw < minimum || raw > 1000000000) {
    throw const FormatException('Refresh this promotion.');
  }
  return raw;
}

DateTime _time(Object? raw) {
  final value = _text(raw, 32), at = DateTime.parse(value).toUtc();
  if (at.toIso8601String() != value) {
    throw const FormatException('Check the promotion date.');
  }
  return at;
}

String _iso(DateTime value) => DateTime.fromMillisecondsSinceEpoch(
  value.millisecondsSinceEpoch,
  isUtc: true,
).toIso8601String();
void _scope(StorePromotionScope scope) {
  _id(scope.account);
  _id(scope.store);
  if (!{'evaluation', 'production'}.contains(scope.realm)) {
    throw const FormatException('Check the Store connection.');
  }
}

const _inputKeys = [
  'skuId',
  'skuRevision',
  'channel',
  'headline',
  'detail',
  'validFrom',
  'validUntil',
  'active',
];

/// Complete explicit promotional input, not a price/benefit or targeted-message draft.
@immutable
class StorePromotionInput {
  StorePromotionInput({
    required String skuId,
    required int skuRevision,
    required String channel,
    required String headline,
    required String detail,
    required DateTime validFrom,
    required DateTime validUntil,
    required bool active,
    BuyV2AdvertisedBenefitTerms? benefitTerms,
  }) : _encoded = jsonEncode({
         'skuId': _id(skuId),
         'skuRevision': _revision(skuRevision, 1),
         'channel': channel,
         'headline': _text(headline.trim(), 160),
         'detail': _text(detail.trim(), 2000),
         'validFrom': _iso(validFrom),
         'validUntil': _iso(validUntil),
         'active': active,
         if (benefitTerms != null) 'benefitTerms': benefitTerms.toJson(),
       }) {
    if (!{'retail', 'wholesale', 'bulk'}.contains(channel) ||
        !this.validUntil.isAfter(this.validFrom)) {
      throw const FormatException('Check the channel and promotion dates.');
    }
  }
  final String _encoded;
  String get fingerprint => _encoded;
  Map<String, dynamic> toJson() => jsonDecode(_encoded) as Map<String, dynamic>;
  String get skuId => toJson()['skuId'] as String;
  int get skuRevision => toJson()['skuRevision'] as int;
  String get channel => toJson()['channel'] as String;
  String get headline => toJson()['headline'] as String;
  String get detail => toJson()['detail'] as String;
  DateTime get validFrom => _time(toJson()['validFrom']);
  DateTime get validUntil => _time(toJson()['validUntil']);
  bool get active => toJson()['active'] as bool;
  BuyV2AdvertisedBenefitTerms? get benefitTerms => toJson().containsKey('benefitTerms')
    ? BuyV2AdvertisedBenefitTerms.fromJson(toJson()['benefitTerms']) : null;
  StorePromotionInput paused() =>
      StorePromotionInput.fromJson(toJson()..['active'] = false);
  void validateForSave(DateTime now) {
    if (active && !validUntil.isAfter(now.toUtc())) {
      throw const FormatException('Choose a future promotion expiry.');
    }
  }

  factory StorePromotionInput.fromJson(Object? raw) {
    final row = _map(raw, [..._inputKeys, if (raw is Map && raw.containsKey('benefitTerms')) 'benefitTerms']);
    if (row['active'] is! bool) {
      throw const FormatException('Check the promotion status.');
    }
    return StorePromotionInput(
      skuId: _id(row['skuId']),
      skuRevision: _revision(row['skuRevision'], 1),
      channel: _text(row['channel'], 16),
      headline: _text(row['headline'], 160),
      detail: _text(row['detail'], 2000),
      validFrom: _time(row['validFrom']),
      validUntil: _time(row['validUntil']),
      active: row['active'] as bool,
      benefitTerms: row.containsKey('benefitTerms') ? BuyV2AdvertisedBenefitTerms.fromJson(row['benefitTerms']) : null,
    );
  }
}

@immutable
class StorePromotionIntent {
  StorePromotionIntent({
    required this.scope,
    required this.placementId,
    required this.expectedRevision,
    required this.idempotencyKey,
    required this.input,
  }) {
    _scope(scope);
    _id(placementId);
    _id(idempotencyKey);
    _revision(expectedRevision);
    if (expectedRevision >= 1000000000) {
      throw const FormatException('This promotion needs a service update.');
    }
  }
  final StorePromotionScope scope;
  final String placementId, idempotencyKey;
  final int expectedRevision;
  final StorePromotionInput input;
  Map<String, dynamic> get body => {
    'storeId': scope.store,
    'placementId': placementId,
    'expectedRevision': expectedRevision,
    'idempotencyKey': idempotencyKey,
    'promotion': input.toJson(),
  };
  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'accountId': scope.account,
    'realm': scope.realm,
    ...body,
  };
  String get fingerprint => jsonEncode(toJson());
  factory StorePromotionIntent.fromJson(Object? raw) {
    final row = _map(raw, [
      'schemaVersion',
      'accountId',
      'realm',
      'storeId',
      'placementId',
      'expectedRevision',
      'idempotencyKey',
      'promotion',
    ]);
    if (row['schemaVersion'] != 1) {
      throw const FormatException('Check the saved promotion update.');
    }
    return StorePromotionIntent(
      scope: (
        account: _id(row['accountId']),
        store: _id(row['storeId']),
        realm: _text(row['realm'], 16),
      ),
      placementId: _id(row['placementId']),
      expectedRevision: _revision(row['expectedRevision']),
      idempotencyKey: _id(row['idempotencyKey']),
      input: StorePromotionInput.fromJson(row['promotion']),
    );
  }
}

@immutable
class StorePromotionRecord {
  const StorePromotionRecord._(
    this.scope,
    this.placementId,
    this.revision,
    this.observedAt,
    this.input,
  );
  final StorePromotionScope scope;
  final String placementId;
  final int revision;
  final DateTime observedAt;
  final StorePromotionInput input;
  static StorePromotionRecord decode(
    Object? raw,
    StorePromotionScope scope,
    DateTime now,
  ) {
    _scope(scope);
    final row = _map(raw, [
      ..._inputKeys,
      if (raw is Map && raw.containsKey('benefitTerms')) 'benefitTerms',
      'schemaVersion',
      'realm',
      'storeId',
      'placementId',
      'revision',
      'observedAt',
    ]);
    final observed = _time(row['observedAt']);
    if (row['schemaVersion'] != 1 ||
        row['realm'] != scope.realm ||
        row['storeId'] != scope.store ||
        observed.isAfter(now.toUtc())) {
      throw const FormatException('Promotion details changed. Refresh them.');
    }
    return StorePromotionRecord._(
      scope,
      _id(row['placementId']),
      _revision(row['revision'], 1),
      observed,
      StorePromotionInput.fromJson({
        for (final key in _inputKeys) key: row[key],
        if (row.containsKey('benefitTerms')) 'benefitTerms': row['benefitTerms'],
      }),
    );
  }

  bool acknowledges(StorePromotionIntent original) =>
      scope == original.scope &&
      placementId == original.placementId &&
      revision == original.expectedRevision + 1 &&
      input.fingerprint == original.input.fingerprint;
}

enum StorePromotionResultState { saved, notSent, rejected, unknown }

class StorePromotionResult {
  const StorePromotionResult(this.state, {this.record});
  final StorePromotionResultState state;
  final StorePromotionRecord? record;
  bool get publicationConfirmed => false;
}

class StorePromotionPage {
  StorePromotionPage(List<StorePromotionRecord> records, this.nextCursor)
    : records = List.unmodifiable(records);
  final List<StorePromotionRecord> records;
  final String? nextCursor;
}

abstract interface class StorePromotionGateway {
  Future<StorePromotionRecord?> read(
    StorePromotionScope scope,
    String placementId,
    bool Function() current,
  );
  Future<StorePromotionPage> list(
    StorePromotionScope scope,
    bool Function() current, {
    String? after,
    int limit = 20,
  });
  Future<StorePromotionResult> save(
    StorePromotionIntent original,
    bool Function() current,
  );
  Future<StorePromotionResult> reconcile(
    StorePromotionIntent original,
    bool Function() current,
  );
}

class _NotSent implements Exception {}

abstract interface class StorePromotionTermsCapability {
  bool get benefitTermsSupported;
}

class AuthenticatedStorePromotionGateway implements StorePromotionGateway, StorePromotionTermsCapability {
  AuthenticatedStorePromotionGateway({
    required this.endpoint,
    required this.credentials,
    required this.transport,
    required this.ownerAccountId,
    required this.realm,
    this.benefitTermsSupported = false,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now {
    if (endpoint.scheme != 'https' ||
        endpoint.host !=
            'asia-south1-moolsocial-dev-503018.cloudfunctions.net' ||
        endpoint.path != '/moolSocialWorkspace' ||
        endpoint.hasQuery ||
        endpoint.hasFragment ||
        endpoint.hasPort ||
        endpoint.userInfo.isNotEmpty ||
        !{'evaluation', 'production'}.contains(realm)) {
      throw ArgumentError('Invalid Store connection.');
    }
    _id(ownerAccountId);
  }
  final Uri endpoint;
  final SocialContentCredentials credentials;
  final SocialContentTransport transport;
  final String ownerAccountId, realm;
  @override final bool benefitTermsSupported;
  final DateTime Function() now;
  void _check(StorePromotionScope scope, bool Function() current) {
    _scope(scope);
    if (scope.account != ownerAccountId || scope.realm != realm || !current()) {
      throw _NotSent();
    }
  }

  Future<SocialContentResponse> _request(
    StorePromotionScope scope,
    Map<String, dynamic> body,
    bool Function() current, {
    required bool mutation,
    required void Function() onSend,
    void Function()? beforeSend,
  }) async {
    _check(scope, current);
    if (!benefitTermsSupported && body['promotion'] is Map && (body['promotion'] as Map).containsKey('benefitTerms')) {
      throw _NotSent();
    }
    final token = await credentials.firebaseIdToken();
    _check(scope, current);
    final check = await credentials.appCheckToken(
      mutation
          ? SocialAppCheckTokenMode.limitedUse
          : SocialAppCheckTokenMode.standard,
    );
    _check(scope, current);
    beforeSend?.call();
    if (token.isEmpty || check.isEmpty) throw _NotSent();
    onSend();
    return transport
        .postJson(
          endpoint,
          headers: {
            'accept': 'application/json',
            'authorization': 'Bearer $token',
            'x-firebase-appcheck': check,
            'x-request-id': _key(),
          },
          body: {...body, if (benefitTermsSupported) 'promotionTermsVersion': 1},
        )
        .timeout(const Duration(seconds: 20));
  }

  Map<String, dynamic> _envelope(
    SocialContentResponse response,
    StorePromotionScope scope,
    List<String> fields,
  ) {
    if (response.statusCode != 200) {
      throw const FormatException('Promotions could not be checked.');
    }
    final envelope = jsonDecode(response.body);
    if (envelope is! Map || envelope['ok'] != true) {
      throw const FormatException('Promotions could not be checked.');
    }
    final row = _map(envelope['data'], [
      'schemaVersion',
      'realm',
      'storeId',
      'publicationConfirmed',
      if (benefitTermsSupported) 'promotionTermsVersion',
      ...fields,
    ]);
    if (row['schemaVersion'] is! int || row['schemaVersion'] != 1 ||
        benefitTermsSupported && (row['promotionTermsVersion'] is! int || row['promotionTermsVersion'] != 1) ||
        row['realm'] != scope.realm ||
        row['storeId'] != scope.store ||
        row['publicationConfirmed'] != false) {
      throw const FormatException('Promotion response changed.');
    }
    return row;
  }

  StorePromotionRecord? _record(
    SocialContentResponse response,
    StorePromotionScope scope,
    String placementId,
  ) {
    final row = _envelope(response, scope, ['record']);
    if (row['record'] == null) return null;
    final result = StorePromotionRecord.decode(row['record'], scope, now());
    if (result.input.benefitTerms != null && !benefitTermsSupported) throw const FormatException();
    if (result.placementId != placementId) {
      throw const FormatException('Wrong promotion returned.');
    }
    return result;
  }

  @override
  Future<StorePromotionRecord?> read(
    StorePromotionScope scope,
    String placementId,
    bool Function() current,
  ) async {
    _id(placementId);
    final response = await _request(
      scope,
      {
        'operation': 'readStorePromotion',
        'storeId': scope.store,
        'placementId': placementId,
      },
      current,
      mutation: false,
      onSend: () {},
    );
    _check(scope, current);
    return _record(response, scope, placementId);
  }

  @override
  Future<StorePromotionPage> list(
    StorePromotionScope scope,
    bool Function() current, {
    String? after,
    int limit = 20,
  }) async {
    if (limit < 1 || limit > 20) {
      throw const FormatException('Check the requested page.');
    }
    if (after != null) _id(after);
    final response = await _request(
      scope,
      {
        'operation': 'listStorePromotions',
        'storeId': scope.store,
        'limit': limit,
        'after': ?after,
      },
      current,
      mutation: false,
      onSend: () {},
    );
    _check(scope, current);
    final row = _envelope(response, scope, ['items', 'nextCursor']),
        items = row['items'];
    if (items is! List || items.length > limit) {
      throw const FormatException('Promotion page changed.');
    }
    final records = <StorePromotionRecord>[];
    var previous = after;
    for (final item in items) {
      final value = StorePromotionRecord.decode(item, scope, now());
      if (value.input.benefitTerms != null && !benefitTermsSupported) throw const FormatException();
      if (previous != null && value.placementId.compareTo(previous) <= 0) {
        throw const FormatException('Promotion page order changed.');
      }
      previous = value.placementId;
      records.add(value);
    }
    final next = row['nextCursor'] == null ? null : _id(row['nextCursor']);
    if (next != (records.length == limit ? records.last.placementId : null)) {
      throw const FormatException('Promotion page changed.');
    }
    return StorePromotionPage(records, next);
  }

  @override
  Future<StorePromotionResult> save(
    StorePromotionIntent original,
    bool Function() current,
  ) => _write(original, current, recovery: false);
  @override
  Future<StorePromotionResult> reconcile(
    StorePromotionIntent original,
    bool Function() current,
  ) => _write(original, current, recovery: true);
  Future<StorePromotionResult> _write(
    StorePromotionIntent original,
    bool Function() current, {
    required bool recovery,
  }) async {
    var sent = false;
    try {
      if (!recovery) original.input.validateForSave(now());
      final response = await _request(
        original.scope,
        {
          'operation': recovery
              ? 'reconcileStorePromotion'
              : 'saveStorePromotion',
          ...original.body,
        },
        current,
        mutation: !recovery,
        onSend: () => sent = true,
        beforeSend: recovery
            ? null
            : () => original.input.validateForSave(now()),
      );
      _check(original.scope, current);
      if (!recovery &&
          response.statusCode >= 400 &&
          response.statusCode < 500) {
        final error = jsonDecode(response.body);
        if (error is Map &&
            error['ok'] == false &&
            error['error'] is Map &&
            {
              'invalid_input',
              'conflict',
              'not_found',
              'invalid_state',
              'forbidden',
              'authentication_required',
            }.contains(error['error']['code'])) {
          return const StorePromotionResult(StorePromotionResultState.rejected);
        }
      }
      final result = _record(response, original.scope, original.placementId);
      return result?.acknowledges(original) == true
          ? StorePromotionResult(
              StorePromotionResultState.saved,
              record: result,
            )
          : const StorePromotionResult(StorePromotionResultState.unknown);
    } on Object {
      return StorePromotionResult(
        sent || recovery
            ? StorePromotionResultState.unknown
            : StorePromotionResultState.notSent,
      );
    }
  }
}

String _key() =>
    'promotion-${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';

/// One exact unresolved request per account/Store/realm; native implementation serializes across instances.
abstract interface class StorePromotionPendingStore {
  Future<StorePromotionIntent?> read(StorePromotionScope scope);
  Future<void> save(StorePromotionIntent original);
  Future<void> clear(StorePromotionIntent original);
}

class StorePromotionController extends ChangeNotifier {
  StorePromotionController({
    required this.scope,
    required this.gateway,
    required this.pendingStore,
    required this.context,
    required this.validateSelection,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now,
       _lifetime = context() {
    _scope(scope);
  }
  final StorePromotionScope scope;
  final StorePromotionGateway gateway;
  bool get benefitTermsSupported => gateway is StorePromotionTermsCapability &&
    (gateway as StorePromotionTermsCapability).benefitTermsSupported;
  final StorePromotionPendingStore pendingStore;
  final Object? Function() context;
  final Future<bool> Function(
    StorePromotionInput input,
    bool Function() current,
  )
  validateSelection;
  final DateTime Function() now;
  final Object? _lifetime;
  bool _closed = false, ready = false, busy = false;
  String? loadedPlacementId, message;
  StorePromotionRecord? currentRecord, lastAcknowledged;
  StorePromotionIntent? pending;
  Future<bool>? _restoring;
  bool get active => !_closed && _lifetime != null && context() == _lifetime;
  void _emit() {
    if (!_closed) notifyListeners();
  }

  Future<bool> restore() {
    if (!active) return Future.value(false);
    if (ready) return Future.value(true);
    return _restoring ??= _restore().whenComplete(() => _restoring = null);
  }

  Future<bool> _restore() async {
    try {
      final retained = await pendingStore
          .read(scope)
          .timeout(const Duration(seconds: 10));
      if (!active) return false;
      if (retained != null && retained.scope != scope) {
        throw const FormatException();
      }
      pending = retained;
      ready = true;
      message = null;
      return true;
    } on Object {
      if (active) {
        ready = false;
        message = 'Saved promotion update could not be opened. Try again.';
      }
      return false;
    } finally {
      if (active) _emit();
    }
  }

  Future<bool> refresh(String placementId) async {
    if (!active || busy) return false;
    _id(placementId);
    busy = true;
    _emit();
    try {
      if (!await restore() || !active || pending != null) return false;
      loadedPlacementId = null;
      final result = await gateway
          .read(scope, placementId, () => active)
          .timeout(const Duration(seconds: 25));
      if (!active) return false;
      if (result != null &&
          (result.scope != scope || result.placementId != placementId)) {
        throw const FormatException();
      }
      currentRecord = result;
      loadedPlacementId = placementId;
      message = null;
      return true;
    } on Object {
      if (active) {
        loadedPlacementId = null;
        message =
            'Current promotion could not be checked. Your entries are kept.';
      }
      return false;
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<StorePromotionResult> submit(
    String placementId,
    StorePromotionInput input, {
    bool Function()? inputCurrent,
  }) async {
    const notSent = StorePromotionResult(StorePromotionResultState.notSent);
    if (!active || busy) return notSent;
    busy = true;
    _emit();
    try {
      if (!await restore() ||
          !active ||
          pending != null ||
          loadedPlacementId != placementId) {
        return notSent;
      }
      bool current() => active && (inputCurrent?.call() ?? true);
      input.validateForSave(now());
      final old = currentRecord;
      if (!input.active) {
        if (old == null ||
            input.fingerprint != old.input.paused().fingerprint) {
          return notSent;
        }
      } else if (!await validateSelection(input, current) || !current()) {
        message =
            'The saved product or channel changed. Refresh before saving.';
        return notSent;
      }
      final original = StorePromotionIntent(
        scope: scope,
        placementId: placementId,
        expectedRevision: old?.revision ?? 0,
        idempotencyKey: _key(),
        input: input,
      );
      pending = original;
      try {
        await pendingStore.save(original).timeout(const Duration(seconds: 10));
      } on Object {
        // Nothing was dispatched. Remove only this original if storage can confirm it.
        try {
          await pendingStore
              .clear(original)
              .timeout(const Duration(seconds: 10));
          if (active) pending = null;
        } on Object {
          // Keep this exact original held when its durable cleanup is uncertain.
        }
        if (active) {
          message = 'Promotion was not sent. Saved recovery needs checking.';
        }
        return notSent;
      }
      if (!active) {
        return const StorePromotionResult(StorePromotionResultState.unknown);
      }
      // Still before transport: expiry/changed form is demonstrably unsent.
      // A failed exact cleanup remains held instead of inventing a missing receipt.
      try {
        if (!current()) return await _finish(original, notSent);
        input.validateForSave(now());
      } on Object {
        return await _finish(original, notSent);
      }
      final result = await gateway
          .save(original, current)
          .timeout(const Duration(seconds: 25));
      return await _finish(original, result);
    } on Object {
      if (active) {
        message = pending == null
            ? 'Check the promotion details.'
            : 'Check the original promotion update before another save.';
      }
      return StorePromotionResult(
        pending == null
            ? StorePromotionResultState.notSent
            : StorePromotionResultState.unknown,
      );
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<StorePromotionResult> reconcile() async {
    const unknown = StorePromotionResult(StorePromotionResultState.unknown);
    if (!active || busy) return unknown;
    busy = true;
    _emit();
    try {
      if (!await restore() || !active || pending == null) return unknown;
      final original = pending!;
      final result = await gateway
          .reconcile(original, () => active)
          .timeout(const Duration(seconds: 25));
      if (result.state != StorePromotionResultState.saved) return unknown;
      return await _finish(original, result);
    } on Object {
      if (active) message = 'The original result is still unconfirmed.';
      return unknown;
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<StorePromotionResult> _finish(
    StorePromotionIntent original,
    StorePromotionResult result,
  ) async {
    const unknown = StorePromotionResult(StorePromotionResultState.unknown);
    if (!active || pending?.fingerprint != original.fingerprint) return unknown;
    if (result.state == StorePromotionResultState.unknown ||
        result.state == StorePromotionResultState.saved &&
            result.record?.acknowledges(original) != true) {
      message = 'Check the original promotion update before another save.';
      return unknown;
    }
    try {
      await pendingStore.clear(original).timeout(const Duration(seconds: 10));
      if (!active) return unknown;
      pending = null;
      loadedPlacementId = null;
      if (result.state == StorePromotionResultState.saved) {
        lastAcknowledged = result.record;
      }
      message = result.state == StorePromotionResultState.saved
          ? 'Promotion update saved. Refresh to check its current state; public visibility is unconfirmed.'
          : 'Promotion was not saved. Refresh before trying again.';
      return result;
    } on Object {
      message = 'The original update needs checking before another save.';
      return unknown;
    }
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}
