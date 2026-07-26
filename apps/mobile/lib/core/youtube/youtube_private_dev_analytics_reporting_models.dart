part of 'youtube_private_dev_models.dart';

const youtubeReportingV1MaximumMediaBytes = 8 * 1024 * 1024;

enum YouTubeAnalyticsV2Metric {
  views,
  engagedViews,
  estimatedMinutesWatched,
  averageViewDuration,
  averageViewPercentage,
  likes,
  comments,
  shares,
  subscribersGained,
  subscribersLost,
  playlistStarts,
  viewsPerPlaylistStart,
  averageTimeInPlaylist,
}

enum YouTubeAnalyticsV2Dimension {
  day,
  video,
  country,
  insightTrafficSourceType,
  deviceType,
  operatingSystem,
  subscribedStatus,
  playlist,
}

enum YouTubeAnalyticsV2SortDirection { ascending, descending }

enum YouTubeAnalyticsV2GroupItemType { channel, playlist, video }

enum YouTubeReportingV1ReportTypeAvailability {
  available,
  systemManaged,
  deprecated,
}

enum YouTubeReportingV1JobStatus { active, expired, systemManaged }

extension YouTubeAnalyticsV2MetricWireValue on YouTubeAnalyticsV2Metric {
  String get wireValue => name;
}

extension YouTubeAnalyticsV2DimensionWireValue on YouTubeAnalyticsV2Dimension {
  String get wireValue => name;
}

extension YouTubeAnalyticsV2SortDirectionWireValue
    on YouTubeAnalyticsV2SortDirection {
  String get wireValue => name;
}

extension YouTubeAnalyticsV2GroupItemTypeWireValue
    on YouTubeAnalyticsV2GroupItemType {
  String get wireValue => switch (this) {
    YouTubeAnalyticsV2GroupItemType.channel => 'youtube#channel',
    YouTubeAnalyticsV2GroupItemType.playlist => 'youtube#playlist',
    YouTubeAnalyticsV2GroupItemType.video => 'youtube#video',
  };
}

class YouTubeAnalyticsV2Sort {
  YouTubeAnalyticsV2Sort.metric(
    YouTubeAnalyticsV2Metric metric, {
    this.direction = YouTubeAnalyticsV2SortDirection.ascending,
  }) : field = metric.wireValue,
       metricField = metric,
       dimensionField = null;

  YouTubeAnalyticsV2Sort.dimension(
    YouTubeAnalyticsV2Dimension dimension, {
    this.direction = YouTubeAnalyticsV2SortDirection.ascending,
  }) : field = dimension.wireValue,
       metricField = null,
       dimensionField = dimension;

  final String field;
  final YouTubeAnalyticsV2Metric? metricField;
  final YouTubeAnalyticsV2Dimension? dimensionField;
  final YouTubeAnalyticsV2SortDirection direction;

  Map<String, Object?> toJson() => <String, Object?>{
    'field': field,
    'direction': direction.wireValue,
  };
}

class YouTubeAnalyticsV2GroupsRequest {
  YouTubeAnalyticsV2GroupsRequest({String? groupId, String? pageToken})
    : groupId = groupId == null
          ? null
          : _analyticsReportingResourceId(groupId, 'groupId'),
      pageToken = pageToken == null
          ? null
          : _analyticsReportingPageToken(pageToken) {
    if (this.groupId != null && this.pageToken != null) {
      throw const FormatException('groupId and pageToken cannot be combined.');
    }
  }

  final String? groupId;
  final String? pageToken;

  Map<String, Object?> toJson() => <String, Object?>{
    'groupId': ?groupId,
    'pageToken': ?pageToken,
  };
}

class YouTubeAnalyticsV2CreateGroupRequest {
  YouTubeAnalyticsV2CreateGroupRequest({
    required String idempotencyKey,
    required String title,
    required this.itemType,
  }) : idempotencyKey = _analyticsReportingIdempotencyKey(idempotencyKey),
       title = _analyticsReportingTitle(title, 500);

  final String idempotencyKey;
  final String title;
  final YouTubeAnalyticsV2GroupItemType itemType;

  Map<String, Object?> toJson() => <String, Object?>{
    'idempotencyKey': idempotencyKey,
    'title': title,
    'itemType': itemType.wireValue,
  };
}

class YouTubeAnalyticsV2UpdateGroupRequest {
  YouTubeAnalyticsV2UpdateGroupRequest({
    required String idempotencyKey,
    required String groupId,
    required String title,
  }) : idempotencyKey = _analyticsReportingIdempotencyKey(idempotencyKey),
       groupId = _analyticsReportingResourceId(groupId, 'groupId'),
       title = _analyticsReportingTitle(title, 500);

  final String idempotencyKey;
  final String groupId;
  final String title;

  Map<String, Object?> toJson() => <String, Object?>{
    'idempotencyKey': idempotencyKey,
    'groupId': groupId,
    'title': title,
  };
}

