import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/features/work/work_workspace_benefits.dart';

void main() {
  for (final channel in WorkContactChannel.values) {
    test('changed $channel invalidates an in-flight OTP and consent', () async {
      final work = WorkSession(gateway: ReviewWorkGateway());
      addTearDown(work.dispose);
      await switch (channel) {
        WorkContactChannel.primaryMobile => work.sendPrimaryMobileOtp(
          '9829012321',
        ),
        WorkContactChannel.email => work.sendContactEmailOtp(
          'asha@example.com',
        ),
        WorkContactChannel.alternateMobile => work.sendAlternateOtp(
          '9876543210',
        ),
      };
      work.setDeclaration(true);
      final confirmation = switch (channel) {
        WorkContactChannel.primaryMobile => work.verifyPrimaryMobileOtp(
          '123456',
        ),
        WorkContactChannel.email => work.verifyContactEmailOtp('123456'),
        WorkContactChannel.alternateMobile => work.verifyAlternateOtp('123456'),
      };
      work.editWorkspaceContact(
        channel,
        channel == WorkContactChannel.email
            ? 'changed@example.com'
            : '9123456789',
      );
      expect(await confirmation, isFalse);
      expect(switch (channel) {
        WorkContactChannel.primaryMobile => work.primaryMobileVerified,
        WorkContactChannel.email => work.contactEmailVerified,
        WorkContactChannel.alternateMobile => work.alternateVerified,
      }, isFalse);
      expect(work.declarationAccepted, isFalse);
      expect(work.errorMessage, contains('Contact changed'));
    });
  }

  test('identity prefill never creates documentary verification', () {
    final work = WorkSession()
      ..hydrateAccountSnapshot(
        const WorkAccountSnapshot(
          displayName: 'Asha Sharma',
          email: 'asha@example.com',
          mobile: '9829012321',
          providerLabel: 'Google',
        ),
      );
    addTearDown(work.dispose);
    expect(work.authorizedPersonName, 'Asha Sharma');
    expect(work.primaryMobileVerified, isFalse);
    expect(work.contactEmailVerified, isFalse);
    expect(work.addedProofs, isEmpty);
    work.savePersonName('Edited name');
    work.hydrateAccountSnapshot(
      const WorkAccountSnapshot(displayName: 'Old name'),
    );
    expect(work.authorizedPersonName, 'Edited name');
    work.setDeclaration(true);
    work.saveBusinessRelationship('Authorized representative');
    expect(work.declarationAccepted, isFalse);
  });

  test(
    'unsupported production request stays a draft without acknowledgement',
    () async {
      final work = WorkSession.production(gateway: UnavailableWorkGateway());
      addTearDown(work.dispose);
      expect(
        await work.sendUnsupportedRequest(
          workspace: 'Furniture repair',
          family: 'Other',
          area: 'Jodhpur',
          otherActivity: 'Furniture repairs',
        ),
        isFalse,
      );
      expect(work.unsupportedRequestSent, isFalse);
      expect(work.unsupportedWorkspace, 'Furniture repair');
      expect(work.noticeMessage, isNull);
      expect(work.errorMessage, contains('cannot be sent yet'));
    },
  );
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

  test('Workspace chooser covers the current business and work choices', () {
    expect(
      workProfiles.map((profile) => profile.label),
      containsAll(const [
        'Grocery / Kirana Shop',
        'Speciality Retail Shop',
        'Wholesaler / Distributor',
        'Manufacturer / Supplier',
        'Restaurant / Café',
        'Cloud Kitchen / Tiffin',
        'Clinic / Doctor',
        'Pharmacy',
        'Salon / Wellness',
        'Bike Travel Provider',
        'Auto Travel Provider',
        'Cab Travel Provider',
        'Bus Travel Provider',
        'Quick Delivery Biker',
        'Wholesale Fleet Delivery',
        'Bulk Delivery Fleet',
        'Creator',
        'Freelancer / Job Seeker',
      ]),
    );
    expect(
      workProfiles.map((profile) => profile.id),
      isNot(containsAll(const ['service-provider', 'captain', 'fleet'])),
    );
    expect(
      workProfiles
          .where((profile) => profile.familyId == 'travel')
          .map((profile) => profile.label),
      [
        'Bike Travel Provider',
        'Auto Travel Provider',
        'Cab Travel Provider',
        'Bus Travel Provider',
      ],
    );
    expect(
      workProfiles
          .where((profile) => profile.familyId == 'delivery')
          .map((profile) => profile.label),
      [
        'Quick Delivery Biker',
        'Wholesale Fleet Delivery',
        'Bulk Delivery Fleet',
      ],
    );
    expect(
      workProfiles.map((profile) => profile.gstMatchCategory).toSet(),
      containsAll(WorkGstMatchCategory.values),
    );
    for (final profile in workProfiles) {
      expect(profile.verificationDocuments, isNotEmpty);
      expect(
        profile.verificationDocuments.any(
          (document) => document.importance == WorkDocumentImportance.required,
        ),
        isTrue,
      );
      final gst = profile.verificationDocuments.singleWhere(
        (document) => document.title == 'GST registration certificate',
      );
      final payoutBank = profile.verificationDocuments.singleWhere(
        (document) => document.title == 'Payout bank account proof',
      );
      expect(payoutBank.importance, WorkDocumentImportance.required);
      expect(payoutBank.detail, contains('cancelled cheque'));
      expect(payoutBank.detail, contains('bank statement PDF'));
      expect(gst.importance, WorkDocumentImportance.ifApplicable);
      expect(gst.detail, contains('Required when GST registration applies'));
      expect(gst.detail.toLowerCase(), isNot(contains('turnover')));
      expect(gst.detail, isNot(matches(RegExp(r'₹|lakh|crore'))));
      expect(
        profile.verificationDocuments.map((document) => document.title).toSet(),
        hasLength(profile.verificationDocuments.length),
      );

      final session = WorkSession()
        ..selectFamily(profile.familyId)
        ..selectProfile(profile.id);
      addTearDown(session.dispose);
      expect(session.selectedGstMatchCategory, profile.gstMatchCategory);
      expect(
        session.selectedGstChecklistItem?.importance,
        WorkDocumentImportance.ifApplicable,
      );
      expect(
        session.selectedWorkspaceDocuments.map((document) => document.label),
        profile.verificationDocuments.map((document) => document.title),
      );
      expect(
        session.selectedWorkspaceDocuments.map((document) => document.label),
        contains('Payout bank account proof'),
      );
      expect(
        session.selectedWorkspaceDocuments
            .singleWhere(
              (document) => document.label == 'Payout bank account proof',
            )
            .id,
        'payout-bank-account',
      );
    }
    final gstProof = workProofs.singleWhere((proof) => proof.id == 'gst');
    expect(gstProof.importance, WorkDocumentImportance.ifApplicable);
    expect(gstProof.required, isFalse);

    expect(
      workWorkspaceBenefits.keys.toSet(),
      workProfiles.map((profile) => profile.id).toSet(),
    );
    for (final content in workWorkspaceBenefits.values) {
      expect(content.problem.trim(), isNotEmpty);
      expect(content.preview.trim(), isNotEmpty);
      expect(content.benefits, hasLength(4));
      expect(content.difference.trim(), isNotEmpty);
      final visibleCopy = [
        content.problem,
        content.preview,
        content.difference,
        ...content.benefits.expand(
          (benefit) => [benefit.title, benefit.detail],
        ),
      ].join(' ').toLowerCase();
      expect(visibleCopy, isNot(matches(RegExp(r'\bactor\b'))));
      expect(visibleCopy, isNot(contains('user type')));
      expect(visibleCopy, isNot(contains('internal')));
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
        _ok(const {}),
        _ok(const {}),
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

      await gateway.sendContactOtp(
        channel: WorkContactChannel.primaryMobile,
        value: '9829012321',
      );
      await gateway.verifyContactOtp(
        channel: WorkContactChannel.primaryMobile,
        value: '9829012321',
        code: '123456',
      );

      const profileSubmission = WorkProfileSubmission(
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
        primaryMobile: '9829012321',
        email: 'asha@example.com',
        connectedProvider: 'Google',
        connectedProviderAccount: 'asha@example.com',
        alternateMobileVerified: false,
        idempotencyKey: 'work-submit-001',
      );
      final submitted = await gateway.submitProfile(profileSubmission);
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
        'sendWorkspaceContactOtp',
        'verifyWorkspaceContactOtp',
        'submitProfile',
        'reviewStatus',
        'submitGst',
        'finishRetailerSetup',
      ]);
      expect(transport.bodies.first, containsPair('channel', 'primary_mobile'));
      expect(transport.bodies[1], containsPair('code', '123456'));
      expect(transport.bodies[2]['idempotencyKey'], 'work-submit-001');
      expect(transport.bodies[2], containsPair('email', 'asha@example.com'));
      expect(transport.bodies.last, containsPair('quantity', 24));
      expect(credentials.modes, [
        SocialAppCheckTokenMode.limitedUse,
        SocialAppCheckTokenMode.limitedUse,
        SocialAppCheckTokenMode.limitedUse,
        SocialAppCheckTokenMode.standard,
        SocialAppCheckTokenMode.limitedUse,
        SocialAppCheckTokenMode.limitedUse,
      ]);
    },
  );

  test(
    'production correction fails closed until backend support exists',
    () async {
      final transport = _RecordingTransport([]);
      final gateway = AuthenticatedWorkGateway(
        endpoint: Uri.parse(
          'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
        ),
        credentials: _RecordingCredentials(),
        transport: transport,
        random: Random(11),
      );

      await expectLater(
        gateway.submitCorrection(
          'wp-1',
          const WorkProfileSubmission(
            familyId: 'products-trade',
            profileId: 'retailer-grocery',
            name: 'Mahadev Fresh Mart',
            area: 'Jodhpur',
            primaryActivity: 'Grocery retail',
            proofReferences: {'personal-kyc': 'account-kyc'},
            primaryMobile: '9829012321',
            email: 'asha@example.com',
            connectedProvider: 'Google',
            connectedProviderAccount: 'asha@example.com',
            alternateMobileVerified: false,
            idempotencyKey: 'work-submit-001',
          ),
        ),
        throwsA(
          isA<WorkGatewayException>().having(
            (error) => error.message,
            'message',
            contains('not available yet'),
          ),
        ),
      );
      expect(transport.bodies, isEmpty);
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

  test('store operations use exact authenticated mutation contracts', () async {
    final transport = _RecordingTransport([
      _ok(const {}),
      _ok({'paymentReference': 'PAY-GROUP-1'}),
      _ok({'reference': 'WORK-1'}),
      _ok({'reference': 'SET-1', 'acceptedAmount': 800}),
      _ok(const {}),
      _ok({
        'partnerName': 'Mool Delivery Partner',
        'vehicleLabel': 'RJ19 AB 1234',
        'eta': '2026-09-03T12:15:00.000Z',
        'stage': 'Assigned',
      }),
    ]);
    final credentials = _RecordingCredentials();
    final gateway = AuthenticatedWorkGateway(
      endpoint: Uri.parse(
        'https://asia-south1-moolsocial-dev-503018.cloudfunctions.net/moolSocialWorkspace',
      ),
      credentials: credentials,
      transport: transport,
      random: Random(19),
    );

    await gateway.saveOperationalState(
      const WorkOperationalSnapshot(
        workspaceId: 'workspace-1',
        reason: 'catalogue-updated',
        state: {
          'storeState': 'open',
          'catalogue': [
            {'sku': 'ATTA-5KG', 'sellingPrice': 275, 'stock': 10},
          ],
        },
        idempotencyKey: 'OPS-1',
      ),
    );
    expect(
      await gateway.createGroupBuy(
        const WorkGroupBuySubmission(
          workspaceId: 'workspace-1',
          values: {
            'productName': 'Premium red onion',
            'targetQuantity': 1000,
            'confirmationAmount': 3920,
          },
          idempotencyKey: 'GROUP-1',
        ),
      ),
      'PAY-GROUP-1',
    );
    expect(
      await gateway.createPaidRequirement(
        const WorkPaidRequirementSubmission(
          workspaceId: 'workspace-1',
          values: {
            'position': 'Evening packing assistant',
            'peopleNeeded': 2,
            'paymentAmount': 600,
          },
          idempotencyKey: 'WORK-1',
        ),
      ),
      'WORK-1',
    );
    final settlement = await gateway.requestSettlement(
      workspaceId: 'workspace-1',
      amount: 800,
      idempotencyKey: 'SETTLEMENT-1',
    );
    await gateway.verifyOrderHandover(
      workspaceId: 'workspace-1',
      orderId: 'order-1',
      otp: '123456',
      idempotencyKey: 'HANDOVER-1',
    );
    final delivery = await gateway.requestDeliveryAssignment(
      workspaceId: 'workspace-1',
      orderId: 'order-1',
      address: '21 Residency Road, Jodhpur',
      idempotencyKey: 'DELIVERY-1',
    );

    expect(settlement.reference, 'SET-1');
    expect(settlement.acceptedAmount, 800);
    expect(delivery.partnerName, 'Mool Delivery Partner');
    expect(delivery.eta.toUtc().toIso8601String(), '2026-09-03T12:15:00.000Z');
    expect(transport.bodies.map((body) => body['operation']), [
      'saveWorkspaceOperations',
      'createWorkspaceGroupBuy',
      'createWorkspacePaidRequirement',
      'requestWorkspaceSettlement',
      'verifyWorkspaceOrderHandover',
      'requestWorkspaceDelivery',
    ]);
    expect(transport.bodies.first['state'], isA<Map<String, Object?>>());
    expect(transport.bodies[1]['values'], containsPair('targetQuantity', 1000));
    expect(
      transport.bodies[2]['values'],
      containsPair('position', 'Evening packing assistant'),
    );
    expect(transport.bodies[3], containsPair('amount', 800));
    expect(transport.bodies[4], containsPair('otp', '123456'));
    expect(
      transport.bodies.last,
      containsPair('address', '21 Residency Road, Jodhpur'),
    );
    expect(
      credentials.modes,
      List<SocialAppCheckTokenMode>.filled(
        6,
        SocialAppCheckTokenMode.limitedUse,
      ),
    );
  });

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
    expect(session.noticeMessage, isNull);
    expect(session.remoteReviewStatus, WorkRemoteReviewStatus.pending);
  });

  test('rejected review cannot silently erase or restart its case', () async {
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
    expect(session.reviewCaseId, 'wp-rejected');
    expect(session.reviewStage, WorkReviewStage.gstPending);
    expect(session.remoteReviewStatus, WorkRemoteReviewStatus.rejected);
    expect(session.reviewReason, 'Shop-front proof is unclear.');
    expect(session.beginReviewCorrection(), isFalse);
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
