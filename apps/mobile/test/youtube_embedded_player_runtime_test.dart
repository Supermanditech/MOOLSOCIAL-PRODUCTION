import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/youtube/youtube_embedded_player_bridge.dart';
import 'package:moolsocial/core/youtube/youtube_embedded_player_contract.dart';
import 'package:moolsocial/core/youtube/youtube_embedded_player_controller.dart';

void main() {
  group('embedded-player release boundary', () {
    test('is disabled by default', () {
      expect(youtubeEmbeddedPlayerEnabled, isFalse);
      expect(youtubeShortsAutoplayEnabled, isFalse);
      expect(
        const YouTubeEmbeddedPlayerFeatureConfig.fromBuildConfiguration()
            .enabled,
        isFalse,
      );
    });

    test('uses the one approved identity and provider-only bootstrap', () {
      expect(youtubeEmbeddedPlayerBaseUrl, 'https://com.moolsocial.app/');
      expect(youtubeEmbeddedPlayerOrigin, 'https://com.moolsocial.app');
      expect(
        YouTubeEmbeddedPlayerBootstrap.html,
        contains('strict-origin-when-cross-origin'),
      );
      expect(
        YouTubeEmbeddedPlayerBootstrap.html,
        contains("origin: EXPECTED_ORIGIN"),
      );
      expect(
        YouTubeEmbeddedPlayerBootstrap.html,
        contains('https://www.youtube.com/iframe_api'),
      );
      expect(YouTubeEmbeddedPlayerBootstrap.html, contains('autoplay: 0'));
      expect(YouTubeEmbeddedPlayerBootstrap.html, contains('controls: 1'));
      expect(YouTubeEmbeddedPlayerBootstrap.html, contains('fs: 1'));
      expect(YouTubeEmbeddedPlayerBootstrap.html, contains('playsinline: 1'));
      expect(
        YouTubeEmbeddedPlayerBootstrap.html,
        isNot(contains('addJavascriptInterface')),
      );
      expect(
        YouTubeEmbeddedPlayerBootstrap.html,
        isNot(contains('window.webkit')),
      );
      expect(
        YouTubeEmbeddedPlayerBootstrap.html,
        isNot(contains('messageHandlers')),
      );
      expect(
        YouTubeEmbeddedPlayerBootstrap.html,
        isNot(contains('window[BRIDGE_NAME]')),
      );
      expect(YouTubeEmbeddedPlayerBootstrap.html, isNot(contains('eval(')));
      expect(
        YouTubeEmbeddedPlayerBootstrap.html,
        isNot(contains('event.origin')),
      );
      expect(
        YouTubeEmbeddedPlayerBootstrap.html,
        contains('__MOOLSOCIAL_NATIVE_PORT_NONCE__'),
      );
      expect(
        YouTubeEmbeddedPlayerBootstrap.html,
        contains("connection[MESSAGE_BODY_KEY].nonce !== CONNECT_NONCE"),
      );
      expect(
        YouTubeEmbeddedPlayerBootstrap.html,
        contains('event.stopImmediatePropagation()'),
      );
      expect(
        YouTubeEmbeddedPlayerBootstrap.html,
        contains('event.ports.length !== 1'),
      );
      expect(
        YouTubeEmbeddedPlayerBootstrap.html,
        contains("connection.type !== 'playerPort'"),
      );
      expect(
        YouTubeEmbeddedPlayerBootstrap.html,
        contains('nativePort.postMessage(message)'),
      );
      expect(
        YouTubeEmbeddedPlayerBootstrap.html,
        isNot(contains('MoolSocial')),
      );
      expect(
        RegExp(r'<div\b').allMatches(YouTubeEmbeddedPlayerBootstrap.html),
        hasLength(1),
      );
    });
  });

  group('fitment and eligibility', () {
    test('enforces 320x200 for standard video', () {
      final geometry = YouTubePlayerGeometry.forAvailableWidth(
        availableWidth: 320,
        aspect: YouTubePlayerAspect.standardVideo,
      );
      expect(geometry.width, 320);
      expect(geometry.height, 200);
    });

    test('keeps verified vertical Shorts at 9:16', () {
      final geometry = YouTubePlayerGeometry.forAvailableWidth(
        availableWidth: 320,
        aspect: YouTubePlayerAspect.verifiedVerticalShort,
      );
      expect(geometry.width, 320);
      expect(geometry.height, closeTo(568.888, 0.001));
    });

    test('rejects a host narrower than the provider minimum', () {
      expect(
        () => YouTubePlayerGeometry.forAvailableWidth(
          availableWidth: 199,
          aspect: YouTubePlayerAspect.standardVideo,
        ),
        throwsArgumentError,
      );
    });

    test('requires ID, current record, embedding and region eligibility', () {
      const base = YouTubeEmbeddedVideoRecord(
        videoId: 'abc123XYZ09',
        hasCurrentDataApiRecord: true,
        embeddable: true,
        hasKnownDeviceRegionExclusion: false,
        isVerifiedVerticalShort: false,
      );
      expect(YouTubePlayerEligibilityPolicy.evaluate(base).eligible, isTrue);
      expect(
        YouTubePlayerEligibilityPolicy.evaluate(
          const YouTubeEmbeddedVideoRecord(
            videoId: 'bad',
            hasCurrentDataApiRecord: true,
            embeddable: true,
            hasKnownDeviceRegionExclusion: false,
            isVerifiedVerticalShort: false,
          ),
        ).reason,
        YouTubePlayerEligibilityReason.invalidVideoId,
      );
      expect(
        YouTubePlayerEligibilityPolicy.evaluate(
          const YouTubeEmbeddedVideoRecord(
            videoId: 'abc123XYZ09',
            hasCurrentDataApiRecord: false,
            embeddable: true,
            hasKnownDeviceRegionExclusion: false,
            isVerifiedVerticalShort: false,
          ),
        ).reason,
        YouTubePlayerEligibilityReason.missingCurrentDataApiRecord,
      );
      expect(
        YouTubePlayerEligibilityPolicy.evaluate(
          const YouTubeEmbeddedVideoRecord(
            videoId: 'abc123XYZ09',
            hasCurrentDataApiRecord: true,
            embeddable: false,
            hasKnownDeviceRegionExclusion: false,
            isVerifiedVerticalShort: false,
          ),
        ).reason,
        YouTubePlayerEligibilityReason.embeddingDisabled,
      );
      expect(
        YouTubePlayerEligibilityPolicy.evaluate(
          const YouTubeEmbeddedVideoRecord(
            videoId: 'abc123XYZ09',
            hasCurrentDataApiRecord: true,
            embeddable: true,
            hasKnownDeviceRegionExclusion: true,
            isVerifiedVerticalShort: false,
          ),
        ).reason,
        YouTubePlayerEligibilityReason.knownDeviceRegionExclusion,
      );
    });
  });

  group('closed typed bridge', () {
    test('encodes the exact one-time transferred-port connection', () {
      const nonce = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFG';
      expect(
        jsonDecode(YouTubePlayerPortConnection.encode(nonce)),
        <String, Object?>{
          'version': 1,
          'kind': 'connect',
          'type': 'playerPort',
          'payload': <String, Object?>{'nonce': nonce},
        },
      );
      expect(
        () => YouTubePlayerPortConnection.encode('predictable'),
        throwsFormatException,
      );
    });

    test('encodes only the declared command envelope', () {
      final encoded = const YouTubePlayerCommand.cue('abc123XYZ09').encode();
      expect(jsonDecode(encoded), <String, Object?>{
        'version': 1,
        'kind': 'command',
        'type': 'cue',
        'payload': <String, Object?>{'videoId': 'abc123XYZ09'},
      });
      expect(
        const YouTubePlayerCommand.load(
          'abc123XYZ09',
          startSeconds: 10,
          endSeconds: 30,
        ).toJson()['payload'],
        <String, Object?>{
          'videoId': 'abc123XYZ09',
          'startSeconds': 10.0,
          'endSeconds': 30.0,
        },
      );
      expect(
        const YouTubePlayerCommand.setCaptionFontSize(2).toJson(),
        <String, Object?>{
          'version': 1,
          'kind': 'command',
          'type': 'setCaptionFontSize',
          'payload': <String, Object?>{'fontSize': 2},
        },
      );
      expect(
        () => const YouTubePlayerCommand.cue('bad').encode(),
        throwsFormatException,
      );
      expect(
        () => const YouTubePlayerCommand.seek(-1).encode(),
        throwsFormatException,
      );
      expect(
        () => const YouTubePlayerCommand.setCaptionFontSize(4).encode(),
        throwsFormatException,
      );
      expect(
        () => const YouTubePlayerCommand.load(
          'abc123XYZ09',
          startSeconds: 30,
          endSeconds: 10,
        ).encode(),
        throwsFormatException,
      );
    });

    test('encodes the complete bounded playlist and playback control set', () {
      expect(
        const YouTubePlayerCommand.cuePlaylist(
          videoIds: <String>['abc123XYZ09', 'def456UVW12'],
          index: 1,
          startSeconds: 12.5,
        ).toJson(),
        <String, Object?>{
          'version': 1,
          'kind': 'command',
          'type': 'cuePlaylist',
          'payload': <String, Object?>{
            'videoIds': <String>['abc123XYZ09', 'def456UVW12'],
            'index': 1,
            'startSeconds': 12.5,
          },
        },
      );
      expect(
        const YouTubePlayerCommand.loadPlaylist(
          playlistId: 'PL1234567890',
        ).toJson(),
        <String, Object?>{
          'version': 1,
          'kind': 'command',
          'type': 'loadPlaylist',
          'payload': <String, Object?>{
            'playlistId': 'PL1234567890',
            'index': 0,
          },
        },
      );
      expect(
        const YouTubePlayerCommand.setVolume(65).toJson()['payload'],
        <String, Object?>{'volume': 65},
      );
      expect(
        const YouTubePlayerCommand.setPlaybackRate(1.5).toJson()['payload'],
        <String, Object?>{'playbackRate': 1.5},
      );
      expect(
        const YouTubePlayerCommand.setSpherical(
          YouTubeSphericalProperties(
            yaw: 90,
            pitch: -15,
            roll: 0,
            fieldOfView: 80,
            enableOrientationSensor: true,
          ),
        ).toJson()['payload'],
        <String, Object?>{
          'yaw': 90.0,
          'pitch': -15.0,
          'roll': 0.0,
          'fieldOfView': 80.0,
          'enableOrientationSensor': true,
        },
      );

      expect(
        () => const YouTubePlayerCommand.cuePlaylist().encode(),
        throwsFormatException,
      );
      expect(
        () => const YouTubePlayerCommand.cuePlaylist(
          videoIds: <String>['bad'],
        ).encode(),
        throwsFormatException,
      );
      expect(
        () => const YouTubePlayerCommand.cuePlaylist(
          videoIds: <String>['abc123XYZ09'],
          index: 1,
        ).encode(),
        throwsFormatException,
      );
      expect(
        () => const YouTubePlayerCommand.setVolume(101).encode(),
        throwsFormatException,
      );
      expect(
        () => const YouTubePlayerCommand.setPlaybackRate(0).encode(),
        throwsFormatException,
      );
      expect(
        () => const YouTubePlayerCommand.setSpherical(
          YouTubeSphericalProperties(
            yaw: 360,
            pitch: 0,
            roll: 0,
            fieldOfView: 80,
          ),
        ).encode(),
        throwsFormatException,
      );
    });

    test('accepts only exact supported provider event messages', () {
      final ready = YouTubePlayerEvent.decode(
        '{"version":1,"kind":"event","type":"ready","payload":{}}',
      );
      expect(ready.type, YouTubePlayerEventType.ready);

      final state = YouTubePlayerEvent.decode(
        '{"version":1,"kind":"event","type":"state",'
        '"payload":{"code":1}}',
      );
      expect(state.state, YouTubeProviderPlayerState.playing);

      final error = YouTubePlayerEvent.decode(
        '{"version":1,"kind":"event","type":"error",'
        '"payload":{"code":153}}',
      );
      expect(error.errorCode, 153);

      expect(
        () => YouTubePlayerEvent.decode(
          '{"version":1,"kind":"event","type":"state",'
          '"payload":{"code":4}}',
        ),
        throwsFormatException,
      );
      expect(
        () => YouTubePlayerEvent.decode(
          '{"version":1,"kind":"event","type":"execute",'
          '"payload":{"script":"alert(1)"}}',
        ),
        throwsFormatException,
      );
    });

    test('decodes bounded player diagnostics and provider change events', () {
      final state = YouTubePlayerEvent.decode(
        '{"version":1,"kind":"event","type":"stateSnapshot",'
        '"payload":{"stateCode":1,"muted":false,"volume":75,'
        '"currentTime":12.5,"duration":120.0,"loadedFraction":0.8,'
        '"playbackRate":1.25,"availablePlaybackRates":[0.5,1,1.25,2],'
        '"playlistIndex":1,"playlist":["abc123XYZ09","def456UVW12"],'
        '"playlistTruncated":false}}',
      );
      expect(state.type, YouTubePlayerEventType.stateSnapshot);
      expect(state.stateSnapshot?.state, YouTubeProviderPlayerState.playing);
      expect(state.stateSnapshot?.volume, 75);
      expect(state.stateSnapshot?.playlistIndex, 1);
      expect(state.stateSnapshot?.playlist, <String>[
        'abc123XYZ09',
        'def456UVW12',
      ]);

      final spherical = YouTubePlayerEvent.decode(
        '{"version":1,"kind":"event","type":"sphericalSnapshot",'
        '"payload":{"yaw":90,"pitch":-10,"roll":0,"fieldOfView":80,'
        '"enableOrientationSensor":true}}',
      );
      expect(spherical.sphericalProperties?.yaw, 90);
      expect(spherical.sphericalProperties?.pitch, -10);
      expect(spherical.sphericalProperties?.enableOrientationSensor, isTrue);

      final captions = YouTubePlayerEvent.decode(
        '{"version":1,"kind":"event","type":"captionOptionsSnapshot",'
        '"payload":{"fontSize":1,'
        '"availableOptions":["fontSize","reload"]}}',
      );
      expect(captions.captionOptionsSnapshot?.fontSize, 1);
      expect(captions.captionOptionsSnapshot?.availableOptions, <String>[
        'fontSize',
        'reload',
      ]);

      final quality = YouTubePlayerEvent.decode(
        '{"version":1,"kind":"event","type":"playbackQualityChanged",'
        '"payload":{"quality":"hd1080"}}',
      );
      expect(quality.playbackQuality, 'hd1080');

      final rate = YouTubePlayerEvent.decode(
        '{"version":1,"kind":"event","type":"playbackRateChanged",'
        '"payload":{"playbackRate":1.5}}',
      );
      expect(rate.playbackRate, 1.5);

      expect(
        YouTubePlayerEvent.decode(
          '{"version":1,"kind":"event","type":"apiChanged","payload":{}}',
        ).type,
        YouTubePlayerEventType.apiChanged,
      );
      expect(
        () => YouTubePlayerEvent.decode(
          '{"version":1,"kind":"event","type":"stateSnapshot",'
          '"payload":{"stateCode":1,"muted":false,"volume":175,'
          '"currentTime":12.5,"duration":120.0,"loadedFraction":0.8,'
          '"playbackRate":1.25,"availablePlaybackRates":[1],'
          '"playlistIndex":0,"playlist":[],"playlistTruncated":false}}',
        ),
        throwsFormatException,
      );
    });

    test('maps all documented provider errors without invented reasons', () {
      expect(
        YouTubePlayerErrorPolicy.evaluate(
          2,
          recreationAlreadyUsed: false,
        ).action,
        YouTubePlayerRecoveryAction.reportIntegrationDefect,
      );
      expect(
        YouTubePlayerErrorPolicy.evaluate(
          5,
          recreationAlreadyUsed: false,
        ).retryableInPlayer,
        isTrue,
      );
      expect(
        YouTubePlayerErrorPolicy.evaluate(
          5,
          recreationAlreadyUsed: true,
        ).retryableInPlayer,
        isFalse,
      );
      expect(
        YouTubePlayerErrorPolicy.evaluate(
          100,
          recreationAlreadyUsed: false,
        ).action,
        YouTubePlayerRecoveryAction.refreshMetadataAndRemoveStaleResult,
      );
      for (final code in <int>[101, 150]) {
        expect(
          YouTubePlayerErrorPolicy.evaluate(
            code,
            recreationAlreadyUsed: false,
          ).action,
          YouTubePlayerRecoveryAction.openInYouTube,
        );
      }
      expect(
        YouTubePlayerErrorPolicy.evaluate(
          153,
          recreationAlreadyUsed: false,
        ).action,
        YouTubePlayerRecoveryAction.blockReleaseForIdentityConfiguration,
      );
    });
  });

  group('one-player lifecycle controller', () {
    test('mounts at the stable base URL and cues only after ready', () async {
      final port = _FakePlayerPort();
      final controller = _enabledController(port: port);

      final result = await controller.select(
        record: _video(),
        availableWidth: 320,
      );

      expect(result.eligible, isTrue);
      expect(port.mounts, hasLength(1));
      expect(
        port.mounts.single.baseUrl,
        Uri.parse('https://com.moolsocial.app/'),
      );
      expect(port.mounts.single.geometry.height, 200);
      expect(port.commands, isEmpty);

      await controller.onBridgeEvent(
        YouTubePlayerEvent.decode(
          '{"version":1,"kind":"event","type":"ready","payload":{}}',
        ),
      );

      expect(port.commands.single.type, YouTubePlayerCommandType.cue);
      expect(port.commands.single.videoId, 'abc123XYZ09');
      expect(controller.snapshot.status, YouTubeEmbeddedPlayerStatus.cued);
    });

    test(
      'refuses a second mounted player across independent callers',
      () async {
        final first = _enabledController(
          port: _FakePlayerPort(),
          lease: YouTubePlayerLease(),
        );
        final second = _enabledController(
          port: _FakePlayerPort(),
          lease: YouTubePlayerLease(),
        );

        await first.select(record: _video(), availableWidth: 320);
        await expectLater(
          second.select(record: _video(), availableWidth: 320),
          throwsStateError,
        );

        await first.dispose();
        await second.select(record: _video(), availableWidth: 320);
        expect(second.snapshot.mounted, isTrue);
      },
    );

    test('does not lose ready when it arrives during awaited mount', () async {
      final port = _FakePlayerPort();
      late YouTubeEmbeddedPlayerController controller;
      port.onMount = () => controller.onBridgeEvent(
        YouTubePlayerEvent.decode(
          '{"version":1,"kind":"event","type":"ready","payload":{}}',
        ),
      );
      controller = _enabledController(port: port);

      await controller.select(record: _video(), availableWidth: 320);

      expect(controller.snapshot.status, YouTubeEmbeddedPlayerStatus.cued);
      expect(port.commands.single.type, YouTubePlayerCommandType.cue);
    });

    test('gates state-changing commands until provider ready', () async {
      final port = _FakePlayerPort();
      final controller = _enabledController(port: port);
      await controller.select(record: _video(), availableWidth: 320);

      await expectLater(controller.playFromUserGesture(), throwsStateError);
      await expectLater(controller.pauseFromUserGesture(), throwsStateError);
      await expectLater(controller.seekFromUserGesture(2), throwsStateError);
      await expectLater(controller.setMuted(true), throwsStateError);
      await expectLater(controller.setCaptionFontSize(2), throwsStateError);
      expect(await controller.attemptVerifiedShortAutoplay(), isFalse);
      expect(port.commands, isEmpty);
    });

    test(
      'forwards bounded provider controls and records diagnostics',
      () async {
        final port = _FakePlayerPort();
        final controller = _enabledController(port: port);
        await controller.select(record: _video(), availableWidth: 320);
        await controller.onBridgeEvent(
          YouTubePlayerEvent.decode(
            '{"version":1,"kind":"event","type":"ready","payload":{}}',
          ),
        );
        port.commands.clear();

        await controller.stopFromUserGesture();
        await controller.playNextFromUserGesture();
        await controller.playPreviousFromUserGesture();
        await controller.playPlaylistIndexFromUserGesture(2);
        await controller.setVolumeFromUserGesture(70);
        await controller.setPlaybackRateFromUserGesture(1.5);
        await controller.setPlaylistLoop(true);
        await controller.setPlaylistShuffle(true);
        await controller.setCaptionFontSize(1);
        await controller.reloadCaptions();
        await controller.requestCaptionOptions();
        await controller.requestPlayerState();
        await controller.requestSphericalProperties();
        await controller.setSphericalProperties(
          const YouTubeSphericalProperties(
            yaw: 90,
            pitch: 0,
            roll: 0,
            fieldOfView: 80,
          ),
        );

        expect(
          port.commands.map((command) => command.type),
          <YouTubePlayerCommandType>[
            YouTubePlayerCommandType.stop,
            YouTubePlayerCommandType.next,
            YouTubePlayerCommandType.previous,
            YouTubePlayerCommandType.playAt,
            YouTubePlayerCommandType.setVolume,
            YouTubePlayerCommandType.setPlaybackRate,
            YouTubePlayerCommandType.setLoop,
            YouTubePlayerCommandType.setShuffle,
            YouTubePlayerCommandType.setCaptionFontSize,
            YouTubePlayerCommandType.reloadCaptions,
            YouTubePlayerCommandType.requestCaptionOptions,
            YouTubePlayerCommandType.requestState,
            YouTubePlayerCommandType.requestSpherical,
            YouTubePlayerCommandType.setSpherical,
          ],
        );

        await controller.onBridgeEvent(
          YouTubePlayerEvent.decode(
            '{"version":1,"kind":"event","type":"playbackQualityChanged",'
            '"payload":{"quality":"hd720"}}',
          ),
        );
        await controller.onBridgeEvent(
          YouTubePlayerEvent.decode(
            '{"version":1,"kind":"event","type":"playbackRateChanged",'
            '"payload":{"playbackRate":1.5}}',
          ),
        );
        await controller.onBridgeEvent(
          YouTubePlayerEvent.decode(
            '{"version":1,"kind":"event","type":"apiChanged","payload":{}}',
          ),
        );
        await controller.onBridgeEvent(
          YouTubePlayerEvent.decode(
            '{"version":1,"kind":"event","type":"stateSnapshot",'
            '"payload":{"stateCode":2,"muted":false,"volume":70,'
            '"currentTime":12,"duration":60,"loadedFraction":0.5,'
            '"playbackRate":1.5,"availablePlaybackRates":[1,1.5],'
            '"playlistIndex":0,"playlist":["abc123XYZ09"],'
            '"playlistTruncated":false}}',
          ),
        );
        await controller.onBridgeEvent(
          YouTubePlayerEvent.decode(
            '{"version":1,"kind":"event","type":"captionOptionsSnapshot",'
            '"payload":{"fontSize":1,'
            '"availableOptions":["fontSize","reload"]}}',
          ),
        );

        expect(controller.snapshot.playbackQuality, 'hd720');
        expect(controller.snapshot.playbackRate, 1.5);
        expect(controller.snapshot.apiRevision, 1);
        expect(controller.snapshot.playerState?.volume, 70);
        expect(controller.snapshot.captionOptions?.fontSize, 1);
      },
    );

    test('remounts when the selected player geometry changes', () async {
      final port = _FakePlayerPort();
      final controller = _enabledController(port: port);
      await controller.select(record: _video(), availableWidth: 320);
      await controller.onBridgeEvent(
        YouTubePlayerEvent.decode(
          '{"version":1,"kind":"event","type":"ready","payload":{}}',
        ),
      );

      await controller.select(
        record: _video(videoId: 'def456UVW12', verifiedShort: true),
        availableWidth: 320,
      );

      expect(port.detachCount, 1);
      expect(port.mounts, hasLength(2));
      expect(
        port.mounts.last.geometry.aspect,
        YouTubePlayerAspect.verifiedVerticalShort,
      );
      expect(port.mounts.last.geometry.height, greaterThan(568));
    });

    test('reuses one mount when selecting another eligible item', () async {
      final port = _FakePlayerPort();
      final controller = _enabledController(port: port);
      await controller.select(record: _video(), availableWidth: 320);
      await controller.onBridgeEvent(
        YouTubePlayerEvent.decode(
          '{"version":1,"kind":"event","type":"ready","payload":{}}',
        ),
      );

      await controller.select(
        record: _video(videoId: 'def456UVW12'),
        availableWidth: 320,
      );

      expect(port.mounts, hasLength(1));
      expect(port.commands.map((command) => command.videoId), <String?>[
        'abc123XYZ09',
        'def456UVW12',
      ]);
    });

    test('pauses below half visibility and never resumes itself', () async {
      final port = _FakePlayerPort();
      final controller = _enabledController(port: port);
      await controller.select(record: _video(), availableWidth: 320);
      await controller.onBridgeEvent(
        YouTubePlayerEvent.decode(
          '{"version":1,"kind":"event","type":"ready","payload":{}}',
        ),
      );
      await controller.onBridgeEvent(
        YouTubePlayerEvent.decode(
          '{"version":1,"kind":"event","type":"state",'
          '"payload":{"code":1}}',
        ),
      );

      await controller.onVisibleFractionChanged(0.5);
      await controller.onVisibleFractionChanged(1);

      expect(
        port.commands.where(
          (command) => command.type == YouTubePlayerCommandType.pause,
        ),
        hasLength(1),
      );
      expect(
        port.commands.where(
          (command) => command.type == YouTubePlayerCommandType.play,
        ),
        isEmpty,
      );
    });

    test('pauses for each unsafe lifecycle boundary', () async {
      final actions = <Future<void> Function(YouTubeEmbeddedPlayerController)>[
        (controller) => controller.onAppActiveChanged(false),
        (controller) => controller.onRouteVisibleChanged(false),
        (controller) => controller.onScreenUnlockedChanged(false),
        (controller) => controller.onAudioFocusChanged(false),
        (controller) => controller.onCallInterruptedChanged(true),
      ];

      for (final action in actions) {
        final port = _FakePlayerPort();
        final controller = _enabledController(port: port);
        await controller.select(record: _video(), availableWidth: 320);
        await controller.onBridgeEvent(
          YouTubePlayerEvent.decode(
            '{"version":1,"kind":"event","type":"ready","payload":{}}',
          ),
        );
        await action(controller);
        expect(port.commands.last.type, YouTubePlayerCommandType.pause);
        await controller.dispose();
      }
    });

    test('keeps Shorts autoplay behind all future-proof gates', () async {
      final disabledPort = _FakePlayerPort();
      final disabledAutoplay = _enabledController(port: disabledPort);
      await disabledAutoplay.select(
        record: _video(verifiedShort: true),
        availableWidth: 320,
      );
      await disabledAutoplay.onBridgeEvent(
        YouTubePlayerEvent.decode(
          '{"version":1,"kind":"event","type":"ready","payload":{}}',
        ),
      );
      expect(await disabledAutoplay.attemptVerifiedShortAutoplay(), isFalse);
      await disabledAutoplay.dispose();

      final port = _FakePlayerPort();
      final controller = _enabledController(
        port: port,
        shortsAutoplayEnabled: true,
      );
      await controller.select(
        record: _video(verifiedShort: true),
        availableWidth: 320,
      );
      await controller.onBridgeEvent(
        YouTubePlayerEvent.decode(
          '{"version":1,"kind":"event","type":"ready","payload":{}}',
        ),
      );
      controller.onReducedMotionChanged(true);
      expect(await controller.attemptVerifiedShortAutoplay(), isFalse);
      controller.onReducedMotionChanged(false);
      await controller.onVisibleFractionChanged(0.5);
      expect(await controller.attemptVerifiedShortAutoplay(), isFalse);
      await controller.onVisibleFractionChanged(1);
      expect(await controller.attemptVerifiedShortAutoplay(), isTrue);
      expect(port.commands.last.type, YouTubePlayerCommandType.load);
    });

    test('detaches before exposing an error and retries code 5 once', () async {
      final port = _FakePlayerPort();
      final controller = _enabledController(port: port);
      await controller.select(record: _video(), availableWidth: 320);

      await port.emitEvent(
        YouTubePlayerEvent.decode(
          '{"version":1,"kind":"event","type":"error",'
          '"payload":{"code":5}}',
        ),
      );

      expect(port.detachCount, 1);
      expect(controller.snapshot.mounted, isFalse);
      expect(controller.snapshot.failure?.retryable, isTrue);

      expect(await controller.retryPlayerFailureFromUser(), isTrue);
      expect(port.mounts, hasLength(2));

      await port.emitEvent(
        YouTubePlayerEvent.decode(
          '{"version":1,"kind":"event","type":"error",'
          '"payload":{"code":5}}',
        ),
      );
      await controller.select(record: _video(), availableWidth: 320);
      expect(
        port.mounts,
        hasLength(2),
        reason: 'Reselecting the same item must not reset its retry budget.',
      );
      expect(controller.snapshot.failure?.retryable, isFalse);
      expect(await controller.retryPlayerFailureFromUser(), isFalse);
    });

    test('ineligible selection clears stale provider recovery state', () async {
      final port = _FakePlayerPort();
      final controller = _enabledController(port: port);
      await controller.select(record: _video(), availableWidth: 320);
      await port.emitEvent(
        YouTubePlayerEvent.decode(
          '{"version":1,"kind":"event","type":"error",'
          '"payload":{"code":5}}',
        ),
      );

      final result = await controller.select(
        record: _video(embeddable: false),
        availableWidth: 320,
      );

      expect(result.eligible, isFalse);
      expect(controller.snapshot.failure, isNull);
      expect(await controller.retryPlayerFailureFromUser(), isFalse);
      expect(port.mounts, hasLength(1));
    });

    test(
      'normal detach invalidates immediately and retains the global lease',
      () async {
        final detachGate = Completer<void>();
        final firstPort = _FakePlayerPort()..onDetach = () => detachGate.future;
        final secondPort = _FakePlayerPort();
        final first = _enabledController(port: firstPort);
        final second = _enabledController(port: secondPort);
        await first.select(record: _video(), availableWidth: 320);

        final failure = firstPort.emitEvent(
          YouTubePlayerEvent.decode(
            '{"version":1,"kind":"event","type":"error",'
            '"payload":{"code":5}}',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(first.snapshot.mounted, isFalse);
        await expectLater(
          second.select(
            record: _video(videoId: 'def456UVW12'),
            availableWidth: 320,
          ),
          throwsStateError,
        );
        expect(secondPort.mounts, isEmpty);

        detachGate.complete();
        await failure;
        await second.select(
          record: _video(videoId: 'def456UVW12'),
          availableWidth: 320,
        );
        expect(secondPort.mounts, hasLength(1));
      },
    );

    test('selection waits for detach and stale failure cannot win', () async {
      final detachGate = Completer<void>();
      final port = _FakePlayerPort()..onDetach = () => detachGate.future;
      final controller = _enabledController(port: port);
      await controller.select(record: _video(), availableWidth: 320);

      final failure = port.emitEvent(
        YouTubePlayerEvent.decode(
          '{"version":1,"kind":"event","type":"error",'
          '"payload":{"code":5}}',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      final nextSelection = controller.select(
        record: _video(videoId: 'def456UVW12'),
        availableWidth: 320,
      );
      await Future<void>.delayed(Duration.zero);
      expect(port.mounts, hasLength(1));

      detachGate.complete();
      await Future.wait<void>([failure, nextSelection.then((_) {})]);

      expect(port.mounts, hasLength(2));
      expect(controller.snapshot.selectedVideoId, 'def456UVW12');
      expect(controller.snapshot.failure, isNull);
      expect(
        controller.snapshot.status,
        YouTubeEmbeddedPlayerStatus.waitingForProvider,
      );
    });

    test(
      'native terminal failure atomically tears down and releases the lease',
      () async {
        final lease = YouTubePlayerLease();
        final port = _FakePlayerPort();
        final controller = _enabledController(port: port, lease: lease);
        await controller.select(record: _video(), availableWidth: 320);

        await port.emitPlatformFailure(
          const YouTubeEmbeddedPlayerPlatformFailure(
            code: 'ready_timeout',
            message: 'The provider player did not become ready.',
          ),
        );

        expect(controller.snapshot.mounted, isFalse);
        expect(controller.snapshot.status, YouTubeEmbeddedPlayerStatus.failed);
        expect(controller.snapshot.failure, isNull);
        expect(controller.snapshot.platformFailure?.code, 'ready_timeout');
        expect(await controller.retryPlayerFailureFromUser(), isFalse);
        expect(lease.hasOwner, isFalse);
        expect(
          port.detachCount,
          0,
          reason: 'Native already destroyed the terminal WebView.',
        );
      },
    );

    test('disposes once and always releases the shared lease', () async {
      final lease = YouTubePlayerLease();
      final port = _FakePlayerPort();
      final controller = _enabledController(port: port, lease: lease);
      await controller.select(record: _video(), availableWidth: 320);
      await controller.onBridgeEvent(
        YouTubePlayerEvent.decode(
          '{"version":1,"kind":"event","type":"ready","payload":{}}',
        ),
      );

      await controller.dispose();
      await controller.dispose();

      expect(
        port.commands.where(
          (command) => command.type == YouTubePlayerCommandType.dispose,
        ),
        hasLength(1),
      );
      expect(port.detachCount, 1);
      expect(lease.hasOwner, isFalse);
      expect(controller.snapshot.status, YouTubeEmbeddedPlayerStatus.disposed);
    });

    test(
      'still detaches and releases when the dispose command fails',
      () async {
        final lease = YouTubePlayerLease();
        final port = _FakePlayerPort()..failDisposeCommand = true;
        final controller = _enabledController(port: port, lease: lease);
        await controller.select(record: _video(), availableWidth: 320);
        await controller.onBridgeEvent(
          YouTubePlayerEvent.decode(
            '{"version":1,"kind":"event","type":"ready","payload":{}}',
          ),
        );

        await expectLater(controller.dispose(), throwsStateError);

        expect(port.detachCount, 1);
        expect(lease.hasOwner, isFalse);
        expect(controller.snapshot.mounted, isFalse);
        expect(
          controller.snapshot.status,
          YouTubeEmbeddedPlayerStatus.disposed,
        );
      },
    );
  });
}

YouTubeEmbeddedPlayerController _enabledController({
  required _FakePlayerPort port,
  YouTubePlayerLease? lease,
  bool shortsAutoplayEnabled = false,
}) {
  final controller = YouTubeEmbeddedPlayerController(
    port,
    lease ?? YouTubePlayerLease(),
    config: YouTubeEmbeddedPlayerFeatureConfig(
      enabled: true,
      shortsAutoplayEnabled: shortsAutoplayEnabled,
    ),
  );
  addTearDown(controller.dispose);
  return controller;
}

YouTubeEmbeddedVideoRecord _video({
  String videoId = 'abc123XYZ09',
  bool verifiedShort = false,
  bool embeddable = true,
}) {
  return YouTubeEmbeddedVideoRecord(
    videoId: videoId,
    hasCurrentDataApiRecord: true,
    embeddable: embeddable,
    hasKnownDeviceRegionExclusion: false,
    isVerifiedVerticalShort: verifiedShort,
  );
}

class _PlayerMount {
  const _PlayerMount({
    required this.bootstrapHtml,
    required this.baseUrl,
    required this.geometry,
  });

  final String bootstrapHtml;
  final Uri baseUrl;
  final YouTubePlayerGeometry geometry;
}

class _FakePlayerPort implements YouTubeEmbeddedPlayerPort {
  final mounts = <_PlayerMount>[];
  final commands = <YouTubePlayerCommand>[];
  var detachCount = 0;
  var failDisposeCommand = false;
  Future<void> Function()? onMount;
  Future<void> Function()? onDetach;
  Future<void> Function(YouTubePlayerEvent event)? _onEvent;
  Future<void> Function(YouTubeEmbeddedPlayerPlatformFailure failure)?
  _onPlatformFailure;

  @override
  void bind({
    required Future<void> Function(YouTubePlayerEvent event) onEvent,
    required Future<void> Function(YouTubeEmbeddedPlayerPlatformFailure failure)
    onPlatformFailure,
  }) {
    _onEvent = onEvent;
    _onPlatformFailure = onPlatformFailure;
  }

  @override
  void unbind() {
    _onEvent = null;
    _onPlatformFailure = null;
  }

  Future<void> emitEvent(YouTubePlayerEvent event) async {
    await _onEvent?.call(event);
  }

  Future<void> emitPlatformFailure(
    YouTubeEmbeddedPlayerPlatformFailure failure,
  ) async {
    await _onPlatformFailure?.call(failure);
  }

  @override
  Future<void> mount({
    required String bootstrapHtml,
    required Uri baseUrl,
    required YouTubePlayerGeometry geometry,
  }) async {
    mounts.add(
      _PlayerMount(
        bootstrapHtml: bootstrapHtml,
        baseUrl: baseUrl,
        geometry: geometry,
      ),
    );
    await onMount?.call();
  }

  @override
  Future<void> send(YouTubePlayerCommand command) async {
    commands.add(command);
    if (failDisposeCommand &&
        command.type == YouTubePlayerCommandType.dispose) {
      throw StateError('dispose command failed');
    }
  }

  @override
  Future<void> detach() async {
    detachCount += 1;
    await onDetach?.call();
  }
}
