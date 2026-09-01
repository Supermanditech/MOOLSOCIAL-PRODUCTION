import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';

void main() {
  test('release app defaults to the fail-closed production Work session', () {
    final source = File('lib/main.dart').readAsStringSync();
    expect(source, contains('workSession: WorkSession.production(),'));
  });

  test('freelance fixtures expose complete funded role and poster data', () {
    const requiredIds = {
      'quick-delivery-biker',
      'user-acquisition-onboarding',
      'sales-specialist',
      'content-creator',
      'social-content-creator',
      'retailer-onboarding-specialist',
      'manufacturer-onboarding-specialist',
      'wholesaler-onboarding-specialist',
      'rider-onboarding-specialist',
      'taxi-operator-onboarding-specialist',
      'bike-rider-onboarding-specialist',
      'bus-operator-onboarding-specialist',
      'doctor-onboarding-specialist',
      'wholesale-sales-specialist',
      'bulk-sales-specialist',
    };

    expect(workOpportunities.map((item) => item.id), containsAll(requiredIds));
    expect(
      workOpportunities.map((item) => item.posterType).toSet(),
      containsAll(WorkOpportunityPosterType.values),
    );
    for (final opportunity in workOpportunities) {
      expect(opportunity.kind, contains('Freelance'));
      expect(opportunity.publisher, isNotEmpty);
      expect(opportunity.publisherType, isNotEmpty);
      expect(opportunity.qualificationHeadline, isNotEmpty);
      expect(opportunity.city, isNotEmpty);
      expect(opportunity.area, isNotEmpty);
      expect(opportunity.paymentAmount, isNotEmpty);
      expect(opportunity.monthlyPayment, isNotEmpty);
      expect(opportunity.aboutRole, isNotEmpty);
      expect(opportunity.whatYoullDo, isNotEmpty);
      expect(opportunity.whoYouAre, isNotEmpty);
      expect(opportunity.niceToHave, isNotEmpty);
      expect(opportunity.whyJoin, isNotEmpty);
      expect(opportunity.funded, isTrue);
      expect(opportunity.peopleNeeded, greaterThan(0));
      expect(opportunity.peopleJoined, greaterThanOrEqualTo(0));
      expect(opportunity.applicationsInProgress, greaterThanOrEqualTo(0));
      expect(
        opportunity.peopleJoined + opportunity.applicationsInProgress,
        lessThanOrEqualTo(opportunity.peopleNeeded),
      );
      expect(
        opportunity.positionsRemaining,
        opportunity.peopleNeeded -
            opportunity.peopleJoined -
            opportunity.applicationsInProgress,
      );
      expect(
        opportunity.finalDeadline,
        matches(RegExp(r'^\d{2} \w{3} \d{4}$')),
      );
    }
  });

  test('opportunity filters combine city, area and exact six-digit PIN', () {
    final session = WorkSession();
    addTearDown(session.dispose);

    session.setOpportunityLocationFilters(
      city: 'Jodhpur',
      area: 'Sardarpura',
      pincode: '342003',
    );
    expect(session.activeOpportunityFilterCount, 3);
    expect(session.filteredOpportunities.map((item) => item.id), [
      'quick-delivery-biker',
      'user-acquisition-onboarding',
    ]);

    session.setOpportunityLocationFilters(pincode: '34200');
    expect(session.filteredOpportunities, isEmpty);
    session.clearOpportunityFilters();
    expect(session.activeOpportunityFilterCount, 0);
    expect(session.filteredOpportunities, isNotEmpty);
  });

  test(
    'application and withdrawal remain bound to the exact opportunity',
    () async {
      final gateway = ReviewWorkGateway();
      final session = WorkSession(gateway: gateway);
      addTearDown(session.dispose);

      session.openOpportunity('content-creator');
      expect(await session.applySelectedOpportunity(), isTrue);
      final contentApplicationId = session.applicationId;
      expect(contentApplicationId, contains('CONTENT-CREATOR'));
      expect(session.appliedOpportunityId, 'content-creator');

      session.openOpportunity('social-content-creator');
      expect(session.applicationId, isNull);
      expect(await session.applySelectedOpportunity(), isTrue);
      final socialApplicationId = session.applicationId;
      expect(socialApplicationId, isNot(contentApplicationId));

      session.openOpportunity('content-creator');
      expect(session.applicationId, contentApplicationId);
      expect(await session.withdrawSelectedOpportunity(), isTrue);
      expect(session.withdrawnApplicationId, contentApplicationId);
      expect(session.applicationId, isNull);
      expect(
        session.applicationIdsByOpportunity['social-content-creator'],
        socialApplicationId,
      );
      expect(gateway.withdrawalCalls, 1);
    },
  );

  test(
    'failed withdrawal remains active and gives a retryable truth',
    () async {
      final gateway = ReviewWorkGateway()..failWithdrawal = true;
      final session = WorkSession(gateway: gateway);
      addTearDown(session.dispose);

      session.openOpportunity('content-creator');
      expect(await session.applySelectedOpportunity(), isTrue);
      final applicationId = session.applicationId;
      expect(await session.withdrawSelectedOpportunity(), isFalse);
      expect(session.applicationId, applicationId);
      expect(session.errorMessage, contains('remains active'));
      expect(await session.withdrawSelectedOpportunity(), isTrue);
      expect(gateway.withdrawalCalls, 2);
    },
  );

  test(
    'authenticated Workspace operations use exact bodies and App Check modes',
    () async {
      final transport = _RecordingTransport([
        _ok({'caseId': 'wp-1', 'status': 'pending', 'plan': 'free'}),
        _ok({
          'caseId': 'wp-1',
          'status': 'approved',
          'plan': 'free',
          'workspaceId': 'workspace-1',
        }),
        _ok({'gstReference': 'gst-1'}),
        _ok({'workspaceId': 'workspace-1', 'status': 'live', 'plan': 'free'}),
      ]);
      final credentials = _RecordingCredentials();
      final gateway = AuthenticatedWorkGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
        ),
        credentials: credentials,
        transport: transport,
        random: Random(1),
      );

      final submitted = await gateway.submitProfile(
        const WorkProfileSubmission(
          familyId: 'products-trade',
          profileId: 'retailer-grocery',
          name: 'Mahadev Fresh Mart',
          area: 'Sardarpura, Jodhpur',
          primaryActivity: 'Grocery and household products',
          proofReferences: {
            'personal-kyc': 'account-kyc',
            'shop-front': 'proof-shop',
            'owner-authority': 'proof-owner',
          },
          alternateMobileVerified: false,
          idempotencyKey: 'work-submit-001',
        ),
      );
      final reviewed = await gateway.checkReview('wp-1');
      expect(
        await gateway.submitGst('wp-1', '08ABCDE1234F1Z5', 'proof-gst-1'),
        'gst-1',
      );
      await gateway.finishSetup(
        workspaceId: 'workspace-1',
        quantity: 24,
        buyPrice: 48,
        sellPrice: 55,
        homeDelivery: true,
        storeCollection: false,
      );

      expect(submitted.status, WorkRemoteReviewStatus.pending);
      expect(submitted.plan, 'free');
      expect(reviewed.status, WorkRemoteReviewStatus.approved);
      expect(reviewed.workspaceId, 'workspace-1');
      expect(transport.bodies.map((body) => body['operation']), [
        'submitProfile',
        'reviewStatus',
        'submitGst',
        'finishRetailerSetup',
      ]);
      expect(transport.bodies.first['idempotencyKey'], 'work-submit-001');
      expect(transport.bodies.last, containsPair('quantity', 24));
      expect(credentials.modes, [
        SocialAppCheckTokenMode.limitedUse,
        SocialAppCheckTokenMode.standard,
        SocialAppCheckTokenMode.limitedUse,
        SocialAppCheckTokenMode.limitedUse,
      ]);
    },
  );

  test(
    'authenticated withdrawal sends both exact identities as a mutation',
    () async {
      final transport = _RecordingTransport([_ok(const {})]);
      final credentials = _RecordingCredentials();
      final gateway = AuthenticatedWorkGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
        ),
        credentials: credentials,
        transport: transport,
        random: Random(7),
      );

      await gateway.withdraw('application-42', 'content-creator');

      expect(transport.bodies.single, {
        'operation': 'withdrawOpportunity',
        'applicationId': 'application-42',
        'opportunityId': 'content-creator',
      });
      expect(credentials.modes, [SocialAppCheckTokenMode.limitedUse]);
    },
  );

  test(
    'proof document is privately uploaded and confirmed before acceptance',
    () async {
      final transport = _RecordingTransport([
        _ok({
          'uploadId': '00000000-0000-4000-8000-000000000001',
          'uploadUrl': 'https://storage.googleapis.com/private-upload',
          'expiresAt': '2099-08-29T09:05:00.000Z',
          'requiredHeaders': {
            'content-type': 'application/pdf',
            'content-length': '8',
          },
        }),
        _ok({'proofReference': 'proof-confirmed-1'}),
      ]);
      final upload = _RecordingProofUpload();
      final gateway = AuthenticatedWorkGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
        ),
        credentials: _RecordingCredentials(),
        transport: transport,
        proofUploadTransport: upload,
        random: Random(2),
      );
      final proof = WorkPickedProof(
        fileName: 'shop-front.pdf',
        contentType: 'application/pdf',
        bytes: Uint8List.fromList('%PDF-1.7'.codeUnits),
      );

      expect(await gateway.saveProof('shop-front', proof), 'proof-confirmed-1');
      expect(transport.bodies.map((body) => body['operation']), [
        'prepareProofUpload',
        'confirmProofUpload',
      ]);
      expect(upload.puts, 1);
      expect(upload.bytes, proof.bytes);
      expect(
        transport.bodies.last['uploadId'],
        '00000000-0000-4000-8000-000000000001',
      );
    },
  );

  test('pending review never invents a verified Workspace', () async {
    final session = WorkSession.production(gateway: _PendingGateway())
      ..selectedProfile = workProfiles.first
      ..workName = 'Mahadev Fresh Mart'
      ..workArea = 'Sardarpura, Jodhpur'
      ..reviewCaseId = 'wp-1'
      ..reviewStage = WorkReviewStage.gstPending;
    addTearDown(session.dispose);

    expect(await session.checkReview(), isFalse);
    expect(session.reviewStage, WorkReviewStage.gstPending);
    expect(session.activeWorkspace, isNull);
    expect(session.noticeMessage, contains('still in progress'));
  });

  test('rejected review preserves details for an exact resubmission', () async {
    final session = WorkSession.production(gateway: _RejectedGateway())
      ..selectedProfile = workProfiles.first
      ..selectedFamilyId = workProfiles.first.familyId
      ..workName = 'Mahadev Fresh Mart'
      ..workArea = 'Sardarpura, Jodhpur'
      ..primaryActivity = 'Grocery retail'
      ..reviewCaseId = 'wp-rejected'
      ..reviewStage = WorkReviewStage.gstPending;
    addTearDown(session.dispose);

    expect(await session.checkReview(), isFalse);
    expect(session.remoteReviewStatus, WorkRemoteReviewStatus.rejected);
    expect(session.reviewReason, 'Shop-front proof is unclear.');
    expect(session.activeWorkspace, isNull);

    session.reviseRejectedProfile();
    expect(session.reviewCaseId, isNull);
    expect(session.reviewStage, WorkReviewStage.drafting);
    expect(session.workName, 'Mahadev Fresh Mart');
    expect(session.workArea, 'Sardarpura, Jodhpur');
  });

  test(
    'authoritative Workspace state is restored after a fresh app session',
    () async {
      final session = WorkSession.production(gateway: _LoadedGateway());
      addTearDown(session.dispose);

      await session.loadInitialWorkspaceState();

      expect(session.activeWorkspace?.id, 'workspace-1');
      expect(session.activeWorkspace?.name, 'Mahadev Fresh Mart');
      expect(session.activeWorkspace?.profileLabel, 'Grocery / Kirana Shop');
      expect(session.reviewStage, WorkReviewStage.live);
      expect(session.subscriptionPlan, 'free');
    },
  );

  test('missing production endpoint fails truthfully', () async {
    final gateway = buildWorkGateway();
    expect(gateway, isA<UnavailableWorkGateway>());
    await expectLater(
      gateway.loadFeed(),
      throwsA(
        isA<WorkGatewayException>().having(
          (error) => error.retryable,
          'retryable',
          isTrue,
        ),
      ),
    );
  });
}

