import 'dart:async';
import 'dart:convert';

typedef PublicAuthAppCheckTokenSupplier = Future<String> Function();
typedef PublicAuthJsonPostTransport =
    Future<PublicAuthHttpResponse> Function(
      Uri uri, {
      required Map<String, String> headers,
      required Map<String, Object?> body,
    });
typedef PublicAuthExternalUrlLauncher = Future<bool> Function(Uri uri);
typedef PublicAuthFirebaseCustomTokenSignIn =
    Future<String?> Function(String customToken);
typedef PublicAuthAuthorizationUriValidator = bool Function(Uri uri);
typedef PublicAuthNetworkClock = DateTime Function();

enum BrokeredPublicAuthOutcome {
  browserOpened,
  authenticated,
  cancelled,
  denied,
  expired,
  replayRejected,
  accountIneligible,
  configurationFailure,
  networkFailure,
  timeout,
  providerFailure,
}

final class BrokeredPublicAuthResult {
  const BrokeredPublicAuthResult._(
    this.outcome,
    this.publicMessage, {
    this.userId,
    this.safeCode,
  });

  final BrokeredPublicAuthOutcome outcome;
  final String publicMessage;
  final String? userId;
  final String? safeCode;

  String get code =>
      safeCode ??
      switch (outcome) {
        BrokeredPublicAuthOutcome.browserOpened => 'auth-browser-opened',
        BrokeredPublicAuthOutcome.authenticated => 'auth-authenticated',
        BrokeredPublicAuthOutcome.cancelled => 'auth-cancelled',
        BrokeredPublicAuthOutcome.denied => 'auth-authorization-denied',
        BrokeredPublicAuthOutcome.expired => 'auth-expired-credential',
        BrokeredPublicAuthOutcome.replayRejected => 'auth-replay-rejected',
        BrokeredPublicAuthOutcome.accountIneligible =>
          'auth-account-ineligible',
        BrokeredPublicAuthOutcome.configurationFailure =>
          'auth-provider-configuration',
        BrokeredPublicAuthOutcome.networkFailure => 'auth-network',
        BrokeredPublicAuthOutcome.timeout => 'auth-timeout',
        BrokeredPublicAuthOutcome.providerFailure =>
          'auth-provider-unavailable',
      };

  bool get isAuthenticated =>
      outcome == BrokeredPublicAuthOutcome.authenticated;

  @override
  String toString() => 'BrokeredPublicAuthResult(outcome: ${outcome.name})';
}

final class PublicAuthHttpResponse {
  const PublicAuthHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  @override
  String toString() => 'PublicAuthHttpResponse(statusCode: $statusCode)';
}

enum PublicAuthDependencyFailure {
  cancelled,
  configuration,
  network,
  timeout,
  provider,
  appCheckConfiguration,
  appCheckNetwork,
  appCheckTimeout,
  browserUnavailable,
  browserTimeout,
  firebaseCredential,
  firebaseNetwork,
  firebaseTimeout,
}

final class PublicAuthDependencyException implements Exception {
  const PublicAuthDependencyException(this.failure);

  final PublicAuthDependencyFailure failure;

  @override
  String toString() => 'PublicAuthDependencyException(${failure.name})';
}

final class BrokeredPublicAuthConfiguration {
  const BrokeredPublicAuthConfiguration({
    required this.providerLabel,
    required this.operationPath,
    required this.authApiBaseUri,
    required this.callbackUri,
    required this.authorizationEndpoint,
  });

  final String providerLabel;
  final String operationPath;
  final Uri authApiBaseUri;
  final Uri callbackUri;
  final Uri authorizationEndpoint;

  Uri? get appDeliveryCallbackUri {
    if (callbackUri.scheme != 'https' ||
        callbackUri.host != 'moolsocial.com' ||
        callbackUri.path != '/app/auth/$operationPath') {
      return null;
    }
    return Uri(scheme: 'moolsocial', host: 'auth', path: '/$operationPath');
  }

