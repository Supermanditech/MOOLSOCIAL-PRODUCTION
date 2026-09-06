import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';
import 'package:moolsocial/features/work/work_workspace_benefits.dart';

void main() {
  for (final source in [WorkProofSource.upload, WorkProofSource.cloudDrive]) {
    for (final extension in ['pdf', 'jpg', 'jpeg', 'png', 'webp']) {
      test(
        'native $source preserves selected $extension bytes and name',
        () async {
          final bytes = Uint8List.fromList([1, 2, 3, 4]);
          final picker = NativeWorkProofPicker(
            documentPicker: () async =>
                XFile.fromData(bytes, path: 'business-proof.$extension'),
          );
          final proof = await picker.pick(source);
          expect(proof!.fileName, 'business-proof.$extension');
          expect(proof.bytes, orderedEquals(bytes));
          expect(proof.contentType, switch (extension) {
            'pdf' => 'application/pdf',
            'jpg' || 'jpeg' => 'image/jpeg',
            _ => 'image/$extension',
          });
        },
      );
    }
    test('native $source cancellation leaves no document', () async {
      final picker = NativeWorkProofPicker(documentPicker: () async => null);
      expect(await picker.pick(source), isNull);
    });
  }
  for (final length in [0, 10 * 1024 * 1024 + 1]) {
    test(
      'native document rejects size $length before opening its stream',
      () async {
        final file = _BoundedProofFile(length: length);
        final picker = NativeWorkProofPicker(documentPicker: () async => file);
        await expectLater(
          picker.pick(WorkProofSource.upload),
          throwsA(
            isA<WorkGatewayException>().having(
              (error) => error.message,
              'message',
              contains('10 MB'),
            ),
          ),
        );
        expect(file.opens, 0);
      },
    );
  }
  test(
    'native document stops a growing or misreported stream at10MB',
    () async {
      final file = _BoundedProofFile(
        length: 1,
        chunks: [
          Uint8List(6 * 1024 * 1024),
          Uint8List(6 * 1024 * 1024),
          Uint8List(1),
        ],
      );
      final picker = NativeWorkProofPicker(documentPicker: () async => file);
      await expectLater(
        picker.pick(WorkProofSource.cloudDrive),
        throwsA(isA<WorkGatewayException>()),
      );
      expect(file.emitted, 2);
    },
  );
  test('native document read failure returns retry guidance', () async {
    final file = _BoundedProofFile(length: 1, failRead: true);
    final picker = NativeWorkProofPicker(documentPicker: () async => file);
    await expectLater(
      picker.pick(WorkProofSource.cloudDrive),
      throwsA(
        isA<WorkGatewayException>().having(
          (error) => error.message,
          'message',
          contains('could not be read'),
        ),
      ),
    );
  });
  test(
    'interrupted camera restores only the account-scoped document draft once',
    () async {
      final store = _PendingProofMemory()..draft = _cameraDraft();
      final picker = _RecoveryPicker();
      final work = WorkSession(pendingProofStore: store, proofPicker: picker);
      addTearDown(work.dispose);
      expect(await work.recoverPendingProof(accountReady: true), isTrue);
      expect(work.selectedProfile?.id, 'retailer-grocery');
      expect(work.workName, 'Review Kirana');
      expect(work.authorizedPersonName, 'Review Owner');
      expect(work.primaryMobileVerified, isTrue);
      expect(work.contactEmailVerified, isTrue);
      expect(work.primaryMobileOtpSent, isFalse);
      expect(work.declarationAccepted, isFalse);
      expect(work.hasVerifiedWorkspace, isFalse);
      expect(work.activeWorkspace, isNull);
      expect(work.pickedProofs['shop-front']?.fileName, 'Camera photo.jpg');
      expect(work.addedProofs.keys, contains('shop-front'));
      expect(work.addedProofs.keys, isNot(contains('unrelated-proof')));
      expect(work.recoveredDocumentStep, isTrue);
      expect(store.draft, isNull);
      expect(await work.recoverPendingProof(accountReady: true), isFalse);
      expect(picker.recoveries, 1);
      work.recoveredDocumentStep = false;
      store.accountScope = 'another-account';
      expect(await work.recoverPendingProof(accountReady: true), isFalse);
      expect(work.workName, isEmpty);
      expect(work.pickedProofs, isEmpty);
      expect(work.primaryMobileVerified, isFalse);
    },
  );

  test(
    'guest and different-account recovery never read or attach a proof',
    () async {
      final store = _PendingProofMemory()..draft = _cameraDraft();
      final picker = _RecoveryPicker();
      final work = WorkSession(pendingProofStore: store, proofPicker: picker);
      addTearDown(work.dispose);
      expect(await work.recoverPendingProof(accountReady: false), isFalse);
      expect(store.reads, 0);
      store.accountScope = 'another-account';
      expect(await work.recoverPendingProof(accountReady: true), isFalse);
      expect(work.selectedProfile, isNull);
      expect(picker.recoveries, 0);
      expect(store.draft, isNotNull);
    },
  );

  test(
    'empty lost-photo result keeps a named retry until the document is added',
    () async {
      final empty = Completer<WorkPickedProof?>()..complete(null);
      final store = _PendingProofMemory()..draft = _cameraDraft();
      final picker = _RecoveryPicker(delayedRecovery: empty);
      final work = WorkSession(pendingProofStore: store, proofPicker: picker);
      addTearDown(work.dispose);
      expect(await work.recoverPendingProof(accountReady: true), isTrue);
      expect(work.workName, 'Review Kirana');
      expect(work.documentRecoveryMessage, contains('Shop address document'));
      expect(work.documentRecoveryMessage, contains('again'));
      expect(work.noticeMessage, isNull);
      expect(work.pickedProofs, isEmpty);
      expect(work.hasVerifiedWorkspace, isFalse);
      work.dismissMessages();
      expect(work.documentRecoveryMessage, isNotNull);
      expect(
        await work.addProof('shop-front', WorkProofSource.camera),
        isFalse,
      );
      expect(work.documentRecoveryMessage, isNotNull);
      picker.nextPick = _cameraProof();
      expect(await work.addProof('shop-front', WorkProofSource.camera), isTrue);
      expect(work.documentRecoveryMessage, isNull);
      expect(work.pickedProofs['shop-front']?.fileName, 'Camera photo.jpg');
    },
  );

  for (final change in ['account', 'workspace']) {
    test('recovery retry guidance cannot leak into another $change', () async {
      final empty = Completer<WorkPickedProof?>()..complete(null);
      final store = _PendingProofMemory()..draft = _cameraDraft();
      final work = WorkSession(
        pendingProofStore: store,
        proofPicker: _RecoveryPicker(delayedRecovery: empty),
      );
      addTearDown(work.dispose);
      expect(await work.recoverPendingProof(accountReady: true), isTrue);
      expect(work.documentRecoveryMessage, isNotNull);
      if (change == 'account') {
        store.accountScope = 'another-account';
        expect(await work.recoverPendingProof(accountReady: true), isFalse);
      } else {
        work.startAnotherWork();
      }
      expect(work.documentRecoveryMessage, isNull);
    });
  }

  test('expired camera checkpoint cannot restore an old application', () async {
    final store = _PendingProofMemory()
      ..draft = _cameraDraft()
      ..draft!['savedAt'] = DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String();
    final picker = _RecoveryPicker();
    final work = WorkSession(pendingProofStore: store, proofPicker: picker);
    addTearDown(work.dispose);
    expect(await work.recoverPendingProof(accountReady: true), isFalse);
    expect(work.selectedProfile, isNull);
    expect(picker.recoveries, 0);
    expect(store.draft, isNull);
  });

  test(
    'camera recovery failure preserves details and asks for a real replacement',
    () async {
      final store = _PendingProofMemory()..draft = _cameraDraft();
      final work = WorkSession(
        pendingProofStore: store,
        proofPicker: _RecoveryPicker(failRecovery: true),
      );
      addTearDown(work.dispose);
      expect(await work.recoverPendingProof(accountReady: true), isTrue);
      expect(work.workName, 'Review Kirana');
      expect(work.errorMessage, contains('add it again'));
      expect(work.pickedProofs, isEmpty);
      expect(work.hasVerifiedWorkspace, isFalse);
    },
  );

  test(
    'account switch during lost-image recovery discards the old result',
    () async {
      final result = Completer<WorkPickedProof?>();
      final store = _PendingProofMemory()..draft = _cameraDraft();
      final picker = _RecoveryPicker(delayedRecovery: result);
      final work = WorkSession(pendingProofStore: store, proofPicker: picker);
      addTearDown(work.dispose);
      final recovery = work.recoverPendingProof(accountReady: true);
      await Future<void>.delayed(Duration.zero);
      store.accountScope = 'another-account';
      expect(await work.recoverPendingProof(accountReady: true), isFalse);
      result.complete(_cameraProof());
      expect(await recovery, isFalse);
      expect(work.pickedProofs, isEmpty);
      expect(work.workName, isEmpty);
      expect(work.activeWorkspace, isNull);
    },
  );

  test(
    'document launch checkpoints before opening camera and cancellation clears it',
    () async {
      final store = _PendingProofMemory();
      final result = Completer<WorkPickedProof?>();
      final picker = _RecoveryPicker(pendingPick: result);
      final work = WorkSession(pendingProofStore: store, proofPicker: picker)
        ..selectProfile('retailer-grocery')
        ..workName = 'Review Kirana'
        ..authorizedPersonName = 'Review Owner';
      addTearDown(work.dispose);
      final upload = work.addProof('shop-front', WorkProofSource.camera);
      await Future<void>.delayed(Duration.zero);
      expect(store.draft?['name'], 'Review Kirana');
      expect(store.draft?['proofId'], 'shop-front');
      expect(
        store.draft?.keys.any(
          (key) =>
              key.toLowerCase().contains('token') ||
              key.toLowerCase().contains('otp') ||
              key == 'bytes',
        ),
        isFalse,
      );
      expect(picker.picks, 1);
      result.complete(null);
      expect(await upload, isFalse);
      expect(store.draft, isNull);
      expect(work.addedProofs, isEmpty);
    },
  );

  test('first approval retains the submitted legal business name', () async {
    final gateway = ReviewWorkGateway()
      ..reviewResultStatus = WorkRemoteReviewStatus.approved;
    final work = WorkSession(gateway: gateway)
      ..selectProfile('retailer-grocery')
      ..workName = 'Review Kirana'
      ..reviewCaseId = 'review-case';
    addTearDown(work.dispose);
    expect(await work.checkReview(), isTrue);
    expect(work.activeWorkspace?.name, 'Review Kirana');
  });
  test(
    'order selection preserves packing and rider state without advancing another order',
    () {
      final session = WorkSession()..seedVerifiedWorkspace();
      addTearDown(session.dispose);
      WorkspaceOrderRecord order(String id, String stage) =>
          WorkspaceOrderRecord(
            id: id,
            customer: '$id customer',
            items: 'Atta × 1',
            quantities: const {},
            amount: 100,
            payment: 'Paid online',
            source: 'App',
            fulfilment: 'Mool delivery',
            address: '$id Market Road',
            stage: stage,
            needsDelivery: true,
            createdAt: DateTime(2026, 9, 6),
            actionDeadline: DateTime(2026, 9, 6, 10),
          );
      session.workspaceOrders.addAll([
        order('A', 'Preparing'),
        order('B', 'Confirmed'),
      ]);
      expect(session.selectWorkspaceOrder('A'), isTrue);
      session.setWorkspacePackingLine('summary-0', true);
      session.workspaceDeliveryAssignment = WorkspaceDeliveryAssignment(
        orderId: 'A',
        partnerName: 'Assigned rider',
        vehicleLabel: 'Bike',
        eta: DateTime(2026, 9, 6, 10),
        stage: 'Accepted',
      );
      expect(session.selectWorkspaceOrder('B'), isTrue);
      expect(session.currentWorkspaceOrderId, 'B');
      expect(session.workspaceOrderStage, 'Confirmed');
      expect(session.workspaceOrderAddress, 'B Market Road');
      expect(session.workspaceDeliveryAssignment, isNull);
      expect(session.workspacePackedProductIds, isEmpty);
      expect(session.workspaceOrders.first.stage, 'Preparing');
      expect(session.selectWorkspaceOrder('A'), isTrue);
      expect(session.workspacePackedProductIds, {'summary-0'});
      expect(session.workspaceDeliveryAssignment?.orderId, 'A');
      session.startNewWorkspaceOrder();
      expect(session.selectWorkspaceOrder('A'), isTrue);
      expect(session.workspacePackedProductIds, {'summary-0'});
      session.workspaceHandoverBusy = true;
      expect(session.selectWorkspaceOrder('B'), isFalse);
      expect(session.currentWorkspaceOrderId, 'A');
      session.workspaceHandoverBusy = false;
      session.startNewWorkspaceOrder();
      session.workspaceOrderQuantities['atta'] = 2;
      expect(session.selectWorkspaceOrder('B'), isFalse);
      expect(session.workspaceOrderQuantities, {'atta': 2});
      expect(session.currentWorkspaceOrderId, isNull);
    },
  );
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
      expect(work.errorMessage, contains('Your details are still here.'));
      expect(work.errorMessage, isNot(contains('saved on this device')));
      expect(work.unsupportedFamily, 'Other');
      expect(work.unsupportedArea, 'Jodhpur');
      expect(work.unsupportedOtherActivity, 'Furniture repairs');
    },
  );
  test('production offer cannot claim publication without acknowledgement', () {
    final work = WorkSession.production(gateway: UnavailableWorkGateway());
    addTearDown(work.dispose);
    work.addWorkspaceOffer(
      title: 'Monthly essentials',
      detail: 'Save on selected groceries.',
      validUntil: DateTime.now().add(const Duration(days: 7)),
      productId: 'oil-fortune-1l',
      orderCap: 50,
    );
    expect(work.workspaceOffers, isEmpty);
    expect(work.noticeMessage, isNull);
    expect(work.errorMessage, contains('not available yet'));
  });

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

