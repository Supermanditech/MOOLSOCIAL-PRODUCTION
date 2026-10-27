import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/social_content_gateway.dart';
import '../buy/buy_v2_models.dart';
import '../buy/buy_v2_saved_products_store.dart';

class AccountProfileFailure implements Exception {
  const AccountProfileFailure(this.code, {this.uncertain = false});
  final String code;
  final bool uncertain;
  @override
  String toString() => uncertain
      ? 'Your Profile save needs checking before another change.'
      : 'Your Profile is unavailable. Please try again later.';
}

typedef AccountProfileOwner = ({
  String environment,
  String projectId,
  String? tenantId,
  String userId,
});

abstract interface class AccountProfileGatewaySource {
  AccountProfileGateway? profileGateway(
    AccountProfileOwner owner,
    bool Function() isCurrent,
  );
}

/// Only pending request data is stored on-device. It never establishes a
/// canonical Profile, imports ownerless fields, or stores credentials.
abstract interface class AccountProfilePendingStore {
  Future<String?> read(String ownerKey);
  Future<void> write(String ownerKey, String value);
  Future<void> clear(String ownerKey);
}

class PreferencesAccountProfilePendingStore
    implements AccountProfilePendingStore {
  PreferencesAccountProfilePendingStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  String _key(String ownerKey) => 'account-profile.pending.v1.$ownerKey';
  @override
  Future<String?> read(String ownerKey) =>
      _preferences.getString(_key(ownerKey));
  @override
  Future<void> write(String ownerKey, String value) =>
      _preferences.setString(_key(ownerKey), value);
  @override
  Future<void> clear(String ownerKey) => _preferences.remove(_key(ownerKey));
}

Map<String, Object?> _map(Object? raw) {
  if (raw is! Map<String, dynamic>) {
    throw const AccountProfileFailure('invalid_profile_response');
  }
  return Map<String, Object?>.from(raw);
}

void _keys(Map<String, Object?> row, Set<String> keys) {
  if (row.length != keys.length || !row.keys.every(keys.contains)) {
    throw const AccountProfileFailure('invalid_profile_response');
  }
}

String _text(Object? value, {int max = 2000, bool empty = false}) {
  if (value is! String ||
      value.length > max ||
      (!empty && value.trim().isEmpty) ||
      RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]').hasMatch(value)) {
    throw const AccountProfileFailure('invalid_profile_response');
  }
  return value;
}

String _id(Object? value) {
  final text = _text(value, max: 128);
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]*$').hasMatch(text)) {
    throw const AccountProfileFailure('invalid_profile_response');
  }
  return text;
}

int _revision(Object? value) {
  if (value is! int || value < 0 || value > 2147483647) {
    throw const AccountProfileFailure('invalid_profile_response');
  }
  return value;
}

// Field order and normalisation match the accepted server fingerprint contract.
// A receipt for another payload must never confirm this user's requested edit.
Map<String, Object?> _change(Object? raw) {
  final row = _map(raw);
  switch (row['kind']) {
    case 'name':
      _keys(row, {'kind', 'displayName'});
      final result = {
        'kind': 'name',
        'displayName': _text(
          row['displayName'],
        ).trim().replaceAll(RegExp(r'\s+'), ' '),
      };
      final name = result['displayName']!;
      if (name.length < 2 || name.length > 60)
        throw const AccountProfileFailure('invalid_profile_request');
      return result;
    case 'delivery':
      _keys(row, {'kind', 'addresses', 'selectedAddressId'});
      final addresses = row['addresses'];
      if (addresses is! List)
        throw const AccountProfileFailure('invalid_profile_request');
      return {
        'kind': 'delivery',
        'addresses': addresses.map((raw) {
          final a = _map(raw);
          _keys(a, {
            'id',
            'kind',
            'label',
            'recipient',
            'phone',
            'line',
            'area',
            'pinCode',
            'landmark',
          });
          return {
            'id': _id(a['id']),
            'kind': a['kind'],
            for (final field in [
              'label',
              'recipient',
              'phone',
              'line',
              'area',
              'pinCode',
              'landmark',
            ])
              field: _text(a[field] ?? '', empty: field == 'landmark').trim(),
          };
        }).toList(),
        'selectedAddressId': row['selectedAddressId'] == null
            ? null
            : _id(row['selectedAddressId']),
      };
    case 'invoices':
      _keys(row, {'kind', 'invoiceProfiles'});
      final invoices = row['invoiceProfiles'];
      if (invoices is! List)
        throw const AccountProfileFailure('invalid_profile_request');
      return {
        'kind': 'invoices',
        'invoiceProfiles': invoices.map((raw) {
          final a = _map(raw);
          _keys(a, {
            'id',
            'registration',
            'legalName',
            'gstin',
            'billingAddress',
          });
          return {
            'id': _id(a['id']),
            'registration': a['registration'],
            'legalName': _text(a['legalName']).trim(),
            'gstin': _text(a['gstin'], empty: true).trim().toUpperCase(),
            'billingAddress': _text(a['billingAddress']).trim(),
          };
        }).toList(),
      };
    default:
      throw const AccountProfileFailure('invalid_profile_request');
  }
}

