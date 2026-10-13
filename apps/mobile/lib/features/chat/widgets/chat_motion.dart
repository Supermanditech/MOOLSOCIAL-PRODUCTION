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
    this.motionKeyName = 'chat-search-focus-motion',
    super.key,
  });

  final bool focused;
  final Widget child;
  final String motionKeyName;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    key: Key(motionKeyName),
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

class ChatFocusMotion extends StatefulWidget {
  const ChatFocusMotion({
    required this.motionKeyName,
    required this.child,
    super.key,
  });

  final String motionKeyName;
  final Widget child;

  @override
  State<ChatFocusMotion> createState() => _ChatFocusMotionState();
}

class _ChatFocusMotionState extends State<ChatFocusMotion> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) => Focus(
    onFocusChange: (focused) {
      if (_focused != focused) setState(() => _focused = focused);
    },
    child: ChatSearchFocusMotion(
      motionKeyName: widget.motionKeyName,
      focused: _focused,
      child: widget.child,
    ),
  );
}

class ChatActionIconMotion extends StatelessWidget {
  const ChatActionIconMotion({
    required this.stateKey,
    required this.icon,
    this.size,
    this.color,
    super.key,
  });

  final Object stateKey;
  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: AnimatedSwitcher(
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
        child: Icon(icon, size: size, color: color),
      ),
    ),
  );
}

class ChatRouteEntryMotion extends StatelessWidget {
  const ChatRouteEntryMotion({
    required this.stateKey,
    required this.child,
    this.forward = true,
    super.key,
  });

  final Object stateKey;
  final bool forward;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return KeyedSubtree(
      key: ValueKey<Object>('chat-route-$stateKey'),
      child: TweenAnimationBuilder<double>(
        key: const Key('chat-route-entry-tween'),
        tween: Tween<double>(begin: reduced ? 1 : .7, end: 1),
        duration: ChatMotion.resolve(context, ChatMotion.routeChange),
        curve: MoolMotion.enter,
        child: child,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            key: const Key('chat-route-motion-translation'),
            offset: Offset((1 - value) * (forward ? 20 : -14), 0),
            transformHitTests: false,
            child: child,
          ),
        ),
      ),
    );
  }
}

class ChatSelectionMotion extends StatelessWidget {
  const ChatSelectionMotion({
    required this.selected,
    required this.child,
    super.key,
  });

  final bool selected;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedScale(
    key: const Key('chat-selection-motion'),
    scale: selected ? 1 : .985,
    duration: ChatMotion.resolve(context, ChatMotion.focus),
    curve: MoolMotion.change,
    child: child,
  );
}

class ChatExpandableMotion extends StatelessWidget {
  const ChatExpandableMotion({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSize(
    key: const Key('chat-expandable-motion'),
    duration: ChatMotion.resolve(context, ChatMotion.stateChange),
    reverseDuration: ChatMotion.resolve(context, ChatMotion.recovery),
    curve: MoolMotion.enter,
    alignment: Alignment.topCenter,
    clipBehavior: Clip.hardEdge,
    child: child,
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
      key: ValueKey<Object>('chat-incoming-motion-tween-$stateKey'),
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
