import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart' as facebook;

import 'facebook_login_contract.dart';

enum FacebookNativeLoginStatus {
  success,
  cancelled,
  denied,
  failed,
  operationInProgress,
}

final class FacebookNativeLoginResponse {
  FacebookNativeLoginResponse._(
    this.status,
    this._transientAccessToken,
    Set<String> grantedPermissions,
    Set<String> declinedPermissions,
  ) : grantedPermissions = Set<String>.unmodifiable(grantedPermissions),
      declinedPermissions = Set<String>.unmodifiable(declinedPermissions);

  factory FacebookNativeLoginResponse.success({
    required String transientAccessToken,
    required Set<String> grantedPermissions,
    required Set<String> declinedPermissions,
  }) {
    if (transientAccessToken.isEmpty) {
      throw ArgumentError.value(
        transientAccessToken,
        'transientAccessToken',
        'The transient Facebook credential is missing.',
      );
    }
    return FacebookNativeLoginResponse._(
      FacebookNativeLoginStatus.success,
      transientAccessToken,
      grantedPermissions,
      declinedPermissions,
    );
  }

  FacebookNativeLoginResponse.terminal(this.status)
    : _transientAccessToken = null,
      grantedPermissions = const <String>{},
      declinedPermissions = const <String>{} {
    if (status == FacebookNativeLoginStatus.success) {
      throw ArgumentError.value(status, 'status', 'Success requires a token.');
    }
  }

  final FacebookNativeLoginStatus status;
  final String? _transientAccessToken;
  final Set<String> grantedPermissions;
  final Set<String> declinedPermissions;
}

abstract interface class FacebookNativeLoginClient {
  bool get isReady;

  Future<FacebookNativeLoginResponse> login({
    required List<String> permissions,
  });

  Future<void> logOut();
}

abstract interface class FacebookFirebaseCredentialSeam {
  bool get isReady;

  Future<void> signInWithTransientAccessToken(String transientAccessToken);
}

abstract interface class FacebookAccessRevocationSeam {
  bool get isReady;

  Future<void> revokeAccess();
}

abstract interface class FacebookCurrentAccessTokenSource {
  bool get isReady;

  Future<bool> useCurrentAccessToken(
    Future<void> Function(String transientAccessToken) useToken,
  );
}

final class FlutterFacebookCurrentAccessTokenSource
    implements FacebookCurrentAccessTokenSource {
  factory FlutterFacebookCurrentAccessTokenSource({
    required facebook.FacebookAuth facebookAuth,
    required bool nativeSdkReady,
  }) {
    return FlutterFacebookCurrentAccessTokenSource._(
      facebookAuth,
      nativeSdkReady,
    );
  }

  FlutterFacebookCurrentAccessTokenSource._(
    this._facebookAuth,
    this._nativeSdkReady,
  );

  final facebook.FacebookAuth _facebookAuth;
  final bool _nativeSdkReady;

  @override
  bool get isReady => _nativeSdkReady;

  @override
  Future<bool> useCurrentAccessToken(
    Future<void> Function(String transientAccessToken) useToken,
  ) async {
    if (!isReady) return false;
    final accessToken = await _facebookAuth.accessToken;
    final transientAccessToken = accessToken?.tokenString;
    if (transientAccessToken == null || transientAccessToken.isEmpty) {
      return false;
    }
    await useToken(transientAccessToken);
    return true;
  }
}

final class FacebookGraphDeleteResponse {
  FacebookGraphDeleteResponse({
    required this.statusCode,
    required List<int> bodyBytes,
  }) : _bodyBytes = Uint8List.fromList(bodyBytes);

  final int statusCode;
  final Uint8List _bodyBytes;
}

abstract interface class FacebookGraphDeleteTransport {
  bool get isReady;

  Future<FacebookGraphDeleteResponse> delete({
    required Uri endpoint,
    required String authorizationBearer,
    required int maximumResponseBytes,
  });
}

typedef FacebookHttpClientFactory = HttpClient Function();

