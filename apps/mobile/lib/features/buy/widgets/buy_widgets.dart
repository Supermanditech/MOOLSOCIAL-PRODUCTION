import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../buy_models.dart';
import '../buy_session.dart';

String buyMoney(int value) => '₹$value';

void buyBack(BuildContext context, String fallback) {
  context.go(fallback);
}

class BuyPageScaffold extends StatelessWidget {
  const BuyPageScaffold({
    required this.session,
    required this.title,
    required this.subtitle,
    required this.body,
    this.activeDock = 'shop',
    this.fallbackBackRoute = '/app/buy',
    this.showBack = true,
    this.trailing,
    this.bottomAction,
    super.key,
  });

  final BuySession session;
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
                  key: const Key('buy-back'),
                  tooltip: 'Go back',
                  onPressed: () => buyBack(context, fallbackBackRoute),
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
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(right: MoolSpacing.sm),
              child: trailing!,
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: MoolSpacing.sm),
              child: BuyBasketButton(session: session),
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
                BuyMessageBanner(session: session),
                Expanded(child: body),
                if (bottomAction != null)
                  Material(
                    color: Colors.white,
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          MoolSpacing.md,
                          MoolSpacing.sm,
                          MoolSpacing.md,
                          MoolSpacing.xs,
                        ),
                        child: bottomAction!,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BuyBottomDock(session: session, active: activeDock),
    );
  }
}

class BuyMessageBanner extends StatelessWidget {
  const BuyMessageBanner({required this.session, super.key});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    final error = session.errorMessage;
    final notice = session.noticeMessage;
    if (error == null && notice == null) return const SizedBox.shrink();
    final isError = error != null;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: Key(isError ? 'buy-error' : 'buy-notice'),
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
              key: const Key('dismiss-buy-message'),
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

class BuyBasketButton extends StatelessWidget {
  const BuyBasketButton({required this.session, super.key});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: session.itemCount > 0,
      label: Text('${session.itemCount}'),
      backgroundColor: MoolColors.orange,
      textColor: MoolColors.ink,
      child: IconButton.outlined(
        key: const Key('buy-open-basket'),
        tooltip: 'Open basket',
        onPressed: () => context.go('/app/buy/basket'),
        icon: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}

class BuyBottomDock extends StatelessWidget {
  const BuyBottomDock({required this.session, required this.active, super.key});

  final BuySession session;
  final String active;

  @override
  Widget build(BuildContext context) {
    return MoolOutcomeDock(
      semanticLabel: 'Buy navigation',
      activeId: active,
      mool: MoolDockAction(
        keyName: 'buy-dock-mool',
        id: 'mool',
        label: 'Mool',
        icon: Icons.blur_circular_rounded,
        onPressed: () => context.go('/app/mool'),
      ),
      actions: [
        MoolDockAction(
          keyName: 'buy-dock-shop',
          id: 'shop',
          label: 'Shop',
          icon: Icons.storefront_outlined,
          onPressed: () => context.go('/app/buy/grocery'),
        ),
        MoolDockAction(
          keyName: 'buy-dock-basket',
          id: 'basket',
          label: session.itemCount == 0
              ? 'Basket'
              : 'Basket ${session.itemCount}',
          icon: Icons.shopping_bag_outlined,
          onPressed: () => context.go('/app/buy/basket'),
        ),
        MoolDockAction(
          keyName: 'buy-dock-orders',
          id: 'orders',
          label: 'Order',
          icon: Icons.receipt_long_outlined,
          onPressed: () {
            final receipt = session.receipt;
            if (receipt == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Place an order to see its live status here.'),
                ),
              );
              return;
            }
            final route = receipt.fulfilment == BuyFulfilment.storePickup
                ? '/app/buy/order/${receipt.id}/collection'
                : '/app/buy/order/${receipt.id}';
            context.go(route);
          },
        ),
      ],
      chat: MoolDockAction(
        keyName: 'buy-dock-chat',
        id: 'chat',
        label: 'Chat',
        icon: Icons.chat_bubble_outline_rounded,
        onPressed: () {
          final current = GoRouterState.of(context).uri.toString();
          context.go(
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

class BuySurfaceCard extends StatelessWidget {
  const BuySurfaceCard({
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

class BuyPriceSummary extends StatelessWidget {
  const BuyPriceSummary({required this.session, super.key});

  final BuySession session;

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

    return BuySurfaceCard(
      child: Column(
        children: [
          row('Items', buyMoney(session.subtotal)),
          row(
            'Delivery',
            session.deliveryFee == 0 ? 'Free' : buyMoney(session.deliveryFee),
          ),
          if (session.discount > 0)
            row('Coupon', '−${buyMoney(session.discount)}'),
          const Divider(),
          row('Total', buyMoney(session.total), strong: true),
        ],
      ),
    );
  }
}

class BuyQuantityControl extends StatelessWidget {
  const BuyQuantityControl({
    required this.productId,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    super.key,
  });

  final String productId;
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
            key: Key('buy-minus-$productId'),
            tooltip: 'Decrease quantity',
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_rounded),
          ),
          Semantics(
            label: 'Quantity $quantity',
            child: SizedBox(
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
          ),
          IconButton(
            key: Key('buy-plus-$productId'),
            tooltip: 'Increase quantity',
            onPressed: onIncrease,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
