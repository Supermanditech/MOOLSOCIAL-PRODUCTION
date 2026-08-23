import 'youtube_private_dev_client.dart';
import 'youtube_private_dev_models.dart';
import 'youtube_private_dev_uploader.dart';

/// Coordinates the private-only Dev proof without proxying media through
/// Firebase Functions or a MoolSocial storage service.
class YouTubePrivateDevUploadWorkflow {
  factory YouTubePrivateDevUploadWorkflow({
    required YouTubePrivateDevClient client,
    required YouTubeDirectUploader uploader,
  }) {
    return YouTubePrivateDevUploadWorkflow._(client, uploader);
  }

  const YouTubePrivateDevUploadWorkflow._(this._client, this._uploader);

  final YouTubePrivateDevClient _client;
  final YouTubeDirectUploader _uploader;

  Future<YouTubeVideoSummary> uploadPrivate({
    required String idempotencyKey,
    required String contentType,
    required YouTubeUploadSource source,
    required YouTubePrivateUploadMetadata metadata,
    YouTubeUploadProgress? onProgress,
    YouTubeUploadCancellation? cancellation,
    int maximumProcessingAttempts = 12,
    Duration processingInterval = const Duration(seconds: 5),
    Future<void> Function(Duration duration)? delay,
  }) async {
    cancellation?.throwIfCancelled();
    final fileIdentity = await source.fileIdentity(contentType);
    cancellation?.throwIfCancelled();
    final session = await _client.beginPrivateUpload(
      idempotencyKey: idempotencyKey,
      fileIdentity: fileIdentity,
      metadata: metadata,
    );
    await _uploader.upload(
      session: session,
      source: source,
      onProgress: onProgress,
      cancellation: cancellation,
    );
    cancellation?.throwIfCancelled();
    return _client.pollUpload(
      jobKey: session.jobKey,
      maximumAttempts: maximumProcessingAttempts,
      interval: processingInterval,
      delay: delay,
    );
  }
}
