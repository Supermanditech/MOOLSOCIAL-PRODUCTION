import 'dart:async';
import 'package:flutter/material.dart';
import '../work_order_identity_gateway.dart';

/// Shared original facts plus separately requested authoritative order updates.
/// Never submits commerce commands or infers payment/delivery state from money.
class WorkspacePurchaseOriginals extends StatefulWidget {
  const WorkspacePurchaseOriginals({
    super.key,
    required this.gateway,
    required this.role,
    required this.realm,
    this.storeId,
  });
  final AuthenticatedWorkspaceOrderIdentityGateway gateway;
  final WorkspaceOrderIdentityRole role;
  final String realm;
  final String? storeId;
  @override
  State<WorkspacePurchaseOriginals> createState() =>
      _WorkspacePurchaseOriginalsState();
}

class _WorkspacePurchaseOriginalsState
    extends State<WorkspacePurchaseOriginals> {
  final _references = <WorkspacePurchaseReference>[];
  final _details = <String, WorkspacePurchaseOrder>{};
  final _updates = <String, WorkspaceOperationalOrderSnapshot>{};
  final _updatePending = <String>{}, _updateFailed = <String>{};
  final _pending = <String>{}, _failed = <String>{};
  int _generation = 0;
  String? _cursor;
  bool _loading = false,
      _unavailable = false,
      _loaded = false,
      _retryMore = false;
  bool _current(int generation) =>
      mounted && generation == _generation && widget.gateway.isCurrent;
  @override
  void didUpdateWidget(covariant WorkspacePurchaseOriginals oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.gateway, widget.gateway) ||
        oldWidget.role != widget.role ||
        oldWidget.realm != widget.realm ||
        oldWidget.storeId != widget.storeId) {
      _generation++;
      _references.clear();
      _details.clear();
      _updates.clear();
      _updatePending.clear();
      _updateFailed.clear();
      _pending.clear();
      _failed.clear();
      _cursor = null;
      _loading = false;
      _unavailable = false;
      _loaded = false;
      _retryMore = false;
    }
  }

  Future<void> _load({bool more = false}) async {
    final generation = _generation;
    if (!widget.gateway.isCurrent) return;
    _loaded = true;
    _retryMore = more;
    if (mounted) {
      setState(() {
        _loading = true;
        _unavailable = false;
        if (!more) {
          _references.clear();
          _details.clear();
          _updates.clear();
          _updatePending.clear();
          _updateFailed.clear();
          _failed.clear();
          _cursor = null;
        }
      });
    }
    final page = await widget.gateway.listPurchaseReferences(
      role: widget.role,
      realm: widget.realm,
      storeId: widget.storeId,
      cursor: more ? _cursor : null,
    );
    if (!_current(generation)) return;
    setState(() {
      _loading = false;
      _unavailable = page == null;
      if (page != null) {
        for (final ref in page.references) {
          if (!_references.any(
            (r) =>
                r.purchaseId == ref.purchaseId &&
                r.storeId == ref.storeId &&
                r.orderId == ref.orderId,
          )) {
            _references.add(ref);
          }
        }
        _cursor = page.nextCursor;
      }
    });
  }

  Future<void> _open(WorkspacePurchaseReference reference) async {
    if (_pending.contains(reference.orderId) ||
        _details.containsKey(reference.orderId)) {
      return;
    }
    final generation = _generation;
    setState(() {
      _pending.add(reference.orderId);
      _failed.remove(reference.orderId);
    });
    final details = await widget.gateway.readReferencedOrder(
      role: widget.role,
      realm: widget.realm,
      reference: reference,
    );
    if (!_current(generation)) return;
    setState(() {
      _pending.remove(reference.orderId);
      if (details == null) {
        _failed.add(reference.orderId);
      } else {
        _details[reference.orderId] = details;
      }
    });
  }

  @override
  void dispose() {
    _generation++;
    super.dispose();
  }

  Future<void> _checkUpdate(WorkspacePurchaseReference reference) async {
    if (!widget.gateway.isCurrent ||
        _updatePending.contains(reference.orderId)) {
      return;
    }
    final generation = _generation;
    setState(() {
      _updatePending.add(reference.orderId);
      _updateFailed.remove(reference.orderId);
    });
    final update = await AuthenticatedWorkspaceOrderOperationsGateway(
      widget.gateway,
    ).read(role: widget.role, realm: widget.realm, reference: reference);
    if (!_current(generation)) return;
    setState(() {
      _updatePending.remove(reference.orderId);
      final previous = _updates[reference.orderId];
      if (update == null ||
          previous != null &&
              (update.revision < previous.revision ||
                  update.revision == previous.revision &&
                      update.stage != previous.stage)) {
        _updateFailed.add(reference.orderId);
      } else {
        _updates[reference.orderId] = update;
      }
    });
  }

  Widget _orderUpdate(WorkspacePurchaseReference reference) {
    final update = _updates[reference.orderId];
    final loading = _updatePending.contains(reference.orderId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (update != null)
          Text(
            switch (update.stage) {
              'Confirmed' => 'Awaiting Store acceptance',
              'Rejected' => 'Not accepted by Store',
              _ => update.stage,
            },
            key: ValueKey('purchase-order-status-${reference.orderId}'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        if (update?.rejectionReason case final reason?) Text(reason),
        if (_updateFailed.contains(reference.orderId))
          Text(
            update == null
                ? 'Order update unavailable. Original purchase details are kept.'
                : 'Update unavailable; showing earlier status.',
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: loading ? null : () => _checkUpdate(reference),
            child: Text(
              loading
                  ? 'Checking order update…'
                  : update == null
                  ? 'Check order update'
                  : 'Refresh order update',
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.gateway.isCurrent) return const SizedBox.shrink();
    return Material(
      type: MaterialType.transparency,
      child: ExpansionTile(
        key: PageStorageKey((
          widget.gateway,
          widget.role,
          widget.realm,
          widget.storeId,
        )),
        tilePadding: EdgeInsets.zero,
        title: const Text(
          'Saved purchase details',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        onExpansionChanged: (expanded) {
          final generation = _generation;
          if (expanded && !_loaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_current(generation) && !_loaded) unawaited(_load());
            });
          }
        },
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Details only. Payment and delivery updates are separate.',
                style: TextStyle(fontSize: 12),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (_unavailable)
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('Purchase details unavailable'),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => _load(more: _retryMore),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              if (!_loading && !_unavailable && _references.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No saved purchase details returned. This is not the complete online order list.',
                  ),
                ),
              for (final reference in _references)
                KeyedSubtree(
                  key: ValueKey('original-order-${reference.orderId}'),
                  child: ExpansionTile(
                    key: PageStorageKey((
                      widget.gateway,
                      widget.role,
                      widget.realm,
                      reference.purchaseId,
                      reference.storeId,
                      reference.orderId,
                    )),
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Order ${reference.orderId}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    subtitle: const Text('View original items and total'),
                    onExpansionChanged: (expanded) {
                      final generation = _generation;
                      if (expanded) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_current(generation)) unawaited(_open(reference));
                        });
                      }
                    },
                    children: [
                      if (_pending.contains(reference.orderId))
                        const LinearProgressIndicator(minHeight: 2),
                      if (_failed.contains(reference.orderId))
                        TextButton(
                          onPressed: () => _open(reference),
                          child: const Text('Details unavailable · retry'),
                        ),
                      if (_details[reference.orderId] case final details?) ...[
                        _orderUpdate(reference),
                        for (final line in details.lines)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  line.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${_quantity(line.quantityMilli)} ${line.quantityUnit} · ${line.packLabel}',
                                ),
                                _amount(line.lineTotalMinor),
                                WorkspaceOriginalBenefitsForLine(original: details, lineId: line.lineId),
                              ],
                            ),
                          ),
                        const Divider(height: 16),
                        for (final (field, label) in const [
                          ('itemsMinor', 'Items'),
                          ('discountMinor', 'Discount'),
                          ('taxMinor', 'Tax'),
                          ('deliveryMinor', 'Delivery'),
                          ('freightMinor', 'Freight'),
                          ('paymentFeeMinor', 'Payment fee'),
                          ('tipMinor', 'Tip'),
                          ('totalMinor', 'Order total'),
                        ])
                          if (field == 'itemsMinor' ||
                              field == 'totalMinor' ||
                              details.totals[field] != 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontWeight: field == 'totalMinor'
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  _amount(
                                    details.totals[field]!,
                                    total: field == 'totalMinor',
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
              if (_cursor != null && !_loading)
                TextButton(
                  onPressed: () => _load(more: true),
                  child: const Text('Load more purchase details'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amount(int minor, {bool total = false}) => LayoutBuilder(
    builder: (context, constraints) {
      final value = _money(minor);
      final style = TextStyle(
        fontSize: total ? 16 : 13,
        fontWeight: total ? FontWeight.w700 : FontWeight.w400,
      );
      final scaler = MediaQuery.textScalerOf(context);
      final painter = TextPainter(
        text: TextSpan(text: value, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout();
      final ratio = painter.width == 0
          ? 1.0
          : (constraints.maxWidth / painter.width).clamp(0.0, 1.0);
      painter.dispose();
      return Text(
        value,
        softWrap: false,
        maxLines: 1,
        style: style.copyWith(fontSize: style.fontSize! * ratio * .99),
      );
    },
  );
}

/// Same immutable breakdown on buyer originals and Store operational details.
/// No raw funding references, inferred savings, cashback success or new actions.
class WorkspaceOriginalBenefitsForLine extends StatelessWidget {
  const WorkspaceOriginalBenefitsForLine({super.key, required this.original, required this.lineId});
  final WorkspacePurchaseOrder original;
  final String lineId;
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    for (final component in original.benefitAttribution?.components ?? const <WorkspaceOriginalBenefitComponent>[])
      if (component.allocations[lineId] case final amount?)
        Padding(key: ValueKey('original-benefit-$lineId-${component.componentId}'),
          padding: const EdgeInsets.only(top: 4), child: Text(component.isCashbackOffer
            ? '${component.label} · ${component.amountBasis == 'maximum' ? 'Up to' : 'Quoted'} ${_money(amount)} cashback · confirmation pending'
            : '${component.label} · Discount ${_money(amount)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4))),
  ]);
}

String _quantity(int milli) {
  final fraction = (milli % 1000)
      .toString()
      .padLeft(3, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  return '${milli ~/ 1000}${fraction.isEmpty ? '' : '.$fraction'}';
}

String _money(int minor) {
  final digits = (minor ~/ 100).toString();
  final tail = digits.length > 3 ? digits.substring(digits.length - 3) : digits;
  var head = digits.length > 3 ? digits.substring(0, digits.length - 3) : '';
  final groups = <String>[tail];
  while (head.isNotEmpty) {
    final length = head.length > 2 ? 2 : head.length;
    groups.insert(0, head.substring(head.length - length));
    head = head.substring(0, head.length - length);
  }
  return '₹${groups.join(',')}.${(minor % 100).toString().padLeft(2, '0')}';
}