  bool get isValid =>
      providerLabel.isNotEmpty &&
      providerLabel == providerLabel.trim() &&
      RegExp(r'^[a-z][a-z0-9-]{0,31}$').hasMatch(operationPath) &&
      _isSecureBase(authApiBaseUri) &&
      _isCallbackBase(callbackUri) &&
      _isSecureBase(authorizationEndpoint);

  Uri operationUri(String operation) {
    final base = authApiBaseUri.toString();
    final separator = base.endsWith('/') ? '' : '/';
    return Uri.parse('$base$separator$operationPath/$operation');
  }

  @override
  String toString() => 'BrokeredPublicAuthConfiguration(redacted)';
}

final class BrokeredPublicAuthNetworkAdapter {
  factory BrokeredPublicAuthNetworkAdapter({
    required BrokeredPublicAuthConfiguration configuration,
    required PublicAuthAppCheckTokenSupplier appCheckTokenSupplier,
    required PublicAuthJsonPostTransport postTransport,
    required PublicAuthExternalUrlLauncher externalUrlLauncher,
    required PublicAuthFirebaseCustomTokenSignIn firebaseCustomTokenSignIn,
    required PublicAuthAuthorizationUriValidator authorizationUriValidator,
    PublicAuthNetworkClock? clock,
    Duration operationTimeout = const Duration(seconds: 70),
  }) {
    if (operationTimeout <= Duration.zero ||
        operationTimeout > const Duration(seconds: 90)) {
      throw ArgumentError.value(
        operationTimeout,
        'operationTimeout',
        'Public authentication timeout is invalid.',
      );
    }
    return BrokeredPublicAuthNetworkAdapter._(
      configuration,
      appCheckTokenSupplier,
      postTransport,
      externalUrlLauncher,
      firebaseCustomTokenSignIn,
      authorizationUriValidator,
      clock ?? _utcNow,
      operationTimeout,
    );
  }

  BrokeredPublicAuthNetworkAdapter._(
    this.configuration,
    this._appCheckTokenSupplier,
    this._postTransport,
    this._externalUrlLauncher,
    this._firebaseCustomTokenSignIn,
    this._authorizationUriValidator,
    this._clock,
    this._operationTimeout,
  );

  final BrokeredPublicAuthConfiguration configuration;
  final PublicAuthAppCheckTokenSupplier _appCheckTokenSupplier;
  final PublicAuthJsonPostTransport _postTransport;
  final PublicAuthExternalUrlLauncher _externalUrlLauncher;
  final PublicAuthFirebaseCustomTokenSignIn _firebaseCustomTokenSignIn;
  final PublicAuthAuthorizationUriValidator _authorizationUriValidator;
  final PublicAuthNetworkClock _clock;
  final Duration _operationTimeout;

  bool recognizesCallback(Uri callbackUri) {
    if (!configuration.isValid) return false;
    if (_isExactCallback(callbackUri, configuration.callbackUri)) return true;
    final deliveryCallback = configuration.appDeliveryCallbackUri;
    return deliveryCallback != null &&
        _isExactCallback(callbackUri, deliveryCallback);
  }

  Future<BrokeredPublicAuthResult> beginAuthorization() {
    return _guard(() async {
      if (!configuration.isValid) {
        return _result(
          BrokeredPublicAuthOutcome.configurationFailure,
          safeCode: 'auth-client-configuration',
        );
      }
      final appCheckToken = await _appCheckTokenSupplier();
      if (!_isOpaqueCredential(appCheckToken)) {
        return _result(
          BrokeredPublicAuthOutcome.configurationFailure,
          safeCode: 'auth-app-check-token-missing',
        );
      }
      final response = await _postTransport(
        configuration.operationUri('begin'),
        headers: Map<String, String>.unmodifiable(<String, String>{
          'content-type': 'application/json; charset=utf-8',
          'X-Firebase-AppCheck': appCheckToken,
        }),
        body: const <String, Object?>{},
      );
      final envelope = _normalizeEnvelope(response);
      if (envelope == null) {
        return _result(
          BrokeredPublicAuthOutcome.providerFailure,
          safeCode: 'auth-broker-response-invalid',
        );
      }
      if (envelope.error case final error?) {
        return _result(
          _outcomeForBrokerError(error.code),
          safeCode: _safeCodeForBrokerError(error.code),
        );
      }
      final begin = _normalizeBeginData(envelope.data, _clock().toUtc());
      if (begin == null) {
        return _result(
          BrokeredPublicAuthOutcome.providerFailure,
          safeCode: 'auth-broker-begin-invalid',
        );
      }
      if (!_authorizationUriValidator(begin.uri)) {
        return _result(
          BrokeredPublicAuthOutcome.providerFailure,
          safeCode: 'auth-authorization-response-invalid',
        );
      }
      final opened = await _externalUrlLauncher(begin.uri);
      return _result(
        opened
            ? BrokeredPublicAuthOutcome.browserOpened
            : BrokeredPublicAuthOutcome.configurationFailure,
        safeCode: opened ? null : 'auth-ui-unavailable',
      );
    });
  }

