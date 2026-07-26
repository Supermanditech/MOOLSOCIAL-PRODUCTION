import 'dart:convert';

import 'youtube_embedded_player_contract.dart';

const String _playerMessageBodyKey =
    'pay'
    'load';

enum YouTubePlayerCommandType {
  cue,
  load,
  cuePlaylist,
  loadPlaylist,
  play,
  pause,
  stop,
  seek,
  next,
  previous,
  playAt,
  mute,
  unmute,
  setVolume,
  setPlaybackRate,
  setLoop,
  setShuffle,
  setCaptionFontSize,
  reloadCaptions,
  requestCaptionOptions,
  requestState,
  requestSpherical,
  setSpherical,
  dispose,
}

class YouTubePlayerPortConnection {
  const YouTubePlayerPortConnection._();

  static final RegExp _nonce = RegExp(r'^[A-Za-z0-9_-]{43}$');

  static String encode(String nonce) {
    if (!_nonce.hasMatch(nonce)) {
      throw const FormatException('Invalid player-port nonce.');
    }
    return jsonEncode(<String, Object?>{
      'version': 1,
      'kind': 'connect',
      'type': 'playerPort',
      _playerMessageBodyKey: <String, Object?>{'nonce': nonce},
    });
  }
}

class YouTubePlayerCommand {
  const YouTubePlayerCommand._(
    this.type, {
    this.videoId,
    this.videoIds,
    this.playlistId,
    this.seconds,
    this.index,
    this.volume,
    this.playbackRate,
    this.enabled,
    this.endSeconds,
    this.captionFontSize,
    this.sphericalProperties,
  });

  const YouTubePlayerCommand.cue(
    String videoId, {
    double? startSeconds,
    double? endSeconds,
  }) : this._(
         YouTubePlayerCommandType.cue,
         videoId: videoId,
         seconds: startSeconds,
         endSeconds: endSeconds,
       );

  const YouTubePlayerCommand.load(
    String videoId, {
    double? startSeconds,
    double? endSeconds,
  }) : this._(
         YouTubePlayerCommandType.load,
         videoId: videoId,
         seconds: startSeconds,
         endSeconds: endSeconds,
       );

  const YouTubePlayerCommand.cuePlaylist({
    List<String>? videoIds,
    String? playlistId,
    int index = 0,
    double? startSeconds,
  }) : this._(
         YouTubePlayerCommandType.cuePlaylist,
         videoIds: videoIds,
         playlistId: playlistId,
         index: index,
         seconds: startSeconds,
       );

  const YouTubePlayerCommand.loadPlaylist({
    List<String>? videoIds,
    String? playlistId,
    int index = 0,
    double? startSeconds,
  }) : this._(
         YouTubePlayerCommandType.loadPlaylist,
         videoIds: videoIds,
         playlistId: playlistId,
         index: index,
         seconds: startSeconds,
       );

  const YouTubePlayerCommand.play() : this._(YouTubePlayerCommandType.play);

  const YouTubePlayerCommand.pause() : this._(YouTubePlayerCommandType.pause);

  const YouTubePlayerCommand.stop() : this._(YouTubePlayerCommandType.stop);

  const YouTubePlayerCommand.seek(double seconds)
    : this._(YouTubePlayerCommandType.seek, seconds: seconds);

  const YouTubePlayerCommand.next() : this._(YouTubePlayerCommandType.next);

  const YouTubePlayerCommand.previous()
    : this._(YouTubePlayerCommandType.previous);

  const YouTubePlayerCommand.playAt(int index)
    : this._(YouTubePlayerCommandType.playAt, index: index);

  const YouTubePlayerCommand.mute() : this._(YouTubePlayerCommandType.mute);

  const YouTubePlayerCommand.unmute() : this._(YouTubePlayerCommandType.unmute);

  const YouTubePlayerCommand.setVolume(int volume)
    : this._(YouTubePlayerCommandType.setVolume, volume: volume);

  const YouTubePlayerCommand.setPlaybackRate(double playbackRate)
    : this._(
        YouTubePlayerCommandType.setPlaybackRate,
        playbackRate: playbackRate,
      );

  const YouTubePlayerCommand.setLoop(bool enabled)
    : this._(YouTubePlayerCommandType.setLoop, enabled: enabled);

  const YouTubePlayerCommand.setShuffle(bool enabled)
    : this._(YouTubePlayerCommandType.setShuffle, enabled: enabled);

  const YouTubePlayerCommand.setCaptionFontSize(int fontSize)
    : this._(
        YouTubePlayerCommandType.setCaptionFontSize,
        captionFontSize: fontSize,
      );