class _PendingGateway extends ReviewWorkGateway {
  @override
  Future<WorkReviewResult> checkReview(String caseId) async => WorkReviewResult(
    caseId: caseId,
    status: WorkRemoteReviewStatus.pending,
    plan: 'free',
  );
}

class _RejectedGateway extends ReviewWorkGateway {
  @override
  Future<WorkReviewResult> checkReview(String caseId) async => WorkReviewResult(
    caseId: caseId,
    status: WorkRemoteReviewStatus.rejected,
    plan: 'free',
    reason: 'Shop-front proof is unclear.',
  );
}

class _LoadedGateway extends ReviewWorkGateway {
  @override
  Future<List<WorkReviewResult>> loadFeed() async => const [
    WorkReviewResult(
      caseId: 'wp-1',
      status: WorkRemoteReviewStatus.live,
      plan: 'free',
      workspaceId: 'workspace-1',
      profileId: 'retailer-grocery',
      name: 'Mahadev Fresh Mart',
      area: 'Sardarpura, Jodhpur',
      primaryActivity: 'Grocery and household products',
    ),
  ];
}

class _RecordingCredentials implements SocialContentCredentials {
  final List<SocialAppCheckTokenMode> modes = [];

  @override
  Future<String> appCheckToken(SocialAppCheckTokenMode mode) async {
    modes.add(mode);
    return 'app-check-test';
  }

  @override
  Future<String> firebaseIdToken() async => 'firebase-id-test';
}

class _RecordingTransport implements SocialContentTransport {
  _RecordingTransport(this.responses);

  final List<SocialContentResponse> responses;
  final List<Map<String, Object?>> bodies = [];

  @override
  Future<SocialContentResponse> postJson(
    Uri endpoint, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) async {
    expect(endpoint.path, '/moolSocialWorkspace');
    expect(headers['authorization'], 'Bearer firebase-id-test');
    bodies.add(Map<String, Object?>.from(body));
    return responses.removeAt(0);
  }
}

class _RecordingProofUpload implements WorkProofUploadTransport {
  int puts = 0;
  Uint8List? bytes;

  @override
  Future<void> put({
    required Uri url,
    required Map<String, String> headers,
    required Uint8List bytes,
  }) async {
    puts += 1;
    this.bytes = bytes;
    expect(url.host, 'storage.googleapis.com');
    expect(headers['content-type'], 'application/pdf');
  }
}

SocialContentResponse _ok(Object? data) => SocialContentResponse(
  statusCode: 200,
  body: jsonEncode({'ok': true, 'data': data}),
);
