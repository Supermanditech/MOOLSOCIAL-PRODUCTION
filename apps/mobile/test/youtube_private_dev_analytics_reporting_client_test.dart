import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_app_check.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_client.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_models.dart';
import 'package:moolsocial/core/youtube/youtube_private_dev_transport.dart';

void main() {
  group('Analytics v2 typed private-Dev client', () {
    late _RecordingTransport transport;
    late _RecordingCredentials credentials;
    late YouTubePrivateDevClient client;

    setUp(() {
      transport = _RecordingTransport();
      credentials = _RecordingCredentials();
      client = _client(transport, credentials, analyticsV2Enabled: true);
    });

    test(
      'covers all eight adapter methods with bounded typed bodies',
      () async {
        transport.queue(<String, Object?>{
          'items': <Object?>[_group()],
          'nextPageToken': 'groups-next',
        });
        expect(
          (await client.analyticsV2ListGroups()).items.single.itemType,
          YouTubeAnalyticsV2GroupItemType.video,
        );

        transport.queue(_group(title: 'Created group'));
        expect(
          (await client.analyticsV2CreateGroup(
            idempotencyKey: 'group-create-001',
            title: 'Created group',
            itemType: YouTubeAnalyticsV2GroupItemType.video,
          )).title,
          'Created group',
        );

        transport.queue(_group(title: 'Updated group'));
        await client.analyticsV2UpdateGroup(
          idempotencyKey: 'group-update-001',
          groupId: 'group-1',
          title: 'Updated group',
        );

        transport.queue(<String, Object?>{
          'deleted': true,
          'groupId': 'group-1',
        });
        expect(
          (await client.analyticsV2DeleteGroup(
            idempotencyKey: 'group-delete-001',
            groupId: 'group-1',
            confirmGroupId: 'group-1',
          )).resourceKey,
          'groupId',
        );

        transport.queue(<String, Object?>{
          'groupId': 'group-1',
          'items': <Object?>[_groupItem()],
        });
        expect(
          (await client.analyticsV2ListGroupItems(
            groupId: 'group-1',
          )).items.single.resourceId,
          'video123',
        );

        transport.queue(_groupItem());
        await client.analyticsV2InsertGroupItem(
          idempotencyKey: 'group-item-insert-001',
          groupId: 'group-1',
          resourceType: YouTubeAnalyticsV2GroupItemType.video,
          resourceId: 'video123',
        );

        transport.queue(<String, Object?>{
          'deleted': true,
          'groupItemId': 'group-item-1',
        });
        await client.analyticsV2DeleteGroupItem(
          idempotencyKey: 'group-item-delete-001',
          groupItemId: 'group-item-1',
          confirmGroupItemId: 'group-item-1',
        );

        transport.queue(<String, Object?>{
          'channelId': 'channel-owner',
          'startDate': '2026-07-01',
          'endDate': '2026-07-25',
          'rows': <Object?>[
            <String, Object?>{
              'dimensions': <String, Object?>{
                'day': '2026-07-25',
                'video': 'video123',
              },
              'metrics': <String, Object?>{'views': 125, 'likes': 9},
            },
          ],
          'continuationStartIndex': 26,
          'empty': false,
        });
        final report = await client.analyticsV2QueryReport(
          query: YouTubeAnalyticsV2ReportQuery(
            startDate: DateTime.utc(2026, 7, 1),
            endDate: DateTime.utc(2026, 7, 25),
            metrics: const <YouTubeAnalyticsV2Metric>[
              YouTubeAnalyticsV2Metric.views,
              YouTubeAnalyticsV2Metric.likes,
            ],
            dimensions: const <YouTubeAnalyticsV2Dimension>[
              YouTubeAnalyticsV2Dimension.day,
              YouTubeAnalyticsV2Dimension.video,
            ],
            videoId: 'video123',
            sort: YouTubeAnalyticsV2Sort.metric(
              YouTubeAnalyticsV2Metric.views,
              direction: YouTubeAnalyticsV2SortDirection.descending,
            ),
            maxResults: 25,
            startIndex: 1,
          ),
        );
        expect(report.rows.single.metrics['views'], 125);
        expect(report.continuationStartIndex, 26);

        expect(transport.operations, <String>[
          'analyticsV2ListGroups',
          'analyticsV2CreateGroup',
          'analyticsV2UpdateGroup',
          'analyticsV2DeleteGroup',
          'analyticsV2ListGroupItems',
          'analyticsV2InsertGroupItem',
          'analyticsV2DeleteGroupItem',
          'analyticsV2QueryReport',
        ]);
        _expectReplayProtected(transport, credentials);
        expect(transport.requests[1].body['itemType'], 'youtube#video');
        expect(transport.requests[3].body['confirmGroupId'], 'group-1');
        expect(transport.requests[7].body, containsPair('maxResults', 25));
        expect(transport.requests[7].body['sort'], <String, Object?>{
          'field': 'views',
          'direction': 'descending',
        });
      },
    );
  });

  group('Reporting v1 typed private-Dev client', () {
    late _RecordingTransport transport;
    late _RecordingCredentials credentials;
    late YouTubePrivateDevClient client;

    setUp(() {
      transport = _RecordingTransport();
      credentials = _RecordingCredentials();
      client = _client(transport, credentials, reportingV1Enabled: true);
    });

    test('covers all eight adapter methods and bounded report media', () async {
      transport.queue(<String, Object?>{
        'items': <Object?>[_reportType()],
        'nextPageToken': 'types-next',
      });
      expect(
        (await client.reportingV1ListReportTypes(
          pageSize: 25,
        )).items.single.availability,
        YouTubeReportingV1ReportTypeAvailability.available,
      );

      transport.queue(_job());
      expect(
        (await client.reportingV1CreateJob(
          idempotencyKey: 'report-job-create-001',
          reportTypeId: 'channel_basic_a2',
          name: 'Daily channel report',
        )).status,
        YouTubeReportingV1JobStatus.active,
      );

      transport.queue(<String, Object?>{
        'items': <Object?>[_job()],
        'nextPageToken': 'jobs-next',
      });
      expect(
        (await client.reportingV1ListJobs(
          pageToken: 'jobs-page',
          includeSystemManaged: true,
        )).nextPageToken,
        'jobs-next',
      );

      transport.queue(_job());
      expect((await client.reportingV1GetJob(jobId: 'job-1')).jobId, 'job-1');

      transport.queue(<String, Object?>{'deleted': true, 'jobId': 'job-1'});
      await client.reportingV1DeleteJob(
        idempotencyKey: 'report-job-delete-001',
        jobId: 'job-1',
        confirmJobId: 'job-1',
      );

      transport.queue(<String, Object?>{
        'items': <Object?>[_report()],
        'nextPageToken': 'reports-next',
      });
      expect(
        (await client.reportingV1ListReports(
          jobId: 'job-1',
          pageSize: 20,
          window: YouTubeReportingV1ReportWindow(
            createdAfter: DateTime.utc(2026, 7, 1),
            startTimeAtOrAfter: DateTime.utc(2026, 7, 1),
            startTimeBefore: DateTime.utc(2026, 7, 26),
          ),
        )).items.single.mediaResourceName,
        'media/v1/jobs/job-1/reports/report-1',
      );

      transport.queue(_report());
      expect(
        (await client.reportingV1GetReport(
          jobId: 'job-1',
          reportId: 'report-1',
        )).reportId,
        'report-1',
      );

      transport.queue(<String, Object?>{
        'jobId': 'job-1',
        'reportId': 'report-1',
        'byteLength': 5,
        'sha256':
            '2cf24dba5fb0a30e26e83b2ac5b9e29e'
            '1b161e5c1fa7425e73043362938b9824',
        'contentType': 'text/csv',
        'contentEncoding': 'base64',
        'bodyBase64': 'aGVsbG8=',
      });
      final media = await client.reportingV1DownloadReportMedia(
        jobId: 'job-1',
        reportId: 'report-1',
        maximumBytes: 1024,
      );
      expect(media.byteLength, 5);
      expect(media.contentEncoding, 'base64');

      expect(transport.operations, <String>[
        'reportingV1ListReportTypes',
        'reportingV1CreateJob',
        'reportingV1ListJobs',
        'reportingV1GetJob',
        'reportingV1DeleteJob',
        'reportingV1ListReports',
        'reportingV1GetReport',
        'reportingV1DownloadReportMedia',
      ]);
      _expectReplayProtected(transport, credentials);
      expect(transport.requests[0].body['pageSize'], 25);
      expect(transport.requests[4].body['confirmJobId'], 'job-1');
      expect(transport.requests[5].body['window'], <String, Object?>{
        'createdAfter': '2026-07-01T00:00:00.000Z',
        'startTimeAtOrAfter': '2026-07-01T00:00:00.000Z',
        'startTimeBefore': '2026-07-26T00:00:00.000Z',
      });
      expect(transport.requests[7].body['maximumBytes'], 1024);
    });
  });

  group('closed boundary and typed failure contract', () {
    test(
      'both clients remain disabled by default before credentials or I/O',
      () async {
        final transport = _RecordingTransport();
        final credentials = _RecordingCredentials();
        final client = _client(transport, credentials);

        await expectLater(
          client.analyticsV2ListGroups(),
          throwsA(isA<YouTubeCapabilityUnavailableException>()),
        );
        await expectLater(
          client.reportingV1ListJobs(),
          throwsA(isA<YouTubeCapabilityUnavailableException>()),
        );
        expect(transport.requests, isEmpty);
        expect(credentials.modes, isEmpty);
        expect(credentials.idTokenCalls, 0);
      },
    );

    test(
      'maps eligibility, disabled, state, and unavailable distinctly',
      () async {
        final transport = _RecordingTransport()
          ..queueError(
            code: 'eligibility_required',
            message: 'Channel is not eligible.',
            statusCode: 403,
          )
          ..queueError(
            code: 'capability_disabled',
            message: 'Capability is disabled.',
            statusCode: 503,
          )
          ..queueError(
            code: 'status_conflict',
            message: 'Resource state is incompatible.',
            statusCode: 409,
          )
          ..queueError(
            code: 'not_found',
            message: 'Resource is unavailable.',
            statusCode: 404,
          );
        final client = _client(
          transport,
          _RecordingCredentials(),
          analyticsV2Enabled: true,
          reportingV1Enabled: true,
        );

        await expectLater(
          client.analyticsV2ListGroups(),
          throwsA(isA<YouTubeEligibilityRequiredException>()),
        );
        await expectLater(
          client.analyticsV2ListGroups(),
          throwsA(isA<YouTubeCapabilityUnavailableException>()),
        );
        await expectLater(
          client.reportingV1GetJob(jobId: 'job-1'),
          throwsA(isA<YouTubeStatusConflictException>()),
        );
        await expectLater(
          client.reportingV1GetReport(jobId: 'job-1', reportId: 'report-1'),
          throwsA(isA<YouTubeResourceUnavailableException>()),
        );
      },
    );

    test(
      'rejects partner claims, unsafe windows, and arbitrary media locations',
      () {
        expect(
          () => YouTubeAnalyticsV2GroupItem.fromJson(<String, Object?>{
            ..._groupItem(),
            'resourceType': 'youtubePartner#asset',
            'resourceId': 'partner-asset-1',
          }),
          throwsFormatException,
        );
        expect(
          () => YouTubeAnalyticsV2ReportQuery(
            startDate: DateTime.utc(2025, 1, 1),
            endDate: DateTime.utc(2026, 7, 1),
            metrics: const <YouTubeAnalyticsV2Metric>[
              YouTubeAnalyticsV2Metric.views,
            ],
          ),
          throwsFormatException,
        );
        expect(
          () => YouTubeReportingV1Report.fromJson(<String, Object?>{
            ..._report(),
            'mediaResourceName': 'https://example.com/report.csv',
          }),
          throwsFormatException,
        );
        expect(
          () => YouTubeReportingV1DownloadRequest(
            jobId: 'job-1',
            reportId: 'report-1',
            maximumBytes: youtubeReportingV1MaximumMediaBytes + 1,
          ),
          throwsFormatException,
        );
      },
    );

    test('download DTO enforces digest, base64, type, and byte bounds', () {
      final valid = <String, Object?>{
        'jobId': 'job-1',
        'reportId': 'report-1',
        'byteLength': 5,
        'sha256':
            '2cf24dba5fb0a30e26e83b2ac5b9e29e'
            '1b161e5c1fa7425e73043362938b9824',
        'contentType': 'text/csv',
        'contentEncoding': 'base64',
        'bodyBase64': 'aGVsbG8=',
      };
      expect(YouTubeReportingV1DownloadedMedia.fromJson(valid).byteLength, 5);
      expect(
        () => YouTubeReportingV1DownloadedMedia.fromJson(<String, Object?>{
          ...valid,
          'sha256': 'not-a-digest',
        }),
        throwsFormatException,
      );
      expect(
        () => YouTubeReportingV1DownloadedMedia.fromJson(<String, Object?>{
          ...valid,
          'bodyBase64': 'aGVsbA==',
        }),
        throwsFormatException,
      );
      expect(
        () => YouTubeReportingV1DownloadedMedia.fromJson(<String, Object?>{
          ...valid,
          'contentType': 'text/html',
        }),
        throwsFormatException,
      );
    });

    test('capability fields are absent-or-false closed', () {
      final absent = YouTubePrivateDevCapabilities.fromJson(_capabilities());
      final explicit = YouTubePrivateDevCapabilities.fromJson(<String, Object?>{
        ..._capabilities(),
        'analyticsV2': false,
        'reportingV1': false,
      });
      expect(absent.analyticsV2, isFalse);
      expect(absent.reportingV1, isFalse);
      expect(explicit.analyticsV2, isFalse);
      expect(explicit.reportingV1, isFalse);
    });
  });
}

