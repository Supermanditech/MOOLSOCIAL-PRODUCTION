import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../shared/social_content_gateway.dart';

const moolSocialWorkspaceUrl = String.fromEnvironment(
  'MOOLSOCIAL_WORKSPACE_URL',
);

class WorkGatewayException implements Exception {
  const WorkGatewayException(
    this.message, {
    this.retryable = false,
    this.cancelled = false,
  });
  final String message;
  final bool retryable;
  final bool cancelled;
  @override
  String toString() => message;
}

enum WorkProofSource { camera, gallery, upload }

class WorkPickedProof {
  const WorkPickedProof({
    required this.fileName,
    required this.contentType,
    required this.bytes,
  });

  final String fileName;
  final String contentType;
  final Uint8List bytes;
}

abstract interface class WorkProofPicker {
  Future<WorkPickedProof?> pick(WorkProofSource source);
}

class NativeWorkProofPicker implements WorkProofPicker {
  NativeWorkProofPicker({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<WorkPickedProof?> pick(WorkProofSource source) async {
    try {
      if (source == WorkProofSource.upload) {
        final file = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        );
        if (file == null) return null;
        final bytes = await file.readAsBytes();
        return _validateProof(file.name, bytes);
      }
      final image = await _imagePicker.pickImage(
        source: source == WorkProofSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (image == null) return null;
      return _validateProof(image.name, await image.readAsBytes());
    } on WorkGatewayException {
      rethrow;
    } on PlatformException catch (error) {
      final denied =
          error.code.toLowerCase().contains('denied') ||
          error.code.toLowerCase().contains('permission');
      throw WorkGatewayException(
        denied
            ? 'Camera or photo access was denied. Allow access in device settings, then try again.'
            : 'The device could not open that proof source. Try another source.',
      );
    } on FileSystemException {
      throw const WorkGatewayException(
        'That proof document could not be read. Choose it again.',
      );
    } on Object {
      throw const WorkGatewayException(
        'The device could not open that proof source. Try another source.',
      );
    }
  }
}

class ReviewWorkProofPicker implements WorkProofPicker {
  @override
  Future<WorkPickedProof?> pick(WorkProofSource source) async =>
      WorkPickedProof(
        fileName: source == WorkProofSource.upload
            ? 'review-proof.pdf'
            : 'review-proof.jpg',
        contentType: source == WorkProofSource.upload
            ? 'application/pdf'
            : 'image/jpeg',
        bytes: Uint8List.fromList(const [0xff, 0xd8, 0xff, 0xd9]),
      );
}

abstract interface class WorkProofUploadTransport {
  Future<void> put({
    required Uri url,
    required Map<String, String> headers,
    required Uint8List bytes,
  });
}

class IoWorkProofUploadTransport implements WorkProofUploadTransport {
  IoWorkProofUploadTransport({HttpClient? client})
    : _client = client ?? HttpClient();

  final HttpClient _client;

  @override
  Future<void> put({
    required Uri url,
    required Map<String, String> headers,
    required Uint8List bytes,
  }) async {
    if (url.scheme != 'https' || !url.host.endsWith('googleapis.com')) {
      throw const WorkGatewayException(
        'Proof upload could not be prepared. Choose the document again.',
      );
    }
    try {
      final request = await _client
          .putUrl(url)
          .timeout(const Duration(seconds: 15));
      request.contentLength = bytes.length;
      for (final entry in headers.entries) {
        if (entry.key.toLowerCase() == 'content-length') continue;
        request.headers.set(entry.key, entry.value);
      }
      request.add(bytes);
      final response = await request.close().timeout(
        const Duration(seconds: 45),
      );
      await response.drain<void>();
      if ((response.statusCode >= 200 && response.statusCode < 300) ||
          response.statusCode == HttpStatus.preconditionFailed) {
        return;
      }
      throw WorkGatewayException(
        response.statusCode == HttpStatus.unauthorized ||
                response.statusCode == HttpStatus.forbidden
            ? 'Proof upload expired. Choose the document again.'
            : 'Proof could not upload. Check your connection and try again.',
        retryable:
            response.statusCode == HttpStatus.requestTimeout ||
            response.statusCode == HttpStatus.tooManyRequests ||
            response.statusCode >= 500,
      );
    } on WorkGatewayException {
      rethrow;
    } on TimeoutException {
      throw const WorkGatewayException(
        'Proof upload timed out. Check your connection and try again.',
        retryable: true,
      );
    } on SocketException {
      throw const WorkGatewayException(
        'Proof could not upload. Check your connection and try again.',
        retryable: true,
      );
    } on Object {
      throw const WorkGatewayException(
        'Proof could not upload. Choose the document again.',
      );
    }
  }
}

class WorkProfileSubmission {
  const WorkProfileSubmission({
    required this.familyId,
    required this.profileId,
    required this.name,
    required this.area,
    required this.primaryActivity,
    required this.proofReferences,
    required this.alternateMobileVerified,
    required this.idempotencyKey,
  });
  final String familyId;
  final String profileId;
  final String name;
  final String area;
  final String primaryActivity;
  final Map<String, String> proofReferences;
  final bool alternateMobileVerified;
  final String idempotencyKey;
}

enum WorkRemoteReviewStatus { pending, approved, rejected, suspended, live }

class WorkReviewResult {
  const WorkReviewResult({
    required this.caseId,
    required this.status,
    required this.plan,
    this.workspaceId,
    this.reason,
    this.profileId,
    this.name,
    this.area,
    this.primaryActivity,
  });
  final String caseId;
  final WorkRemoteReviewStatus status;
  final String plan;
  final String? workspaceId;
  final String? reason;
  final String? profileId;
  final String? name;
  final String? area;
  final String? primaryActivity;
}

abstract interface class WorkGateway {
  Future<List<WorkReviewResult>> loadFeed();
  Future<String> apply(String opportunityId);
  Future<void> sendOtp(String mobile);
  Future<String> saveProof(String proofId, WorkPickedProof proof);
  Future<WorkReviewResult> submitProfile(WorkProfileSubmission submission);
  Future<WorkReviewResult> checkReview(String caseId);
  Future<String> submitGst(String caseId, String gstin, String proofReference);
  Future<void> finishSetup({
    required String workspaceId,
    required int quantity,
    required int buyPrice,
    required int sellPrice,
    required bool homeDelivery,
    required bool storeCollection,
  });
}

WorkGateway buildWorkGateway() {
  final endpoint = Uri.tryParse(moolSocialWorkspaceUrl.trim());
  if (endpoint == null ||
      endpoint.scheme != 'https' ||
      endpoint.host != 'asia-south1-moolsocial-dev-503018.cloudfunctions.net' ||
      endpoint.path != '/moolSocialWorkspace' ||
      endpoint.hasQuery ||
      endpoint.hasFragment) {
    return const UnavailableWorkGateway();
  }
  return AuthenticatedWorkGateway(
    endpoint: endpoint,
    credentials: FirebaseSocialContentCredentials(),
    transport: IoSocialContentTransport(),
  );
}

class UnavailableWorkGateway implements WorkGateway {
  const UnavailableWorkGateway();
  WorkGatewayException get _error => const WorkGatewayException(
    'Workspace service is unavailable right now. Your personal account remains active.',
    retryable: true,
  );
  @override
  Future<String> apply(String opportunityId) async => throw _error;
  @override
  Future<WorkReviewResult> checkReview(String caseId) async => throw _error;
  @override
  Future<void> finishSetup({
    required String workspaceId,
    required int quantity,
    required int buyPrice,
    required int sellPrice,
    required bool homeDelivery,
    required bool storeCollection,
  }) async => throw _error;
  @override
  Future<List<WorkReviewResult>> loadFeed() async => throw _error;
  @override
  Future<String> saveProof(String proofId, WorkPickedProof proof) async =>
      throw _error;
  @override
  Future<void> sendOtp(String mobile) async => throw _error;
  @override
  Future<WorkReviewResult> submitProfile(
    WorkProfileSubmission submission,
  ) async => throw _error;
  @override
  Future<String> submitGst(
    String caseId,
    String gstin,
    String proofReference,
  ) async => throw _error;
}

class AuthenticatedWorkGateway implements WorkGateway {
  AuthenticatedWorkGateway({
    required this.endpoint,
    required this.credentials,
    required this.transport,
    WorkProofUploadTransport? proofUploadTransport,
    Random? random,
  }) : proofUploadTransport =
           proofUploadTransport ?? IoWorkProofUploadTransport(),
       random = random ?? Random.secure();
  final Uri endpoint;
  final SocialContentCredentials credentials;
  final SocialContentTransport transport;
  final WorkProofUploadTransport proofUploadTransport;
  final Random random;

  @override
  Future<List<WorkReviewResult>> loadFeed() async {
    final data = _map(await _invoke('listWorkspaces', const {}));
    final items = data['workspaces'];
    if (items is! List) {
      throw const WorkGatewayException(
        'Workspace returned an invalid response. Try again.',
        retryable: true,
      );
    }
    return items.map((item) => _decodeReview(_map(item))).toList();
  }

  @override
  Future<String> apply(String opportunityId) async => _requiredString(
    _map(
      await _invoke('applyOpportunity', {
        'opportunityId': opportunityId,
      }, mutation: true),
    )['applicationId'],
  );
  @override
  Future<void> sendOtp(String mobile) =>
      _invoke('sendAlternateOtp', {'mobile': mobile}, mutation: true);
  @override
  Future<String> saveProof(String proofId, WorkPickedProof proof) async {
    final prepared = _map(
      await _invoke('prepareProofUpload', {
        'proofId': proofId,
        'fileName': proof.fileName,
        'contentType': proof.contentType,
        'sizeBytes': proof.bytes.length,
      }, mutation: true),
    );
    final uploadUrl = Uri.tryParse(_requiredString(prepared['uploadUrl']));
    final expiresAt = DateTime.tryParse(_requiredString(prepared['expiresAt']));
    if (uploadUrl == null ||
        expiresAt == null ||
        !expiresAt.isAfter(DateTime.now())) {
      throw const WorkGatewayException(
        'Proof upload could not be prepared. Choose the document again.',
        retryable: true,
      );
    }
    final headers = _map(
      prepared['requiredHeaders'],
    ).map((key, value) => MapEntry(key, _requiredString(value)));
    await proofUploadTransport.put(
      url: uploadUrl,
      headers: headers,
      bytes: proof.bytes,
    );
    return _requiredString(
      _map(
        await _invoke('confirmProofUpload', {
          'proofId': proofId,
          'uploadId': _requiredString(prepared['uploadId']),
          'fileName': proof.fileName,
          'contentType': proof.contentType,
          'sizeBytes': proof.bytes.length,
        }, mutation: true),
      )['proofReference'],
    );
  }

  @override
  Future<WorkReviewResult> submitProfile(WorkProfileSubmission value) async =>
      _decodeReview(
        _map(
          await _invoke('submitProfile', {
            'familyId': value.familyId,
            'profileId': value.profileId,
            'name': value.name,
            'area': value.area,
            'primaryActivity': value.primaryActivity,
            'proofReferences': value.proofReferences,
            'alternateMobileVerified': value.alternateMobileVerified,
            'idempotencyKey': value.idempotencyKey,
          }, mutation: true),
        ),
      );
  @override
  Future<WorkReviewResult> checkReview(String caseId) async =>
      _decodeReview(_map(await _invoke('reviewStatus', {'caseId': caseId})));
  @override
  Future<String> submitGst(
    String caseId,
    String gstin,
    String proofReference,
  ) async => _requiredString(
    _map(
      await _invoke('submitGst', {
        'caseId': caseId,
        'gstin': gstin,
        'proofReference': proofReference,
      }, mutation: true),
    )['gstReference'],
  );
  @override
  Future<void> finishSetup({
    required String workspaceId,
    required int quantity,
    required int buyPrice,
    required int sellPrice,
    required bool homeDelivery,
    required bool storeCollection,
  }) => _invoke('finishRetailerSetup', {
    'workspaceId': workspaceId,
    'quantity': quantity,
    'buyPrice': buyPrice,
    'sellPrice': sellPrice,
    'homeDelivery': homeDelivery,
    'storeCollection': storeCollection,
  }, mutation: true);

  Future<Object?> _invoke(
    String operation,
    Map<String, Object?> body, {
    bool mutation = false,
  }) async {
    final response = await transport.postJson(
      endpoint,
      headers: {
        'accept': 'application/json',
        'authorization': 'Bearer ${await credentials.firebaseIdToken()}',
        'x-firebase-appcheck': await credentials.appCheckToken(
          mutation
              ? SocialAppCheckTokenMode.limitedUse
              : SocialAppCheckTokenMode.standard,
        ),
        'x-request-id': List<int>.generate(
          16,
          (_) => random.nextInt(256),
        ).map((value) => value.toRadixString(16).padLeft(2, '0')).join(),
      },
      body: {'operation': operation, ...body},
    );
    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const WorkGatewayException(
        'Workspace returned an invalid response. Try again.',
        retryable: true,
      );
    }
    final envelope = _map(decoded);
    if (envelope['ok'] == true) return envelope['data'];
    final error = _map(envelope['error']);
    throw WorkGatewayException(
      _requiredString(error['message']),
      retryable: error['retryable'] == true,
    );
  }
}

class ReviewWorkGateway implements WorkGateway {
  bool failFeed = false;
  bool failApplication = false;
  bool failOtp = false;
  bool failProof = false;
  bool failSubmission = false;
  bool failReview = false;
  bool failGst = false;
  bool failSetup = false;
  int applicationCalls = 0;
  int otpCalls = 0;
  int proofCalls = 0;
  int submissionCalls = 0;
  int reviewCalls = 0;
  int gstCalls = 0;
  int setupCalls = 0;
  Future<void> _wait() =>
      Future<void>.delayed(const Duration(milliseconds: 24));
  @override
  Future<List<WorkReviewResult>> loadFeed() async {
    await _wait();
    if (failFeed) {
      failFeed = false;
      throw const WorkGatewayException(
        'Work could not be refreshed. Check your connection and try again.',
      );
    }
    return const [];
  }

