import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../book_session.dart';

String bookMoney(int value) => '₹$value';

class BookPageScaffold extends StatelessWidget {
  const BookPageScaffold({
    required this.session,
    required this.title,
    required this.subtitle,
    required this.body,
    this.activeDock = 'book',
    this.fallbackBackRoute = '/app/book/home',
    this.showBack = true,
    this.trailing,
    this.bottomAction,
    super.key,
  });

  final BookSession session;
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
                  key: const Key('book-back'),
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
                  tooltip: 'Open booking help',
                  onPressed: () => session.showNotice(
                    'Booking help is ready. Your current selection remains saved.',
                  ),
                  icon: const Icon(Icons.support_agent_rounded),
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
                BookMessageBanner(session: session),
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
      bottomNavigationBar: BookBottomDock(session: session, active: activeDock),
    );
  }
}

class BookMessageBanner extends StatelessWidget {
  const BookMessageBanner({required this.session, super.key});

  final BookSession session;

  @override
  Widget build(BuildContext context) {
    final error = session.errorMessage;
    final notice = session.noticeMessage;
    if (error == null && notice == null) return const SizedBox.shrink();
    final isError = error != null;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: Key(isError ? 'book-error' : 'book-notice'),
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
              key: const Key('dismiss-book-message'),
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

class BookCard extends StatelessWidget {
  const BookCard({
    required this.child,
    this.padding = const EdgeInsets.all(MoolSpacing.md),
    this.color = Colors.white,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
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

class BookSectionTitle extends StatelessWidget {
  const BookSectionTitle(this.title, {this.detail, super.key});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Column(
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class BookFact extends StatelessWidget {
  const BookFact({
    required this.icon,
    required this.title,
    required this.detail,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFECECFB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: MoolColors.navy, size: 21),
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

class BookBottomDock extends StatelessWidget {
  const BookBottomDock({
    required this.session,
    required this.active,
    super.key,
  });

  final BookSession session;
  final String active;

  @override
  Widget build(BuildContext context) {
    void clear() => session.clearMessages();
    return MoolOutcomeDock(
      semanticLabel: 'Booking navigation',
      activeId: active,
      mool: MoolDockAction(
        keyName: 'book-dock-mool',
        id: 'mool',
        label: 'Mool',
        icon: Icons.blur_circular_rounded,
        onPressed: () {
          clear();
          context.go('/app/mool');
        },
      ),
      actions: [
        MoolDockAction(
          keyName: 'book-dock-book',
          id: 'book',
          label: 'Book',
          icon: Icons.calendar_month_outlined,
          onPressed: () {
            clear();
            context.go('/app/book/home');
          },
        ),
        MoolDockAction(
          keyName: 'book-dock-activity',
          id: 'activity',
          label: 'Activity',
          icon: Icons.event_available_outlined,
          onPressed: () {
            clear();
            if (session.task != null) {
              context.go('/app/book/task/live');
            } else if (session.salonBooking != null) {
              context.go('/app/book/salon/confirmed');
            } else if (session.appointment != null) {
              context.go('/app/book/doctor/followup');
            } else {
              session.showNotice(
                'Your confirmed appointments and tasks will appear here.',
              );
            }
          },
        ),
        MoolDockAction(
          keyName: 'book-dock-help',
          id: 'help',
          label: 'Help',
          icon: Icons.support_agent_rounded,
          onPressed: () {
            clear();
            if (session.task != null) {
              context.go('/app/book/task/support');
            } else if (session.salonBooking != null) {
              context.go('/app/book/salon/support');
            } else {
              session.showNotice(
                'Open a confirmed appointment or task to attach its saved evidence.',
              );
            }
          },
        ),
      ],
      chat: MoolDockAction(
        keyName: 'book-dock-chat',
        id: 'chat',
        label: 'Chat',
        icon: Icons.chat_bubble_outline_rounded,
        onPressed: () {
          final current = GoRouterState.of(context).uri.toString();
          clear();
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
