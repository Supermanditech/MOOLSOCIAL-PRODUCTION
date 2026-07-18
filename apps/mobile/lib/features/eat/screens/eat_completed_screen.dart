import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/mool_design_system.dart';
import '../../../core/design/mool_theme.dart';
import '../eat_session.dart';
import '../widgets/eat_widgets.dart';

class EatCompletedScreen extends StatelessWidget {
  const EatCompletedScreen({
    required this.session,
    required this.orderId,
    super.key,
  });

  final EatSession session;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => EatPageScaffold(
        key: const Key('eat-completed-screen'),
        session: session,
        title: 'Meal delivered',
        subtitle: orderId,
        activeDock: 'order',
        fallbackBackRoute: '/app/eat/order/$orderId',
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            MoolSpacing.md,
            MoolSpacing.xs,
            MoolSpacing.md,
            MoolSpacing.xxl,
          ),
          children: [
            const EatSurfaceCard(
              color: Color(0xFFEAF7E8),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 56,
                    color: MoolColors.success,
                  ),
                  SizedBox(height: MoolSpacing.sm),
                  Text(
                    'Your meal is complete',
                    style: TextStyle(
                      color: MoolColors.ink,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'The digital bill and delivery proof are saved with this order.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: MoolColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            EatSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rate your meal',
                    style: TextStyle(
                      color: MoolColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: MoolSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      return IconButton(
                        key: Key('eat-rating-$value'),
                        tooltip: 'Rate $value stars',
                        onPressed: () => session.setFoodRating(value),
                        icon: Icon(
                          value <= session.foodRating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: MoolColors.orange,
                          size: 31,
                        ),
                      );
                    }),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('eat-submit-rating'),
                      onPressed: session.submitFoodRating,
                      child: const Text('Submit rating'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MoolSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('eat-view-bill'),
                    onPressed: () => session.showNotice(
                      'Digital bill opened for order $orderId.',
                    ),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('View bill'),
                  ),
                ),
                const SizedBox(width: MoolSpacing.xs),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('eat-report-problem'),
                    onPressed: () => context.go(
                      '/app/chat/thread/order-support?return=/app/eat/order/$orderId/completed',
                    ),
                    icon: const Icon(Icons.support_agent_rounded),
                    label: const Text('Get help'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MoolSpacing.xs),
            FilledButton(
              key: const Key('eat-order-again'),
              onPressed: () {
                session.startNewFoodOrder();
                context.go('/app/eat/order');
              },
              child: const Text('Order food again'),
            ),
          ],
        ),
      ),
    );
  }
}