  Future<BrokeredPublicAuthResult> completeForegroundCallback(
    Uri callbackUri,
  ) => _completeCallback(callbackUri);

  Future<BrokeredPublicAuthResult> completeColdStartCallback(Uri callbackUri) =>
      _completeCallback(callbackUri);

  Future<BrokeredPublicAuthResult> _completeCallback(Uri callbackUri) {
    return _guard(() async {
      if (!configuration.isValid) {
        return _result(
          BrokeredPublicAuthOutcome.configurationFailure,
          safeCode: 'auth-client-configuration',
        );
      }
      if (!recognizesCallback(callbackUri)) {
        return _result(
          BrokeredPublicAuthOutcome.providerFailure,
          safeCode: 'auth-callback-origin-invalid',
        );
      }
      final callbackText = callbackUri.toString();
      if (callbackText.length > 4096 || callbackUri.query.isEmpty) {
        return _result(
          BrokeredPublicAuthOutcome.providerFailure,
          safeCode: 'auth-callback-payload-invalid',
        );
      }
      final brokerCallbackUri =
          _isExactCallback(callbackUri, configuration.callbackUri)
          ? callbackUri
          : configuration.callbackUri.replace(query: callbackUri.query);
      final appCheckToken = await _appCheckTokenSupplier();
      if (!_isOpaqueCredential(appCheckToken)) {
        return _result(
          BrokeredPublicAuthOutcome.configurationFailure,
          safeCode: 'auth-app-check-token-missing',
        );
      }
      final response = await _postTransport(
        configuration.operationUri('complete'),
        headers: Map<String, String>.unmodifiable(<String, String>{
          'content-type': 'application/json; charset=utf-8',
          'X-Firebase-AppCheck': appCheckToken,
        }),
        body: Map<String, Object?>.unmodifiable(<String, Object?>{
          'callbackUri': brokerCallbackUri.toString(),
        }),
      );
      final envelope = _normalizeEnvelope(response);
      if (envelope == null) {
        return _result(
          BrokeredPublicAuthOutcome.providerFailure,
          safeCode: 'auth-broker-response-invalid',
        );
      }
      if (envelope.error case final error?) {
        return _result(
          _outcomeForBrokerError(error.code),
          safeCode: _safeCodeForBrokerError(error.code),
        );
      }
      final customToken = _normalizeCustomToken(envelope.data);
      if (customToken == null) {
        return _result(
          BrokeredPublicAuthOutcome.providerFailure,
          safeCode: 'auth-custom-token-invalid',
        );
      }
      final userId = await _firebaseCustomTokenSignIn(customToken);
      if (userId == null || !_isSafeUserId(userId)) {
        return _result(
          BrokeredPublicAuthOutcome.providerFailure,
          safeCode: 'auth-firebase-session-missing',
        );
      }
      return _result(
        BrokeredPublicAuthOutcome.authenticated,
        userId: userId,
        safeCode: 'auth-firebase-custom-token-complete',
      );
    });
  }

