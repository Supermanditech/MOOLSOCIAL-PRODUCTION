import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/auth/instagram_oauth_network_adapter.dart';
import 'package:moolsocial/core/auth/x_oauth2_pkce_network_adapter.dart';

final _now = DateTime.utc(2026, 8, 18, 2);
final _apiBase = Uri.parse('https://auth.example.test/moolSocialPublicAuth');
final _callbackBase = Uri.parse('moolsocial://auth/instagram/callback');
final _authorizationEndpoint = Uri.parse(
  'https://instagram.example.test/oauth/authorize',
);
final _state = List<String>.filled(43, 'i').join();
const _customToken = 'synthetic.header.signature';
const _userId = 'synthetic-instagram-firebase-user';

InstagramOAuthNetworkAdapter _adapter({
  required PublicAuthJsonPostTransport transport,
  PublicAuthExternalUrlLauncher? launcher,
  PublicAuthFirebaseCustomTokenSignIn? signIn,
}) {
  return InstagramOAuthNetworkAdapter(
    authApiBaseUri: _apiBase,
    callbackUri: _callbackBase,
    authorizationEndpoint: _authorizationEndpoint,
    appCheckTokenSupplier: () async => 'synthetic-app-check-token',
    postTransport: transport,
    externalUrlLauncher: launcher ?? (_) async => true,
    firebaseCustomTokenSignIn: signIn ?? (_) async => _userId,
    clock: () => _now,
  );
}

PublicAuthHttpResponse _success(Map<String, Object?> data) {
  return PublicAuthHttpResponse(
    statusCode: 200,
    body: jsonEncode(<String, Object?>{'ok': true, 'data': data}),
  );
}

PublicAuthHttpResponse _failure(String code) {
  return PublicAuthHttpResponse(
    statusCode: 400,
    body: jsonEncode(<String, Object?>{
      'ok': false,
      'error': <String, Object?>{
        'code': code,
        'message': 'Synthetic server message.',
        'retryable': false,
      },
    }),
  );
}

Uri _authorizationUri({
  String scope = 'instagram_business_basic',
  String? forceReauth = 'true',
  Uri? endpoint,
  Map<String, String> extras = const {},
}) {
  return (endpoint ?? _authorizationEndpoint).replace(
    queryParameters: <String, String>{
      'response_type': 'code',
      'force_reauth': ?forceReauth,
      'client_id': 'synthetic-instagram-public-client',
      'redirect_uri': _callbackBase.toString(),
      'scope': scope,
      'state': _state,
      ...extras,
    },
  );
}

Map<String, Object?> _beginData(Uri authorizationUri) => <String, Object?>{
  'authorizationUrl': authorizationUri.toString(),
  'expiresAt': _now.add(const Duration(minutes: 10)).toIso8601String(),
};