final class IoFacebookGraphDeleteTransport
    implements FacebookGraphDeleteTransport {
  factory IoFacebookGraphDeleteTransport({
    FacebookHttpClientFactory? clientFactory,
  }) {
    return IoFacebookGraphDeleteTransport._(clientFactory ?? HttpClient.new);
  }

  IoFacebookGraphDeleteTransport._(this._clientFactory);

  final FacebookHttpClientFactory _clientFactory;

  @override
  bool get isReady => true;

  @override
  Future<FacebookGraphDeleteResponse> delete({
    required Uri endpoint,
    required String authorizationBearer,
    required int maximumResponseBytes,
  }) async {
    if (authorizationBearer.isEmpty || maximumResponseBytes < 1) {
      throw StateError('Facebook revocation request is unavailable.');
    }
    final client = _clientFactory();
    try {
      final request = await client.deleteUrl(endpoint);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.authorizationHeader, authorizationBearer);
      final response = await request.close();
      final body = BytesBuilder(copy: false);
      var byteCount = 0;
      await for (final chunk in response) {
        byteCount += chunk.length;
        if (byteCount > maximumResponseBytes) {
          throw StateError('Facebook revocation response is invalid.');
        }
        body.add(chunk);
      }
      return FacebookGraphDeleteResponse(
        statusCode: response.statusCode,
        bodyBytes: body.takeBytes(),
      );
    } finally {
      client.close(force: true);
    }
  }
}

final class FacebookGraphPermissionRevocationSeam
    implements FacebookAccessRevocationSeam {
  factory FacebookGraphPermissionRevocationSeam({
    required Uri endpoint,
    required FacebookCurrentAccessTokenSource accessTokenSource,
    required FacebookGraphDeleteTransport deleteTransport,
    Duration timeout = const Duration(seconds: 10),
  }) {
    return FacebookGraphPermissionRevocationSeam._(
      endpoint,
      accessTokenSource,
      deleteTransport,
      timeout,
    );
  }

  FacebookGraphPermissionRevocationSeam._(
    this._endpoint,
    this._accessTokenSource,
    this._deleteTransport,
    this._timeout,
  );

  static const int maximumResponseBytes = 256;
  static final RegExp _pathPattern = RegExp(
    r'^/v[1-9][0-9]*[.][0-9]+/me/permissions$',
  );

  final Uri _endpoint;
  final FacebookCurrentAccessTokenSource _accessTokenSource;
  final FacebookGraphDeleteTransport _deleteTransport;
  final Duration _timeout;

  @override
  bool get isReady =>
      _isExactEndpoint(_endpoint) &&
      _accessTokenSource.isReady &&
      _deleteTransport.isReady &&
      _timeout > Duration.zero &&
      _timeout <= const Duration(seconds: 30);

  @override
  Future<void> revokeAccess() async {
    if (!isReady) {
      throw StateError('Facebook access revocation is unavailable.');
    }
    try {
      final tokenWasAvailable = await _accessTokenSource.useCurrentAccessToken((
        transientAccessToken,
      ) async {
        final response = await _deleteTransport
            .delete(
              endpoint: _endpoint,
              authorizationBearer: 'Bearer $transientAccessToken',
              maximumResponseBytes: maximumResponseBytes,
            )
            .timeout(_timeout);
        _requireSuccessfulResponse(response);
      });
      if (!tokenWasAvailable) {
        throw StateError('Facebook access revocation is unavailable.');
      }
    } on Object {
      throw StateError('Facebook access revocation did not complete.');
    }
  }

  bool _isExactEndpoint(Uri endpoint) {
    return endpoint.scheme == 'https' &&
        endpoint.host == 'graph.facebook.com' &&
        endpoint.userInfo.isEmpty &&
        !endpoint.hasPort &&
        !endpoint.hasQuery &&
        !endpoint.hasFragment &&
        _pathPattern.hasMatch(endpoint.path) &&
        endpoint.toString() == 'https://graph.facebook.com${endpoint.path}';
  }

  void _requireSuccessfulResponse(FacebookGraphDeleteResponse response) {
    if (response.statusCode < HttpStatus.ok ||
        response.statusCode >= HttpStatus.multipleChoices ||
        response._bodyBytes.isEmpty ||
        response._bodyBytes.length > maximumResponseBytes) {
      throw StateError('Facebook revocation response is invalid.');
    }
    final Object? payload;
    try {
      payload = jsonDecode(
        utf8.decode(response._bodyBytes, allowMalformed: false),
      );
    } on Object {
      throw StateError('Facebook revocation response is invalid.');
    }
    if (payload == true) return;
    if (payload is Map<String, dynamic> &&
        payload.length == 1 &&
        payload['success'] == true) {
      return;
    }
    throw StateError('Facebook revocation response is invalid.');
  }
}

