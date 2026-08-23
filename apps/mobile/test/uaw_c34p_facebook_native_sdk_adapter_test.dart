import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart' as facebook;
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/auth/facebook_login_contract.dart';
import 'package:moolsocial/core/auth/facebook_native_sdk_adapter.dart';

const _transientFixture = 'synthetic-transient-credential';

final class _FakeNativeLoginClient implements FacebookNativeLoginClient {
  _FakeNativeLoginClient({
    this.isReady = true,
    FacebookNativeLoginResponse? response,
    this.failure,
    this.events,
  }) : response =
           response ??
           FacebookNativeLoginResponse.success(
             transientAccessToken: _transientFixture,
             grantedPermissions: const <String>{'public_profile'},
             declinedPermissions: const <String>{},
           );

  @override
  final bool isReady;
  final FacebookNativeLoginResponse response;
  final Object? failure;
  final List<String>? events;
  int loginCount = 0;
  int logoutCount = 0;
  List<String>? requestedPermissions;

  @override
  Future<FacebookNativeLoginResponse> login({
    required List<String> permissions,
  }) async {
    loginCount += 1;
    requestedPermissions = List<String>.of(permissions);
    final currentFailure = failure;
    if (currentFailure != null) throw currentFailure;
    return response;
  }

  @override
  Future<void> logOut() async {
    logoutCount += 1;
    events?.add('logout');
    final currentFailure = failure;
    if (currentFailure != null) throw currentFailure;
  }
}

final class _FakeCredentialSeam implements FacebookFirebaseCredentialSeam {
  _FakeCredentialSeam({this.isReady = true, this.failure});

  @override
  final bool isReady;
  final Object? failure;
  int callCount = 0;
  bool receivedExpectedTransientCredential = false;

  @override
  Future<void> signInWithTransientAccessToken(
    String transientAccessToken,
  ) async {
    callCount += 1;
    receivedExpectedTransientCredential =
        transientAccessToken == _transientFixture;
    final currentFailure = failure;
    if (currentFailure != null) throw currentFailure;
  }
}

final class _FakeRevocationSeam implements FacebookAccessRevocationSeam {
  _FakeRevocationSeam({this.isReady = true, this.failure, this.events});

  @override
  final bool isReady;
  final Object? failure;
  final List<String>? events;
  int callCount = 0;

  @override
  Future<void> revokeAccess() async {
    callCount += 1;
    events?.add('revoke');
    final currentFailure = failure;
    if (currentFailure != null) throw currentFailure;
  }
}

final class _FakeCurrentAccessTokenSource
    implements FacebookCurrentAccessTokenSource {
  _FakeCurrentAccessTokenSource({
    this.isReady = true,
    this.tokenAvailable = true,
    this.failure,
  });

  @override
  final bool isReady;
  final bool tokenAvailable;
  final Object? failure;
  int useCount = 0;

  @override
  Future<bool> useCurrentAccessToken(
    Future<void> Function(String transientAccessToken) useToken,
  ) async {
    useCount += 1;
    final currentFailure = failure;
    if (currentFailure != null) throw currentFailure;
    if (!tokenAvailable) return false;
    await useToken(_transientFixture);
    return true;
  }
}

final class _FakeGraphDeleteTransport implements FacebookGraphDeleteTransport {
  factory _FakeGraphDeleteTransport({
    bool isReady = true,
    FacebookGraphDeleteResponse? response,
    Object? failure,
    Duration delay = Duration.zero,
  }) {
    return _FakeGraphDeleteTransport._(
      isReady,
      response ??
          FacebookGraphDeleteResponse(
            statusCode: HttpStatus.ok,
            bodyBytes: 'true'.codeUnits,
          ),
      failure,
      delay,
    );
  }

  _FakeGraphDeleteTransport._(
    this.isReady,
    this.response,
    this.failure,
    this.delay,
  );

  @override
  final bool isReady;
  final FacebookGraphDeleteResponse response;
  final Object? failure;
  final Duration delay;
  int callCount = 0;
  bool sawExactEndpoint = false;
  bool sawExactBearerHeader = false;
  bool sawCredentialInEndpoint = false;
  int? maximumResponseBytes;

