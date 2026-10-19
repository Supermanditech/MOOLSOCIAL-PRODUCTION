import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// Frontend integration proposal, not an implemented backend API. Adapters must
/// return only the receiving Store's authorized projection, never buyer targets
/// containing the full mixed-order Store map or private contact/payment data.
enum StoreFeedbackKind { overallOrder, storeService, product }

enum StoreFeedbackCoverage { unavailable, complete, partial }

enum StoreFeedbackAction { reply, report }

enum StoreFeedbackAudience {
  public,
  orderParticipants,
  storeAndCustomer,
  moderation,
}

enum StoreFeedbackOutcome { accepted, rejected, unknown }

typedef StoreFeedbackScope = ({String account, String store});
typedef StoreFeedbackBinding = ({
  Object context,
  int readEpoch,
  String reviewId,
  String version,
});

class StoreFeedbackEntry {
  StoreFeedbackEntry({
    required this.storeId,
    required this.id,
    required this.version,
    required this.kind,
    required this.authorLabel,
    required this.text,
    this.stars,
    this.orderId,
    this.productId,
    this.productLabel,
    this.mixedOrder = false,
    this.ownerReply,
    Set<StoreFeedbackAudience> replyAudiences = const {},
    this.canReport = false,
  }) : replyAudiences = Set.unmodifiable(replyAudiences);

  final String storeId, id, version, authorLabel, text;
  final StoreFeedbackKind kind;
  final int? stars;
  // Only this Store's validated suborder/product references, not the complete
  // buyer purchase map. Absence must not be repaired by matching display text.
  final String? orderId, productId, productLabel, ownerReply;
  final bool mixedOrder, canReport;
  final Set<StoreFeedbackAudience> replyAudiences;

  bool validFor(StoreFeedbackScope scope) =>
      storeId == scope.store &&
      id.trim().isNotEmpty &&
      version.trim().isNotEmpty &&
      authorLabel.trim().isNotEmpty &&
      authorLabel.length <= 200 &&
      text.length <= 10000 &&
      (stars == null || (stars! >= 1 && stars! <= 5)) &&
      (text.trim().isNotEmpty || stars != null) &&
      (orderId == null || orderId!.trim().isNotEmpty) &&
      (kind == StoreFeedbackKind.product
          ? productId?.trim().isNotEmpty == true &&
                productLabel?.trim().isNotEmpty == true
          : productId == null && productLabel == null) &&
      (!mixedOrder || kind == StoreFeedbackKind.overallOrder) &&
      !replyAudiences.contains(StoreFeedbackAudience.moderation);
}

class StoreFeedbackPage {
  StoreFeedbackPage({
    required this.scope,
    required this.coverage,
    List<StoreFeedbackEntry> entries = const [],
    this.nextCursor,
  }) : entries = List.unmodifiable(entries);
  final StoreFeedbackScope scope;
  final StoreFeedbackCoverage coverage;
  final List<StoreFeedbackEntry> entries;
  final String? nextCursor;
}

class StoreFeedbackCommand {
  const StoreFeedbackCommand({
    required this.scope,
    required this.reviewId,
    required this.version,
    required this.operationId,
    required this.action,
    required this.audience,
    required this.content,
  });
  final StoreFeedbackScope scope;
  final String reviewId, version, operationId, content;
  final StoreFeedbackAction action;
  final StoreFeedbackAudience audience;

  bool get valid =>
      [scope.account, scope.store, reviewId, version, operationId].every(
        (s) => s.trim().isNotEmpty && s.length <= 512) &&
      content.trim().isNotEmpty && content == content.trim() &&
      content.length <= 2000 &&
      (action == StoreFeedbackAction.report
          ? audience == StoreFeedbackAudience.moderation
          : audience != StoreFeedbackAudience.moderation);

  Map<String, Object?> toJson() => {
    'account': scope.account, 'store': scope.store, 'reviewId': reviewId,
    'version': version, 'operationId': operationId, 'action': action.name,
    'audience': audience.name, 'content': content,
  };

