import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../features/buy/buy_v2_models.dart';
import '../../features/buy/buy_v2_session.dart';
import 'buy_v2_catalogue.dart';
import 'buy_v2_design.dart';
import 'buy_v2_views.dart';

class BuyV2Screen extends StatefulWidget {
  const BuyV2Screen({
    super.key,
    required this.session,
    this.initialDestination = BuyV2Destination.shop,
    this.initialView = BuyV2View.catalogue,
    this.productId,
    this.orderId,
  });

  final BuyV2Session session;
  final BuyV2Destination initialDestination;
  final BuyV2View initialView;
  final String? productId;
  final String? orderId;

  @override
  State<BuyV2Screen> createState() => _BuyV2ScreenState();
}

class _BuyV2ScreenState extends State<BuyV2Screen> {
  Timer? _noticeTimer;
  late final TextEditingController _searchController = TextEditingController(
    text: widget.session.query,
  );

  @override
  void initState() {
    super.initState();
    _applyInitialState();
    widget.session.addListener(_sessionChanged);
  }

  @override
  void didUpdateWidget(covariant BuyV2Screen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.removeListener(_sessionChanged);
      widget.session.addListener(_sessionChanged);
    }
    if (oldWidget.initialDestination != widget.initialDestination ||
        oldWidget.initialView != widget.initialView ||
        oldWidget.productId != widget.productId ||
        oldWidget.orderId != widget.orderId) {
      _applyInitialState();
    }
  }

  void _applyInitialState() {
    final productId = widget.productId;
    final orderId = widget.orderId;
    if (productId != null) {
      widget.session.openProduct(productId);
    } else if (orderId != null) {
      widget.session.openTracking(orderId);
    } else {
      widget.session.destination = widget.initialDestination;
      widget.session.view = widget.initialView;
    }
  }

  void _sessionChanged() {
    if (!mounted) return;
    if (_searchController.text != widget.session.query) {
      _searchController.value = TextEditingValue(
        text: widget.session.query,
        selection: TextSelection.collapsed(offset: widget.session.query.length),
      );
    }
    _noticeTimer?.cancel();
    if (widget.session.notice != null) {
      _noticeTimer = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) widget.session.clearNotice();
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    widget.session.removeListener(_sessionChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Scaffold(
      key: const ValueKey('buy-v2-screen'),
      backgroundColor: BuyV2Colors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: BuyV2Colors.canvas),
              child: Stack(
                children: [
                  Column(
                    children: [
                      _BuyHeader(
                        session: session,
                        controller: _searchController,
                        onAddress: () =>
                            showBuyV2AddressSheet(context, session),
                      ),
                      Expanded(child: _currentView(session)),
                      const SizedBox(height: BuyV2Metrics.dockHeight + 8),
                    ],
                  ),
                  if (session.notice case final message?
                      when !(session.itemCount > 0 &&
                          message.toLowerCase().contains('added')))
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: BuyV2Metrics.dockHeight + 66,
                      child: _BuyNotice(message: message),
                    ),
                  if (session.itemCount > 0 &&
                      session.view != BuyV2View.cart &&
                      session.view != BuyV2View.checkout)
                    Positioned(
                      right: 12,
                      bottom: BuyV2Metrics.dockHeight + 12,
                      child: _CompactCartIndicator(session: session),
                    ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 6,
                    child: _BuyDock(session: session),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _currentView(BuyV2Session session) {
    if (session.destination == BuyV2Destination.orders &&
        session.view == BuyV2View.catalogue) {
      return BuyV2OrdersView(session: session);
    }
    return switch (session.view) {
      BuyV2View.catalogue => BuyV2CatalogueView(session: session),
      BuyV2View.product => BuyV2ProductView(session: session),
      BuyV2View.cart => BuyV2CartView(session: session),
      BuyV2View.checkout => BuyV2CheckoutView(session: session),
      BuyV2View.tracking => BuyV2TrackingView(session: session),
      BuyV2View.assist => BuyV2AssistView(session: session),
    };
  }
}

class _BuyHeader extends StatelessWidget {
  const _BuyHeader({
    required this.session,
    required this.controller,
    required this.onAddress,
  });

  final BuyV2Session session;
  final TextEditingController controller;
  final VoidCallback onAddress;

  bool get _compact =>
      session.view != BuyV2View.catalogue ||
      session.destination == BuyV2Destination.medicine ||
      session.destination == BuyV2Destination.orders;

  @override
  Widget build(BuildContext context) {
    final shortViewport = MediaQuery.sizeOf(context).height < 520;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A064D), BuyV2Colors.navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
            child: Row(
              children: [
                const Expanded(child: _MoolSocialWordmark()),
                _HeaderCircle(
                  icon: Icons.bookmark_border_rounded,
                  label: 'Saved',
                  onTap: () => _showBuyV2SavedSheet(context, session),
                ),
                const SizedBox(width: 8),
                Semantics(
                  label: 'Profile',
                  button: true,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: BuyV2Colors.orange, width: 2),
                    ),
                    child: const Text(
                      'DC',
                      style: TextStyle(
                        color: BuyV2Colors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_compact && !shortViewport) ...[
            InkWell(
              onTap: onAddress,
              borderRadius: BorderRadius.circular(13),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: BuyV2Colors.orange,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.destination == BuyV2Destination.wholesale
                                  ? 'Buying for'
                                  : 'Delivering to',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              session.destination == BuyV2Destination.wholesale
                                  ? 'Shree Balaji Retail'
                                  : session.selectedAddress.shortLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (session.destination == BuyV2Destination.wholesale)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: const BoxDecoration(
                            color: BuyV2Colors.green,
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextField(
                        controller: controller,
                        onChanged: session.updateQuery,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                          color: BuyV2Colors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              session.destination == BuyV2Destination.wholesale
                              ? 'Search bulk products'
                              : 'Search products or brands',
                          hintStyle: const TextStyle(
                            color: Color(0xFF8A8EA4),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: BuyV2Colors.navy,
                            size: 21,
                          ),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _HeaderCircle(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Scan',
                    light: true,
                    onTap: () => _showBuyV2CodeSheet(context, session),
                  ),
                ],
              ),
            ),
          ],
          const BuyV2TricolourLine(),
        ],
      ),
    );
  }
}

Future<void> _showBuyV2SavedSheet(
  BuildContext context,
  BuyV2Session session,
) async {
  final saved = BuyV2Catalogue.products
      .where((product) => product.destination == session.destination)
      .take(3)
      .toList(growable: false);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saved products',
            style: TextStyle(
              color: BuyV2Colors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (final product in saved)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.bookmark_rounded,
                color: BuyV2Colors.navy,
              ),
              title: Text(
                product.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('${product.pack} · ₹${product.price}'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(sheetContext).pop();
                session.openProduct(product.id);
              },
            ),
        ],
      ),
    ),
  );
}

