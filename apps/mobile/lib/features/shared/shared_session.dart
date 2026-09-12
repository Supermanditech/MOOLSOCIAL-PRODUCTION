import 'package:flutter/foundation.dart';

import 'shared_models.dart';
import 'shared_services.dart';
import 'social_content_gateway.dart';

class SharedIntentResult {
  const SharedIntentResult({
    required this.title,
    required this.detail,
    required this.action,
    required this.route,
  });

  final String title;
  final String detail;
  final String action;
  final String route;
}

class SharedSession extends ChangeNotifier {
  SharedSession({
    ReviewSharedGateway? gateway,
    SocialContentGateway? socialContentGateway,
  }) : gateway = gateway ?? ReviewSharedGateway(),
       _socialContentGateway =
           socialContentGateway ?? buildSocialContentGateway();

  final ReviewSharedGateway gateway;
  final SocialContentGateway _socialContentGateway;

  bool busy = false;
  bool online = true;
  bool authorized = true;
  bool cameraAllowed = true;
  bool microphoneAllowed = true;
  bool subscriptionActive = false;
  String? errorMessage;
  String? noticeMessage;
  String input = '';
  SharedIntentResult? inputResult;
  String pauseDuration = '1 hour';
  final Map<int, String> filters = <int, String>{};
  final Map<int, String> searches = <int, String>{};
  final Map<String, bool> _controlValues = <String, bool>{};
  final Set<String> _completedActions = <String>{};
  final List<SocialPublishedItem> _socialPublishedItems =
      <SocialPublishedItem>[];
  final Set<String> _socialInteractionsInFlight = <String>{};
  final Map<String, String> _socialInteractionErrors = <String, String>{};
  int _socialPublishSequence = 0;
  String? _pendingSocialPublishFingerprint;
  String? _pendingSocialPublishKey;
  String? _socialFeedCursor;
  bool socialFeedLoading = false;
  bool socialFeedLoaded = false;
  bool socialFeedHasMore = false;
  String? socialFeedError;
  bool _socialFeedFailureWasRefresh = true;
  final Map<String, List<SocialComment>> _socialComments = {};
  final Map<String, String?> _socialCommentCursors = {};
  final Set<String> _socialCommentsLoaded = {};
  final Set<String> _socialCommentsLoading = {};
  final Set<String> _socialRepliesInFlight = {};
  final Map<String, String> _socialCommentErrors = {};
  final Map<String, String> _socialReplyDrafts = {};
  final Map<String, String> _pendingSocialReplyFingerprints = {};
  final Map<String, String> _pendingSocialReplyKeys = {};
  int _socialReplySequence = 0;
  final Map<String, SocialAuthorProfile> _socialAuthorProfiles = {};
  final Set<String> _socialAuthorsLoading = {};
  final Set<String> _socialFollowsInFlight = {};
  final Map<String, String> _socialAuthorErrors = {};
  final Set<String> _socialReportsInFlight = {};
  final Map<String, String> _socialReportErrors = {};
  final Set<String> _reportedSocialPosts = {};
  final Map<String, String> _pendingSocialReportFingerprints = {};
  final Map<String, String> _pendingSocialReportKeys = {};
  int _socialReportSequence = 0;
  final List<SocialPublishedItem> _socialSavedPosts = [];
  String? _socialSavedCursor;
  bool socialSavedLoading = false;
  bool socialSavedLoaded = false;
  bool socialSavedHasMore = false;
  String? socialSavedError;
  final List<SocialNotificationItem> _socialNotifications = [];
  String? _socialNotificationCursor;
  bool socialNotificationsLoading = false;
  bool socialNotificationsLoaded = false;
  bool socialNotificationsHasMore = false;
  String? socialNotificationsError;
  final Set<String> _socialNotificationsReading = {};
  final Set<String> _blockedSocialAuthors = {};
  final Set<String> _socialBlocksInFlight = {};
  final Map<String, String> _socialBlockErrors = {};

  List<SocialPublishedItem> get socialPublishedItems =>
      List<SocialPublishedItem>.unmodifiable(_socialPublishedItems);

  bool get socialContentAvailable =>
      _socialContentGateway is! UnavailableSocialContentGateway;

  SocialCommentGateway? get _socialCommentGateway =>
      _socialContentGateway is SocialCommentGateway
      ? _socialContentGateway as SocialCommentGateway
      : null;

  SocialAuthorGateway? get _socialAuthorGateway =>
      _socialContentGateway is SocialAuthorGateway
      ? _socialContentGateway as SocialAuthorGateway
      : null;

  SocialModerationGateway? get _socialModerationGateway =>
      _socialContentGateway is SocialModerationGateway
      ? _socialContentGateway as SocialModerationGateway
      : null;

  SocialSavedGateway? get _socialSavedGateway =>
      _socialContentGateway is SocialSavedGateway
      ? _socialContentGateway as SocialSavedGateway
      : null;

  SocialNotificationGateway? get _socialNotificationGateway =>
      _socialContentGateway is SocialNotificationGateway
      ? _socialContentGateway as SocialNotificationGateway
      : null;

  bool socialInteractionBusy(String postId) =>
      _socialInteractionsInFlight.contains(postId);

