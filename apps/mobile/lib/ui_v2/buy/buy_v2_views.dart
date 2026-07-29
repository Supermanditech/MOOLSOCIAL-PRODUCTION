import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/buy/buy_v2_models.dart';
import '../../features/buy/buy_v2_session.dart';
import 'buy_v2_design.dart';

String _productCountLabel(int count) =>
    '$count ${count == 1 ? 'product' : 'products'}';

class BuyV2ProductView extends StatelessWidget {
  const BuyV2ProductView({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final product = session.selectedProduct;
    if (product == null) {
      return const SizedBox.shrink();
    }
    final quantity = session.quantityFor(product.id);
    final rxBlocked =
        product.requiresPrescription &&
        !session.isPrescriptionApproved(product.id);
    return ListView(
      key: PageStorageKey('buy-product-${product.id}'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 112),
      children: [
        _ReturnAffordance(
          label: product.destination.label,
          onTap: session.returnToCatalogue,
        ),
        const SizedBox(height: 10),
        Container(
          height: 210,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                product.destination == BuyV2Destination.medicine
                    ? const Color(0xFFE7F5F1)
                    : BuyV2Colors.softOrange,
                Colors.white,
                BuyV2Colors.softGreen,
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BuyV2Colors.line),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: product.requiresPrescription
                        ? BuyV2Colors.navy
                        : BuyV2Colors.green,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    product.badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 116,
                  height: 116,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        switch (product.visualKind) {
                          'produce' => Icons.eco_rounded,
                          'bottle' => Icons.local_drink_outlined,
                          'paper' => Icons.description_outlined,
                          'medicine-box' => Icons.medication_outlined,
                          'tube' => Icons.sanitizer_outlined,
                          _ => Icons.inventory_2_outlined,
                        },
                        color: product.visualKind == 'produce'
                            ? BuyV2Colors.green
                            : BuyV2Colors.navy,
                        size: 54,
                      ),
                      Text(
                        product.visualLabel,
                        style: const TextStyle(
                          color: BuyV2Colors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(product.brand, style: context.buyEyebrow),
        const SizedBox(height: 4),
        Text(product.title, style: context.buyTitle.copyWith(fontSize: 25)),
        const SizedBox(height: 7),
        Text(
          product.composition ?? product.variant,
          style: context.buyBody.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(product.pack, style: context.buyMeta.copyWith(fontSize: 11)),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              buyV2Money(product.price),
              style: const TextStyle(
                color: BuyV2Colors.navy,
                fontSize: 29,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (product.mrp case final mrp?) ...[
              const SizedBox(width: 7),
              Text(
                '₹$mrp',
                style: const TextStyle(
                  color: BuyV2Colors.muted,
                  fontSize: 12,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
            const Spacer(),
            Text(
              product.unitPrice,
              style: context.buyMeta.copyWith(fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _DecisionPanel(
          title: 'Pack, delivery and seller',
          children: [
            _DecisionRow(
              icon: Icons.inventory_2_outlined,
              label: 'Pack',
              value: product.pack,
            ),
            _DecisionRow(
              icon: Icons.schedule_rounded,
              label: 'Delivery',
              value: product.deliveryPromise,
              valueColor: BuyV2Colors.green,
            ),
            _DecisionRow(
              icon: Icons.storefront_outlined,
              label: product.sellerType,
              value: product.seller,
            ),
            _DecisionRow(
              icon: Icons.route_outlined,
              label: 'Route',
              value: product.origin,
            ),
            _DecisionRow(
              icon: Icons.verified_outlined,
              label: 'Confirmed',
              value: product.confirmedOn,
            ),
          ],
        ),
        if (product.destination == BuyV2Destination.wholesale) ...[
          const SizedBox(height: 10),
          const _DecisionPanel(
            title: 'Wholesale terms',
            children: [
              _DecisionRow(
                icon: Icons.layers_outlined,
                label: 'Minimum order',
                value: 'MOQ 2 · case packs',
              ),
              _DecisionRow(
                icon: Icons.local_shipping_outlined,
                label: 'Freight',
                value: 'Included in landed price',
              ),
              _DecisionRow(
                icon: Icons.payments_outlined,
                label: 'Payment',
                value: 'UPI or bank transfer',
              ),
              _DecisionRow(
                icon: Icons.receipt_long_outlined,
                label: 'Tax',
                value: 'GST included · invoice provided',
              ),
            ],
          ),
        ],
        if (product.destination == BuyV2Destination.medicine) ...[
          const SizedBox(height: 10),
          _DecisionPanel(
            title: 'Medicine information',
            children: [
              _DecisionRow(
                icon: Icons.science_outlined,
                label: 'Composition',
                value: product.composition ?? product.variant,
              ),
              _DecisionRow(
                icon: Icons.health_and_safety_outlined,
                label: 'Dispensing',
                value: product.requiresPrescription
                    ? 'Valid prescription and pharmacist review required'
                    : 'No prescription required for this listed pack',
              ),
              _DecisionRow(
                icon: Icons.info_outline_rounded,
                label: 'Important',
                value:
                    product.regulatoryNote ??
                    'Check the sealed pack before use.',
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        if (quantity > 0)
          _LargeStepper(
            quantity: quantity,
            onDecrease: () => session.decrease(product.id),
            onIncrease: () => session.increase(product.id),
          )
        else
          FilledButton(
            onPressed: () {
              final added = session.addProduct(product.id);
              if (!added &&
                  session.pendingPrescriptionProductId == product.id) {
                showBuyV2PrescriptionSheet(context, session);
              }
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(rxBlocked ? 'Use prescription' : 'Add to cart'),
          ),
      ],
    );
  }
}

class BuyV2CartView extends StatelessWidget {
  const BuyV2CartView({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final lines = session.cartLines;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: buyV2CardDecoration(radius: 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: BuyV2Colors.navy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cart',
                        style: context.buyTitle.copyWith(fontSize: 19),
                      ),
                      Text(
                        '${_productCountLabel(session.itemCount)} · Shop + Wholesale + Medicine · ${buyV2Money(session.cartTotal)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.buyMeta.copyWith(fontSize: 8),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: session.clearCart,
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Color(0xFFB42318), fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
        _CartScopeBar(session: session),
        const SizedBox(height: 7),
        Expanded(
          child: lines.isEmpty
              ? const SizedBox.shrink()
              : ListView(
                  key: PageStorageKey('buy-cart-${session.cartScope.name}'),
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 120),
                  children: [
                    for (final destination in const [
                      BuyV2Destination.shop,
                      BuyV2Destination.medicine,
                      BuyV2Destination.wholesale,
                    ])
                      if (lines.any(
                        (line) => line.product.destination == destination,
                      )) ...[
                        _CartGroupHeader(
                          destination: destination,
                          total: lines
                              .where(
                                (line) =>
                                    line.product.destination == destination,
                              )
                              .fold(0, (sum, line) => sum + line.total),
                        ),
                        for (final line in lines.where(
                          (line) => line.product.destination == destination,
                        ))
                          _CartLine(session: session, line: line),
                        const SizedBox(height: 8),
                      ],
                  ],
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 88),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: BuyV2Colors.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total', style: context.buyMeta),
                    Text(
                      buyV2Money(session.cartTotal),
                      style: const TextStyle(
                        color: BuyV2Colors.navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 190,
                child: FilledButton(
                  onPressed: session.openCheckout,
                  child: const Text('Delivery & payment'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BuyV2CheckoutView extends StatelessWidget {
  const BuyV2CheckoutView({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final address = session.selectedAddress;
    return ListView(
      key: const PageStorageKey('buy-checkout'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 118),
      children: [
        _ReturnAffordance(label: 'Cart', onTap: session.openCart),
        const SizedBox(height: 10),
        Text(
          'Delivery & payment',
          style: context.buyTitle.copyWith(fontSize: 25),
        ),
        const SizedBox(height: 12),
        _CheckoutCard(
          icon: Icons.location_on_outlined,
          title: 'Deliver to ${address.label}',
          detail:
              '${address.recipient} · ${address.phone}\n${address.line}, ${address.area} · ${address.pinCode}\n${address.landmark}',
          action: 'Change',
          onTap: () => showBuyV2AddressSheet(context, session),
        ),
        const SizedBox(height: 9),
        const _CheckoutCard(
          icon: Icons.storefront_outlined,
          title: 'Shop fulfillment',
          detail:
              'Sardarpura Supermart · Verified retailer\nWed, 29 Jul · by 7:30 pm',
        ),
        const SizedBox(height: 7),
        const _CheckoutCard(
          icon: Icons.medication_outlined,
          title: 'Medicine fulfillment',
          detail:
              'Sardarpura Health Pharmacy · Licensed pharmacy\nWed, 29 Jul · by 11:00 am',
        ),
        const SizedBox(height: 7),
        const _CheckoutCard(
          icon: Icons.inventory_2_outlined,
          title: 'Wholesale fulfillment',
          detail:
              'Marwar Foods Distribution · Verified distributor\nThu, 30 Jul · by 2:00 pm',
        ),
        const SizedBox(height: 11),
        const _CheckoutCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'UPI',
          detail: 'Pay securely in MoolSocial after final review.',
          action: 'Change',
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: buyV2CardDecoration(
            color: BuyV2Colors.softGreen,
            border: const Color(0x33138808),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: BuyV2Colors.green,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Delivery address, final prices and each fulfillment promise are confirmed before payment.',
                  style: context.buyBody.copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _productCountLabel(session.itemCount),
                    style: context.buyMeta,
                  ),
                  Text(
                    buyV2Money(session.cartTotal),
                    style: const TextStyle(
                      color: BuyV2Colors.navy,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 190,
              child: FilledButton(
                onPressed: session.confirmOrder,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Confirm & pay'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class BuyV2OrdersView extends StatelessWidget {
  const BuyV2OrdersView({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('buy-orders'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 116),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PURCHASES AND DELIVERY', style: context.buyEyebrow),
                  const SizedBox(height: 4),
                  Text(
                    'Orders',
                    style: context.buyTitle.copyWith(fontSize: 29),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 126,
              child: FilledButton.tonalIcon(
                onPressed: session.openAssist,
                icon: const Icon(Icons.chat_outlined, size: 19),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Mool Assist'),
                ),
                style: FilledButton.styleFrom(
                  foregroundColor: BuyV2Colors.navy,
                  backgroundColor: BuyV2Colors.softBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            _OrderMetric(label: 'Active', value: '${session.orders.length}'),
            const SizedBox(width: 7),
            const _OrderMetric(label: 'Arriving next', value: 'Wed, 29 Jul'),
            const SizedBox(width: 7),
            const _OrderMetric(label: 'Delivered', value: '3'),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8E9F3),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: BuyV2Colors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Delivered',
                    style: TextStyle(
                      color: BuyV2Colors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        for (final order in session.orders)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OrderCard(session: session, order: order),
          ),
      ],
    );
  }
}

class BuyV2TrackingView extends StatelessWidget {
  const BuyV2TrackingView({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final order = session.selectedOrder;
    return ListView(
      key: PageStorageKey('buy-tracking-${order.id}'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 116),
      children: [
        _ReturnAffordance(label: 'Orders', onTap: session.openOrders),
        const SizedBox(height: 11),
        Text(order.title, style: context.buyTitle.copyWith(fontSize: 26)),
        Text(order.id, style: context.buyMeta),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                BuyV2Colors.softOrange,
                Colors.white,
                BuyV2Colors.softGreen,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BuyV2Colors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                switch (order.status) {
                  BuyV2OrderStatus.preparing => 'Preparing your order',
                  BuyV2OrderStatus.confirmed => 'Supplier confirmation',
                  BuyV2OrderStatus.dispatched => 'Dispatched',
                  BuyV2OrderStatus.arriving => 'Arriving soon',
                  BuyV2OrderStatus.delivered => 'Delivered',
                },
                style: const TextStyle(
                  color: BuyV2Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.promise,
                style: const TextStyle(
                  color: BuyV2Colors.navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: order.progress,
                  backgroundColor: const Color(0xFFE2E4EE),
                  valueColor: const AlwaysStoppedAnimation(BuyV2Colors.green),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        _DecisionPanel(
          title: 'Fulfillment',
          children: [
            _DecisionRow(
              icon: Icons.storefront_outlined,
              label: order.partnerType,
              value: order.partner,
            ),
            _DecisionRow(
              icon: Icons.location_on_outlined,
              label: 'Delivering to',
              value: order.destinationLabel,
            ),
            _DecisionRow(
              icon: Icons.inventory_2_outlined,
              label: 'Products',
              value: order.itemSummary,
            ),
          ],
        ),
        const SizedBox(height: 11),
        const _TrackingTimeline(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: session.openAssist,
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: const Text('Get help'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => session.reorder(order),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Reorder'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class BuyV2AssistView extends StatelessWidget {
  const BuyV2AssistView({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('buy-assist'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 116),
      children: [
        _ReturnAffordance(
          label: session.destination == BuyV2Destination.orders
              ? 'Orders'
              : session.destination.label,
          onTap: session.destination == BuyV2Destination.orders
              ? session.openOrders
              : session.returnToCatalogue,
        ),
        const SizedBox(height: 12),
        Text('MOOL ASSIST', style: context.buyEyebrow),
        const SizedBox(height: 4),
        Text(
          'Orders, chat and calls',
          style: context.buyTitle.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: buyV2CardDecoration(
            color: BuyV2Colors.softGreen,
            border: const Color(0x33138808),
          ),
          child: const Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded, color: BuyV2Colors.navy),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get an answer or speak with MoolSocial',
                      style: TextStyle(
                        color: BuyV2Colors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'AI-assisted help uses your order status. Chat and calls stay inside MoolSocial.',
                      style: TextStyle(color: BuyV2Colors.muted, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _CheckoutCard(
          icon: Icons.local_shipping_outlined,
          title: 'Preparing your order',
          detail:
              'MS-240782 · Wed, 29 Jul · by 7:30 pm\nSardarpura Supermart + nearby partners',
          action: 'Track',
          onTap: () => session.openTracking('MS-240782'),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final prompt in const [
              'Where is my order?',
              'Change delivery',
              'Problem with an item',
              'Medicine support',
            ])
              ActionChip(
                label: Text(prompt),
                onPressed: () =>
                    session.showNotice('$prompt · Mool Assist is ready.'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Ask Mool Assist',
            suffixIcon: IconButton(
              tooltip: 'Send',
              onPressed: () {
                HapticFeedback.selectionClick();
                session.showNotice('Mool Assist is checking your order.');
              },
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _AssistChannel(
                icon: Icons.chat_outlined,
                title: 'Chat in app',
                detail: 'Continue with support',
                onTap: () =>
                    session.showNotice('In-app support chat is ready.'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AssistChannel(
                icon: Icons.phone_outlined,
                title: 'Call in app',
                detail: 'Speak securely here',
                onTap: () =>
                    session.showNotice('In-app support call is ready.'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> showBuyV2FilterSheet(BuildContext context, BuyV2Session session) {
  final options = switch (session.destination) {
    BuyV2Destination.shop => const [
      ('fast', 'Fast delivery', 'Nearby fulfillment first'),
      ('lowest', 'Lowest delivered price', 'Price including delivery'),
      ('any', 'Any delivery time', 'Show every available product'),
    ],
    BuyV2Destination.wholesale => const [
      ('lowest', 'Lowest landed price', 'Product and freight together'),
      ('manufacturer', 'Manufacturer direct', 'Verified manufacturer supply'),
      ('any', 'All delivery terms', 'Show every confirmed trade listing'),
    ],
    BuyV2Destination.medicine => const [
      ('fast', 'Fastest pharmacy delivery', 'Nearby licensed pharmacies'),
      ('otc', 'No prescription required', 'Listed non-prescription products'),
      ('rx', 'Prescription medicines', 'Pharmacist review required'),
    ],
    BuyV2Destination.orders => const <(String, String, String)>[],
  };
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 5, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${session.destination.label} filters',
              style: context.buyTitle,
            ),
            const SizedBox(height: 4),
            Text('Results update on this screen.', style: context.buyMeta),
            const SizedBox(height: 10),
            for (final option in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: InkWell(
                  onTap: () {
                    session.chooseFilter(option.$1 == 'any' ? null : option.$1);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: buyV2CardDecoration(radius: 15),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: session.selectedFilter == option.$1
                                ? BuyV2Colors.navy
                                : BuyV2Colors.softBlue,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: session.selectedFilter == option.$1
                                ? Colors.white
                                : BuyV2Colors.navy,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(option.$2, style: context.buyBody),
                              Text(option.$3, style: context.buyMeta),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: BuyV2Colors.navy,
                        ),
                      ],
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

Future<void> showBuyV2PrescriptionSheet(
  BuildContext context,
  BuyV2Session session,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          5,
          16,
          14 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add your prescription', style: context.buyTitle),
            const SizedBox(height: 4),
            Text(
              'Choose a saved prescription or add a new one. A pharmacist verifies each matched medicine before payment.',
              style: context.buyMeta,
            ),
            const SizedBox(height: 11),
            _PrescriptionChoice(
              doctor: 'Dr Meera Sharma',
              detail: 'Heart & BP · issued 08 July 2026',
              onTap: () {
                session.approveSavedPrescription('meera');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 7),
            _PrescriptionChoice(
              doctor: 'Dr Arvind Joshi',
              detail: 'Diabetes · issued 19 June 2026',
              onTap: () {
                session.approveSavedPrescription('arvind');
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 7),
            InkWell(
              onTap: () {
                session.attachNewPrescription();
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(15),
              child: Container(
                constraints: const BoxConstraints(minHeight: 58),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: buyV2CardDecoration(radius: 15),
                child: Row(
                  children: [
                    const Icon(
                      Icons.camera_alt_outlined,
                      color: BuyV2Colors.navy,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add a new prescription',
                            style: context.buyBody,
                          ),
                          Text(
                            'Take a photo or choose a file',
                            style: context.buyMeta,
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Add',
                      style: TextStyle(
                        color: BuyV2Colors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showBuyV2AddressSheet(BuildContext context, BuyV2Session session) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          5,
          16,
          14 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delivery address', style: context.buyTitle),
            const SizedBox(height: 4),
            Text(
              'Choose a saved address or send an address request.',
              style: context.buyMeta,
            ),
            const SizedBox(height: 10),
            for (final address in session.addresses)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: InkWell(
                  onTap: () {
                    session.chooseAddress(address.id);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: buyV2CardDecoration(
                      radius: 15,
                      color: session.selectedAddressId == address.id
                          ? BuyV2Colors.softOrange
                          : Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          address.kind == BuyV2AddressKind.home
                              ? Icons.home_outlined
                              : Icons.work_outline_rounded,
                          color: BuyV2Colors.navy,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(address.label, style: context.buyBody),
                              Text(
                                '${address.recipient} · ${address.phone}\n${address.line}, ${address.shortLine} · ${address.landmark}',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: context.buyMeta,
                              ),
                            ],
                          ),
                        ),
                        if (session.selectedAddressId == address.id)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: BuyV2Colors.green,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddressRequestSheet(context),
                    icon: const Icon(Icons.ios_share_outlined, size: 18),
                    label: const Text('Request address'),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _showAddAddressSheet(context),
                    icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                    label: const Text('Add address'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showAddressRequestSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 5, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request their address', style: context.buyTitle),
            const SizedBox(height: 9),
            const TextField(
              decoration: InputDecoration(labelText: 'Recipient name or phone'),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                _ShareChoice(
                  label: 'WhatsApp',
                  icon: Icons.call_outlined,
                  onTap: () => _copyAddressRequest(context, 'WhatsApp'),
                ),
                const SizedBox(width: 7),
                _ShareChoice(
                  label: 'MoolSocial',
                  icon: Icons.chat_outlined,
                  onTap: () => _copyAddressRequest(context, 'MoolSocial'),
                ),
                const SizedBox(width: 7),
                _ShareChoice(
                  label: 'Device share',
                  icon: Icons.ios_share_outlined,
                  onTap: () => _copyAddressRequest(context, 'Device share'),
                ),
              ],
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showAddAddressSheet(context),
                child: const Text('Enter address yourself'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showAddAddressSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          5,
          16,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add address', style: context.buyTitle),
            const SizedBox(height: 9),
            Wrap(
              spacing: 6,
              children: const [
                ChoiceChip(label: Text('Home'), selected: true),
                ChoiceChip(label: Text('Work'), selected: false),
                ChoiceChip(label: Text('Third party'), selected: false),
                ChoiceChip(label: Text('Other place'), selected: false),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                _LocationChoice(
                  label: 'Current',
                  icon: Icons.my_location_rounded,
                ),
                const SizedBox(width: 6),
                _LocationChoice(label: 'Map pin', icon: Icons.map_outlined),
                const SizedBox(width: 6),
                _LocationChoice(label: 'Google', icon: Icons.place_outlined),
              ],
            ),
            const SizedBox(height: 9),
            const TextField(
              decoration: InputDecoration(labelText: 'Recipient name'),
            ),
            const SizedBox(height: 7),
            const TextField(
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: 'Recipient phone'),
            ),
            const SizedBox(height: 7),
            const TextField(
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'House, street and full address',
              ),
            ),
            const SizedBox(height: 7),
            const Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'PIN code'),
                  ),
                ),
                SizedBox(width: 7),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: 'Area or locality'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            const TextField(decoration: InputDecoration(labelText: 'Landmark')),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Save and deliver here'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ReturnAffordance extends StatelessWidget {
  const _ReturnAffordance({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BuyV2Colors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chevron_left_rounded,
                color: BuyV2Colors.navy,
                size: 19,
              ),
              const SizedBox(width: 3),
              Text(
                label,
                style: const TextStyle(
                  color: BuyV2Colors.navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecisionPanel extends StatelessWidget {
  const _DecisionPanel({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 7),
      decoration: buyV2CardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.buyEyebrow),
          const SizedBox(height: 5),
          ...children,
        ],
      ),
    );
  }
}

class _DecisionRow extends StatelessWidget {
  const _DecisionRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = BuyV2Colors.ink,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: BuyV2Colors.navy, size: 18),
          const SizedBox(width: 8),
          SizedBox(
            width: 82,
            child: Text(label, style: context.buyMeta.copyWith(fontSize: 9)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 10,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeStepper extends StatelessWidget {
  const _LargeStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: BuyV2Colors.softBlue,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0x28000080)),
      ),
      child: Row(
        children: [
          Expanded(
            child: IconButton(
              tooltip: 'Remove one',
              onPressed: onDecrease,
              icon: const Icon(Icons.remove),
            ),
          ),
          Text(
            '$quantity in cart',
            style: const TextStyle(
              color: BuyV2Colors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          Expanded(
            child: IconButton(
              tooltip: 'Add one',
              onPressed: onIncrease,
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartScopeBar extends StatelessWidget {
  const _CartScopeBar({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final scopes = const [
      BuyV2CartScope.all,
      BuyV2CartScope.shop,
      BuyV2CartScope.wholesale,
      BuyV2CartScope.medicine,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        height: 58,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE9EAF3),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            for (final scope in scopes)
              Expanded(
                child: InkWell(
                  onTap: () => session.chooseCartScope(scope),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: session.cartScope == scope
                          ? BuyV2Colors.navy
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          scope.label,
                          maxLines: 1,
                          style: TextStyle(
                            color: session.cartScope == scope
                                ? Colors.white
                                : BuyV2Colors.muted,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          scope == BuyV2CartScope.all
                              ? buyV2Money(session.cartTotal)
                              : '${session.countForDestination(switch (scope) {
                                  BuyV2CartScope.shop => BuyV2Destination.shop,
                                  BuyV2CartScope.wholesale => BuyV2Destination.wholesale,
                                  BuyV2CartScope.medicine => BuyV2Destination.medicine,
                                  BuyV2CartScope.all => BuyV2Destination.shop,
                                })}',
                          style: TextStyle(
                            color: session.cartScope == scope
                                ? Colors.white
                                : BuyV2Colors.navy,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CartGroupHeader extends StatelessWidget {
  const _CartGroupHeader({required this.destination, required this.total});

  final BuyV2Destination destination;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BuyV2Colors.softOrange, Colors.white, BuyV2Colors.softGreen],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
        border: Border.all(color: BuyV2Colors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: destination == BuyV2Destination.wholesale
                  ? BuyV2Colors.navy
                  : BuyV2Colors.orange,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              switch (destination) {
                BuyV2Destination.shop => Icons.shopping_bag_outlined,
                BuyV2Destination.wholesale => Icons.inventory_2_outlined,
                BuyV2Destination.medicine => Icons.medication_outlined,
                BuyV2Destination.orders => Icons.receipt_long_outlined,
              },
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${destination.label} order',
              style: const TextStyle(
                color: BuyV2Colors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '₹$total',
            style: const TextStyle(
              color: BuyV2Colors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.session, required this.line});

  final BuyV2Session session;
  final BuyV2CartLine line;

  @override
  Widget build(BuildContext context) {
    final product = line.product;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 9, 9),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: BuyV2Colors.line),
          right: BorderSide(color: BuyV2Colors.line),
          bottom: BorderSide(color: BuyV2Colors.line),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BuyV2Colors.softBlue,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              product.visualLabel,
              style: const TextStyle(
                color: BuyV2Colors.navy,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.buyBody,
                ),
                Text(
                  '${product.variant} · ${product.pack}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.buyMeta.copyWith(fontSize: 8),
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.deliveryPromise} · ${product.seller}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BuyV2Colors.green,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                buyV2Money(line.total),
                style: const TextStyle(
                  color: BuyV2Colors.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                height: 34,
                decoration: BoxDecoration(
                  color: BuyV2Colors.softBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Remove one',
                      onPressed: () => session.decrease(product.id),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: const Icon(Icons.remove, size: 15),
                    ),
                    Text(
                      '${line.quantity}',
                      style: const TextStyle(
                        color: BuyV2Colors.navy,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add one',
                      onPressed: () => session.increase(product.id),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: const Icon(Icons.add, size: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutCard extends StatelessWidget {
  const _CheckoutCard({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: buyV2CardDecoration(radius: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: BuyV2Colors.softBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: BuyV2Colors.navy, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.buyBody),
                  const SizedBox(height: 2),
                  Text(detail, style: context.buyMeta.copyWith(fontSize: 9)),
                ],
              ),
            ),
            if (action != null)
              Text(
                action!,
                style: const TextStyle(
                  color: BuyV2Colors.navy,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OrderMetric extends StatelessWidget {
  const _OrderMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 70,
        alignment: Alignment.center,
        decoration: buyV2CardDecoration(radius: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: context.buyMeta.copyWith(fontSize: 8)),
            const SizedBox(height: 5),
            FittedBox(
              child: Text(
                value,
                style: const TextStyle(
                  color: BuyV2Colors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.session, required this.order});

  final BuyV2Session session;
  final BuyV2Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: buyV2CardDecoration(radius: 18, shadow: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BuyV2TricolourLine(height: 3),
          const SizedBox(height: 9),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: order.destination == BuyV2Destination.wholesale
                      ? BuyV2Colors.navy
                      : BuyV2Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.destination.label[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.id,
                      style: context.buyMeta.copyWith(fontSize: 8),
                    ),
                    Text(order.title, style: context.buyBody),
                    Text(
                      order.itemSummary,
                      style: context.buyMeta.copyWith(fontSize: 8),
                    ),
                  ],
                ),
              ),
              Text(
                buyV2Money(order.total),
                style: const TextStyle(
                  color: BuyV2Colors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            switch (order.status) {
              BuyV2OrderStatus.preparing => 'Preparing your order',
              BuyV2OrderStatus.confirmed => 'Supplier confirmation',
              BuyV2OrderStatus.dispatched => 'Dispatched',
              BuyV2OrderStatus.arriving => 'Arriving soon',
              BuyV2OrderStatus.delivered => 'Delivered',
            },
            style: const TextStyle(
              color: BuyV2Colors.green,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            order.promise,
            style: const TextStyle(
              color: BuyV2Colors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: order.progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFE3E5EE),
              valueColor: const AlwaysStoppedAnimation(BuyV2Colors.green),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${order.partner} · ${order.partnerType}',
            style: context.buyMeta.copyWith(fontSize: 8),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => session.openTracking(order.id),
                  child: const Text('Track order'),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: OutlinedButton(
                  onPressed: session.openAssist,
                  child: const Text('Get help'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackingTimeline extends StatelessWidget {
  const _TrackingTimeline();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: buyV2CardDecoration(),
      child: Column(
        children: [
          for (final step in const [
            ('Confirmed', 'Seller accepted every product', true),
            ('Packing', 'Items are being checked and packed', true),
            ('Dispatch', 'Partner will hand over the order', false),
            ('Delivered', 'Delivery confirmation at the address', false),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 23,
                    height: 23,
                    decoration: BoxDecoration(
                      color: step.$3 ? BuyV2Colors.green : BuyV2Colors.softBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      step.$3 ? Icons.check : Icons.circle_outlined,
                      size: 13,
                      color: step.$3 ? Colors.white : BuyV2Colors.muted,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.$1, style: context.buyBody),
                        Text(step.$2, style: context.buyMeta),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AssistChannel extends StatelessWidget {
  const _AssistChannel({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: buyV2CardDecoration(radius: 15),
        child: Row(
          children: [
            Icon(icon, color: BuyV2Colors.navy),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.buyBody),
                  Text(detail, style: context.buyMeta),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrescriptionChoice extends StatelessWidget {
  const _PrescriptionChoice({
    required this.doctor,
    required this.detail,
    required this.onTap,
  });

  final String doctor;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: buyV2CardDecoration(radius: 15),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BuyV2Colors.navy,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Rx',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor, style: context.buyBody),
                  Text(detail, style: context.buyMeta),
                  Text('Valid prescription', style: context.buyMeta),
                ],
              ),
            ),
            const Text(
              'Use',
              style: TextStyle(
                color: BuyV2Colors.green,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareChoice extends StatelessWidget {
  const _ShareChoice({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 66,
          alignment: Alignment.center,
          decoration: buyV2CardDecoration(radius: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: BuyV2Colors.navy),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: BuyV2Colors.navy,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _copyAddressRequest(BuildContext context, String channel) async {
  await Clipboard.setData(
    const ClipboardData(text: 'https://moolsocial.com/address/request'),
  );
  if (!context.mounted) return;
  Navigator.of(context).pop();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Address request copied for $channel')),
  );
}

class _LocationChoice extends StatelessWidget {
  const _LocationChoice({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: buyV2CardDecoration(radius: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: BuyV2Colors.navy, size: 19),
            Text(
              label,
              style: const TextStyle(
                color: BuyV2Colors.navy,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