final class FlutterFacebookNativeLoginClient
    implements FacebookNativeLoginClient {
  factory FlutterFacebookNativeLoginClient({
    required facebook.FacebookAuth facebookAuth,
    required bool nativeSdkReady,
  }) {
    return FlutterFacebookNativeLoginClient._(facebookAuth, nativeSdkReady);
  }

  FlutterFacebookNativeLoginClient._(this._facebookAuth, this._nativeSdkReady);

  final facebook.FacebookAuth _facebookAuth;
  final bool _nativeSdkReady;

  @override
  bool get isReady => _nativeSdkReady;

  @override
  Future<FacebookNativeLoginResponse> login({
    required List<String> permissions,
  }) async {
    final result = await _facebookAuth.login(
      permissions: permissions,
      loginBehavior: facebook.LoginBehavior.nativeOnly,
    );
    return switch (result.status) {
      facebook.LoginStatus.success => _successResponse(result.accessToken),
      facebook.LoginStatus.cancelled => FacebookNativeLoginResponse.terminal(
        FacebookNativeLoginStatus.cancelled,
      ),
      facebook.LoginStatus.failed => FacebookNativeLoginResponse.terminal(
        FacebookNativeLoginStatus.failed,
      ),
      facebook.LoginStatus.operationInProgress =>
        FacebookNativeLoginResponse.terminal(
          FacebookNativeLoginStatus.operationInProgress,
        ),
    };
  }

  @override
  Future<void> logOut() => _facebookAuth.logOut();

  FacebookNativeLoginResponse _successResponse(
    facebook.AccessToken? accessToken,
  ) {
    return projectFacebookClassicToken(accessToken);
  }
}

@visibleForTesting
FacebookNativeLoginResponse projectFacebookClassicToken(
  facebook.AccessToken? accessToken,
) {
  if (accessToken is! facebook.ClassicToken ||
      accessToken.tokenString.isEmpty ||
      accessToken.grantedPermissions == null ||
      accessToken.declinedPermissions == null) {
    return FacebookNativeLoginResponse.terminal(
      FacebookNativeLoginStatus.failed,
    );
  }
  return FacebookNativeLoginResponse.success(
    transientAccessToken: accessToken.tokenString,
    grantedPermissions: accessToken.grantedPermissions!.toSet(),
    declinedPermissions: accessToken.declinedPermissions!.toSet(),
  );
}

final class FirebaseFacebookCredentialSeam
    implements FacebookFirebaseCredentialSeam {
  factory FirebaseFacebookCredentialSeam({
    required FirebaseAuth firebaseAuth,
    required bool firebaseReady,
  }) {
    return FirebaseFacebookCredentialSeam._(firebaseAuth, firebaseReady);
  }

  FirebaseFacebookCredentialSeam._(this._firebaseAuth, this._firebaseReady);

  final FirebaseAuth _firebaseAuth;
  final bool _firebaseReady;

  @override
  bool get isReady => _firebaseReady;

  @override
  Future<void> signInWithTransientAccessToken(
    String transientAccessToken,
  ) async {
    if (!isReady || transientAccessToken.isEmpty) {
      throw StateError('Facebook credential exchange is unavailable.');
    }
    final credential = FacebookAuthProvider.credential(transientAccessToken);
    final result = await _firebaseAuth.signInWithCredential(credential);
    if (result.user == null) {
      throw StateError('Facebook credential exchange did not finish.');
    }
  }
}