  Future<BrokeredPublicAuthResult> _guard(
    Future<BrokeredPublicAuthResult> Function() operation,
  ) async {
    try {
      return await operation().timeout(_operationTimeout);
    } on TimeoutException {
      return _result(BrokeredPublicAuthOutcome.timeout);
    } on PublicAuthDependencyException catch (error) {
      return _result(
        _outcomeForDependencyFailure(error.failure),
        safeCode: _safeCodeForDependencyFailure(error.failure),
      );
    } on Object {
      return _result(
        BrokeredPublicAuthOutcome.providerFailure,
        safeCode: 'auth-broker-unexpected',
      );
    }
  }

  BrokeredPublicAuthResult _result(
    BrokeredPublicAuthOutcome outcome, {
    String? userId,
    String? safeCode,
  }) {
    final label = configuration.providerLabel;
    final message = switch (outcome) {
      BrokeredPublicAuthOutcome.browserOpened =>
        '$label sign-in opened in your browser.',
      BrokeredPublicAuthOutcome.authenticated => '$label sign-in completed.',
      BrokeredPublicAuthOutcome.cancelled => '$label sign-in was cancelled.',
      BrokeredPublicAuthOutcome.denied =>
        '$label did not authorize sign-in. Review the request and try again.',
      BrokeredPublicAuthOutcome.expired =>
        'This $label sign-in attempt expired. Start again.',
      BrokeredPublicAuthOutcome.replayRejected =>
        'This $label sign-in return was already used. Start again.',
      BrokeredPublicAuthOutcome.accountIneligible =>
        'This account is not eligible for $label sign-in. Choose another method.',
      BrokeredPublicAuthOutcome.configurationFailure =>
        '$label sign-in is not available right now. Choose another method.',
      BrokeredPublicAuthOutcome.networkFailure =>
        '$label sign-in could not connect. Check your connection and try again.',
      BrokeredPublicAuthOutcome.timeout =>
        '$label sign-in took too long. Please try again.',
      BrokeredPublicAuthOutcome.providerFailure =>
        '$label sign-in could not be completed. Please try again.',
    };
    return BrokeredPublicAuthResult._(
      outcome,
      message,
      userId: userId,
      safeCode: safeCode,
    );
  }
}

final class _BrokerEnvelope {
  const _BrokerEnvelope.success(this.data) : error = null;
  const _BrokerEnvelope.failure(this.error) : data = null;

  final Map<String, Object?>? data;
  final _BrokerError? error;
}

final class _BrokerError {
  const _BrokerError(this.code);

  final String code;
}

final class _BeginData {
  const _BeginData(this.uri, this.expiresAt);

  final Uri uri;
  final DateTime expiresAt;
}

_BrokerEnvelope? _normalizeEnvelope(PublicAuthHttpResponse response) {
  if (response.body.isEmpty || response.body.length > 16384) return null;
  Object? decoded;
  try {
    decoded = jsonDecode(response.body);
  } on FormatException {
    return null;
  }
  final object = _stringMap(decoded);
  if (object == null || object['ok'] is! bool) return null;
  if (object['ok'] == true) {
    if (response.statusCode != 200 || !_hasExactKeys(object, {'ok', 'data'})) {
      return null;
    }
    final data = _stringMap(object['data']);
    return data == null ? null : _BrokerEnvelope.success(data);
  }
  if (response.statusCode < 400 ||
      response.statusCode > 599 ||
      !_hasExactKeys(object, {'ok', 'error'})) {
    return null;
  }
  final error = _stringMap(object['error']);
  if (error == null ||
      !_hasExactKeys(error, {'code', 'message', 'retryable'})) {
    return null;
  }
  final code = error['code'];
  final message = error['message'];
  if (code is! String ||
      !_brokerErrorCodes.contains(code) ||
      message is! String ||
      message.isEmpty ||
      message.length > 256 ||
      message.contains('\n') ||
      message.contains('\r') ||
      error['retryable'] is! bool) {
    return null;
  }
  return _BrokerEnvelope.failure(_BrokerError(code));
}

