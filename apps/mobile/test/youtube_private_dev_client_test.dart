import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_app_check.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_client.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_models.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_transport.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_uploader.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_workflow.dart';

void main() {
  group('private Dev App Check gate', () {
    test(
      'compiled application path is disabled without the dart define',
      () async {
        var activationCount = 0;

        final activated = await activateYouTubePrivateDevAppCheckIfEnabled(
          useEmulators: true,
          firebaseProjectId: 'demo-moolsocial-local',
          activate: () async {
            activationCount += 1;
          },
        );

        expect(youtubePrivateDevProofEnabled, isFalse);
        expect(activated, isFalse);
        expect(activationCount, 0);
      },
    );

    test('is a no-op unless the explicit proof flag is enabled', () async {
      var activationCount = 0;

      final activated = await activateYouTubePrivateDevAppCheckForTesting(
        enabled: false,
        useEmulators: true,
        firebaseProjectId: 'demo-moolsocial-local',
        activate: () async {
          activationCount += 1;
        },
      );

      expect(activated, isFalse);
      expect(activationCount, 0);
    });

    test('fails closed outside the dedicated Dev project', () async {
      expect(
        () => activateYouTubePrivateDevAppCheckForTesting(
          enabled: true,
          useEmulators: false,
          firebaseProjectId: 'moolsocial-staging-503018',
          activate: () async {},
        ),
        throwsStateError,
      );
    });

    test('activates once for an explicit dedicated Dev proof', () async {
      var activationCount = 0;

      final activated = await activateYouTubePrivateDevAppCheckForTesting(
        enabled: true,
        useEmulators: false,
        firebaseProjectId: youtubePrivateDevProjectId,
        activate: () async {
          activationCount += 1;
        },
      );

      expect(activated, isTrue);
      expect(activationCount, 1);
    });
  });

  group('YouTubePrivateDevClient', () {
    late _FakeTransport transport;
    late _FakeCredentials credentials;
    late YouTubePrivateDevClient client;

    setUp(() {
      transport = _FakeTransport();
      credentials = _FakeCredentials();
      client = YouTubePrivateDevClient.forTesting(
        providerEndpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/'
          'youtubeProvider',
        ),
        transport: transport,
        credentials: credentials,
        proofEnabled: true,
        firebaseProjectId: youtubePrivateDevProjectId,
        requestId: () => 'request-fixed',
      );
    });

    test('uses standard App Check without Auth for capabilities', () async {
      transport.queueJson(<String, Object?>{
        'ok': true,
        'data': <String, Object?>{
          'environment': 'dev',
          'publicData': true,
          'ownerConnect': true,
          'privateUpload': true,
          'ownerAnalytics': true,
          'publicOrUnlistedUpload': false,
        },
      });

      final capabilities = await client.capabilities();

      expect(capabilities.environment, 'dev');
      expect(capabilities.privateUpload, isTrue);
      expect(capabilities.publicOrUnlistedUpload, isFalse);
      expect(credentials.appCheckModes, [YouTubeAppCheckTokenMode.standard]);
      expect(credentials.idTokenCalls, 0);
      expect(transport.posts.single.headers['authorization'], isNull);
      expect(
        transport.posts.single.headers['x-firebase-appcheck'],
        'standard-app-check',
      );
      expect(transport.posts.single.body['operation'], 'capabilities');
    });

    test('parses public pages and sends explicit pagination', () async {
      transport.queueJson(<String, Object?>{
        'ok': true,
        'data': <String, Object?>{
          'items': <Object?>[_videoJson()],
          'nextPageToken': 'next-page',
        },
      });

      final page = await client.search(
        query: 'Rajasthan crafts',
        pageToken: 'current-page',
      );

      expect(page.items.single.videoId, 'abc123XYZ09');
      expect(page.items.single.thumbnail.width, 1280);
      expect(page.nextPageToken, 'next-page');
      expect(transport.posts.single.body, <String, Object?>{
        'operation': 'publicSearch',
        'query': 'Rajasthan crafts',
        'pageToken': 'current-page',
      });
      expect(
        credentials.appCheckModes.single,
        YouTubeAppCheckTokenMode.standard,
      );
      expect(credentials.idTokenCalls, 0);
    });

    test(
      'parses channel activity without claiming a personalized feed',
      () async {
        transport.queueJson(<String, Object?>{
          'ok': true,
          'data': <String, Object?>{
            'source': 'youtube',
            'feedScope': 'publicChannel',
            'channelId': 'UC1234567890123456789012',
            'regionCode': 'IN',
            'items': <Object?>[
              <String, Object?>{
                'activityId': 'activity-1',
                'channelId': 'UC1234567890123456789012',
                'channelTitle': 'MoolSocial Dev Channel',
                'publishedAt': '2026-07-24T10:00:00.000Z',
                'type': 'playlistItem',
                'title': 'Made across India',
                'description': 'A public channel activity.',
                'target': <String, Object?>{
                  'kind': 'video',
                  'videoId': 'abc123XYZ09',
                  'playlistId': 'PL123',
                  'playlistItemId': 'PLI123',
                },
                'thumbnail': <String, Object?>{
                  'url': 'https://i.ytimg.com/vi/abc123XYZ09/maxresdefault.jpg',
                  'width': 1280,
                  'height': 720,
                },
              },
            ],
            'omittedByFilterOrUnsupportedCount': 1,
            'nextPageToken': 'next-activity',
          },
        });

        final page = await client.channelActivities(
          channelId: 'UC1234567890123456789012',
          regionCode: 'IN',
          pageToken: 'current-activity',
          publishedAfter: DateTime.utc(2026, 7, 1),
          publishedBefore: DateTime.utc(2026, 7, 25),
          maxResults: 25,
          eventTypes: const <YouTubePublicActivityType>[
            YouTubePublicActivityType.upload,
            YouTubePublicActivityType.playlistItem,
          ],
        );

        expect(page.source, YouTubeProviderSource.youtube);
        expect(page.regionCode, 'IN');
        expect(page.omittedByFilterOrUnsupportedCount, 1);
        expect(page.nextPageToken, 'next-activity');
        expect(page.items.single.type, YouTubePublicActivityType.playlistItem);
        final target =
            page.items.single.target as YouTubePublicActivityVideoTarget;
        expect(target.videoId, 'abc123XYZ09');
        expect(target.playlistItemId, 'PLI123');
        expect(transport.posts.single.body, <String, Object?>{
          'operation': 'publicChannelActivities',
          'channelId': 'UC1234567890123456789012',
          'regionCode': 'IN',
          'pageToken': 'current-activity',
          'publishedAfter': '2026-07-01T00:00:00.000Z',
          'publishedBefore': '2026-07-25T00:00:00.000Z',
          'maxResults': 25,
          'eventTypes': <String>['upload', 'playlistItem'],
        });
        expect(credentials.idTokenCalls, 0);
      },
    );

    test(
      'parses public channel layout sections as provider metadata',
      () async {
        transport.queueJson(<String, Object?>{
          'ok': true,
          'data': <String, Object?>{
            'source': 'youtube',
            'channelId': 'UC1234567890123456789012',
            'items': <Object?>[
              <String, Object?>{
                'sectionId': 'section-1',
                'channelId': 'UC1234567890123456789012',
                'type': 'multiplePlaylists',
                'position': 0,
                'title': 'Featured playlists',
                'playlistIds': <String>['PL123', 'PL456'],
              },
            ],
          },
        });

        final result = await client.channelSections(
          channelId: 'UC1234567890123456789012',
        );

        expect(result.source, YouTubeProviderSource.youtube);
        expect(
          result.items.single.type,
          YouTubePublicChannelSectionType.multiplePlaylists,
        );
        expect(result.items.single.playlistIds, <String>['PL123', 'PL456']);
        expect(transport.posts.single.body, <String, Object?>{
          'operation': 'publicChannelSections',
          'channelId': 'UC1234567890123456789012',
        });
        expect(credentials.idTokenCalls, 0);
      },
    );

    test('uses Auth plus standard App Check for connection status', () async {
      transport.queueJson(<String, Object?>{
        'ok': true,
        'data': <String, Object?>{
          'connected': true,
          'channelId': 'channel-1',
          'channelTitle': 'MoolSocial Dev Channel',
          'grantedScopes': <String>['scope-one'],
          'lastVerifiedAt': '2026-07-23T10:00:00.000Z',
          'nextVerificationDueAt': '2026-08-22T10:00:00.000Z',
          'verificationState': 'current',
        },
      });

      final status = await client.connectionStatus();

      expect(status, isA<YouTubeConnected>());
      expect((status as YouTubeConnected).channelId, 'channel-1');
      expect(
        status.verificationState,
        YouTubeConnectionVerificationState.current,
      );
      expect(
        status.nextVerificationDueAt,
        DateTime.parse('2026-08-22T10:00:00.000Z'),
      );
      expect(
        credentials.appCheckModes.single,
        YouTubeAppCheckTokenMode.standard,
      );
      expect(credentials.idTokenCalls, 1);
      expect(
        transport.posts.single.headers['authorization'],
        'Bearer firebase-id-token',
      );
    });

    test('uses a limited-use token for connection start', () async {
      transport.queueJson(<String, Object?>{
        'ok': true,
        'data': <String, Object?>{
          'authorizationUrl': 'https://accounts.google.com/o/oauth2/v2/auth',
          'expiresAt': '2026-07-23T12:00:00.000Z',
        },
      });

      final start = await client.startConnection(
        purpose: YouTubeConnectPurpose.upload,
        promptForConsent: true,
      );

      expect(start.authorizationUrl.host, 'accounts.google.com');
      expect(
        credentials.appCheckModes.single,
        YouTubeAppCheckTokenMode.limitedUse,
      );
      expect(transport.posts.single.body, <String, Object?>{
        'operation': 'beginConnect',
        'purpose': 'upload',
        'promptForConsent': true,
      });
    });

    test('starts only a private upload and preserves expected media', () async {
      transport.queueJson(<String, Object?>{
        'ok': true,
        'data': <String, Object?>{
          'jobKey': 'job-1',
          'sessionUrl':
              'https://www.googleapis.com/upload/youtube/v3/videos'
              '?upload_id=private-session',
          'expiresAt': '2099-07-23T12:00:00.000Z',
          'privacyStatus': 'private',
        },
      });
      const metadata = YouTubePrivateUploadMetadata(
        title: 'Dev private upload',
        description: 'Private verification media.',
        categoryId: '22',
        madeForKids: false,
        containsSyntheticMedia: false,
        containsPaidPromotion: false,
        notifySubscribers: false,
      );

      final session = await client.beginPrivateUpload(
        idempotencyKey: 'publication-1',
        fileIdentity: _identity(List<int>.filled(524288, 7)),
        metadata: metadata,
      );

      expect(session.privacyStatus, 'private');
      expect(session.contentLength, 524288);
      expect(
        credentials.appCheckModes.single,
        YouTubeAppCheckTokenMode.limitedUse,
      );
      expect(
        (transport.posts.single.body['metadata'] as Map)['title'],
        'Dev private upload',
      );
    });

    test(
      'polls retryable reconciliation with a fresh limited-use token',
      () async {
        transport.queueJson(<String, Object?>{
          'ok': false,
          'error': <String, Object?>{
            'code': 'conflict',
            'message': 'The YouTube upload is still in progress.',
            'retryable': true,
          },
        }, statusCode: 409);
        transport.queueJson(<String, Object?>{
          'ok': true,
          'data': _videoJson(uploadStatus: 'processed'),
        });
        final delays = <Duration>[];

        final video = await client.pollUpload(
          jobKey: 'job-1',
          maximumAttempts: 2,
          interval: const Duration(milliseconds: 1),
          delay: (duration) async {
            delays.add(duration);
          },
        );

        expect(video.processingComplete, isTrue);
        expect(credentials.appCheckModes, [
          YouTubeAppCheckTokenMode.limitedUse,
          YouTubeAppCheckTokenMode.limitedUse,
        ]);
        expect(credentials.idTokenCalls, 2);
        expect(delays, [const Duration(milliseconds: 1)]);
      },
    );

    for (final terminalStatus in <String>['failed', 'rejected', 'deleted']) {
      test(
        'rejects terminal-unsuccessful $terminalStatus processing',
        () async {
          transport.queueJson(<String, Object?>{
            'ok': true,
            'data': _videoJson(uploadStatus: terminalStatus),
          });
          final delays = <Duration>[];

          await expectLater(
            client.pollUpload(
              jobKey: 'job-1',
              maximumAttempts: 3,
              interval: const Duration(milliseconds: 1),
              delay: (duration) async {
                delays.add(duration);
              },
            ),
            throwsA(
              isA<YouTubeProviderClientException>()
                  .having(
                    (error) => error.code,
                    'code',
                    'upload_processing_failed',
                  )
                  .having((error) => error.retryable, 'retryable', isFalse),
            ),
          );

          expect(
            YouTubeVideoSummary.fromJson(
              _videoJson(uploadStatus: terminalStatus),
            ).processingComplete,
            isFalse,
          );
          expect(delays, isEmpty);
          expect(transport.posts, hasLength(1));
        },
      );
    }

    test('fails closed on an unknown upload status', () async {
      transport.queueJson(<String, Object?>{
        'ok': true,
        'data': _videoJson(uploadStatus: 'unexpected-terminal-status'),
      });

      await expectLater(
        client.pollUpload(jobKey: 'job-1', maximumAttempts: 1),
        throwsA(
          isA<YouTubeProviderClientException>()
              .having(
                (error) => error.code,
                'code',
                'invalid_provider_response',
              )
              .having((error) => error.retryable, 'retryable', isFalse),
        ),
      );
    });

    test('times out while a transferred upload is still pending', () async {
      transport.queueJson(<String, Object?>{
        'ok': true,
        'data': _videoJson(uploadStatus: 'uploaded'),
      });

      await expectLater(
        client.pollUpload(jobKey: 'job-1', maximumAttempts: 1),
        throwsA(
          isA<YouTubeProviderClientException>()
              .having(
                (error) => error.code,
                'code',
                'upload_processing_timeout',
              )
              .having((error) => error.retryable, 'retryable', isTrue),
        ),
      );
    });

    test(
      'supports owner analytics and disconnect without exposing tokens',
      () async {
        transport.queueJson(<String, Object?>{
          'ok': true,
          'data': <String, Object?>{
            'preset': 'overview',
            'startDate': '2026-07-01',
            'endDate': '2026-07-21',
            'requestedRange': <String, Object?>{
              'startDate': '2026-07-01',
              'endDate': '2026-07-22',
            },
            'rows': <Object?>[
              <String, Object?>{
                'dimensions': <String, Object?>{'day': '2026-07-21'},
                'metrics': <String, Object?>{'views': 12, 'likes': 2},
              },
            ],
            'continuationStartIndex': 501,
            'empty': false,
            'providerMayExcludeRecentIncompleteDays': true,
          },
        });
        transport.queueJson(<String, Object?>{
          'ok': true,
          'data': <String, Object?>{
            'disconnected': true,
            'providerRevocationConfirmed': true,
          },
        });

        final analytics = await client.analyticsPreset(
          preset: YouTubeOwnerAnalyticsPreset.overview,
          startDate: DateTime.utc(2026, 7, 1),
          endDate: DateTime.utc(2026, 7, 22),
          startIndex: 1,
        );
        final disconnect = await client.disconnect();

        expect(analytics.preset, YouTubeOwnerAnalyticsPreset.overview);
        expect(analytics.rows.single.metrics['views'], 12);
        expect(analytics.requestedEndDate, '2026-07-22');
        expect(analytics.endDate, '2026-07-21');
        expect(analytics.continuationStartIndex, 501);
        expect(transport.posts.first.body, <String, Object?>{
          'operation': 'ownerAnalyticsPreset',
          'preset': 'overview',
          'startDate': '2026-07-01',
          'endDate': '2026-07-22',
          'startIndex': 1,
        });
        expect(disconnect.disconnected, isTrue);
        expect(disconnect.providerRevocationConfirmed, isTrue);
        expect(transport.posts.last.body, <String, Object?>{
          'operation': 'disconnect',
        });
        expect(credentials.appCheckModes, [
          YouTubeAppCheckTokenMode.limitedUse,
          YouTubeAppCheckTokenMode.limitedUse,
        ]);
        expect(
          transport.posts.every(
            (request) =>
                !jsonEncode(request.body).contains('firebase-id-token') &&
                !jsonEncode(request.body).contains('limited-app-check'),
          ),
          isTrue,
        );
      },
    );

    test('returns a redacted provider error', () async {
      transport.queueJson(<String, Object?>{
        'ok': false,
        'error': <String, Object?>{
          'code': 'quota_exhausted',
          'message': 'This operation is temporarily unavailable.',
          'retryable': true,
        },
      }, statusCode: 429);

      await expectLater(
        client.mostPopular(),
        throwsA(
          isA<YouTubeProviderClientException>()
              .having((error) => error.code, 'code', 'quota_exhausted')
              .having((error) => error.retryable, 'retryable', isTrue)
              .having(
                (error) => error.toString(),
                'redacted representation',
                isNot(contains('standard-app-check')),
              ),
        ),
      );
    });

    test('build configuration fails closed when the proof gate is off', () {
      expect(
        () => YouTubePrivateDevClient.fromBuildConfiguration(
          transport: transport,
          credentials: credentials,
        ),
        throwsStateError,
      );
    });

    test('rejects any endpoint outside the dedicated Dev function', () {
      expect(
        () => YouTubePrivateDevClient.forTesting(
          providerEndpoint: Uri.parse(
            'https://untrusted.example/youtubeProvider',
          ),
          transport: transport,
          credentials: credentials,
          proofEnabled: true,
          firebaseProjectId: youtubePrivateDevProjectId,
        ),
        throwsArgumentError,
      );
    });

    test('test seam still enforces the proof and Dev project boundary', () {
      YouTubePrivateDevClient build({
        required bool proofEnabled,
        required String projectId,
      }) {
        return YouTubePrivateDevClient.forTesting(
          providerEndpoint: Uri.parse(
            'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/'
            'youtubeProvider',
          ),
          transport: transport,
          credentials: credentials,
          proofEnabled: proofEnabled,
          firebaseProjectId: projectId,
        );
      }

      expect(
        () => build(proofEnabled: false, projectId: youtubePrivateDevProjectId),
        throwsStateError,
      );
      expect(
        () => build(proofEnabled: true, projectId: 'moolsocial-staging-503018'),
        throwsStateError,
      );
    });
  });

  group('YouTubeDirectUploader', () {
    test('uploads chunks directly to the Google resumable session', () async {
      final transport = _FakeTransport()
        ..queuePut(
          const YouTubeHttpResponse(
            statusCode: 308,
            headers: <String, String>{},
            body: '',
          ),
        )
        ..queuePut(
          const YouTubeHttpResponse(
            statusCode: 308,
            headers: <String, String>{'range': 'bytes=0-262143'},
            body: '',
          ),
        )
        ..queuePut(
          const YouTubeHttpResponse(
            statusCode: 201,
            headers: <String, String>{},
            body: '{}',
          ),
        );
      final uploader = YouTubeDirectUploader(transport);
      final progress = <int>[];
      final bytes = List<int>.generate(524288, (i) => i % 251);

      final result = await uploader.upload(
        session: _session(bytes: bytes),
        source: _MemoryUploadSource(bytes),
        chunkSize: 262144,
        onProgress: (accepted, _) => progress.add(accepted),
      );

      expect(result.bytesAccepted, 524288);
      expect(transport.puts, hasLength(3));
      expect(transport.puts.first.headers['content-range'], 'bytes */524288');
      expect(transport.puts.first.bytes, isEmpty);
      expect(
        transport.puts[1].headers['content-range'],
        'bytes 0-262143/524288',
      );
      expect(
        transport.puts[2].headers['content-range'],
        'bytes 262144-524287/524288',
      );
      expect(
        transport.puts.every(
          (request) =>
              request.uri.host == 'www.googleapis.com' &&
              !request.headers.containsKey('authorization') &&
              !request.headers.containsKey('x-firebase-appcheck'),
        ),
        isTrue,
      );
      expect(progress, [262144, 524288]);
    });

    test('rejects a non-Google session before reading media', () async {
      final uploader = YouTubeDirectUploader(_FakeTransport());
      final bytes = List<int>.filled(262144, 1);

      await expectLater(
        uploader.upload(
          session: YouTubePrivateUploadSession(
            jobKey: 'job-1',
            sessionUrl: Uri.parse(
              'https://example.test/upload/youtube/v3/videos?upload_id=x',
            ),
            expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
            privacyStatus: 'private',
            contentType: 'video/mp4',
            contentLength: 262144,
            fileIdentity: _identity(bytes),
          ),
          source: _MemoryUploadSource(bytes),
        ),
        throwsA(
          isA<YouTubeTransportException>().having(
            (error) => error.code,
            'code',
            'invalid_upload_session',
          ),
        ),
      );
    });

    test('rejects changed media before sending upload bytes', () async {
      final transport = _FakeTransport();
      final uploader = YouTubeDirectUploader(transport);

      await expectLater(
        uploader.upload(
          session: _session(bytes: List<int>.filled(262144, 1)),
          source: _MemoryUploadSource(List<int>.filled(262145, 1)),
        ),
        throwsA(
          isA<YouTubeTransportException>().having(
            (error) => error.code,
            'code',
            'content_identity_mismatch',
          ),
        ),
      );
      expect(transport.puts, isEmpty);
    });

    test('resumes from the provider-confirmed byte range', () async {
      final transport = _FakeTransport()
        ..queuePut(
          const YouTubeHttpResponse(
            statusCode: 308,
            headers: <String, String>{'range': 'bytes=0-262143'},
            body: '',
          ),
        )
        ..queuePut(
          const YouTubeHttpResponse(
            statusCode: 201,
            headers: <String, String>{},
            body: '{}',
          ),
        );
      final uploader = YouTubeDirectUploader(transport);
      final bytes = List<int>.filled(524288, 9);

      final result = await uploader.upload(
        session: _session(bytes: bytes),
        source: _MemoryUploadSource(bytes),
        chunkSize: 262144,
      );

      expect(result.bytesAccepted, 524288);
      expect(transport.puts, hasLength(2));
      expect(transport.puts.first.bytes, isEmpty);
      expect(
        transport.puts.last.headers['content-range'],
        'bytes 262144-524287/524288',
      );
      expect(transport.puts.last.bytes, hasLength(262144));
    });

    test('confirms completion after a final full-range 308', () async {
      final transport = _FakeTransport()
        ..queuePut(
          const YouTubeHttpResponse(
            statusCode: 308,
            headers: <String, String>{},
            body: '',
          ),
        )
        ..queuePut(
          const YouTubeHttpResponse(
            statusCode: 308,
            headers: <String, String>{'range': 'bytes=0-262143'},
            body: '',
          ),
        )
        ..queuePut(
          const YouTubeHttpResponse(
            statusCode: 200,
            headers: <String, String>{},
            body: '{}',
          ),
        );
      final uploader = YouTubeDirectUploader(transport);
      final bytes = List<int>.filled(262144, 5);

      final result = await uploader.upload(
        session: _session(bytes: bytes),
        source: _MemoryUploadSource(bytes),
        chunkSize: 262144,
      );

      expect(result.statusCode, 200);
      expect(result.bytesAccepted, 262144);
      expect(transport.puts, hasLength(3));
      expect(transport.puts.last.headers['content-range'], 'bytes */262144');
      expect(transport.puts.last.bytes, isEmpty);
    });

    test('rejects upload sessions with a non-default port', () async {
      final transport = _FakeTransport();
      final uploader = YouTubeDirectUploader(transport);
      final bytes = List<int>.filled(262144, 1);

      await expectLater(
        uploader.upload(
          session: YouTubePrivateUploadSession(
            jobKey: 'job-1',
            sessionUrl: Uri.parse(
              'https://www.googleapis.com:444/upload/youtube/v3/videos'
              '?upload_id=private-session',
            ),
            expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
            privacyStatus: 'private',
            contentType: 'video/mp4',
            contentLength: 262144,
            fileIdentity: _identity(bytes),
          ),
          source: _MemoryUploadSource(bytes),
        ),
        throwsA(
          isA<YouTubeTransportException>().having(
            (error) => error.code,
            'code',
            'invalid_upload_session',
          ),
        ),
      );
      expect(transport.puts, isEmpty);
    });
  });

  test('private workflow keeps media off the Functions request path', () async {
    final transport = _FakeTransport();
    final credentials = _FakeCredentials();
    final client = YouTubePrivateDevClient.forTesting(
      providerEndpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/'
        'youtubeProvider',
      ),
      transport: transport,
      credentials: credentials,
      proofEnabled: true,
      firebaseProjectId: youtubePrivateDevProjectId,
      requestId: () => 'request-fixed',
    );
    final workflow = YouTubePrivateDevUploadWorkflow(
      client: client,
      uploader: YouTubeDirectUploader(transport),
    );
    transport.queueJson(<String, Object?>{
      'ok': true,
      'data': <String, Object?>{
        'jobKey': 'job-1',
        'sessionUrl':
            'https://www.googleapis.com/upload/youtube/v3/videos'
            '?upload_id=private-session',
        'expiresAt': '2099-07-23T12:00:00.000Z',
        'privacyStatus': 'private',
      },
    });
    transport.queuePut(
      const YouTubeHttpResponse(
        statusCode: 308,
        headers: <String, String>{},
        body: '',
      ),
    );
    transport.queuePut(
      const YouTubeHttpResponse(
        statusCode: 201,
        headers: <String, String>{},
        body: '{}',
      ),
    );
    transport.queueJson(<String, Object?>{
      'ok': true,
      'data': _videoJson(uploadStatus: 'processed'),
    });
    final source = _MemoryUploadSource(List<int>.filled(262144, 7));

    final video = await workflow.uploadPrivate(
      idempotencyKey: 'publication-1',
      contentType: 'video/mp4',
      source: source,
      metadata: const YouTubePrivateUploadMetadata(
        title: 'Private workflow',
        description: '',
        categoryId: '22',
        madeForKids: false,
        containsSyntheticMedia: false,
        containsPaidPromotion: false,
        notifySubscribers: false,
      ),
      maximumProcessingAttempts: 1,
    );

    expect(video.videoId, 'abc123XYZ09');
    expect(transport.posts, hasLength(2));
    expect(transport.posts.first.body.containsKey('media'), isFalse);
    expect(transport.posts.first.body['contentLength'], 262144);
    expect(transport.puts, hasLength(2));
    expect(transport.puts.first.bytes, isEmpty);
    expect(transport.puts.last.bytes, hasLength(262144));
    expect(transport.puts.last.uri.host, 'www.googleapis.com');
  });

  test(
    'private workflow never reports a rejected processed upload as success',
    () async {
      final transport = _FakeTransport();
      final client = YouTubePrivateDevClient.forTesting(
        providerEndpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/'
          'youtubeProvider',
        ),
        transport: transport,
        credentials: _FakeCredentials(),
        proofEnabled: true,
        firebaseProjectId: youtubePrivateDevProjectId,
        requestId: () => 'request-fixed',
      );
      final workflow = YouTubePrivateDevUploadWorkflow(
        client: client,
        uploader: YouTubeDirectUploader(transport),
      );
      transport.queueJson(<String, Object?>{
        'ok': true,
        'data': <String, Object?>{
          'jobKey': 'job-rejected',
          'sessionUrl':
              'https://www.googleapis.com/upload/youtube/v3/videos'
              '?upload_id=rejected-session',
          'expiresAt': '2099-07-23T12:00:00.000Z',
          'privacyStatus': 'private',
        },
      });
      transport.queuePut(
        const YouTubeHttpResponse(
          statusCode: 308,
          headers: <String, String>{},
          body: '',
        ),
      );
      transport.queuePut(
        const YouTubeHttpResponse(
          statusCode: 201,
          headers: <String, String>{},
          body: '{}',
        ),
      );
      transport.queueJson(<String, Object?>{
        'ok': true,
        'data': _videoJson(uploadStatus: 'rejected'),
      });

      await expectLater(
        workflow.uploadPrivate(
          idempotencyKey: 'publication-rejected',
          contentType: 'video/mp4',
          source: _MemoryUploadSource(List<int>.filled(262144, 7)),
          metadata: const YouTubePrivateUploadMetadata(
            title: 'Private workflow rejection',
            description: '',
            categoryId: '22',
            madeForKids: false,
            containsSyntheticMedia: false,
            containsPaidPromotion: false,
            notifySubscribers: false,
          ),
          maximumProcessingAttempts: 1,
        ),
        throwsA(
          isA<YouTubeProviderClientException>().having(
            (error) => error.code,
            'code',
            'upload_processing_failed',
          ),
        ),
      );

      expect(transport.puts, hasLength(2));
      expect(transport.posts, hasLength(2));
    },
  );
}

