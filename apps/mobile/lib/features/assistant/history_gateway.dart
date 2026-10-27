import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../journey01/account_profile_gateway.dart' show AccountProfileOwner;
import '../shared/social_content_gateway.dart';
import 'mool_assistant.dart';
import 'preparation_pending_store.dart';

class AssistantHistoryFailure implements Exception {
  const AssistantHistoryFailure(this.code);
  final String code;
}
abstract interface class AssistantHistoryGatewaySource {
  AssistantHistoryGateway? assistantHistoryGateway(AccountProfileOwner owner, bool Function() current);
}
typedef _Scope = ({String audience, String? storeId});
const _languages = {'Auto', 'English', 'हिन्दी', 'मराठी', 'தமிழ்', 'اردو', 'ಕನ್ನಡ'};
const _limit = 2 * 1024 * 1024;

/// The source factory never injects authority or a runtime fixture. The journal
/// contains opaque original-save metadata only; transcripts remain server-owned.
class AssistantHistoryGateway implements MoolAssistantConversationHistorySource {
  AssistantHistoryGateway({required this.owner, required this.isCurrent,
    required SocialContentCredentials credentials, SocialContentTransport? transport,
    AssistantPreparationPendingStore? journal})
      : _credentials = credentials, _journal = journal ?? SecureAssistantPreparationPendingStore(),
        _transport = transport ?? IoSocialContentTransport(followRedirects: false, maximumResponseBytes: _limit + 65536) {
    if (owner.tenantId != null || owner.userId.isEmpty || !RegExp(r'^[a-z][a-z0-9-]{4,62}$').hasMatch(owner.projectId)) {
      throw const MoolAssistantHistoryAccessFailure();
    }
  }
  final AccountProfileOwner owner;
  final bool Function() isCurrent;
  final SocialContentCredentials _credentials;
  final SocialContentTransport _transport;
  final AssistantPreparationPendingStore _journal;
  bool _disposed = false, _denied = false;
  static final Map<String, Future<void>> _tails = {};
  bool get available => !_disposed && !_denied && isCurrent();
  void dispose() {_disposed = true;}
  void _check(MoolAssistantContext c) {
    if (!available || !c.signedIn || c.accountScope != owner ||
        c.workspaceId != null && !c.inWorkspace || c.inWorkspace && !c.storeWorkspace) {
      throw const MoolAssistantHistoryAccessFailure();
    }
  }
  _Scope _scope(MoolAssistantContext c) {
    _check(c);
    return (audience: c.inWorkspace ? 'workspace' : 'personal', storeId: c.inWorkspace ? c.workspaceId : null);
  }
  Map<String, Object?> _scopeJson(_Scope s) => {'audience': s.audience, 'storeId': s.storeId};
  String _hash(Object value) => sha256.convert(utf8.encode(jsonEncode(value))).toString();
  String _ownerKey(_Scope s) => _hash([owner.projectId, owner.userId, s.audience, s.storeId]);
  String _journalKey(_Scope s) => _hash(['assistant.history.v1', owner.environment, owner.projectId, owner.tenantId, owner.userId, s.audience, s.storeId]);
  Future<T> _lock<T>(_Scope s, Future<T> Function() action) async {
    final key = _journalKey(s), previous = _tails[_journalKey(s)], done = Completer<void>();
    _tails[key] = done.future;
    try {await previous; return await action();}
    finally {done.complete(); if (identical(_tails[key], done.future)) _tails.remove(key);}
  }
  Map<String, Object?> _map(Object? raw, [Set<String>? keys]) {
    if (raw is! Map || raw.keys.any((k) => k is! String)) throw const AssistantHistoryFailure('invalid_response');
    final p = Map<String, Object?>.from(raw);
    if (keys != null && (p.length != keys.length || !p.keys.every(keys.contains))) throw const AssistantHistoryFailure('invalid_response');
    return p;
  }
  String _id(Object? raw) {
    if (raw is! String || raw.length > 128 || !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]*$').hasMatch(raw)) throw const AssistantHistoryFailure('invalid_response');
    return raw;
  }
  String _text(Object? raw, int max) {
    if (raw is! String || raw.length > max || RegExp(r'[\u0000-\u0008\u000b\u000c\u000e-\u001f]').hasMatch(raw)) throw const AssistantHistoryFailure('invalid_response');
    if (utf8.decode(utf8.encode(raw)) != raw) throw const AssistantHistoryFailure('invalid_response');
    return raw;
  }
  DateTime _date(Object? raw) {
    final value = _text(raw, 40), date = DateTime.tryParse(value);
    if (date == null || !date.isUtc || date.toIso8601String() != value) throw const AssistantHistoryFailure('invalid_response');
    return date;
  }
  Future<Map<String, Object?>> _post(MoolAssistantContext c, String operation, Map<String, Object?> payload) async {
    final scope = _scope(c);
    final token = await _credentials.firebaseIdToken(); _check(c);
    final proof = await _credentials.appCheckToken(operation == 'save' ? SocialAppCheckTokenMode.limitedUse : SocialAppCheckTokenMode.standard);
    _check(c);
    if (token.trim().isEmpty || proof.trim().isEmpty) throw const MoolAssistantHistoryAccessFailure();
    final response = await _transport.postJson(Uri.https('asia-south1-' + owner.projectId + '.cloudfunctions.net', '/moolSocialAssistantHistory'),
      headers: {'Authorization': 'Bearer ' + token, 'X-Firebase-AppCheck': proof},
      body: {'operation': operation, 'payload': payload});
    _check(c);
    if (utf8.encode(response.body).length > _limit + 65536) throw const AssistantHistoryFailure('invalid_response');
    if (response.statusCode == 401 || response.statusCode == 403) {
      // No private snapshot is cached here. A later explicit read must be able
      // to revalidate refreshed credentials/paid access with the original source.
      throw const MoolAssistantHistoryAccessFailure();
    }
    final envelope = _map(jsonDecode(response.body));
    if (response.statusCode != 200 || envelope['ok'] != true) {
      String code = 'history_unavailable';
      try {
        final error = _map(envelope['error']);
        if ({'history_request_not_found', 'history_not_found', 'history_request_conflict', 'history_access_changed',
          'history_too_large', 'invalid_history_cursor'}.contains(error['code'])) code = error['code'] as String;
      } on Object {/* Do not expose provider text. */}
      throw AssistantHistoryFailure(code);
    }
    final data = _map(envelope['data']), responseScope = _map(data['scope'], {'audience', 'storeId'});
    if (data['ownerKey'] != _ownerKey(scope) || responseScope['audience'] != scope.audience || responseScope['storeId'] != scope.storeId) {
      _denied = true; throw const MoolAssistantHistoryAccessFailure();
    }
    return data;
  }
  MoolAssistantConversation _conversation(MoolAssistantContext c, Object? raw, {bool summary = false}) {
    final p = _map(raw, summary ? {'id', 'revision', 'title', 'updatedAt'} : {'id', 'revision', 'title', 'updatedAt', 'draft', 'language', 'messages'});
    if (p['revision'] is! int || (p['revision'] as int) < 1 || (p['revision'] as int) > 9007199254740991) throw const AssistantHistoryFailure('invalid_response');
    final messages = <(bool, String)>[];
    if (!summary) {
      if (p['messages'] is! List || (p['messages'] as List).length > 500 || !_languages.contains(p['language'])) throw const AssistantHistoryFailure('invalid_response');
      for (final value in p['messages'] as List) {
        final m = _map(value, {'role', 'text'});
        if (m['role'] != 'user' && m['role'] != 'assistant') throw const AssistantHistoryFailure('invalid_response');
        messages.add((m['role'] == 'user', _text(m['text'], 32000)));
      }
    }
    final title = _text(p['title'], 100);
    if (title.trim().isEmpty) throw const AssistantHistoryFailure('invalid_response');
    return MoolAssistantConversation(id: _id(p['id']), binding: c.binding, revision: p['revision'] as int,
      title: title, updatedAt: _date(p['updatedAt']), draft: summary ? '' : _text(p['draft'], 32000),
      language: summary ? 'Auto' : p['language'] as String, messages: messages);
  }
  @override Future<MoolAssistantHistoryPage> list(MoolAssistantContext c, {String? cursor}) async {
    final s = _scope(c);
    final p = await _post(c, 'list', {'scope': _scopeJson(s), 'cursor': cursor});
    _map(p, {'ownerKey', 'scope', 'items', 'nextCursor'});
    if (p.keys.toSet().difference({'ownerKey', 'scope', 'items', 'nextCursor'}).isNotEmpty ||
        p['items'] is! List || (p['items'] as List).length > 20 ||
        p['nextCursor'] != null && (p['nextCursor'] is! String || (p['nextCursor'] as String).isEmpty || (p['nextCursor'] as String).length > 2048)) {
      throw const AssistantHistoryFailure('invalid_response');
    }
    final items = (p['items'] as List).map((v) => _conversation(c, v, summary: true)).toList();
    if (items.map((v) => v.id).toSet().length != items.length || p['nextCursor'] != null && p['nextCursor'] == cursor) throw const AssistantHistoryFailure('invalid_response');
    return MoolAssistantHistoryPage(binding: c.binding, items: items, nextCursor: p['nextCursor'] as String?);
  }
  @override Future<MoolAssistantConversation> read(MoolAssistantContext c, String id) async {
    final s = _scope(c); _id(id);
    final p = await _post(c, 'read', {'scope': _scopeJson(s), 'id': id});
    _map(p, {'ownerKey', 'scope', 'conversation'});
    if (p.keys.toSet().difference({'ownerKey', 'scope', 'conversation'}).isNotEmpty) throw const AssistantHistoryFailure('invalid_response');
    final result = _conversation(c, p['conversation']);
    if (result.id != id) throw const AssistantHistoryFailure('invalid_response');
    return result;
  }
  Future<Map<String, Object?>?> _pending(MoolAssistantContext c, _Scope s) async {
    final raw = await _journal.read(_journalKey(s)); _check(c);
    if (raw == null) return null;
    if (raw.length > 2048) throw const AssistantHistoryFailure('history_recovery_unavailable');
    final p = _map(jsonDecode(raw), {'schemaVersion', 'ownerKey', 'requestId', 'payloadHash', 'inputHash', 'editorHash', 'conversationId', 'expectedRevision'});
    if (p['schemaVersion'] != 1 || p['ownerKey'] != _ownerKey(s) ||
        p['payloadHash'] is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(p['payloadHash'] as String) ||
        p['inputHash'] is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(p['inputHash'] as String) ||
        p['editorHash'] is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(p['editorHash'] as String) ||
        p['expectedRevision'] is! int || (p['expectedRevision'] as int) < 0 ||
        (p['conversationId'] == null) != (p['expectedRevision'] == 0)) throw const AssistantHistoryFailure('history_recovery_unavailable');
    if (p['conversationId'] != null) _id(p['conversationId']);
    _id(p['requestId']); return p;
  }
  @override Future<MoolAssistantConversation> saveDraft(MoolAssistantContext c, {required String draftKey,
    String? conversationId, required String text, required String language, required List<MoolAssistantAttachment> attachments}) {
    if (conversationId != null) throw const AssistantHistoryFailure('history_revision_required');
    return saveConversation(c, draftKey: draftKey, editorKey: draftKey, expectedRevision: 0,
      text: text, language: language, attachments: attachments, messages: const []);
  }
  @override Future<MoolAssistantConversation> saveConversation(MoolAssistantContext c, {required String draftKey,
    required String editorKey, String? conversationId, required int expectedRevision, required String text,
    required String language, required List<(bool, String)> messages, required List<MoolAssistantAttachment> attachments}) async {
    final s = _scope(c);
    // Private media requires its original upload/read authority. Never persist
    // device paths or silently discard attachments to make New chat succeed.
    if (attachments.isNotEmpty) throw const AssistantHistoryFailure('history_media_unavailable');
    if (draftKey.isEmpty || editorKey.isEmpty || editorKey.length > 256 || expectedRevision < 0 ||
        (conversationId == null) != (expectedRevision == 0) || !_languages.contains(language) || messages.length > 500) throw const AssistantHistoryFailure('invalid_request');
    _text(text, 32000); if (conversationId != null) _id(conversationId);
    final transcript = messages.map((v) => {'role': v.$1 ? 'user' : 'assistant', 'text': _text(v.$2, 32000)}).toList(growable: false);
    if (text.trim().isEmpty && transcript.isEmpty) throw const AssistantHistoryFailure('empty_history');
    final input = <String, Object?>{'scope': _scopeJson(s), 'clientKey': editorKey, 'conversationId': conversationId,
      'expectedRevision': expectedRevision, 'draft': text, 'language': language, 'messages': transcript};
    if (utf8.encode(jsonEncode(input)).length > _limit) throw const AssistantHistoryFailure('history_too_large');
    return _lock(s, () async {
      _check(c);
      var candidate = Map<String, Object?>.of(input), hash = _hash(input);
      final inputHash = hash;
      final editorHash = _hash(editorKey);
      var previous = await _pending(c, s);
      if (previous != null) {
        Map<String, Object?>? original;
        try {original = await _post(c, 'status', {'scope': _scopeJson(s), 'requestId': previous['requestId']});}
        on AssistantHistoryFailure catch (e) {
          if (e.code != 'history_request_not_found') rethrow;
        }
        if (original != null) _receipt(original);
        if (original?['state'] == 'confirmed') {
          final saved = _conversation(c, original!['conversation']);
          if (previous['inputHash'] == inputHash) {
            final originalInput = {...input, 'conversationId': previous['conversationId'], 'expectedRevision': previous['expectedRevision']};
            if (_hash(originalInput) != previous['payloadHash']) throw const AssistantHistoryFailure('history_recovery_unavailable');
            return _ack(saved, originalInput);
          }
          // Recover only this editor's known accepted effect, never a newly read
          // server revision that could overwrite another editor's changes.
          if (previous['editorHash'] == editorHash &&
              (conversationId == null || conversationId == saved.id)) {
            candidate['conversationId'] = saved.id; candidate['expectedRevision'] = saved.revision; hash = _hash(candidate);
          }
        } else if (original?['state'] == 'pending') {
          if (previous['inputHash'] != inputHash) throw const AssistantHistoryFailure('original_history_pending');
          final originalInput = {...input, 'conversationId': previous['conversationId'], 'expectedRevision': previous['expectedRevision']};
          if (_hash(originalInput) != previous['payloadHash']) throw const AssistantHistoryFailure('history_recovery_unavailable');
          return _sendOriginal(c, s, originalInput, previous['requestId'] as String);
        } else if (original != null && original['state'] != 'conflict') {
          throw const AssistantHistoryFailure('invalid_response');
        } else if (original?['state'] == 'conflict') {
          // A stale editor must re-open the original record, not rebase itself.
          await _journal.clear(_journalKey(s)); _check(c);
          throw const AssistantHistoryFailure('history_conflict');
        }
        await _journal.clear(_journalKey(s)); _check(c); previous = null;
      }
      final random = Random.secure();
      final requestId = 'hs-' + List.generate(24, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await _journal.write(_journalKey(s), jsonEncode({'schemaVersion': 1, 'ownerKey': _ownerKey(s),
        'requestId': requestId, 'payloadHash': hash, 'inputHash': inputHash, 'editorHash': editorHash,
        'conversationId': candidate['conversationId'], 'expectedRevision': candidate['expectedRevision']}));
      _check(c);
      return _sendOriginal(c, s, candidate, requestId);
    });
  }
  MoolAssistantConversation _ack(MoolAssistantConversation saved, Map<String, Object?> input) {
    final messages = input['messages'] as List<Map<String, String>>;
    if (saved.draft != input['draft'] || saved.language != input['language'] ||
        input['conversationId'] != null && saved.id != input['conversationId'] ||
        saved.revision != (input['expectedRevision'] as int) + 1 ||
        !listEquals(saved.messages, messages.map((v) => (v['role'] == 'user', v['text']!)).toList())) throw const AssistantHistoryFailure('history_acknowledgement_unknown');
    return saved;
  }
  void _receipt(Map<String, Object?> p) {
    if (!{'pending', 'conflict', 'confirmed'}.contains(p['state'])) throw const AssistantHistoryFailure('invalid_response');
    _map(p, p['state'] == 'confirmed' ? {'ownerKey', 'scope', 'state', 'conversation'} : {'ownerKey', 'scope', 'state'});
  }
  Future<MoolAssistantConversation> _sendOriginal(MoolAssistantContext c, _Scope s, Map<String, Object?> candidate, String requestId) async {
    final response = await _post(c, 'save', {...candidate, 'scope': _scopeJson(s), 'requestId': requestId});
    _receipt(response);
    if (response['state'] == 'conflict') throw const AssistantHistoryFailure('history_conflict');
    if (response['state'] != 'confirmed') throw const AssistantHistoryFailure('history_outcome_unknown');
    return _ack(_conversation(c, response['conversation']), candidate);
  }
}
