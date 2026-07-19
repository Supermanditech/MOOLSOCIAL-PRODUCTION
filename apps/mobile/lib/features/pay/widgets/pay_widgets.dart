import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../pay_models.dart';
import '../pay_session.dart';

String payMoney(int value) => '₹$value';

class PayPageScaffold extends StatelessWidget {
  const PayPageScaffold({
    required this.session,
    required this.title,
    required this.subtitle,
    required this.body,
    this.fallbackBackRoute = '/app/pay/home',
    this.showBack = true,
    this.activeDock = 'pay',
    this.trailing,
    this.bottomAction,
    super.key,
  });

  final PaySession session;
  final String title;
  final String subtitle;
  final Widget body;
  final String fallbackBackRoute;
  final bool showBack;
  final String activeDock;
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
                  key: const Key('pay-back'),
                  tooltip: 'Go back',
                  onPressed: () {
                    session.clearMessages();
                    context.go(fallbackBackRoute);
                  },
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
            child:
                trailing ??
                IconButton.outlined(
                  key: const Key('pay-help-shortcut'),
                  tooltip: 'Payment help',
                  onPressed: () => session.showNotice(
                    'Payment help is ready. Every case keeps its payee, amount and bank references.',
                  ),
                  icon: const Icon(Icons.shield_outlined),
                ),
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
                PayMessageBanner(session: session),
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
                      child: SizedBox(
                        width: double.infinity,
                        child: bottomAction,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: PayBottomDock(session: session, active: activeDock),
    );
  }
}

class PayMessageBanner extends StatelessWidget {
  const PayMessageBanner({required this.session, super.key});

  final PaySession session;

  @override
  Widget build(BuildContext context) {
    final error = session.errorMessage;
    final notice = session.noticeMessage;
    if (error == null && notice == null) return const SizedBox.shrink();
    final isError = error != null;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: Key(isError ? 'pay-error' : 'pay-notice'),
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
              key: const Key('dismiss-pay-message'),
              tooltip: 'Dismiss message',
              visualDensity: VisualDensity.compact,
              onPressed: session.clearMessages,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class PayCard extends StatelessWidget {
  const PayCard({
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(MoolSpacing.md),
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return MoolCardSurface(
      color: color,
      padding: padding,
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: child,
    );
  }
}

class PaySectionTitle extends StatelessWidget {
  const PaySectionTitle(this.title, {this.detail, super.key});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: MoolSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: MoolColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 2),
            Text(
              detail!,
              style: const TextStyle(
                color: MoolColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PaySegment<T> extends StatelessWidget {
  const PaySegment({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    required this.keyFor,
    super.key,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;
  final String Function(T) keyFor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in values) ...[
            ChoiceChip(
              key: Key(keyFor(value)),
              selected: value == selected,
              label: Text(label(value)),
              onSelected: (_) => onSelected(value),
            ),
            const SizedBox(width: MoolSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class PayTrustRow extends StatelessWidget {
  const PayTrustRow({
    required this.icon,
    required this.title,
    required this.detail,
    this.color = MoolColors.success,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        const SizedBox(width: MoolSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PayChoiceTile extends StatelessWidget {
  const PayChoiceTile({
    required this.choice,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final PayChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PayCard(
      key: Key('pay-choice-${choice.id}'),
      color: selected ? const Color(0xFFF0F0FF) : Colors.white,
      padding: const EdgeInsets.all(MoolSpacing.sm),
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected ? MoolColors.navy : MoolColors.muted,
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  choice.title,
                  style: const TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  choice.detail,
                  style: const TextStyle(
                    color: MoolColors.muted,
                    fontSize: 11,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: MoolSpacing.xs),
          Text(
            payMoney(choice.amount),
            style: const TextStyle(
              color: MoolColors.success,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class PayPaymentMethods extends StatelessWidget {
  const PayPaymentMethods({required this.session, super.key});

  final PaySession session;

  @override
  Widget build(BuildContext context) {
    return PaySegment<ConsumerPaymentMethod>(
      values: ConsumerPaymentMethod.values,
      selected: session.paymentMethod,
      label: (value) => value.label,
      keyFor: (value) => 'pay-method-${value.name}',
      onSelected: session.choosePaymentMethod,
    );
  }
}

class PayPrimaryButton extends StatelessWidget {
  const PayPrimaryButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.keyName,
    this.icon = Icons.arrow_forward_rounded,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final String? keyName;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: keyName == null ? null : Key(keyName!),
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(busy ? 'Please wait…' : label),
    );
  }
}

class PayBottomDock extends StatelessWidget {
  const PayBottomDock({required this.session, required this.active, super.key});

  final PaySession session;
  final String active;

  @override
  Widget build(BuildContext context) {
    void open(String route) {
      session.clearMessages();
      context.go(route);
    }

    return MoolOutcomeDock(
      semanticLabel: 'Pay navigation',
      activeId: active,
      mool: MoolDockAction(
        keyName: 'pay-dock-mool',
        id: 'mool',
        label: 'Mool',
        icon: Icons.blur_circular_rounded,
        onPressed: () => open('/app/mool'),
      ),
      actions: [
        MoolDockAction(
          keyName: 'pay-dock-pay',
          id: 'pay',
          label: 'Pay',
          icon: Icons.account_balance_wallet_rounded,
          onPressed: () => open('/app/pay/home'),
        ),
        MoolDockAction(
          keyName: 'pay-dock-receipts',
          id: 'receipts',
          label: 'Receipts',
          icon: Icons.receipt_long_rounded,
          onPressed: () => open('/app/pay/receipts'),
        ),
        MoolDockAction(
          keyName: 'pay-dock-requests',
          id: 'requests',
          label: 'Requests',
          icon: Icons.mark_email_unread_outlined,
          onPressed: () => open('/app/pay/requests'),
        ),
      ],
      chat: MoolDockAction(
        keyName: 'pay-dock-chat',
        id: 'chat',
        label: 'Chat',
        icon: Icons.chat_bubble_outline_rounded,
        onPressed: () => open('/app/chat/inbox?return=/app/pay/home'),
      ),
    );
  }
}
