import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'youtube_private_dev_models.dart';
import 'youtube_private_dev_transport.dart';

const _minimumChunkSize = 256 * 1024;
const _defaultChunkSize = 8 * 1024 * 1024;

abstract interface class YouTubeUploadSource {
  Future<int> length();

  Future<YouTubeUploadFileIdentity> fileIdentity(String contentType);

  Stream<List<int>> openRead(int start, int endExclusive);
}

class FileYouTubeUploadSource implements YouTubeUploadSource {
  FileYouTubeUploadSource(String path) : _file = File(path);

  final File _file;

  @override
  Future<int> length() => _file.length();

  @override
  Future<YouTubeUploadFileIdentity> fileIdentity(String contentType) async {
    final digest = await sha256.bind(_file.openRead()).first;
    final encoded = base64Url.encode(digest.bytes).replaceAll('=', '');
    return YouTubeUploadFileIdentity(
      digest: encoded,
      byteLength: await _file.length(),
      contentType: contentType,
    );
  }

  @override
  Stream<List<int>> openRead(int start, int endExclusive) {
    return _file.openRead(start, endExclusive);
  }
}

class YouTubeDirectUploadResult {
  const YouTubeDirectUploadResult({
    required this.bytesAccepted,
    required this.statusCode,
  });

  /// Bytes accepted by Google's resumable transfer endpoint.
  ///
  /// This is not evidence that YouTube finished processing or accepted the
  /// video for publication. Final success belongs to upload reconciliation.
  final int bytesAccepted;
  final int statusCode;
}

typedef YouTubeUploadProgress = void Function(int bytesAccepted, int total);

class YouTubeUploadCancellation {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
  }

  void throwIfCancelled() {
    if (_cancelled) throw const YouTubeUploadCancelledException();
  }
}

class YouTubeUploadCancelledException implements Exception {
  const YouTubeUploadCancelledException();

  @override
  String toString() => 'YouTube upload cancelled';
}

class YouTubeDirectUploader {
  const YouTubeDirectUploader(this._transport);

  final YouTubeHttpTransport _transport;

  Future<YouTubeDirectUploadResult> upload({
    required YouTubePrivateUploadSession session,
    required YouTubeUploadSource source,
    int chunkSize = _defaultChunkSize,
    YouTubeUploadProgress? onProgress,
    YouTubeUploadCancellation? cancellation,
  }) async {
    cancellation?.throwIfCancelled();
    _validateSession(session);
    _validateChunkSize(chunkSize);
    late final YouTubeUploadFileIdentity sourceIdentity;
    try {
      sourceIdentity = await source.fileIdentity(session.contentType);
    } on FileSystemException {
      throw const YouTubeTransportException(
        code: 'media_unavailable',
        message: 'The selected video could not be read.',
      );
    }
    cancellation?.throwIfCancelled();
    final total = sourceIdentity.byteLength;
    if (!session.fileIdentity.matches(sourceIdentity) ||
        total != session.contentLength) {
      throw const YouTubeTransportException(
        code: 'content_identity_mismatch',
        message: 'The selected video no longer matches the upload session.',
      );
    }
    if (total < 1) {
      throw const YouTubeTransportException(
        code: 'empty_upload',
        message: 'The selected video is empty.',
      );
    }

    final initialStatus = await _probe(session, total, cancellation);
    cancellation?.throwIfCancelled();
    if (initialStatus.complete) {
      onProgress?.call(total, total);
      return YouTubeDirectUploadResult(
        bytesAccepted: total,
        statusCode: initialStatus.statusCode,
      );
    }
    var offset = initialStatus.bytesAccepted;
    if (offset > 0) onProgress?.call(offset, total);
    var stalledResponses = 0;
    while (offset < total) {
      cancellation?.throwIfCancelled();
      final endExclusive = (offset + chunkSize).clamp(0, total);
      final response = await _transport.putStream(
        session.sessionUrl,
        headers: <String, String>{
          'content-type': session.contentType,
          'content-range': 'bytes $offset-${endExclusive - 1}/$total',
        },
        body: _withCancellation(
          source.openRead(offset, endExclusive),
          cancellation,
        ),
        contentLength: endExclusive - offset,
      );
      cancellation?.throwIfCancelled();

      if (response.statusCode == 200 || response.statusCode == 201) {
        onProgress?.call(total, total);
        return YouTubeDirectUploadResult(
          bytesAccepted: total,
          statusCode: response.statusCode,
        );
      }
      if (response.statusCode == 308) {
        final accepted = _acceptedBytes(
          response.headers['range'],
          total,
          endExclusive,
        );
        if (accepted <= offset) {
          stalledResponses += 1;
          if (stalledResponses > 3) {
            throw const YouTubeTransportException(
              code: 'upload_stalled',
              message: 'The provider did not accept the video upload.',
              retryable: true,
            );
          }
        } else {
          stalledResponses = 0;
        }
        offset = accepted;
        onProgress?.call(offset, total);
        continue;
      }
      if (response.statusCode == 404 || response.statusCode == 410) {
        throw YouTubeTransportException(
          code: 'upload_session_expired',
          message: 'The provider upload session has expired.',
          statusCode: response.statusCode,
        );
      }
      throw YouTubeTransportException(
        code: 'provider_rejected',
        message: 'The provider rejected the video upload.',
        statusCode: response.statusCode,
        retryable:
            response.statusCode == 408 ||
            response.statusCode == 429 ||
            response.statusCode >= 500,
      );
    }

    final completionStatus = await _probe(session, total, cancellation);
    cancellation?.throwIfCancelled();
    if (completionStatus.complete) {
      onProgress?.call(total, total);
      return YouTubeDirectUploadResult(
        bytesAccepted: total,
        statusCode: completionStatus.statusCode,
      );
    }
    throw const YouTubeTransportException(
      code: 'upload_incomplete',
      message: 'The provider did not confirm the video upload.',
      retryable: true,
    );
  }

