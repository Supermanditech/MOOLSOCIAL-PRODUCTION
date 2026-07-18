import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../ride_models.dart';
import '../ride_session.dart';
import '../widgets/ride_widgets.dart';

class RideSupportScreen extends StatefulWidget {
  const RideSupportScreen({
    required this.session,
    required this.tripId,
    super.key,
  });

  final RideSession session;
  final String tripId;

  @override
  State<RideSupportScreen> createState() => _RideSupportScreenState();
}

class _RideSupportScreenState extends State<RideSupportScreen> {
  late final TextEditingController _detailController;

  RideSession get session => widget.session;

  @override
  void initState() {
    super.initState();
    session.clearMessages();
    _detailController = TextEditingController();
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await session.submitSupport(_detailController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => RidePageScaffold(
        session: session,
        title: 'Ride help',
        subtitle: 'Trip, route and receipt evidence attached',
        activeDock: 'help',
        fallbackBackRoute: '/app/ride/trip/${widget.tripId}',
        bottomAction: FilledButton.icon(
          key: const Key('ride-submit-support'),
          onPressed: session.busy || session.trip == null ? null : _submit,
          icon: session.busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.support_agent_rounded),
          label: Text(
            session.busy
                ? 'Creating request…'
                : session.supportTicket == null
                ? session.issueType.action
                : 'Request ${session.supportTicket!.id} is open',
          ),
        ),
        body: ListView(
          key: const Key('ride-support-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.lg,
          ),
          children: [
            const RideCard(
              color: Color(0xFFFFF5E9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.search_rounded, color: MoolColors.orange),
                  SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Check your belongings first',
                          style: TextStyle(
                            color: MoolColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Check pockets, seat area and bags before reporting a missing item.',
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
            ),
            const SizedBox(height: MoolSpacing.md),
            const RideSectionTitle('What do you need help with?'),
            const SizedBox(height: MoolSpacing.xs),
            Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: [
                for (final issue in RideIssueType.values)
                  MoolSegment(
                    key: Key('ride-issue-${issue.name}'),
                    label: issue.label,
                    selected: session.issueType == issue,
                    onPressed: () => session.chooseIssue(issue),
                  ),
              ],
            ),
            if (session.issueType == RideIssueType.missingItem) ...[
              const SizedBox(height: MoolSpacing.md),
              const RideSectionTitle('Which item is missing?'),
              const SizedBox(height: MoolSpacing.xs),
              Wrap(
                spacing: MoolSpacing.xs,
                runSpacing: MoolSpacing.xs,
                children: [
                  for (final item in const ['Phone', 'Wallet', 'Bag', 'Keys'])
                    MoolSegment(
                      key: Key('ride-missing-${item.toLowerCase()}'),
                      label: item,
                      selected: session.missingItem == item,
                      onPressed: () => session.chooseMissingItem(item),
                    ),
                ],
              ),
            ],
            const SizedBox(height: MoolSpacing.md),
            TextField(
              key: const Key('ride-support-detail'),
              controller: _detailController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: session.issueType == RideIssueType.missingItem
                    ? 'More detail (optional)'
                    : 'Tell us what happened',
                hintText: session.issueType == RideIssueType.safety
                    ? 'Describe the concern and where it happened'
                    : 'Add a short, clear detail',
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            const RideSectionTitle('Evidence ready'),
            const SizedBox(height: MoolSpacing.xs),
            RideCard(
              child: Column(
                children: [
                  _EvidenceRow(
                    icon: Icons.receipt_long_outlined,
                    title: 'Receipt',
                    detail: widget.tripId,
                  ),
                  const Divider(),
                  const _EvidenceRow(
                    icon: Icons.route_outlined,
                    title: 'Route',
                    detail: 'Pickup, destination and route history',
                  ),
                  const Divider(),
                  const _EvidenceRow(
                    icon: Icons.badge_outlined,
                    title: 'Captain',
                    detail: 'Arjun Singh · RJ19 AB 2841',
                  ),
                ],
              ),
            ),
            if (session.supportTicket != null) ...[
              const SizedBox(height: MoolSpacing.md),
              RideCard(
                key: const Key('ride-support-confirmation'),
                color: const Color(0xFFF0F8EF),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: MoolColors.success,
                        ),
                        SizedBox(width: MoolSpacing.xs),
                        Expanded(
                          child: Text(
                            'Support request created',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF155B17),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    Text(
                      '${session.supportTicket!.id} · ${session.issueType.label}',
                      style: const TextStyle(
                        color: Color(0xFF155B17),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const Key('ride-track-support'),
                        onPressed: () => session.showNotice(
                          '${session.supportTicket!.id} is assigned to Ride Support.',
                        ),
                        icon: const Icon(Icons.track_changes_rounded),
                        label: const Text('Track request'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: MoolSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('ride-support-chat'),
                    onPressed: () => context.go(
                      '/app/chat/thread/ride-support?return=/app/ride/trip/${widget.tripId}/support',
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Support chat'),
                  ),
                ),
                const SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('ride-urgent-safety'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB42318),
                    ),
                    onPressed: () => session.showNotice(
                      'Connecting to urgent safety assistance…',
                    ),
                    icon: const Icon(Icons.emergency_outlined),
                    label: const Text('Urgent safety'),
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

class _EvidenceRow extends StatelessWidget {
  const _EvidenceRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: MoolColors.navy),
        const SizedBox(width: MoolSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
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
        const Icon(Icons.check_circle_rounded, color: MoolColors.success),
      ],
    );
  }
}
