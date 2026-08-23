import 'package:flutter/material.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_service_home.dart';
import '../book_models.dart';
import '../book_session.dart';
import '../widgets/book_widgets.dart';

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
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Bus',
        subtitle: 'Compare routes before booking',
        showBack: false,
        body: ColoredBox(
          color: MoolServiceHomeTokens.page,
          child: ListView(
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
                    lastDate: session.busToday.add(const Duration(days: 90)),
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
        ),
        bottomAction: MoolServicePrimaryButton(
          key: const Key('bus-search'),
          accent: _accent,
          icon: Icons.search_rounded,
          label: session.busSearching ? 'Searching…' : 'Search buses',
          onPressed: session.busSearching
              ? null
              : () async {
                  FocusScope.of(context).unfocus();
                  session.updateBusFrom(_fromController.text);
                  session.updateBusTo(_toController.text);
                  await session.searchBuses();
                },
        ),
      ),
    );
  }
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