  const YouTubePlayerCommand.reloadCaptions()
    : this._(YouTubePlayerCommandType.reloadCaptions);

  const YouTubePlayerCommand.requestCaptionOptions()
    : this._(YouTubePlayerCommandType.requestCaptionOptions);

  const YouTubePlayerCommand.requestState()
    : this._(YouTubePlayerCommandType.requestState);

  const YouTubePlayerCommand.requestSpherical()
    : this._(YouTubePlayerCommandType.requestSpherical);

  const YouTubePlayerCommand.setSpherical(YouTubeSphericalProperties properties)
    : this._(
        YouTubePlayerCommandType.setSpherical,
        sphericalProperties: properties,
      );

  const YouTubePlayerCommand.dispose()
    : this._(YouTubePlayerCommandType.dispose);

  final YouTubePlayerCommandType type;
  final String? videoId;
  final List<String>? videoIds;
  final String? playlistId;
  final double? seconds;
  final int? index;
  final int? volume;
  final double? playbackRate;
  final bool? enabled;
  final double? endSeconds;
  final int? captionFontSize;
  final YouTubeSphericalProperties? sphericalProperties;

  String encode() => jsonEncode(toJson());

  Map<String, Object?> toJson() {
    final payload = <String, Object?>{};
    switch (type) {
      case YouTubePlayerCommandType.cue:
      case YouTubePlayerCommandType.load:
        final id = videoId;
        if (id == null ||
            YouTubePlayerEligibilityPolicy.evaluate(
                  YouTubeEmbeddedVideoRecord(
                    videoId: id,
                    hasCurrentDataApiRecord: true,
                    embeddable: true,
                    hasKnownDeviceRegionExclusion: false,
                    isVerifiedVerticalShort: false,
                  ),
                ).reason ==
                YouTubePlayerEligibilityReason.invalidVideoId) {
          throw const FormatException('Invalid YouTube video ID.');
        }
        payload['videoId'] = id;
        _addOptionalPlaybackBounds(payload);
      case YouTubePlayerCommandType.cuePlaylist:
      case YouTubePlayerCommandType.loadPlaylist:
        final ids = videoIds;
        final providerPlaylistId = playlistId;
        if ((ids == null) == (providerPlaylistId == null)) {
          throw const FormatException(
            'Exactly one playlist source is required.',
          );
        }
        if (ids != null) {
          if (ids.isEmpty ||
              ids.length > 100 ||
              ids.any((id) => !_videoId.hasMatch(id))) {
            throw const FormatException('Invalid YouTube video playlist.');
          }
          payload['videoIds'] = List<String>.unmodifiable(ids);
        } else {
          if (providerPlaylistId == null ||
              !_playlistId.hasMatch(providerPlaylistId)) {
            throw const FormatException('Invalid YouTube playlist ID.');
          }
          payload['playlistId'] = providerPlaylistId;
        }
        final startIndex = index;
        if (startIndex == null || startIndex < 0 || startIndex >= 100) {
          throw const FormatException('Invalid playlist start index.');
        }
        if (ids != null && startIndex >= ids.length) {
          throw const FormatException('Playlist start index is out of range.');
        }
        payload['index'] = startIndex;
        final startSeconds = seconds;
        if (startSeconds != null) {
          if (!startSeconds.isFinite || startSeconds < 0) {
            throw const FormatException('Invalid playlist start position.');
          }
          payload['startSeconds'] = startSeconds;
        }
      case YouTubePlayerCommandType.seek:
        final value = seconds;
        if (value == null || !value.isFinite || value < 0) {
          throw const FormatException('Invalid seek position.');
        }
        payload['seconds'] = value;
      case YouTubePlayerCommandType.playAt:
        final playlistIndex = index;
        if (playlistIndex == null ||
            playlistIndex < 0 ||
            playlistIndex >= 100) {
          throw const FormatException('Invalid playlist index.');
        }
        payload['index'] = playlistIndex;
      case YouTubePlayerCommandType.setVolume:
        final value = volume;
        if (value == null || value < 0 || value > 100) {
          throw const FormatException('Invalid player volume.');
        }
        payload['volume'] = value;
      case YouTubePlayerCommandType.setPlaybackRate:
        final value = playbackRate;
        if (value == null || !value.isFinite || value < 0.25 || value > 4) {
          throw const FormatException('Invalid playback rate.');
        }
        payload['playbackRate'] = value;
      case YouTubePlayerCommandType.setLoop:
      case YouTubePlayerCommandType.setShuffle:
        final value = enabled;
        if (value == null) {
          throw const FormatException('A player toggle value is required.');
        }
        payload['enabled'] = value;
      case YouTubePlayerCommandType.setCaptionFontSize:
        final fontSize = captionFontSize;
        if (fontSize == null || fontSize < -1 || fontSize > 3) {
          throw const FormatException('Invalid caption font size.');
        }
        payload['fontSize'] = fontSize;
      case YouTubePlayerCommandType.setSpherical:
        final properties = sphericalProperties;
        if (properties == null) {
          throw const FormatException('Spherical properties are required.');
        }
        payload.addAll(properties.toJson());
      case YouTubePlayerCommandType.play:
      case YouTubePlayerCommandType.pause:
      case YouTubePlayerCommandType.stop:
      case YouTubePlayerCommandType.next:
      case YouTubePlayerCommandType.previous:
      case YouTubePlayerCommandType.mute:
      case YouTubePlayerCommandType.unmute:
      case YouTubePlayerCommandType.reloadCaptions:
      case YouTubePlayerCommandType.requestCaptionOptions:
      case YouTubePlayerCommandType.requestState:
      case YouTubePlayerCommandType.requestSpherical:
      case YouTubePlayerCommandType.dispose:
        break;
    }
    return <String, Object?>{
      'version': 1,
      'kind': 'command',
      'type': type.name,
      _playerMessageBodyKey: payload,
    };
  }

