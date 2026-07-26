import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android private-Dev adapter keeps the closed bridge architecture', () {
    final nativeSource = File(
      'packages/youtube_embedded_player_private_dev/android/src/debug/kotlin/'
      'com/moolsocial/app/youtube/'
      'YouTubeEmbeddedPlayerPlatformView.kt',
    ).readAsStringSync();
    final factorySource = File(
      'packages/youtube_embedded_player_private_dev/android/src/debug/kotlin/'
      'com/moolsocial/app/youtube/'
      'YouTubeEmbeddedPlayerPlatformViewFactory.kt',
    ).readAsStringSync();
    final pluginSource = File(
      'packages/youtube_embedded_player_private_dev/android/src/main/kotlin/'
      'com/moolsocial/youtube_embedded_player_private_dev/'
      'YouTubeEmbeddedPlayerPrivateDevPlugin.kt',
    ).readAsStringSync();
    final debugRegistrarSource = File(
      'packages/youtube_embedded_player_private_dev/android/src/debug/kotlin/'
      'com/moolsocial/youtube_embedded_player_private_dev/'
      'YouTubeEmbeddedPlayerPrivateDevRegistrar.kt',
    ).readAsStringSync();
    final releaseRegistrarSource = File(
      'packages/youtube_embedded_player_private_dev/android/src/release/kotlin/'
      'com/moolsocial/youtube_embedded_player_private_dev/'
      'YouTubeEmbeddedPlayerPrivateDevRegistrar.kt',
    ).readAsStringSync();
    final profileRegistrarSource = File(
      'packages/youtube_embedded_player_private_dev/android/src/profile/kotlin/'
      'com/moolsocial/youtube_embedded_player_private_dev/'
      'YouTubeEmbeddedPlayerPrivateDevRegistrar.kt',
    ).readAsStringSync();
    final activitySource = File(
      'android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt',
    ).readAsStringSync();
    final dartAdapterSource = File(
      'lib/core/youtube/youtube_embedded_player_android.dart',
    ).readAsStringSync();
    final bootstrapSource = File(
      'lib/core/youtube/youtube_embedded_player_bridge.dart',
    ).readAsStringSync();
    final contractSource = File(
      'lib/core/youtube/youtube_embedded_player_contract.dart',
    ).readAsStringSync();
    final combinedAdapterSource =
        '$nativeSource\n$factorySource\n$pluginSource\n'
        '$debugRegistrarSource\n$dartAdapterSource';

    expect(
      activitySource,
      isNot(contains('YouTubeEmbeddedPlayer')),
      reason: 'Accepted MainActivity must remain untouched.',
    );
    expect(debugRegistrarSource, contains('check('));
    expect(debugRegistrarSource, contains('registerViewFactory('));
    expect(
      debugRegistrarSource,
      contains('YouTubeEmbeddedPlayerPlatformViewFactory.VIEW_TYPE'),
    );
    expect(
      releaseRegistrarSource,
      isNot(contains('registerViewFactory(')),
      reason: 'Release registration must be a no-op.',
    );
    expect(
      releaseRegistrarSource,
      isNot(contains('YouTubeEmbeddedPlayerPlatformViewFactory')),
    );
    expect(
      profileRegistrarSource,
      isNot(contains('registerViewFactory(')),
      reason: 'Profile registration must be a no-op.',
    );
    expect(
      profileRegistrarSource,
      isNot(contains('YouTubeEmbeddedPlayerPlatformViewFactory')),
    );
    expect(
      pluginSource,
      contains('YouTubeEmbeddedPlayerPrivateDevRegistrar.register(binding)'),
    );
    expect(
      contractSource,
      contains('kDebugMode &&'),
      reason: 'Build defines cannot enable the private adapter in release.',
    );
    expect(
      dartAdapterSource,
      contains('if (!kDebugMode ||'),
      reason: 'The Android surface must fail closed outside debug builds.',
    );
    expect(
      nativeSource,
      contains('loadDataWithBaseURL('),
      reason: 'The injected document must retain the approved HTTPS origin.',
    );
    expect(nativeSource, contains('createWebMessageChannel()'));
    expect(nativeSource, contains('WebMessage(connection, arrayOf(ports[1]))'));
    expect(nativeSource, contains('PLAYER_ORIGIN_URI'));
    expect(nativeSource, contains('Uri.parse("https://com.moolsocial.app")'));
    expect(nativeSource, contains('SecureRandom()'));
    expect(nativeSource, contains('ByteArray(32)'));
    expect(nativeSource, contains('bootstrapLoadPending'));
    expect(nativeSource, contains('expectedWebView !== webView'));
    expect(
      nativeSource,
      contains('destroyCurrentWebView(rendererGone = true)'),
    );
    expect(
      nativeSource,
      contains(
        'F63983016541BF07FD5390EACB34B8CC'
        'A7B6A564957DCD647A643689B27D0FBB',
      ),
    );
    expect(nativeSource, isNot(contains('__MOOLSOCIAL_BOOTSTRAP_SHA256__')));
    expect(
      '__MOOLSOCIAL_NATIVE_PORT_NONCE__'.allMatches(bootstrapSource),
      hasLength(1),
    );
    expect(bootstrapSource, isNot(contains('event.origin')));

    for (final forbidden in <String>[
      'addJavascriptInterface(',
      'addWebMessageListener(',
      'evaluateJavascript(',
      'JavascriptChannel',
      'javascript:',
      'window.webkit',
      'messageHandlers',
    ]) {
      expect(
        combinedAdapterSource,
        isNot(contains(forbidden)),
        reason: 'Forbidden bridge surface found: $forbidden',
      );
    }
    expect(
      combinedAdapterSource,
      isNot(contains('Uri.parse("*")')),
      reason: 'The native target origin must never be a wildcard.',
    );
    expect(
      combinedAdapterSource,
      isNot(contains('screens/04')),
      reason: 'The isolated probe cannot be wired into Screen 04.',
    );
    final appPubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      appPubspec,
      contains('path: packages/youtube_embedded_player_private_dev'),
    );
  });

  test('existing MainActivity current-area owner remains intact', () {
    final activitySource = File(
      'android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt',
    ).readAsStringSync();

    expect(activitySource, contains('resolveCurrentArea'));
    expect(activitySource, contains('openLocationServicesSettings'));
    expect(activitySource, contains('reverseGeocode'));
    expect(activitySource, contains('geocodingExecutor.shutdownNow()'));
  });
}
