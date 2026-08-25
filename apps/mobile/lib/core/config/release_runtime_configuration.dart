import 'package:flutter/material.dart';

import '../design/moolsocial_brand_motion.dart';

const requiredReleaseRuntimeDefineNames = <String>[
  'MOOLSOCIAL_FIREBASE_API_KEY',
  'MOOLSOCIAL_FIREBASE_APP_ID',
  'MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID',
  'MOOLSOCIAL_FIREBASE_PROJECT_ID',
  'MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID',
];

bool isQualifiedHttpsRuntimeEndpoint(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

bool shouldUseNativeAndroidFirebaseConfiguration({
  required bool isAndroid,
  required bool useEmulators,
}) => isAndroid && !useEmulators;

bool isQualifiedDeviceReviewRuntimeMode({
  required bool deviceReview,
  required bool useEmulators,
  required bool youtubePublicReview,
  required bool youtubePrivateDevProof,
  required bool sideloadPreflightEnabled,
  required bool googleSideloadSigningQualified,
  bool globalSocialLoginAudit = false,
}) {
  final youtubeReviewQualified =
      youtubePublicReview && youtubePrivateDevProof && !useEmulators;
  final publicAuthSideloadQualified =
      deviceReview &&
      !useEmulators &&
      sideloadPreflightEnabled &&
      googleSideloadSigningQualified;

  if (youtubePublicReview && !youtubeReviewQualified) return false;
  if (sideloadPreflightEnabled && !publicAuthSideloadQualified) return false;
  if (globalSocialLoginAudit && !publicAuthSideloadQualified) return false;
  if (deviceReview && !useEmulators) {
    return youtubeReviewQualified || publicAuthSideloadQualified;
  }
  return true;
}

const socialRuntimeFirebaseProjectId = 'moolsocial-dev-503018';
const socialRuntimeYouTubeProviderUrl =
    'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/youtubeProvider';
const socialRuntimeContentUrl =
    'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialContent';
const socialRuntimeChatUrl =
    'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialChat';

bool isQualifiedSocialRuntimeDependencySet({
  required bool globalSocialLoginAudit,
  required bool useEmulators,
  required String firebaseProjectId,
  required bool youtubePrivateDevProof,
  required bool youtubeEmbeddedPlayerEnabled,
  required String youtubeProviderUrl,
  required String socialContentUrl,
  required String chatUrl,
}) {
  if (!globalSocialLoginAudit) return true;
  return !useEmulators &&
      firebaseProjectId.trim() == socialRuntimeFirebaseProjectId &&
      youtubePrivateDevProof &&
      youtubeEmbeddedPlayerEnabled &&
      youtubeProviderUrl.trim() == socialRuntimeYouTubeProviderUrl &&
      socialContentUrl.trim() == socialRuntimeContentUrl &&
      chatUrl.trim() == socialRuntimeChatUrl;
}

@immutable
class GlobalSocialLoginAuditComposition {
  const GlobalSocialLoginAuditComposition({
    required this.useReviewAuthentication,
    required this.useProductionProviderAvailability,
    required this.useFirebaseSessionBootstrap,
    required this.activateDevAppCheck,
  });

  final bool useReviewAuthentication;
  final bool useProductionProviderAvailability;
  final bool useFirebaseSessionBootstrap;
  final bool activateDevAppCheck;
}

GlobalSocialLoginAuditComposition resolveGlobalSocialLoginAuditComposition({
  required bool deviceReview,
  required bool globalSocialLoginAudit,
}) {
  final liveAudit = deviceReview && globalSocialLoginAudit;
  return GlobalSocialLoginAuditComposition(
    useReviewAuthentication: deviceReview && !liveAudit,
    useProductionProviderAvailability: !deviceReview || liveAudit,
    useFirebaseSessionBootstrap: liveAudit,
    activateDevAppCheck: liveAudit,
  );
}

@immutable
class ReleaseRuntimeConfiguration {
  const ReleaseRuntimeConfiguration({
    required this.useEmulators,
    required this.firebaseApiKey,
    required this.firebaseAppId,
    required this.firebaseMessagingSenderId,
    required this.firebaseProjectId,
    required this.googleServerClientId,
  });

  final bool useEmulators;
  final String firebaseApiKey;
  final String firebaseAppId;
  final String firebaseMessagingSenderId;
  final String firebaseProjectId;
  final String googleServerClientId;

  List<String> get missingRequiredDefineNames {
    if (useEmulators) return const <String>[];

    final valuesByDefineName = <String, String>{
      'MOOLSOCIAL_FIREBASE_API_KEY': firebaseApiKey,
      'MOOLSOCIAL_FIREBASE_APP_ID': firebaseAppId,
      'MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID': firebaseMessagingSenderId,
      'MOOLSOCIAL_FIREBASE_PROJECT_ID': firebaseProjectId,
      'MOOLSOCIAL_GOOGLE_SERVER_CLIENT_ID': googleServerClientId,
    };
    return List<String>.unmodifiable(
      requiredReleaseRuntimeDefineNames.where(
        (defineName) => valuesByDefineName[defineName]!.trim().isEmpty,
      ),
    );
  }

  bool get isComplete => missingRequiredDefineNames.isEmpty;
}

class ReleaseConfigurationFailureApp extends StatelessWidget {
  const ReleaseConfigurationFailureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoolSocial',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3157D5)),
        useMaterial3: true,
      ),
      home: const _ReleaseConfigurationFailureScreen(),
    );
  }
}

class ReleaseBootstrapApp extends StatelessWidget {
  const ReleaseBootstrapApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF000080);
    return MaterialApp(
      title: 'MoolSocial',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: navy,
        body: SafeArea(
          child: Center(
            child: Semantics(
              label: 'MoolSocial is starting',
              liveRegion: true,
              container: true,
              explicitChildNodes: true,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MoolSocialBrandMotion(
                    onDarkBackground: true,
                    width: 220,
                    height: 82,
                    fontSize: 18,
                    autoPlay: false,
                    progressOverride: 1,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Starting MoolSocial',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReleaseConfigurationFailureScreen extends StatelessWidget {
  const _ReleaseConfigurationFailureScreen();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: 'Update required',
                  child: Icon(
                    Icons.system_update_alt_rounded,
                    size: 52,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'MoolSocial needs an update',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This version cannot open safely. Update MoolSocial from '
                  'your app store, then open it again. Your account and '
                  'content are safe.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
