import 'package:flutter/foundation.dart';

import 'buy_v2_models.dart';

enum BuyV2OrderResolutionKind { cancel, returnItems, replacement, refund }

enum BuyV2OrderResolutionState { loading, ready, offline, unavailable }

@immutable
class BuyV2OrderResolutionOption {
  const BuyV2OrderResolutionOption({
    required this.kind,
    required this.title,
    required this.detail,
    required this.reasons,
  });

  final BuyV2OrderResolutionKind kind;
  final String title;
  final String detail;
  final List<String> reasons;
}

@immutable
class BuyV2OrderResolutionItemEligibility {
  const BuyV2OrderResolutionItemEligibility({
    required this.productId,
    required this.kind,
    required this.eligibleQuantity,
    required this.policyWindow,
    this.eligibleUntil,
    this.exclusionReason,
  });

  final String productId;
  final BuyV2OrderResolutionKind kind;
  final int eligibleQuantity;

  /// Policy recorded for this purchased item, supplied by the order service.
  final String policyWindow;
  final DateTime? eligibleUntil;
  final String? exclusionReason;

  String? unavailableReasonAt(DateTime now) {
    if (exclusionReason?.trim().isNotEmpty ?? false) return exclusionReason;
    if (eligibleQuantity == 0) return 'This item is not eligible.';
    if (policyWindow.trim().isEmpty || eligibleUntil == null) {
      return 'Eligibility could not be confirmed. Contact support for help.';
    }
    if (!now.isBefore(eligibleUntil!)) {
      return 'The request window has ended. Contact support for help.';
    }
    return null;
  }
}

@immutable
class BuyV2OrderResolutionSnapshot {
  const BuyV2OrderResolutionSnapshot({
    required this.orderId,
    required this.state,
    required this.sourceId,
    this.options = const [],
    this.itemEligibility = const [],
    this.customerMessage,
  });

  final String orderId;
  final BuyV2OrderResolutionState state;
  final String sourceId;
  final List<BuyV2OrderResolutionOption> options;
  final List<BuyV2OrderResolutionItemEligibility> itemEligibility;
  final String? customerMessage;
}

@immutable
class BuyV2OrderResolutionRequest {
  const BuyV2OrderResolutionRequest({
    required this.orderId,
    required this.kind,
    required this.reason,
    this.itemQuantities = const {},
    this.eligibilitySourceId,
  });

  final String orderId;
  final BuyV2OrderResolutionKind kind;
  final String reason;
  final Map<String, int> itemQuantities;
  final String? eligibilitySourceId;
}

@immutable
class BuyV2OrderResolutionResult {
  const BuyV2OrderResolutionResult({
    required this.accepted,
    required this.customerMessage,
    this.reference,
  });

  final bool accepted;
  final String customerMessage;
  final String? reference;
}

abstract interface class BuyV2OrderResolutionAdapter {
  const BuyV2OrderResolutionAdapter();

  Future<BuyV2OrderResolutionSnapshot> load(BuyV2Order order);

  /// The order service must revalidate item eligibility and quantities atomically.
  Future<BuyV2OrderResolutionResult> submit(
    BuyV2OrderResolutionRequest request,
  );
}

final class BuyV2UnavailableOrderResolutionAdapter
    implements BuyV2OrderResolutionAdapter {
  const BuyV2UnavailableOrderResolutionAdapter();

  @override
  Future<BuyV2OrderResolutionSnapshot> load(
    BuyV2Order order,
  ) async => BuyV2OrderResolutionSnapshot(
    orderId: order.id,
    state: BuyV2OrderResolutionState.unavailable,
    sourceId: 'order-resolution-unavailable',
    customerMessage:
        'Order changes are unavailable right now. Contact support for help.',
  );

  @override
  Future<BuyV2OrderResolutionResult> submit(
    BuyV2OrderResolutionRequest request,
  ) async => const BuyV2OrderResolutionResult(
    accepted: false,
    customerMessage:
        'This request could not be sent. Contact support for help.',
  );
}

/// Read-only options for the non-promotable UI-review package.
/// Submissions remain unavailable until a real order service accepts them.
final class BuyV2UiReviewOrderResolutionAdapter
    implements BuyV2OrderResolutionAdapter {
  const BuyV2UiReviewOrderResolutionAdapter();

  @override
  Future<BuyV2OrderResolutionSnapshot> load(BuyV2Order order) async {
    final delivered = order.status == BuyV2OrderStatus.delivered;
    return BuyV2OrderResolutionSnapshot(
      orderId: order.id,
      state: BuyV2OrderResolutionState.ready,
      sourceId: 'ui-review-order-resolution',
      options: delivered
          ? const [
              BuyV2OrderResolutionOption(
                kind: BuyV2OrderResolutionKind.returnItems,
                title: 'Return items',
                detail: 'Request a return for eligible delivered items.',
                reasons: [
                  'Damaged item',
                  'Incorrect item',
                  'Quality issue',
                  'Item no longer needed',
                ],
              ),
              BuyV2OrderResolutionOption(
                kind: BuyV2OrderResolutionKind.replacement,
                title: 'Request replacement',
                detail: 'Ask for an eligible item to be replaced.',
                reasons: ['Damaged item', 'Incorrect item', 'Missing item'],
              ),
              BuyV2OrderResolutionOption(
                kind: BuyV2OrderResolutionKind.refund,
                title: 'Request refund',
                detail: 'Request a refund review for an eligible item.',
                reasons: [
                  'Item not received',
                  'Damaged item',
                  'Incorrect item',
                  'Payment issue',
                ],
              ),
            ]
          : const [
              BuyV2OrderResolutionOption(
                kind: BuyV2OrderResolutionKind.cancel,
                title: 'Cancel order',
                detail:
                    'Request cancellation before the order enters delivery.',
                reasons: [
                  'Ordered by mistake',
                  'Need to change address',
                  'Need to change items',
                  'Delivery time does not work',
                ],
              ),
            ],
    );
  }

  @override
  Future<BuyV2OrderResolutionResult> submit(
    BuyV2OrderResolutionRequest request,
  ) async => const BuyV2OrderResolutionResult(
    accepted: false,
    customerMessage:
        'This request could not be sent. Contact support for help.',
  );
}
