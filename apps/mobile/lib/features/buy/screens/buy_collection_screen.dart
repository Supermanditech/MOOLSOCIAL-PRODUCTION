import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../buy_models.dart';
import '../buy_session.dart';
import '../widgets/buy_widgets.dart';

class BuyCollectionScreen extends StatelessWidget {
  const BuyCollectionScreen({
    required this.session,
    required this.orderId,
    super.key,
  });

  final BuySession session;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final receipt = session.receipt;
        if (receipt == null ||
            receipt.id != orderId ||
            receipt.fulfilment != BuyFulfilment.storePickup) {
          return _MissingCollection(session: session);
        }
        final ready =
            session.collectionStage.index >= BuyCollectionStage.ready.index;
        final collected =
            session.collectionStage == BuyCollectionStage.collected;
        return BuyPageScaffold(
          key: const Key('buy-collection-screen'),
          session: session,
          title: collected ? 'Collection confirmed' : 'Collect your order',
          subtitle: '$orderId · ${session.collectionStage.title}',
          activeDock: 'orders',
          fallbackBackRoute: '/app/buy/review',
          trailing: IconButton.outlined(
            key: const Key('buy-collection-help'),
            tooltip: 'Collection help',
            onPressed: () => _showCollectionHelp(context, session),
            icon: const Icon(Icons.support_agent_rounded),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xxl,
            ),
            children: [
              _CollectionHero(session: session),
              const SizedBox(height: MoolSpacing.sm),
              _CollectionTimeline(stage: session.collectionStage),
              const SizedBox(height: MoolSpacing.sm),
              _StoreCard(session: session),
              const SizedBox(height: MoolSpacing.sm),
              _CollectionCode(available: ready),
              const SizedBox(height: MoolSpacing.sm),
              _CollectionActions(session: session),
            ],
          ),
          bottomAction: FilledButton.icon(
            key: const Key('buy-confirm-collection'),
            onPressed: () {
              if (collected) {
                context.go('/app/buy/order/$orderId/collection-completed');
                return;
              }
              if (session.confirmCollection()) {
                context.go('/app/buy/order/$orderId/collection-completed');
              }
            },
            icon: Icon(
              collected
                  ? Icons.receipt_long_outlined
                  : Icons.inventory_2_outlined,
            ),
            label: Text(
              collected ? 'Open collection receipt' : 'Confirm collection',
            ),
          ),
        );
      },
    );
  }
}