  static StoreFeedbackCommand fromJson(Object? value) {
    const keys = {'account', 'store', 'reviewId', 'version', 'operationId',
      'action', 'audience', 'content'};
    if (value is! Map || value.length != keys.length ||
        !keys.every((k) => value[k] is String)) {
      throw const FormatException('Invalid feedback request');
    }
    final command = StoreFeedbackCommand(
      scope: (account: value['account'] as String, store: value['store'] as String),
      reviewId: value['reviewId'] as String, version: value['version'] as String,
      operationId: value['operationId'] as String,
      action: StoreFeedbackAction.values.byName(value['action'] as String),
      audience: StoreFeedbackAudience.values.byName(value['audience'] as String),
      content: value['content'] as String,
    );
    if (!command.valid) throw const FormatException('Invalid feedback request');
    return command;
  }
}

class StoreFeedbackResult {
  const StoreFeedbackResult({required this.command, required this.outcome});
  final StoreFeedbackCommand command;
  final StoreFeedbackOutcome outcome;

  bool matches(StoreFeedbackCommand original) =>
      command.scope == original.scope &&
      command.reviewId == original.reviewId &&
      command.version == original.version &&
      command.operationId == original.operationId &&
      command.action == original.action &&
      command.audience == original.audience &&
      command.content == original.content;
}

abstract interface class StoreFeedbackAdapter {
  /// May be true only after the real adapter's authorization and durable command
  /// reconciliation are qualified. A device intent journal does not grant
  /// provider authorization or prove that a server request was accepted.
  bool get commandRecoveryReady;
  Future<StoreFeedbackPage> load(StoreFeedbackScope scope, {String? cursor});
  Future<StoreFeedbackResult> submit(StoreFeedbackCommand command);
  Future<StoreFeedbackResult> reconcile(StoreFeedbackCommand original);
}

/// The MVP connection is private product stars, not public written reviews.
/// Legacy adapters/journals retain their existing capabilities and data.
abstract interface class StoreStarsOnlyFeedbackAdapter implements StoreFeedbackAdapter {}

/// One unresolved original request per authenticated account/Store. Production
/// implementations must serialize reads/writes/removals across instances.
abstract interface class StoreFeedbackPendingStore {
  Future<StoreFeedbackCommand?> readPending(StoreFeedbackScope scope);
  Future<void> savePending(StoreFeedbackCommand command);
  Future<void> removePending(StoreFeedbackCommand original);
}

/// Session-owned per-account/Store presentation state. No local review database,
/// optimistic rating edits, report hiding or provider-success fallback.
class StoreFeedbackController extends ChangeNotifier {
  StoreFeedbackController({
    required this.scope,
    required this.context,
    this.adapter,
    this.pendingStore,
  }) : _restored = pendingStore == null;
  final StoreFeedbackScope scope;
  final Object? Function() context;
  final StoreFeedbackAdapter? adapter;
  bool get starsOnly => adapter is StoreStarsOnlyFeedbackAdapter;
  // Optional only for isolated session fixtures. WorkSession supplies its secure
  // implementation; absence must never be claimed as restart qualification.
  final StoreFeedbackPendingStore? pendingStore;
  bool _restored;
  Future<bool>? _restoring;
  final Map<String, StoreFeedbackEntry> _entries = {};
  final Map<(String, StoreFeedbackAction), String> _drafts = {};
  final Set<String> _consumedCursors = {};
  Object? _pageContext;
  bool _disposed = false, loading = false, _commandInFlight = false;
  int _readEpoch = 0;
  StoreFeedbackCoverage coverage = StoreFeedbackCoverage.unavailable;
  String? nextCursor, message;
  StoreFeedbackCommand? _pending;

  List<StoreFeedbackEntry> get entries => List.unmodifiable(_entries.values);
  StoreFeedbackCommand? get pending => _pending;
  bool get commandInFlight => _commandInFlight;
  bool get recoveryReady => _restored;
  bool get actionsReady =>
      !_disposed &&
      context() != null &&
      context() == _pageContext &&
      !loading &&
      recoveryReady && !_commandInFlight &&
      _pending == null &&
      adapter?.commandRecoveryReady == true;
  bool get current =>
      !_disposed && context() != null && context() == _pageContext;
  String draft(String id, StoreFeedbackAction action) =>
      _drafts[(id, action)] ?? '';
  StoreFeedbackBinding? bindingFor(String id) {
    final entry = _entries[id];
    return current && !loading && entry != null
        ? (
            context: _pageContext!,
            readEpoch: _readEpoch,
            reviewId: id,
            version: entry.version,
          )
        : null;
  }

