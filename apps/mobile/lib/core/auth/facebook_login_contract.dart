const Set<String> _defaultFacebookPermissions = <String>{'public_profile'};

/// The native Facebook SDK boundary is supplied separately from this contract.
///
/// This pure-Dart owner deliberately has no SDK dependency and cannot perform
/// provider, browser, or network work on its own.
abstract interface class FacebookNativeSdkAdapter {
  bool get isConfigured;

  Future<FacebookLoginResult> signIn();

  Future<FacebookLoginOutcome> logOut();

  Future<FacebookLoginOutcome> revokeAccess();
}

enum FacebookLoginConfigurationIssue {
  androidPackageMismatch,
  androidLaunchActivityMismatch,
  keyHashReadinessMissing,
  redirectMismatch,
  privacyPolicyUnavailable,
  dataDeletionUnavailable,
  revocationUnavailable,
  permissionsNotMinimal,
  emailPermissionForbidden,
  nativeAdapterUnavailable,
}

final class FacebookRedirectExpectation {
  const FacebookRedirectExpectation({required this.host, required this.path});

  final String host;
  final String path;

  bool get isWellFormed {
    return host.isNotEmpty &&
        host == host.trim() &&
        host == host.toLowerCase() &&
        !host.contains('*') &&
        path.startsWith('/') &&
        path != '/' &&
        !path.contains('*') &&
        !path.contains('?') &&
        !path.contains('#');
  }
}

final class FacebookLoginConfiguration {
  FacebookLoginConfiguration({
    required this.androidPackageName,
    required this.androidLaunchActivity,
    required this.keyHashReadinessFact,
    required this.redirectUri,
    required this.privacyPolicyUrl,
    required this.dataDeletionUrl,
    this.revocationConfigured = false,
    this.dataDeletionRequestConfigured = false,
    Set<String> permissions = _defaultFacebookPermissions,
  }) : permissions = Set<String>.unmodifiable(permissions);

  final String androidPackageName;
  final String androidLaunchActivity;
  final String keyHashReadinessFact;
  final Uri? redirectUri;
  final Uri? privacyPolicyUrl;
  final Uri? dataDeletionUrl;
  final bool revocationConfigured;
  final bool dataDeletionRequestConfigured;
  final Set<String> permissions;

  bool get requestsEmail => permissions.contains('email');
}

final class FacebookLoginReadiness {
  FacebookLoginReadiness._(Set<FacebookLoginConfigurationIssue> issues)
    : issues = Set<FacebookLoginConfigurationIssue>.unmodifiable(issues);

  final Set<FacebookLoginConfigurationIssue> issues;

  bool get isReady => issues.isEmpty;
}

enum FacebookLoginOutcome {
  success,
  cancelled,
  denied,
  providerFailure,
  operationInProgress,
  configurationUnavailable,
  networkUnavailable,
  accountCollision,
  firebaseUnclassified,
  firebaseBridgeFailure,
}

enum FacebookLoginOrigin {
  configurationPreflight,
  nativeSdk,
  firebaseCredentialExchange,
  completed,
}

final class FacebookLoginResult {
  const FacebookLoginResult({required this.outcome, required this.origin});

  final FacebookLoginOutcome outcome;
  final FacebookLoginOrigin origin;

  String get safeCode {
    final stage = switch (origin) {
      FacebookLoginOrigin.configurationPreflight => 'preflight',
      FacebookLoginOrigin.nativeSdk => 'native',
      FacebookLoginOrigin.firebaseCredentialExchange => 'firebase',
      FacebookLoginOrigin.completed => 'completed',
    };
    final result = switch (outcome) {
      FacebookLoginOutcome.success => 'success',
      FacebookLoginOutcome.cancelled => 'cancelled',
      FacebookLoginOutcome.denied => 'denied',
      FacebookLoginOutcome.providerFailure => 'provider-failure',
      FacebookLoginOutcome.operationInProgress => 'operation-in-progress',
      FacebookLoginOutcome.configurationUnavailable => 'configuration',
      FacebookLoginOutcome.networkUnavailable => 'network',
      FacebookLoginOutcome.accountCollision => 'account-collision',
      FacebookLoginOutcome.firebaseUnclassified => 'unclassified',
      FacebookLoginOutcome.firebaseBridgeFailure => 'bridge-failure',
    };
    return 'auth-facebook-$stage-$result';
  }

  @override
  String toString() =>
      'FacebookLoginResult(origin: ${origin.name}, outcome: ${outcome.name})';
}