class YouTubeAnalyticsV2DeleteGroupRequest {
  YouTubeAnalyticsV2DeleteGroupRequest({
    required String idempotencyKey,
    required String groupId,
    required String confirmGroupId,
  }) : idempotencyKey = _analyticsReportingIdempotencyKey(idempotencyKey),
       groupId = _analyticsReportingResourceId(groupId, 'groupId'),
       confirmGroupId = _analyticsReportingResourceId(
         confirmGroupId,
         'confirmGroupId',
       ) {
    if (this.groupId != this.confirmGroupId) {
      throw const FormatException('confirmGroupId must match groupId.');
    }
  }

  final String idempotencyKey;
  final String groupId;
  final String confirmGroupId;

  Map<String, Object?> toJson() => <String, Object?>{
    'idempotencyKey': idempotencyKey,
    'groupId': groupId,
    'confirmGroupId': confirmGroupId,
  };
}

class YouTubeAnalyticsV2GroupItemsRequest {
  YouTubeAnalyticsV2GroupItemsRequest({required String groupId})
    : groupId = _analyticsReportingResourceId(groupId, 'groupId');

  final String groupId;

  Map<String, Object?> toJson() => <String, Object?>{'groupId': groupId};
}

class YouTubeAnalyticsV2InsertGroupItemRequest {
  YouTubeAnalyticsV2InsertGroupItemRequest({
    required String idempotencyKey,
    required String groupId,
    required this.resourceType,
    required String resourceId,
  }) : idempotencyKey = _analyticsReportingIdempotencyKey(idempotencyKey),
       groupId = _analyticsReportingResourceId(groupId, 'groupId'),
       resourceId = _analyticsV2GroupResourceId(resourceType, resourceId);

  final String idempotencyKey;
  final String groupId;
  final YouTubeAnalyticsV2GroupItemType resourceType;
  final String resourceId;

  Map<String, Object?> toJson() => <String, Object?>{
    'idempotencyKey': idempotencyKey,
    'groupId': groupId,
    'resourceType': resourceType.wireValue,
    'resourceId': resourceId,
  };
}

class YouTubeAnalyticsV2DeleteGroupItemRequest {
  YouTubeAnalyticsV2DeleteGroupItemRequest({
    required String idempotencyKey,
    required String groupItemId,
    required String confirmGroupItemId,
  }) : idempotencyKey = _analyticsReportingIdempotencyKey(idempotencyKey),
       groupItemId = _analyticsReportingResourceId(groupItemId, 'groupItemId'),
       confirmGroupItemId = _analyticsReportingResourceId(
         confirmGroupItemId,
         'confirmGroupItemId',
       ) {
    if (this.groupItemId != this.confirmGroupItemId) {
      throw const FormatException('confirmGroupItemId must match groupItemId.');
    }
  }

  final String idempotencyKey;
  final String groupItemId;
  final String confirmGroupItemId;

  Map<String, Object?> toJson() => <String, Object?>{
    'idempotencyKey': idempotencyKey,
    'groupItemId': groupItemId,
    'confirmGroupItemId': confirmGroupItemId,
  };
}

class YouTubeAnalyticsV2ReportQuery {
  YouTubeAnalyticsV2ReportQuery({
    required DateTime startDate,
    required DateTime endDate,
    required List<YouTubeAnalyticsV2Metric> metrics,
    List<YouTubeAnalyticsV2Dimension>? dimensions,
    String? videoId,
    this.sort,
    this.maxResults = 50,
    this.startIndex = 1,
  }) : startDate = _dateOnly(startDate),
       endDate = _dateOnly(endDate),
       metrics = List<YouTubeAnalyticsV2Metric>.unmodifiable(metrics),
       dimensions = dimensions == null
           ? null
           : List<YouTubeAnalyticsV2Dimension>.unmodifiable(dimensions),
       videoId = videoId == null ? null : _analyticsReportingVideoId(videoId) {
    final inclusiveDays = this.endDate.difference(this.startDate).inDays + 1;
    if (inclusiveDays < 1 || inclusiveDays > 366) {
      throw const FormatException(
        'The analytics date range must contain 1 to 366 days.',
      );
    }
    if (this.metrics.isEmpty ||
        this.metrics.length > 10 ||
        this.metrics.toSet().length != this.metrics.length) {
      throw const FormatException(
        'metrics must contain 1 to 10 unique values.',
      );
    }
    final selectedDimensions = this.dimensions;
    if (selectedDimensions != null &&
        (selectedDimensions.isEmpty ||
            selectedDimensions.length > 3 ||
            selectedDimensions.toSet().length != selectedDimensions.length)) {
      throw const FormatException(
        'dimensions must contain 1 to 3 unique values when supplied.',
      );
    }
    if (maxResults < 1 || maxResults > 200) {
      throw const FormatException('maxResults must be between 1 and 200.');
    }
    if (startIndex < 1 || startIndex > 10000) {
      throw const FormatException('startIndex must be between 1 and 10000.');
    }
    final selectedSort = sort;
    if (selectedSort != null) {
      final metricSelected =
          selectedSort.metricField == null ||
          this.metrics.contains(selectedSort.metricField);
      final dimensionSelected =
          selectedSort.dimensionField == null ||
          (selectedDimensions?.contains(selectedSort.dimensionField) ?? false);
      if (!metricSelected || !dimensionSelected) {
        throw const FormatException(
          'sort must reference a selected metric or dimension.',
        );
      }
    }
  }