Future<void> _showBuyV2CodeSheet(
  BuildContext context,
  BuyV2Session session,
) async {
  var code = '';
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find by product code',
            style: TextStyle(
              color: BuyV2Colors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => code = value,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: 'Barcode or product code',
              prefixIcon: Icon(Icons.qr_code_scanner_rounded),
            ),
            onSubmitted: (_) {
              final value = code.trim();
              if (value.isEmpty) return;
              FocusScope.of(sheetContext).unfocus();
              Navigator.of(sheetContext).pop();
              session.updateQuery(value);
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final value = code.trim();
                if (value.isEmpty) {
                  session.showNotice('Enter a product code');
                  return;
                }
                FocusScope.of(sheetContext).unfocus();
                Navigator.of(sheetContext).pop();
                session.updateQuery(value);
              },
              child: const Text('Find product'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MoolSocialWordmark extends StatelessWidget {
  const _MoolSocialWordmark();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MoolSocial',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -.8,
          ),
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: const SizedBox(
            width: 86,
            child: BuyV2TricolourLine(height: 4),
          ),
        ),
      ],
    );
  }
}

class _HeaderCircle extends StatelessWidget {
  const _HeaderCircle({
    required this.icon,
    required this.label,
    required this.onTap,
    this.light = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: light ? Colors.white : Colors.white.withValues(alpha: .1),
            shape: BoxShape.circle,
            border: Border.all(color: light ? Colors.white : Colors.white24),
          ),
          child: Icon(
            icon,
            color: light ? BuyV2Colors.navy : Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _BuyDock extends StatelessWidget {
  const _BuyDock({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final items =
        <({String label, IconData icon, VoidCallback onTap, bool active})>[
          (
            label: 'Mool',
            icon: Icons.grid_view_rounded,
            onTap: () => context.go('/app/social?world=buy'),
            active: false,
          ),
          (
            label: 'Shop',
            icon: Icons.shopping_bag_outlined,
            onTap: () => session.openDestination(BuyV2Destination.shop),
            active: session.destination == BuyV2Destination.shop,
          ),
          (
            label: 'Wholesale',
            icon: Icons.inventory_2_outlined,
            onTap: () => session.openDestination(BuyV2Destination.wholesale),
            active: session.destination == BuyV2Destination.wholesale,
          ),
          (
            label: 'Medicine',
            icon: Icons.medication_outlined,
            onTap: () => session.openDestination(BuyV2Destination.medicine),
            active: session.destination == BuyV2Destination.medicine,
          ),
          (
            label: 'Orders',
            icon: Icons.receipt_long_outlined,
            onTap: session.openOrders,
            active:
                session.destination == BuyV2Destination.orders &&
                session.view != BuyV2View.assist,
          ),
          (
            label: 'Chat',
            icon: Icons.chat_bubble_outline_rounded,
            onTap: session.openAssist,
            active: session.view == BuyV2View.assist,
          ),
        ];

    return Container(
      height: BuyV2Metrics.dockHeight,
      padding: const EdgeInsets.all(5),
      decoration: buyV2CardDecoration(
        color: Colors.white.withValues(alpha: .98),
        radius: 21,
        shadow: true,
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: Semantics(
                label: item.label,
                selected: item.active,
                button: true,
                child: InkWell(
                  key: ValueKey('buy-dock-${item.label.toLowerCase()}'),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    item.onTap();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: item.active
                          ? (item.label == 'Chat'
                                ? BuyV2Colors.softBlue
                                : BuyV2Colors.softOrange)
                          : (item.label == 'Mool'
                                ? BuyV2Colors.navy
                                : Colors.transparent),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 21,
                          color: item.label == 'Mool'
                              ? Colors.white
                              : item.active
                              ? BuyV2Colors.navy
                              : BuyV2Colors.muted,
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.label,
                            maxLines: 1,
                            style: TextStyle(
                              color: item.label == 'Mool'
                                  ? Colors.white
                                  : item.active
                                  ? BuyV2Colors.navy
                                  : BuyV2Colors.muted,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompactCartIndicator extends StatelessWidget {
  const _CompactCartIndicator({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final message = session.notice;
    final expanded = message != null && message.contains('added');
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      width: expanded ? 270 : 154,
      height: 44,
      decoration: BoxDecoration(
        color: BuyV2Colors.navy,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000060),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: session.openCart,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BuyV2Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${session.itemCount}',
                  style: const TextStyle(
                    color: BuyV2Colors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  expanded ? message : 'Cart',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '₹${session.cartTotal}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuyNotice extends StatelessWidget {
  const _BuyNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: 1,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 160),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: BuyV2Colors.navy,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Color(0x29000050),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