_BeginData? _normalizeBeginData(Map<String, Object?>? data, DateTime now) {
  if (data == null || !_hasExactKeys(data, {'authorizationUrl', 'expiresAt'})) {
    return null;
  }
  final authorizationUrl = data['authorizationUrl'];
  final expiresAtText = data['expiresAt'];
  if (authorizationUrl is! String ||
      authorizationUrl.isEmpty ||
      authorizationUrl.length > 4096 ||
      expiresAtText is! String ||
      !expiresAtText.endsWith('Z')) {
    return null;
  }
  final authorizationUri = Uri.tryParse(authorizationUrl);
  final expiresAt = DateTime.tryParse(expiresAtText)?.toUtc();
  if (authorizationUri == null ||
      expiresAt == null ||
      !expiresAt.isAfter(now) ||
      expiresAt.difference(now) > const Duration(minutes: 15)) {
    return null;
  }
  return _BeginData(authorizationUri, expiresAt);
}

String? _normalizeCustomToken(Map<String, Object?>? data) {
  if (data == null || !_hasExactKeys(data, {'firebaseCustomToken'})) {
    return null;
  }
  final value = data['firebaseCustomToken'];
  if (value is! String ||
      value.length > 8192 ||
      !RegExp(r'^[A-Za-z0-9_-]+(?:[.][A-Za-z0-9_-]+){2}$').hasMatch(value)) {
    return null;
  }
  return value;
}

Map<String, Object?>? _stringMap(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) return null;
  return Map<String, Object?>.unmodifiable(
    value.map((key, item) => MapEntry(key as String, item)),
  );
}

bool _hasExactKeys(Map<String, Object?> value, Set<String> expected) =>
    value.length == expected.length && value.keys.every(expected.contains);

BrokeredPublicAuthOutcome _outcomeForBrokerError(String code) => switch (code) {
  'authorization_denied' => BrokeredPublicAuthOutcome.denied,
  'attempt_expired' => BrokeredPublicAuthOutcome.expired,
  'attempt_not_found' ||
  'attempt_replayed' => BrokeredPublicAuthOutcome.replayRejected,
  'account_ineligible' => BrokeredPublicAuthOutcome.accountIneligible,
  'app_check_required' => BrokeredPublicAuthOutcome.configurationFailure,
  _ => BrokeredPublicAuthOutcome.providerFailure,
};

String _safeCodeForBrokerError(String code) => switch (code) {
  'authorization_denied' => 'auth-authorization-denied',
  'attempt_expired' => 'auth-expired-credential',
  'attempt_not_found' || 'attempt_replayed' => 'auth-replay-rejected',
  'account_ineligible' => 'auth-account-ineligible',
  'app_check_required' => 'auth-app-check-required',
  'provider_unavailable' => 'auth-provider-unavailable',
  'identity_unavailable' => 'auth-identity-unavailable',
  'token_issue_failed' => 'auth-token-issue-failed',
  'revocation_failed' => 'auth-revocation-failed',
  'invalid_request' => 'auth-broker-invalid-request',
  'internal' => 'auth-broker-internal',
  _ => 'auth-broker-unclassified',
};

BrokeredPublicAuthOutcome _outcomeForDependencyFailure(
  PublicAuthDependencyFailure failure,
) => switch (failure) {
  PublicAuthDependencyFailure.cancelled => BrokeredPublicAuthOutcome.cancelled,
  PublicAuthDependencyFailure.configuration =>
    BrokeredPublicAuthOutcome.configurationFailure,
  PublicAuthDependencyFailure.network =>
    BrokeredPublicAuthOutcome.networkFailure,
  PublicAuthDependencyFailure.timeout => BrokeredPublicAuthOutcome.timeout,
  PublicAuthDependencyFailure.provider =>
    BrokeredPublicAuthOutcome.providerFailure,
  PublicAuthDependencyFailure.appCheckConfiguration =>
    BrokeredPublicAuthOutcome.configurationFailure,
  PublicAuthDependencyFailure.appCheckNetwork =>
    BrokeredPublicAuthOutcome.networkFailure,
  PublicAuthDependencyFailure.appCheckTimeout =>
    BrokeredPublicAuthOutcome.timeout,
  PublicAuthDependencyFailure.browserUnavailable =>
    BrokeredPublicAuthOutcome.configurationFailure,
  PublicAuthDependencyFailure.browserTimeout =>
    BrokeredPublicAuthOutcome.timeout,
  PublicAuthDependencyFailure.firebaseCredential =>
    BrokeredPublicAuthOutcome.providerFailure,
  PublicAuthDependencyFailure.firebaseNetwork =>
    BrokeredPublicAuthOutcome.networkFailure,
  PublicAuthDependencyFailure.firebaseTimeout =>
    BrokeredPublicAuthOutcome.timeout,
};

