import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/features/work/work_models.dart';
import 'package:moolsocial/features/work/work_services.dart';
import 'package:moolsocial/features/work/work_session.dart';

void main() {
  test('release app defaults to the fail-closed production Work session', () {
    final source = File('lib/app/moolsocial_app.dart').readAsStringSync();
    expect(source, contains('widget.workSession ?? WorkSession.production()'));
    expect(source, isNot(contains('widget.workSession ?? WorkSession();')));
  });

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
      expect(await gateway.submitGst('wp-1', '08ABCDE1234F1Z5'), 'gst-1');
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

  test('pending review never invents a verified Workspace', () async {
    final session = WorkSession.production(gateway: _PendingGateway())
      ..selectedProfile = workProfiles.first
      ..workName = 'Mahadev Fresh Mart'
      ..workArea = 'Sardarpura, Jodhpur'
      ..reviewCaseId = 'wp-1'
      ..reviewStage = WorkReviewStage.gstPending;
    addTearDown(session.dispose);

    expect(await session.checkReview(), isTrue);
    expect(session.reviewStage, WorkReviewStage.gstPending);
    expect(session.activeWorkspace, isNull);
    expect(session.noticeMessage, contains('still in progress'));
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

SocialContentResponse _ok(Object? data) => SocialContentResponse(
  statusCode: 200,
  body: jsonEncode({'ok': true, 'data': data}),
);
