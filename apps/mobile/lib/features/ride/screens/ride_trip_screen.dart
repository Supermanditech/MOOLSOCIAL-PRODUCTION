import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../ride_models.dart';
import '../ride_session.dart';
import '../widgets/ride_widgets.dart';

class RideTripScreen extends StatelessWidget {
  const RideTripScreen({
    required this.session,
    required this.tripId,
    super.key,
  });

  final RideSession session;
  final String tripId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        if (session.trip == null || session.trip!.id != tripId) {
          return RidePageScaffold(
            session: session,
            title: 'Trip unavailable',
            subtitle: 'Start a new ride to continue',
            fallbackBackRoute: '/app/ride/book',
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(MoolSpacing.lg),
                child: RideCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.route_outlined,
                        size: 42,
                        color: MoolColors.navy,
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                      const Text(
                        'This trip is not available on this device.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: MoolSpacing.md),
                      FilledButton(
                        key: const Key('ride-empty-book'),
                        onPressed: () => context.go('/app/ride/book'),
                        child: const Text('Book a ride'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return switch (session.stage) {
          RideTripStage.captainArriving => _CaptainArriving(
            session: session,
            tripId: tripId,
          ),
          RideTripStage.liveTrip => _LiveTrip(session: session, tripId: tripId),
          RideTripStage.paymentApproval => _PaymentApproval(
            session: session,
            tripId: tripId,
          ),
          RideTripStage.receipt => _RideReceipt(
            session: session,
            tripId: tripId,
          ),
        };
      },
    );
  }
}

class _CaptainArriving extends StatelessWidget {
  const _CaptainArriving({required this.session, required this.tripId});

  final RideSession session;
  final String tripId;

  Future<void> _editPickupNote(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PickupNoteSheet(session: session),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.lg,
          MoolSpacing.sm,
          MoolSpacing.lg,
          MoolSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cancel this ride?',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            const Text(
              'Cancellation is free before pickup. No payment will be taken.',
              style: TextStyle(color: MoolColors.muted),
            ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('ride-confirm-cancel'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB42318),
                ),
                onPressed: () {
                  session.cancelRide();
                  Navigator.pop(sheetContext);
                },
                child: const Text('Cancel ride · ₹0 fee'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const Key('ride-keep-ride'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Keep my ride'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RidePageScaffold(
      session: session,
      title: session.rideCancelled ? 'Ride cancelled' : 'Arjun is arriving',
      subtitle: session.rideCancelled
          ? 'No payment taken'
          : '700 m away · about 4 min',
      activeDock: 'trip',
      fallbackBackRoute: '/app/ride/book',
      bottomAction: session.rideCancelled
          ? FilledButton(
              key: const Key('ride-book-after-cancel'),
              onPressed: () {
                session.reset();
                context.go('/app/ride/book');
              },
              child: const Text('Book another ride'),
            )
          : FilledButton.icon(
              key: const Key('ride-start-trip'),
              onPressed: session.startTrip,
              icon: const Icon(Icons.directions_car_filled_rounded),
              label: const Text('Captain picked me up'),
            ),
      body: ListView(
        key: const Key('ride-arriving-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.lg,
        ),
        children: [
          _RouteMap(
            headline: session.rideCancelled
                ? 'Matching stopped'
                : 'Captain moving to pickup',
            detail: session.rideCancelled
                ? 'Start a new ride when you are ready.'
                : 'Live location · RJ19 AB 2841',
          ),
          const SizedBox(height: MoolSpacing.md),
          const RideSectionTitle('Your captain'),
          const SizedBox(height: MoolSpacing.xs),
          RideCard(
            child: Column(
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: MoolColors.navy,
                      child: Text(
                        'AS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(width: MoolSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arjun Singh',
                            style: TextStyle(
                              color: MoolColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '4.9 ★ · 2,840 rides · verified',
                            style: TextStyle(
                              color: MoolColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'White Auto · RJ19 AB 2841',
                            style: TextStyle(
                              color: MoolColors.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.sm),
                Row(
                  children: [
                    RideQuickAction(
                      key: const Key('ride-call-captain'),
                      label: 'Call',
                      icon: Icons.call_outlined,
                      onPressed: () =>
                          session.showNotice('Calling Arjun securely…'),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    RideQuickAction(
                      key: const Key('ride-chat-captain'),
                      label: 'Chat',
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: () => context.go(
                        '/app/chat/thread/ride-$tripId?return=/app/ride/trip/$tripId',
                      ),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    RideQuickAction(
                      key: const Key('ride-share-arrival'),
                      label: 'Share',
                      icon: Icons.ios_share_rounded,
                      onPressed: () => session.showNotice(
                        'Live arrival link is ready to share.',
                      ),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    RideQuickAction(
                      key: const Key('ride-open-map'),
                      label: 'Map',
                      icon: Icons.map_outlined,
                      onPressed: () =>
                          session.showNotice('Live captain map centred.'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          const RideSectionTitle('Pickup instruction'),
          const SizedBox(height: MoolSpacing.xs),
          RideCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.pickupNote,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('ride-edit-pickup-note'),
                    onPressed: session.rideCancelled
                        ? null
                        : () => _editPickupNote(context),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit pickup instruction'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          RideCard(
            color: const Color(0xFFF0F8EF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fare locked · ${rideMoney(session.fare)}',
                  style: const TextStyle(
                    color: Color(0xFF155B17),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${session.paymentMethod.label} · pay after the ride · free cancellation before pickup',
                  style: const TextStyle(
                    color: Color(0xFF155B17),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('ride-open-safety'),
                  onPressed: session.rideCancelled
                      ? null
                      : () => _showSafetyCentre(context, session, tripId),
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('Safety centre'),
                ),
              ),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: TextButton(
                  key: const Key('ride-cancel'),
                  onPressed: session.rideCancelled
                      ? null
                      : () => _confirmCancel(context),
                  child: const Text('Cancel ride'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveTrip extends StatelessWidget {
  const _LiveTrip({required this.session, required this.tripId});

  final RideSession session;
  final String tripId;

  Future<void> _addStop(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddedStopSheet(session: session),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RidePageScaffold(
      session: session,
      title: 'Trip in progress',
      subtitle: '3.2 km · about 12 min to Railway Station',
      activeDock: 'trip',
      fallbackBackRoute: '/app/ride/book',
      bottomAction: FilledButton.icon(
        key: const Key('ride-reach-destination'),
        onPressed: session.reachDestination,
        icon: const Icon(Icons.flag_rounded),
        label: const Text('We reached the destination'),
      ),
      body: ListView(
        key: const Key('ride-live-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.lg,
        ),
        children: [
          const _RouteMap(
            headline: 'On the way to Railway Station',
            detail: 'Route monitored · ETA 12 min',
            live: true,
          ),
          const SizedBox(height: MoolSpacing.md),
          RideCard(
            child: Column(
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: MoolColors.navy,
                      child: Text(
                        'AS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(width: MoolSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arjun Singh · 4.9 ★',
                            style: TextStyle(
                              color: MoolColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'White Auto · RJ19 AB 2841',
                            style: TextStyle(
                              color: MoolColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.sm),
                Row(
                  children: [
                    RideQuickAction(
                      key: const Key('ride-live-call'),
                      label: 'Call',
                      icon: Icons.call_outlined,
                      onPressed: () =>
                          session.showNotice('Calling Arjun securely…'),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    RideQuickAction(
                      key: const Key('ride-live-chat'),
                      label: 'Chat',
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: () => context.go(
                        '/app/chat/thread/ride-$tripId?return=/app/ride/trip/$tripId',
                      ),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    RideQuickAction(
                      key: const Key('ride-live-share'),
                      label: 'Share',
                      icon: Icons.ios_share_rounded,
                      onPressed: () => session.showNotice(
                        'Live trip link is ready to share.',
                      ),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    RideQuickAction(
                      key: const Key('ride-live-safety'),
                      label: 'Safety',
                      icon: Icons.shield_outlined,
                      onPressed: () =>
                          _showSafetyCentre(context, session, tripId),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          const RideSectionTitle('Trip changes'),
          const SizedBox(height: MoolSpacing.xs),
          RideCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (session.addedStop != null) ...[
                  Text(
                    'Added stop · ${session.addedStop}',
                    style: const TextStyle(
                      color: MoolColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                ],
                Text(
                  'Current estimated fare · ${rideMoney(session.fare)}',
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('ride-add-stop'),
                    onPressed: session.addedStop == null
                        ? () => _addStop(context)
                        : null,
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: Text(
                      session.addedStop == null
                          ? 'Add a stop'
                          : 'Stop already added',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          const RideSectionTitle('Pay at trip end'),
          const SizedBox(height: MoolSpacing.xs),
          RideCard(
            child: Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: [
                for (final method in RidePaymentMethod.values)
                  MoolSegment(
                    key: Key('ride-live-payment-${method.name}'),
                    label: method.label,
                    selected: session.paymentMethod == method,
                    onPressed: () => session.choosePayment(method),
                  ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const RideCard(
            color: Color(0xFFF0F8EF),
            child: Row(
              children: [
                Icon(Icons.route_rounded, color: MoolColors.success),
                SizedBox(width: MoolSpacing.sm),
                Expanded(
                  child: Text(
                    'Route is on track. GPS and safety checks remain active until arrival.',
                    style: TextStyle(
                      color: Color(0xFF155B17),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentApproval extends StatelessWidget {
  const _PaymentApproval({required this.session, required this.tripId});

  final RideSession session;
  final String tripId;

  Future<void> _approve() async {
    await session.approvePayment();
  }

  @override
  Widget build(BuildContext context) {
    return RidePageScaffold(
      session: session,
      title: 'Review final fare',
      subtitle: 'Reached Railway Station · approve before payment',
      activeDock: 'trip',
      fallbackBackRoute: '/app/ride/trip/$tripId',
      bottomAction: FilledButton.icon(
        key: const Key('ride-approve-payment'),
        onPressed: session.busy ? null : _approve,
        icon: session.busy
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.lock_open_rounded),
        label: Text(
          session.busy
              ? 'Confirming payment…'
              : 'Approve ${rideMoney(session.fare)} with ${session.paymentMethod.label}',
        ),
      ),
      body: ListView(
        key: const Key('ride-payment-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.lg,
        ),
        children: [
          RideCard(
            color: const Color(0xFFF0F8EF),
            child: Column(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: MoolColors.success,
                  size: 34,
                ),
                const SizedBox(height: MoolSpacing.xs),
                const Text(
                  'You have arrived',
                  style: TextStyle(
                    color: Color(0xFF155B17),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  session.drop,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF155B17),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          const RideSectionTitle('Fare breakdown'),
          const SizedBox(height: MoolSpacing.xs),
          RideCard(
            child: Column(
              children: [
                _FareRow(
                  label: session.selectedPackage.name,
                  value: session.selectedPackage.fare,
                ),
                if (session.addedStop != null)
                  const _FareRow(label: 'Added stop', value: 26),
                const _FareRow(label: 'Waiting', value: 0),
                const _FareRow(label: 'Toll', value: 0),
                const Divider(),
                _FareRow(label: 'Final fare', value: session.fare, total: true),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          const RideSectionTitle('Choose payment'),
          const SizedBox(height: MoolSpacing.xs),
          RideCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: MoolSpacing.xs,
                  runSpacing: MoolSpacing.xs,
                  children: [
                    for (final method in RidePaymentMethod.values)
                      MoolSegment(
                        key: Key('ride-final-payment-${method.name}'),
                        label: method.label,
                        selected: session.paymentMethod == method,
                        onPressed: () => session.choosePayment(method),
                      ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.sm),
                Text(
                  session.paymentMethod == RidePaymentMethod.card
                      ? 'Your card has not been charged. The debit happens only after you tap Approve.'
                      : 'Confirm only after you are ready to pay.',
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('ride-report-fare'),
                  onPressed: () {
                    session.chooseIssue(RideIssueType.fare);
                    context.go('/app/ride/trip/$tripId/support');
                  },
                  child: const Text('Wrong fare'),
                ),
              ),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: OutlinedButton(
                  key: const Key('ride-report-route'),
                  onPressed: () {
                    session.chooseIssue(RideIssueType.route);
                    context.go('/app/ride/trip/$tripId/support');
                  },
                  child: const Text('Route issue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RideReceipt extends StatelessWidget {
  const _RideReceipt({required this.session, required this.tripId});

  final RideSession session;
  final String tripId;

  @override
  Widget build(BuildContext context) {
    const compliments = ['Clean ride', 'Polite', 'Safe driving', 'On time'];
    return RidePageScaffold(
      session: session,
      title: 'Ride complete',
      subtitle: 'Payment confirmed · receipt saved',
      activeDock: 'trip',
      fallbackBackRoute: '/app/ride/book',
      bottomAction: FilledButton.icon(
        key: const Key('ride-again'),
        onPressed: () {
          session.reset();
          context.go('/app/ride/book');
        },
        icon: const Icon(Icons.replay_rounded),
        label: const Text('Ride again'),
      ),
      body: ListView(
        key: const Key('ride-receipt-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.lg,
        ),
        children: [
          RideCard(
            color: const Color(0xFFF0F8EF),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: MoolColors.success,
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
                Text(
                  '${rideMoney(session.fare)} paid',
                  style: const TextStyle(
                    color: Color(0xFF155B17),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${session.paymentMethod.label} · receipt $tripId',
                  style: const TextStyle(
                    color: Color(0xFF155B17),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          RideCard(
            child: Column(
              children: [
                _TripPoint(
                  icon: Icons.my_location_rounded,
                  text: session.pickup,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 11),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 20,
                      child: VerticalDivider(
                        color: MoolColors.line,
                        thickness: 2,
                      ),
                    ),
                  ),
                ),
                _TripPoint(icon: Icons.location_on_rounded, text: session.drop),
                const Divider(height: MoolSpacing.lg),
                const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: MoolColors.navy,
                      child: Text(
                        'AS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox(width: MoolSpacing.sm),
                    Expanded(
                      child: Text(
                        'Arjun Singh · White Auto\nRJ19 AB 2841',
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          Row(
            children: [
              RideQuickAction(
                key: const Key('ride-download-receipt'),
                label: 'Download',
                icon: Icons.download_rounded,
                onPressed: () =>
                    session.showNotice('Receipt downloaded securely.'),
              ),
              const SizedBox(width: MoolSpacing.xs),
              RideQuickAction(
                key: const Key('ride-share-receipt'),
                label: 'Share',
                icon: Icons.ios_share_rounded,
                onPressed: () =>
                    session.showNotice('Receipt is ready to share.'),
              ),
              const SizedBox(width: MoolSpacing.xs),
              RideQuickAction(
                key: const Key('ride-open-support'),
                label: 'Support',
                icon: Icons.support_agent_rounded,
                onPressed: () => context.go('/app/ride/trip/$tripId/support'),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.md),
          const RideSectionTitle('Rate your captain'),
          const SizedBox(height: MoolSpacing.xs),
          RideCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var value = 1; value <= 5; value += 1)
                      IconButton(
                        key: Key('ride-rating-$value'),
                        tooltip: '$value stars',
                        onPressed: () => session.setRating(value),
                        icon: Icon(
                          value <= session.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: MoolColors.orange,
                          size: 31,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.xs),
                Wrap(
                  spacing: MoolSpacing.xs,
                  runSpacing: MoolSpacing.xs,
                  children: [
                    for (final compliment in compliments)
                      MoolSegment(
                        key: Key(
                          'ride-compliment-${compliment.toLowerCase().replaceAll(' ', '-')}',
                        ),
                        label: compliment,
                        selected: session.compliments.contains(compliment),
                        onPressed: () => session.toggleCompliment(compliment),
                      ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const Key('ride-submit-rating'),
                    onPressed: session.submitRating,
                    child: const Text('Submit rating'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupNoteSheet extends StatefulWidget {
  const _PickupNoteSheet({required this.session});

  final RideSession session;

  @override
  State<_PickupNoteSheet> createState() => _PickupNoteSheetState();
}

class _PickupNoteSheetState extends State<_PickupNoteSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.session.pickupNote,
  );
  String? _inlineError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        MoolSpacing.sm,
        MoolSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help Arjun find you',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            const Text(
              'Add a visible landmark or short pickup instruction.',
              style: TextStyle(color: MoolColors.muted),
            ),
            const SizedBox(height: MoolSpacing.md),
            TextField(
              key: const Key('ride-pickup-note-field'),
              controller: _controller,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Pickup instruction',
                errorText: _inlineError,
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('ride-save-pickup-note'),
                onPressed: () {
                  if (widget.session.updatePickupNote(_controller.text)) {
                    Navigator.pop(context);
                  } else {
                    setState(
                      () => _inlineError =
                          'Enter a visible landmark or instruction.',
                    );
                  }
                },
                child: const Text('Save instruction'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const Key('ride-cancel-pickup-note'),
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep current instruction'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddedStopSheet extends StatefulWidget {
  const _AddedStopSheet({required this.session});

  final RideSession session;

  @override
  State<_AddedStopSheet> createState() => _AddedStopSheetState();
}

class _AddedStopSheetState extends State<_AddedStopSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _reviewed = false;
  String? _inlineError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        MoolSpacing.sm,
        MoolSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _reviewed ? 'Review updated fare' : 'Add one stop',
              style: const TextStyle(
                color: MoolColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            Text(
              _reviewed
                  ? '${_controller.text.trim()} · new fare ${rideMoney(session.fare)}'
                  : 'Enter a landmark or address. You will see the fare before confirming.',
              style: const TextStyle(color: MoolColors.muted),
            ),
            const SizedBox(height: MoolSpacing.md),
            if (!_reviewed)
              TextField(
                key: const Key('ride-added-stop-field'),
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Stop address',
                  prefixIcon: const Icon(Icons.add_location_alt_outlined),
                  errorText: _inlineError,
                ),
              )
            else
              RideCard(
                color: const Color(0xFFF0F8EF),
                child: Row(
                  children: [
                    const Icon(
                      Icons.currency_rupee_rounded,
                      color: MoolColors.success,
                    ),
                    const SizedBox(width: MoolSpacing.sm),
                    Expanded(
                      child: Text(
                        'Original ${rideMoney(session.selectedPackage.fare)} · added stop ₹26 · total ${rideMoney(session.fare)}',
                        style: const TextStyle(
                          color: Color(0xFF155B17),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: Key(
                  _reviewed ? 'ride-confirm-added-stop' : 'ride-review-stop',
                ),
                onPressed: () {
                  if (_reviewed) {
                    Navigator.pop(context);
                    return;
                  }
                  if (session.reviewAddedStop(_controller.text)) {
                    setState(() {
                      _reviewed = true;
                      _inlineError = null;
                    });
                  } else {
                    setState(
                      () => _inlineError =
                          'Enter a landmark or complete address.',
                    );
                  }
                },
                child: Text(_reviewed ? 'Confirm added stop' : 'Review fare'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const Key('ride-cancel-added-stop'),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({
    required this.headline,
    required this.detail,
    this.live = false,
  });

  final String headline;
  final String detail;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE9ECFF), Color(0xFFDDF5E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(MoolRadii.card),
        border: Border.all(color: MoolColors.line),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 30,
            top: 30,
            child: Icon(
              Icons.circle_outlined,
              color: MoolColors.success,
              size: 26,
            ),
          ),
          Positioned(
            left: 50,
            top: 52,
            right: 64,
            child: Transform.rotate(
              angle: -.18,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: MoolColors.navy,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
          const Positioned(
            right: 38,
            top: 90,
            child: Icon(
              Icons.location_on_rounded,
              color: MoolColors.orange,
              size: 34,
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 18,
            child: MoolGlassSurface(
              padding: const EdgeInsets.symmetric(
                horizontal: MoolSpacing.sm,
                vertical: MoolSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(
                    live
                        ? Icons.navigation_rounded
                        : Icons.electric_rickshaw_rounded,
                    color: MoolColors.navy,
                  ),
                  const SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headline,
                          style: const TextStyle(
                            color: MoolColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          detail,
                          style: const TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FareRow extends StatelessWidget {
  const _FareRow({
    required this.label,
    required this.value,
    this.total = false,
  });

  final String label;
  final int value;
  final bool total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: total ? MoolColors.ink : MoolColors.muted,
                fontWeight: total ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            rideMoney(value),
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: total ? 20 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripPoint extends StatelessWidget {
  const _TripPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: MoolColors.navy),
        const SizedBox(width: MoolSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _showSafetyCentre(
  BuildContext context,
  RideSession session,
  String tripId,
) async {
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        MoolSpacing.sm,
        MoolSpacing.lg,
        MoolSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Safety centre',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          const Text(
            'Trip details, live route and captain identity are saved.',
            style: TextStyle(color: MoolColors.muted),
          ),
          const SizedBox(height: MoolSpacing.md),
          ListTile(
            key: const Key('ride-safety-share'),
            leading: const Icon(Icons.ios_share_rounded),
            title: const Text('Share live trip'),
            subtitle: const Text('Send your route and captain details'),
            onTap: () {
              session.showNotice('Live trip safety link is ready to share.');
              Navigator.pop(sheetContext);
            },
          ),
          ListTile(
            key: const Key('ride-safety-emergency'),
            leading: const Icon(
              Icons.emergency_outlined,
              color: Color(0xFFB42318),
            ),
            title: const Text('Call emergency help'),
            subtitle: const Text('Connect to emergency assistance now'),
            onTap: () {
              session.showNotice('Connecting to emergency assistance…');
              Navigator.pop(sheetContext);
            },
          ),
          ListTile(
            key: const Key('ride-safety-report'),
            leading: const Icon(Icons.report_outlined),
            title: const Text('Report a safety concern'),
            subtitle: const Text('Route evidence will be attached'),
            onTap: () {
              session.chooseIssue(RideIssueType.safety);
              Navigator.pop(sheetContext);
              context.go('/app/ride/trip/$tripId/support');
            },
          ),
        ],
      ),
    ),
  );
}
