import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/auth/x_oauth2_pkce_network_adapter.dart';

final _now = DateTime.utc(2026, 8, 18, 2);
final _apiBase = Uri.parse('https://auth.example.test/moolSocialPublicAuth');
final _callbackBase = Uri.parse('moolsocial://auth/x/callback');
final _authorizationEndpoint = Uri.parse(
  'https://provider.example.test/i/oauth2/authorize',
);
const _appCheckToken = 'synthetic-app-check-token';
const _customToken = 'synthetic.header.signature';
const _userId = 'synthetic-firebase-user';
final _state = List<String>.filled(43, 's').join();
final _challenge = List<String>.filled(43, 'c').join();

XOAuth2PkceNetworkAdapter _adapter({
  required PublicAuthJsonPostTransport transport,
  PublicAuthAppCheckTokenSupplier? appCheckTokenSupplier,
  PublicAuthExternalUrlLauncher? launcher,
  PublicAuthFirebaseCustomTokenSignIn? signIn,
  Uri? apiBase,
  Uri? callbackBase,
  Duration operationTimeout = const Duration(seconds: 70),
}) {
  return XOAuth2PkceNetworkAdapter(
    authApiBaseUri: apiBase ?? _apiBase,
    callbackUri: callbackBase ?? _callbackBase,
    authorizationEndpoint: _authorizationEndpoint,
    appCheckTokenSupplier: appCheckTokenSupplier ?? () async => _appCheckToken,
    postTransport: transport,
    externalUrlLauncher: launcher ?? (_) async => true,
    firebaseCustomTokenSignIn: signIn ?? (_) async => _userId,
    clock: () => _now,
    operationTimeout: operationTimeout,
  );
}

PublicAuthHttpResponse _success(Map<String, Object?> data) {
  return PublicAuthHttpResponse(
    statusCode: 200,
    body: jsonEncode(<String, Object?>{'ok': true, 'data': data}),
  );
}

PublicAuthHttpResponse _failure(String code, {bool retryable = false}) {
  return PublicAuthHttpResponse(
    statusCode: 400,
    body: jsonEncode(<String, Object?>{
      'ok': false,
      'error': <String, Object?>{
        'code': code,
        'message': 'Synthetic sanitized failure.',
        'retryable': retryable,
      },
    }),
  );
}

Uri _authorizationUri({Map<String, String> replacements = const {}}) {
  return _authorizationEndpoint.replace(
    queryParameters: <String, String>{
      'response_type': 'code',
      'client_id': 'synthetic-public-client',
      'redirect_uri': _callbackBase.toString(),
      'scope': 'tweet.read users.read',
      'state': _state,
      'code_challenge': _challenge,
      'code_challenge_method': 'S256',
      ...replacements,
    },
  );
}

Map<String, Object?> _beginData({Uri? authorizationUri, DateTime? expiresAt}) {
  return <String, Object?>{
    'authorizationUrl': (authorizationUri ?? _authorizationUri()).toString(),
    'expiresAt': (expiresAt ?? _now.add(const Duration(minutes: 10)))
        .toIso8601String(),
  };
}

