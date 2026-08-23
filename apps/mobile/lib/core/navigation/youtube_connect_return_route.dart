const youtubeConnectRoute = '/app/creator/youtube-connect';

String? youtubeConnectReturnLocation(String platformRouteName) {
  final uri = Uri.tryParse(platformRouteName);
  if (uri == null || uri.hasFragment) {
    return null;
  }

  final customSchemeReturn =
      uri.scheme == 'moolsocial' &&
      uri.host == 'app' &&
      uri.path == '/creator/youtube-connect';
  final webReturn =
      uri.scheme == 'https' &&
      uri.host == 'moolsocial.com' &&
      uri.path == youtubeConnectRoute;
  final internalReturn =
      uri.scheme.isEmpty && uri.host.isEmpty && uri.path == youtubeConnectRoute;
  final resultValues = uri.queryParametersAll['youtubeConnect'];
  if (!(customSchemeReturn || webReturn || internalReturn) ||
      uri.queryParametersAll.length != 1 ||
      resultValues == null ||
      resultValues.length != 1) {
    return null;
  }

  final result = resultValues.single;
  if (result != 'complete' && result != 'failed') {
    return null;
  }
  return '$youtubeConnectRoute?youtubeConnect=$result';
}
