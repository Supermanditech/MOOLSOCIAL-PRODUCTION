import 'package:flutter/material.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';

abstract final class ChatMotion {
  static const focus = MoolMotion.quick;
  static const stateChange = MoolMotion.standard;
  static const routeChange = MoolMotion.deliberate;
  static const recovery = MoolMotion.quick;

  static Duration resolve(BuildContext context, Duration duration) =>
      MoolMotion.accessible(context, duration);

  static AnimationStyle sheetStyle(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnimationStyle(
      duration: reduced ? Duration.zero : routeChange,
      reverseDuration: reduced ? Duration.zero : recovery,
      curve: reduced ? Curves.linear : MoolMotion.enter,
      reverseCurve: reduced ? Curves.linear : MoolMotion.change,
    );
  }
}

class ChatSearchFocusMotion extends StatelessWidget {
  const ChatSearchFocusMotion({
    required this.focused,
    required this.child,
    super.key,
  });

  final bool focused;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    key: const Key('chat-search-focus-motion'),
    duration: ChatMotion.resolve(context, ChatMotion.focus),
    curve: MoolMotion.change,
    decoration: BoxDecoration(
      color: focused ? Colors.white : const Color(0xFFF0F1F5),
      borderRadius: BorderRadius.circular(MoolRadii.capsule),
      border: Border.all(
        color: focused
            ? MoolColors.navy.withValues(alpha: .72)
            : Colors.transparent,
        width: 1.5,
      ),
      boxShadow: focused
          ? [
              BoxShadow(
                color: MoolColors.navy.withValues(alpha: .08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : const [],
    ),
    child: child,
  );
}

class ChatActionIconMotion extends StatelessWidget {
  const ChatActionIconMotion({
    required this.stateKey,
    required this.icon,
    super.key,
  });

  final Object stateKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: AnimatedSwitcher(
      key: const Key('chat-search-action-icon-motion'),
      duration: ChatMotion.resolve(context, ChatMotion.focus),
      reverseDuration: ChatMotion.resolve(context, ChatMotion.focus),
      switchInCurve: MoolMotion.enter,
      switchOutCurve: MoolMotion.change,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: .9, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: ExcludeSemantics(
        key: ValueKey<Object>(stateKey),
        child: Icon(icon),
      ),
    ),
  );
}

class ChatFiniteIncomingMotion extends StatelessWidget {
  const ChatFiniteIncomingMotion({
    required this.stateKey,
    required this.child,
    this.duration = ChatMotion.stateChange,
    super.key,
  });

  final Object stateKey;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      key: ValueKey<Object>(stateKey),
      tween: Tween<double>(begin: reduced ? 1 : .76, end: 1),
      duration: ChatMotion.resolve(context, duration),
      curve: MoolMotion.enter,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 6),
          transformHitTests: false,
          child: child,
        ),
      ),
    );
  }
}

class ChatListEntryMotion extends StatelessWidget {
  const ChatListEntryMotion({
    required this.stateKey,
    required this.index,
    required this.child,
    super.key,
  });

  final Object stateKey;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(
      milliseconds:
          ChatMotion.stateChange.inMilliseconds + index.clamp(0, 5) * 20,
    );
    return ChatFiniteIncomingMotion(
      key: ValueKey<Object>('chat-list-entry-$stateKey'),
      stateKey: stateKey,
      duration: duration,
      child: child,
    );
  }
}
