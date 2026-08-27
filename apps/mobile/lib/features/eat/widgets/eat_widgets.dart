import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../../../ui_v2/profile/global_profile_panel_v2.dart';
import '../../../ui_v2/universal/mool_global_navigation_v2.dart';
import '../eat_models.dart';
import '../eat_session.dart';

String eatMoney(int value) => '₹$value';

GlobalProfileContextAction _foodProfileContext(
  EatSession session,
  ValueChanged<String> onOpenRoute,
) {
  final order = session.orderReceipt;
  if (order != null &&
      !session.foodOrderCancelled &&
      session.orderStage != EatOrderStage.delivered) {
    return GlobalProfileContextAction(
      id: 'food-order',
      title: 'Your food order',
      detail: '${session.orderStage.title} · ${order.restaurant.name}',
      actionLabel: 'Track order',
      icon: Icons.delivery_dining_outlined,
      accentColor: const Color(0xFFF97316),
      gradientColors: const [Color(0xFFE65100), Color(0xFFFF8A00)],
      onPressed: () => onOpenRoute('/app/eat/order/${order.id}'),
    );
  }

  final table = session.tableReceipt;
  if (table != null && !session.tableBookingCancelled) {
    return GlobalProfileContextAction(
      id: 'food-table',
      title: 'Your table booking',
      detail:
          '${table.restaurant.name} · ${table.people} people · ${table.time}',
      actionLabel: 'View booking',
      icon: Icons.table_restaurant_outlined,
      accentColor: const Color(0xFF7C3AED),
      gradientColors: const [Color(0xFF5B21B6), Color(0xFF8B5CF6)],
      onPressed: () => onOpenRoute('/app/eat/table/${table.id}'),
    );
  }

  final tiffin = session.tiffinReceipt;
  if (tiffin != null && !session.tiffinCancelled) {
    return GlobalProfileContextAction(
      id: 'food-tiffin',
      title: 'Your tiffin plan',
      detail: '${tiffin.kitchen.name} · ${tiffin.plan.label}',
      actionLabel: 'Manage plan',
      icon: Icons.lunch_dining_outlined,
      accentColor: const Color(0xFF0F766E),
      gradientColors: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
      onPressed: () => onOpenRoute('/app/eat/tiffin/${tiffin.id}'),
    );
  }

  if (session.itemCount > 0) {
    return GlobalProfileContextAction(
      id: 'food-basket',
      title: 'Your food basket',
      detail: '${session.itemCount} items · ${eatMoney(session.orderTotal)}',
      actionLabel: 'Open basket',
      icon: Icons.shopping_basket_outlined,
      accentColor: const Color(0xFFF97316),
      gradientColors: const [Color(0xFFE65100), Color(0xFFFF8A00)],
      onPressed: () => onOpenRoute('/app/eat/basket'),
    );
  }

  return GlobalProfileContextAction(
    id: 'food-table-discovery',
    title: 'Reserve a table',
    detail: 'Choose a restaurant and review timing before you confirm.',
    actionLabel: 'Book a table',
    icon: Icons.table_restaurant_outlined,
    accentColor: const Color(0xFFF97316),
    gradientColors: const [Color(0xFFE65100), Color(0xFFFF8A00)],
    onPressed: () => onOpenRoute('/app/eat/table'),
  );
}

class EatPageScaffold extends StatelessWidget {
  const EatPageScaffold({
    required this.session,
    required this.title,
    required this.subtitle,
    required this.body,
    this.activeLocalAction = '',
    this.fallbackBackRoute = '/app/eat/home',
    this.showBack = true,
    this.trailing,
    this.showTrailing = true,
    this.bottomAction,
    super.key,
  });