  String? socialInteractionError(String postId) =>
      _socialInteractionErrors[postId];

  List<SocialComment> socialComments(String postId) =>
      List.unmodifiable(_socialComments[postId] ?? const <SocialComment>[]);

  bool socialCommentsLoaded(String postId) =>
      _socialCommentsLoaded.contains(postId);

  bool socialCommentsLoading(String postId) =>
      _socialCommentsLoading.contains(postId);

  bool socialCommentsHasMore(String postId) =>
      _socialCommentCursors[postId] != null;

  bool socialReplyBusy(String postId) =>
      _socialRepliesInFlight.contains(postId);

  String? socialCommentError(String postId) => _socialCommentErrors[postId];

  String socialReplyDraft(String postId) => _socialReplyDrafts[postId] ?? '';

  SocialAuthorProfile? socialAuthorProfile(String authorId) =>
      _socialAuthorProfiles[authorId];

  bool socialAuthorLoading(String authorId) =>
      _socialAuthorsLoading.contains(authorId);

  bool socialFollowBusy(String authorId) =>
      _socialFollowsInFlight.contains(authorId);

  String? socialAuthorError(String authorId) => _socialAuthorErrors[authorId];

  bool socialReportBusy(String postId) =>
      _socialReportsInFlight.contains(postId);

  String? socialReportError(String postId) => _socialReportErrors[postId];

  bool socialPostReported(String postId) =>
      _reportedSocialPosts.contains(postId);

  List<SocialPublishedItem> get socialSavedPosts =>
      List<SocialPublishedItem>.unmodifiable(_socialSavedPosts);

  List<SocialNotificationItem> get socialNotifications =>
      List<SocialNotificationItem>.unmodifiable(_socialNotifications);

  bool socialNotificationReading(String notificationId) =>
      _socialNotificationsReading.contains(notificationId);

  bool socialAuthorBlocked(String authorId) =>
      _blockedSocialAuthors.contains(authorId);

  bool socialBlockBusy(String authorId) =>
      _socialBlocksInFlight.contains(authorId);

  String? socialBlockError(String authorId) => _socialBlockErrors[authorId];

  void saveSocialReplyDraft(String postId, String value) {
    if (value.isEmpty) {
      _socialReplyDrafts.remove(postId);
    } else {
      _socialReplyDrafts[postId] = value;
    }
  }

  SocialPublishedItem? get latestPublishedReel {
    for (final item in _socialPublishedItems) {
      if (item.type == SocialPublishedContentType.reel) return item;
    }
    return null;
  }

  Future<bool> loadSocialFeed({bool refresh = false}) async {
    if (socialFeedLoading) return false;
    if (!online) {
      _socialFeedFailureWasRefresh = refresh;
      socialFeedError =
          'You are offline. Your last loaded Feed is still available.';
      notifyListeners();
      return false;
    }
    socialFeedLoading = true;
    socialFeedError = null;
    notifyListeners();
    try {
      final page = await _socialContentGateway.feed(
        cursor: refresh ? null : _socialFeedCursor,
      );
      if (refresh) _socialPublishedItems.clear();
      for (final item in page.items) {
        _upsertSocialItem(item, append: true);
      }
      _socialFeedCursor = page.nextCursor;
      socialFeedHasMore = page.nextCursor != null;
      socialFeedLoaded = true;
      socialFeedError = null;
      _socialFeedFailureWasRefresh = true;
      return true;
    } on SocialContentGatewayException catch (error) {
      _socialFeedFailureWasRefresh = refresh;
      socialFeedError = error.message;
      return false;
    } on Object {
      _socialFeedFailureWasRefresh = refresh;
      socialFeedError =
          'Feed is unavailable right now. Your last loaded posts remain visible.';
      return false;
    } finally {
      socialFeedLoading = false;
      notifyListeners();
    }
  }

  Future<bool> retrySocialFeed() =>
      loadSocialFeed(refresh: _socialFeedFailureWasRefresh);

  Future<bool> loadSocialComments(String postId, {bool refresh = false}) async {
    if (_socialCommentsLoading.contains(postId)) return false;
    if (!online) {
      _socialCommentErrors[postId] =
          'You are offline. Previously loaded replies remain available.';
      notifyListeners();
      return false;
    }
    final gateway = _socialCommentGateway;
    if (gateway == null) {
      _socialCommentErrors[postId] =
          'Replies are unavailable right now. Try again later.';
      notifyListeners();
      return false;
    }
    _socialCommentsLoading.add(postId);
    _socialCommentErrors.remove(postId);
    notifyListeners();
    try {
      final page = await gateway.comments(
        postId: postId,
        cursor: refresh ? null : _socialCommentCursors[postId],
      );
      final comments = _socialComments.putIfAbsent(
        postId,
        () => <SocialComment>[],
      );
      if (refresh) comments.clear();
      for (final comment in page.items) {
        if (!comments.any((item) => item.id == comment.id)) {
          comments.add(comment);
        }
      }
      _socialCommentCursors[postId] = page.nextCursor;
      _socialCommentsLoaded.add(postId);
      _socialCommentErrors.remove(postId);
      return true;
    } on SocialContentGatewayException catch (error) {
      _socialCommentErrors[postId] = error.message;
      return false;
    } on Object {
      _socialCommentErrors[postId] =
          'Replies could not load. Check your connection and try again.';
      return false;
    } finally {
      _socialCommentsLoading.remove(postId);
      notifyListeners();
    }
  }