  @override
  Future<String> apply(String opportunityId) async {
    applicationCalls++;
    await _wait();
    if (failApplication) {
      failApplication = false;
      throw const WorkGatewayException(
        'Application was not sent. Your opportunity is still saved.',
      );
    }
    return 'APP-${opportunityId.toUpperCase()}-${1200 + applicationCalls}';
  }

  @override
  Future<void> sendOtp(String mobile) async {
    otpCalls++;
    await _wait();
    if (failOtp) {
      failOtp = false;
      throw const WorkGatewayException(
        'OTP could not be sent. Check the number and try again.',
      );
    }
  }

  @override
  Future<String> saveProof(String proofId, WorkPickedProof proof) async {
    proofCalls++;
    await _wait();
    if (failProof) {
      failProof = false;
      throw const WorkGatewayException(
        'Proof was not added. Choose the same file or source and retry.',
      );
    }
    return 'PROOF-${proofId.toUpperCase()}-$proofCalls';
  }

  @override
  Future<WorkReviewResult> submitProfile(WorkProfileSubmission value) async {
    submissionCalls++;
    await _wait();
    if (failSubmission) {
      failSubmission = false;
      throw const WorkGatewayException(
        'Work profile was not submitted. Your details and proof remain saved.',
      );
    }
    return WorkReviewResult(
      caseId: 'WP-${240700 + submissionCalls}',
      status: WorkRemoteReviewStatus.pending,
      plan: 'free',
    );
  }