class _MissingCollection extends StatelessWidget {
  const _MissingCollection({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    return BuyPageScaffold(
      key: const Key('buy-missing-collection-screen'),
      session: session,
      title: 'Collection order not available',
      subtitle: 'Choose a store before placing a collection order',
      activeDock: 'orders',
      fallbackBackRoute: '/app/buy/grocery',
      body: Center(
        child: FilledButton(
          key: const Key('buy-missing-collection-shop'),
          onPressed: () => context.go('/app/buy/grocery'),
          child: const Text('Shop products'),
        ),
      ),
    );
  }
}

class _CollectionHero extends StatelessWidget {
  const _CollectionHero({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    final ready =
        session.collectionStage.index >= BuyCollectionStage.ready.index;
    return Container(
      padding: const EdgeInsets.all(MoolSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: ready
              ? const [Color(0xFF0C6E10), MoolColors.success]
              : const [MoolColors.navy, Color(0xFF2525CB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(MoolRadii.sheet),
        boxShadow: MoolShadows.floating,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(
              ready ? Icons.storefront_rounded : Icons.inventory_2_outlined,
              color: ready ? MoolColors.success : MoolColors.navy,
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          Text(
            session.collectionStage.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -.45,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          Text(
            session.collectionStage.detail,
            style: const TextStyle(
              color: Color(0xE6FFFFFF),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          FilledButton.tonalIcon(
            key: const Key('buy-refresh-collection'),
            onPressed: session.refreshCollectionStatus,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh collection status'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: MoolColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionTimeline extends StatelessWidget {
  const _CollectionTimeline({required this.stage});

  final BuyCollectionStage stage;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      child: Row(
        children: [
          for (var index = 0; index < BuyCollectionStage.values.length; index++)
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: index <= stage.index
                          ? MoolColors.success
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: index <= stage.index
                            ? MoolColors.success
                            : MoolColors.line,
                        width: 2,
                      ),
                    ),
                    child: index <= stage.index
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                  const SizedBox(height: MoolSpacing.xs),
                  Text(
                    _shortStage(BuyCollectionStage.values[index]),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: index <= stage.index
                          ? MoolColors.ink
                          : MoolColors.muted,
                      fontSize: 10,
                      fontWeight: index == stage.index
                          ? FontWeight.w900
                          : FontWeight.w700,
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

String _shortStage(BuyCollectionStage stage) => switch (stage) {
  BuyCollectionStage.confirmed => 'Confirmed',
  BuyCollectionStage.packing => 'Packing',
  BuyCollectionStage.ready => 'Ready',
  BuyCollectionStage.collected => 'Collected',
};

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE5F3E4),
                child: Icon(
                  Icons.storefront_outlined,
                  color: MoolColors.success,
                ),
              ),
              const SizedBox(width: MoolSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mahadev Fresh Mart',
                      style: TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      session.pickupStore ?? session.address,
                      style: const TextStyle(
                        color: MoolColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          Wrap(
            spacing: MoolSpacing.xs,
            runSpacing: MoolSpacing.xs,
            children: [
              OutlinedButton.icon(
                key: const Key('buy-collection-directions'),
                onPressed: () =>
                    session.showNotice('Directions opened for the store.'),
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Directions'),
              ),
              OutlinedButton.icon(
                key: const Key('buy-call-shop'),
                onPressed: () => _showCallShop(context, session),
                icon: const Icon(Icons.call_outlined),
                label: const Text('Call shop'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionCode extends StatelessWidget {
  const _CollectionCode({required this.available});

  final bool available;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      color: available ? const Color(0xFFEAF7E8) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            available ? 'Show this code at the counter' : 'Collection code',
            style: const TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          Center(
            child: Text(
              available ? '4 7 2 9' : 'Available when your basket is ready',
              key: const Key('buy-collection-code'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: available ? MoolColors.success : MoolColors.muted,
                fontSize: available ? 34 : 14,
                fontWeight: FontWeight.w900,
                letterSpacing: available ? 7 : 0,
              ),
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          const Text(
            'Do not share the code until you are at the selected store.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MoolColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionActions extends StatelessWidget {
  const _CollectionActions({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Collection options',
            style: TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          ListTile(
            key: const Key('buy-share-collection'),
            leading: const Icon(
              Icons.ios_share_rounded,
              color: MoolColors.navy,
            ),
            title: const Text('Share collection details'),
            subtitle: const Text('Code stays hidden from the shared message'),
            onTap: () => session.showNotice(
              'Collection address and order number are ready to share.',
            ),
          ),
          ListTile(
            key: const Key('buy-change-collection-person'),
            leading: const Icon(
              Icons.person_add_alt_outlined,
              color: MoolColors.navy,
            ),
            title: const Text('Let someone else collect'),
            subtitle: const Text('Add their name before sharing the code'),
            onTap: () => _showCollectorSheet(context, session),
          ),
          ListTile(
            key: const Key('buy-collection-support'),
            leading: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: MoolColors.navy,
            ),
            title: const Text('Chat with order support'),
            onTap: () {
              final current = GoRouterState.of(context).uri.toString();
              context.go(
                Uri(
                  path: '/app/chat/thread/order-support',
                  queryParameters: {'return': current},
                ).toString(),
              );
            },
          ),
        ],
      ),
    );
  }
}

Future<void> _showCallShop(BuildContext context, BuySession session) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        MoolSpacing.sm,
        MoolSpacing.lg,
        MoolSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Call Mahadev Fresh Mart?',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.xs),
          const Text('The shop will see your order number with the call.'),
          const SizedBox(height: MoolSpacing.md),
          FilledButton.icon(
            key: const Key('buy-confirm-call-shop'),
            onPressed: () {
              Navigator.of(sheetContext).pop();
              session.showNotice('Calling Mahadev Fresh Mart.');
            },
            icon: const Icon(Icons.call_outlined),
            label: const Text('Call shop'),
          ),
          TextButton(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showCollectorSheet(BuildContext context, BuySession session) {
  var name = '';
  String? error;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
          MoolSpacing.lg,
          MoolSpacing.sm,
          MoolSpacing.lg,
          MediaQuery.viewInsetsOf(sheetContext).bottom + MoolSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Who will collect the order?',
              style: TextStyle(
                color: MoolColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            TextFormField(
              key: const Key('buy-collector-name'),
              onChanged: (value) => name = value,
              decoration: InputDecoration(
                labelText: 'Collector name',
                errorText: error,
              ),
            ),
            const SizedBox(height: MoolSpacing.md),
            FilledButton(
              key: const Key('buy-save-collector'),
              onPressed: () {
                if (name.trim().length < 2) {
                  setSheetState(() => error = 'Enter the collector name.');
                  return;
                }
                Navigator.of(sheetContext).pop();
                session.showNotice(
                  '${name.trim()} can collect after showing the collection code.',
                );
              },
              child: const Text('Allow collection'),
            ),
            TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showCollectionHelp(BuildContext context, BuySession session) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(
        MoolSpacing.lg,
        MoolSpacing.sm,
        MoolSpacing.lg,
        MoolSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Collection help',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          ListTile(
            key: const Key('buy-help-collection-refresh'),
            leading: const Icon(Icons.refresh_rounded, color: MoolColors.navy),
            title: const Text('Refresh collection status'),
            onTap: () {
              session.refreshCollectionStatus();
              Navigator.of(sheetContext).pop();
            },
          ),
          ListTile(
            key: const Key('buy-help-collection-chat'),
            leading: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: MoolColors.navy,
            ),
            title: const Text('Chat with order support'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              final current = GoRouterState.of(context).uri.toString();
              context.go(
                Uri(
                  path: '/app/chat/thread/order-support',
                  queryParameters: {'return': current},
                ).toString(),
              );
            },
          ),
          ListTile(
            key: const Key('buy-help-collection-cancel'),
            leading: const Icon(
              Icons.cancel_outlined,
              color: Color(0xFFB42318),
            ),
            title: const Text('Check cancellation options'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              session.showNotice(
                'Cancellation is available until the order is ready.',
              );
            },
          ),
        ],
      ),
    ),
  );
}
