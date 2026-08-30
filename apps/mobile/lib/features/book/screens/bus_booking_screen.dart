import 'package:flutter/material.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_service_home.dart';
import '../../../core/design/mool_theme.dart';
import '../book_models.dart';
import '../book_session.dart';
import '../widgets/book_widgets.dart';

enum _BusBookingStep { search, review, ready }

class BusBookingScreen extends StatefulWidget {
  const BusBookingScreen({required this.session, super.key});

  final BookSession session;

  @override
  State<BusBookingScreen> createState() => _BusBookingScreenState();
}

class _BusBookingScreenState extends State<BusBookingScreen> {
  static const _accent = Color(0xFFB45309);
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  _BusBookingStep _step = _BusBookingStep.search;
  int _passengers = 1;
  String _seatPreference = 'Window';

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(text: widget.session.busFrom);
    _toController = TextEditingController(text: widget.session.busTo);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final selected = session.selectedBus;
        final step = selected == null ? _BusBookingStep.search : _step;
        void backWithinBus() {
          setState(() {
            _step = step == _BusBookingStep.ready
                ? _BusBookingStep.review
                : _BusBookingStep.search;
          });
        }

        return BookPageScaffold(
          session: session,
          title: switch (step) {
            _BusBookingStep.search => 'Bus',
            _BusBookingStep.review => 'Review bus',
            _BusBookingStep.ready => 'Request ready',
          },
          subtitle: switch (step) {
            _BusBookingStep.search => 'Compare routes before booking',
            _BusBookingStep.review => 'Passenger and seat preferences',
            _BusBookingStep.ready => 'No payment or ticket issued',
          },
          showBack: step != _BusBookingStep.search,
          onBack: step == _BusBookingStep.search ? null : backWithinBus,
          body: ColoredBox(
            color: MoolServiceHomeTokens.page,
            child: switch (step) {
              _BusBookingStep.search => ListView(
                key: const Key('bus-booking-home'),
                padding: const EdgeInsets.fromLTRB(
                  MoolServiceHomeTokens.pagePadding,
                  MoolSpacing.sm,
                  MoolServiceHomeTokens.pagePadding,
                  MoolSpacing.xl,
                ),
                children: [
                  const MoolServiceSectionHeader(
                    title: 'Where are you going?',
                    subtitle: 'Your route stays editable until checkout.',
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  MoolServiceSearchField(
                    fieldKey: const Key('bus-from'),
                    controller: _fromController,
                    hintText: 'From',
                    semanticLabel: 'Bus departure place',
                    leading: Icons.trip_origin_rounded,
                    onChanged: session.updateBusFrom,
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton.outlined(
                      key: const Key('bus-swap'),
                      tooltip: 'Swap From and To',
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      onPressed: () {
                        session.updateBusFrom(_fromController.text);
                        session.updateBusTo(_toController.text);
                        session.swapBusStops();
                        _fromController.text = session.busFrom;
                        _toController.text = session.busTo;
                      },
                      icon: const Icon(Icons.swap_vert_rounded),
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                  MoolServiceSearchField(
                    fieldKey: const Key('bus-to'),
                    controller: _toController,
                    hintText: 'To',
                    semanticLabel: 'Bus destination place',
                    leading: Icons.location_on_outlined,
                    onChanged: session.updateBusTo,
                  ),
                  const SizedBox(height: MoolServiceHomeTokens.sectionGap),
                  const MoolServiceSectionHeader(
                    title: 'Travel date',
                    subtitle: 'Choose a shortcut or open the calendar.',
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  Wrap(
                    spacing: MoolSpacing.xs,
                    runSpacing: MoolSpacing.xs,
                    children: [
                      MoolServiceChoice(
                        key: const Key('bus-date-today'),
                        label: 'Today',
                        icon: Icons.today_outlined,
                        accent: _accent,
                        selected: session.busDayOffset == 0,
                        onSelected: (_) => session.chooseBusDayOffset(0),
                      ),
                      MoolServiceChoice(
                        key: const Key('bus-date-tomorrow'),
                        label: 'Tomorrow',
                        icon: Icons.event_outlined,
                        accent: _accent,
                        selected: session.busDayOffset == 1,
                        onSelected: (_) => session.chooseBusDayOffset(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  MoolServiceCard(
                    key: const Key('bus-date'),
                    title: 'Selected date',
                    subtitle: MaterialLocalizations.of(
                      context,
                    ).formatMediumDate(session.busDate),
                    icon: Icons.calendar_month_outlined,
                    accent: _accent,
                    semanticLabel:
                        'Selected bus travel date ${MaterialLocalizations.of(context).formatMediumDate(session.busDate)}. Open calendar',
                    onTap: () async {
                      final chosen = await showDatePicker(
                        context: context,
                        initialDate: session.busDate,
                        firstDate: session.busToday,
                        lastDate: session.busToday.add(
                          const Duration(days: 90),
                        ),
                      );
                      if (chosen != null) session.chooseBusDate(chosen);
                    },
                  ),
                  AnimatedSwitcher(
                    key: const Key('bus-results-motion'),
                    duration: MoolServiceHomeTokens.accessibleDuration(context),
                    switchInCurve: MoolMotion.enter,
                    switchOutCurve: MoolMotion.change,
                    child: session.busResults.isEmpty
                        ? const SizedBox.shrink(key: Key('bus-results-empty'))
                        : _BusResults(
                            key: const Key('bus-results'),
                            session: session,
                            accent: _accent,
                          ),
                  ),
                ],
              ),
              _BusBookingStep.review => _BusReview(
                trip: selected!,
                passengers: _passengers,
                seatPreference: _seatPreference,
                accent: _accent,
                onPassengersChanged: (value) =>
                    setState(() => _passengers = value),
                onSeatPreferenceChanged: (value) =>
                    setState(() => _seatPreference = value),
              ),
              _BusBookingStep.ready => _BusRequestReady(
                trip: selected!,
                passengers: _passengers,
                seatPreference: _seatPreference,
                accent: _accent,
              ),
            },
          ),
          bottomAction: MoolServicePrimaryButton(
            key: switch (step) {
              _BusBookingStep.search when selected != null => const Key(
                'bus-review',
              ),
              _BusBookingStep.search => const Key('bus-search'),
              _BusBookingStep.review => const Key('bus-prepare-request'),
              _BusBookingStep.ready => const Key('bus-compare-another'),
            },
            accent: _accent,
            icon: switch (step) {
              _BusBookingStep.search when selected != null =>
                Icons.arrow_forward_rounded,
              _BusBookingStep.search => Icons.search_rounded,
              _BusBookingStep.review => Icons.fact_check_outlined,
              _BusBookingStep.ready => Icons.compare_arrows_rounded,
            },
            label: switch (step) {
              _BusBookingStep.search when selected != null =>
                'Review ${selected.operatorName}',
              _BusBookingStep.search =>
                session.busSearching ? 'Searching…' : 'Search buses',
              _BusBookingStep.review => 'Prepare booking request',
              _BusBookingStep.ready => 'Compare another bus',
            },
            onPressed: session.busSearching
                ? null
                : () async {
                    if (step == _BusBookingStep.search && selected != null) {
                      setState(() => _step = _BusBookingStep.review);
                      session.clearMessages();
                      return;
                    }
                    if (step == _BusBookingStep.review) {
                      setState(() => _step = _BusBookingStep.ready);
                      session.showNotice(
                        'Booking request prepared. No payment was taken and no ticket was issued.',
                      );
                      return;
                    }
                    if (step == _BusBookingStep.ready) {
                      setState(() => _step = _BusBookingStep.search);
                      session.clearMessages();
                      return;
                    }
                    FocusScope.of(context).unfocus();
                    session.updateBusFrom(_fromController.text);
                    session.updateBusTo(_toController.text);
                    await session.searchBuses();
                  },
          ),
        );
      },
    );
  }
}

class _BusReview extends StatelessWidget {
  const _BusReview({
    required this.trip,
    required this.passengers,
    required this.seatPreference,
    required this.accent,
    required this.onPassengersChanged,
    required this.onSeatPreferenceChanged,
  });

  final BusTrip trip;
  final int passengers;
  final String seatPreference;
  final Color accent;
  final ValueChanged<int> onPassengersChanged;
  final ValueChanged<String> onSeatPreferenceChanged;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('bus-review-screen'),
    padding: const EdgeInsets.fromLTRB(
      MoolServiceHomeTokens.pagePadding,
      MoolSpacing.sm,
      MoolServiceHomeTokens.pagePadding,
      MoolSpacing.xl,
    ),
    children: [
      const MoolServiceSectionHeader(
        title: 'Review your bus',
        subtitle: 'Final seat and fare remain subject to live checkout.',
      ),
      const SizedBox(height: MoolSpacing.sm),
      MoolServiceCard(
        key: const Key('bus-review-trip'),
        title: trip.operatorName,
        subtitle:
            '${trip.from} → ${trip.to} · ${trip.departure} – ${trip.arrival}',
        icon: Icons.directions_bus_filled_outlined,
        accent: accent,
        metadata: [
          MoolServiceMeta(icon: Icons.schedule_rounded, label: trip.duration),
          MoolServiceMeta(
            icon: Icons.event_seat_outlined,
            label: '${trip.availableSeats} seats shown',
          ),
          MoolServiceMeta(
            icon: Icons.currency_rupee_rounded,
            label: '₹${trip.fare} shown per passenger',
          ),
        ],
      ),
      const SizedBox(height: MoolServiceHomeTokens.sectionGap),
      const MoolServiceSectionHeader(
        title: 'Passengers',
        subtitle: 'Choose how many travellers this request should cover.',
      ),
      const SizedBox(height: MoolSpacing.sm),
      Wrap(
        spacing: MoolSpacing.xs,
        runSpacing: MoolSpacing.xs,
        children: [
          for (final count in const [1, 2, 3])
            MoolServiceChoice(
              key: Key('bus-passengers-$count'),
              label: '$count',
              icon: Icons.person_outline_rounded,
              accent: accent,
              selected: passengers == count,
              onSelected: (_) => onPassengersChanged(count),
            ),
        ],
      ),
      const SizedBox(height: MoolServiceHomeTokens.sectionGap),
      const MoolServiceSectionHeader(
        title: 'Seat preference',
        subtitle: 'A preference is not a confirmed seat.',
      ),
      const SizedBox(height: MoolSpacing.sm),
      Wrap(
        spacing: MoolSpacing.xs,
        runSpacing: MoolSpacing.xs,
        children: [
          for (final preference in const ['Window', 'Aisle', 'Any'])
            MoolServiceChoice(
              key: Key('bus-seat-${preference.toLowerCase()}'),
              label: preference,
              icon: preference == 'Any'
                  ? Icons.event_seat_outlined
                  : Icons.airline_seat_recline_normal_rounded,
              accent: accent,
              selected: seatPreference == preference,
              onSelected: (_) => onSeatPreferenceChanged(preference),
            ),
        ],
      ),
      const SizedBox(height: MoolServiceHomeTokens.sectionGap),
      MoolServiceCard(
        key: const Key('bus-live-checkout-boundary'),
        title: 'Live checkout required',
        subtitle:
            'The operator must confirm the seat, final fare and boarding details before payment. Preparing this request will not charge you or issue a ticket.',
        icon: Icons.verified_user_outlined,
        accent: accent,
      ),
    ],
  );
}

class _BusRequestReady extends StatelessWidget {
  const _BusRequestReady({
    required this.trip,
    required this.passengers,
    required this.seatPreference,
    required this.accent,
  });

  final BusTrip trip;
  final int passengers;
  final String seatPreference;
  final Color accent;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('bus-request-ready-screen'),
    padding: const EdgeInsets.fromLTRB(
      MoolServiceHomeTokens.pagePadding,
      MoolSpacing.sm,
      MoolServiceHomeTokens.pagePadding,
      MoolSpacing.xl,
    ),
    children: [
      MoolServiceCard(
        key: const Key('bus-request-ready'),
        title: 'Booking request ready',
        subtitle:
            '${trip.operatorName} · ${trip.from} → ${trip.to} · $passengers ${passengers == 1 ? 'passenger' : 'passengers'} · $seatPreference preference',
        icon: Icons.fact_check_outlined,
        accent: MoolColors.success,
        emphasized: true,
      ),
      const SizedBox(height: MoolServiceHomeTokens.sectionGap),
      MoolServiceCard(
        key: const Key('bus-request-boundary'),
        title: 'No payment or ticket yet',
        subtitle:
            'Live checkout is unavailable in this UI review. Your route and preferences are retained so you can continue when seat, fare and payment services are available.',
        icon: Icons.info_outline_rounded,
        accent: accent,
        metadata: const [
          MoolServiceMeta(
            icon: Icons.event_seat_outlined,
            label: 'Seat not confirmed',
          ),
          MoolServiceMeta(icon: Icons.payments_outlined, label: '₹0 charged'),
          MoolServiceMeta(
            icon: Icons.confirmation_number_outlined,
            label: 'Ticket not issued',
          ),
        ],
      ),
    ],
  );
}

class _BusResults extends StatelessWidget {
  const _BusResults({required this.session, required this.accent, super.key});

  final BookSession session;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: MoolServiceHomeTokens.sectionGap),
        const MoolServiceSectionHeader(
          title: 'Available for review',
          subtitle: 'Final seats and fares are confirmed only at checkout.',
        ),
        const SizedBox(height: MoolSpacing.sm),
        for (var index = 0; index < session.busResults.length; index++) ...[
          _BusTripCard(
            trip: session.busResults[index],
            selected: session.selectedBusId == session.busResults[index].id,
            accent: accent,
            onTap: () => session.selectBus(session.busResults[index].id),
          ),
          if (index != session.busResults.length - 1)
            const SizedBox(height: MoolServiceHomeTokens.cardGap),
        ],
      ],
    );
  }
}