YouTubePrivateDevClient _client(
  _RecordingTransport transport,
  _RecordingCredentials credentials, {
  bool analyticsV2Enabled = false,
  bool reportingV1Enabled = false,
}) {
  return YouTubePrivateDevClient.forTesting(
    providerEndpoint: Uri.parse(
      'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/'
      'youtubeProvider',
    ),
    transport: transport,
    credentials: credentials,
    proofEnabled: true,
    firebaseProjectId: youtubePrivateDevProjectId,
    analyticsV2Enabled: analyticsV2Enabled,
    reportingV1Enabled: reportingV1Enabled,
    requestId: () => 'request-fixed',
  );
}

void _expectReplayProtected(
  _RecordingTransport transport,
  _RecordingCredentials credentials,
) {
  expect(credentials.modes, everyElement(YouTubeAppCheckTokenMode.limitedUse));
  expect(credentials.idTokenCalls, transport.requests.length);
  for (final request in transport.requests) {
    expect(request.headers['authorization'], 'Bearer firebase-token');
    expect(request.headers['x-firebase-appcheck'], 'limited-app-check');
  }
}

Map<String, Object?> _capabilities() {
  return <String, Object?>{
    'environment': 'dev',
    'publicData': false,
    'ownerConnect': false,
    'privateUpload': false,
    'ownerAnalytics': false,
    'publicOrUnlistedUpload': false,
  };
}