  final DateTime startDate;
  final DateTime endDate;
  final List<YouTubeAnalyticsV2Metric> metrics;
  final List<YouTubeAnalyticsV2Dimension>? dimensions;
  final String? videoId;
  final YouTubeAnalyticsV2Sort? sort;
  final int maxResults;
  final int startIndex;

  Map<String, Object?> toJson() => <String, Object?>{
    'startDate': _dateWireValue(startDate),
    'endDate': _dateWireValue(endDate),
    'metrics': metrics.map((value) => value.wireValue).toList(growable: false),
    if (dimensions case final values?)
      'dimensions': values
          .map((value) => value.wireValue)
          .toList(growable: false),
    'videoId': ?videoId,
    if (sort case final value?) 'sort': value.toJson(),
    'maxResults': maxResults,
    'startIndex': startIndex,
  };
}

class YouTubeAnalyticsV2Group {
  YouTubeAnalyticsV2Group({
    required this.groupId,
    required this.title,
    required this.publishedAt,
    required this.itemCount,
    required this.itemType,
  });

  factory YouTubeAnalyticsV2Group.fromJson(Map<String, Object?> json) {
    return YouTubeAnalyticsV2Group(
      groupId: _analyticsReportingResourceId(
        _requiredString(json, 'groupId'),
        'groupId',
      ),
      title: _analyticsReportingTitle(_requiredString(json, 'title'), 500),
      publishedAt: _requiredDateTime(json, 'publishedAt'),
      itemCount: _analyticsReportingNonNegativeInt(json, 'itemCount'),
      itemType: _analyticsV2GroupItemType(_requiredString(json, 'itemType')),
    );
  }

  final String groupId;
  final String title;
  final DateTime publishedAt;
  final int itemCount;
  final YouTubeAnalyticsV2GroupItemType itemType;
}

class YouTubeAnalyticsV2GroupItem {
  YouTubeAnalyticsV2GroupItem({
    required this.groupItemId,
    required this.groupId,
    required this.resourceType,
    required this.resourceId,
  });

  factory YouTubeAnalyticsV2GroupItem.fromJson(Map<String, Object?> json) {
    return YouTubeAnalyticsV2GroupItem(
      groupItemId: _analyticsReportingResourceId(
        _requiredString(json, 'groupItemId'),
        'groupItemId',
      ),
      groupId: _analyticsReportingResourceId(
        _requiredString(json, 'groupId'),
        'groupId',
      ),
      resourceType: _analyticsV2GroupItemType(
        _requiredString(json, 'resourceType'),
      ),
      resourceId: _analyticsV2GroupResourceId(
        _analyticsV2GroupItemType(_requiredString(json, 'resourceType')),
        _requiredString(json, 'resourceId'),
      ),
    );
  }

  final String groupItemId;
  final String groupId;
  final YouTubeAnalyticsV2GroupItemType resourceType;
  final String resourceId;
}

class YouTubeAnalyticsV2GroupsPage {
  YouTubeAnalyticsV2GroupsPage({required this.items, this.nextPageToken});

  factory YouTubeAnalyticsV2GroupsPage.fromJson(Map<String, Object?> json) {
    final items = _requiredList(
      json,
      'items',
    ).map(_asMap).map(YouTubeAnalyticsV2Group.fromJson).toList(growable: false);
    if (items.length > 200) {
      throw const FormatException('Too many analytics groups.');
    }
    return YouTubeAnalyticsV2GroupsPage(
      items: items,
      nextPageToken: _analyticsReportingOptionalPageToken(
        json,
        'nextPageToken',
      ),
    );
  }

  final List<YouTubeAnalyticsV2Group> items;
  final String? nextPageToken;
}

class YouTubeAnalyticsV2GroupItemsResult {
  YouTubeAnalyticsV2GroupItemsResult({
    required this.groupId,
    required this.items,
  });

  factory YouTubeAnalyticsV2GroupItemsResult.fromJson(
    Map<String, Object?> json,
  ) {
    final groupId = _analyticsReportingResourceId(
      _requiredString(json, 'groupId'),
      'groupId',
    );
    final items = _requiredList(json, 'items')
        .map(_asMap)
        .map(YouTubeAnalyticsV2GroupItem.fromJson)
        .toList(growable: false);
    if (items.length > 200 || items.any((item) => item.groupId != groupId)) {
      throw const FormatException(
        'items must belong to the requested analytics group.',
      );
    }
    return YouTubeAnalyticsV2GroupItemsResult(groupId: groupId, items: items);
  }

