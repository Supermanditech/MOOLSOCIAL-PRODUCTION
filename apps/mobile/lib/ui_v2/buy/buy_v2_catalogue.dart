import 'dart:async';

import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/mool_design_system.dart';
import '../../features/buy/buy_v2_content_contracts.dart';
import '../../features/buy/buy_v2_models.dart';
import '../../features/buy/buy_v2_session.dart';
import '../../features/buy/buy_v2_shopping_alerts.dart';
import 'buy_v2_address_sheet_motion.dart';
import 'buy_v2_category_sheet_policy.dart';
import 'buy_v2_design.dart';
import 'buy_v2_info_sheet_motion.dart';
import 'buy_v2_saved_clear_sheet_motion.dart';
import 'buy_v2_supplier_sheet_motion.dart';
import 'buy_v2_views.dart';

enum BuyV2OfferPublisherType { manufacturer, wholesaler, retailer }

@immutable
class BuyV2PublishedOffer {
  const BuyV2PublishedOffer({
    required this.productId,
    required this.publisherType,
    required this.headline,
  });

  final String productId;
  final BuyV2OfferPublisherType publisherType;
  final String headline;
}

/// Presentation seam for the ordered offer placements published for Buy.
///
/// The source supplies catalogue product IDs and merchandising copy only. The
/// existing Buy session remains the authority for product facts, cart state,
/// checkout and order creation.
abstract interface class BuyV2PublishedOffersSource {
  List<BuyV2PublishedOffer> get publishedOffers;
}

enum BuyV2PublishedOffersLoadState { loading, ready, offline, unavailable }

@immutable
class BuyV2PublishedOffersSnapshot {
  const BuyV2PublishedOffersSnapshot({
    required this.state,
    this.offers = const [],
    this.customerMessage,
  });

  final BuyV2PublishedOffersLoadState state;
  final List<BuyV2PublishedOffer> offers;
  final String? customerMessage;
}

abstract interface class BuyV2LivePublishedOffersSource
    implements BuyV2PublishedOffersSource {
  Future<BuyV2PublishedOffersSnapshot> load();
}

final class BuyV2CataloguePublishedOffersSource
    implements BuyV2PublishedOffersSource {
  const BuyV2CataloguePublishedOffersSource();

  @override
  List<BuyV2PublishedOffer> get publishedOffers => _publishedOffers;

  static const _publishedOffers = <BuyV2PublishedOffer>[
    BuyV2PublishedOffer(
      productId: 'w-oil',
      publisherType: BuyV2OfferPublisherType.manufacturer,
      headline: 'Manufacturer price',
    ),
    BuyV2PublishedOffer(
      productId: 's-tomato',
      publisherType: BuyV2OfferPublisherType.retailer,
      headline: 'Fresh price',
    ),
    BuyV2PublishedOffer(
      productId: 'w-rice',
      publisherType: BuyV2OfferPublisherType.wholesaler,
      headline: 'Bulk saving',
    ),
    BuyV2PublishedOffer(
      productId: 's-atta',
      publisherType: BuyV2OfferPublisherType.retailer,
      headline: 'Everyday value',
    ),
    BuyV2PublishedOffer(
      productId: 'w-notebook',
      publisherType: BuyV2OfferPublisherType.manufacturer,
      headline: 'Direct supply',
    ),
    BuyV2PublishedOffer(
      productId: 's-soap',
      publisherType: BuyV2OfferPublisherType.retailer,
      headline: 'Family pack deal',
    ),
    BuyV2PublishedOffer(
      productId: 'w-turmeric',
      publisherType: BuyV2OfferPublisherType.manufacturer,
      headline: 'Trade price',
    ),
    BuyV2PublishedOffer(
      productId: 's-milk',
      publisherType: BuyV2OfferPublisherType.retailer,
      headline: 'Daily essential',
    ),
    BuyV2PublishedOffer(
      productId: 'w-foil',
      publisherType: BuyV2OfferPublisherType.wholesaler,
      headline: 'Business pack',
    ),
    BuyV2PublishedOffer(
      productId: 's-toothpaste',
      publisherType: BuyV2OfferPublisherType.retailer,
      headline: 'Care saving',
    ),
    BuyV2PublishedOffer(
      productId: 'w-detergent',
      publisherType: BuyV2OfferPublisherType.manufacturer,
      headline: 'Manufacturer deal',
    ),
    BuyV2PublishedOffer(
      productId: 's-banana',
      publisherType: BuyV2OfferPublisherType.retailer,
      headline: 'Fresh today',
    ),
    BuyV2PublishedOffer(
      productId: 'w-tea',
      publisherType: BuyV2OfferPublisherType.wholesaler,
      headline: 'Stock-up price',
    ),
    BuyV2PublishedOffer(
      productId: 's-pasta',
      publisherType: BuyV2OfferPublisherType.retailer,
      headline: 'Meal deal',
    ),
    BuyV2PublishedOffer(
      productId: 'w-paper-cups',
      publisherType: BuyV2OfferPublisherType.wholesaler,
      headline: 'Volume saving',
    ),
    BuyV2PublishedOffer(
      productId: 's-diapers',
      publisherType: BuyV2OfferPublisherType.retailer,
      headline: 'Family saving',
    ),
    BuyV2PublishedOffer(
      productId: 'w-groundnut-oil',
      publisherType: BuyV2OfferPublisherType.manufacturer,
      headline: 'Direct price',
    ),
    BuyV2PublishedOffer(
      productId: 's-dog-food',
      publisherType: BuyV2OfferPublisherType.retailer,
      headline: 'Pet care deal',
    ),
    BuyV2PublishedOffer(
      productId: 'w-shampoo',
      publisherType: BuyV2OfferPublisherType.wholesaler,
      headline: 'Case saving',
    ),
    BuyV2PublishedOffer(
      productId: 's-chocolate',
      publisherType: BuyV2OfferPublisherType.retailer,
      headline: 'Popular offer',
    ),
    BuyV2PublishedOffer(
      productId: 'w-mustard-oil',
      publisherType: BuyV2OfferPublisherType.manufacturer,
      headline: 'Maker price',
    ),
    BuyV2PublishedOffer(
      productId: 's-curd',
      publisherType: BuyV2OfferPublisherType.retailer,
      headline: 'Chilled value',
    ),
    BuyV2PublishedOffer(
      productId: 'w-thermal-rolls',
      publisherType: BuyV2OfferPublisherType.manufacturer,
      headline: 'Direct supply',
    ),
    BuyV2PublishedOffer(
      productId: 's-water',
      publisherType: BuyV2OfferPublisherType.retailer,
      headline: 'Pack offer',
    ),
  ];
}

class BuyV2OffersView extends StatefulWidget {
  const BuyV2OffersView({
    super.key,
    required this.session,
    required this.source,
  });

  final BuyV2Session session;
  final BuyV2PublishedOffersSource source;

  @override
  State<BuyV2OffersView> createState() => _BuyV2OffersViewState();
}

class _BuyV2OffersViewState extends State<BuyV2OffersView> {
  BuyV2PublishedOffersSnapshot? _snapshot;
  BuyV2OfferPublisherType? _selectedPublisher;
  var _requestSequence = 0;