Map<String, Object?> _group({String title = 'Video group'}) {
  return <String, Object?>{
    'groupId': 'group-1',
    'title': title,
    'publishedAt': '2026-07-25T08:00:00.000Z',
    'itemCount': 1,
    'itemType': 'youtube#video',
  };
}

Map<String, Object?> _groupItem() {
  return <String, Object?>{
    'groupItemId': 'group-item-1',
    'groupId': 'group-1',
    'resourceType': 'youtube#video',
    'resourceId': 'video123',
  };
}

Map<String, Object?> _reportType() {
  return <String, Object?>{
    'reportTypeId': 'channel_basic_a2',
    'name': 'Channel basic',
    'systemManaged': false,
    'availability': 'available',
  };
}

Map<String, Object?> _job() {
  return <String, Object?>{
    'jobId': 'job-1',
    'reportTypeId': 'channel_basic_a2',
    'name': 'Daily channel report',
    'systemManaged': false,
    'createTime': '2026-07-25T08:00:00.000Z',
    'status': 'active',
  };
}

Map<String, Object?> _report() {
  return <String, Object?>{
    'reportId': 'report-1',
    'jobId': 'job-1',
    'createTime': '2026-07-25T08:00:00.000Z',
    'startTime': '2026-07-24T00:00:00.000Z',
    'endTime': '2026-07-25T00:00:00.000Z',
    'mediaResourceName': 'media/v1/jobs/job-1/reports/report-1',
  };
}

