import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/mool_design_system.dart';
import '../../core/design/mool_theme.dart';

@immutable
class LegacyRouteContainmentSpec {
  const LegacyRouteContainmentSpec({
    required this.id,
    required this.label,
    required this.currentRootLabel,
    required this.currentRootRoute,
    required this.detail,
  });

  final String id;
  final String label;
  final String currentRootLabel;
  final String currentRootRoute;
  final String detail;

  String get recoveryLocation => Uri(
    path: '/app/action-unavailable',
    queryParameters: {'reason': id},
  ).toString();
}

const legacyRouteContainmentSpecs = <String, LegacyRouteContainmentSpec>{
  'retailer-services': LegacyRouteContainmentSpec(
    id: 'retailer-services',
    label: 'Business services',
    currentRootLabel: 'Store',
    currentRootRoute: '/app/work/my-work',
    detail:
        'Service activation is not available from this link. No service was activated or charged. Open Store to use available options.',
  ),
  'retailer-customer-detail': LegacyRouteContainmentSpec(
    id: 'retailer-customer-detail',
    label: 'Customer details',
    currentRootLabel: 'Store',
    currentRootRoute: '/app/work/my-work',
    detail:
        'Customer account changes are not available from this link. Open Store to view available customer and Sales records. No message or payment was sent.',
  ),
  'retailer-campaigns': LegacyRouteContainmentSpec(
    id: 'retailer-campaigns',
    label: 'Promotions',
    currentRootLabel: 'Store',
    currentRootRoute: '/app/work/my-work',
    detail:
        'Promotions are not available from this link. No campaign was created or message sent. Open Store to use available options.',
  ),
  'tiffin': LegacyRouteContainmentSpec(
    id: 'tiffin',
    label: 'Tiffin',
    currentRootLabel: 'Eat',
    currentRootRoute: '/app/eat/home',
    detail:
        'Tiffin is not part of the current Personal MVP. Your old link did not start a meal plan or charge.',
  ),
  'get-it-done': LegacyRouteContainmentSpec(
    id: 'get-it-done',
    label: 'Get It Done',
    currentRootLabel: 'Book',
    currentRootRoute: '/app/book/doctor',
    detail:
        'Get It Done is not part of the current Personal MVP. Your old link did not create a task or booking.',
  ),
  'standalone-pay': LegacyRouteContainmentSpec(
    id: 'standalone-pay',
    label: 'Standalone Pay',
    currentRootLabel: 'Mool',
    currentRootRoute: '/app/mool',
    detail:
        'Standalone Pay is not available from the launcher. Payment and receipts stay inside their exact transaction.',
  ),
  'delivery': LegacyRouteContainmentSpec(
    id: 'delivery',
    label: 'Delivery Work',
    currentRootLabel: 'Work',
    currentRootRoute: '/app/work/earn',
    detail:
        'This generic Delivery link cannot open work. Use Earn Today for an exact eligible, funded opportunity.',
  ),
  'onboard': LegacyRouteContainmentSpec(
    id: 'onboard',
    label: 'Onboard',
    currentRootLabel: 'Work',
    currentRootRoute: '/app/work/my-work',
    detail:
        'This old Onboard link cannot start workspace setup. Open Workspace and choose an available next step.',
  ),
  'verify': LegacyRouteContainmentSpec(
    id: 'verify',
    label: 'Verify',
    currentRootLabel: 'Work',
    currentRootRoute: '/app/work/my-work',
    detail:
        'This old Verify link cannot open proof collection. Open Workspace to continue an existing permitted setup.',
  ),
};

LegacyRouteContainmentSpec legacyRouteContainmentSpecForReason(
  String? reason,
) =>
    legacyRouteContainmentSpecs[reason] ??
    legacyRouteContainmentSpecs['standalone-pay']!;