  final EatSession session;
  final String title;
  final String subtitle;
  final Widget body;
  final String activeLocalAction;
  final String fallbackBackRoute;
  final bool showBack;
  final Widget? trailing;
  final bool showTrailing;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    void leaveContentDepth() {
      session.clearMessages();
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(fallbackBackRoute);
      }
    }

    void openLocal(String route) {
      session.clearMessages();
      context.push(route);
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

    void switchGlobalDestination(String route) {
      session.clearMessages();
      openMoolConnectedRoute(context, activeFamilyId: 'eat', route: route);
    }

    return PopScope<Object?>(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) leaveContentDepth();
      },
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          backgroundColor: MoolColors.canvas,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          toolbarHeight: 72,
          leadingWidth: showBack ? 64 : 16,
          leading: showBack
              ? Padding(
                  padding: const EdgeInsets.only(left: MoolSpacing.sm),
                  child: IconButton.outlined(
                    key: const Key('eat-back'),
                    tooltip: 'Go back',
                    onPressed: leaveContentDepth,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 19,
                    ),
                  ),
                )
              : null,
          titleSpacing: showBack ? 4 : MoolSpacing.md,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.35,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            MoolGlobalChatShortcut(
              keyName: 'eat-global-chat',
              onPressed: openChat,
            ),
            const SizedBox(width: 4),
            if (showTrailing)
              Padding(
                padding: const EdgeInsets.only(right: MoolSpacing.sm),
                child: trailing ?? EatBasketButton(session: session),
              ),
            if (!showBack)
              Padding(
                padding: const EdgeInsets.only(right: MoolSpacing.sm),
                child: MoolGlobalProfileShortcutV2(
                  keyName: 'eat-global-profile',
                  onPressed: () => showGlobalProfilePanelV2(
                    context,
                    contextAction: _foodProfileContext(session, openGlobal),
                    onOpenRoute: openGlobal,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
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
                  EatMessageBanner(session: session),
                  Expanded(child: body),
                  if (bottomAction != null)
                    Material(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          MoolSpacing.md,
                          MoolSpacing.sm,
                          MoolSpacing.md,
                          MoolSpacing.xs,
                        ),
                        child: SafeArea(
                          top: false,
                          bottom: false,
                          child: SizedBox(
                            width: double.infinity,
                            child: bottomAction,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: MoolDestinationNavigationV2(
          activeId: 'eat',
          destinationLabel: 'Food',
          selectedLocalIndex: activeLocalAction == 'table' ? 1 : 0,
          localActionCount: 2,
          localNavigation: MoolLocalNavigationRail(
            key: const Key('eat-local-navigation'),
            familyId: 'eat',
            surfaceTone: MoolLocalNavigationSurfaceTone.light,
            semanticLabel: 'Food choices: Order Food and Book Table.',
            activeId: activeLocalAction,
            actions: [
              MoolLocalNavigationAction(
                keyName: 'eat-local-order',
                id: 'order',
                label: 'Order Food',
                icon: Icons.restaurant_menu_rounded,
                onPressed: activeLocalAction == 'order'
                    ? null
                    : () => openLocal('/app/eat/home'),
              ),
              MoolLocalNavigationAction(
                keyName: 'eat-local-table',
                id: 'table',
                label: 'Book Table',
                icon: Icons.table_restaurant_outlined,
                onPressed: activeLocalAction == 'table'
                    ? null
                    : () => openLocal('/app/eat/table'),
              ),
            ],
          ),
          onOpenMool: () => openGlobal('/app/mool?from=eat'),
          onOpenAction: (action) => switchGlobalDestination(action.route),
          onPreviousLocalAction: () => openLocal(
            activeLocalAction == 'table' ? '/app/eat/home' : '/app/eat/table',
          ),
          onNextLocalAction: () => openLocal(
            activeLocalAction == 'table' ? '/app/eat/home' : '/app/eat/table',
          ),
          onOpenChat: openChat,
        ),
      ),
    );
  }
}

class EatMessageBanner extends StatelessWidget {
  const EatMessageBanner({required this.session, super.key});

  final EatSession session;

  @override
  Widget build(BuildContext context) {
    final error = session.errorMessage;
    final notice = session.noticeMessage;
    if (error == null && notice == null) return const SizedBox.shrink();
    final isError = error != null;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: Key(isError ? 'eat-error' : 'eat-notice'),
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
              key: const Key('dismiss-eat-message'),
              tooltip: 'Dismiss message',
              onPressed: session.clearMessages,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class EatBasketButton extends StatelessWidget {
  const EatBasketButton({required this.session, super.key});

  final EatSession session;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: session.itemCount > 0,
      label: Text('${session.itemCount}'),
      backgroundColor: MoolColors.orange,
      textColor: MoolColors.ink,
      child: IconButton.outlined(
        key: const Key('eat-open-basket'),
        tooltip: 'Open food basket',
        onPressed: () => context.go('/app/eat/basket'),
        icon: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}

class EatSurfaceCard extends StatelessWidget {
  const EatSurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(MoolSpacing.md),
    this.color = Colors.white,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return MoolCardSurface(color: color, padding: padding, child: child);
  }
}

class EatQuantityControl extends StatelessWidget {
  const EatQuantityControl({
    required this.itemId,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    super.key,
  });

  final String itemId;
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F8),
        borderRadius: BorderRadius.circular(MoolRadii.capsule),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: Key('eat-minus-$itemId'),
            tooltip: 'Decrease quantity',
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: MoolColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            key: Key('eat-plus-$itemId'),
            tooltip: 'Increase quantity',
            onPressed: onIncrease,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class EatPriceSummary extends StatelessWidget {
  const EatPriceSummary({required this.session, super.key});

  final EatSession session;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {bool strong = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: strong ? MoolColors.ink : MoolColors.muted,
                  fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: strong ? MoolColors.ink : MoolColors.muted,
                fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return EatSurfaceCard(
      child: Column(
        children: [
          row('Food', eatMoney(session.subtotal)),
          row(
            'Delivery',
            session.deliveryFee == 0 ? 'Free' : eatMoney(session.deliveryFee),
          ),
          row('Taxes', eatMoney(session.taxes)),
          const Divider(),
          row('Total', eatMoney(session.orderTotal), strong: true),
        ],
      ),
    );
  }
}

class EatTrustStrip extends StatelessWidget {
  const EatTrustStrip({required this.items, super.key});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: MoolSpacing.xs,
      runSpacing: MoolSpacing.xs,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MoolSpacing.sm,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7E8),
                borderRadius: BorderRadius.circular(MoolRadii.capsule),
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${item.$1} · ',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    TextSpan(text: item.$2),
                  ],
                ),
                style: const TextStyle(color: Color(0xFF155B17), fontSize: 11),
              ),
            ),
          )
          .toList(),
    );
  }
}