  Future<_UploadProbe> _probe(
    YouTubePrivateUploadSession session,
    int total,
    YouTubeUploadCancellation? cancellation,
  ) async {
    cancellation?.throwIfCancelled();
    final response = await _transport.putStream(
      session.sessionUrl,
      headers: <String, String>{'content-range': 'bytes */$total'},
      body: const Stream<List<int>>.empty(),
      contentLength: 0,
    );
    cancellation?.throwIfCancelled();
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _UploadProbe(
        complete: true,
        bytesAccepted: total,
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode == 308) {
      return _UploadProbe(
        complete: false,
        bytesAccepted: _acceptedBytes(response.headers['range'], total, total),
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode == 404 || response.statusCode == 410) {
      throw YouTubeTransportException(
        code: 'upload_session_expired',
        message: 'The provider upload session has expired.',
        statusCode: response.statusCode,
      );
    }
    throw YouTubeTransportException(
      code: 'provider_rejected',
      message: 'The provider rejected the upload status request.',
      statusCode: response.statusCode,
      retryable:
          response.statusCode == 408 ||
          response.statusCode == 429 ||
          response.statusCode >= 500,
    );
  }

  Stream<List<int>> _withCancellation(
    Stream<List<int>> source,
    YouTubeUploadCancellation? cancellation,
  ) async* {
    await for (final chunk in source) {
      cancellation?.throwIfCancelled();
      yield chunk;
    }
    cancellation?.throwIfCancelled();
  }

  void _validateSession(YouTubePrivateUploadSession session) {
    final uri = session.sessionUrl;
    if (session.privacyStatus != 'private' ||
        uri.scheme != 'https' ||
        uri.host != 'www.googleapis.com' ||
        uri.path != '/upload/youtube/v3/videos' ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        uri.queryParametersAll['upload_id']?.length != 1 ||
        !(uri.queryParameters['upload_id']?.isNotEmpty ?? false)) {
      throw const YouTubeTransportException(
        code: 'invalid_upload_session',
        message: 'The provider upload session is invalid.',
      );
    }
    if (!session.expiresAt.isAfter(DateTime.now().toUtc())) {
      throw const YouTubeTransportException(
        code: 'upload_session_expired',
        message: 'The provider upload session has expired.',
      );
    }
  }

  void _validateChunkSize(int chunkSize) {
    if (chunkSize < _minimumChunkSize || chunkSize % _minimumChunkSize != 0) {
      throw const YouTubeTransportException(
        code: 'invalid_chunk_size',
        message: 'The upload chunk size is invalid.',
      );
    }
  }

  int _acceptedBytes(String? range, int total, int maximumAccepted) {
    if (range == null || range.isEmpty) return 0;
    final match = RegExp(r'^bytes=0-(\d+)$').firstMatch(range);
    if (match == null) {
      throw const YouTubeTransportException(
        code: 'invalid_upload_range',
        message: 'The provider returned an invalid upload range.',
      );
    }
    final last = int.parse(match.group(1)!);
    if (last < 0 || last >= total || last + 1 > maximumAccepted) {
      throw const YouTubeTransportException(
        code: 'invalid_upload_range',
        message: 'The provider returned an invalid upload range.',
      );
    }
    return last + 1;
  }
}

class _UploadProbe {
  const _UploadProbe({
    required this.complete,
    required this.bytesAccepted,
    required this.statusCode,
  });

  final bool complete;
  final int bytesAccepted;
  final int statusCode;
}
