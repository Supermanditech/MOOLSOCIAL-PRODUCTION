const defaultFirebaseEmailLinkDomain = 'moolsocial-dev-503018.firebaseapp.com';
const customMoolSocialEmailLinkDomain = 'moolsocial.com';
const supportedEmailLinkDomains = <String>{customMoolSocialEmailLinkDomain};

enum EmailLinkGatewaySelection { unavailable, review, firebase }

EmailLinkGatewaySelection resolveEmailLinkGatewaySelection({
  required bool deviceReviewMode,
  required bool publicReviewMode,
  required bool runtimeConfigurationAvailable,
}) {
  if (publicReviewMode) {
    return runtimeConfigurationAvailable
        ? EmailLinkGatewaySelection.firebase
        : EmailLinkGatewaySelection.unavailable;
  }
  if (deviceReviewMode) return EmailLinkGatewaySelection.review;
  return runtimeConfigurationAvailable
      ? EmailLinkGatewaySelection.firebase
      : EmailLinkGatewaySelection.unavailable;
}

bool isQualifiedEmailLinkRuntimeConfiguration({
  required String continueUrl,
  required String linkDomain,
}) {
  final continueUri = Uri.tryParse(continueUrl.trim());
  if (continueUri == null ||
      continueUri.scheme != 'https' ||
      continueUri.host.toLowerCase() != customMoolSocialEmailLinkDomain ||
      continueUri.userInfo.isNotEmpty ||
      continueUri.hasPort ||
      continueUri.fragment.isNotEmpty ||
      !_isMoolSocialAppPath(continueUri.path)) {
    return false;
  }

  final normalizedLinkDomain = linkDomain.trim().toLowerCase();
  return normalizedLinkDomain.isEmpty ||
      supportedEmailLinkDomains.contains(normalizedLinkDomain);
}

bool _isMoolSocialAppPath(String path) =>
    path == '/app' || path.startsWith('/app/');
