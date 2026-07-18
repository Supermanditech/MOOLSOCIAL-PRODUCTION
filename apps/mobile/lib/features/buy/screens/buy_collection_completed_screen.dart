import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../buy_models.dart';
import '../buy_session.dart';
import '../widgets/buy_widgets.dart';

class BuyCollectionCompletedScreen extends StatefulWidget {
  const BuyCollectionCompletedScreen({
    required this.session,
    required this.orderId,
    super.key,
  });

  final BuySession session;
  final String orderId;

  @override
  State<BuyCollectionCompletedScreen> createState() =>
      _BuyCollectionCompletedScreenState();
}

class _BuyCollectionCompletedScreenState
    extends State<BuyCollectionCompletedScreen> {
  bool _ratingOpen = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.session,
      builder: (context, _) {
        final receipt = widget.session.receipt;
        if (receipt == null ||
            receipt.id != widget.orderId ||
            receipt.fulfilment != BuyFulfilment.storePickup) {
          return BuyPageScaffold(
            session: widget.session,
            title: 'Collection not available',
            subtitle: 'Return to the shop',
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
        return BuyPageScaffold(
          key: const Key('buy-collection-completed-screen'),
          session: widget.session,
          title: 'Collected',
          subtitle: '${receipt.id} · Bill ${buyMoney(receipt.total)}',
          activeDock: 'orders',
          fallbackBackRoute: '/app/buy/order/${receipt.id}/collection',
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xxl,
            ),
            children: [
              const _CollectionCompleteHero(),
              const SizedBox(height: MoolSpacing.sm),
              BuySurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Collection receipt',
                      style: TextStyle(
                        color: MoolColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    for (final line in receipt.lines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${line.quantity} × ${line.product.name}',
                              ),
                            ),
                            Text(
                              buyMoney(line.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Divider(),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Paid total',
                            style: TextStyle(
                              color: MoolColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          buyMoney(receipt.total),
                          style: const TextStyle(
                            color: MoolColors.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MoolSpacing.sm),
                    OutlinedButton.icon(
                      key: const Key('buy-download-collection-bill'),
                      onPressed: () => widget.session.showNotice(
                        'Collection bill saved to your downloads.',
                      ),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download bill'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MoolSpacing.sm),
              BuySurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      key: const Key('buy-rate-collection'),
                      onPressed: () => setState(() => _ratingOpen = true),
                      icon: const Icon(Icons.star_outline_rounded),
                      label: const Text('Rate the shop'),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    OutlinedButton.icon(
                      key: const Key('buy-report-collection-problem'),
                      onPressed: () =>
                          context.go('/app/buy/order/${receipt.id}/problem'),
                      icon: const Icon(Icons.report_problem_outlined),
                      label: const Text('Report an order problem'),
                    ),
                    const SizedBox(height: MoolSpacing.xs),
                    TextButton.icon(
                      key: const Key('buy-new-basket-after-collection'),
                      onPressed: () {
                        widget.session.startNewBasket();
                        context.go('/app/buy/grocery');
                      },
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Start a new basket'),
                    ),
                  ],
                ),
              ),
              if (_ratingOpen || widget.session.ratingSubmitted) ...[
                const SizedBox(height: MoolSpacing.sm),
                _CollectionRating(session: widget.session),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CollectionCompleteHero extends StatelessWidget {
  const _CollectionCompleteHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MoolSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0C6E10), MoolColors.success],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(MoolRadii.sheet),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(Icons.check_rounded, color: MoolColors.success),
          ),
          SizedBox(height: MoolSpacing.md),
          Text(
            'Order collected successfully',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: MoolSpacing.xs),
          Text(
            'Your bill is ready. Check the items before leaving the store.',
            style: TextStyle(
              color: Color(0xE6FFFFFF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionRating extends StatelessWidget {
  const _CollectionRating({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      key: const Key('buy-collection-rating-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate Mahadev Fresh Mart',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          Row(
            children: [
              for (var rating = 1; rating <= 5; rating++)
                Expanded(
                  child: IconButton(
                    key: Key('buy-rate-collection-shop-$rating'),
                    tooltip: '$rating ${rating == 1 ? 'star' : 'stars'}',
                    onPressed: () => session.setShopRating(rating),
                    icon: Icon(
                      rating <= session.shopRating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: MoolColors.orange,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: MoolSpacing.sm),
          FilledButton(
            key: const Key('buy-submit-collection-rating'),
            onPressed: session.ratingSubmitted
                ? null
                : session.submitCollectionRating,
            child: Text(
              session.ratingSubmitted ? 'Rating submitted' : 'Submit rating',
            ),
          ),
        ],
      ),
    );
  }
}