  final String groupId;
  final List<YouTubeAnalyticsV2GroupItem> items;
}

class YouTubeAnalyticsV2DeleteResult {
  YouTubeAnalyticsV2DeleteResult({
    required this.resourceId,
    required this.resourceKey,
  });

  factory YouTubeAnalyticsV2DeleteResult.group(Map<String, Object?> json) {
    return _delete(json, 'groupId');
  }

  factory YouTubeAnalyticsV2DeleteResult.groupItem(Map<String, Object?> json) {
    return _delete(json, 'groupItemId');
  }

  static YouTubeAnalyticsV2DeleteResult _delete(
    Map<String, Object?> json,
    String key,
  ) {
    if (_requiredBool(json, 'deleted') != true) {
      throw const FormatException('deleted must be true.');
    }
    return YouTubeAnalyticsV2DeleteResult(
      resourceId: _analyticsReportingResourceId(
        _requiredString(json, key),
        key,
      ),
      resourceKey: key,
    );
  }

  final String resourceId;
  final String resourceKey;
}

class YouTubeAnalyticsV2ResultRow {
  YouTubeAnalyticsV2ResultRow({
    required this.dimensions,
    required this.metrics,
  });

  factory YouTubeAnalyticsV2ResultRow.fromJson(Map<String, Object?> json) {
    final rawDimensions = _requiredMap(json, 'dimensions');
    final rawMetrics = _requiredMap(json, 'metrics');
    final dimensions = <String, String>{};
    final metrics = <String, num>{};
    for (final entry in rawDimensions.entries) {
      if (entry.key.isEmpty || entry.value is! String) {
        throw const FormatException('dimensions must contain text values.');
      }
      dimensions[entry.key] = entry.value! as String;
    }
    for (final entry in rawMetrics.entries) {
      final value = entry.value;
      if (entry.key.isEmpty || value is! num || !value.isFinite) {
        throw const FormatException('metrics must contain finite numbers.');
      }
      metrics[entry.key] = value;
    }
    return YouTubeAnalyticsV2ResultRow(
      dimensions: Map<String, String>.unmodifiable(dimensions),
      metrics: Map<String, num>.unmodifiable(metrics),
    );
  }

  final Map<String, String> dimensions;
  final Map<String, num> metrics;
}

class YouTubeAnalyticsV2ReportResult {
  YouTubeAnalyticsV2ReportResult({
    required this.channelId,
    required this.startDate,
    required this.endDate,
    required this.rows,
    required this.empty,
    this.continuationStartIndex,
  });

  factory YouTubeAnalyticsV2ReportResult.fromJson(Map<String, Object?> json) {
    final rows = _requiredList(json, 'rows')
        .map(_asMap)
        .map(YouTubeAnalyticsV2ResultRow.fromJson)
        .toList(growable: false);
    final empty = _requiredBool(json, 'empty');
    if (empty != rows.isEmpty) {
      throw const FormatException('empty must match rows.');
    }
    final continuation = _optionalPositiveInt(json, 'continuationStartIndex');
    final startDate = _analyticsReportingDate(
      _requiredString(json, 'startDate'),
      'startDate',
    );
    final endDate = _analyticsReportingDate(
      _requiredString(json, 'endDate'),
      'endDate',
    );
    if (startDate.isAfter(endDate) || rows.length > 200) {
      throw const FormatException('Analytics report bounds are invalid.');
    }
    return YouTubeAnalyticsV2ReportResult(
      channelId: _analyticsReportingChannelId(
        _requiredString(json, 'channelId'),
      ),
      startDate: startDate,
      endDate: endDate,
      rows: rows,
      empty: empty,
      continuationStartIndex: continuation,
    );
  }

  final String channelId;
  final DateTime startDate;
  final DateTime endDate;
  final List<YouTubeAnalyticsV2ResultRow> rows;
  final bool empty;
  final int? continuationStartIndex;
}

class YouTubeReportingV1PageRequest {
  YouTubeReportingV1PageRequest({
    String? pageToken,
    this.pageSize = 50,
    this.includeSystemManaged = false,
  }) : pageToken = pageToken == null
           ? null
           : _analyticsReportingPageToken(pageToken) {
    if (pageSize < 1 || pageSize > 100) {
      throw const FormatException('pageSize must be between 1 and 100.');
    }
  }

  final String? pageToken;
  final int pageSize;
  final bool includeSystemManaged;

  Map<String, Object?> toJson() => <String, Object?>{
    'pageToken': ?pageToken,
    'pageSize': pageSize,
    'includeSystemManaged': includeSystemManaged,
  };
}

class YouTubeReportingV1CreateJobRequest {
  YouTubeReportingV1CreateJobRequest({
    required String idempotencyKey,
    required String reportTypeId,
    required String name,
  }) : idempotencyKey = _analyticsReportingIdempotencyKey(idempotencyKey),
       reportTypeId = _analyticsReportingResourceId(
         reportTypeId,
         'reportTypeId',
       ),
       name = _analyticsReportingTitle(name, 100);