extension FacebookLoginOutcomeMessage on FacebookLoginOutcome {
  String get safeMessage {
    return switch (this) {
      FacebookLoginOutcome.success => 'Facebook sign-in completed.',
      FacebookLoginOutcome.cancelled => 'Facebook sign-in was cancelled.',
      FacebookLoginOutcome.denied =>
        'Facebook sign-in permission was not approved.',
      FacebookLoginOutcome.providerFailure =>
        'Facebook sign-in could not be completed. Please try again.',
      FacebookLoginOutcome.operationInProgress =>
        'Facebook sign-in is already in progress.',
      FacebookLoginOutcome.configurationUnavailable =>
        'Facebook sign-in is unavailable.',
      FacebookLoginOutcome.networkUnavailable =>
        'Facebook sign-in could not reach the provider.',
      FacebookLoginOutcome.accountCollision =>
        'This sign-in method cannot be linked automatically.',
      FacebookLoginOutcome.firebaseUnclassified ||
      FacebookLoginOutcome.firebaseBridgeFailure =>
        'Facebook sign-in could not confirm the account. Please try again.',
    };
  }
}

final class FacebookProviderCallback {
  const FacebookProviderCallback({
    required this.outcome,
    required this.providerStateVerified,
  });

  final FacebookLoginOutcome outcome;
  final bool providerStateVerified;
}

enum FacebookProviderAttemptPhase { notStarted, awaitingProvider, terminal }

final class FacebookProviderAttempt {
  const FacebookProviderAttempt.notStarted()
    : phase = FacebookProviderAttemptPhase.notStarted,
      providerStartCount = 0,
      callbackCount = 0,
      terminalOutcomeCount = 0,
      outcome = null;

  const FacebookProviderAttempt._({
    required this.phase,
    required this.providerStartCount,
    required this.callbackCount,
    required this.terminalOutcomeCount,
    required this.outcome,
  });

  final FacebookProviderAttemptPhase phase;
  final int providerStartCount;
  final int callbackCount;
  final int terminalOutcomeCount;
  final FacebookLoginOutcome? outcome;

  FacebookProviderAttempt startProvider() {
    if (phase != FacebookProviderAttemptPhase.notStarted ||
        providerStartCount != 0 ||
        callbackCount != 0 ||
        terminalOutcomeCount != 0 ||
        outcome != null) {
      throw StateError('Facebook provider attempt was already started.');
    }
    return const FacebookProviderAttempt._(
      phase: FacebookProviderAttemptPhase.awaitingProvider,
      providerStartCount: 1,
      callbackCount: 0,
      terminalOutcomeCount: 0,
      outcome: null,
    );
  }

  FacebookProviderAttempt completeCallback(FacebookProviderCallback callback) {
    _requireAwaitingProvider();
    final resolvedOutcome = callback.providerStateVerified
        ? callback.outcome
        : FacebookLoginOutcome.configurationUnavailable;
    return FacebookProviderAttempt._(
      phase: FacebookProviderAttemptPhase.terminal,
      providerStartCount: 1,
      callbackCount: 1,
      terminalOutcomeCount: 1,
      outcome: resolvedOutcome,
    );
  }

  FacebookProviderAttempt failWithoutCallback(FacebookLoginOutcome failure) {
    _requireAwaitingProvider();
    if (failure != FacebookLoginOutcome.configurationUnavailable &&
        failure != FacebookLoginOutcome.networkUnavailable) {
      throw ArgumentError.value(
        failure,
        'failure',
        'Only a sanitized pre-callback failure is accepted.',
      );
    }
    return FacebookProviderAttempt._(
      phase: FacebookProviderAttemptPhase.terminal,
      providerStartCount: 1,
      callbackCount: 0,
      terminalOutcomeCount: 1,
      outcome: failure,
    );
  }

  FacebookProviderAttempt expire() {
    return failWithoutCallback(FacebookLoginOutcome.configurationUnavailable);
  }

  void _requireAwaitingProvider() {
    if (phase != FacebookProviderAttemptPhase.awaitingProvider ||
        providerStartCount != 1 ||
        callbackCount != 0 ||
        terminalOutcomeCount != 0 ||
        outcome != null) {
      throw StateError('Facebook provider attempt is no longer active.');
    }
  }
}

enum FacebookAccountRequestKind { logout, revokeAccess, dataDeletion }

sealed class FacebookAccountRequest {
  const FacebookAccountRequest();

  FacebookAccountRequestKind get kind;
}

final class FacebookLogoutRequest extends FacebookAccountRequest {
  const FacebookLogoutRequest();

  @override
  FacebookAccountRequestKind get kind => FacebookAccountRequestKind.logout;
}

final class FacebookRevocationRequest extends FacebookAccountRequest {
  const FacebookRevocationRequest();

  @override
  FacebookAccountRequestKind get kind =>
      FacebookAccountRequestKind.revokeAccess;
}

final class FacebookDataDeletionRequest extends FacebookAccountRequest {
  const FacebookDataDeletionRequest({required this.destination});

  final Uri destination;

  @override
  FacebookAccountRequestKind get kind =>
      FacebookAccountRequestKind.dataDeletion;
}

