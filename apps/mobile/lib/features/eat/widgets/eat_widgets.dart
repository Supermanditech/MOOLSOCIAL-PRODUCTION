import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../eat_session.dart';

String eatMoney(int value) => '₹$value';

class EatPageScaffold extends StatelessWidget {
  const EatPageScaffold({
    required this.session,
    required this.title,
    required this.subtitle,
    required this.body,
    this.activeDock = 'eat',
    this.fallbackBackRoute = '/app/eat/home',
    this.showBack = true,
    this.trailing,
    this.bottomAction,
    super.key,
  });

  final EatSession session;
  final String title;
  final String subtitle;
  final Widget body;
  final String activeDock;
  final String fallbackBackRoute;
  final bool showBack;
  final Widget? trailing;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  onPressed: () => context.go(fallbackBackRoute),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
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
          Padding(
            padding: const EdgeInsets.only(right: MoolSpacing.sm),
            child: trailing ?? EatBasketButton(session: session),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
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
      bottomNavigationBar: EatBottomDock(session: session, active: activeDock),
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

class EatBottomDock extends StatelessWidget {
  const EatBottomDock({required this.session, required this.active, super.key});

  final EatSession session;
  final String active;

  @override
  Widget build(BuildContext context) {
    void open(String route) {
      session.clearMessages();
      context.go(route);
    }

    return MoolOutcomeDock(
      semanticLabel: 'Eat navigation',
      activeId: active,
      mool: MoolDockAction(
        keyName: 'eat-dock-mool',
        id: 'mool',
        label: 'Mool',
        icon: Icons.blur_circular_rounded,
        onPressed: () => open('/app/mool'),
      ),
      actions: [
        MoolDockAction(
          keyName: 'eat-dock-order',
          id: 'order',
          label: 'Order',
          icon: Icons.restaurant_menu_rounded,
          onPressed: () => open('/app/eat/order'),
        ),
        MoolDockAction(
          keyName: 'eat-dock-table',
          id: 'table',
          label: 'Table',
          icon: Icons.table_restaurant_outlined,
          onPressed: () => open('/app/eat/table'),
        ),
        MoolDockAction(
          keyName: 'eat-dock-tiffin',
          id: 'tiffin',
          label: 'Tiffin',
          icon: Icons.lunch_dining_outlined,
          onPressed: () => open('/app/eat/tiffin'),
        ),
      ],
      chat: MoolDockAction(
        keyName: 'eat-dock-chat',
        id: 'chat',
        label: 'Chat',
        icon: Icons.chat_bubble_outline_rounded,
        onPressed: () {
          final current = GoRouterState.of(context).uri.toString();
          open(
            Uri(
              path: '/app/chat/inbox',
              queryParameters: {'return': current},
            ).toString(),
          );
        },
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