Map<String, Object?> _videoJson({String uploadStatus = 'processed'}) {
  return <String, Object?>{
    'videoId': 'abc123XYZ09',
    'title': 'Made across India',
    'channelId': 'channel-1',
    'channelTitle': 'MoolSocial Dev Channel',
    'publishedAt': '2026-07-23T08:00:00.000Z',
    'description': 'A private Dev verification video.',
    'thumbnail': <String, Object?>{
      'url': 'https://i.ytimg.com/vi/abc123XYZ09/maxresdefault.jpg',
      'width': 1280,
      'height': 720,
    },
    'duration': 'PT1M2S',
    'viewCount': '12',
    'likeCount': '2',
    'commentCount': '1',
    'embeddable': true,
    'privacyStatus': 'private',
    'uploadStatus': uploadStatus,
  };
}

YouTubePrivateUploadSession _session({
  required List<int> bytes,
  String contentType = 'video/mp4',
}) {
  return YouTubePrivateUploadSession(
    jobKey: 'job-1',
    sessionUrl: Uri.parse(
      'https://www.googleapis.com/upload/youtube/v3/videos'
      '?upload_id=private-session',
    ),
    expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
    privacyStatus: 'private',
    contentType: contentType,
    contentLength: bytes.length,
    fileIdentity: _identity(bytes, contentType: contentType),
  );
}

