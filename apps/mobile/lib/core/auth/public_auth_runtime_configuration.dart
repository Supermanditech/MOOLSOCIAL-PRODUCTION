class PublicAuthRuntimeConfiguration {
  const PublicAuthRuntimeConfiguration({
    required this.googleServerClientConfigured,
    required this.googleProviderQualified,
    required this.playSigningQualified,
    this.sideloadPreflightEnabled = false,
    this.googleSideloadSigningQualified = false,
    required this.emailLinkQualified,
    required this.mobileOtpEnabled,
    required this.mobileAttestationQualified,
    required this.appleEnabled,
    required this.appleProviderQualified,
    required this.applePlatformConfigurationQualified,
    required this.appleRevocationQualified,
    required this.xPublicClientEnabled,
    required this.xClientIdConfigured,
    required this.xExactRedirectQualified,
    required this.xPkceAdapterInstalled,
    required this.xFirebaseBrokerQualified,
    required this.instagramEnabled,
    required this.instagramProfessionalLoginQualified,
    required this.instagramExactRedirectQualified,
    required this.instagramBrokerAdapterInstalled,
    required this.instagramBrokerQualified,
    required this.instagramRevocationQualified,
    required this.facebookEnabled,
    required this.facebookNativeAdapterInstalled,
    required this.facebookProviderQualified,
    required this.facebookAndroidConfigurationQualified,
    required this.facebookRevocationQualified,
    required this.facebookDataDeletionQualified,
  });

  final bool googleServerClientConfigured;
  final bool googleProviderQualified;
  final bool playSigningQualified;
  final bool sideloadPreflightEnabled;
  final bool googleSideloadSigningQualified;
  final bool emailLinkQualified;
  final bool mobileOtpEnabled;
  final bool mobileAttestationQualified;
  final bool appleEnabled;
  final bool appleProviderQualified;
  final bool applePlatformConfigurationQualified;
  final bool appleRevocationQualified;
  final bool xPublicClientEnabled;
  final bool xClientIdConfigured;
  final bool xExactRedirectQualified;
  final bool xPkceAdapterInstalled;
  final bool xFirebaseBrokerQualified;
  final bool instagramEnabled;
  final bool instagramProfessionalLoginQualified;
  final bool instagramExactRedirectQualified;
  final bool instagramBrokerAdapterInstalled;
  final bool instagramBrokerQualified;
  final bool instagramRevocationQualified;
  final bool facebookEnabled;
  final bool facebookNativeAdapterInstalled;
  final bool facebookProviderQualified;
  final bool facebookAndroidConfigurationQualified;
  final bool facebookRevocationQualified;
  final bool facebookDataDeletionQualified;

  bool get googleAndYoutubeAvailable =>
      googleServerClientConfigured &&
      googleProviderQualified &&
      (playSigningQualified ||
          (sideloadPreflightEnabled && googleSideloadSigningQualified));

  bool get passwordlessEmailAvailable => emailLinkQualified;

  bool get mobileOtpAvailable => mobileOtpEnabled && mobileAttestationQualified;

  bool get appleAvailable =>
      appleEnabled &&
      appleProviderQualified &&
      applePlatformConfigurationQualified &&
      appleRevocationQualified;

  bool get xAvailable =>
      xPublicClientEnabled &&
      xClientIdConfigured &&
      xExactRedirectQualified &&
      xPkceAdapterInstalled &&
      xFirebaseBrokerQualified;

  bool get instagramAvailable =>
      instagramEnabled &&
      instagramProfessionalLoginQualified &&
      instagramExactRedirectQualified &&
      instagramBrokerAdapterInstalled &&
      instagramBrokerQualified &&
      instagramRevocationQualified;

  bool get facebookAvailable =>
      facebookEnabled &&
      facebookNativeAdapterInstalled &&
      facebookProviderQualified &&
      facebookAndroidConfigurationQualified &&
      facebookRevocationQualified &&
      facebookDataDeletionQualified;
}
