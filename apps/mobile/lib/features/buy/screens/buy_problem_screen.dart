import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../buy_models.dart';
import '../buy_session.dart';
import '../widgets/buy_widgets.dart';

class BuyProblemScreen extends StatefulWidget {
  const BuyProblemScreen({
    required this.session,
    required this.orderId,
    super.key,
  });

  final BuySession session;
  final String orderId;

  @override
  State<BuyProblemScreen> createState() => _BuyProblemScreenState();
}

class _BuyProblemScreenState extends State<BuyProblemScreen> {
  String? _productId;
  String? _issue;
  String? _resolution;
  bool _photoAttached = false;
  bool _submitted = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final receipt = widget.session.receipt;
        if (receipt == null || receipt.id != widget.orderId) {
          return BuyPageScaffold(
            session: widget.session,
            title: 'Order not available',
            subtitle: 'Return to your latest order',
            activeDock: 'orders',
            fallbackBackRoute: '/app/buy/grocery',
            body: Center(
              child: FilledButton(
                onPressed: () => context.go('/app/buy/grocery'),
                child: const Text('Shop products'),
              ),
            ),
          );
        }
        final completedRoute = receipt.fulfilment == BuyFulfilment.storePickup
            ? '/app/buy/order/${receipt.id}/collection-completed'
            : '/app/buy/order/${receipt.id}/completed';
        if (_submitted) {
          return BuyPageScaffold(
            key: const Key('buy-problem-submitted-screen'),
            session: widget.session,
            title: 'Support case opened',
            subtitle: 'Case MS-CASE-204 · ${receipt.id}',
            activeDock: 'orders',
            fallbackBackRoute: completedRoute,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(MoolSpacing.lg),
                child: BuySurfaceCard(
                  color: const Color(0xFFEAF7E8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: MoolColors.success,
                        child: Icon(Icons.check_rounded, color: Colors.white),
                      ),
                      const SizedBox(height: MoolSpacing.md),
                      const Text(
                        'Your order problem is recorded',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: MoolColors.ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: MoolSpacing.xs),
                      Text(
                        'Requested resolution: $_resolution. Support will update this case in Chat.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: MoolSpacing.lg),
                      FilledButton.icon(
                        key: const Key('buy-chat-case-support'),
                        onPressed: () {
                          final current = GoRouterState.of(
                            context,
                          ).uri.toString();
                          context.go(
                            Uri(
                              path: '/app/chat/thread/order-support',
                              queryParameters: {'return': current},
                            ).toString(),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Chat with case support'),
                      ),
                      TextButton(
                        key: const Key('buy-return-completed'),
                        onPressed: () => context.go(completedRoute),
                        child: const Text('Return to order'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return BuyPageScaffold(
          key: const Key('buy-problem-screen'),
          session: widget.session,
          title: 'Report an order problem',
          subtitle: receipt.id,
          activeDock: 'orders',
          fallbackBackRoute: completedRoute,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xxl,
            ),
            children: [
              if (_error != null) ...[
                Container(
                  key: const Key('buy-problem-error'),
                  padding: const EdgeInsets.all(MoolSpacing.sm),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEA),
                    borderRadius: BorderRadius.circular(MoolRadii.control),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFF7A271A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: MoolSpacing.sm),
              ],
              BuySurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Which item has a problem?',
                      style: TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    RadioGroup<String>(
                      groupValue: _productId,
                      onChanged: (value) => setState(() => _productId = value),
                      child: Column(
                        children: [
                          for (final line in receipt.lines)
                            RadioListTile<String>(
                              key: Key(
                                'buy-problem-product-${line.product.id}',
                              ),
                              value: line.product.id,
                              title: Text(line.product.name),
                              subtitle: Text(
                                '${line.quantity} × ${line.product.unitLabel}',
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              _ChoiceCard(
                title: 'What went wrong?',
                selected: _issue,
                values: const [
                  'Missing item',
                  'Damaged item',
                  'Wrong item',
                  'Quality problem',
                  'Bill issue',
                ],
                keyPrefix: 'buy-problem-issue',
                onChanged: (value) => setState(() => _issue = value),
              ),
              const SizedBox(height: MoolSpacing.sm),
              BuySurfaceCard(
                child: Row(
                  children: [
                    Icon(
                      _photoAttached
                          ? Icons.check_circle_rounded
                          : Icons.add_a_photo_outlined,
                      color: _photoAttached
                          ? MoolColors.success
                          : MoolColors.navy,
                    ),
                    const SizedBox(width: MoolSpacing.sm),
                    Expanded(
                      child: Text(
                        _photoAttached
                            ? 'Item photo attached'
                            : 'Add an item photo if it helps',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      key: const Key('buy-problem-photo'),
                      onPressed: () =>
                          setState(() => _photoAttached = !_photoAttached),
                      child: Text(_photoAttached ? 'Remove' : 'Add photo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              _ChoiceCard(
                title: 'How should we resolve it?',
                selected: _resolution,
                values: const ['Refund this item', 'Replace this item'],
                keyPrefix: 'buy-problem-resolution',
                onChanged: (value) => setState(() => _resolution = value),
              ),
            ],
          ),
          bottomAction: FilledButton(
            key: const Key('buy-submit-problem'),
            onPressed: _submit,
            child: const Text('Submit order problem'),
          ),
        );
      },
    );
  }

  void _submit() {
    if (_productId == null) {
      setState(() => _error = 'Choose the item with a problem.');
      return;
    }
    if (_issue == null) {
      setState(() => _error = 'Choose what went wrong.');
      return;
    }
    if (_resolution == null) {
      setState(() => _error = 'Choose refund or replacement.');
      return;
    }
    setState(() {
      _error = null;
      _submitted = true;
    });
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.selected,
    required this.values,
    required this.keyPrefix,
    required this.onChanged,
  });

  final String title;
  final String? selected;
  final List<String> values;
  final String keyPrefix;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          RadioGroup<String>(
            groupValue: selected,
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
            child: Column(
              children: [
                for (var index = 0; index < values.length; index++)
                  RadioListTile<String>(
                    key: Key('$keyPrefix-$index'),
                    value: values[index],
                    title: Text(values[index]),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