YouTubeUploadFileIdentity _identity(
  List<int> bytes, {
  String contentType = 'video/mp4',
}) {
  final encoded = base64Url
      .encode(sha256.convert(bytes).bytes)
      .replaceAll('=', '');
  return YouTubeUploadFileIdentity(
    digest: encoded,
    byteLength: bytes.length,
    contentType: contentType,
  );
}

class _FakeCredentials implements YouTubeCredentialSource {
  final appCheckModes = <YouTubeAppCheckTokenMode>[];
  var idTokenCalls = 0;

  @override
  Future<String> appCheckToken(YouTubeAppCheckTokenMode mode) async {
    appCheckModes.add(mode);
    return switch (mode) {
      YouTubeAppCheckTokenMode.standard => 'standard-app-check',
      YouTubeAppCheckTokenMode.limitedUse => 'limited-app-check',
    };
  }

  @override
  Future<String> firebaseIdToken() async {
    idTokenCalls += 1;
    return 'firebase-id-token';
  }
}

class _PostRequest {
  const _PostRequest({
    required this.uri,
    required this.headers,
    required this.body,
  });

  final Uri uri;
  final Map<String, String> headers;
  final Map<String, Object?> body;
}

class _PutRequest {
  const _PutRequest({
    required this.uri,
    required this.headers,
    required this.bytes,
  });