class AccountProfileSnapshot {
  AccountProfileSnapshot._(
    this.ownerUid,
    this.revision,
    this.updatedAt,
    this.displayName,
    this.addresses,
    this.selectedAddressId,
    this.invoiceProfiles,
  );
  final String ownerUid;
  final int revision;
  final DateTime updatedAt;
  final String? displayName, selectedAddressId;
  final List<Map<String, Object?>> addresses, invoiceProfiles;

  Map<String, Object?> toJson() => {
    'ownerUid': ownerUid,
    'revision': revision,
    'updatedAt': updatedAt.toIso8601String(),
    'displayName': displayName,
    'addresses': addresses,
    'selectedAddressId': selectedAddressId,
    'invoiceProfiles': invoiceProfiles,
  };

  List<BuyV2Address> get deliveryAddresses => List.unmodifiable(
    addresses.map(
      (a) => BuyV2Address(
        id: a['id'] as String,
        kind: BuyV2AddressKind.values.byName(a['kind'] as String),
        label: a['label'] as String,
        recipient: a['recipient'] as String,
        phone: a['phone'] as String,
        line: a['line'] as String,
        area: a['area'] as String,
        pinCode: a['pinCode'] as String,
        landmark: a['landmark'] as String,
      ),
    ),
  );

  factory AccountProfileSnapshot.decode(Object? raw, String owner) {
    final row = _map(raw);
    _keys(row, {
      'ownerUid',
      'revision',
      'updatedAt',
      'displayName',
      'addresses',
      'selectedAddressId',
      'invoiceProfiles',
    });
    if (row['ownerUid'] != owner) {
      throw const AccountProfileFailure('account_scope_mismatch');
    }
    final stamp = DateTime.tryParse(_text(row['updatedAt']));
    if (stamp == null || !stamp.isUtc) {
      throw const AccountProfileFailure('invalid_profile_response');
    }
    List<Map<String, Object?>> records(Object? raw, bool delivery) {
      if (raw is! List)
        throw const AccountProfileFailure('invalid_profile_response');
      final ids = <String>{};
      return List.unmodifiable(
        raw.map((value) {
          final item = _map(value);
          _keys(
            item,
            delivery
                ? {
                    'id',
                    'kind',
                    'label',
                    'recipient',
                    'phone',
                    'line',
                    'area',
                    'pinCode',
                    'landmark',
                  }
                : {
                    'id',
                    'legalName',
                    'gstin',
                    'billingAddress',
                    'registration',
                  },
          );
          if (!ids.add(_id(item['id']))) {
            throw const AccountProfileFailure('invalid_profile_response');
          }
          for (final entry in item.entries) {
            _text(
              entry.value,
              empty: entry.key == 'landmark' || entry.key == 'gstin',
            );
          }
          if (delivery) {
            if (!{
                  'home',
                  'work',
                  'thirdParty',
                  'other',
                }.contains(item['kind']) ||
                !RegExp(r'^[1-9]\d{5}$').hasMatch(item['pinCode'] as String) ||
                !RegExp(
                  r'^[+\d() -]{7,32}$',
                ).hasMatch(item['phone'] as String)) {
              throw const AccountProfileFailure('invalid_profile_response');
            }
          } else {
            final registration = item['registration'];
            final gstin = item['gstin'] as String;
            if (!{'registered', 'unregistered'}.contains(registration) ||
                (registration == 'unregistered' && gstin.isNotEmpty) ||
                (registration == 'registered' &&
                    !RegExp(
                      r'^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
                    ).hasMatch(gstin))) {
              throw const AccountProfileFailure('invalid_profile_response');
            }
          }
          return Map<String, Object?>.unmodifiable(item);
        }),
      );
    }

    final addresses = records(row['addresses'], true);
    final selected = row['selectedAddressId'] == null
        ? null
        : _id(row['selectedAddressId']);
    if (selected != null && !addresses.any((a) => a['id'] == selected)) {
      throw const AccountProfileFailure('invalid_profile_response');
    }
    return AccountProfileSnapshot._(
      owner,
      _revision(row['revision']),
      stamp,
      row['displayName'] == null
          ? null
          : _text(row['displayName'], max: 120, empty: true),
      addresses,
      selected,
      records(row['invoiceProfiles'], false),
    );
  }
}

