import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

const youtubePrivateDevProofEnabled = bool.fromEnvironment(
  'MOOLSOCIAL_YOUTUBE_PRIVATE_DEV_PROOF',
);

const youtubePrivateDevProjectId = 'moolsocial-dev-503018';

typedef YouTubeAppCheckActivator = Future<void> Function();

/// Activates App Check only for an explicitly built private Dev proof.
///
/// Normal local, preview, staging and production builds remain untouched. A
/// proof build fails closed if it is accidentally pointed at emulators or a
/// Firebase project other than the dedicated Dev/Trial project.
Future<bool> activateYouTubePrivateDevAppCheckIfEnabled({
  required bool useEmulators,
  required String firebaseProjectId,
  bool globalSocialLoginAuditEnabled = false,
  YouTubeAppCheckActivator? activate,
}) async {
  return _activateYouTubePrivateDevAppCheck(
    enabled: youtubePrivateDevProofEnabled || globalSocialLoginAuditEnabled,
    useEmulators: useEmulators,
    firebaseProjectId: firebaseProjectId,
    activate: activate,
  );
}

@visibleForTesting
Future<bool> activateYouTubePrivateDevAppCheckForTesting({
  required bool enabled,
  required bool useEmulators,
  required String firebaseProjectId,
  required YouTubeAppCheckActivator activate,
}) {
  return _activateYouTubePrivateDevAppCheck(
    enabled: enabled,
    useEmulators: useEmulators,
    firebaseProjectId: firebaseProjectId,
    activate: activate,
  );
}

Future<bool> _activateYouTubePrivateDevAppCheck({
  required bool enabled,
  required bool useEmulators,
  required String firebaseProjectId,
  YouTubeAppCheckActivator? activate,
}) async {
  if (!enabled) return false;
  if (useEmulators || firebaseProjectId != youtubePrivateDevProjectId) {
    throw StateError(
      'YouTube private Dev proof requires the dedicated Dev Firebase project.',
    );
  }

  await (activate ??
      () => FirebaseAppCheck.instance.activate(
        providerAndroid: const AndroidPlayIntegrityProvider(),
        providerApple: const AppleAppAttestWithDeviceCheckFallbackProvider(),
      ))();
  return true;
}
