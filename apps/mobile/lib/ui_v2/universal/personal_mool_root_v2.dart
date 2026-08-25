import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/mool_design_system.dart';
import '../../core/design/mool_theme.dart';
import 'mool_global_navigation_v2.dart';

export 'mool_global_navigation_v2.dart'
    show
        MoolActionFamilySpec,
        MoolDirectActionSpec,
        PersonalMoolActionSpec,
        moolActionFamilies,
        personalMoolRootActions;

class PersonalMoolRootV2 extends StatefulWidget {
  const PersonalMoolRootV2({
    required this.onBack,
    required this.onOpenAction,
    required this.onOpenChat,
    this.onSignOut,
    this.onOpenRoute,
    this.areaLabel,
    super.key,
  });

  final VoidCallback onBack;
  final ValueChanged<PersonalMoolActionSpec> onOpenAction;
  final VoidCallback onOpenChat;
  final Future<void> Function()? onSignOut;
  final ValueChanged<String>? onOpenRoute;
  final String? areaLabel;

  @override
  State<PersonalMoolRootV2> createState() => _PersonalMoolRootV2State();
}

class _PersonalMoolRootV2State extends State<PersonalMoolRootV2>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arrival = AnimationController(
    vsync: this,
    duration: MoolHomeHubTokens.arrivalDuration,
  );

  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    final reduceMotion = media.disableAnimations || media.accessibleNavigation;
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _arrival.value = 1;
    } else {
      _arrival.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _arrival.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeMotion = CurvedAnimation(
      parent: _arrival,
      curve: MoolMotion.enter,
    );
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onBack();
      },
      child: FadeTransition(
        key: const Key('mool-home-route-motion'),
        opacity: routeMotion,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-.025, 0),
            end: Offset.zero,
          ).animate(routeMotion),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: MoolColors.navy,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: Color(0xFFF5F5F7),
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: Scaffold(
              key: const Key('personal-mool-root-v2'),
              backgroundColor: const Color(0xFFF5F5F7),
              body: SafeArea(
                bottom: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: MoolMetrics.maximumContentWidth,
                    ),
                    child: Column(
                      children: [
                        _MoolRootHeader(
                          onOpenChat: widget.onOpenChat,
                          onSignOut: widget.onSignOut,
                        ),
                        Expanded(
                          child: _MoolHomeDashboard(
                            arrival: _arrival,
                            onOpenRoute: widget.onOpenRoute,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: MoolGlobalNavigationV2(
                activeId: 'mool',
                onOpenMool: null,
                onOpenAction: widget.onOpenAction,
                onOpenChat: widget.onOpenChat,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoolRootHeader extends StatelessWidget {
  const _MoolRootHeader({required this.onOpenChat, this.onSignOut});

  final VoidCallback onOpenChat;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.xs,
          MoolSpacing.sm,
          0,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onSignOut != null) ...[
                Semantics(
                  button: true,
                  label: 'Sign out of MoolSocial',
                  onTap: () => _requestSignOut(context),
                  excludeSemantics: true,
                  child: SizedBox(
                    width: MoolMetrics.minimumTapTarget,
                    height: MoolMetrics.minimumTapTarget,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 1,
                      shadowColor: const Color(0x18000000),
                      child: InkWell(
                        key: const Key('mool-home-sign-out'),
                        customBorder: const CircleBorder(),
                        onTap: () => _requestSignOut(context),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: MoolColors.navy,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: MoolSpacing.xs),
              ],
              Semantics(
                button: true,
                label: 'Open Chat',
                onTap: onOpenChat,
                excludeSemantics: true,
                child: SizedBox(
                  width: MoolMetrics.minimumTapTarget,
                  height: MoolMetrics.minimumTapTarget,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 1,
                    shadowColor: const Color(0x18000000),
                    child: InkWell(
                      key: const Key('mool-home-chat'),
                      customBorder: const CircleBorder(),
                      onTap: onOpenChat,
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: MoolColors.navy,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out of MoolSocial?'),
        content: const Text(
          'You can sign in again with any supported method. '
          'Your language and serviceable area stay saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay signed in'),
          ),
          FilledButton(
            key: const Key('mool-confirm-sign-out'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await onSignOut?.call();
  }
}

class _MoolHomeDashboard extends StatelessWidget {
  const _MoolHomeDashboard({required this.arrival, required this.onOpenRoute});

  final Animation<double> arrival;
  final ValueChanged<String>? onOpenRoute;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('mool-home-dashboard'),
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.md,
        MoolSpacing.xs,
        MoolSpacing.md,
        MoolSpacing.md,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: FadeTransition(
          opacity: CurvedAnimation(parent: arrival, curve: MoolMotion.enter),
          child: MoolMainDomainMenu(
            keyPrefix: 'mool-home',
            onOpenFamily: (family) => onOpenRoute?.call(family.route),
          ),
        ),
      ),
    );
  }
}