/// One session generation owns each instance. A restart reads the same pending
/// request from its account namespace; a timeout cannot manufacture a new save.
class AccountProfileGateway {
  AccountProfileGateway({
    required this.owner,
    required this.isCurrent,
    required SocialContentCredentials credentials,
    required AccountProfilePendingStore pendingStore,
    SocialContentTransport? transport,
    String Function()? requestId,
  }) : _credentials = credentials,
       _pendingStore = pendingStore,
       _transport =
           transport ??
           IoSocialContentTransport(
             followRedirects: false,
             maximumResponseBytes: 256 * 1024,
           ),
       _requestId = requestId ?? _newRequestId {
    if (owner.tenantId != null ||
        owner.environment.isEmpty ||
        !RegExp(r'^[a-z][a-z0-9-]{4,62}$').hasMatch(owner.projectId) ||
        owner.userId.isEmpty ||
        owner.userId.length > 128) {
      throw const AccountProfileFailure('account_scope_mismatch');
    }
  }
  final AccountProfileOwner owner;
  final bool Function() isCurrent;
  final SocialContentCredentials _credentials;
  final AccountProfilePendingStore _pendingStore;
  final SocialContentTransport _transport;
  final String Function() _requestId;
  bool _busy = false;
  bool _accessDenied = false;
  Future<AccountProfileSnapshot>? _reading;
  AccountProfileSnapshot? _snapshot;
  AccountProfileSnapshot? get snapshot =>
      isCurrent() && !_accessDenied ? _snapshot : null;
  String get _ownerKey => sha256
      .convert(
        utf8.encode(
          jsonEncode([
            owner.environment,
            owner.projectId,
            owner.tenantId,
            owner.userId,
          ]),
        ),
      )
      .toString();
  String? get ownerScope =>
      isCurrent() && !_accessDenied ? 'firebase-account:v1:$_ownerKey' : null;
  static String _newRequestId() {
    final random = Random.secure();
    return List.generate(
      24,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  void _current() {
    if (!isCurrent())
      throw const AccountProfileFailure('account_scope_mismatch');
  }

  Future<T> _exclusive<T>(Future<T> Function() action) async {
    _current();
    if (_busy) throw const AccountProfileFailure('profile_save_in_progress');
    _busy = true;
    try {
      return await action();
    } finally {
      _busy = false;
    }
  }

  Future<Object?> _call(String operation, Map<String, Object?> payload) async {
    _current();
    final token = await _credentials.firebaseIdToken();
    _current();
    final proof = await _credentials.appCheckToken(
      operation == 'save'
          ? SocialAppCheckTokenMode.limitedUse
          : SocialAppCheckTokenMode.standard,
    );
    _current();
    if (token.trim().isEmpty || proof.trim().isEmpty) {
      throw const AccountProfileFailure('authentication_required');
    }
    final response = await _transport.postJson(
      Uri.https(
        'asia-south1-${owner.projectId}.cloudfunctions.net',
        '/moolSocialAccountProfile',
      ),
      headers: {'Authorization': 'Bearer $token', 'X-Firebase-AppCheck': proof},
      body: {'operation': operation, 'payload': payload},
    );
    _current();
    if (response.statusCode == 401 || response.statusCode == 403) {
      // Firebase identity alone cannot override an account restriction.
      _snapshot = null;
      _accessDenied = true;
    }
    if (utf8.encode(response.body).length > 256 * 1024) {
      throw AccountProfileFailure(
        'invalid_profile_response',
        uncertain: operation == 'save',
      );
    }
    final body = _map(jsonDecode(response.body));
    if (response.statusCode != 200 || body['ok'] != true) {
      final error = body['error'];
      final code = error is Map && error['code'] is String
          ? error['code'] as String
          : 'profile_service_unavailable';
      throw AccountProfileFailure(
        code,
        uncertain:
            operation == 'save' &&
            (response.statusCode < 400 ||
                response.statusCode >= 500 ||
                error is! Map ||
                error['uncertain'] != false),
      );
    }
    _keys(body, {'ok', 'data'});
    return body['data'];
  }

  AccountProfileSnapshot _accept(Object? raw) {
    _current();
    final AccountProfileSnapshot value;
    try {
      value = AccountProfileSnapshot.decode(raw, owner.userId);
    } on AccountProfileFailure catch (error) {
      if (error.code == 'account_scope_mismatch') {
        _snapshot = null;
        _accessDenied = true;
      }
      rethrow;
    }
    if (_snapshot != null &&
        (value.revision < _snapshot!.revision ||
            value.revision == _snapshot!.revision &&
                jsonEncode(value.toJson()) !=
                    jsonEncode(_snapshot!.toJson()))) {
      throw const AccountProfileFailure('profile_revision_conflict');
    }
    _accessDenied = false;
    return _snapshot = value;
  }

  /// AI source validation never reconciles or replays an earlier save.
  Future<AccountProfileSnapshot> readForPreparation() => _exclusive(() async {
    final pending = await _pendingStore.read(_ownerKey);
    _current();
    if (pending != null) {
      throw const AccountProfileFailure('profile_outcome_unknown', uncertain: true);
    }
    return _accept(await _call('read', {}));
  });

  Future<AccountProfileSnapshot> read() {
    if (_reading != null) return _reading!;
    late final Future<AccountProfileSnapshot> read;
    read =
        _exclusive(() async {
          final raw = await _pendingStore.read(_ownerKey);
          _current();
          if (raw == null) return _accept(await _call('read', {}));
          final request = _originalRequest(raw);
          // This is continuation of the user's already-confirmed Profile save,
          // never a new draft/action. Readback precedes any same-key replay.
          try {
            final receipt = await _call('reconcile', {
              'requestId': request['requestId'],
            });
            return await _confirmed(
              receipt ?? await _call('save', request),
              request,
            );
          } on AccountProfileFailure catch (error) {
            await _discardExplicitRejection(error);
            rethrow;
          } on Object {
            throw const AccountProfileFailure(
              'profile_outcome_unknown',
              uncertain: true,
            );
          }
        }).whenComplete(() {
          if (identical(_reading, read)) _reading = null;
        });
    return _reading = read;
  }

  Map<String, Object?> _originalRequest(String raw) {
    final journal = _map(jsonDecode(raw));
    _keys(journal, {'ownerKey', 'request'});
    if (journal['ownerKey'] != _ownerKey)
      throw const AccountProfileFailure('account_scope_mismatch');
    final request = _map(journal['request']);
    _keys(request, {'requestId', 'expectedRevision', 'change'});
    _id(request['requestId']);
    _revision(request['expectedRevision']);
    _change(request['change']);
    return request;
  }

  Future<void> _discardExplicitRejection(AccountProfileFailure error) async {
    if (!error.uncertain &&
        isCurrent() &&
        {
          'invalid_profile_request',
          'profile_revision_conflict',
          'profile_request_conflict',
          'account_restricted',
          'account_not_ready',
          'profile_request_too_large',
        }.contains(error.code)) {
      await _pendingStore.clear(_ownerKey);
      _snapshot = null;
    }
    if (error.code == 'invalid_profile_response') {
      throw const AccountProfileFailure(
        'invalid_profile_response',
        uncertain: true,
      );
    }
  }

  Future<AccountProfileSnapshot> saveDelivery(
    List<BuyV2Address> addresses,
    String? selectedId,
  ) => save({
    'kind': 'delivery',
    'addresses': addresses
        .map(
          (a) => {
            'id': a.id,
            'kind': a.kind.name,
            'label': a.label,
            'recipient': a.recipient,
            'phone': a.phone,
            'line': a.line,
            'area': a.area,
            'pinCode': a.pinCode,
            'landmark': a.landmark,
          },
        )
        .toList(),
    'selectedAddressId': selectedId,
  });

  Future<AccountProfileSnapshot> save(
    Map<String, Object?> change,
  ) => _exclusive(() async {
    // Freeze before the first await; callers cannot change a dispatched request.
    final frozen = _change(jsonDecode(jsonEncode(change)));
    if (!{'name', 'delivery', 'invoices'}.contains(frozen['kind'])) {
      throw const AccountProfileFailure('invalid_profile_request');
    }
    final pending = await _pendingStore.read(_ownerKey);
    _current();
    Map<String, Object?> request;
    if (pending != null) {
      request = _originalRequest(pending);
      if (jsonEncode(request['change']) != jsonEncode(frozen)) {
        throw const AccountProfileFailure(
          'profile_original_save_pending',
          uncertain: true,
        );
      }
      final original = await _call('reconcile', {
        'requestId': request['requestId'],
      });
      if (original != null) return _confirmed(original, request);
    } else {
      final current = _snapshot;
      if (current == null)
        throw const AccountProfileFailure('profile_read_required');
      request = {
        'requestId': _id(_requestId()),
        'expectedRevision': current.revision,
        'change': frozen,
      };
      if (utf8
              .encode(jsonEncode({'operation': 'save', 'payload': request}))
              .length >
          65536) {
        throw const AccountProfileFailure('profile_request_too_large');
      }
      await _pendingStore.write(
        _ownerKey,
        jsonEncode({'ownerKey': _ownerKey, 'request': request}),
      );
      _current();
    }
    try {
      return await _confirmed(await _call('save', request), request);
    } on AccountProfileFailure catch (error) {
      // Explicit rejection cannot establish success. Unknown outcomes retain
      // the exact request for reconciliation rather than a second mutation.
      await _discardExplicitRejection(error);
      rethrow;
    } on Object {
      throw const AccountProfileFailure(
        'profile_outcome_unknown',
        uncertain: true,
      );
    }
  });

  Future<AccountProfileSnapshot> _confirmed(
    Object? raw,
    Map<String, Object?> request,
  ) async {
    final receipt = _map(raw);
    _keys(receipt, {'ownerUid', 'requestId', 'fingerprint', 'profile'});
    final expectedFingerprint = sha256
        .convert(
          utf8.encode(
            jsonEncode({
              'expectedRevision': request['expectedRevision'],
              'change': _change(request['change']),
            }),
          ),
        )
        .toString();
    if (receipt['ownerUid'] != owner.userId ||
        receipt['requestId'] != request['requestId'] ||
        receipt['fingerprint'] != expectedFingerprint ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(receipt['fingerprint'] as String)) {
      throw const AccountProfileFailure(
        'invalid_profile_response',
        uncertain: true,
      );
    }
    final value = AccountProfileSnapshot.decode(
      receipt['profile'],
      owner.userId,
    );
    if (value.revision != (request['expectedRevision'] as int) + 1) {
      throw const AccountProfileFailure(
        'invalid_profile_response',
        uncertain: true,
      );
    }
    _current();
    // Refresh canonical state: an original receipt can predate other-device edits.
    final latest = AccountProfileSnapshot.decode(
      await _call('read', {}),
      owner.userId,
    );
    if (latest.revision < value.revision) {
      throw const AccountProfileFailure(
        'invalid_profile_response',
        uncertain: true,
      );
    }
    _current();
    final confirmed = _accept(latest.toJson());
    await _pendingStore.clear(_ownerKey);
    _current();
    return confirmed;
  }
}

/// Same store interface used by Profile and Checkout. It never substitutes the
/// Cart's composite local snapshot for an account-owned server Profile.
class AccountProfileInvoiceStore implements BuyV2GstInvoiceProfileStore {
  AccountProfileInvoiceStore(this.gateway);
  final AccountProfileGateway gateway;
  @override
  String? get ownerScope => gateway.ownerScope;
  @override
  Future<BuyV2GstInvoiceProfileSnapshot?> read() async {
    final value = await gateway.read();
    return BuyV2GstInvoiceProfileSnapshot(
      profiles: value.invoiceProfiles
          .map(
            (a) => BuyV2GstInvoiceProfileRecord(
              id: a['id'] as String,
              legalName: a['legalName'] as String,
              gstin: a['gstin'] as String,
              billingAddress: a['billingAddress'] as String,
              registration: BuyV2BusinessInvoiceRegistration.values.byName(
                a['registration'] as String,
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<bool> write(BuyV2GstInvoiceProfileSnapshot snapshot) async {
    final change = _change({
      'kind': 'invoices',
      'invoiceProfiles': snapshot.profiles
          .map(
            (a) => {
              'id': a.id,
              'legalName': a.legalName,
              'gstin': a.gstin,
              'billingAddress': a.billingAddress,
              'registration': a.registration.name,
            },
          )
          .toList(),
    });
    if (gateway.snapshot == null) await gateway.read();
    final saved = await gateway.save(change);
    return gateway.isCurrent() &&
        jsonEncode(saved.invoiceProfiles) ==
            jsonEncode(change['invoiceProfiles']);
  }
}
