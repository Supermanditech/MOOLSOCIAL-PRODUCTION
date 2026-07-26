import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/youtube/youtube_embedded_player_bridge.dart';

void main() {
  test('iOS private-Dev adapter keeps the closed provider-only boundary', () {
    final packageRoot = 'packages/youtube_embedded_player_private_dev';
    final pubspec = File('$packageRoot/pubspec.yaml').readAsStringSync();
    final podspec = File(
      '$packageRoot/ios/youtube_embedded_player_private_dev.podspec',
    ).readAsStringSync();
    final pluginSource = File(
      '$packageRoot/ios/Classes/'
      'YouTubeEmbeddedPlayerPrivateDevPlugin.swift',
    ).readAsStringSync();
    final factorySource = File(
      '$packageRoot/ios/Classes/'
      'YouTubeEmbeddedPlayerPlatformViewFactory.swift',
    ).readAsStringSync();
    final nativeSource = File(
      '$packageRoot/ios/Classes/'
      'YouTubeEmbeddedPlayerPlatformView.swift',
    ).readAsStringSync();
    final dartSurfaceSource = File(
      'lib/core/youtube/youtube_embedded_player_ios.dart',
    ).readAsStringSync();
    final bootstrapSource = File(
      'lib/core/youtube/youtube_embedded_player_bridge.dart',
    ).readAsStringSync();
    final mainActivitySource = File(
      'android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt',
    ).readAsStringSync();

    expect(pubspec, contains('ios:'));
    expect(
      pubspec,
      contains('pluginClass: YouTubeEmbeddedPlayerPrivateDevPlugin'),
    );
    expect(podspec, contains("spec.platform = :ios, '15.0'"));
    expect(podspec, contains("'DEFINES_MODULE' => 'YES'"));
    expect(podspec, contains("spec.swift_version = '5.0'"));
    expect(pluginSource, contains('#if DEBUG'));
    expect(pluginSource, contains('registrar.register('));
    expect(
      pluginSource.indexOf('#if DEBUG'),
      lessThan(pluginSource.indexOf('registrar.register(')),
    );
    expect(
      pluginSource.indexOf('registrar.register('),
      lessThan(pluginSource.indexOf('#endif')),
    );

    expect(factorySource, contains('FlutterPlatformViewFactory'));
    expect(
      factorySource,
      contains(
        'static let viewType = '
        '"com.moolsocial.app/youtube_embedded_player"',
      ),
    );
    expect(nativeSource, contains('WKWebView'));
    expect(nativeSource, contains('loadHTMLString(html, baseURL:'));
    expect(
      nativeSource,
      contains(
        'private static let playerBaseURL = '
        '"https://com.moolsocial.app/"',
      ),
    );
    expect(
      nativeSource,
      contains('private static let expectedBootstrapSHA256 ='),
    );
    expect(
      nativeSource,
      contains(
        'F63983016541BF07FD5390EACB34B8CC'
        'A7B6A564957DCD647A643689B27D0FBB',
      ),
    );
    final canonicalBootstrapDigest = sha256
        .convert(utf8.encode(YouTubeEmbeddedPlayerBootstrap.html))
        .toString()
        .toUpperCase();
    expect(
      canonicalBootstrapDigest,
      'F63983016541BF07FD5390EACB34B8CC'
      'A7B6A564957DCD647A643689B27D0FBB',
    );
    expect(nativeSource, contains(canonicalBootstrapDigest));
    expect(nativeSource, contains('SHA256.hash('));
    expect(nativeSource, contains('SecRandomCopyBytes('));
    expect(nativeSource, contains('__MOOLSOCIAL_NATIVE_PORT_NONCE__'));
    expect(
      nativeSource,
      contains('private static let maximumMessageBytes = 8_192'),
    );

    expect(nativeSource, contains('message.frameInfo.isMainFrame'));
    expect(nativeSource, contains('message.frameInfo.securityOrigin'));
    expect(nativeSource, contains('origin.protocol == "https"'));
    expect(
      nativeSource,
      contains(
        'origin.host.caseInsensitiveCompare(Self.playerHost) == .orderedSame',
      ),
    );
    expect(nativeSource, contains('isExactPlayerDocument('));
    expect(nativeSource, contains('isAllowedProviderFrameDocument('));
    expect(nativeSource, contains('providerFrameHostSuffixes'));
    expect(nativeSource, contains('externalAccountHosts'));
    expect(
      nativeSource,
      contains('navigationAction.navigationType == .linkActivated'),
    );
    expect(nativeSource, contains('url.scheme?.lowercased() == "https"'));
    final mainFrameLinkHandoff = nativeSource.indexOf(
      'navigationAction.navigationType == .linkActivated',
      nativeSource.indexOf('if isMainFrame {') + 1,
    );
    final subframeLinkHandoff = nativeSource.indexOf(
      'navigationAction.navigationType == .linkActivated',
      mainFrameLinkHandoff + 1,
    );
    final subframeProviderAllow = nativeSource.indexOf(
      'if isAllowedProviderFrameDocument(url)',
    );
    expect(subframeLinkHandoff, isNonNegative);
    expect(subframeProviderAllow, greaterThan(subframeLinkHandoff));

    expect(nativeSource, contains('MessageChannel()'));
    expect(nativeSource, contains('window.postMessage('));
    expect(nativeSource, contains('callAsyncJavaScript('));
    expect(nativeSource, contains('arguments: ["message": message]'));
    expect(nativeSource, contains('window.__moolsocialNativePlayerPort'));
    expect(nativeSource, contains('channel.invokeMethod("playerEvent"'));

    expect(
      nativeSource,
      contains('configuration.allowsInlineMediaPlayback = true'),
    );
    expect(
      nativeSource,
      contains('configuration.mediaTypesRequiringUserActionForPlayback = .all'),
    );
    expect(
      nativeSource,
      contains('configuration.allowsPictureInPictureMediaPlayback = false'),
    );
    expect(nativeSource, contains('requestMediaCapturePermissionFor'));
    expect(nativeSource, contains('decisionHandler(.deny)'));

    expect(nativeSource, contains('destroyCurrentWebView()'));
    expect(nativeSource, contains('removeScriptMessageHandler('));
    expect(nativeSource, contains('current?.stopLoading()'));
    expect(nativeSource, contains('current?.navigationDelegate = nil'));
    expect(nativeSource, contains('current?.uiDelegate = nil'));
    expect(nativeSource, contains('current?.removeFromSuperview()'));
    expect(nativeSource, contains('deinit {'));
    expect(nativeSource, contains('dispose()'));

    expect(dartSurfaceSource, contains('UiKitView('));
    expect(dartSurfaceSource, contains('!kDebugMode'));
    expect(
      dartSurfaceSource,
      contains('defaultTargetPlatform != TargetPlatform.iOS'),
    );
    expect(
      dartSurfaceSource,
      contains(
        "const iosYouTubeEmbeddedPlayerViewType =\n"
        "    'com.moolsocial.app/youtube_embedded_player';",
      ),
    );
    expect(
      dartSurfaceSource,
      contains('static const _maximumBridgeMessageBytes = 8192'),
    );
    expect(
      dartSurfaceSource,
      contains('bootstrapHtml != YouTubeEmbeddedPlayerBootstrap.html'),
    );
    expect(
      dartSurfaceSource,
      contains('baseUrl.toString() != youtubeEmbeddedPlayerBaseUrl'),
    );
    expect(dartSurfaceSource, contains("invokeMethod<void>('mount'"));
    expect(dartSurfaceSource, contains("invokeMethod<void>('send'"));
    expect(dartSurfaceSource, contains("invokeMethod<void>('detach')"));
    expect(dartSurfaceSource, contains('YouTubePlayerEvent.decode(raw)'));
    expect(dartSurfaceSource, isNot(contains('evaluateJavaScript')));
    expect(dartSurfaceSource, isNot(contains('runJavaScript')));

    for (final duplicatedSchemaToken in <String>[
      'case "cue"',
      'case "load"',
      'case "play"',
      'case "pause"',
      'case "seek"',
      'case "state"',
      'case "error"',
      'YouTubePlayerCommandType',
      'YouTubePlayerEventType',
      'evaluateJavaScript(',
    ]) {
      expect(
        nativeSource,
        isNot(contains(duplicatedSchemaToken)),
        reason:
            'The iOS adapter must transport the typed bridge without '
            'duplicating or bypassing its schema: $duplicatedSchemaToken',
      );
    }
    for (final forbidden in <String>[
      'screens/01',
      'screens/02',
      'screens/03',
      'screens/04',
      'WebViewWidget',
      'http://',
      'localhost',
      'file://',
      'loadFileURL(',
      'load(URLRequest(',
    ]) {
      expect(nativeSource, isNot(contains(forbidden)));
    }
    expect(
      mainActivitySource,
      isNot(contains('YouTubeEmbeddedPlayerPrivateDevPlugin')),
      reason: 'Accepted Android application registration remains untouched.',
    );
    expect(
      '__MOOLSOCIAL_NATIVE_PORT_NONCE__'.allMatches(bootstrapSource),
      hasLength(1),
    );
  });
}