LegacyRouteContainmentSpec? legacyRouteContainmentFor(Uri uri) {
  final path = uri.path;

  if (path == '/app/retailer/services' ||
      path.startsWith('/app/retailer/services/')) {
    return legacyRouteContainmentSpecs['retailer-services'];
  }
  if (path.startsWith('/app/retailer/customers/')) {
    return legacyRouteContainmentSpecs['retailer-customer-detail'];
  }
  if (path == '/app/retailer/campaigns' ||
      path.startsWith('/app/retailer/campaigns/')) {
    return legacyRouteContainmentSpecs['retailer-campaigns'];
  }

  if (path == '/app/eat/tiffin' || path.startsWith('/app/eat/tiffin/')) {
    return legacyRouteContainmentSpecs['tiffin'];
  }
  if (path == '/app/book/home' ||
      path == '/app/book/task' ||
      path.startsWith('/app/book/task/')) {
    return legacyRouteContainmentSpecs['get-it-done'];
  }
  if (const {
    '/app/pay',
    '/app/pay/home',
    '/app/pay/recharge',
    '/app/pay/bills',
    '/app/pay/scan',
    '/app/pay/requests',
    '/app/pay/receipts',
  }.contains(path)) {
    return legacyRouteContainmentSpecs['standalone-pay'];
  }
  if (path == '/app/work/opportunity/delivery') {
    return legacyRouteContainmentSpecs['delivery'];
  }
  if (path == '/app/work/choose') {
    return legacyRouteContainmentSpecs['onboard'];
  }
  if (path == '/app/work/proof') {
    return legacyRouteContainmentSpecs['verify'];
  }

  final alias = uri.queryParameters['sub'] ?? uri.queryParameters['intent'];
  final world = uri.queryParameters['world'] ?? uri.queryParameters['section'];
  final isLegacyUniversal = path == '/app/social';
  if (alias == 'tiffin' && (path == '/app/eat' || world == 'eat')) {
    return legacyRouteContainmentSpecs['tiffin'];
  }
  if (const {'get-done', 'home'}.contains(alias) &&
      (path == '/app/book' || world == 'book')) {
    return legacyRouteContainmentSpecs['get-it-done'];
  }
  if (const {
        'pay',
        'recharge',
        'bills',
        'scan-pay',
        'receipts',
      }.contains(alias) &&
      (path == '/app/pay' || world == 'pay')) {
    return legacyRouteContainmentSpecs['standalone-pay'];
  }
  if (alias == 'delivery' &&
      (path == '/app/work' || world == 'work' || isLegacyUniversal)) {
    return legacyRouteContainmentSpecs['delivery'];
  }
  if (alias == 'onboard' &&
      (path == '/app/work' || world == 'work' || isLegacyUniversal)) {
    return legacyRouteContainmentSpecs['onboard'];
  }
  if (alias == 'verify' &&
      (path == '/app/work' || world == 'work' || isLegacyUniversal)) {
    return legacyRouteContainmentSpecs['verify'];
  }
  return null;
}

class LegacyRouteContainmentScreenV2 extends StatefulWidget {
  const LegacyRouteContainmentScreenV2({
    required this.spec,
    this.onBack,
    super.key,
  });

  final LegacyRouteContainmentSpec spec;

  /// Supplied by the router only; URLs cannot supply a trusted return target.
  final bool Function()? onBack;

  @override
  State<LegacyRouteContainmentScreenV2> createState() =>
      _LegacyRouteContainmentState();
}

class _LegacyRouteContainmentState
    extends State<LegacyRouteContainmentScreenV2> {
  bool _leaving = false;
  LegacyRouteContainmentSpec get spec => widget.spec;

  void _open(String location) {
    if (!mounted || _leaving) return;
    _leaving = true;
    context.go(location);
  }

  void _back() {
    if (!mounted || _leaving) return;
    _leaving = true;
    final back = widget.onBack;
    if (back != null) {
      // A covered/stale page did not leave; its Back remains usable later.
      _leaving = back();
    } else {
      context.go(spec.currentRootRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    void openCurrentRoot() => _open(spec.currentRootRoute);

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        key: Key('legacy-route-containment-${spec.id}'),
        backgroundColor: MoolColors.canvas,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: MoolColors.navy,
          foregroundColor: Colors.white,
          leading: IconButton(
            key: const Key('legacy-route-containment-back'),
            tooltip: 'Back',
            onPressed: _back,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: const Text(
            'MoolSocial',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(MoolSpacing.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: MoolMetrics.maximumContentWidth,
                ),
                child: MoolCardSurface(
                  padding: const EdgeInsets.all(MoolSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.link_off_rounded,
                        color: MoolColors.orange,
                        size: 44,
                      ),
                      const SizedBox(height: MoolSpacing.md),
                      Semantics(
                        header: true,
                        child: Text(
                          '${spec.label} is not available here',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: MoolColors.ink,
                            fontSize: 23,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: MoolSpacing.sm),
                      Text(
                        spec.detail,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: MoolColors.muted,
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: MoolSpacing.lg),
                      FilledButton.icon(
                        key: const Key('legacy-route-containment-primary'),
                        onPressed: openCurrentRoot,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text('Open ${spec.currentRootLabel}'),
                      ),
                      if (spec.currentRootRoute != '/app/mool') ...[
                        const SizedBox(height: MoolSpacing.sm),
                        OutlinedButton.icon(
                          key: const Key('legacy-route-containment-mool'),
                          onPressed: () => _open('/app/mool'),
                          icon: const Icon(MoolBrand.moolLauncherIcon),
                          label: const Text('Open Mool'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
