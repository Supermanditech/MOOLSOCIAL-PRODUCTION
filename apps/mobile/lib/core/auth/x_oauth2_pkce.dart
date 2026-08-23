import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;

typedef XOAuth2Clock = DateTime Function();
typedef XOAuth2RandomBytes = List<int> Function(int length);

enum XAuthorizationStartOutcome { ready, attemptAlreadyActive }

enum XAuthorizationCallbackOutcome {
  tokenExchangeReady,
  cancelled,
  denied,
  wrongState,
  wrongRedirect,
  duplicateCallback,
  expiredAttempt,
  providerFailure,
  invalidResponse,
  noActiveAttempt,
}

final class XOAuth2PkceConfiguration {
  XOAuth2PkceConfiguration({
    required this.clientId,
    required this.redirectUri,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.revocationEndpoint,
    this.attemptLifetime = const Duration(minutes: 10),
  }) {
    if (clientId.isEmpty || clientId != clientId.trim()) {
      throw ArgumentError.value(
        clientId,
        'clientId',
        'Invalid public client ID.',
      );
    }
    _validateRedirect(redirectUri);
    _validateEndpoint(authorizationEndpoint, 'authorizationEndpoint');
    _validateEndpoint(tokenEndpoint, 'tokenEndpoint');
    _validateEndpoint(revocationEndpoint, 'revocationEndpoint');
    if (attemptLifetime <= Duration.zero ||
        attemptLifetime > const Duration(minutes: 15)) {
      throw ArgumentError.value(
        attemptLifetime,
        'attemptLifetime',
        'Attempt lifetime must be between zero and 15 minutes.',
      );
    }
  }

  final String clientId;
  final Uri redirectUri;
  final Uri authorizationEndpoint;
  final Uri tokenEndpoint;
  final Uri revocationEndpoint;
  final Duration attemptLifetime;

  List<String> get scopes => const <String>['tweet.read', 'users.read'];

  static void _validateRedirect(Uri value) {
    if (!value.isAbsolute ||
        value.scheme.isEmpty ||
        (value.host.isEmpty && value.path.isEmpty) ||
        value.hasQuery ||
        value.hasFragment ||
        value.userInfo.isNotEmpty) {
      throw ArgumentError.value(
        value,
        'redirectUri',
        'Invalid exact redirect URI.',
      );
    }
  }

  static void _validateEndpoint(Uri value, String name) {
    if (value.scheme != 'https' ||
        value.host.isEmpty ||
        value.userInfo.isNotEmpty ||
        value.hasQuery ||
        value.hasFragment) {
      throw ArgumentError.value(value, name, 'Invalid HTTPS endpoint.');
    }
  }

  @override
  String toString() => 'XOAuth2PkceConfiguration(redacted)';
}

final class XAuthorizationRequest {
  const XAuthorizationRequest._({
    required this.authorizationUri,
    required this.expiresAt,
    required this.scopes,
  });

  final Uri authorizationUri;
  final DateTime expiresAt;
  final List<String> scopes;

  @override
  String toString() => 'XAuthorizationRequest(redacted)';
}

final class XAuthorizationStartResult {
  const XAuthorizationStartResult._(this.outcome, this.request);

  final XAuthorizationStartOutcome outcome;
  final XAuthorizationRequest? request;

  @override
  String toString() => 'XAuthorizationStartResult(outcome: ${outcome.name})';
}

final class XTokenExchangeRequestDescription {
  const XTokenExchangeRequestDescription._(this.endpoint);

  final Uri endpoint;
  String get method => 'POST';
  String get contentType => 'application/x-www-form-urlencoded';
  List<String> get requiredFormFields => const <String>[
    'grant_type',
    'code',
    'redirect_uri',
    'code_verifier',
    'client_id',
  ];
  bool get includesClientSecret => false;
  bool get executesNetwork => false;
  bool get persistsCredentials => false;

  @override
  String toString() => 'XTokenExchangeRequestDescription(redacted)';
}

final class XRevocationRequestDescription {
  const XRevocationRequestDescription._(this.endpoint);

  final Uri endpoint;
  String get method => 'POST';
  String get contentType => 'application/x-www-form-urlencoded';
  List<String> get requiredFormFields => const <String>['token', 'client_id'];
  List<String> get optionalFormFields => const <String>['token_type_hint'];
  bool get includesClientSecret => false;
  bool get executesNetwork => false;
  bool get persistsToken => false;

  @override
  String toString() => 'XRevocationRequestDescription(redacted)';
}