final class FacebookLoginContract {
  FacebookLoginContract({
    required this.configuration,
    required this.redirectExpectation,
    this.nativeSdkAdapter,
  });

  static const String expectedAndroidPackage = 'com.moolsocial.app';
  static const String expectedAndroidLaunchActivity =
      'com.moolsocial.app.MainActivity';
  static const String expectedKeyHashReadinessFact =
      'debug_and_release_key_hashes_qualified_separately';
  static const Set<String> defaultPermissions = _defaultFacebookPermissions;
  static const bool emailPermissionRequestedByDefault = false;

  final FacebookLoginConfiguration configuration;
  final FacebookRedirectExpectation redirectExpectation;
  final FacebookNativeSdkAdapter? nativeSdkAdapter;

  FacebookLoginReadiness get readiness {
    final issues = <FacebookLoginConfigurationIssue>{};
    if (configuration.androidPackageName != expectedAndroidPackage) {
      issues.add(FacebookLoginConfigurationIssue.androidPackageMismatch);
    }
    if (configuration.androidLaunchActivity != expectedAndroidLaunchActivity) {
      issues.add(FacebookLoginConfigurationIssue.androidLaunchActivityMismatch);
    }
    if (configuration.keyHashReadinessFact.trim().isEmpty ||
        configuration.keyHashReadinessFact != expectedKeyHashReadinessFact) {
      issues.add(FacebookLoginConfigurationIssue.keyHashReadinessMissing);
    }
    if (!_matchesExactRedirect(configuration.redirectUri)) {
      issues.add(FacebookLoginConfigurationIssue.redirectMismatch);
    }
    if (!_isPublicHttpsUrl(configuration.privacyPolicyUrl)) {
      issues.add(FacebookLoginConfigurationIssue.privacyPolicyUnavailable);
    }
    if (!_isPublicHttpsUrl(configuration.dataDeletionUrl) ||
        !configuration.dataDeletionRequestConfigured ||
        configuration.dataDeletionUrl == configuration.privacyPolicyUrl) {
      issues.add(FacebookLoginConfigurationIssue.dataDeletionUnavailable);
    }
    if (!configuration.revocationConfigured) {
      issues.add(FacebookLoginConfigurationIssue.revocationUnavailable);
    }
    if (!_hasExactDefaultPermissions(configuration.permissions)) {
      issues.add(FacebookLoginConfigurationIssue.permissionsNotMinimal);
    }
    if (configuration.requestsEmail) {
      issues.add(FacebookLoginConfigurationIssue.emailPermissionForbidden);
    }
    if (nativeSdkAdapter?.isConfigured != true) {
      issues.add(FacebookLoginConfigurationIssue.nativeAdapterUnavailable);
    }
    return FacebookLoginReadiness._(issues);
  }

  FacebookProviderAttempt beginProviderAttempt() {
    if (!readiness.isReady) {
      throw StateError('Facebook sign-in is unavailable.');
    }
    return const FacebookProviderAttempt.notStarted().startProvider();
  }

  FacebookLogoutRequest createLogoutRequest() {
    _requireNativeAdapter();
    return const FacebookLogoutRequest();
  }

  FacebookRevocationRequest createRevocationRequest() {
    _requireNativeAdapter();
    if (!configuration.revocationConfigured) {
      throw StateError('Facebook access revocation is unavailable.');
    }
    return const FacebookRevocationRequest();
  }

  FacebookDataDeletionRequest createDataDeletionRequest() {
    _requireNativeAdapter();
    final destination = configuration.dataDeletionUrl;
    if (!configuration.dataDeletionRequestConfigured ||
        !_isPublicHttpsUrl(destination) ||
        destination == configuration.privacyPolicyUrl) {
      throw StateError('Facebook data deletion is unavailable.');
    }
    return FacebookDataDeletionRequest(destination: destination!);
  }

  bool _matchesExactRedirect(Uri? uri) {
    return redirectExpectation.isWellFormed &&
        _isPublicHttpsUrl(uri) &&
        uri!.host == redirectExpectation.host &&
        uri.path == redirectExpectation.path;
  }

  bool _hasExactDefaultPermissions(Set<String> permissions) {
    return permissions.length == defaultPermissions.length &&
        permissions.containsAll(defaultPermissions);
  }

  bool _isPublicHttpsUrl(Uri? uri) {
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        !uri.host.contains('*') &&
        uri.userInfo.isEmpty &&
        !uri.hasPort &&
        !uri.hasQuery &&
        !uri.hasFragment &&
        uri.path.startsWith('/') &&
        uri.path != '/';
  }

  void _requireNativeAdapter() {
    if (nativeSdkAdapter?.isConfigured != true) {
      throw StateError('Facebook native support is unavailable.');
    }
  }
}
