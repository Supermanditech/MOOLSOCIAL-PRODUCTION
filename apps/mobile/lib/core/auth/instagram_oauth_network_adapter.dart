import 'x_oauth2_pkce_network_adapter.dart';

typedef InstagramOAuthNetworkOutcome = BrokeredPublicAuthOutcome;
typedef InstagramOAuthNetworkResult = BrokeredPublicAuthResult;

final class InstagramOAuthNetworkAdapter {
  factory InstagramOAuthNetworkAdapter({
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
      providerLabel: 'Instagram',
      operationPath: 'instagram',
      authApiBaseUri: authApiBaseUri,
      callbackUri: callbackUri,
      authorizationEndpoint: authorizationEndpoint,
    );
    return InstagramOAuthNetworkAdapter._(
      BrokeredPublicAuthNetworkAdapter(
        configuration: configuration,
        appCheckTokenSupplier: appCheckTokenSupplier,
        postTransport: postTransport,
        externalUrlLauncher: externalUrlLauncher,
        firebaseCustomTokenSignIn: firebaseCustomTokenSignIn,
        authorizationUriValidator: (uri) =>
            _isValidInstagramAuthorizationUri(uri, configuration),
        clock: clock,
        operationTimeout: operationTimeout,
      ),
    );
  }

  const InstagramOAuthNetworkAdapter._(this._delegate);

  final BrokeredPublicAuthNetworkAdapter _delegate;

  Future<InstagramOAuthNetworkResult> beginAuthorization() =>
      _delegate.beginAuthorization();

  bool recognizesCallback(Uri callbackUri) =>
      _delegate.recognizesCallback(callbackUri);

  Future<InstagramOAuthNetworkResult> completeForegroundCallback(
    Uri callbackUri,
  ) => _delegate.completeForegroundCallback(callbackUri);

  Future<InstagramOAuthNetworkResult> completeColdStartCallback(
    Uri callbackUri,
  ) => _delegate.completeColdStartCallback(callbackUri);

  @override
  String toString() => 'InstagramOAuthNetworkAdapter(redacted)';
}

bool _isValidInstagramAuthorizationUri(
  Uri uri,
  BrokeredPublicAuthConfiguration configuration,
) {
  if (!_sameInstagramUriBase(uri, configuration.authorizationEndpoint) ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      !_hasExactInstagramQueryKeys(uri.queryParametersAll, {
        'response_type',
        'force_reauth',
        'client_id',
        'redirect_uri',
        'scope',
        'state',
      })) {
    return false;
  }
  final responseType = _singleInstagramQueryValue(uri, 'response_type');
  final forceReauth = _singleInstagramQueryValue(uri, 'force_reauth');
  final clientId = _singleInstagramQueryValue(uri, 'client_id');
  final redirectUri = _singleInstagramQueryValue(uri, 'redirect_uri');
  final scope = _singleInstagramQueryValue(uri, 'scope');
  final state = _singleInstagramQueryValue(uri, 'state');
  return responseType == 'code' &&
      forceReauth == 'true' &&
      clientId != null &&
      clientId.isNotEmpty &&
      clientId.length <= 256 &&
      clientId == clientId.trim() &&
      !RegExp(r'\s').hasMatch(clientId) &&
      redirectUri == configuration.callbackUri.toString() &&
      scope == 'instagram_business_basic' &&
      state != null &&
      RegExp(r'^[A-Za-z0-9_-]{32,512}$').hasMatch(state);
}

bool _hasExactInstagramQueryKeys(
  Map<String, List<String>> value,
  Set<String> expected,
) => value.length == expected.length && value.keys.every(expected.contains);

String? _singleInstagramQueryValue(Uri uri, String name) {
  final values = uri.queryParametersAll[name];
  return values?.length == 1 ? values!.single : null;
}

bool _sameInstagramUriBase(Uri left, Uri right) =>
    _instagramQueryAndFragmentFreeBase(left).toString() ==
    _instagramQueryAndFragmentFreeBase(right).toString();

Uri _instagramQueryAndFragmentFreeBase(Uri value) => Uri(
  scheme: value.scheme,
  userInfo: value.userInfo,
  host: value.host,
  port: value.hasPort ? value.port : null,
  path: value.path,
);
