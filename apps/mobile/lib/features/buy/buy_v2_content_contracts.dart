import 'package:flutter/foundation.dart';

import 'buy_v2_models.dart';

@immutable
class BuyV2ProductFactsSnapshot {
  const BuyV2ProductFactsSnapshot({
    required this.productId,
    required this.price,
    required this.deliveryPromise,
    required this.partner,
    required this.orderabilityLabel,
    required this.sourceId,
    this.observedAt,
    this.stale = false,
  }) : assert(
         observedAt == null || sourceId != '',
         'Changing product facts require a named source.',
       );

  final String productId;
  final int price;
  final String deliveryPromise;
  final String partner;
  final String orderabilityLabel;
  final String sourceId;
  final DateTime? observedAt;
  final bool stale;

  bool get isLive => observedAt != null;

  BuyV2ProductFactsSnapshot copyWith({
    int? price,
    String? deliveryPromise,
    String? partner,
    String? orderabilityLabel,
    String? sourceId,
    DateTime? observedAt,
    bool? stale,
  }) {
    return BuyV2ProductFactsSnapshot(
      productId: productId,
      price: price ?? this.price,
      deliveryPromise: deliveryPromise ?? this.deliveryPromise,
      partner: partner ?? this.partner,
      orderabilityLabel: orderabilityLabel ?? this.orderabilityLabel,
      sourceId: sourceId ?? this.sourceId,
      observedAt: observedAt ?? this.observedAt,
      stale: stale ?? this.stale,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BuyV2ProductFactsSnapshot &&
        other.productId == productId &&
        other.price == price &&
        other.deliveryPromise == deliveryPromise &&
        other.partner == partner &&
        other.orderabilityLabel == orderabilityLabel &&
        other.sourceId == sourceId &&
        other.observedAt == observedAt &&
        other.stale == stale;
  }

  @override
  int get hashCode => Object.hash(
    productId,
    price,
    deliveryPromise,
    partner,
    orderabilityLabel,
    sourceId,
    observedAt,
    stale,
  );
}

abstract interface class BuyV2ProductFactsAdapter {
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product);
}

final class BuyV2CatalogueProductFactsAdapter
    implements BuyV2ProductFactsAdapter {
  const BuyV2CatalogueProductFactsAdapter();

  @override
  BuyV2ProductFactsSnapshot snapshotFor(BuyV2Product product) {
    return BuyV2ProductFactsSnapshot(
      productId: product.id,
      price: product.price,
      deliveryPromise: product.deliveryPromise,
      partner: product.seller,
      orderabilityLabel: product.requiresPrescription
          ? 'Prescription required'
          : 'Available to add',
      sourceId: 'approved-buy-catalogue',
    );
  }
}

enum BuyV2SponsoredPlacement {
  catalogueAfterDiscovery,
  ordersAfterHistory,
  cartBeforeSummary,
}

enum BuyV2SponsoredFormat { card, inlineVideo }

@immutable
class BuyV2SponsoredContent {
  const BuyV2SponsoredContent({
    required this.id,
    required this.placement,
    required this.format,
    required this.disclosure,
    required this.title,
    required this.detail,
    this.posterAsset,
    this.captions,
    this.transcript,
  }) : assert(disclosure == 'Sponsored' || disclosure == 'Advertisement'),
       assert(
         format != BuyV2SponsoredFormat.inlineVideo ||
             (posterAsset != null && captions != null && transcript != null),
         'Inline video requires a poster, captions and transcript.',
       );

  final String id;
  final BuyV2SponsoredPlacement placement;
  final BuyV2SponsoredFormat format;
  final String disclosure;
  final String title;
  final String detail;
  final String? posterAsset;
  final String? captions;
  final String? transcript;
}

abstract interface class BuyV2SponsoredContentAdapter {
  BuyV2SponsoredContent? contentFor(BuyV2SponsoredPlacement placement);
}

final class BuyV2DisabledSponsoredContentAdapter
    implements BuyV2SponsoredContentAdapter {
  const BuyV2DisabledSponsoredContentAdapter();

  @override
  BuyV2SponsoredContent? contentFor(BuyV2SponsoredPlacement placement) => null;
}

abstract final class BuyV2ExperienceBudgets {
  static const targetFrame = Duration(microseconds: 16667);
  static const slowFrameCeiling = Duration(milliseconds: 33);
  static const maximumSponsoredCardsPerCatalogue = 1;
  static const maximumInlineVideosPerViewport = 1;
  static const maximumPreloadedInlineVideos = 0;
  static const autoplayAudioAllowed = false;
  static const perpetualDecorativeMotionAllowed = false;
}