  BuyV2Session get session => widget.session;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BuyV2OffersView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) _load();
  }

  Future<void> _load() async {
    final source = widget.source;
    if (source is! BuyV2LivePublishedOffersSource) return;
    final request = ++_requestSequence;
    setState(() {
      _snapshot = const BuyV2PublishedOffersSnapshot(
        state: BuyV2PublishedOffersLoadState.loading,
      );
    });
    try {
      final snapshot = await source.load();
      if (!mounted || request != _requestSequence) return;
      setState(() => _snapshot = snapshot);
    } on Object {
      if (!mounted || request != _requestSequence) return;
      setState(() {
        _snapshot = const BuyV2PublishedOffersSnapshot(
          state: BuyV2PublishedOffersLoadState.offline,
          customerMessage:
              'Offers could not refresh. Check your connection and try again.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!session.catalogueAvailable) {
      return _OffersAvailabilityState(session: session);
    }
    final liveSource = widget.source is BuyV2LivePublishedOffersSource;
    if (!session.reviewDataEnabled && !liveSource) {
      return _OffersAvailabilityState(session: session);
    }
    final snapshot = _snapshot;
    if (liveSource && snapshot?.state != BuyV2PublishedOffersLoadState.ready) {
      return _LiveOffersState(snapshot: snapshot, onRetry: _load);
    }
    final publishedOffers = liveSource
        ? snapshot!.offers
        : widget.source.publishedOffers;
    final query = session.query.trim().toLowerCase();
    final allResolved = <({BuyV2PublishedOffer offer, BuyV2Product product})>[];
    final productIds = <String>{};
    for (final offer in publishedOffers) {
      final product = session.findProduct(offer.productId);
      if (product == null || !productIds.add(product.id)) continue;
      if (query.isNotEmpty &&
          !_matchesPublishedOffer(query, [
            product.title,
            product.brand,
            product.pack,
            product.badge,
            product.seller,
            product.sellerType,
            offer.headline,
          ])) {
        continue;
      }
      allResolved.add((offer: offer, product: product));
    }
    final resolved = _selectedPublisher == null
        ? allResolved
        : allResolved
              .where((entry) => entry.offer.publisherType == _selectedPublisher)
              .toList(growable: false);
    final products = resolved
        .map((entry) => entry.product)
        .toList(growable: false);
    final publisherCounts = {
      for (final type in BuyV2OfferPublisherType.values)
        type: allResolved
            .where((entry) => entry.offer.publisherType == type)
            .length,
    };

    return CustomScrollView(
      key: const PageStorageKey('buy-offers'),
      slivers: [
        SliverToBoxAdapter(
          child: Semantics(
            key: const ValueKey('buy-offers-publisher-summary'),
            container: true,
            label:
                'Published offers from manufacturers, wholesalers and retailers.',
            child: Container(
              margin: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              decoration: buyV2CardDecoration(
                color: BuyV2Colors.softOrange,
                radius: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_offer_outlined,
                        color: BuyV2Colors.orange,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Offers',
                              style: context.buyTitle.copyWith(fontSize: 17),
                            ),
                            Text(
                              'Published prices from trusted sellers',
                              style: context.buyMeta.copyWith(fontSize: 8),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${products.length} available',
                        style: context.buyMeta.copyWith(
                          color: BuyV2Colors.orange,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final type in BuyV2OfferPublisherType.values) ...[
                        Expanded(
                          child: _OfferPublisherChip(
                            type: type,
                            count: publisherCounts[type] ?? 0,
                            selected: _selectedPublisher == type,
                            onTap: () => setState(() {
                              _selectedPublisher = _selectedPublisher == type
                                  ? null
                                  : type;
                            }),
                          ),
                        ),
                        if (type != BuyV2OfferPublisherType.retailer)
                          const SizedBox(width: 5),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (products.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.search_off_rounded,
                      color: BuyV2Colors.muted,
                      size: 34,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No matching offers',
                      style: context.buyTitle.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try another product, brand or seller.',
                      textAlign: TextAlign.center,
                      style: context.buyMeta,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: BuyV2ProgressiveProductGrid(
              session: session,
              products: products,
              storageKey: 'buy-offers-products',
              semanticLabel: 'Offer products',
            ),
          ),
      ],
    );
  }
}

class _LiveOffersState extends StatelessWidget {
  const _LiveOffersState({required this.snapshot, required this.onRetry});

  final BuyV2PublishedOffersSnapshot? snapshot;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final state = snapshot?.state ?? BuyV2PublishedOffersLoadState.loading;
    final loading = state == BuyV2PublishedOffersLoadState.loading;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox.square(
                dimension: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              const Icon(
                Icons.local_offer_outlined,
                color: BuyV2Colors.navy,
                size: 34,
              ),
            const SizedBox(height: 10),
            Text(
              loading ? 'Opening Offers' : 'Offers could not refresh',
              style: context.buyTitle.copyWith(fontSize: 17),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              snapshot?.customerMessage ??
                  'Checking current prices and eligibility.',
              style: context.buyMeta,
              textAlign: TextAlign.center,
            ),
            if (!loading) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: BuyV2Metrics.minimumTap,
                child: FilledButton.icon(
                  key: const ValueKey('buy-live-offers-retry'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try again'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OffersAvailabilityState extends StatelessWidget {
  const _OffersAvailabilityState({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final loading = session.commerceLoadState == BuyV2CommerceLoadState.loading;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox.square(
                dimension: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            else
              const Icon(
                Icons.local_offer_outlined,
                color: BuyV2Colors.navy,
                size: 34,
              ),
            const SizedBox(height: 10),
            Text(
              loading ? 'Opening Offers' : 'Offers could not refresh',
              textAlign: TextAlign.center,
              style: context.buyTitle.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 5),
            Text(
              session.commerceMessage ??
                  'Try again shortly to see current prices and eligibility.',
              textAlign: TextAlign.center,
              style: context.buyMeta,
            ),
            if (!loading) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: BuyV2Metrics.minimumTap,
                child: FilledButton.icon(
                  key: const ValueKey('buy-offers-retry'),
                  onPressed: session.retryCommerce,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try again'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

bool _matchesPublishedOffer(String query, List<String> values) {
  final queryTokens = query
      .split(RegExp(r'[^a-z0-9]+'))
      .where((token) => token.isNotEmpty);
  final valueTokens = values
      .expand(
        (value) => value
            .toLowerCase()
            .split(RegExp(r'[^a-z0-9]+'))
            .where((token) => token.isNotEmpty),
      )
      .toList(growable: false);
  return queryTokens.every(
    (queryToken) => valueTokens.any((value) => value.startsWith(queryToken)),
  );
}

class _OfferPublisherChip extends StatelessWidget {
  const _OfferPublisherChip({
    required this.type,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final BuyV2OfferPublisherType type;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      BuyV2OfferPublisherType.manufacturer => 'Makers',
      BuyV2OfferPublisherType.wholesaler => 'Wholesale',
      BuyV2OfferPublisherType.retailer => 'Retail',
    };
    return Semantics(
      key: ValueKey('buy-offers-filter-${type.name}'),
      button: true,
      selected: selected,
      label: '$label offers, $count available',
      child: Material(
        color: selected
            ? BuyV2Colors.navy
            : Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: selected ? BuyV2Colors.navy : const Color(0x1F000080),
              ),
            ),
            child: Text(
              '$label · $count',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.buyMeta.copyWith(
                color: selected ? Colors.white : BuyV2Colors.navy,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BuyV2CatalogueView extends StatefulWidget {
  const BuyV2CatalogueView({super.key, required this.session});

  final BuyV2Session session;

  @override
  State<BuyV2CatalogueView> createState() => _BuyV2CatalogueViewState();
}

class _BuyV2CatalogueViewState extends State<BuyV2CatalogueView> {
  bool _savedOnly = false;
  late BuyV2Destination _lastDestination = widget.session.destination;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    if (_lastDestination != session.destination) {
      _lastDestination = session.destination;
      _savedOnly = false;
    }
    return Column(
      children: [
        if (session.canReturnToAccount)
          _CatalogueAccountReturn(session: session),
        _CatalogueToolbar(
          session: session,
          savedOnly: _savedOnly,
          onSaved: () {
            if (!_savedOnly) {
              session.chooseCategory('all');
            }
            setState(() => _savedOnly = !_savedOnly);
          },
        ),
        Expanded(
          child: _CatalogueMotionOwner(
            key: ValueKey(
              'buy-catalogue-motion-${session.destination.name}-'
              '${session.selectedCategoryId}',
            ),
            destination: session.destination,
            child: _ProductGrid(
              session: session,
              savedOnly: _savedOnly,
              onShowAll: () => setState(() => _savedOnly = false),
            ),
          ),
        ),
      ],
    );
  }
}

class BuyV2ShoppingIntentBar extends StatelessWidget {
  const BuyV2ShoppingIntentBar({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final intent = session.activeShoppingIntent;
    if (intent == null) return const SizedBox.shrink();
    final (title, detail, icon) = switch (intent) {
      BuyV2ShoppingIntent.monthlyBasket => (
        'Monthly basket',
        '12 household products · edit before Checkout',
        Icons.shopping_basket_outlined,
      ),
      BuyV2ShoppingIntent.businessBuying => (
        'Buying for business',
        'Wholesale packs for your verified Workspace',
        Icons.storefront_outlined,
      ),
      BuyV2ShoppingIntent.flexibleRestocking => (
        'Flexible restocking',
        'Products with lower minimum pack quantities',
        Icons.inventory_2_outlined,
      ),
      BuyV2ShoppingIntent.homeShopping => (
        'Shopping for home',
        'Retail packs for household use',
        Icons.shopping_bag_outlined,
      ),
    };
    return Material(
      key: const ValueKey('buy-shopping-intent-bar'),
      color: BuyV2Colors.softGreen,
      child: Semantics(
        container: true,
        label: '$title. $detail',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 6, 7),
          child: Row(
            children: [
              Icon(icon, color: BuyV2Colors.green, size: 21),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      key: const ValueKey('buy-shopping-intent-title'),
                      style: context.buyBody.copyWith(
                        color: BuyV2Colors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.buyMeta,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const ValueKey('buy-shopping-intent-clear'),
                tooltip: 'Dismiss $title',
                onPressed: session.clearShoppingIntent,
                icon: const Icon(Icons.close_rounded),
                color: BuyV2Colors.navy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogueMotionOwner extends StatelessWidget {
  const _CatalogueMotionOwner({
    super.key,
    required this.destination,
    required this.child,
  });

  final BuyV2Destination destination;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = BuyV2Motion.resolved(context, BuyV2Motion.contentChange);
    final motion = switch (destination) {
      BuyV2Destination.shop => const (offset: Offset(14, 0), beginScale: 0.985),
      BuyV2Destination.wholesale => const (
        offset: Offset(0, 10),
        beginScale: 0.98,
      ),
      BuyV2Destination.medicine => const (
        offset: Offset(0, 6),
        beginScale: 0.995,
      ),
      BuyV2Destination.orders => const (offset: Offset.zero, beginScale: 1.0),
    };
    return TweenAnimationBuilder<double>(
      key: ValueKey('buy-catalogue-motion-tween-${destination.name}'),
      duration: duration,
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: duration == Duration.zero ? 1 : 0, end: 1),
      builder: (context, value, child) {
        final offset = Offset(
          motion.offset.dx * (1 - value),
          motion.offset.dy * (1 - value),
        );
        final scale = motion.beginScale + ((1 - motion.beginScale) * value);
        return Opacity(
          key: ValueKey('buy-catalogue-motion-opacity-${destination.name}'),
          opacity: value,
          child: Transform.translate(
            key: ValueKey('buy-catalogue-motion-translate-${destination.name}'),
            offset: offset,
            child: Transform.scale(
              key: ValueKey('buy-catalogue-motion-scale-${destination.name}'),
              alignment: Alignment.topCenter,
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: RepaintBoundary(
        key: ValueKey(
          'buy-catalogue-motion-raster-boundary-${destination.name}',
        ),
        child: child,
      ),
    );
  }
}

class _CatalogueAccountReturn extends StatelessWidget {
  const _CatalogueAccountReturn({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('buy-catalogue-return-account'),
      color: BuyV2Colors.softBlue,
      child: InkWell(
        onTap: session.returnToAccount,
        child: const SizedBox(
          height: 44,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  size: 19,
                  color: BuyV2Colors.navy,
                ),
                SizedBox(width: 6),
                Text(
                  'Back to Account',
                  style: TextStyle(
                    color: BuyV2Colors.navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BuyV2SearchResultsView extends StatelessWidget {
  const BuyV2SearchResultsView({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final query = session.query.trim();
    final products = session.visibleProducts;
    return BuyV2FiniteIncomingTransition(
      key: const ValueKey('buy-search-results-surface'),
      stateKey:
          'buy-query-results-${session.destination.name}-'
          '${session.selectedCategoryId}-'
          '${session.selectedFilter ?? 'none'}-'
          '${session.discoveryRefinementSignature}-'
          '${query.toLowerCase()}',
      child: query.isEmpty
          ? _SearchReadyState(
              key: ValueKey('buy-search-ready-${session.destination.name}'),
              session: session,
            )
          : _SearchProductResults(
              key: ValueKey(
                'buy-search-matches-${session.destination.name}-$query',
              ),
              session: session,
              products: products,
              query: query,
            ),
    );
  }
}

class _SearchReadyState extends StatelessWidget {
  const _SearchReadyState({super.key, required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final suggestions = session.searchSuggestions;
    final recentSearches = session.recentSearchesFor(session.destination);
    return ColoredBox(
      color: Colors.white,
      child: ListView(
        key: const ValueKey('buy-search-suggestion-list'),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        children: [
          if (recentSearches.isNotEmpty)
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 19,
                    color: BuyV2Colors.navy,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recent searches',
                      style: context.buyBody.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('buy-recent-searches-clear'),
                    onPressed: () =>
                        session.clearRecentSearches(session.destination),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                    ),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          for (final (index, recent) in recentSearches.indexed) ...[
            Semantics(
              button: true,
              label: 'Search again for $recent',
              child: InkWell(
                key: ValueKey('buy-recent-search-$index'),
                onTap: () {
                  HapticFeedback.selectionClick();
                  session.submitSearch(recent);
                },
                child: SizedBox(
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 30,
                          child: Icon(
                            Icons.history_rounded,
                            size: 19,
                            color: BuyV2Colors.muted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            recent,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: BuyV2Colors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.north_west_rounded,
                          size: 17,
                          color: BuyV2Colors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, indent: 42, color: BuyV2Colors.line),
          ],
          if (recentSearches.isNotEmpty && suggestions.isNotEmpty)
            const SizedBox(height: 4),
          for (final (index, suggestion) in suggestions.indexed) ...[
            Semantics(
              button: true,
              label: 'Search ${session.destination.label} for $suggestion',
              child: InkWell(
                key: ValueKey(
                  'buy-search-suggestion-${session.destination.name}-$index',
                ),
                onTap: () {
                  HapticFeedback.selectionClick();
                  session.submitSearch(suggestion);
                },
                child: SizedBox(
                  height: 44,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 30,
                          child: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: BuyV2Colors.muted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            suggestion,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: BuyV2Colors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (index != suggestions.length - 1)
              const Divider(height: 1, indent: 42, color: BuyV2Colors.line),
          ],
        ],
      ),
    );
  }
}

class _SearchProductResults extends StatelessWidget {
  const _SearchProductResults({
    super.key,
    required this.session,
    required this.products,
    required this.query,
  });

  final BuyV2Session session;
  final List<BuyV2Product> products;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final centeredHeight = constraints.maxHeight > 48
              ? constraints.maxHeight - 48
              : 0.0;
          return SingleChildScrollView(
            key: const ValueKey('buy-search-empty-scroll'),
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: centeredHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    size: 38,
                    color: BuyV2Colors.muted,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'No matches for “$query”',
                    textAlign: TextAlign.center,
                    style: context.buyTitle.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check the spelling or try a product, brand, seller or code.',
                    textAlign: TextAlign.center,
                    style: context.buyMeta,
                  ),
                  if (session.hasNarrowedProductSearchScope) ...[
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          key: ValueKey(
                            'buy-search-all-${session.destination.name}',
                          ),
                          onPressed: session.broadenProductSearchScope,
                          icon: const Icon(
                            Icons.travel_explore_rounded,
                            size: 20,
                          ),
                          label: Text(
                            'Search all ${session.destination.label}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final accessibleText = textScale > 1.25;
        final layout = _resolveCompactProductGridLayout(
          constraints: constraints,
          accessibleText: accessibleText,
        );
        return CustomScrollView(
          key: PageStorageKey('buy-search-${session.destination.name}-$query'),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${products.length} '
                        '${products.length == 1 ? 'match' : 'matches'}',
                        style: context.buyTitle.copyWith(fontSize: 15),
                      ),
                    ),
                    Text(
                      session.destination.label,
                      style: context.buyEyebrow.copyWith(
                        color: BuyV2Colors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _HorizontalProductGrid(
                session: session,
                products: products,
                cardWidth: layout.cardWidth,
                tileHeight: layout.tileHeight,
                storageKey:
                    'buy-search-horizontal-${session.destination.name}-$query',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CatalogueToolbar extends StatelessWidget {
  const _CatalogueToolbar({
    required this.session,
    required this.savedOnly,
    required this.onSaved,
  });

  final BuyV2Session session;
  final bool savedOnly;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    final order = session.orders
        .where(
          (order) =>
              order.destination == session.destination ||
              session.destination == BuyV2Destination.shop,
        )
        .firstOrNull;
    return Container(
      key: const ValueKey('buy-catalogue-toolbar'),
      height: 60,
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
      decoration: const BoxDecoration(
        color: BuyV2Colors.canvas,
        border: Border(bottom: BorderSide(color: BuyV2Colors.line)),
      ),
      child: Row(
        children: [
          _CatalogueCategoryPickerButton(session: session),
          const SizedBox(width: 4),
          Expanded(child: _CatalogueOwnedFeature(session: session)),
          const SizedBox(width: 4),
          _CompactCatalogueAction(
            key: const ValueKey('buy-saved-products-button'),
            icon: savedOnly
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: savedOnly ? 'Show all products' : 'Show Saved products',
            badge: '${session.savedCountFor(session.destination)}',
            active: savedOnly,
            onTap: onSaved,
          ),
          const SizedBox(width: 4),
          _CatalogueToolsMenu(session: session, order: order),
        ],
      ),
    );
  }
}

class _CatalogueCategoryPickerButton extends StatelessWidget {
  const _CatalogueCategoryPickerButton({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final selected = session.categories.firstWhere(
      (category) => category.id == session.selectedCategoryId,
      orElse: () => session.categories.first,
    );
    return Semantics(
      label:
          'Choose ${session.destination.label} category. '
          'Current category ${selected.label}',
      button: true,
      child: IconButton(
        key: const ValueKey('buy-category-picker'),
        tooltip: '${session.destination.label} categories · ${selected.label}',
        onPressed: () {
          HapticFeedback.selectionClick();
          showBuyV2CategoryPicker(context, session);
        },
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(44, 44),
          maximumSize: const Size(44, 44),
          backgroundColor: BuyV2Colors.softOrange,
          foregroundColor: BuyV2Colors.navy,
          side: const BorderSide(color: BuyV2Colors.orange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: const Icon(Icons.menu_rounded, size: 21),
      ),
    );
  }
}

Future<void> showBuyV2CategoryPicker(
  BuildContext context,
  BuyV2Session session,
) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  barrierColor: const Color(0x240A064D),
  constraints: const BoxConstraints(
    maxWidth: BuyV2CategorySheetPolicy.maxWidth,
  ),
  sheetAnimationStyle: BuyV2CategorySheetPolicy.resolve(context),
  builder: (_) => _CatalogueCategorySheet(session: session),
);

class _CatalogueOwnedFeature extends StatelessWidget {
  const _CatalogueOwnedFeature({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final feature = switch (session.destination) {
      BuyV2Destination.shop => (
        'Best prices',
        'lowest',
        Icons.auto_awesome_rounded,
      ),
      BuyV2Destination.wholesale => (
        'Lower minimums',
        'moq',
        Icons.inventory_2_outlined,
      ),
      BuyV2Destination.medicine => (
        'No-prescription care',
        'otc',
        Icons.health_and_safety_outlined,
      ),
      BuyV2Destination.orders => (
        'MoolSocial',
        'any',
        Icons.auto_awesome_rounded,
      ),
    };
    final active = session.selectedFilter == feature.$2;
    return Semantics(
      label: '${feature.$1} filter',
      selected: active,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('buy-owned-feature'),
          onTap: () {
            HapticFeedback.selectionClick();
            session.chooseFilter(active ? null : feature.$2);
          },
          borderRadius: BorderRadius.circular(13),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: active
                    ? const [BuyV2Colors.softGreen, Color(0xFFE8F7EC)]
                    : const [Color(0xFFFFF2E4), Color(0xFFF2F4FF)],
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: active ? BuyV2Colors.green : BuyV2Colors.line,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  feature.$3,
                  size: 18,
                  color: active ? BuyV2Colors.green : BuyV2Colors.navy,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        feature.$1,
                        maxLines: 1,
                        style: const TextStyle(
                          color: BuyV2Colors.ink,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogueCategorySheet extends StatefulWidget {
  const _CatalogueCategorySheet({required this.session});

  final BuyV2Session session;

  @override
  State<_CatalogueCategorySheet> createState() =>
      _CatalogueCategorySheetState();
}

class _CatalogueCategorySheetState extends State<_CatalogueCategorySheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _searchFocus = FocusNode(debugLabel: 'buy-category-search');
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(_handleSearchFocusChanged);
  }

  void _handleSearchFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _setQueryFromSemantics(String value) {
    _searchFocus.requestFocus();
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() => _query = value);
  }

  void _clearQuery() {
    _controller.clear();
    setState(() => _query = '');
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_handleSearchFocusChanged);
    _searchFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final query = _query.trim().toLowerCase();
    final categories = session.categories
        .where(
          (category) =>
              query.isEmpty || category.label.toLowerCase().contains(query),
        )
        .toList(growable: false);
    return Semantics(
      key: const ValueKey('buy-category-sheet-route'),
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: '${session.destination.label} categories',
      child: KeyedSubtree(
        key: const ValueKey('buy-category-sheet-layout-owner'),
        child: FractionallySizedBox(
          heightFactor: BuyV2CategorySheetPolicy.heightFactorFor(context),
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: MoolMetrics.compactTapTarget,
            ),
            child: ClipRRect(
              key: const ValueKey('buy-category-sheet-surface'),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: RepaintBoundary(
                key: const ValueKey('buy-category-sheet-repaint-boundary'),
                child: _CatalogueCategoryBackdrop(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Color(0xFAFFFFFF),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      border: Border(
                        top: BorderSide(color: BuyV2Colors.line, width: 1.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 36,
                          height: 3,
                          decoration: BoxDecoration(
                            color: BuyV2Colors.line,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: BuyV2Colors.softOrange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.category_outlined,
                                  color: BuyV2Colors.navy,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${session.destination.label} categories',
                                      key: const ValueKey(
                                        'buy-category-sheet-title',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: BuyV2Colors.navy,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const Text(
                                      'Choose one to update products',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: BuyV2Colors.muted,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                key: const ValueKey('buy-category-close'),
                                tooltip: 'Close categories',
                                onPressed: () => Navigator.of(context).pop(),
                                style: IconButton.styleFrom(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  minimumSize: const Size(44, 44),
                                  maximumSize: const Size(44, 44),
                                  backgroundColor: Colors.white,
                                  foregroundColor: BuyV2Colors.navy,
                                  side: const BorderSide(
                                    color: BuyV2Colors.line,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.close_rounded, size: 20),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                          child: SizedBox(
                            height: 44,
                            child: Semantics(
                              key: const ValueKey(
                                'buy-category-search-semantics',
                              ),
                              container: true,
                              excludeSemantics: true,
                              textField: true,
                              focusable: true,
                              focused: _searchFocus.hasFocus,
                              label: 'Category search',
                              value: _query,
                              hint: 'Find a category',
                              onTap: _searchFocus.requestFocus,
                              onFocus: _searchFocus.requestFocus,
                              onSetText: _setQueryFromSemantics,
                              child: TextField(
                                key: const ValueKey('buy-category-search'),
                                controller: _controller,
                                focusNode: _searchFocus,
                                onChanged: (value) =>
                                    setState(() => _query = value),
                                textInputAction: TextInputAction.search,
                                style: const TextStyle(
                                  color: BuyV2Colors.ink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: InputDecoration(
                                  label: const ExcludeSemantics(
                                    child: Text('Category search'),
                                  ),
                                  hint: const ExcludeSemantics(
                                    child: Text('Find a category'),
                                  ),
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.always,
                                  labelStyle: const TextStyle(
                                    color: BuyV2Colors.navy,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  hintStyle: const TextStyle(
                                    color: BuyV2Colors.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 44,
                                  ),
                                  suffixIcon: _query.isEmpty
                                      ? null
                                      : IconButton(
                                          key: const ValueKey(
                                            'buy-category-search-clear',
                                          ),
                                          tooltip: 'Clear category search',
                                          onPressed: _clearQuery,
                                          icon: const Icon(
                                            Icons.clear_rounded,
                                            size: 18,
                                          ),
                                        ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: BuyV2Colors.line,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: BuyV2Colors.line,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: BuyV2Colors.orange,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: categories.isEmpty
                              ? _CatalogueCategoryEmptyState(
                                  onClear: _clearQuery,
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final columns = constraints.maxWidth < 350
                                        ? 2
                                        : 3;
                                    return GridView.builder(
                                      key: const ValueKey('buy-category-grid'),
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        0,
                                        12,
                                        10,
                                      ),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: columns,
                                            mainAxisExtent: 84,
                                            mainAxisSpacing: 8,
                                            crossAxisSpacing: 8,
                                          ),
                                      itemCount: categories.length,
                                      itemBuilder: (context, index) {
                                        final category = categories[index];
                                        final selected =
                                            category.id ==
                                            session.selectedCategoryId;
                                        return Semantics(
                                          key: ValueKey(
                                            'buy-category-semantics-${category.id}',
                                          ),
                                          label:
                                              '${session.destination.label} category, '
                                              '${category.label}'
                                              '${selected ? ', selected' : ''}',
                                          selected: selected,
                                          button: true,
                                          child: Material(
                                            color: selected
                                                ? const Color(0xFFFDF0E1)
                                                : const Color(0xEFFFFFFF),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              side: BorderSide(
                                                color: selected
                                                    ? BuyV2Colors.orange
                                                    : BuyV2Colors.line,
                                              ),
                                            ),
                                            child: InkWell(
                                              key: ValueKey(
                                                'buy-category-${category.id}',
                                              ),
                                              onTap: () async {
                                                HapticFeedback.selectionClick();
                                                final routeCompleted =
                                                    ModalRoute.of(
                                                      context,
                                                    )?.completed;
                                                Navigator.of(context).pop();
                                                if (routeCompleted != null) {
                                                  await routeCompleted;
                                                }
                                                if (session
                                                        .selectedCategoryId !=
                                                    category.id) {
                                                  session.chooseCategory(
                                                    category.id,
                                                  );
                                                }
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 7,
                                                    ),
                                                child: Stack(
                                                  children: [
                                                    Align(
                                                      alignment:
                                                          Alignment.center,
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            width: 28,
                                                            height: 28,
                                                            alignment: Alignment
                                                                .center,
                                                            decoration: BoxDecoration(
                                                              color: selected
                                                                  ? Colors.white
                                                                  : BuyV2Colors
                                                                        .softBlue,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    10,
                                                                  ),
                                                            ),
                                                            child: Icon(
                                                              buyV2CategoryIconFor(
                                                                category.id,
                                                              ),
                                                              key: ValueKey(
                                                                'buy-category-icon-'
                                                                '${category.id}',
                                                              ),
                                                              color: selected
                                                                  ? BuyV2Colors
                                                                        .green
                                                                  : BuyV2Colors
                                                                        .navy,
                                                              size: 16,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          SizedBox(
                                                            width:
                                                                double.infinity,
                                                            child: Text(
                                                              category.label,
                                                              key: ValueKey(
                                                                'buy-category-label-'
                                                                '${category.id}',
                                                              ),
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                color:
                                                                    BuyV2Colors
                                                                        .ink,
                                                                fontSize: 10,
                                                                height: 1.05,
                                                                fontWeight:
                                                                    selected
                                                                    ? FontWeight
                                                                          .w900
                                                                    : FontWeight
                                                                          .w700,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (selected)
                                                      const Positioned(
                                                        right: 0,
                                                        top: 0,
                                                        child: Icon(
                                                          Icons
                                                              .check_circle_rounded,
                                                          color:
                                                              BuyV2Colors.green,
                                                          size: 15,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogueCategoryBackdrop extends StatelessWidget {
  const _CatalogueCategoryBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('buy-category-sheet-backdrop-owner'),
      child: KeyedSubtree(
        key: const ValueKey('buy-category-sheet-opaque-content'),
        child: child,
      ),
    );
  }
}

class _CatalogueCategoryEmptyState extends StatelessWidget {
  const _CatalogueCategoryEmptyState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Semantics(
      key: const ValueKey('buy-category-empty'),
      container: true,
      explicitChildNodes: true,
      label: 'No categories match. Clear category search.',
      child: keyboardVisible
          ? _CatalogueCategoryKeyboardEmptyState(onClear: onClear)
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: BuyV2Colors.softOrange,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.search_off_rounded,
                        color: BuyV2Colors.navy,
                        size: 23,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No categories match',
                      style: TextStyle(
                        color: BuyV2Colors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Try a different category name.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: BuyV2Colors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _CatalogueCategoryClearButton(onClear: onClear),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CatalogueCategoryKeyboardEmptyState extends StatelessWidget {
  const _CatalogueCategoryKeyboardEmptyState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No categories match',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: BuyV2Colors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Try a different category name.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: BuyV2Colors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _CatalogueCategoryClearButton(onClear: onClear, compact: true),
          ],
        ),
      ),
    );
  }
}

class _CatalogueCategoryClearButton extends StatelessWidget {
  const _CatalogueCategoryClearButton({
    required this.onClear,
    this.compact = false,
  });

  final VoidCallback onClear;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const ValueKey('buy-category-empty-clear'),
      onPressed: onClear,
      style: compact
          ? OutlinedButton.styleFrom(
              minimumSize: const Size(116, 44),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            )
          : null,
      icon: const Icon(Icons.refresh_rounded, size: 17),
      label: const Text('Clear search'),
    );
  }
}

@visibleForTesting
IconData buyV2CategoryIconFor(String id) => switch (id) {
  'all' => Icons.auto_awesome_rounded,
  'fruits-vegetables' => Icons.eco_outlined,
  'dairy-bakery' => Icons.bakery_dining_outlined,
  'eggs-poultry' => Icons.egg_alt_outlined,
  'meat-seafood' => Icons.set_meal_outlined,
  'flour-rice-grains' => Icons.grain_rounded,
  'dals-staples' => Icons.rice_bowl_outlined,
  'oils-ghee' => Icons.opacity_rounded,
  'ground-spices' => Icons.blender_outlined,
  'whole-spices' => Icons.filter_vintage_outlined,
  'breakfast-cereals' => Icons.breakfast_dining_outlined,
  'instant-foods' => Icons.ramen_dining_outlined,
  'sauces-spreads' => Icons.local_dining_outlined,
  'biscuits-chocolate' => Icons.cookie_outlined,
  'namkeen-chips' => Icons.fastfood_outlined,
  'tea-coffee' => Icons.coffee_outlined,
  'juices-water' => Icons.local_drink_outlined,
  'frozen-foods' => Icons.ac_unit_rounded,
  'icecream-cheese' => Icons.icecream_outlined,
  'bath-hand-care' => Icons.soap_outlined,
  'oral-care' => Icons.health_and_safety_outlined,
  'hair-care' => Icons.content_cut_rounded,
  'skin-care' => Icons.face_retouching_natural_outlined,
  'surface-cleaners' => Icons.cleaning_services_outlined,
  'air-waste-care' => Icons.delete_sweep_outlined,
  'laundry-dishwash' => Icons.local_laundry_service_outlined,
  'diapers-wipes' => Icons.baby_changing_station_outlined,
  'baby-care' => Icons.child_friendly_outlined,
  'health-wellness' => Icons.health_and_safety_outlined,
  'dog-care' || 'cat-care' => Icons.pets_outlined,
  'food-storage-packs' => Icons.inventory_2_outlined,
  'cups-tissues' => Icons.takeout_dining_outlined,
  'school-office' || 'stationery-office' => Icons.edit_note_outlined,
  'shop-supplies' || 'retail-supplies' => Icons.storefront_outlined,
  'horeca-food-packs' => Icons.restaurant_menu_outlined,
  'horeca-tableware' => Icons.room_service_outlined,
  'rx' => Icons.description_outlined,
  'pain-fever' => Icons.thermostat_outlined,
  'diabetes' => Icons.bloodtype_outlined,
  'heart-bp' => Icons.favorite_border_rounded,
  'digestive' => Icons.restaurant_outlined,
  'respiratory' => Icons.air_rounded,
  'allergy' => Icons.masks_outlined,
  'vitamins' => Icons.medication_outlined,
  'first-aid' => Icons.medical_services_outlined,
  'devices' => Icons.monitor_heart_outlined,
  'women-care' => Icons.female_rounded,
  _ => Icons.category_outlined,
};

class _CompactCatalogueAction extends StatelessWidget {
  const _CompactCatalogueAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final bool active;

  @override
  Widget build(BuildContext context) {
    void activate() {
      HapticFeedback.selectionClick();
      onTap();
    }

    return Semantics(
      label: badge == null ? label : '$label, $badge saved',
      button: true,
      excludeSemantics: true,
      onTap: activate,
      child: IconButton(
        onPressed: activate,
        tooltip: label,
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          maximumSize: const Size(44, 44),
          backgroundColor: active ? BuyV2Colors.softOrange : Colors.white,
          foregroundColor: BuyV2Colors.navy,
          side: const BorderSide(color: BuyV2Colors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: Badge(
          isLabelVisible: badge != null,
          label: badge == null
              ? null
              : Text(badge!, style: const TextStyle(fontSize: 8)),
          backgroundColor: BuyV2Colors.orange,
          textColor: BuyV2Colors.navy,
          child: BuyV2FiniteVisualTransition(
            key: const ValueKey('buy-saved-filter-icon-motion'),
            stateKey: icon,
            ownerSize: const Size.square(19),
            child: Icon(icon, size: 19),
          ),
        ),
      ),
    );
  }
}

class _CatalogueToolsMenu extends StatelessWidget {
  const _CatalogueToolsMenu({required this.session, required this.order});

  final BuyV2Session session;
  final BuyV2Order? order;

  @override
  Widget build(BuildContext context) {
    final filterOptions = _filterOptionsFor(session.destination);
    final refinementCount = session.activeDiscoveryRefinementCount;
    void openSheet() {
      HapticFeedback.selectionClick();
      showBuyV2FilterSheet(
        context,
        session,
        actions: [
          if (order case final activeOrder?)
            BuyV2FilterSheetAction(
              keyName: 'buy-active-orders-button',
              icon: Icons.local_shipping_outlined,
              title: 'Track active order',
              detail: 'Order ${activeOrder.id}',
              onTap: () => session.openTracking(activeOrder.id),
            ),
          if (session.destination == BuyV2Destination.shop)
            BuyV2FilterSheetAction(
              keyName: 'buy-household-basket-button',
              icon: Icons.shopping_basket_outlined,
              title: 'Monthly home basket',
              detail: 'Review a ready household list',
              onTap: () {
                showBuyV2HouseholdBasket(context, session);
              },
            ),
          if (session.destination == BuyV2Destination.shop ||
              session.destination == BuyV2Destination.wholesale)
            BuyV2FilterSheetAction(
              keyName: 'buy-recently-viewed-button',
              icon: Icons.history_rounded,
              title: 'Recently viewed',
              detail:
                  session.recentlyViewedProductsFor(session.destination).isEmpty
                  ? 'Products you open will appear here'
                  : '${session.recentlyViewedProductsFor(session.destination).length} products ready to revisit',
              onTap: () => showBuyV2RecentlyViewed(context, session),
            ),
          if (session.destination == BuyV2Destination.shop ||
              session.destination == BuyV2Destination.wholesale)
            BuyV2FilterSheetAction(
              keyName: 'buy-shopping-settings-button',
              icon: Icons.tune_rounded,
              title: 'Shopping settings',
              detail: 'Delivery, payments, alerts and saved activity',
              onTap: () => showBuyV2ShoppingSettings(context, session),
            ),
          if (session.destination == BuyV2Destination.medicine)
            BuyV2FilterSheetAction(
              keyName: 'buy-prescription-button',
              icon: Icons.description_outlined,
              title: 'Prescriptions',
              detail: 'Review saved prescription access',
              onTap: () {
                showBuyV2PrescriptionSheet(context, session);
              },
            ),
        ],
      );
    }

    return Semantics(
      label:
          'Open ${session.destination.label} tools and filters. '
          'Current ${_filterLabel(filterOptions, session.selectedFilter)}. '
          '$refinementCount additional ${refinementCount == 1 ? 'filter' : 'filters'} selected',
      button: true,
      excludeSemantics: true,
      onTap: openSheet,
      child: IconButton(
        key: const ValueKey('buy-filter-button'),
        onPressed: openSheet,
        tooltip: 'Orders, tools and filters',
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          maximumSize: const Size(44, 44),
          backgroundColor:
              session.selectedFilter == null && refinementCount == 0
              ? Colors.white
              : BuyV2Colors.softOrange,
          foregroundColor: BuyV2Colors.navy,
          side: const BorderSide(color: BuyV2Colors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: Badge(
          isLabelVisible: session.selectedFilter != null || refinementCount > 0,
          backgroundColor: BuyV2Colors.orange,
          child: const Icon(
            Icons.more_horiz_rounded,
            color: BuyV2Colors.navy,
            size: 20,
          ),
        ),
      ),
    );
  }
}

String _filterLabel(List<(String, String)> options, String? selectedFilter) =>
    options
        .firstWhere(
          (option) =>
              (option.$1 == 'any' && selectedFilter == null) ||
              option.$1 == selectedFilter,
          orElse: () => options.first,
        )
        .$2;

List<(String, String)> _filterOptionsFor(BuyV2Destination destination) =>
    switch (destination) {
      BuyV2Destination.shop => const [
        ('any', 'Any delivery time'),
        ('fast', 'Fast delivery'),
        ('today', 'Delivered today'),
        ('quick-local', 'Quick local delivery'),
        ('standard-courier', 'Standard/courier delivery'),
        ('lowest', 'Lowest delivered price'),
        ('nearby', 'Nearby sellers'),
        ('returns', 'Easy returns'),
      ],
      BuyV2Destination.wholesale => const [
        ('any', 'Any delivery schedule'),
        ('fast', 'Fastest delivery'),
        ('two-days', 'Within two days'),
        ('bulk-freight', 'Bulk freight'),
        ('lowest', 'Lowest landed price'),
        ('freight', 'Freight included'),
        ('moq', 'Flexible MOQ'),
        ('manufacturer', 'Manufacturer direct'),
      ],
      BuyV2Destination.medicine => const [
        ('any', 'Any delivery time'),
        ('fast', 'Fastest pharmacy delivery'),
        ('today', 'Delivered today'),
        ('lowest', 'Lowest delivered price'),
        ('otc', 'No prescription required'),
        ('nearby', 'Nearby pharmacy'),
        ('manufacturer', 'Manufacturer sealed packs'),
      ],
      BuyV2Destination.orders => const [],
    };

Future<void> showBuyV2ShoppingSettings(
  BuildContext context,
  BuyV2Session session,
) async {
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    sheetAnimationStyle: BuyV2InfoSheetMotion.resolve(context),
    builder: (sheetContext) => _BuyV2ShoppingSettingsSheet(
      session: session,
      onOpenSavedProducts: () {
        Navigator.of(sheetContext).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            unawaited(showBuyV2SavedProducts(context, session));
          }
        });
      },
      onOpenRecentlyViewed: () {
        Navigator.of(sheetContext).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            unawaited(showBuyV2RecentlyViewed(context, session));
          }
        });
      },
    ),
  );
}

class _BuyV2ShoppingSettingsSheet extends StatelessWidget {
  const _BuyV2ShoppingSettingsSheet({
    required this.session,
    required this.onOpenSavedProducts,
    required this.onOpenRecentlyViewed,
  });

  final BuyV2Session session;
  final VoidCallback onOpenSavedProducts;
  final VoidCallback onOpenRecentlyViewed;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final recentCount =
            session.recentlyViewedProductsFor(BuyV2Destination.shop).length +
            session
                .recentlyViewedProductsFor(BuyV2Destination.wholesale)
                .length;
        final savedCount =
            session.savedCountFor(BuyV2Destination.shop) +
            session.savedCountFor(BuyV2Destination.wholesale);
        final preferredDelivery = session.selectedFulfilmentMode == null
            ? 'No preference'
            : buyV2FulfilmentModeLabel(session.selectedFulfilmentMode!);
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            key: const ValueKey('buy-shopping-settings'),
            padding: EdgeInsets.fromLTRB(
              14,
              0,
              14,
              18 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Shopping settings',
                  style: context.buyTitle.copyWith(fontSize: 19),
                ),
                const SizedBox(height: 3),
                Text(
                  'Keep delivery, payment and shopping preferences easy to review.',
                  style: context.buyMeta,
                ),
                const SizedBox(height: 12),
                const _ShoppingSettingsHeading('Checkout preferences'),
                _ShoppingSettingsRow(
                  key: const ValueKey('buy-settings-addresses'),
                  icon: Icons.location_on_outlined,
                  title: 'Delivery addresses',
                  detail:
                      session.selectedAddressOrNull?.shortLine ??
                      'Choose or add an address',
                  onTap: () => showBuyV2AddressSheet(context, session),
                ),
                _ShoppingSettingsRow(
                  key: const ValueKey('buy-settings-payment'),
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Payment preference',
                  detail: session.selectedPayment.isEmpty
                      ? 'Choose at Checkout'
                      : session.selectedPayment,
                  onTap: () => showBuyV2PaymentSheet(context, session),
                ),
                _ShoppingSettingsRow(
                  key: const ValueKey('buy-settings-delivery'),
                  icon: Icons.local_shipping_outlined,
                  title: 'Preferred delivery',
                  detail: preferredDelivery,
                  onTap: () => _showBuyV2DeliveryPreference(context, session),
                ),
                const SizedBox(height: 12),
                const _ShoppingSettingsHeading('Orders and activity'),
                _ShoppingSettingsRow(
                  key: const ValueKey('buy-settings-order-alerts'),
                  icon: Icons.notifications_active_outlined,
                  title: 'Order notifications',
                  detail: session.trackingAlertsBusy
                      ? 'Updating preference…'
                      : !session.trackingAlertsAvailable
                      ? 'Unavailable right now'
                      : session.trackingAlertsEnabled
                      ? 'Order and delivery alerts are on'
                      : 'Order and delivery alerts are paused',
                  trailing: Switch.adaptive(
                    value:
                        session.trackingAlertsAvailable &&
                        session.trackingAlertsEnabled,
                    onChanged:
                        session.trackingAlertsBusy ||
                            !session.trackingAlertsAvailable
                        ? null
                        : (value) =>
                              unawaited(session.setTrackingAlerts(value)),
                  ),
                  onTap:
                      session.trackingAlertsBusy ||
                          !session.trackingAlertsAvailable
                      ? null
                      : () => unawaited(
                          session.setTrackingAlerts(
                            !session.trackingAlertsEnabled,
                          ),
                        ),
                ),
                _ShoppingSettingsRow(
                  key: const ValueKey('buy-settings-shopping-alerts'),
                  icon: Icons.notifications_none_rounded,
                  title: 'Shopping alerts',
                  detail: switch (session.shoppingAlertsState) {
                    BuyV2ShoppingAlertsState.loading => 'Loading alerts…',
                    BuyV2ShoppingAlertsState.ready =>
                      '${session.shoppingAlerts.length} current alerts',
                    BuyV2ShoppingAlertsState.offline =>
                      'Reconnect to review alerts',
                    BuyV2ShoppingAlertsState.unavailable =>
                      'Alerts are unavailable right now',
                  },
                  onTap: () => showBuyV2ShoppingAlerts(context, session),
                ),
                _ShoppingSettingsRow(
                  key: const ValueKey('buy-settings-saved'),
                  icon: Icons.bookmark_border_rounded,
                  title: 'Saved products',
                  detail: '$savedCount saved',
                  onTap: onOpenSavedProducts,
                ),
                _ShoppingSettingsRow(
                  key: const ValueKey('buy-settings-recently-viewed'),
                  icon: Icons.history_rounded,
                  title: 'Recently viewed',
                  detail: recentCount == 0
                      ? 'No recently viewed products'
                      : '$recentCount recently viewed',
                  onTap: recentCount == 0 ? null : onOpenRecentlyViewed,
                ),
                _ShoppingSettingsRow(
                  key: const ValueKey('buy-settings-messages'),
                  icon: Icons.forum_outlined,
                  title: 'Messages and blocked sellers',
                  detail: 'Manage Shop conversations and seller access',
                  onTap: () => _openBuyV2SettingsRoute(
                    context,
                    Uri(
                      path: '/app/chat/inbox',
                      queryParameters: {
                        'type': 'business',
                        'return': '/app/buy',
                      },
                    ).toString(),
                  ),
                ),
                const SizedBox(height: 12),
                const _ShoppingSettingsHeading('Privacy and help'),
                _ShoppingSettingsRow(
                  key: const ValueKey('buy-settings-privacy'),
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy preferences',
                  detail: 'Control activity and communication preferences',
                  onTap: () => _openBuyV2SettingsRoute(
                    context,
                    '/app/account/workspaces/preferences',
                  ),
                ),
                _ShoppingSettingsRow(
                  key: const ValueKey('buy-settings-security'),
                  icon: Icons.security_outlined,
                  title: 'Security and account controls',
                  detail: 'Review sign-in, sessions and account access',
                  onTap: () =>
                      _openBuyV2SettingsRoute(context, '/app/account/security'),
                ),
                _ShoppingSettingsRow(
                  key: const ValueKey('buy-settings-help'),
                  icon: Icons.help_outline_rounded,
                  title: 'Help and support',
                  detail: 'Get help with shopping and orders',
                  onTap: () => _openBuyV2SettingsRoute(context, '/app/ask'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShoppingSettingsHeading extends StatelessWidget {
  const _ShoppingSettingsHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 5),
    child: Text(label, style: context.buyEyebrow),
  );
}

class _ShoppingSettingsRow extends StatelessWidget {
  const _ShoppingSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    enabled: onTap != null,
    label: '$title. $detail',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
        decoration: buyV2CardDecoration(radius: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BuyV2Colors.softBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: BuyV2Colors.navy),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.buyBody.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.buyMeta,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            trailing ??
                Icon(
                  onTap == null
                      ? Icons.remove_rounded
                      : Icons.chevron_right_rounded,
                  color: BuyV2Colors.muted,
                ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showBuyV2DeliveryPreference(
  BuildContext context,
  BuyV2Session session,
) async {
  final currentKey = switch (session.selectedFulfilmentMode) {
    BuyV2FulfilmentMode.quickLocal => 'quick-local',
    BuyV2FulfilmentMode.standardCourier => 'standard-courier',
    BuyV2FulfilmentMode.bulkFreight => 'bulk-freight',
    null => 'any',
  };
  final selected = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        children: [
          Text(
            'Preferred delivery',
            style: sheetContext.buyTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 5),
          for (final option in <(String, BuyV2FulfilmentMode?, String)>[
            ('any', null, 'No preference'),
            (
              'quick-local',
              BuyV2FulfilmentMode.quickLocal,
              'Quick local delivery',
            ),
            (
              'standard-courier',
              BuyV2FulfilmentMode.standardCourier,
              'Standard/courier delivery',
            ),
            ('bulk-freight', BuyV2FulfilmentMode.bulkFreight, 'Bulk freight'),
          ])
            ListTile(
              key: ValueKey('buy-settings-delivery-${option.$1}'),
              minTileHeight: 48,
              leading: Icon(
                currentKey == option.$1
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: BuyV2Colors.navy,
              ),
              onTap: () => Navigator.of(sheetContext).pop(option.$1),
              title: Text(option.$3),
            ),
        ],
      ),
    ),
  );
  if (selected == null) return;
  session.chooseFulfilmentMode(switch (selected) {
    'quick-local' => BuyV2FulfilmentMode.quickLocal,
    'standard-courier' => BuyV2FulfilmentMode.standardCourier,
    'bulk-freight' => BuyV2FulfilmentMode.bulkFreight,
    _ => null,
  });
}

Future<void> _confirmClearBuyV2RecentlyViewed(
  BuildContext context,
  BuyV2Session session,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Clear recently viewed?'),
      content: const Text(
        'Products you viewed in Shop and Wholesale will be removed from this device.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep'),
        ),
        FilledButton(
          key: const ValueKey('buy-settings-recently-viewed-confirm'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Clear'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  session.clearRecentlyViewed(BuyV2Destination.shop);
  session.clearRecentlyViewed(BuyV2Destination.wholesale);
}

void _openBuyV2SettingsRoute(BuildContext context, String route) {
  final router = GoRouter.maybeOf(context);
  if (router == null) return;
  Navigator.of(context).pop();
  Future<void>.microtask(() => router.push(route));
}

Future<void> showBuyV2ShoppingAlerts(
  BuildContext context,
  BuyV2Session session,
) async {
  final router = GoRouter.maybeOf(context);
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => AnimatedBuilder(
      animation: session,
      builder: (sheetContext, _) {
        void openAlert(BuyV2ShoppingAlert alert) {
          if (router == null) return;
          final location = buyV2ShoppingAlertLocation(alert);
          Navigator.of(sheetContext).pop();
          Navigator.of(context).pop();
          Future<void>.microtask(() => router.push(location));
        }

        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            key: const ValueKey('buy-shopping-alerts'),
            padding: EdgeInsets.fromLTRB(
              14,
              0,
              14,
              18 + MediaQuery.viewPaddingOf(sheetContext).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Shopping alerts',
                  style: sheetContext.buyTitle.copyWith(fontSize: 19),
                ),
                const SizedBox(height: 3),
                Text(
                  'Order, payment, delivery and product updates appear here.',
                  style: sheetContext.buyMeta,
                ),
                const SizedBox(height: 12),
                if (session.shoppingAlertsBusy ||
                    session.shoppingAlertsState ==
                        BuyV2ShoppingAlertsState.loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  )
                else if (session.shoppingAlertsState !=
                    BuyV2ShoppingAlertsState.ready) ...[
                  Container(
                    key: const ValueKey('buy-shopping-alerts-unavailable'),
                    padding: const EdgeInsets.all(12),
                    decoration: buyV2CardDecoration(
                      color: BuyV2Colors.softOrange,
                      radius: 15,
                    ),
                    child: Text(
                      session.shoppingAlertsMessage ??
                          'Shopping alerts are unavailable right now.',
                      style: sheetContext.buyBody,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const ValueKey('buy-shopping-alerts-retry'),
                    onPressed: session.shoppingAlertsBusy
                        ? null
                        : session.restoreShoppingAlerts,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ] else if (session.shoppingAlerts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: buyV2CardDecoration(radius: 15),
                    child: const Text(
                      'You have no current shopping alerts.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (final alert in session.shoppingAlerts) ...[
                    Semantics(
                      button: router != null,
                      label:
                          '${alert.title}. ${alert.detail}. ${alert.updatedLabel}',
                      child: InkWell(
                        key: ValueKey('buy-shopping-alert-${alert.id}'),
                        onTap: router == null ? null : () => openAlert(alert),
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 72),
                          padding: const EdgeInsets.all(10),
                          decoration: buyV2CardDecoration(radius: 15),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: BuyV2Colors.softBlue,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  _buyV2ShoppingAlertIcon(alert.kind),
                                  color: BuyV2Colors.navy,
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      alert.title,
                                      style: sheetContext.buyBody.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      alert.detail,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: sheetContext.buyMeta,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      alert.updatedLabel,
                                      style: sheetContext.buyMeta.copyWith(
                                        color: BuyV2Colors.green,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (router != null)
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: BuyV2Colors.muted,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

IconData _buyV2ShoppingAlertIcon(BuyV2ShoppingAlertKind kind) => switch (kind) {
  BuyV2ShoppingAlertKind.order => Icons.receipt_long_outlined,
  BuyV2ShoppingAlertKind.payment => Icons.account_balance_wallet_outlined,
  BuyV2ShoppingAlertKind.delivery => Icons.local_shipping_outlined,
  BuyV2ShoppingAlertKind.offer => Icons.local_offer_outlined,
  BuyV2ShoppingAlertKind.priceDrop => Icons.trending_down_rounded,
  BuyV2ShoppingAlertKind.restock => Icons.inventory_2_outlined,
  BuyV2ShoppingAlertKind.cancellation => Icons.cancel_outlined,
  BuyV2ShoppingAlertKind.returnUpdate => Icons.assignment_return_outlined,
  BuyV2ShoppingAlertKind.refund => Icons.currency_rupee_rounded,
};

Future<void> showBuyV2HouseholdBasket(
  BuildContext context,
  BuyV2Session session,
) async {
  session.chooseShoppingIntent(BuyV2ShoppingIntent.monthlyBasket);
  final action = await showModalBottomSheet<_HouseholdBasketAction>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    sheetAnimationStyle: BuyV2InfoSheetMotion.resolve(context),
    builder: (sheetContext) => _HouseholdBasket(
      onClose: () => Navigator.of(sheetContext).pop(),
      onSeeProducts: () =>
          Navigator.of(sheetContext).pop(_HouseholdBasketAction.seeProducts),
      onAddToCart: () =>
          Navigator.of(sheetContext).pop(_HouseholdBasketAction.addToCart),
    ),
  );
  switch (action) {
    case _HouseholdBasketAction.seeProducts:
      session.chooseCategory('all');
      session.showNotice('Basket products are shown below');
      break;
    case _HouseholdBasketAction.addToCart:
      final featured = BuyV2Catalogue.products
          .where((product) => product.destination == BuyV2Destination.shop)
          .take(4);
      for (final product in featured) {
        session.addProduct(product.id);
      }
      break;
    case null:
      break;
  }
}

Future<void> showBuyV2SavedProducts(
  BuildContext context,
  BuyV2Session session,
) async {
  final destination = session.destination;
  final selectedProductId = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    sheetAnimationStyle: BuyV2InfoSheetMotion.resolve(context),
    builder: (sheetContext) => _SavedProductsSheet(
      session: session,
      destination: destination,
      onClose: () => Navigator.of(sheetContext).pop(),
      onOpenProduct: (productId) => Navigator.of(sheetContext).pop(productId),
    ),
  );
  if (selectedProductId != null) {
    session.openProduct(selectedProductId);
  }
}

Future<void> showBuyV2RecentlyViewed(
  BuildContext context,
  BuyV2Session session,
) async {
  final destination = session.destination;
  final selectedProductId = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    sheetAnimationStyle: BuyV2InfoSheetMotion.resolve(context),
    builder: (sheetContext) => _RecentlyViewedProductsSheet(
      session: session,
      destination: destination,
      onClose: () => Navigator.of(sheetContext).pop(),
      onOpenProduct: (productId) => Navigator.of(sheetContext).pop(productId),
      onClear: () => _confirmClearBuyV2RecentlyViewed(sheetContext, session),
    ),
  );
  if (selectedProductId != null) {
    session.openProduct(selectedProductId);
  }
}

Future<void> showBuyV2PartnerCatalogue(
  BuildContext context,
  BuyV2Session session,
  BuyV2Product current, {
  bool brandOnly = false,
}) async {
  final supportedDestination =
      current.destination == BuyV2Destination.shop ||
      current.destination == BuyV2Destination.wholesale ||
      current.destination == BuyV2Destination.medicine;
  final sellerProducts = current.destination == BuyV2Destination.medicine
      ? [current, ...session.sellerContinuationsFor(current)]
      : session.partnerCatalogueFor(current);
  final brandProducts = current.destination == BuyV2Destination.medicine
      ? const <BuyV2Product>[]
      : session.brandCatalogueFor(current);
  final products = brandOnly ? brandProducts : sellerProducts;
  final previewProducts = products.take(6).toList(growable: false);
  final otherStores = brandOnly
      ? const <BuyV2Product>[]
      : BuyV2Catalogue.products
            .where(
              (product) =>
                  product.destination == current.destination &&
                  product.seller != current.seller &&
                  product.catalogueListing,
            )
            .fold(<BuyV2Product>[], (stores, product) {
              if (stores.every((store) => store.seller != product.seller)) {
                stores.add(product);
              }
              return stores;
            })
            .take(4)
            .toList(growable: false);
  if (!supportedDestination || products.isEmpty) return;

  final ownerPrefix = brandOnly
      ? 'buy-${current.destination.name}-brand'
      : switch (current.destination) {
          BuyV2Destination.shop => 'buy-shop-seller',
          BuyV2Destination.wholesale => 'buy-wholesale-supplier',
          BuyV2Destination.medicine => 'buy-medicine-pharmacy',
          BuyV2Destination.orders => 'buy-order-partner',
        };
  final title = brandOnly
      ? '${current.brand} products'
      : 'More from ${current.seller}';
  final detail = brandOnly
      ? 'Browse ${products.length} available ${current.brand} products'
      : switch (current.destination) {
          BuyV2Destination.wholesale =>
            'Compare available packs, minimum orders, prices and delivery',
          BuyV2Destination.medicine =>
            'Review available packs and prices · Not medical advice',
          _ => 'Browse this store’s available products and delivery times',
        };
  final closeTooltip = brandOnly
      ? 'Close brand products'
      : switch (current.destination) {
          BuyV2Destination.wholesale => 'Close supplier products',
          BuyV2Destination.medicine => 'Close pharmacy products',
          _ => 'Close seller products',
        };
  final motion = BuyV2SupplierSheetMotion.resolve(context);
  final transitionController = AnimationController(
    vsync: Navigator.of(context),
    duration: motion.duration ?? Duration.zero,
    reverseDuration: motion.reverseDuration ?? Duration.zero,
  );
  try {
    final selectedProductId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(
        maxWidth: BuyV2SupplierSheetMotion.maxWidth,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      transitionAnimationController: transitionController,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .96,
        child: SafeArea(
          top: false,
          child: Semantics(
            key: ValueKey('$ownerPrefix-sheet-${current.id}'),
            container: true,
            scopesRoute: true,
            namesRoute: true,
            explicitChildNodes: true,
            label: title,
            child: ListView(
              key: ValueKey('$ownerPrefix-sheet-list'),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: BuyV2Colors.softOrange,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        brandOnly
                            ? Icons.sell_outlined
                            : Icons.storefront_outlined,
                        color: BuyV2Colors.navy,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.clip,
                            style: sheetContext.buyTitle.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 2),
                          Text(detail, style: sheetContext.buyMeta),
                          const SizedBox(height: 3),
                          Text(
                            '${products.length} ${products.length == 1 ? 'product' : 'products'}',
                            style: sheetContext.buyMeta.copyWith(
                              color: BuyV2Colors.green,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      key: ValueKey('$ownerPrefix-sheet-close'),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      tooltip: closeTooltip,
                      style: IconButton.styleFrom(
                        minimumSize: const Size.square(BuyV2Metrics.minimumTap),
                        side: const BorderSide(color: BuyV2Colors.line),
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                BuyV2ProgressiveProductGrid(
                  session: session,
                  products: previewProducts,
                  storageKey:
                      '$ownerPrefix-catalogue-${brandOnly ? current.brand : current.seller}',
                  semanticLabel:
                      '${brandOnly ? current.brand : current.seller} product catalogue',
                  laneCount: products.length > 1 ? 2 : 1,
                  storeContext: !brandOnly,
                  onOpenProduct: (product) =>
                      Navigator.of(sheetContext).pop(product.id),
                ),
                if (!brandOnly && products.length > 1) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    height: BuyV2Metrics.minimumTap,
                    child: OutlinedButton.icon(
                      key: ValueKey('$ownerPrefix-view-more-${current.id}'),
                      onPressed: () async {
                        final productId = await _showBuyV2FullStoreCatalogue(
                          sheetContext,
                          session,
                          current,
                          products,
                          ownerPrefix,
                        );
                        if (productId != null && sheetContext.mounted) {
                          Navigator.of(sheetContext).pop(productId);
                        }
                      },
                      icon: const Icon(Icons.grid_view_rounded, size: 18),
                      label: Text('View all ${products.length} products'),
                    ),
                  ),
                ],
                if (otherStores.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Other stores you may like',
                    style: sheetContext.buyTitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'More stores with relevant products and delivery options',
                    style: sheetContext.buyMeta,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 128,
                    child: ListView.separated(
                      key: ValueKey('$ownerPrefix-other-stores'),
                      scrollDirection: Axis.horizontal,
                      itemCount: otherStores.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, index) {
                        final store = otherStores[index];
                        return _RelatedStoreCard(
                          key: ValueKey('$ownerPrefix-other-store-${store.id}'),
                          product: store,
                          onTap: () => Navigator.of(
                            sheetContext,
                          ).pop('store:${store.id}'),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (!transitionController.isDismissed) {
      await transitionController.reverse();
    }
    if (selectedProductId != null && context.mounted) {
      const storePrefix = 'store:';
      if (selectedProductId.startsWith(storePrefix)) {
        await showBuyV2PartnerCatalogue(
          context,
          session,
          session.product(selectedProductId.substring(storePrefix.length)),
        );
      } else {
        session.openProduct(selectedProductId);
      }
    }
  } finally {
    transitionController.dispose();
  }
}

Future<String?> _showBuyV2FullStoreCatalogue(
  BuildContext context,
  BuyV2Session session,
  BuyV2Product current,
  List<BuyV2Product> products,
  String ownerPrefix,
) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: .98,
      child: SafeArea(
        top: false,
        child: ListView(
          key: ValueKey('$ownerPrefix-full-catalogue-list'),
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox.square(
                  dimension: 44,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: BuyV2Colors.softOrange,
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      color: BuyV2Colors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current.seller,
                        maxLines: 2,
                        overflow: TextOverflow.clip,
                        style: sheetContext.buyTitle.copyWith(fontSize: 18),
                      ),
                      Text(
                        '${_sellerTypeLabel(current.sellerType)} · ${products.length} available products',
                        style: sheetContext.buyMeta.copyWith(
                          color: BuyV2Colors.green,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.outlined(
                  key: ValueKey('$ownerPrefix-full-catalogue-close'),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  tooltip: 'Close full store catalogue',
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            BuyV2ProgressiveProductGrid(
              session: session,
              products: products,
              storageKey: '$ownerPrefix-full-catalogue-${current.seller}',
              semanticLabel: '${current.seller} full product catalogue',
              laneCount: products.length > 3 ? 2 : 1,
              storeContext: true,
              onOpenProduct: (product) =>
                  Navigator.of(sheetContext).pop(product.id),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RelatedStoreCard extends StatelessWidget {
  const _RelatedStoreCard({
    required this.product,
    required this.onTap,
    super.key,
  });

  final BuyV2Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Material(
        color: BuyV2Colors.softBlue,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      color: BuyV2Colors.navy,
                      size: 20,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        product.seller,
                        maxLines: 2,
                        overflow: TextOverflow.clip,
                        style: context.buyBody.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: BuyV2Colors.navy,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${product.title} · ${product.pack}',
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                  style: context.buyMeta.copyWith(color: BuyV2Colors.ink),
                ),
                const Spacer(),
                Text(
                  '${_sellerTypeLabel(product.sellerType)} · ${_compactDeliveryPromise(product.deliveryPromise)}',
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                  style: context.buyMeta.copyWith(
                    color: BuyV2Colors.green,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _HouseholdBasketAction { seeProducts, addToCart }

class _BuyV2InfoSheetHeader extends StatelessWidget {
  const _BuyV2InfoSheetHeader({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onClose,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: BuyV2Colors.softOrange,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: BuyV2Colors.navy, size: 23),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.buyTitle.copyWith(fontSize: 19)),
                const SizedBox(height: 2),
                Text(detail, style: context.buyMeta),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          key: ValueKey('buy-info-sheet-close-$title'),
          onPressed: onClose,
          tooltip: 'Close $title',
          style: IconButton.styleFrom(
            minimumSize: const Size.square(BuyV2Metrics.minimumTap),
            side: const BorderSide(color: BuyV2Colors.line),
          ),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _SavedProductsSheet extends StatelessWidget {
  const _SavedProductsSheet({
    required this.session,
    required this.destination,
    required this.onClose,
    required this.onOpenProduct,
  });

  final BuyV2Session session;
  final BuyV2Destination destination;
  final VoidCallback onClose;
  final ValueChanged<String> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final sheetHeight = (MediaQuery.sizeOf(context).height * .58)
        .clamp(300.0, 420.0)
        .toDouble();
    return Semantics(
      key: const ValueKey('buy-saved-products-info-sheet'),
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Saved products in ${destination.label}',
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AnimatedBuilder(
            animation: session,
            builder: (context, _) {
              final saved = session.savedProductsFor(destination);
              final ownerKey = saved.map((product) => product.id).join('|');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BuyV2InfoSheetHeader(
                    icon: Icons.bookmarks_rounded,
                    title: 'Saved products',
                    detail: '${destination.label} · ${saved.length} saved',
                    onClose: onClose,
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: AnimatedSwitcher(
                      key: const ValueKey('buy-saved-products-owner-motion'),
                      duration: BuyV2InfoSheetMotion.resolveContentDuration(
                        context,
                      ),
                      reverseDuration:
                          BuyV2InfoSheetMotion.resolveContentDuration(context),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, .025),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: saved.isEmpty
                          ? _SavedProductsEmptyState(
                              key: const ValueKey(
                                'buy-saved-products-empty-state',
                              ),
                              destination: destination,
                            )
                          : ListView.separated(
                              key: ValueKey(
                                'buy-saved-products-list-$ownerKey',
                              ),
                              padding: EdgeInsets.zero,
                              itemCount: saved.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final product = saved[index];
                                return _SavedProductInfoRow(
                                  product: product,
                                  onOpen: () => onOpenProduct(product.id),
                                  onRemove: () =>
                                      session.toggleSaved(product.id),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RecentlyViewedProductsSheet extends StatelessWidget {
  const _RecentlyViewedProductsSheet({
    required this.session,
    required this.destination,
    required this.onClose,
    required this.onOpenProduct,
    required this.onClear,
  });

  final BuyV2Session session;
  final BuyV2Destination destination;
  final VoidCallback onClose;
  final ValueChanged<String> onOpenProduct;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final sheetHeight = (MediaQuery.sizeOf(context).height * .58)
        .clamp(310.0, 430.0)
        .toDouble();
    return Semantics(
      key: const ValueKey('buy-recently-viewed-info-sheet'),
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Recently viewed products in ${destination.label}',
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: AnimatedBuilder(
            animation: session,
            builder: (context, _) {
              final products = session.recentlyViewedProductsFor(destination);
              final ownerKey = products.map((product) => product.id).join('|');
              final productLabel = products.length == 1
                  ? 'product'
                  : 'products';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BuyV2InfoSheetHeader(
                    icon: Icons.history_rounded,
                    title: 'Recently viewed',
                    detail:
                        '${destination.label} · ${products.length} $productLabel',
                    onClose: onClose,
                  ),
                  if (products.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        key: const ValueKey('buy-recently-viewed-sheet-clear'),
                        onPressed: onClear,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 17,
                        ),
                        label: const Text('Clear'),
                      ),
                    ),
                  ] else
                    const SizedBox(height: 14),
                  Expanded(
                    child: AnimatedSwitcher(
                      key: const ValueKey(
                        'buy-recently-viewed-products-owner-motion',
                      ),
                      duration: BuyV2InfoSheetMotion.resolveContentDuration(
                        context,
                      ),
                      reverseDuration:
                          BuyV2InfoSheetMotion.resolveContentDuration(context),
                      child: products.isEmpty
                          ? _RecentlyViewedEmptyState(destination: destination)
                          : ListView.separated(
                              key: ValueKey(
                                'buy-recently-viewed-products-list-$ownerKey',
                              ),
                              padding: EdgeInsets.zero,
                              itemCount: products.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return _RecentlyViewedProductInfoRow(
                                  product: product,
                                  facts: session.productFactsFor(product),
                                  onOpen: () => onOpenProduct(product.id),
                                  onAdd: () => session.addProduct(product.id),
                                  quantity: session.quantityFor(product.id),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RecentlyViewedEmptyState extends StatelessWidget {
  const _RecentlyViewedEmptyState({required this.destination});

  final BuyV2Destination destination;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: BuyV2Colors.softBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_toggle_off_rounded,
              color: BuyV2Colors.navy,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No recently viewed products',
            textAlign: TextAlign.center,
            style: context.buyTitle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Products you open in ${destination.label} will appear here.',
            textAlign: TextAlign.center,
            style: context.buyMeta,
          ),
        ],
      ),
    ),
  );
}

class _RecentlyViewedProductInfoRow extends StatelessWidget {
  const _RecentlyViewedProductInfoRow({
    required this.product,
    required this.facts,
    required this.onOpen,
    required this.onAdd,
    required this.quantity,
  });

  final BuyV2Product product;
  final BuyV2ProductFactsSnapshot facts;
  final VoidCallback onOpen;
  final VoidCallback onAdd;
  final int quantity;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: BuyV2Colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Open ${product.title}, ${product.pack}',
                onTap: onOpen,
                excludeSemantics: true,
                child: InkWell(
                  key: ValueKey(
                    'buy-settings-recently-viewed-product-${product.id}',
                  ),
                  onTap: onOpen,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: 48,
                        child: BuyV2ProductPackshot(
                          product: product,
                          borderRadius: 12,
                          animateFirstFrame: false,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: BuyV2Colors.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${product.pack} · ${buyV2Money(facts.price)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.buyMeta,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              buyV2BuyerDeliveryPromise(facts),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.buyMeta.copyWith(
                                color: BuyV2Colors.green,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 7),
            SizedBox(
              width: 76,
              height: BuyV2Metrics.minimumTap,
              child: Semantics(
                button: true,
                label: quantity > 0
                    ? '${product.title} is in Cart'
                    : 'Add ${product.title} to cart',
                child: FilledButton.tonalIcon(
                  key: ValueKey('buy-recently-viewed-add-${product.id}'),
                  onPressed: onAdd,
                  icon: Icon(
                    quantity > 0
                        ? Icons.check_rounded
                        : Icons.add_shopping_cart_rounded,
                    size: 17,
                  ),
                  label: Text(quantity > 0 ? 'Added' : 'Add'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SavedProductsEmptyState extends StatelessWidget {
  const _SavedProductsEmptyState({super.key, required this.destination});

  final BuyV2Destination destination;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: BuyV2Colors.softBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_add_outlined,
                color: BuyV2Colors.navy,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No Saved products yet',
              textAlign: TextAlign.center,
              style: context.buyTitle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Save products from the ${destination.label} grid for instant access.',
              textAlign: TextAlign.center,
              style: context.buyMeta,
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedProductInfoRow extends StatelessWidget {
  const _SavedProductInfoRow({
    required this.product,
    required this.onOpen,
    required this.onRemove,
  });

  final BuyV2Product product;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: BuyV2Colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: 'Open ${product.title}',
              onTap: onOpen,
              excludeSemantics: true,
              child: InkWell(
                key: ValueKey('buy-saved-${product.id}'),
                onTap: onOpen,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: BuyV2Colors.softBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bookmark_rounded,
                          color: BuyV2Colors.navy,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: BuyV2Colors.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${product.pack} · ${buyV2Money(product.price)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.buyMeta,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            key: ValueKey('buy-unsave-${product.id}'),
            tooltip: 'Remove ${product.title} from Saved',
            onPressed: onRemove,
            icon: const Icon(Icons.bookmark_remove_rounded),
          ),
          const SizedBox(width: 2),
        ],
      ),
    );
  }
}

class _HouseholdBasket extends StatelessWidget {
  const _HouseholdBasket({
    required this.onClose,
    required this.onSeeProducts,
    required this.onAddToCart,
  });

  final VoidCallback onClose;
  final VoidCallback onSeeProducts;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final compactActions =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.2;
    final seeProducts = OutlinedButton.icon(
      key: const ValueKey('buy-household-see-products'),
      onPressed: onSeeProducts,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(BuyV2Metrics.minimumTap),
        side: const BorderSide(color: BuyV2Colors.line),
      ),
      icon: const Icon(Icons.grid_view_rounded, size: 18),
      label: const Text('See 12 products'),
    );
    final addToCart = FilledButton.icon(
      key: const ValueKey('buy-household-add-to-cart'),
      onPressed: onAddToCart,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(BuyV2Metrics.minimumTap),
      ),
      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
      label: const Text('Add basket to cart'),
    );
    return Semantics(
      key: const ValueKey('buy-household-basket-info-sheet'),
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Monthly home basket',
      child: SafeArea(
        key: const ValueKey('buy-household-basket-bottom-safe-area'),
        top: false,
        bottom: false,
        maintainBottomViewPadding: true,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: BuyV2AddressSheetMotion.resolveModalActionBottomInset(
              context,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BuyV2InfoSheetHeader(
                  icon: Icons.shopping_basket_outlined,
                  title: 'Monthly home basket',
                  detail: 'A ready 30-day household plan',
                  onClose: onClose,
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: BuyV2Colors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'HOUSEHOLD BASKET',
                              style: context.buyMeta.copyWith(
                                color: BuyV2Colors.navy,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .7,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: BuyV2Colors.softGreen,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text(
                              'Save ₹415',
                              style: TextStyle(
                                color: BuyV2Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HouseholdBasketFact(
                            icon: Icons.inventory_2_outlined,
                            label: '12 products',
                          ),
                          _HouseholdBasketFact(
                            icon: Icons.layers_outlined,
                            label: '21 packs',
                          ),
                          _HouseholdBasketFact(
                            icon: Icons.calendar_month_outlined,
                            label: '30 days',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Review the products first, or add the existing basket to your cart.',
                        style: context.buyMeta,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (compactActions) ...[
                  SizedBox(width: double.infinity, child: seeProducts),
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: addToCart),
                ] else
                  Row(
                    children: [
                      Expanded(child: seeProducts),
                      const SizedBox(width: 8),
                      Expanded(child: addToCart),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HouseholdBasketFact extends StatelessWidget {
  const _HouseholdBasketFact({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: BuyV2Colors.softOrange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: BuyV2Colors.navy, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: BuyV2Colors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _compactProductBadge(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('manufacturer')) return 'Maker offer';
  if (normalized.contains('landed')) return 'Best cost';
  if (normalized.contains('lowest')) return 'Lowest';
  if (normalized.contains('popular')) return 'Popular';
  if (normalized.contains('prescription')) return 'Rx required';
  return value;
}

String _compactDeliveryPromise(String value) {
  if (value.toLowerCase().contains('confirmed at checkout')) {
    return 'At checkout';
  }
  final minutes = RegExp(
    r'(?:delivered|delivery)\s+in\s+(\d+)\s+min',
    caseSensitive: false,
  ).firstMatch(value);
  if (minutes != null) return '${minutes.group(1)} min';
  final parts = value.split(' · ');
  if (parts.length < 2) return value;
  final date = parts.first.replaceFirst(RegExp(r'^[A-Za-z]{3},\s*'), '');
  final timing = parts
      .sublist(1)
      .join(' · ')
      .replaceFirst(RegExp(r'^(?:by|within)\s+'), '');
  return '$date · $timing';
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.session,
    required this.savedOnly,
    required this.onShowAll,
  });

  final BuyV2Session session;
  final bool savedOnly;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    if (!savedOnly && !session.catalogueAvailable) {
      return _CatalogueAvailabilityState(session: session);
    }
    final products = savedOnly
        ? session.visibleProducts
              .where((product) => session.isSaved(product.id))
              .toList(growable: false)
        : session.visibleProducts;
    final showPromotions =
        !savedOnly &&
        session.query.isEmpty &&
        session.selectedCategoryId == 'all' &&
        session.activeShoppingIntent == null;
    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                color: BuyV2Colors.muted,
                size: 34,
              ),
              const SizedBox(height: 8),
              Text(
                savedOnly ? 'No Saved products here' : 'No matching products',
                style: context.buyTitle.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 4),
              Text(
                savedOnly
                    ? 'Save products from this grid for instant access.'
                    : 'Try another category or clear the filter.',
                textAlign: TextAlign.center,
                style: context.buyMeta,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  if (savedOnly) {
                    onShowAll();
                  } else {
                    session.chooseFilter(null);
                    session.chooseCategory('all');
                  }
                },
                child: const Text('Show all products'),
              ),
            ],
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final accessibleText = textScale > 1.25;
        const compactCards = true;
        final layout = _resolveCompactProductGridLayout(
          constraints: constraints,
          accessibleText: accessibleText,
          savedOnly: savedOnly,
        );
        final featuredProducts = showPromotions
            ? products.take(6).toList(growable: false)
            : const <BuyV2Product>[];
        final recentlyViewedProducts = showPromotions
            ? session.recentlyViewedProductsFor(session.destination)
            : const <BuyV2Product>[];
        final prescriptionMatches =
            showPromotions && session.destination == BuyV2Destination.medicine
            ? session.matchedPrescriptionProducts
            : const <BuyV2Product>[];
        final gridProducts = showPromotions
            ? products.skip(featuredProducts.length).toList(growable: false)
            : products;
        return CustomScrollView(
          key: PageStorageKey(
            'buy-${session.destination.name}-${session.selectedCategoryId}'
            '-${savedOnly ? 'saved' : 'all'}',
          ),
          slivers: [
            if (showPromotions)
              SliverToBoxAdapter(
                child: _CataloguePromotionRail(session: session),
              ),
            if (recentlyViewedProducts.isNotEmpty)
              SliverToBoxAdapter(
                child: _RecentlyViewedRail(
                  session: session,
                  products: recentlyViewedProducts,
                  accessibleText: accessibleText,
                ),
              ),
            if (prescriptionMatches.isNotEmpty)
              SliverToBoxAdapter(
                child: _PrescriptionMatchLane(
                  session: session,
                  products: prescriptionMatches,
                ),
              ),
            if (showPromotions)
              SliverToBoxAdapter(
                child: _FeaturedProductRail(
                  session: session,
                  products: featuredProducts,
                  accessibleText: accessibleText,
                ),
              ),
            if (showPromotions)
              SliverToBoxAdapter(
                child: BuyV2SponsoredSlot(
                  content: session.sponsoredContentFor(
                    BuyV2SponsoredPlacement.catalogueAfterDiscovery,
                  ),
                ),
              ),
            if (showPromotions && gridProducts.isNotEmpty)
              SliverToBoxAdapter(
                child: _CatalogueSectionHeader(session: session),
              ),
            if (savedOnly)
              SliverToBoxAdapter(
                child: _SavedDecisionShelf(
                  session: session,
                  products: products,
                ),
              ),
            if (gridProducts.isNotEmpty)
              SliverToBoxAdapter(
                child: _HorizontalProductGrid(
                  session: session,
                  products: gridProducts,
                  cardWidth: layout.cardWidth,
                  tileHeight: layout.tileHeight,
                  storageKey:
                      'buy-products-horizontal-${session.destination.name}-'
                      '${session.selectedCategoryId}-${savedOnly ? 'saved' : 'all'}',
                  compact: compactCards,
                  laneCount: savedOnly ? 1 : null,
                  savedContext: savedOnly,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CatalogueAvailabilityState extends StatelessWidget {
  const _CatalogueAvailabilityState({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final loading = session.commerceLoadState == BuyV2CommerceLoadState.loading;
    final offline = session.commerceLoadState == BuyV2CommerceLoadState.offline;
    final title = loading
        ? 'Opening Shop'
        : offline
        ? 'Shop could not refresh'
        : 'Shop is unavailable right now';
    final detail =
        session.commerceMessage ??
        (loading
            ? 'Checking current products, prices and delivery availability.'
            : offline
            ? 'Check your connection, then try again. Your Cart is unchanged.'
            : 'Try again shortly. Your Cart and saved choices are unchanged.');
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Semantics(
          key: ValueKey('buy-catalogue-${session.commerceLoadState.name}'),
          container: true,
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox.square(
                  dimension: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              else
                Icon(
                  offline ? Icons.cloud_off_outlined : Icons.store_outlined,
                  color: BuyV2Colors.navy,
                  size: 34,
                ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: context.buyTitle.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 5),
              Text(detail, textAlign: TextAlign.center, style: context.buyMeta),
              if (!loading) ...[
                const SizedBox(height: 14),
                SizedBox(
                  height: BuyV2Metrics.minimumTap,
                  child: FilledButton.icon(
                    key: const ValueKey('buy-catalogue-retry'),
                    onPressed: session.retryCommerce,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try again'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedDecisionShelf extends StatelessWidget {
  const _SavedDecisionShelf({required this.session, required this.products});

  final BuyV2Session session;
  final List<BuyV2Product> products;

  @override
  Widget build(BuildContext context) {
    final destination = session.destination;
    final savedTitle = switch (destination) {
      BuyV2Destination.shop => 'Saved in Shop',
      BuyV2Destination.wholesale => 'Saved for Wholesale',
      BuyV2Destination.medicine => 'Saved in Medicine',
      BuyV2Destination.orders => 'Saved in Shop',
    };
    final productLabel = switch (destination) {
      BuyV2Destination.shop => products.length == 1 ? 'product' : 'products',
      BuyV2Destination.wholesale =>
        products.length == 1 ? 'trade product' : 'trade products',
      BuyV2Destination.medicine =>
        products.length == 1 ? 'medicine' : 'medicines',
      BuyV2Destination.orders => products.length == 1 ? 'product' : 'products',
    };
    final hasPrescriptionGate =
        destination == BuyV2Destination.medicine &&
        products.any(
          (product) =>
              product.requiresPrescription &&
              !session.isPrescriptionApproved(product.id),
        );

    return Semantics(
      key: const ValueKey('buy-saved-decision-shelf'),
      container: true,
      label: '$savedTitle. ${products.length} $productLabel.',
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 2),
        padding: const EdgeInsets.fromLTRB(9, 7, 9, 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BuyV2Colors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BuyV2ThemeScope.of(context).softAccent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.bookmarks_rounded,
                    color: BuyV2Colors.navy,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        savedTitle,
                        style: const TextStyle(
                          color: BuyV2Colors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${products.length} $productLabel · ready for Cart',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.buyMeta.copyWith(fontSize: 8),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  key: const ValueKey('buy-saved-clear'),
                  onPressed: () => _confirmClearSaved(
                    context,
                    session,
                    destination,
                    savedTitle,
                    productLabel,
                    products.length,
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: BuyV2Colors.muted,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Changed your mind?'),
                      Text(
                        'Clear list',
                        style: TextStyle(
                          color: BuyV2Colors.navy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (hasPrescriptionGate) ...[
              const SizedBox(height: 4),
              Text(
                'A prescription medicine stays Saved until its prescription '
                'is linked.',
                style: context.buyMeta.copyWith(
                  color: BuyV2Colors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            if (hasPrescriptionGate) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const ValueKey('buy-saved-review-prescription'),
                  onPressed: () => showBuyV2PrescriptionSheet(context, session),
                  icon: const Icon(
                    Icons.medical_information_outlined,
                    size: 17,
                  ),
                  label: const Text('Review prescription'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmClearSaved(
  BuildContext context,
  BuyV2Session session,
  BuyV2Destination destination,
  String savedTitle,
  String productLabel,
  int productCount,
) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: BuyV2Metrics.maxWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    sheetAnimationStyle: BuyV2SavedClearSheetMotion.resolve(context),
    builder: (sheetContext) => _SavedClearDecisionSheet(
      savedTitle: savedTitle,
      productLabel: productLabel,
      productCount: productCount,
      destination: destination,
      onKeep: () => Navigator.of(sheetContext).pop(false),
      onClear: () => Navigator.of(sheetContext).pop(true),
    ),
  );
  if (confirmed == true) {
    session.clearSavedProducts(destination);
  }
}

class _SavedClearDecisionSheet extends StatelessWidget {
  const _SavedClearDecisionSheet({
    required this.savedTitle,
    required this.productLabel,
    required this.productCount,
    required this.destination,
    required this.onKeep,
    required this.onClear,
  });

  final String savedTitle;
  final String productLabel;
  final int productCount;
  final BuyV2Destination destination;
  final VoidCallback onKeep;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final destinationNoun = switch (destination) {
      BuyV2Destination.shop => 'Shop',
      BuyV2Destination.wholesale => 'Wholesale',
      BuyV2Destination.medicine => 'Medicine',
      BuyV2Destination.orders => 'Shop',
    };
    return Semantics(
      key: const ValueKey('buy-saved-clear-sheet'),
      container: true,
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Clear $savedTitle',
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: BuyV2ThemeScope.of(context).softAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bookmark_remove_outlined,
                    color: BuyV2Colors.navy,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clear $savedTitle?',
                        style: context.buyTitle.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Remove $productCount saved $productLabel from '
                        '$destinationNoun. Items already in Cart stay there.',
                        style: context.buyMeta.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const ValueKey('buy-saved-clear-close'),
                  tooltip: 'Keep saved',
                  onPressed: onKeep,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('buy-saved-keep'),
                    onPressed: onKeep,
                    child: const Text('Keep saved'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('buy-saved-confirm-clear'),
                    onPressed: onClear,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB3261E),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear list'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BuyV2ProgressiveProductGrid extends StatelessWidget {
  const BuyV2ProgressiveProductGrid({
    super.key,
    required this.session,
    required this.products,
    required this.storageKey,
    required this.semanticLabel,
    this.laneCount,
    this.savedContext = false,
    this.onOpenProduct,
    this.storeContext = false,
  });

  final BuyV2Session session;
  final List<BuyV2Product> products;
  final String storageKey;
  final String semanticLabel;
  final int? laneCount;
  final bool savedContext;
  final ValueChanged<BuyV2Product>? onOpenProduct;
  final bool storeContext;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final accessibleText = textScale > 1.25;
        final layout = _resolveCompactProductGridLayout(
          constraints: constraints,
          accessibleText: accessibleText,
        );
        return _HorizontalProductGrid(
          session: session,
          products: products,
          cardWidth: layout.cardWidth,
          tileHeight: layout.tileHeight,
          storageKey: storageKey,
          compact: true,
          laneCount: laneCount,
          savedContext: savedContext,
          semanticLabel: semanticLabel,
          onOpenProduct: onOpenProduct,
          storeContext: storeContext,
        );
      },
    );
  }
}

({int columns, double cardWidth, double tileHeight})
_resolveCompactProductGridLayout({
  required BoxConstraints constraints,
  required bool accessibleText,
  bool savedOnly = false,
}) {
  // The founder-approved Shop and Wholesale rhythm keeps three products
  // visible at normal text scale. Enlarged accessibility text uses two cards
  // so type and actions can grow without clipping.
  final columns = savedOnly
      ? constraints.maxWidth >= 320
            ? 2
            : 1
      : accessibleText && constraints.maxWidth < 460
      ? 2
      : constraints.maxWidth >= 320
      ? 3
      : 2;
  const horizontalInsets = 20.0;
  const cardGap = 7.0;
  final cardWidth =
      (constraints.maxWidth - horizontalInsets - ((columns - 1) * cardGap)) /
      columns;
  final tileHeight = savedOnly
      ? accessibleText
            ? constraints.maxWidth < 360
                  ? 290.0
                  : 284.0
            : 260.0
      : accessibleText
      ? constraints.maxWidth < 360
            ? 310.0
            : 296.0
      : columns == 3
      ? 246.0
      : 244.0;
  return (columns: columns, cardWidth: cardWidth, tileHeight: tileHeight);
}

class _HorizontalProductGrid extends StatefulWidget {
  const _HorizontalProductGrid({
    required this.session,
    required this.products,
    required this.cardWidth,
    required this.tileHeight,
    required this.storageKey,
    this.compact = true,
    this.laneCount,
    this.savedContext = false,
    this.semanticLabel = 'Products',
    this.onOpenProduct,
    this.storeContext = false,
  });

  final BuyV2Session session;
  final List<BuyV2Product> products;
  final double cardWidth;
  final double tileHeight;
  final String storageKey;
  final bool compact;
  final int? laneCount;
  final bool savedContext;
  final String semanticLabel;
  final ValueChanged<BuyV2Product>? onOpenProduct;
  final bool storeContext;

  @override
  State<_HorizontalProductGrid> createState() => _HorizontalProductGridState();
}

class _HorizontalProductGridState extends State<_HorizontalProductGrid> {
  static const _pageSize = 8;

  late int _visibleCount;
  late List<String> _productIds;
  bool _pageRequestPending = false;

  int get _initialCount =>
      widget.products.length < _pageSize ? widget.products.length : _pageSize;

  static List<String> _idsFor(List<BuyV2Product> products) =>
      products.map((product) => product.id).toList(growable: false);

  @override
  void initState() {
    super.initState();
    _visibleCount = _initialCount;
    _productIds = _idsFor(widget.products);
  }

  @override
  void didUpdateWidget(covariant _HorizontalProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIds = _idsFor(widget.products);
    if (!listEquals(_productIds, nextIds) ||
        oldWidget.storageKey != widget.storageKey) {
      _productIds = nextIds;
      _visibleCount = _initialCount;
    }
  }

  bool _loadNextPage(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification &&
        notification is! OverscrollNotification) {
      return false;
    }
    if (notification.metrics.axis != Axis.horizontal ||
        notification.metrics.extentAfter > widget.cardWidth ||
        _visibleCount >= widget.products.length ||
        _pageRequestPending) {
      return false;
    }
    _pageRequestPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final next = _visibleCount + _pageSize;
      setState(() {
        _visibleCount = next < widget.products.length
            ? next
            : widget.products.length;
        _pageRequestPending = false;
      });
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products
        .take(_visibleCount)
        .toList(growable: false);
    final resolvedLaneCount = widget.laneCount ?? (products.length > 1 ? 2 : 1);
    return Semantics(
      key: const ValueKey('buy-horizontal-product-grid'),
      container: true,
      liveRegion: true,
      label:
          '${widget.semanticLabel}. Showing ${products.length} of '
          '${widget.products.length} in $resolvedLaneCount independently '
          'scrollable ${resolvedLaneCount == 1 ? 'lane' : 'lanes'}. '
          '${_visibleCount < widget.products.length ? 'More products load near the end.' : 'All products loaded.'}',
      child: SizedBox(
        key: ValueKey('buy-progressive-product-count-${widget.storageKey}'),
        height: (widget.tileHeight * resolvedLaneCount) + 14,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 12, 10),
          child: Column(
            children: [
              for (
                var laneIndex = 0;
                laneIndex < resolvedLaneCount;
                laneIndex++
              ) ...[
                if (laneIndex > 0) const SizedBox(height: 6),
                Expanded(
                  child: Semantics(
                    key: ValueKey('buy-horizontal-product-lane-$laneIndex'),
                    container: true,
                    label:
                        'Product lane ${laneIndex + 1}. '
                        'Swipe left or right for more.',
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _loadNextPage,
                      child: ListView.separated(
                        key: PageStorageKey(
                          '${widget.storageKey}-lane-$laneIndex',
                        ),
                        scrollDirection: Axis.horizontal,
                        primary: false,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount:
                            (products.length -
                                laneIndex +
                                resolvedLaneCount -
                                1) ~/
                            resolvedLaneCount,
                        separatorBuilder: (_, _) => const SizedBox(width: 7),
                        itemBuilder: (context, index) {
                          final productIndex =
                              (index * resolvedLaneCount) + laneIndex;
                          return SizedBox(
                            width: widget.cardWidth,
                            child: BuyV2ProductCard(
                              session: widget.session,
                              product: products[productIndex],
                              compact: widget.compact,
                              savedContext: widget.savedContext,
                              onOpenProduct: widget.onOpenProduct,
                              storeContext: widget.storeContext,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CataloguePromotionRail extends StatelessWidget {
  const _CataloguePromotionRail({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    final accessibleText = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    final cards = switch (session.destination) {
      BuyV2Destination.shop => [
        BuyV2PromotionCard(
          key: const ValueKey('buy-promotion-shop-basket'),
          title: 'Plan the monthly basket',
          detail: 'Review a curated 30-day household basket',
          icon: Icons.shopping_basket_outlined,
          sequenceIndex: 0,
          onTap: () => showBuyV2HouseholdBasket(context, session),
        ),
        BuyV2PromotionCard(
          key: const ValueKey('buy-promotion-shop-wholesale'),
          title: 'Buying for a business?',
          detail: 'Compare wholesale packs for your Workspace',
          icon: Icons.storefront_outlined,
          accent: BuyV2Colors.green,
          sequenceIndex: 1,
          onTap: () =>
              session.chooseShoppingIntent(BuyV2ShoppingIntent.businessBuying),
        ),
      ],
      BuyV2Destination.wholesale => [
        BuyV2PromotionCard(
          key: const ValueKey('buy-promotion-wholesale-restock'),
          title: 'Flexible restocking',
          detail: 'Compare products with lower minimum packs',
          icon: Icons.inventory_2_outlined,
          sequenceIndex: 0,
          onTap: () => session.chooseShoppingIntent(
            BuyV2ShoppingIntent.flexibleRestocking,
          ),
        ),
        BuyV2PromotionCard(
          key: const ValueKey('buy-promotion-wholesale-shop'),
          title: 'Shopping for home?',
          detail: 'Browse retail packs sized for home',
          icon: Icons.shopping_bag_outlined,
          accent: BuyV2Colors.green,
          sequenceIndex: 1,
          onTap: () =>
              session.chooseShoppingIntent(BuyV2ShoppingIntent.homeShopping),
        ),
      ],
      BuyV2Destination.medicine => [
        BuyV2PromotionCard(
          key: const ValueKey('buy-promotion-medicine-prescription'),
          title: 'Prescription centre',
          detail: 'Add or use a saved prescription',
          icon: Icons.description_outlined,
          sequenceIndex: 0,
          onTap: () => showBuyV2PrescriptionSheet(context, session),
        ),
        BuyV2PromotionCard(
          key: const ValueKey('buy-promotion-medicine-wellness'),
          title: 'Everyday wellness',
          detail: 'Browse no-prescription care',
          icon: Icons.health_and_safety_outlined,
          accent: BuyV2Colors.green,
          sequenceIndex: 1,
          onTap: () => session.chooseFilter('otc'),
        ),
      ],
      BuyV2Destination.orders => const <BuyV2PromotionCard>[],
    };
    return SizedBox(
      key: const ValueKey('buy-catalogue-promotions'),
      height: accessibleText ? 164 : 148,
      child: Padding(
        key: PageStorageKey(
          'buy-catalogue-promotions-${session.destination.name}',
        ),
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              if (index > 0) const SizedBox(width: 7),
              Expanded(child: cards[index]),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrescriptionMatchLane extends StatelessWidget {
  const _PrescriptionMatchLane({required this.session, required this.products});

  final BuyV2Session session;
  final List<BuyV2Product> products;

  @override
  Widget build(BuildContext context) {
    final stateKey = products.map((product) => product.id).join('|');
    final medicineLabel = products.length == 1 ? 'medicine' : 'medicines';
    return BuyV2FiniteIncomingTransition(
      key: const ValueKey('buy-prescription-match-lane-motion'),
      stateKey: 'prescription-matches-$stateKey',
      child: Container(
        key: const ValueKey('buy-prescription-match-lane'),
        margin: const EdgeInsets.fromLTRB(6, 4, 6, 6),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: BuyV2Colors.softGreen,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: BuyV2Colors.green.withValues(alpha: .26)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.medical_information_outlined,
                  size: 19,
                  color: BuyV2Colors.green,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Prescription matches',
                    style: context.buyTitle.copyWith(fontSize: 15),
                  ),
                ),
                Text(
                  '${products.length} $medicineLabel',
                  style: context.buyMeta.copyWith(
                    color: BuyV2Colors.green,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Matched in this session. Pharmacist review is still required '
              'before payment. Not medical advice.',
              style: context.buyMeta,
            ),
            const SizedBox(height: 9),
            SizedBox(
              height: 58,
              child: ListView.separated(
                key: const ValueKey('buy-prescription-match-list'),
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final product = products[index];
                  void openProduct() {
                    HapticFeedback.selectionClick();
                    session.openProduct(product.id);
                  }

                  return Semantics(
                    key: ValueKey(
                      'buy-prescription-match-product-${product.id}',
                    ),
                    button: true,
                    label:
                        'View prescription-matched ${product.title} product '
                        'details. ${product.pack}. '
                        'Pharmacist review required. Not medical advice.',
                    excludeSemantics: true,
                    onTap: openProduct,
                    child: BuyV2IntentDepth(
                      key: ValueKey(
                        'buy-prescription-match-depth-${product.id}',
                      ),
                      spatial: true,
                      child: OutlinedButton(
                        key: ValueKey(
                          'buy-prescription-match-action-${product.id}',
                        ),
                        onPressed: openProduct,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(238, 54),
                          maximumSize: const Size(286, 58),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          foregroundColor: BuyV2Colors.navy,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: BuyV2Colors.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: Text(
                          '${product.title}\n${product.pack} · '
                          '${buyV2Money(product.price)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            height: 1.22,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedProductRail extends StatelessWidget {
  const _FeaturedProductRail({
    required this.session,
    required this.products,
    required this.accessibleText,
  });

  final BuyV2Session session;
  final List<BuyV2Product> products;
  final bool accessibleText;

  @override
  Widget build(BuildContext context) {
    final title = switch (session.destination) {
      BuyV2Destination.shop => 'Fresh picks',
      BuyV2Destination.wholesale => 'Trade picks',
      BuyV2Destination.medicine => 'Pharmacy picks',
      BuyV2Destination.orders => 'Product picks',
    };
    return SizedBox(
      key: const ValueKey('buy-featured-products'),
      height: accessibleText ? 338 : 302,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 7, 9, 5),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.buyTitle.copyWith(fontSize: 15),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  key: const ValueKey('buy-featured-browse-categories'),
                  button: true,
                  label: 'Browse categories',
                  onTap: () => showBuyV2CategoryPicker(context, session),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => showBuyV2CategoryPicker(context, session),
                      borderRadius: BorderRadius.circular(9),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Swipe to explore',
                              style: context.buyMeta.copyWith(
                                color: BuyV2Colors.navy,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: BuyV2Colors.navy,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              key: const ValueKey('buy-featured-product-list'),
              padding: const EdgeInsets.fromLTRB(7, 0, 12, 8),
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => SizedBox(
                width: accessibleText ? 178 : 168,
                child: _FeaturedProductCard(
                  session: session,
                  product: products[index],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentlyViewedRail extends StatelessWidget {
  const _RecentlyViewedRail({
    required this.session,
    required this.products,
    required this.accessibleText,
  });

  final BuyV2Session session;
  final List<BuyV2Product> products;
  final bool accessibleText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('buy-recently-viewed'),
      height: accessibleText ? 178 : 158,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 2, 4, 2),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recently viewed',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.buyTitle.copyWith(fontSize: 14),
                      ),
                      Text(
                        'Continue with the exact pack you viewed',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.buyMeta.copyWith(fontSize: 8),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  key: const ValueKey('buy-recently-viewed-clear'),
                  onPressed: () =>
                      session.clearRecentlyViewed(session.destination),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    foregroundColor: BuyV2Colors.navy,
                    textStyle: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              key: const ValueKey('buy-recently-viewed-list'),
              padding: const EdgeInsets.fromLTRB(7, 0, 12, 8),
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => _RecentlyViewedCard(
                session: session,
                product: products[index],
                accessibleText: accessibleText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentlyViewedCard extends StatelessWidget {
  const _RecentlyViewedCard({
    required this.session,
    required this.product,
    required this.accessibleText,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final bool accessibleText;

  @override
  Widget build(BuildContext context) {
    final facts = session.productFactsFor(product);
    final fulfilmentMode =
        facts.fulfilmentMode ?? buyV2CatalogueFulfilmentModeFor(product);
    final deliveryPromise = buyV2BuyerDeliveryPromise(facts);
    return SizedBox(
      width: accessibleText ? 224 : 206,
      child: Semantics(
        button: true,
        label:
            '${product.title}, ${product.pack}, ${buyV2Money(facts.price)}, '
            '${buyV2FulfilmentModeLabel(fulfilmentMode)}, $deliveryPromise',
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: BuyV2Colors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('buy-recently-viewed-product-${product.id}'),
            onTap: () {
              HapticFeedback.selectionClick();
              session.openProduct(product.id);
            },
            child: Row(
              children: [
                SizedBox(
                  width: 78,
                  height: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _productVisualColors(product),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: BuyV2ProductPackshot(
                        key: ValueKey(
                          'buy-recently-viewed-packshot-${product.id}',
                        ),
                        product: product,
                        borderRadius: 11,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(9, 7, 8, 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BuyV2Colors.ink,
                            fontSize: 10,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.pack,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.buyMeta.copyWith(fontSize: 8),
                        ),
                        const Spacer(),
                        Text(
                          buyV2Money(facts.price),
                          style: const TextStyle(
                            color: BuyV2Colors.navy,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${buyV2CompactFulfilmentModeLabel(fulfilmentMode)} · '
                          '${_compactDeliveryPromise(deliveryPromise)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BuyV2Colors.green,
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogueSectionHeader extends StatelessWidget {
  const _CatalogueSectionHeader({required this.session});

  final BuyV2Session session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('buy-more-products-heading'),
      padding: const EdgeInsets.fromLTRB(9, 7, 9, 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'More products',
              style: context.buyTitle.copyWith(fontSize: 15),
            ),
          ),
          Semantics(
            key: const ValueKey('buy-more-products-browse-categories'),
            button: true,
            label: 'Browse categories',
            onTap: () => showBuyV2CategoryPicker(context, session),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => showBuyV2CategoryPicker(context, session),
                borderRadius: BorderRadius.circular(9),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Swipe for more',
                        style: context.buyMeta.copyWith(
                          color: BuyV2Colors.navy,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: BuyV2Colors.navy,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedProductCard extends StatefulWidget {
  const _FeaturedProductCard({required this.session, required this.product});

  final BuyV2Session session;
  final BuyV2Product product;

  @override
  State<_FeaturedProductCard> createState() => _FeaturedProductCardState();
}

class _FeaturedProductCardState extends State<_FeaturedProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final product = widget.product;
    final facts = session.productFactsFor(product);
    final fulfilmentMode =
        facts.fulfilmentMode ?? buyV2CatalogueFulfilmentModeFor(product);
    final automaticFulfilment =
        product.destination == BuyV2Destination.shop ||
        product.destination == BuyV2Destination.wholesale;
    final buyerPromise = automaticFulfilment
        ? buyV2BuyerDeliveryPromise(facts)
        : facts.deliveryPromise;
    final offerDecision = automaticFulfilment
        ? buyV2ResolveProductOfferDecision(product: product, facts: facts)
        : null;
    final quantity = session.quantityFor(product.id);
    final rxBlocked =
        product.requiresPrescription &&
        !session.isPrescriptionApproved(product.id);
    return BuyV2IntentDepth(
      key: ValueKey('buy-featured-depth-${product.id}'),
      spatial: true,
      child: AnimatedScale(
        key: ValueKey('buy-featured-product-${product.id}'),
        scale: _pressed ? BuyV2Motion.pressScale : 1,
        duration: BuyV2Motion.resolved(context, BuyV2Motion.press),
        curve: Curves.easeOutCubic,
        child: Semantics(
          label:
              '${product.title}, ${product.pack}, ${buyV2Money(facts.price)}, '
              '${buyV2FulfilmentModeLabel(fulfilmentMode)}, '
              '$buyerPromise${automaticFulfilment ? ', ${facts.partner}, ${offerDecision!.statusLabel}' : ', fulfilled by ${facts.partner}'}',
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('buy-product-${product.id}'),
              onHighlightChanged: (pressed) {
                if (_pressed != pressed) {
                  setState(() => _pressed = pressed);
                }
              },
              onTap: () {
                HapticFeedback.selectionClick();
                session.openProduct(product.id);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: buyV2CardDecoration(radius: 16, shadow: true),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _FeaturedProductVisual(product: product),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: _ProductSaveButton(
                              session: session,
                              product: product,
                            ),
                          ),
                          Positioned(
                            right: 7,
                            bottom: 7,
                            child: _FeaturedProductAction(
                              session: session,
                              product: product,
                              quantity: quantity,
                              rxBlocked: rxBlocked,
                              offerDecision: offerDecision,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              maxLines: 2,
                              overflow: TextOverflow.clip,
                              style: const TextStyle(
                                color: BuyV2Colors.ink,
                                fontSize: 11,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.pack,
                              maxLines: 2,
                              overflow: TextOverflow.clip,
                              style: context.buyMeta.copyWith(fontSize: 8),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              buyV2Money(facts.price),
                              style: const TextStyle(
                                color: BuyV2Colors.navy,
                                fontSize: 16,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${facts.partner} · ${_sellerTypeLabel(product.sellerType)}',
                              maxLines: 2,
                              overflow: TextOverflow.clip,
                              style: const TextStyle(
                                color: BuyV2Colors.navy,
                                fontSize: 7.5,
                                height: 1.05,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              automaticFulfilment
                                  ? '${buyV2CompactFulfilmentModeLabel(fulfilmentMode)} · ${_compactDeliveryPromise(buyerPromise)}'
                                  : _compactDeliveryPromise(
                                      facts.deliveryPromise,
                                    ),
                              maxLines: 2,
                              overflow: TextOverflow.clip,
                              style: const TextStyle(
                                color: BuyV2Colors.green,
                                fontSize: 7.5,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedProductVisual extends StatelessWidget {
  const _FeaturedProductVisual({required this.product});

  final BuyV2Product product;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _productVisualColors(product)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 8,
            right: 8,
            bottom: 8,
            child: BuyV2ProductPackshot(
              key: ValueKey('buy-featured-packshot-${product.id}'),
              product: product,
              borderRadius: 13,
            ),
          ),
          Positioned(
            left: 7,
            top: 7,
            right: 50,
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 92),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: product.requiresPrescription
                      ? BuyV2Colors.navy
                      : BuyV2Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _compactProductBadge(product.badge),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedProductAction extends StatelessWidget {
  const _FeaturedProductAction({
    required this.session,
    required this.product,
    required this.quantity,
    required this.rxBlocked,
    required this.offerDecision,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final int quantity;
  final bool rxBlocked;
  final BuyV2ProductOfferDecision? offerDecision;

  @override
  Widget build(BuildContext context) {
    final requiresOfferReview = offerDecision?.canAdd == false;
    return AnimatedSwitcher(
      duration: BuyV2Motion.resolved(context, BuyV2Motion.stateChange),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: .92, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: quantity > 0
          ? SizedBox(
              key: ValueKey('buy-featured-quantity-shell-${product.id}'),
              width: 108,
              child: _QuantityStepper(
                key: ValueKey('buy-quantity-${product.id}'),
                productTitle: product.title,
                quantity: quantity,
                onDecrease: () => session.decrease(product.id),
                onIncrease: () => session.increase(product.id),
              ),
            )
          : Semantics(
              label: requiresOfferReview
                  ? 'Review ${product.title}. ${offerDecision!.statusLabel}'
                  : rxBlocked
                  ? 'Use prescription for ${product.title}'
                  : 'Add ${product.title} to cart',
              button: true,
              child: Material(
                key: ValueKey(
                  requiresOfferReview
                      ? 'buy-review-offer-${product.id}'
                      : 'buy-add-${product.id}',
                ),
                color: requiresOfferReview
                    ? BuyV2Colors.softOrange
                    : rxBlocked
                    ? BuyV2Colors.navy
                    : Colors.white,
                elevation: 3,
                shadowColor: const Color(0x33000040),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (requiresOfferReview) {
                      session.openProduct(product.id);
                      return;
                    }
                    final added = session.addProduct(product.id);
                    if (!added &&
                        session.pendingPrescriptionProductId == product.id) {
                      showBuyV2PrescriptionSheet(context, session);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 62,
                    height: BuyV2Metrics.minimumTap,
                    child: Center(
                      child: rxBlocked
                          ? const Text(
                              'Rx',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : requiresOfferReview
                          ? const Icon(
                              Icons.info_outline_rounded,
                              color: BuyV2Colors.orange,
                              size: 23,
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: BuyV2Colors.navy,
                                  size: 19,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    color: BuyV2Colors.navy,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class BuyV2ProductCard extends StatelessWidget {
  const BuyV2ProductCard({
    super.key,
    required this.session,
    required this.product,
    this.compact = false,
    this.savedContext = false,
    this.onOpenProduct,
    this.storeContext = false,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final bool compact;
  final bool savedContext;
  final ValueChanged<BuyV2Product>? onOpenProduct;
  final bool storeContext;

  @override
  Widget build(BuildContext context) {
    void openProduct() {
      HapticFeedback.selectionClick();
      final callback = onOpenProduct;
      if (callback != null) {
        callback(product);
      } else {
        session.openProduct(product.id);
      }
    }

    final facts = session.productFactsFor(product);
    final fulfilmentMode =
        facts.fulfilmentMode ?? buyV2CatalogueFulfilmentModeFor(product);
    final automaticFulfilment =
        product.destination == BuyV2Destination.shop ||
        product.destination == BuyV2Destination.wholesale;
    final buyerPromise = automaticFulfilment
        ? buyV2BuyerDeliveryPromise(facts)
        : facts.deliveryPromise;
    final offerDecision = automaticFulfilment
        ? buyV2ResolveProductOfferDecision(product: product, facts: facts)
        : null;
    final requiresOfferReview = offerDecision?.canAdd == false;
    final quantity = session.quantityFor(product.id);
    final rxBlocked =
        product.requiresPrescription &&
        !session.isPrescriptionApproved(product.id);
    return BuyV2IntentDepth(
      key: ValueKey('buy-product-depth-${product.id}'),
      spatial: true,
      child: Semantics(
        label:
            '${product.title}, ${product.pack}, ${buyV2Money(facts.price)}, '
            '${buyV2FulfilmentModeLabel(fulfilmentMode)}, '
            '$buyerPromise${automaticFulfilment ? ', ${facts.partner}, ${offerDecision!.statusLabel}' : ', fulfilled by ${facts.partner}'}',
        button: true,
        child: InkWell(
          key: ValueKey('buy-product-${product.id}'),
          onTap: openProduct,
          borderRadius: BorderRadius.circular(BuyV2Metrics.compactRadius),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: buyV2CardDecoration(radius: BuyV2Metrics.compactRadius),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProductVisual(
                      product: product,
                      compact: compact,
                      reservedActionWidth: savedContext ? 84 : 42,
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 6 : 9,
                          compact ? 4 : 7,
                          compact ? 6 : 9,
                          compact ? 2 : 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!compact) ...[
                              Text(
                                product.brand,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.buyEyebrow.copyWith(fontSize: 7),
                              ),
                              const SizedBox(height: 3),
                            ],
                            Text(
                              product.title,
                              maxLines: compact ? 3 : 2,
                              overflow: compact
                                  ? TextOverflow.clip
                                  : TextOverflow.ellipsis,
                              style: TextStyle(
                                color: BuyV2Colors.ink,
                                fontSize: compact ? 10 : 12,
                                height: compact ? 1.05 : 1.08,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: compact ? 1 : 5),
                            if (!compact) ...[
                              Text(
                                product.variant,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: BuyV2Colors.ink,
                                  fontSize: 8,
                                  height: 1.15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                            ],
                            Text(
                              product.pack,
                              maxLines: compact ? 2 : 1,
                              overflow: compact
                                  ? TextOverflow.clip
                                  : TextOverflow.ellipsis,
                              style: context.buyMeta.copyWith(
                                fontSize: compact ? 8.5 : 8,
                                height: 1.05,
                              ),
                            ),
                            if (compact)
                              const SizedBox(height: 2)
                            else
                              const Spacer(),
                            Text(
                              buyV2Money(facts.price),
                              style: TextStyle(
                                color: BuyV2Colors.navy,
                                fontSize: compact ? 16 : 18,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (!compact)
                              Text(
                                product.unitPrice,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.buyMeta.copyWith(fontSize: 7),
                              ),
                            if (compact && !storeContext) ...[
                              const SizedBox(height: 2),
                              Text(
                                facts.partner,
                                maxLines: 2,
                                overflow: TextOverflow.clip,
                                style: context.buyMeta.copyWith(
                                  color: BuyV2Colors.navy,
                                  fontSize: 7.5,
                                  height: 1.05,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                _sellerTypeLabel(product.sellerType),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: context.buyMeta.copyWith(
                                  fontSize: 7,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            SizedBox(height: compact ? 3 : 6),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 4 : 6,
                                vertical: compact ? 2 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: requiresOfferReview
                                    ? BuyV2Colors.softOrange
                                    : BuyV2Colors.softGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        requiresOfferReview
                                            ? Icons.sync_problem_rounded
                                            : facts.isLive
                                            ? Icons.bolt_rounded
                                            : Icons.schedule_rounded,
                                        size: 11,
                                        color: requiresOfferReview
                                            ? BuyV2Colors.orange
                                            : BuyV2Colors.green,
                                      ),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          compact
                                              ? requiresOfferReview
                                                    ? offerDecision!.statusLabel
                                                    : automaticFulfilment
                                                    ? '${buyV2CompactFulfilmentModeLabel(fulfilmentMode)} · '
                                                          '${_compactDeliveryPromise(buyerPromise)}'
                                                    : '${facts.partner} · '
                                                          '${_compactDeliveryPromise(facts.deliveryPromise)}'
                                              : buyerPromise,
                                          maxLines: compact ? 2 : 2,
                                          overflow: compact
                                              ? TextOverflow.clip
                                              : TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: BuyV2Colors.green,
                                            fontSize: compact ? 8 : 8,
                                            height: compact ? 1.1 : 1.05,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!compact) ...[
                                    const SizedBox(height: 2),
                                    if (!storeContext) ...[
                                      Text(
                                        facts.partner,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: BuyV2Colors.ink,
                                          fontSize: 8,
                                          height: 1.05,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _sellerTypeLabel(product.sellerType),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: BuyV2Colors.muted,
                                          fontSize: 7,
                                          height: 1.05,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(height: compact ? 2 : 6),
                            AnimatedSwitcher(
                              duration: BuyV2Motion.resolved(
                                context,
                                BuyV2Motion.stateChange,
                              ),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: quantity > 0
                                  ? _QuantityStepper(
                                      key: ValueKey(
                                        'buy-quantity-${product.id}',
                                      ),
                                      productTitle: product.title,
                                      quantity: quantity,
                                      onDecrease: () =>
                                          session.decrease(product.id),
                                      onIncrease: () =>
                                          session.increase(product.id),
                                    )
                                  : SizedBox(
                                      key: ValueKey(
                                        'buy-add-shell-${product.id}',
                                      ),
                                      width: double.infinity,
                                      height: BuyV2Metrics.minimumTap,
                                      child: Semantics(
                                        label: requiresOfferReview
                                            ? 'Review ${product.title}. ${offerDecision!.statusLabel}'
                                            : rxBlocked
                                            ? 'Use prescription for '
                                                  '${product.title}'
                                            : 'Add ${product.title} to cart',
                                        button: true,
                                        child: Material(
                                          key: ValueKey(
                                            requiresOfferReview
                                                ? 'buy-review-offer-${product.id}'
                                                : 'buy-add-${product.id}',
                                          ),
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              HapticFeedback.selectionClick();
                                              if (requiresOfferReview) {
                                                session.openProduct(product.id);
                                                return;
                                              }
                                              final added = session.addProduct(
                                                product.id,
                                              );
                                              if (!added &&
                                                  session.pendingPrescriptionProductId ==
                                                      product.id) {
                                                showBuyV2PrescriptionSheet(
                                                  context,
                                                  session,
                                                );
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(
                                              11,
                                            ),
                                            child: Center(
                                              child: Container(
                                                height: 32,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: requiresOfferReview
                                                      ? BuyV2Colors.softOrange
                                                      : rxBlocked
                                                      ? BuyV2Colors.navy
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: requiresOfferReview
                                                        ? BuyV2Colors.orange
                                                        : rxBlocked
                                                        ? BuyV2Colors.navy
                                                        : const Color(
                                                            0x66000080,
                                                          ),
                                                  ),
                                                ),
                                                child: requiresOfferReview
                                                    ? const Icon(
                                                        Icons
                                                            .info_outline_rounded,
                                                        color:
                                                            BuyV2Colors.orange,
                                                        size: 20,
                                                      )
                                                    : rxBlocked
                                                    ? const Text(
                                                        'Use Rx',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                        ),
                                                      )
                                                    : const Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.add_rounded,
                                                            color: BuyV2Colors
                                                                .navy,
                                                            size: 17,
                                                          ),
                                                          SizedBox(width: 3),
                                                          Text(
                                                            'Add',
                                                            style: TextStyle(
                                                              color: BuyV2Colors
                                                                  .navy,
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w900,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: _ProductSaveButton(
                    session: session,
                    product: product,
                    showRemoveLabel: savedContext,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _sellerTypeLabel(String source) {
  final value = source.replaceFirst(
    RegExp(r'^Verified\\s+', caseSensitive: false),
    '',
  );
  return value.isEmpty ? 'Seller' : value;
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    super.key,
    required this.productTitle,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String productTitle;
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: BuyV2Metrics.minimumTap,
      decoration: BoxDecoration(
        color: BuyV2Colors.softBlue,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0x23000080)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: 'Decrease $productTitle quantity from $quantity',
              button: true,
              excludeSemantics: true,
              onTap: onDecrease,
              child: IconButton(
                tooltip: 'Remove one',
                onPressed: onDecrease,
                icon: const Icon(Icons.remove, size: 17),
                color: BuyV2Colors.navy,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          BuyV2FiniteValueTransition(
            key: const ValueKey('buy-grid-quantity-value-motion'),
            stateKey: quantity,
            text: '$quantity',
            ownerSize: const Size(24, 24),
            style: const TextStyle(
              color: BuyV2Colors.navy,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          Expanded(
            child: Semantics(
              label: 'Increase $productTitle quantity from $quantity',
              button: true,
              excludeSemantics: true,
              onTap: onIncrease,
              child: IconButton(
                tooltip: 'Add one',
                onPressed: onIncrease,
                icon: const Icon(Icons.add, size: 17),
                color: BuyV2Colors.navy,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSaveButton extends StatelessWidget {
  const _ProductSaveButton({
    required this.session,
    required this.product,
    this.showRemoveLabel = false,
  });

  final BuyV2Session session;
  final BuyV2Product product;
  final bool showRemoveLabel;

  @override
  Widget build(BuildContext context) {
    final saved = session.isSaved(product.id);
    void toggleSaved() {
      HapticFeedback.selectionClick();
      session.toggleSaved(product.id);
    }

    if (showRemoveLabel && saved) {
      return Semantics(
        key: ValueKey('buy-save-${product.id}'),
        button: true,
        label: 'Remove ${product.title} from Saved',
        child: Tooltip(
          message: 'Remove ${product.title} from Saved',
          child: InkWell(
            onTap: toggleSaved,
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              width: 62,
              height: 44,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: BuyV2Colors.orange.withValues(alpha: .22),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bookmark_remove_outlined,
                          size: 12,
                          color: BuyV2Colors.orange,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Remove',
                          style: TextStyle(
                            color: BuyV2Colors.muted,
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return IconButton(
      key: ValueKey('buy-save-${product.id}'),
      tooltip: saved
          ? 'Remove ${product.title} from Saved'
          : 'Save ${product.title}',
      onPressed: toggleSaved,
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        maximumSize: const Size(44, 44),
        foregroundColor: saved ? BuyV2Colors.orange : BuyV2Colors.navy,
        shape: const CircleBorder(),
      ),
      icon: BuyV2FiniteVisualTransition(
        key: ValueKey('buy-save-visual-${product.id}'),
        stateKey: saved,
        ownerSize: const Size.square(27),
        child: Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .92),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white),
          ),
          child: Icon(
            saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _ProductVisual extends StatelessWidget {
  const _ProductVisual({
    required this.product,
    required this.compact,
    this.reservedActionWidth = 42,
  });

  final BuyV2Product product;
  final bool compact;
  final double reservedActionWidth;

  @override
  Widget build(BuildContext context) {
    final colors = _productVisualColors(product);
    return SizedBox(
      height: compact ? 78 : 110,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13),
                  bottom: Radius.circular(10),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, .35),
            child: SizedBox(
              key: ValueKey('buy-grid-packshot-${product.id}'),
              width: compact ? 78 : 96,
              height: compact ? 70 : 86,
              child: BuyV2ProductPackshot(
                product: product,
                borderRadius: compact ? 8 : 12,
              ),
            ),
          ),
          Positioned(
            left: 6,
            top: 6,
            right: compact ? reservedActionWidth : 6,
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                constraints: BoxConstraints(maxWidth: compact ? 96 : 120),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 4 : 6,
                  vertical: compact ? 2 : 4,
                ),
                decoration: BoxDecoration(
                  color: product.requiresPrescription
                      ? BuyV2Colors.navy
                      : BuyV2Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  compact ? _compactProductBadge(product.badge) : product.badge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 8 : 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            right: 8,
            bottom: 7,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: BuyV2Colors.green,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.white, spreadRadius: 2)],
              ),
              child: SizedBox(width: 9, height: 9),
            ),
          ),
        ],
      ),
    );
  }
}

List<Color> _productVisualColors(BuyV2Product product) {
  return switch (product.visualKind) {
    'produce' => const [Color(0xFFFFE9E2), Color(0xFFEAF7E8)],
    'bottle' => const [Color(0xFFFFF5CF), Color(0xFFE8F6F8)],
    'paper' => const [Color(0xFFE8ECFA), Color(0xFFF8EBF4)],
    'medicine-box' => const [Color(0xFFE5F5F1), Color(0xFFFFE9E9)],
    'tube' => const [Color(0xFFFFE6D6), Color(0xFFF4EAF8)],
    _ => const [Color(0xFFFFF1DE), Color(0xFFEDF3F8)],
  };
}
