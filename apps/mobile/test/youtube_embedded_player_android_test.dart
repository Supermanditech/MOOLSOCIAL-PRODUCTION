import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/youtube/youtube_embedded_player_android.dart';
import 'package:moolsocial/core/youtube/youtube_embedded_player_bridge.dart';
import 'package:moolsocial/core/youtube/youtube_embedded_player_contract.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewId = 47;
  const channelName = '$androidYouTubeEmbeddedPlayerViewType/$viewId';
  const channel = MethodChannel(channelName);
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('packages the same closed player behind the release build flag', () {
    final contract = File(
      'lib/core/youtube/youtube_embedded_player_contract.dart',
    ).readAsStringSync();
    final adapter = File(
      'lib/core/youtube/youtube_embedded_player_android.dart',
    ).readAsStringSync();
    final gradle = File(
      'packages/youtube_embedded_player_private_dev/android/build.gradle.kts',
    ).readAsStringSync();
    final profileRegistrar = File(
      'packages/youtube_embedded_player_private_dev/android/src/profile/'
      'kotlin/com/moolsocial/youtube_embedded_player_private_dev/'
      'YouTubeEmbeddedPlayerPrivateDevRegistrar.kt',
    ).readAsStringSync();
    final releaseRegistrar = File(
      'packages/youtube_embedded_player_private_dev/android/src/release/'
      'kotlin/com/moolsocial/youtube_embedded_player_private_dev/'
      'YouTubeEmbeddedPlayerPrivateDevRegistrar.kt',
    ).readAsStringSync();
    final nativePlayer = File(
      'packages/youtube_embedded_player_private_dev/android/src/debug/'
      'kotlin/com/moolsocial/app/youtube/'
      'YouTubeEmbeddedPlayerPlatformView.kt',
    ).readAsStringSync();

    expect(contract, contains('bool.fromEnvironment('));
    expect(contract, contains('MOOLSOCIAL_YOUTUBE_EMBEDDED_PLAYER_ENABLED'));
    expect(contract, isNot(contains('kReleaseMode')));
    expect(adapter, isNot(contains('kReleaseMode')));
    expect(gradle, contains('create("profile")'));
    expect(gradle, contains('buildConfig = true'));
    expect(
      'src/debug/kotlin/com/moolsocial/app/youtube'.allMatches(gradle),
      hasLength(2),
    );
    expect(profileRegistrar, contains('registerViewFactory('));
    expect(releaseRegistrar, contains('registerViewFactory('));
    expect(
      nativePlayer,
      contains('WebView.setWebContentsDebuggingEnabled(BuildConfig.DEBUG)'),
    );
    expect(
      nativePlayer,
      isNot(contains('WebView.setWebContentsDebuggingEnabled(true)')),
    );
  });

  test('sends only the closed mount, command and detach methods', () async {
    final port = AndroidYouTubeEmbeddedPlayerPort(viewId);
    addTearDown(port.close);
    const geometry = YouTubePlayerGeometry(
      width: 320,
      height: 200,
      aspect: YouTubePlayerAspect.standardVideo,
    );

    await port.mount(
      bootstrapHtml: YouTubeEmbeddedPlayerBootstrap.html,
      baseUrl: Uri.parse(youtubeEmbeddedPlayerBaseUrl),
      geometry: geometry,
    );
    await port.send(const YouTubePlayerCommand.cue('abc123XYZ09'));
    await port.detach();

    expect(calls.map((call) => call.method), <String>[
      'mount',
      'send',
      'detach',
    ]);
    expect(calls.first.arguments, <String, Object?>{
      'bootstrapHtml': YouTubeEmbeddedPlayerBootstrap.html,
      'baseUrl': youtubeEmbeddedPlayerBaseUrl,
      'width': 320.0,
      'height': 200.0,
      'aspect': 'standardVideo',
    });
    final sendArguments = calls[1].arguments as Map<Object?, Object?>;
    expect(sendArguments.keys, <Object?>['message']);
    expect(
      sendArguments['message'],
      const YouTubePlayerCommand.cue('abc123XYZ09').encode(),
    );
    expect(calls.last.arguments, isNull);
  });

  test(
    'rejects any bootstrap or origin substitution before native code',
    () async {
      final port = AndroidYouTubeEmbeddedPlayerPort(viewId);
      addTearDown(port.close);
      const geometry = YouTubePlayerGeometry(
        width: 320,
        height: 200,
        aspect: YouTubePlayerAspect.standardVideo,
      );

      await expectLater(
        port.mount(
          bootstrapHtml: '${YouTubeEmbeddedPlayerBootstrap.html}\n',
          baseUrl: Uri.parse(youtubeEmbeddedPlayerBaseUrl),
          geometry: geometry,
        ),
        throwsStateError,
      );
      await expectLater(
        port.mount(
          bootstrapHtml: YouTubeEmbeddedPlayerBootstrap.html,
          baseUrl: Uri.parse('https://com.moolsocial.app/player'),
          geometry: geometry,
        ),
        throwsStateError,
      );
      expect(calls, isEmpty);
    },
  );

  test('decodes only typed native callbacks', () async {
    final port = AndroidYouTubeEmbeddedPlayerPort(viewId);
    addTearDown(port.close);
    YouTubePlayerEvent? receivedEvent;
    AndroidYouTubePlatformFailure? receivedFailure;
    port.bind(
      onEvent: (event) async {
        receivedEvent = event;
      },
      onPlatformFailure: (failure) async {
        receivedFailure = failure;
      },
    );

    await _sendNativeCall(
      channelName,
      const MethodCall(
        'playerEvent',
        '{"version":1,"kind":"event","type":"ready","payload":{}}',
      ),
    );
    await _sendNativeCall(
      channelName,
      const MethodCall('platformFailure', <String, Object?>{
        'code': 'ready_timeout',
        'message': 'The provider player did not become ready.',
      }),
    );

    expect(receivedEvent?.type, YouTubePlayerEventType.ready);
    expect(receivedFailure?.code, 'ready_timeout');
    expect(
      receivedFailure?.message,
      'The provider player did not become ready.',
    );
  });

  test('closes the Dart endpoint fail-closed', () async {
    final port = AndroidYouTubeEmbeddedPlayerPort(viewId);
    port.close();

    await expectLater(port.detach(), throwsStateError);
    await expectLater(
      port.send(const YouTubePlayerCommand.pause()),
      throwsStateError,
    );
  });
}

Future<void> _sendNativeCall(String channelName, MethodCall call) async {
  final response = await TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger
      .handlePlatformMessage(
        channelName,
        const StandardMethodCodec().encodeMethodCall(call),
        null,
      );
  if (response != null) {
    const StandardMethodCodec().decodeEnvelope(response);
  }
}