class _BusTripCard extends StatelessWidget {
  const _BusTripCard({
    required this.trip,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final BusTrip trip;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MoolServiceCard(
      key: Key('bus-trip-${trip.id}'),
      title: trip.operatorName,
      subtitle:
          '${trip.from} → ${trip.to} · ${trip.departure} – ${trip.arrival}',
      icon: Icons.directions_bus_filled_outlined,
      accent: accent,
      emphasized: selected,
      metadata: [
        MoolServiceMeta(icon: Icons.schedule_rounded, label: trip.duration),
        MoolServiceMeta(
          icon: Icons.event_seat_outlined,
          label: '${trip.availableSeats} seats shown',
        ),
        MoolServiceMeta(
          icon: Icons.star_outline_rounded,
          label: '${trip.rating.toStringAsFixed(1)} rating',
        ),
        MoolServiceMeta(
          icon: Icons.currency_rupee_rounded,
          label: '₹${trip.fare}',
        ),
        MoolServiceMeta(
          icon: selected
              ? Icons.check_circle_rounded
              : Icons.touch_app_outlined,
          label: selected ? 'Selected for review' : 'Select for review',
        ),
      ],
      semanticLabel:
          '${trip.operatorName}, ${trip.from} to ${trip.to}, departs ${trip.departure}, arrives ${trip.arrival}, ${trip.duration}, ${trip.availableSeats} seats shown, ${trip.rating.toStringAsFixed(1)} rating, ₹${trip.fare}. ${selected ? 'Selected for review' : 'Select for review'}. Final availability is confirmed only at checkout',
      onTap: onTap,
    );
  }
}
