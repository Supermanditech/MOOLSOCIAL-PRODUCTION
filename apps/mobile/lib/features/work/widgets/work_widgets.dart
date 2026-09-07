import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_service_home.dart';
import '../../../core/design/mool_theme.dart';
import '../../../ui_v2/universal/mool_global_navigation_v2.dart';
import '../work_session.dart';
import '../work_models.dart';
import '../scan_and_pick_contract.dart';

/// Rendering seam only. The host supplies a real QR encoder; no placeholder
/// code, local token signing or embedded customer-authorisation fallback.
class WorkCollectionCodeRenderer extends InheritedWidget {
  const WorkCollectionCodeRenderer({
    required this.render,
    required super.child,
    super.key,
  });
  final Widget Function(BuildContext context, String payload) render;
  static WorkCollectionCodeRenderer? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WorkCollectionCodeRenderer>();
  @override
  bool updateShouldNotify(WorkCollectionCodeRenderer oldWidget) =>
      render != oldWidget.render;
}

class WorkCollectionLiveCard extends StatefulWidget {
  const WorkCollectionLiveCard({
    required this.order,
    required this.amountBuilder,
    this.controller,
    super.key,
  });
  final WorkspaceOrderRecord order;
  final Widget Function(String value, int minor, TextStyle style) amountBuilder;
  final StoreCollectionController? controller;
  @override
  State<WorkCollectionLiveCard> createState() => _WorkCollectionLiveCardState();
}