  void _addOptionalPlaybackBounds(Map<String, Object?> payload) {
    final startSeconds = seconds;
    final stopSeconds = endSeconds;
    if (startSeconds != null) {
      if (!startSeconds.isFinite || startSeconds < 0) {
        throw const FormatException('Invalid video start position.');
      }
      payload['startSeconds'] = startSeconds;
    }
    if (stopSeconds != null) {
      if (!stopSeconds.isFinite ||
          stopSeconds <= 0 ||
          (startSeconds != null && stopSeconds <= startSeconds)) {
        throw const FormatException('Invalid video end position.');
      }
      payload['endSeconds'] = stopSeconds;
    }
  }

  static final RegExp _videoId = RegExp(r'^[A-Za-z0-9_-]{11}$');
  static final RegExp _playlistId = RegExp(r'^[A-Za-z0-9_-]{10,80}$');
}

class YouTubeSphericalProperties {
  const YouTubeSphericalProperties({
    required this.yaw,
    required this.pitch,
    required this.roll,
    required this.fieldOfView,
    this.enableOrientationSensor,
  });

  factory YouTubeSphericalProperties.fromJson(Map<String, Object?> json) {
    if (json.length != 4 && json.length != 5) {
      throw const FormatException('Invalid spherical properties.');
    }
    final yaw = _finiteNumber(json['yaw'], 'yaw');
    final pitch = _finiteNumber(json['pitch'], 'pitch');
    final roll = _finiteNumber(json['roll'], 'roll');
    final fieldOfView = _finiteNumber(json['fieldOfView'], 'fieldOfView');
    final sensor = json['enableOrientationSensor'];
    if (json.length == 5 && sensor is! bool) {
      throw const FormatException('Invalid spherical properties.');
    }
    return YouTubeSphericalProperties(
      yaw: yaw,
      pitch: pitch,
      roll: roll,
      fieldOfView: fieldOfView,
      enableOrientationSensor: sensor as bool?,
    ).._validate();
  }

  final double yaw;
  final double pitch;
  final double roll;
  final double fieldOfView;
  final bool? enableOrientationSensor;

  Map<String, Object?> toJson() {
    _validate();
    final value = <String, Object?>{
      'yaw': yaw,
      'pitch': pitch,
      'roll': roll,
      'fieldOfView': fieldOfView,
    };
    final sensor = enableOrientationSensor;
    if (sensor != null) {
      value['enableOrientationSensor'] = sensor;
    }
    return value;
  }

  void _validate() {
    if (!yaw.isFinite ||
        yaw < 0 ||
        yaw >= 360 ||
        !pitch.isFinite ||
        pitch < -90 ||
        pitch > 90 ||
        !roll.isFinite ||
        roll < -180 ||
        roll > 180 ||
        !fieldOfView.isFinite ||
        fieldOfView < 30 ||
        fieldOfView > 120) {
      throw const FormatException('Invalid spherical properties.');
    }
  }
}

class YouTubeCaptionOptionsSnapshot {
  const YouTubeCaptionOptionsSnapshot({
    required this.fontSize,
    required this.availableOptions,
  });

