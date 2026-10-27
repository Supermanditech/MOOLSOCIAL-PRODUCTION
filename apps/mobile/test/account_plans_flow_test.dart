import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/core/design/mool_theme.dart';
import 'package:moolsocial/features/journey01/account_plans_gateway.dart';
import 'package:moolsocial/features/shared/social_content_gateway.dart';
import 'package:moolsocial/ui_v2/profile/global_account_plans_v2.dart';
import 'account_plans_gateway_test.dart'
    show
        owner,
        at,
        personal,
        workspace,
        plansFixture,
        plansReply,
        PlansCredentials,
        PlansTransport;

// Explicit host transport seam only. Production endpoint/payload/credentials
// pass through the actual gateway; only its network destination is loopback.
class _LocalHttpOverrides extends HttpOverrides {}

HttpClient _localHttpClient() => HttpOverrides.runWithHttpOverrides(
  () => HttpClient(),
  _LocalHttpOverrides(),
);

class _LocalPlansTransport implements SocialContentTransport {
  _LocalPlansTransport(
    this.port, {
    Duration timeout = const Duration(seconds: 5),
  }) : inner = IoSocialContentTransport(
         client: _localHttpClient(),
         timeout: timeout,
         followRedirects: false,
       );
  final int port;
  final IoSocialContentTransport inner;
  @override
  Future<SocialContentResponse> postJson(
    Uri endpoint, {
    required Map<String, String> headers,
    required Map<String, Object?> body,
  }) {
    expectSync(endpoint.host, 'asia-south1-fixture-project.cloudfunctions.net');
    expectSync(endpoint.path, '/moolSocialAccountPlans');
    return inner.postJson(
      Uri.http('127.0.0.1:$port', '/moolSocialAccountPlans'),
      headers: headers,
      body: body,
    );
  }
}

class _LocalPlansCredentials implements SocialContentCredentials {
  _LocalPlansCredentials([this.other = false]);
  final bool other;
  @override
  Future<String> firebaseIdToken() async =>
      other ? 'fixture-other-token' : 'fixture-token';
  @override
  Future<String> appCheckToken(SocialAppCheckTokenMode mode) async =>
      'fixture-proof';
}

const _localPort = int.fromEnvironment('B02_LOCAL_PORT');
Future<void> _fixture(String action) async {
  final client = _localHttpClient();
  try {
    final request = await client.getUrl(
      Uri.http('127.0.0.1:$_localPort', '/__fixture__', {'action': action}),
    );
    final reply = await request.close();
    await reply.drain<void>();
    expect(reply.statusCode, 200);
  } finally {
    client.close(force: true);
  }
}

