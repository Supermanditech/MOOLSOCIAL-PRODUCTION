import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../eat_models.dart';
import '../eat_session.dart';
import '../widgets/eat_widgets.dart';

class EatBasketScreen extends StatelessWidget {
  const EatBasketScreen({required this.session, super.key});

  final EatSession session;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final empty = session.cartLines.isEmpty;
        return EatPageScaffold(
          key: const Key('eat-basket-screen'),
          session: session,
          title: 'Your food basket',
          subtitle: empty
              ? 'Add a meal to continue'
              : '${session.itemCount} items · ${session.fulfilmentPromise}',
          activeDock: 'order',
          fallbackBackRoute: '/app/eat/order',
          body: empty
              ? _EmptyBasket(onOrder: () => context.go('/app/eat/order'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    MoolSpacing.md,
                    MoolSpacing.xs,
                    MoolSpacing.md,
                    MoolSpacing.xxl,
                  ),
                  children: [
                    for (final line in session.cartLines) ...[
                      _BasketLine(line: line, session: session),
                      const SizedBox(height: MoolSpacing.sm),
                    ],
                    _DeliveryDetails(session: session),
                    const SizedBox(height: MoolSpacing.sm),
                    EatPriceSummary(session: session),
                    const SizedBox(height: MoolSpacing.sm),
                    const EatSurfaceCard(
                      color: Color(0xFFEAF7E8),
                      child: Text(
                        'Available items are reserved before payment. Final price, fees, taxes and cancellation terms appear on the next screen.',
                        style: TextStyle(
                          color: Color(0xFF155B17),
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
          bottomAction: empty
              ? null
              : FilledButton(
                  key: const Key('eat-review-order'),
                  onPressed: () => context.go('/app/eat/review'),
                  child: Text('Review and pay ${eatMoney(session.orderTotal)}'),
                ),
        );
      },
    );
  }
}

class _BasketLine extends StatelessWidget {
  const _BasketLine({required this.line, required this.session});

  final EatCartLine line;
  final EatSession session;

  @override
  Widget build(BuildContext context) {
    return EatSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.item.name,
                      style: const TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      line.customization ?? 'Standard preparation',
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                eatMoney(line.total),
                style: const TextStyle(
                  color: MoolColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          Row(
            children: [
              TextButton(
                key: Key('eat-remove-${line.item.id}'),
                onPressed: () => session.remove(line.item.id),
                child: const Text('Remove'),
              ),
              const Spacer(),
              EatQuantityControl(
                itemId: line.item.id,
                quantity: line.quantity,
                onDecrease: () => session.decrease(line.item.id),
                onIncrease: () => session.increase(line.item.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryDetails extends StatelessWidget {
  const _DeliveryDetails({required this.session});

  final EatSession session;

  @override
  Widget build(BuildContext context) {
    final needsAddress =
        session.fulfilment == EatFulfilment.delivery ||
        session.fulfilment == EatFulfilment.scheduled;
    return EatSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.fulfilment.label,
            style: const TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            session.fulfilmentPromise,
            style: const TextStyle(
              color: MoolColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (needsAddress) ...[
            const SizedBox(height: MoolSpacing.xs),
            Text(
              session.deliveryAddress,
              style: const TextStyle(color: MoolColors.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: MoolSpacing.sm),
          OutlinedButton(
            key: const Key('eat-change-delivery'),
            onPressed: () => _editDelivery(context, session),
            child: const Text('Change fulfilment or address'),
          ),
        ],
      ),
    );
  }
}

class _EmptyBasket extends StatelessWidget {
  const _EmptyBasket({required this.onOrder});

  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MoolSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_meals_outlined,
              size: 52,
              color: MoolColors.muted,
            ),
            const SizedBox(height: MoolSpacing.md),
            const Text(
              'Your food basket is empty',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'Choose a dish to see price, preparation time and final total.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MoolSpacing.lg),
            FilledButton(
              key: const Key('eat-empty-order'),
              onPressed: onOrder,
              child: const Text('Choose food'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _editDelivery(BuildContext context, EatSession session) async {
  var fulfilment = session.fulfilment;
  final controller = TextEditingController(text: session.deliveryAddress);
  String? validationMessage;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            MoolSpacing.lg,
            MoolSpacing.lg,
            MoolSpacing.lg,
            MediaQuery.viewInsetsOf(sheetContext).bottom + MoolSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Choose fulfilment',
                style: TextStyle(
                  color: MoolColors.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              Wrap(
                spacing: MoolSpacing.xs,
                runSpacing: MoolSpacing.xs,
                children: EatFulfilment.values
                    .where((value) => value != EatFulfilment.scheduled)
                    .map(
                      (value) => ChoiceChip(
                        key: Key('eat-basket-fulfilment-${value.name}'),
                        label: Text(value.label),
                        selected: fulfilment == value,
                        onSelected: (_) =>
                            setSheetState(() => fulfilment = value),
                      ),
                    )
                    .toList(),
              ),
              if (fulfilment == EatFulfilment.delivery) ...[
                const SizedBox(height: MoolSpacing.sm),
                TextField(
                  key: const Key('eat-address-field'),
                  controller: controller,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Complete delivery address',
                  ),
                ),
              ],
              if (validationMessage != null) ...[
                const SizedBox(height: MoolSpacing.xs),
                Text(
                  validationMessage!,
                  key: const Key('eat-address-error'),
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: MoolSpacing.md),
              FilledButton(
                key: const Key('eat-save-delivery'),
                onPressed: () {
                  if (fulfilment == EatFulfilment.delivery &&
                      controller.text.trim().length < 8) {
                    setSheetState(
                      () => validationMessage =
                          'Enter a complete delivery address.',
                    );
                    return;
                  }
                  if (fulfilment == EatFulfilment.delivery) {
                    session.updateDeliveryAddress(controller.text);
                  }
                  session.chooseFulfilment(fulfilment);
                  Navigator.pop(sheetContext);
                },
                child: const Text('Save fulfilment'),
              ),
              TextButton(
                key: const Key('eat-cancel-delivery'),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 400));
  controller.dispose();
}