  final String idempotencyKey;
  final String reportTypeId;
  final String name;

  Map<String, Object?> toJson() => <String, Object?>{
    'idempotencyKey': idempotencyKey,
    'reportTypeId': reportTypeId,
    'name': name,
  };
}

class YouTubeReportingV1JobRequest {
  YouTubeReportingV1JobRequest({required String jobId})
    : jobId = _analyticsReportingResourceId(jobId, 'jobId');

  final String jobId;

  Map<String, Object?> toJson() => <String, Object?>{'jobId': jobId};
}

class YouTubeReportingV1DeleteJobRequest {
  YouTubeReportingV1DeleteJobRequest({
    required String idempotencyKey,
    required String jobId,
    required String confirmJobId,
  }) : idempotencyKey = _analyticsReportingIdempotencyKey(idempotencyKey),
       jobId = _analyticsReportingResourceId(jobId, 'jobId'),
       confirmJobId = _analyticsReportingResourceId(
         confirmJobId,
         'confirmJobId',
       ) {
    if (this.jobId != this.confirmJobId) {
      throw const FormatException('confirmJobId must match jobId.');
    }
  }

  final String idempotencyKey;
  final String jobId;
  final String confirmJobId;

  Map<String, Object?> toJson() => <String, Object?>{
    'idempotencyKey': idempotencyKey,
    'jobId': jobId,
    'confirmJobId': confirmJobId,
  };
}

class YouTubeReportingV1ReportWindow {
  YouTubeReportingV1ReportWindow({
    DateTime? createdAfter,
    DateTime? startTimeAtOrAfter,
    DateTime? startTimeBefore,
  }) : createdAfter = createdAfter?.toUtc(),
       startTimeAtOrAfter = startTimeAtOrAfter?.toUtc(),
       startTimeBefore = startTimeBefore?.toUtc() {
    final start = this.startTimeAtOrAfter;
    final end = this.startTimeBefore;
    if (start != null &&
        end != null &&
        (!start.isBefore(end) || end.difference(start).inDays > 366)) {
      throw const FormatException(
        'The report window must be ordered and no longer than 366 days.',
      );
    }
  }

  final DateTime? createdAfter;
  final DateTime? startTimeAtOrAfter;
  final DateTime? startTimeBefore;

  Map<String, Object?> toJson() => <String, Object?>{
    if (createdAfter case final value?) 'createdAfter': value.toIso8601String(),
    if (startTimeAtOrAfter case final value?)
      'startTimeAtOrAfter': value.toIso8601String(),
    if (startTimeBefore case final value?)
      'startTimeBefore': value.toIso8601String(),
  };
}

class YouTubeReportingV1ReportsRequest {
  YouTubeReportingV1ReportsRequest({
    required String jobId,
    String? pageToken,
    this.pageSize = 50,
    this.window,
  }) : jobId = _analyticsReportingResourceId(jobId, 'jobId'),
       pageToken = pageToken == null
           ? null
           : _analyticsReportingPageToken(pageToken) {
    if (pageSize < 1 || pageSize > 100) {
      throw const FormatException('pageSize must be between 1 and 100.');
    }
  }

  final String jobId;
  final String? pageToken;
  final int pageSize;
  final YouTubeReportingV1ReportWindow? window;

  Map<String, Object?> toJson() => <String, Object?>{
    'jobId': jobId,
    'pageToken': ?pageToken,
    'pageSize': pageSize,
    if (window case final value?) 'window': value.toJson(),
  };
}

class YouTubeReportingV1ReportRequest {
  YouTubeReportingV1ReportRequest({
    required String jobId,
    required String reportId,
  }) : jobId = _analyticsReportingResourceId(jobId, 'jobId'),
       reportId = _analyticsReportingResourceId(reportId, 'reportId');

  final String jobId;
  final String reportId;

  Map<String, Object?> toJson() => <String, Object?>{
    'jobId': jobId,
    'reportId': reportId,
  };
}

class YouTubeReportingV1DownloadRequest
    extends YouTubeReportingV1ReportRequest {
  YouTubeReportingV1DownloadRequest({
    required super.jobId,
    required super.reportId,
    this.maximumBytes = youtubeReportingV1MaximumMediaBytes,
  }) {
    if (maximumBytes < 1 ||
        maximumBytes > youtubeReportingV1MaximumMediaBytes) {
      throw const FormatException(
        'maximumBytes must be within the approved 8 MiB boundary.',
      );
    }
  }

  final int maximumBytes;

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    ...super.toJson(),
    'maximumBytes': maximumBytes,
  };
}

