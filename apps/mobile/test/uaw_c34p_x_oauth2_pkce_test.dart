import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/auth/x_oauth2_pkce.dart';

const _publicClientFixture = 'public-client-fixture';
final _redirectFixture = Uri.parse('moolsocial-test://oauth/x/callback');
final _authorizationFixture = Uri.parse(
  'https://provider.invalid/oauth2/authorize',
);
final _tokenFixture = Uri.parse('https://provider.invalid/oauth2/token');
final _revocationFixture = Uri.parse('https://provider.invalid/oauth2/revoke');
final _initialTime = DateTime.utc(2026, 8, 18, 0);

void main() {
  group('X OAuth 2.0 authorization-code PKCE contract', () {
    test('matches the RFC 7636 S256 reference vector', () {
      const verifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';

      expect(
        XOAuth2PkceContract.createS256Challenge(verifier),
        'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
      );
    });

    test('builds one exact minimal public-client authorization request', () {
      final random = _SequenceRandom();
      final contract = _contract(random: random);

      final first = contract.beginAuthorization();

      expect(first.outcome, XAuthorizationStartOutcome.ready);
      final request = first.request!;
      final query = request.authorizationUri.queryParameters;
      expect(
        query.keys,
        unorderedEquals(<String>[
          'response_type',
          'client_id',
          'redirect_uri',
          'scope',
          'state',
          'code_challenge',
          'code_challenge_method',
        ]),
      );
      expect(query['response_type'], 'code');
      expect(query['client_id'], _publicClientFixture);
      expect(query['redirect_uri'], _redirectFixture.toString());
      expect(query['scope'], 'tweet.read users.read');
      expect(query['code_challenge_method'], 'S256');
      expect(request.scopes, <String>['tweet.read', 'users.read']);
      expect(
        _queryAndFragmentFreeBase(request.authorizationUri),
        _authorizationFixture,
      );
      expect(request.expiresAt, _initialTime.add(const Duration(minutes: 10)));

      final state = query['state']!;
      final challenge = query['code_challenge']!;
      final expectedVerifier = _base64Url(_bytesFor(64, 1));
      expect(state, hasLength(43));
      expect(state, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
      expect(challenge, hasLength(43));
      expect(challenge, isNot(contains('=')));
      expect(
        challenge,
        XOAuth2PkceContract.createS256Challenge(expectedVerifier),
      );

      final second = contract.beginAuthorization();
      expect(second.outcome, XAuthorizationStartOutcome.attemptAlreadyActive);
      expect(second.request, isNull);
    });

    test('always requests only tweet.read and users.read', () {
      final request = _contract().beginAuthorization().request!;

      expect(request.scopes, <String>['tweet.read', 'users.read']);
      expect(
        request.authorizationUri.queryParameters['scope'],
        'tweet.read users.read',
      );
      expect(request.authorizationUri.toString(), isNot(contains('offline')));
    });

    test('describes token exchange and revocation without executing them', () {
      final contract = _contract();
      final exchange = contract.tokenExchangeRequest;
      final revoke = contract.revocationRequest;

      expect(exchange.endpoint, _tokenFixture);
      expect(exchange.method, 'POST');
      expect(exchange.contentType, 'application/x-www-form-urlencoded');
      expect(exchange.requiredFormFields, <String>[
        'grant_type',
        'code',
        'redirect_uri',
        'code_verifier',
        'client_id',
      ]);
      expect(exchange.includesClientSecret, isFalse);
      expect(exchange.executesNetwork, isFalse);
      expect(exchange.persistsCredentials, isFalse);

      expect(revoke.endpoint, _revocationFixture);
      expect(revoke.method, 'POST');
      expect(revoke.requiredFormFields, <String>['token', 'client_id']);
      expect(revoke.optionalFormFields, <String>['token_type_hint']);
      expect(revoke.includesClientSecret, isFalse);
      expect(revoke.executesNetwork, isFalse);
      expect(revoke.persistsToken, isFalse);
    });

    test('accepts one exact callback and rejects its replay', () {
      final random = _SequenceRandom();
      final contract = _contract(random: random);
      final request = contract.beginAuthorization().request!;
      final callback = _callback(request, code: 'authorization-code-fixture');

      final result = contract.completeCallback(callback);

      expect(result.outcome, XAuthorizationCallbackOutcome.tokenExchangeReady);
      expect(result.isTokenExchangeReady, isTrue);
      final grant = result.exchangeGrant!;
      expect(grant.isTransient, isTrue);
      expect(grant.mayBePersisted, isFalse);
      expect(
        grant.formFields.keys,
        unorderedEquals(<String>[
          'grant_type',
          'code',
          'redirect_uri',
          'code_verifier',
          'client_id',
        ]),
      );
      expect(grant.formFields['grant_type'], 'authorization_code');
      expect(grant.formFields['code'], 'authorization-code-fixture');
      expect(grant.formFields['redirect_uri'], _redirectFixture.toString());
      expect(grant.formFields['code_verifier'], _base64Url(_bytesFor(64, 1)));
      expect(grant.formFields['client_id'], _publicClientFixture);
      expect(grant.formFields, isNot(containsPair('client_secret', anything)));
      expect(grant.toString(), isNot(contains('authorization-code-fixture')));
      expect(result.toString(), isNot(contains('authorization-code-fixture')));

      final replay = contract.completeCallback(callback);
      expect(replay.outcome, XAuthorizationCallbackOutcome.duplicateCallback);
      expect(replay.exchangeGrant, isNull);
    });

    test('a replay cannot consume a newer active attempt', () {
      final contract = _contract(random: _SequenceRandom());
      final first = contract.beginAuthorization().request!;
      final firstCallback = _callback(first, code: 'first-code-fixture');
      expect(
        contract.completeCallback(firstCallback).outcome,
        XAuthorizationCallbackOutcome.tokenExchangeReady,
      );
      final second = contract.beginAuthorization().request!;

      expect(
        contract.completeCallback(firstCallback).outcome,
        XAuthorizationCallbackOutcome.duplicateCallback,
      );
      expect(
        contract
            .completeCallback(_callback(second, code: 'second-code-fixture'))
            .outcome,
        XAuthorizationCallbackOutcome.tokenExchangeReady,
      );
    });

    test('maps cancellation, denial, and provider failure without detail', () {
      final cancelled = _contract();
      cancelled.beginAuthorization();
      expect(
        cancelled.cancelAuthorization().outcome,
        XAuthorizationCallbackOutcome.cancelled,
      );
      expect(
        cancelled.cancelAuthorization().outcome,
        XAuthorizationCallbackOutcome.noActiveAttempt,
      );

      final denied = _contract();
      final deniedRequest = denied.beginAuthorization().request!;
      expect(
        denied
            .completeCallback(_callback(deniedRequest, error: 'access_denied'))
            .outcome,
        XAuthorizationCallbackOutcome.denied,
      );

      final failed = _contract();
      final failedRequest = failed.beginAuthorization().request!;
      final failure = failed.completeCallback(
        _callback(failedRequest, error: 'provider_error_fixture'),
      );
      expect(failure.outcome, XAuthorizationCallbackOutcome.providerFailure);
      expect(failure.toString(), isNot(contains('provider_error_fixture')));
    });

    test(
      'rejects wrong state, redirect, and fragment and consumes attempt',
      () {
        final wrongState = _contract();
        wrongState.beginAuthorization();
        final stateResult = wrongState.completeCallback(
          _redirectFixture.replace(
            queryParameters: <String, String>{
              'state': 'different-state-fixture',
              'code': 'authorization-code-fixture',
            },
          ),
        );
        expect(stateResult.outcome, XAuthorizationCallbackOutcome.wrongState);
        expect(stateResult.exchangeGrant, isNull);

        final wrongRedirect = _contract();
        final redirectRequest = wrongRedirect.beginAuthorization().request!;
        final redirectResult = wrongRedirect.completeCallback(
          _callback(
            redirectRequest,
            code: 'authorization-code-fixture',
            redirect: Uri.parse('moolsocial-test://other/x/callback'),
          ),
        );
        expect(
          redirectResult.outcome,
          XAuthorizationCallbackOutcome.wrongRedirect,
        );

        final fragment = _contract();
        final fragmentRequest = fragment.beginAuthorization().request!;
        final fragmentResult = fragment.completeCallback(
          _callback(
            fragmentRequest,
            code: 'authorization-code-fixture',
          ).replace(fragment: 'rejected-fragment'),
        );
        expect(
          fragmentResult.outcome,
          XAuthorizationCallbackOutcome.wrongRedirect,
        );
      },
    );

    test('expires one attempt and recognizes a later duplicate callback', () {
      var now = _initialTime;
      final contract = _contract(
        clock: () => now,
        attemptLifetime: const Duration(minutes: 1),
      );
      final request = contract.beginAuthorization().request!;
      final callback = _callback(request, code: 'authorization-code-fixture');
      now = _initialTime.add(const Duration(minutes: 1));

      expect(
        contract.completeCallback(callback).outcome,
        XAuthorizationCallbackOutcome.expiredAttempt,
      );
      expect(
        contract.completeCallback(callback).outcome,
        XAuthorizationCallbackOutcome.duplicateCallback,
      );
    });

    test('rejects malformed callback cardinality and missing response', () {
      XAuthorizationCallbackOutcome run(
        Uri Function(XAuthorizationRequest request) callback,
      ) {
        final contract = _contract();
        final request = contract.beginAuthorization().request!;
        return contract.completeCallback(callback(request)).outcome;
      }

      expect(
        run(
          (request) => _callback(
            request,
            code: 'authorization-code-fixture',
            error: 'access_denied',
          ),
        ),
        XAuthorizationCallbackOutcome.invalidResponse,
      );
      expect(
        run(
          (request) => _redirectFixture.replace(
            queryParameters: <String, String>{
              'state': request.authorizationUri.queryParameters['state']!,
            },
          ),
        ),
        XAuthorizationCallbackOutcome.invalidResponse,
      );
      expect(
        run((request) {
          final state = Uri.encodeQueryComponent(
            request.authorizationUri.queryParameters['state']!,
          );
          return Uri.parse(
            '${_redirectFixture.toString()}?state=$state&state=$state&code=fixture',
          );
        }),
        XAuthorizationCallbackOutcome.invalidResponse,
      );
      expect(
        run((request) {
          final state = Uri.encodeQueryComponent(
            request.authorizationUri.queryParameters['state']!,
          );
          return Uri.parse(
            '${_redirectFixture.toString()}?state=$state&code=one&code=two',
          );
        }),
        XAuthorizationCallbackOutcome.invalidResponse,
      );
    });

    test('returns no-active and sanitized printable representations', () {
      final contract = _contract();
      final callback = _redirectFixture.replace(
        queryParameters: <String, String>{
          'state': 'state-fixture',
          'code': 'authorization-code-fixture',
        },
      );

      expect(
        contract.completeCallback(callback).outcome,
        XAuthorizationCallbackOutcome.noActiveAttempt,
      );
      expect(
        contract.configuration.toString(),
        isNot(contains(_publicClientFixture)),
      );
      expect(
        contract.tokenExchangeRequest.toString(),
        isNot(contains('https://')),
      );
      expect(
        contract.revocationRequest.toString(),
        isNot(contains('https://')),
      );
    });

    test('rejects invalid configuration and randomness sources', () {
      XOAuth2PkceConfiguration configuration({
        String clientId = _publicClientFixture,
        Uri? redirect,
        Uri? authorization,
        Duration lifetime = const Duration(minutes: 10),
      }) {
        return XOAuth2PkceConfiguration(
          clientId: clientId,
          redirectUri: redirect ?? _redirectFixture,
          authorizationEndpoint: authorization ?? _authorizationFixture,
          tokenEndpoint: _tokenFixture,
          revocationEndpoint: _revocationFixture,
          attemptLifetime: lifetime,
        );
      }

      expect(() => configuration(clientId: ' padded '), throwsArgumentError);
      expect(
        () => configuration(
          redirect: Uri.parse('moolsocial-test://oauth/x/callback?extra=true'),
        ),
        throwsArgumentError,
      );
      expect(
        () => configuration(
          authorization: Uri.parse('http://provider.invalid/oauth2/authorize'),
        ),
        throwsArgumentError,
      );
      expect(() => configuration(lifetime: Duration.zero), throwsArgumentError);

      final invalidRandom = XOAuth2PkceContract(
        configuration(),
        clock: () => _initialTime,
        randomBytes: (length) => List<int>.filled(length - 1, 0),
      );
      expect(invalidRandom.beginAuthorization, throwsStateError);
      expect(
        () => XOAuth2PkceContract.createS256Challenge('too-short'),
        throwsArgumentError,
      );
    });
  });
}

XOAuth2PkceContract _contract({
  DateTime Function()? clock,
  _SequenceRandom? random,
  Duration attemptLifetime = const Duration(minutes: 10),
}) {
  return XOAuth2PkceContract(
    XOAuth2PkceConfiguration(
      clientId: _publicClientFixture,
      redirectUri: _redirectFixture,
      authorizationEndpoint: _authorizationFixture,
      tokenEndpoint: _tokenFixture,
      revocationEndpoint: _revocationFixture,
      attemptLifetime: attemptLifetime,
    ),
    clock: clock ?? () => _initialTime,
    randomBytes: (random ?? _SequenceRandom()).call,
  );
}

Uri _callback(
  XAuthorizationRequest request, {
  String? code,
  String? error,
  Uri? redirect,
}) {
  return (redirect ?? _redirectFixture).replace(
    queryParameters: <String, String>{
      'state': request.authorizationUri.queryParameters['state']!,
      'code': ?code,
      'error': ?error,
    },
  );
}

final class _SequenceRandom {
  var _invocation = 0;

  List<int> call(int length) {
    final result = _bytesFor(length, _invocation);
    _invocation += 1;
    return result;
  }
}

List<int> _bytesFor(int length, int invocation) => List<int>.generate(
  length,
  (index) => (length + (invocation * 41) + (index * 37)) & 0xff,
  growable: false,
);

String _base64Url(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

Uri _queryAndFragmentFreeBase(Uri value) => Uri(
  scheme: value.scheme,
  userInfo: value.userInfo,
  host: value.host,
  port: value.hasPort ? value.port : null,
  path: value.path,
);
