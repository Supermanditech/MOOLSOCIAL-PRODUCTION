import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/mool_design_system.dart';
import '../../../../core/design/mool_theme.dart';
import '../operations_session.dart';
import '../widgets/operations_widgets.dart';

class ProviderHomeScreen extends StatelessWidget {
  const ProviderHomeScreen({required this.session, super.key});

  final OperationsSession session;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => OperationsPageScaffold(
      session: session,
      title: 'Ravi Home Services',
      subtitle: 'Verified service provider · Jodhpur',
      activeDock: 'requests',
      returnRoute: '/app/provider',
      provider: true,
      showBack: false,
      trailing: IconButton.outlined(
        key: const Key('provider-home-controls'),
        tooltip: 'Workspace controls',
        onPressed: () => context.go('/app/provider/control'),
        icon: const Icon(Icons.tune_rounded),
      ),
      body: ListView(
        key: const Key('provider-home-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.xl,
        ),
        children: [
          const OpsCard(
            color: MoolColors.navy,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'READY TO OPERATE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '3 actions need you',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Identity and service readiness · 82% complete',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                OpsPill(label: '82%', color: MoolColors.orange),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const Row(
            children: [
              Expanded(
                child: OpsMetric(
                  label: 'TODAY',
                  value: '6',
                  detail: 'requests',
                ),
              ),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: OpsMetric(
                  label: 'ACCEPTED',
                  value: '4',
                  detail: 'active',
                ),
              ),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: OpsMetric(
                  label: 'TO RECEIVE',
                  value: '₹4,860',
                  detail: 'verified',
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.md),
          const OpsSectionTitle(
            title: 'Operate today',
            detail: 'One owner per outcome',
          ),
          const SizedBox(height: MoolSpacing.sm),
          _HomeOwnerCard(
            keyName: 'provider-home-requests',
            icon: Icons.inbox_outlined,
            title: 'Requests',
            detail: '2 need a response',
            status: 'Act now',
            onTap: () => context.go('/app/provider/requests'),
          ),
          _HomeOwnerCard(
            keyName: 'provider-home-services',
            icon: Icons.design_services_outlined,
            title: 'Services',
            detail: '8 ready for customers',
            status: 'Keep current',
            onTap: () => context.go('/app/provider/catalogue'),
          ),
          _HomeOwnerCard(
            keyName: 'provider-home-availability',
            icon: Icons.calendar_month_outlined,
            title: 'Availability and area',
            detail: 'Open until 7 PM',
            status: 'Control',
            onTap: () => context.go('/app/provider/availability'),
          ),
          _HomeOwnerCard(
            keyName: 'provider-home-business',
            icon: Icons.account_balance_wallet_outlined,
            title: 'Money and records',
            detail: '₹2,640 available',
            status: 'Business',
            onTap: () => context.go('/app/provider/business'),
          ),
          const SizedBox(height: MoolSpacing.md),
          const OpsSectionTitle(
            title: 'Priority',
            detail: 'Highest impact first',
          ),
          const SizedBox(height: MoolSpacing.sm),
          OpsActionRow(
            keyName: 'provider-priority-request',
            icon: Icons.notification_important_outlined,
            title: 'Respond within 4 minutes',
            detail: 'Customer needs price, time and confirmation',
            meta: '₹850 request value',
            action: 'Review',
            color: const Color(0xFFFFF6E8),
            onTap: () => context.go('/app/provider/requests'),
          ),
          const SizedBox(height: MoolSpacing.xs),
          OpsActionRow(
            keyName: 'provider-priority-capacity',
            icon: Icons.event_available_outlined,
            title: 'Confirm tomorrow’s capacity',
            detail: 'Prevent overbooking before new demand opens',
            meta: 'Availability and area',
            action: 'Confirm',
            onTap: () => context.go('/app/provider/availability'),
          ),
          const SizedBox(height: MoolSpacing.xs),
          OpsActionRow(
            keyName: 'provider-priority-readiness',
            icon: Icons.verified_user_outlined,
            title: 'Complete readiness',
            detail: 'One service document needs review',
            meta: 'Identity and service readiness',
            action: 'Continue',
            onTap: () => context.go('/app/provider/control'),
          ),
          const SizedBox(height: MoolSpacing.md),
          OpsActionRow(
            keyName: 'provider-home-growth',
            icon: Icons.trending_up_rounded,
            title: 'Earn and campaign opportunities',
            detail: '12 funded nearby outcomes',
            meta: 'Potential ₹18K/month · not guaranteed',
            action: 'Explore',
            onTap: () => context.go('/app/provider/growth'),
          ),
        ],
      ),
    ),
  );
}

class ProviderCatalogueScreen extends StatelessWidget {
  const ProviderCatalogueScreen({required this.session, super.key});

