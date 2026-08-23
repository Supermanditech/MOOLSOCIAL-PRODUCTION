import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_service_home.dart';
import '../../../core/design/mool_theme.dart';
import '../ride_models.dart';
import '../ride_session.dart';
import '../widgets/ride_widgets.dart';

const _rideAccent = Color(0xFF175CD3);

const _ridePlaces = <_RidePlace>[
  _RidePlace(
    id: 'railway-station',
    title: 'Railway Station',
    destination: 'Railway Station main gate',
    detail: 'Main gate · Jodhpur',
    icon: Icons.history_rounded,
  ),
  _RidePlace(
    id: 'aiims-jodhpur',
    title: 'AIIMS Jodhpur',
    destination: 'AIIMS Jodhpur main entrance',
    detail: 'Basni Industrial Area',
    icon: Icons.history_rounded,
  ),
  _RidePlace(
    id: 'home',
    title: 'Home',
    destination: 'Sardarpura, Jodhpur',
    detail: 'Saved place',
    icon: Icons.home_outlined,
  ),
];

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
      session.prepareBooking(widget.initialType!, notifyChange: false);
    } else {
      session.clearMessages(notifyChange: false);
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
        title: 'Ride',
        subtitle: 'Choose destination, vehicle and fare',
        fallbackBackRoute: '/app/ride',
        showBack: false,
        activeLocalAction: session.selectedType.name,
        bottomAction: FilledButton.icon(
          key: const Key('ride-book'),
          style: FilledButton.styleFrom(
            backgroundColor: _rideAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(
              44,
              MoolServiceHomeTokens.primaryActionHeight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MoolRadii.card),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: MoolServiceHomeTokens.bodySize,
              fontWeight: FontWeight.w900,
            ),
          ),
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
        body: ColoredBox(
          color: MoolServiceHomeTokens.page,
          child: ListView(
            key: const Key('ride-booking-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolServiceHomeTokens.pagePadding,
              MoolSpacing.xs,
              MoolServiceHomeTokens.pagePadding,
              MoolSpacing.lg,
            ),
            children: [
              MoolServiceCard(
                key: const Key('ride-current-pickup'),
                title: 'Current pickup',
                subtitle: session.pickup,
                icon: Icons.my_location_rounded,
                accent: MoolColors.success,
                trailing: TextButton(
                  key: const Key('ride-edit-route'),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    foregroundColor: _rideAccent,
                  ),
                  onPressed: _editRoute,
                  child: const Text('Change'),
                ),
              ),
              const SizedBox(height: MoolServiceHomeTokens.sectionGap),
              const MoolServiceSectionHeader(
                title: 'Where to?',
                subtitle: 'Search or choose a recent place',
              ),
              const SizedBox(height: MoolSpacing.sm),
              MoolServiceSearchField(
                key: const Key('ride-destination-search-surface'),
                fieldKey: const Key('ride-destination-search'),
                hintText: session.drop,
                semanticLabel: 'Search destination. Selected ${session.drop}',
                readOnly: true,
                onTap: _editRoute,
                leading: Icons.search_rounded,
                trailing: const Icon(Icons.arrow_forward_rounded, size: 20),
              ),
              const SizedBox(height: MoolSpacing.sm),
              for (final place in _ridePlaces) ...[
                _PlaceRow(
                  place: place,
                  selected: session.drop == place.destination,
                  onTap: () => session.updateRoute(
                    pickupValue: session.pickup,
                    dropValue: place.destination,
                  ),
                ),
                if (place != _ridePlaces.last)
                  const SizedBox(height: MoolSpacing.xs),
              ],
              const SizedBox(height: MoolServiceHomeTokens.sectionGap),
              const MoolServiceSectionHeader(
                title: 'Pickup time',
                subtitle: 'Free cancellation before captain matching',
              ),
              const SizedBox(height: MoolSpacing.sm),
              Wrap(
                spacing: MoolSpacing.xs,
                runSpacing: MoolSpacing.xs,
                children: [
                  MoolServiceChoice(
                    key: const Key('ride-time-now'),
                    label: 'Now',
                    icon: Icons.bolt_rounded,
                    accent: _rideAccent,
                    selected: session.rideTime == RideTime.now,
                    onSelected: (_) => session.chooseRideTime(RideTime.now),
                  ),
                  MoolServiceChoice(
                    key: const Key('ride-time-15'),
                    label: 'After 15 min',
                    icon: Icons.timer_outlined,
                    accent: _rideAccent,
                    selected: session.rideTime == RideTime.after15Minutes,
                    onSelected: (_) =>
                        session.chooseRideTime(RideTime.after15Minutes),
                  ),
                  MoolServiceChoice(
                    key: const Key('ride-time-schedule'),
                    label: session.rideTime == RideTime.scheduled
                        ? session.rideTimeLabel
                        : 'Schedule',
                    icon: Icons.calendar_month_outlined,
                    accent: _rideAccent,
                    selected: session.rideTime == RideTime.scheduled,
                    onSelected: (_) {
                      session.chooseRideTime(RideTime.scheduled);
                      _scheduleRide();
                    },
                  ),
                ],
              ),
              const SizedBox(height: MoolServiceHomeTokens.sectionGap),
              const MoolServiceSectionHeader(
                title: 'Choose a ride',
                subtitle: 'Fare and pickup time shown before booking',
              ),
              const SizedBox(height: MoolSpacing.sm),
              Wrap(
                spacing: MoolSpacing.xs,
                runSpacing: MoolSpacing.xs,
                children: [
                  for (final type in RideType.values)
                    MoolServiceChoice(
                      key: Key('ride-type-${type.name}'),
                      label: type.label,
                      icon: switch (type) {
                        RideType.bike => Icons.two_wheeler_rounded,
                        RideType.auto => Icons.electric_rickshaw_rounded,
                        RideType.cab => Icons.local_taxi_rounded,
                      },
                      accent: _rideAccent,
                      selected: session.selectedType == type,
                      onSelected: (_) => session.chooseType(type),
                    ),
                ],
              ),
              const SizedBox(height: MoolSpacing.sm),
              for (final package in session.visiblePackages) ...[
                _PackageCard(
                  package: package,
                  selected: package.id == session.selectedPackageId,
                  onTap: () => session.choosePackage(package.id),
                ),
                if (package != session.visiblePackages.last)
                  const SizedBox(height: MoolSpacing.xs),
              ],
              const SizedBox(height: MoolServiceHomeTokens.sectionGap),
              const MoolServiceSectionHeader(
                title: 'Payment',
                subtitle: 'Nothing is charged before your ride',
              ),
              const SizedBox(height: MoolSpacing.sm),
              RideCard(
                key: const Key('ride-payment-summary'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: MoolSpacing.xs,
                      runSpacing: MoolSpacing.xs,
                      children: [
                        for (final method in RidePaymentMethod.values)
                          MoolServiceChoice(
                            key: Key('ride-payment-${method.name}'),
                            label: method.label,
                            accent: _rideAccent,
                            selected: session.paymentMethod == method,
                            onSelected: (_) => session.choosePayment(method),
                          ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Text(
                      session.paymentMethod == RidePaymentMethod.card
                          ? 'Approve the final card fare after you reach your destination.'
                          : 'Pay only after you reach your destination.',
                      style: const TextStyle(
                        color: MoolServiceHomeTokens.muted,
                        fontSize: MoolServiceHomeTokens.metadataSize,
                        height: 1.35,
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
      ),
    );
  }
}

class _RidePlace {
  const _RidePlace({
    required this.id,
    required this.title,
    required this.destination,
    required this.detail,
    required this.icon,
  });

  final String id;
  final String title;
  final String destination;
  final String detail;
  final IconData icon;
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.place,
    required this.selected,
    required this.onTap,
  });

  final _RidePlace place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MoolServiceCard(
      key: Key('ride-place-${place.id}'),
      title: place.title,
      subtitle: place.detail,
      icon: place.icon,
      accent: _rideAccent,
      emphasized: selected,
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: _rideAccent, size: 22)
          : null,
      semanticLabel:
          '${place.title}. ${place.detail}.${selected ? ' Selected destination.' : ''}',
      onTap: onTap,
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
    return MoolServiceCard(
      key: Key('ride-package-${package.id}'),
      title: package.name,
      subtitle: '${package.capacity} · ${package.note}',
      icon: switch (package.type) {
        RideType.bike => Icons.two_wheeler_rounded,
        RideType.auto => Icons.electric_rickshaw_rounded,
        RideType.cab => Icons.local_taxi_rounded,
      },
      accent: _rideAccent,
      emphasized: selected,
      metadata: [
        MoolServiceMeta(
          icon: Icons.schedule_rounded,
          label: '${package.arrivalMinutes} min',
        ),
        MoolServiceMeta(
          icon: Icons.near_me_outlined,
          label: '${package.nearbyCaptains} nearby',
        ),
      ],
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            rideMoney(package.fare),
            style: const TextStyle(
              color: MoolServiceHomeTokens.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (selected)
            const Icon(
              Icons.check_circle_rounded,
              color: _rideAccent,
              size: 20,
            ),
        ],
      ),
      semanticLabel:
          '${package.type.label} ${package.name}. ${rideMoney(package.fare)}. '
          'Arrives in ${package.arrivalMinutes} minutes. ${package.capacity}. '
          '${package.note}. ${package.nearbyCaptains} captains nearby.'
          '${selected ? ' Selected.' : ''}',
      onTap: onTap,
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();

  @override
  Widget build(BuildContext context) {
    return const MoolServiceCard(
      title: 'Know before you book',
      subtitle:
          'Verified captain · fare shown first · free cancellation before matching',
      icon: Icons.verified_user_outlined,
      accent: MoolColors.success,
    );
  }
}