Map<String, Object?> _cameraDraft() => {
  'version': 1,
  'savedAt': DateTime.now().toUtc().toIso8601String(),
  'profileId': 'retailer-grocery',
  'proofId': 'shop-front',
  'source': 'camera',
  'personName': 'Review Owner',
  'relationship': 'Owner',
  'name': 'Review Kirana',
  'area': 'Review market',
  'activity': 'Groceries',
  'phone': '9876543210',
  'email': 'review@example.com',
  'phoneConfirmed': true,
  'emailConfirmed': true,
  'proofs': {'unrelated-proof': 'must-not-restore'},
};

WorkPickedProof _cameraProof() => WorkPickedProof(
  fileName: 'Camera photo.jpg',
  contentType: 'image/jpeg',
  bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]),
);

class _PendingProofMemory implements WorkPendingProofStore {
  @override
  String? accountScope = 'review-account';
  String? savedScope = 'review-account';
  Map<String, Object?>? draft;
  int reads = 0;
  @override
  Future<Map<String, Object?>?> read(String scope) async {
    reads++;
    return scope == accountScope && scope == savedScope ? draft : null;
  }

  @override
  Future<void> save(String scope, Map<String, Object?> value) async {
    savedScope = scope;
    draft = Map.of(value);
  }

  @override
  Future<void> clear(String scope) async {
    if (scope == savedScope && scope == accountScope) draft = null;
  }
}