  final OperationsSession session;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => OperationsPageScaffold(
      session: session,
      title: 'Services',
      subtitle: 'Ravi Home Services · customer-ready catalogue',
      activeDock: 'services',
      returnRoute: '/app/provider',
      provider: true,
      trailing: IconButton.outlined(
        key: const Key('provider-service-add'),
        tooltip: 'Add service',
        onPressed: () {
          session.beginService();
          _serviceSheet(context);
        },
        icon: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        key: const Key('provider-catalogue-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.xl,
        ),
        children: [
          const OpsCard(
            color: MoolColors.navy,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CUSTOMER-READY CATALOGUE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '8 services live',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Price, time, completion and cancellation are clear',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                OpsPill(label: '8 LIVE', color: MoolColors.orange),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          _ProviderSegments<ProviderCatalogueTab>(
            values: ProviderCatalogueTab.values,
            selected: session.catalogueTab,
            keyPrefix: 'provider-catalogue-tab',
            label: (value) => switch (value) {
              ProviderCatalogueTab.live => 'Live',
              ProviderCatalogueTab.draft => 'Draft',
              ProviderCatalogueTab.paused => 'Paused',
              ProviderCatalogueTab.needsUpdate => 'Needs Update',
            },
            onSelect: session.setCatalogueTab,
          ),
          const SizedBox(height: MoolSpacing.md),
          if (session.catalogueTab == ProviderCatalogueTab.live) ...[
            _ServiceCard(
              keyName: 'provider-service-standard',
              title: 'Standard service',
              price: '₹499',
              time: '45 min',
              detail: 'At location · free cancellation up to 2 hours',
              onEdit: () {
                session.beginService(name: 'Standard service');
                _serviceSheet(context);
              },
              onPreview: () => _previewSheet(context, 'Standard service'),
            ),
            const SizedBox(height: MoolSpacing.sm),
            _ServiceCard(
              keyName: 'provider-service-premium',
              title: 'Premium service',
              price: '₹899',
              time: '75 min',
              detail: 'At location · completion receipt',
              onEdit: () {
                session.beginService(name: 'Premium service');
                _serviceSheet(context);
              },
              onPreview: () => _previewSheet(context, 'Premium service'),
            ),
          ] else
            const OpsCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(MoolSpacing.md),
                  child: Text(
                    'No services in this state. Add a service or choose Live.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          const SizedBox(height: MoolSpacing.sm),
          const OpsCard(
            color: Color(0xFFF4F3FF),
            child: Text(
              'Only fields required for this verified service profile are shown. Other provider types receive their own relevant fields.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _serviceSheet(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.md,
            MoolSpacing.md,
            MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.md,
          ),
          child: SingleChildScrollView(
            child: Column(
              key: const Key('provider-service-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service customers can choose',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const Text('Show exactly what the customer gets.'),
                const SizedBox(height: MoolSpacing.md),
                TextFormField(
                  key: const Key('provider-service-name'),
                  initialValue: session.serviceName,
                  onChanged: (value) {
                    session.serviceName = value;
                    session.clearMessages();
                  },
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: MoolSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('provider-service-price'),
                        initialValue: session.servicePrice,
                        keyboardType: TextInputType.number,
                        onChanged: (value) => session.servicePrice = value,
                        decoration: const InputDecoration(labelText: 'Price ₹'),
                      ),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    Expanded(
                      child: TextFormField(
                        key: const Key('provider-service-time'),
                        initialValue: session.serviceTime,
                        keyboardType: TextInputType.number,
                        onChanged: (value) => session.serviceTime = value,
                        decoration: const InputDecoration(labelText: 'Minutes'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.sm),
                TextFormField(
                  key: const Key('provider-service-scope'),
                  initialValue: session.serviceScope,
                  minLines: 2,
                  maxLines: 3,
                  onChanged: (value) => session.serviceScope = value,
                  decoration: const InputDecoration(
                    labelText: 'What customer gets',
                  ),
                ),
                SwitchListTile(
                  key: const Key('provider-service-visible'),
                  contentPadding: EdgeInsets.zero,
                  value: session.serviceConsumerVisible,
                  onChanged: session.setServiceConsumerVisible,
                  title: const Text('Show to customers after readiness check'),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('provider-service-save'),
                    onPressed: session.busy ? null : session.saveService,
                    child: Text(
                      session.serviceId == null
                          ? 'Save Service'
                          : 'Service Saved',
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('provider-service-close'),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _previewSheet(
    BuildContext context,
    String name,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('provider-service-preview-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const Text('This is what a customer sees before choosing.'),
            const SizedBox(height: MoolSpacing.md),
            const OpsCard(
              color: Color(0xFFF4F3FF),
              child: Column(
                children: [
                  OpsFact(label: 'Price', value: '₹499'),
                  OpsFact(label: 'Time', value: '45 minutes'),
                  OpsFact(label: 'Mode', value: 'At customer location'),
                  OpsFact(label: 'Cancellation', value: 'Free up to 2 hours'),
                  OpsFact(label: 'Completion', value: 'Receipt included'),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('provider-service-preview-close'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ProviderAvailabilityScreen extends StatelessWidget {
  const ProviderAvailabilityScreen({required this.session, super.key});

  final OperationsSession session;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => OperationsPageScaffold(
      session: session,
      title: 'Availability and Area',
      subtitle: 'Ravi Home Services · capacity protected',
      activeDock: 'services',
      returnRoute: '/app/provider',
      provider: true,
      trailing: IconButton.outlined(
        key: const Key('provider-availability-pause'),
        tooltip: 'Pause new demand',
        onPressed: () => _pauseSheet(context),
        icon: const Icon(Icons.pause_rounded),
      ),
      bottomAction: FilledButton(
        key: const Key('provider-availability-save'),
        onPressed: session.busy ? null : session.saveAvailability,
        child: Text(
          session.availabilityId == null
              ? 'Save Availability'
              : 'Availability Saved',
        ),
      ),
      body: ListView(
        key: const Key('provider-availability-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.xl,
        ),
        children: [
          OpsCard(
            color: MoolColors.navy,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AVAILABLE NOW',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        session.acceptNewDemand
                            ? '4 more requests today'
                            : 'New demand paused',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Confirmed work remains active',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                OpsPill(
                  label: session.acceptNewDemand ? 'OPEN' : 'PAUSED',
                  color: MoolColors.orange,
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const Row(
            children: [
              Expanded(
                child: OpsMetric(label: 'OPEN', value: '4', detail: 'today'),
              ),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: OpsMetric(
                  label: 'BOOKED',
                  value: '6',
                  detail: 'confirmed',
                ),
              ),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: OpsMetric(
                  label: 'NEXT',
                  value: '11:30',
                  detail: 'start',
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.md),
          const OpsSectionTitle(
            title: 'Operating promise',
            detail: 'Visible to customers',
          ),
          const SizedBox(height: MoolSpacing.sm),
          const OpsCard(
            color: Color(0xFFF4F3FF),
            child: Column(
              children: [
                OpsFact(label: 'Opens', value: '9:00 AM'),
                OpsFact(label: 'Closes', value: '7:00 PM'),
                OpsFact(label: 'Service area', value: 'Jodhpur · within 8 km'),
                OpsFact(label: 'Mode', value: 'At customer location'),
              ],
            ),
          ),
          SwitchListTile(
            key: const Key('provider-accept-demand'),
            contentPadding: EdgeInsets.zero,
            value: session.acceptNewDemand,
            onChanged: (value) {
              session.toggleNewDemand(value);
              if (!value) _pauseSheet(context);
            },
            title: const Text('Accept new demand'),
            subtitle: const Text('Stops automatically at confirmed capacity'),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const OpsSectionTitle(title: 'Next 7 days', detail: 'Tap to change'),
          const SizedBox(height: MoolSpacing.sm),
          ...const [
            ('monday', 'Monday', '4 slots open', '9 AM – 7 PM'),
            ('tuesday', 'Tuesday', '2 slots open', '10 AM – 5 PM'),
            ('wednesday', 'Wednesday', 'Closed', 'Personal day'),
          ].map(
            (day) => Padding(
              padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
              child: OpsActionRow(
                keyName: 'provider-day-${day.$1}',
                icon: Icons.calendar_today_outlined,
                title: day.$2,
                detail: day.$3,
                meta: day.$4,
                action: 'Change',
                onTap: () => _daySheet(context, day.$2),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _pauseSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.md),
          child: Column(
            key: const Key('provider-pause-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pause new demand?',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const Text(
                'Accepted work stays active. Customers see your next available time.',
              ),
              const SizedBox(height: MoolSpacing.md),
              Wrap(
                spacing: MoolSpacing.xs,
                runSpacing: MoolSpacing.xs,
                children: ['30 minutes', '2 hours', 'Today', 'Custom']
                    .map(
                      (value) => ChoiceChip(
                        key: Key(
                          'provider-pause-${value.toLowerCase().replaceAll(' ', '-')}',
                        ),
                        label: Text(value),
                        selected: session.pauseDuration == value,
                        onSelected: (_) => session.setPauseDuration(value),
                      ),
                    )
                    .toList(),
              ),
              CheckboxListTile(
                key: const Key('provider-pause-confirm'),
                contentPadding: EdgeInsets.zero,
                value: session.pauseConfirmed,
                onChanged: (value) => session.confirmPause(value ?? false),
                title: const Text(
                  'Keep accepted work active and pause only new demand',
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('provider-pause-apply'),
                  onPressed: () {
                    session.toggleNewDemand(false);
                    session.confirmPause(true);
                    Navigator.pop(sheetContext);
                  },
                  child: const Text('Pause Safely'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: const Key('provider-pause-cancel'),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _daySheet(BuildContext context, String day) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.md),
            child: Column(
              key: const Key('provider-day-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text('Set open capacity without changing accepted work.'),
                const SizedBox(height: MoolSpacing.md),
                const OpsCard(
                  color: Color(0xFFF4F3FF),
                  child: Column(
                    children: [
                      OpsFact(label: 'Hours', value: '9 AM – 7 PM'),
                      OpsFact(label: 'Open capacity', value: '4 requests'),
                      OpsFact(label: 'Area', value: 'Within 8 km'),
                    ],
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('provider-day-save'),
                    onPressed: () {
                      session.selectedDay = day;
                      Navigator.pop(sheetContext);
                    },
                    child: const Text('Use These Hours'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class ProviderRequestsScreen extends StatelessWidget {
  const ProviderRequestsScreen({required this.session, super.key});

  final OperationsSession session;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => OperationsPageScaffold(
      session: session,
      title: 'Requests',
      subtitle: 'Ravi Home Services · live customer demand',
      activeDock: 'requests',
      returnRoute: '/app/provider',
      provider: true,
      trailing: IconButton.outlined(
        key: const Key('provider-request-filter'),
        tooltip: 'Filter requests',
        onPressed: () => _filterSheet(context),
        icon: const Icon(Icons.tune_rounded),
      ),
      body: ListView(
        key: const Key('provider-requests-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.xl,
        ),
        children: [
          _ProviderSegments<ProviderRequestTab>(
            values: ProviderRequestTab.values,
            selected: session.requestTab,
            keyPrefix: 'provider-request-tab',
            label: (value) => switch (value) {
              ProviderRequestTab.newRequests => 'New 2',
              ProviderRequestTab.accepted => 'Accepted 4',
              ProviderRequestTab.completed => 'Completed',
            },
            onSelect: session.setRequestTab,
          ),
          const SizedBox(height: MoolSpacing.md),
          if (session.requestTab == ProviderRequestTab.newRequests) ...[
            _RequestCard(
              keyName: 'provider-request-RQ-2401',
              title: 'Standard service · Priya Sharma',
              price: '₹850',
              urgency: 'Respond in 04:18',
              time: 'Today 11:30',
              place: '3.2 km',
              onAccept: () {
                session.selectRequest('RQ-2401');
                _requestSheet(context, 'Priya Sharma', '₹850');
              },
              onDecline: () {
                session.selectRequest('RQ-2401');
                _declineSheet(context);
              },
            ),
            const SizedBox(height: MoolSpacing.sm),
            _RequestCard(
              keyName: 'provider-request-RQ-2402',
              title: 'Premium service · Aarav Mehta',
              price: '₹1,250',
              urgency: 'Respond in 09:42',
              time: 'Today 3 PM',
              place: 'At location',
              onAccept: () {
                session.selectRequest('RQ-2402');
                _requestSheet(context, 'Aarav Mehta', '₹1,250');
              },
              onDecline: () {
                session.selectRequest('RQ-2402');
                _declineSheet(context);
              },
            ),
          ] else if (session.requestTab == ProviderRequestTab.accepted)
            OpsActionRow(
              keyName: 'provider-request-active-2401',
              icon: Icons.play_circle_outline_rounded,
              title: 'Priya Sharma · Standard service',
              detail: 'Today 11:30 · protected payment',
              meta: 'Next: confirm arrival',
              action: 'Continue',
              onTap: () => context.go('/app/provider/fulfilment'),
            )
          else
            OpsActionRow(
              keyName: 'provider-request-completed-2397',
              icon: Icons.check_circle_outline_rounded,
              title: 'Completed service · RQ-2397',
              detail: 'Receipt sent · ₹650 available',
              action: 'Money',
              onTap: () => context.go('/app/provider/business'),
            ),
        ],
      ),
    ),
  );

  Future<void> _filterSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('provider-request-filter-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Show requests',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: MoolSpacing.md),
            _ProviderSegments<ProviderRequestTab>(
              values: ProviderRequestTab.values,
              selected: session.requestTab,
              keyPrefix: 'provider-request-filter-tab',
              label: (value) => switch (value) {
                ProviderRequestTab.newRequests => 'New',
                ProviderRequestTab.accepted => 'Accepted',
                ProviderRequestTab.completed => 'Completed',
              },
              onSelect: session.setRequestTab,
            ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('provider-request-filter-close'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Show Requests'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _requestSheet(
    BuildContext context,
    String customer,
    String price,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.md),
          child: SingleChildScrollView(
            child: Column(
              key: const Key('provider-request-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accept $customer’s request?',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text('Capacity is reserved only after confirmation.'),
                const SizedBox(height: MoolSpacing.md),
                OpsCard(
                  color: const Color(0xFFF4F3FF),
                  child: Column(
                    children: [
                      OpsFact(label: 'Price', value: price),
                      const OpsFact(label: 'Time', value: 'Today 11:30'),
                      const OpsFact(label: 'Payment', value: 'Protected'),
                      const OpsFact(
                        label: 'Cancellation',
                        value: 'Free until 2 hours before',
                      ),
                    ],
                  ),
                ),
                CheckboxListTile(
                  key: const Key('provider-request-terms'),
                  contentPadding: EdgeInsets.zero,
                  value: session.requestTermsConfirmed,
                  onChanged: (value) =>
                      session.confirmRequestTerms(value ?? false),
                  title: const Text(
                    'I reviewed the scope, price, time and cancellation',
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('provider-request-accept'),
                    onPressed: session.busy
                        ? null
                        : () async {
                            if (await session.acceptRequest() &&
                                context.mounted) {
                              Navigator.pop(sheetContext);
                              context.go('/app/provider/fulfilment');
                            }
                          },
                    child: Text(
                      session.requestAcceptanceId == null
                          ? 'Confirm and Open Work'
                          : 'Request Accepted',
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('provider-request-close'),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _declineSheet(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => AnimatedBuilder(
          animation: session,
          builder: (context, _) => SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                MoolSpacing.md,
                MoolSpacing.md,
                MoolSpacing.md,
                MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.md,
              ),
              child: Column(
                key: const Key('provider-request-decline-sheet'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cannot take this request',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                  ),
                  const Text('Give the customer a clear next step.'),
                  const SizedBox(height: MoolSpacing.md),
                  TextField(
                    key: const Key('provider-request-decline-reason'),
                    onChanged: (value) => session.declineReason = value,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      hintText: 'For example: no capacity at this time',
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('provider-request-decline'),
                      onPressed: session.busy ? null : session.declineRequest,
                      child: Text(
                        session.requestDeclineId == null
                            ? 'Notify Customer'
                            : 'Customer Notified',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      key: const Key('provider-request-decline-close'),
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class ProviderFulfilmentScreen extends StatelessWidget {
  const ProviderFulfilmentScreen({required this.session, super.key});

  final OperationsSession session;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => OperationsPageScaffold(
      session: session,
      title: 'Active Service',
      subtitle: 'RQ-2401 · Priya Sharma · protected payment',
      activeDock: 'requests',
      returnRoute: '/app/provider/requests',
      provider: true,
      trailing: IconButton.outlined(
        key: const Key('provider-fulfilment-privacy'),
        tooltip: 'Privacy for this service',
        onPressed: () => _privacySheet(context),
        icon: const Icon(Icons.privacy_tip_outlined),
      ),
      bottomAction: FilledButton(
        key: const Key('provider-fulfilment-complete'),
        onPressed: session.busy ? null : () => _complete(context),
        child: Text(
          session.fulfilmentId == null
              ? 'Confirm and Continue'
              : 'Outcome Complete',
        ),
      ),
      body: ListView(
        key: const Key('provider-fulfilment-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.xl,
        ),
        children: [
          const OpsCard(
            color: MoolColors.navy,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEXT ACTION',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Confirm arrival by 11:25',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Customer sees live status; only required proof appears',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                OpsPill(label: '12 MIN', color: MoolColors.orange),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          OpsCard(
            color: const Color(0xFFF4F3FF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress · ${session.fulfilmentStep} of 5',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: MoolSpacing.xs),
                LinearProgressIndicator(
                  value: session.fulfilmentStep / 5,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: MoolSpacing.sm),
                const OpsFact(label: '1 · Accepted', value: 'Terms locked'),
                const OpsFact(label: '2 · Customer confirmed', value: 'Ready'),
                const OpsFact(label: '3 · Start service', value: 'Next'),
                const OpsFact(label: '4 · Complete outcome', value: 'Pending'),
                const OpsFact(label: '5 · Settlement', value: 'Pending'),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const OpsCard(
            child: Column(
              children: [
                OpsFact(label: 'Customer', value: 'Priya Sharma · verified'),
                OpsFact(label: 'Price', value: '₹850'),
                OpsFact(label: 'Time', value: '11:30'),
                OpsFact(label: 'Location', value: '3.2 km'),
                OpsFact(label: 'Payment', value: 'Protected'),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          OutlinedButton.icon(
            key: const Key('provider-message-customer'),
            onPressed: () => _messageSheet(context),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Message Customer'),
          ),
          CheckboxListTile(
            key: const Key('provider-arrival-confirm'),
            contentPadding: EdgeInsets.zero,
            value: session.arrivalConfirmed,
            onChanged: (value) => session.confirmArrival(value ?? false),
            title: const Text('I arrived at the confirmed location'),
          ),
          CheckboxListTile(
            key: const Key('provider-outcome-confirm'),
            contentPadding: EdgeInsets.zero,
            value: session.outcomeCompleted,
            onChanged: (value) =>
                session.confirmFulfilmentOutcome(value ?? false),
            title: const Text('Customer outcome and receipt are complete'),
          ),
        ],
      ),
    ),
  );

  Future<void> _complete(BuildContext context) async {
    if (await session.completeFulfilment() && context.mounted) {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.md),
            child: Column(
              key: const Key('provider-fulfilment-complete-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service outcome complete',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const Text('₹850 is now in settlement review.'),
                const SizedBox(height: MoolSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('provider-fulfilment-open-money'),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      context.go('/app/provider/business');
                    },
                    child: const Text('Open Money'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<void> _messageSheet(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MoolSpacing.md),
            child: Column(
              key: const Key('provider-message-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Message Priya Sharma',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const Text('This message stays with request RQ-2401.'),
                const SizedBox(height: MoolSpacing.md),
                const TextField(
                  key: Key('provider-message-text'),
                  decoration: InputDecoration(
                    hintText: 'Write a service update',
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('provider-message-send'),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Send Update'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _privacySheet(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('provider-privacy-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy for this service',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: MoolSpacing.sm),
            const Text(
              'Only the location, time, service scope and payment state required to complete this request are visible. Private records from other provider types remain separate.',
            ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('provider-privacy-close'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Understood'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ProviderBusinessScreen extends StatelessWidget {
  const ProviderBusinessScreen({required this.session, super.key});

  final OperationsSession session;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => OperationsPageScaffold(
      session: session,
      title: 'Money and Records',
      subtitle: 'Ravi Home Services · trace every amount',
      activeDock: 'money',
      returnRoute: '/app/provider',
      provider: true,
      trailing: IconButton.outlined(
        key: const Key('provider-export-open'),
        tooltip: 'Export records',
        onPressed: () => _exportSheet(context),
        icon: const Icon(Icons.download_rounded),
      ),
      body: ListView(
        key: const Key('provider-business-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.xl,
        ),
        children: [
          const OpsCard(
            color: MoolColors.navy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AVAILABLE TO RECEIVE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '₹12,460',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '₹4,860 expected after 4 active outcomes',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const Row(
            children: [
              Expanded(
                child: OpsMetric(
                  label: 'THIS MONTH',
                  value: '₹38.4K',
                  detail: 'received',
                ),
              ),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: OpsMetric(
                  label: 'RETURNS',
                  value: '₹420',
                  detail: 'done',
                ),
              ),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: OpsMetric(
                  label: 'CUSTOMERS',
                  value: '86',
                  detail: 'served',
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          _ProviderSegments<ProviderBusinessTab>(
            values: ProviderBusinessTab.values,
            selected: session.businessTab,
            keyPrefix: 'provider-business-tab',
            label: (value) => switch (value) {
              ProviderBusinessTab.payments => 'Payments',
              ProviderBusinessTab.customers => 'Customers',
              ProviderBusinessTab.receipts => 'Receipts',
              ProviderBusinessTab.refunds => 'Returns',
            },
            onSelect: session.setBusinessTab,
          ),
          const SizedBox(height: MoolSpacing.md),
          const OpsSectionTitle(
            title: 'Recent records',
            detail: 'Source-linked money',
          ),
          const SizedBox(height: MoolSpacing.sm),
          ...const [
            (
              'payment-2401',
              '₹850 · Priya Sharma',
              'RQ-2401 · completed',
              'Available',
            ),
            (
              'receipt-2941',
              'Receipt MS-2941',
              'Tax and provider details',
              'Download',
            ),
            (
              'expected-2402',
              '₹1,250 · Aarav Mehta',
              'Active request · terms locked',
              'Expected',
            ),
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
              child: OpsActionRow(
                keyName: 'provider-business-${item.$1}',
                icon: Icons.receipt_long_outlined,
                title: item.$2,
                detail: item.$3,
                meta: item.$4,
                action: 'Open',
                onTap: () => _recordSheet(context, item),
              ),
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          const OpsCard(
            color: Color(0xFFF4F3FF),
            child: Text(
              'Customer reminders require consent. Private or regulated records remain outside this commercial money view.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _recordSheet(
    BuildContext context,
    (String, String, String, String) item,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('provider-business-record-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.$2,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            Text(item.$3),
            const SizedBox(height: MoolSpacing.md),
            OpsCard(
              color: const Color(0xFFF4F3FF),
              child: Column(
                children: [
                  OpsFact(label: 'Status', value: item.$4),
                  const OpsFact(label: 'Request', value: 'RQ-2401'),
                  const OpsFact(label: 'Customer payment', value: 'Protected'),
                  const OpsFact(label: 'Receipt', value: 'Ready'),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('provider-business-record-close'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _exportSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.md),
          child: Column(
            key: const Key('provider-export-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Export records',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),
              const Text('Choose an authorized record type.'),
              const SizedBox(height: MoolSpacing.md),
              Wrap(
                spacing: MoolSpacing.xs,
                runSpacing: MoolSpacing.xs,
                children: ['Statement', 'Receipts', 'GST summary']
                    .map(
                      (value) => ChoiceChip(
                        key: Key(
                          'provider-export-${value.toLowerCase().replaceAll(' ', '-')}',
                        ),
                        label: Text(value),
                        selected: session.exportType == value,
                        onSelected: (_) => session.setExportType(value),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: MoolSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('provider-export-generate'),
                  onPressed: session.busy ? null : session.exportRecords,
                  child: Text(
                    session.exportId == null
                        ? 'Generate Secure File'
                        : 'File Ready',
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: const Key('provider-export-close'),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ProviderGrowthScreen extends StatelessWidget {
  const ProviderGrowthScreen({required this.session, super.key});

  final OperationsSession session;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => OperationsPageScaffold(
      session: session,
      title: 'Earn and Grow',
      subtitle: 'Earn from funded work or buy verified growth',
      activeDock: 'requests',
      returnRoute: '/app/provider',
      provider: true,
      trailing: IconButton.outlined(
        key: const Key('provider-growth-filter'),
        tooltip: 'Filter opportunities',
        onPressed: () => _filterSheet(context),
        icon: const Icon(Icons.tune_rounded),
      ),
      body: ListView(
        key: const Key('provider-growth-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.xl,
        ),
        children: [
          const OpsCard(
            color: MoolColors.navy,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MATCHED MONTHLY POTENTIAL',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '₹16,000–₹42,000',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Open funded capacity · not guaranteed income',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                OpsPill(label: '24 OPEN', color: MoolColors.orange),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          _ProviderSegments<ProviderGrowthTab>(
            values: ProviderGrowthTab.values,
            selected: session.growthTab,
            keyPrefix: 'provider-growth-tab',
            label: (value) => switch (value) {
              ProviderGrowthTab.bestMatch => 'Best Match',
              ProviderGrowthTab.earn => 'Earn',
              ProviderGrowthTab.promote => 'Promote',
              ProviderGrowthTab.nearby => 'Nearby',
            },
            onSelect: session.setGrowthTab,
          ),
          const SizedBox(height: MoolSpacing.md),
          _GrowthCard(
            keyName: 'provider-growth-serve',
            source: 'MOOLSOCIAL FUNDED · 94% FIT',
            title: 'Serve verified nearby demand',
            status: '18 open',
            facts: const [
              ('PAYOUT', '₹650 / outcome'),
              ('AREA', 'Jodhpur'),
              ('PROOF', 'Completed request'),
            ],
            onOpen: () {
              session.selectGrowth('serve');
              _termsSheet(context, campaign: false);
            },
          ),
          const SizedBox(height: MoolSpacing.sm),
          _GrowthCard(
            keyName: 'provider-growth-campaign',
            source: 'YOUR BUSINESS PAYS · CONTROLLED BUDGET',
            title: 'New customer activation campaign',
            status: '6 days',
            facts: const [
              ('BUDGET', '₹8,000'),
              ('OUTCOME', '20 orders'),
              ('CHARGE', 'Success based'),
            ],
            onOpen: () {
              session.selectGrowth('campaign');
              _termsSheet(context, campaign: true);
            },
          ),
          const SizedBox(height: MoolSpacing.sm),
          const OpsCard(
            color: Color(0xFFF4F3FF),
            child: Text(
              'Earn cards pay you for completed work. Growth cards use your approved business budget to acquire verified customer outcomes. MoolSocial measures attribution and completion.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _filterSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('provider-growth-filter-sheet'),
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProviderSegments<ProviderGrowthTab>(
              values: ProviderGrowthTab.values,
              selected: session.growthTab,
              keyPrefix: 'provider-growth-filter-tab',
              label: (value) => switch (value) {
                ProviderGrowthTab.bestMatch => 'Best Match',
                ProviderGrowthTab.earn => 'Earn',
                ProviderGrowthTab.promote => 'Promote',
                ProviderGrowthTab.nearby => 'Nearby',
              },
              onSelect: session.setGrowthTab,
            ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('provider-growth-filter-close'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Show Opportunities'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _termsSheet(
    BuildContext context, {
    required bool campaign,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.md),
          child: SingleChildScrollView(
            child: Column(
              key: const Key('provider-growth-terms-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign
                      ? 'Buy a customer growth campaign'
                      : 'Accept funded service work',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  campaign
                      ? 'Review the outcome, maximum business budget, charging point and expiry before submitting.'
                      : 'Review the output, capacity, payout and expiry before accepting.',
                ),
                const SizedBox(height: MoolSpacing.md),
                OpsCard(
                  color: const Color(0xFFF4F3FF),
                  child: Column(
                    children: [
                      OpsFact(
                        label: campaign ? 'Outcome' : 'Output',
                        value: campaign
                            ? '20 paid orders'
                            : 'Verified completed service',
                      ),
                      OpsFact(
                        label: campaign ? 'Budget' : 'Payout',
                        value: campaign ? '₹8,000 maximum' : '₹650 / outcome',
                      ),
                      const OpsFact(label: 'Review', value: 'Within 24 hours'),
                      OpsFact(
                        label: campaign ? 'Charging point' : 'Funding',
                        value: campaign
                            ? 'Only after final confirmation'
                            : 'Payout reserved for you',
                      ),
                      const OpsFact(
                        label: 'Expiry',
                        value: 'Shown before start',
                      ),
                    ],
                  ),
                ),
                CheckboxListTile(
                  key: const Key('provider-growth-terms'),
                  contentPadding: EdgeInsets.zero,
                  value: session.growthTermsAccepted,
                  onChanged: (value) =>
                      session.confirmGrowthTerms(value ?? false),
                  title: Text(
                    campaign
                        ? 'I reviewed the outcome, maximum budget, charging point and expiry'
                        : 'I reviewed the output, proof, payout and expiry',
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('provider-growth-accept'),
                    onPressed: session.busy ? null : session.acceptGrowth,
                    child: Text(
                      session.growthAcceptanceId == null
                          ? campaign
                                ? 'Submit Growth Campaign'
                                : 'Accept Funded Work'
                          : campaign
                          ? 'Campaign Submitted'
                          : 'Funded Work Accepted',
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('provider-growth-close'),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Close'),
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

class ProviderControlScreen extends StatelessWidget {
  const ProviderControlScreen({required this.session, super.key});

  final OperationsSession session;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => OperationsPageScaffold(
      session: session,
      title: 'Workspace Controls',
      subtitle: 'Readiness, people, alerts and support',
      activeDock: 'services',
      returnRoute: '/app/provider',
      provider: true,
      trailing: IconButton.outlined(
        key: const Key('provider-control-help'),
        tooltip: 'Open workspace support',
        onPressed: () => _supportSheet(context),
        icon: const Icon(Icons.help_outline_rounded),
      ),
      bottomAction: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const Key('provider-control-support'),
              onPressed: () => _supportSheet(context),
              child: const Text('Get Support'),
            ),
          ),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: FilledButton(
              key: const Key('provider-control-save'),
              onPressed: session.busy ? null : session.saveControls,
              child: Text(
                session.controlsVersionId == null ? 'Save Controls' : 'Saved',
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        key: const Key('provider-control-screen'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.md,
          MoolSpacing.xl,
        ),
        children: [
          const OpsCard(
            color: MoolColors.navy,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WORKSPACE READINESS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '82% complete',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'One service document needs review',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                OpsPill(label: '82%', color: MoolColors.orange),
              ],
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          const OpsSectionTitle(
            title: 'Readiness',
            detail: 'What is needed to operate',
          ),
          const SizedBox(height: MoolSpacing.sm),
          _ControlOwner(
            keyName: 'provider-control-identity',
            icon: Icons.badge_outlined,
            title: 'Identity verified',
            detail: 'Primary contact and payout identity match',
            status: 'Complete',
            onTap: () => _controlSheet(context, 'Identity', 'Verified'),
          ),
          _ControlOwner(
            keyName: 'provider-control-document',
            icon: Icons.description_outlined,
            title: 'Service readiness',
            detail: 'One profile-specific document needs review',
            status: 'Action needed',
            onTap: () => _controlSheet(context, 'Service readiness', '1 item'),
          ),
          _ControlOwner(
            keyName: 'provider-control-payment',
            icon: Icons.account_balance_outlined,
            title: 'Payment account ready',
            detail: 'Settlement name verified',
            status: 'Complete',
            onTap: () => _controlSheet(context, 'Payment account', 'Ready'),
          ),
          const SizedBox(height: MoolSpacing.md),
          const OpsSectionTitle(
            title: 'People and access',
            detail: 'Only what each role needs',
          ),
          const SizedBox(height: MoolSpacing.sm),
          _ControlOwner(
            keyName: 'provider-control-owner',
            icon: Icons.admin_panel_settings_outlined,
            title: 'Owner',
            detail: 'All workspace controls · 1 person',
            status: 'Full access',
            onTap: () => _controlSheet(context, 'Owner access', '1 person'),
          ),
          _ControlOwner(
            keyName: 'provider-control-operations',
            icon: Icons.engineering_outlined,
            title: 'Operations staff',
            detail: 'Requests and fulfilment only · 2 people',
            status: 'Limited',
            onTap: () =>
                _controlSheet(context, 'Operations access', '2 people'),
          ),
          _ControlOwner(
            keyName: 'provider-control-accounts',
            icon: Icons.receipt_long_outlined,
            title: 'Accounts',
            detail: 'Payments and receipts · no private records',
            status: 'Limited',
            onTap: () => _controlSheet(context, 'Accounts access', '1 person'),
          ),
          const SizedBox(height: MoolSpacing.md),
          const OpsSectionTitle(
            title: 'Workspace behavior',
            detail: 'Save together',
          ),
          const SizedBox(height: MoolSpacing.sm),
          _ControlToggle(
            keyName: 'provider-toggle-alerts',
            title: 'Priority request alerts',
            detail: 'Push, SMS fallback and Chat',
            value: session.priorityAlerts,
            onChanged: (_) => session.toggleControl('alerts'),
          ),
          _ControlToggle(
            keyName: 'provider-toggle-capacity',
            title: 'Auto-pause at capacity',
            detail: 'Prevents false availability',
            value: session.autoPauseAtCapacity,
            onChanged: (_) => session.toggleControl('capacity'),
          ),
          _ControlToggle(
            keyName: 'provider-toggle-reminders',
            title: 'Customer reminders',
            detail: 'Consent and purpose controlled',
            value: session.customerReminders,
            onChanged: (_) => session.toggleControl('reminders'),
          ),
          if (session.controlsVersionId == null)
            const Padding(
              padding: EdgeInsets.only(top: MoolSpacing.xs),
              child: Text(
                'Changes are not saved yet.',
                style: TextStyle(
                  color: Color(0xFFB05C00),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Future<void> _controlSheet(
    BuildContext context,
    String title,
    String status,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('provider-control-detail-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: MoolSpacing.md),
            OpsCard(
              color: const Color(0xFFF4F3FF),
              child: Column(
                children: [
                  OpsFact(label: 'Current status', value: status),
                  const OpsFact(label: 'Last confirmed', value: 'Today'),
                  const OpsFact(
                    label: 'Private records',
                    value: 'Only permitted roles',
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('provider-control-detail-close'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _supportSheet(
    BuildContext context,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.md,
            MoolSpacing.md,
            MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.md,
          ),
          child: SingleChildScrollView(
            child: Column(
              key: const Key('provider-support-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workspace support',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const Text(
                  'Describe the access, readiness, payment or capacity issue.',
                ),
                const SizedBox(height: MoolSpacing.md),
                DropdownButtonFormField<String>(
                  key: const Key('provider-support-category'),
                  initialValue: session.providerSupportCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items:
                      const [
                            'Access and staff',
                            'Readiness document',
                            'Payment account',
                            'Alerts and capacity',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) =>
                      session.setProviderSupportCategory(value!),
                ),
                const SizedBox(height: MoolSpacing.sm),
                TextField(
                  key: const Key('provider-support-details'),
                  minLines: 3,
                  maxLines: 4,
                  onChanged: session.updateProviderSupportDetails,
                  decoration: const InputDecoration(
                    labelText: 'What needs to be checked?',
                  ),
                ),
                const SizedBox(height: MoolSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('provider-support-submit'),
                    onPressed: session.busy
                        ? null
                        : session.openProviderSupport,
                    child: Text(
                      session.providerSupportId == null
                          ? 'Open Support Case'
                          : 'Case SUP-146-2048 Opened',
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    key: const Key('provider-support-close'),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Close'),
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

class _ProviderSegments<T> extends StatelessWidget {
  const _ProviderSegments({
    required this.values,
    required this.selected,
    required this.keyPrefix,
    required this.label,
    required this.onSelect,
  });

  final List<T> values;
  final T selected;
  final String keyPrefix;
  final String Function(T) label;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: values
          .map(
            (value) => Padding(
              padding: const EdgeInsets.only(right: MoolSpacing.xs),
              child: MoolSegment(
                key: Key('$keyPrefix-${(value as Enum).name}'),
                label: label(value),
                selected: value == selected,
                onPressed: () => onSelect(value),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _HomeOwnerCard extends StatelessWidget {
  const _HomeOwnerCard({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.detail,
    required this.status,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String detail;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
    child: OpsActionRow(
      keyName: keyName,
      icon: icon,
      title: title,
      detail: detail,
      meta: status,
      action: 'Open',
      onTap: onTap,
    ),
  );
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.keyName,
    required this.title,
    required this.price,
    required this.time,
    required this.detail,
    required this.onEdit,
    required this.onPreview,
  });

  final String keyName;
  final String title;
  final String price;
  final String time;
  final String detail;
  final VoidCallback onEdit;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) => OpsCard(
    keyName: keyName,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LIVE · CUSTOMER READY',
          style: TextStyle(
            color: MoolColors.success,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        Text(detail, style: const TextStyle(color: MoolColors.muted)),
        const SizedBox(height: MoolSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ProviderFact(label: 'PRICE', value: price),
            ),
            Expanded(
              child: _ProviderFact(label: 'TIME', value: time),
            ),
            const Expanded(
              child: _ProviderFact(label: 'MODE', value: 'At location'),
            ),
          ],
        ),
        const SizedBox(height: MoolSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: Key('$keyName-edit'),
                onPressed: onEdit,
                child: const Text('Edit'),
              ),
            ),
            const SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: FilledButton(
                key: Key('$keyName-preview'),
                onPressed: onPreview,
                child: const Text('Preview'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.keyName,
    required this.title,
    required this.price,
    required this.urgency,
    required this.time,
    required this.place,
    required this.onAccept,
    required this.onDecline,
  });

  final String keyName;
  final String title;
  final String price;
  final String urgency;
  final String time;
  final String place;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) => OpsCard(
    keyName: keyName,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          urgency.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFFB05C00),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            OpsPill(label: price),
          ],
        ),
        const SizedBox(height: MoolSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ProviderFact(label: 'WHEN', value: time),
            ),
            Expanded(
              child: _ProviderFact(label: 'WHERE', value: place),
            ),
            const Expanded(
              child: _ProviderFact(label: 'PAYMENT', value: 'Protected'),
            ),
          ],
        ),
        const SizedBox(height: MoolSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: Key('$keyName-decline'),
                onPressed: onDecline,
                child: const Text('Cannot Take'),
              ),
            ),
            const SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: FilledButton(
                key: Key('$keyName-accept'),
                onPressed: onAccept,
                child: const Text('Review & Accept'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _GrowthCard extends StatelessWidget {
  const _GrowthCard({
    required this.keyName,
    required this.source,
    required this.title,
    required this.status,
    required this.facts,
    required this.onOpen,
  });

  final String keyName;
  final String source;
  final String title;
  final String status;
  final List<(String, String)> facts;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => OpsCard(
    keyName: keyName,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source,
                    style: const TextStyle(
                      color: MoolColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            OpsPill(label: status, color: const Color(0xFFB05C00)),
          ],
        ),
        const SizedBox(height: MoolSpacing.sm),
        Row(
          children: facts
              .map(
                (fact) => Expanded(
                  child: _ProviderFact(label: fact.$1, value: fact.$2),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: MoolSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: Key('$keyName-review'),
            onPressed: onOpen,
            child: const Text('Review Terms'),
          ),
        ),
      ],
    ),
  );
}

class _ControlOwner extends StatelessWidget {
  const _ControlOwner({
    required this.keyName,
    required this.icon,
    required this.title,
    required this.detail,
    required this.status,
    required this.onTap,
  });

  final String keyName;
  final IconData icon;
  final String title;
  final String detail;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
    child: OpsActionRow(
      keyName: keyName,
      icon: icon,
      title: title,
      detail: detail,
      meta: status,
      action: 'Open',
      onTap: onTap,
    ),
  );
}

class _ControlToggle extends StatelessWidget {
  const _ControlToggle({
    required this.keyName,
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final String keyName;
  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
    child: OpsCard(
      child: SwitchListTile(
        key: Key(keyName),
        contentPadding: EdgeInsets.zero,
        value: value,
        onChanged: onChanged,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(detail),
      ),
    ),
  );
}

class _ProviderFact extends StatelessWidget {
  const _ProviderFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: MoolSpacing.xs),
    decoration: const BoxDecoration(
      border: Border(left: BorderSide(color: MoolColors.orange, width: 2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: MoolColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
