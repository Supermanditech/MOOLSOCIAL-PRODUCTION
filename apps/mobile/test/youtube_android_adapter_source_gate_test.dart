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
      contains('registerViewFactory('),
      reason: 'The authorized Play release must register the official player.',
    );
    expect(
      releaseRegistrarSource,
      contains('YouTubeEmbeddedPlayerPlatformViewFactory'),
    );
    expect(
      profileRegistrarSource,
      contains('registerViewFactory('),
      reason: 'Profile device review must exercise the same player surface.',
    );
    expect(
      profileRegistrarSource,
      contains('YouTubeEmbeddedPlayerPlatformViewFactory'),
    );
    expect(
      pluginSource,
      contains('YouTubeEmbeddedPlayerPrivateDevRegistrar.register(binding)'),
    );
    expect(
      contractSource,
      contains('defaultValue: false'),
      reason:
          'The player remains disabled unless an authorized build enables it.',
    );
    expect(
      dartAdapterSource,
      contains('defaultTargetPlatform != TargetPlatform.android'),
      reason: 'The registered player remains Android-only.',
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

  test('Android provider full-screen custom view has one paired host', () {
    final nativeSource = File(
      'packages/youtube_embedded_player_private_dev/android/src/debug/kotlin/'
      'com/moolsocial/app/youtube/'
      'YouTubeEmbeddedPlayerPlatformView.kt',
    ).readAsStringSync();
    final activitySource = File(
      'android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt',
    ).readAsStringSync();

    expect(
      'override fun onShowCustomView('.allMatches(nativeSource),
      hasLength(2),
      reason: 'Both current and legacy WebChromeClient entry points must pair.',
    );
    expect(
      'override fun onHideCustomView()'.allMatches(nativeSource),
      hasLength(1),
    );
    expect(nativeSource, contains('Theme_Black_NoTitleBar_Fullscreen'));
    expect(
      nativeSource,
      contains('WindowManager.LayoutParams.FLAG_FULLSCREEN'),
    );
    expect(nativeSource, contains('WindowInsets.Type.systemBars()'));
    expect(nativeSource, contains('BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE'));
    expect(nativeSource, contains('dialog.setOnCancelListener'));
    expect(nativeSource, contains('callback?.onCustomViewHidden()'));
    expect(nativeSource, contains('root.visibility = View.INVISIBLE'));
    expect(nativeSource, contains('root.visibility = View.VISIBLE'));
    expect(
      RegExp(
        r'private fun destroyCurrentWebView\([^)]*\) \{\s*'
        r'hideProviderFullscreen\(\)',
      ).hasMatch(nativeSource),
      isTrue,
      reason: 'Detach, renderer loss and disposal must all close full-screen.',
    );
    expect(
      activitySource,
      isNot(contains('YouTubeEmbeddedPlayer')),
      reason: 'The accepted MainActivity remains player agnostic.',
    );
  });
}