String _safeCodeForDependencyFailure(PublicAuthDependencyFailure failure) =>
    switch (failure) {
      PublicAuthDependencyFailure.cancelled => 'auth-cancelled',
      PublicAuthDependencyFailure.configuration => 'auth-client-configuration',
      PublicAuthDependencyFailure.network => 'auth-network',
      PublicAuthDependencyFailure.timeout => 'auth-timeout',
      PublicAuthDependencyFailure.provider => 'auth-provider-dependency',
      PublicAuthDependencyFailure.appCheckConfiguration =>
        'auth-app-check-configuration',
      PublicAuthDependencyFailure.appCheckNetwork => 'auth-app-check-network',
      PublicAuthDependencyFailure.appCheckTimeout => 'auth-app-check-timeout',
      PublicAuthDependencyFailure.browserUnavailable =>
        'auth-browser-unavailable',
      PublicAuthDependencyFailure.browserTimeout => 'auth-browser-timeout',
      PublicAuthDependencyFailure.firebaseCredential =>
        'auth-firebase-custom-token',
      PublicAuthDependencyFailure.firebaseNetwork => 'auth-firebase-network',
      PublicAuthDependencyFailure.firebaseTimeout => 'auth-firebase-timeout',
    };

const _brokerErrorCodes = <String>{
  'invalid_request',
  'app_check_required',
  'attempt_not_found',
  'attempt_expired',
  'attempt_replayed',
  'authorization_denied',
  'account_ineligible',
  'provider_unavailable',
  'identity_unavailable',
  'token_issue_failed',
  'revocation_failed',
  'internal',
};

typedef XOAuth2PkceNetworkOutcome = BrokeredPublicAuthOutcome;
typedef XOAuth2PkceNetworkResult = BrokeredPublicAuthResult;

final class XOAuth2PkceNetworkAdapter {
  factory XOAuth2PkceNetworkAdapter({
    required Uri authApiBaseUri,
    required Uri callbackUri,
    required Uri authorizationEndpoint,
    required PublicAuthAppCheckTokenSupplier appCheckTokenSupplier,
    required PublicAuthJsonPostTransport postTransport,
    required PublicAuthExternalUrlLauncher externalUrlLauncher,
    required PublicAuthFirebaseCustomTokenSignIn firebaseCustomTokenSignIn,
    PublicAuthNetworkClock? clock,
    Duration operationTimeout = const Duration(seconds: 70),
  }) {
    final configuration = BrokeredPublicAuthConfiguration(
      providerLabel: 'X',
      operationPath: 'x',
      authApiBaseUri: authApiBaseUri,
      callbackUri: callbackUri,
      authorizationEndpoint: authorizationEndpoint,
    );
    return XOAuth2PkceNetworkAdapter._(
      BrokeredPublicAuthNetworkAdapter(
        configuration: configuration,
        appCheckTokenSupplier: appCheckTokenSupplier,
        postTransport: postTransport,
        externalUrlLauncher: externalUrlLauncher,
        firebaseCustomTokenSignIn: firebaseCustomTokenSignIn,
        authorizationUriValidator: (uri) =>
            _isValidXAuthorizationUri(uri, configuration),
        clock: clock,
        operationTimeout: operationTimeout,
      ),
    );
  }

  const XOAuth2PkceNetworkAdapter._(this._delegate);

