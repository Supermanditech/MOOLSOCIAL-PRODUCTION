import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_app_check.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_client.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_proof_harness.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_system_browser.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_transport.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_uploader.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_workflow.dart';

const _firebaseApiKey = String.fromEnvironment('MOOLSOCIAL_FIREBASE_API_KEY');
const _firebaseAppId = String.fromEnvironment('MOOLSOCIAL_FIREBASE_APP_ID');
const _firebaseMessagingSenderId = String.fromEnvironment(
  'MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID',
);
const _firebaseProjectId = String.fromEnvironment(
  'MOOLSOCIAL_FIREBASE_PROJECT_ID',
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'runs one explicitly confirmed supervised private-Dev provider profile',
    (tester) async {
      final configuration =
          YouTubePrivateDevProofConfiguration.fromBuildConfiguration();
      final firebaseOptions = _requiredFirebaseOptions();
      expect(firebaseOptions.projectId, youtubePrivateDevProjectId);

      await Firebase.initializeApp(options: firebaseOptions);
      await activateYouTubePrivateDevAppCheckIfEnabled(
        useEmulators: false,
        firebaseProjectId: firebaseOptions.projectId,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      final transport = IoYouTubeHttpTransport(
        timeout: const Duration(seconds: 45),
        uploadTimeout: const Duration(minutes: 15),
      );
      addTearDown(() => transport.close(force: true));
      final client = YouTubePrivateDevClient.fromBuildConfiguration(
        transport: transport,
      );
      final gateway = RealYouTubePrivateDevProofGateway(
        client: client,
        uploadWorkflow: YouTubePrivateDevUploadWorkflow(
          client: client,
          uploader: YouTubeDirectUploader(transport),
        ),
      );
      final evidence = await YouTubePrivateDevProofHarness(
        configuration: configuration,
        gateway: gateway,
        authorizationLauncher: const ExternalYouTubePrivateDevSystemBrowser(),
        mediaSelector: const _GalleryMp4Selector(),
      ).run();

      binding.reportData = Map<String, dynamic>.from(evidence.toJson());
      expect(
        evidence.outcome,
        YouTubePrivateDevProofOutcome.passed,
        reason: evidence.error?.code,
      );
    },
    timeout: const Timeout(Duration(minutes: 35)),
  );
}

FirebaseOptions _requiredFirebaseOptions() {
  final required = <String, String>{
    'MOOLSOCIAL_FIREBASE_API_KEY': _firebaseApiKey,
    'MOOLSOCIAL_FIREBASE_APP_ID': _firebaseAppId,
    'MOOLSOCIAL_FIREBASE_MESSAGING_SENDER_ID': _firebaseMessagingSenderId,
    'MOOLSOCIAL_FIREBASE_PROJECT_ID': _firebaseProjectId,
  };
  final missing = required.entries
      .where((entry) => entry.value.trim().isEmpty)
      .map((entry) => entry.key)
      .toList(growable: false);
  if (missing.isNotEmpty) {
    throw StateError(
      'Private-Dev proof configuration is incomplete: ${missing.join(', ')}.',
    );
  }
  if (_firebaseProjectId != youtubePrivateDevProjectId) {
    throw StateError(
      'The supervised proof requires the dedicated Dev Firebase project.',
    );
  }
  return const FirebaseOptions(
    apiKey: _firebaseApiKey,
    appId: _firebaseAppId,
    messagingSenderId: _firebaseMessagingSenderId,
    projectId: _firebaseProjectId,
  );
}

class _GalleryMp4Selector implements YouTubePrivateDevMediaSelector {
  const _GalleryMp4Selector();

  @override
  Future<YouTubeUploadSource?> selectRightsClearedMp4() async {
    final selected = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (selected == null) return null;
    if (!selected.path.toLowerCase().endsWith('.mp4')) {
      throw const YouTubePrivateDevProofFailure('selected_media_must_be_mp4');
    }
    return FileYouTubeUploadSource(selected.path);
  }
}