void main() {
  test(
    'begin posts only the empty operation and opens one validated URL',
    () async {
      Uri? postedUri;
      Map<String, String>? postedHeaders;
      Map<String, Object?>? postedBody;
      Uri? launchedUri;
      var launchCalls = 0;
      final adapter = _adapter(
        transport: (uri, {required headers, required body}) async {
          postedUri = uri;
          postedHeaders = headers;
          postedBody = body;
          return _success(_beginData());
        },
        launcher: (uri) async {
          launchCalls += 1;
          launchedUri = uri;
          return true;
        },
      );

      final result = await adapter.beginAuthorization();

      expect(result.outcome, BrokeredPublicAuthOutcome.browserOpened);
      expect(result.code, 'auth-browser-opened');
      expect(result.userId, isNull);
      expect(postedUri, Uri.parse('$_apiBase/x/begin'));
      expect(postedBody, isEmpty);
      expect(
        postedHeaders?.keys,
        unorderedEquals(<String>['content-type', 'X-Firebase-AppCheck']),
      );
      expect(postedHeaders?['X-Firebase-AppCheck'], _appCheckToken);
      expect(launchCalls, 1);
      expect(launchedUri, _authorizationUri());
    },
  );

  test('begin rejects non-exact URL, scope, expiry, and data schema', () async {
    final validUri = _authorizationUri();
    final extraQueryUri = validUri.replace(
      queryParameters: <String, String>{
        ...validUri.queryParameters,
        'unexpected': 'value',
      },
    );
    final responses = <PublicAuthHttpResponse>[
      _success(
        _beginData(
          authorizationUri: Uri.parse(
            'https://other.example.test/i/oauth2/authorize?value=1',
          ),
        ),
      ),
      _success(
        _beginData(
          authorizationUri: _authorizationUri(
            replacements: const <String, String>{
              'scope': 'tweet.read users.read offline.access',
            },
          ),
        ),
      ),
      _success(_beginData(authorizationUri: extraQueryUri)),
      _success(_beginData(expiresAt: _now)),
      _success(<String, Object?>{..._beginData(), 'unexpected': true}),
    ];

    for (var index = 0; index < responses.length; index += 1) {
      final response = responses[index];
      var launchCalls = 0;
      final adapter = _adapter(
        transport: (_, {required headers, required body}) async => response,
        launcher: (_) async {
          launchCalls += 1;
          return true;
        },
      );

      final result = await adapter.beginAuthorization();

      expect(result.outcome, BrokeredPublicAuthOutcome.providerFailure);
      expect(
        result.code,
        index < 3
            ? 'auth-authorization-response-invalid'
            : 'auth-broker-begin-invalid',
      );
      expect(launchCalls, 0);
    }
  });

  test('invalid HTTPS base fails closed before dependency access', () async {
    var dependencyCalls = 0;
    final adapter = _adapter(
      apiBase: Uri.parse('http://auth.example.test/function'),
      appCheckTokenSupplier: () async {
        dependencyCalls += 1;
        return _appCheckToken;
      },
      transport: (_, {required headers, required body}) async {
        dependencyCalls += 1;
        return _success(_beginData());
      },
    );

    final result = await adapter.beginAuthorization();

    expect(result.outcome, BrokeredPublicAuthOutcome.configurationFailure);
    expect(result.code, 'auth-client-configuration');
    expect(dependencyCalls, 0);
  });

  test('launcher and dependency failures map to sanitized outcomes', () async {
    final response = _success(_beginData());
    final launcherResult = await _adapter(
      transport: (_, {required headers, required body}) async => response,
      launcher: (_) async => false,
    ).beginAuthorization();
    final networkResult = await _adapter(
      appCheckTokenSupplier: () async =>
          throw const PublicAuthDependencyException(
            PublicAuthDependencyFailure.network,
          ),
      transport: (_, {required headers, required body}) async => response,
    ).beginAuthorization();
    final timeoutResult = await _adapter(
      transport: (_, {required headers, required body}) async =>
          throw TimeoutException('synthetic'),
    ).beginAuthorization();

    expect(
      launcherResult.outcome,
      BrokeredPublicAuthOutcome.configurationFailure,
    );
    expect(launcherResult.code, 'auth-ui-unavailable');
    expect(networkResult.outcome, BrokeredPublicAuthOutcome.networkFailure);
    expect(networkResult.code, 'auth-network');
    expect(timeoutResult.outcome, BrokeredPublicAuthOutcome.timeout);
    expect(timeoutResult.code, 'auth-timeout');
    expect(networkResult.publicMessage, contains('Check your connection'));
    expect(timeoutResult.publicMessage, isNot(contains('synthetic')));
  });

  test('a hung dependency is bounded by the whole-operation timeout', () async {
    final never = Completer<PublicAuthHttpResponse>();
    final result = await _adapter(
      transport: (_, {required headers, required body}) => never.future,
      operationTimeout: const Duration(milliseconds: 10),
    ).beginAuthorization();

    expect(result.outcome, BrokeredPublicAuthOutcome.timeout);
    expect(result.publicMessage, isNot(contains('Completer')));
  });

  test('production dependency stages retain fixed safe codes', () async {
    const cases = <PublicAuthDependencyFailure, String>{
      PublicAuthDependencyFailure.appCheckConfiguration:
          'auth-app-check-configuration',
      PublicAuthDependencyFailure.appCheckNetwork: 'auth-app-check-network',
      PublicAuthDependencyFailure.appCheckTimeout: 'auth-app-check-timeout',
      PublicAuthDependencyFailure.browserUnavailable:
          'auth-browser-unavailable',
      PublicAuthDependencyFailure.browserTimeout: 'auth-browser-timeout',
      PublicAuthDependencyFailure.firebaseCredential:
          'auth-firebase-custom-token',
      PublicAuthDependencyFailure.firebaseNetwork: 'auth-firebase-network',
      PublicAuthDependencyFailure.firebaseTimeout: 'auth-firebase-timeout',
    };

    for (final entry in cases.entries) {
      final result = await _adapter(
        transport: (_, {required headers, required body}) async {
          throw StateError('dependency failure must stop before transport');
        },
        appCheckTokenSupplier: () async =>
            throw PublicAuthDependencyException(entry.key),
      ).beginAuthorization();
      expect(result.code, entry.value, reason: entry.key.name);
      expect(result.publicMessage, isNot(contains(entry.key.name)));
    }
  });

  test(
    'foreground completion sends callback transiently into Firebase seam',
    () async {
      final callback = Uri.parse(
        'moolsocial://auth/x/callback?code=synthetic-code&state=$_state',
      );
      Uri? postedUri;
      Map<String, Object?>? postedBody;
      String? receivedCustomToken;
      final adapter = _adapter(
        transport: (uri, {required headers, required body}) async {
          postedUri = uri;
          postedBody = body;
          return _success(<String, Object?>{
            'firebaseCustomToken': _customToken,
          });
        },
        signIn: (customToken) async {
          receivedCustomToken = customToken;
          return _userId;
        },
      );

      final result = await adapter.completeForegroundCallback(callback);

      expect(result.outcome, BrokeredPublicAuthOutcome.authenticated);
      expect(result.userId, _userId);
      expect(postedUri, Uri.parse('$_apiBase/x/complete'));
      expect(postedBody, <String, Object?>{'callbackUri': callback.toString()});
      expect(receivedCustomToken, _customToken);
    },
  );

  test(
    'hosted return bridge is normalized to the exact HTTPS callback',
    () async {
      final providerCallback = Uri.parse('https://moolsocial.com/app/auth/x');
      final deliveryCallback = Uri.parse(
        'moolsocial://auth/x?code=synthetic-code&state=$_state',
      );
      Map<String, Object?>? postedBody;
      final adapter = _adapter(
        callbackBase: providerCallback,
        transport: (_, {required headers, required body}) async {
          postedBody = body;
          return _success(<String, Object?>{
            'firebaseCustomToken': _customToken,
          });
        },
      );

      expect(adapter.recognizesCallback(deliveryCallback), isTrue);
      final result = await adapter.completeForegroundCallback(deliveryCallback);

      expect(result.outcome, BrokeredPublicAuthOutcome.authenticated);
      expect(postedBody, <String, Object?>{
        'callbackUri':
            'https://moolsocial.com/app/auth/x?code=synthetic-code&state=$_state',
      });
    },
  );

  test('cold and foreground callbacks share exact return validation', () async {
    final acceptedBodies = <Map<String, Object?>>[];
    XOAuth2PkceNetworkAdapter buildAdapter() => _adapter(
      transport: (_, {required headers, required body}) async {
        acceptedBodies.add(body);
        return _success(<String, Object?>{'firebaseCustomToken': _customToken});
      },
    );
    final foreground = Uri.parse(
      'moolsocial://auth/x/callback?code=foreground&state=$_state',
    );
    final cold = Uri.parse(
      'moolsocial://auth/x/callback?code=cold&state=$_state',
    );

    final foregroundResult = await buildAdapter().completeForegroundCallback(
      foreground,
    );
    final coldResult = await buildAdapter().completeColdStartCallback(cold);

    expect(foregroundResult.isAuthenticated, isTrue);
    expect(coldResult.isAuthenticated, isTrue);
    expect(acceptedBodies, <Map<String, Object?>>[
      <String, Object?>{'callbackUri': foreground.toString()},
      <String, Object?>{'callbackUri': cold.toString()},
    ]);
  });

  test('callback recognition rejects every non-exact configured URI', () async {
    var transportCalls = 0;
    final adapter = _adapter(
      transport: (_, {required headers, required body}) async {
        transportCalls += 1;
        return _success(<String, Object?>{'firebaseCustomToken': _customToken});
      },
    );
    final exact = Uri.parse('moolsocial://auth/x/callback?code=one');
    final wrongPath = Uri.parse('moolsocial://auth/x/other?code=one');
    final fragment = Uri.parse('moolsocial://auth/x/callback?code=one#private');

    expect(adapter.recognizesCallback(exact), isTrue);
    expect(adapter.recognizesCallback(wrongPath), isFalse);
    expect(adapter.recognizesCallback(fragment), isFalse);
    expect(
      (await adapter.completeForegroundCallback(wrongPath)).outcome,
      BrokeredPublicAuthOutcome.providerFailure,
    );
    expect(
      (await adapter.completeColdStartCallback(fragment)).outcome,
      BrokeredPublicAuthOutcome.providerFailure,
    );
    expect(transportCalls, 0);
  });

  test('broker failures map without exposing provider messages', () async {
    const cases = <String, ({BrokeredPublicAuthOutcome outcome, String code})>{
      'authorization_denied': (
        outcome: BrokeredPublicAuthOutcome.denied,
        code: 'auth-authorization-denied',
      ),
      'invalid_request': (
        outcome: BrokeredPublicAuthOutcome.providerFailure,
        code: 'auth-broker-invalid-request',
      ),
      'attempt_expired': (
        outcome: BrokeredPublicAuthOutcome.expired,
        code: 'auth-expired-credential',
      ),
      'attempt_not_found': (
        outcome: BrokeredPublicAuthOutcome.replayRejected,
        code: 'auth-replay-rejected',
      ),
      'attempt_replayed': (
        outcome: BrokeredPublicAuthOutcome.replayRejected,
        code: 'auth-replay-rejected',
      ),
      'app_check_required': (
        outcome: BrokeredPublicAuthOutcome.configurationFailure,
        code: 'auth-app-check-required',
      ),
      'account_ineligible': (
        outcome: BrokeredPublicAuthOutcome.accountIneligible,
        code: 'auth-account-ineligible',
      ),
      'provider_unavailable': (
        outcome: BrokeredPublicAuthOutcome.providerFailure,
        code: 'auth-provider-unavailable',
      ),
      'identity_unavailable': (
        outcome: BrokeredPublicAuthOutcome.providerFailure,
        code: 'auth-identity-unavailable',
      ),
      'token_issue_failed': (
        outcome: BrokeredPublicAuthOutcome.providerFailure,
        code: 'auth-token-issue-failed',
      ),
      'revocation_failed': (
        outcome: BrokeredPublicAuthOutcome.providerFailure,
        code: 'auth-revocation-failed',
      ),
      'internal': (
        outcome: BrokeredPublicAuthOutcome.providerFailure,
        code: 'auth-broker-internal',
      ),
    };
    final callback = Uri.parse(
      'moolsocial://auth/x/callback?code=synthetic&state=$_state',
    );
    for (final entry in cases.entries) {
      var signInCalls = 0;
      final adapter = _adapter(
        transport: (_, {required headers, required body}) async =>
            _failure(entry.key),
        signIn: (_) async {
          signInCalls += 1;
          return _userId;
        },
      );

      final result = await adapter.completeForegroundCallback(callback);

      expect(result.outcome, entry.value.outcome, reason: entry.key);
      expect(result.code, entry.value.code, reason: entry.key);
      expect(result.publicMessage, isNot(contains('Synthetic sanitized')));
      expect(signInCalls, 0);
    }
  });

  test(
    'strict response schema rejects malformed or token-bearing extras',
    () async {
      final callback = Uri.parse(
        'moolsocial://auth/x/callback?code=synthetic&state=$_state',
      );
      final responses = <PublicAuthHttpResponse>[
        const PublicAuthHttpResponse(statusCode: 200, body: 'not-json'),
        PublicAuthHttpResponse(
          statusCode: 200,
          body: jsonEncode(<String, Object?>{
            'ok': true,
            'data': <String, Object?>{'firebaseCustomToken': _customToken},
            'unexpected': true,
          }),
        ),
        _success(<String, Object?>{'firebaseCustomToken': 'not-a-jwt'}),
        _success(<String, Object?>{
          'firebaseCustomToken': _customToken,
          'providerToken': 'forbidden',
        }),
      ];
      for (final response in responses) {
        var signInCalls = 0;
        final result = await _adapter(
          transport: (_, {required headers, required body}) async => response,
          signIn: (_) async {
            signInCalls += 1;
            return _userId;
          },
        ).completeForegroundCallback(callback);

        expect(result.outcome, BrokeredPublicAuthOutcome.providerFailure);
        expect(signInCalls, 0);
      }
    },
  );

  test(
    'diagnostic strings redact tokens, callbacks, and Firebase identity',
    () async {
      final response = PublicAuthHttpResponse(
        statusCode: 200,
        body: jsonEncode(<String, Object?>{
          'ok': true,
          'data': <String, Object?>{'firebaseCustomToken': _customToken},
        }),
      );
      final adapter = _adapter(
        transport: (_, {required headers, required body}) async => response,
      );
      final result = await adapter.completeForegroundCallback(
        Uri.parse('moolsocial://auth/x/callback?code=private&state=$_state'),
      );

      expect(response.toString(), isNot(contains(_customToken)));
      expect(adapter.toString(), isNot(contains('private')));
      expect(result.toString(), isNot(contains(_userId)));
      expect(result.toString(), isNot(contains(_customToken)));
    },
  );
}
