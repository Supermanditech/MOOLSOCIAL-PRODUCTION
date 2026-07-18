import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../ride_models.dart';
import '../ride_session.dart';
import '../widgets/ride_widgets.dart';

class RideBookingScreen extends StatefulWidget {
  const RideBookingScreen({required this.session, this.initialType, super.key});

  final RideSession session;
  final RideType? initialType;

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  late final TextEditingController _pickupController;
  late final TextEditingController _dropController;

  RideSession get session => widget.session;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null && session.trip == null) {
      session.prepareBooking(widget.initialType!);
    } else {
      session.clearMessages();
    }
    _pickupController = TextEditingController(text: session.pickup);
    _dropController = TextEditingController(text: session.drop);
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  Future<void> _editRoute() async {
    _pickupController.text = session.pickup;
    _dropController.text = session.drop;
    String? inlineError;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.lg,
            MoolSpacing.sm,
            MoolSpacing.lg,
            MediaQuery.viewInsetsOf(sheetContext).bottom + MoolSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Where are you going?',
                style: TextStyle(
                  color: MoolColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.xs),
              const Text(
                'Add a clear pickup point and destination.',
                style: TextStyle(color: MoolColors.muted),
              ),
              const SizedBox(height: MoolSpacing.md),
              TextField(
                key: const Key('ride-pickup-field'),
                controller: _pickupController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Pickup',
                  prefixIcon: const Icon(Icons.my_location_rounded),
                  errorText: inlineError,
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              TextField(
                key: const Key('ride-drop-field'),
                controller: _dropController,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('ride-save-route'),
                  onPressed: () {
                    if (session.updateRoute(
                      pickupValue: _pickupController.text,
                      dropValue: _dropController.text,
                    )) {
                      Navigator.pop(sheetContext);
                    } else {
                      setSheetState(() => inlineError = session.errorMessage);
                    }
                  },
                  child: const Text('Use this route'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: const Key('ride-cancel-route'),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Keep current route'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scheduleRide() async {
    var date = session.scheduledDate;
    var time = session.scheduledTime ?? '';
    String? inlineError;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
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
                'Schedule pickup',
                style: TextStyle(
                  color: MoolColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.xs),
              const Text(
                'Choose a day and pickup time. You can cancel before matching.',
                style: TextStyle(color: MoolColors.muted),
              ),
              const SizedBox(height: MoolSpacing.md),
              OutlinedButton.icon(
                key: const Key('ride-schedule-tomorrow'),
                onPressed: () => setSheetState(
                  () => date = DateTime.now().add(const Duration(days: 1)),
                ),
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  date == null
                      ? 'Choose tomorrow'
                      : '${date!.day}/${date!.month}/${date!.year}',
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              Wrap(
                spacing: MoolSpacing.xs,
                runSpacing: MoolSpacing.xs,
                children: [
                  for (final value in const ['9:00 AM', '2:00 PM', '7:30 PM'])
                    MoolSegment(
                      key: Key('ride-schedule-${value.replaceAll(' ', '-')}'),
                      label: value,
                      selected: time == value,
                      onPressed: () => setSheetState(() => time = value),
                    ),
                ],
              ),
              if (inlineError != null) ...[
                const SizedBox(height: MoolSpacing.sm),
                Text(
                  inlineError!,
                  key: const Key('ride-schedule-error'),
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: MoolSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('ride-confirm-schedule'),
                  onPressed: () {
                    if (session.confirmSchedule(date, time)) {
                      Navigator.pop(sheetContext);
                    } else {
                      setSheetState(
                        () =>
                            inlineError = 'Choose both a pickup date and time.',
                      );
                    }
                  },
                  child: const Text('Confirm pickup time'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: const Key('ride-cancel-schedule'),
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

  Future<void> _book() async {
    final booked = await session.bookRide();
    if (!mounted || !booked || session.trip == null) return;
    context.go('/app/ride/trip/${session.trip!.id}');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => RidePageScaffold(
        session: session,
        title: 'Book your ride',
        subtitle: 'Fare first · captain next · pay after the trip',
        fallbackBackRoute: '/app/ride',
        bottomAction: FilledButton.icon(
          key: const Key('ride-book'),
          onPressed: session.busy ? null : _book,
          icon: session.busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.arrow_forward_rounded),
          label: Text(
            session.busy
                ? 'Finding a captain…'
                : 'Book ${session.selectedPackage.name} · ${rideMoney(session.fare)}',
          ),
        ),
        body: ListView(
          key: const Key('ride-booking-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.lg,
          ),
          children: [
            _RouteCard(session: session, onEdit: _editRoute),
            const SizedBox(height: MoolSpacing.md),
            const RideSectionTitle(
              'Pickup time',
              detail: 'Cancel free before pickup',
            ),
            const SizedBox(height: MoolSpacing.xs),
            Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: [
                MoolSegment(
                  key: const Key('ride-time-now'),
                  label: 'Now',
                  icon: Icons.bolt_rounded,
                  selected: session.rideTime == RideTime.now,
                  onPressed: () => session.chooseRideTime(RideTime.now),
                ),
                MoolSegment(
                  key: const Key('ride-time-15'),
                  label: 'After 15 min',
                  icon: Icons.timer_outlined,
                  selected: session.rideTime == RideTime.after15Minutes,
                  onPressed: () =>
                      session.chooseRideTime(RideTime.after15Minutes),
                ),
                MoolSegment(
                  key: const Key('ride-time-schedule'),
                  label: session.rideTime == RideTime.scheduled
                      ? session.rideTimeLabel
                      : 'Schedule',
                  icon: Icons.calendar_month_outlined,
                  selected: session.rideTime == RideTime.scheduled,
                  onPressed: () {
                    session.chooseRideTime(RideTime.scheduled);
                    _scheduleRide();
                  },
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.md),
            const RideSectionTitle('Choose a ride'),
            const SizedBox(height: MoolSpacing.xs),
            Row(
              children: [
                for (final type in RideType.values) ...[
                  Expanded(
                    child: MoolSegment(
                      key: Key('ride-type-${type.name}'),
                      label: type.label,
                      icon: switch (type) {
                        RideType.bike => Icons.two_wheeler_rounded,
                        RideType.auto => Icons.electric_rickshaw_rounded,
                        RideType.cab => Icons.local_taxi_rounded,
                      },
                      selected: session.selectedType == type,
                      onPressed: () => session.chooseType(type),
                    ),
                  ),
                  if (type != RideType.cab)
                    const SizedBox(width: MoolSpacing.xs),
                ],
              ],
            ),
            const SizedBox(height: MoolSpacing.sm),
            for (final package in session.visiblePackages) ...[
              _PackageCard(
                package: package,
                selected: package.id == session.selectedPackageId,
                onTap: () => session.choosePackage(package.id),
              ),
              const SizedBox(height: MoolSpacing.xs),
            ],
            const SizedBox(height: MoolSpacing.sm),
            const RideSectionTitle('Pay after your ride'),
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
                          key: Key('ride-payment-${method.name}'),
                          label: method.label,
                          selected: session.paymentMethod == method,
                          onPressed: () => session.choosePayment(method),
                        ),
                    ],
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  Text(
                    session.paymentMethod == RidePaymentMethod.card
                        ? 'Your card is not charged now. Approve the final fare after arrival.'
                        : 'Pay only after you reach your destination.',
                    style: const TextStyle(
                      color: MoolColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            const _TrustStrip(),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.session, required this.onEdit});

  final RideSession session;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return RideCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.my_location_rounded, color: MoolColors.success),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pickup',
                      style: TextStyle(
                        color: MoolColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      session.pickup,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 11),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 22,
                child: VerticalDivider(color: MoolColors.line, thickness: 2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: MoolColors.orange),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Destination',
                      style: TextStyle(
                        color: MoolColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      session.drop,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('ride-edit-route'),
              onPressed: onEdit,
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: const Text('Edit route'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.selected,
    required this.onTap,
  });

  final RidePackage package;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RideCard(
      key: Key('ride-package-${package.id}'),
      onTap: onTap,
      color: selected ? const Color(0xFFEDEEFF) : Colors.white,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: selected ? MoolColors.navy : const Color(0xFFF0F1F8),
              borderRadius: BorderRadius.circular(MoolRadii.control),
            ),
            child: Icon(switch (package.type) {
              RideType.bike => Icons.two_wheeler_rounded,
              RideType.auto => Icons.electric_rickshaw_rounded,
              RideType.cab => Icons.local_taxi_rounded,
            }, color: selected ? Colors.white : MoolColors.navy),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.name,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${package.arrivalMinutes} min · ${package.capacity} · ${package.note}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${package.nearbyCaptains} captains nearby',
                  style: const TextStyle(
                    color: MoolColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MoolSpacing.xs),
          Text(
            rideMoney(package.fare),
            style: const TextStyle(
              color: MoolColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return const RideCard(
      color: Color(0xFFF0F8EF),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, color: MoolColors.success),
          SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Text(
              'Verified captain · fare shown before booking · free cancellation before pickup',
              style: TextStyle(
                color: Color(0xFF155B17),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
