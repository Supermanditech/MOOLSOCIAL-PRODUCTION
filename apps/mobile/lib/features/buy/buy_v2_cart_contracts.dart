import 'package:flutter/foundation.dart';

import 'buy_v2_models.dart';

enum BuyV2CartBenefitKind { coupon, paymentOffer }

// Founder post-integration owner boundary (2026-08-29): Codex Workspace must
// publish each supplier's exact commercial terms, MSME classification,
// booking/balance schedule, regulated-financier offer, delivery partner and
// dispatch/delivery promise. Cursor Buy then renders and validates those exact
// choices. Supplier credit for a micro/small enterprise must never exceed the
// applicable MSMED payment limit; a longer bank/NBFC tenor is a separate
// regulated credit product, never a supplier-term shortcut.

@immutable
class BuyV2CartBenefit {
  const BuyV2CartBenefit({
    required this.id,
    required this.kind,
    required this.destination,
    required this.title,
    required this.detail,
    required this.sourceId,
  });

  final String id;
  final BuyV2CartBenefitKind kind;
  final BuyV2Destination destination;
  final String title;
  final String detail;
  final String sourceId;
}

abstract interface class BuyV2CartBenefitsAdapter {
  const BuyV2CartBenefitsAdapter();

  List<BuyV2CartBenefit> benefitsFor({
    required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations,
    required int itemTotal,
  });
}

/// Compile-time boundary for founder device-review benefit states.
///
/// Normal builds omit [MOOLSOCIAL_DEVICE_REVIEW] and remain fail-closed until
/// an approved benefits backend is connected.
const bool buyV2DeviceReviewBenefitSeedsEnabled = bool.fromEnvironment(
  'MOOLSOCIAL_DEVICE_REVIEW',
);

class BuyV2SeededCartBenefitsAdapter implements BuyV2CartBenefitsAdapter {
  const BuyV2SeededCartBenefitsAdapter();

  @override
  List<BuyV2CartBenefit> benefitsFor({
    required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations,
    required int itemTotal,
  }) {
    if (itemTotal <= 0 || destinations.contains(BuyV2Destination.orders)) {
      return const [];
    }
    return List.unmodifiable([
      for (final destination in destinations)
        if (destination != BuyV2Destination.orders)
          ..._deviceReviewBenefits(destination, kind),
    ]);
  }
}

List<BuyV2CartBenefit> _deviceReviewBenefits(
  BuyV2Destination destination,
  BuyV2CartBenefitKind kind,
) {
  final verticalId = destination.name;
  final titles = switch ((destination, kind)) {
    (BuyV2Destination.shop, BuyV2CartBenefitKind.coupon) => const [
      'Shop basket coupon',
      'Shop product coupon',
      'Shop partner coupon',
    ],
    (BuyV2Destination.shop, BuyV2CartBenefitKind.paymentOffer) => const [
      'Shop payment offer',
      'Checkout payment offer',
      'Shop partner payment offer',
    ],
    (BuyV2Destination.wholesale, BuyV2CartBenefitKind.coupon) => const [
      'Trade order coupon',
      'Trade pack coupon',
      'Supplier coupon',
    ],
    (BuyV2Destination.wholesale, BuyV2CartBenefitKind.paymentOffer) => const [
      'Trade payment offer',
      'Business payment offer',
      'Supplier payment offer',
    ],
    (BuyV2Destination.medicine, BuyV2CartBenefitKind.coupon) => const [
      'Medicine order coupon',
      'Medicine product coupon',
      'Pharmacy coupon',
    ],
    (BuyV2Destination.medicine, BuyV2CartBenefitKind.paymentOffer) => const [
      'Medicine payment offer',
      'Checkout payment offer',
      'Pharmacy payment offer',
    ],
    (BuyV2Destination.orders, _) => throw StateError(
      'Orders cannot own cart benefits.',
    ),
  };
  final detail = switch (kind) {
    BuyV2CartBenefitKind.coupon =>
      'Eligibility and any saving are confirmed before payment.',
    BuyV2CartBenefitKind.paymentOffer =>
      'Choose a payment method at Checkout to check available benefits.',
  };
  return List.unmodifiable([
    for (var index = 0; index < titles.length; index++)
      BuyV2CartBenefit(
        id: index == 0
            ? '$verticalId-${kind.name}'
            : '$verticalId-${kind.name}-${index + 1}',
        kind: kind,
        destination: destination,
        title: titles[index],
        detail: detail,
        sourceId: 'device-seed-v2',
      ),
  ]);
}

