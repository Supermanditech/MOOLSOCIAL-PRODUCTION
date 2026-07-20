import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../book_models.dart';
import '../book_session.dart';
import '../widgets/book_widgets.dart';

class TaskCreateScreen extends StatefulWidget {
  const TaskCreateScreen({required this.session, super.key});

  final BookSession session;

  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  late final TextEditingController _detailController = TextEditingController(
    text: widget.session.taskDetail,
  );

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
        title: 'Get It Done',
        subtitle: 'Verified help · proof before payment',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            const BookSectionTitle('Task city'),
            const SizedBox(height: MoolSpacing.sm),
            Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: const ['Jodhpur', 'Delhi', 'Mumbai', 'Chennai']
                  .map(
                    (city) => MoolSegment(
                      key: Key('task-city-${city.toLowerCase()}'),
                      label: city,
                      selected: session.taskCity == city,
                      onPressed: () => session.chooseTaskCity(city),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('Choose task'),
            const SizedBox(height: MoolSpacing.sm),
            Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: TaskType.values
                  .map(
                    (type) => MoolSegment(
                      key: Key('task-type-${type.name}'),
                      label: type.label,
                      selected: session.taskType == type,
                      onPressed: () => session.chooseTaskType(type),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle(
              'Exact place and instruction',
              detail: 'Required',
            ),
            const SizedBox(height: MoolSpacing.sm),
            TextField(
              key: const Key('task-detail'),
              controller: _detailController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'What should the helper do?',
                hintText:
                    'Visit Mahadev counter, collect parcel and send a clear photo',
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            OutlinedButton(
              key: const Key('save-task-detail'),
              onPressed: () => session.saveTaskDetail(_detailController.text),
              child: const Text('Save task detail'),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookCard(
              color: Color(0xFFF4F3FF),
              child: Column(
                children: [
                  BookFact(
                    icon: Icons.verified_user_outlined,
                    title: 'Verified helper',
                    detail: 'ID, rating and completed-task history shown.',
                  ),
                  Divider(height: 24),
                  BookFact(
                    icon: Icons.photo_camera_outlined,
                    title: 'Photo and bill required',
                    detail:
                        'You review proof before any protected money is released.',
                  ),
                  Divider(height: 24),
                  BookFact(
                    icon: Icons.schedule_outlined,
                    title: '₹99 fee · 60 minute target',
                    detail: 'Spend limit and total protected hold appear next.',
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomAction: FilledButton(
          key: const Key('review-task'),
          onPressed: () {
            if (session.saveTaskDetail(_detailController.text)) {
              context.go('/app/book/task/review');
            }
          },
          child: const Text('Review task'),
        ),
      ),
    );
  }
}

class TaskReviewScreen extends StatelessWidget {
  const TaskReviewScreen({required this.session, super.key});

  final BookSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Review task',
        subtitle: 'Fee, spend limit and protected hold',
        fallbackBackRoute: '/app/book/task',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            _TaskProgress(step: 2),
            const SizedBox(height: MoolSpacing.lg),
            BookCard(
              child: Column(
                children: [
                  BookFact(
                    icon: Icons.task_alt_rounded,
                    title: session.taskType.label,
                    detail: '${session.taskCity} · ${session.taskDetail}',
                  ),
                  const Divider(height: 24),
                  BookFact(
                    icon: Icons.person_search_outlined,
                    title: '${bookMoney(session.taskFee)} helper fee',
                    detail: 'Paid after completion and accepted proof.',
                  ),
                  const Divider(height: 24),
                  BookFact(
                    icon: Icons.account_balance_wallet_outlined,
                    title:
                        '${bookMoney(session.taskSpendLimit)} task spend limit',
                    detail:
                        'The helper cannot cross this approved amount without asking.',
                  ),
                  const Divider(height: 24),
                  BookFact(
                    icon: Icons.lock_outline_rounded,
                    title:
                        '${bookMoney(session.taskHeldAmount)} total protected hold',
                    detail: 'Unused task spend returns automatically.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('Payment method'),
            const SizedBox(height: MoolSpacing.sm),
            Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: TaskPayment.values
                  .map(
                    (payment) => MoolSegment(
                      key: Key('task-payment-${payment.name}'),
                      label: payment.label,
                      selected: session.taskPayment == payment,
                      onPressed: () => session.chooseTaskPayment(payment),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookCard(
              color: Color(0xFFF4F3FF),
              child: BookFact(
                icon: Icons.add_a_photo_outlined,
                title: 'Photo proof before release',
                detail:
                    'Payment remains protected until you accept the photo and bill.',
              ),
            ),
          ],
        ),
        bottomAction: FilledButton(
          key: const Key('confirm-task'),
          onPressed: session.busy
              ? null
              : () async {
                  final ok = await session.confirmTask();
                  if (ok && context.mounted) {
                    context.go('/app/book/task/live');
                  }
                },
          child: Text(
            session.busy
                ? 'Finding verified help…'
                : 'Confirm task & protect ${bookMoney(session.taskHeldAmount)}',
          ),
        ),
      ),
    );
  }
}

class TaskLiveScreen extends StatelessWidget {
  const TaskLiveScreen({required this.session, super.key});

  final BookSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Live task',
        subtitle: 'Helper accepted · payment protected',
        activeDock: 'activity',
        fallbackBackRoute: '/app/book/task/review',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            _TaskProgress(step: 3),
            const SizedBox(height: MoolSpacing.lg),
            BookCard(
              color: const Color(0xFFEAF7E8),
              child: Column(
                children: [
                  const BookFact(
                    icon: Icons.verified_user_rounded,
                    title: 'Ramesh Kumar accepted',
                    detail: 'ID verified · 4.8 rating · 620 completed tasks',
                  ),
                  const Divider(height: 24),
                  BookFact(
                    icon: Icons.route_outlined,
                    title: 'Going to the counter · 18 min',
                    detail:
                        '${session.taskCity} · live status remains in task chat',
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('task-live-chat'),
                    onPressed: () => context.go(
                      Uri(
                        path: '/app/chat/thread/task-helper',
                        queryParameters: {'return': '/app/book/task/live'},
                      ).toString(),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Chat'),
                  ),
                ),
                const SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('task-live-call'),
                    onPressed: () =>
                        session.showNotice('Calling Ramesh securely…'),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('task-live-share'),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              'https://moolsocial.com/task/${session.task?.id ?? 'active'}',
                        ),
                      );
                      session.showNotice('Live task link copied.');
                    },
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.lg),
            BookCard(
              child: Column(
                children: [
                  BookFact(
                    icon: Icons.lock_outline_rounded,
                    title:
                        '${bookMoney(session.taskHeldAmount)} remains protected',
                    detail: 'The ₹500 spend cap is active.',
                  ),
                  const Divider(height: 24),
                  const BookFact(
                    icon: Icons.photo_camera_outlined,
                    title: 'Photo proof and bill pending',
                    detail:
                        'You approve, ask again or open support before release.',
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomAction: FilledButton(
          key: const Key('task-proof-arrived'),
          onPressed: () {
            session.receiveTaskProof();
            context.go('/app/book/task/proof');
          },
          child: const Text('Review received proof'),
        ),
      ),
    );
  }
}

class TaskProofScreen extends StatelessWidget {
  const TaskProofScreen({required this.session, super.key});

  final BookSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Review proof',
        subtitle: 'Release only if the task is correct',
        activeDock: 'activity',
        fallbackBackRoute: '/app/book/task/live',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            _TaskProgress(step: 4),
            const SizedBox(height: MoolSpacing.lg),
            BookCard(
              color: const Color(0xFFF4F3FF),
              child: Column(
                children: [
                  const BookFact(
                    icon: Icons.photo_outlined,
                    title: 'Counter photo uploaded',
                    detail:
                        'Mahadev counter · parcel and counter board visible',
                  ),
                  const Divider(height: 24),
                  const BookFact(
                    icon: Icons.receipt_long_outlined,
                    title: '₹420 counter bill saved',
                    detail: 'Bill stays linked to this task and support.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            BookCard(
              child: Column(
                children: [
                  BookFact(
                    icon: Icons.lock_open_outlined,
                    title:
                        '${bookMoney(session.taskReleaseAmount)} will release',
                    detail: '₹99 helper fee + ₹420 actual task spend',
                  ),
                  const Divider(height: 24),
                  BookFact(
                    icon: Icons.keyboard_return_rounded,
                    title: '${bookMoney(session.taskReturnAmount)} returns',
                    detail: 'Unused protected task spend',
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            OutlinedButton.icon(
              key: const Key('ask-clearer-proof'),
              onPressed: () {
                session.askForClearerProof();
                context.go('/app/book/task/live');
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Ask for clearer proof'),
            ),
            const SizedBox(height: MoolSpacing.xs),
            OutlinedButton.icon(
              key: const Key('report-task-issue'),
              onPressed: () => context.go('/app/book/task/support'),
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Report an issue · keep money protected'),
            ),
          ],
        ),
        bottomAction: FilledButton(
          key: const Key('release-task-payment'),
          onPressed: session.busy
              ? null
              : () async {
                  final ok = await session.releaseTaskPayment();
                  if (ok && context.mounted) {
                    context.go('/app/book/task/completed');
                  }
                },
          child: Text(
            session.busy
                ? 'Confirming release…'
                : 'Release ${bookMoney(session.taskReleaseAmount)}',
          ),
        ),
      ),
    );
  }
}

class TaskCompletedScreen extends StatelessWidget {
  const TaskCompletedScreen({required this.session, super.key});

  final BookSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Task completed',
        subtitle: 'Receipt and proof saved',
        activeDock: 'activity',
        fallbackBackRoute: '/app/book/task/proof',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            BookCard(
              color: const Color(0xFFEAF7E8),
              child: Column(
                children: [
                  BookFact(
                    icon: Icons.check_circle_rounded,
                    title: '${bookMoney(session.taskReleaseAmount)} released',
                    detail: 'Helper fee and accepted task spend',
                  ),
                  const Divider(height: 24),
                  BookFact(
                    icon: Icons.keyboard_return_rounded,
                    title: '${bookMoney(session.taskReturnAmount)} returned',
                    detail: 'Unused protected amount returned automatically',
                  ),
                  const Divider(height: 24),
                  const BookFact(
                    icon: Icons.folder_copy_outlined,
                    title: 'Photo, bill and receipt saved',
                    detail: 'Available later for repeat task or support.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('Rate Ramesh', detail: 'Optional'),
            const SizedBox(height: MoolSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                5,
                (index) => IconButton.filledTonal(
                  key: Key('task-rating-${index + 1}'),
                  tooltip: '${index + 1} stars',
                  onPressed: () => session.setTaskRating(index + 1),
                  icon: Icon(
                    index < session.taskRating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            OutlinedButton.icon(
              key: const Key('save-helper'),
              onPressed: session.saveHelper,
              icon: Icon(
                session.helperSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
              label: Text(session.helperSaved ? 'Ramesh saved' : 'Save helper'),
            ),
            const SizedBox(height: MoolSpacing.xs),
            OutlinedButton.icon(
              key: const Key('task-share-receipt-proof'),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(
                    text:
                        'https://moolsocial.com/task/${session.task?.id ?? 'completed'}/receipt',
                  ),
                );
                session.showNotice('Receipt and proof link copied.');
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share receipt and proof'),
            ),
            const SizedBox(height: MoolSpacing.xs),
            OutlinedButton(
              onPressed: () => context.go('/app/book/task/support'),
              child: const Text('Get post-task help'),
            ),
          ],
        ),
        bottomAction: FilledButton(
          key: const Key('repeat-task'),
          onPressed: () {
            session.resetTask();
            context.go('/app/book/task');
          },
          child: const Text('Book this task again'),
        ),
      ),
    );
  }
}

class TaskSupportScreen extends StatefulWidget {
  const TaskSupportScreen({required this.session, super.key});

  final BookSession session;

  @override
  State<TaskSupportScreen> createState() => _TaskSupportScreenState();
}

class _TaskSupportScreenState extends State<TaskSupportScreen> {
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
        title: 'Task help',
        subtitle: 'Payment and saved evidence stay protected',
        activeDock: 'help',
        fallbackBackRoute: '/app/book/task/proof',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            BookCard(
              color: const Color(0xFFF4F3FF),
              child: BookFact(
                icon: Icons.lock_outline_rounded,
                title: session.taskReleased
                    ? 'Released payment under review'
                    : '${bookMoney(session.taskHeldAmount)} remains protected',
                detail:
                    'Proof, bill, spend limit and task chat are attached automatically.',
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('What happened?'),
            const SizedBox(height: MoolSpacing.sm),
            Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: TaskIssue.values
                  .map(
                    (issue) => MoolSegment(
                      key: Key('task-issue-${issue.name}'),
                      label: issue.label,
                      selected: session.taskIssue == issue,
                      onPressed: () => session.chooseTaskIssue(issue),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: MoolSpacing.sm),
            TextField(
              key: const Key('task-support-detail'),
              controller: _detailController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Add detail (optional)',
                hintText: 'Explain what the proof or saved bill does not show',
              ),
            ),
            if (session.taskSupportCase != null) ...[
              const SizedBox(height: MoolSpacing.sm),
              BookCard(
                color: const Color(0xFFEAF7E8),
                child: BookFact(
                  icon: Icons.support_agent_rounded,
                  title: 'Case ${session.taskSupportCase!.id} created',
                  detail:
                      '${bookMoney(session.taskHeldAmount)} protected · proof and chat attached',
                ),
              ),
            ],
          ],
        ),
        bottomAction: FilledButton(
          key: const Key('submit-task-support'),
          onPressed: session.busy
              ? null
              : () async {
                  final ok = await session.submitTaskSupport(
                    _detailController.text,
                  );
                  if (ok && context.mounted) {
                    context.go('/app/book/task/case');
                  }
                },
          child: Text(session.busy ? 'Attaching evidence…' : 'Submit issue'),
        ),
      ),
    );
  }
}

class TaskCaseScreen extends StatelessWidget {
  const TaskCaseScreen({required this.session, super.key});

  final BookSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Case in review',
        subtitle: 'Payment stays protected',
        activeDock: 'help',
        fallbackBackRoute: '/app/book/task/support',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            BookCard(
              color: const Color(0xFFF4F3FF),
              child: BookFact(
                icon: Icons.manage_search_rounded,
                title:
                    'Case ${session.taskSupportCase?.id ?? 'not created'} active',
                detail:
                    'Specialist response expected in 5–15 minutes · ${bookMoney(session.taskHeldAmount)} protected',
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('Review timeline'),
            const SizedBox(height: MoolSpacing.sm),
            const BookCard(
              child: Column(
                children: [
                  BookFact(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Report filed',
                    detail: 'Your selected issue and task are linked.',
                  ),
                  Divider(height: 24),
                  BookFact(
                    icon: Icons.attachment_rounded,
                    title: 'Evidence synced',
                    detail: 'Photo, bill, spend and chat are attached.',
                  ),
                  Divider(height: 24),
                  BookFact(
                    icon: Icons.fact_check_outlined,
                    title: 'Verification in progress',
                    detail: 'Support is comparing the proof with the task.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            OutlinedButton.icon(
              key: const Key('task-case-chat'),
              onPressed: () => context.go(
                Uri(
                  path: '/app/chat/thread/order-support',
                  queryParameters: {'return': '/app/book/task/case'},
                ).toString(),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Ask support'),
            ),
          ],
        ),
        bottomAction: FilledButton(
          key: const Key('view-task-decision'),
          onPressed: session.taskSupportCase == null
              ? null
              : () => context.go('/app/book/task/resolution'),
          child: const Text('View support decision'),
        ),
      ),
    );
  }
}

class TaskResolutionScreen extends StatelessWidget {
  const TaskResolutionScreen({required this.session, super.key});

  final BookSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Review resolution',
        subtitle: 'No money moves before your action',
        activeDock: 'help',
        fallbackBackRoute: '/app/book/task/case',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            const BookCard(
              color: Color(0xFFF4F3FF),
              child: BookFact(
                icon: Icons.verified_outlined,
                title: 'Refund recommended',
                detail:
                    'Support found the uploaded proof did not match the task instruction.',
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookSectionTitle('Choose resolution'),
            const SizedBox(height: MoolSpacing.sm),
            Wrap(
              spacing: MoolSpacing.xs,
              runSpacing: MoolSpacing.xs,
              children: TaskResolution.values
                  .map(
                    (resolution) => MoolSegment(
                      key: Key('task-resolution-${resolution.name}'),
                      label: resolution.label,
                      selected: session.taskResolution == resolution,
                      onPressed: () => session.chooseTaskResolution(resolution),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: MoolSpacing.lg),
            const BookCard(
              child: Column(
                children: [
                  BookFact(
                    icon: Icons.photo_outlined,
                    title: 'Proof compared',
                    detail: 'Helper photo checked against the task request.',
                  ),
                  Divider(height: 24),
                  BookFact(
                    icon: Icons.receipt_long_outlined,
                    title: 'Bill and chat reviewed',
                    detail:
                        'Spend cap, bill amount and instructions were verified.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            OutlinedButton.icon(
              key: const Key('task-resolution-chat'),
              onPressed: () => context.go(
                Uri(
                  path: '/app/chat/thread/order-support',
                  queryParameters: {'return': '/app/book/task/resolution'},
                ).toString(),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Ask support a question'),
            ),
          ],
        ),
        bottomAction: FilledButton(
          key: const Key('accept-task-resolution'),
          onPressed: session.busy
              ? null
              : () async {
                  final ok = await session.acceptTaskResolution();
                  if (ok && context.mounted) {
                    context.go('/app/book/task/resolution-complete');
                  }
                },
          child: Text(
            session.busy
                ? 'Confirming…'
                : 'Accept ${session.taskResolution.label.toLowerCase()}',
          ),
        ),
      ),
    );
  }
}

class TaskResolutionCompleteScreen extends StatelessWidget {
  const TaskResolutionCompleteScreen({required this.session, super.key});

  final BookSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => BookPageScaffold(
        session: session,
        title: 'Resolution complete',
        subtitle: 'Result, receipt and proof saved',
        activeDock: 'help',
        fallbackBackRoute: '/app/book/task/resolution',
        body: ListView(
          padding: const EdgeInsets.all(MoolSpacing.md),
          children: [
            BookCard(
              color: const Color(0xFFEAF7E8),
              child: BookFact(
                icon: Icons.task_alt_rounded,
                title: '${session.taskResolution.label} saved',
                detail:
                    '${bookMoney(session.taskHeldAmount)} · case, proof and payment record preserved',
              ),
            ),
            const SizedBox(height: MoolSpacing.lg),
            BookCard(
              child: Column(
                children: [
                  BookFact(
                    icon: Icons.payments_outlined,
                    title: _moneyAction(session.taskResolution),
                    detail: 'Track the final status from the saved receipt.',
                  ),
                  const Divider(height: 24),
                  const BookFact(
                    icon: Icons.folder_copy_outlined,
                    title: 'Proof and support trail saved',
                    detail:
                        'The case reason, decision and chat remain available.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            OutlinedButton.icon(
              key: const Key('track-task-resolution'),
              onPressed: () => context.go('/app/book/task/completed'),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('View receipt and status'),
            ),
          ],
        ),
        bottomAction: FilledButton(
          key: const Key('new-task-after-resolution'),
          onPressed: () {
            session.resetTask();
            context.go('/app/book/task');
          },
          child: const Text('Start a new task'),
        ),
      ),
    );
  }

  String _moneyAction(TaskResolution resolution) => switch (resolution) {
    TaskResolution.refund => 'Refund started to original payment method',
    TaskResolution.rework => 'Protected hold retained for rework',
    TaskResolution.adjustBill => 'Adjusted bill and return started',
    TaskResolution.closeCase => 'Accepted amount released and case closed',
  };
}

class _TaskProgress extends StatelessWidget {
  const _TaskProgress({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Task progress step $step of 4',
      child: Row(
        children: List.generate(
          4,
          (index) => Expanded(
            child: Container(
              height: 5,
              margin: EdgeInsets.only(right: index == 3 ? 0 : 5),
              decoration: BoxDecoration(
                color: index < step ? MoolColors.navy : MoolColors.line,
                borderRadius: BorderRadius.circular(MoolRadii.capsule),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
