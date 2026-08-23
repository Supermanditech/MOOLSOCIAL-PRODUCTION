import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moolsocial/ui_v2/universal/mvp_action_projection_state_panel_v2.dart';

void main() {
  Widget host(
    MvpActionProjectionState state, {
    VoidCallback? onRetryProjection,
    VoidCallback? onReturnSafe,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: MvpActionProjectionStatePanelV2(
            state: state,
            onRetryProjection: onRetryProjection,
            onReturnSafe: onReturnSafe,
          ),
        ),
      ),
    );
  }

  test('machine contract and native state specs remain identical', () {
    final contractFile = File.fromUri(
      Directory.current.uri.resolve(
        '../../config/mvp-personal-exposure-failure-states-v1.json',
      ),
    );
    final contract = jsonDecode(contractFile.readAsStringSync()) as Map;
    final states = (contract['states'] as List).cast<Map>();

    expect(
      contract['sourceProjectionState'],
      'static_reference_fixture_not_runtime_authority',
    );
    expect(contract['futureRuntimeOwner'], 'launch_policy_owner');
    expect(
      contract['runtimeIntegrationState'],
      'dependency_held_until_authoritative_projection_owner',
    );
    expect(contract['newScreenOwners'], 0);
    expect(contract['newRouteOwners'], 0);
    expect(contract['newBackendOwners'], 0);
    expect(states.map((state) => state['id']), [
      'loading',
      'held',
      'disabled',
      'stale',
      'offline',
      'denied',
    ]);
    expect(mvpActionProjectionStateSpecs.length, states.length);

    final nativeById = {
      for (final spec in mvpActionProjectionStateSpecs.values) spec.id: spec,
    };
    const recoveryById = {
      'none': MvpActionProjectionRecovery.none,
      'return_safe': MvpActionProjectionRecovery.returnSafe,
      'retry_projection': MvpActionProjectionRecovery.retryProjection,
    };
    for (final state in states) {
      final spec = nativeById[state['id']]!;
      expect(spec.title, state['title'], reason: '${state['id']} title');
      expect(spec.detail, state['detail'], reason: '${state['id']} detail');
      expect(
        spec.recovery,
        recoveryById[state['recovery']],
        reason: '${state['id']} recovery',
      );
      expect(spec.safeContextRetained, isTrue, reason: '${state['id']}');
      expect(state['safeContext'], 'retained', reason: '${state['id']}');
      expect(spec.committingActionAllowed, isFalse, reason: '${state['id']}');
      expect(
        state['committingActionAllowed'],
        isFalse,
        reason: '${state['id']}',
      );
    }
  });

  testWidgets('active state does not place a failure panel', (tester) async {
    await tester.pumpWidget(host(MvpActionProjectionState.active));

    expect(
      find.byKey(const Key('mvp-projection-state-active')),
      findsOneWidget,
    );
    expect(find.byType(MvpActionProjectionStatePanelV2), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    expect(find.text('Back to safe choices'), findsNothing);
  });

  for (final entry in mvpActionProjectionStateSpecs.entries) {
    testWidgets('${entry.value.id} shows exact truthful state copy', (
      tester,
    ) async {
      await tester.pumpWidget(host(entry.key));

      expect(
        find.byKey(Key('mvp-projection-state-${entry.value.id}')),
        findsOneWidget,
      );
      expect(find.text(entry.value.title), findsOneWidget);
      expect(find.text(entry.value.detail), findsOneWidget);
      expect(entry.value.safeContextRetained, isTrue);
      expect(entry.value.committingActionAllowed, isFalse);
    });
  }

  testWidgets('loading exposes no synthetic recovery action', (tester) async {
    var retryCount = 0;
    var safeCount = 0;
    await tester.pumpWidget(
      host(
        MvpActionProjectionState.loading,
        onRetryProjection: () => retryCount += 1,
        onReturnSafe: () => safeCount += 1,
      ),
    );

    expect(find.byKey(const Key('mvp-projection-state-retry')), findsNothing);
    expect(
      find.byKey(const Key('mvp-projection-state-return-safe')),
      findsNothing,
    );
    expect(retryCount, 0);
    expect(safeCount, 0);
  });

  for (final state in const [
    MvpActionProjectionState.stale,
    MvpActionProjectionState.offline,
  ]) {
    testWidgets('${state.name} owns retry and never safe return', (
      tester,
    ) async {
      var retryCount = 0;
      var safeCount = 0;
      await tester.pumpWidget(
        host(
          state,
          onRetryProjection: () => retryCount += 1,
          onReturnSafe: () => safeCount += 1,
        ),
      );

      expect(
        find.byKey(const Key('mvp-projection-state-return-safe')),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('mvp-projection-state-retry')));
      expect(retryCount, 1);
      expect(safeCount, 0);
    });
  }

  for (final state in const [
    MvpActionProjectionState.held,
    MvpActionProjectionState.disabled,
    MvpActionProjectionState.denied,
  ]) {
    testWidgets('${state.name} owns safe return and never retry', (
      tester,
    ) async {
      var retryCount = 0;
      var safeCount = 0;
      await tester.pumpWidget(
        host(
          state,
          onRetryProjection: () => retryCount += 1,
          onReturnSafe: () => safeCount += 1,
        ),
      );

      expect(find.byKey(const Key('mvp-projection-state-retry')), findsNothing);
      await tester.tap(
        find.byKey(const Key('mvp-projection-state-return-safe')),
      );
      expect(retryCount, 0);
      expect(safeCount, 1);
    });
  }

  test('no failure state claims success approval or active status', () {
    final successClaim = RegExp(r'\b(success|approved|active)\b');
    for (final spec in mvpActionProjectionStateSpecs.values) {
      expect(
        successClaim.hasMatch('${spec.title} ${spec.detail}'.toLowerCase()),
        isFalse,
        reason: spec.id,
      );
      expect(spec.committingActionAllowed, isFalse, reason: spec.id);
    }
  });
}