final class XAuthorizationCodeGrant {
  XAuthorizationCodeGrant._({
    required String authorizationCode,
    required String codeVerifier,
    required Uri redirectUri,
    required String clientId,
  }) : formFields = Map<String, String>.unmodifiable(<String, String>{
         'grant_type': 'authorization_code',
         'code': authorizationCode,
         'redirect_uri': redirectUri.toString(),
         'code_verifier': codeVerifier,
         'client_id': clientId,
       });

  final Map<String, String> formFields;
  bool get isTransient => true;
  bool get mayBePersisted => false;

  @override
  String toString() => 'XAuthorizationCodeGrant(redacted)';
}

final class XAuthorizationCallbackResult {
  const XAuthorizationCallbackResult._(this.outcome, [this.exchangeGrant]);

  final XAuthorizationCallbackOutcome outcome;
  final XAuthorizationCodeGrant? exchangeGrant;

  bool get isTokenExchangeReady =>
      outcome == XAuthorizationCallbackOutcome.tokenExchangeReady;

  @override
  String toString() =>
      'XAuthorizationCallbackResult(outcome: ${outcome.name}, data: redacted)';
}

final class XOAuth2PkceContract {
  XOAuth2PkceContract(
    this.configuration, {
    XOAuth2Clock? clock,
    XOAuth2RandomBytes? randomBytes,
  }) : _clock = clock ?? _systemUtcNow,
       _randomBytes = randomBytes ?? _systemSecureRandomBytes;

  final XOAuth2PkceConfiguration configuration;
  final XOAuth2Clock _clock;
  final XOAuth2RandomBytes _randomBytes;
  final List<String> _consumedStateDigests = <String>[];
  _XAuthorizationAttempt? _activeAttempt;

  XTokenExchangeRequestDescription get tokenExchangeRequest =>
      XTokenExchangeRequestDescription._(configuration.tokenEndpoint);

  XRevocationRequestDescription get revocationRequest =>
      XRevocationRequestDescription._(configuration.revocationEndpoint);

  XAuthorizationStartResult beginAuthorization() {
    final now = _clock().toUtc();
    final current = _activeAttempt;
    if (current != null && now.isBefore(current.expiresAt)) {
      return const XAuthorizationStartResult._(
        XAuthorizationStartOutcome.attemptAlreadyActive,
        null,
      );
    }
    if (current != null) {
      _consume(current);
    }

    final state = _randomBase64Url(32);
    final verifier = _randomBase64Url(64);
    final expiresAt = now.add(configuration.attemptLifetime);
    _activeAttempt = _XAuthorizationAttempt(
      state: state,
      verifier: verifier,
      expiresAt: expiresAt,
    );
    final scopes = configuration.scopes;
    final request = XAuthorizationRequest._(
      authorizationUri:
          _queryAndFragmentFreeBase(
            configuration.authorizationEndpoint,
          ).replace(
            queryParameters: <String, String>{
              'response_type': 'code',
              'client_id': configuration.clientId,
              'redirect_uri': configuration.redirectUri.toString(),
              'scope': scopes.join(' '),
              'state': state,
              'code_challenge': createS256Challenge(verifier),
              'code_challenge_method': 'S256',
            },
          ),
      expiresAt: expiresAt,
      scopes: scopes,
    );
    return XAuthorizationStartResult._(
      XAuthorizationStartOutcome.ready,
      request,
    );
  }