class YouTubeReportingV1ReportType {
  YouTubeReportingV1ReportType({
    required this.reportTypeId,
    required this.name,
    required this.systemManaged,
    required this.availability,
    this.deprecateTime,
  }) {
    if ((availability ==
                YouTubeReportingV1ReportTypeAvailability.systemManaged &&
            !systemManaged) ||
        (availability == YouTubeReportingV1ReportTypeAvailability.available &&
            systemManaged)) {
      throw const FormatException(
        'systemManaged must match report type availability.',
      );
    }
    if (availability == YouTubeReportingV1ReportTypeAvailability.deprecated &&
        deprecateTime == null) {
      throw const FormatException(
        'A deprecated report type requires deprecateTime.',
      );
    }
  }

  factory YouTubeReportingV1ReportType.fromJson(Map<String, Object?> json) {
    return YouTubeReportingV1ReportType(
      reportTypeId: _analyticsReportingResourceId(
        _requiredString(json, 'reportTypeId'),
        'reportTypeId',
      ),
      name: _analyticsReportingTitle(_requiredString(json, 'name'), 100),
      systemManaged: _requiredBool(json, 'systemManaged'),
      deprecateTime: _optionalDateTime(json, 'deprecateTime'),
      availability: _reportingV1ReportTypeAvailability(
        _requiredString(json, 'availability'),
      ),
    );
  }

  final String reportTypeId;
  final String name;
  final bool systemManaged;
  final DateTime? deprecateTime;
  final YouTubeReportingV1ReportTypeAvailability availability;
}

class YouTubeReportingV1Job {
  YouTubeReportingV1Job({
    required this.jobId,
    required this.reportTypeId,
    required this.name,
    required this.systemManaged,
    required this.createTime,
    required this.status,
    this.expireTime,
  }) {
    if ((status == YouTubeReportingV1JobStatus.systemManaged) !=
        systemManaged) {
      throw const FormatException(
        'systemManaged must match reporting job status.',
      );
    }
    if (status == YouTubeReportingV1JobStatus.expired && expireTime == null) {
      throw const FormatException('An expired job requires expireTime.');
    }
  }

  factory YouTubeReportingV1Job.fromJson(Map<String, Object?> json) {
    return YouTubeReportingV1Job(
      jobId: _analyticsReportingResourceId(
        _requiredString(json, 'jobId'),
        'jobId',
      ),
      reportTypeId: _analyticsReportingResourceId(
        _requiredString(json, 'reportTypeId'),
        'reportTypeId',
      ),
      name: _analyticsReportingTitle(_requiredString(json, 'name'), 100),
      systemManaged: _requiredBool(json, 'systemManaged'),
      createTime: _requiredDateTime(json, 'createTime'),
      expireTime: _optionalDateTime(json, 'expireTime'),
      status: _reportingV1JobStatus(_requiredString(json, 'status')),
    );
  }

  final String jobId;
  final String reportTypeId;
  final String name;
  final bool systemManaged;
  final DateTime createTime;
  final DateTime? expireTime;
  final YouTubeReportingV1JobStatus status;
}

class YouTubeReportingV1Report {
  YouTubeReportingV1Report({
    required this.reportId,
    required this.jobId,
    required this.createTime,
    required this.startTime,
    required this.endTime,
    required this.mediaResourceName,
    this.jobExpireTime,
  }) {
    if (!startTime.isBefore(endTime)) {
      throw const FormatException('Report startTime must precede endTime.');
    }
  }

  factory YouTubeReportingV1Report.fromJson(Map<String, Object?> json) {
    return YouTubeReportingV1Report(
      reportId: _analyticsReportingResourceId(
        _requiredString(json, 'reportId'),
        'reportId',
      ),
      jobId: _analyticsReportingResourceId(
        _requiredString(json, 'jobId'),
        'jobId',
      ),
      createTime: _requiredDateTime(json, 'createTime'),
      startTime: _requiredDateTime(json, 'startTime'),
      endTime: _requiredDateTime(json, 'endTime'),
      jobExpireTime: _optionalDateTime(json, 'jobExpireTime'),
      mediaResourceName: _reportingV1MediaResourceName(
        _requiredString(json, 'mediaResourceName'),
      ),
    );
  }

  final String reportId;
  final String jobId;
  final DateTime createTime;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? jobExpireTime;
  final String mediaResourceName;
}

class YouTubeReportingV1ReportTypesPage {
  YouTubeReportingV1ReportTypesPage({required this.items, this.nextPageToken});

  factory YouTubeReportingV1ReportTypesPage.fromJson(
    Map<String, Object?> json,
  ) {
    final items = _requiredList(json, 'items')
        .map(_asMap)
        .map(YouTubeReportingV1ReportType.fromJson)
        .toList(growable: false);
    _reportingV1PageSize(items.length);
    return YouTubeReportingV1ReportTypesPage(
      items: items,
      nextPageToken: _analyticsReportingOptionalPageToken(
        json,
        'nextPageToken',
      ),
    );
  }

  final List<YouTubeReportingV1ReportType> items;
  final String? nextPageToken;
}

class YouTubeReportingV1JobsPage {
  YouTubeReportingV1JobsPage({required this.items, this.nextPageToken});