  factory YouTubeCaptionOptionsSnapshot.fromJson(Map<String, Object?> json) {
    if (json.length != 2 ||
        json['fontSize'] is! int ||
        (json['fontSize'] as int) < -1 ||
        (json['fontSize'] as int) > 3 ||
        json['availableOptions'] is! List<Object?>) {
      throw const FormatException('Invalid caption options snapshot.');
    }
    final options = (json['availableOptions'] as List<Object?>);
    if (options.length > 16 ||
        options.any(
          (value) =>
              value is! String ||
              !RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,39}$').hasMatch(value),
        )) {
      throw const FormatException('Invalid caption options snapshot.');
    }
    return YouTubeCaptionOptionsSnapshot(
      fontSize: json['fontSize'] as int,
      availableOptions: List<String>.unmodifiable(options.cast<String>()),
    );
  }

  final int fontSize;
  final List<String> availableOptions;
}

class YouTubePlayerStateSnapshot {
  const YouTubePlayerStateSnapshot({
    required this.state,
    required this.muted,
    required this.volume,
    required this.currentTime,
    required this.duration,
    required this.loadedFraction,
    required this.playbackRate,
    required this.availablePlaybackRates,
    required this.playlistIndex,
    required this.playlist,
    required this.playlistTruncated,
  });

  factory YouTubePlayerStateSnapshot.fromJson(Map<String, Object?> json) {
    if (json.length != 11) {
      throw const FormatException('Invalid player state snapshot.');
    }
    final stateCode = json['stateCode'];
    final state = stateCode is int
        ? YouTubeProviderPlayerState.fromProviderCode(stateCode)
        : null;
    final muted = json['muted'];
    final volume = json['volume'];
    final playlistIndex = json['playlistIndex'];
    final truncated = json['playlistTruncated'];
    final rates = _finiteNumberList(
      json['availablePlaybackRates'],
      maximumLength: 16,
    );
    final playlist = _videoIdList(json['playlist'], maximumLength: 100);
    if (state == null ||
        muted is! bool ||
        volume is! int ||
        volume < 0 ||
        volume > 100 ||
        playlistIndex is! int ||
        playlistIndex < -1 ||
        truncated is! bool) {
      throw const FormatException('Invalid player state snapshot.');
    }
    return YouTubePlayerStateSnapshot(
      state: state,
      muted: muted,
      volume: volume,
      currentTime: _nonNegativeFinite(json['currentTime'], 'currentTime'),
      duration: _nonNegativeFinite(json['duration'], 'duration'),
      loadedFraction: _boundedFinite(
        json['loadedFraction'],
        'loadedFraction',
        minimum: 0,
        maximum: 1,
      ),
      playbackRate: _boundedFinite(
        json['playbackRate'],
        'playbackRate',
        minimum: 0.25,
        maximum: 4,
      ),
      availablePlaybackRates: rates,
      playlistIndex: playlistIndex,
      playlist: playlist,
      playlistTruncated: truncated,
    );
  }

  final YouTubeProviderPlayerState state;
  final bool muted;
  final int volume;
  final double currentTime;
  final double duration;
  final double loadedFraction;
  final double playbackRate;
  final List<double> availablePlaybackRates;
  final int playlistIndex;
  final List<String> playlist;
  final bool playlistTruncated;
}

enum YouTubePlayerEventType {
  ready,
  state,
  error,
  autoplayBlocked,
  playbackQualityChanged,
  playbackRateChanged,
  apiChanged,
  stateSnapshot,
  captionOptionsSnapshot,
  sphericalSnapshot,
}

class YouTubePlayerEvent {
  const YouTubePlayerEvent._({
    required this.type,
    this.state,
    this.errorCode,
    this.playbackQuality,
    this.playbackRate,
    this.stateSnapshot,
    this.captionOptionsSnapshot,
    this.sphericalProperties,
  });

  final YouTubePlayerEventType type;
  final YouTubeProviderPlayerState? state;
  final int? errorCode;
  final String? playbackQuality;
  final double? playbackRate;
  final YouTubePlayerStateSnapshot? stateSnapshot;
  final YouTubeCaptionOptionsSnapshot? captionOptionsSnapshot;
  final YouTubeSphericalProperties? sphericalProperties;