  Future<bool> postSocialReply(String postId, String body) async {
    final normalized = body.trim();
    if (normalized.isEmpty) {
      _socialCommentErrors[postId] = 'Write a reply before posting.';
      notifyListeners();
      return false;
    }
    if (normalized.length > 500) {
      _socialCommentErrors[postId] = 'Keep your reply within 500 characters.';
      notifyListeners();
      return false;
    }
    if (_socialRepliesInFlight.contains(postId)) return false;
    if (!online) {
      _socialCommentErrors[postId] =
          'You are offline. Your reply is still here. Reconnect and try again.';
      notifyListeners();
      return false;
    }
    if (!authorized) {
      _socialCommentErrors[postId] = 'Sign in again before posting this reply.';
      notifyListeners();
      return false;
    }
    final gateway = _socialCommentGateway;
    if (gateway == null) {
      _socialCommentErrors[postId] =
          'Replies are unavailable right now. Try again later.';
      notifyListeners();
      return false;
    }
    final fingerprint = '$postId\u001f$normalized';
    if (_pendingSocialReplyFingerprints[postId] != fingerprint ||
        _pendingSocialReplyKeys[postId] == null) {
      _socialReplySequence += 1;
      _pendingSocialReplyFingerprints[postId] = fingerprint;
      _pendingSocialReplyKeys[postId] =
          'social-reply-${DateTime.now().microsecondsSinceEpoch}-$_socialReplySequence';
    }
    _socialRepliesInFlight.add(postId);
    _socialCommentErrors.remove(postId);
    notifyListeners();
    try {
      final result = await gateway.reply(
        SocialReplyDraft(
          postId: postId,
          idempotencyKey: _pendingSocialReplyKeys[postId]!,
          body: normalized,
        ),
      );
      final comments = _socialComments.putIfAbsent(
        postId,
        () => <SocialComment>[],
      );
      comments.removeWhere((item) => item.id == result.comment.id);
      comments.insert(0, result.comment);
      _socialCommentsLoaded.add(postId);
      _upsertSocialItem(result.post);
      _pendingSocialReplyFingerprints.remove(postId);
      _pendingSocialReplyKeys.remove(postId);
      _socialReplyDrafts.remove(postId);
      _socialCommentErrors.remove(postId);
      return true;
    } on SocialContentGatewayException catch (error) {
      _socialCommentErrors[postId] = error.message;
      return false;
    } on Object {
      _socialCommentErrors[postId] =
          'Your reply could not be posted. It is still here. Please try again.';
      return false;
    } finally {
      _socialRepliesInFlight.remove(postId);
      notifyListeners();
    }
  }

  Future<bool> loadSocialAuthor(
    String authorId, {
    bool authenticated = false,
  }) async {
    if (_socialAuthorsLoading.contains(authorId)) return false;
    if (!online) {
      _socialAuthorErrors[authorId] =
          'You are offline. Previously loaded author details remain available.';
      notifyListeners();
      return false;
    }
    final gateway = _socialAuthorGateway;
    if (gateway == null) {
      _socialAuthorErrors[authorId] =
          'This author profile is unavailable right now. Try again later.';
      notifyListeners();
      return false;
    }
    _socialAuthorsLoading.add(authorId);
    _socialAuthorErrors.remove(authorId);
    notifyListeners();
    try {
      final profile = await gateway.author(
        authorId: authorId,
        authenticated: authenticated,
      );
      _socialAuthorProfiles[authorId] = profile;
      _socialAuthorErrors.remove(authorId);
      return true;
    } on SocialContentGatewayException catch (error) {
      _socialAuthorErrors[authorId] = error.message;
      return false;
    } on Object {
      _socialAuthorErrors[authorId] =
          'This author profile could not load. Check your connection and try again.';
      return false;
    } finally {
      _socialAuthorsLoading.remove(authorId);
      notifyListeners();
    }
  }

  Future<bool> setSocialFollow(String authorId, bool followed) async {
    if (_socialFollowsInFlight.contains(authorId)) return false;
    if (!online) {
      _socialAuthorErrors[authorId] =
          'You are offline. Nothing changed. Reconnect and try again.';
      notifyListeners();
      return false;
    }
    if (!authorized) {
      _socialAuthorErrors[authorId] =
          'Sign in again before changing this relationship.';
      notifyListeners();
      return false;
    }
    if (_socialAuthorProfiles[authorId]?.isSelf == true) {
      _socialAuthorErrors[authorId] =
          'You cannot follow your own MoolSocial profile.';
      notifyListeners();
      return false;
    }
    final gateway = _socialAuthorGateway;
    if (gateway == null) {
      _socialAuthorErrors[authorId] =
          'Follow is unavailable right now. Try again later.';
      notifyListeners();
      return false;
    }
    _socialFollowsInFlight.add(authorId);
    _socialAuthorErrors.remove(authorId);
    notifyListeners();
    try {
      final profile = await gateway.follow(
        authorId: authorId,
        followed: followed,
      );
      _socialAuthorProfiles[authorId] = profile;
      _socialAuthorErrors.remove(authorId);
      return true;
    } on SocialContentGatewayException catch (error) {
      _socialAuthorErrors[authorId] = error.message;
      return false;
    } on Object {
      _socialAuthorErrors[authorId] =
          'Follow could not be updated. Nothing changed. Please try again.';
      return false;
    } finally {
      _socialFollowsInFlight.remove(authorId);
      notifyListeners();
    }
  }