class _RecordingCredentials implements YouTubeCredentialSource {
  final modes = <YouTubeAppCheckTokenMode>[];
  var idTokenCalls = 0;

  @override
  Future<String> appCheckToken(YouTubeAppCheckTokenMode mode) async {
    modes.add(mode);
    return mode == YouTubeAppCheckTokenMode.limitedUse
        ? 'limited-app-check'
        : 'standard-app-check';
  }

  @override
  Future<String> firebaseIdToken() async {
    idTokenCalls += 1;
    return 'firebase-token';
  }
}

class _Request {
  const _Request({required this.headers, required this.body});

  final Map<String, String> headers;
  final Map<String, Object?> body;
}

class _RecordingTransport implements YouTubeHttpTransport {
  final responses = <YouTubeHttpResponse>[];
  final requests = <_Request>[];

  List<String> get operations => requests
      .map((request) => request.body['operation']! as String)
      .toList(growable: false);

  void queue(Map<String, Object?> data) {
    responses.add(
      YouTubeHttpResponse(
        statusCode: 200,
        headers: const <String, String>{},
        body: jsonEncode(<String, Object?>{'ok': true, 'data': data}),
      ),
    );
  }

  void queueError({
    required String code,
    required String message,
    required int statusCode,
  }) {
    responses.add(
      YouTubeHttpResponse(
        statusCode: statusCode,
        headers: const <String, String>{},
        body: jsonEncode(<String, Object?>{
          'ok': false,
          'error': <String, Object?>{
            'code': code,
            'message': message,
            'retryable': false,
          },
        }),
      ),
    );
  }

  @override
  Future<YouTubeHttpResponse> postJson(
    Uri uri, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    requests.add(
      _Request(
        headers: Map<String, String>.unmodifiable(headers),
        body: Map<String, Object?>.unmodifiable(body),
      ),
    );
    return responses.removeAt(0);
  }

  @override
  Future<YouTubeHttpResponse> putStream(
    Uri uri, {
    required Map<String, String> headers,
    required Stream<List<int>> body,
    required int contentLength,
  }) {
    throw UnimplementedError();
  }
}
