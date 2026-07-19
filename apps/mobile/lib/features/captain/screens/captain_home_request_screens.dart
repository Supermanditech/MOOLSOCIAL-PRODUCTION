import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../captain_models.dart';
import '../captain_session.dart';
import '../widgets/captain_widgets.dart';

class CaptainHomeScreen extends StatelessWidget {
  const CaptainHomeScreen({required this.session, super.key});

  final CaptainSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => CaptainPageScaffold(
        session: session,
        title: 'Captain',
        subtitle: 'Bike · Jodhpur Central',
        activeDock: 'none',
        returnRoute: '/app/captain',
        showBack: false,
        trailing: IconButton.outlined(
          key: const Key('captain-controls'),
          tooltip: 'Open captain controls',
          onPressed: () => _controls(context),
          icon: const Icon(Icons.tune_rounded),
        ),
        body: ListView(
          key: const Key('captain-home-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            CaptainCard(
              keyName: 'captain-availability-card',
              color: MoolColors.navy,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.availableForRides
                              ? 'YOU ARE ONLINE'
                              : 'YOU ARE OFFLINE',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .72),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: MoolSpacing.xxs),
                        Text(
                          session.availableForRides
                              ? 'Ready for eligible rides'
                              : 'Go online for rides',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: MoolSpacing.xxs),
                        Text(
                          session.availableForRides
                              ? 'Live location is used only for eligible requests.'
                              : 'Location sharing starts only after you choose.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .78),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.sm),
                  FilledButton.tonal(
                    key: const Key('captain-online-toggle'),
                    onPressed: session.busy ? null : session.toggleAvailability,
                    style: FilledButton.styleFrom(
                      backgroundColor: session.availableForRides
                          ? MoolColors.success
                          : Colors.white.withValues(alpha: .16),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(92, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: MoolSpacing.sm,
                      ),
                    ),
                    child: Text(
                      session.availableForRides ? 'Online' : 'Go Online',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            const Row(
              children: [
                Expanded(
                  child: CaptainMetric(
                    label: 'TODAY',
                    value: '₹1,460',
                    detail: 'after charges',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: CaptainMetric(
                    label: 'TRIPS',
                    value: '11',
                    detail: 'completed',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: CaptainMetric(
                    label: 'ONLINE',
                    value: '6h 20m',
                    detail: 'today',
                  ),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.md),
            const CaptainSectionTitle(
              title: 'Demand near you',
              detail: 'Live zone signal',
            ),
            const SizedBox(height: MoolSpacing.sm),
            CaptainCard(
              keyName: 'captain-demand-zones',
              child: const Row(
                children: [
                  Expanded(
                    child: _DemandZone(
                      title: 'Station Road',
                      detail: 'High demand · 4 min away',
                    ),
                  ),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: _DemandZone(
                      title: 'Airport',
                      detail: '3 requests nearby',
                    ),
                  ),
                ],
              ),
            ),
            if (session.availableForRides) ...[
              const SizedBox(height: MoolSpacing.md),
              const CaptainSectionTitle(
                title: 'New ride request',
                detail: 'Complete details ready',
              ),
              const SizedBox(height: MoolSpacing.sm),
              CaptainActionRow(
                keyName: 'captain-open-request',
                icon: Icons.two_wheeler_rounded,
                title: 'Sardarpura to Jodhpur Airport',
                detail: '11.8 km · 28 min · pickup 2.1 km',
                meta: '₹238 expected net earning',
                action: 'Review',
                color: const Color(0xFFF4F3FF),
                onTap: () => context.go('/app/captain/requests'),
              ),
            ],
            const SizedBox(height: MoolSpacing.md),
            const CaptainSectionTitle(
              title: 'Priority',
              detail: 'One tap to act',
            ),
            const SizedBox(height: MoolSpacing.sm),
            CaptainActionRow(
              keyName: 'captain-priority-trips',
              icon: Icons.navigation_outlined,
              title: '2 trips need attention',
              detail: '1 pickup · 1 payment confirmation',
              meta: 'Continue from the latest trip step',
              action: 'Continue',
              onTap: () => context.go(session.currentTripRoute),
            ),
            const SizedBox(height: MoolSpacing.xs),
            CaptainActionRow(
              keyName: 'captain-priority-earnings',
              icon: Icons.account_balance_wallet_outlined,
              title: '₹3,090 available',
              detail: 'Next automatic payout tomorrow',
              meta: 'Ready for payout',
              action: 'View',
              onTap: () => context.go('/app/captain/earnings'),
            ),
            const SizedBox(height: MoolSpacing.xs),
            CaptainActionRow(
              keyName: 'captain-priority-documents',
              icon: Icons.verified_user_outlined,
              title: 'Insurance expires in 18 days',
              detail: 'Renew before ride eligibility pauses',
              meta: 'Reminder active',
              action: 'Renew',
              color: const Color(0xFFFFF6E8),
              onTap: () => context.go('/app/captain/compliance'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _controls(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('captain-controls-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Captain controls',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const Text('Availability never changes automatically.'),
            const SizedBox(height: MoolSpacing.md),
            const CaptainCard(
              color: Color(0xFFF4F3FF),
              child: Column(
                children: [
                  _ControlLine(label: 'Vehicle', value: 'Bike · RJ19'),
                  _ControlLine(label: 'Zone', value: 'Jodhpur Central'),
                  _ControlLine(
                    label: 'Location',
                    value: 'Live only when online',
                  ),
                  _ControlLine(label: 'Reliability', value: '96%'),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('captain-controls-support'),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  context.go('/app/captain/support-work');
                },
                child: const Text('Support & Paid Work'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const Key('captain-controls-close'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class CaptainRideRequestScreen extends StatelessWidget {
  const CaptainRideRequestScreen({required this.session, super.key});

  final CaptainSession session;

  @override
  Widget build(BuildContext context) {
    final request = reviewCaptainRide;
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => CaptainPageScaffold(
        session: session,
        title: 'Ride Request',
        subtitle: 'Route and earning before acceptance',
        activeDock: 'requests',
        returnRoute: '/app/captain',
        trailing: IconButton.outlined(
          key: const Key('captain-pause-requests'),
          tooltip: 'Pause requests',
          onPressed: () => _pauseSheet(context),
          icon: Icon(
            session.requestsPaused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
          ),
        ),
        bottomAction: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('captain-decline-ride'),
                onPressed: session.busy
                    ? null
                    : () async {
                        final ok = await session.declineRide();
                        if (ok && context.mounted) {
                          context.go('/app/captain?declined=${request.id}');
                        }
                      },
                child: const Text('Decline'),
              ),
            ),
            const SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: FilledButton(
                key: const Key('captain-accept-ride'),
                onPressed: session.busy
                    ? null
                    : () async {
                        final ok = await session.acceptRide();
                        if (ok && context.mounted) {
                          context.go('/app/captain/trips/${request.id}/pickup');
                        }
                      },
                child: const Text('Accept Ride'),
              ),
            ),
          ],
        ),
        body: ListView(
          key: const Key('captain-request-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            CaptainCard(
              color: const Color(0xFFF4F3FF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${request.service} · ${request.id}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const CaptainPill(
                        label: '24 SEC',
                        color: Color(0xFFB05C00),
                      ),
                    ],
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  const LinearProgressIndicator(
                    value: .68,
                    minHeight: 4,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    color: MoolColors.orange,
                    backgroundColor: Color(0xFFE4E5EF),
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  CaptainRouteMap(
                    label: 'Pickup ${request.pickupDistance}',
                    start: 'YOU',
                    end: 'PICK',
                    height: 210,
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  _RoutePoint(
                    label: 'A',
                    title: request.pickup,
                    detail: request.pickupDetail,
                    color: MoolColors.navy,
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                  _RoutePoint(
                    label: 'B',
                    title: request.drop,
                    detail: request.dropDetail,
                    color: MoolColors.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: CaptainMetric(
                    label: 'EXPECTED NET',
                    value: '₹${request.netEarning}',
                    detail: 'after est. fuel',
                  ),
                ),
                const SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: CaptainMetric(
                    label: 'RIDER FARE',
                    value: '₹${request.riderFare}',
                    detail: request.paymentMethod,
                  ),
                ),
                const SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: CaptainMetric(
                    label: 'PLATFORM',
                    value: '₹${request.platformCharge}',
                    detail: 'fuel est. ₹${request.estimatedFuel}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.sm),
            const CaptainCard(
              color: Color(0xFFEAF7E8),
              child: Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: MoolColors.success),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified rider · 4.8 rating',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Destination, fare and payment stay fixed unless both sides approve a change.',
                          style: TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pauseSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('captain-pause-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.requestsPaused
                  ? 'Resume ride requests'
                  : 'Pause ride requests',
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            Text(
              session.requestsPaused
                  ? 'Eligible requests can reach you again.'
                  : 'You will not receive another request until you resume.',
            ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('captain-pause-confirm'),
                onPressed: () {
                  session.setRequestsPaused(!session.requestsPaused);
                  Navigator.pop(sheetContext);
                },
                child: Text(
                  session.requestsPaused ? 'Resume Requests' : 'Pause Requests',
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const Key('captain-pause-cancel'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DemandZone extends StatelessWidget {
  const _DemandZone({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: MoolSpacing.sm),
    decoration: const BoxDecoration(
      border: Border(left: BorderSide(color: MoolColors.success, width: 3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        Text(
          detail,
          style: const TextStyle(color: MoolColors.muted, fontSize: 11),
        ),
      ],
    ),
  );
}

class _ControlLine extends StatelessWidget {
  const _ControlLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xxs),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: MoolColors.muted)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    ),
  );
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.label,
    required this.title,
    required this.detail,
    required this.color,
  });

  final String label;
  final String title;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 12,
        backgroundColor: color,
        foregroundColor: Colors.white,
        child: Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
        ),
      ),
      const SizedBox(width: MoolSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(
              detail,
              style: const TextStyle(color: MoolColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    ],
  );
}