void main() {
  test(
    'begin uses shared AUTH_API and minimum professional identity scope',
    () async {
      Uri? postedUri;
      Map<String, Object?>? postedBody;
      Uri? launchedUri;
      var launchCalls = 0;
      final expectedAuthorization = _authorizationUri();
      final adapter = _adapter(
        transport: (uri, {required headers, required body}) async {
          postedUri = uri;
          postedBody = body;
          expect(headers.keys, contains('X-Firebase-AppCheck'));
          return _success(_beginData(expectedAuthorization));
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
      expect(postedUri, Uri.parse('$_apiBase/instagram/begin'));
      expect(postedBody, isEmpty);
      expect(launchCalls, 1);
      expect(launchedUri, expectedAuthorization);
    },
  );

  test(
    'begin rejects personal/content scope, wrong endpoint, and extra query',
    () async {
      final responses = <PublicAuthHttpResponse>[
        _success(
          _beginData(
            _authorizationUri(
              scope: 'instagram_business_basic instagram_manage_messages',
            ),
          ),
        ),
        _success(
          _beginData(
            _authorizationUri(
              endpoint: Uri.parse('https://facebook.example.test/authorize'),
            ),
          ),
        ),
        _success(
          _beginData(
            _authorizationUri(extras: const <String, String>{'email': '1'}),
          ),
        ),
        _success(_beginData(_authorizationUri(forceReauth: 'false'))),
        _success(_beginData(_authorizationUri(forceReauth: null))),
      ];
      for (final response in responses) {
        var launchCalls = 0;
        final result = await _adapter(
          transport: (_, {required headers, required body}) async => response,
          launcher: (_) async {
            launchCalls += 1;
            return true;
          },
        ).beginAuthorization();

        expect(result.outcome, BrokeredPublicAuthOutcome.providerFailure);
        expect(result.code, 'auth-authorization-response-invalid');
        expect(launchCalls, 0);
      }
    },
  );

  test(
    'foreground and cold returns share exact callback and Firebase seam',
    () async {
      final callbackBodies = <Map<String, Object?>>[];
      final receivedTokens = <String>[];
      InstagramOAuthNetworkAdapter buildAdapter() => _adapter(
        transport: (uri, {required headers, required body}) async {
          expect(uri, Uri.parse('$_apiBase/instagram/complete'));
          callbackBodies.add(body);
          return _success(<String, Object?>{
            'firebaseCustomToken': _customToken,
          });
        },
        signIn: (token) async {
          receivedTokens.add(token);
          return _userId;
        },
      );
      final foreground = Uri.parse(
        'moolsocial://auth/instagram/callback?code=foreground&state=$_state',
      );
      final cold = Uri.parse(
        'moolsocial://auth/instagram/callback?code=cold&state=$_state',
      );

      final foregroundResult = await buildAdapter().completeForegroundCallback(
        foreground,
      );
      final coldResult = await buildAdapter().completeColdStartCallback(cold);

      expect(foregroundResult.userId, _userId);
      expect(coldResult.userId, _userId);
      expect(foregroundResult.code, 'auth-firebase-custom-token-complete');
      expect(coldResult.code, 'auth-firebase-custom-token-complete');
      expect(callbackBodies, <Map<String, Object?>>[
        <String, Object?>{'callbackUri': foreground.toString()},
        <String, Object?>{'callbackUri': cold.toString()},
      ]);
      expect(receivedTokens, <String>[_customToken, _customToken]);
    },
  );

  test(
    'hosted return bridge is normalized to the exact HTTPS callback',
    () async {
      final providerCallback = Uri.parse(
        'https://moolsocial.com/app/auth/instagram',
      );
      final deliveryCallback = Uri.parse(
        'moolsocial://auth/instagram?code=synthetic-code&state=$_state',
      );
      Map<String, Object?>? postedBody;
      final adapter = InstagramOAuthNetworkAdapter(
        authApiBaseUri: _apiBase,
        callbackUri: providerCallback,
        authorizationEndpoint: _authorizationEndpoint,
        appCheckTokenSupplier: () async => 'synthetic-app-check-token',
        postTransport: (_, {required headers, required body}) async {
          postedBody = body;
          return _success(<String, Object?>{
            'firebaseCustomToken': _customToken,
          });
        },
        externalUrlLauncher: (_) async => true,
        firebaseCustomTokenSignIn: (_) async => _userId,
        clock: () => _now,
      );

      expect(adapter.recognizesCallback(deliveryCallback), isTrue);
      final result = await adapter.completeForegroundCallback(deliveryCallback);

      expect(result.outcome, BrokeredPublicAuthOutcome.authenticated);
      expect(postedBody, <String, Object?>{
        'callbackUri':
            'https://moolsocial.com/app/auth/instagram?code=synthetic-code&state=$_state',
      });
    },
  );

  test(
    'ineligible professional account receives truthful sanitized recovery',
    () async {
      final callback = Uri.parse(
        'moolsocial://auth/instagram/callback?error=ineligible&state=$_state',
      );
      var signInCalls = 0;
      final result = await _adapter(
        transport: (_, {required headers, required body}) async =>
            _failure('account_ineligible'),
        signIn: (_) async {
          signInCalls += 1;
          return _userId;
        },
      ).completeForegroundCallback(callback);

      expect(result.outcome, BrokeredPublicAuthOutcome.accountIneligible);
      expect(result.code, 'auth-account-ineligible');
      expect(result.publicMessage, contains('not eligible'));
      expect(result.publicMessage, isNot(contains('Synthetic server')));
      expect(signInCalls, 0);
    },
  );

  test(
    'wrong callback, replay, and denial fail without private evidence',
    () async {
      var transportCalls = 0;
      final adapter = _adapter(
        transport: (_, {required headers, required body}) async {
          transportCalls += 1;
          return _failure('attempt_replayed');
        },
      );
      final wrong = Uri.parse(
        'moolsocial://auth/facebook/callback?code=private&state=$_state',
      );
      final exact = Uri.parse(
        'moolsocial://auth/instagram/callback?code=private&state=$_state',
      );

      expect(adapter.recognizesCallback(wrong), isFalse);
      final wrongResult = await adapter.completeColdStartCallback(wrong);
      expect(wrongResult.outcome, BrokeredPublicAuthOutcome.providerFailure);
      expect(wrongResult.code, 'auth-callback-origin-invalid');
      final replay = await adapter.completeColdStartCallback(exact);
      expect(replay.outcome, BrokeredPublicAuthOutcome.replayRejected);
      expect(replay.code, 'auth-replay-rejected');
      expect(replay.toString(), isNot(contains('private')));
      expect(transportCalls, 1);

      final denied = await _adapter(
        transport: (_, {required headers, required body}) async =>
            _failure('authorization_denied'),
      ).completeForegroundCallback(exact);
      expect(denied.outcome, BrokeredPublicAuthOutcome.denied);
      expect(denied.code, 'auth-authorization-denied');
    },
  );
}