class _BoundedProofFile extends XFile {
  _BoundedProofFile({
    required int length,
    this.chunks = const [],
    this.failRead = false,
  }) : reportedLength = length,
       super('business-proof.pdf');
  final int reportedLength;
  final List<Uint8List> chunks;
  final bool failRead;
  int opens = 0, emitted = 0;
  @override
  String get name => 'business-proof.pdf';
  @override
  Future<int> length() async => reportedLength;
  @override
  Stream<Uint8List> openRead([int? start, int? end]) async* {
    opens++;
    if (failRead) {
      throw const FileSystemException('Could not read selected file');
    }
    for (final chunk in chunks) {
      emitted++;
      yield chunk;
    }
  }

  @override
  Future<Uint8List> readAsBytes() =>
      throw StateError('Unbounded read must not run');
}

class _RecoveryPicker implements WorkRecoverableProofPicker {
  _RecoveryPicker({
    this.failRecovery = false,
    this.pendingPick,
    this.delayedRecovery,
  });
  final bool failRecovery;
  final Completer<WorkPickedProof?>? pendingPick, delayedRecovery;
  WorkPickedProof? nextPick;
  int recoveries = 0, picks = 0;
  @override
  Future<WorkPickedProof?> pick(WorkProofSource source) async {
    picks++;
    return pendingPick == null ? nextPick : await pendingPick!.future;
  }

  @override
  Future<WorkPickedProof?> recover(WorkProofSource source) async {
    recoveries++;
    if (failRecovery) throw const WorkGatewayException('Please add it again.');
    return delayedRecovery == null
        ? _cameraProof()
        : await delayedRecovery!.future;
  }
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