final class FlutterFacebookNativeSdkAdapter
    implements FacebookNativeSdkAdapter {
  factory FlutterFacebookNativeSdkAdapter({
    required FacebookNativeLoginClient nativeLoginClient,
    required FacebookFirebaseCredentialSeam firebaseCredentialSeam,
    required FacebookAccessRevocationSeam accessRevocationSeam,
    required bool platformConfigurationReady,
  }) {
    return FlutterFacebookNativeSdkAdapter._(
      nativeLoginClient,
      firebaseCredentialSeam,
      accessRevocationSeam,
      platformConfigurationReady,
    );
  }

  FlutterFacebookNativeSdkAdapter._(
    this._nativeLoginClient,
    this._firebaseCredentialSeam,
    this._accessRevocationSeam,
    this._platformConfigurationReady,
  );

  static const List<String> permissions = <String>['public_profile'];

  final FacebookNativeLoginClient _nativeLoginClient;
  final FacebookFirebaseCredentialSeam _firebaseCredentialSeam;
  final FacebookAccessRevocationSeam _accessRevocationSeam;
  final bool _platformConfigurationReady;

  @override
  bool get isConfigured =>
      _platformConfigurationReady &&
      _nativeLoginClient.isReady &&
      _firebaseCredentialSeam.isReady &&
      _accessRevocationSeam.isReady;

  @override
  Future<FacebookLoginResult> signIn() async {
    if (!isConfigured) {
      return const FacebookLoginResult(
        outcome: FacebookLoginOutcome.configurationUnavailable,
        origin: FacebookLoginOrigin.configurationPreflight,
      );
    }
    late final FacebookNativeLoginResponse response;
    try {
      response = await _nativeLoginClient.login(permissions: permissions);
    } on Object {
      return const FacebookLoginResult(
        outcome: FacebookLoginOutcome.providerFailure,
        origin: FacebookLoginOrigin.nativeSdk,
      );
    }
    if (response.status != FacebookNativeLoginStatus.success) {
      final outcome = switch (response.status) {
        FacebookNativeLoginStatus.success =>
          FacebookLoginOutcome.providerFailure,
        FacebookNativeLoginStatus.cancelled => FacebookLoginOutcome.cancelled,
        FacebookNativeLoginStatus.denied => FacebookLoginOutcome.denied,
        FacebookNativeLoginStatus.failed =>
          FacebookLoginOutcome.providerFailure,
        FacebookNativeLoginStatus.operationInProgress =>
          FacebookLoginOutcome.operationInProgress,
      };
      return FacebookLoginResult(
        outcome: outcome,
        origin: FacebookLoginOrigin.nativeSdk,
      );
    }
    try {
      return await _completeSignIn(response);
    } on FirebaseAuthException catch (error) {
      return FacebookLoginResult(
        outcome: _mapFirebaseFailure(error.code),
        origin: FacebookLoginOrigin.firebaseCredentialExchange,
      );
    } on PlatformException catch (error) {
      return FacebookLoginResult(
        outcome: _mapFirebaseFailure(error.code),
        origin: FacebookLoginOrigin.firebaseCredentialExchange,
      );
    } on Object {
      return const FacebookLoginResult(
        outcome: FacebookLoginOutcome.firebaseBridgeFailure,
        origin: FacebookLoginOrigin.firebaseCredentialExchange,
      );
    }
  }

  @override
  Future<FacebookLoginOutcome> logOut() async {
    if (!isConfigured) {
      return FacebookLoginOutcome.configurationUnavailable;
    }
    try {
      await _nativeLoginClient.logOut();
      return FacebookLoginOutcome.success;
    } on Object {
      return FacebookLoginOutcome.providerFailure;
    }
  }

  @override
  Future<FacebookLoginOutcome> revokeAccess() async {
    if (!isConfigured) {
      return FacebookLoginOutcome.configurationUnavailable;
    }
    try {
      await _accessRevocationSeam.revokeAccess();
      await _nativeLoginClient.logOut();
      return FacebookLoginOutcome.success;
    } on Object {
      return FacebookLoginOutcome.providerFailure;
    }
  }

  Future<FacebookLoginResult> _completeSignIn(
    FacebookNativeLoginResponse response,
  ) async {
    if (!response.grantedPermissions.contains('public_profile') ||
        response.declinedPermissions.contains('public_profile')) {
      return const FacebookLoginResult(
        outcome: FacebookLoginOutcome.denied,
        origin: FacebookLoginOrigin.nativeSdk,
      );
    }
    final transientAccessToken = response._transientAccessToken;
    if (transientAccessToken == null || transientAccessToken.isEmpty) {
      return const FacebookLoginResult(
        outcome: FacebookLoginOutcome.providerFailure,
        origin: FacebookLoginOrigin.nativeSdk,
      );
    }
    await _firebaseCredentialSeam.signInWithTransientAccessToken(
      transientAccessToken,
    );
    return const FacebookLoginResult(
      outcome: FacebookLoginOutcome.success,
      origin: FacebookLoginOrigin.completed,
    );
  }

  FacebookLoginOutcome _mapFirebaseFailure(String code) {
    return switch (code.trim().toLowerCase()) {
      'network-request-failed' => FacebookLoginOutcome.networkUnavailable,
      'account-exists-with-different-credential' ||
      'credential-already-in-use' ||
      'email-already-in-use' => FacebookLoginOutcome.accountCollision,
      'operation-not-allowed' ||
      'invalid-credential' ||
      'invalid-oauth-access-token' ||
      'user-disabled' => FacebookLoginOutcome.configurationUnavailable,
      _ => FacebookLoginOutcome.firebaseUnclassified,
    };
  }
}