  factory YouTubeReportingV1JobsPage.fromJson(Map<String, Object?> json) {
    final items = _requiredList(
      json,
      'items',
    ).map(_asMap).map(YouTubeReportingV1Job.fromJson).toList(growable: false);
    _reportingV1PageSize(items.length);
    return YouTubeReportingV1JobsPage(
      items: items,
      nextPageToken: _analyticsReportingOptionalPageToken(
        json,
        'nextPageToken',
      ),
    );
  }

  final List<YouTubeReportingV1Job> items;
  final String? nextPageToken;
}

class YouTubeReportingV1ReportsPage {
  YouTubeReportingV1ReportsPage({required this.items, this.nextPageToken});

  factory YouTubeReportingV1ReportsPage.fromJson(Map<String, Object?> json) {
    final items = _requiredList(json, 'items')
        .map(_asMap)
        .map(YouTubeReportingV1Report.fromJson)
        .toList(growable: false);
    _reportingV1PageSize(items.length);
    return YouTubeReportingV1ReportsPage(
      items: items,
      nextPageToken: _analyticsReportingOptionalPageToken(
        json,
        'nextPageToken',
      ),
    );
  }

  final List<YouTubeReportingV1Report> items;
  final String? nextPageToken;
}

class YouTubeReportingV1DeleteJobResult {
  YouTubeReportingV1DeleteJobResult({required this.jobId});

  factory YouTubeReportingV1DeleteJobResult.fromJson(
    Map<String, Object?> json,
  ) {
    if (_requiredBool(json, 'deleted') != true) {
      throw const FormatException('deleted must be true.');
    }
    return YouTubeReportingV1DeleteJobResult(
      jobId: _analyticsReportingResourceId(
        _requiredString(json, 'jobId'),
        'jobId',
      ),
    );
  }

  final String jobId;
}

class YouTubeReportingV1DownloadedMedia {
  YouTubeReportingV1DownloadedMedia({
    required String jobId,
    required String reportId,
    required this.byteLength,
    required String sha256,
    required String contentType,
    required String contentEncoding,
    required String bodyBase64,
  }) : jobId = _analyticsReportingResourceId(jobId, 'jobId'),
       reportId = _analyticsReportingResourceId(reportId, 'reportId'),
       sha256 = _reportingV1Sha256(sha256),
       contentType = _reportingV1ContentType(contentType),
       contentEncoding = _reportingV1ContentEncoding(contentEncoding),
       bodyBase64 = _reportingV1Base64(bodyBase64, byteLength) {
    if (byteLength < 0 || byteLength > youtubeReportingV1MaximumMediaBytes) {
      throw const FormatException(
        'byteLength exceeds the approved 8 MiB boundary.',
      );
    }
  }

  factory YouTubeReportingV1DownloadedMedia.fromJson(
    Map<String, Object?> json,
  ) {
    return YouTubeReportingV1DownloadedMedia(
      jobId: _requiredString(json, 'jobId'),
      reportId: _requiredString(json, 'reportId'),
      byteLength: _analyticsReportingNonNegativeInt(json, 'byteLength'),
      sha256: _requiredString(json, 'sha256'),
      contentType: _requiredString(json, 'contentType'),
      contentEncoding: _requiredString(json, 'contentEncoding'),
      bodyBase64: _requiredText(json, 'bodyBase64'),
    );
  }

  final String jobId;
  final String reportId;
  final int byteLength;
  final String sha256;
  final String contentType;
  final String contentEncoding;
  final String bodyBase64;
}

String _analyticsReportingIdempotencyKey(String value) {
  final clean = value.trim();
  if (!RegExp(r'^[A-Za-z0-9._:-]{8,128}$').hasMatch(clean)) {
    throw const FormatException('idempotencyKey is invalid.');
  }
  return clean;
}

String _analyticsReportingResourceId(String value, String label) {
  final clean = value.trim();
  if (!RegExp(r'^[A-Za-z0-9._:-]{1,256}$').hasMatch(clean)) {
    throw FormatException('$label is invalid.');
  }
  return clean;
}

String _analyticsReportingVideoId(String value) {
  final clean = value.trim();
  if (!RegExp(r'^[A-Za-z0-9_-]{6,20}$').hasMatch(clean)) {
    throw const FormatException('videoId is invalid.');
  }
  return clean;
}

String _analyticsReportingChannelId(String value) {
  final clean = value.trim();
  if (!RegExp(r'^[A-Za-z0-9_-]{6,64}$').hasMatch(clean)) {
    throw const FormatException('channelId is invalid.');
  }
  return clean;
}

String _analyticsV2GroupResourceId(
  YouTubeAnalyticsV2GroupItemType type,
  String value,
) {
  return switch (type) {
    YouTubeAnalyticsV2GroupItemType.channel => _analyticsReportingChannelId(
      value,
    ),
    YouTubeAnalyticsV2GroupItemType.video => _analyticsReportingVideoId(value),
    YouTubeAnalyticsV2GroupItemType.playlist => _analyticsReportingResourceId(
      value,
      'resourceId',
    ),
  };
}