class _WorkCollectionLiveCardState extends State<WorkCollectionLiveCard>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _foreground = true;
  bool _expanded = false;
  static const _blue = Color(0xFF000080);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller?.addListener(_changed);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void didUpdateWidget(WorkCollectionLiveCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_changed);
      widget.controller?.addListener(_changed);
      _expanded = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    if (!mounted ||
        !_foreground ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    final controller = widget.controller;
    if (controller == null ||
        controller.busy ||
        controller.snapshot?.state == ScanPickState.collected ||
        controller.snapshot?.state == ScanPickState.cancelled) {
      return;
    }
    await controller.refresh();
    if (!mounted || !_foreground || widget.controller != controller) return;
    final value = controller.snapshot;
    if (WorkCollectionCodeRenderer.of(context) != null &&
        controller.message == null &&
        !controller.needsReconciliation &&
        (value?.state == ScanPickState.ready ||
            (value?.state == ScanPickState.awaitingCustomer &&
                controller.visibleQr == null))) {
      await controller.showCode();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      unawaited(_refresh());
    } else {
      _changed();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.controller?.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final value = controller?.snapshot;
    final state = value?.state;
    final matched =
        state == ScanPickState.matched &&
        controller?.hasCurrentMatch == true &&
        _foreground;
    final collected = state == ScanPickState.collected;
    final renderer = WorkCollectionCodeRenderer.of(context);
    final payload = _foreground ? controller?.visibleQr : null;
    final showQr = payload != null && renderer != null;
    final title = collected
        ? 'Collected'
        : matched
        ? 'Matched'
        : switch (state) {
            ScanPickState.preparing => 'Pack the items',
            ScanPickState.cancelled => 'Order cancelled',
            ScanPickState.ready ||
            ScanPickState.awaitingCustomer => 'Ready at the counter',
            _ => 'Checking collection',
          };
    final message =
        controller?.message ??
        (controller == null
            ? 'Collection confirmation is unavailable. Do not hand over yet.'
            : value == null
            ? 'Checking this order…'
            : renderer == null &&
                  (state == ScanPickState.ready ||
                      state == ScanPickState.awaitingCustomer)
            ? 'Collection code is unavailable. Do not hand over yet.'
            : null);
    return Column(
      key: const Key('work-collection-live-card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            key: const Key('work-collection-content'),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      color: _blue,
                      size: 18,
                    ),
                    const Text(
                      'Collect at store',
                      style: TextStyle(
                        fontSize: 12,
                        color: _blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (value != null)
                      Text(
                        switch (value.payment) {
                          ScanPickPayment.paid => 'Paid',
                          ScanPickPayment.refunded => 'Refunded',
                          ScanPickPayment.partiallyPaid => 'Part paid',
                          ScanPickPayment.unpaid => 'Payment pending',
                        },
                        style: const TextStyle(
                          fontSize: 11,
                          color: MoolColors.muted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  value?.customerName ?? widget.order.customer,
                  key: const Key('work-collection-customer'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _blue,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${value?.orderId ?? widget.order.id} · ${value?.storeName ?? 'Your store'}',
                  style: const TextStyle(fontSize: 11, color: MoolColors.muted),
                ),
                const SizedBox(height: 12),
                AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: matched || collected
                        ? _blue
                        : const Color(0xFFF1F3FC),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        matched || collected
                            ? Icons.check_circle_outline
                            : Icons.inventory_2_outlined,
                        size: 20,
                        color: matched || collected ? Colors.white : _blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          key: const Key('work-collection-state'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: matched || collected ? Colors.white : _blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (value != null) ...[
                  for (final line
                      in (_expanded ? value.lines : value.lines.take(2)))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            line.name,
                            style: const TextStyle(
                              fontSize: 13,
                              color: _blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final description = Text(
                                '${line.pack} · Qty ${line.quantity}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: MoolColors.muted,
                                ),
                              );
                              final amount = widget.amountBuilder(
                                _collectionMoney(line.amountMinor),
                                line.amountMinor,
                                const TextStyle(
                                  fontSize: 12,
                                  color: _blue,
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                              return MediaQuery.textScalerOf(
                                            context,
                                          ).scale(14) >
                                          18 ||
                                      line.amountMinor > 100000000
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [description, amount],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(child: description),
                                        const SizedBox(width: 6),
                                        SizedBox(
                                          width: constraints.maxWidth * .35,
                                          child: amount,
                                        ),
                                      ],
                                    );
                            },
                          ),
                          if (_expanded)
                            Text(
                              'SKU ${line.skuId}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: MoolColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (value.lines.length > 2)
                    TextButton(
                      onPressed: () => setState(() => _expanded = !_expanded),
                      child: Text(
                        _expanded
                            ? 'Show less'
                            : 'All ${value.lines.length} items',
                      ),
                    ),
                  const Divider(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final count = Text(
                        '${value.lines.length} items',
                        style: const TextStyle(
                          fontSize: 12,
                          color: MoolColors.muted,
                        ),
                      );
                      final amount = SizedBox(
                        key: const Key('work-collection-amount'),
                        child: widget.amountBuilder(
                          _collectionMoney(value.totalMinor),
                          value.totalMinor,
                          const TextStyle(
                            fontSize: 18,
                            color: _blue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                      return MediaQuery.textScalerOf(context).scale(14) <= 18
                          ? Row(
                              children: [
                                count,
                                const SizedBox(width: 8),
                                Expanded(child: amount),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                count,
                                const SizedBox(height: 3),
                                amount,
                              ],
                            );
                    },
                  ),
                ] else
                  Text(
                    widget.order.items,
                    style: const TextStyle(
                      fontSize: 13,
                      color: MoolColors.muted,
                    ),
                  ),
                if (showQr) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Ask the customer to scan this code from their order.',
                    key: Key('work-collection-scan-instruction'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: _blue),
                  ),
                  const SizedBox(height: 7),
                  Center(
                    child: Semantics(
                      label: 'Customer collection code for ${widget.order.id}',
                      image: true,
                      child: ExcludeSemantics(
                        child: SizedBox.square(
                          key: const Key('work-collection-qr'),
                          dimension: 156,
                          child: ColoredBox(
                            color: Colors.white,
                            child: renderer.render(context, payload),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (collected && value?.receipt != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Collection confirmed',
                    style: TextStyle(
                      fontSize: 13,
                      color: _blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (value!.receipt!.invoiceReference != null)
                    Text(
                      'Invoice ${value.receipt!.invoiceReference}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: MoolColors.muted,
                      ),
                    ),
                ],
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      message,
                      key: const Key('work-collection-recovery'),
                      style: const TextStyle(fontSize: 12, color: _blue),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!collected && state != ScanPickState.cancelled)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (message != null && controller != null)
                  TextButton(
                    onPressed: controller.busy ? null : _refresh,
                    child: const Text('Try again'),
                  )
                else if (matched || controller?.actionPending == true)
                  FilledButton(
                    key: const Key('work-collection-hand-over'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: matched && controller!.canHandOver
                        ? () {
                            if (_foreground &&
                                ModalRoute.of(context)?.isCurrent != false) {
                              unawaited(controller.handOver());
                            }
                          }
                        : null,
                    child: Text(
                      controller?.actionPending == true
                          ? 'Confirming…'
                          : matched
                          ? 'Hand Over'
                          : 'Waiting for customer',
                    ),
                  ),
                if (message == null &&
                    !matched &&
                    controller?.actionPending != true)
                  Text(
                    state == ScanPickState.preparing
                        ? 'Waiting for packing confirmation'
                        : 'Waiting for customer',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _blue,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  matched
                      ? 'Give the goods, then tap Hand Over. Payout remains pending until collection is confirmed.'
                      : 'Hand over only when this screen shows Matched.',
                  style: const TextStyle(fontSize: 11, color: MoolColors.muted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _collectionMoney(int minor) {
  final whole = (minor ~/ 100).toString();
  final suffix = (minor % 100).toString().padLeft(2, '0');
  if (whole.length <= 3) return '₹$whole${minor % 100 == 0 ? '' : '.$suffix'}';
  final end = whole.substring(whole.length - 3);
  final prefix = whole
      .substring(0, whole.length - 3)
      .replaceAllMapped(
        RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
        (match) => '${match[1]},',
      );
  return '₹$prefix,$end${minor % 100 == 0 ? '' : '.$suffix'}';
}

class WorkPageScaffold extends StatelessWidget {
  const WorkPageScaffold({
    required this.session,
    required this.title,
    required this.subtitle,
    required this.body,
    this.headerTitle,
    this.headerHeight = 88,
    this.wrapHeader = false,
    this.fallbackBackRoute = '/app/work/earn',
    this.showBack = true,
    this.activeLocalAction = 'earn',
    this.showHeaderChat = true,
    this.showTrailingAction = true,
    this.showMessageBanner = true,
    this.onBack,
    this.trailing,
    this.bottomAction,
    this.contextualLocalActions,
    this.contextualActiveId,
    this.contextualDestinationLabel,
    this.manageSystemBack = true,
    this.hideNavigationWhenKeyboardVisible = false,
    this.navigationOverBody = false,
    this.resizeToAvoidBottomInset = true,
    super.key,
  });

  final WorkSession session;
  final String title;
  final String subtitle;
  final Widget body;
  final Widget? headerTitle;
  final double headerHeight;
  final bool wrapHeader;
  final String fallbackBackRoute;
  final bool showBack;
  final String activeLocalAction;
  final bool showHeaderChat;
  final bool showTrailingAction;
  final bool showMessageBanner;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? bottomAction;
  final List<MoolLocalNavigationAction>? contextualLocalActions;
  final String? contextualActiveId;
  final String? contextualDestinationLabel;
  final bool manageSystemBack;
  final bool hideNavigationWhenKeyboardVisible;
  final bool navigationOverBody;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final titleWidth =
        (MediaQuery.sizeOf(context).width -
                MediaQuery.paddingOf(context).horizontal -
                (showBack ? 64 : 0) -
                (showBack ? 8 : 32) -
                (showHeaderChat ? 52 : 0) -
                (showTrailingAction ? 64 : 0))
            .clamp(1.0, double.infinity)
            .toDouble();
    final wrappedTitle = wrapHeader && headerTitle == null
        ? _WorkSetupHeader(
            title: title,
            subtitle: subtitle,
            textScaler: MediaQuery.textScalerOf(context),
          )
        : null;
    final measuredHeight = wrappedTitle?.height(context, titleWidth) ?? 0;
    final toolbarHeight = measuredHeight > headerHeight
        ? measuredHeight
        : headerHeight;
    final canPop = Navigator.of(context).canPop();
    void leaveContentDepth() {
      session.clearMessages();
      if (onBack != null) {
        onBack!();
        return;
      }
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(fallbackBackRoute);
      }
    }

    void openGlobal(String route) {
      session.clearMessages();
      context.push(route);
    }

    void openChat() {
      final current = GoRouterState.of(context).uri.toString();
      openGlobal(
        Uri(
          path: '/app/chat/inbox',
          queryParameters: {'return': current},
        ).toString(),
      );
    }

    void openLocal(String route) {
      session.clearMessages();
      context.push(route);
    }

    void switchGlobalDestination(String route) {
      session.clearMessages();
      openMoolConnectedRoute(context, activeFamilyId: 'work', route: route);
    }

    final localActions =
        contextualLocalActions ??
        [
          MoolLocalNavigationAction(
            keyName: 'work-local-earn',
            id: 'earn',
            label: 'Earn Today',
            icon: Icons.bolt_rounded,
            onPressed: activeLocalAction == 'earn'
                ? null
                : () => openLocal('/app/work/earn'),
          ),
          MoolLocalNavigationAction(
            keyName: 'work-local-workspace',
            id: 'workspace',
            label: 'Workspace',
            icon: Icons.dashboard_customize_outlined,
            onPressed: activeLocalAction == 'workspace'
                ? null
                : () => openLocal('/app/work/my-work'),
          ),
        ];
    final resolvedActiveId = contextualActiveId ?? activeLocalAction;
    var selectedLocalIndex = localActions.indexWhere(
      (action) => action.id == resolvedActiveId,
    );
    if (selectedLocalIndex < 0) selectedLocalIndex = 0;

    void moveLocal(int delta) {
      final target = (selectedLocalIndex + delta) % localActions.length;
      localActions[target].onPressed?.call();
    }

    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showNavigation =
        !hideNavigationWhenKeyboardVisible || !keyboardVisible;
    final navigation = MoolDestinationNavigationV2(
      activeId: 'work',
      destinationLabel: contextualDestinationLabel ?? 'Work',
      showFamilyRootAction: false,
      selectedLocalIndex: selectedLocalIndex,
      localActionCount: localActions.length,
      localNavigation: MoolLocalNavigationRail(
        key: const Key('work-local-navigation'),
        familyId: 'work',
        surfaceTone: MoolLocalNavigationSurfaceTone.light,
        semanticLabel: contextualLocalActions == null
            ? 'Work choices: Earn Today and Workspace.'
            : 'Store choices: Store, Orders, Sell and Stock.',
        activeId: resolvedActiveId,
        actions: localActions,
      ),
      onOpenMool: () => openGlobal('/app/mool?from=work'),
      onOpenAction: (action) => switchGlobalDestination(action.route),
      onPreviousLocalAction: () => moveLocal(-1),
      onNextLocalAction: () => moveLocal(1),
      onOpenChat: openChat,
    );
    final pageBody = SafeArea(
      top: false,
      bottom: true,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: MoolMetrics.maximumContentWidth,
          ),
          child: Column(
            children: [
              if (showMessageBanner) WorkMessageBanner(session: session),
              Expanded(child: _WorkPageReveal(child: body)),
              if (bottomAction != null)
                Material(
                  key: const Key('work-sticky-action-bar'),
                  color: Colors.white,
                  elevation: 8,
                  shadowColor: const Color(0x22000050),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      MoolSpacing.md,
                      MoolSpacing.sm,
                      MoolSpacing.md,
                      MoolSpacing.xs,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: _WorkActionReveal(child: bottomAction!),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    final composedBody = navigationOverBody
        ? Stack(
            children: [
              Positioned.fill(child: pageBody),
              if (showNavigation)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ColoredBox(color: Colors.white, child: navigation),
                ),
            ],
          )
        : pageBody;

    return PopScope<Object?>(
      canPop: manageSystemBack ? onBack == null && canPop : true,
      onPopInvokedWithResult: (didPop, _) {
        if (!manageSystemBack) return;
        if (!didPop) {
          leaveContentDepth();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBody: false,
        appBar: AppBar(
          backgroundColor: MoolColors.canvas,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          toolbarHeight: toolbarHeight,
          leadingWidth: showBack ? 64 : 16,
          leading: showBack
              ? Padding(
                  padding: const EdgeInsets.only(left: MoolSpacing.sm),
                  child: MoolNativeBackButton(
                    keyName: 'work-back',
                    onPressed: leaveContentDepth,
                  ),
                )
              : null,
          titleSpacing: showBack ? 4 : MoolSpacing.md,
          title:
              headerTitle ??
              wrappedTitle ??
              MoolServiceHeaderTitle(
                title: title,
                subtitle: subtitle,
                titleKey: const Key('work-page-title'),
                subtitleKey: const Key('work-page-subtitle'),
              ),
          actions: [
            if (showHeaderChat) ...[
              MoolGlobalChatShortcut(
                keyName: 'work-global-chat',
                onPressed: openChat,
              ),
              const SizedBox(width: 4),
            ],
            if (showTrailingAction)
              Padding(
                padding: const EdgeInsets.only(right: MoolSpacing.sm),
                child:
                    trailing ??
                    IconButton.outlined(
                      key: const Key('work-help'),
                      tooltip: 'Work help',
                      onPressed: () => context.go(
                        Uri(
                          path: '/app/chat',
                          queryParameters: {
                            'type': 'support',
                            'return': GoRouterState.of(context).uri.toString(),
                          },
                        ).toString(),
                      ),
                      icon: const Icon(Icons.support_agent_outlined),
                    ),
              ),
          ],
        ),
        body: composedBody,
        bottomNavigationBar: navigationOverBody || !showNavigation
            ? null
            : navigation,
      ),
    );
  }
}

class _WorkSetupHeader extends StatelessWidget {
  const _WorkSetupHeader({
    required this.title,
    required this.subtitle,
    required this.textScaler,
  });

  final String title;
  final String subtitle;
  final TextScaler textScaler;

  ({TextStyle title, TextStyle subtitle}) _styles(
    BuildContext context,
    double width,
  ) {
    final compact = width < 300;
    final theme = Theme.of(context);
    final base = theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge;
    return (
      title: (base ?? const TextStyle()).merge(
        TextStyle(
          color: MoolColors.ink,
          fontSize: compact ? 15 : 20,
          height: 1.05,
          fontWeight: FontWeight.w900,
          letterSpacing: compact ? -.15 : -.35,
        ),
      ),
      subtitle: (base ?? const TextStyle()).merge(
        TextStyle(
          color: MoolColors.muted,
          fontSize: compact ? 10.5 : 12,
          height: 1.1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  double height(BuildContext context, double width) {
    final styles = _styles(context, width);
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: textScaler,
      )..layout(maxWidth: width);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    return (measure(title, styles.title) +
            measure(subtitle, styles.subtitle) +
            18)
        .ceilToDouble();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final styles = _styles(context, constraints.maxWidth);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            key: const Key('work-page-title'),
            style: styles.title,
            textScaler: textScaler,
            softWrap: true,
            overflow: TextOverflow.clip,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            key: const Key('work-page-subtitle'),
            style: styles.subtitle,
            textScaler: textScaler,
            softWrap: true,
            overflow: TextOverflow.clip,
          ),
        ],
      );
    },
  );
}

class _WorkPageReveal extends StatelessWidget {
  const _WorkPageReveal({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: MoolMotion.accessible(context, MoolMotion.standard),
      curve: MoolMotion.enter,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _WorkActionReveal extends StatelessWidget {
  const _WorkActionReveal({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: MoolMotion.accessible(context, MoolMotion.deliberate),
      curve: MoolMotion.enter,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(
          scale: .97 + (.03 * value),
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class WorkMessageBanner extends StatefulWidget {
  const WorkMessageBanner({required this.session, super.key});

  final WorkSession session;

  @override
  State<WorkMessageBanner> createState() => _WorkMessageBannerState();
}

class _WorkMessageBannerState extends State<WorkMessageBanner> {
  Timer? _dismissTimer;
  String? _scheduledNotice;

  void _scheduleNoticeDismissal(String? notice) {
    if (notice == null || notice == _scheduledNotice) return;
    _dismissTimer?.cancel();
    _scheduledNotice = notice;
    _dismissTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted || widget.session.noticeMessage != notice) return;
      widget.session.dismissMessages();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.session.errorMessage;
    final notice = widget.session.noticeMessage;
    _scheduleNoticeDismissal(notice);
    if (error == null && notice == null) return const SizedBox.shrink();
    final isError = error != null;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: Key(isError ? 'work-error' : 'work-notice'),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          0,
          MoolSpacing.md,
          MoolSpacing.xs,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: MoolSpacing.sm,
          vertical: MoolSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isError ? const Color(0xFFFFEBEA) : const Color(0xFFEAF7E8),
          borderRadius: BorderRadius.circular(MoolRadii.control),
          border: Border.all(
            color: isError ? const Color(0xFFD3322F) : MoolColors.success,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: isError ? const Color(0xFFB42318) : MoolColors.success,
              size: 19,
            ),
            const SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: Text(
                error ?? notice!,
                style: TextStyle(
                  color: isError
                      ? const Color(0xFF7A271A)
                      : const Color(0xFF155B17),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              key: const Key('dismiss-work-message'),
              tooltip: 'Dismiss message',
              visualDensity: VisualDensity.compact,
              onPressed: widget.session.dismissMessages,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkCard extends StatelessWidget {
  const WorkCard({
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(MoolSpacing.md),
    this.onTap,
    this.keyName,
    super.key,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? keyName;

  @override
  Widget build(BuildContext context) {
    return MoolCardSurface(
      key: keyName == null ? null : Key(keyName!),
      color: color,
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}

class WorkSectionTitle extends StatelessWidget {
  const WorkSectionTitle({
    required this.title,
    required this.detail,
    this.trailing,
    super.key,
  });

  final String title;
  final String detail;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: MoolSpacing.xs),
          trailing!,
        ],
      ],
    );
  }
}

class WorkPrimaryButton extends StatelessWidget {
  const WorkPrimaryButton({
    required this.keyName,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.busy = false,
    super.key,
  });

  final String keyName;
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return MoolServicePrimaryButton(
      key: Key(keyName),
      label: label,
      onPressed: busy ? null : onPressed,
      icon: busy ? Icons.hourglass_top_rounded : icon,
    );
  }
}

class WorkPill extends StatelessWidget {
  const WorkPill({
    required this.label,
    this.color = MoolColors.success,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MoolSpacing.xs,
        vertical: MoolSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(MoolRadii.capsule),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkEmptyState extends StatelessWidget {
  const WorkEmptyState({
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onAction,
    this.keyName = 'work-empty',
    super.key,
  });

  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onAction;
  final String keyName;

  @override
  Widget build(BuildContext context) {
    return WorkCard(
      keyName: keyName,
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: MoolColors.muted,
            size: 36,
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MoolColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.xxs),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(color: MoolColors.muted),
          ),
          const SizedBox(height: MoolSpacing.sm),
          OutlinedButton(
            key: Key('$keyName-action'),
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
