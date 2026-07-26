import 'package:url_launcher/url_launcher.dart';

import 'youtube_private_dev_proof_harness.dart';

class ExternalYouTubePrivateDevSystemBrowser
    implements YouTubePrivateDevAuthorizationLauncher {
  const ExternalYouTubePrivateDevSystemBrowser();

  @override
  Future<void> openInSystemBrowser(Uri authorizationUrl) async {
    if (authorizationUrl.scheme != 'https' ||
        authorizationUrl.host != 'accounts.google.com' ||
        authorizationUrl.path != '/o/oauth2/v2/auth' ||
        authorizationUrl.hasPort ||
        authorizationUrl.userInfo.isNotEmpty ||
        authorizationUrl.hasFragment) {
      throw const YouTubePrivateDevProofFailure(
        'invalid_authorization_contract',
      );
    }
    final opened = await launchUrl(
      authorizationUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      throw const YouTubePrivateDevProofFailure('system_browser_not_opened');
    }
  }
}
