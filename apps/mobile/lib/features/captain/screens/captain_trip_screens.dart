import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../captain_models.dart';
import '../captain_session.dart';
import '../widgets/captain_widgets.dart';

class CaptainPickupScreen extends StatelessWidget {
  const CaptainPickupScreen({required this.session, super.key});

  final CaptainSession session;

  @override
  Widget build(BuildContext context) {
    final ride = reviewCaptainRide;
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => CaptainPageScaffold(
        session: session,
        title: 'Reach Pickup',
        subtitle: '${ride.id} · 1.2 km away',
        activeDock: 'trips',
        returnRoute: '/app/captain',
        trailing: IconButton.outlined(
          key: const Key('captain-pickup-support'),
          tooltip: 'Open pickup support',
          onPressed: () => context.go('/app/captain/support-work?case=pickup'),
          icon: const Icon(Icons.support_agent_rounded),
        ),
        bottomAction: FilledButton(
          key: const Key('captain-pickup-arrived'),
          onPressed: () {
            session.markPickupArrival();
            if (session.captainArrivedAtPickup) _otpSheet(context);
          },
          child: Text(
            session.captainArrivedAtPickup
                ? 'Enter Rider OTP'
                : 'I Have Arrived',
          ),
        ),
        body: ListView(
          key: const Key('captain-pickup-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const CaptainRouteMap(
              label: '4 min · turn left after 300 m',
              start: 'YOU',
              end: 'PICK',
              height: 285,
            ),
            const SizedBox(height: MoolSpacing.sm),
            CaptainCard(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 23,
                    backgroundColor: MoolColors.success,
                    foregroundColor: Colors.white,
                    child: Text(
                      'AK',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ride.rider} · ${ride.rating}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          ride.pickupDetail,
                          style: const TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.outlined(
                    key: const Key('captain-pickup-call'),
                    tooltip: 'Masked call',
                    onPressed: () => _callSheet(context),
                    icon: const Icon(Icons.call_outlined, size: 19),
                  ),
                  const SizedBox(width: MoolSpacing.xxs),
                  IconButton.outlined(
                    key: const Key('captain-pickup-chat'),
                    tooltip: 'Trip chat',
                    onPressed: () => context.go(
                      '/app/chat/thread/order-support?return=/app/captain/trips/${ride.id}/pickup',
                    ),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 19,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            const CaptainCard(
              color: Color(0xFFFFF6E8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFFB05C00)),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start only with the rider OTP',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Meet at the pickup point. Do not ask the rider to cancel or start early.',
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
            const SizedBox(height: MoolSpacing.sm),
            const Row(
              children: [
                Expanded(
                  child: CaptainMetric(
                    label: 'PICKUP ETA',
                    value: '4 min',
                    detail: 'live route',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: CaptainMetric(
                    label: 'WAIT FREE',
                    value: '3 min',
                    detail: 'after arrival',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: CaptainMetric(
                    label: 'TRIP NET',
                    value: '₹238',
                    detail: 'estimated',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _callSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('captain-masked-call-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masked call',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const Text(
              'The call connects without sharing either personal number.',
            ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('captain-masked-call-connect'),
                onPressed: () {
                  session.showNotice('Masked rider call started.');
                  Navigator.pop(sheetContext);
                },
                icon: const Icon(Icons.call_rounded),
                label: const Text('Call Rider'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const Key('captain-masked-call-cancel'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _otpSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.md,
          ),
          child: SingleChildScrollView(
            child: Column(
              key: const Key('captain-otp-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Start trip',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const Text('Ask the rider for the 4-digit trip OTP.'),
                const SizedBox(height: MoolSpacing.md),
                TextFormField(
                  key: const Key('captain-trip-otp'),
                  initialValue: session.pickupOtp,
                  autofocus: true,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Rider OTP',
                    counterText: '',
                  ),
                  onChanged: session.setPickupOtp,
                ),
                const SizedBox(height: MoolSpacing.xs),
                Text(
                  session.errorMessage ??
                      (session.pickupOtp.length == 4
                          ? 'OTP entered. Tap Verify OTP & Start.'
                          : 'Pickup location and all 4 digits must match.'),
                  key: const Key('captain-otp-status'),
                  style: TextStyle(
                    color: session.errorMessage == null
                        ? MoolColors.muted
                        : const Color(0xFFC62828),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('captain-trip-start'),
                    onPressed: session.busy
                        ? null
                        : () async {
                            final ok = await session.startTrip();
                            if (ok && sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                              context.go(
                                '/app/captain/trips/${reviewCaptainRide.id}',
                              );
                            }
                          },
                    child: const Text('Verify OTP & Start'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('captain-otp-cancel'),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class CaptainLiveTripScreen extends StatelessWidget {
  const CaptainLiveTripScreen({required this.session, super.key});

  final CaptainSession session;

  @override
  Widget build(BuildContext context) {
    final ride = reviewCaptainRide;
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => CaptainPageScaffold(
        session: session,
        title: 'Jodhpur Airport',
        subtitle: '${ride.id} · rider ${ride.rider}',
        activeDock: 'trips',
        returnRoute: '/app/captain',
        showBack: false,
        trailing: IconButton.outlined(
          key: const Key('captain-trip-more'),
          tooltip: 'Trip options',
          onPressed: () => _tripSheet(context, 'options'),
          icon: const Icon(Icons.more_horiz_rounded),
        ),
        bottomAction: FilledButton(
          key: const Key('captain-arrive-destination'),
          onPressed: session.busy
              ? null
              : () async {
                  final ok = await session.confirmDestinationArrival();
                  if (ok && context.mounted) {
                    context.go('/app/captain/trips/${ride.id}/complete');
                  }
                },
          child: const Text('Arrived at Destination'),
        ),
        body: ListView(
          key: const Key('captain-live-trip-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const CaptainRouteMap(
              label: '7.4 km · about 18 min',
              start: 'LIVE',
              end: 'DROP',
              height: 300,
            ),
            const SizedBox(height: MoolSpacing.sm),
            const CaptainCard(
              color: Color(0xFFEAF7E8),
              child: Row(
                children: [
                  Icon(Icons.turn_slight_right_rounded),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Continue straight for 2.3 km',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Airport Road · normal traffic',
                          style: TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CaptainPill(label: '18 MIN'),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            const Row(
              children: [
                Expanded(
                  child: CaptainMetric(
                    label: 'TRIP TIME',
                    value: '10:42',
                    detail: 'minutes',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: CaptainMetric(
                    label: 'DISTANCE',
                    value: '4.4 km',
                    detail: 'covered',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: CaptainMetric(
                    label: 'FARE',
                    value: '₹278',
                    detail: 'current',
                  ),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('captain-trip-sos'),
                    onPressed: () => _tripSheet(context, 'sos'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFC62828),
                    ),
                    icon: const Icon(Icons.sos_rounded),
                    label: const Text('SOS'),
                  ),
                ),
                const SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('captain-trip-issue'),
                    onPressed: () => _tripSheet(context, 'issue'),
                    icon: const Icon(Icons.report_problem_outlined),
                    label: const Text('Issue'),
                  ),
                ),
                const SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('captain-trip-contact'),
                    onPressed: () => context.go(
                      '/app/chat/thread/order-support?return=/app/captain/trips/${ride.id}',
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Rider'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _tripSheet(BuildContext context, String option) {
    session.selectTripOption(option);
    final title = switch (option) {
      'sos' => 'Emergency support',
      'issue' => 'Report trip issue',
      _ => 'Trip options',
    };
    final detail = switch (option) {
      'sos' => 'Contact emergency assistance and share this live trip.',
      'issue' => 'Get help for safety, route, rider or vehicle issues.',
      _ => 'Every option remains attached to trip ${reviewCaptainRide.id}.',
    };
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.md),
          child: Column(
            key: const Key('captain-trip-option-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(detail),
              const SizedBox(height: MoolSpacing.md),
              const CaptainCard(
                color: Color(0xFFF4F3FF),
                child: Column(
                  children: [
                    _TripFact(label: 'Route sharing', value: 'Active'),
                    _TripFact(label: 'Location updated', value: '5 sec ago'),
                    _TripFact(label: 'Rider contact', value: 'Masked'),
                    _TripFact(label: 'Support', value: '24×7'),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('captain-trip-open-support'),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.go(
                      '/app/captain/support-work?case=$option&trip=${reviewCaptainRide.id}',
                    );
                  },
                  child: Text(
                    option == 'options'
                        ? 'Open Support'
                        : 'Continue to Support',
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: const Key('captain-trip-option-close'),
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
}

class CaptainFareCompletionScreen extends StatelessWidget {
  const CaptainFareCompletionScreen({required this.session, super.key});

  final CaptainSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => CaptainPageScaffold(
        session: session,
        title: 'Complete Trip',
        subtitle: '${reviewCaptainRide.id} · Jodhpur Airport',
        activeDock: 'trips',
        returnRoute: '/app/captain',
        trailing: IconButton.outlined(
          key: const Key('captain-payment-help'),
          tooltip: 'Payment support',
          onPressed: () => context.go('/app/captain/support-work?case=payment'),
          icon: const Icon(Icons.help_outline_rounded),
        ),
        bottomAction: FilledButton(
          key: const Key('captain-check-payment'),
          onPressed: session.busy
              ? null
              : () async {
                  final ok = await session.checkPayment();
                  if (ok &&
                      session.paymentReceiptId != null &&
                      context.mounted) {
                    _paymentSheet(context);
                  }
                },
          child: Text(
            session.paymentReceiptId == null
                ? 'Check Payment'
                : 'Payment Confirmed',
          ),
        ),
        body: ListView(
          key: const Key('captain-completion-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            const CaptainCard(
              color: Color(0xFFEAF7E8),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: MoolColors.success,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.check_rounded, size: 30),
                  ),
                  SizedBox(height: MoolSpacing.sm),
                  Text(
                    'Trip completed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '12.1 km · 29 min · arrival verified',
                    style: TextStyle(color: MoolColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            const CaptainCard(
              child: Column(
                children: [
                  _FareLine(label: 'Base and distance fare', value: '₹258'),
                  _FareLine(label: 'Wait time', value: '₹20'),
                  _FareLine(label: 'Toll / parking', value: '₹0'),
                  Divider(),
                  _FareLine(label: 'Customer pays', value: '₹278', total: true),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            CaptainCard(
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFEAF7E8),
                    foregroundColor: MoolColors.success,
                    child: Text(
                      'UPI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.sm),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer payment',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'App confirmation is required',
                          style: TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CaptainPill(
                    label: session.paymentReceiptId == null
                        ? 'PENDING'
                        : 'PAID',
                    color: session.paymentReceiptId == null
                        ? const Color(0xFFB05C00)
                        : MoolColors.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            const Row(
              children: [
                Expanded(
                  child: CaptainMetric(
                    label: 'GROSS FARE',
                    value: '₹278',
                    detail: 'customer fare',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: CaptainMetric(
                    label: 'PLATFORM',
                    value: '−₹28',
                    detail: 'charge',
                  ),
                ),
                SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: CaptainMetric(
                    label: 'YOUR EARNING',
                    value: '₹250',
                    detail: 'after payment',
                  ),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.sm),
            const CaptainCard(
              color: Color(0xFFFFF6E8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.account_balance_outlined,
                    color: Color(0xFFB05C00),
                  ),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wait for in-app payment',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Do not accept a screenshot as payment. The payment record confirms the result.',
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

  Future<void> _paymentSheet(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.md),
            child: Column(
              key: const Key('captain-payment-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment confirmed',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const Text('₹278 received through UPI for trip MS-R4821.'),
                const SizedBox(height: MoolSpacing.md),
                const CaptainCard(
                  color: Color(0xFFF4F3FF),
                  child: Column(
                    children: [
                      _TripFact(label: 'Your earning', value: '₹250'),
                      _TripFact(label: 'Payout', value: 'Available'),
                      _TripFact(label: 'Receipt', value: 'Sent to rider'),
                      _TripFact(label: 'Trip', value: 'Closed'),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('captain-payment-view-earnings'),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      context.go('/app/captain/earnings');
                    },
                    child: const Text('View Earnings'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('captain-payment-close'),
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

class _TripFact extends StatelessWidget {
  const _TripFact({required this.label, required this.value});

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

class _FareLine extends StatelessWidget {
  const _FareLine({
    required this.label,
    required this.value,
    this.total = false,
  });

  final String label;
  final String value;
  final bool total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xs),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: total ? MoolColors.navy : MoolColors.muted,
              fontWeight: total ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: MoolColors.ink,
            fontSize: total ? 16 : 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}
