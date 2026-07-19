import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../retailer_pos_models.dart';
import '../retailer_session.dart';
import '../widgets/retailer_widgets.dart';

Future<void> _showRetailerSheet(
  BuildContext context, {
  required String keyName,
  required String title,
  required String detail,
  required Widget child,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .86,
      ),
      child: Material(
        key: Key(keyName),
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(MoolRadii.sheet),
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4D5E7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: MoolColors.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          detail,
                          style: const TextStyle(
                            color: MoolColors.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: Key('$keyName-close'),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: MoolSpacing.md),
              child,
            ],
          ),
        ),
      ),
    ),
  );
}

class RetailerCreateOrderScreen extends StatefulWidget {
  const RetailerCreateOrderScreen({
    required this.session,
    this.initialSource = RetailerOrderSource.phone,
    this.counterId,
    super.key,
  });

  final RetailerSession session;
  final RetailerOrderSource initialSource;
  final String? counterId;

  @override
  State<RetailerCreateOrderScreen> createState() =>
      _RetailerCreateOrderScreenState();
}

class _RetailerCreateOrderScreenState extends State<RetailerCreateOrderScreen> {
  late final TextEditingController _mobile = TextEditingController(
    text: widget.session.customerMobile,
  );
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.session.ensurePosOrderSource(
      widget.initialSource,
      counterId: widget.counterId,
    );
  }

  @override
  void dispose() {
    _mobile.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) => RetailerPageScaffold(
        session: widget.session,
        title: 'Create order',
        subtitle: 'Counter, phone or Chat · one live stock',
        activeDock: 'orders',
        returnRoute: '/app/retailer/orders/new',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.outlined(
              key: const Key('pos-open-sales-book'),
              tooltip: 'Open Sales Book',
              onPressed: () => context.go('/app/retailer/books/sales'),
              icon: const Icon(Icons.auto_stories_outlined),
            ),
            const SizedBox(width: MoolSpacing.xxs),
            IconButton.outlined(
              key: const Key('pos-order-alerts'),
              tooltip: 'Open order alerts',
              onPressed: () => _showAlerts(context),
              icon: const Badge(
                label: Text('3'),
                child: Icon(Icons.notifications_none_rounded),
              ),
            ),
          ],
        ),
        bottomAction: widget.session.posOrderId == null
            ? RetailerPrimaryButton(
                keyName: 'pos-create-order',
                label: 'Create order · ₹${widget.session.posTotal}',
                busy: widget.session.busy,
                onPressed: () => widget.session.createPosOrder(),
                icon: Icons.check_rounded,
              )
            : null,
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (widget.session.posOrderId != null) return _buildSuccess(context);
    final query = _search.text.trim().toLowerCase();
    final products = widget.session.posProducts.where(
      (product) =>
          query.isEmpty ||
          '${product.name} ${product.pack} ${product.sku}'
              .toLowerCase()
              .contains(query),
    );
    return ListView(
      key: const Key('pos-create-order-screen'),
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.md,
        MoolSpacing.xs,
        MoolSpacing.md,
        MoolSpacing.xl,
      ),
      children: [
        Row(
          children: [
            const Expanded(
              child: RetailerSectionTitle(
                title: 'New order',
                detail: 'Choose how the customer reached your shop',
              ),
            ),
            const RetailerPill(label: 'DRAFT', color: MoolColors.navy),
          ],
        ),
        const SizedBox(height: MoolSpacing.sm),
        SegmentedButton<RetailerOrderSource>(
          key: const Key('pos-order-source'),
          segments: [
            for (final source in RetailerOrderSource.values)
              ButtonSegment(
                value: source,
                label: KeyedSubtree(
                  key: Key('pos-source-${source.name}'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(source.label),
                      Text(source.detail, style: const TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
              ),
          ],
          selected: {widget.session.posSource},
          showSelectedIcon: false,
          onSelectionChanged: (values) =>
              widget.session.selectPosSource(values.first),
        ),
        const SizedBox(height: MoolSpacing.sm),
        if (widget.session.posSource == RetailerOrderSource.counter)
          _buildCounterContext(context),
        _buildCustomer(context),
        const SizedBox(height: MoolSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('pos-product-search'),
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Search My Stock',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          key: const Key('pos-clear-product-search'),
                          tooltip: 'Clear product search',
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            const SizedBox(width: MoolSpacing.xxs),
            _ToolButton(
              keyName: 'pos-scan-product',
              tooltip: 'Scan barcode',
              icon: Icons.qr_code_scanner_rounded,
              onTap: () => _showScanSheet(context),
            ),
            _ToolButton(
              keyName: 'pos-voice-product',
              tooltip: 'Add by voice',
              icon: Icons.mic_none_rounded,
              onTap: () => _showVoiceSheet(context),
            ),
            _ToolButton(
              keyName: 'pos-repeat-basket',
              tooltip: 'Use repeat basket',
              icon: Icons.replay_rounded,
              onTap: () => _showRepeatBasket(context),
            ),
          ],
        ),
        const SizedBox(height: MoolSpacing.md),
        RetailerSectionTitle(
          title: 'Available in My Stock',
          detail: widget.session.posItemCount == 0
              ? 'Tap Add to begin'
              : '${widget.session.posItemCount} products in this order',
        ),
        const SizedBox(height: MoolSpacing.xs),
        if (products.isEmpty)
          RetailerEmptyState(
            keyName: 'pos-products-empty',
            title: 'No matching product',
            detail: 'Clear the search to see products available now.',
            actionLabel: 'Clear search',
            onAction: () {
              _search.clear();
              setState(() {});
            },
          )
        else
          for (final product in products) ...[
            _ProductRow(product: product, session: widget.session),
            const SizedBox(height: MoolSpacing.xs),
          ],
        RetailerSectionTitle(
          title: 'Live bill',
          detail: 'Taxes included in shown selling prices',
          trailing: TextButton(
            key: const Key('pos-clear-bill'),
            onPressed: widget.session.posItemCount == 0
                ? null
                : () => _confirmClear(context),
            child: const Text('Clear'),
          ),
        ),
        const SizedBox(height: MoolSpacing.xs),
        _BillCard(session: widget.session),
        if (widget.session.posItemCount > 0) ...[
          const SizedBox(height: MoolSpacing.md),
          const RetailerSectionTitle(
            title: 'How will they receive it?',
            detail: 'Choose the promised handover',
          ),
          const SizedBox(height: MoolSpacing.xs),
          _ChoiceWrap<RetailerFulfilment>(
            values: RetailerFulfilment.values,
            selected: widget.session.posFulfilment,
            label: (value) => value.label,
            detail: (value) => value.detail,
            keyPrefix: 'pos-fulfilment',
            onSelected: widget.session.selectPosFulfilment,
          ),
          const SizedBox(height: MoolSpacing.md),
          RetailerSectionTitle(
            title: 'How will they pay?',
            detail: '₹${widget.session.posTotal} · choose one',
          ),
          const SizedBox(height: MoolSpacing.xs),
          _ChoiceWrap<RetailerPosPayment>(
            values: widget.session.availablePosPayments,
            selected: widget.session.posPayment,
            label: (value) => value.label,
            detail: (value) => value.detail,
            keyPrefix: 'pos-payment',
            onSelected: widget.session.selectPosPayment,
          ),
          const SizedBox(height: MoolSpacing.md),
          RetailerCard(
            color: const Color(0xFFF2F2FF),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded, color: MoolColors.navy),
                const SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: Text(
                    'Creating this order reserves ${widget.session.posItemCount} products once. Invoice, delivery, stock and Sales Book use the same order.',
                    style: const TextStyle(
                      color: MoolColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCounterContext(BuildContext context) {
    final counter = widget.session.activeCounter;
    return Padding(
      padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
      child: RetailerCard(
        color: const Color(0xFFF2F2FF),
        padding: const EdgeInsets.all(MoolSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: MoolColors.navy,
              foregroundColor: Colors.white,
              child: Text('${counter.number}'),
            ),
            const SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${counter.purpose} · ${counter.operatorName}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${counter.id} · orders and invoices stay tagged',
                    style: const TextStyle(
                      color: MoolColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const Key('pos-manage-counters'),
              tooltip: 'Manage shop counters',
              onPressed: () => context.go('/app/retailer/pos/counters'),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomer(BuildContext context) {
    if (widget.session.customerKnown) {
      return RetailerCard(
        padding: const EdgeInsets.all(MoolSpacing.sm),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE9F6E8),
              foregroundColor: MoolColors.success,
              child: Text('SF', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sharma Family',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    widget.session.posSource == RetailerOrderSource.chat
                        ? 'Order-linked Chat · verified contact'
                        : 'Repeat customer · 14 completed orders',
                    style: const TextStyle(
                      color: MoolColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              key: const Key('pos-customer-basket'),
              onPressed: widget.session.posSource == RetailerOrderSource.counter
                  ? widget.session.changeCounterCustomer
                  : () => _showRepeatBasket(context),
              child: Text(
                widget.session.posSource == RetailerOrderSource.counter
                    ? 'Change'
                    : 'Basket',
              ),
            ),
          ],
        ),
      );
    }
    return RetailerCard(
      padding: const EdgeInsets.all(MoolSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('pos-customer-mobile'),
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  onChanged: widget.session.setCustomerMobile,
                  decoration: const InputDecoration(
                    labelText: 'Customer mobile (optional)',
                    prefixText: '+91 ',
                  ),
                ),
              ),
              const SizedBox(width: MoolSpacing.xs),
              FilledButton(
                key: const Key('pos-find-customer'),
                style: FilledButton.styleFrom(minimumSize: const Size(76, 48)),
                onPressed: widget.session.findCounterCustomer,
                child: const Text('Find'),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.xs),
          const Text(
            'Used only to find the customer, send the invoice and retain purchase history.',
            style: TextStyle(
              color: MoolColors.muted,
              fontSize: 11,
              height: 1.35,
            ),
          ),
          TextButton(
            key: const Key('pos-continue-without-customer'),
            onPressed: widget.session.continueWithoutCustomer,
            child: const Text('Continue without mobile'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return ListView(
      key: const Key('pos-order-created-screen'),
      padding: const EdgeInsets.all(MoolSpacing.md),
      children: [
        Row(
          children: [
            const Expanded(
              child: RetailerSectionTitle(
                title: 'Order created',
                detail: 'Customer, stock and payment are connected',
              ),
            ),
            RetailerPill(
              label: widget.session.posOrderId!,
              color: MoolColors.success,
            ),
          ],
        ),
        const SizedBox(height: MoolSpacing.md),
        RetailerCard(
          color: MoolColors.navy,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: MoolColors.orange,
                foregroundColor: MoolColors.navy,
                child: Icon(Icons.check_rounded, size: 34),
              ),
              const SizedBox(height: MoolSpacing.sm),
              const Text(
                'One order. Everything connected.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.xxs),
              Text(
                '${widget.session.posItemCount} products · ₹${widget.session.posTotal} · ${widget.session.posFulfilment.label}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFD9DAFF)),
              ),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.md),
        RetailerCard(
          color: const Color(0xFFF2F2FF),
          child: Text(
            'Invoice and order link remain attached to ${widget.session.posOrderId}. Counter sales confirm received payment before final stock and Sales Book posting.',
            style: const TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: MoolSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('pos-new-order'),
                onPressed: () => widget.session.startNewPosOrder(
                  source: widget.session.posSource,
                ),
                child: const Text('New order'),
              ),
            ),
            const SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: FilledButton(
                key: const Key('pos-open-created-order'),
                onPressed: () {
                  if (widget.session.posSource == RetailerOrderSource.counter) {
                    context.go('/app/retailer/pos/sales/new');
                  } else {
                    context.go(
                      '/app/retailer/orders/${widget.session.posOrderId}',
                    );
                  }
                },
                child: Text(
                  widget.session.posSource == RetailerOrderSource.counter
                      ? 'Receive payment'
                      : 'Open order',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmClear(BuildContext context) => _showRetailerSheet(
    context,
    keyName: 'pos-clear-bill-sheet',
    title: 'Clear this bill?',
    detail: 'Customer and order source stay selected.',
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: const Key('pos-cancel-clear-bill'),
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep bill'),
          ),
        ),
        const SizedBox(width: MoolSpacing.xs),
        Expanded(
          child: FilledButton(
            key: const Key('pos-confirm-clear-bill'),
            onPressed: () {
              widget.session.clearPosCart();
              Navigator.pop(context);
            },
            child: const Text('Clear bill'),
          ),
        ),
      ],
    ),
  );

  Future<void> _showRepeatBasket(BuildContext context) => _showRetailerSheet(
    context,
    keyName: 'pos-repeat-basket-sheet',
    title: 'Repeat basket',
    detail: '14 completed orders are linked to this verified customer.',
    child: Column(
      children: [
        const _SheetFact(label: 'Last basket', value: '4 products · ₹536'),
        const _SheetFact(label: 'Usual handover', value: 'Home delivery'),
        const SizedBox(height: MoolSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('pos-use-last-basket'),
            onPressed: () {
              widget.session.useRepeatBasket();
              Navigator.pop(context);
            },
            child: const Text('Use last basket'),
          ),
        ),
      ],
    ),
  );

  Future<void> _showScanSheet(BuildContext context) => _showRetailerSheet(
    context,
    keyName: 'pos-scan-sheet',
    title: 'Scan barcode',
    detail: 'Camera access is requested only while scanning.',
    child: Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('pos-scan-success'),
            onPressed: () {
              widget.session.useBarcodeResult();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Scan product'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            key: const Key('pos-scan-permission-denied'),
            onPressed: () {
              Navigator.pop(context);
              widget.session.useBarcodeResult(permissionDenied: true);
            },
            child: const Text('Test without camera permission'),
          ),
        ),
      ],
    ),
  );

  Future<void> _showVoiceSheet(BuildContext context) => _showRetailerSheet(
    context,
    keyName: 'pos-voice-sheet',
    title: 'Add by voice',
    detail: 'Say product, pack and quantity, then review the match.',
    child: Column(
      children: [
        const _SheetFact(label: 'Example', value: 'One atta 1 kg'),
        const SizedBox(height: MoolSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('pos-voice-success'),
            onPressed: () {
              widget.session.useVoiceResult();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.mic_rounded),
            label: const Text('Use voice match'),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            key: const Key('pos-voice-permission-denied'),
            onPressed: () {
              Navigator.pop(context);
              widget.session.useVoiceResult(permissionDenied: true);
            },
            child: const Text('Test without microphone permission'),
          ),
        ),
      ],
    ),
  );

  Future<void> _showAlerts(BuildContext context) => _showRetailerSheet(
    context,
    keyName: 'pos-order-alerts-sheet',
    title: 'Order alerts',
    detail: 'Only customer orders needing action remain here.',
    child: Column(
      children: const [
        _SheetFact(label: 'New orders', value: '3 waiting for review'),
        _SheetFact(label: 'Delivery promise', value: '1 due before 8:15 PM'),
      ],
    ),
  );
}

class RetailerCounterManagementScreen extends StatelessWidget {
  const RetailerCounterManagementScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final counter = session.activeCounter;
        return RetailerPageScaffold(
          session: session,
          title: 'Shop counters',
          subtitle: 'One live stock across every counter',
          activeDock: 'orders',
          returnRoute: '/app/retailer/pos/counters',
          trailing: IconButton.outlined(
            key: const Key('counter-alerts'),
            tooltip: 'Open counter alerts',
            onPressed: () => _showCounterAlerts(context),
            icon: Badge(
              isLabelVisible: session.counters.any((item) => !item.isOpen),
              label: Text(
                '${session.counters.where((item) => !item.isOpen).length}',
              ),
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          bottomAction: RetailerPrimaryButton(
            keyName: 'counter-primary-action',
            label: counter.isOpen ? 'Start order' : 'Open counter',
            busy: session.busy,
            onPressed: () async {
              if (!counter.isOpen &&
                  !await session.setActiveCounterOpen(true)) {
                return;
              }
              if (context.mounted) {
                context.go(
                  '/app/retailer/orders/new?source=counter&counterId=${counter.id}',
                );
              }
            },
            icon: counter.isOpen
                ? Icons.add_shopping_cart_rounded
                : Icons.lock_open,
          ),
          body: ListView(
            key: const Key('counter-management-screen'),
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xl,
            ),
            children: [
              RetailerCard(
                color: MoolColors.navy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Today across shop',
                            style: TextStyle(
                              color: Color(0xFFD9DAFF),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        RetailerPill(
                          label:
                              '${session.openCounterCount} OF ${session.counters.length} OPEN',
                          color: MoolColors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    Text(
                      '₹${session.counterSalesTotal}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Row(
                      children: [
                        _DarkMetric(
                          value: '${session.counterOrderTotal}',
                          label: 'Orders',
                        ),
                        _DarkMetric(
                          value:
                              '₹${session.counterSalesTotal ~/ session.counterOrderTotal.clamp(1, 9999)}',
                          label: 'Average bill',
                        ),
                        const _DarkMetric(value: 'One', label: 'Shared stock'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              RetailerSectionTitle(
                title: 'Choose counter',
                detail: 'Swipe for more',
                trailing: IconButton.filled(
                  key: const Key('counter-add'),
                  tooltip: 'Create counter',
                  onPressed: () => _openEditor(context),
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
              const SizedBox(height: MoolSpacing.xs),
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: session.counters.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: MoolSpacing.xs),
                  itemBuilder: (context, index) {
                    final item = session.counters[index];
                    final selected = item.id == session.activeCounterId;
                    return ChoiceChip(
                      key: Key('counter-select-${item.id}'),
                      selected: selected,
                      onSelected: (_) => session.selectCounter(item.id),
                      avatar: CircleAvatar(child: Text('${item.number}')),
                      label: SizedBox(
                        width: 104,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.purpose,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              item.isOpen ? item.operatorName : 'Closed',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              RetailerCard(
                keyName: 'counter-active-panel',
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: MoolColors.navy,
                          foregroundColor: Colors.white,
                          child: Text(
                            '${counter.number}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: MoolSpacing.xs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                counter.purpose,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${counter.id} · ${counter.operatorName}',
                                style: const TextStyle(
                                  color: MoolColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        RetailerPill(
                          label: counter.isOpen ? 'OPEN' : 'CLOSED',
                          color: counter.isOpen
                              ? MoolColors.success
                              : MoolColors.muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.md),
                    Row(
                      children: [
                        _LightMetric(
                          value: '${counter.orderCount}',
                          label: 'Orders today',
                        ),
                        _LightMetric(
                          value: '₹${counter.salesAmount}',
                          label: 'Sales today',
                        ),
                        _LightMetric(
                          value: counter.operatorName,
                          label: 'Operator',
                        ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('counter-edit'),
                            onPressed: () =>
                                _openEditor(context, editing: true),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: MoolSpacing.xs),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('counter-toggle'),
                            onPressed: session.busy
                                ? null
                                : () => session.setActiveCounterOpen(
                                    !counter.isOpen,
                                  ),
                            icon: Icon(
                              counter.isOpen
                                  ? Icons.lock_outline_rounded
                                  : Icons.lock_open_rounded,
                            ),
                            label: Text(counter.isOpen ? 'Close' : 'Open'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              const RetailerCard(
                color: Color(0xFFF2F2FF),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: MoolColors.navy),
                    SizedBox(width: MoolSpacing.xs),
                    Expanded(
                      child: Text(
                        'Every counter reserves the same live stock and retains its counter and operator trail.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              RetailerSectionTitle(
                title: '${counter.purpose} activity',
                detail: 'Today',
              ),
              const SizedBox(height: MoolSpacing.xs),
              if (counter.activity.isEmpty)
                const RetailerCard(
                  keyName: 'counter-empty-activity',
                  child: ListTile(
                    leading: CircleAvatar(child: Text('—')),
                    title: Text('No orders today'),
                    subtitle: Text('Open this counter when it is needed.'),
                    trailing: Text('₹0'),
                  ),
                )
              else
                for (var index = 0; index < counter.activity.length; index += 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
                    child: RetailerCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(
                          counter.activity[index].split(' · ').first,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          counter.activity[index]
                              .split(' · ')
                              .skip(1)
                              .take(1)
                              .join(),
                        ),
                        trailing: Text(
                          counter.activity[index].split(' · ').last,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEditor(BuildContext context, {bool editing = false}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          _CounterEditorSheet(session: session, editing: editing),
    );
  }

  Future<void> _showCounterAlerts(BuildContext context) => _showRetailerSheet(
    context,
    keyName: 'counter-alerts-sheet',
    title: 'Counter alerts',
    detail: 'Only counter availability needing attention is shown.',
    child: Column(
      children: [
        for (final counter in session.counters.where((item) => !item.isOpen))
          ListTile(
            key: Key('counter-alert-${counter.id}'),
            leading: CircleAvatar(child: Text('${counter.number}')),
            title: Text(counter.purpose),
            subtitle: const Text('Closed · no operator taking orders'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              session.selectCounter(counter.id);
              Navigator.pop(context);
            },
          ),
      ],
    ),
  );
}

class _CounterEditorSheet extends StatefulWidget {
  const _CounterEditorSheet({required this.session, required this.editing});

  final RetailerSession session;
  final bool editing;

  @override
  State<_CounterEditorSheet> createState() => _CounterEditorSheetState();
}

class _CounterEditorSheetState extends State<_CounterEditorSheet> {
  late final TextEditingController _purpose = TextEditingController(
    text: widget.editing ? widget.session.activeCounter.purpose : '',
  );
  late final TextEditingController _operator = TextEditingController(
    text:
        widget.editing &&
            widget.session.activeCounter.operatorName != 'Unassigned'
        ? widget.session.activeCounter.operatorName
        : '',
  );
  late bool _open = widget.editing ? widget.session.activeCounter.isOpen : true;

  @override
  void dispose() {
    _purpose.dispose();
    _operator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) => Padding(
        key: const Key('counter-editor-sheet'),
        padding: EdgeInsets.fromLTRB(
          MoolSpacing.md,
          MoolSpacing.md,
          MoolSpacing.md,
          MediaQuery.viewInsetsOf(context).bottom + MoolSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.editing ? 'Edit counter' : 'New counter',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                widget.editing
                    ? 'Update purpose, operator or availability.'
                    : 'Counter ${widget.session.counters.length + 1} is assigned automatically.',
                style: const TextStyle(color: MoolColors.muted),
              ),
              const SizedBox(height: MoolSpacing.md),
              TextField(
                key: const Key('counter-purpose'),
                controller: _purpose,
                decoration: const InputDecoration(
                  labelText: 'Counter purpose',
                  hintText: 'Main Billing, Express or Returns',
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              Wrap(
                spacing: MoolSpacing.xs,
                children: [
                  for (final example in const [
                    'Main Billing',
                    'Express',
                    'Delivery Orders',
                    'Wholesale',
                    'Returns',
                  ])
                    ActionChip(
                      key: Key(
                        'counter-purpose-${example.toLowerCase().replaceAll(' ', '-')}',
                      ),
                      label: Text(example),
                      onPressed: () {
                        _purpose.text = example;
                        _purpose.selection = TextSelection.collapsed(
                          offset: example.length,
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: MoolSpacing.sm),
              TextField(
                key: const Key('counter-operator'),
                controller: _operator,
                decoration: const InputDecoration(
                  labelText: 'Operator (optional)',
                  hintText: 'Assign a staff member',
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              SwitchListTile.adaptive(
                key: const Key('counter-open-now'),
                contentPadding: EdgeInsets.zero,
                value: _open,
                onChanged: (value) => setState(() => _open = value),
                title: Text(_open ? 'Open now' : 'Keep closed'),
                subtitle: Text(
                  _open
                      ? 'Orders can start after saving.'
                      : 'Open it later when the counter is staffed.',
                ),
              ),
              const SizedBox(height: MoolSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('counter-save'),
                  onPressed: widget.session.busy
                      ? null
                      : () async {
                          final saved = widget.editing
                              ? await widget.session.updateActiveCounter(
                                  purpose: _purpose.text,
                                  operatorName: _operator.text,
                                  open: _open,
                                )
                              : await widget.session.createCounter(
                                  purpose: _purpose.text,
                                  operatorName: _operator.text,
                                  open: _open,
                                );
                          if (saved && context.mounted) Navigator.pop(context);
                        },
                  child: Text(
                    widget.editing ? 'Save changes' : 'Create counter',
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: const Key('counter-cancel-editor'),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RetailerCounterSaleScreen extends StatelessWidget {
  const RetailerCounterSaleScreen({required this.session, super.key});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    session.ensureSaleReady();
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => RetailerPageScaffold(
        session: session,
        title: session.posSaleCompleted ? 'Sale complete' : 'Receive payment',
        subtitle: session.posSaleCompleted
            ? '${session.activeCounter.purpose} · invoice ready'
            : '${session.posOrderId} · ${session.activeCounter.operatorName}',
        activeDock: 'orders',
        returnRoute: '/app/retailer/pos/sales/new',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.outlined(
              key: const Key('sale-open-sales-book'),
              tooltip: 'Open Sales Book',
              onPressed: () => context.go('/app/retailer/books/sales'),
              icon: const Icon(Icons.auto_stories_outlined),
            ),
            const SizedBox(width: MoolSpacing.xxs),
            IconButton.outlined(
              key: const Key('sale-alerts'),
              tooltip: 'Open sale alerts',
              onPressed: () => _showSaleAlerts(context),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        body: session.posSaleCompleted
            ? _buildCompleted(context)
            : _buildPayment(context),
      ),
    );
  }

  Widget _buildPayment(BuildContext context) {
    return ListView(
      key: const Key('counter-sale-screen'),
      padding: const EdgeInsets.all(MoolSpacing.md),
      children: [
        RetailerCard(
          child: Row(
            children: [
              _LightMetric(
                value: session.activeCounter.purpose,
                label: 'Counter ${session.activeCounter.number}',
              ),
              const _LightMetric(
                value: 'Sharma Family',
                label: 'Verified customer',
              ),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.sm),
        RetailerCard(
          color: MoolColors.navy,
          child: Column(
            children: [
              const Text(
                'AMOUNT TO RECEIVE',
                style: TextStyle(
                  color: Color(0xFFD9DAFF),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '₹${session.posTotal}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${session.posItemCount} products · taxes included · stock reserved',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFD9DAFF)),
              ),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.sm),
        RetailerCard(
          keyName: 'sale-view-items',
          onTap: () => _showItems(context),
          child: const Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFF2F2FF),
                foregroundColor: MoolColors.navy,
                child: Icon(Icons.shopping_bag_outlined),
              ),
              SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Products in this sale',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Oil, atta and salt',
                      style: TextStyle(color: MoolColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                'View',
                style: TextStyle(
                  color: MoolColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.md),
        const RetailerSectionTitle(
          title: 'How did they pay?',
          detail: 'Select one verified method',
        ),
        const SizedBox(height: MoolSpacing.xs),
        _ChoiceWrap<RetailerPosPayment>(
          values: const [
            RetailerPosPayment.cash,
            RetailerPosPayment.upi,
            RetailerPosPayment.card,
          ],
          selected: session.posPayment,
          label: (value) => value.label,
          detail: (value) => value.detail,
          keyPrefix: 'sale-payment',
          onSelected: session.selectPosPayment,
        ),
        const SizedBox(height: MoolSpacing.sm),
        RetailerCard(
          color: const Color(0xFFEAF7E8),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: MoolColors.success,
                foregroundColor: Colors.white,
                child: Icon(Icons.check_rounded),
              ),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(switch (session.posPayment) {
                      RetailerPosPayment.cash => 'Cash counted',
                      RetailerPosPayment.upi => 'UPI received',
                      RetailerPosPayment.card => 'Card approved',
                      _ => 'Payment ready',
                    }, style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text(
                      switch (session.posPayment) {
                        RetailerPosPayment.cash =>
                          'Confirm physical cash received',
                        RetailerPosPayment.upi =>
                          'Transaction ending 7618 matched',
                        RetailerPosPayment.card =>
                          'Terminal authorisation 4261',
                        _ => '',
                      },
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${session.posTotal}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        if (session.posPayment == RetailerPosPayment.cash)
          CheckboxListTile(
            key: const Key('sale-confirm-cash'),
            contentPadding: EdgeInsets.zero,
            value: session.cashConfirmed,
            onChanged: (value) => session.confirmCashReceived(value ?? false),
            title: Text('₹${session.posTotal} cash received'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        const SizedBox(height: MoolSpacing.md),
        RetailerPrimaryButton(
          keyName: 'sale-complete',
          label: 'Complete ${session.posPayment.label} sale',
          busy: session.busy,
          onPressed: session.completePosSale,
          icon: Icons.check_circle_outline_rounded,
        ),
        TextButton(
          key: const Key('sale-edit-order'),
          onPressed: () {
            session.editCreatedPosOrder();
            context.go(
              '/app/retailer/orders/new?source=counter&counterId=${session.activeCounter.id}',
            );
          },
          child: const Text('Edit order instead'),
        ),
      ],
    );
  }

  Widget _buildCompleted(BuildContext context) {
    return ListView(
      key: const Key('counter-sale-complete-screen'),
      padding: const EdgeInsets.all(MoolSpacing.md),
      children: [
        RetailerCard(
          color: MoolColors.navy,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: MoolColors.orange,
                foregroundColor: MoolColors.navy,
                child: Icon(Icons.check_rounded, size: 34),
              ),
              const SizedBox(height: MoolSpacing.sm),
              Text(
                '₹${session.posTotal} received',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Sharma Family · ${session.posPayment.label}',
                style: const TextStyle(color: Color(0xFFD9DAFF)),
              ),
              const SizedBox(height: MoolSpacing.sm),
              Wrap(
                spacing: MoolSpacing.xs,
                children: [
                  RetailerPill(
                    label: session.posOrderId!,
                    color: MoolColors.orange,
                  ),
                  RetailerPill(
                    label: session.posInvoiceId!,
                    color: MoolColors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.sm),
        const Row(
          children: [
            _PostedState(label: 'Stock updated'),
            _PostedState(label: 'Sale posted'),
            _PostedState(label: 'Invoice ready'),
          ],
        ),
        const SizedBox(height: MoolSpacing.sm),
        RetailerCard(
          keyName: 'sale-view-invoice',
          onTap: () => _showInvoice(context),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFF2F2FF),
                foregroundColor: MoolColors.navy,
                child: Icon(Icons.receipt_long_outlined),
              ),
              const SizedBox(width: MoolSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice ${session.posInvoiceId}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${session.posItemCount} products · ₹${session.posTotal} · ${session.posPayment.label}',
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'View',
                style: TextStyle(
                  color: MoolColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: MoolSpacing.md),
        const RetailerSectionTitle(
          title: 'Send invoice',
          detail: 'Optional · customer consent respected',
        ),
        const SizedBox(height: MoolSpacing.xs),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.4,
          mainAxisSpacing: MoolSpacing.xs,
          crossAxisSpacing: MoolSpacing.xs,
          children: [
            _ShareButton(
              keyName: 'sale-share-chat',
              label: 'Mool Chat',
              icon: Icons.chat_bubble_outline_rounded,
              onTap: () => session.sharePosInvoice('Mool Chat'),
            ),
            _ShareButton(
              keyName: 'sale-share-whatsapp',
              label: 'WhatsApp',
              icon: Icons.send_outlined,
              onTap: () => session.sharePosInvoice('WhatsApp'),
            ),
            _ShareButton(
              keyName: 'sale-share-sms',
              label: 'SMS',
              icon: Icons.sms_outlined,
              onTap: () => session.sharePosInvoice('SMS'),
            ),
            _ShareButton(
              keyName: 'sale-share-qr',
              label: 'QR / Print',
              icon: Icons.qr_code_rounded,
              onTap: () => session.sharePosInvoice('QR / Print'),
            ),
          ],
        ),
        SwitchListTile.adaptive(
          key: const Key('sale-customer-consent'),
          contentPadding: EdgeInsets.zero,
          value: session.customerMessagingConsent,
          onChanged: session.setCustomerMessagingConsent,
          title: const Text('Customer approved WhatsApp and SMS'),
          subtitle: const Text(
            'Mool Chat and counter QR remain available without this approval.',
          ),
        ),
        const SizedBox(height: MoolSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('sale-new'),
                onPressed: () {
                  session.startNewPosOrder(source: RetailerOrderSource.counter);
                  context.go(
                    '/app/retailer/orders/new?source=counter&counterId=${session.activeCounter.id}',
                  );
                },
                child: const Text('New sale'),
              ),
            ),
            const SizedBox(width: MoolSpacing.xs),
            Expanded(
              child: FilledButton(
                key: const Key('sale-done'),
                onPressed: () => context.go('/app/retailer/books/sales'),
                child: const Text('View Sales Book'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showItems(BuildContext context) => _showRetailerSheet(
    context,
    keyName: 'sale-items-sheet',
    title: '${session.posItemCount} products',
    detail: '${session.posOrderId} · taxes included',
    child: _InvoiceLines(session: session),
  );

  Future<void> _showInvoice(BuildContext context) => _showRetailerSheet(
    context,
    keyName: 'sale-invoice-sheet',
    title: 'Invoice ${session.posInvoiceId}',
    detail: 'Sharma Family · paid',
    child: _InvoiceLines(session: session),
  );

  Future<void> _showSaleAlerts(BuildContext context) => _showRetailerSheet(
    context,
    keyName: 'sale-alerts-sheet',
    title: 'Ready to complete',
    detail: 'Payment and reserved stock are ready.',
    child: _SheetFact(
      label: session.posPayment.label,
      value: '₹${session.posTotal}',
    ),
  );
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.session});

  final RetailerPosProduct product;
  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    final quantity = session.posQuantity(product.id);
    return RetailerCard(
      padding: const EdgeInsets.all(MoolSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFF0DB),
            foregroundColor: MoolColors.navy,
            child: Text(
              product.name.substring(0, 1),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: MoolSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${product.pack} · ${product.sku} · ${product.stock} available',
                  style: const TextStyle(color: MoolColors.muted, fontSize: 10),
                ),
                Text(
                  '₹${product.price} · stock checked now',
                  style: const TextStyle(
                    color: MoolColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (quantity == 0)
            FilledButton.tonal(
              key: Key('pos-add-${product.id}'),
              style: FilledButton.styleFrom(minimumSize: const Size(68, 48)),
              onPressed: () => session.adjustPosQuantity(product.id, 1),
              child: const Text('Add'),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: Key('pos-reduce-${product.id}'),
                  tooltip: 'Reduce ${product.name}',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => session.adjustPosQuantity(product.id, -1),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Text(
                  '$quantity',
                  key: Key('pos-quantity-${product.id}'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                IconButton(
                  key: Key('pos-increase-${product.id}'),
                  tooltip: 'Add ${product.name}',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => session.adjustPosQuantity(product.id, 1),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({required this.session});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    if (session.posItemCount == 0) {
      return const RetailerCard(
        keyName: 'pos-empty-bill',
        child: Text(
          'Add an available product to build the live bill.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: MoolColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return RetailerCard(
      keyName: 'pos-live-bill',
      child: Column(
        children: [
          for (final product in session.posProducts.where(
            (item) => session.posQuantity(item.id) > 0,
          ))
            Padding(
              padding: const EdgeInsets.only(bottom: MoolSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '${session.posQuantity(product.id)} × ₹${product.price}',
                    style: const TextStyle(color: MoolColors.muted),
                  ),
                  const SizedBox(width: MoolSpacing.sm),
                  SizedBox(
                    width: 56,
                    child: Text(
                      '₹${session.posQuantity(product.id) * product.price}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${session.posItemCount} products${session.posDeliveryFee > 0 ? ' · delivery ₹${session.posDeliveryFee}' : ''}',
                  style: const TextStyle(color: MoolColors.muted),
                ),
              ),
              Text(
                '₹${session.posTotal}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceWrap<T> extends StatelessWidget {
  const _ChoiceWrap({
    required this.values,
    required this.selected,
    required this.label,
    required this.detail,
    required this.keyPrefix,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final String Function(T) detail;
  final String keyPrefix;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: MoolSpacing.xs,
      runSpacing: MoolSpacing.xs,
      children: [
        for (final value in values)
          ChoiceChip(
            key: Key(
              '$keyPrefix-${label(value).toLowerCase().replaceAll(' ', '-')}',
            ),
            selected: value == selected,
            onSelected: (_) => onSelected(value),
            label: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label(value),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(detail(value), style: const TextStyle(fontSize: 9)),
              ],
            ),
          ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.keyName,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String keyName;
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      key: Key(keyName),
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon),
    );
  }
}

class _SheetFact extends StatelessWidget {
  const _SheetFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MoolSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: MoolColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkMetric extends StatelessWidget {
  const _DarkMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFD9DAFF), fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _LightMetric extends StatelessWidget {
  const _LightMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(color: MoolColors.muted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _PostedState extends StatelessWidget {
  const _PostedState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: MoolColors.success),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MoolColors.muted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.keyName,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String keyName;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: Key(keyName),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _InvoiceLines extends StatelessWidget {
  const _InvoiceLines({required this.session});

  final RetailerSession session;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final product in session.posProducts.where(
          (item) => session.posQuantity(item.id) > 0,
        ))
          _SheetFact(
            label:
                '${product.name} · ${product.pack} × ${session.posQuantity(product.id)}',
            value: '₹${product.price * session.posQuantity(product.id)}',
          ),
        const Divider(),
        _SheetFact(
          label: '${session.posItemCount} products · total',
          value: '₹${session.posTotal}',
        ),
      ],
    );
  }
}