  Future<bool> reportSocialPost(
    String postId,
    SocialReportReason reason,
  ) async {
    if (_reportedSocialPosts.contains(postId)) return true;
    if (_socialReportsInFlight.contains(postId)) return false;
    if (!online) {
      _socialReportErrors[postId] =
          'You are offline. The report was not sent. Reconnect and try again.';
      notifyListeners();
      return false;
    }
    if (!authorized) {
      _socialReportErrors[postId] = 'Sign in again before sending this report.';
      notifyListeners();
      return false;
    }
    if (!_socialPublishedItems.any((item) => item.id == postId)) {
      _socialReportErrors[postId] =
          'This post is no longer available. The report was not sent.';
      notifyListeners();
      return false;
    }
    final gateway = _socialModerationGateway;
    if (gateway == null) {
      _socialReportErrors[postId] =
          'Reporting is unavailable right now. Nothing was sent.';
      notifyListeners();
      return false;
    }
    final fingerprint = '$postId\u001f${reason.name}';
    if (_pendingSocialReportFingerprints[postId] != fingerprint ||
        _pendingSocialReportKeys[postId] == null) {
      _socialReportSequence += 1;
      _pendingSocialReportFingerprints[postId] = fingerprint;
      _pendingSocialReportKeys[postId] =
          'social-report-${DateTime.now().microsecondsSinceEpoch}-$_socialReportSequence';
    }
    _socialReportsInFlight.add(postId);
    _socialReportErrors.remove(postId);
    notifyListeners();
    try {
      await gateway.reportPost(
        postId: postId,
        reason: reason,
        idempotencyKey: _pendingSocialReportKeys[postId]!,
      );
      _reportedSocialPosts.add(postId);
      _pendingSocialReportFingerprints.remove(postId);
      _pendingSocialReportKeys.remove(postId);
      _socialReportErrors.remove(postId);
      return true;
    } on SocialContentGatewayException catch (error) {
      _socialReportErrors[postId] = error.message;
      return false;
    } on Object {
      _socialReportErrors[postId] =
          'The report could not be sent. Nothing changed. Please try again.';
      return false;
    } finally {
      _socialReportsInFlight.remove(postId);
      notifyListeners();
    }
  }

