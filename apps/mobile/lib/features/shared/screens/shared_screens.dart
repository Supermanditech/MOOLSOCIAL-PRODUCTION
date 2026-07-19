import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design/mool_design_system.dart';
import '../../../../core/design/mool_theme.dart';
import '../shared_models.dart';
import '../shared_session.dart';

class SharedHubScreen extends StatefulWidget {
  const SharedHubScreen({
    required this.session,
    required this.screen,
    this.initialItemId,
    super.key,
  });

  final SharedSession session;
  final int screen;
  final String? initialItemId;

  @override
  State<SharedHubScreen> createState() => _SharedHubScreenState();
}

class _SharedHubScreenState extends State<SharedHubScreen> {
  bool openedInitialItem = false;

  SharedScreenSpec get spec => sharedScreenSpec(widget.screen);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!openedInitialItem && widget.initialItemId != null) {
      openedInitialItem = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final item = spec.items.where(
          (candidate) => candidate.id == widget.initialItemId,
        );
        if (item.isNotEmpty) _openItem(item.first);
      });
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session,
    builder: (context, _) {
      final items = widget.session.visibleItems(spec);
      return Scaffold(
        key: Key('shared-screen-${spec.screen}'),
        backgroundColor: MoolColors.canvas,
        appBar: AppBar(
          leading: IconButton(
            key: Key('shared-${spec.screen}-back'),
            tooltip: 'Back',
            onPressed: () => context.go(
              spec.screen == 162 ? '/app/social' : '/app/account/workspaces',
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spec.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                spec.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          actions: [
            if (spec.topAction != null)
              TextButton.icon(
                key: Key('shared-${spec.screen}-top-action'),
                onPressed: widget.session.busy ? null : _topAction,
                icon: Icon(
                  spec.topAction == 'Scan'
                      ? Icons.qr_code_scanner_rounded
                      : Icons.add_rounded,
                  size: 19,
                ),
                label: Text(spec.topAction!),
              ),
            const SizedBox(width: MoolSpacing.xs),
          ],
        ),
        bottomNavigationBar: _SharedDock(
          activeId: switch (spec.screen) {
            157 => 'activity',
            162 => 'workspaces',
            165 => 'settings',
            _ => '',
          },
          returnRoute: _routeForScreen(spec.screen),
        ),
        body: ListView(
          key: Key('shared-${spec.screen}-list'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            _SharedHero(spec: spec),
            const SizedBox(height: MoolSpacing.sm),
            Row(
              children: [
                for (var index = 0; index < spec.stats.length; index++) ...[
                  if (index > 0) const SizedBox(width: MoolSpacing.xs),
                  Expanded(child: _SharedMetric(stat: spec.stats[index])),
                ],
              ],
            ),
            const SizedBox(height: MoolSpacing.md),
            if (spec.screen == 159)
              _UniversalInputPanel(
                session: widget.session,
                onPermissionRecovery: _permissionRecovery,
              )
            else
              TextField(
                key: Key('shared-${spec.screen}-search'),
                controller: TextEditingController(
                  text: widget.session.searchFor(spec.screen),
                ),
                onChanged: (value) =>
                    widget.session.setSearch(spec.screen, value),
                decoration: InputDecoration(
                  hintText: 'Search ${spec.listTitle.toLowerCase()}',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon:
                      widget.session.searchFor(spec.screen).trim().isNotEmpty
                      ? IconButton(
                          key: Key('shared-${spec.screen}-clear-search'),
                          tooltip: 'Clear search',
                          onPressed: () =>
                              widget.session.setSearch(spec.screen, ''),
                          icon: const Icon(Icons.close_rounded),
                        )
                      : null,
                ),
              ),
            const SizedBox(height: MoolSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in spec.filters) ...[
                    MoolSegment(
                      key: Key('shared-${spec.screen}-filter-${_slug(filter)}'),
                      label: filter,
                      selected: widget.session.filterFor(spec) == filter,
                      onPressed: () =>
                          widget.session.setFilter(spec.screen, filter),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                  ],
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            _SharedMessages(session: widget.session),
            Row(
              children: [
                Expanded(
                  child: Text(
                    spec.listTitle,
                    style: const TextStyle(
                      color: MoolColors.navy,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  spec.listNote,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.sm),
            if (items.isEmpty)
              _SharedEmptyState(
                screen: spec.screen,
                onReset: () => widget.session.resetDiscovery(spec),
              )
            else
              for (var index = 0; index < items.length; index++) ...[
                _SharedItemCard(
                  screen: spec.screen,
                  item: items[index],
                  onTap: () => _openItem(items[index]),
                ),
                if (index < items.length - 1)
                  const SizedBox(height: MoolSpacing.sm),
              ],
          ],
        ),
      );
    },
  );

  Future<void> _openItem(SharedItem item) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => _SharedItemSheet(
        session: widget.session,
        screen: spec.screen,
        item: item,
      ),
    );
  }

  Future<void> _topAction() async {
    switch (spec.screen) {
      case 159:
        if (!widget.session.startScanner()) {
          await _permissionRecovery('camera');
        }
        return;
      case 160:
        await _addFileSheet();
        return;
      case 162:
        context.go('/app/work/choose');
        return;
      default:
        return;
    }
  }

  Future<void> _addFileSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SingleChildScrollView(
        key: const Key('shared-file-add-sheet'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.lg,
          0,
          MoolSpacing.lg,
          MoolSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add a secure file',
              style: TextStyle(
                color: MoolColors.navy,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'Purpose, access and retention are shown before sharing.',
              style: TextStyle(color: MoolColors.muted),
            ),
            const SizedBox(height: MoolSpacing.md),
            for (final choice in const [
              ('camera', 'Camera', Icons.photo_camera_outlined),
              ('scan', 'Scan document', Icons.document_scanner_outlined),
              ('gallery', 'Gallery', Icons.photo_library_outlined),
              ('file', 'Choose file', Icons.attach_file_rounded),
            ])
              ListTile(
                key: Key('shared-file-add-${choice.$1}'),
                leading: Icon(choice.$3),
                title: Text(choice.$2),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  widget.session.completeLocal(
                    '${choice.$2} opened. No file was shared.',
                  );
                  Navigator.pop(sheetContext);
                },
              ),
            TextButton(
              key: const Key('shared-file-add-cancel'),
              onPressed: () => Navigator.pop(sheetContext),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _permissionRecovery(String permission) {
    final camera = permission == 'camera';
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SingleChildScrollView(
        key: Key('shared-$permission-recovery'),
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.lg,
          0,
          MoolSpacing.lg,
          MoolSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              camera ? 'Camera access is off' : 'Microphone access is off',
              style: const TextStyle(
                color: MoolColors.navy,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.xs),
            Text(
              camera
                  ? 'Allow camera access in device settings, or enter the product, shop, bill or payment code.'
                  : 'Allow microphone access in device settings, or type your request.',
              style: const TextStyle(color: MoolColors.muted, height: 1.4),
            ),
            const SizedBox(height: MoolSpacing.md),
            FilledButton(
              key: Key('shared-$permission-open-settings'),
              onPressed: () {
                widget.session.completeLocal(
                  'Device settings opened. Return to retry when permission is ready.',
                );
                Navigator.pop(sheetContext);
              },
              child: const Text('Open device settings'),
            ),
            TextButton(
              key: Key('shared-$permission-use-keyboard'),
              onPressed: () {
                Navigator.pop(sheetContext);
                widget.session.completeLocal('Keyboard input is ready.');
              },
              child: const Text('Use keyboard instead'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedHero extends StatelessWidget {
  const _SharedHero({required this.spec});

  final SharedScreenSpec spec;

  @override
  Widget build(BuildContext context) => MoolCardSurface(
    color: MoolColors.navy,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          spec.kicker,
          style: const TextStyle(
            color: MoolColors.orange,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: MoolSpacing.xs),
        Text(
          spec.heroTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: -.5,
          ),
        ),
        const SizedBox(height: MoolSpacing.xxs),
        Text(
          spec.heroText,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

class _SharedMetric extends StatelessWidget {
  const _SharedMetric({required this.stat});

  final SharedStat stat;

  @override
  Widget build(BuildContext context) => MoolCardSurface(
    padding: const EdgeInsets.all(MoolSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stat.label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: MoolColors.muted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          stat.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: MoolColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _SharedItemCard extends StatelessWidget {
  const _SharedItemCard({
    required this.screen,
    required this.item,
    required this.onTap,
  });

  final int screen;
  final SharedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (item.tone) {
      'required' => MoolColors.orange,
      'good' => MoolColors.success,
      _ => MoolColors.royal,
    };
    return MoolCardSurface(
      key: Key('shared-$screen-item-${item.id}'),
      onTap: onTap,
      semanticLabel: '${item.title}. ${item.primary}',
      padding: const EdgeInsets.all(MoolSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(_iconForCategory(item.category), color: accent),
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.category.toUpperCase(),
                        style: TextStyle(
                          color: accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                    ),
                    if (item.unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: MoolColors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: MoolSpacing.xxs),
                Text(
                  item.title,
                  style: const TextStyle(
                    color: MoolColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: MoolSpacing.xxs),
                Text(
                  item.summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: MoolSpacing.xs),
                Text(
                  item.meta,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoolColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MoolSpacing.xs),
          const Icon(Icons.chevron_right_rounded, color: MoolColors.navy),
        ],
      ),
    );
  }
}

class _SharedEmptyState extends StatelessWidget {
  const _SharedEmptyState({required this.screen, required this.onReset});

  final int screen;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => MoolCardSurface(
    key: Key('shared-$screen-empty'),
    child: Column(
      children: [
        const Icon(Icons.search_off_rounded, size: 36, color: MoolColors.muted),
        const SizedBox(height: MoolSpacing.xs),
        const Text(
          'No matching items',
          style: TextStyle(
            color: MoolColors.navy,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Text(
          'Clear search and filters to see every available action.',
          textAlign: TextAlign.center,
          style: TextStyle(color: MoolColors.muted),
        ),
        const SizedBox(height: MoolSpacing.sm),
        FilledButton(
          key: Key('shared-$screen-reset'),
          onPressed: onReset,
          child: const Text('Clear search and filters'),
        ),
      ],
    ),
  );
}

class _SharedMessages extends StatelessWidget {
  const _SharedMessages({required this.session});

  final SharedSession session;

  @override
  Widget build(BuildContext context) {
    final error = session.errorMessage;
    final notice = session.noticeMessage;
    if (error == null && notice == null) return const SizedBox.shrink();
    final failed = error != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: MoolSpacing.sm),
      child: MoolCardSurface(
        key: Key(failed ? 'shared-error' : 'shared-notice'),
        color: failed ? const Color(0xFFFFEEEA) : const Color(0xFFEAF8ED),
        padding: const EdgeInsets.all(MoolSpacing.sm),
        child: Row(
          children: [
            Icon(
              failed
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: failed ? const Color(0xFFB42318) : MoolColors.success,
            ),
            const SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: Text(
                error ?? notice!,
                style: TextStyle(
                  color: failed ? const Color(0xFFB42318) : MoolColors.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ),
            IconButton(
              key: const Key('shared-dismiss-message'),
              tooltip: 'Dismiss',
              onPressed: session.dismissMessages,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedItemSheet extends StatefulWidget {
  const _SharedItemSheet({
    required this.session,
    required this.screen,
    required this.item,
  });

  final SharedSession session;
  final int screen;
  final SharedItem item;

  @override
  State<_SharedItemSheet> createState() => _SharedItemSheetState();
}

class _SharedItemSheetState extends State<_SharedItemSheet> {
  bool primaryConfirmed = false;
  bool secondaryConfirmed = false;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.session,
    builder: (context, _) {
      final item = widget.item;
      return FractionallySizedBox(
        heightFactor: .92,
        child: Column(
          key: Key('shared-${widget.screen}-detail-${item.id}'),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MoolSpacing.lg,
                0,
                MoolSpacing.sm,
                MoolSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.category.toUpperCase(),
                          style: const TextStyle(
                            color: MoolColors.royal,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .7,
                          ),
                        ),
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: MoolColors.navy,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.4,
                          ),
                        ),
                        Text(
                          item.meta,
                          style: const TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: Key('shared-${widget.screen}-detail-${item.id}-close'),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(MoolSpacing.md),
                children: [
                  if (item.preview.isNotEmpty) ...[
                    MoolCardSurface(
                      color: MoolColors.navy,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final preview in item.preview)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: MoolSpacing.xxs,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.visibility_outlined,
                                    color: MoolColors.orange,
                                    size: 18,
                                  ),
                                  const SizedBox(width: MoolSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      preview,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                  ],
                  _FactGrid(facts: item.facts),
                  const SizedBox(height: MoolSpacing.sm),
                  MoolCardSurface(
                    color: const Color(0xFFF1F2FB),
                    padding: const EdgeInsets.all(MoolSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WHY YOU SEE THIS',
                          style: TextStyle(
                            color: MoolColors.navy,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: MoolSpacing.xxs),
                        Text(
                          item.why,
                          style: const TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  _StepList(item: item),
                  if (item.controls.isNotEmpty) ...[
                    const SizedBox(height: MoolSpacing.md),
                    const Text(
                      'Your controls',
                      style: TextStyle(
                        color: MoolColors.navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    for (final control in item.controls)
                      SwitchListTile.adaptive(
                        key: Key(
                          'shared-${widget.screen}-${item.id}-control-${control.id}',
                        ),
                        contentPadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                control.label,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (control.locked)
                              const Icon(
                                Icons.lock_outline_rounded,
                                size: 16,
                                color: MoolColors.muted,
                              ),
                          ],
                        ),
                        subtitle: Text(
                          control.note,
                          style: const TextStyle(fontSize: 10.5),
                        ),
                        value: widget.session.controlValue(item, control),
                        onChanged: (value) =>
                            widget.session.toggleControl(item, control, value),
                      ),
                  ],
                  if (item.schedule.isNotEmpty) ...[
                    const SizedBox(height: MoolSpacing.md),
                    Text(
                      item.scheduleTitle ?? 'Schedule',
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    MoolCardSurface(
                      padding: const EdgeInsets.all(MoolSpacing.sm),
                      child: Column(
                        children: [
                          for (final schedule in item.schedule)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: MoolSpacing.xxs,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      schedule.label,
                                      style: const TextStyle(
                                        color: MoolColors.muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: MoolSpacing.sm),
                                  Flexible(
                                    child: Text(
                                      schedule.value,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (item.secondary?.startsWith('Pause') ?? false) ...[
                    const SizedBox(height: MoolSpacing.md),
                    const Text(
                      'Pause new demand until',
                      style: TextStyle(
                        color: MoolColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    Wrap(
                      spacing: MoolSpacing.xs,
                      runSpacing: MoolSpacing.xs,
                      children: [
                        for (final duration in const [
                          '30 minutes',
                          '1 hour',
                          'Until tomorrow',
                        ])
                          ChoiceChip(
                            key: Key(
                              'shared-${widget.screen}-${item.id}-pause-${_slug(duration)}',
                            ),
                            label: Text(duration),
                            selected: widget.session.pauseDuration == duration,
                            onSelected: (_) =>
                                widget.session.setPauseDuration(duration),
                          ),
                      ],
                    ),
                  ],
                  if (item.id == 'agent') ...[
                    const SizedBox(height: MoolSpacing.md),
                    const _AgentAuthorityBoundary(),
                  ],
                  if (item.confirmation case final confirmation?) ...[
                    const SizedBox(height: MoolSpacing.sm),
                    CheckboxListTile(
                      key: Key(
                        'shared-${widget.screen}-${item.id}-confirm-primary',
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: primaryConfirmed,
                      onChanged: (value) =>
                          setState(() => primaryConfirmed = value ?? false),
                      title: Text(
                        confirmation,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                  if (item.secondaryConfirmation
                      case final secondaryConfirmation?) ...[
                    CheckboxListTile(
                      key: Key(
                        'shared-${widget.screen}-${item.id}-confirm-secondary',
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: secondaryConfirmed,
                      onChanged: (value) =>
                          setState(() => secondaryConfirmed = value ?? false),
                      title: Text(
                        secondaryConfirmation,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                  const SizedBox(height: MoolSpacing.sm),
                  _SharedMessages(session: widget.session),
                ],
              ),
            ),
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(MoolSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (item.secondary != null) ...[
                      OutlinedButton(
                        key: Key(
                          'shared-${widget.screen}-${item.id}-secondary',
                        ),
                        onPressed: widget.session.busy
                            ? null
                            : () => _execute(primary: false),
                        child: Text(
                          widget.session.actionComplete(
                                widget.session.actionId(
                                  widget.screen,
                                  item.id,
                                  'secondary',
                                ),
                              )
                              ? 'Alternative complete'
                              : item.secondary!,
                        ),
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                    ],
                    FilledButton(
                      key: Key('shared-${widget.screen}-${item.id}-primary'),
                      onPressed: widget.session.busy
                          ? null
                          : () => _execute(primary: true),
                      child: Text(
                        widget.session.busy
                            ? 'Completing…'
                            : widget.session.actionComplete(
                                widget.session.actionId(
                                  widget.screen,
                                  item.id,
                                  'primary',
                                ),
                              )
                            ? 'Action complete'
                            : item.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Future<void> _execute({required bool primary}) async {
    final item = widget.item;
    final route = primary ? item.primaryRoute : item.secondaryRoute;
    final success = await widget.session.execute(
      id: widget.session.actionId(
        widget.screen,
        item.id,
        primary ? 'primary' : 'secondary',
      ),
      outcome: primary
          ? item.primaryOutcome
          : item.secondaryOutcome ?? 'Alternative action complete.',
      confirmation: primary ? item.confirmation : item.secondaryConfirmation,
      confirmed: primary ? primaryConfirmed : secondaryConfirmed,
    );
    if (!success || !mounted || route == null) return;
    Navigator.pop(context);
    if (context.mounted) context.go(route);
  }
}

class _FactGrid extends StatelessWidget {
  const _FactGrid({required this.facts});

  final List<SharedFact> facts;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: facts.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 2.15,
      crossAxisSpacing: MoolSpacing.xs,
      mainAxisSpacing: MoolSpacing.xs,
    ),
    itemBuilder: (context, index) {
      final fact = facts[index];
      return MoolCardSurface(
        padding: const EdgeInsets.all(MoolSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              fact.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: MoolColors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              fact.value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: MoolColors.navy,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _StepList extends StatelessWidget {
  const _StepList({required this.item});

  final SharedItem item;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < item.steps.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: index < item.currentStep
                    ? MoolColors.success
                    : index == item.currentStep
                    ? MoolColors.orange
                    : const Color(0xFFE9EAF3),
                foregroundColor: index <= item.currentStep
                    ? Colors.white
                    : MoolColors.muted,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.steps[index].label,
                      style: const TextStyle(
                        color: MoolColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      item.steps[index].outcome,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _UniversalInputPanel extends StatelessWidget {
  const _UniversalInputPanel({
    required this.session,
    required this.onPermissionRecovery,
  });

  final SharedSession session;
  final Future<void> Function(String permission) onPermissionRecovery;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(
        key: const Key('shared-159-input'),
        controller: TextEditingController(text: session.input)
          ..selection = TextSelection.collapsed(offset: session.input.length),
        onChanged: session.updateInput,
        onSubmitted: (_) => session.resolveInput(),
        decoration: InputDecoration(
          hintText: 'Ask for a product, service, work or workspace action',
          prefixIcon: const Icon(Icons.auto_awesome_rounded),
          suffixIcon: IconButton(
            key: const Key('shared-159-submit'),
            tooltip: 'Find exact action',
            onPressed: session.busy ? null : session.resolveInput,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ),
      ),
      const SizedBox(height: MoolSpacing.xs),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('shared-159-scan'),
              onPressed: () async {
                if (!session.startScanner()) {
                  await onPermissionRecovery('camera');
                }
              },
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan'),
            ),
          ),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('shared-159-voice'),
              onPressed: () async {
                if (!session.startVoice()) {
                  await onPermissionRecovery('microphone');
                }
              },
              icon: const Icon(Icons.mic_none_rounded),
              label: const Text('Voice'),
            ),
          ),
        ],
      ),
      if (session.inputResult case final result?) ...[
        const SizedBox(height: MoolSpacing.sm),
        MoolCardSurface(
          key: const Key('shared-159-result'),
          color: const Color(0xFFF0F1FF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                result.title,
                style: const TextStyle(
                  color: MoolColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                result.detail,
                style: const TextStyle(color: MoolColors.muted, fontSize: 11),
              ),
              const SizedBox(height: MoolSpacing.sm),
              FilledButton(
                key: const Key('shared-159-result-open'),
                onPressed: () => context.go(result.route),
                child: Text(result.action),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

class _AgentAuthorityBoundary extends StatelessWidget {
  const _AgentAuthorityBoundary();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Agent authority',
        style: TextStyle(
          color: MoolColors.navy,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: MoolSpacing.xs),
      for (final boundary in const [
        (
          'Runs automatically',
          'Monitor, prioritize, prepare drafts and apply saved reversible schedules.',
          MoolColors.success,
        ),
        (
          'Asks before action',
          'Payments, refunds, purchases, prices, public posts, ads, contracts and data sharing.',
          MoolColors.orange,
        ),
        (
          'Never delegated',
          'OTP, PIN, password, borrowing, guarantees, consent, evidence or audit history.',
          Color(0xFFB42318),
        ),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
          child: MoolCardSurface(
            color: boundary.$3.withValues(alpha: .07),
            padding: const EdgeInsets.all(MoolSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  boundary.$1,
                  style: TextStyle(
                    color: boundary.$3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  boundary.$2,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

class _SharedDock extends StatelessWidget {
  const _SharedDock({required this.activeId, required this.returnRoute});

  final String activeId;
  final String returnRoute;

  @override
  Widget build(BuildContext context) => MoolOutcomeDock(
    semanticLabel: 'Shared account navigation',
    activeId: activeId,
    mool: MoolDockAction(
      keyName: 'shared-dock-mool',
      id: 'mool',
      label: 'Mool',
      icon: Icons.circle,
      onPressed: () => context.go('/app/social'),
    ),
    actions: [
      MoolDockAction(
        keyName: 'shared-dock-activity',
        id: 'activity',
        label: 'Activity',
        icon: Icons.notifications_none_rounded,
        badgeCount: 2,
        onPressed: () => context.go('/app/activity'),
      ),
      MoolDockAction(
        keyName: 'shared-dock-workspaces',
        id: 'workspaces',
        label: 'Spaces',
        icon: Icons.grid_view_rounded,
        onPressed: () => context.go('/app/account/workspaces'),
      ),
      MoolDockAction(
        keyName: 'shared-dock-settings',
        id: 'settings',
        label: 'Controls',
        icon: Icons.tune_rounded,
        onPressed: () => context.go('/app/account/workspaces/preferences'),
      ),
    ],
    chat: MoolDockAction(
      keyName: 'shared-dock-chat',
      id: 'chat',
      label: 'Chat',
      icon: Icons.chat_bubble_outline_rounded,
      badgeCount: 2,
      onPressed: () => context.go(
        Uri(
          path: '/app/chat/inbox',
          queryParameters: {'return': returnRoute},
        ).toString(),
      ),
    ),
  );
}

String _routeForScreen(int screen) => switch (screen) {
  157 => '/app/activity',
  158 => '/app/account/identity',
  159 => '/app/ask',
  160 => '/app/files',
  161 => '/app/account/security',
  162 => '/app/account/workspaces',
  165 => '/app/account/workspaces/preferences',
  _ => '/app/account/workspaces',
};

String _slug(String value) => value
    .toLowerCase()
    .replaceAll('&', 'and')
    .replaceAll(RegExp('[^a-z0-9]+'), '-')
    .replaceAll(RegExp('(^-+|-+\$)'), '');

IconData _iconForCategory(String category) => switch (category) {
  'Required' => Icons.notification_important_outlined,
  'Orders' => Icons.shopping_bag_outlined,
  'Work' => Icons.work_outline_rounded,
  'Offers' => Icons.local_offer_outlined,
  'Updates' => Icons.auto_awesome_outlined,
  'Identity' => Icons.badge_outlined,
  'Workspaces' || 'Workspace' => Icons.storefront_outlined,
  'Consent' => Icons.verified_user_outlined,
  'Buy' => Icons.shopping_basket_outlined,
  'Book' => Icons.calendar_month_outlined,
  'Documents' => Icons.description_outlined,
  'Evidence' => Icons.fact_check_outlined,
  'Media' => Icons.video_library_outlined,
  'Clinical' => Icons.health_and_safety_outlined,
  'Security' => Icons.shield_outlined,
  'Access' => Icons.manage_accounts_outlined,
  'Support' => Icons.support_agent_outlined,
  'Personal' => Icons.person_outline_rounded,
  'Business' => Icons.business_outlined,
  'Creator' || 'Social' => Icons.play_circle_outline_rounded,
  'Settings' => Icons.tune_rounded,
  'Communication' => Icons.notifications_none_rounded,
  'Agent' => Icons.auto_awesome_rounded,
  'Privacy' => Icons.privacy_tip_outlined,
  _ => Icons.chevron_right_rounded,
};