  @override
  Future<WorkReviewResult> checkReview(String caseId) async {
    reviewCalls++;
    await _wait();
    if (failReview) {
      failReview = false;
      throw const WorkGatewayException(
        'Review update is unavailable. No duplicate request was created.',
      );
    }
    return WorkReviewResult(
      caseId: caseId,
      status: WorkRemoteReviewStatus.approved,
      plan: 'free',
      workspaceId: 'WK-${510000 + reviewCalls}',
    );
  }

  @override
  Future<String> submitGst(
    String caseId,
    String gstin,
    String proofReference,
  ) async {
    gstCalls++;
    await _wait();
    if (failGst) {
      failGst = false;
      throw const WorkGatewayException(
        'GST proof was not submitted. Your review remains active.',
      );
    }
    return 'GST-$gstCalls';
  }

  @override
  Future<void> finishSetup({
    required String workspaceId,
    required int quantity,
    required int buyPrice,
    required int sellPrice,
    required bool homeDelivery,
    required bool storeCollection,
  }) async {
    setupCalls++;
    await _wait();
    if (failSetup) {
      failSetup = false;
      throw const WorkGatewayException(
        'Shop setup was not completed. Product and fulfilment choices remain saved.',
      );
    }
  }
}

WorkPickedProof _validateProof(String fileName, Uint8List bytes) {
  final extension = fileName.split('.').last.toLowerCase();
  final contentType = switch (extension) {
    'pdf' => 'application/pdf',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => throw const WorkGatewayException(
      'Choose a PDF, JPG, PNG or WebP proof document.',
    ),
  };
  if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
    throw const WorkGatewayException('Choose a proof document up to 10 MB.');
  }
  return WorkPickedProof(
    fileName: fileName,
    contentType: contentType,
    bytes: bytes,
  );
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) {
    throw const WorkGatewayException(
      'Workspace returned an invalid response. Try again.',
      retryable: true,
    );
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

String _requiredString(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const WorkGatewayException(
      'Workspace returned an invalid response. Try again.',
      retryable: true,
    );
  }
  return value.trim();
}

WorkReviewResult _decodeReview(Map<String, Object?> data) => WorkReviewResult(
  caseId: _requiredString(data['caseId']),
  status: switch (_requiredString(data['status'])) {
    'approved' => WorkRemoteReviewStatus.approved,
    'rejected' => WorkRemoteReviewStatus.rejected,
    'suspended' => WorkRemoteReviewStatus.suspended,
    'live' => WorkRemoteReviewStatus.live,
    _ => WorkRemoteReviewStatus.pending,
  },
  plan: _requiredString(data['plan']),
  workspaceId: data['workspaceId'] is String
      ? _requiredString(data['workspaceId'])
      : null,
  reason: data['reason'] is String ? _requiredString(data['reason']) : null,
  profileId: data['profileId'] is String
      ? _requiredString(data['profileId'])
      : null,
  name: data['name'] is String ? _requiredString(data['name']) : null,
  area: data['area'] is String ? _requiredString(data['area']) : null,
  primaryActivity: data['primaryActivity'] is String
      ? _requiredString(data['primaryActivity'])
      : null,
);
