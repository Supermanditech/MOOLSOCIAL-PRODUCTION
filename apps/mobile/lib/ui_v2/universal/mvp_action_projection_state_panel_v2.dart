import 'package:flutter/material.dart';

import '../../core/design/mool_design_system.dart';
import '../../core/design/mool_theme.dart';

enum MvpActionProjectionState {
  active,
  loading,
  held,
  disabled,
  stale,
  offline,
  denied,
}

enum MvpActionProjectionRecovery { none, returnSafe, retryProjection }

@immutable
class MvpActionProjectionStateSpec {
  const MvpActionProjectionStateSpec({
    required this.id,
    required this.title,
    required this.detail,
    required this.recovery,
    this.safeContextRetained = true,
    this.committingActionAllowed = false,
  });

  final String id;
  final String title;
  final String detail;
  final MvpActionProjectionRecovery recovery;
  final bool safeContextRetained;
  final bool committingActionAllowed;
}

const mvpActionProjectionStateSpecs = <MvpActionProjectionState, MvpActionProjectionStateSpec>{
  MvpActionProjectionState.loading: MvpActionProjectionStateSpec(
    id: 'loading',
    title: 'Updating your actions',
    detail:
        'Your last safe choices stay in place while MoolSocial checks the current action list.',
    recovery: MvpActionProjectionRecovery.none,
  ),
  MvpActionProjectionState.held: MvpActionProjectionStateSpec(
    id: 'held',
    title: 'This action is not available yet',
    detail:
        'A required approval or dependency is still pending. Nothing was activated.',
    recovery: MvpActionProjectionRecovery.returnSafe,
  ),
  MvpActionProjectionState.disabled: MvpActionProjectionStateSpec(
    id: 'disabled',
    title: 'This action is unavailable',
    detail:
        'It is not enabled for this account or location. No capability was granted.',
    recovery: MvpActionProjectionRecovery.returnSafe,
  ),
  MvpActionProjectionState.stale: MvpActionProjectionStateSpec(
    id: 'stale',
    title: 'Your actions need an update',
    detail:
        'Your last safe choices remain visible, but a fresh action list is required before continuing.',
    recovery: MvpActionProjectionRecovery.retryProjection,
  ),
  MvpActionProjectionState.offline: MvpActionProjectionStateSpec(
    id: 'offline',
    title: 'You are offline',
    detail:
        'Your last safe choices remain visible. Reconnect and check again before opening an action.',
    recovery: MvpActionProjectionRecovery.retryProjection,
  ),
  MvpActionProjectionState.denied: MvpActionProjectionStateSpec(
    id: 'denied',
    title: 'This action is not permitted',
    detail:
        'It cannot open for this account. No other workspace or account details were disclosed.',
    recovery: MvpActionProjectionRecovery.returnSafe,
  ),
};

class MvpActionProjectionStatePanelV2 extends StatelessWidget {
  const MvpActionProjectionStatePanelV2({
    required this.state,
    this.onRetryProjection,
    this.onReturnSafe,
    super.key,
  });

  final MvpActionProjectionState state;
  final VoidCallback? onRetryProjection;
  final VoidCallback? onReturnSafe;

  @override
  Widget build(BuildContext context) {
    if (state == MvpActionProjectionState.active) {
      return const SizedBox.shrink(key: Key('mvp-projection-state-active'));
    }

    final spec = mvpActionProjectionStateSpecs[state]!;
    return MoolCardSurface(
      key: Key('mvp-projection-state-${spec.id}'),
      padding: const EdgeInsets.all(MoolSpacing.md),
      child: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _iconFor(state),
              key: Key('mvp-projection-state-icon-${spec.id}'),
              color: MoolColors.orange,
              size: 32,
            ),
            const SizedBox(height: MoolSpacing.sm),
            Semantics(
              header: true,
              child: Text(
                spec.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontSize: 18,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            Text(
              spec.detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: MoolColors.muted,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            ..._recoveryControls(spec.recovery),
          ],
        ),
      ),
    );
  }

  List<Widget> _recoveryControls(MvpActionProjectionRecovery recovery) {
    return switch (recovery) {
      MvpActionProjectionRecovery.none => const <Widget>[],
      MvpActionProjectionRecovery.retryProjection => <Widget>[
        const SizedBox(height: MoolSpacing.md),
        OutlinedButton.icon(
          key: const Key('mvp-projection-state-retry'),
          onPressed: onRetryProjection,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      ],
      MvpActionProjectionRecovery.returnSafe => <Widget>[
        const SizedBox(height: MoolSpacing.md),
        OutlinedButton.icon(
          key: const Key('mvp-projection-state-return-safe'),
          onPressed: onReturnSafe,
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Back to safe choices'),
        ),
      ],
    };
  }

  IconData _iconFor(MvpActionProjectionState state) {
    return switch (state) {
      MvpActionProjectionState.active => Icons.check_circle_outline_rounded,
      MvpActionProjectionState.loading => Icons.hourglass_top_rounded,
      MvpActionProjectionState.held => Icons.pause_circle_outline_rounded,
      MvpActionProjectionState.disabled => Icons.block_rounded,
      MvpActionProjectionState.stale => Icons.update_rounded,
      MvpActionProjectionState.offline => Icons.cloud_off_rounded,
      MvpActionProjectionState.denied => Icons.lock_outline_rounded,
    };
  }
}