  Future<bool> loadSavedSocialPosts({bool refresh = false}) async {
    if (socialSavedLoading) return false;
    if (!online) {
      socialSavedError =
          'You are offline. Previously loaded saved posts remain available.';
      notifyListeners();
      return false;
    }
    if (!authorized) {
      socialSavedError = 'Sign in again to view your saved posts.';
      notifyListeners();
      return false;
    }
    final gateway = _socialSavedGateway;
    if (gateway == null) {
      socialSavedError =
          'Saved posts are unavailable right now. Try again later.';
      notifyListeners();
      return false;
    }
    socialSavedLoading = true;
    socialSavedError = null;
    notifyListeners();
    try {
      final page = await gateway.saved(
        cursor: refresh ? null : _socialSavedCursor,
      );
      if (refresh) _socialSavedPosts.clear();
      for (final item in page.items) {
        _upsertSavedSocialItem(item);
      }
      _socialSavedCursor = page.nextCursor;
      socialSavedHasMore = page.nextCursor != null;
      socialSavedLoaded = true;
      socialSavedError = null;
      return true;
    } on SocialContentGatewayException catch (error) {
      socialSavedError = error.message;
      return false;
    } on Object {
      socialSavedError =
          'Saved posts could not load. Check your connection and try again.';
      return false;
    } finally {
      socialSavedLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadSocialNotifications({bool refresh = false}) async {
    if (socialNotificationsLoading) return false;
    if (!online) {
      socialNotificationsError =
          'You are offline. Previously loaded notifications remain available.';
      notifyListeners();
      return false;
    }
    final gateway = _socialNotificationGateway;
    if (gateway == null) {
      socialNotificationsError =
          'Notifications are unavailable right now. Try again later.';
      notifyListeners();
      return false;
    }
    socialNotificationsLoading = true;
    socialNotificationsError = null;
    notifyListeners();
    try {
      final page = await gateway.notifications(
        cursor: refresh ? null : _socialNotificationCursor,
      );
      if (refresh) _socialNotifications.clear();
      for (final item in page.items) {
        final index = _socialNotifications.indexWhere(
          (candidate) => candidate.id == item.id,
        );
        if (index >= 0) {
          _socialNotifications[index] = item;
        } else {
          _socialNotifications.add(item);
        }
      }
      _socialNotificationCursor = page.nextCursor;
      socialNotificationsHasMore = page.nextCursor != null;
      socialNotificationsLoaded = true;
      socialNotificationsError = null;
      return true;
    } on SocialContentGatewayException catch (error) {
      socialNotificationsError = error.message;
      return false;
    } on Object {
      socialNotificationsError =
          'Notifications could not load. Check your connection and try again.';
      return false;
    } finally {
      socialNotificationsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markSocialNotificationRead(String notificationId) async {
    final index = _socialNotifications.indexWhere(
      (item) => item.id == notificationId,
    );
    if (index < 0 || _socialNotifications[index].read) return index >= 0;
    if (_socialNotificationsReading.contains(notificationId)) return false;
    if (!online || !authorized) {
      socialNotificationsError = !online
          ? 'You are offline. This notification remains unread.'
          : 'Sign in again before changing notification status.';
      notifyListeners();
      return false;
    }
    final gateway = _socialNotificationGateway;
    if (gateway == null) return false;
    _socialNotificationsReading.add(notificationId);
    socialNotificationsError = null;
    notifyListeners();
    try {
      await gateway.markNotificationRead(notificationId);
      _socialNotifications[index] = _socialNotifications[index].copyWith(
        read: true,
      );
      return true;
    } on SocialContentGatewayException catch (error) {
      socialNotificationsError = error.message;
      return false;
    } on Object {
      socialNotificationsError =
          'Notification status could not update. The content can still open.';
      return false;
    } finally {
      _socialNotificationsReading.remove(notificationId);
      notifyListeners();
    }
  }

  Future<bool> setSocialAuthorBlocked(String authorId, bool blocked) async {
    if (_socialBlocksInFlight.contains(authorId)) return false;
    if (!online || !authorized) {
      _socialBlockErrors[authorId] = !online
          ? 'You are offline. The block setting did not change.'
          : 'Sign in again before changing this block setting.';
      notifyListeners();
      return false;
    }
    final gateway = _socialModerationGateway;
    if (gateway == null) {
      _socialBlockErrors[authorId] =
          'Blocking is unavailable right now. Nothing changed.';
      notifyListeners();
      return false;
    }
    _socialBlocksInFlight.add(authorId);
    _socialBlockErrors.remove(authorId);
    notifyListeners();
    try {
      final saved = await gateway.setAuthorBlocked(
        authorId: authorId,
        blocked: blocked,
      );
      if (saved != blocked) {
        _socialBlockErrors[authorId] =
            'MoolSocial could not confirm this block setting.';
        return false;
      }
      if (blocked) {
        _blockedSocialAuthors.add(authorId);
      } else {
        _blockedSocialAuthors.remove(authorId);
      }
      return true;
    } on SocialContentGatewayException catch (error) {
      _socialBlockErrors[authorId] = error.message;
      return false;
    } on Object {
      _socialBlockErrors[authorId] =
          'The block setting could not change. Nothing changed.';
      return false;
    } finally {
      _socialBlocksInFlight.remove(authorId);
      notifyListeners();
    }
  }

  String filterFor(SharedScreenSpec spec) =>
      filters[spec.screen] ?? spec.filters.first;

  String searchFor(int screen) => searches[screen] ?? '';

  void clearMessages() {
    errorMessage = null;
    noticeMessage = null;
  }

  void resetForAuthenticationBoundary() {
    busy = false;
    authorized = false;
    subscriptionActive = false;
    errorMessage = null;
    noticeMessage = null;
    input = '';
    inputResult = null;
    filters.clear();
    searches.clear();
    _controlValues.clear();
    _completedActions.clear();
    _socialPublishedItems.clear();
    _socialInteractionsInFlight.clear();
    _socialInteractionErrors.clear();
    _socialPublishSequence = 0;
    _pendingSocialPublishFingerprint = null;
    _pendingSocialPublishKey = null;
    _socialFeedCursor = null;
    socialFeedLoading = false;
    socialFeedLoaded = false;
    socialFeedHasMore = false;
    socialFeedError = null;
    _socialFeedFailureWasRefresh = true;
    _socialComments.clear();
    _socialCommentCursors.clear();
    _socialCommentsLoaded.clear();
    _socialCommentsLoading.clear();
    _socialRepliesInFlight.clear();
    _socialCommentErrors.clear();
    _socialReplyDrafts.clear();
    _pendingSocialReplyFingerprints.clear();
    _pendingSocialReplyKeys.clear();
    _socialReplySequence = 0;
    _socialAuthorProfiles.clear();
    _socialAuthorsLoading.clear();
    _socialFollowsInFlight.clear();
    _socialAuthorErrors.clear();
    _socialReportsInFlight.clear();
    _socialReportErrors.clear();
    _reportedSocialPosts.clear();
    _pendingSocialReportFingerprints.clear();
    _pendingSocialReportKeys.clear();
    _socialReportSequence = 0;
    _socialSavedPosts.clear();
    _socialSavedCursor = null;
    socialSavedLoading = false;
    socialSavedLoaded = false;
    socialSavedHasMore = false;
    socialSavedError = null;
    _socialNotifications.clear();
    _socialNotificationCursor = null;
    socialNotificationsLoading = false;
    socialNotificationsLoaded = false;
    socialNotificationsHasMore = false;
    socialNotificationsError = null;
    _socialNotificationsReading.clear();
    _blockedSocialAuthors.clear();
    _socialBlocksInFlight.clear();
    _socialBlockErrors.clear();
    notifyListeners();
  }

  void dismissMessages() {
    clearMessages();
    notifyListeners();
  }

  void setOnline(bool value) {
    online = value;
    clearMessages();
    notifyListeners();
  }

  void setAuthorized(bool value) {
    authorized = value;
    clearMessages();
    notifyListeners();
  }

  void setSubscriptionActive(bool value) {
    subscriptionActive = value;
    clearMessages();
    notifyListeners();
  }

  void setFilter(int screen, String value) {
    filters[screen] = value;
    clearMessages();
    notifyListeners();
  }

  void setSearch(int screen, String value) {
    searches[screen] = value;
    clearMessages();
    notifyListeners();
  }

  void resetDiscovery(SharedScreenSpec spec) {
    filters[spec.screen] = spec.filters.first;
    searches[spec.screen] = '';
    clearMessages();
    notifyListeners();
  }

  List<SharedItem> visibleItems(SharedScreenSpec spec) {
    final selected = filterFor(spec);
    final query = searchFor(spec.screen).trim().toLowerCase();
    return spec.items
        .where((item) {
          final categoryMatch =
              selected == spec.filters.first || item.category == selected;
          final searchMatch =
              query.isEmpty ||
              '${item.title} ${item.summary} ${item.meta} ${item.category}'
                  .toLowerCase()
                  .contains(query);
          return categoryMatch && searchMatch;
        })
        .toList(growable: false);
  }

  String actionId(int screen, String itemId, String action) =>
      'SHARED-$screen-${itemId.toUpperCase()}-${action.toUpperCase()}';

  bool actionComplete(String id) => _completedActions.contains(id);

  bool controlValue(SharedItem item, SharedControl control) {
    return _controlValues.putIfAbsent(
      '${item.id}:${control.id}',
      () => control.initialValue,
    );
  }

  bool toggleControl(SharedItem item, SharedControl control, bool value) {
    if (control.locked) {
      errorMessage =
          control.lockedMessage ?? 'This protection cannot be changed here.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (control.subscriptionRequired && value && !subscriptionActive) {
      errorMessage =
          'Choose and activate a monthly plan before enabling Mool Agent.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    _controlValues['${item.id}:${control.id}'] = value;
    _completedActions.remove(actionId(165, item.id, 'primary'));
    clearMessages();
    notifyListeners();
    return true;
  }

  void setPauseDuration(String value) {
    pauseDuration = value;
    clearMessages();
    notifyListeners();
  }

  Future<bool> execute({
    required String id,
    required String outcome,
    String? confirmation,
    bool confirmed = false,
  }) async {
    if (_completedActions.contains(id)) {
      errorMessage = null;
      noticeMessage = 'Action already complete. No duplicate was created.';
      notifyListeners();
      return true;
    }
    if (confirmation != null && !confirmed) {
      errorMessage = 'Review and confirm the effect of this action first.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (!online) {
      errorMessage =
          'You are offline. Nothing changed. Reconnect and retry the same action.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    if (!authorized) {
      errorMessage =
          'Your current role cannot complete this action. Nothing changed.';
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    busy = true;
    clearMessages();
    notifyListeners();
    try {
      await gateway.execute(id);
      _completedActions.add(id);
      noticeMessage = outcome.replaceAll(
        'the selected end time',
        pauseDuration,
      );
      errorMessage = null;
      return true;
    } on SharedGatewayException catch (error) {
      errorMessage = error.message;
      noticeMessage = null;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void updateInput(String value) {
    input = value;
    inputResult = null;
    clearMessages();
    notifyListeners();
  }

  Future<bool> resolveInput() async {
    final normalized = input.trim().toLowerCase();
    if (normalized.length < 3) {
      errorMessage = 'Type at least 3 characters, or choose Scan or Voice.';
      noticeMessage = null;
      inputResult = null;
      notifyListeners();
      return false;
    }
    final result = switch (normalized) {
      final value when value.contains('atta') || value.contains('grocery') =>
        const SharedIntentResult(
          title: 'Atta under ₹300 delivered today',
          detail:
              'Compare final price, pack, delivery and refund before adding.',
          action: 'See matching atta',
          route: '/app/buy/grocery',
        ),
      final value when value.contains('cab') || value.contains('airport') =>
        const SharedIntentResult(
          title: 'Book a cab to Jodhpur Airport',
          detail:
              'Confirm pickup, arrival estimate and fare before requesting.',
          action: 'Set pickup',
          route: '/app/ride/book?type=cab',
        ),
      final value when value.contains('order') => const SharedIntentResult(
        title: 'Today’s retailer orders',
        detail: 'Open the authorized Mahadev Fresh Mart order queue.',
        action: 'Open orders',
        route: '/app/retailer',
      ),
      final value when value.contains('work') || value.contains('job') =>
        const SharedIntentResult(
          title: 'Paid work near you',
          detail: 'Review funding, output, proof and payout before applying.',
          action: 'See opportunities',
          route: '/app/earn',
        ),
      _ => null,
    };
    if (result == null) {
      errorMessage =
          'No exact action matched. Add a product, service, place or workspace name.';
      noticeMessage = null;
      inputResult = null;
      notifyListeners();
      return false;
    }
    final resultId = switch (result.route) {
      '/app/buy/grocery' => 'BUY',
      '/app/ride/book?type=cab' => 'RIDE',
      '/app/retailer' => 'RETAILER',
      '/app/earn' => 'EARN',
      _ => 'ACTION',
    };
    final success = await execute(
      id: 'SHARED-159-ASK-$resultId',
      outcome: 'Exact action found. Review it before continuing.',
    );
    if (success) inputResult = result;
    notifyListeners();
    return success;
  }

  void useSuggestedInput(String value) {
    input = value;
    inputResult = null;
    clearMessages();
    notifyListeners();
  }

  bool startScanner() {
    clearMessages();
    if (!cameraAllowed) {
      errorMessage =
          'Camera access is off. Allow it in device settings or enter the code.';
      notifyListeners();
      return false;
    }
    noticeMessage =
        'Scanner opened for a product, shop, bill or payment QR. Nothing is paid automatically.';
    notifyListeners();
    return true;
  }

  bool startVoice() {
    clearMessages();
    if (!microphoneAllowed) {
      errorMessage =
          'Microphone access is off. Allow it in device settings or type instead.';
      notifyListeners();
      return false;
    }
    input = 'atta under ₹300 delivered today';
    noticeMessage = 'Voice captured. Review the words before searching.';
    notifyListeners();
    return true;
  }

  void completeLocal(String message) {
    errorMessage = null;
    noticeMessage = message;
    notifyListeners();
  }

  Future<SocialPublishedItem?> publishSocialContent({
    required SocialPublishedContentType type,
    required String authorName,
    required String authorHandle,
    required String body,
    String audience = 'Public',
    List<String> mediaPaths = const <String>[],
    bool mediaAreAssets = false,
    List<SocialPublishedChoice> choices = const <SocialPublishedChoice>[],
    int? correctChoiceIndex,
    DateTime? closesAt,
    String? quotedPostId,
  }) async {
    final normalizedBody = body.trim();
    final normalizedChoices = choices
        .map(
          (choice) => SocialPublishedChoice(
            label: choice.label.trim(),
            imagePath: choice.imagePath,
            imageIsAsset: choice.imageIsAsset,
            votes: choice.votes,
          ),
        )
        .toList(growable: false);
    if (quotedPostId != null && normalizedBody.isEmpty) {
      errorMessage = 'Add your thoughts before sharing this post.';
      noticeMessage = null;
      notifyListeners();
      return null;
    }
    final validation = _validateSocialContent(
      type: type,
      body: normalizedBody,
      mediaPaths: mediaPaths,
      choices: normalizedChoices,
      correctChoiceIndex: correctChoiceIndex,
    );
    if (validation != null) {
      errorMessage = validation;
      noticeMessage = null;
      notifyListeners();
      return null;
    }
    if (!online) {
      errorMessage =
          'You are offline. Your content is still here. Reconnect and post again.';
      noticeMessage = null;
      notifyListeners();
      return null;
    }
    if (!authorized) {
      errorMessage = 'Sign in again before posting to your public profile.';
      noticeMessage = null;
      notifyListeners();
      return null;
    }
    if (busy) {
      errorMessage = 'Your current post is still finishing.';
      noticeMessage = null;
      notifyListeners();
      return null;
    }

    busy = true;
    clearMessages();
    notifyListeners();
    final fingerprint = <Object?>[
      type.name,
      normalizedBody,
      audience,
      ...mediaPaths,
      for (final choice in normalizedChoices)
        '${choice.label}|${choice.imagePath ?? ''}',
      correctChoiceIndex,
      quotedPostId,
    ].join('\u001f');
    if (_pendingSocialPublishFingerprint != fingerprint ||
        _pendingSocialPublishKey == null) {
      _socialPublishSequence += 1;
      _pendingSocialPublishFingerprint = fingerprint;
      _pendingSocialPublishKey =
          'social-${DateTime.now().microsecondsSinceEpoch}-$_socialPublishSequence';
    }
    try {
      final item = await _socialContentGateway.publish(
        SocialPublishDraft(
          idempotencyKey: _pendingSocialPublishKey!,
          type: type,
          authorName: authorName.trim().isEmpty ? 'Your profile' : authorName,
          authorHandle: authorHandle.trim().isEmpty
              ? 'Public profile'
              : authorHandle,
          body: normalizedBody,
          audience: audience,
          mediaPaths: List<String>.unmodifiable(mediaPaths),
          mediaAreAssets: mediaAreAssets,
          choices: List<SocialPublishedChoice>.unmodifiable(normalizedChoices),
          correctChoiceIndex: correctChoiceIndex,
          quotedPostId: quotedPostId,
        ),
      );
      _upsertSocialItem(item);
      _pendingSocialPublishFingerprint = null;
      _pendingSocialPublishKey = null;
      errorMessage = null;
      noticeMessage = 'Posted to Feed and your public profile.';
      return item;
    } on SocialContentGatewayException catch (error) {
      errorMessage = error.message;
      noticeMessage = null;
      return null;
    } on Object {
      errorMessage =
          'Your content could not be posted. It is still here. Please try again.';
      noticeMessage = null;
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  String? _validateSocialContent({
    required SocialPublishedContentType type,
    required String body,
    required List<String> mediaPaths,
    required List<SocialPublishedChoice> choices,
    required int? correctChoiceIndex,
  }) {
    switch (type) {
      case SocialPublishedContentType.reel:
        return 'MoolSocial does not host Shorts or Reels. Use the YouTube creator option for YouTube-hosted Shorts.';
      case SocialPublishedContentType.carousel:
        if (mediaPaths.length < 2 || mediaPaths.length > 10) {
          return 'Choose between 2 and 10 photos for your carousel.';
        }
        break;
      case SocialPublishedContentType.post:
        if (body.isEmpty && mediaPaths.isEmpty) {
          return 'Write something or add an image before posting.';
        }
        break;
      case SocialPublishedContentType.imagePoll:
        if (body.isEmpty) return 'Add a question for your Image Poll.';
        if (choices.length != 4 ||
            choices.any(
              (choice) =>
                  choice.label.isEmpty || choice.imagePath?.isEmpty != false,
            )) {
          return 'Add a name and image for all four choices.';
        }
        break;
      case SocialPublishedContentType.quickPoll:
        if (body.isEmpty) return 'Add a question for your Quick Poll.';
        if (choices.length != 4 ||
            choices.any((choice) => choice.label.isEmpty)) {
          return 'Add all four choices.';
        }
        break;
      case SocialPublishedContentType.quiz:
        if (body.isEmpty) return 'Add a question for your Quiz.';
        if (choices.length != 4 ||
            choices.any((choice) => choice.label.isEmpty)) {
          return 'Add all four answers.';
        }
        if (correctChoiceIndex == null ||
            correctChoiceIndex < 0 ||
            correctChoiceIndex >= choices.length) {
          return 'Choose the correct answer before posting.';
        }
        break;
    }
    return null;
  }

  Future<bool> toggleSocialLike(String id) => _runSocialInteraction(id, 'like');

  Future<bool> toggleSocialSave(String id) => _runSocialInteraction(id, 'save');

  Future<bool> toggleSocialRepost(String id) =>
      _runSocialInteraction(id, 'repost');

  Future<bool> voteOnSocialContent(String id, int choiceIndex) =>
      _runSocialInteraction(id, 'vote', choiceIndex: choiceIndex);

  void rejectUnsupportedSocialInteraction(String action) {
    errorMessage = '$action is not available yet. Nothing changed.';
    noticeMessage = null;
    notifyListeners();
  }

  Future<bool> _runSocialInteraction(
    String id,
    String interaction, {
    int? choiceIndex,
  }) async {
    if (_socialInteractionsInFlight.contains(id)) {
      return false;
    }
    if (!online) {
      const message = 'You are offline. Nothing changed.';
      _socialInteractionErrors[id] = message;
      errorMessage = message;
      noticeMessage = null;
      notifyListeners();
      return false;
    }
    _socialInteractionsInFlight.add(id);
    _socialInteractionErrors.remove(id);
    clearMessages();
    notifyListeners();
    try {
      final updated = await _socialContentGateway.interact(
        postId: id,
        interaction: interaction,
        choiceIndex: choiceIndex,
      );
      _upsertSocialItem(updated);
      if (interaction == 'save') {
        if (updated.saved) {
          _upsertSavedSocialItem(updated);
        } else {
          _socialSavedPosts.removeWhere((item) => item.id == updated.id);
        }
      }
      _socialInteractionErrors.remove(id);
      clearMessages();
      notifyListeners();
      return true;
    } on SocialContentGatewayException catch (error) {
      _socialInteractionErrors[id] = error.message;
      errorMessage = error.message;
      noticeMessage = null;
      notifyListeners();
      return false;
    } on Object {
      const message =
          'That Feed action could not be completed. Nothing changed. Please try again.';
      _socialInteractionErrors[id] = message;
      errorMessage = message;
      noticeMessage = null;
      notifyListeners();
      return false;
    } finally {
      _socialInteractionsInFlight.remove(id);
      notifyListeners();
    }
  }

  void _upsertSocialItem(SocialPublishedItem item, {bool append = false}) {
    final index = _socialPublishedItems.indexWhere(
      (candidate) => candidate.id == item.id,
    );
    if (index >= 0) {
      _socialPublishedItems[index] = item;
    } else if (append) {
      _socialPublishedItems.add(item);
    } else {
      _socialPublishedItems.insert(0, item);
    }
  }

  void _upsertSavedSocialItem(SocialPublishedItem item) {
    final index = _socialSavedPosts.indexWhere(
      (candidate) => candidate.id == item.id,
    );
    if (index >= 0) {
      _socialSavedPosts[index] = item;
    } else {
      _socialSavedPosts.add(item);
    }
  }
}
