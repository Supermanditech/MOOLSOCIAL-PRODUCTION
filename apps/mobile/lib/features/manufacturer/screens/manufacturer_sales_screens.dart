import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../manufacturer_models.dart';
import '../manufacturer_session.dart';
import '../widgets/manufacturer_widgets.dart';

class ManufacturerCatalogueScreen extends StatelessWidget {
  const ManufacturerCatalogueScreen({
    required this.session,
    required this.initialMode,
    super.key,
  });

  final ManufacturerSession session;
  final ManufacturerCatalogueMode initialMode;

  @override
  Widget build(BuildContext context) {
    if (session.catalogueMode != initialMode &&
        session.productPublishedId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (session.catalogueMode != initialMode) {
          session.setCatalogueMode(initialMode);
        }
      });
    }
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => ManufacturerPageScaffold(
        session: session,
        title: 'Product Stock',
        subtitle: 'Buyer-visible SKU, quantity and terms',
        activeDock: 'stock',
        returnRoute: '/app/manufacturer',
        trailing: IconButton.outlined(
          key: const Key('manufacturer-catalogue-filters'),
          tooltip: 'Open product filters',
          onPressed: () => _filterSheet(context),
          icon: const Icon(Icons.tune_rounded),
        ),
        body: ListView(
          key: const Key('manufacturer-catalogue-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            MoolGlassSurface(
              padding: const EdgeInsets.all(MoolSpacing.xxs),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    MoolSegment(
                      key: const Key('manufacturer-catalogue-stock'),
                      label: 'My Stock · 42',
                      selected:
                          session.catalogueMode ==
                          ManufacturerCatalogueMode.stock,
                      onPressed: () => session.setCatalogueMode(
                        ManufacturerCatalogueMode.stock,
                      ),
                    ),
                    const SizedBox(width: MoolSpacing.xs),
                    MoolSegment(
                      key: const Key('manufacturer-catalogue-master'),
                      label: 'Add Products',
                      selected:
                          session.catalogueMode ==
                          ManufacturerCatalogueMode.master,
                      onPressed: () => session.setCatalogueMode(
                        ManufacturerCatalogueMode.master,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            ManufacturerSearch(
              session: session,
              hint: session.catalogueMode == ManufacturerCatalogueMode.stock
                  ? 'Search stock, SKU or batch'
                  : 'Search master product catalogue',
              scan: () => _toolSheet(
                context,
                'Scan product pack',
                'A matched barcode opens the saved product. A new pack opens the add-product form.',
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    (session.catalogueMode == ManufacturerCatalogueMode.stock
                            ? {
                                'qty': 'Update quantity',
                                'csv-mobile': 'CSV mobile',
                                'csv-web': 'CSV web',
                                'new': 'New product',
                              }
                            : {
                                'master': 'Master list',
                                'template': 'CSV template',
                                'scan': 'Scan pack',
                                'not-listed': 'Not listed',
                              })
                        .entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(
                              right: MoolSpacing.xs,
                            ),
                            child: ActionChip(
                              key: Key(
                                'manufacturer-catalogue-tool-${entry.key}',
                              ),
                              label: Text(entry.value),
                              onPressed: () => _toolSheet(
                                context,
                                entry.value,
                                'This updates the saved product after your team confirms the change.',
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            if (session.catalogueMode == ManufacturerCatalogueMode.master) ...[
              const SizedBox(height: MoolSpacing.sm),
              ManufacturerCard(
                keyName: 'manufacturer-input-resolver',
                color: const Color(0xFFF4F3FF),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_tree_outlined,
                      color: MoolColors.navy,
                    ),
                    const SizedBox(width: MoolSpacing.sm),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FMCG catalogue pre-filtered',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'Adding an output prepares suggested input categories; you must confirm them.',
                            style: TextStyle(
                              color: MoolColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      key: const Key('manufacturer-input-map-confirm'),
                      value: session.inputMappingConfirmed,
                      onChanged: session.confirmInputMapping,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: MoolSpacing.md),
            ManufacturerSectionTitle(
              title: session.catalogueMode == ManufacturerCatalogueMode.stock
                  ? 'Published stock'
                  : 'Choose and configure',
              detail: session.catalogueMode == ManufacturerCatalogueMode.stock
                  ? 'available · reserved · MOQ'
                  : 'HSN · pack · category',
            ),
            const SizedBox(height: MoolSpacing.sm),
            if (session.filteredProducts.isEmpty)
              ManufacturerCard(
                keyName: 'manufacturer-catalogue-empty',
                child: Column(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 36),
                    const Text(
                      'No matching product',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    TextButton(
                      key: const Key('manufacturer-catalogue-clear'),
                      onPressed: session.clearSearch,
                      child: const Text('Show catalogue'),
                    ),
                  ],
                ),
              )
            else
              ...session.filteredProducts.map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
                  child: ManufacturerCard(
                    keyName: 'manufacturer-product-${product.id}',
                    onTap: () => _productSheet(context, product),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: product.live
                                  ? const Color(0xFFEAF7E8)
                                  : const Color(0xFFF4F3FF),
                              foregroundColor: MoolColors.navy,
                              child: const Icon(Icons.inventory_2_outlined),
                            ),
                            const SizedBox(width: MoolSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    '${product.pack} · HSN ${product.hsn}',
                                    style: const TextStyle(
                                      color: MoolColors.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ManufacturerPill(
                              label: product.live ? 'LIVE' : 'MASTER',
                            ),
                          ],
                        ),
                        const SizedBox(height: MoolSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: _Fact(
                                label: 'Buyer price',
                                value: '₹${product.price}',
                              ),
                            ),
                            Expanded(
                              child: _Fact(
                                label: 'Available',
                                value: '${product.available}',
                              ),
                            ),
                            Expanded(
                              child: _Fact(
                                label: 'Reserved',
                                value: '${product.reserved}',
                              ),
                            ),
                            Expanded(
                              child: _Fact(
                                label: 'MOQ',
                                value: '${product.moq}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: MoolSpacing.xs),
                        Text(
                          product.terms,
                          style: const TextStyle(
                            color: MoolColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
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

  Future<void> _filterSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.md),
        child: Column(
          key: const Key('manufacturer-catalogue-filter-sheet'),
          mainAxisSize: MainAxisSize.min,
          children: ['All', 'Edible Oil', 'Flour', 'Tea', 'Needs action']
              .map(
                (filter) => ListTile(
                  key: Key(
                    'manufacturer-catalogue-filter-${filter.toLowerCase().replaceAll(' ', '-')}',
                  ),
                  title: Text(filter),
                  trailing: session.catalogueFilter == filter
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () {
                    session.setCatalogueFilter(filter);
                    Navigator.pop(sheetContext);
                  },
                ),
              )
              .toList(),
        ),
      ),
    ),
  );

  Future<void> _productSheet(
    BuildContext context,
    ManufacturerProduct product,
  ) {
    session.selectProduct(product.id);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => AnimatedBuilder(
        animation: session,
        builder: (context, _) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.md,
            ),
            child: SingleChildScrollView(
              child: Column(
                key: const Key('manufacturer-product-sheet'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${product.pack} · HSN ${product.hsn}',
                    style: const TextStyle(color: MoolColors.muted),
                  ),
                  const SizedBox(height: MoolSpacing.md),
                  TextFormField(
                    key: const Key('manufacturer-product-quantity'),
                    initialValue: '${session.productQuantity}',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Confirmed available quantity',
                    ),
                    onChanged: (value) =>
                        session.setProductQuantity(int.tryParse(value) ?? -1),
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('manufacturer-product-price'),
                          initialValue: '${session.productPrice}',
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Buyer price',
                          ),
                          onChanged: (value) =>
                              session.setProductPrice(int.tryParse(value) ?? 0),
                        ),
                      ),
                      const SizedBox(width: MoolSpacing.xs),
                      Expanded(
                        child: TextFormField(
                          key: const Key('manufacturer-product-moq'),
                          initialValue: '${session.productMoq}',
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'MOQ'),
                          onChanged: (value) =>
                              session.setProductMoq(int.tryParse(value) ?? 0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                  TextFormField(
                    key: const Key('manufacturer-product-terms'),
                    initialValue: session.productTerms,
                    onChanged: session.setProductTerms,
                    decoration: const InputDecoration(
                      labelText: 'Payment and commercial terms',
                    ),
                  ),
                  CheckboxListTile(
                    key: const Key('manufacturer-product-input-map'),
                    contentPadding: EdgeInsets.zero,
                    value: session.inputMappingConfirmed,
                    onChanged: (value) =>
                        session.confirmInputMapping(value ?? false),
                    title: const Text('Confirm proposed input categories'),
                    subtitle: const Text(
                      'No BOM or input recommendation is published without manufacturer confirmation.',
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('manufacturer-product-publish'),
                      onPressed: session.busy
                          ? null
                          : () async {
                              final ok = await session.publishProduct();
                              if (ok && sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                      child: Text(
                        session.productPublishedId == null
                            ? 'Publish confirmed stock'
                            : 'Published',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ManufacturerOrderReviewScreen extends StatelessWidget {
  const ManufacturerOrderReviewScreen({required this.session, super.key});

  final ManufacturerSession session;

  @override
  Widget build(BuildContext context) {
    final order = session.selectedOrder;
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => ManufacturerPageScaffold(
        session: session,
        title: 'Sales Order ${order.id}',
        subtitle: 'Review, commit and fulfil once',
        activeDock: 'orders',
        returnRoute: '/app/manufacturer?view=orders',
        trailing: IconButton.outlined(
          key: const Key('manufacturer-order-chat'),
          tooltip: 'Chat with verified buyer',
          onPressed: () => context.go(
            '/app/chat/thread/order-support?return=/app/manufacturer/orders/review',
          ),
          icon: const Icon(Icons.chat_bubble_outline_rounded),
        ),
        bottomAction: FilledButton(
          key: const Key('manufacturer-order-confirm'),
          onPressed: session.busy ? null : session.confirmOrder,
          child: Text(
            session.orderConfirmationId == null
                ? session.orderDecision ==
                          ManufacturerOrderDecision.cannotFulfil
                      ? 'Return demand with reason'
                      : 'Confirm quantity and terms'
                : 'Order confirmed',
          ),
        ),
        body: ListView(
          key: const Key('manufacturer-order-review-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            ManufacturerCard(
              keyName: 'manufacturer-order-buyer',
              color: const Color(0xFFF4F3FF),
              onTap: () => _toolSheet(
                context,
                'Verified buyer',
                '${order.buyer} · ${order.protection}. Buyer identity and operating status remain visible.',
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: MoolColors.navy,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.storefront_outlined),
                  ),
                  const SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.buyer,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${order.buyerType} · ${order.protection}',
                          style: const TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const ManufacturerPill(label: 'VERIFIED'),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            ManufacturerCard(
              color: const Color(0xFFFFF6E8),
              child: Column(
                children: [
                  _InvoiceLine(label: order.product, value: '₹${order.total}'),
                  _InvoiceLine(
                    label: '${order.cases} cases · GST included',
                    value: order.due,
                  ),
                  const _InvoiceLine(
                    label: 'Protected advance',
                    value: '₹1.02L held',
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            const ManufacturerSectionTitle(
              title: 'Your fulfilment decision',
              detail: 'No silent quantity reduction',
            ),
            const SizedBox(height: MoolSpacing.sm),
            ...ManufacturerOrderDecision.values.map(
              (decision) => Padding(
                padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
                child: ManufacturerCard(
                  keyName: 'manufacturer-order-decision-${decision.name}',
                  onTap: () => session.setOrderDecision(decision),
                  color: session.orderDecision == decision
                      ? const Color(0xFFF4F3FF)
                      : Colors.white,
                  child: Row(
                    children: [
                      Icon(
                        session.orderDecision == decision
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: session.orderDecision == decision
                            ? MoolColors.navy
                            : MoolColors.muted,
                      ),
                      Expanded(
                        child: Text(
                          decision.label,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (session.orderDecision == ManufacturerOrderDecision.partial) ...[
              TextFormField(
                key: const Key('manufacturer-order-cases'),
                initialValue: '${session.confirmedCases}',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cases you can fulfil (below ${order.cases})',
                ),
                onChanged: (value) =>
                    session.setConfirmedCases(int.tryParse(value) ?? 0),
              ),
              const SizedBox(height: MoolSpacing.xs),
            ],
            if (session.orderDecision ==
                ManufacturerOrderDecision.cannotFulfil) ...[
              TextFormField(
                key: const Key('manufacturer-order-reason'),
                initialValue: session.orderNote,
                onChanged: session.setOrderNote,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Auditable reason',
                ),
              ),
              const SizedBox(height: MoolSpacing.xs),
            ],
            TextFormField(
              key: const Key('manufacturer-order-date'),
              initialValue: session.productionDate,
              onChanged: session.setProductionDate,
              decoration: const InputDecoration(
                labelText: 'Production or dispatch date',
                suffixIcon: Icon(Icons.calendar_month_outlined),
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            const ManufacturerSectionTitle(
              title: 'Locked commercial terms',
              detail: 'Before confirmation',
            ),
            const SizedBox(height: MoolSpacing.sm),
            const ManufacturerCard(
              child: Column(
                children: [
                  _InvoiceLine(label: 'Buyer price', value: '₹142 / unit'),
                  _InvoiceLine(label: 'GST', value: '5% · HSN 1512'),
                  _InvoiceLine(
                    label: 'Payment',
                    value: '30% protected · 7 day balance',
                  ),
                  _InvoiceLine(
                    label: 'Delivery',
                    value: 'Own fleet · buyer warehouse',
                  ),
                  _InvoiceLine(
                    label: 'Cancellation',
                    value: 'Before production commitment',
                  ),
                ],
              ),
            ),
            if (session.orderConfirmationId != null) ...[
              const SizedBox(height: MoolSpacing.md),
              const ManufacturerSectionTitle(
                title: 'Fulfilment progress',
                detail: 'One order lifecycle',
              ),
              const SizedBox(height: MoolSpacing.sm),
              Wrap(
                spacing: MoolSpacing.xs,
                runSpacing: MoolSpacing.xs,
                children: [
                  ActionChip(
                    key: const Key('manufacturer-order-production'),
                    label: const Text('Production ready'),
                    onPressed: () =>
                        session.advanceOrder(ManufacturerOrderStage.production),
                  ),
                  ActionChip(
                    key: const Key('manufacturer-order-packed'),
                    label: const Text('Packing complete'),
                    onPressed: () =>
                        session.advanceOrder(ManufacturerOrderStage.packed),
                  ),
                  ActionChip(
                    key: const Key('manufacturer-order-documents'),
                    label: const Text('Documents'),
                    onPressed: () => _toolSheet(
                      context,
                      'Order documents',
                      'GST invoice ready · LR required · e-way bill ready.',
                    ),
                  ),
                  ActionChip(
                    key: const Key('manufacturer-order-transport'),
                    label: const Text('Arrange dispatch'),
                    onPressed: () => context.go('/app/manufacturer/dispatch'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ManufacturerProcurementScreen extends StatelessWidget {
  const ManufacturerProcurementScreen({
    required this.session,
    required this.initialTab,
    super.key,
  });

  final ManufacturerSession session;
  final ManufacturerPurchaseTab initialTab;

  @override
  Widget build(BuildContext context) {
    if (session.purchaseTab != initialTab && session.purchaseOrderId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (session.purchaseTab != initialTab) {
          session.setPurchaseTab(initialTab);
        }
      });
    }
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => ManufacturerPageScaffold(
        session: session,
        title: 'Wholesale Buy',
        subtitle: 'Verified inputs and protected POs',
        activeDock: 'inputs',
        returnRoute: '/app/manufacturer',
        trailing: IconButton.outlined(
          key: const Key('manufacturer-purchase-cart'),
          tooltip: 'Open PO cart',
          onPressed: () => session.setPurchaseTab(ManufacturerPurchaseTab.cart),
          icon: Badge(
            isLabelVisible: session.purchaseCartCount > 0,
            label: Text('${session.purchaseCart.length}'),
            child: const Icon(Icons.shopping_bag_outlined),
          ),
        ),
        bottomAction: session.purchaseTab == ManufacturerPurchaseTab.cart
            ? FilledButton(
                key: const Key('manufacturer-place-po'),
                onPressed: session.busy ? null : session.placePurchaseOrder,
                child: Text(
                  session.purchaseOrderId == null
                      ? 'Review and place protected PO'
                      : 'PO placed',
                ),
              )
            : null,
        body: ListView(
          key: const Key('manufacturer-procurement-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            MoolGlassSurface(
              padding: const EdgeInsets.all(MoolSpacing.xxs),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ManufacturerPurchaseTab.values
                      .map(
                        (tab) => Padding(
                          padding: const EdgeInsets.only(right: MoolSpacing.xs),
                          child: MoolSegment(
                            key: Key('manufacturer-purchase-tab-${tab.name}'),
                            label: switch (tab) {
                              ManufacturerPurchaseTab.matched => 'Matched',
                              ManufacturerPurchaseTab.cart => 'PO Cart',
                              ManufacturerPurchaseTab.orders => 'Orders',
                            },
                            selected: session.purchaseTab == tab,
                            onPressed: () => session.setPurchaseTab(tab),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            if (session.purchaseTab == ManufacturerPurchaseTab.matched)
              ..._matched(context)
            else if (session.purchaseTab == ManufacturerPurchaseTab.cart)
              ..._cart(context)
            else
              ..._orders(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _matched(BuildContext context) => [
    ManufacturerSearch(
      session: session,
      hint: 'Search material, grade, pack or supplier',
    ),
    const SizedBox(height: MoolSpacing.sm),
    const ManufacturerCard(
      color: Color(0xFFF4F3FF),
      child: Row(
        children: [
          Icon(Icons.account_tree_outlined, color: MoolColors.navy),
          SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested from 42 confirmed products',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '18 input categories confirmed by Shakti Foods',
                  style: TextStyle(color: MoolColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          ManufacturerPill(label: 'MFR ONLY'),
        ],
      ),
    ),
    const SizedBox(height: MoolSpacing.sm),
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['Matched inputs', 'Raw material', 'Packaging', 'Machinery']
            .map(
              (filter) => Padding(
                padding: const EdgeInsets.only(right: MoolSpacing.xs),
                child: MoolSegment(
                  key: Key(
                    'manufacturer-input-filter-${filter.toLowerCase().replaceAll(' ', '-')}',
                  ),
                  label: filter,
                  selected: session.inputFilter == filter,
                  onPressed: () => session.setInputFilter(filter),
                ),
              ),
            )
            .toList(),
      ),
    ),
    const SizedBox(height: MoolSpacing.md),
    const ManufacturerSectionTitle(
      title: 'Compare and buy',
      detail: 'price · MOQ · delivery',
    ),
    const SizedBox(height: MoolSpacing.sm),
    ...reviewManufacturerInputs.map(
      (offer) => Padding(
        padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
        child: ManufacturerCard(
          keyName: 'manufacturer-input-${offer.id}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFEAF7E8),
                    foregroundColor: MoolColors.success,
                    child: Icon(Icons.factory_outlined),
                  ),
                  const SizedBox(width: MoolSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          offer.name,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${offer.grade} · ${offer.pack}',
                          style: const TextStyle(
                            color: MoolColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const ManufacturerPill(label: 'VERIFIED'),
                ],
              ),
              const SizedBox(height: MoolSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _Fact(label: 'Price', value: '₹${offer.price}'),
                  ),
                  Expanded(
                    child: _Fact(label: 'MOQ', value: '${offer.moq}'),
                  ),
                  Expanded(
                    child: _Fact(label: 'Delivery', value: offer.delivery),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: Key('manufacturer-input-terms-${offer.id}'),
                      onPressed: () => _toolSheet(
                        context,
                        offer.name,
                        '${offer.payment} · ${offer.delivery} · MOQ ${offer.moq}.',
                      ),
                      child: const Text('Full terms'),
                    ),
                  ),
                  const SizedBox(width: MoolSpacing.xs),
                  Expanded(
                    child: FilledButton(
                      key: Key('manufacturer-input-add-${offer.id}'),
                      onPressed: () => session.addInput(offer.id),
                      child: const Text('Add MOQ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ];

  List<Widget> _cart(BuildContext context) => [
    const ManufacturerSectionTitle(
      title: 'Purchase order cart',
      detail: 'Terms rechecked now',
    ),
    const SizedBox(height: MoolSpacing.sm),
    if (session.purchaseCart.isEmpty)
      ManufacturerCard(
        keyName: 'manufacturer-purchase-empty',
        child: Column(
          children: [
            const Icon(Icons.shopping_bag_outlined, size: 38),
            const Text(
              'No input selected',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            TextButton(
              key: const Key('manufacturer-purchase-browse'),
              onPressed: () =>
                  session.setPurchaseTab(ManufacturerPurchaseTab.matched),
              child: const Text('Compare verified inputs'),
            ),
          ],
        ),
      )
    else
      ...session.purchaseCart.entries.map((entry) {
        final offer = reviewManufacturerInputs.firstWhere(
          (item) => item.id == entry.key,
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
          child: ManufacturerActionRow(
            keyName: 'manufacturer-cart-${entry.key}',
            icon: Icons.factory_outlined,
            title: offer.name,
            detail: '${entry.value} units · ${offer.pack}',
            meta: '${offer.payment} · ${offer.delivery}',
            action: 'Remove',
            onTap: () => session.removeInput(entry.key),
          ),
        );
      }),
    if (session.purchaseCart.isNotEmpty)
      const ManufacturerCard(
        color: Color(0xFFFFF6E8),
        child: Text(
          'Protected advance is authorized once. Supplier payment releases only against the agreed receipt conditions.',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
  ];

  List<Widget> _orders(BuildContext context) => [
    const ManufacturerSectionTitle(
      title: 'Input purchase orders',
      detail: 'PO · receipt · payment',
    ),
    const SizedBox(height: MoolSpacing.sm),
    ManufacturerActionRow(
      keyName: 'manufacturer-purchase-order-active',
      icon: Icons.local_shipping_outlined,
      title: session.purchaseOrderId ?? 'PO-IN-2028',
      detail: session.purchaseOrderId == null
          ? 'Refined oil · supplier response received'
          : 'Protected PO · dispatch preparation',
      meta: session.purchaseReceiptId == null
          ? 'Track or record receipt'
          : 'GRN-111-0719 · evidence recorded',
      action: 'Track',
      onTap: () => _toolSheet(
        context,
        'Input shipment',
        'See supplier dispatch, live ETA and confirmed purchase documents.',
      ),
    ),
    const SizedBox(height: MoolSpacing.xs),
    FilledButton.tonalIcon(
      key: const Key('manufacturer-purchase-receipt'),
      onPressed: session.receivePurchase,
      icon: const Icon(Icons.fact_check_outlined),
      label: Text(
        session.purchaseReceiptId == null
            ? 'Record goods receipt'
            : 'Receipt recorded',
      ),
    ),
  ];
}

class ManufacturerDispatchScreen extends StatelessWidget {
  const ManufacturerDispatchScreen({
    required this.session,
    required this.initialTab,
    super.key,
  });

  final ManufacturerSession session;
  final ManufacturerDispatchTab initialTab;

  @override
  Widget build(BuildContext context) {
    if (session.dispatchTab != initialTab && session.dispatchId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (session.dispatchTab != initialTab) {
          session.setDispatchTab(initialTab);
        }
      });
    }
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => ManufacturerPageScaffold(
        session: session,
        title: 'Dispatch & Delivery',
        subtitle: 'Documents, tracking and buyer receipt',
        activeDock: 'orders',
        returnRoute: '/app/manufacturer?view=orders',
        trailing: IconButton.outlined(
          key: const Key('manufacturer-dispatch-details'),
          tooltip: 'Shipment documents',
          onPressed: () => _toolSheet(
            context,
            'Shipment documents',
            'GST invoice ${session.gstInvoiceReady ? 'ready' : 'missing'} · LR ${session.lrReady ? 'ready' : 'required'} · e-way bill ${session.eWayBillReady ? 'ready' : 'missing'}.',
          ),
          icon: const Icon(Icons.description_outlined),
        ),
        bottomAction: session.dispatchTab == ManufacturerDispatchTab.ready
            ? FilledButton(
                key: const Key('manufacturer-dispatch-confirm'),
                onPressed: session.busy ? null : session.confirmDispatch,
                child: Text(
                  session.dispatchId == null
                      ? 'Confirm dispatch'
                      : 'Dispatch confirmed',
                ),
              )
            : session.dispatchTab == ManufacturerDispatchTab.delivered
            ? FilledButton.tonal(
                key: const Key('manufacturer-delivery-receipt'),
                onPressed: session.confirmDeliveryReceipt,
                child: Text(
                  session.deliveryReceiptId == null
                      ? 'Confirm buyer receipt'
                      : 'Receipt confirmed',
                ),
              )
            : null,
        body: ListView(
          key: const Key('manufacturer-dispatch-screen'),
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xl,
          ),
          children: [
            MoolGlassSurface(
              padding: const EdgeInsets.all(MoolSpacing.xxs),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ManufacturerDispatchTab.values
                      .map(
                        (tab) => Padding(
                          padding: const EdgeInsets.only(right: MoolSpacing.xs),
                          child: MoolSegment(
                            key: Key('manufacturer-dispatch-tab-${tab.name}'),
                            label: switch (tab) {
                              ManufacturerDispatchTab.ready => 'Ready',
                              ManufacturerDispatchTab.transit => 'In transit',
                              ManufacturerDispatchTab.delivered => 'Delivered',
                            },
                            selected: session.dispatchTab == tab,
                            onPressed: () => session.setDispatchTab(tab),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            if (session.dispatchTab == ManufacturerDispatchTab.ready)
              ..._ready(context)
            else if (session.dispatchTab == ManufacturerDispatchTab.transit)
              ..._transit(context)
            else
              ..._delivered(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _ready(BuildContext context) => [
    const ManufacturerCard(
      color: Color(0xFFF4F3FF),
      child: Column(
        children: [
          _InvoiceLine(label: 'Sales order', value: 'SO-4821'),
          _InvoiceLine(label: 'Buyer', value: 'Rajasthan Retailer Pool'),
          _InvoiceLine(label: 'Cases', value: '240'),
          _InvoiceLine(label: 'Advance held', value: '₹1.02L'),
          _InvoiceLine(label: 'Release', value: 'After buyer receipt'),
        ],
      ),
    ),
    const SizedBox(height: MoolSpacing.md),
    const ManufacturerSectionTitle(
      title: 'Choose transport',
      detail: 'Explicit per shipment',
    ),
    const SizedBox(height: MoolSpacing.sm),
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ManufacturerTransport.values
            .map(
              (transport) => Padding(
                padding: const EdgeInsets.only(right: MoolSpacing.xs),
                child: MoolSegment(
                  key: Key('manufacturer-transport-${transport.name}'),
                  label: transport.label,
                  selected: session.dispatchTransport == transport,
                  onPressed: () => session.setDispatchTransport(transport),
                ),
              ),
            )
            .toList(),
      ),
    ),
    const SizedBox(height: MoolSpacing.sm),
    if (session.dispatchTransport == ManufacturerTransport.ownFleet) ...[
      TextFormField(
        key: const Key('manufacturer-vehicle-number'),
        initialValue: session.vehicleNumber,
        onChanged: session.setVehicleNumber,
        decoration: const InputDecoration(labelText: 'Vehicle number'),
      ),
      const SizedBox(height: MoolSpacing.xs),
      TextFormField(
        key: const Key('manufacturer-driver-mobile'),
        initialValue: session.driverMobile,
        keyboardType: TextInputType.phone,
        onChanged: session.setDriverMobile,
        decoration: const InputDecoration(labelText: 'Driver mobile'),
      ),
      const SizedBox(height: MoolSpacing.sm),
    ],
    const ManufacturerSectionTitle(
      title: 'Dispatch documents',
      detail: 'All required',
    ),
    const SizedBox(height: MoolSpacing.sm),
    _DocumentToggle(
      keyName: 'manufacturer-document-invoice',
      title: 'GST invoice',
      value: session.gstInvoiceReady,
      onChanged: () => session.toggleDispatchDocument('invoice'),
    ),
    _DocumentToggle(
      keyName: 'manufacturer-document-lr',
      title: 'Lorry receipt (LR)',
      value: session.lrReady,
      onChanged: () => session.toggleDispatchDocument('lr'),
    ),
    _DocumentToggle(
      keyName: 'manufacturer-document-eway',
      title: 'E-way bill',
      value: session.eWayBillReady,
      onChanged: () => session.toggleDispatchDocument('eway'),
    ),
  ];

  List<Widget> _transit(BuildContext context) => [
    ManufacturerCard(
      keyName: 'manufacturer-live-shipment',
      color: const Color(0xFFF4F3FF),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: MoolColors.navy,
                foregroundColor: Colors.white,
                child: Icon(Icons.local_shipping_outlined),
              ),
              SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DSP-112-4821 · In transit',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'RJ19 GC 4821 · ETA today 6:20 PM',
                      style: TextStyle(color: MoolColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              ManufacturerPill(label: 'LIVE'),
            ],
          ),
          SizedBox(height: MoolSpacing.sm),
          LinearProgressIndicator(value: .62),
        ],
      ),
    ),
    const SizedBox(height: MoolSpacing.sm),
    ManufacturerActionRow(
      keyName: 'manufacturer-open-tracking',
      icon: Icons.route_outlined,
      title: 'Live shipment tracking',
      detail: 'Current position, ETA and driver contact',
      action: 'Open',
      onTap: () => _toolSheet(
        context,
        'Live shipment',
        'Live location is shown only for the authorized delivery route.',
      ),
    ),
    const SizedBox(height: MoolSpacing.xs),
    FilledButton(
      key: const Key('manufacturer-mark-delivered'),
      onPressed: () =>
          session.setDispatchTab(ManufacturerDispatchTab.delivered),
      child: const Text('Delivery reached buyer'),
    ),
  ];

  List<Widget> _delivered(BuildContext context) => [
    ManufacturerCard(
      keyName: 'manufacturer-buyer-receipt',
      color: const Color(0xFFEAF7E8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                backgroundColor: MoolColors.success,
                foregroundColor: Colors.white,
                child: Icon(Icons.fact_check_outlined),
              ),
              SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buyer goods receipt',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Quantity, condition and proof must match',
                      style: TextStyle(color: MoolColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          const _InvoiceLine(label: 'Cases received', value: '240 / 240'),
          const _InvoiceLine(label: 'Condition', value: 'Accepted'),
          _InvoiceLine(
            label: 'Payment release',
            value: session.deliveryReceiptId == null
                ? 'Awaiting proof'
                : 'Ledger eligible',
          ),
        ],
      ),
    ),
    const SizedBox(height: MoolSpacing.sm),
    const ManufacturerCard(
      color: Color(0xFFFFF6E8),
      child: Text(
        'Receipt evidence is saved here. Payment releases only after the agreed delivery checks pass.',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ),
  ];
}

class _DocumentToggle extends StatelessWidget {
  const _DocumentToggle({
    required this.keyName,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String keyName;
  final String title;
  final bool value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
    child: ManufacturerCard(
      keyName: keyName,
      onTap: onChanged,
      padding: const EdgeInsets.symmetric(
        horizontal: MoolSpacing.sm,
        vertical: MoolSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(
            value
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: value ? MoolColors.success : MoolColors.muted,
          ),
          const SizedBox(width: MoolSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Text(value ? 'Ready' : 'Required'),
        ],
      ),
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: MoolColors.muted, fontSize: 9)),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: MoolColors.navy,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _InvoiceLine extends StatelessWidget {
  const _InvoiceLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xxs),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: MoolColors.muted, fontSize: 11),
          ),
        ),
        const SizedBox(width: MoolSpacing.xs),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}

Future<void> _toolSheet(BuildContext context, String title, String detail) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MoolSpacing.md),
          child: Column(
            key: const Key('manufacturer-tool-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.xs),
              Text(detail),
              const SizedBox(height: MoolSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('manufacturer-tool-done'),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