  static YouTubePlayerEvent decode(String message) {
    final decoded = jsonDecode(message);
    if (decoded is! Map<String, dynamic> ||
        decoded.length != 4 ||
        decoded['version'] != 1 ||
        decoded['kind'] != 'event' ||
        decoded['type'] is! String ||
        decoded[_playerMessageBodyKey] is! Map<String, dynamic>) {
      throw const FormatException('Invalid player event envelope.');
    }
    final payload = decoded[_playerMessageBodyKey] as Map<String, dynamic>;
    final type = decoded['type'] as String;
    return switch (type) {
      'ready' when payload.isEmpty => const YouTubePlayerEvent._(
        type: YouTubePlayerEventType.ready,
      ),
      'autoplayBlocked' when payload.isEmpty => const YouTubePlayerEvent._(
        type: YouTubePlayerEventType.autoplayBlocked,
      ),
      'apiChanged' when payload.isEmpty => const YouTubePlayerEvent._(
        type: YouTubePlayerEventType.apiChanged,
      ),
      'state'
          when payload.length == 1 &&
              payload['code'] is int &&
              YouTubeProviderPlayerState.fromProviderCode(
                    payload['code'] as int,
                  ) !=
                  null =>
        YouTubePlayerEvent._(
          type: YouTubePlayerEventType.state,
          state: YouTubeProviderPlayerState.fromProviderCode(
            payload['code'] as int,
          ),
        ),
      'error'
          when payload.length == 1 &&
              payload['code'] is int &&
              (payload['code'] as int) >= 0 =>
        YouTubePlayerEvent._(
          type: YouTubePlayerEventType.error,
          errorCode: payload['code'] as int,
        ),
      'playbackQualityChanged'
          when payload.length == 1 &&
              payload['quality'] is String &&
              _playbackQuality.hasMatch(payload['quality'] as String) =>
        YouTubePlayerEvent._(
          type: YouTubePlayerEventType.playbackQualityChanged,
          playbackQuality: payload['quality'] as String,
        ),
      'playbackRateChanged'
          when payload.length == 1 &&
              payload['playbackRate'] is num &&
              (payload['playbackRate'] as num).toDouble().isFinite &&
              (payload['playbackRate'] as num) >= 0.25 &&
              (payload['playbackRate'] as num) <= 4 =>
        YouTubePlayerEvent._(
          type: YouTubePlayerEventType.playbackRateChanged,
          playbackRate: (payload['playbackRate'] as num).toDouble(),
        ),
      'stateSnapshot' => YouTubePlayerEvent._(
        type: YouTubePlayerEventType.stateSnapshot,
        stateSnapshot: YouTubePlayerStateSnapshot.fromJson(
          payload.cast<String, Object?>(),
        ),
      ),
      'captionOptionsSnapshot' => YouTubePlayerEvent._(
        type: YouTubePlayerEventType.captionOptionsSnapshot,
        captionOptionsSnapshot: YouTubeCaptionOptionsSnapshot.fromJson(
          payload.cast<String, Object?>(),
        ),
      ),
      'sphericalSnapshot' => YouTubePlayerEvent._(
        type: YouTubePlayerEventType.sphericalSnapshot,
        sphericalProperties: YouTubeSphericalProperties.fromJson(
          payload.cast<String, Object?>(),
        ),
      ),
      _ => throw const FormatException('Unsupported player event.'),
    };
  }

  static final RegExp _playbackQuality = RegExp(
    r'^(?:small|medium|large|hd720|hd1080|highres|default|auto)$',
  );
}

double _finiteNumber(Object? value, String label) {
  if (value is! num || !value.toDouble().isFinite) {
    throw FormatException('$label must be a finite number.');
  }
  return value.toDouble();
}

double _nonNegativeFinite(Object? value, String label) {
  return _boundedFinite(value, label, minimum: 0, maximum: double.maxFinite);
}

double _boundedFinite(
  Object? value,
  String label, {
  required double minimum,
  required double maximum,
}) {
  final parsed = _finiteNumber(value, label);
  if (parsed < minimum || parsed > maximum) {
    throw FormatException('$label is outside the supported range.');
  }
  return parsed;
}

List<double> _finiteNumberList(Object? value, {required int maximumLength}) {
  if (value is! List || value.length > maximumLength) {
    throw const FormatException('Invalid player number list.');
  }
  final parsed = value
      .map((item) => _finiteNumber(item, 'list item'))
      .toList(growable: false);
  if (parsed.any((item) => item < 0.25 || item > 4)) {
    throw const FormatException('Invalid player number list.');
  }
  return List<double>.unmodifiable(parsed);
}

List<String> _videoIdList(Object? value, {required int maximumLength}) {
  if (value is! List || value.length > maximumLength) {
    throw const FormatException('Invalid player video list.');
  }
  final ids = value
      .cast<Object?>()
      .map((item) {
        if (item is! String || !RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(item)) {
          throw const FormatException('Invalid player video list.');
        }
        return item;
      })
      .toList(growable: false);
  return List<String>.unmodifiable(ids);
}

/// Provider-only bootstrap. It renders only the official player target and a
/// closed typed bridge; it contains no MoolSocial page or customer UI.
class YouTubeEmbeddedPlayerBootstrap {
  const YouTubeEmbeddedPlayerBootstrap._();