String _analyticsReportingPageToken(String value) {
  final clean = value.trim();
  if (!RegExp(r'^[A-Za-z0-9._~-]{1,512}$').hasMatch(clean)) {
    throw const FormatException('pageToken is invalid.');
  }
  return clean;
}

String? _analyticsReportingOptionalPageToken(
  Map<String, Object?> json,
  String key,
) {
  final value = _optionalString(json, key);
  return value == null ? null : _analyticsReportingPageToken(value);
}

String _analyticsReportingTitle(String value, int maximum) {
  final clean = value.trim();
  if (clean.isEmpty ||
      clean.length > maximum ||
      RegExp(r'[\u0000-\u001f\u007f-\u009f]').hasMatch(clean)) {
    throw FormatException('Text must contain 1 to $maximum characters.');
  }
  return clean;
}

DateTime _dateOnly(DateTime value) {
  final utc = value.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day);
}

String _dateWireValue(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

DateTime _analyticsReportingDate(String value, String label) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw FormatException('$label must be a date.');
  }
  final parsed = DateTime.tryParse('${value}T00:00:00.000Z');
  if (parsed == null || _dateWireValue(parsed) != value) {
    throw FormatException('$label must be a valid date.');
  }
  return parsed;
}

int _analyticsReportingNonNegativeInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int && value >= 0) return value;
  throw FormatException('$key must be a non-negative whole number.');
}

YouTubeAnalyticsV2GroupItemType _analyticsV2GroupItemType(String value) {
  return switch (value) {
    'youtube#channel' => YouTubeAnalyticsV2GroupItemType.channel,
    'youtube#playlist' => YouTubeAnalyticsV2GroupItemType.playlist,
    'youtube#video' => YouTubeAnalyticsV2GroupItemType.video,
    _ => throw const FormatException(
      'itemType must be an ordinary channel, playlist, or video.',
    ),
  };
}

YouTubeReportingV1ReportTypeAvailability _reportingV1ReportTypeAvailability(
  String value,
) {
  return switch (value) {
    'available' => YouTubeReportingV1ReportTypeAvailability.available,
    'system-managed' => YouTubeReportingV1ReportTypeAvailability.systemManaged,
    'deprecated' => YouTubeReportingV1ReportTypeAvailability.deprecated,
    _ => throw const FormatException('availability is invalid.'),
  };
}

YouTubeReportingV1JobStatus _reportingV1JobStatus(String value) {
  return switch (value) {
    'active' => YouTubeReportingV1JobStatus.active,
    'expired' => YouTubeReportingV1JobStatus.expired,
    'system-managed' => YouTubeReportingV1JobStatus.systemManaged,
    _ => throw const FormatException('status is invalid.'),
  };
}

String _reportingV1MediaResourceName(String value) {
  if (!RegExp(r'^media/[A-Za-z0-9._~:/-]{1,900}$').hasMatch(value) ||
      value.contains('://') ||
      value.contains('..') ||
      value.contains('//') ||
      value.contains(r'\') ||
      value.contains('?') ||
      value.contains('#')) {
    throw const FormatException(
      'mediaResourceName must be a bounded provider resource name.',
    );
  }
  return value;
}

String _reportingV1Sha256(String value) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw const FormatException('sha256 must be a lowercase digest.');
  }
  return value;
}

String _reportingV1ContentType(String value) {
  const allowed = <String>{
    'text/csv',
    'application/csv',
    'application/gzip',
    'application/zip',
    'application/octet-stream',
  };
  final clean = value.trim().toLowerCase();
  if (!allowed.contains(clean)) {
    throw const FormatException('contentType is unsupported.');
  }
  return clean;
}

void _reportingV1PageSize(int length) {
  if (length > 100) {
    throw const FormatException('Reporting page exceeds 100 items.');
  }
}

String _reportingV1ContentEncoding(String value) {
  if (value != 'base64') {
    throw const FormatException('contentEncoding must be base64.');
  }
  return value;
}

String _reportingV1Base64(String value, int expectedLength) {
  final maximumEncodedLength =
      ((youtubeReportingV1MaximumMediaBytes + 2) ~/ 3) * 4;
  if (value.length > maximumEncodedLength ||
      value.length % 4 != 0 ||
      !RegExp(
        r'^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$',
      ).hasMatch(value)) {
    throw const FormatException('bodyBase64 is invalid.');
  }
  late final List<int> decoded;
  try {
    decoded = base64Decode(value);
  } on FormatException {
    throw const FormatException('bodyBase64 is invalid.');
  }
  if (decoded.length != expectedLength ||
      decoded.length > youtubeReportingV1MaximumMediaBytes) {
    throw const FormatException(
      'bodyBase64 does not match the bounded byteLength.',
    );
  }
  return value;
}