  final Uri uri;
  final Map<String, String> headers;
  final List<int> bytes;
}

class _FakeTransport implements YouTubeHttpTransport {
  final _postResponses = <YouTubeHttpResponse>[];
  final _putResponses = <YouTubeHttpResponse>[];
  final posts = <_PostRequest>[];
  final puts = <_PutRequest>[];

  void queueJson(Map<String, Object?> body, {int statusCode = 200}) {
    _postResponses.add(
      YouTubeHttpResponse(
        statusCode: statusCode,
        headers: const <String, String>{},
        body: jsonEncode(body),
      ),
    );
  }

  void queuePut(YouTubeHttpResponse response) {
    _putResponses.add(response);
  }

  @override
  Future<YouTubeHttpResponse> postJson(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    posts.add(
      _PostRequest(
        uri: uri,
        headers: Map.unmodifiable(headers),
        body: Map.unmodifiable(body),
      ),
    );
    return _postResponses.removeAt(0);
  }

  @override
  Future<YouTubeHttpResponse> putStream(
    Uri uri, {
    required Map<String, String> headers,
    required Stream<List<int>> body,
    required int contentLength,
  }) async {
    final bytes = await body.expand((chunk) => chunk).toList();
    expect(bytes, hasLength(contentLength));
    puts.add(
      _PutRequest(uri: uri, headers: Map.unmodifiable(headers), bytes: bytes),
    );
    return _putResponses.removeAt(0);
  }
}

class _MemoryUploadSource implements YouTubeUploadSource {
  const _MemoryUploadSource(this.bytes);

  final List<int> bytes;

  @override
  Future<int> length() async => bytes.length;

  @override
  Future<YouTubeUploadFileIdentity> fileIdentity(String contentType) async {
    return _identity(bytes, contentType: contentType);
  }

  @override
  Stream<List<int>> openRead(int start, int endExclusive) {
    return Stream<List<int>>.value(bytes.sublist(start, endExclusive));
  }
}