void main() {
  test(
    'B02 local parity: actual mobile gateway -> HTTP -> service -> durable SQL, assigned version and lifecycle',
    () async {
      await _fixture('reset');
      final gateway = AccountPlansGateway(
        owner: owner,
        isCurrent: () => true,
        credentials: _LocalPlansCredentials(),
        transport: _LocalPlansTransport(_localPort),
      );
      final personalRead = await gateway.read(personal);
      expect(personalRead.offers.length, 12);
      expect(personalRead.activeFeatureIds, ['mool_ai']);
      final storeRead = await gateway.read(workspace);
      expect(storeRead.scope, workspace);
      expect(storeRead.activeFeatureIds, ['mool_ai']);
      final other = AccountPlansGateway(
        owner: (
          environment: owner.environment,
          projectId: owner.projectId,
          tenantId: null,
          userId: 'fixture-other',
        ),
        isCurrent: () => true,
        credentials: _LocalPlansCredentials(true),
        transport: _LocalPlansTransport(_localPort),
      );
      expect((await other.read(personal)).activeFeatureIds, isEmpty);
      await _fixture('catalogue-v2');
      final changed = await gateway.read(personal);
      expect(changed.offers.first.version, 'v2');
      expect(changed.subscription!.planVersion, 'v1');
      expect(changed.activeFeatureIds, ['mool_ai']);
      await _fixture('pending');
      expect((await gateway.read(personal)).activeFeatureIds, isEmpty);
      await _fixture('cancelled');
      expect((await gateway.read(personal)).activeFeatureIds, ['mool_ai']);
      await _fixture('expired');
      expect((await gateway.read(personal)).activeFeatureIds, isEmpty);
      await _fixture('revoked-store');
      await expectLater(
        gateway.read(workspace),
        throwsA(isA<AccountPlansFailure>()),
      );
      await _fixture('restrict');
      await expectLater(
        gateway.read(personal),
        throwsA(isA<AccountPlansFailure>()),
      );
    },
    skip: _localPort == 0
        ? 'Requires the explicitly isolated B02 production-code local SQL service.'
        : false,
  );

  test(
    'B02 local parity: transport timeout retries a read, malformed durable content fails closed',
    () async {
      await _fixture('reset');
      await _fixture('delay');
      final gateway = AccountPlansGateway(
        owner: owner,
        isCurrent: () => true,
        credentials: _LocalPlansCredentials(),
        transport: _LocalPlansTransport(
          _localPort,
          timeout: const Duration(milliseconds: 40),
        ),
      );
      await expectLater(gateway.read(personal), throwsA(anything));
      await _fixture('no-delay');
      expect((await gateway.read(personal, fresh: true)).offers.length, 12);
      await _fixture('broken');
      await expectLater(
        gateway.read(personal),
        throwsA(isA<AccountPlansFailure>()),
      );
      await _fixture('reset');
      await _fixture('durable');
      final durable = AccountPlansGateway(
        owner: owner,
        isCurrent: () => true,
        credentials: _LocalPlansCredentials(),
        transport: _LocalPlansTransport(_localPort),
      );
      expect((await durable.read(personal)).catalogueRevision, 7);
    },
    skip: _localPort == 0
        ? 'Requires the explicitly isolated B02 production-code local SQL service.'
        : false,
  );

  test(
    'B02 durable restart: a fresh client and server retain the original SQL catalogue',
    () async {
      final gateway = AccountPlansGateway(
        owner: owner,
        isCurrent: () => true,
        credentials: _LocalPlansCredentials(),
        transport: _LocalPlansTransport(_localPort),
      );
      final value = await gateway.read(personal);
      expect(value.catalogueRevision, 7);
      expect(value.offers.length, 17);
      expect(value.subscription!.planVersion, 'v1');
      expect(value.activeFeatureIds, ['mool_ai']);
    },
    skip: _localPort == 0
        ? 'Run only against the restarted B02 durable local service.'
        : false,
  );

  Future<void> mount(
    WidgetTester tester, {
    required AccountPlansGateway? gateway,
    Object? account = owner,
    String? storeId = 'fixture-store',
    double scale = 1,
    bool workspaceOnly = false,
    GlobalWorkspacePlanGuide guide = GlobalWorkspacePlanGuide.unknown,
    String? applicationLabel,
    VoidCallback? onOpenWorkspace,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MoolTheme.light(),
        home: RepaintBoundary(
          key: const Key('b02-plans-capture'),
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: GlobalAccountPlansConnected(
              accountScope: account,
              accountAuthenticated: account != null,
              gateway: gateway,
              storeId: storeId,
              storeName: storeId == null ? null : 'Host fixture Store',
              clock: () => at,
              workspaceOnly: workspaceOnly,
              workspaceAccessConfirmed: workspaceOnly && storeId != null,
              workspaceGuide: guide,
              applicationLabel: applicationLabel,
              onOpenWorkspace: onOpenWorkspace,
              onClose: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  AccountPlansGateway reader(PlansTransport transport) => AccountPlansGateway(
    owner: owner,
    isCurrent: () => true,
    credentials: PlansCredentials(),
    transport: transport,
    clock: () => at,
  );

  testWidgets(
    'B02 host-only rendered plan states',
    (tester) async {
      const destination = String.fromEnvironment('B02_CAPTURE_DIRECTORY');
      expect(
        destination.replaceAll('\\', '/'),
        contains('/profile-b02-plans-20261027-v1/'),
      );
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final scene in [
        (
          name: 'personal-normal',
          workspace: false,
          available: true,
          width: 360.0,
          scale: 1.0,
        ),
        (
          name: 'workspace-normal',
          workspace: true,
          available: true,
          width: 360.0,
          scale: 1.0,
        ),
        (
          name: 'personal-narrow-large-text',
          workspace: false,
          available: true,
          width: 320.0,
          scale: 2.0,
        ),
        (
          name: 'signed-out',
          workspace: false,
          available: false,
          width: 360.0,
          scale: 1.0,
        ),
      ]) {
        tester.view.physicalSize = Size(scene.width, 806);
        final gateway = scene.available
            ? reader(
                PlansTransport((body) {
                  final requested = body['payload'] as Map<String, Object?>;
                  return plansReply(
                    plansFixture(
                      scope: requested['audience'] == 'workspace'
                          ? workspace
                          : personal,
                      assigned: !scene.workspace,
                      count: 10,
                    ),
                  );
                }),
              )
            : null;
        await mount(
          tester,
          gateway: gateway,
          account: scene.available ? owner : null,
          scale: scene.scale,
          workspaceOnly: scene.workspace,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('b02-plans-capture')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('$destination/${scene.name}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
    skip: const String.fromEnvironment('B02_CAPTURE_DIRECTORY').isEmpty,
  );

  testWidgets(
    'B02 connected original page shows confirmed Personal plan and no unsupported billing handoff',
    (tester) async {
      await mount(
        tester,
        gateway: reader(PlansTransport((_) => plansReply(plansFixture()))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Current plan'), findsOneWidget);
      expect(
        find.textContaining('Host fixture plan 0 · Active until'),
        findsOneWidget,
      );
      expect(find.text('Manage plan'), findsNothing);
      expect(find.text('Recommended'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('B02 Personal and selected Store readback never mix', (
    tester,
  ) async {
    final calls = <Object?>[];
    final transport = PlansTransport((body) {
      final scope = body['payload'] as Map<String, Object?>;
      calls.add(scope);
      final data = scope['audience'] == 'personal'
          ? plansFixture()
          : plansFixture(scope: workspace, assigned: false);
      if (scope['audience'] == 'workspace') (data['offers'] as List).clear();
      return plansReply(data);
    });
    await mount(tester, gateway: reader(transport));
    await tester.pumpAndSettle();
    await mount(tester, gateway: reader(transport), workspaceOnly: true);
    await tester.pumpAndSettle();
    expect(find.text('Personal'), findsNothing);
    expect(calls.last, {'audience': 'workspace', 'storeId': 'fixture-store'});
    expect(find.text('Current plan'), findsNothing);
    expect(find.textContaining('Store · Host fixture Store'), findsOneWidget);
    expect(
      find.text('No plans are available for this account.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'B02 Workspace without an approved selected Store does not send a request',
    (tester) async {
      final transport = PlansTransport((_) => plansReply(plansFixture()));
      await mount(tester, gateway: reader(transport), storeId: null);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Workspace'));
      await tester.pumpAndSettle();
      expect(transport.calls, 1);
      expect(
        find.text('Check your Workspace application or start registration.'),
        findsOneWidget,
      );
      expect(find.text('Current plan'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'B02 preapproval Workspace is guidance and never a subscription request',
    (tester) async {
      final transport = PlansTransport((_) => plansReply(plansFixture()));
      var opened = 0;
      final gateway = reader(transport);
      await mount(
        tester,
        gateway: gateway,
        storeId: null,
        guide: GlobalWorkspacePlanGuide.available,
        onOpenWorkspace: () => opened++,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Workspace'));
      await tester.pumpAndSettle();
      expect(transport.calls, 1);
      expect(find.text('Activate Workspace'), findsOneWidget);
      expect(find.text('Current plan'), findsNothing);
      expect(find.text('Review plan'), findsNothing);
      await tester.tap(find.text('Activate Workspace'));
      expect(opened, 1);
      await mount(
        tester,
        gateway: gateway,
        storeId: null,
        guide: GlobalWorkspacePlanGuide.application,
        applicationLabel: 'Application awaiting review',
        onOpenWorkspace: () => opened++,
      );
      await tester.pumpAndSettle();
      expect(find.text('View application'), findsOneWidget);
      expect(find.text('Application awaiting review'), findsOneWidget);
      await tester.tap(find.text('View application'));
      expect(opened, 2);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'B02 approved owner personal Plans hides Workspace promotion without requesting Store subscriptions',
    (tester) async {
      final calls = <Object?>[];
      final transport = PlansTransport((body) {
        calls.add(body['payload']);
        return plansReply(plansFixture());
      });
      await mount(
        tester,
        gateway: reader(transport),
        guide: GlobalWorkspacePlanGuide.approved,
      );
      await tester.pumpAndSettle();
      expect(find.text('Workspace'), findsNothing);
      expect(find.text('Activate Workspace'), findsNothing);
      expect(find.textContaining('Store ·'), findsNothing);
      expect(calls, [
        {'audience': 'personal', 'storeId': null},
      ]);
      expect(find.text('Current plan'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('B02 lost Store binding clears confirmed paid presentation', (
    tester,
  ) async {
    final gateway = reader(
      PlansTransport((_) => plansReply(plansFixture(scope: workspace))),
    );
    await mount(tester, gateway: gateway, workspaceOnly: true);
    await tester.pumpAndSettle();
    expect(find.text('Current plan'), findsOneWidget);
    await mount(tester, gateway: gateway, workspaceOnly: true, storeId: null);
    await tester.pumpAndSettle();
    expect(find.text('Current plan'), findsNothing);
    expect(find.text('Personal'), findsNothing);
    expect(
      find.text('Open an approved Store from My Workspaces to view its plans.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'B02 zero-cost base access is separate from unavailable subscriptions',
    (tester) async {
      await mount(tester, gateway: null);
      expect(find.text('Free · ₹0'), findsOneWidget);
      expect(find.text('Included with your account'), findsOneWidget);
      expect(find.text('Current plan'), findsNothing);
      await mount(tester, gateway: null, workspaceOnly: true);
      expect(find.text('Free Workspace access'), findsOneWidget);
      await mount(tester, gateway: null, workspaceOnly: true, storeId: null);
      expect(find.byKey(const Key('account-free-access')), findsNothing);
      await mount(tester, gateway: null, account: null);
      expect(find.byKey(const Key('account-free-access')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('B02 failed read recovers through actual gateway retry', (
    tester,
  ) async {
    var failed = true;
    final transport = PlansTransport(
      (_) => failed
          ? const SocialContentResponse(statusCode: 503, body: '{"ok":false}')
          : plansReply(plansFixture()),
    );
    await mount(tester, gateway: reader(transport));
    await tester.pumpAndSettle();
    expect(find.text('Could not load plans.'), findsOneWidget);
    failed = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Current plan'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'B02 pending old-account reply cannot paint after owner changes',
    (tester) async {
      final pending = Completer<SocialContentResponse>();
      final gateway = reader(PlansTransport((_) => pending.future));
      await mount(tester, gateway: gateway);
      await mount(tester, gateway: null, account: 'other-account');
      pending.complete(plansReply(plansFixture()));
      await tester.pumpAndSettle();
      expect(find.text('Current plan'), findsNothing);
      expect(find.text('Plans are not available right now.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'B02 confirmed state expires and is not restored from local preferences',
    (tester) async {
      await mount(
        tester,
        gateway: reader(PlansTransport((_) => plansReply(plansFixture()))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Current plan'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
      expect(find.text('Current plan'), findsNothing);
      expect(find.text('Plans are not available right now.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'B02 lifecycle resume must read new authority rather than join the pre-pause request',
    (tester) async {
      final replies = <Completer<SocialContentResponse>>[];
      final resumedRequestStarted = Completer<void>();
      final transport = PlansTransport((_) {
        final reply = Completer<SocialContentResponse>();
        replies.add(reply);
        if (replies.length == 2) resumedRequestStarted.complete();
        return reply.future;
      });
      await mount(tester, gateway: reader(transport));
      await tester.pump();
      expect(transport.calls, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(tester.binding.lifecycleState, AppLifecycleState.resumed);
      // Lifecycle callbacks may resume their credentials outside the widget fake
      // clock. Observe the actual second request, not a premature counter sample.
      await tester.runAsync(
        () => resumedRequestStarted.future.timeout(const Duration(seconds: 2)),
      );
      final calls = transport.calls;
      for (final reply in replies) {
        reply.complete(plansReply(plansFixture(assigned: false)));
      }
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      expect(
        calls,
        2,
        reason: 'Resume must invalidate the old outstanding authority read.',
      );
    },
  );
}
