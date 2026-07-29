import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/buy/buy_v2_models.dart';
import '../../features/buy/buy_v2_session.dart';
import 'buy_v2_design.dart';
import 'buy_v2_views.dart';

class BuyV2CatalogueView extends StatelessWidget {
  const BuyV2CatalogueView({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final shortViewport = MediaQuery.sizeOf(context).height < 520;
    return Column(
      children: [
        if (!shortViewport) _ActiveOrderStrip(session: session),
        if (session.destination == BuyV2Destination.medicine)
          _MedicineIntro(session: session, compact: shortViewport),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 9, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(switch (session.destination) {
                      BuyV2Destination.shop => 'SHOP PACKS',
                      BuyV2Destination.wholesale =>
                        'WHOLESALE PACKS · BUSINESS PRICES',
                      BuyV2Destination.medicine =>
                        'AVAILABLE FOR YOUR PIN CODE',
                      BuyV2Destination.orders => '',
                    }, style: context.buyEyebrow),
                    const SizedBox(height: 4),
                    Text(switch (session.destination) {
                      BuyV2Destination.shop => 'Recommended near you',
                      BuyV2Destination.wholesale => 'Wholesale prices',
                      BuyV2Destination.medicine =>
                        'Medicines and health products',
                      BuyV2Destination.orders => '',
                    }, style: context.buyTitle),
                  ],
                ),
              ),
              _FilterButton(session: session),
            ],
          ),
        ),
        if (session.destination == BuyV2Destination.shop && !shortViewport)
          _HouseholdBasket(session: session),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CategoryRail(session: session),
              Expanded(child: _ProductGrid(session: session)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveOrderStrip extends StatelessWidget {
  const _ActiveOrderStrip({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final matching = session.orders.firstWhere(
      (order) =>
          order.destination == session.destination ||
          session.destination == BuyV2Destination.shop,
      orElse: () => session.orders.first,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: InkWell(
        onTap: () => session.openTracking(matching.id),
        borderRadius: BorderRadius.circular(17),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                BuyV2Colors.softOrange,
                Colors.white,
                BuyV2Colors.softGreen,
              ],
            ),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0x26FF9933)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: BuyV2Colors.navy,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('3 ACTIVE ORDERS', style: context.buyEyebrow),
                    Text(
                      switch (session.destination) {
                        BuyV2Destination.shop =>
                          'Preparing your order · Wed, 29 Jul · by 7:30 pm',
                        BuyV2Destination.wholesale =>
                          'Supplier confirmation · Thu, 30 Jul',
                        BuyV2Destination.medicine =>
                          'Pharmacy packing · Wed, 29 Jul · by 11:00 am',
                        BuyV2Destination.orders => matching.promise,
                      },
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: BuyV2Colors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${matching.partner} · ${matching.partnerType}',
                      maxLines: 1,
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
              const Text(
                'Track',
                style: TextStyle(
                  color: BuyV2Colors.navy,
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

class _MedicineIntro extends StatelessWidget {
  const _MedicineIntro({required this.session, required this.compact});

  final BuyV2Session session;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 0),
      child: Column(
        children: [
          if (!compact) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, BuyV2Colors.softGreen],
                ),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: BuyV2Colors.line),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.medication_liquid_outlined,
                    color: BuyV2Colors.green,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LICENSED PHARMACY PARTNERS',
                          style: TextStyle(
                            color: BuyV2Colors.green,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Medicines & health',
                          style: TextStyle(
                            color: BuyV2Colors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.shopping_cart_outlined, color: BuyV2Colors.navy),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: TextField(
                    onChanged: session.updateQuery,
                    decoration: InputDecoration(
                      hintText: 'Search medicines',
                      hintStyle: const TextStyle(
                        fontSize: 11,
                        color: BuyV2Colors.muted,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: BuyV2Colors.navy,
                      ),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: BuyV2Colors.line),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: () => showBuyV2PrescriptionSheet(context, session),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: BuyV2Colors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Rx',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text('Photo or PDF', style: TextStyle(fontSize: 7)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                _MedicineShortcut(
                  icon: Icons.assignment_outlined,
                  title: 'Saved Rx',
                  detail: '2 saved prescriptions',
                  onTap: () => showBuyV2PrescriptionSheet(context, session),
                ),
                const SizedBox(width: 6),
                _MedicineShortcut(
                  icon: Icons.chat_outlined,
                  title: 'Pharmacist',
                  detail: 'Available now',
                  onTap: session.openAssist,
                ),
                const SizedBox(width: 6),
                _MedicineShortcut(
                  icon: Icons.history_rounded,
                  title: 'Refills',
                  detail: 'Next refill due',
                  onTap: () {
                    session.chooseCategory('rx');
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MedicineShortcut extends StatelessWidget {
  const _MedicineShortcut({
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 53,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          decoration: buyV2CardDecoration(radius: 13),
          child: Row(
            children: [
              Icon(icon, size: 18, color: BuyV2Colors.navy),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      style: const TextStyle(
                        color: BuyV2Colors.navy,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: BuyV2Colors.muted,
                        fontSize: 7,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Filter ${session.destination.label} products',
      button: true,
      child: InkWell(
        onTap: () => showBuyV2FilterSheet(context, session),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: BuyV2Colors.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000050),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: BuyV2Colors.softBlue,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: BuyV2Colors.navy,
                  size: 16,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                session.selectedFilter == null ? 'Filter' : 'Filtered',
                style: const TextStyle(
                  color: BuyV2Colors.navy,
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

class _HouseholdBasket extends StatelessWidget {
  const _HouseholdBasket({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              BuyV2Colors.softOrange,
              Colors.white,
              BuyV2Colors.softGreen,
            ],
          ),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: BuyV2Colors.line),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🧺', style: TextStyle(fontSize: 21)),
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HOUSEHOLD BASKETS',
                        style: TextStyle(
                          color: BuyV2Colors.muted,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Monthly home basket',
                        style: TextStyle(
                          color: BuyV2Colors.navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '12 products · 21 packs · 30 days',
                        style: TextStyle(
                          color: BuyV2Colors.muted,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Save ₹415',
                  style: TextStyle(
                    color: BuyV2Colors.green,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      session.chooseCategory('all');
                      session.showNotice('Basket products are shown below');
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      side: const BorderSide(color: BuyV2Colors.line),
                    ),
                    child: const Text(
                      'See 12 products',
                      style: TextStyle(
                        color: BuyV2Colors.navy,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final featured = BuyV2Catalogue.products
                          .where(
                            (product) =>
                                product.destination == BuyV2Destination.shop,
                          )
                          .take(4);
                      for (final product in featured) {
                        session.addProduct(product.id);
                      }
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    ),
                    child: const Text(
                      'Add basket to cart',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRail extends StatefulWidget {
  const _CategoryRail({required this.session});

  final BuyV2Session session;

  @override
  State<_CategoryRail> createState() => _CategoryRailState();
}

class _CategoryRailState extends State<_CategoryRail> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Container(
      width: BuyV2Metrics.railWidth,
      margin: const EdgeInsets.fromLTRB(10, 0, 4, 4),
      decoration: buyV2CardDecoration(radius: 18),
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        thickness: 5,
        radius: const Radius.circular(12),
        child: ListView.separated(
          controller: _controller,
          primary: false,
          padding: const EdgeInsets.fromLTRB(5, 6, 9, 8),
          itemCount: session.categories.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final category = session.categories[index];
            final selected = category.id == session.selectedCategoryId;
            return Semantics(
              label: category.label,
              selected: selected,
              button: true,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  SystemSound.play(SystemSoundType.click);
                  session.chooseCategory(category.id);
                },
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  constraints: const BoxConstraints(minHeight: 58),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? BuyV2Colors.softOrange
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: selected
                        ? const Border(
                            left: BorderSide(
                              color: BuyV2Colors.orange,
                              width: 3,
                            ),
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? BuyV2Colors.navy
                              : BuyV2Colors.softBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          category.glyph,
                          style: TextStyle(
                            color: selected ? Colors.white : BuyV2Colors.navy,
                            fontSize: category.glyph == 'Rx' ? 9 : 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.label,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? BuyV2Colors.navy
                              : BuyV2Colors.muted,
                          fontSize: 8,
                          height: 1.05,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final products = session.visibleProducts;
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                color: BuyV2Colors.muted,
                size: 34,
              ),
              const SizedBox(height: 8),
              Text(
                'No matching products',
                style: context.buyTitle.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 4),
              Text(
                'Try another category or clear the filter.',
                textAlign: TextAlign.center,
                style: context.buyMeta,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  session.chooseFilter(null);
                  session.chooseCategory('all');
                },
                child: const Text('Show all products'),
              ),
            ],
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 430 ? 3 : 2;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final tileHeight = textScale > 1.25 ? 360.0 : 324.0;
        final width =
            (constraints.maxWidth - 10 - ((columns - 1) * 7)) / columns;
        return CustomScrollView(
          key: PageStorageKey(
            'buy-${session.destination.name}-${session.selectedCategoryId}',
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(3, 0, 7, 118),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => BuyV2ProductCard(
                    session: session,
                    product: products[index],
                  ),
                  childCount: products.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 7,
                  mainAxisSpacing: 8,
                  childAspectRatio: width / tileHeight,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class BuyV2ProductCard extends StatelessWidget {
  const BuyV2ProductCard({
    super.key,
    required this.session,
    required this.product,
  });

  final BuyV2Session session;
  final BuyV2Product product;

  @override
  Widget build(BuildContext context) {
    final quantity = session.quantityFor(product.id);
    final rxBlocked =
        product.requiresPrescription &&
        !session.isPrescriptionApproved(product.id);
    return Semantics(
      label:
          '${product.title}, ${product.pack}, ${buyV2Money(product.price)}, ${product.deliveryPromise}, fulfilled by ${product.seller}',
      button: true,
      child: InkWell(
        onTap: () => session.openProduct(product.id),
        borderRadius: BorderRadius.circular(17),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: buyV2CardDecoration(radius: 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductVisual(product: product),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(9, 7, 9, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.buyEyebrow.copyWith(fontSize: 7),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: BuyV2Colors.ink,
                          fontSize: 12,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        product.variant,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: BuyV2Colors.ink,
                          fontSize: 8,
                          height: 1.15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        product.pack,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.buyMeta.copyWith(fontSize: 8),
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  buyV2Money(product.price),
                                  style: const TextStyle(
                                    color: BuyV2Colors.navy,
                                    fontSize: 18,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  product.unitPrice,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.buyMeta.copyWith(fontSize: 7),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (quantity > 0)
                        _QuantityStepper(
                          quantity: quantity,
                          onDecrease: () => session.decrease(product.id),
                          onIncrease: () => session.increase(product.id),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: FilledButton(
                            onPressed: () {
                              final added = session.addProduct(product.id);
                              if (!added &&
                                  session.pendingPrescriptionProductId ==
                                      product.id) {
                                showBuyV2PrescriptionSheet(context, session);
                              }
                            },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              backgroundColor: rxBlocked
                                  ? BuyV2Colors.navy
                                  : BuyV2Colors.softBlue,
                              foregroundColor: rxBlocked
                                  ? Colors.white
                                  : BuyV2Colors.navy,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                                side: BorderSide(
                                  color: rxBlocked
                                      ? BuyV2Colors.navy
                                      : const Color(0x26000080),
                                ),
                              ),
                            ),
                            child: Text(
                              rxBlocked ? 'Use Rx' : 'ADD',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: BuyV2Colors.softGreen,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 12,
                                  color: BuyV2Colors.green,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    product.deliveryPromise,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: BuyV2Colors.green,
                                      fontSize: 7,
                                      height: 1.05,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${product.seller} · ${product.sellerType}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: BuyV2Colors.ink,
                                fontSize: 7,
                                height: 1.05,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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
}

class _ProductVisual extends StatelessWidget {
  const _ProductVisual({required this.product});

  final BuyV2Product product;

  @override
  Widget build(BuildContext context) {
    final colors = switch (product.visualKind) {
      'produce' => const [Color(0xFFFFE9E2), Color(0xFFEAF7E8)],
      'bottle' => const [Color(0xFFFFF5CF), Color(0xFFE8F6F8)],
      'paper' => const [Color(0xFFE8ECFA), Color(0xFFF8EBF4)],
      'medicine-box' => const [Color(0xFFE5F5F1), Color(0xFFFFE9E9)],
      'tube' => const [Color(0xFFFFE6D6), Color(0xFFF4EAF8)],
      _ => const [Color(0xFFFFF1DE), Color(0xFFEDF3F8)],
    };
    return SizedBox(
      height: 94,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                  bottom: Radius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            left: 6,
            top: 6,
            right: 6,
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 120),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: product.requiresPrescription
                      ? BuyV2Colors.navy
                      : BuyV2Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  product.badge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, .3),
            child: _ProductGlyph(product: product),
          ),
          const Positioned(
            right: 8,
            bottom: 7,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: BuyV2Colors.green,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.white, spreadRadius: 2)],
              ),
              child: SizedBox(width: 9, height: 9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductGlyph extends StatelessWidget {
  const _ProductGlyph({required this.product});

  final BuyV2Product product;

  @override
  Widget build(BuildContext context) {
    if (product.visualKind == 'produce') {
      return Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 58,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFEE5246),
              borderRadius: BorderRadius.all(Radius.elliptical(28, 22)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x2B000000),
                  blurRadius: 4,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),
          const Icon(Icons.eco_rounded, color: BuyV2Colors.green, size: 25),
        ],
      );
    }
    final icon = switch (product.visualKind) {
      'bottle' => Icons.local_drink_outlined,
      'paper' => Icons.description_outlined,
      'medicine-box' => Icons.medication_outlined,
      'tube' => Icons.sanitizer_outlined,
      _ => Icons.inventory_2_outlined,
    };
    return Container(
      width: 62,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(11),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 5,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: BuyV2Colors.navy, size: 24),
          Text(
            product.visualLabel,
            maxLines: 1,
            style: const TextStyle(
              color: BuyV2Colors.ink,
              fontSize: 7,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
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
      height: 42,
      decoration: BoxDecoration(
        color: BuyV2Colors.softBlue,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0x23000080)),
      ),
      child: Row(
        children: [
          Expanded(
            child: IconButton(
              tooltip: 'Remove one',
              onPressed: onDecrease,
              icon: const Icon(Icons.remove, size: 17),
              color: BuyV2Colors.navy,
              padding: EdgeInsets.zero,
            ),
          ),
          Text(
            '$quantity',
            style: const TextStyle(
              color: BuyV2Colors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          Expanded(
            child: IconButton(
              tooltip: 'Add one',
              onPressed: onIncrease,
              icon: const Icon(Icons.add, size: 17),
              color: BuyV2Colors.navy,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
