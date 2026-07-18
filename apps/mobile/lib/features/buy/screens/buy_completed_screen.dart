import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../buy_models.dart';
import '../buy_session.dart';
import '../widgets/buy_widgets.dart';

class BuyCompletedScreen extends StatefulWidget {
  const BuyCompletedScreen({
    required this.session,
    required this.orderId,
    super.key,
  });

  final BuySession session;
  final String orderId;

  @override
  State<BuyCompletedScreen> createState() => _BuyCompletedScreenState();
}

class _BuyCompletedScreenState extends State<BuyCompletedScreen> {
  bool _ratingsOpen = false;

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
                key: const Key('buy-completed-shop'),
                onPressed: () => context.go('/app/buy/grocery'),
                child: const Text('Shop products'),
              ),
            ),
          );
        }
        return BuyPageScaffold(
          key: const Key('buy-completed-screen'),
          session: widget.session,
          title: 'Delivered',
          subtitle: '${receipt.id} · Bill ${buyMoney(receipt.total)}',
          activeDock: 'orders',
          fallbackBackRoute: '/app/buy/order/${receipt.id}',
          trailing: IconButton.outlined(
            key: const Key('buy-share-bill-top'),
            tooltip: 'Share bill',
            onPressed: () => _showBillShare(context, receipt),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              MoolSpacing.md,
              MoolSpacing.xs,
              MoolSpacing.md,
              MoolSpacing.xxl,
            ),
            children: [
              _DeliveredHero(receipt: receipt),
              const SizedBox(height: MoolSpacing.sm),
              _NextActions(
                onRate: () => setState(() => _ratingsOpen = true),
                onProblem: () =>
                    context.go('/app/buy/order/${receipt.id}/problem'),
                onShopAgain: () {
                  widget.session.startNewBasket();
                  context.go('/app/buy/grocery');
                },
              ),
              const SizedBox(height: MoolSpacing.sm),
              _BillCard(receipt: receipt),
              const SizedBox(height: MoolSpacing.sm),
              const _ProofCard(),
              if (_ratingsOpen || widget.session.ratingSubmitted) ...[
                const SizedBox(height: MoolSpacing.sm),
                _RatingCard(session: widget.session),
              ],
              const SizedBox(height: MoolSpacing.sm),
              _RepeatCard(
                onShopAgain: () {
                  widget.session.startNewBasket();
                  context.go('/app/buy/grocery');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DeliveredHero extends StatelessWidget {
  const _DeliveredHero({required this.receipt});

  final BuyOrderReceipt receipt;

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
        boxShadow: MoolShadows.floating,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.check_rounded,
              color: MoolColors.success,
              size: 30,
            ),
          ),
          SizedBox(height: MoolSpacing.md),
          Text(
            'Delivered at your doorstep',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -.45,
            ),
          ),
          SizedBox(height: MoolSpacing.xs),
          Text(
            'Your bill and delivery proof are ready. Check the items before rating the order.',
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

class _NextActions extends StatelessWidget {
  const _NextActions({
    required this.onRate,
    required this.onProblem,
    required this.onShopAgain,
  });

  final VoidCallback onRate;
  final VoidCallback onProblem;
  final VoidCallback onShopAgain;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What would you like to do?',
            style: TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          FilledButton.icon(
            key: const Key('buy-rate-order'),
            onPressed: onRate,
            icon: const Icon(Icons.star_outline_rounded),
            label: const Text('Rate this order'),
          ),
          const SizedBox(height: MoolSpacing.xs),
          OutlinedButton.icon(
            key: const Key('buy-report-problem'),
            onPressed: onProblem,
            icon: const Icon(Icons.report_problem_outlined),
            label: const Text('Report an order problem'),
          ),
          const SizedBox(height: MoolSpacing.xs),
          TextButton.icon(
            key: const Key('buy-shop-again'),
            onPressed: onShopAgain,
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Start a new basket'),
          ),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({required this.receipt});

  final BuyOrderReceipt receipt;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Order bill',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                receipt.id,
                style: const TextStyle(
                  color: MoolColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    buyMoney(line.total),
                    style: const TextStyle(fontWeight: FontWeight.w800),
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
          Wrap(
            spacing: MoolSpacing.xs,
            runSpacing: MoolSpacing.xs,
            children: [
              OutlinedButton.icon(
                key: const Key('buy-download-bill'),
                onPressed: () =>
                    _showSnack(context, 'Bill saved to your downloads.'),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download'),
              ),
              OutlinedButton.icon(
                key: const Key('buy-share-bill'),
                onPressed: () => _showBillShare(context, receipt),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Share'),
              ),
              OutlinedButton.icon(
                key: const Key('buy-open-orders'),
                onPressed: () => context.go('/app/buy/order/${receipt.id}'),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Order'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProofCard extends StatelessWidget {
  const _ProofCard();

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEEFF),
              borderRadius: BorderRadius.circular(MoolRadii.control),
            ),
            child: const Icon(Icons.image_outlined, color: MoolColors.navy),
          ),
          const SizedBox(width: MoolSpacing.sm),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Doorstep delivery proof',
                  style: TextStyle(
                    color: MoolColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Captured at delivery · visible only to you and support',
                  style: TextStyle(color: MoolColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('buy-view-proof'),
            tooltip: 'View delivery proof',
            onPressed: () => _showProof(context),
            icon: const Icon(Icons.open_in_full_rounded),
          ),
        ],
      ),
    );
  }
}

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.session});

  final BuySession session;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      key: const Key('buy-rating-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate your experience',
            style: TextStyle(
              color: MoolColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          _StarRow(
            label: 'Mahadev Fresh Mart',
            target: 'shop',
            value: session.shopRating,
            onChanged: session.setShopRating,
          ),
          const SizedBox(height: MoolSpacing.md),
          _StarRow(
            label: 'Rakesh · delivery partner',
            target: 'rider',
            value: session.riderRating,
            onChanged: session.setRiderRating,
          ),
          const SizedBox(height: MoolSpacing.md),
          FilledButton(
            key: const Key('buy-submit-rating'),
            onPressed: session.ratingSubmitted ? null : session.submitRating,
            child: Text(
              session.ratingSubmitted ? 'Ratings submitted' : 'Submit ratings',
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({
    required this.label,
    required this.target,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String target;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: MoolSpacing.xs),
        Row(
          children: [
            for (var rating = 1; rating <= 5; rating++)
              Expanded(
                child: IconButton(
                  key: Key('buy-rate-$target-$rating'),
                  tooltip: '$rating ${rating == 1 ? 'star' : 'stars'}',
                  onPressed: () => onChanged(rating),
                  icon: Icon(
                    rating <= value
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: MoolColors.orange,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RepeatCard extends StatelessWidget {
  const _RepeatCard({required this.onShopAgain});

  final VoidCallback onShopAgain;

  @override
  Widget build(BuildContext context) {
    return BuySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Make the next order easier',
            style: TextStyle(
              color: MoolColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.sm),
          OutlinedButton.icon(
            key: const Key('buy-repeat-order'),
            onPressed: onShopAgain,
            icon: const Icon(Icons.repeat_rounded),
            label: const Text('Shop these items again'),
          ),
          const SizedBox(height: MoolSpacing.xs),
          OutlinedButton.icon(
            key: const Key('buy-monthly-reminder'),
            onPressed: () =>
                _showSnack(context, 'Monthly basket reminder is on.'),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Remind me next month'),
          ),
        ],
      ),
    );
  }
}

Future<void> _showBillShare(BuildContext context, BuyOrderReceipt receipt) {
  final pageContext = context;
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
          Text(
            'Share bill ${receipt.id}',
            style: const TextStyle(
              color: MoolColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MoolSpacing.md),
          ListTile(
            key: const Key('buy-share-bill-chat'),
            leading: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: MoolColors.navy,
            ),
            title: const Text('MoolSocial Chat'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _showSnack(pageContext, 'Bill attached to a new chat message.');
            },
          ),
          ListTile(
            key: const Key('buy-share-bill-more'),
            leading: const Icon(
              Icons.ios_share_rounded,
              color: MoolColors.navy,
            ),
            title: const Text('More apps'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _showSnack(pageContext, 'Device sharing options opened.');
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _showProof(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Doorstep delivery proof'),
      content: Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFFEDEEFF),
          borderRadius: BorderRadius.circular(MoolRadii.card),
        ),
        child: const Center(
          child: Icon(
            Icons.inventory_2_outlined,
            color: MoolColors.navy,
            size: 62,
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('buy-close-proof'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
