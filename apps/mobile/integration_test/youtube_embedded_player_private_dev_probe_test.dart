import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moolsocial/core/youtube/youtube_embedded_player_android.dart';
import 'package:moolsocial/core/youtube/youtube_embedded_player_contract.dart';
import 'package:moolsocial/core/youtube/youtube_embedded_player_controller.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('private-Dev Android probe mounts one official provider player', (
    tester,
  ) async {
    const videoId = String.fromEnvironment('MOOLSOCIAL_YOUTUBE_PROBE_VIDEO_ID');
    expect(
      youtubeEmbeddedPlayerEnabled,
      isTrue,
      reason:
          'Run with '
          '--dart-define=MOOLSOCIAL_YOUTUBE_EMBEDDED_PLAYER_ENABLED=true.',
    );
    expect(
      RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(videoId),
      isTrue,
      reason:
          'Provide one current, embeddable private-Dev video ID through '
          'MOOLSOCIAL_YOUTUBE_PROBE_VIDEO_ID.',
    );

    final providerReady = Completer<void>();
    final platformFailure = Completer<YouTubeEmbeddedPlayerPlatformFailure>();
    YouTubeEmbeddedPlayerController? controller;
    addTearDown(() async {
      await controller?.dispose();
    });

    await binding.convertFlutterSurfaceToImage();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: SizedBox(
              width: 320,
              height: 200,
              child: AndroidYouTubeEmbeddedPlayerSurface(
                onPortReady: (port) {
                  final nextController = YouTubeEmbeddedPlayerController(
                    port,
                    YouTubePlayerLease(),
                    config:
                        const YouTubeEmbeddedPlayerFeatureConfig.fromBuildConfiguration(),
                    onSnapshot: (snapshot) {
                      if (snapshot.status == YouTubeEmbeddedPlayerStatus.cued &&
                          !providerReady.isCompleted) {
                        providerReady.complete();
                      }
                      final failure = snapshot.platformFailure;
                      if (failure != null && !platformFailure.isCompleted) {
                        platformFailure.complete(failure);
                      }
                    },
                  );
                  controller = nextController;
                  unawaited(
                    _selectProbeVideo(nextController, videoId, providerReady),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final outcome = await Future.any<Object>([
      providerReady.future.then<Object>((_) => const _ProviderReady()),
      platformFailure.future.then<Object>((failure) => failure),
    ]).timeout(const Duration(seconds: 30));
    expect(
      outcome,
      isA<_ProviderReady>(),
      reason: outcome is YouTubeEmbeddedPlayerPlatformFailure
          ? '${outcome.code}: ${outcome.message}'
          : null,
    );
    expect(controller?.snapshot.status, YouTubeEmbeddedPlayerStatus.cued);
    expect(find.byType(AndroidYouTubeEmbeddedPlayerSurface), findsOneWidget);
    await binding.takeScreenshot('youtube-private-dev-provider-probe');

    await controller?.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

class _ProviderReady {
  const _ProviderReady();
}

Future<void> _selectProbeVideo(
  YouTubeEmbeddedPlayerController controller,
  String videoId,
  Completer<void> ready,
) async {
  try {
    await controller.select(
      record: YouTubeEmbeddedVideoRecord(
        videoId: videoId,
        hasCurrentDataApiRecord: true,
        embeddable: true,
        hasKnownDeviceRegionExclusion: false,
        isVerifiedVerticalShort: false,
      ),
      availableWidth: 320,
    );
  } catch (error, stackTrace) {
    if (!ready.isCompleted) ready.completeError(error, stackTrace);
  }
}