  void setDraft(
    StoreFeedbackBinding binding,
    StoreFeedbackAction action,
    String value,
  ) {
    if (bindingFor(binding.reviewId) == binding) {
      _drafts[(binding.reviewId, action)] = value;
    }
  }

  bool canAct(String id, StoreFeedbackAction action) {
    final entry = _entries[id];
    return actionsReady &&
        entry != null &&
        (action == StoreFeedbackAction.report
            ? entry.canReport
            : entry.replyAudiences.isNotEmpty);
  }

  String? orderForReview(StoreFeedbackBinding binding) {
    return bindingFor(binding.reviewId) == binding
        ? _entries[binding.reviewId]?.orderId
        : null;
  }

  Future<void> load({bool more = false}) async {
    if (_disposed || loading) return;
    final origin = context();
    if (origin == null) return;
    final restored = await restorePending();
    // Private ratings are read-only. An unavailable legacy command journal
    // must still block actions, but cannot grant or deny the feed's own auth.
    final readOnlyStars = starsOnly && adapter?.commandRecoveryReady == false;
    if ((!restored && !readOnlyStars) || !_matches(origin) || loading) return;
    final cursor = more ? nextCursor : null;
    if (more && (cursor == null || _pageContext != origin)) return;
    final epoch = ++_readEpoch;
    if (!more) {
      _entries.clear();
      _consumedCursors.clear();
      nextCursor = null;
      coverage = StoreFeedbackCoverage.unavailable;
    }
    _pageContext = origin;
    message = restored ? null : 'Saved requests could not be checked. No changes can be sent.';
    if (adapter == null) {
      notifyListeners();
      return;
    }
    loading = true;
    try {
      notifyListeners();
      if (!_matches(origin) || epoch != _readEpoch) return;
      final page = await adapter!
          .load(scope, cursor: cursor)
          .timeout(const Duration(seconds: 20));
      if (!_matches(origin) || epoch != _readEpoch) return;
      if (page.scope != scope ||
          page.entries.any((e) => !e.validFor(scope)) ||
          (page.coverage == StoreFeedbackCoverage.unavailable &&
              (page.entries.isNotEmpty || page.nextCursor != null)) ||
          (page.nextCursor != null &&
              (page.nextCursor!.trim().isEmpty ||
                  page.nextCursor == cursor ||
                  _consumedCursors.contains(page.nextCursor)))) {
        throw const FormatException('Unusable feedback page');
      }
      final merged = more
          ? Map<String, StoreFeedbackEntry>.of(_entries)
          : <String, StoreFeedbackEntry>{};
      for (final entry in page.entries) {
        final previous = merged[entry.id];
        // Versions are opaque. A later page cannot establish which is newer.
        if (previous != null && previous.version != entry.version) {
          throw const FormatException('Conflicting feedback versions');
        }
        merged.putIfAbsent(entry.id, () => entry);
      }
      _entries
        ..clear()
        ..addAll(merged);
      if (cursor != null) _consumedCursors.add(cursor);
      nextCursor = page.nextCursor;
      coverage = page.coverage;
    } catch (_) {
      if (_matches(origin) && epoch == _readEpoch) {
        message = 'Could not refresh feedback. Please try again.';
        _pageContext =
            null; // Do not act on stale entries after failed refresh.
        nextCursor = null;
      }
    } finally {
      if (!_disposed && epoch == _readEpoch) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> restorePending() {
    if (_disposed || context() == null) return Future.value(false);
    if (_restored) return Future.value(true);
    final existing = _restoring;
    if (existing != null) return existing;
    final origin = context()!;
    final restoring = _restorePending(origin);
    _restoring = restoring;
    return restoring.whenComplete(() {
      if (identical(_restoring, restoring)) _restoring = null;
    });
  }

  Future<bool> _restorePending(Object origin) async {
    // Publish single-flight state before a synchronous fixture can complete.
    await Future<void>.value();
    if (!_matches(origin)) return false;
    try {
      final saved = await pendingStore!.readPending(scope)
          .timeout(const Duration(seconds: 20));
      if (!_matches(origin)) return false;
      if (saved != null && (!saved.valid || saved.scope != scope)) {
        throw const FormatException('Wrong feedback request owner');
      }
      _pending = saved;
      _restored = true;
      message = saved == null ? null
          : 'A saved request needs confirmation. Check it before sending another.';
      notifyListeners();
      return true;
    } catch (_) {
      if (_matches(origin)) {
        message = 'Could not restore saved requests. Refresh before sending.';
        notifyListeners();
      }
      return false;
    }
  }

  Future<void> submit(
    StoreFeedbackBinding binding,
    StoreFeedbackAction action,
    StoreFeedbackAudience audience,
  ) async {
    final id = binding.reviewId;
    if (bindingFor(id) != binding || !canAct(id, action)) return;
    final entry = _entries[id]!;
    final content = draft(id, action).trim();
    if (content.isEmpty ||
        content.length > 2000 ||
        (action == StoreFeedbackAction.reply
            ? !entry.replyAudiences.contains(audience)
            : audience != StoreFeedbackAudience.moderation)) {
      return;
    }
    final random = Random.secure();
    final operationId = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final command = StoreFeedbackCommand(
      scope: scope,
      reviewId: id,
      version: entry.version,
      operationId: operationId,
      action: action,
      audience: audience,
      content: content,
    );
    _pending = command; // Before calling the adapter, never after the await.
    await _execute(command, reconcile: false);
  }

  Future<void> reconcile() async {
    final command = _pending;
    if (_disposed ||
        context() == null ||
        command == null ||
        !recoveryReady ||
        _commandInFlight ||
        adapter?.commandRecoveryReady != true) {
      return;
    }
    await _execute(command, reconcile: true);
  }

  bool _matches(Object origin) => !_disposed && context() == origin;

  Future<void> _execute(
    StoreFeedbackCommand command, {
    required bool reconcile,
  }) async {
    final origin = context();
    if (origin == null || _commandInFlight) return;
    _commandInFlight = true;
    message = null;
    try {
      notifyListeners();
      if (!_matches(origin)) {
        // No external call was made. Do not create an unknown result for an
        // undispatched submission; an existing reconciliation hold stays held.
        if (!_disposed && !reconcile && identical(_pending, command)) {
          _pending = null;
        }
        return;
      }
      if (!reconcile && pendingStore != null) {
        try {
          await pendingStore!.savePending(command)
              .timeout(const Duration(seconds: 20));
        } catch (_) {
          if (_matches(origin)) {
            // A native write may still finish after timeout. Restore is queued
            // behind it; never dispatch or erase uncertain journal bytes.
            _restored = false;
            message = 'Could not safely save this request. It was not sent. Refresh to recover.';
          }
          return;
        }
        if (!_matches(origin)) return;
      }
      if (adapter?.commandRecoveryReady != true) {
        message = 'Request checking is unavailable. The original request is kept; do not send it again.';
        return;
      }
      final result =
          await (reconcile
                  ? adapter!.reconcile(command)
                  : adapter!.submit(command))
              .timeout(const Duration(seconds: 20));
      if (!_matches(origin)) return;
      if (!result.matches(command) ||
          result.outcome == StoreFeedbackOutcome.unknown) {
        message =
            'Result not confirmed. Check the original request before trying again.';
        return;
      }
      if (pendingStore != null) {
        try {
          await pendingStore!.removePending(command)
              .timeout(const Duration(seconds: 20));
        } catch (_) {
          if (_matches(origin)) {
            message = 'Could not finish saving the result. Check the original request again.';
          }
          return;
        }
        if (!_matches(origin)) return;
      }
      _pending = null;
      if (result.outcome == StoreFeedbackOutcome.accepted) {
        // Do not erase newer typing or modify the customer's review locally.
        if (draft(command.reviewId, command.action).trim() == command.content) {
          _drafts.remove((command.reviewId, command.action));
        }
        message = command.action == StoreFeedbackAction.reply
            ? 'Reply confirmed. Refresh to see the latest feedback.'
            : 'Report received for review. The customer feedback remains visible.';
        _pageContext = null;
      } else {
        message =
            'Request was not accepted. Your text is kept; refresh before retrying.';
        _pageContext = null;
      }
    } catch (_) {
      if (_matches(origin)) {
        message =
            'Result not confirmed. Check the original request before trying again.';
      }
    } finally {
      if (!_disposed) {
        _commandInFlight = false;
        // A changed account/Store must never consume the old acknowledgement.
        // Its original command remains held for this scoped controller.
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_readEpoch;
    super.dispose();
  }
}
