import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_service_home.dart';
import '../book_models.dart';
import '../book_session.dart';
import '../widgets/book_widgets.dart';

class SalonBookingScreen extends StatefulWidget {
  const SalonBookingScreen({required this.session, super.key});

  final BookSession session;

  @override
  State<SalonBookingScreen> createState() => _SalonBookingScreenState();
}

class _SalonBookingScreenState extends State<SalonBookingScreen> {
  static const _accent = Color(0xFF6D28D9);
  static const _services = [
    'Haircut',
    'Beard',
    'Facial',
    'Colour',
    'Massage',
    'Bridal',
  ];

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final normalizedQuery = _query.trim().toLowerCase();
    final visibleServices = normalizedQuery.isEmpty
        ? _services
        : _services
              .where(
                (service) => service.toLowerCase().contains(normalizedQuery),
              )
              .toList();
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Salon',
        subtitle: 'Choose a service and book directly',
        showBack: false,
        body: ColoredBox(
          color: MoolServiceHomeTokens.page,
          child: ListView(
            key: const Key('salon-discovery-home'),
            padding: const EdgeInsets.fromLTRB(
              MoolServiceHomeTokens.pagePadding,
              MoolSpacing.sm,
              MoolServiceHomeTokens.pagePadding,
              MoolSpacing.xl,
            ),
            children: [
              MoolServiceSearchField(
                fieldKey: const Key('salon-search'),
                hintText: 'Search salon service',
                semanticLabel: 'Search salon service',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: MoolServiceHomeTokens.sectionGap),
              MoolServiceSectionHeader(
                title: 'Services',
                subtitle: normalizedQuery.isEmpty
                    ? 'Select one to see the exact starting price.'
                    : '${visibleServices.length} matching service${visibleServices.length == 1 ? '' : 's'}',
              ),
              const SizedBox(height: MoolSpacing.sm),
              if (visibleServices.isEmpty)
                const MoolServiceCard(
                  key: Key('salon-search-empty'),
                  title: 'No matching service',
                  subtitle:
                      'Try Haircut, Beard, Facial, Colour, Massage or Bridal.',
                  icon: Icons.search_off_rounded,
                )
              else
                Wrap(
                  spacing: MoolSpacing.xs,
                  runSpacing: MoolSpacing.xs,
                  children: visibleServices
                      .map(
                        (service) => MoolServiceChoice(
                          key: Key('salon-service-${service.toLowerCase()}'),
                          label: service,
                          accent: _accent,
                          selected: session.salonService == service,
                          onSelected: (_) =>
                              session.chooseSalonService(service),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: MoolServiceHomeTokens.sectionGap),
              const MoolServiceSectionHeader(
                title: 'Where should it happen?',
                subtitle: 'Availability and price stay visible before booking.',
              ),
              const SizedBox(height: MoolSpacing.sm),
              Wrap(
                spacing: MoolSpacing.xs,
                runSpacing: MoolSpacing.xs,
                children: SalonMode.values
                    .map(
                      (mode) => MoolServiceChoice(
                        key: Key('salon-mode-${mode.name}'),
                        label: mode.label,
                        icon: switch (mode) {
                          SalonMode.salon => Icons.storefront_outlined,
                          SalonMode.home => Icons.home_outlined,
                          SalonMode.makeup => Icons.face_retouching_natural,
                          SalonMode.package => Icons.inventory_2_outlined,
                        },
                        accent: _accent,
                        selected: session.salonMode == mode,
                        onSelected: (_) => session.chooseSalonMode(mode),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: MoolServiceHomeTokens.sectionGap),
              const MoolServiceSectionHeader(
                title: 'Available today',
                subtitle:
                    'One trusted match with price and cancellation shown.',
              ),
              const SizedBox(height: MoolSpacing.sm),
              MoolServiceCard(
                key: const Key('salon-top-provider'),
                title: 'Royal Touch Salon',
                subtitle:
                    '${session.salonService} · ${session.salonMode.label}',
                icon: Icons.content_cut_rounded,
                accent: _accent,
                emphasized: true,
                metadata: [
                  const MoolServiceMeta(
                    icon: Icons.verified_rounded,
                    label: 'Shop and photos verified',
                  ),
                  const MoolServiceMeta(
                    icon: Icons.near_me_outlined,
                    label: '800 m',
                  ),
                  const MoolServiceMeta(
                    icon: Icons.schedule_rounded,
                    label: 'Today · 5:40 PM',
                  ),
                  const MoolServiceMeta(
                    icon: Icons.timer_outlined,
                    label: '35 min',
                  ),
                  MoolServiceMeta(
                    icon: Icons.currency_rupee_rounded,
                    label: bookMoney(session.salonAmount),
                  ),
                  const MoolServiceMeta(
                    icon: Icons.event_busy_outlined,
                    label: 'Free cancel until 5:10 PM',
                  ),
                ],
                semanticLabel:
                    'Royal Touch Salon, verified, ${session.salonService}, ${session.salonMode.label}, today at 5:40 PM, ${bookMoney(session.salonAmount)}, free cancellation until 5:10 PM',
                onTap: () {
                  session.clearMessages();
                  context.go('/app/book/salon/confirm');
                },
              ),
              const SizedBox(height: MoolSpacing.sm),
              OutlinedButton.icon(
                key: const Key('salon-ask-provider'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(44, 48),
                ),
                onPressed: () => session.showNotice(
                  'Salon chat opened with service and slot attached.',
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Ask salon'),
              ),
            ],
          ),
        ),
        bottomAction: MoolServicePrimaryButton(
          key: const Key('review-salon-slot'),
          accent: _accent,
          icon: Icons.event_available_outlined,
          label: 'Review ${bookMoney(session.salonAmount)} slot',
          onPressed: () {
            session.clearMessages();
            context.go('/app/book/salon/confirm');
          },
        ),
      ),
    );
  }
}

class SalonConfirmScreen extends StatelessWidget {
  const SalonConfirmScreen({required this.session, super.key});

  final BookSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Confirm salon',
        subtitle: 'Slot held · price locked',
        fallbackBackRoute: '/app/book/salon',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            _SalonSummary(session: session),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('Payment choice'),
            const SizedBox(height: MoolSpacing.sm),
            Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: SalonPayment.values
                  .map(
                    (payment) => MoolSegment(
                      key: Key('salon-payment-${payment.name}'),
                      label: payment.label,
                      selected: session.salonPayment == payment,
                      onPressed: () => session.chooseSalonPayment(payment),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('Optional add-on'),
            const SizedBox(height: MoolSpacing.sm),
            Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: const ['No add-on', 'Beard', 'Wash', 'Cleanup']
                  .map(
                    (addon) => MoolSegment(
                      key: Key(
                        'salon-addon-${addon.toLowerCase().replaceAll(' ', '-')}',
                      ),
                      label: addon,
                      selected: session.salonAddon == addon,
                      onPressed: () => session.chooseSalonAddon(addon),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: MoolSpacing.lg),
            BookCard(
              color: const Color(0xFFF4F3FF),
              child: Column(
                children: [
                  const BookFact(
                    icon: Icons.receipt_long_outlined,
                    title: 'Pay through MoolSocial',
                    detail:
                        'Receipt, correction record, support and rewards stay together.',
                  ),
                  const Divider(height: 24),
                  const BookFact(
                    icon: Icons.event_busy_outlined,
                    title: 'Free cancellation till 5:10 PM',
                    detail:
                        'Alternate slots appear before any cancellation is final.',
                  ),
                  const Divider(height: 24),
                  BookFact(
                    icon: Icons.payments_outlined,
                    title: '${bookMoney(session.salonTotal)} total',
                    detail:
                        '${session.salonService} · ${session.salonAddon} · ${session.salonPayment.label}',
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomAction: FilledButton(
          key: const Key('confirm-salon-slot'),
          onPressed: session.busy
              ? null
              : () async {
                  final ok = await session.confirmSalon();
                  if (ok && context.mounted) {
                    context.go('/app/book/salon/confirmed');
                  }
                },
          child: Text(session.busy ? 'Confirming…' : 'Confirm slot'),
        ),
      ),
    );
  }
}

class SalonConfirmedScreen extends StatelessWidget {
  const SalonConfirmedScreen({required this.session, super.key});

  final BookSession session;

  @override
  Widget build(BuildContext context) {
    final booking = session.salonBooking;
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Salon confirmed',
        subtitle: 'Reminder, route and changes',
        activeLocalAction: 'activity',
        fallbackBackRoute: '/app/book/salon/confirm',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            BookCard(
              color: const Color(0xFFEAF7E8),
              child: BookFact(
                icon: Icons.event_available_rounded,
                title: booking == null
                    ? 'No active salon booking'
                    : 'Booking ${booking.id} confirmed',
                detail:
                    'Royal Touch Salon · Today 5:40 PM · reminder 30 min before',
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            _SalonSummary(session: session),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('Manage booking'),
            const SizedBox(height: MoolSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('salon-directions'),
                    onPressed: () => session.showNotice(
                      'Directions opened for Royal Touch Salon, 800 m away.',
                    ),
                    icon: const Icon(Icons.directions_outlined),
                    label: const Text('Directions'),
                  ),
                ),
                const SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('salon-reschedule'),
                    onPressed: () => session.showNotice(
                      'Alternate slots are ready before changing this booking.',
                    ),
                    icon: const Icon(Icons.edit_calendar_outlined),
                    label: const Text('Reschedule'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.xs),
            OutlinedButton.icon(
              key: const Key('salon-cancel'),
              onPressed: () => _showCancelSheet(context, session),
              icon: const Icon(Icons.event_busy_outlined),
              label: const Text('Cancel booking'),
            ),
          ],
        ),
        bottomAction: FilledButton(
          key: const Key('salon-arrived'),
          onPressed: booking == null
              ? null
              : () {
                  session.checkInSalon();
                  context.go('/app/book/salon/visit');
                },
          child: const Text('I arrived at salon'),
        ),
      ),
    );
  }

  Future<void> _showCancelSheet(
    BuildContext context,
    BookSession session,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cancel this salon slot?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: MoolSpacing.xs),
              const Text(
                'The booking is inside the free cancellation window. No fee will be charged.',
              ),
              const SizedBox(height: MoolSpacing.lg),
              FilledButton(
                key: const Key('confirm-salon-cancel'),
                onPressed: () {
                  session.cancelSalon();
                  Navigator.of(sheetContext).pop();
                },
                child: const Text('Cancel with ₹0 fee'),
              ),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Keep booking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SalonVisitScreen extends StatelessWidget {
  const SalonVisitScreen({required this.session, super.key});

  final BookSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Salon visit',
        subtitle: 'Checked in · stylist preparing',
        activeLocalAction: 'activity',
        fallbackBackRoute: '/app/book/salon/confirmed',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            const BookCard(
              color: Color(0xFFEAF7E8),
              child: BookFact(
                icon: Icons.store_mall_directory_outlined,
                title: 'Royal Touch acknowledged your arrival',
                detail: 'Ravi assigned · chair 3 · approximately 5 minutes',
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('Visit status'),
            const SizedBox(height: MoolSpacing.sm),
            const BookCard(
              child: Column(
                children: [
                  BookFact(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Arrival noted',
                    detail: 'The salon and your saved booking are connected.',
                  ),
                  Divider(height: 24),
                  BookFact(
                    icon: Icons.groups_2_outlined,
                    title: '2 customers ahead',
                    detail: 'Ravi is preparing chair 3 for your service.',
                  ),
                  Divider(height: 24),
                  BookFact(
                    icon: Icons.receipt_long_outlined,
                    title: '₹199 payment pending',
                    detail:
                        'Review the final service and bill before approving payment.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            OutlinedButton.icon(
              key: const Key('salon-issue-before-pay'),
              onPressed: () => context.go('/app/book/salon/support'),
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Report an issue before payment'),
            ),
          ],
        ),
        bottomAction: FilledButton(
          key: const Key('salon-service-done'),
          onPressed: () {
            session.completeSalonService();
            context.go('/app/book/salon/complete');
          },
          child: const Text('Service is done'),
        ),
      ),
    );
  }
}

class SalonCompleteScreen extends StatelessWidget {
  const SalonCompleteScreen({required this.session, super.key});

  final BookSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Finish salon visit',
        subtitle: 'Review bill · pay · rate',
        activeLocalAction: 'activity',
        fallbackBackRoute: '/app/book/salon/visit',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            BookCard(
              color: const Color(0xFFF4F3FF),
              child: BookFact(
                icon: Icons.receipt_long_rounded,
                title: '${bookMoney(session.salonTotal)} final bill',
                detail:
                    '${session.salonService} completed by Ravi · no hidden add-ons',
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            FilledButton.icon(
              key: const Key('pay-salon-bill'),
              onPressed: session.busy || session.salonPaid
                  ? null
                  : session.paySalonBill,
              icon: const Icon(Icons.lock_open_rounded),
              label: Text(
                session.salonPaid
                    ? 'Bill paid and saved'
                    : session.busy
                    ? 'Confirming payment…'
                    : 'Approve ${bookMoney(session.salonTotal)} bill',
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('Rate your visit', detail: 'Optional'),
            const SizedBox(height: MoolSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                5,
                (index) => IconButton.filledTonal(
                  key: Key('salon-rating-${index + 1}'),
                  tooltip: '${index + 1} stars',
                  onPressed: () => session.setSalonRating(index + 1),
                  icon: Icon(
                    index < session.salonRating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            OutlinedButton(
              key: const Key('submit-salon-rating'),
              onPressed: session.submitSalonRating,
              child: const Text('Submit rating'),
            ),
            const SizedBox(height: MoolSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      session.resetSalon();
                      context.go('/app/book/salon');
                    },
                    child: const Text('Book again'),
                  ),
                ),
                const SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/app/book/salon/support'),
                    child: const Text('Need help'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SalonSupportScreen extends StatefulWidget {
  const SalonSupportScreen({required this.session, super.key});

  final BookSession session;

  @override
  State<SalonSupportScreen> createState() => _SalonSupportScreenState();
}

class _SalonSupportScreenState extends State<SalonSupportScreen> {
  final _detailController = TextEditingController();

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Salon help',
        subtitle: 'Saved bill and visit evidence attached',
        activeLocalAction: 'help',
        fallbackBackRoute: '/app/book/salon/complete',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            const BookCard(
              color: Color(0xFFF4F3FF),
              child: BookFact(
                icon: Icons.folder_copy_outlined,
                title: 'Your visit record is ready',
                detail:
                    'Booking, bill, payment, rating and salon chat will be attached automatically.',
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('What needs review?'),
            const SizedBox(height: MoolSpacing.sm),
            Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: SalonIssue.values
                  .map(
                    (issue) => MoolSegment(
                      key: Key('salon-issue-${issue.name}'),
                      label: issue.label,
                      selected: session.salonIssue == issue,
                      onPressed: () => session.chooseSalonIssue(issue),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: MoolSpacing.sm),
            TextField(
              key: const Key('salon-support-detail'),
              controller: _detailController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Add detail (optional)',
                hintText: 'Explain only what the saved record does not show',
              ),
            ),
            if (session.salonSupportCase != null) ...[
              const SizedBox(height: MoolSpacing.sm),
              BookCard(
                color: const Color(0xFFEAF7E8),
                child: BookFact(
                  icon: Icons.support_agent_rounded,
                  title: 'Case ${session.salonSupportCase!.id} open',
                  detail: 'Saved visit attached · reply expected the same day',
                ),
              ),
            ],
          ],
        ),
        bottomAction: FilledButton(
          key: const Key('submit-salon-support'),
          onPressed: session.busy
              ? null
              : () => session.submitSalonSupport(_detailController.text),
          child: Text(session.busy ? 'Attaching record…' : 'Ask for review'),
        ),
      ),
    );
  }
}

class _SalonSummary extends StatelessWidget {
  const _SalonSummary({required this.session});

  final BookSession session;

  @override
  Widget build(BuildContext context) {
    return BookCard(
      child: Column(
        children: [
          const BookFact(
            icon: Icons.storefront_outlined,
            title: 'Royal Touch Salon',
            detail: 'Today 5:40 PM · 800 m · rating and photos verified',
          ),
          const Divider(height: 24),
          BookFact(
            icon: Icons.content_cut_rounded,
            title: session.salonService,
            detail: '${session.salonMode.label} · 35 minute slot',
          ),
          const Divider(height: 24),
          BookFact(
            icon: Icons.payments_outlined,
            title: bookMoney(session.salonTotal),
            detail: session.salonPaid
                ? 'Paid · bill saved'
                : 'Payment not taken yet',
          ),
        ],
      ),
    );
  }
}
