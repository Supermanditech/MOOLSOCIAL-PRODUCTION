import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/design/mool_theme.dart';
import '../work_customer_feedback.dart';

class StoreCustomerFeedback extends StatefulWidget {
  const StoreCustomerFeedback({
    super.key,
    required this.controller,
    required this.onClose,
    this.orderId,
    this.onOpenOrder,
  });
  final StoreFeedbackController? controller;
  final VoidCallback onClose;
  final String? orderId;
  final ValueChanged<String>? onOpenOrder;

  @override
  State<StoreCustomerFeedback> createState() => _StoreCustomerFeedbackState();
}

class _StoreCustomerFeedbackState extends State<StoreCustomerFeedback> {
  StoreFeedbackKind _kind = StoreFeedbackKind.overallOrder;
  String? _selected;
  StoreFeedbackAction? _action;
  StoreFeedbackAudience? _audience;
  StoreFeedbackBinding? _editorBinding;
  Object _editorGeneration = Object();
  final _editor = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    widget.controller?.addListener(_changed);
    final controller = widget.controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(widget.controller, controller)) {
        unawaited(controller?.load());
      }
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant StoreCustomerFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller) ||
        oldWidget.orderId != widget.orderId) {
      oldWidget.controller?.removeListener(_changed);
      _selected = null;
      _action = null;
      _audience = null;
      _editor.clear();
      _editorBinding = null;
      _editorGeneration = Object();
      _listen();
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_changed);
    _editor.dispose();
    _scroll.dispose();
    super.dispose();
  }

  static String _label(StoreFeedbackKind kind) => switch (kind) {
    StoreFeedbackKind.overallOrder => 'Overall order',
    StoreFeedbackKind.storeService => 'Store service',
    StoreFeedbackKind.product => 'Product',
  };
  static String _audienceLabel(StoreFeedbackAudience audience) =>
      switch (audience) {
        StoreFeedbackAudience.public => 'Public',
        StoreFeedbackAudience.orderParticipants =>
          'Customer and participating Stores',
        StoreFeedbackAudience.storeAndCustomer => 'This Store and customer',
        StoreFeedbackAudience.moderation => 'MoolSocial moderation only',
      };

  void _edit(StoreFeedbackEntry entry, StoreFeedbackAction action) {
    final controller = widget.controller!;
    final binding = controller.bindingFor(entry.id);
    if (!controller.canAct(entry.id, action) ||
        binding == null ||
        binding.version != entry.version) {
      return;
    }
    setState(() {
      _editorBinding = binding;
      _editorGeneration = Object();
      _action = action;
      _audience = action == StoreFeedbackAction.report
          ? StoreFeedbackAudience.moderation
          : entry.replyAudiences.first;
      _editor.text = controller.draft(entry.id, action);
    });
  }

  Future<void> _send(StoreFeedbackEntry entry, Object generation) async {
    final controller = widget.controller;
    final action = _action, audience = _audience;
    final binding = _editorBinding;
    if (!identical(generation, _editorGeneration) ||
        controller == null ||
        action == null ||
        audience == null ||
        binding == null ||
        binding.reviewId != entry.id ||
        binding.version != entry.version) {
      return;
    }
    final submitted = _editor.text;
    await controller.submit(binding, action, audience);
    if (!mounted ||
        !identical(widget.controller, controller) ||
        !identical(generation, _editorGeneration) ||
        _selected != entry.id ||
        _action != action ||
        _editor.text != submitted) {
      return;
    }
    setState(() {
      _editor.text = controller.draft(entry.id, action);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final scoped = controller != null && controller.context() != null;
    final entries = scoped && controller.current
        ? controller.entries
        : <StoreFeedbackEntry>[];
    final selected = entries.where((e) => e.id == _selected).firstOrNull;
    final visible = entries.where(
      (e) =>
          e.kind == _kind &&
          (widget.orderId == null || e.orderId == widget.orderId),
    );
    final unavailable =
        !scoped || controller.coverage == StoreFeedbackCoverage.unavailable;
    final needsRefresh = scoped && !controller.current && !unavailable;
    final binding = _editorBinding;
    final generation = _editorGeneration;
    final action = _action;
    final editorCurrent =
        selected != null &&
        binding != null &&
        binding == controller?.bindingFor(selected.id);
    final orderBinding = selected == null
        ? null
        : controller?.bindingFor(selected.id);
    return Material(
      key: const Key('work-customer-feedback'),
      color: Colors.white,
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('work-feedback-back'),
                tooltip: selected == null
                    ? 'Back to customer orders'
                    : 'Back to feedback',
                onPressed: () {
                  if (selected == null) {
                    widget.onClose();
                  } else {
                    if (_scroll.hasClients) _scroll.jumpTo(0);
                    setState(() {
                      _selected = null;
                      _action = null;
                    });
                  }
                },
                icon: const Icon(Icons.arrow_back),
              ),
              const Expanded(
                child: Text(
                  'Customer feedback',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (scoped)
                IconButton(
                  tooltip: 'Refresh feedback',
                  onPressed: controller.loading
                      ? null
                      : () => unawaited(controller.load()),
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          if (widget.orderId != null) const Text('Feedback for this order'),
          if (controller?.pending != null && scoped) ...[
            const Text(
              'A request is awaiting confirmation. Do not send it again.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              key: const Key('work-feedback-check-request'),
              onPressed: controller.commandInFlight || !controller.recoveryReady ||
                      controller.adapter?.commandRecoveryReady != true
                  ? null
                  : () => unawaited(controller.reconcile()),
              icon: const Icon(Icons.update),
              label: const Text('Check original request'),
            ),
          ],
          if (controller?.message != null && scoped)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(controller.message!),
              ),
            ),
          if (controller?.loading == true && scoped)
            const LinearProgressIndicator(
              semanticsLabel: 'Loading customer feedback',
            ),
          if (selected == null) ...[
            if (unavailable &&
                controller?.loading != true &&
                controller?.message == null) ...[
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 8),
                child: Icon(
                  Icons.rate_review_outlined,
                  color: MoolColors.navy,
                  size: 32,
                ),
              ),
              const Text(
                'Customer feedback is not connected yet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Reviews, replies and reports will appear here when available. '
                  'This does not mean there are no reviews.',
                  textAlign: TextAlign.center,
                ),
              ),
            ] else if (scoped &&
                controller.coverage == StoreFeedbackCoverage.partial)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Only some feedback is available. These are not complete Store totals.',
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                for (final kind in StoreFeedbackKind.values)
                  ChoiceChip(
                    checkmarkColor: Colors.white,
                    label: Text(_label(kind)),
                    selected: _kind == kind,
                    onSelected: (_) => setState(() {
                      _kind = kind;
                      _action = null;
                    }),
                  ),
              ],
            ),
            if (needsRefresh)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Refresh to see current feedback.'),
              ),
            if (!unavailable &&
                !needsRefresh &&
                !controller.loading &&
                visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  controller.nextCursor != null ||
                          controller.coverage == StoreFeedbackCoverage.partial
                      ? 'No matching feedback in the loaded results.'
                      : 'No ${_label(_kind).toLowerCase()} feedback in these results.',
                ),
              ),
            for (final entry in visible) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.authorLabel),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.stars != null) Text('${entry.stars} / 5 stars'),
                    if (entry.mixedOrder)
                      const Text('Mixed-Store order · Overall order feedback'),
                    if (entry.productLabel != null) Text(entry.productLabel!),
                    Text(
                      entry.text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (_scroll.hasClients) _scroll.jumpTo(0);
                  setState(() {
                    _selected = entry.id;
                    _action = null;
                  });
                },
              ),
              const Divider(height: 1),
            ],
            if (scoped && controller.nextCursor != null)
              TextButton(
                onPressed: controller.loading
                    ? null
                    : () => unawaited(controller.load(more: true)),
                child: const Text('Load more feedback'),
              ),
          ] else ...[
            Text(
              '${_label(selected.kind)} feedback',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (selected.mixedOrder)
              const Text('Mixed-Store order · Shared overall review'),
            if (selected.kind == StoreFeedbackKind.overallOrder)
              const Text(
                'Separate from this Store’s service and product ratings.',
              ),
            const SizedBox(height: 12),
            Text(
              selected.authorLabel,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (selected.stars != null) Text('${selected.stars} / 5 stars'),
            if (selected.productLabel != null) Text(selected.productLabel!),
            SelectableText(selected.text),
            if (selected.ownerReply != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Store reply: ${selected.ownerReply}'),
              ),
            if (selected.orderId != null && widget.onOpenOrder != null)
              TextButton.icon(
                onPressed: orderBinding == null
                    ? null
                    : () {
                        final id = controller?.orderForReview(orderBinding);
                        if (id != null) widget.onOpenOrder!(id);
                      },
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('View this Store’s order'),
              ),
            const Divider(),
            if (controller!.adapter?.commandRecoveryReady != true)
              const Text('Replies and reports are not available yet.')
            else
              Wrap(
                spacing: 12,
                children: [
                  if (selected.replyAudiences.isNotEmpty)
                    TextButton.icon(
                      onPressed:
                          controller.canAct(
                            selected.id,
                            StoreFeedbackAction.reply,
                          )
                          ? () => _edit(selected, StoreFeedbackAction.reply)
                          : null,
                      icon: const Icon(Icons.reply),
                      label: Text(
                        selected.ownerReply == null ? 'Reply' : 'Update reply',
                      ),
                    ),
                  if (selected.canReport)
                    TextButton.icon(
                      onPressed:
                          controller.canAct(
                            selected.id,
                            StoreFeedbackAction.report,
                          )
                          ? () => _edit(selected, StoreFeedbackAction.report)
                          : null,
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Report'),
                    ),
                ],
              ),
            if (action != null && !editorCurrent)
              const Text(
                'Feedback changed. Review it and open Reply or Report again. Your text is kept.',
              ),
            if (action != null && editorCurrent) ...[
              const SizedBox(height: 8),
              Text(
                _action == StoreFeedbackAction.report
                    ? 'Reason for reporting'
                    : 'Store reply',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (_action == StoreFeedbackAction.reply &&
                  selected.replyAudiences.length > 1)
                Wrap(
                  spacing: 8,
                  children: [
                    for (final audience in selected.replyAudiences)
                      ChoiceChip(
                      checkmarkColor: Colors.white,
                        label: Text(_audienceLabel(audience)),
                        selected: _audience == audience,
                        onSelected: controller.pending != null
                            ? null
                            : (_) => setState(() {
                                _audience = audience;
                              }),
                      ),
                  ],
                ),
              if (_audience != null)
                Text('Visible to: ${_audienceLabel(_audience!)}'),
              TextField(
                key: const Key('work-feedback-text'),
                controller: _editor,
                minLines: 2,
                maxLines: 6,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: _action == StoreFeedbackAction.reply
                      ? 'Your reply'
                      : 'Report details',
                ),
                onChanged: (value) {
                  if (!mounted || !identical(generation, _editorGeneration)) {
                    return;
                  }
                  controller.setDraft(binding, action, value);
                  setState(() {});
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  key: const Key('work-feedback-send'),
                  onPressed:
                      controller.canAct(selected.id, _action!) &&
                          _editor.text.trim().isNotEmpty
                      ? () => unawaited(_send(selected, generation))
                      : null,
                  child: Text(
                    _action == StoreFeedbackAction.reply
                        ? 'Send reply'
                        : 'Submit report',
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