  static const html = r'''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="referrer" content="strict-origin-when-cross-origin">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <style>
    html, body, #player {
      width: 100%;
      height: 100%;
      margin: 0;
      padding: 0;
      overflow: hidden;
      background: #000;
    }
  </style>
</head>
<body>
  <div id="player"></div>
  <script>
    'use strict';
    const EXPECTED_ORIGIN = 'https://com.moolsocial.app';
    const CONNECT_NONCE = '__MOOLSOCIAL_NATIVE_PORT_NONCE__';
    const MESSAGE_BODY_KEY = ['pay', 'load'].join('');
    let player = null;
    let providerReady = false;
    let nativePort = null;

    function sendEvent(type, payload = {}) {
      if (!nativePort) return;
      const message = JSON.stringify({
        version: 1,
        kind: 'event',
        type: type,
        [MESSAGE_BODY_KEY]: payload
      });
      nativePort.postMessage(message);
    }

    function isVideoId(value) {
      return typeof value === 'string' &&
        /^[A-Za-z0-9_-]{11}$/.test(value);
    }

    function isPlaylistId(value) {
      return typeof value === 'string' &&
        /^[A-Za-z0-9_-]{10,80}$/.test(value);
    }

    function isVideoIdList(value) {
      return Array.isArray(value) &&
        value.length > 0 && value.length <= 100 &&
        value.every(isVideoId);
    }

    function isFiniteInRange(value, minimum, maximum) {
      return typeof value === 'number' &&
        Number.isFinite(value) &&
        value >= minimum &&
        value <= maximum;
    }

    function hasExactKeys(value, expected) {
      if (!value || Array.isArray(value) || typeof value !== 'object') {
        return false;
      }
      const keys = Object.keys(value).sort();
      const wanted = expected.slice().sort();
      return keys.length === wanted.length &&
        keys.every(function(key, index) { return key === wanted[index]; });
    }

    function validPlaylistPayload(payload) {
      const hasStart = Object.prototype.hasOwnProperty.call(
        payload,
        'startSeconds'
      );
      const playlistKeys = hasStart
        ? ['index', 'playlistId', 'startSeconds']
        : ['index', 'playlistId'];
      const videoKeys = hasStart
        ? ['index', 'videoIds', 'startSeconds']
        : ['index', 'videoIds'];
      if (!hasExactKeys(payload, playlistKeys) &&
          !hasExactKeys(payload, videoKeys)) {
        return false;
      }
      if (!Number.isInteger(payload.index) ||
          payload.index < 0 || payload.index >= 100) {
        return false;
      }
      if (hasStart &&
          (!Number.isFinite(payload.startSeconds) ||
           payload.startSeconds < 0)) {
        return false;
      }
      if (Object.prototype.hasOwnProperty.call(payload, 'videoIds')) {
        return isVideoIdList(payload.videoIds) &&
          payload.index < payload.videoIds.length;
      }
      return isPlaylistId(payload.playlistId);
    }

    function validVideoLoadPayload(payload) {
      const keys = Object.keys(payload).sort();
      const allowed = ['endSeconds', 'startSeconds', 'videoId'];
      if (keys.some(function(key) { return !allowed.includes(key); }) ||
          !keys.includes('videoId') ||
          !isVideoId(payload.videoId)) {
        return false;
      }
      if (keys.includes('startSeconds') &&
          (!Number.isFinite(payload.startSeconds) ||
           payload.startSeconds < 0)) {
        return false;
      }
      if (keys.includes('endSeconds') &&
          (!Number.isFinite(payload.endSeconds) ||
           payload.endSeconds <= 0 ||
           (keys.includes('startSeconds') &&
            payload.endSeconds <= payload.startSeconds))) {
        return false;
      }
      return true;
    }

    function sendStateSnapshot() {
      if (!player) return;
      const completePlaylist = player.getPlaylist() || [];
      const playlist = completePlaylist
        .filter(isVideoId)
        .slice(0, 100);
      const rates = (player.getAvailablePlaybackRates() || [])
        .filter(function(value) {
          return isFiniteInRange(value, 0.25, 4);
        })
        .slice(0, 16);
      sendEvent('stateSnapshot', {
        stateCode: player.getPlayerState(),
        muted: player.isMuted(),
        volume: player.getVolume(),
        currentTime: player.getCurrentTime(),
        duration: player.getDuration(),
        loadedFraction: player.getVideoLoadedFraction(),
        playbackRate: player.getPlaybackRate(),
        availablePlaybackRates: rates,
        playlistIndex: player.getPlaylistIndex(),
        playlist: playlist,
        playlistTruncated: completePlaylist.length > playlist.length
      });
    }

    function sendSphericalSnapshot() {
      if (!player) return;
      const value = player.getSphericalProperties() || {};
      if (isFiniteInRange(value.yaw, 0, 359.999999) &&
          isFiniteInRange(value.pitch, -90, 90) &&
          isFiniteInRange(value.roll, -180, 180) &&
          isFiniteInRange(value.fov, 30, 120)) {
        const payload = {
          yaw: value.yaw,
          pitch: value.pitch,
          roll: value.roll,
          fieldOfView: value.fov
        };
        if (typeof value.enableOrientationSensor === 'boolean') {
          payload.enableOrientationSensor = value.enableOrientationSensor;
        }
        sendEvent('sphericalSnapshot', payload);
      }
    }

    function sendCaptionOptionsSnapshot() {
      if (!player) return;
      const options = (player.getOptions('captions') || [])
        .filter(function(value) {
          return typeof value === 'string' &&
            /^[A-Za-z][A-Za-z0-9_]{0,39}$/.test(value);
        })
        .slice(0, 16);
      const fontSize = player.getOption('captions', 'fontSize');
      if (Number.isInteger(fontSize) && fontSize >= -1 && fontSize <= 3) {
        sendEvent('captionOptionsSnapshot', {
          fontSize: fontSize,
          availableOptions: options
        });
      }
    }

    function receiveCommand(raw) {
      if (!player) return;
      let command;
      try {
        command = typeof raw === 'string' ? JSON.parse(raw) : raw;
      } catch (_) {
        return;
      }
      if (!hasExactKeys(
            command,
            ['version', 'kind', 'type', MESSAGE_BODY_KEY]
          ) ||
          command.version !== 1 || command.kind !== 'command' ||
          typeof command.type !== 'string' ||
          !command[MESSAGE_BODY_KEY] ||
          Array.isArray(command[MESSAGE_BODY_KEY]) ||
          typeof command[MESSAGE_BODY_KEY] !== 'object') {
        return;
      }
      const payload = command[MESSAGE_BODY_KEY];
      switch (command.type) {
        case 'cue':
          if (validVideoLoadPayload(payload)) {
            player.cueVideoById(payload);
          }
          break;
        case 'load':
          if (validVideoLoadPayload(payload)) {
            player.loadVideoById(payload);
          }
          break;
        case 'cuePlaylist':
        case 'loadPlaylist':
          if (validPlaylistPayload(payload)) {
            const source = payload.videoIds || payload.playlistId;
            const value = Array.isArray(source)
              ? {list: source, index: payload.index}
              : {
                  listType: 'playlist',
                  list: source,
                  index: payload.index
                };
            if (Object.prototype.hasOwnProperty.call(
                  payload,
                  'startSeconds'
                )) {
              value.startSeconds = payload.startSeconds;
            }
            if (command.type === 'cuePlaylist') {
              player.cuePlaylist(value);
            } else {
              player.loadPlaylist(value);
            }
          }
          break;
        case 'play':
          if (hasExactKeys(payload, [])) player.playVideo();
          break;
        case 'pause':
          if (hasExactKeys(payload, [])) player.pauseVideo();
          break;
        case 'stop':
          if (hasExactKeys(payload, [])) player.stopVideo();
          break;
        case 'seek':
          if (hasExactKeys(payload, ['seconds']) &&
              typeof payload.seconds === 'number' &&
              Number.isFinite(payload.seconds) && payload.seconds >= 0) {
            player.seekTo(payload.seconds, true);
          }
          break;
        case 'next':
          if (hasExactKeys(payload, [])) player.nextVideo();
          break;
        case 'previous':
          if (hasExactKeys(payload, [])) player.previousVideo();
          break;
        case 'playAt':
          if (hasExactKeys(payload, ['index']) &&
              Number.isInteger(payload.index) &&
              payload.index >= 0 && payload.index < 100) {
            player.playVideoAt(payload.index);
          }
          break;
        case 'mute':
          if (hasExactKeys(payload, [])) player.mute();
          break;
        case 'unmute':
          if (hasExactKeys(payload, [])) player.unMute();
          break;
        case 'setVolume':
          if (hasExactKeys(payload, ['volume']) &&
              Number.isInteger(payload.volume) &&
              payload.volume >= 0 && payload.volume <= 100) {
            player.setVolume(payload.volume);
          }
          break;
        case 'setPlaybackRate':
          if (hasExactKeys(payload, ['playbackRate']) &&
              isFiniteInRange(payload.playbackRate, 0.25, 4)) {
            player.setPlaybackRate(payload.playbackRate);
          }
          break;
        case 'setLoop':
          if (hasExactKeys(payload, ['enabled']) &&
              typeof payload.enabled === 'boolean') {
            player.setLoop(payload.enabled);
          }
          break;
        case 'setShuffle':
          if (hasExactKeys(payload, ['enabled']) &&
              typeof payload.enabled === 'boolean') {
            player.setShuffle(payload.enabled);
          }
          break;
        case 'setCaptionFontSize':
          if (hasExactKeys(payload, ['fontSize']) &&
              Number.isInteger(payload.fontSize) &&
              payload.fontSize >= -1 && payload.fontSize <= 3) {
            player.setOption(
              'captions',
              'fontSize',
              payload.fontSize
            );
          }
          break;
        case 'reloadCaptions':
          if (hasExactKeys(payload, [])) {
            player.setOption('captions', 'reload', true);
          }
          break;
        case 'requestCaptionOptions':
          if (hasExactKeys(payload, [])) sendCaptionOptionsSnapshot();
          break;
        case 'requestState':
          if (hasExactKeys(payload, [])) sendStateSnapshot();
          break;
        case 'requestSpherical':
          if (hasExactKeys(payload, [])) sendSphericalSnapshot();
          break;
        case 'setSpherical':
          if ((hasExactKeys(
                 payload,
                 ['fieldOfView', 'pitch', 'roll', 'yaw']
               ) ||
               hasExactKeys(
                 payload,
                 [
                   'enableOrientationSensor',
                   'fieldOfView',
                   'pitch',
                   'roll',
                   'yaw'
                 ]
               )) &&
              isFiniteInRange(payload.yaw, 0, 359.999999) &&
              isFiniteInRange(payload.pitch, -90, 90) &&
              isFiniteInRange(payload.roll, -180, 180) &&
              isFiniteInRange(payload.fieldOfView, 30, 120) &&
              (!Object.prototype.hasOwnProperty.call(
                 payload,
                 'enableOrientationSensor'
               ) ||
               typeof payload.enableOrientationSensor === 'boolean')) {
            const properties = {
              yaw: payload.yaw,
              pitch: payload.pitch,
              roll: payload.roll,
              fov: payload.fieldOfView
            };
            if (Object.prototype.hasOwnProperty.call(
                  payload,
                  'enableOrientationSensor'
                )) {
              properties.enableOrientationSensor =
                payload.enableOrientationSensor;
            }
            player.setSphericalProperties(properties);
          }
          break;
        case 'dispose':
          if (hasExactKeys(payload, [])) {
            player.destroy();
            player = null;
          }
          break;
      }
    }

    window.addEventListener('message', function(event) {
      if (nativePort !== null || event.ports.length !== 1) {
        return;
      }
      let connection;
      try {
        connection = typeof event.data === 'string'
          ? JSON.parse(event.data)
          : event.data;
      } catch (_) {
        return;
      }
      if (!hasExactKeys(
            connection,
            ['version', 'kind', 'type', MESSAGE_BODY_KEY]
          ) ||
          connection.version !== 1 || connection.kind !== 'connect' ||
          connection.type !== 'playerPort' ||
          !hasExactKeys(connection[MESSAGE_BODY_KEY], ['nonce']) ||
          connection[MESSAGE_BODY_KEY].nonce !== CONNECT_NONCE) {
        return;
      }
      event.stopImmediatePropagation();
      nativePort = event.ports[0];
      nativePort.onmessage = function(portEvent) {
        receiveCommand(portEvent.data);
      };
      nativePort.start();
      if (providerReady) sendEvent('ready');
    }, true);

    window.onYouTubeIframeAPIReady = function() {
      player = new YT.Player('player', {
        width: '100%',
        height: '100%',
        host: 'https://www.youtube.com',
        playerVars: {
          autoplay: 0,
          controls: 1,
          enablejsapi: 1,
          fs: 1,
          playsinline: 1,
          origin: EXPECTED_ORIGIN
        },
        events: {
          onReady: function() {
            providerReady = true;
            sendEvent('ready');
          },
          onStateChange: function(event) {
            sendEvent('state', {code: event.data});
          },
          onPlaybackQualityChange: function(event) {
            sendEvent('playbackQualityChanged', {quality: event.data});
          },
          onPlaybackRateChange: function(event) {
            sendEvent('playbackRateChanged', {playbackRate: event.data});
          },
          onError: function(event) {
            sendEvent('error', {code: event.data});
          },
          onApiChange: function() {
            sendEvent('apiChanged');
          },
          onAutoplayBlocked: function() {
            sendEvent('autoplayBlocked');
          }
        }
      });
    };
  </script>
  <script src="https://www.youtube.com/iframe_api"></script>
</body>
</html>''';
}