  @override
  Future<FacebookGraphDeleteResponse> delete({
    required Uri endpoint,
    required String authorizationBearer,
    required int maximumResponseBytes,
  }) async {
    callCount += 1;
    sawExactEndpoint =
        endpoint ==
        Uri.parse('https://graph.facebook.com/v25.0/me/permissions');
    sawExactBearerHeader = authorizationBearer == 'Bearer $_transientFixture';
    sawCredentialInEndpoint = endpoint.toString().contains(_transientFixture);
    this.maximumResponseBytes = maximumResponseBytes;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final currentFailure = failure;
    if (currentFailure != null) throw currentFailure;
    return response;
  }
}

FlutterFacebookNativeSdkAdapter _adapter({
  required _FakeNativeLoginClient nativeClient,
  required _FakeCredentialSeam credentialSeam,
  required _FakeRevocationSeam revocationSeam,
  bool platformConfigurationReady = true,
}) {
  return FlutterFacebookNativeSdkAdapter(
    nativeLoginClient: nativeClient,
    firebaseCredentialSeam: credentialSeam,
    accessRevocationSeam: revocationSeam,
    platformConfigurationReady: platformConfigurationReady,
  );
}

FacebookGraphPermissionRevocationSeam _graphRevocation({
  Uri? endpoint,
  _FakeCurrentAccessTokenSource? accessTokenSource,
  _FakeGraphDeleteTransport? deleteTransport,
  Duration timeout = const Duration(seconds: 1),
}) {
  return FacebookGraphPermissionRevocationSeam(
    endpoint:
        endpoint ??
        Uri.parse('https://graph.facebook.com/v25.0/me/permissions'),
    accessTokenSource: accessTokenSource ?? _FakeCurrentAccessTokenSource(),
    deleteTransport: deleteTransport ?? _FakeGraphDeleteTransport(),
    timeout: timeout,
  );
}