  XAuthorizationCallbackResult completeCallback(Uri callbackUri) {
    if (!_isExactRedirect(callbackUri)) {
      final current = _activeAttempt;
      if (current != null) {
        _consume(current);
      }
      return const XAuthorizationCallbackResult._(
        XAuthorizationCallbackOutcome.wrongRedirect,
      );
    }

    final stateValues =
        callbackUri.queryParametersAll['state'] ?? const <String>[];
    final callbackState = stateValues.length == 1 ? stateValues.single : null;
    if (callbackState != null && _wasConsumed(callbackState)) {
      return const XAuthorizationCallbackResult._(
        XAuthorizationCallbackOutcome.duplicateCallback,
      );
    }

    final current = _activeAttempt;
    if (current == null) {
      return const XAuthorizationCallbackResult._(
        XAuthorizationCallbackOutcome.noActiveAttempt,
      );
    }
    if (!_clock().toUtc().isBefore(current.expiresAt)) {
      _consume(current);
      return const XAuthorizationCallbackResult._(
        XAuthorizationCallbackOutcome.expiredAttempt,
      );
    }
    if (callbackState == null || callbackState.isEmpty) {
      _consume(current);
      return const XAuthorizationCallbackResult._(
        XAuthorizationCallbackOutcome.invalidResponse,
      );
    }
    if (!_constantTimeEquals(callbackState, current.state)) {
      _consume(current);
      return const XAuthorizationCallbackResult._(
        XAuthorizationCallbackOutcome.wrongState,
      );
    }

    _consume(current);
    final codeValues =
        callbackUri.queryParametersAll['code'] ?? const <String>[];
    final errorValues =
        callbackUri.queryParametersAll['error'] ?? const <String>[];
    final hasOneCode = codeValues.length == 1 && codeValues.single.isNotEmpty;
    final hasOneError =
        errorValues.length == 1 && errorValues.single.isNotEmpty;
    if (hasOneCode == hasOneError) {
      return const XAuthorizationCallbackResult._(
        XAuthorizationCallbackOutcome.invalidResponse,
      );
    }
    if (hasOneError) {
      return XAuthorizationCallbackResult._(
        errorValues.single == 'access_denied'
            ? XAuthorizationCallbackOutcome.denied
            : XAuthorizationCallbackOutcome.providerFailure,
      );
    }
    return XAuthorizationCallbackResult._(
      XAuthorizationCallbackOutcome.tokenExchangeReady,
      XAuthorizationCodeGrant._(
        authorizationCode: codeValues.single,
        codeVerifier: current.verifier,
        redirectUri: configuration.redirectUri,
        clientId: configuration.clientId,
      ),
    );
  }

  XAuthorizationCallbackResult cancelAuthorization() {
    final current = _activeAttempt;
    if (current == null) {
      return const XAuthorizationCallbackResult._(
        XAuthorizationCallbackOutcome.noActiveAttempt,
      );
    }
    final expired = !_clock().toUtc().isBefore(current.expiresAt);
    _consume(current);
    return XAuthorizationCallbackResult._(
      expired
          ? XAuthorizationCallbackOutcome.expiredAttempt
          : XAuthorizationCallbackOutcome.cancelled,
    );
  }

  static String createS256Challenge(String verifier) {
    if (!RegExp(r'^[A-Za-z0-9._~-]{43,128}$').hasMatch(verifier)) {
      throw ArgumentError.value(verifier, 'verifier', 'Invalid PKCE verifier.');
    }
    return _withoutPadding(base64Url.encode(_sha256(ascii.encode(verifier))));
  }

  String _randomBase64Url(int length) {
    final bytes = _randomBytes(length);
    if (bytes.length != length ||
        bytes.any((value) => value < 0 || value > 255)) {
      throw StateError('Secure randomness source failed contract.');
    }
    return _withoutPadding(base64Url.encode(bytes));
  }

  bool _isExactRedirect(Uri callbackUri) {
    if (callbackUri.hasFragment) {
      return false;
    }
    return _queryAndFragmentFreeBase(callbackUri).toString() ==
        configuration.redirectUri.toString();
  }

  bool _wasConsumed(String state) {
    final digest = _stateDigest(state);
    return _consumedStateDigests.any(
      (consumed) => _constantTimeEquals(consumed, digest),
    );
  }

  void _consume(_XAuthorizationAttempt attempt) {
    final digest = _stateDigest(attempt.state);
    _consumedStateDigests.remove(digest);
    _consumedStateDigests.add(digest);
    if (_consumedStateDigests.length > 4) {
      _consumedStateDigests.removeAt(0);
    }
    if (identical(_activeAttempt, attempt)) {
      _activeAttempt = null;
    }
  }

  static String _stateDigest(String state) =>
      _withoutPadding(base64Url.encode(_sha256(ascii.encode(state))));
}

final class _XAuthorizationAttempt {
  const _XAuthorizationAttempt({
    required this.state,
    required this.verifier,
    required this.expiresAt,
  });

  final String state;
  final String verifier;
  final DateTime expiresAt;
}

DateTime _systemUtcNow() => DateTime.now().toUtc();

List<int> _systemSecureRandomBytes(int length) {
  final random = Random.secure();
  return List<int>.generate(
    length,
    (_) => random.nextInt(256),
    growable: false,
  );
}

String _withoutPadding(String value) => value.replaceAll('=', '');

Uri _queryAndFragmentFreeBase(Uri value) => Uri(
  scheme: value.scheme,
  userInfo: value.userInfo,
  host: value.host,
  port: value.hasPort ? value.port : null,
  path: value.path,
);

bool _constantTimeEquals(String left, String right) {
  if (left.length != right.length) {
    return false;
  }
  var difference = 0;
  for (var index = 0; index < left.length; index += 1) {
    difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
  }
  return difference == 0;
}

List<int> _sha256(List<int> input) => crypto.sha256.convert(input).bytes;