  final BrokeredPublicAuthNetworkAdapter _delegate;

  Future<XOAuth2PkceNetworkResult> beginAuthorization() =>
      _delegate.beginAuthorization();

  bool recognizesCallback(Uri callbackUri) =>
      _delegate.recognizesCallback(callbackUri);

  Future<XOAuth2PkceNetworkResult> completeForegroundCallback(
    Uri callbackUri,
  ) => _delegate.completeForegroundCallback(callbackUri);

  Future<XOAuth2PkceNetworkResult> completeColdStartCallback(Uri callbackUri) =>
      _delegate.completeColdStartCallback(callbackUri);

  @override
  String toString() => 'XOAuth2PkceNetworkAdapter(redacted)';
}

bool _isValidXAuthorizationUri(
  Uri uri,
  BrokeredPublicAuthConfiguration configuration,
) {
  if (!_sameUriBase(uri, configuration.authorizationEndpoint) ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      !_hasExactKeys(Map<String, Object?>.from(uri.queryParametersAll), {
        'response_type',
        'client_id',
        'redirect_uri',
        'scope',
        'state',
        'code_challenge',
        'code_challenge_method',
      })) {
    return false;
  }
  final responseType = _singleQueryValue(uri, 'response_type');
  final clientId = _singleQueryValue(uri, 'client_id');
  final redirectUri = _singleQueryValue(uri, 'redirect_uri');
  final scope = _singleQueryValue(uri, 'scope');
  final state = _singleQueryValue(uri, 'state');
  final challenge = _singleQueryValue(uri, 'code_challenge');
  final method = _singleQueryValue(uri, 'code_challenge_method');
  return responseType == 'code' &&
      clientId != null &&
      clientId.isNotEmpty &&
      clientId.length <= 256 &&
      clientId == clientId.trim() &&
      !RegExp(r'\s').hasMatch(clientId) &&
      redirectUri == configuration.callbackUri.toString() &&
      scope == 'tweet.read users.read' &&
      state != null &&
      RegExp(r'^[A-Za-z0-9_-]{32,512}$').hasMatch(state) &&
      challenge != null &&
      RegExp(r'^[A-Za-z0-9_-]{43,128}$').hasMatch(challenge) &&
      method == 'S256';
}

String? _singleQueryValue(Uri uri, String name) {
  final values = uri.queryParametersAll[name];
  return values?.length == 1 ? values!.single : null;
}

bool _isSecureBase(Uri value) =>
    value.scheme == 'https' &&
    value.host.isNotEmpty &&
    value.userInfo.isEmpty &&
    !value.hasQuery &&
    !value.hasFragment &&
    value.pathSegments.every((segment) => segment != '.' && segment != '..');

bool _isCallbackBase(Uri value) =>
    value.isAbsolute &&
    value.scheme.isNotEmpty &&
    (value.host.isNotEmpty || value.path.isNotEmpty) &&
    value.userInfo.isEmpty &&
    !value.hasQuery &&
    !value.hasFragment;

bool _isExactCallback(Uri value, Uri expected) =>
    value.userInfo.isEmpty &&
    !value.hasFragment &&
    _sameUriBase(value, expected);

bool _sameUriBase(Uri left, Uri right) =>
    _queryAndFragmentFreeBase(left).toString() ==
    _queryAndFragmentFreeBase(right).toString();

Uri _queryAndFragmentFreeBase(Uri value) => Uri(
  scheme: value.scheme,
  userInfo: value.userInfo,
  host: value.host,
  port: value.hasPort ? value.port : null,
  path: value.path,
);

bool _isOpaqueCredential(String value) =>
    value.isNotEmpty &&
    value.length <= 8192 &&
    value == value.trim() &&
    !RegExp(r'\s').hasMatch(value);

bool _isSafeUserId(String value) =>
    value.isNotEmpty &&
    value.length <= 128 &&
    value == value.trim() &&
    value.codeUnits.every((unit) => unit >= 33 && unit != 127);

DateTime _utcNow() => DateTime.now().toUtc();