class BuyV2DisabledCartBenefitsAdapter implements BuyV2CartBenefitsAdapter {
  const BuyV2DisabledCartBenefitsAdapter();

  @override
  List<BuyV2CartBenefit> benefitsFor({
    required BuyV2CartBenefitKind kind,
    required Set<BuyV2Destination> destinations,
    required int itemTotal,
  }) => const [];
}

@immutable
class BuyV2DeliveryInstructionOption {
  const BuyV2DeliveryInstructionOption({
    required this.id,
    required this.destination,
    required this.label,
    required this.detail,
  });

  final String id;
  final BuyV2Destination destination;
  final String label;
  final String detail;
}

const buyV2DeliveryInstructionOptions = <BuyV2DeliveryInstructionOption>[
  BuyV2DeliveryInstructionOption(
    id: 'shop-call-arrival',
    destination: BuyV2Destination.shop,
    label: 'Call on arrival',
    detail: 'Use the saved delivery phone.',
  ),
  BuyV2DeliveryInstructionOption(
    id: 'shop-security',
    destination: BuyV2Destination.shop,
    label: 'Leave with security',
    detail: 'Only where building security accepts deliveries.',
  ),
  BuyV2DeliveryInstructionOption(
    id: 'shop-door',
    destination: BuyV2Destination.shop,
    label: 'Leave at the door',
    detail: 'Place the order at the saved address door.',
  ),
  BuyV2DeliveryInstructionOption(
    id: 'shop-no-bell',
    destination: BuyV2Destination.shop,
    label: 'Do not ring',
    detail: 'Call instead of using the doorbell.',
  ),
  BuyV2DeliveryInstructionOption(
    id: 'trade-call-receiving',
    destination: BuyV2Destination.wholesale,
    label: 'Call receiving contact',
    detail: 'Use the saved business delivery phone.',
  ),
  BuyV2DeliveryInstructionOption(
    id: 'trade-receiving-desk',
    destination: BuyV2Destination.wholesale,
    label: 'Deliver to receiving',
    detail: 'Report to the business receiving point.',
  ),
  BuyV2DeliveryInstructionOption(
    id: 'trade-loading-access',
    destination: BuyV2Destination.wholesale,
    label: 'Loading access needed',
    detail: 'Confirm access before unloading.',
  ),
  BuyV2DeliveryInstructionOption(
    id: 'trade-cartons-together',
    destination: BuyV2Destination.wholesale,
    label: 'Keep cartons together',
    detail: 'Keep this trade order grouped at handover.',
  ),
  BuyV2DeliveryInstructionOption(
    id: 'medicine-hand-recipient',
    destination: BuyV2Destination.medicine,
    label: 'Hand to recipient',
    detail: 'Give the order to the named recipient.',
  ),
  BuyV2DeliveryInstructionOption(
    id: 'medicine-call-arrival',
    destination: BuyV2Destination.medicine,
    label: 'Call on arrival',
    detail: 'Use the saved delivery phone.',
  ),
  BuyV2DeliveryInstructionOption(
    id: 'medicine-no-bell',
    destination: BuyV2Destination.medicine,
    label: 'Do not ring',
    detail: 'Call instead of using the doorbell.',
  ),
  BuyV2DeliveryInstructionOption(
    id: 'medicine-no-unattended',
    destination: BuyV2Destination.medicine,
    label: 'Do not leave unattended',
    detail: 'Wait for a recipient at the saved address.',
  ),
];

List<BuyV2DeliveryInstructionOption> buyV2DeliveryInstructionsFor(
  BuyV2Destination destination,
) => List.unmodifiable(
  buyV2DeliveryInstructionOptions.where(
    (option) => option.destination == destination,
  ),
);

@immutable
class BuyV2TipOption {
  const BuyV2TipOption({required this.amount});

  final int amount;
}

abstract interface class BuyV2TipPolicy {
  const BuyV2TipPolicy();

  List<BuyV2TipOption> optionsFor(BuyV2Destination destination);

  bool accepts(BuyV2Destination destination, int amount);
}

class BuyV2DisabledTipPolicy implements BuyV2TipPolicy {
  const BuyV2DisabledTipPolicy();

  @override
  List<BuyV2TipOption> optionsFor(BuyV2Destination destination) => const [];

  @override
  bool accepts(BuyV2Destination destination, int amount) => amount == 0;
}
