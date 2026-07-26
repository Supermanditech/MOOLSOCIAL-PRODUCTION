const youtubeConnectRoute = '/app/creator/youtube-connect';

String? youtubeConnectReturnLocation(String platformRouteName) {
  final uri = Uri.tryParse(platformRouteName);
  if (uri == null || uri.hasFragment || uri.path != youtubeConnectRoute) {
    return null;
  }

  final allowedOrigin =
      (uri.scheme == 'moolsocial' && uri.host.isEmpty) ||
      (uri.scheme == 'https' && uri.host == 'moolsocial.com') ||
      (uri.scheme.isEmpty && uri.host.isEmpty);
  final resultValues = uri.queryParametersAll['youtubeConnect'];
  if (!allowedOrigin ||
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