void main() {
  group('Facebook production token projection', () {
    test('preserves authoritative ClassicToken permission evidence', () {
      final response = projectFacebookClassicToken(
        facebook.ClassicToken(
          declinedPermissions: const <String>['email'],
          grantedPermissions: const <String>['public_profile'],
          userId: 'fixture-user',
          expires: DateTime.utc(2030),
          tokenString: _transientFixture,
          applicationId: 'fixture-app',
        ),
      );

      expect(response.status, FacebookNativeLoginStatus.success);
      expect(response.grantedPermissions, const <String>{'public_profile'});
      expect(response.declinedPermissions, const <String>{'email'});
    });

    test('fails closed for null or limited token variants', () {
      expect(
        projectFacebookClassicToken(null).status,
        FacebookNativeLoginStatus.failed,
      );
      expect(
        projectFacebookClassicToken(
          facebook.LimitedToken(
            userId: 'fixture-user',
            userName: 'Fixture',
            userEmail: null,
            nonce: 'fixture-nonce',
            tokenString: _transientFixture,
          ),
        ).status,
        FacebookNativeLoginStatus.failed,
      );
    });
  });

  group('Facebook native readiness and minimum permission', () {
    test(
      'fails closed before every platform and native seam is ready',
      () async {
        final readinessCases =
            <({bool platform, bool native, bool firebase, bool revocation})>[
              (platform: false, native: true, firebase: true, revocation: true),
              (platform: true, native: false, firebase: true, revocation: true),
              (platform: true, native: true, firebase: false, revocation: true),
              (platform: true, native: true, firebase: true, revocation: false),
            ];

        for (final readiness in readinessCases) {
          final nativeClient = _FakeNativeLoginClient(
            isReady: readiness.native,
          );
          final credentialSeam = _FakeCredentialSeam(
            isReady: readiness.firebase,
          );
          final revocationSeam = _FakeRevocationSeam(
            isReady: readiness.revocation,
          );
          final adapter = _adapter(
            nativeClient: nativeClient,
            credentialSeam: credentialSeam,
            revocationSeam: revocationSeam,
            platformConfigurationReady: readiness.platform,
          );

          expect(adapter.isConfigured, isFalse);
          final result = await adapter.signIn();
          expect(result.outcome, FacebookLoginOutcome.configurationUnavailable);
          expect(result.origin, FacebookLoginOrigin.configurationPreflight);
          expect(nativeClient.loginCount, 0);
          expect(credentialSeam.callCount, 0);
        }
      },
    );

    test(
      'requests only public_profile and hands the token directly to Firebase',
      () async {
        final nativeClient = _FakeNativeLoginClient();
        final credentialSeam = _FakeCredentialSeam();
        final adapter = _adapter(
          nativeClient: nativeClient,
          credentialSeam: credentialSeam,
          revocationSeam: _FakeRevocationSeam(),
        );

        final result = await adapter.signIn();
        expect(result.outcome, FacebookLoginOutcome.success);
        expect(result.origin, FacebookLoginOrigin.completed);
        expect(result.safeCode, 'auth-facebook-completed-success');
        expect(nativeClient.requestedPermissions, const <String>[
          'public_profile',
        ]);
        expect(nativeClient.requestedPermissions, isNot(contains('email')));
        expect(credentialSeam.callCount, 1);
        expect(credentialSeam.receivedExpectedTransientCredential, isTrue);
      },
    );

    test(
      'maps native terminal statuses without provider-authored messages',
      () async {
        final cases =
            <
              ({
                FacebookNativeLoginStatus native,
                FacebookLoginOutcome expected,
              })
            >[
              (
                native: FacebookNativeLoginStatus.cancelled,
                expected: FacebookLoginOutcome.cancelled,
              ),
              (
                native: FacebookNativeLoginStatus.denied,
                expected: FacebookLoginOutcome.denied,
              ),
              (
                native: FacebookNativeLoginStatus.failed,
                expected: FacebookLoginOutcome.providerFailure,
              ),
              (
                native: FacebookNativeLoginStatus.operationInProgress,
                expected: FacebookLoginOutcome.operationInProgress,
              ),
            ];

        for (final mapped in cases) {
          final nativeClient = _FakeNativeLoginClient(
            response: FacebookNativeLoginResponse.terminal(mapped.native),
          );
          final credentialSeam = _FakeCredentialSeam();
          final result = await _adapter(
            nativeClient: nativeClient,
            credentialSeam: credentialSeam,
            revocationSeam: _FakeRevocationSeam(),
          ).signIn();

          expect(result.outcome, mapped.expected);
          expect(result.origin, FacebookLoginOrigin.nativeSdk);
          expect(credentialSeam.callCount, 0);
        }
      },
    );

    test('maps missing or declined public_profile to denial', () async {
      final deniedResponses = <FacebookNativeLoginResponse>[
        FacebookNativeLoginResponse.success(
          transientAccessToken: _transientFixture,
          grantedPermissions: const <String>{},
          declinedPermissions: const <String>{},
        ),
        FacebookNativeLoginResponse.success(
          transientAccessToken: _transientFixture,
          grantedPermissions: const <String>{'public_profile'},
          declinedPermissions: const <String>{'public_profile'},
        ),
      ];

      for (final response in deniedResponses) {
        final credentialSeam = _FakeCredentialSeam();
        final result = await _adapter(
          nativeClient: _FakeNativeLoginClient(response: response),
          credentialSeam: credentialSeam,
          revocationSeam: _FakeRevocationSeam(),
        ).signIn();
        expect(result.outcome, FacebookLoginOutcome.denied);
        expect(result.origin, FacebookLoginOrigin.nativeSdk);
        expect(credentialSeam.callCount, 0);
      }
    });
  });

  group('Facebook Firebase failure and account lifecycle mapping', () {
    test(
      'maps Firebase failures through sanitized enumerated outcomes',
      () async {
        final cases = <({String code, FacebookLoginOutcome expected})>[
          (
            code: 'network-request-failed',
            expected: FacebookLoginOutcome.networkUnavailable,
          ),
          (
            code: 'account-exists-with-different-credential',
            expected: FacebookLoginOutcome.accountCollision,
          ),
          (
            code: 'credential-already-in-use',
            expected: FacebookLoginOutcome.accountCollision,
          ),
          (
            code: 'operation-not-allowed',
            expected: FacebookLoginOutcome.configurationUnavailable,
          ),
          (
            code: 'invalid-credential',
            expected: FacebookLoginOutcome.configurationUnavailable,
          ),
          (
            code: 'provider-specific-unmapped-failure',
            expected: FacebookLoginOutcome.firebaseUnclassified,
          ),
        ];

        for (final mapped in cases) {
          final result = await _adapter(
            nativeClient: _FakeNativeLoginClient(),
            credentialSeam: _FakeCredentialSeam(
              failure: FirebaseAuthException(code: mapped.code),
            ),
            revocationSeam: _FakeRevocationSeam(),
          ).signIn();
          expect(result.outcome, mapped.expected);
          expect(result.origin, FacebookLoginOrigin.firebaseCredentialExchange);
          expect(result.safeCode, startsWith('auth-facebook-firebase-'));
        }
      },
    );

    test(
      'maps unexpected native and credential failures without details',
      () async {
        final nativeFailure = await _adapter(
          nativeClient: _FakeNativeLoginClient(failure: StateError('private')),
          credentialSeam: _FakeCredentialSeam(),
          revocationSeam: _FakeRevocationSeam(),
        ).signIn();
        final credentialFailure = await _adapter(
          nativeClient: _FakeNativeLoginClient(),
          credentialSeam: _FakeCredentialSeam(failure: StateError('private')),
          revocationSeam: _FakeRevocationSeam(),
        ).signIn();

        expect(nativeFailure.outcome, FacebookLoginOutcome.providerFailure);
        expect(nativeFailure.origin, FacebookLoginOrigin.nativeSdk);
        expect(
          credentialFailure.outcome,
          FacebookLoginOutcome.firebaseBridgeFailure,
        );
        expect(
          credentialFailure.origin,
          FacebookLoginOrigin.firebaseCredentialExchange,
        );
        expect(nativeFailure.outcome.safeMessage, isNot(contains('private')));
        expect(
          credentialFailure.outcome.safeMessage,
          isNot(contains('private')),
        );
      },
    );

    test(
      'maps platform Firebase codes without exposing platform detail',
      () async {
        const privateDiagnostic = 'private-platform-firebase-detail';
        final result = await _adapter(
          nativeClient: _FakeNativeLoginClient(),
          credentialSeam: _FakeCredentialSeam(
            failure: PlatformException(
              code: 'network-request-failed',
              message: privateDiagnostic,
            ),
          ),
          revocationSeam: _FakeRevocationSeam(),
        ).signIn();

        expect(result.outcome, FacebookLoginOutcome.networkUnavailable);
        expect(result.origin, FacebookLoginOrigin.firebaseCredentialExchange);
        expect(result.safeCode, 'auth-facebook-firebase-network');
        expect(result.outcome.safeMessage, isNot(contains(privateDiagnostic)));
      },
    );

    test('delegates logout and revocation in a deterministic order', () async {
      final events = <String>[];
      final nativeClient = _FakeNativeLoginClient(events: events);
      final revocationSeam = _FakeRevocationSeam(events: events);
      final adapter = _adapter(
        nativeClient: nativeClient,
        credentialSeam: _FakeCredentialSeam(),
        revocationSeam: revocationSeam,
      );

      expect(await adapter.logOut(), FacebookLoginOutcome.success);
      expect(nativeClient.logoutCount, 1);
      events.clear();

      expect(await adapter.revokeAccess(), FacebookLoginOutcome.success);
      expect(revocationSeam.callCount, 1);
      expect(nativeClient.logoutCount, 2);
      expect(events, const <String>['revoke', 'logout']);
    });

    test('sanitizes logout and revocation failures', () async {
      final logoutFailure = await _adapter(
        nativeClient: _FakeNativeLoginClient(failure: StateError('private')),
        credentialSeam: _FakeCredentialSeam(),
        revocationSeam: _FakeRevocationSeam(),
      ).logOut();
      final revocationFailure = await _adapter(
        nativeClient: _FakeNativeLoginClient(),
        credentialSeam: _FakeCredentialSeam(),
        revocationSeam: _FakeRevocationSeam(failure: StateError('private')),
      ).revokeAccess();

      expect(logoutFailure, FacebookLoginOutcome.providerFailure);
      expect(revocationFailure, FacebookLoginOutcome.providerFailure);
    });
  });

  group('Facebook Graph permission revocation', () {
    test('accepts only an exact configured versioned Graph endpoint', () async {
      final invalidEndpoints = <Uri>[
        Uri.parse('http://graph.facebook.com/v25.0/me/permissions'),
        Uri.parse('https://graph.facebook.net/v25.0/me/permissions'),
        Uri.parse('https://graph.facebook.com/me/permissions'),
        Uri.parse('https://graph.facebook.com/v25/me/permissions'),
        Uri.parse('https://graph.facebook.com/v25.0/me/permissions/'),
        Uri.parse(
          'https://graph.facebook.com/v25.0/me/permissions?access_token=blocked',
        ),
        Uri.parse('https://graph.facebook.com/v25.0/me/permissions#blocked'),
      ];

      for (final endpoint in invalidEndpoints) {
        final accessTokenSource = _FakeCurrentAccessTokenSource();
        final deleteTransport = _FakeGraphDeleteTransport();
        final seam = _graphRevocation(
          endpoint: endpoint,
          accessTokenSource: accessTokenSource,
          deleteTransport: deleteTransport,
        );
        expect(seam.isReady, isFalse, reason: endpoint.toString());
        await expectLater(seam.revokeAccess(), throwsStateError);
        expect(accessTokenSource.useCount, 0);
        expect(deleteTransport.callCount, 0);
      }
    });

    test(
      'fails closed before token source or DELETE transport readiness',
      () async {
        final unavailableSources = <FacebookGraphPermissionRevocationSeam>[
          _graphRevocation(
            accessTokenSource: _FakeCurrentAccessTokenSource(isReady: false),
          ),
          _graphRevocation(
            deleteTransport: _FakeGraphDeleteTransport(isReady: false),
          ),
          _graphRevocation(timeout: Duration.zero),
          _graphRevocation(timeout: const Duration(seconds: 31)),
        ];

        for (final seam in unavailableSources) {
          expect(seam.isReady, isFalse);
          await expectLater(seam.revokeAccess(), throwsStateError);
        }
      },
    );

    test(
      'retrieves the SDK token only at action time and sends one Bearer DELETE',
      () async {
        final accessTokenSource = _FakeCurrentAccessTokenSource();
        final deleteTransport = _FakeGraphDeleteTransport();
        final seam = _graphRevocation(
          accessTokenSource: accessTokenSource,
          deleteTransport: deleteTransport,
        );

        expect(accessTokenSource.useCount, 0);
        await seam.revokeAccess();

        expect(accessTokenSource.useCount, 1);
        expect(deleteTransport.callCount, 1);
        expect(deleteTransport.sawExactEndpoint, isTrue);
        expect(deleteTransport.sawExactBearerHeader, isTrue);
        expect(deleteTransport.sawCredentialInEndpoint, isFalse);
        expect(
          deleteTransport.maximumResponseBytes,
          FacebookGraphPermissionRevocationSeam.maximumResponseBytes,
        );
      },
    );

    test('accepts only true or an exact success true object on 2xx', () async {
      final acceptedBodies = <String>['true', '{"success":true}'];
      for (final body in acceptedBodies) {
        final seam = _graphRevocation(
          deleteTransport: _FakeGraphDeleteTransport(
            response: FacebookGraphDeleteResponse(
              statusCode: HttpStatus.ok,
              bodyBytes: body.codeUnits,
            ),
          ),
        );
        await expectLater(seam.revokeAccess(), completes);
      }
    });

    test(
      'does not dispatch DELETE when the SDK has no current token',
      () async {
        final accessTokenSource = _FakeCurrentAccessTokenSource(
          tokenAvailable: false,
        );
        final deleteTransport = _FakeGraphDeleteTransport();
        final seam = _graphRevocation(
          accessTokenSource: accessTokenSource,
          deleteTransport: deleteTransport,
        );

        await expectLater(seam.revokeAccess(), throwsStateError);
        expect(accessTokenSource.useCount, 1);
        expect(deleteTransport.callCount, 0);
      },
    );

    test(
      'rejects non-2xx, oversized, malformed, false, and extra-field bodies',
      () async {
        final rejectedResponses = <FacebookGraphDeleteResponse>[
          FacebookGraphDeleteResponse(
            statusCode: HttpStatus.internalServerError,
            bodyBytes: 'true'.codeUnits,
          ),
          FacebookGraphDeleteResponse(
            statusCode: HttpStatus.multipleChoices,
            bodyBytes: 'true'.codeUnits,
          ),
          FacebookGraphDeleteResponse(
            statusCode: HttpStatus.ok,
            bodyBytes: const <int>[],
          ),
          FacebookGraphDeleteResponse(
            statusCode: HttpStatus.ok,
            bodyBytes: 'false'.codeUnits,
          ),
          FacebookGraphDeleteResponse(
            statusCode: HttpStatus.ok,
            bodyBytes: '{"success":false}'.codeUnits,
          ),
          FacebookGraphDeleteResponse(
            statusCode: HttpStatus.ok,
            bodyBytes: '{"success":true,"extra":true}'.codeUnits,
          ),
          FacebookGraphDeleteResponse(
            statusCode: HttpStatus.ok,
            bodyBytes: 'not-json'.codeUnits,
          ),
          FacebookGraphDeleteResponse(
            statusCode: HttpStatus.ok,
            bodyBytes: List<int>.filled(
              FacebookGraphPermissionRevocationSeam.maximumResponseBytes + 1,
              0x20,
            ),
          ),
        ];

        for (final response in rejectedResponses) {
          final seam = _graphRevocation(
            deleteTransport: _FakeGraphDeleteTransport(response: response),
          );
          await expectLater(seam.revokeAccess(), throwsStateError);
        }
      },
    );

    test(
      'fails closed on timeout and sanitizes source or transport errors',
      () async {
        final timeoutTransport = _FakeGraphDeleteTransport(
          delay: const Duration(milliseconds: 20),
        );
        final seams = <FacebookGraphPermissionRevocationSeam>[
          _graphRevocation(
            deleteTransport: timeoutTransport,
            timeout: const Duration(milliseconds: 1),
          ),
          _graphRevocation(
            accessTokenSource: _FakeCurrentAccessTokenSource(
              failure: StateError('private source detail'),
            ),
          ),
          _graphRevocation(
            deleteTransport: _FakeGraphDeleteTransport(
              failure: StateError('private transport detail'),
            ),
          ),
        ];

        for (final seam in seams) {
          await expectLater(
            seam.revokeAccess(),
            throwsA(
              isA<StateError>().having(
                (error) => error.toString(),
                'sanitized error',
                allOf(
                  isNot(contains('private source detail')),
                  isNot(contains('private transport detail')),
                ),
              ),
            ),
          );
        }
        expect(timeoutTransport.callCount, 1);
      },
    );
  });

  group('Facebook native privacy and dependency containment', () {
    test(
      'does not expose the transient credential through result rendering',
      () {
        final response = FacebookNativeLoginResponse.success(
          transientAccessToken: _transientFixture,
          grantedPermissions: const <String>{'public_profile'},
          declinedPermissions: const <String>{},
        );

        expect(response.toString(), isNot(contains(_transientFixture)));
        expect(
          () => FacebookNativeLoginResponse.terminal(
            FacebookNativeLoginStatus.success,
          ),
          throwsArgumentError,
        );
      },
    );

    test('contains no logging, persistence, account-data, or message reads', () {
      final source = File(
        'lib/core/auth/facebook_native_sdk_adapter.dart',
      ).readAsStringSync();
      const forbiddenTokens = <String>[
        'print(',
        'debugPrint(',
        'developer.log',
        'result.message',
        'getUserData',
        'SharedPreferences',
        'writeAsString',
        'accountIdentifier',
        'accountEmail',
      ];
      for (final token in forbiddenTokens) {
        expect(source, isNot(contains(token)), reason: token);
      }
      expect(source, isNot(contains('access_token=')));
      expect(source, isNot(contains('queryParameters')));
      expect(source, contains('facebook.LoginBehavior.nativeOnly'));
      expect(source, contains('facebookAuth.accessToken'));
      expect(source, contains('HttpHeaders.authorizationHeader'));
      expect(
        source,
        contains("authorizationBearer: 'Bearer \$transientAccessToken'"),
      );
      expect(source, contains(r'^/v[1-9][0-9]*[.][0-9]+/me/permissions$'));
      expect(source, contains('request.followRedirects = false'));
      expect(
        source,
        contains(
          "static const List<String> permissions = <String>['public_profile'];",
        ),
      );
    });

    test('pins flutter_facebook_auth 7.2.0 in manifest and lock', () {
      final manifest = File('pubspec.yaml').readAsStringSync();
      final lock = File('pubspec.lock').readAsStringSync();

      expect(manifest, contains('  flutter_facebook_auth: 7.2.0'));
      expect(
        lock,
        matches(
          RegExp(
            r'  flutter_facebook_auth:\r?\n(?:.*\r?\n){0,10}    version: "7\.2\.0"',
          ),
        ),
      );
    });
  });
}
